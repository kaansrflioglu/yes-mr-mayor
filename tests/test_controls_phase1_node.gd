extends Node

## test_controls_phase1_node.gd - Acceptance tests for Controls Phase 1
## Validates:
## 1. InputMap has all mayor_* actions defined
## 2. Page flipping (Q / E) cycles document tabs
## 3. Keyboard bribe pocketing (S / B)
## 4. Input guarding prevents stamp actions when modal/rulebook open
## 5. Red phone keyboard handling (T)
## 6. Rulebook tab shortcuts (1-4)

const DESK_VIEW_SCENE: PackedScene = preload("res://scenes/desk/DeskView.tscn")

var passed_tests: int = 0
var total_tests: int = 6
var desk: Control = null


func _ready() -> void:
	print("\n============================================================")
	print(">>> RUNNING KEYBOARD CONTROLS & QOL: PHASE 1 TESTS <<<")
	print("============================================================\n")

	_run_tests_async()


func _run_tests_async() -> void:
	desk = DESK_VIEW_SCENE.instantiate()
	add_child(desk)
	await get_tree().process_frame

	if desk.active_document != null and desk.active_document.has_signal("slide_in_completed"):
		await desk.active_document.slide_in_completed
	else:
		await get_tree().create_timer(0.6).timeout
	desk._set_stamps_enabled(true)

	test_criterion_1_input_map_actions()
	test_criterion_2_page_flipping()
	test_criterion_3_bribe_shortcut()
	test_criterion_4_input_guarding()
	test_criterion_5_telephone_shortcut()
	test_criterion_6_rulebook_tab_shortcuts()

	print("\n============================================================")
	if passed_tests == total_tests:
		print(">>> ALL %d CONTROLS PHASE 1 TESTS PASSED SUCCESSFULLY! <<<" % total_tests)
	else:
		print(">>> TEST FAILURES DETECTED! (%d/%d passed) <<<" % [passed_tests, total_tests])
	print("============================================================\n")

	get_tree().quit(0 if passed_tests == total_tests else 1)


func test_criterion_1_input_map_actions() -> void:
	print("[TEST 1] Verifying all mayor_* actions registered in InputMap...")
	var expected_actions := [
		"mayor_approve", "mayor_reject", "mayor_bribe", "mayor_inspect",
		"mayor_rulebook", "mayor_page_prev", "mayor_page_next",
		"mayor_telephone", "mayor_coffee", "mayor_uv",
		"mayor_rulebook_tab_1", "mayor_rulebook_tab_2",
		"mayor_rulebook_tab_3", "mayor_rulebook_tab_4", "mayor_twitch"
	]

	var all_found := true
	for action in expected_actions:
		if not InputMap.has_action(action):
			print("  [FAIL] Missing action: ", action)
			all_found = false

	if all_found:
		print("  -> All %d actions verified in InputMap [OK]" % expected_actions.size())
		passed_tests += 1
		print("  [PASS] Test 1: InputMap actions verified.")
	else:
		printerr("  [FAIL] Test 1: Some actions were missing in InputMap.")


func test_criterion_2_page_flipping() -> void:
	print("[TEST 2] Verifying dossier page flipping (Q / E shortcuts)...")
	var doc = desk.active_document
	if doc == null:
		printerr("  [FAIL] No active document present.")
		return

	# Initial tab is 0 (Application)
	doc.switch_dossier_tab(0)
	if doc.current_tab_idx != 0:
		printerr("  [FAIL] Initial tab index is not 0.")
		return

	desk._flip_dossier_page(true) # Next (E)
	var tab_after_next = doc.current_tab_idx
	desk._flip_dossier_page(true) # Next (E)
	var tab_after_next_2 = doc.current_tab_idx
	desk._flip_dossier_page(true) # Next (E)
	var tab_cycle_back = doc.current_tab_idx

	desk._flip_dossier_page(false) # Prev (Q)
	var tab_prev = doc.current_tab_idx

	if tab_after_next == 1 and tab_after_next_2 == 2 and tab_cycle_back == 0 and tab_prev == 2:
		print("  -> Page flipping cycle confirmed: 0 -> 1 -> 2 -> 0 -> 2 [OK]")
		passed_tests += 1
		print("  [PASS] Test 2: Dossier page flipping verified.")
	else:
		printerr("  [FAIL] Test 2: Page flip indices mismatch (%d, %d, %d, %d)" % [tab_after_next, tab_after_next_2, tab_cycle_back, tab_prev])


func test_criterion_3_bribe_shortcut() -> void:
	print("[TEST 3] Verifying bribe pocketing shortcut (S / B)...")
	var doc = desk.active_document
	if doc == null:
		printerr("  [FAIL] No active document.")
		return

	# Create a dummy event with bribe to test pocketing
	var fake_event := EventData.new()
	fake_event.id = "test_bribe_event"
	fake_event.bribe_offered = 25000
	fake_event.category = "COMMERCIAL"
	GameManager.active_event = fake_event
	doc.setup_event(fake_event)

	if doc.has_pocketed_bribe:
		printerr("  [FAIL] Bribe already pocketed before action.")
		return

	desk._handle_bribe_shortcut()

	if doc.has_pocketed_bribe:
		print("  -> Bribe pocketed via shortcut [OK]")
		passed_tests += 1
		print("  [PASS] Test 3: Bribe pocketing shortcut verified.")
	else:
		printerr("  [FAIL] Test 3: Bribe was not pocketed.")


func test_criterion_4_input_guarding() -> void:
	print("[TEST 4] Verifying input guarding when modals or rulebook are open...")
	# Normally desk action is allowed
	var initial_allowed: bool = desk._is_desk_action_allowed()

	# Open rulebook
	desk.rulebook.toggle_rulebook()
	var rulebook_blocking: bool = not desk._is_desk_action_allowed()
	desk.rulebook.toggle_rulebook() # close rulebook

	# Open red telephone dialog
	desk.red_telephone.open_consultation_dialog()
	var phone_blocking: bool = not desk._is_desk_action_allowed()
	desk.red_telephone.hang_up() # close phone

	if initial_allowed and rulebook_blocking and phone_blocking:
		print("  -> Input guarding properly blocks actions during open overlays [OK]")
		passed_tests += 1
		print("  [PASS] Test 4: Input guarding verified.")
	else:
		printerr("  [FAIL] Test 4: Input guarding failed (init: %s, rulebook: %s, phone: %s)" % [initial_allowed, rulebook_blocking, phone_blocking])


func test_criterion_5_telephone_shortcut() -> void:
	print("[TEST 5] Verifying red telephone shortcut (T)...")
	var phone = desk.red_telephone
	if phone == null:
		printerr("  [FAIL] RedTelephone not found.")
		return

	# Case A: Idle phone -> shortcut opens consultation dialog
	desk._handle_telephone_shortcut()
	var dialog_opened: bool = phone.dialog_panel.visible

	# Case B: Open dialog -> shortcut hangs up / closes dialog
	desk._handle_telephone_shortcut()
	var dialog_closed: bool = not phone.dialog_panel.visible

	# Case C: Ringing phone -> shortcut answers call
	phone.is_ringing = true
	desk._handle_telephone_shortcut()
	var answered: bool = (not phone.is_ringing and phone.dialog_panel.visible)
	phone.hang_up()

	if dialog_opened and dialog_closed and answered:
		print("  -> Phone shortcut covers idle consultation, hangup, and answering [OK]")
		passed_tests += 1
		print("  [PASS] Test 5: Telephone shortcut verified.")
	else:
		printerr("  [FAIL] Test 5: Telephone shortcut state error (open: %s, close: %s, answer: %s)" % [dialog_opened, dialog_closed, answered])


func test_criterion_6_rulebook_tab_shortcuts() -> void:
	print("[TEST 6] Verifying Rulebook tab selection shortcuts (1-4)...")
	var rb = desk.rulebook
	if rb == null:
		printerr("  [FAIL] Rulebook not found.")
		return

	rb.toggle_rulebook() # Open rulebook
	rb.switch_tab(3) # Switch to tab 3 (Orders)
	var tab_3_active: bool = rb.page_orders.visible and not rb.page_zoning.visible
	rb.switch_tab(1) # Switch to tab 1 (Seals)
	var tab_1_active: bool = rb.page_seals.visible and not rb.page_orders.visible
	rb.switch_tab(0) # Switch to tab 0 (Zoning)
	var tab_0_active: bool = rb.page_zoning.visible and not rb.page_seals.visible
	rb.toggle_rulebook() # Close rulebook

	if tab_3_active and tab_1_active and tab_0_active:
		print("  -> Rulebook tab navigation verified [OK]")
		passed_tests += 1
		print("  [PASS] Test 6: Rulebook tab shortcuts verified.")
	else:
		printerr("  [FAIL] Test 6: Rulebook tab active state mismatch.")
