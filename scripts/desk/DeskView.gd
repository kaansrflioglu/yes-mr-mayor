extends Control

## DeskView.gd - Primary gameplay canvas for "Yes, Mr. Mayor!"
## Handles multi-document dossier handling, municipal rulebook inspection,
## Papers, Please style deduction / discrepancy spotting, and consequence stamping.

const DOCUMENT_SCENE: PackedScene = preload("res://scenes/desk/DocumentItem.tscn")
const DAY_SUMMARY_SCENE: PackedScene = preload("res://scenes/summary/DayEndSummary.tscn")
const GAME_OVER_SCENE: PackedScene = preload("res://scenes/summary/GameOverModal.tscn")

@onready var shake_root: Control = %ShakeRoot
@onready var document_drop_zone: Control = %DocumentDropZone
@onready var btn_stamp_approve: Button = %BtnStampApprove
@onready var btn_stamp_reject: Button = %BtnStampReject
@onready var btn_inspect_mode: Button = %BtnInspectMode
@onready var rulebook: Control = %Rulebook
@onready var btn_toggle_rulebook: Button = %BtnToggleRulebook
@onready var inspect_status_panel: PanelContainer = %InspectStatusPanel
@onready var inspect_status_label: Label = %InspectStatusLabel

@onready var focus_panel: PanelContainer = %FocusPanel if has_node("%FocusPanel") else null
@onready var focus_label: Label = %FocusLabel if has_node("%FocusLabel") else null
@onready var focus_icons_container: HBoxContainer = (
	%FocusIconsContainer if has_node("%FocusIconsContainer") else null
)
@onready var btn_order_espresso: Button = (
	%BtnOrderEspresso if has_node("%BtnOrderEspresso") else null
)
@onready var btn_toggle_uv: Button = (
	%BtnToggleUV if has_node("%BtnToggleUV") else null
)

@onready var safe_drawer_panel: PanelContainer = %SafeDrawerPanel
@onready var drawer_label: Label = %DrawerLabel
@onready var drawer_hint: Label = %DrawerHint
@onready var next_day_box: PanelContainer = %NextDayBox
@onready var btn_next_day: Button = %BtnNextDay
@onready var shift_info_label: Label = %ShiftInfoLabel
@onready var red_telephone: Control = %RedTelephone
@onready var skyline_view: Control = %SkylineView
@onready var top_bar_hud: Control = $TopBarHUD
@onready var twitch_overlay: Control = %TwitchVoteOverlay
@onready var settings_modal: Control = %SettingsModal
@onready var pause_menu: Control = %PauseMenu
@onready var save_load_modal: Control = %SaveLoadModal
@onready var save_toast: Control = %SaveToast if has_node("%SaveToast") else null

# Inspection Focus & Stamina Mechanics (Milestone 1)
const MAX_INSPECT_FOCUS: int = 4
const FALSE_INQUIRY_WARN_THRESHOLD: int = 2
const FALSE_INQUIRY_PENALTY_THRESHOLD: int = 3
const ESPRESSO_COST: int = 500
const ESPRESSO_FOCUS_RESTORE: int = 2
const ESPRESSO_SUSPICION_GAIN: float = 1.5

var current_inspect_focus: int = MAX_INSPECT_FOCUS
var consecutive_false_inquiries: int = 0

# Shift Time Clock & Tactile Immersion Mechanics (Milestone 2)
const SHIFT_START_MINUTES: int = 9 * 60 # 09:00 AM (540 mins)
const SHIFT_END_MINUTES: int = 17 * 60   # 05:00 PM (1020 mins)
const INSPECT_TIME_COST_MINUTES: int = 15
const PHONE_INQUIRY_TIME_COST_MINUTES: int = 30
const UV_TOGGLE_TIME_COST_MINUTES: int = 5
const OVERTIME_FINE_PER_DOC: int = 5000
const OVERTIME_APPROVAL_PENALTY_PER_DOC: float = 5.0

var current_shift_minutes: int = SHIFT_START_MINUTES
var is_overtime: bool = false
var is_uv_active: bool = false

var active_document: Control = null
var active_summary: Control = null
var active_game_over: Control = null
var is_processing_decision: bool = false
var _shake_tween: Tween
var _was_paused_for_modal: bool = false

# Inspection & Discrepancy state
var is_inspect_mode: bool = false
var first_token: String = ""
var first_label: String = ""


func _ready() -> void:
	btn_stamp_approve.pressed.connect(_on_approve_pressed)
	btn_stamp_reject.pressed.connect(_on_reject_pressed)
	btn_inspect_mode.pressed.connect(_toggle_inspect_mode)
	btn_toggle_rulebook.pressed.connect(_toggle_rulebook)
	btn_next_day.pressed.connect(_on_next_day_pressed)
	safe_drawer_panel.gui_input.connect(_on_drawer_gui_input)

	if btn_order_espresso != null:
		btn_order_espresso.pressed.connect(_on_order_espresso_pressed)

	if btn_toggle_uv != null:
		btn_toggle_uv.pressed.connect(toggle_uv_blacklight)

	if red_telephone != null and red_telephone.has_signal("inspector_tip_requested"):
		red_telephone.inspector_tip_requested.connect(_on_inspector_tip_requested)

	top_bar_hud.settings_toggle_requested.connect(_toggle_settings)
	top_bar_hud.pause_toggle_requested.connect(_toggle_pause_menu)

	if settings_modal != null:
		settings_modal.set_twitch_overlay_reference(twitch_overlay)
		settings_modal.twitch_overlay_toggle_requested.connect(
			func(): twitch_overlay.toggle_overlay()
		)
		settings_modal.modal_closed.connect(_on_settings_modal_closed)

	if pause_menu != null:
		pause_menu.save_requested.connect(_on_pause_save_requested)
		pause_menu.load_requested.connect(_on_pause_load_requested)
		pause_menu.settings_requested.connect(_on_pause_settings_requested)

	if save_load_modal != null:
		save_load_modal.modal_closed.connect(_on_save_load_modal_closed)
		save_load_modal.load_completed.connect(_on_game_load_completed)

	rulebook.rule_tag_selected.connect(_on_rule_tag_selected)

	GameManager.game_over.connect(_on_game_over)
	LocalizationManager.locale_changed.connect(_update_locale_texts)
	_update_locale_texts("")

	next_day_box.visible = false
	inspect_status_panel.visible = false
	_start_or_continue_shift()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			_toggle_inspect_mode()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_U:
			toggle_uv_blacklight()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_TAB:
			_toggle_rulebook()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			_handle_escape_key()
			get_viewport().set_input_as_handled()


func _handle_escape_key() -> void:
	if settings_modal != null and settings_modal.is_open:
		settings_modal.close()
	elif save_load_modal != null and save_load_modal.is_open:
		save_load_modal.close()
	elif red_telephone != null and red_telephone.dialog_panel.visible:
		red_telephone.hang_up()
	elif rulebook != null and rulebook.is_open:
		rulebook.toggle_rulebook()
	elif pause_menu != null and pause_menu.is_open:
		pause_menu.close()
	else:
		_toggle_pause_menu()


func _toggle_pause_menu() -> void:
	if pause_menu == null:
		return
	if pause_menu.is_open:
		pause_menu.close()
	else:
		_open_pause_menu()


func _open_pause_menu() -> void:
	if pause_menu == null or pause_menu.is_open:
		return
	if settings_modal != null and settings_modal.is_open:
		settings_modal.close()
	if save_load_modal != null and save_load_modal.is_open:
		save_load_modal.close()
	pause_menu.open()


func _on_pause_save_requested() -> void:
	_was_paused_for_modal = true
	pause_menu.close()
	if save_load_modal != null:
		save_load_modal.open_in_save_mode()


func _on_pause_load_requested() -> void:
	_was_paused_for_modal = true
	pause_menu.close()
	if save_load_modal != null:
		save_load_modal.open_in_load_mode()


func _on_pause_settings_requested() -> void:
	_was_paused_for_modal = true
	pause_menu.close()
	if settings_modal != null:
		settings_modal.open()


func _on_save_load_modal_closed() -> void:
	if _was_paused_for_modal:
		_was_paused_for_modal = false
		if pause_menu != null:
			pause_menu.open()


func _on_settings_modal_closed() -> void:
	if _was_paused_for_modal:
		_was_paused_for_modal = false
		if pause_menu != null:
			pause_menu.open()


func _on_game_load_completed(_slot_id: String) -> void:
	_was_paused_for_modal = false
	if active_document != null and is_instance_valid(active_document):
		active_document.queue_free()
		active_document = null
	if active_summary != null and is_instance_valid(active_summary):
		active_summary.queue_free()
		active_summary = null
	if active_game_over != null and is_instance_valid(active_game_over):
		active_game_over.queue_free()
		active_game_over = null

	next_day_box.visible = false
	inspect_status_panel.visible = false
	_start_or_continue_shift()


func _toggle_settings() -> void:
	if settings_modal == null:
		return
	if settings_modal.is_open:
		settings_modal.close()
	else:
		if pause_menu != null and pause_menu.is_open:
			_on_pause_settings_requested()
		else:
			_open_pause_menu()


func _update_locale_texts(_loc: String) -> void:
	btn_stamp_approve.text = tr("UI_STAMP_APPROVED")
	_update_reject_button_text()
	var inspect_key := "UI_INSPECT_MODE" if not is_inspect_mode else "UI_INSPECT_CANCEL"
	btn_inspect_mode.text = tr(inspect_key)
	btn_toggle_rulebook.text = tr("UI_RULEBOOK_TOGGLE")
	drawer_label.text = tr("UI_DRAWER_LABEL")
	drawer_hint.text = tr("UI_DRAWER_HINT")
	btn_next_day.text = tr("UI_NEXT_DAY")
	shift_info_label.text = tr("UI_NO_MORE_DOCS")
	if is_inspect_mode:
		inspect_status_label.text = tr("UI_INSPECT_ACTIVE")
	_update_focus_ui()
	if btn_toggle_uv != null:
		btn_toggle_uv.text = tr("UI_UV_ACTIVE") if is_uv_active else tr("UI_UV_TOOL")
	_update_clock_ui()


func _update_reject_button_text() -> void:
	var cause_count: int = 0
	if active_document != null and "discovered_violations" in active_document:
		cause_count = active_document.discovered_violations.size()

	if cause_count > 0:
		btn_stamp_reject.text = tr("UI_REJECT_WITH_CAUSE").format({"count": cause_count})
	else:
		btn_stamp_reject.text = tr("UI_STAMP_REJECTED")


func _start_or_continue_shift() -> void:
	if EventManager.daily_queue.is_empty():
		EventManager.prepare_daily_queue(4)
		current_shift_minutes = SHIFT_START_MINUTES
		is_overtime = false
		_update_clock_ui()
	_present_next_document()


## Draws and animates the next document onto the desk
func _present_next_document() -> void:
	if GameManager.is_game_over:
		return

	# Reset focus and inquiries for new dossier
	current_inspect_focus = MAX_INSPECT_FOCUS
	consecutive_false_inquiries = 0
	_update_focus_ui()

	if active_document != null and is_instance_valid(active_document):
		active_document.queue_free()
		active_document = null

	var next_event: EventData = EventManager.pop_daily_event()
	if next_event == null:
		_on_daily_quota_completed()
		return

	next_day_box.visible = false
	_set_stamps_enabled(false)
	TwitchManager.reset_votes()

	var doc_instance := DOCUMENT_SCENE.instantiate()
	document_drop_zone.add_child(doc_instance)
	active_document = doc_instance

	doc_instance.setup_event(next_event)
	doc_instance.set_uv_blacklight(is_uv_active)
	GameManager.present_event(next_event)

	# Connect inspection signals
	doc_instance.data_point_selected.connect(_on_doc_data_selected)
	doc_instance.violation_uncovered.connect(_on_violation_uncovered)

	# Reset inspection state for new document
	first_token = ""
	first_label = ""
	_update_reject_button_text()

	# Audio feedback: Paper slide rustle
	AudioManager.play_paper_slide()

	# Center on the desk blotter
	var desk_center := Vector2(600, 140)
	var spawn_pos := Vector2(-700, 350)
	doc_instance.animate_slide_in(spawn_pos, desk_center, -0.01)

	doc_instance.slide_in_completed.connect(func():
		if not GameManager.is_game_over:
			_set_stamps_enabled(true)
		is_processing_decision = false

		# 35% chance to trigger red emergency phone ringing
		if randf() < 0.35 and red_telephone != null:
			red_telephone.ring_telephone()
	)


func _toggle_rulebook() -> void:
	rulebook.toggle_rulebook()


func _toggle_inspect_mode() -> void:
	is_inspect_mode = not is_inspect_mode
	AudioManager.play_inspect_toggle()

	rulebook.set_inspect_mode(is_inspect_mode)
	if active_document != null and active_document.has_method("set_inspect_mode"):
		active_document.set_inspect_mode(is_inspect_mode)

	first_token = ""
	first_label = ""
	inspect_status_panel.visible = is_inspect_mode

	if is_inspect_mode:
		btn_inspect_mode.text = tr("UI_INSPECT_CANCEL")
		inspect_status_label.text = tr("UI_INSPECT_ACTIVE")
		# Auto-open rulebook if closed so player can cross-reference
		if not rulebook.is_open:
			rulebook.toggle_rulebook()
	else:
		btn_inspect_mode.text = tr("UI_INSPECT_MODE")


func _on_order_espresso_pressed() -> void:
	order_espresso()


func order_espresso() -> bool:
	if current_inspect_focus >= MAX_INSPECT_FOCUS:
		return false
	if GameManager.treasury < ESPRESSO_COST:
		return false

	GameManager.treasury -= ESPRESSO_COST
	var new_susp: float = GameManager.suspicion_level + ESPRESSO_SUSPICION_GAIN
	GameManager.suspicion_level = clampf(new_susp, 0.0, 100.0)
	current_inspect_focus = mini(current_inspect_focus + ESPRESSO_FOCUS_RESTORE, MAX_INSPECT_FOCUS)
	GameManager.stats_changed.emit()

	if AudioManager.has_method("play_coffee_sip"):
		AudioManager.play_coffee_sip()
	else:
		AudioManager.play_inspect_toggle()

	_update_focus_ui()
	inspect_status_panel.visible = true
	inspect_status_label.text = "☕ " + tr("UI_ESPRESSO_ORDERED")
	return true


func _update_focus_ui() -> void:
	if focus_label != null:
		focus_label.text = tr("UI_FOCUS_POINTS").format({
			"current": current_inspect_focus,
			"max": MAX_INSPECT_FOCUS
		})

	if focus_icons_container != null:
		var pips := focus_icons_container.get_children()
		for i in range(pips.size()):
			if pips[i] is CanvasItem:
				if i < current_inspect_focus:
					pips[i].modulate = Color(1.0, 0.85, 0.35, 1.0)
				else:
					pips[i].modulate = Color(0.4, 0.45, 0.55, 0.3)

	if btn_order_espresso != null:
		btn_order_espresso.visible = (current_inspect_focus <= 1)
		btn_order_espresso.disabled = (GameManager.treasury < ESPRESSO_COST)
		btn_order_espresso.text = tr("UI_ORDER_ESPRESSO")
		btn_order_espresso.tooltip_text = tr("UI_ORDER_ESPRESSO_TIP")


## Public testing API wrapper: evaluate a pair of tokens
func evaluate_discrepancy(token_a: String, token_b: String) -> void:
	_evaluate_discrepancy(token_a, token_b)


## Public testing API wrapper: refresh focus UI elements
func update_focus_ui() -> void:
	_update_focus_ui()


## Public testing API wrapper: present the next document in queue
func present_next_document() -> void:
	_present_next_document()


## Advances the shift clock and updates display
func advance_shift_time(minutes: int) -> void:
	current_shift_minutes += minutes
	if current_shift_minutes >= SHIFT_END_MINUTES and not is_overtime:
		is_overtime = true
		inspect_status_panel.visible = true
		inspect_status_label.text = "⚠️ " + tr("UI_SHIFT_OVERTIME")
		_trigger_camera_shake(0.2, 5.0)

	if AudioManager.has_method("play_clock_tick"):
		AudioManager.play_clock_tick()

	_update_clock_ui()


## Returns human-readable clock representation, e.g. "09:15 AM"
func get_formatted_shift_time() -> String:
	var total_m: int = current_shift_minutes
	var hrs: int = (total_m / 60)
	var mins: int = total_m % 60
	var is_pm: bool = hrs >= 12
	var display_hr: int = hrs
	if display_hr > 12:
		display_hr -= 12
	var period: String = "PM" if is_pm else "AM"
	var base_time: String = "%02d:%02d %s" % [display_hr, mins, period]
	if is_overtime or current_shift_minutes >= SHIFT_END_MINUTES:
		return base_time + " (!)"
	return base_time


func _update_clock_ui() -> void:
	if top_bar_hud != null and top_bar_hud.has_method("set_shift_time"):
		top_bar_hud.set_shift_time(get_formatted_shift_time(), is_overtime)


## Toggles tactical UV blacklight on the active document
func toggle_uv_blacklight() -> void:
	is_uv_active = not is_uv_active
	if AudioManager.has_method("play_uv_toggle"):
		AudioManager.play_uv_toggle()
	advance_shift_time(UV_TOGGLE_TIME_COST_MINUTES)

	if btn_toggle_uv != null:
		btn_toggle_uv.text = tr("UI_UV_ACTIVE") if is_uv_active else tr("UI_UV_TOOL")
		btn_toggle_uv.modulate = (
			Color(1.2, 0.8, 1.5, 1.0) if is_uv_active else Color.WHITE
		)

	if active_document != null and active_document.has_method("set_uv_blacklight"):
		active_document.set_uv_blacklight(is_uv_active)


## Handles tipline consultation tip from Senior Building Inspector
func _on_inspector_tip_requested() -> void:
	advance_shift_time(PHONE_INQUIRY_TIME_COST_MINUTES)
	if GameManager.active_event == null:
		return

	var event: EventData = GameManager.active_event
	var found_viol: Dictionary = {}
	if event.has_violations():
		for viol in event.violations:
			var already_found: bool = false
			if active_document != null and "discovered_violations" in active_document:
				for d in active_document.discovered_violations:
					if d.get("id") == viol.get("id"):
						already_found = true
						break
			if not already_found:
				found_viol = viol
				break

	if not found_viol.is_empty():
		if active_document != null and active_document.has_method("mark_violation_found"):
			active_document.mark_violation_found(found_viol)
		var viol_name: String = tr(str(found_viol.get("name_key", "VIOL_HEIGHT_LIMIT")))
		inspect_status_panel.visible = true
		var msg_text: String = tr("UI_HOTLINE_TIP_FOUND").format({"violation": viol_name})
		inspect_status_label.text = "☎️ " + msg_text
		AudioManager.play_discrepancy_match()
		_update_reject_button_text()
	else:
		inspect_status_panel.visible = true
		inspect_status_label.text = "☎️ " + tr("UI_HOTLINE_TIP_CLEAN")
		AudioManager.play_discrepancy_fail()


func _on_doc_data_selected(tag: String, label_preview: String) -> void:
	_handle_inspect_selection(tag, label_preview)


func _on_rule_tag_selected(tag: String, label_preview: String) -> void:
	_handle_inspect_selection(tag, label_preview)


func _handle_inspect_selection(tag: String, label_preview: String) -> void:
	if not is_inspect_mode:
		# Auto-activate inspect mode on clicking a field
		_toggle_inspect_mode()

	if first_token.is_empty():
		first_token = tag
		first_label = label_preview
		inspect_status_panel.visible = true
		var step_text: String = "1. " + label_preview.to_upper() + " ➔ "
		inspect_status_label.text = step_text + tr("UI_INSPECT_ACTIVE")
	else:
		# Compare first_token with second tag
		var second_token: String = tag

		if first_token == second_token:
			# Clicked same item twice, reset
			first_token = ""
			first_label = ""
			inspect_status_label.text = tr("UI_INSPECT_ACTIVE")
			return

		_evaluate_discrepancy(first_token, second_token)
		first_token = ""
		first_label = ""


func _evaluate_discrepancy(token_a: String, token_b: String) -> void:
	if GameManager.active_event == null:
		return

	# Focus AP Limit Check
	if current_inspect_focus <= 0:
		AudioManager.play_discrepancy_fail()
		inspect_status_panel.visible = true
		inspect_status_label.text = "⚠️ " + tr("UI_INSPECT_FATIGUED")
		_trigger_camera_shake(0.15, 3.0)
		return

	current_inspect_focus -= 1
	_update_focus_ui()
	advance_shift_time(INSPECT_TIME_COST_MINUTES)

	var match_viol: Dictionary = GameManager.active_event.find_matching_violation(token_a, token_b)

	if not match_viol.is_empty():
		# DISCREPANCY DETECTED!
		consecutive_false_inquiries = 0
		AudioManager.play_discrepancy_match()
		_trigger_camera_shake(0.2, 5.0)

		if active_document != null and active_document.has_method("mark_violation_found"):
			active_document.mark_violation_found(match_viol)

		var viol_name: String = tr(str(match_viol.get("name_key", "VIOL_HEIGHT_LIMIT")))
		inspect_status_panel.visible = true
		var disc_msg: String = tr("UI_DISCREPANCY_FOUND").format({"violation": viol_name})
		inspect_status_label.text = "✔ " + disc_msg
		_update_reject_button_text()
	else:
		# NO CONTRADICTION
		consecutive_false_inquiries += 1
		AudioManager.play_discrepancy_fail()
		inspect_status_panel.visible = true

		if consecutive_false_inquiries >= FALSE_INQUIRY_PENALTY_THRESHOLD:
			GameManager.apply_resolution({
				"public_opinion": -2.0,
				"suspicion": 2.0
			})
			_trigger_camera_shake(0.25, 6.0)
			inspect_status_label.text = "❌ " + tr("UI_FALSE_ACCUSATION_PENALTY")
		elif consecutive_false_inquiries == FALSE_INQUIRY_WARN_THRESHOLD:
			inspect_status_label.text = "⚠️ " + tr("UI_FALSE_ACCUSATION_WARN")
		else:
			inspect_status_label.text = "✗ " + tr("UI_NO_DISCREPANCY")


func _on_violation_uncovered(_violation: Dictionary) -> void:
	_update_reject_button_text()


func _on_approve_pressed() -> void:
	_execute_stamping(true)


func _on_reject_pressed() -> void:
	_execute_stamping(false)


func _execute_stamping(approved: bool) -> void:
	if is_processing_decision or active_document == null or GameManager.active_event == null:
		return

	is_processing_decision = true
	_set_stamps_enabled(false)
	if is_inspect_mode:
		_toggle_inspect_mode()

	# Audio feedback: Heavy physical stamp thud
	AudioManager.play_stamp_thud(approved)

	# Micro-camera shake on desk
	_trigger_camera_shake(0.25, 6.0)

	# Tactile ink stamp slam on document
	active_document.apply_stamp_visual(approved)

	# Evaluate deep deductive outcomes:
	var event: EventData = GameManager.active_event
	var has_viol: bool = event.has_violations()
	var took_bribe: bool = active_document.has_pocketed_bribe

	if approved:
		if has_viol:
			# Corrupt approval of violation
			if took_bribe:
				# Took bribe & approved fraud: Suspicion jumps, approval drops
				GameManager.pocket_bribe(event.bribe_offered, 12.0)
				GameManager.apply_resolution({
					"public_opinion": -15.0,
					"suspicion": 15.0,
					"budget": event.effects_approve.get("budget", 20000)
				})
			else:
				# Negligent approval: approved illegal project without even taking bribe!
				GameManager.apply_resolution({
					"public_opinion": -10.0,
					"suspicion": 10.0,
					"budget": event.effects_approve.get("budget", 15000)
				})
		else:
			# Honest approval of clean petition: good for the city
			GameManager.apply_resolution({
				"public_opinion": 12.0,
				"budget": 20000,
				"suspicion": -5.0
			})
	else:
		# Rejected:
		if has_viol:
			# Valid rejection with cause: Player gets praised for sharp vigilance!
			GameManager.apply_resolution({
				"public_opinion": 15.0,
				"suspicion": -10.0,
				"budget": 0
			})
		else:
			# Wrongful rejection of completely legal petition: Citizens outraged
			GameManager.apply_resolution({
				"public_opinion": -15.0,
				"suspicion": 5.0,
				"budget": 0
			})

	# Record history in GameManager
	var headline_key: String = (
		event.news_headline_approve_key if approved
		else event.news_headline_reject_key
	)
	var record := {
		"day": GameManager.current_day,
		"event_id": event.id,
		"approved": approved,
		"took_bribe": took_bribe,
		"headline_key": headline_key
	}
	GameManager.daily_history.append(record)
	GameManager.event_resolved.emit(event, approved, took_bribe)
	GameManager.event_decided.emit(event.id, approved)

	# Brief delay to let player savor the stamped document
	await get_tree().create_timer(0.45).timeout

	if GameManager.is_game_over:
		return

	# Slide document offscreen to right
	var exit_pos := Vector2(2100, 140)
	active_document.animate_slide_out(exit_pos)
	active_document.slide_out_completed.connect(func():
		_present_next_document()
	)


func _trigger_camera_shake(duration: float, intensity: float) -> void:
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()

	_shake_tween = create_tween()
	var steps: int = int(duration / 0.04)
	for i in range(steps):
		var damp: float = 1.0 - (float(i) / float(steps))
		var offset := Vector2(
			randf_range(-intensity, intensity) * damp,
			randf_range(-intensity, intensity) * damp
		)
		_shake_tween.tween_property(shake_root, "position", offset, 0.04)
	_shake_tween.tween_property(shake_root, "position", Vector2.ZERO, 0.04)


func _on_drawer_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_animate_drawer_pull()
		AudioManager.play_cash_register()
		if active_document != null and not active_document.has_pocketed_bribe:
			if GameManager.active_event and GameManager.active_event.bribe_offered > 0:
				active_document.pocket_bribe()


func _animate_drawer_pull() -> void:
	var tween := create_tween()
	var target_y := safe_drawer_panel.position.y + 16.0
	tween.tween_property(safe_drawer_panel, "position:y", target_y, 0.1)
	tween.tween_property(safe_drawer_panel, "position:y", safe_drawer_panel.position.y, 0.15)


## Quota of daily documents finished -> Deliver Tabloid newspaper
func _on_daily_quota_completed() -> void:
	_set_stamps_enabled(false)
	if is_inspect_mode:
		_toggle_inspect_mode()

	# Autosave progress on shift completion
	SaveLoadManager.save_game("autosave")
	if save_toast != null:
		save_toast.show_toast(GameManager.current_day)

	if active_summary != null and is_instance_valid(active_summary):
		active_summary.queue_free()

	var summary_instance := DAY_SUMMARY_SCENE.instantiate()
	shake_root.add_child(summary_instance)
	active_summary = summary_instance

	summary_instance.populate_summary(GameManager.current_day)
	summary_instance.animate_newspaper_delivery()
	summary_instance.next_day_requested.connect(_on_next_day_pressed)


func _on_next_day_pressed() -> void:
	if active_summary != null and is_instance_valid(active_summary):
		active_summary.queue_free()
		active_summary = null

	GameManager.advance_day()
	EventManager.prepare_daily_queue(4)
	current_shift_minutes = SHIFT_START_MINUTES
	is_overtime = false
	_update_clock_ui()
	_present_next_document()


func _on_game_over(reason_key: String) -> void:
	_set_stamps_enabled(false)
	is_processing_decision = true
	if is_inspect_mode:
		_toggle_inspect_mode()

	# Clean up autosave so players cannot reload into a dead end
	SaveLoadManager.handle_game_over_cleanup()

	if active_game_over != null and is_instance_valid(active_game_over):
		active_game_over.queue_free()

	var modal_instance := GAME_OVER_SCENE.instantiate()
	add_child(modal_instance)
	active_game_over = modal_instance

	modal_instance.show_game_over(reason_key)
	modal_instance.restart_requested.connect(_on_restart_mandate)
	modal_instance.connect("main_menu_requested", Callable(self, "_on_game_over_main_menu"))


func _on_game_over_main_menu() -> void:
	var main_menu_path := "res://scenes/menu/MainMenu.tscn"
	if ResourceLoader.exists(main_menu_path):
		get_tree().change_scene_to_file(main_menu_path)


func _on_restart_mandate() -> void:
	if active_game_over != null and is_instance_valid(active_game_over):
		active_game_over.queue_free()
		active_game_over = null

	if active_summary != null and is_instance_valid(active_summary):
		active_summary.queue_free()
		active_summary = null

	GameManager.start_new_game()
	EventManager.reset_deck()
	EventManager.prepare_daily_queue(4)
	current_shift_minutes = SHIFT_START_MINUTES
	is_overtime = false
	_update_clock_ui()
	_present_next_document()


func _set_stamps_enabled(enabled: bool) -> void:
	btn_stamp_approve.disabled = not enabled
	btn_stamp_reject.disabled = not enabled
	btn_inspect_mode.disabled = not enabled
