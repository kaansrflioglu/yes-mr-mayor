extends Node

## test_inspection_and_hotline_fixes.gd - Verifies cross-category pairing,
## hotline unique picking, and shift time integrity.

var passed_tests: int = 0
var total_tests: int = 3

@onready var game_mgr: Node = get_node("/root/GameManager")
@onready var event_mgr: Node = get_node("/root/EventManager")


func _ready() -> void:
	print("\n========================================================")
	print(">>> RUNNING INSPECTION & HOTLINE COOLDOWN TESTS <<<")
	print("========================================================\n")

	test_test_1_rulebook_requirement()
	test_test_2_hotline_unique_tracking()
	test_test_3_shift_time_integrity()

	print("\n========================================================")
	if passed_tests == total_tests:
		print(">>> ALL 3 INSPECTION & HOTLINE TESTS PASSED! (3/3) <<<")
	else:
		print(">>> TEST FAILURES DETECTED! (%d/%d) <<<" % [passed_tests, total_tests])
	print("========================================================\n")

	get_tree().quit(0 if passed_tests == total_tests else 1)


func test_test_1_rulebook_requirement() -> void:
	print("[TEST 1] Verifying cross-category token pairing in EventData...")
	# Find an event with a violation containing at least 2 non-rule tags or rule tags
	var evt_001: EventData = null
	for ev in event_mgr.all_events:
		if ev.id == "EVT_001":
			evt_001 = ev
			break

	assert(evt_001 != null, "EVT_001 must exist.")

	# A) Two application tags (e.g. app_district + app_seal) should NEVER form a valid match
	var illegal_match := evt_001.find_matching_violation("app_district", "app_seal")
	assert(illegal_match.is_empty(), "Two application tags must not match.")

	# B) Application vs Rule (app_district + rule_zoning_river) is valid and matches
	var valid_match := evt_001.find_matching_violation("app_district", "rule_zoning_river")
	assert(not valid_match.is_empty(), "App vs Rule should successfully match violation.")

	print("  -> Illegal pair (app_district, app_seal): rejected [OK]")
	print("  -> Valid pair (app_district, rule_zoning_river): accepted [OK]")
	print("  [PASS] Test 1: Rulebook Requirement verified.\n")
	passed_tests += 1


func test_test_2_hotline_unique_tracking() -> void:
	print("[TEST 2] Verifying HotlineManager unique call tracking...")
	var h_mgr: HotlineManager = HotlineManager.new()
	h_mgr.reset_history()

	var test_day: int = 15
	var eligible_count: int = h_mgr.get_eligible_calls(test_day).size()
	var pick_count: int = mini(5, eligible_count)

	var picked_ids: Array[String] = []
	for i in range(pick_count):
		var hotline_call: HotlineCallData = h_mgr.pick_next_call(test_day)
		assert(hotline_call != null, "Eligible call must be picked.")
		assert(
			not picked_ids.has(hotline_call.id),
			"Call ID %s was repeated before pool exhausted." % hotline_call.id
		)
		picked_ids.append(hotline_call.id)

	print("  -> Picked %d unique calls: %s" % [picked_ids.size(), str(picked_ids)])
	print("  [PASS] Test 2: Hotline Unique Tracking verified.\n")
	passed_tests += 1


func test_test_3_shift_time_integrity() -> void:
	print("[TEST 3] Verifying voluntary consultation vs whistleblower shift time cost...")
	game_mgr.start_new_game()
	var initial_budget: int = game_mgr.city_budget

	var phone_scene: PackedScene = preload("res://scenes/desk/RedTelephone.tscn")
	var phone_instance = phone_scene.instantiate()
	add_child(phone_instance)

	var desk_scene: PackedScene = preload("res://scenes/desk/DeskView.tscn")
	var desk_instance = desk_scene.instantiate()
	desk_instance.name = "DeskView"
	add_child(desk_instance)

	var initial_time: int = desk_instance.current_shift_minutes

	# Case A: Voluntary Inspector Consultation -> Costs $1000 and 30 mins
	var consult_ok: bool = desk_instance.consult_red_phone()
	assert(consult_ok, "Voluntary consultation must succeed.")
	assert(game_mgr.city_budget == initial_budget - 1000, "City budget must be debited $1000.")
	assert(
		desk_instance.current_shift_minutes == initial_time + 30,
		"Consultation must advance shift clock by 30 minutes."
	)

	# Case B: Whistleblower Tip Revealed -> Does NOT advance shift time
	var time_after_consult: int = desk_instance.current_shift_minutes
	desk_instance.call("_on_whistleblower_tip_revealed")
	assert(
		desk_instance.current_shift_minutes == time_after_consult,
		"Whistleblower tip must NOT advance shift clock."
	)

	desk_instance.queue_free()
	phone_instance.queue_free()
	print("  -> Consultation cost: $1,000 + 30 min clock advance [OK]")
	print("  -> Whistleblower tip: $0 + 0 min clock advance [OK]")
	print("  [PASS] Test 3: Shift Time Integrity verified.\n")
	passed_tests += 1
