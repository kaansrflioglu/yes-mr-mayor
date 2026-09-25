extends Control

## SaveLoadModal.gd - Slot selector modal for saving and loading game terms.
## Displays slot cards with rich metadata, confirmation dialogs, and smooth transitions.

signal save_completed(slot_id: String)
signal load_completed(slot_id: String)
signal modal_closed

enum Mode { SAVE, LOAD }
enum ConfirmType { NONE, OVERWRITE, DELETE }

var current_mode: Mode = Mode.SAVE
var current_confirm: ConfirmType = ConfirmType.NONE
var pending_slot_id: String = ""
var is_open: bool = false

@onready var backdrop: ColorRect = %Backdrop
@onready var modal_panel: PanelContainer = %ModalPanel
@onready var title_label: Label = %TitleLabel
@onready var btn_header_close: Button = %BtnHeaderClose
@onready var btn_footer_close: Button = %BtnFooterClose
@onready var toast_panel: PanelContainer = %ToastPanel
@onready var toast_label: Label = %ToastLabel

# Confirmation overlay
@onready var confirm_overlay: Control = %ConfirmOverlay
@onready var confirm_panel: PanelContainer = %ConfirmPanel
@onready var confirm_title: Label = %ConfirmTitle
@onready var confirm_message: Label = %ConfirmMessage
@onready var btn_confirm_yes: Button = %BtnConfirmYes
@onready var btn_confirm_no: Button = %BtnConfirmNo

# Slot card controls (mapped by slot_id)
@onready var card_autosave: PanelContainer = %CardAutosave
@onready var card_slot_1: PanelContainer = %CardSlot1
@onready var card_slot_2: PanelContainer = %CardSlot2
@onready var card_slot_3: PanelContainer = %CardSlot3

var _slot_cards: Dictionary = {}
var _toast_tween: Tween


func _ready() -> void:
	visible = false
	confirm_overlay.visible = false
	toast_panel.visible = false

	_slot_cards = {
		"autosave": card_autosave,
		"slot_1": card_slot_1,
		"slot_2": card_slot_2,
		"slot_3": card_slot_3
	}

	_connect_events()
	LocalizationManager.locale_changed.connect(func(_loc): _on_locale_changed())


func _connect_events() -> void:
	btn_header_close.pressed.connect(close)
	btn_footer_close.pressed.connect(close)

	btn_confirm_yes.pressed.connect(_on_confirm_yes_pressed)
	btn_confirm_no.pressed.connect(_on_confirm_no_pressed)

	for slot_id in _slot_cards:
		var btn_action := get_card_action_button(slot_id)
		var btn_delete := get_card_delete_button(slot_id)

		btn_action.pressed.connect(func(): _on_slot_action_pressed(slot_id))
		btn_delete.pressed.connect(func(): _on_slot_delete_pressed(slot_id))


func open(mode: Mode = Mode.SAVE) -> void:
	if mode == Mode.SAVE:
		open_in_save_mode()
	else:
		open_in_load_mode()


func open_in_save_mode() -> void:
	current_mode = Mode.SAVE
	title_label.text = tr("UI_SAVE_LOAD_TITLE_SAVE")
	_open_modal()


func open_in_load_mode() -> void:
	current_mode = Mode.LOAD
	title_label.text = tr("UI_SAVE_LOAD_TITLE_LOAD")
	_open_modal()


func _open_modal() -> void:
	is_open = true
	visible = true
	confirm_overlay.visible = false
	toast_panel.visible = false
	refresh_slots()

	backdrop.modulate = Color(1, 1, 1, 0)
	modal_panel.scale = Vector2(0.92, 0.92)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(backdrop, "modulate:a", 1.0, 0.2)
	tween.tween_property(modal_panel, "scale", Vector2.ONE, 0.25).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)


func close() -> void:
	if not is_open:
		return
	is_open = false
	_hide_confirm()

	var tween := create_tween().set_parallel(true)
	tween.tween_property(backdrop, "modulate:a", 0.0, 0.15)
	tween.tween_property(modal_panel, "scale", Vector2(0.94, 0.94), 0.15)
	await tween.finished
	visible = false
	modal_closed.emit()


func refresh_slots() -> void:
	for slot_id in _slot_cards:
		var card: PanelContainer = _slot_cards[slot_id]
		var meta: Dictionary = SaveLoadManager.get_slot_metadata(slot_id)
		_update_card_ui(card, slot_id, meta)


func _update_card_ui(_card: PanelContainer, slot_id: String, meta: Dictionary) -> void:
	var label_name := get_card_slot_name_label(slot_id)
	var label_time := get_card_timestamp_label(slot_id)
	var label_badge := get_card_alignment_badge(slot_id)
	var label_empty := get_card_empty_label(slot_id)
	var stats_box := get_card_stats_box(slot_id)

	var label_day := get_card_day_label(slot_id)
	var label_budget := get_card_budget_label(slot_id)
	var label_approval := get_card_approval_label(slot_id)
	var label_suspicion := get_card_suspicion_label(slot_id)

	var btn_action := get_card_action_button(slot_id)
	var btn_delete := get_card_delete_button(slot_id)

	label_name.text = _get_localized_slot_name(slot_id)
	var has_data: bool = meta.get("exists", false) and not meta.get("is_empty", true)

	if has_data:
		label_empty.visible = false
		stats_box.visible = true
		label_time.text = str(meta.get("timestamp_str", ""))

		var day_num: int = int(meta.get("day", 1))
		label_day.text = tr("UI_DAY").format({"day": day_num})

		var budget_amt: int = int(meta.get("budget", 0))
		label_budget.text = "💰 $%s" % [_format_number(budget_amt)]

		var opinion: float = float(meta.get("approval", 0.0))
		label_approval.text = "👥 %d%%" % int(opinion)

		var suspicion: float = float(meta.get("suspicion", 0.0))
		label_suspicion.text = "🕵️ %d%%" % int(suspicion)

		var align_str: String = str(meta.get("alignment", "Moderate"))
		var align_key := "UI_ALIGNMENT_" + align_str.to_upper()
		label_badge.text = "[ %s ]" % tr(align_key)
		label_badge.visible = true
		_style_alignment_badge(label_badge, align_str)

		btn_delete.visible = true
		btn_delete.text = tr("UI_BTN_DELETE")
		btn_action.disabled = false
	else:
		label_empty.visible = true
		label_empty.text = tr("UI_SLOT_EMPTY")
		stats_box.visible = false
		label_time.text = ""
		label_badge.visible = false
		btn_delete.visible = false

		if current_mode == Mode.LOAD:
			btn_action.disabled = true
		else:
			btn_action.disabled = false

	if current_mode == Mode.SAVE:
		btn_action.text = tr("UI_BTN_SAVE_HERE")
		btn_action.modulate = Color(0.9, 1.0, 0.9, 1.0)
	else:
		btn_action.text = tr("UI_BTN_LOAD")
		btn_action.modulate = Color(0.85, 0.95, 1.0, 1.0)


func _on_slot_action_pressed(slot_id: String) -> void:
	if current_mode == Mode.SAVE:
		if SaveLoadManager.has_save(slot_id):
			pending_slot_id = slot_id
			current_confirm = ConfirmType.OVERWRITE
			_show_confirm(
				tr("UI_CONFIRM_OVERWRITE_TITLE"),
				tr("UI_CONFIRM_OVERWRITE_MSG")
			)
		else:
			_execute_save(slot_id)
	else:
		if SaveLoadManager.has_save(slot_id):
			_execute_load(slot_id)


func _on_slot_delete_pressed(slot_id: String) -> void:
	pending_slot_id = slot_id
	current_confirm = ConfirmType.DELETE
	_show_confirm(
		tr("UI_CONFIRM_DELETE_TITLE"),
		tr("UI_CONFIRM_DELETE_MSG")
	)


func _on_confirm_yes_pressed() -> void:
	var slot := pending_slot_id
	var confirm := current_confirm
	_hide_confirm()

	if confirm == ConfirmType.OVERWRITE:
		_execute_save(slot)
	elif confirm == ConfirmType.DELETE:
		_execute_delete(slot)


func _on_confirm_no_pressed() -> void:
	_hide_confirm()


func _execute_save(slot_id: String) -> void:
	var success := SaveLoadManager.save_game(slot_id)
	if success:
		refresh_slots()
		_show_toast(tr("UI_SAVE_SUCCESS").format({"slot": _get_localized_slot_name(slot_id)}))
		AudioManager.play_stamp_thud(true)
		save_completed.emit(slot_id)


func _execute_load(slot_id: String) -> void:
	var success := SaveLoadManager.load_game(slot_id)
	if success:
		_show_toast(tr("UI_LOAD_SUCCESS").format({"slot": _get_localized_slot_name(slot_id)}))
		AudioManager.play_paper_slide()
		load_completed.emit(slot_id)


func _execute_delete(slot_id: String) -> void:
	var success := SaveLoadManager.delete_save(slot_id)
	if success:
		refresh_slots()
		_show_toast(tr("UI_DELETE_SUCCESS").format({"slot": _get_localized_slot_name(slot_id)}))
		AudioManager.play_paper_slide()


func _show_confirm(title_text: String, msg_text: String) -> void:
	confirm_title.text = title_text
	confirm_message.text = msg_text
	btn_confirm_yes.text = tr("UI_CONFIRM_YES")
	btn_confirm_no.text = tr("UI_CONFIRM_NO")

	confirm_overlay.visible = true
	confirm_overlay.modulate = Color(1, 1, 1, 0)
	confirm_panel.scale = Vector2(0.9, 0.9)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(confirm_overlay, "modulate:a", 1.0, 0.15)
	tween.tween_property(confirm_panel, "scale", Vector2.ONE, 0.2).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)


func _hide_confirm() -> void:
	confirm_overlay.visible = false
	current_confirm = ConfirmType.NONE
	pending_slot_id = ""


func _show_toast(msg: String) -> void:
	toast_label.text = msg
	toast_panel.visible = true
	toast_panel.modulate = Color(1, 1, 1, 0)

	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()

	_toast_tween = create_tween()
	_toast_tween.tween_property(toast_panel, "modulate:a", 1.0, 0.2)
	_toast_tween.tween_interval(1.8)
	_toast_tween.tween_property(toast_panel, "modulate:a", 0.0, 0.3)
	_toast_tween.tween_callback(func(): toast_panel.visible = false)


func _get_localized_slot_name(slot_id: String) -> String:
	match slot_id:
		"autosave":
			return "⚡ " + tr("UI_SLOT_AUTOSAVE")
		"slot_1":
			return "💾 " + tr("UI_SLOT_1")
		"slot_2":
			return "💾 " + tr("UI_SLOT_2")
		"slot_3":
			return "💾 " + tr("UI_SLOT_3")
		_:
			return slot_id.capitalize()


func _style_alignment_badge(badge: Label, align: String) -> void:
	match align:
		"Lawful":
			badge.modulate = Color(0.3, 0.85, 0.45, 1.0)
		"Corrupt":
			badge.modulate = Color(0.95, 0.3, 0.3, 1.0)
		_:
			badge.modulate = Color(0.9, 0.75, 0.35, 1.0)


func _format_number(n: int) -> String:
	var s := str(abs(n))
	var res := ""
	var cnt := 0
	for i in range(s.length() - 1, -1, -1):
		res = s[i] + res
		cnt += 1
		if cnt % 3 == 0 and i > 0:
			res = "," + res
	return ("-" if n < 0 else "") + res


func _on_locale_changed() -> void:
	if current_mode == Mode.SAVE:
		title_label.text = tr("UI_SAVE_LOAD_TITLE_SAVE")
	else:
		title_label.text = tr("UI_SAVE_LOAD_TITLE_LOAD")
	refresh_slots()


func _unhandled_input(event: InputEvent) -> void:
	if is_open and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if confirm_overlay.visible:
				_hide_confirm()
			else:
				close()
			get_viewport().set_input_as_handled()


# Public card element accessors
func get_card(slot_id: String) -> PanelContainer:
	return _slot_cards.get(slot_id, null)

func get_card_action_button(slot_id: String) -> Button:
	var c := get_card(slot_id)
	return c.get_node("Margin/HBox/ActionsHBox/BtnAction") as Button if c else null

func get_card_delete_button(slot_id: String) -> Button:
	var c := get_card(slot_id)
	return c.get_node("Margin/HBox/ActionsHBox/BtnDelete") as Button if c else null

func get_card_slot_name_label(slot_id: String) -> Label:
	var c := get_card(slot_id)
	return c.get_node("Margin/HBox/InfoVBox/HeaderRow/LabelSlotName") as Label if c else null

func get_card_alignment_badge(slot_id: String) -> Label:
	var c := get_card(slot_id)
	return c.get_node("Margin/HBox/InfoVBox/HeaderRow/LabelAlignment") as Label if c else null

func get_card_timestamp_label(slot_id: String) -> Label:
	var c := get_card(slot_id)
	return c.get_node("Margin/HBox/InfoVBox/HeaderRow/LabelTimestamp") as Label if c else null

func get_card_empty_label(slot_id: String) -> Label:
	var c := get_card(slot_id)
	return c.get_node("Margin/HBox/InfoVBox/LabelEmpty") as Label if c else null

func get_card_stats_box(slot_id: String) -> Container:
	var c := get_card(slot_id)
	return c.get_node("Margin/HBox/InfoVBox/StatsBox") as Container if c else null

func get_card_day_label(slot_id: String) -> Label:
	var c := get_card(slot_id)
	return c.get_node("Margin/HBox/InfoVBox/StatsBox/LabelDay") as Label if c else null

func get_card_budget_label(slot_id: String) -> Label:
	var c := get_card(slot_id)
	return c.get_node("Margin/HBox/InfoVBox/StatsBox/LabelBudget") as Label if c else null

func get_card_approval_label(slot_id: String) -> Label:
	var c := get_card(slot_id)
	return c.get_node("Margin/HBox/InfoVBox/StatsBox/LabelApproval") as Label if c else null

func get_card_suspicion_label(slot_id: String) -> Label:
	var c := get_card(slot_id)
	return c.get_node("Margin/HBox/InfoVBox/StatsBox/LabelSuspicion") as Label if c else null
