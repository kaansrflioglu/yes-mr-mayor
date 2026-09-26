extends Node

## test_milestone2_tactile_immersion.gd
## Acceptance tests for Milestone 2: Shift Clock (09:00-17:00),
## UV Blacklight Tool, and Red Phone Hotline Investigations.

const DESK_VIEW_SCENE: PackedScene = preload("res://scenes/desk/DeskView.tscn")

var passed_tests: int = 0
var total_tests: int = 6

@onready var game_mgr: Node = get_node("/root/GameManager")
@onready var event_mgr: Node = get_node("/root/EventManager")


func _ready() -> void:
	print("\n============================================================")
	print(">>> RUNNING INVESTIGATION MECHANICS MILESTONE 2 TESTS <<<")
	print("============================================================\n")

	test_clock_initial_allocation()
	test_clock_advancement_on_inspection()
	test_uv_blacklight_watermark_reveal()
	test_red_phone_consultation_tip()
	test_clock_overtime_threshold()
	test_clock_reset_on_new_day()

	print("\n============================================================")
	if passed_tests == total_tests:
		print(">>> ALL %d MILESTONE 2 TESTS PASSED! (%d/%d) <<<" % [
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


func test_clock_initial_allocation() -> void:
	print("[TEST 1] Verifying Shift Clock starts at 09:00 AM (540 min)...")
	var desk = _setup_desk()

	assert(
		desk.current_shift_minutes == desk.SHIFT_START_MINUTES,
		"Clock must start at 09:00 AM (540 mins)."
	)
	assert(not desk.is_overtime, "Shift must not start in overtime.")
	var formatted: String = desk.get_formatted_shift_time()
	assert(formatted.contains("09:00 AM"), "Clock string must show 09:00 AM.")

	desk.queue_free()
	print("  -> Shift Clock: 09:00 AM [OK]")
	print("  [PASS] Test 1: Clock initial allocation verified.\n")
	passed_tests += 1


func test_clock_advancement_on_inspection() -> void:
	print("[TEST 2] Verifying inspection attempts consume 15 shift minutes...")
	var desk = _setup_desk()
	var test_evt: EventData = event_mgr.all_events[0]
	game_mgr.active_event = test_evt

	var init_mins: int = desk.current_shift_minutes
	desk.evaluate_discrepancy("app_district", "rule_zoning_river")

	assert(
		desk.current_shift_minutes == init_mins + 15,
		"Inspection must consume 15 minutes."
	)
	var formatted: String = desk.get_formatted_shift_time()
	assert(formatted.contains("09:15 AM"), "Clock must advance to 09:15 AM.")

	desk.queue_free()
	print("  -> Time advanced 15m (09:00 -> 09:15 AM) [OK]")
	print("  [PASS] Test 2: Inspection time consumption verified.\n")
	passed_tests += 1


func test_uv_blacklight_watermark_reveal() -> void:
	print("[TEST 3] Verifying UV Blacklight reveals watermarks & consumes time...")
	var desk = _setup_desk()

	# Find EVT_001 which has VIOL_FORGED_SEAL
	var evt_forged: EventData = null
	for ev in event_mgr.all_events:
		if ev.id == "EVT_001":
			evt_forged = ev
			break
	assert(evt_forged != null, "EVT_001 must exist.")

	game_mgr.active_event = evt_forged
	desk.active_document.setup_event(evt_forged)

	var init_time: int = desk.current_shift_minutes
	desk.toggle_uv_blacklight()

	assert(desk.is_uv_active, "UV mode must be active.")
	assert(
		desk.current_shift_minutes == init_time + desk.UV_TOGGLE_TIME_COST_MINUTES,
		"UV toggle must advance time by 5 minutes."
	)
	assert(
		desk.active_document.uv_overlay.visible,
		"Document UV overlay must be visible."
	)
	assert(
		desk.active_document.uv_seal_label.visible,
		"UV seal watermark must be visible."
	)
	var seal_text: String = desk.active_document.uv_seal_label.text
	assert(
		seal_text.contains(tr("UI_UV_FORGED_SEAL")),
		"Forged seal must reveal fake watermark under UV."
	)

	# Toggle off
	desk.toggle_uv_blacklight()
	assert(not desk.is_uv_active, "UV mode must deactivate.")
	assert(
		not desk.active_document.uv_overlay.visible,
		"UV overlay must hide when deactivated."
	)

	desk.queue_free()
	print("  -> UV Blacklight overlay activated [OK]")
	print("  -> Forged Seal watermark detected under UV [OK]")
	print("  -> Toggle off restores normal light [OK]")
	print("  [PASS] Test 3: UV Blacklight tool verified.\n")
	passed_tests += 1


func test_red_phone_consultation_tip() -> void:
	print("[TEST 4] Verifying Red Phone consultation tipline ($1,000, 30m)...")
	var desk = _setup_desk()
	game_mgr.city_budget = 50000

	# Find a violating event
	var test_evt: EventData = null
	for ev in event_mgr.all_events:
		if ev.has_violations():
			test_evt = ev
			break
	assert(test_evt != null, "A violating event must exist.")

	game_mgr.active_event = test_evt
	desk.active_document.setup_event(test_evt)

	var initial_budget: int = game_mgr.city_budget
	var initial_time: int = desk.current_shift_minutes

	var phone: Control = desk.get_node("%RedTelephone")
	assert(phone != null, "RedTelephone node must exist in desk.")

	var success: bool = phone.consult_inspector()
	assert(success, "Phone consultation must succeed.")
	assert(
		game_mgr.city_budget == initial_budget - 1000,
		"Consultation must deduct $1,000 fee."
	)
	assert(
		desk.current_shift_minutes == initial_time + 30,
		"Consultation must consume 30 shift minutes."
	)
	assert(
		desk.active_document.discovered_violations.size() >= 1,
		"Inspector hotline must reveal 1 guaranteed violation."
	)

	desk.queue_free()
	print("  -> Hotline dialed: -$1,000 Budget, +30 mins [OK]")
	print("  -> 1 Guaranteed violation uncovered [OK]")
	print("  [PASS] Test 4: Red Phone consultation verified.\n")
	passed_tests += 1


func test_clock_overtime_threshold() -> void:
	print("[TEST 5] Verifying 17:00 (1020 min) Shift Clock Overtime deadline...")
	var desk = _setup_desk()

	# Advance time close to 17:00
	desk.current_shift_minutes = 1010
	desk.advance_shift_time(15)

	assert(
		desk.current_shift_minutes >= desk.SHIFT_END_MINUTES,
		"Time must reach or exceed 17:00 (1020 mins)."
	)
	assert(desk.is_overtime, "Overtime flag must trigger at or past 17:00.")
	var formatted: String = desk.get_formatted_shift_time()
	assert(formatted.contains("(!)"), "Clock string must flag overtime.")
	var status_text: String = desk.inspect_status_label.text
	assert(
		status_text.contains(tr("UI_SHIFT_OVERTIME")),
		"Overtime warning must display."
	)

	desk.queue_free()
	print("  -> Overtime reached at 17:00 deadline [OK]")
	print("  -> Overtime warning displayed [OK]")
	print("  [PASS] Test 5: Shift Clock Overtime verified.\n")
	passed_tests += 1


func test_clock_reset_on_new_day() -> void:
	print("[TEST 6] Verifying Shift Clock resets to 09:00 AM on new day...")
	var desk = _setup_desk()
	desk.current_shift_minutes = 1050
	desk.is_overtime = true

	desk._on_next_day_pressed()

	assert(
		desk.current_shift_minutes == desk.SHIFT_START_MINUTES,
		"Clock must reset to 09:00 AM on next day."
	)
	assert(not desk.is_overtime, "Overtime must clear on next day.")
	var formatted: String = desk.get_formatted_shift_time()
	assert(formatted.contains("09:00 AM"), "Clock must read 09:00 AM.")

	desk.queue_free()
	print("  -> Clock reset to 09:00 AM and overtime cleared [OK]")
	print("  [PASS] Test 6: Clock reset on new day verified.\n")
	passed_tests += 1
