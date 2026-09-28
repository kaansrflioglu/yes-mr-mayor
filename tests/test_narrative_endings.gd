extends Node

## test_narrative_endings.gd - Headless automated test suite for Spec 10:
## Expanded 12 Narrative Endings & Mayoral Report Card Modal

var passed_tests: int = 0
var total_tests: int = 6


func _ready() -> void:
	print("\n========================================================")
	print(">>> RUNNING EXPANDED NARRATIVE ENDINGS TESTS (SPEC 10) <<<")
	print("========================================================\n")

	await run_tests()

	print("\n========================================================")
	if passed_tests == total_tests:
		print(">>> ALL %d ENDINGS & REPORT CARD TESTS PASSED! (%d/%d) <<<" % [total_tests, passed_tests, total_tests])
	else:
		printerr(">>> FAILURES ENCOUNTERED: %d/%d passed <<<" % [passed_tests, total_tests])
	print("========================================================\n")

	get_tree().quit(0 if passed_tests == total_tests else 1)


func run_tests() -> void:
	test_1_civic_saint_evaluation()
	test_2_teflon_mastermind_evaluation()
	await test_3_report_card_ui_display()
	test_4_sudden_federal_supermax()
	test_5_eco_utopia_evaluation()
	test_6_day_1_decisions_do_not_end_game()


func test_1_civic_saint_evaluation() -> void:
	print("[TEST 1] Verifying Civic Saint mandate evaluation (S Grade)...")
	GameManager.reset_state()
	GameManager.current_day = 30
	GameManager.public_opinion = 90.0
	GameManager.personal_wealth = 0
	GameManager.suspicion_level = 5.0
	GameManager.event_flags.clear()

	var eval: Dictionary = EndingsManager.evaluate_mandate()
	assert(eval["end_key"] == "END_SAINT", "Expected END_SAINT, got: %s" % eval["end_key"])
	assert(eval["letter_grade"] == "S", "Expected S grade, got: %s" % eval["letter_grade"])
	assert(eval["title_key"] == "TITLE_CIVIC_SAINT", "Expected TITLE_CIVIC_SAINT, got: %s" % eval["title_key"])
	assert(not eval["epilogue_text"].is_empty(), "Epilogue text must not be empty")

	print("  -> Evaluated: %s, Grade: %s, Title: %s" % [eval["end_key"], eval["letter_grade"], eval["title_key"]])
	print("  [PASS] Test 1: Civic Saint Evaluation verified.\n")
	passed_tests += 1


func test_2_teflon_mastermind_evaluation() -> void:
	print("[TEST 2] Verifying Teflon Mastermind secret corrupt victory (S Grade)...")
	GameManager.reset_state()
	GameManager.current_day = 30
	GameManager.personal_wealth = 260000
	GameManager.public_opinion = 72.0
	GameManager.suspicion_level = 20.0
	GameManager.event_flags.clear()

	var eval: Dictionary = EndingsManager.evaluate_mandate()
	assert(eval["end_key"] == "END_TEFLON_DON", "Expected END_TEFLON_DON, got: %s" % eval["end_key"])
	assert(eval["letter_grade"] == "S", "Expected S grade, got: %s" % eval["letter_grade"])
	assert(eval["title_key"] == "TITLE_TEFLON_MASTERMIND", "Expected TITLE_TEFLON_MASTERMIND, got: %s" % eval["title_key"])

	print("  -> Evaluated: %s, Grade: %s, Title: %s" % [eval["end_key"], eval["letter_grade"], eval["title_key"]])
	print("  [PASS] Test 2: Teflon Mastermind Evaluation verified.\n")
	passed_tests += 1


func test_3_report_card_ui_display() -> void:
	print("[TEST 3] Verifying Mayoral Report Card Modal UI instantiation & population...")
	var scene: PackedScene = load("res://scenes/summary/MayoralReportCardModal.tscn")
	assert(scene != null, "MayoralReportCardModal.tscn must be loadable")

	var modal = scene.instantiate()
	add_child(modal)
	await get_tree().process_frame

	var dummy_eval: Dictionary = {
		"end_key": "END_SAINT",
		"letter_grade": "S",
		"title_key": "TITLE_CIVIC_SAINT",
		"epilogue_text": "A bronze monument stands in the central plaza...",
		"stats": {
			"wealth": 0,
			"opinion": 92.5,
			"suspicion": 4.0,
			"budget": 180000,
			"day": 30
		},
		"districts": {
			"DIST_CENTRAL": {"name_key": "DIST_CENTRAL", "prosperity": 75.0},
			"DIST_HISTORIC": {"name_key": "DIST_HISTORIC", "prosperity": 80.0}
		}
	}

	modal.show_report_card(dummy_eval)
	await get_tree().process_frame

	# Check UI node populations
	var grade_lbl: Label = modal.get_node("%GradeLabel")
	var title_lbl: Label = modal.get_node("%TitleLabel")
	var historic_lbl: Label = modal.get_node("%HistoricTitleLabel")
	var narrative_lbl: Label = modal.get_node("%NarrativeLabel")
	var btn_restart: Button = modal.get_node("%BtnRestart")
	var btn_main_menu: Button = modal.get_node("%BtnMainMenu")

	assert(grade_lbl != null and grade_lbl.text == "S", "GradeLabel must show 'S'")
	assert(title_lbl != null and not title_lbl.text.is_empty(), "TitleLabel must be populated")
	assert(historic_lbl != null and not historic_lbl.text.is_empty(), "HistoricTitleLabel must be populated")
	assert(narrative_lbl != null and narrative_lbl.text.contains("bronze monument"), "NarrativeLabel must show epilogue text")
	assert(btn_restart != null, "BtnRestart must exist")
	assert(btn_main_menu != null, "BtnMainMenu must exist")

	modal.queue_free()
	await get_tree().process_frame

	print("  -> Scorecard UI verified: Grade 'S', title, epilogue narrative, and action buttons present.")
	print("  [PASS] Test 3: Report Card UI Display verified.\n")
	passed_tests += 1


func test_4_sudden_federal_supermax() -> void:
	print("[TEST 4] Verifying sudden Federal Supermax collapse on 100% suspicion...")
	GameManager.reset_state()
	GameManager.current_day = 14
	GameManager.suspicion_level = 100.0
	GameManager.public_opinion = 60.0

	var eval: Dictionary = EndingsManager.evaluate_mandate()
	assert(eval["end_key"] == "END_FEDERAL_SUPERMAX", "Expected END_FEDERAL_SUPERMAX on 100%% suspicion, got: %s" % eval["end_key"])
	assert(eval["letter_grade"] == "F", "Expected F grade for federal supermax, got: %s" % eval["letter_grade"])
	assert(eval["title_key"] == "TITLE_CONVICTED_FELON", "Expected TITLE_CONVICTED_FELON, got: %s" % eval["title_key"])

	print("  -> Evaluated: %s, Grade: %s, Title: %s" % [eval["end_key"], eval["letter_grade"], eval["title_key"]])
	print("  [PASS] Test 4: Sudden Federal Supermax verified.\n")
	passed_tests += 1


func test_5_eco_utopia_evaluation() -> void:
	print("[TEST 5] Verifying Eco Utopia ending on Green Faction dominance...")
	GameManager.reset_state()
	GameManager.current_day = 30
	GameManager.public_opinion = 68.0
	GameManager.personal_wealth = 10000
	GameManager.suspicion_level = 15.0
	GameManager.event_flags.clear()

	if FactionManager != null:
		FactionManager.reset_state()
		FactionManager.factions["greens"]["value"] = 88.0

	var eval: Dictionary = EndingsManager.evaluate_mandate()
	assert(eval["end_key"] == "END_ECO_UTOPIA", "Expected END_ECO_UTOPIA, got: %s" % eval["end_key"])
	assert(eval["letter_grade"] == "S", "Expected S grade for Eco Utopia, got: %s" % eval["letter_grade"])
	assert(eval["title_key"] == "TITLE_EMERALD_METROPOLIS", "Expected TITLE_EMERALD_METROPOLIS, got: %s" % eval["title_key"])

	print("  -> Evaluated: %s, Grade: %s, Title: %s" % [eval["end_key"], eval["letter_grade"], eval["title_key"]])
	print("  [PASS] Test 5: Eco Utopia Evaluation verified.\n")
	passed_tests += 1


func test_6_day_1_decisions_do_not_end_game() -> void:
	print("[TEST 6] Verifying Day 1 decisions do NOT trigger false-positive mandate game over...")
	GameManager.reset_state()
	assert(GameManager.current_day == 1, "Game must start on Day 1")
	assert(GameManager.is_game_over == false, "Game must not be over at start")

	# Approve decision effects
	GameManager.apply_resolution({"public_opinion": 5.0, "budget": 10000})
	assert(GameManager.is_game_over == false, "Approving on Day 1 must NOT trigger game over")

	# Reject decision effects
	GameManager.apply_resolution({"public_opinion": -5.0, "budget": -5000})
	assert(GameManager.is_game_over == false, "Rejecting on Day 1 must NOT trigger game over")

	print("  -> Verified: Day 1 approval and rejection leave is_game_over = false.")
	print("  [PASS] Test 6: Day 1 decisions integrity verified.\n")
	passed_tests += 1
