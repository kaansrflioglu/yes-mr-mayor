extends Node

## test_press_conference.gd - Acceptance test suite for Weekly Press Conference Minigame (Spec 07).

var passed_tests: int = 0
var total_tests: int = 3

@onready var game_mgr: Node = get_node("/root/GameManager")


func _ready() -> void:
	print("\n========================================================")
	print(">>> RUNNING WEEKLY PRESS CONFERENCE ACCEPTANCE TESTS <<<")
	print("========================================================\n")

	await test_test_1_trigger_on_day_5()
	await test_test_2_contextual_question_binding()
	await test_test_3_tactic_impact()

	print("\n========================================================")
	if passed_tests == total_tests:
		print(">>> ALL 3 PRESS CONFERENCE TESTS PASSED! (3/3) <<<")
	else:
		print(">>> TEST FAILURES DETECTED! (%d/%d) <<<" % [passed_tests, total_tests])
	print("========================================================\n")

	get_tree().quit(0 if passed_tests == total_tests else 1)


func test_test_1_trigger_on_day_5() -> void:
	print("[TEST 1] Verifying PressConferenceModal spawns on Day 5 shift end before newspaper...")
	game_mgr.start_new_game()
	game_mgr.current_day = 5

	var desk_scene: PackedScene = preload("res://scenes/desk/DeskView.tscn")
	var desk_instance = desk_scene.instantiate()
	desk_instance.name = "DeskView"
	add_child(desk_instance)

	assert(desk_instance._should_trigger_press_conference() == true, "Day 5 must trigger press conference")

	desk_instance._on_daily_quota_completed()
	await get_tree().process_frame
	await get_tree().process_frame

	assert(desk_instance.active_press_conference != null, "Press conference modal must spawn on Day 5")
	assert(desk_instance.active_summary == null, "Tabloid summary newspaper must NOT spawn until press conference ends")

	desk_instance.queue_free()
	print("  -> Day 5 shift end correctly launched PressConferenceModal prior to newspaper.")
	print("  [PASS] Test 1: Day 5 Trigger verified.\n")
	passed_tests += 1


func test_test_2_contextual_question_binding() -> void:
	print("[TEST 2] Verifying floodway permit decision binds to relevant investigative question...")
	var modal_scene: PackedScene = preload("res://scenes/summary/PressConferenceModal.tscn")
	var modal = modal_scene.instantiate()
	add_child(modal)

	var mock_events := [
		{
			"event_id": "EVT_001",
			"category": "floodway",
			"district_id": "DIST_RIVERBED",
			"took_bribe": true
		}
	]

	modal.start_conference(mock_events)
	await get_tree().process_frame

	assert(modal.active_questions.size() >= 1, "Must generate at least one active question")
	var q_id: String = modal.active_questions[0].get("id", "")
	assert(q_id == "PRESS_Q_FLOODWAY" or q_id == "PRESS_Q_BRIBE_LEAK", "First question must reference floodway or bribe, got: %s" % q_id)
	assert(modal.question_label.text.length() > 15, "Question label text must be populated")

	modal.queue_free()
	print("  -> Corrupt riverbed permit directly generated contextual floodway question: '%s'." % q_id)
	print("  [PASS] Test 2: Contextual Question Binding verified.\n")
	passed_tests += 1


func test_test_3_tactic_impact() -> void:
	print("[TEST 3] Verifying 'Distract' tactic costs $20K budget, boosts opinion (+12), and cuts suspicion (-10)...")
	game_mgr.city_budget = 100000
	game_mgr.public_opinion = 50.0
	game_mgr.suspicion_level = 30.0

	var modal_scene: PackedScene = preload("res://scenes/summary/PressConferenceModal.tscn")
	var modal = modal_scene.instantiate()
	add_child(modal)

	modal.start_conference([])
	await get_tree().process_frame

	# Execute "distract" tactic
	modal._resolve_answer("distract")

	assert(game_mgr.city_budget == 80000, "City budget must drop by $20,000 to $80,000, got: %d" % game_mgr.city_budget)
	assert(game_mgr.public_opinion == 62.0, "Public opinion must increase by +12 to 62.0, got: %f" % game_mgr.public_opinion)
	assert(game_mgr.suspicion_level == 20.0, "Suspicion level must decrease by -10 to 20.0, got: %f" % game_mgr.suspicion_level)

	modal.queue_free()
	print("  -> Media Distraction successfully applied budget cost and narrative payoff.")
	print("  [PASS] Test 3: Tactic Impact verified.\n")
	passed_tests += 1
