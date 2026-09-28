extends Node

## test_saveload_lifecycle_expansion.gd - Verifies hotline history, directive state, and shift state persistence.

var passed_tests: int = 0
var total_tests: int = 3

@onready var game_mgr: Node = get_node("/root/GameManager")
@onready var save_load_mgr: Node = get_node("/root/SaveLoadManager")
@onready var directive_mgr: Node = get_node("/root/DirectiveManager")

const TEST_SLOT: String = "slot_1"


func _ready() -> void:
	print("\n========================================================")
	print(">>> RUNNING EXPANDED SAVE/LOAD PERSISTENCE TESTS <<<")
	print("========================================================\n")

	test_test_1_hotline_history_persistence()
	test_test_2_directive_persistence()
	test_test_3_shift_state_persistence()

	# Cleanup test slot
	if save_load_mgr.has_save(TEST_SLOT):
		save_load_mgr.delete_save(TEST_SLOT)

	print("\n========================================================")
	if passed_tests == total_tests:
		print(">>> ALL 3 SAVE/LOAD EXPANSION TESTS PASSED! (3/3) <<<")
	else:
		print(">>> TEST FAILURES DETECTED! (%d/%d) <<<" % [passed_tests, total_tests])
	print("========================================================\n")

	get_tree().quit(0 if passed_tests == total_tests else 1)


func test_test_1_hotline_history_persistence() -> void:
	print("[TEST 1] Verifying GameManager.hotline_history persistence...")
	game_mgr.start_new_game()
	game_mgr.hotline_history.clear()

	var mock_call: Dictionary = {
		"call_id": "CALL_TEST_101",
		"accepted": true,
		"archetype": "party_boss",
		"bribe": 5000
	}
	game_mgr.hotline_history.append(mock_call)

	var saved: bool = save_load_mgr.save_game(TEST_SLOT)
	assert(saved, "Save game must succeed.")

	# Clear hotline history in memory
	game_mgr.hotline_history.clear()
	assert(game_mgr.hotline_history.is_empty(), "History must be cleared.")

	var loaded: bool = save_load_mgr.load_game(TEST_SLOT)
	assert(loaded, "Load game must succeed.")
	assert(game_mgr.hotline_history.size() == 1, "Hotline history must have 1 record.")
	assert(game_mgr.hotline_history[0]["call_id"] == "CALL_TEST_101", "Call ID must match.")

	print("  -> Restored %d hotline call(s): %s" % [game_mgr.hotline_history.size(), game_mgr.hotline_history[0]["call_id"]])
	print("  [PASS] Test 1: Hotline Persistence verified.\n")
	passed_tests += 1


func test_test_2_directive_persistence() -> void:
	print("[TEST 2] Verifying DirectiveManager active_directive_id persistence...")
	game_mgr.start_new_game()

	var test_directive_id: String = "DIR_ANTI_CORRUPTION"
	directive_mgr.set_active_directive(test_directive_id)
	assert(directive_mgr.active_directive_id == test_directive_id, "Directive must be set.")

	var saved: bool = save_load_mgr.save_game(TEST_SLOT)
	assert(saved, "Save game must succeed.")

	# Reset directive state to standard
	directive_mgr.reset_state()
	assert(directive_mgr.active_directive_id == directive_mgr.DIR_STANDARD, "Directive must be standard.")

	var loaded: bool = save_load_mgr.load_game(TEST_SLOT)
	assert(loaded, "Load game must succeed.")
	assert(directive_mgr.active_directive_id == test_directive_id, "Directive ID must be restored.")

	print("  -> Restored active directive: %s" % directive_mgr.active_directive_id)
	print("  [PASS] Test 2: Directive Persistence verified.\n")
	passed_tests += 1


func test_test_3_shift_state_persistence() -> void:
	print("[TEST 3] Verifying DeskView shift state serialization & payload retention...")
	game_mgr.start_new_game()

	# Create a dummy desk node or DeskView instance to simulate mid-shift state
	var desk_scene: PackedScene = preload("res://scenes/desk/DeskView.tscn")
	var desk_instance = desk_scene.instantiate()
	desk_instance.name = "DeskView"
	add_child(desk_instance)

	desk_instance.current_shift_minutes = 960 # 04:00 PM
	desk_instance.current_inspect_focus = 1
	desk_instance.is_overtime = false
	desk_instance.consecutive_false_inquiries = 2

	var saved: bool = save_load_mgr.save_game(TEST_SLOT)
	assert(saved, "Save game must succeed with DeskView in tree.")

	# Reset desk state
	desk_instance.current_shift_minutes = 540 # 09:00 AM
	desk_instance.current_inspect_focus = 4
	desk_instance.consecutive_false_inquiries = 0

	var loaded: bool = save_load_mgr.load_game(TEST_SLOT)
	assert(loaded, "Load game must succeed.")

	# Verify payload shift_state was stored and passed
	var restored_shift: Dictionary = save_load_mgr.last_loaded_shift_state
	assert(int(restored_shift.get("shift_minutes", 0)) == 960, "Shift minutes in payload must be 960.")
	assert(int(restored_shift.get("inspect_focus", 0)) == 1, "Inspect focus in payload must be 1.")
	assert(int(restored_shift.get("consecutive_false_inquiries", -1)) == 2, "Consecutive false inquiries must be 2.")

	# Verify desk instance itself was updated by _on_game_load_completed
	assert(desk_instance.current_shift_minutes == 960, "DeskView shift minutes must be 960.")
	assert(desk_instance.current_inspect_focus == 1, "DeskView inspect focus must be 1.")

	desk_instance.queue_free()
	print("  -> Restored mid-shift time: 04:00 PM (960 min), Focus: 1, Inquiries: 2")
	print("  [PASS] Test 3: Shift State Persistence verified.\n")
	passed_tests += 1
