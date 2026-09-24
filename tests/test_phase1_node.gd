extends Node

## test_phase1_node.gd - Runs Phase 1 Acceptance Criteria inside full Godot scene tree.

const EventManagerScript = preload("res://scripts/autoload/EventManager.gd")
const GameManagerScript = preload("res://scripts/autoload/GameManager.gd")

var passed_tests: int = 0
var total_tests: int = 4

@onready var event_mgr: EventManagerScript = get_node("/root/EventManager")
@onready var game_mgr: GameManagerScript = get_node("/root/GameManager")


func _ready() -> void:
	print("\n==========================================")
	print(">>> RUNNING PHASE 1 ACCEPTANCE TESTS <<<")
	print("==========================================\n")

	test_criterion_1_event_manager_draw()
	test_criterion_2_stats_update_and_signal()
	test_criterion_3_clamping()
	test_criterion_4_localization()

	print("\n==========================================")
	if passed_tests == total_tests:
		print(">>> ALL 4 PHASE 1 TESTS PASSED SUCCESSFULLY! (4/4) <<<")
	else:
		print(">>> TEST FAILURES DETECTED! (%d/%d) <<<" % [passed_tests, total_tests])
	print("==========================================\n")

	get_tree().quit(0 if passed_tests == total_tests else 1)


func test_criterion_1_event_manager_draw() -> void:
	print("[TEST 1] Testing EventManager.draw_next_event()...")
	var event: EventData = event_mgr.draw_next_event()
	if event != null and not event.id.is_empty():
		print("  -> Drawn event ID: %s | Title Key: %s" % [event.id, event.title_key])
		print("  [PASS] Test 1: Event drawn successfully.\n")
		passed_tests += 1
	else:
		printerr("  [FAIL] Test 1: EventManager failed to draw a valid event.\n")


func test_criterion_2_stats_update_and_signal() -> void:
	print("[TEST 2] Testing stat update and stats_changed signal on approval...")
	game_mgr.start_new_game()

	var signal_box: Array[bool] = [false]
	var callable := func(): signal_box[0] = true
	game_mgr.stats_changed.connect(callable)

	var initial_budget: int = game_mgr.city_budget
	var initial_wealth: int = game_mgr.offshore_account
	var initial_opinion: float = game_mgr.public_opinion
	var initial_suspicion: float = game_mgr.suspicion_meter

	var test_event := EventData.new()
	test_event.id = "TEST_EVT"
	test_event.effects_approve = {
		"budget": 25000,
		"personal_wealth": 50000,
		"public_opinion": -15.0,
		"suspicion": 20.0
	}
	test_event.bribe_offered = 50000

	# Apply approval
	game_mgr.resolve_event(test_event, true, false)
	game_mgr.stats_changed.disconnect(callable)

	var signal_received: bool = signal_box[0]

	var stats_changed_properly: bool = (
		signal_received
		and game_mgr.city_budget == initial_budget + 25000
		and game_mgr.offshore_account == initial_wealth + 50000
		and is_equal_approx(game_mgr.public_opinion, initial_opinion - 15.0)
		and is_equal_approx(game_mgr.suspicion_meter, initial_suspicion + 20.0)
	)

	if stats_changed_properly:
		print("  -> Budget: %d | Offshore: %d | Opinion: %.1f | Suspicion: %.1f" % [
			game_mgr.city_budget, game_mgr.offshore_account,
			game_mgr.public_opinion, game_mgr.suspicion_meter
		])
		print("  [PASS] Test 2: Approval updated all 4 variables & emitted stats_changed.\n")
		passed_tests += 1
	else:
		printerr("  [FAIL] Test 2 Debug:")
		printerr("    signal_received: %s" % signal_received)
		printerr(
			"    budget: %d (expected %d)"
			% [game_mgr.city_budget, initial_budget + 25000]
		)
		printerr(
			"    offshore: %d (expected %d)"
			% [game_mgr.offshore_account, initial_wealth + 50000]
		)
		printerr(
			"    opinion: %f (expected %f)"
			% [game_mgr.public_opinion, initial_opinion - 15.0]
		)
		printerr(
			"    suspicion: %f (expected %f)"
			% [game_mgr.suspicion_meter, initial_suspicion + 20.0]
		)


func test_criterion_3_clamping() -> void:
	print("[TEST 3] Testing public_opinion and suspicion_meter clamping (0.0 - 100.0)...")
	game_mgr.public_opinion = 999.0
	var clamped_max_opinion: bool = is_equal_approx(game_mgr.public_opinion, 100.0)

	game_mgr.public_opinion = -50.0
	var clamped_min_opinion: bool = is_equal_approx(game_mgr.public_opinion, 0.0)

	game_mgr.suspicion_meter = 250.0
	var clamped_max_suspicion: bool = is_equal_approx(game_mgr.suspicion_meter, 100.0)

	game_mgr.suspicion_meter = -20.0
	var clamped_min_suspicion: bool = is_equal_approx(game_mgr.suspicion_meter, 0.0)

	var clamping_valid: bool = (
		clamped_max_opinion and clamped_min_opinion
		and clamped_max_suspicion and clamped_min_suspicion
	)

	if clamping_valid:
		print("  -> Public opinion range: [0.0 - 100.0] confirmed.")
		print("  -> Suspicion meter range: [0.0 - 100.0] confirmed.")
		print("  [PASS] Test 3: Clamping functions correctly.\n")
		passed_tests += 1
	else:
		printerr("  [FAIL] Test 3: Value clamping failed.\n")


func test_criterion_4_localization() -> void:
	print("[TEST 4] Testing tr(\"UI_TITLE\") in English and Turkish...")
	TranslationServer.set_locale("en")
	var en_text: String = tr("UI_TITLE")

	TranslationServer.set_locale("tr")
	var tr_text: String = tr("UI_TITLE")

	var valid_en: bool = (en_text == "Mr. Mayor: Paper Trail")
	var valid_tr: bool = (tr_text == "Sayın Başkanım")

	if valid_en and valid_tr:
		print("  -> Locale [EN]: %s" % en_text)
		print("  -> Locale [TR]: %s" % tr_text)
		print("  [PASS] Test 4: Localization translations output valid text.\n")
		passed_tests += 1
	else:
		printerr("  [FAIL] Test 4: tr() failed: EN='%s', TR='%s'\n" % [en_text, tr_text])
