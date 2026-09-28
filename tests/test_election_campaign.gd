extends Node

## test_election_campaign.gd - Acceptance test suite for Mayoral Election Campaign Sprint (Spec 08).

var passed_tests: int = 0
var total_tests: int = 3

@onready var election_mgr: Node = get_node("/root/ElectionManager")
@onready var game_mgr: Node = get_node("/root/GameManager")


func _ready() -> void:
	print("\n========================================================")
	print(">>> RUNNING MAYORAL ELECTION CAMPAIGN TESTS <<<")
	print("========================================================\n")

	await test_test_1_campaign_trigger_on_day_23()
	await test_test_2_polling_swing_on_decision()
	await test_test_3_ballot_counting_climax()

	print("\n========================================================")
	if passed_tests == total_tests:
		print(">>> ALL 3 ELECTION CAMPAIGN TESTS PASSED! (3/3) <<<")
	else:
		print(">>> TEST FAILURES DETECTED! (%d/%d) <<<" % [passed_tests, total_tests])
	print("========================================================\n")

	get_tree().quit(0 if passed_tests == total_tests else 1)


func test_test_1_campaign_trigger_on_day_23() -> void:
	print("[TEST 1] Verifying Election Sprint activates on Day 23 with dynamic rival selection...")
	election_mgr.reset_state()
	game_mgr.start_new_game()

	assert(election_mgr.is_campaign_active == false, "Campaign must not be active before Day 23")

	# Activate Day 23
	election_mgr.activate_campaign(23)

	assert(election_mgr.is_campaign_active == true, "Campaign must be active on Day 23")
	assert(not election_mgr.rival_id.is_empty(), "Rival candidate must be assigned")
	assert(election_mgr.rival_id == "reformer" or election_mgr.rival_id == "populist", "Rival must be reformer or populist")

	print("  -> Campaign successfully activated on Day 23 vs rival: %s." % election_mgr.rival_id)
	print("  [PASS] Test 1: Campaign Trigger on Day 23 verified.\n")
	passed_tests += 1


func test_test_2_polling_swing_on_decision() -> void:
	print("[TEST 2] Verifying permit approval swings district voter polling...")
	election_mgr.reset_state()
	election_mgr.activate_campaign(23)

	var initial_poll: float = float(election_mgr.district_polls["DIST_HISTORIC"])

	var event = EventData.new()
	event.id = "TEST_HISTORIC_PETITION"
	event.category = "heritage"
	event.application_data = {"district_id": "DIST_HISTORIC"}
	event.violations.clear()

	# Approve compliant historic petition
	election_mgr.process_decision(event, true, false)

	var new_poll: float = float(election_mgr.district_polls["DIST_HISTORIC"])
	assert(new_poll > initial_poll, "Compliant approval must increase incumbent vote share")
	assert(election_mgr.incumbent_poll > 0.0, "Aggregate incumbent poll must be positive")

	print("  -> Permit decision swung DIST_HISTORIC polling from %.1f%% to %.1f%%." % [initial_poll, new_poll])
	print("  [PASS] Test 2: Polling Swing on Decision verified.\n")
	passed_tests += 1


func test_test_3_ballot_counting_climax() -> void:
	print("[TEST 3] Verifying 3 of 5 district threshold awards reelection victory vs defeat...")
	election_mgr.reset_state()
	election_mgr.activate_campaign(23)

	# Case A: 3 of 5 districts won -> Victory
	election_mgr.district_polls = {
		"DIST_CENTRAL": 55.0,
		"DIST_RIVERBED": 52.0,
		"DIST_INDUSTRIAL": 51.0,
		"DIST_HISTORIC": 44.0,
		"DIST_SUBURBS": 42.0
	}
	var victory_a: bool = election_mgr.run_election_tally()
	assert(victory_a == true, "3 of 5 districts must result in reelection victory")

	# Case B: 2 of 5 districts won -> Defeat
	election_mgr.district_polls = {
		"DIST_CENTRAL": 55.0,
		"DIST_RIVERBED": 52.0,
		"DIST_INDUSTRIAL": 45.0,
		"DIST_HISTORIC": 44.0,
		"DIST_SUBURBS": 42.0
	}
	var victory_b: bool = election_mgr.run_election_tally()
	assert(victory_b == false, "2 of 5 districts must result in election defeat")

	print("  -> Election tally rules verified: 3/5 won = Victory, 2/5 won = Defeat.")
	print("  [PASS] Test 3: Ballot Counting Climax verified.\n")
	passed_tests += 1
