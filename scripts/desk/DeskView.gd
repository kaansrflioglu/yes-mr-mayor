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

var active_document: Control = null
var active_summary: Control = null
var active_game_over: Control = null
var is_processing_decision: bool = false
var _shake_tween: Tween

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
	top_bar_hud.settings_toggle_requested.connect(_toggle_settings)
	if settings_modal != null:
		settings_modal.set_twitch_overlay_reference(twitch_overlay)
		settings_modal.twitch_overlay_toggle_requested.connect(
			func(): twitch_overlay.toggle_overlay()
		)

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
		elif event.keycode == KEY_TAB:
			_toggle_rulebook()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			_handle_escape_key()
			get_viewport().set_input_as_handled()


func _handle_escape_key() -> void:
	if settings_modal != null and settings_modal.is_open:
		settings_modal.close()
	elif rulebook != null and rulebook.is_open:
		rulebook.toggle_rulebook()
	else:
		_toggle_settings()


func _toggle_settings() -> void:
	if settings_modal == null:
		return
	if settings_modal.is_open:
		settings_modal.close()
	else:
		settings_modal.open()


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
	_present_next_document()


## Draws and animates the next document onto the desk
func _present_next_document() -> void:
	if GameManager.is_game_over:
		return

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

	var match_viol: Dictionary = GameManager.active_event.find_matching_violation(token_a, token_b)

	if not match_viol.is_empty():
		# DISCREPANCY DETECTED!
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
		AudioManager.play_discrepancy_fail()
		inspect_status_panel.visible = true
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
	_present_next_document()


## Game over condition met
func _on_game_over(reason_key: String) -> void:
	_set_stamps_enabled(false)
	is_processing_decision = true
	if is_inspect_mode:
		_toggle_inspect_mode()

	if active_game_over != null and is_instance_valid(active_game_over):
		active_game_over.queue_free()

	var modal_instance := GAME_OVER_SCENE.instantiate()
	add_child(modal_instance)
	active_game_over = modal_instance

	modal_instance.show_game_over(reason_key)
	modal_instance.restart_requested.connect(_on_restart_mandate)


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
	_present_next_document()


func _set_stamps_enabled(enabled: bool) -> void:
	btn_stamp_approve.disabled = not enabled
	btn_stamp_reject.disabled = not enabled
	btn_inspect_mode.disabled = not enabled
