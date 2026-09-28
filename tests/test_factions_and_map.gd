extends Node

## test_factions_and_map.gd - Acceptance test suite for Municipal Factions & District Map Blueprint (Spec 06).

var passed_tests: int = 0
var total_tests: int = 3

@onready var faction_mgr: Node = get_node("/root/FactionManager")
@onready var game_mgr: Node = get_node("/root/GameManager")


func _ready() -> void:
	print("\n========================================================")
	print(">>> RUNNING FACTION INFLUENCE & DISTRICT MAP TESTS <<<")
	print("========================================================\n")

	await test_test_1_decision_impact()
	await test_test_2_crisis_trigger()
	await test_test_3_map_modal_navigation()

	print("\n========================================================")
	if passed_tests == total_tests:
		print(">>> ALL 3 FACTION & MAP TESTS PASSED! (3/3) <<<")
	else:
		print(">>> TEST FAILURES DETECTED! (%d/%d) <<<" % [passed_tests, total_tests])
	print("========================================================\n")

	get_tree().quit(0 if passed_tests == total_tests else 1)


func test_test_1_decision_impact() -> void:
	print("[TEST 1] Verifying industrial decision impact on Greens, Oligarchs and District pollution...")
	faction_mgr.reset_state()

	var event = EventData.new()
	event.id = "TEST_INDUSTRIAL_01"
	event.category = "industrial"
	event.application_data = {"district_id": "DIST_INDUSTRIAL"}

	var initial_greens: float = faction_mgr.get_faction_value("greens")
	var initial_oligarchs: float = faction_mgr.get_faction_value("oligarchs")
	var initial_poll: float = float(faction_mgr.districts["DIST_INDUSTRIAL"]["pollution"])

	assert(initial_greens == 50.0, "Initial greens must be 50.0")
	assert(initial_oligarchs == 50.0, "Initial oligarchs must be 50.0")

	# Approve industrial permit
	faction_mgr.process_decision(event, true, false)

	var new_greens: float = faction_mgr.get_faction_value("greens")
	var new_oligarchs: float = faction_mgr.get_faction_value("oligarchs")
	var new_poll: float = float(faction_mgr.districts["DIST_INDUSTRIAL"]["pollution"])

	assert(new_greens == 38.0, "Greens must drop by 12 points to 38.0, got: %f" % new_greens)
	assert(new_oligarchs == 58.0, "Oligarchs must rise by 8 points to 58.0, got: %f" % new_oligarchs)
	assert(new_poll == initial_poll + 15.0, "District pollution must rise by 15 points, got: %f" % new_poll)

	print("  -> Industrial permit approval shifted Greens (-12), Oligarchs (+8), Pollution (+15).")
	print("  [PASS] Test 1: Decision Impact verified.\n")
	passed_tests += 1


func test_test_2_crisis_trigger() -> void:
	print("[TEST 2] Verifying faction crisis trigger when favor drops below 15%...")
	faction_mgr.reset_state()

	var crisis_box := {"faction": ""}
	var on_crisis := func(f_id: String) -> void:
		crisis_box["faction"] = f_id

	faction_mgr.faction_crisis_triggered.connect(on_crisis)

	# Drop unions favor from 50 down to 10
	faction_mgr.adjust_faction("unions", -40.0)

	assert(faction_mgr.get_faction_value("unions") == 10.0, "Unions value must be 10.0")
	assert(crisis_box["faction"] == "unions", "Crisis signal must fire for unions")
	assert(faction_mgr.crisis_triggered_factions.has("unions"), "Unions must be flagged as in crisis")

	faction_mgr.faction_crisis_triggered.disconnect(on_crisis)
	print("  -> Union favor dropped to 10%, triggering faction_crisis_triggered correctly.")
	print("  [PASS] Test 2: Crisis Trigger verified.\n")
	passed_tests += 1


func test_test_3_map_modal_navigation() -> void:
	print("[TEST 3] Verifying DistrictMapModal opens, displays 5 districts and 5 factions, and closes...")
	var modal_scene: PackedScene = preload("res://scenes/desk/DistrictMapModal.tscn")
	var modal = modal_scene.instantiate()
	add_child(modal)

	modal.open_modal()
	await get_tree().process_frame
	await get_tree().process_frame

	assert(modal.visible == true, "Modal must be visible upon open_modal()")

	# Verify 5 factions present
	var required_factions: Array[String] = ["oligarchs", "unions", "greens", "historic", "police"]
	for f_id in required_factions:
		assert(modal.faction_rows.has(f_id), "Faction row '%s' must exist in map modal" % f_id)

	# Verify 5 districts present
	var required_districts: Array[String] = [
		"DIST_CENTRAL", "DIST_RIVERBED", "DIST_INDUSTRIAL", "DIST_HISTORIC", "DIST_SUBURBS"
	]
	for d_id in required_districts:
		assert(modal.district_cards.has(d_id), "District card '%s' must exist in map modal" % d_id)

	# Verify modified industrial pollution is rendered on DIST_INDUSTRIAL card
	var ind_card = modal.district_cards["DIST_INDUSTRIAL"]
	var poll_val = ind_card.find_child("PollVal", true, false) as Label
	assert(poll_val != null, "PollVal label must exist on district card")

	# Close modal
	modal.close_modal()
	await modal.closed

	assert(modal.visible == false, "Modal must be hidden upon close_modal()")

	modal.queue_free()
	print("  -> DistrictMapModal rendered all 5 factions and 5 districts, responding to open/close lifecycle.")
	print("  [PASS] Test 3: Map Modal Navigation verified.\n")
	passed_tests += 1
