extends Node

## test_phase3_node.gd - Automated Test verifying Phase 3 Day Loop, Tabloids & Endings.

const DAY_SUMMARY_SCENE: PackedScene = preload("res://scenes/summary/DayEndSummary.tscn")
const GAME_OVER_SCENE: PackedScene = preload("res://scenes/summary/GameOverModal.tscn")

var passed_tests: int = 0
var total_tests: int = 5


func _ready() -> void:
	print("\n==========================================")
	print(">>> RUNNING PHASE 3 ACCEPTANCE TESTS <<<")
	print("==========================================\n")

	test_criterion_1_tabloid_reflects_choices()
	test_criterion_2_instant_arrest_at_100_suspicion()
	test_criterion_3_election_assessment_day_31()
	test_criterion_4_riot_game_over()
	test_criterion_5_bankruptcy_game_over()

	print("\n==========================================")
	if passed_tests == total_tests:
		print(">>> ALL 5 PHASE 3 TESTS PASSED SUCCESSFULLY! (5/5) <<<")
	else:
		print(">>> TEST FAILURES DETECTED! (%d/%d) <<<" % [passed_tests, total_tests])
	print("==========================================\n")

	get_tree().quit(0 if passed_tests == total_tests else 1)


func test_criterion_1_tabloid_reflects_choices() -> void:
	print("[TEST 1] Verifying end-of-day newspaper reflects shift choices...")
	GameManager.start_new_game()

	var test_evt := EventData.new()
	test_evt.id = "EVT_001"
	test_evt.news_headline_approve_key = "EVT_001_NEWS_APP"
	test_evt.news_headline_reject_key = "EVT_001_NEWS_REJ"
	test_evt.effects_approve = {"budget": 1000}

	# Approve event on Day 1
	GameManager.resolve_event(test_evt, true, false)

	var summary_instance: PanelContainer = DAY_SUMMARY_SCENE.instantiate()
	add_child(summary_instance)
	summary_instance.populate_summary(1)

	var headline_lbl: Label = summary_instance.get_node("%HeadlineMain")
	var expected_headline: String = tr("EVT_001_NEWS_APP")
	var matches: bool = (headline_lbl.text == expected_headline)

	summary_instance.queue_free()

	if matches:
		print("  -> Newspaper Headline: '%s'" % headline_lbl.text)
		print("  [PASS] Test 1: Tabloid accurately reflected shift choice.\n")
		passed_tests += 1
	else:
		printerr("  [FAIL] Test 1: Tabloid headline did not match choice.\n")


func test_criterion_2_instant_arrest_at_100_suspicion() -> void:
	print("[TEST 2] Verifying 100% suspicion instantly interrupts with arrest...")
	GameManager.start_new_game()

	var reason_received: Array[String] = [""]
	var callable := func(key: String): reason_received[0] = key
	GameManager.game_over.connect(callable)

	# Pocket huge bribe that maxes suspicion to 100%
	GameManager.suspicion_meter = 100.0
	GameManager.apply_resolution({})

	GameManager.game_over.disconnect(callable)

	var arrest_triggered: bool = (
		GameManager.is_game_over
		and reason_received[0] == "END_ARRESTED"
	)

	if arrest_triggered:
		print("  -> Game Over: Arrested! Suspicion at 100.0%")
		print("  [PASS] Test 2: Instant arrest triggered correctly.\n")
		passed_tests += 1
	else:
		printerr("  [FAIL] Test 2: Arrest failed to trigger.\n")


func test_criterion_3_election_assessment_day_31() -> void:
	print("[TEST 3] Verifying Day 31 election victory / loss assessment...")
	# 3A: Victory (> 50% approval)
	GameManager.start_new_game()
	GameManager.current_day = 30
	GameManager.public_opinion = 70.0

	var win_reason: Array[String] = [""]
	var callable_win := func(key: String): win_reason[0] = key
	GameManager.game_over.connect(callable_win)

	GameManager.advance_day() # Moves to day 31
	GameManager.game_over.disconnect(callable_win)

	var won: bool = (GameManager.is_game_over and win_reason[0] == "END_REELECTED")

	# 3B: Defeat (< 50% approval)
	GameManager.start_new_game()
	GameManager.current_day = 30
	GameManager.public_opinion = 35.0

	var lose_reason: Array[String] = [""]
	var callable_lose := func(key: String): lose_reason[0] = key
	GameManager.game_over.connect(callable_lose)

	GameManager.advance_day() # Moves to day 31
	GameManager.game_over.disconnect(callable_lose)

	var lost: bool = (GameManager.is_game_over and lose_reason[0] == "END_LOST_ELECTION")

	if won and lost:
		print("  -> Day 31 with 70% approval => Re-elected.")
		print("  -> Day 31 with 35% approval => Lost Election.")
		print("  [PASS] Test 3: Election assessment handles win and loss.\n")
		passed_tests += 1
	else:
		printerr("  [FAIL] Test 3: Election assessment failed.\n")


func test_criterion_4_riot_game_over() -> void:
	print("[TEST 4] Verifying public opinion <= 15% triggers instant riot...")
	GameManager.start_new_game()

	var riot_reason: Array[String] = [""]
	var callable := func(key: String): riot_reason[0] = key
	GameManager.game_over.connect(callable)

	GameManager.public_opinion = 10.0
	GameManager.apply_resolution({})
	GameManager.game_over.disconnect(callable)

	var riot_triggered: bool = (
		GameManager.is_game_over
		and riot_reason[0] == "END_RIOT"
	)

	if riot_triggered:
		print("  -> Game Over: Riot! Public opinion at 10.0%")
		print("  [PASS] Test 4: Riot game over triggered correctly.\n")
		passed_tests += 1
	else:
		printerr("  [FAIL] Test 4: Riot failed to trigger.\n")


func test_criterion_5_bankruptcy_game_over() -> void:
	print("[TEST 5] Verifying city budget < -50000 triggers bankruptcy...")
	GameManager.start_new_game()

	var bank_reason: Array[String] = [""]
	var callable := func(key: String): bank_reason[0] = key
	GameManager.game_over.connect(callable)

	GameManager.city_budget = -75000
	GameManager.apply_resolution({})
	GameManager.game_over.disconnect(callable)

	var bank_triggered: bool = (
		GameManager.is_game_over
		and bank_reason[0] == "END_BANKRUPT"
	)

	if bank_triggered:
		print("  -> Game Over: Bankruptcy! Budget at -$75,000")
		print("  [PASS] Test 5: Bankruptcy triggered correctly.\n")
		passed_tests += 1
	else:
		printerr("  [FAIL] Test 5: Bankruptcy failed to trigger.\n")
