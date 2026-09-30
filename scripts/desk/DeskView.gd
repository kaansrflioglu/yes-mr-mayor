extends Control

## DeskView.gd - Primary gameplay canvas for "Yes, Mr. Mayor!"
## Handles multi-document dossier handling, municipal rulebook inspection,
## Papers, Please style deduction / discrepancy spotting, and consequence stamping.

const DOCUMENT_SCENE: PackedScene = preload("res://scenes/desk/DocumentItem.tscn")
const DAY_SUMMARY_SCENE: PackedScene = preload("res://scenes/summary/DayEndSummary.tscn")
const GAME_OVER_SCENE: PackedScene = preload("res://scenes/summary/GameOverModal.tscn")
const REPORT_CARD_SCENE: PackedScene = preload("res://scenes/summary/MayoralReportCardModal.tscn")
const PRESS_CONFERENCE_SCENE: PackedScene = preload("res://scenes/summary/PressConferenceModal.tscn")

@onready var shake_root: Control = %ShakeRoot
@onready var document_drop_zone: Control = %DocumentDropZone
@onready var btn_stamp_approve: Button = %BtnStampApprove
@onready var btn_stamp_reject: Button = %BtnStampReject
@onready var approve_keycap: Control = %ApproveKeycap if has_node("%ApproveKeycap") else null
@onready var reject_keycap: Control = %RejectKeycap if has_node("%RejectKeycap") else null
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
@onready var offshore_ledger_modal: Control = %OffshoreLedgerModal if has_node("%OffshoreLedgerModal") else null
@onready var cigar_box_prop: Control = %CigarBoxProp if has_node("%CigarBoxProp") else null
@onready var yacht_brochure_prop: Control = %YachtBrochureProp if has_node("%YachtBrochureProp") else null
@onready var gold_stamp_badge: Control = %GoldStampBadge if has_node("%GoldStampBadge") else null
@onready var desk_shredder: Control = %DeskShredder if has_node("%DeskShredder") else null
@onready var physical_stamp_rack: Control = %PhysicalStampRack if has_node("%PhysicalStampRack") else null
@onready var district_map_modal: Control = %DistrictMapModal if has_node("%DistrictMapModal") else null
@onready var btn_toggle_map: Button = %BtnToggleMap if has_node("%BtnToggleMap") else null
@onready var prop_espresso_machine: Control = %PropEspressoMachine if has_node("%PropEspressoMachine") else null
@onready var prop_dictaphone: Control = %PropDictaphone if has_node("%PropDictaphone") else null
@onready var campaign_tracker_hud: Control = %CampaignTrackerHUD if has_node("%CampaignTrackerHUD") else null
@onready var election_night_modal: Control = %ElectionNightModal if has_node("%ElectionNightModal") else null

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
var active_press_conference: Control = null
var is_processing_decision: bool = false
var _shake_tween: Tween
var _was_paused_for_modal: bool = false
var _is_restoring_loaded_game: bool = false

# Morning Briefing & Pre-Shift Ritual (Phase 1)
enum DeskState {
	STATE_MORNING_RITUAL,
	STATE_PROCESSING_EVENTS,
	STATE_DAY_END
}

var current_desk_state: DeskState = DeskState.STATE_PROCESSING_EVENTS

@onready var stamp_rack: Control = %StampRack if has_node("%StampRack") else null
@onready var morning_ritual_container: Control = (
	%MorningRitualContainer if has_node("%MorningRitualContainer") else null
)
@onready var morning_briefing_card: Control = (
	%MorningBriefingCard if has_node("%MorningBriefingCard") else null
)
@onready var desk_bell_button: Button = (
	%DeskBellButton if has_node("%DeskBellButton") else null
)
@onready var desk_coffee_mug: Button = (
	%DeskCoffeeMug if has_node("%DeskCoffeeMug") else null
)
@onready var coffee_steam_label: Label = (
	%CoffeeSteamLabel if has_node("%CoffeeSteamLabel") else null
)

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

	if desk_bell_button != null:
		desk_bell_button.pressed.connect(_on_desk_bell_pressed)
	if desk_coffee_mug != null:
		desk_coffee_mug.pressed.connect(_on_coffee_mug_pressed)

	if btn_order_espresso != null:
		btn_order_espresso.pressed.connect(_on_order_espresso_pressed)

	if btn_toggle_uv != null:
		btn_toggle_uv.pressed.connect(toggle_uv_blacklight)

	if red_telephone != null:
		if red_telephone.has_signal("inspector_tip_requested"):
			red_telephone.inspector_tip_requested.connect(_on_inspector_tip_requested)
		if red_telephone.has_signal("whistleblower_tip_revealed"):
			red_telephone.whistleblower_tip_revealed.connect(_on_whistleblower_tip_revealed)

	if desk_shredder != null:
		desk_shredder.shred_requested.connect(_on_shred_requested)

	if physical_stamp_rack != null and physical_stamp_rack.has_signal("stamp_dropped"):
		physical_stamp_rack.stamp_dropped.connect(_on_physical_stamp_dropped)

	if btn_toggle_map != null:
		btn_toggle_map.pressed.connect(_toggle_district_map)

	top_bar_hud.settings_toggle_requested.connect(_toggle_settings)
	top_bar_hud.pause_toggle_requested.connect(_toggle_pause_menu)
	if top_bar_hud.has_signal("twitch_toggle_requested"):
		top_bar_hud.twitch_toggle_requested.connect(_toggle_twitch_overlay)
	if top_bar_hud.has_signal("map_toggle_requested"):
		top_bar_hud.map_toggle_requested.connect(_toggle_district_map)

	DirectiveManager.directive_activated.connect(_on_directive_activated)
	TwitchManager.tool_action_executed.connect(_on_twitch_tool_action)
	DirectiveManager.activate_directive_for_day(GameManager.current_day)
	_update_directive_ui()

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

	if SaveLoadManager != null and not SaveLoadManager.game_loaded.is_connected(_on_game_load_completed):
		SaveLoadManager.game_loaded.connect(_on_game_load_completed)

	rulebook.rule_tag_selected.connect(_on_rule_tag_selected)

	GameManager.game_over.connect(_on_game_over)
	LocalizationManager.locale_changed.connect(_update_locale_texts)
	_update_locale_texts("")

	next_day_box.visible = false
	inspect_status_panel.visible = false
	if GameManager != null and GameManager.has_signal("stats_changed"):
		GameManager.stats_changed.connect(_update_luxury_props)
	_update_luxury_props()
	if SettingsManager != null:
		if SettingsManager.has_signal("hotkey_hints_toggled"):
			SettingsManager.hotkey_hints_toggled.connect(func(_val): _update_hotkey_badges_visibility())
		_update_hotkey_badges_visibility()
	_start_or_continue_shift()

	if AudioManager != null and AudioManager.has_method("set_bgm_context"):
		AudioManager.set_bgm_context("desk", 1.0)
	_setup_focus_navigation()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE):
		_handle_escape_key()
		get_viewport().set_input_as_handled()
		return

	# Gamepad / Keyboard navigation auto-focus when idle
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		var focused := get_viewport().gui_get_focus_owner()
		if focused == null:
			grab_default_focus()

	# If any high-level modal is open, do not process desk gameplay hotkeys
	if _is_any_modal_open():
		return

	# In Morning Ritual state, pressing Space or clicking bell starts shift!
	if current_desk_state == DeskState.STATE_MORNING_RITUAL:
		if event.is_action_pressed("mayor_inspect") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE):
			_on_desk_bell_pressed()
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("mayor_coffee"):
			_on_coffee_mug_pressed()
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("mayor_approve") or event.is_action_pressed("mayor_reject"):
			get_viewport().set_input_as_handled()
			return

	# Twitch overlay toggle
	if event.is_action_pressed("mayor_twitch"):
		_toggle_twitch_overlay()
		get_viewport().set_input_as_handled()
		return

	# Rulebook toggle
	if event.is_action_pressed("mayor_rulebook"):
		_toggle_rulebook()
		get_viewport().set_input_as_handled()
		return

	# District Map Blueprint toggle
	if event.is_action_pressed("mayor_map") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_M):
		_toggle_district_map()
		get_viewport().set_input_as_handled()
		return

	# Rulebook quick-tab shortcuts (1-4)
	if rulebook != null and rulebook.is_open:
		if event.is_action_pressed("mayor_rulebook_tab_1"):
			rulebook.switch_tab(0)
			get_viewport().set_input_as_handled()
			return
		elif event.is_action_pressed("mayor_rulebook_tab_2"):
			rulebook.switch_tab(1)
			get_viewport().set_input_as_handled()
			return
		elif event.is_action_pressed("mayor_rulebook_tab_3"):
			rulebook.switch_tab(2)
			get_viewport().set_input_as_handled()
			return
		elif event.is_action_pressed("mayor_rulebook_tab_4"):
			rulebook.switch_tab(3)
			get_viewport().set_input_as_handled()
			return

	# Red Telephone shortcut (Answer / Hang up / Consultation)
	if event.is_action_pressed("mayor_telephone"):
		_handle_telephone_shortcut()
		get_viewport().set_input_as_handled()
		return

	# Morning Coffee / AP refill
	if event.is_action_pressed("mayor_coffee"):
		_on_order_espresso_pressed()
		get_viewport().set_input_as_handled()
		return

	# UV Blacklight tactical toggle
	if event.is_action_pressed("mayor_uv"):
		toggle_uv_blacklight()
		get_viewport().set_input_as_handled()
		return

	# Discrepancy inspection toggle
	if event.is_action_pressed("mayor_inspect"):
		_toggle_inspect_mode()
		get_viewport().set_input_as_handled()
		return

	# Dossier Page Flipping (Q / E)
	if event.is_action_pressed("mayor_page_prev"):
		_flip_dossier_page(false)
		get_viewport().set_input_as_handled()
		return
	elif event.is_action_pressed("mayor_page_next"):
		_flip_dossier_page(true)
		get_viewport().set_input_as_handled()
		return

	# Core Mayoral Actions (Approve / Reject / Bribe)
	if not _is_desk_action_allowed():
		return

	if event.is_action_pressed("mayor_approve"):
		_on_approve_pressed()
		get_viewport().set_input_as_handled()
		return
	elif event.is_action_pressed("mayor_reject"):
		_on_reject_pressed()
		get_viewport().set_input_as_handled()
		return
	elif event.is_action_pressed("mayor_bribe"):
		_handle_bribe_shortcut()
		get_viewport().set_input_as_handled()
		return
	elif event.is_action_pressed("mayor_shred") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_X):
		_on_shred_requested()
		get_viewport().set_input_as_handled()
		return


func _is_any_modal_open() -> bool:
	if settings_modal != null and settings_modal.is_open:
		return true
	if save_load_modal != null and save_load_modal.is_open:
		return true
	if pause_menu != null and pause_menu.is_open:
		return true
	if offshore_ledger_modal != null and offshore_ledger_modal.visible:
		return true
	if district_map_modal != null and district_map_modal.visible:
		return true
	return false


func _is_desk_action_allowed() -> bool:
	if _is_any_modal_open():
		return false
	if rulebook != null and rulebook.is_open:
		return false
	if red_telephone != null and red_telephone.dialog_panel.visible:
		return false
	if is_processing_decision or active_document == null or GameManager.active_event == null:
		return false
	if btn_stamp_approve == null or not btn_stamp_approve.is_inside_tree() or btn_stamp_approve.disabled:
		return false
	return true


func _handle_telephone_shortcut() -> void:
	if red_telephone == null:
		return
	if red_telephone.is_ringing:
		red_telephone.answer_call()
	elif red_telephone.dialog_panel.visible:
		red_telephone.hang_up()
	else:
		red_telephone.open_consultation_dialog()


func _handle_bribe_shortcut() -> void:
	_animate_drawer_pull()
	if active_document != null and not active_document.has_pocketed_bribe:
		if GameManager.active_event != null and GameManager.active_event.bribe_offered > 0:
			if "btn_pocket_bribe" in active_document and active_document.btn_pocket_bribe != null:
				_animate_button_slam(active_document.btn_pocket_bribe)
			active_document.pocket_bribe()


func _update_hotkey_badges_visibility() -> void:
	var visible_hints: bool = SettingsManager.show_hotkey_hints if SettingsManager != null else true
	if approve_keycap != null:
		approve_keycap.visible = visible_hints
	if reject_keycap != null:
		reject_keycap.visible = visible_hints
	if active_document != null and active_document.has_method("set_keycap_hint_visible"):
		active_document.set_keycap_hint_visible(visible_hints)


func _animate_button_slam(btn: Button) -> void:
	if btn == null or not is_instance_valid(btn):
		return
	var pivot_orig := btn.pivot_offset
	btn.pivot_offset = btn.size * 0.5
	var tween := create_tween()
	tween.tween_property(btn, "scale", Vector2(0.95, 0.95), 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func():
		if is_instance_valid(btn):
			btn.pivot_offset = pivot_orig
	)


func grab_default_focus() -> void:
	if btn_stamp_approve != null and is_instance_valid(btn_stamp_approve) and not btn_stamp_approve.disabled:
		btn_stamp_approve.grab_focus()


func _setup_focus_navigation() -> void:
	var focus_box := StyleBoxFlat.new()
	focus_box.draw_center = false
	focus_box.border_width_left = 3
	focus_box.border_width_top = 3
	focus_box.border_width_right = 3
	focus_box.border_width_bottom = 3
	focus_box.border_color = Color(1.0, 0.85, 0.35, 1.0)
	focus_box.corner_radius_top_left = 6
	focus_box.corner_radius_top_right = 6
	focus_box.corner_radius_bottom_right = 6
	focus_box.corner_radius_bottom_left = 6

	var desk_buttons: Array[Button] = [
		btn_stamp_approve,
		btn_stamp_reject,
		btn_inspect_mode,
		btn_toggle_uv,
		btn_toggle_rulebook
	]
	if btn_order_espresso != null:
		desk_buttons.append(btn_order_espresso)
	if btn_next_day != null:
		desk_buttons.append(btn_next_day)

	for b in desk_buttons:
		if b != null and is_instance_valid(b):
			b.focus_mode = Control.FOCUS_ALL
			b.add_theme_stylebox_override("focus", focus_box)

	# Vertical StampRack navigation chain
	if btn_stamp_approve != null and btn_stamp_reject != null:
		btn_stamp_approve.focus_neighbor_bottom = btn_stamp_reject.get_path()
		btn_stamp_reject.focus_neighbor_top = btn_stamp_approve.get_path()

	if btn_stamp_reject != null and btn_inspect_mode != null:
		btn_stamp_reject.focus_neighbor_bottom = btn_inspect_mode.get_path()
		btn_inspect_mode.focus_neighbor_top = btn_stamp_reject.get_path()

	if btn_inspect_mode != null and btn_toggle_uv != null:
		btn_inspect_mode.focus_neighbor_bottom = btn_toggle_uv.get_path()
		btn_toggle_uv.focus_neighbor_top = btn_inspect_mode.get_path()

	if btn_toggle_uv != null and btn_toggle_rulebook != null:
		btn_toggle_uv.focus_neighbor_bottom = btn_toggle_rulebook.get_path()
		btn_toggle_rulebook.focus_neighbor_top = btn_toggle_uv.get_path()

	if btn_toggle_rulebook != null and btn_order_espresso != null:
		btn_toggle_rulebook.focus_neighbor_bottom = btn_order_espresso.get_path()
		btn_order_espresso.focus_neighbor_top = btn_toggle_rulebook.get_path()

	_connect_document_focus_neighbors(focus_box)


func _connect_document_focus_neighbors(custom_box: StyleBox = null) -> void:
	if active_document == null or not is_instance_valid(active_document):
		return

	if active_document.has_method("setup_focus_mode"):
		active_document.setup_focus_mode(custom_box)

	var doc_bribe: Button = active_document.get_node_or_null("%BtnPocketBribe") as Button
	var doc_tab_both: Button = active_document.get_node_or_null("%TabBtnBoth") as Button
	var target_left: Control = doc_bribe if (doc_bribe != null and doc_bribe.visible and not doc_bribe.disabled) else doc_tab_both

	if target_left != null and is_instance_valid(target_left):
		if btn_stamp_approve != null:
			btn_stamp_approve.focus_neighbor_left = target_left.get_path()
		if btn_stamp_reject != null:
			btn_stamp_reject.focus_neighbor_left = target_left.get_path()
		if btn_stamp_approve != null:
			target_left.focus_neighbor_right = btn_stamp_approve.get_path()


func _flip_dossier_page(forward: bool) -> void:
	if active_document != null and is_instance_valid(active_document):
		if forward:
			active_document.flip_next_page()
		else:
			active_document.flip_prev_page()


func _handle_escape_key() -> void:
	if district_map_modal != null and district_map_modal.visible:
		district_map_modal.close_modal()
	elif settings_modal != null and settings_modal.is_open:
		settings_modal.close()
	elif save_load_modal != null and save_load_modal.is_open:
		save_load_modal.close()
	elif offshore_ledger_modal != null and offshore_ledger_modal.visible:
		offshore_ledger_modal.close()
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
	if district_map_modal != null and district_map_modal.visible:
		district_map_modal.close_modal()
	pause_menu.open()


func _toggle_district_map() -> void:
	if district_map_modal == null:
		return
	if district_map_modal.visible:
		district_map_modal.close_modal()
	else:
		district_map_modal.open_modal()


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
	if _is_restoring_loaded_game:
		return
	_is_restoring_loaded_game = true

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

	# Restore Shift Clock & Stamina State if saved mid-shift
	var saved_shift: Dictionary = SaveLoadManager.last_loaded_shift_state
	if not saved_shift.is_empty():
		current_shift_minutes = int(saved_shift.get("shift_minutes", SHIFT_START_MINUTES))
		is_overtime = bool(saved_shift.get("is_overtime", false))
		current_inspect_focus = int(saved_shift.get("inspect_focus", MAX_INSPECT_FOCUS))
		consecutive_false_inquiries = int(saved_shift.get("consecutive_false_inquiries", 0))
		is_uv_active = bool(saved_shift.get("is_uv_active", false))
	else:
		current_shift_minutes = SHIFT_START_MINUTES
		is_overtime = false
		current_inspect_focus = MAX_INSPECT_FOCUS
		consecutive_false_inquiries = 0
		is_uv_active = false

	_update_clock_ui()
	_update_directive_ui()
	_present_next_document()

	if not saved_shift.is_empty():
		current_inspect_focus = int(saved_shift.get("inspect_focus", MAX_INSPECT_FOCUS))
		consecutive_false_inquiries = int(saved_shift.get("consecutive_false_inquiries", 0))
	_update_focus_ui()

	_is_restoring_loaded_game = false


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
		DirectiveManager.activate_directive_for_day(GameManager.current_day)
		_update_directive_ui()
	_present_next_document()


## Draws and animates the next document onto the desk
func _present_next_document() -> void:
	if GameManager.is_game_over:
		return

	# Reset focus and inquiries for new dossier
	current_inspect_focus = _get_max_focus()
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
	TwitchManager.reset_tool_votes()

	var doc_instance := DOCUMENT_SCENE.instantiate()
	document_drop_zone.add_child(doc_instance)
	active_document = doc_instance

	doc_instance.setup_event(next_event)
	doc_instance.set_uv_blacklight(is_uv_active)
	if doc_instance.has_method("set_keycap_hint_visible") and SettingsManager != null:
		doc_instance.set_keycap_hint_visible(SettingsManager.show_hotkey_hints)
	doc_instance.bribe_pocketed.connect(_on_bribe_pocketed)
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

		# Check Audit Immunity Leak intel
		_check_audit_intel_leak(next_event)
		_connect_document_focus_neighbors()

		# 35% chance to trigger red emergency phone ringing
		if randf() < 0.35 and red_telephone != null:
			red_telephone.ring_telephone()
	)


func _toggle_rulebook() -> void:
	rulebook.toggle_rulebook()


func _toggle_inspect_mode() -> void:
	is_inspect_mode = not is_inspect_mode
	AudioManager.play_inspect_toggle()

	if AudioManager.has_method("play_coffee_clink"):
		AudioManager.play_coffee_clink()
	if AudioManager.has_method("set_inspection_mode_active"):
		AudioManager.set_inspection_mode_active(is_inspect_mode)

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


func _get_max_focus() -> int:
	var base_max: int = MAX_INSPECT_FOCUS
	if GameManager != null and GameManager.event_flags.get("FLAG_EQUIP_ESPRESSO_MACHINE", false):
		base_max += 1
	return base_max


func order_espresso() -> bool:
	if current_inspect_focus >= _get_max_focus():
		return false
	if GameManager.treasury < ESPRESSO_COST:
		return false

	GameManager.treasury -= ESPRESSO_COST
	var new_susp: float = GameManager.suspicion_level + ESPRESSO_SUSPICION_GAIN
	GameManager.suspicion_level = clampf(new_susp, 0.0, 100.0)
	current_inspect_focus = mini(current_inspect_focus + ESPRESSO_FOCUS_RESTORE, _get_max_focus())
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
			"max": _get_max_focus()
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
	var hrs: int = int(float(total_m) / 60.0)
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


## Handles tipline consultation tip from Senior Building Inspector (voluntary, costs shift time)
func _on_inspector_tip_requested() -> void:
	advance_shift_time(PHONE_INQUIRY_TIME_COST_MINUTES)
	_reveal_tip_violation()


## Handles whistleblower / hotline deal tip (free of shift time cost)
func _on_whistleblower_tip_revealed() -> void:
	_reveal_tip_violation()


func _reveal_tip_violation() -> void:
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
		if active_document != null and active_document.has_method("highlight_suspicious_field"):
			var tags: Array = found_viol.get("tags", [])
			var first_tag: String = str(tags[0]) if not tags.is_empty() else ""
			active_document.highlight_suspicious_field(first_tag)
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
	_animate_button_slam(btn_stamp_approve)
	_execute_stamping(true)


func _on_reject_pressed() -> void:
	_animate_button_slam(btn_stamp_reject)
	_execute_stamping(false)


func _on_physical_stamp_dropped(approved: bool, hit_pos: Vector2, hit_rot: float) -> void:
	if is_processing_decision or active_document == null or GameManager.active_event == null:
		return

	var doc_rect := Rect2(active_document.global_position, active_document.size)
	if doc_rect.size.x > 10.0 and doc_rect.size.y > 10.0 and not doc_rect.has_point(hit_pos):
		# Dropped outside document area: no decision
		return

	_execute_stamping_at(hit_pos, hit_rot, approved)


func _on_shred_requested() -> void:
	if is_processing_decision or active_document == null or GameManager.active_event == null:
		return

	is_processing_decision = true
	_set_stamps_enabled(false)
	if is_inspect_mode:
		_toggle_inspect_mode()

	var event: EventData = GameManager.active_event
	var is_sting: bool = event.is_federal_sting or DirectiveManager.is_sting_override()
	var took_bribe: bool = active_document.has_pocketed_bribe

	if desk_shredder != null:
		desk_shredder.execute_shred_animation(active_document)
		desk_shredder.shred_completed.connect(func():
			_complete_shredding(event, is_sting, took_bribe)
		, CONNECT_ONE_SHOT)
	else:
		_complete_shredding(event, is_sting, took_bribe)


func _complete_shredding(event: EventData, is_sting: bool, took_bribe: bool) -> void:
	var res_effects: Dictionary = {}
	if is_sting:
		# Foiled federal entrapment: wiretaps shredded!
		res_effects = {
			"public_opinion": 10.0,
			"suspicion": -20.0
		}
	else:
		var shred_count: int = desk_shredder.daily_shred_count if desk_shredder != null else 1
		var penalty: float = 25.0 if shred_count > 1 else 0.0
		if shred_count > 1:
			GameManager.event_flags["FLAG_SHREDDER_EVIDENCE_TAMPERED"] = true

		var base_susp_drop: float = -20.0 if took_bribe else -15.0
		res_effects = {
			"public_opinion": -5.0 if shred_count > 1 else 0.0,
			"suspicion": base_susp_drop + penalty
		}

	res_effects = DirectiveManager.apply_modifiers(
		res_effects, event, false, took_bribe
	)
	GameManager.apply_resolution(res_effects)

	var record := {
		"day": GameManager.current_day,
		"event_id": event.id,
		"approved": false,
		"took_bribe": took_bribe,
		"shredded": true,
		"headline_key": "NEWS_DOC_SHREDDED"
	}
	GameManager.daily_history.append(record)
	GameManager.event_decided.emit(event.id, false)

	var f_mgr_shred = get_node_or_null("/root/FactionManager")
	if f_mgr_shred != null and f_mgr_shred.has_method("process_decision"):
		f_mgr_shred.process_decision(event, false, took_bribe)

	var e_mgr_shred = get_node_or_null("/root/ElectionManager")
	if e_mgr_shred != null and e_mgr_shred.has_method("process_decision"):
		e_mgr_shred.process_decision(event, false, took_bribe)

	is_processing_decision = false
	_present_next_document()


func _execute_stamping(approved: bool) -> void:
	if active_document == null:
		return
	var center_pos: Vector2 = active_document.global_position + (active_document.size * 0.5)
	var center_rot: float = -0.16 if approved else 0.20
	if physical_stamp_rack != null and physical_stamp_rack.has_method("trigger_hotkey_slam"):
		physical_stamp_rack.trigger_hotkey_slam(approved, center_pos)
	_execute_stamping_at(center_pos, center_rot, approved)


func _execute_stamping_at(target_pos: Vector2, target_rot: float, approved: bool) -> void:
	if is_processing_decision or active_document == null or GameManager.active_event == null:
		return

	is_processing_decision = true
	_set_stamps_enabled(false)
	if is_inspect_mode:
		_toggle_inspect_mode()

	# Audio feedback: Gold stamp clang or heavy physical stamp thud
	if GameManager != null and GameManager.event_flags.get("FLAG_GOLD_STAMP_UNLOCKED", false):
		if AudioManager != null and AudioManager.has_method("play_gold_stamp"):
			AudioManager.play_gold_stamp()
		else:
			AudioManager.play_stamp_thud(approved)
	else:
		AudioManager.play_stamp_thud(approved)

	# Micro-camera shake on desk
	_trigger_camera_shake(0.25, 6.0)

	# Tactile ink stamp slam on document
	if active_document.has_method("apply_stamp_visual_at"):
		active_document.apply_stamp_visual_at(target_pos, target_rot, approved)
	else:
		active_document.apply_stamp_visual(approved)

	# Evaluate deep deductive outcomes:
	var event: EventData = GameManager.active_event
	var has_viol: bool = event.has_violations()
	var took_bribe: bool = active_document.has_pocketed_bribe

	# Fetch base authored effects from EventData
	var base_effects: Dictionary = (
		event.effects_approve.duplicate(true) if approved
		else event.effects_reject.duplicate(true)
	)

	var res_effects: Dictionary = base_effects.duplicate(true)

	# Apply Deductive Context Overlays:
	if approved:
		if has_viol:
			# Corrupt / Negligent approval of a project with known violations:
			# Severe penalty to opinion and spike in suspicion
			var viol_count: int = event.violations.size()
			var opinion_penalty: float = -12.0 * float(viol_count)
			var susp_spike: float = 12.0 * float(viol_count)

			res_effects["public_opinion"] = float(res_effects.get("public_opinion", 0.0)) + opinion_penalty
			res_effects["suspicion"] = float(res_effects.get("suspicion", 0.0)) + susp_spike
			if not took_bribe:
				# Negligent approval: citizens are bewildered why you allowed illegal works for free
				res_effects["public_opinion"] = float(res_effects.get("public_opinion", 0.0)) - 5.0
		else:
			# Honest approval of a fully compliant petition:
			# Bonus civic satisfaction and slight suspicion reduction
			res_effects["public_opinion"] = float(res_effects.get("public_opinion", 0.0)) + 6.0
			res_effects["suspicion"] = float(res_effects.get("suspicion", 0.0)) - 3.0
	else:
		# Rejection logic:
		if has_viol:
			# Valid rejection with cause: Mayor praised for sharp vigilance!
			var discovered_count: int = active_document.discovered_violations.size() if ("discovered_violations" in active_document) else 1
			var vigilance_bonus: float = 8.0 + (float(discovered_count) * 4.0)
			res_effects["public_opinion"] = float(res_effects.get("public_opinion", 0.0)) + vigilance_bonus
			res_effects["suspicion"] = float(res_effects.get("suspicion", 0.0)) - 8.0
		else:
			# Wrongful rejection of legal application: Bureaucratic red-tape outrage!
			res_effects["public_opinion"] = float(res_effects.get("public_opinion", 0.0)) - 10.0
			res_effects["suspicion"] = float(res_effects.get("suspicion", 0.0)) + 4.0

	# Ensure visual flags and unlocked event IDs are preserved
	if base_effects.has("city_visual_flag"):
		res_effects["city_visual_flag"] = base_effects["city_visual_flag"]
	if base_effects.has("city_flag"):
		res_effects["city_flag"] = base_effects["city_flag"]
	if base_effects.has("unlocks_event_id"):
		res_effects["unlocks_event_id"] = base_effects["unlocks_event_id"]

	res_effects = DirectiveManager.apply_modifiers(
		res_effects, event, approved, took_bribe
	)
	GameManager.apply_resolution(res_effects)

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

	var f_mgr_stamp = get_node_or_null("/root/FactionManager")
	if f_mgr_stamp != null and f_mgr_stamp.has_method("process_decision"):
		f_mgr_stamp.process_decision(event, approved, took_bribe)

	var e_mgr_stamp = get_node_or_null("/root/ElectionManager")
	if e_mgr_stamp != null and e_mgr_stamp.has_method("process_decision"):
		e_mgr_stamp.process_decision(event, approved, took_bribe)

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
		if active_document != null and not active_document.has_pocketed_bribe:
			if GameManager.active_event and GameManager.active_event.bribe_offered > 0:
				active_document.pocket_bribe()
		open_offshore_ledger()


## Public method to open the Mayor's offshore safe ledger modal
func open_offshore_ledger() -> void:
	if offshore_ledger_modal != null and offshore_ledger_modal.has_method("open"):
		offshore_ledger_modal.open()


## Checks if Audit Immunity Leak intel is active and reveals violations on incoming documents
func _check_audit_intel_leak(event: EventData) -> void:
	if event == null:
		return
	var charges: int = int(GameManager.event_flags.get("AUDIT_LEAK_REMAINING", 0))
	if charges <= 0:
		return
	if not event.has_violations():
		return

	# Consume 1 charge for this violating document
	charges -= 1
	GameManager.event_flags["AUDIT_LEAK_REMAINING"] = charges
	GameManager.notify_stats_changed()

	# Auto-reveal first hidden violation
	var found_viol: Dictionary = event.violations[0]
	if active_document != null and active_document.has_method("mark_violation_found"):
		active_document.mark_violation_found(found_viol)
	if active_document != null and active_document.has_method("highlight_suspicious_field"):
		var tags: Array = found_viol.get("tags", [])
		var first_tag: String = str(tags[0]) if not tags.is_empty() else ""
		active_document.highlight_suspicious_field(first_tag)

	inspect_status_panel.visible = true
	var viol_name: String = tr(str(found_viol.get("name_key", "VIOL_HEIGHT_LIMIT")))
	inspect_status_label.text = "🕵️ " + tr("UI_AUDIT_LEAK_TRIGGERED").format({
		"violation": viol_name,
		"remaining": charges
	})
	AudioManager.play_discrepancy_match()
	_update_reject_button_text()


## Updates visual luxury props on the mayoral desk based on unlocked event flags
func _update_luxury_props() -> void:
	var flags: Dictionary = GameManager.event_flags if GameManager != null else {}
	if cigar_box_prop != null:
		cigar_box_prop.visible = bool(flags.get("FLAG_CIGAR_BOX_UNLOCKED", false))
	if yacht_brochure_prop != null:
		yacht_brochure_prop.visible = bool(flags.get("FLAG_YACHT_BROCHURE_UNLOCKED", false))
	if gold_stamp_badge != null:
		gold_stamp_badge.visible = bool(flags.get("FLAG_GOLD_STAMP_UNLOCKED", false))
	if prop_espresso_machine != null:
		prop_espresso_machine.visible = bool(flags.get("FLAG_EQUIP_ESPRESSO_MACHINE", false))
	if prop_dictaphone != null:
		prop_dictaphone.visible = bool(flags.get("FLAG_EQUIP_DICTAPHONE", false))


func _on_bribe_pocketed(amount: int) -> void:
	var event: EventData = GameManager.active_event
	if event == null:
		return

	var is_sting: bool = event.is_federal_sting or DirectiveManager.is_sting_override()
	if is_sting:
		AudioManager.play_alarm_siren()
		_trigger_camera_shake(0.5, 16.0)
		GameManager.pocket_bribe(amount, 25.0)
		inspect_status_panel.visible = true
		inspect_status_label.text = "🚨 " + tr("UI_FEDERAL_STING_ALERT")
	else:
		AudioManager.play_cash_register()
		var susp_mult: float = float(DirectiveManager.get_active_directive().get(
			"suspicion_mult", 1.0
		))
		GameManager.pocket_bribe(amount, 3.0 * susp_mult)


## Public method allowing DeskView or external tools to consult the Red Phone
func consult_red_phone() -> bool:
	if red_telephone != null and red_telephone.has_method("consult_inspector"):
		return red_telephone.consult_inspector()
	return false


func _toggle_twitch_overlay() -> void:
	if twitch_overlay != null and twitch_overlay.has_method("toggle_overlay"):
		twitch_overlay.toggle_overlay()


func _on_twitch_tool_action(tool_name: String) -> void:
	match tool_name:
		"uv":
			toggle_uv_blacklight()
		"phone":
			consult_red_phone()
		"coffee":
			order_espresso()
		"inspect":
			_toggle_inspect_mode()


func _update_directive_ui() -> void:
	if top_bar_hud != null and top_bar_hud.has_method("set_directive_text"):
		var title: String = DirectiveManager.get_active_title()
		var desc: String = DirectiveManager.get_active_desc()
		top_bar_hud.set_directive_text(title, desc)


func _on_directive_activated(_directive: Dictionary) -> void:
	_update_directive_ui()


func _animate_drawer_pull() -> void:
	var tween := create_tween()
	var target_y := safe_drawer_panel.position.y + 16.0
	tween.tween_property(safe_drawer_panel, "position:y", target_y, 0.1)
	tween.tween_property(safe_drawer_panel, "position:y", safe_drawer_panel.position.y, 0.15)


## Quota of daily documents finished -> Deliver Tabloid newspaper (or Weekly Press Conference)
func _on_daily_quota_completed() -> void:
	current_desk_state = DeskState.STATE_DAY_END
	_set_stamps_enabled(false)
	if is_inspect_mode:
		_toggle_inspect_mode()

	# Autosave progress on shift completion
	SaveLoadManager.save_game("autosave")
	if save_toast != null:
		save_toast.show_toast(GameManager.current_day)

	if _should_trigger_press_conference():
		_start_press_conference()
	else:
		_present_newspaper_summary()


func _should_trigger_press_conference() -> bool:
	return (GameManager.current_day % 5 == 0) or (GameManager.suspicion_level >= 70.0)


func _start_press_conference() -> void:
	if active_press_conference != null and is_instance_valid(active_press_conference):
		active_press_conference.queue_free()

	var conf = PRESS_CONFERENCE_SCENE.instantiate()
	add_child(conf)
	active_press_conference = conf
	conf.conference_finished.connect(func():
		_present_newspaper_summary()
	)
	conf.start_conference(GameManager.daily_history)


func _present_newspaper_summary() -> void:
	if GameManager.current_day >= GameManager.MAX_DAYS and election_night_modal != null:
		election_night_modal.election_completed.connect(func(won: bool):
			if won:
				GameManager.apply_resolution({"public_opinion": 10.0})
				GameManager._trigger_game_end("END_REELECTED")
			else:
				GameManager._trigger_game_end("END_LOST_ELECTION")
		, CONNECT_ONE_SHOT)
		election_night_modal.start_election_tally()
		return

	if active_summary != null and is_instance_valid(active_summary):
		active_summary.queue_free()

	var summary_instance := DAY_SUMMARY_SCENE.instantiate()
	shake_root.add_child(summary_instance)
	active_summary = summary_instance

	summary_instance.populate_summary(GameManager.current_day)
	summary_instance.animate_newspaper_delivery()
	summary_instance.next_day_requested.connect(_on_next_day_pressed)

	if AudioManager != null and AudioManager.has_method("set_bgm_context"):
		AudioManager.set_bgm_context("summary", 0.8)


func _on_next_day_pressed() -> void:
	if active_summary != null and is_instance_valid(active_summary):
		active_summary.queue_free()
		active_summary = null

	GameManager.advance_day()
	enter_morning_ritual()


## Enters the morning office pre-shift ritual: hides stamps, spawns post-it memo & brass bell, plays sunrise
func enter_morning_ritual() -> void:
	current_desk_state = DeskState.STATE_MORNING_RITUAL

	if active_document != null and is_instance_valid(active_document):
		active_document.queue_free()
		active_document = null

	EventManager.prepare_daily_queue(4)
	current_shift_minutes = SHIFT_START_MINUTES
	is_overtime = false
	if desk_shredder != null:
		desk_shredder.reset_day()
	_update_clock_ui()
	DirectiveManager.activate_directive_for_day(GameManager.current_day)
	_update_directive_ui()

	# 1. Hide stamp rack & buttons
	_set_stamps_visible(false)

	# 2. Trigger morning sunrise window tint transition in SkylineView
	if skyline_view != null and skyline_view.has_method("play_morning_sunrise_transition"):
		skyline_view.play_morning_sunrise_transition()
	elif skyline_view != null:
		skyline_view.daily_time_progress = 0.0
		skyline_view.update_skyline()

	# 3. Setup and spawn Morning Post-It Memo & Brass Bell on desk center
	if morning_ritual_container != null:
		morning_ritual_container.visible = true
		if morning_briefing_card != null and morning_briefing_card.has_method("setup_briefing"):
			morning_briefing_card.setup_briefing(GameManager.current_day)
			morning_briefing_card.slide_in()

	if AudioManager != null and AudioManager.has_method("set_bgm_context"):
		AudioManager.set_bgm_context("desk", 1.0)


func _on_desk_bell_pressed() -> void:
	if current_desk_state != DeskState.STATE_MORNING_RITUAL:
		return

	if AudioManager != null and AudioManager.has_method("play_desk_bell"):
		AudioManager.play_desk_bell()

	_animate_bell_ring()
	_dismiss_morning_ritual()


func _animate_bell_ring() -> void:
	if desk_bell_button != null:
		var tween := create_tween()
		tween.tween_property(desk_bell_button, "scale", Vector2(1.15, 0.85), 0.08)
		tween.tween_property(desk_bell_button, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_ELASTIC)


func _dismiss_morning_ritual() -> void:
	current_desk_state = DeskState.STATE_PROCESSING_EVENTS
	_set_stamps_visible(true)

	if morning_ritual_container != null:
		if morning_briefing_card != null and morning_briefing_card.has_method("slide_out"):
			var card_tween: Tween = morning_briefing_card.slide_out()
			card_tween.chain().tween_callback(func():
				morning_ritual_container.visible = false
				_present_next_document()
			)
		else:
			morning_ritual_container.visible = false
			_present_next_document()
	else:
		_present_next_document()


func _on_coffee_mug_pressed() -> void:
	if AudioManager != null and AudioManager.has_method("play_coffee_sip"):
		AudioManager.play_coffee_sip()
	if AudioManager != null and AudioManager.has_method("play_coffee_clink"):
		AudioManager.play_coffee_clink()

	if desk_coffee_mug != null:
		# Pleasant sip tilt and bounce animation
		var tween := create_tween().set_parallel(true)
		tween.tween_property(desk_coffee_mug, "scale", Vector2(1.15, 1.15), 0.12).set_trans(Tween.TRANS_BACK)
		tween.tween_property(desk_coffee_mug, "rotation", -0.08, 0.12)
		if coffee_steam_label != null:
			# Steam fades away smoothly on sip
			tween.tween_property(coffee_steam_label, "modulate:a", 0.0, 0.15)

		var chain_tween := create_tween()
		chain_tween.tween_interval(0.18)
		chain_tween.tween_property(desk_coffee_mug, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_ELASTIC)
		chain_tween.parallel().tween_property(desk_coffee_mug, "rotation", 0.0, 0.2)
		if coffee_steam_label != null:
			# Steam slowly fades back in as coffee stays warm
			chain_tween.parallel().tween_property(coffee_steam_label, "modulate:a", 1.0, 0.6)

	# Refill / set starting focus to max
	current_inspect_focus = _get_max_focus()
	_update_focus_ui()


func _set_stamps_visible(vis: bool) -> void:
	if stamp_rack != null:
		stamp_rack.visible = vis
	else:
		btn_stamp_approve.visible = vis
		btn_stamp_reject.visible = vis
		btn_inspect_mode.visible = vis


func _on_game_over(reason_key: String) -> void:
	_set_stamps_enabled(false)
	is_processing_decision = true
	if is_inspect_mode:
		_toggle_inspect_mode()

	# Clean up autosave so players cannot reload into a dead end
	SaveLoadManager.handle_game_over_cleanup()

	if AudioManager != null and AudioManager.has_method("set_bgm_context"):
		AudioManager.set_bgm_context("game_over", 1.5)

	if active_game_over != null and is_instance_valid(active_game_over):
		active_game_over.queue_free()

	var is_mandate_end: bool = (
		GameManager.current_day >= GameManager.MAX_DAYS
		or reason_key in [
			"END_REELECTED", "END_SAINT", "END_TEFLON_DON", "END_ECO_UTOPIA",
			"END_CORPORATE_PUPPET", "END_MOB_VICEROY", "END_SHADOW_JUNTA",
			"END_AUSTERE_ACCOUNTANT", "END_ONE_TERM_MEDIOCRE", "END_CAYMAN_EXILE"
		]
	)

	var modal_instance: Control = null
	if is_mandate_end:
		modal_instance = REPORT_CARD_SCENE.instantiate()
	else:
		modal_instance = GAME_OVER_SCENE.instantiate()

	add_child(modal_instance)
	active_game_over = modal_instance

	modal_instance.show_game_over(reason_key)
	modal_instance.restart_requested.connect(_on_restart_mandate)
	modal_instance.connect("main_menu_requested", Callable(self, "_on_game_over_main_menu"))


## Explicitly displays Mayoral Report Card with evaluation data
func show_report_card(eval_dict: Dictionary = {}) -> void:
	if active_game_over != null and is_instance_valid(active_game_over):
		active_game_over.queue_free()

	var modal_instance := REPORT_CARD_SCENE.instantiate()
	add_child(modal_instance)
	active_game_over = modal_instance

	if eval_dict.is_empty() and EndingsManager != null:
		eval_dict = EndingsManager.evaluate_mandate()

	modal_instance.show_report_card(eval_dict)
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
	DirectiveManager.reset_state()
	DirectiveManager.activate_directive_for_day(1)
	_update_directive_ui()
	_present_next_document()


func _set_stamps_enabled(enabled: bool) -> void:
	btn_stamp_approve.disabled = not enabled
	btn_stamp_reject.disabled = not enabled
	btn_inspect_mode.disabled = not enabled
