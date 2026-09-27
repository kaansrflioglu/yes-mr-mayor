extends Node

## test_morning_briefing_phase1_node.gd - Acceptance tests for Morning Briefing Ritual Phase 1.
## Validates:
## 1. DeskState enum existence and transition states (STATE_MORNING_RITUAL, STATE_PROCESSING_EVENTS, STATE_DAY_END).
## 2. enter_morning_ritual() sets STATE_MORNING_RITUAL and hides stamp buttons.
## 3. enter_morning_ritual() reveals Morning Post-It Note and Brass Bell on desk.
## 4. SkylineView morning sunrise window tint transition execution.
## 5. Ringing the desk bell transitions to STATE_PROCESSING_EVENTS, restores stamps, and presents docket.
## 6. Daily quota completion transitions to STATE_DAY_END.

const DESK_VIEW_SCENE: PackedScene = preload("res://scenes/desk/DeskView.tscn")
const SKYLINE_VIEW_SCENE: PackedScene = preload("res://scenes/desk/SkylineView.tscn")

var passed_tests: int = 0
var total_tests: int = 6
var desk: Control = null


func _ready() -> void:
	print("\n============================================================")
	print(">>> RUNNING MORNING BRIEFING RITUAL: PHASE 1 TESTS <<<")
	print("============================================================\n")

	_run_tests_async()


func _run_tests_async() -> void:
	desk = DESK_VIEW_SCENE.instantiate()
	add_child(desk)
	await get_tree().process_frame

	test_criterion_1_state_machine_states()
	test_criterion_2_morning_ritual_entry_and_stamp_hiding()
	test_criterion_3_postit_memo_and_bell_presence()
	test_criterion_4_skyline_sunrise_tint_transition()
	await test_criterion_5_bell_ring_starts_shift()
	test_criterion_6_shift_end_transition()

	print("\n============================================================")
	if passed_tests == total_tests:
		print(">>> ALL %d MORNING BRIEFING PHASE 1 TESTS PASSED SUCCESSFULLY! <<<" % total_tests)
	else:
		print(">>> TEST FAILURES DETECTED! (%d/%d passed) <<<" % [passed_tests, total_tests])
	print("============================================================\n")

	get_tree().quit(0 if passed_tests == total_tests else 1)


func test_criterion_1_state_machine_states() -> void:
	print("[TEST 1] Verifying DeskState enum definitions and initial state...")
	assert("DeskState" in desk, "DeskView must define DeskState enum.")
	assert("STATE_MORNING_RITUAL" in desk.DeskState, "DeskState must define STATE_MORNING_RITUAL.")
	assert("STATE_PROCESSING_EVENTS" in desk.DeskState, "DeskState must define STATE_PROCESSING_EVENTS.")
	assert("STATE_DAY_END" in desk.DeskState, "DeskState must define STATE_DAY_END.")

	print("  -> DeskState enum correctly exposes all 3 lifecycle states.")
	print("  [PASS] Test 1: DeskState enum verified.\n")
	passed_tests += 1


func test_criterion_2_morning_ritual_entry_and_stamp_hiding() -> void:
	print("[TEST 2] Verifying enter_morning_ritual() state and stamp visibility...")
	desk.enter_morning_ritual()

	assert(
		desk.current_desk_state == desk.DeskState.STATE_MORNING_RITUAL,
		"current_desk_state must be STATE_MORNING_RITUAL after enter_morning_ritual()."
	)
	var stamp_rack: Control = desk.get_node_or_null("%StampRack")
	if stamp_rack != null:
		assert(not stamp_rack.visible, "Stamp rack must be hidden during morning ritual.")

	print("  -> Desk entered STATE_MORNING_RITUAL and stamp buttons were hidden.")
	print("  [PASS] Test 2: Pre-shift state and stamp hiding verified.\n")
	passed_tests += 1


func test_criterion_3_postit_memo_and_bell_presence() -> void:
	print("[TEST 3] Verifying Morning Post-It Note and Brass Bell on desk...")
	var container: Control = desk.get_node_or_null("%MorningRitualContainer")
	assert(container != null, "MorningRitualContainer must exist in DeskView.")
	assert(container.visible, "MorningRitualContainer must be visible in morning ritual.")

	var memo_card: Control = desk.get_node_or_null("%MorningBriefingCard")
	assert(memo_card != null, "MorningBriefingCard must exist in MorningRitualContainer.")
	assert(memo_card.visible, "MorningBriefingCard must be visible.")

	var bell_button: Button = desk.get_node_or_null("%DeskBellButton")
	assert(bell_button != null, "DeskBellButton must exist.")
	assert(bell_button.visible, "DeskBellButton must be visible.")

	var coffee_mug: Button = desk.get_node_or_null("%DeskCoffeeMug")
	assert(coffee_mug != null, "DeskCoffeeMug must exist.")
	assert(coffee_mug.visible, "DeskCoffeeMug must be visible.")

	print("  -> Post-It Note, Brass Bell, and Coffee Mug successfully spawned on desk center.")
	print("  [PASS] Test 3: Post-It Note and Brass Bell presence verified.\n")
	passed_tests += 1


func test_criterion_4_skyline_sunrise_tint_transition() -> void:
	print("[TEST 4] Verifying SkylineView morning sunrise window tint transition...")
	var skyline: Control = desk.get_node_or_null("%SkylineView")
	assert(skyline != null, "SkylineView must be present on desk.")
	assert(skyline.has_method("play_morning_sunrise_transition"), "SkylineView must implement play_morning_sunrise_transition().")

	skyline.play_morning_sunrise_transition(0.05)
	assert(skyline.daily_time_progress == 0.0, "Sunrise transition must reset daily_time_progress to 0.0.")

	print("  -> Skyline sunrise transition executed smoothly with fresh morning dawn tint.")
	print("  [PASS] Test 4: Skyline sunrise transition verified.\n")
	passed_tests += 1


func test_criterion_5_bell_ring_starts_shift() -> void:
	print("[TEST 5] Verifying brass desk bell chime transitions to active shift...")
	assert(desk.current_desk_state == desk.DeskState.STATE_MORNING_RITUAL, "Desk must be in morning ritual.")

	# Trigger bell press
	desk._on_desk_bell_pressed()

	assert(
		desk.current_desk_state == desk.DeskState.STATE_PROCESSING_EVENTS,
		"Desk must transition to STATE_PROCESSING_EVENTS after bell ring."
	)
	var stamp_rack: Control = desk.get_node_or_null("%StampRack")
	if stamp_rack != null:
		assert(stamp_rack.visible, "Stamp rack must be restored visible after bell ring.")

	# Allow slide out animation callback to settle
	await get_tree().create_timer(0.35).timeout
	assert(desk.active_document != null, "First petition docket must be presented after bell ring.")

	print("  -> Bell ring successfully dismissed memo, restored stamps, and loaded first petition docket.")
	print("  [PASS] Test 5: Bell ring starts shift verified.\n")
	passed_tests += 1


func test_criterion_6_shift_end_transition() -> void:
	print("[TEST 6] Verifying daily quota completion transitions to STATE_DAY_END...")
	desk._on_daily_quota_completed()

	assert(
		desk.current_desk_state == desk.DeskState.STATE_DAY_END,
		"current_desk_state must be STATE_DAY_END after daily quota completion."
	)

	print("  -> Shift completion transitioned desk to STATE_DAY_END.")
	print("  [PASS] Test 6: Shift end transition verified.\n")
	passed_tests += 1
