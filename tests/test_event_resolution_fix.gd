extends Node

## test_event_resolution_fix.gd - Verifies event resolution base effects, visual flags, and consequence chaining.

var passed_tests: int = 0
var total_tests: int = 3

@onready var game_mgr: Node = get_node("/root/GameManager")
@onready var event_mgr: Node = get_node("/root/EventManager")


func _ready() -> void:
	print("\n========================================================")
	print(">>> RUNNING EVENT RESOLUTION & FLAG PROPAGATION TESTS <<<")
	print("========================================================\n")

	test_test_1_custom_budget_delta()
	test_test_2_city_visual_flag_propagation()
	test_test_3_consequence_chaining()

	print("\n========================================================")
	if passed_tests == total_tests:
		print(">>> ALL 3 EVENT RESOLUTION TESTS PASSED! (3/3) <<<")
	else:
		print(">>> TEST FAILURES DETECTED! (%d/%d) <<<" % [passed_tests, total_tests])
	print("========================================================\n")

	get_tree().quit(0 if passed_tests == total_tests else 1)


func test_test_1_custom_budget_delta() -> void:
	print("[TEST 1] Verifying custom budget delta resolution...")
	game_mgr.start_new_game()
	var initial_budget: int = game_mgr.city_budget

	var custom_effects: Dictionary = {
		"budget": -80000,
		"public_opinion": 25.0
	}
	game_mgr.apply_resolution(custom_effects)

	assert(game_mgr.city_budget == initial_budget - 80000, "City budget must reflect -80000 delta.")
	print("  -> Budget delta applied correctly: %d -> %d" % [initial_budget, game_mgr.city_budget])
	print("  [PASS] Test 1: Custom Budget Delta verified.\n")
	passed_tests += 1


func test_test_2_city_visual_flag_propagation() -> void:
	print("[TEST 2] Verifying city visual flag propagation into GameManager.event_flags...")
	game_mgr.start_new_game()

	var flag_key: String = "add_concrete_tower"
	assert(not game_mgr.event_flags.has(flag_key), "Flag should not be set initially.")

	var custom_effects: Dictionary = {
		"city_visual_flag": flag_key
	}
	game_mgr.apply_resolution(custom_effects)

	assert(game_mgr.event_flags.has(flag_key) and game_mgr.event_flags[flag_key] == true, "City visual flag must be set in event_flags.")
	print("  -> City visual flag propagated: %s = true" % flag_key)
	print("  [PASS] Test 2: City Visual Flag Propagation verified.\n")
	passed_tests += 1


func test_test_3_consequence_chaining() -> void:
	print("[TEST 3] Verifying consequence chaining via unlocks_event_id...")
	game_mgr.start_new_game()

	var target_ev: EventData = null
	for ev in event_mgr.all_events:
		if ev.category == "consequence":
			target_ev = ev
			break

	if target_ev == null and not event_mgr.all_events.is_empty():
		target_ev = event_mgr.all_events[0]

	assert(target_ev != null, "Target event must exist for testing.")
	var unlocked_id: String = target_ev.id

	# Ensure target_ev is not in draw_pile initially for test
	if event_mgr.draw_pile.has(target_ev):
		event_mgr.draw_pile.erase(target_ev)

	var custom_effects: Dictionary = {
		"unlocks_event_id": unlocked_id
	}
	game_mgr.apply_resolution(custom_effects)

	assert(event_mgr.draw_pile.has(target_ev), "EventManager draw_pile must contain the unlocked EventData.")
	print("  -> Unlocked event appended to draw_pile: %s" % unlocked_id)
	print("  [PASS] Test 3: Consequence Chaining verified.\n")
	passed_tests += 1
