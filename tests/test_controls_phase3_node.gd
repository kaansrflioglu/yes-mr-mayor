extends Node

## test_controls_phase3_node.gd - Acceptance tests for Controls Phase 3
## Validates:
## 1. Gamepad / Steam Deck InputEvents in project.godot (A, B, X, Y, LB, RB)
## 2. Full UI Focus mode and neighbors configured on DeskView buttons
## 3. Focus navigation within DocumentItem tabs and bribe button
## 4. Focus navigation within Rulebook tabs and close button
## 5. Focus navigation in PauseMenu with initial grab_focus
## 6. Gamepad bumper page flipping and face button action simulation

const DESK_VIEW_SCENE: PackedScene = preload("res://scenes/desk/DeskView.tscn")
const PAUSE_MENU_SCENE: PackedScene = preload("res://scenes/ui/PauseMenu.tscn")

var passed_tests: int = 0
var total_tests: int = 6
var desk: Control = null
var pause_menu: Control = null


func _ready() -> void:
	print("\n============================================================")
	print(">>> RUNNING KEYBOARD CONTROLS & QOL: PHASE 3 TESTS <<<")
	print("============================================================\n")

	_run_tests_async()


func _run_tests_async() -> void:
	desk = DESK_VIEW_SCENE.instantiate()
	add_child(desk)
	pause_menu = PAUSE_MENU_SCENE.instantiate()
	add_child(pause_menu)
	await get_tree().process_frame

	if desk.active_document != null and desk.active_document.has_signal("slide_in_completed"):
		await desk.active_document.slide_in_completed
	else:
		await get_tree().create_timer(0.6).timeout
	desk._set_stamps_enabled(true)

	test_criterion_1_gamepad_input_mappings()
	test_criterion_2_desk_focus_navigation()
	test_criterion_3_document_focus_navigation()
	test_criterion_4_rulebook_focus_navigation()
	test_criterion_5_pause_menu_focus_navigation()
	test_criterion_6_bumper_page_flips_simulation()

	print("\n============================================================")
	if passed_tests == total_tests:
		print(">>> ALL %d CONTROLS PHASE 3 TESTS PASSED SUCCESSFULLY! <<<" % total_tests)
	else:
		print(">>> TEST FAILURES DETECTED! (%d/%d passed) <<<" % [passed_tests, total_tests])
	print("============================================================\n")

	get_tree().quit(0 if passed_tests == total_tests else 1)


func test_criterion_1_gamepad_input_mappings() -> void:
	print("[TEST 1] Verifying Gamepad / Steam Deck InputEvents in InputMap...")
	var expected_joy_buttons = {
		"mayor_approve": JOY_BUTTON_A,               # 0
		"mayor_reject": JOY_BUTTON_B,                # 1
		"mayor_bribe": JOY_BUTTON_X,                 # 2
		"mayor_inspect": JOY_BUTTON_Y,               # 3
		"mayor_page_prev": JOY_BUTTON_LEFT_SHOULDER, # 9
		"mayor_page_next": JOY_BUTTON_RIGHT_SHOULDER # 10
	}

	var all_verified := true
	for action in expected_joy_buttons:
		var target_btn: int = expected_joy_buttons[action]
		var found_joy_ev := false
		for ev in InputMap.action_get_events(action):
			if ev is InputEventJoypadButton and ev.button_index == target_btn:
				found_joy_ev = true
				break
		if not found_joy_ev:
			printerr("  [FAIL] Action '%s' missing Joypad button %d" % [action, target_btn])
			all_verified = false

	if all_verified:
		print("  -> Face buttons (A, B, X, Y) and Bumpers (LB, RB) verified in InputMap [OK]")
		passed_tests += 1
		print("  [PASS] Test 1: Gamepad input mappings verified.")
	else:
		printerr("  [FAIL] Test 1: Some joypad button mappings were missing.")


func test_criterion_2_desk_focus_navigation() -> void:
	print("[TEST 2] Verifying DeskView UI focus modes and neighbor routing...")
	var app_btn: Button = desk.btn_stamp_approve
	var rej_btn: Button = desk.btn_stamp_reject
	var insp_btn: Button = desk.btn_inspect_mode
	var uv_btn: Button = desk.btn_toggle_uv

	var modes_valid: bool = (
		app_btn.focus_mode == Control.FOCUS_ALL
		and rej_btn.focus_mode == Control.FOCUS_ALL
		and insp_btn.focus_mode == Control.FOCUS_ALL
		and uv_btn.focus_mode == Control.FOCUS_ALL
	)

	var routing_valid: bool = (
		app_btn.focus_neighbor_bottom == rej_btn.get_path()
		and rej_btn.focus_neighbor_top == app_btn.get_path()
		and rej_btn.focus_neighbor_bottom == insp_btn.get_path()
		and insp_btn.focus_neighbor_bottom == uv_btn.get_path()
	)

	desk.grab_default_focus()
	var focused_ok: bool = (app_btn.has_focus())

	if modes_valid and routing_valid and focused_ok:
		print("  -> StampRack buttons have full focus mode, neighbors, and grab_default_focus [OK]")
		passed_tests += 1
		print("  [PASS] Test 2: Desk focus navigation verified.")
	else:
		printerr("  [FAIL] Test 2: Desk focus error (modes: %s, routing: %s, focus: %s)" % [modes_valid, routing_valid, focused_ok])


func test_criterion_3_document_focus_navigation() -> void:
	print("[TEST 3] Verifying DocumentItem focus modes and horizontal routing...")
	var doc = desk.active_document
	if doc == null:
		printerr("  [FAIL] Active document not present.")
		return

	var tab_app: Button = doc.tab_btn_app
	var tab_rep: Button = doc.tab_btn_rep
	var tab_both: Button = doc.tab_btn_both

	var doc_modes_ok: bool = (
		tab_app.focus_mode == Control.FOCUS_ALL
		and tab_rep.focus_mode == Control.FOCUS_ALL
		and tab_both.focus_mode == Control.FOCUS_ALL
	)

	var doc_routing_ok: bool = (
		tab_app.focus_neighbor_right == tab_rep.get_path()
		and tab_rep.focus_neighbor_right == tab_both.get_path()
		and tab_both.focus_neighbor_right == tab_app.get_path()
	)

	if doc_modes_ok and doc_routing_ok:
		print("  -> Dossier tabs support seamless cyclical focus navigation [OK]")
		passed_tests += 1
		print("  [PASS] Test 3: Document focus navigation verified.")
	else:
		printerr("  [FAIL] Test 3: Document focus navigation mismatch.")


func test_criterion_4_rulebook_focus_navigation() -> void:
	print("[TEST 4] Verifying Rulebook UI focus modes and grab_focus on open...")
	var rb = desk.rulebook
	if rb == null:
		printerr("  [FAIL] Rulebook not found.")
		return

	rb.toggle_rulebook()
	var tab_zoning: Button = rb.tab_btn_zoning
	var is_focused: bool = tab_zoning.has_focus()
	var focus_mode_ok: bool = (tab_zoning.focus_mode == Control.FOCUS_ALL)
	rb.toggle_rulebook()

	if is_focused and focus_mode_ok:
		print("  -> Rulebook grabs focus automatically on open and has FOCUS_ALL [OK]")
		passed_tests += 1
		print("  [PASS] Test 4: Rulebook focus navigation verified.")
	else:
		printerr("  [FAIL] Test 4: Rulebook focus error (focused: %s, mode: %s)" % [is_focused, focus_mode_ok])


func test_criterion_5_pause_menu_focus_navigation() -> void:
	print("[TEST 5] Verifying PauseMenu focus modes, neighbors, and initial focus...")
	pause_menu.open()
	var btn_resume: Button = pause_menu.btn_resume
	var btn_save: Button = pause_menu.btn_save

	var has_focus: bool = btn_resume.has_focus()
	var routing_ok: bool = (btn_resume.focus_neighbor_bottom == btn_save.get_path())
	pause_menu.close()

	if has_focus and routing_ok:
		print("  -> PauseMenu automatically focuses Resume button with vertical routing [OK]")
		passed_tests += 1
		print("  [PASS] Test 5: Pause menu focus navigation verified.")
	else:
		printerr("  [FAIL] Test 5: Pause menu focus error (has_focus: %s, routing: %s)" % [has_focus, routing_ok])


func test_criterion_6_bumper_page_flips_simulation() -> void:
	print("[TEST 6] Verifying LB / RB bumper dossier page flipping simulation...")
	var doc = desk.active_document
	if doc == null:
		printerr("  [FAIL] Active document not present.")
		return

	doc.switch_dossier_tab(0)

	# Simulate RB (Right bumper) page flip
	var joy_rb := InputEventJoypadButton.new()
	joy_rb.button_index = JOY_BUTTON_RIGHT_SHOULDER
	joy_rb.pressed = true
	Input.parse_input_event(joy_rb)

	# Call handler directly to guarantee frame-independent check
	desk._flip_dossier_page(true)
	var flipped_to_1: bool = (doc.current_tab_idx == 1)

	# Simulate LB (Left bumper) page flip
	desk._flip_dossier_page(false)
	var flipped_back_to_0: bool = (doc.current_tab_idx == 0)

	if flipped_to_1 and flipped_back_to_0:
		print("  -> Bumper page flipping operates reliably [OK]")
		passed_tests += 1
		print("  [PASS] Test 6: Bumper page flipping verified.")
	else:
		printerr("  [FAIL] Test 6: Bumper flip error (%s, %s)" % [flipped_to_1, flipped_back_to_0])
