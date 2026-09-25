extends Node

## test_save_load_node.gd - Automated test suite for Phase 1 SaveLoadManager.
## Validates state serialization, file persistence, deck restoration, metadata, and cleanup.

var passed_tests: int = 0
var total_tests: int = 6

const TEST_SLOT_A: String = "slot_1"
const TEST_SLOT_B: String = "slot_2"
const TEST_AUTOSAVE: String = "autosave"


func _ready() -> void:
	print("\n==============================================")
	print(">>> RUNNING SAVE/LOAD MANAGER TEST SUITE <<<")
	print("==============================================\n")

	_run_all_tests()


func _run_all_tests() -> void:
	_cleanup_test_saves()

	test_criterion_1_initial_state_and_paths()
	test_criterion_2_save_serialization_and_signals()
	test_criterion_3_metadata_extraction()
	test_criterion_4_state_and_deck_restoration()
	test_criterion_5_latest_save_and_has_any()
	test_criterion_6_delete_save_and_cleanup()

	_cleanup_test_saves()

	print("\n==============================================")
	if passed_tests == total_tests:
		print(">>> ALL %d SAVE/LOAD TESTS PASSED! (%d/%d) <<<" % [
			total_tests, passed_tests, total_tests
		])
	else:
		print(">>> TEST FAILURES DETECTED! (%d/%d) <<<" % [passed_tests, total_tests])
	print("==============================================\n")

	get_tree().quit(0 if passed_tests == total_tests else 1)


func _cleanup_test_saves() -> void:
	for slot in SaveLoadManager.VALID_SLOTS:
		if SaveLoadManager.has_save(slot):
			SaveLoadManager.delete_save(slot)


func test_criterion_1_initial_state_and_paths() -> void:
	print("[TEST 1] Verifying initial filesystem paths, directories, and slot validation...")
	assert(SaveLoadManager != null, "SaveLoadManager autoload must exist")
	assert(SaveLoadManager.is_valid_slot("autosave"), "autosave should be valid slot")
	assert(SaveLoadManager.is_valid_slot("slot_1"), "slot_1 should be valid slot")
	assert(SaveLoadManager.is_valid_slot("slot_2"), "slot_2 should be valid slot")
	assert(SaveLoadManager.is_valid_slot("slot_3"), "slot_3 should be valid slot")
	assert(not SaveLoadManager.is_valid_slot("slot_99"), "slot_99 should NOT be valid slot")

	var saves_dir := SaveLoadManager.SAVES_DIR
	assert(DirAccess.dir_exists_absolute(saves_dir), "user://saves/ directory must exist")
	assert(not SaveLoadManager.has_any_save(), "Initially no saves should exist")

	var path := SaveLoadManager.get_save_path("slot_1")
	assert(path.ends_with("slot_1.json"), "Path should end with slot_1.json")

	print("  -> Autoload, paths, and directory verified.")
	print("  [PASS] Test 1: Initial state verified.\n")
	passed_tests += 1


func test_criterion_2_save_serialization_and_signals() -> void:
	print("[TEST 2] Verifying save_game() JSON schema and signal emission...")
	# Configure recognizable game state
	GameManager.start_new_game()
	GameManager.current_day = 7
	GameManager.city_budget = 142500
	GameManager.public_opinion = 64.5
	GameManager.personal_wealth = 15000
	GameManager.suspicion_level = 18.0
	GameManager.event_flags["tower_built"] = true
	GameManager.event_flags["park_funded"] = true
	GameManager.daily_history = [
		{
			"day": 1,
			"event_id": "EVT_001",
			"approved": true,
			"took_bribe": false,
			"headline_key": "EVT_001_NEWS_APP"
		}
	]

	# Track signal emission
	var signal_received: Array[String] = []
	var on_saved := func(slot: String): signal_received.append(slot)
	SaveLoadManager.game_saved.connect(on_saved)

	var success := SaveLoadManager.save_game(TEST_SLOT_A)
	SaveLoadManager.game_saved.disconnect(on_saved)

	assert(success, "save_game should return true")
	assert(signal_received.size() == 1, "game_saved signal must be emitted once")
	assert(signal_received[0] == TEST_SLOT_A, "Emitted slot must match TEST_SLOT_A")
	assert(SaveLoadManager.has_save(TEST_SLOT_A), "Save file must exist on disk")

	# Inspect written JSON file structure
	var file_path := SaveLoadManager.get_save_path(TEST_SLOT_A)
	var file := FileAccess.open(file_path, FileAccess.READ)
	assert(file != null, "File must be readable")
	var content := file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(content)
	assert(err == OK, "Saved file must be valid JSON")
	var root: Dictionary = json.data
	assert(root.has("version"), "Root must contain version")
	assert(root.has("metadata"), "Root must contain metadata")
	assert(root.has("game_state"), "Root must contain game_state")
	assert(root.has("deck_state"), "Root must contain deck_state")

	var gs: Dictionary = root["game_state"]
	assert(int(gs["current_day"]) == 7, "game_state current_day mismatch")
	assert(int(gs["city_budget"]) == 142500, "game_state city_budget mismatch")
	assert(is_equal_approx(float(gs["public_opinion"]), 64.5), "public_opinion mismatch")
	assert(int(gs["personal_wealth"]) == 15000, "personal_wealth mismatch")
	assert(is_equal_approx(float(gs["suspicion_level"]), 18.0), "suspicion_level mismatch")
	assert(gs["event_flags"]["tower_built"] == true, "event_flags tower_built mismatch")
	assert(gs["daily_history"].size() == 1, "daily_history size mismatch")

	var ds: Dictionary = root["deck_state"]
	assert(ds.has("draw_pile_ids"), "deck_state must have draw_pile_ids")
	assert(ds.has("discard_pile_ids"), "deck_state must have discard_pile_ids")
	assert(ds.has("daily_queue_ids"), "deck_state must have daily_queue_ids")

	print("  -> State properly serialized into valid JSON schema with signals.")
	print("  [PASS] Test 2: Save serialization verified.\n")
	passed_tests += 1


func test_criterion_3_metadata_extraction() -> void:
	print("[TEST 3] Verifying get_slot_metadata() and get_all_slots_metadata()...")
	# Metadata for occupied slot
	var meta_a := SaveLoadManager.get_slot_metadata(TEST_SLOT_A)
	assert(meta_a["exists"] == true, "meta_a should exist")
	assert(meta_a["is_empty"] == false, "meta_a should not be empty")
	assert(meta_a["slot_id"] == TEST_SLOT_A, "meta_a slot_id mismatch")
	assert(int(meta_a["day"]) == 7, "meta_a day mismatch")
	assert(int(meta_a["budget"]) == 142500, "meta_a budget mismatch")
	assert(is_equal_approx(float(meta_a["approval"]), 64.5), "meta_a approval mismatch")
	assert(int(meta_a["offshore"]) == 15000, "meta_a offshore mismatch")
	assert(int(meta_a["timestamp_unix"]) > 0, "meta_a timestamp_unix must be > 0")
	assert(not str(meta_a["timestamp_str"]).is_empty(), "meta_a timestamp_str must not be empty")
	assert(meta_a["version"] == "1.0", "meta_a version mismatch")

	# Metadata for empty slot
	var meta_empty := SaveLoadManager.get_slot_metadata(TEST_SLOT_B)
	assert(meta_empty["exists"] == false, "empty slot should have exists=false")
	assert(meta_empty["is_empty"] == true, "empty slot should have is_empty=true")
	assert(meta_empty["slot_id"] == TEST_SLOT_B, "empty slot slot_id mismatch")

	# All slots metadata
	var all_meta := SaveLoadManager.get_all_slots_metadata()
	assert(all_meta.size() == 4, "get_all_slots_metadata must return 4 slots")
	var found_a: bool = false
	var found_empty: bool = false
	for m in all_meta:
		if m["slot_id"] == TEST_SLOT_A and m["exists"] == true:
			found_a = true
		if m["slot_id"] == TEST_SLOT_B and m["exists"] == false:
			found_empty = true
	assert(found_a, "Slot A must be found populated in all slots metadata")
	assert(found_empty, "Slot B must be found empty in all slots metadata")

	print("  -> Metadata extraction for populated and empty slots verified.")
	print("  [PASS] Test 3: Metadata extraction verified.\n")
	passed_tests += 1


func test_criterion_4_state_and_deck_restoration() -> void:
	print("[TEST 4] Verifying load_game() round-trip state and deck reconstruction...")
	# Setup specific deck distribution
	EventManager.reset_deck()
	var total_events_count := EventManager.all_events.size()
	assert(total_events_count > 0, "EventManager must have events loaded")

	# Draw some events to populate discard and queue
	var ev1 := EventManager.draw_next_event()
	var ev2 := EventManager.draw_next_event()
	EventManager.discard_event(ev1)
	EventManager.daily_queue = [ev2]

	var original_draw_size := EventManager.draw_pile.size()
	var original_discard_size := EventManager.discard_pile.size()
	var original_queue_size := EventManager.daily_queue.size()

	# Save state
	GameManager.current_day = 14
	GameManager.city_budget = 42000
	GameManager.public_opinion = 31.0
	GameManager.personal_wealth = 55000
	GameManager.suspicion_level = 62.0
	GameManager.event_flags.clear()
	GameManager.event_flags["corrupt_deal_sealed"] = true

	var save_ok := SaveLoadManager.save_game(TEST_SLOT_A)
	assert(save_ok, "Save must succeed")

	# Mutate state completely
	GameManager.start_new_game()
	EventManager.reset_deck()
	assert(GameManager.current_day == 1, "GameManager day should be reset to 1")
	assert(GameManager.city_budget == 100000, "GameManager budget reset mismatch")

	# Load state back
	var load_signals: Array[String] = []
	var on_loaded := func(slot: String): load_signals.append(slot)
	SaveLoadManager.game_loaded.connect(on_loaded)

	var load_ok := SaveLoadManager.load_game(TEST_SLOT_A)
	SaveLoadManager.game_loaded.disconnect(on_loaded)

	assert(load_ok, "load_game should return true")
	assert(load_signals.size() == 1, "game_loaded signal must be emitted")
	assert(load_signals[0] == TEST_SLOT_A, "Loaded signal slot ID mismatch")

	# Verify GameManager restored fields
	assert(GameManager.current_day == 14, "Restored day mismatch")
	assert(GameManager.city_budget == 42000, "Restored city_budget mismatch")
	assert(is_equal_approx(GameManager.public_opinion, 31.0), "Restored opinion mismatch")
	assert(GameManager.personal_wealth == 55000, "Restored wealth mismatch")
	assert(is_equal_approx(GameManager.suspicion_level, 62.0), "Restored suspicion mismatch")
	assert(
		GameManager.event_flags.get("corrupt_deal_sealed", false) == true,
		"Restored event_flags mismatch"
	)

	# Verify EventManager restored deck
	assert(EventManager.draw_pile.size() == original_draw_size, "Draw pile size mismatch")
	assert(EventManager.discard_pile.size() == original_discard_size, "Discard size mismatch")
	assert(EventManager.daily_queue.size() == original_queue_size, "Daily queue size mismatch")
	assert(EventManager.discard_pile[0].id == ev1.id, "Discarded event ID mismatch")
	assert(EventManager.daily_queue[0].id == ev2.id, "Daily queue event ID mismatch")

	print("  -> GameManager stats and EventManager deck state accurately restored.")
	print("  [PASS] Test 4: State and deck restoration verified.\n")
	passed_tests += 1


func test_criterion_5_latest_save_and_has_any() -> void:
	print("[TEST 5] Verifying get_latest_save_slot() and has_any_save()...")
	assert(SaveLoadManager.has_any_save(), "has_any_save should be true after saving")

	# Save into slot_2 with a slightly modified time/state
	GameManager.current_day = 20
	SaveLoadManager.save_game(TEST_SLOT_B)

	var latest := SaveLoadManager.get_latest_save_slot()
	assert(
		latest == TEST_SLOT_B or latest == TEST_SLOT_A,
		"get_latest_save_slot must return one of the saved slots"
	)

	# Save into autosave
	GameManager.current_day = 21
	SaveLoadManager.save_game(TEST_AUTOSAVE)
	var latest_after_auto := SaveLoadManager.get_latest_save_slot()
	assert(
		latest_after_auto == TEST_AUTOSAVE or latest_after_auto == TEST_SLOT_B,
		"Latest slot should reflect recent save"
	)

	print("  -> has_any_save() and get_latest_save_slot() verified.")
	print("  [PASS] Test 5: Latest save selection verified.\n")
	passed_tests += 1


func test_criterion_6_delete_save_and_cleanup() -> void:
	print("[TEST 6] Verifying delete_save(), filesystem removal, and signal...")
	var delete_signals: Array[String] = []
	var on_deleted := func(slot: String): delete_signals.append(slot)
	SaveLoadManager.save_deleted.connect(on_deleted)

	assert(SaveLoadManager.has_save(TEST_SLOT_A), "Slot A must exist before delete")
	var deleted_ok := SaveLoadManager.delete_save(TEST_SLOT_A)
	assert(deleted_ok, "delete_save should return true")
	assert(not SaveLoadManager.has_save(TEST_SLOT_A), "Slot A must not exist after delete")
	assert(delete_signals.size() == 1, "save_deleted signal emitted once")
	assert(delete_signals[0] == TEST_SLOT_A, "Deleted slot ID mismatch in signal")

	# Attempting to delete non-existent slot
	var second_delete := SaveLoadManager.delete_save(TEST_SLOT_A)
	assert(not second_delete, "delete_save on missing slot should return false")

	# Clean remaining
	SaveLoadManager.delete_save(TEST_SLOT_B)
	SaveLoadManager.delete_save(TEST_AUTOSAVE)
	SaveLoadManager.save_deleted.disconnect(on_deleted)

	assert(not SaveLoadManager.has_any_save(), "All saves should be cleaned up")
	print("  -> File deletion, signal, and full cleanup verified.")
	print("  [PASS] Test 6: Delete save verified.\n")
	passed_tests += 1
