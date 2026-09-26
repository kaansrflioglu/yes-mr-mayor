extends Control

## RedTelephone.gd - Dynamic red emergency telephone on the mayor's desk.
## Rings with urgent or discreet calls from 6 distinct caller archetypes.

signal call_resolved(accepted: bool)
signal inspector_tip_requested

const CONSULT_FEE: int = 1000

@onready var phone_button: Button = %PhoneButton
@onready var ring_badge: Label = %RingBadge
@onready var dialog_panel: PanelContainer = %DialogPanel
@onready var caller_label: Label = %CallerLabel
@onready var message_label: Label = %MessageLabel
@onready var btn_accept: Button = %BtnAccept
@onready var btn_hangup: Button = %BtnHangup

var hotline_mgr: HotlineManager
var active_call: HotlineCallData = null
var is_ringing: bool = false
var is_consultation_mode: bool = false
var _wobble_tween: Tween


func _ready() -> void:
	hotline_mgr = HotlineManager.new()
	ring_badge.visible = false
	dialog_panel.visible = false
	phone_button.pressed.connect(_on_phone_clicked)
	btn_accept.pressed.connect(_on_accept_pressed)
	btn_hangup.pressed.connect(_on_hangup_pressed)
	LocalizationManager.locale_changed.connect(func(_l): _update_locale_texts())
	_update_locale_texts()


func _update_locale_texts() -> void:
	if is_consultation_mode:
		caller_label.text = tr("UI_HOTLINE_INQUIRY_TITLE")
		message_label.text = tr("UI_HOTLINE_INQUIRY_MSG")
		btn_accept.text = tr("UI_HOTLINE_BTN_INSPECT")
		btn_hangup.text = tr("UI_HOTLINE_HANGUP")
		_apply_dialog_theme(Color(0.85, 0.65, 0.15, 1.0))
	elif active_call != null:
		var badge_data := HotlineManager.get_archetype_badge_data(active_call.caller_archetype)
		var icon: String = badge_data.get("icon", "📞")
		var badge_text: String = tr(badge_data.get("badge_key", "UI_HOTLINE_TITLE"))
		var c_name: String = active_call.get_caller_name()
		var c_title: String = active_call.get_caller_title()

		caller_label.text = "%s [%s] %s (%s)" % [icon, badge_text, c_name, c_title]
		message_label.text = active_call.get_message()
		btn_accept.text = active_call.get_accept_text()
		btn_hangup.text = active_call.get_reject_text()
		_apply_dialog_theme(badge_data.get("accent_color", Color(0.85, 0.2, 0.2, 1.0)))
	else:
		caller_label.text = tr("UI_HOTLINE_TITLE")
		message_label.text = tr("UI_HOTLINE_MSG")
		btn_accept.text = tr("UI_HOTLINE_ACCEPT")
		btn_hangup.text = tr("UI_HOTLINE_HANGUP")
		_apply_dialog_theme(Color(0.85, 0.2, 0.2, 1.0))

	ring_badge.text = tr("UI_HOTLINE_RING")


func _apply_dialog_theme(accent_color: Color) -> void:
	if not dialog_panel:
		return
	var style: StyleBox = dialog_panel.get_theme_stylebox("panel")
	if style is StyleBoxFlat:
		var dup := style.duplicate() as StyleBoxFlat
		dup.border_color = accent_color
		dialog_panel.add_theme_stylebox_override("panel", dup)
	caller_label.add_theme_color_override("font_color", accent_color.lightened(0.2))


## Triggers random emergency call filtered by day and flags
func ring_telephone(custom_call: HotlineCallData = null) -> void:
	if is_ringing or dialog_panel.visible:
		return

	is_consultation_mode = false

	# Pick eligible call
	if custom_call != null:
		active_call = custom_call
	else:
		var cur_day: int = GameManager.current_day if GameManager != null else 1
		var cur_flags: Dictionary = GameManager.event_flags if GameManager != null else {}
		active_call = hotline_mgr.pick_next_call(cur_day, cur_flags)

	# Safety fallback to first call if database had no matches
	if active_call == null and not hotline_mgr.all_calls.is_empty():
		active_call = hotline_mgr.all_calls[0]

	is_ringing = true
	ring_badge.visible = true

	# Audio routing based on archetype
	if active_call != null and AudioManager != null:
		if AudioManager.has_method("play_phone_ring_archetype"):
			AudioManager.play_phone_ring_archetype(active_call.caller_archetype)
		else:
			AudioManager.play_phone_ring()
	elif AudioManager != null:
		AudioManager.play_phone_ring()

	_start_wobble_animation()


func _start_wobble_animation() -> void:
	if _wobble_tween and _wobble_tween.is_valid():
		_wobble_tween.kill()

	_wobble_tween = create_tween().set_loops(4)
	_wobble_tween.tween_property(phone_button, "rotation", 0.08, 0.06)
	_wobble_tween.tween_property(phone_button, "rotation", -0.08, 0.06)
	_wobble_tween.tween_property(phone_button, "rotation", 0.0, 0.04)


func _on_phone_clicked() -> void:
	if is_ringing:
		answer_call()
	else:
		open_consultation_dialog()


## Public method to answer the ringing hotline
func answer_call() -> void:
	if is_ringing:
		is_ringing = false
		ring_badge.visible = false
		if _wobble_tween and _wobble_tween.is_valid():
			_wobble_tween.kill()
		phone_button.rotation = 0.0
		is_consultation_mode = false
		_open_call_dialog()


## Opens the tipline consultation dialog
func open_consultation_dialog() -> void:
	if dialog_panel.visible:
		dialog_panel.visible = false
		return
	is_consultation_mode = true
	_open_call_dialog()


func _open_call_dialog() -> void:
	dialog_panel.visible = true
	_update_locale_texts()
	_ensure_dialog_on_screen()

	dialog_panel.scale = Vector2(0.9, 0.9)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(dialog_panel, "scale", Vector2.ONE, 0.25)


func _ensure_dialog_on_screen() -> void:
	dialog_panel.position = Vector2(0.0, -230.0)
	var vp_size := get_viewport_rect().size
	if vp_size.x > 0.0 and vp_size.y > 0.0:
		var panel_size := dialog_panel.size
		if panel_size == Vector2.ZERO:
			panel_size = dialog_panel.custom_minimum_size
		var glob := dialog_panel.global_position
		var max_x := maxf(20.0, vp_size.x - panel_size.x - 20.0)
		var max_y := maxf(80.0, vp_size.y - panel_size.y - 20.0)
		glob.x = clampf(glob.x, 20.0, max_x)
		glob.y = clampf(glob.y, 80.0, max_y)
		dialog_panel.global_position = glob


func _on_accept_pressed() -> void:
	if is_consultation_mode:
		consult_inspector()
	else:
		accept_deal()


## Public method to consult the Building Inspector for a guaranteed tip
func consult_inspector() -> bool:
	if GameManager.city_budget < CONSULT_FEE:
		return false
	dialog_panel.visible = false
	is_consultation_mode = false
	GameManager.city_budget -= CONSULT_FEE
	GameManager.stats_changed.emit()
	if AudioManager.has_method("play_phone_dial"):
		AudioManager.play_phone_dial()
	inspector_tip_requested.emit()
	return true


## Public method to accept the hotline deal
func accept_deal() -> void:
	dialog_panel.visible = false
	AudioManager.play_cash_register()

	var cur_day: int = GameManager.current_day if GameManager != null else 1
	if active_call != null:
		var should_reveal: bool = active_call.has_reveal_violation(true)
		hotline_mgr.resolve_call(active_call, true, cur_day)
		if should_reveal:
			inspector_tip_requested.emit()
		active_call = null
	else:
		# Fallback legacy behavior
		GameManager.apply_resolution({
			"budget": -30000,
			"suspicion": -20.0
		})

	call_resolved.emit(true)


func _on_hangup_pressed() -> void:
	reject_deal()


## Public method to reject the hotline deal
func reject_deal() -> void:
	dialog_panel.visible = false

	var cur_day: int = GameManager.current_day if GameManager != null else 1
	if active_call != null:
		hotline_mgr.resolve_call(active_call, false, cur_day)
		active_call = null

	call_resolved.emit(false)


## Public method to hang up the phone or close active dialog
func hang_up() -> void:
	reject_deal()
