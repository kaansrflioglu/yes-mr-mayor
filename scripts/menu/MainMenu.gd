extends Control

## MainMenu.gd - Title screen controller for Yes, Mr. Mayor.
## Manages game entry, save/load routing, modal transitions, and city backdrop.

enum ConfirmAction { NONE, NEW_GAME, QUIT }

var _pending_action: ConfirmAction = ConfirmAction.NONE
var _is_transitioning: bool = false

# Top / Title
@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel

# Menu Action Buttons
@onready var btn_continue: Button = %BtnContinue
@onready var label_continue_preview: Label = %LabelContinuePreview
@onready var btn_new_game: Button = %BtnNewGame
@onready var btn_load_game: Button = %BtnLoadGame
@onready var btn_how_to_play: Button = %BtnHowToPlay
@onready var btn_settings: Button = %BtnSettings
@onready var btn_quit: Button = %BtnQuit

# Modals
@onready var save_load_modal: Control = %SaveLoadModal
@onready var settings_modal: Control = %SettingsModal
@onready var how_to_play_modal: Control = %HowToPlayModal

# Confirmation dialog
@onready var confirm_overlay: Control = %ConfirmOverlay
@onready var confirm_panel: PanelContainer = %ConfirmPanel
@onready var confirm_title: Label = %ConfirmTitle
@onready var confirm_message: Label = %ConfirmMessage
@onready var btn_confirm_yes: Button = %BtnConfirmYes
@onready var btn_confirm_no: Button = %BtnConfirmNo

# Transition Overlay
@onready var transition_overlay: ColorRect = %TransitionOverlay


func _ready() -> void:
	confirm_overlay.visible = false
	save_load_modal.visible = false
	settings_modal.visible = false
	how_to_play_modal.visible = false

	_connect_signals()
	_update_locale_texts()
	_refresh_buttons()

	# Listen to locale and save changes
	LocalizationManager.locale_changed.connect(func(_loc): _on_locale_changed())
	SaveLoadManager.game_saved.connect(func(_slot): _refresh_buttons())
	SaveLoadManager.save_deleted.connect(func(_slot): _refresh_buttons())

	# Initial fade in from black
	transition_overlay.visible = true
	transition_overlay.color = Color(0, 0, 0, 1)
	var tween := create_tween()
	tween.tween_property(transition_overlay, "color:a", 0.0, 0.45)
	tween.tween_callback(func():
		transition_overlay.visible = false
	)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_handle_cancel_request()


func _handle_cancel_request() -> void:
	if confirm_overlay.visible:
		_hide_confirm()
	elif how_to_play_modal.get("is_open"):
		how_to_play_modal.call("close")
	elif save_load_modal.get("is_open"):
		save_load_modal.call("close")
	elif settings_modal.get("is_open"):
		settings_modal.call("close")
	else:
		_prompt_quit_confirmation()


func _connect_signals() -> void:
	btn_continue.pressed.connect(_on_continue_pressed)
	btn_new_game.pressed.connect(_on_new_game_pressed)
	btn_load_game.pressed.connect(_on_load_game_pressed)
	btn_how_to_play.pressed.connect(_on_how_to_play_pressed)
	btn_settings.pressed.connect(_on_settings_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)

	# Sound hooks for button interactions
	for btn: Button in [
		btn_continue, btn_new_game, btn_load_game,
		btn_how_to_play, btn_settings, btn_quit
	]:
		btn.mouse_entered.connect(func(): AudioManager.play_inspect_toggle())

	btn_confirm_yes.pressed.connect(_on_confirm_yes_pressed)
	btn_confirm_no.pressed.connect(_on_confirm_no_pressed)

	# SaveLoadModal signals
	save_load_modal.connect("load_completed", Callable(self, "_on_save_load_completed"))


func _refresh_buttons() -> void:
	var has_saves: bool = SaveLoadManager.has_any_save()
	btn_continue.disabled = not has_saves

	if has_saves:
		var latest_slot: String = SaveLoadManager.get_latest_save_slot()
		var meta: Dictionary = SaveLoadManager.get_slot_metadata(latest_slot)
		var day: int = int(meta.get("day", 1))
		var treasury: int = int(meta.get("city_budget", meta.get("budget", 0)))
		var opinion: float = float(meta.get("public_opinion", meta.get("approval", 50.0)))
		label_continue_preview.text = "Day %d  •  $%s  •  %d%% Approval" % [
			day, _format_currency(treasury), int(opinion)
		]
		label_continue_preview.modulate = Color(0.9, 0.85, 0.6, 1.0)
	else:
		label_continue_preview.text = tr("UI_MAIN_NO_SAVE_PREVIEW")
		label_continue_preview.modulate = Color(0.55, 0.6, 0.7, 0.6)


func _on_continue_pressed() -> void:
	AudioManager.play_paper_slide()
	var latest_slot: String = SaveLoadManager.get_latest_save_slot()
	if latest_slot != "":
		var success: bool = SaveLoadManager.load_game(latest_slot)
		if success:
			_transition_to_desk()


func _on_new_game_pressed() -> void:
	AudioManager.play_paper_slide()
	if SaveLoadManager.has_any_save():
		_pending_action = ConfirmAction.NEW_GAME
		_show_confirm(
			tr("UI_CONFIRM_NEW_GAME_TITLE"),
			tr("UI_CONFIRM_NEW_GAME_MSG")
		)
	else:
		_start_new_term()


func _start_new_term() -> void:
	GameManager.start_new_game()
	EventManager.reset_deck()
	_transition_to_desk()


func _on_load_game_pressed() -> void:
	AudioManager.play_paper_slide()
	save_load_modal.call("open_in_load_mode")


func _on_save_load_completed(_slot_id: String) -> void:
	_transition_to_desk()


func _on_how_to_play_pressed() -> void:
	how_to_play_modal.call("open")


func _on_settings_pressed() -> void:
	AudioManager.play_paper_slide()
	settings_modal.call("open")


func _on_quit_pressed() -> void:
	AudioManager.play_paper_slide()
	_prompt_quit_confirmation()


func _prompt_quit_confirmation() -> void:
	_pending_action = ConfirmAction.QUIT
	_show_confirm(
		tr("UI_CONFIRM_QUIT_TITLE"),
		tr("UI_CONFIRM_QUIT_MSG")
	)


func _on_confirm_yes_pressed() -> void:
	var action := _pending_action
	_hide_confirm()

	if action == ConfirmAction.NEW_GAME:
		_start_new_term()
	elif action == ConfirmAction.QUIT:
		get_tree().quit()


func _on_confirm_no_pressed() -> void:
	_hide_confirm()


func _show_confirm(title_text: String, msg_text: String) -> void:
	confirm_title.text = title_text
	confirm_message.text = msg_text
	confirm_overlay.visible = true
	confirm_panel.scale = Vector2(0.92, 0.92)
	confirm_overlay.modulate.a = 0.0

	var tween := create_tween().set_parallel(true)
	tween.tween_property(confirm_overlay, "modulate:a", 1.0, 0.18)
	tween.tween_property(confirm_panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)


func _hide_confirm() -> void:
	_pending_action = ConfirmAction.NONE
	var tween := create_tween().set_parallel(true)
	tween.tween_property(confirm_overlay, "modulate:a", 0.0, 0.14)
	tween.chain().tween_callback(func():
		confirm_overlay.visible = false
	)


func _transition_to_desk() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	transition_overlay.visible = true
	transition_overlay.modulate.a = 0.0

	var tween := create_tween()
	tween.tween_property(transition_overlay, "modulate:a", 1.0, 0.35)
	tween.tween_callback(func():
		get_tree().change_scene_to_file("res://scenes/desk/DeskView.tscn")
	)


func _update_locale_texts() -> void:
	title_label.text = tr("UI_MAIN_TITLE")
	subtitle_label.text = tr("UI_MAIN_SUBTITLE")
	btn_continue.text = tr("UI_BTN_CONTINUE")
	btn_new_game.text = tr("UI_BTN_NEW_GAME")
	btn_load_game.text = tr("UI_BTN_LOAD_GAME")
	btn_how_to_play.text = tr("UI_BTN_HOW_TO_PLAY")
	btn_settings.text = tr("UI_BTN_SETTINGS")
	btn_quit.text = tr("UI_BTN_QUIT")
	btn_confirm_yes.text = tr("UI_CONFIRM_YES")
	btn_confirm_no.text = tr("UI_CONFIRM_NO")
	_refresh_buttons()


func _on_locale_changed() -> void:
	_update_locale_texts()


func _format_currency(amount: int) -> String:
	var s := str(abs(amount))
	var res := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		res = s[i] + res
		count += 1
		if count % 3 == 0 and i > 0:
			res = "," + res
	return ("-" if amount < 0 else "") + res
