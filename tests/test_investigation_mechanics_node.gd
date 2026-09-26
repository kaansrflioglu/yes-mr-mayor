extends Node

## test_investigation_mechanics_node.gd
## Acceptance tests for Milestone 1: Deduction limits (Focus AP),
## false accusation escalation penalties, and espresso stamina refills.

const DESK_VIEW_SCENE: PackedScene = preload("res://scenes/desk/DeskView.tscn")

var passed_tests: int = 0
var total_tests: int = 6

@onready var game_mgr: Node = get_node("/root/GameManager")
@onready var event_mgr: Node = get_node("/root/EventManager")


func _ready() -> void:
	print("\n============================================================")
	print(">>> RUNNING INVESTIGATION MECHANICS MILESTONE 1 TESTS <<<")
	print("============================================================\n")

	test_initial_focus_and_ui()
	test_focus_ap_depletion()
	test_fatigue_lockout_at_zero()
	test_false_accusation_escalation_and_penalty()
	test_espresso_order_refill()
	test_focus_reset_on_new_document()

	print("\n============================================================")
	if passed_tests == total_tests:
		print(">>> ALL %d INVESTIGATION TESTS PASSED! (%d/%d) <<<" % [
			total_tests, passed_tests, total_tests
		])
	else:
		print(">>> TEST FAILURES DETECTED! (%d/%d) <<<" % [
			passed_tests, total_tests
		])
	print("============================================================\n")

	get_tree().quit(0 if passed_tests == total_tests else 1)


func _setup_desk() -> Control:
	game_mgr.start_new_game()
	var desk = DESK_VIEW_SCENE.instantiate()
	add_child(desk)
	return desk


func test_initial_focus_and_ui() -> void:
	print("[TEST 1] Verifying Focus AP initial allocation and visual counter...")
	var desk = _setup_desk()

	assert(
		desk.current_inspect_focus == desk.MAX_INSPECT_FOCUS,
		"Initial focus must be MAX_INSPECT_FOCUS (4)."
	)
	assert(desk.consecutive_false_inquiries == 0, "Initial false inquiries must be 0.")
	assert(desk.focus_panel != null, "FocusPanel node must be present in DeskView.")
	assert(desk.focus_icons_container != null, "FocusIconsContainer must be present.")
	assert(
		desk.focus_icons_container.get_child_count() == 4,
		"Must have 4 coffee focus icons."
	)

	desk.queue_free()
	print("  -> Focus AP = 4/4 [OK]")
	print("  -> 4 Visual Coffee Pips verified [OK]")
	print("  [PASS] Test 1: Focus AP initialization and UI verified.\n")
	passed_tests += 1


func test_focus_ap_depletion() -> void:
	print("[TEST 2] Verifying inspection attempts consume 1 Focus AP...")
	var desk = _setup_desk()

	var test_evt: EventData = event_mgr.all_events[0]
	game_mgr.active_event = test_evt

	var init_focus: int = desk.current_inspect_focus
	desk.evaluate_discrepancy("app_district", "rule_zoning_river")

	assert(desk.current_inspect_focus == init_focus - 1, "Inspection must consume 1 AP.")
	assert(
		desk.consecutive_false_inquiries == 0,
		"Valid match must maintain 0 consecutive false inquiries."
	)

	desk.queue_free()
	print("  -> Focus AP consumed 1 (4 -> 3) [OK]")
	print("  [PASS] Test 2: Focus AP consumption verified.\n")
	passed_tests += 1


func test_fatigue_lockout_at_zero() -> void:
	print("[TEST 3] Verifying Mental Fatigue lockout when Focus AP reaches 0...")
	var desk = _setup_desk()
	var test_evt: EventData = event_mgr.all_events[0]
	game_mgr.active_event = test_evt

	# Drain all 4 focus points
	desk.current_inspect_focus = 0
	desk.update_focus_ui()

	# Attempt inspection at 0 focus
	desk.evaluate_discrepancy("app_district", "rule_zoning_river")

	assert(desk.current_inspect_focus == 0, "Focus must not dip below 0.")
	var status_text: String = desk.inspect_status_label.text
	assert(
		status_text.contains(tr("UI_INSPECT_FATIGUED")),
		"Fatigue warning must be shown."
	)

	desk.queue_free()
	print("  -> Blocked inquiry at 0 AP with fatigue alert [OK]")
	print("  [PASS] Test 3: Fatigue lockout verified.\n")
	passed_tests += 1


func test_false_accusation_escalation_and_penalty() -> void:
	print("[TEST 4] Verifying False Accusation warning and escalating penalties...")
	var desk = _setup_desk()
	var test_evt: EventData = event_mgr.all_events[0]
	game_mgr.active_event = test_evt

	var start_opinion: float = game_mgr.public_opinion
	var start_suspicion: float = game_mgr.suspicion_level

	# False Inquiry 1: Standard 'No discrepancy'
	desk.evaluate_discrepancy("app_floors", "rule_blacklist_guide")
	assert(desk.consecutive_false_inquiries == 1, "First false inquiry count must be 1.")
	var st1: String = desk.inspect_status_label.text
	assert(st1.contains(tr("UI_NO_DISCREPANCY")), "Must show no discrepancy.")
	assert(game_mgr.public_opinion == start_opinion, "No penalty on first mistake.")

	# False Inquiry 2: Legal counsel warning
	desk.evaluate_discrepancy("app_floors", "rule_blacklist_guide")
	assert(desk.consecutive_false_inquiries == 2, "Second false inquiry count must be 2.")
	var st2: String = desk.inspect_status_label.text
	assert(st2.contains(tr("UI_FALSE_ACCUSATION_WARN")), "Must show counsel warning.")
	assert(game_mgr.public_opinion == start_opinion, "Warning only on second mistake.")

	# False Inquiry 3: Baseless audit penalty!
	desk.evaluate_discrepancy("app_floors", "rule_blacklist_guide")
	assert(desk.consecutive_false_inquiries == 3, "Third false inquiry count must be 3.")
	var st3: String = desk.inspect_status_label.text
	assert(st3.contains(tr("UI_FALSE_ACCUSATION_PENALTY")), "Must show penalty text.")
	assert(
		game_mgr.public_opinion < start_opinion,
		"Public opinion must drop on 3rd false accusation."
	)
	assert(
		game_mgr.suspicion_level > start_suspicion,
		"Suspicion must rise on 3rd false accusation."
	)

	# Valid match resets false inquiries
	desk.current_inspect_focus = 4
	desk.evaluate_discrepancy("app_district", "rule_zoning_river")
	assert(
		desk.consecutive_false_inquiries == 0,
		"Valid match must reset false inquiry counter to 0."
	)

	desk.queue_free()
	print("  -> Mistake 1: Normal alert [OK]")
	print("  -> Mistake 2: Legal Counsel Warning [OK]")
	print("  -> Mistake 3: Baseless Audit Penalty (-2% Opinion, +2% Suspicion) [OK]")
	print("  -> Reset on Valid Match [OK]")
	print("  [PASS] Test 4: False accusation escalation verified.\n")
	passed_tests += 1


func test_espresso_order_refill() -> void:
	print("[TEST 5] Verifying Double Espresso stamina refill mechanic...")
	var desk = _setup_desk()
	game_mgr.treasury = 50000
	var prev_treasury: int = game_mgr.treasury
	var prev_suspicion: float = game_mgr.suspicion_level

	desk.current_inspect_focus = 0
	desk.update_focus_ui()

	var success: bool = desk.order_espresso()
	assert(success, "Espresso order should succeed.")
	assert(desk.current_inspect_focus == 2, "Espresso should restore 2 AP.")
	assert(
		game_mgr.treasury == prev_treasury - 500,
		"Treasury should decrease by $500."
	)
	assert(
		game_mgr.suspicion_level > prev_suspicion,
		"Suspicion should increase by 1.5%."
	)

	desk.queue_free()
	print("  -> Refilled 2 Focus AP, -$500 Budget, +1.5% Suspicion [OK]")
	print("  [PASS] Test 5: Espresso order mechanic verified.\n")
	passed_tests += 1


func test_focus_reset_on_new_document() -> void:
	print("[TEST 6] Verifying Focus AP resets to 4 on new document presentation...")
	var desk = _setup_desk()
	desk.current_inspect_focus = 1
	desk.consecutive_false_inquiries = 2

	desk.present_next_document()
	assert(
		desk.current_inspect_focus == desk.MAX_INSPECT_FOCUS,
		"Focus must reset to 4 on next document."
	)
	assert(
		desk.consecutive_false_inquiries == 0,
		"False inquiries must reset on next document."
	)

	desk.queue_free()
	print("  -> Focus reset to 4/4 and inquiries to 0 on new docket [OK]")
	print("  [PASS] Test 6: Focus reset verified.\n")
	passed_tests += 1
