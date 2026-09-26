extends Node

## test_milestone3_narrative_twists.gd
## Acceptance tests for Milestone 3: Federal Sting Bribes,
## Daily Executive Directives, and Twitch Chat Inspector Tool Voting.

const DESK_VIEW_SCENE: PackedScene = preload("res://scenes/desk/DeskView.tscn")

var passed_tests: int = 0
var total_tests: int = 6

@onready var game_mgr: Node = get_node("/root/GameManager")
@onready var event_mgr: Node = get_node("/root/EventManager")
@onready var directive_mgr: Node = get_node("/root/DirectiveManager")
@onready var twitch_mgr: Node = get_node("/root/TwitchManager")


func _ready() -> void:
	print("\n============================================================")
	print(">>> RUNNING INVESTIGATION MECHANICS MILESTONE 3 TESTS <<<")
	print("============================================================\n")

	test_federal_sting_uv_detection()
	test_federal_sting_pocket_consequence()
	test_daily_directives_catalog_and_progression()
	test_directive_impact_on_resolution()
	test_twitch_tool_command_parsing_and_consensus()
	test_twitch_tool_execution_integration()

	print("\n============================================================")
	if passed_tests == total_tests:
		print(">>> ALL %d MILESTONE 3 TESTS PASSED! (%d/%d) <<<" % [
			total_tests, passed_tests, total_tests
		])
	else:
		print(">>> TEST FAILURES DETECTED! (%d/%d) <<<" % [
			passed_tests, total_tests
		])
	print("============================================================\n")

	get_tree().quit(0 if passed_tests == total_tests else 1)


func _setup_desk() -> Control:
	game_mgr.start_new_game()
	directive_mgr.reset_state()
	twitch_mgr.reset_votes()
	twitch_mgr.reset_tool_votes()
	var desk = DESK_VIEW_SCENE.instantiate()
	add_child(desk)
	return desk


func test_federal_sting_uv_detection() -> void:
	print("[TEST 1] Verifying Federal Sting Bribes detected under UV Blacklight...")
	var desk = _setup_desk()

	# Create a mock federal sting event
	var sting_ev := EventData.new()
	sting_ev.id = "EVT_TEST_STING"
	sting_ev.bribe_offered = 85000
	sting_ev.is_federal_sting = true
	sting_ev.violations = [{"id": "VIOL_FORGED_SEAL", "tags": ["TAG_SEAL"]}]

	var doc: Control = desk.active_document
	assert(doc != null, "Active document must exist on desk.")
	doc.setup_event(sting_ev)

	# Verify normal lighting hides UV watermark labels
	assert(not doc.uv_bribe_label.visible, "UV bribe label must be hidden in normal light.")

	# Turn on UV Blacklight
	doc.set_uv_blacklight(true)
	assert(doc.uv_bribe_label.visible, "UV bribe label must be visible under UV light.")
	var expected_text: String = tr("UI_UV_STING_BRIBE")
	assert(doc.uv_bribe_label.text == expected_text, "UV bribe label must warn of Federal Sting.")
	print("  -> UV Sting Watermark Detected: %s [OK]" % doc.uv_bribe_label.text)

	# Clean bribe comparison
	var clean_ev := EventData.new()
	clean_ev.id = "EVT_TEST_CLEAN"
	clean_ev.bribe_offered = 20000
	clean_ev.is_federal_sting = false
	clean_ev.violations = []
	doc.setup_event(clean_ev)
	doc.set_uv_blacklight(true)
	assert(doc.uv_bribe_label.text == tr("UI_UV_CLEAN_BRIBE"), "Clean bribe must show clean label.")
	print("  -> Clean Bribe Watermark: %s [OK]" % doc.uv_bribe_label.text)

	desk.queue_free()
	print("  [PASS] Test 1: Federal Sting UV detection verified.\n")
	passed_tests += 1


func test_federal_sting_pocket_consequence() -> void:
	print("[TEST 2] Verifying Federal Sting pocketing triggers +25% suspicion & alert...")
	var desk = _setup_desk()

	var sting_ev := EventData.new()
	sting_ev.id = "EVT_TEST_STING_PENALTY"
	sting_ev.bribe_offered = 100000
	sting_ev.is_federal_sting = true

	game_mgr.active_event = sting_ev
	var doc: Control = desk.active_document
	doc.setup_event(sting_ev)

	var initial_susp: float = game_mgr.suspicion_level
	var initial_funds: int = game_mgr.personal_wealth

	# Pocket the marked bills
	doc.pocket_bribe()

	assert(
		game_mgr.personal_wealth == initial_funds + 100000,
		"Offshore funds must receive bribe amount."
	)
	assert(
		game_mgr.suspicion_level >= initial_susp + 25.0,
		"Federal sting must trigger immediate +25% suspicion!"
	)
	assert(desk.inspect_status_panel.visible, "Inspection status banner must be shown.")
	assert(
		desk.inspect_status_label.text.contains("FEDERAL"),
		"Alert banner must display federal sting warning."
	)
	print("  -> Suspicion jumped: %.1f -> %.1f (+25%%) [OK]" % [
		initial_susp, game_mgr.suspicion_level
	])
	print("  -> Status Alert: %s [OK]" % desk.inspect_status_label.text)

	desk.queue_free()
	print("  [PASS] Test 2: Federal Sting pocketing consequences verified.\n")
	passed_tests += 1


func test_daily_directives_catalog_and_progression() -> void:
	print("[TEST 3] Verifying Daily Directives catalog & progression mapping...")
	directive_mgr.reset_state()

	# Day 1: Standard
	var d1: Dictionary = directive_mgr.activate_directive_for_day(1)
	assert(d1.get("id") == directive_mgr.DIR_STANDARD, "Day 1 must be Standard Directive.")

	# Day 3: EPA Environmental Audit
	var d3: Dictionary = directive_mgr.activate_directive_for_day(3)
	assert(d3.get("id") == directive_mgr.DIR_EPA_AUDIT, "Day 3 must be EPA Audit Directive.")
	assert(bool(d3.get("eco_bonus", false)), "EPA Audit must enable eco bonus.")

	# Day 8: Budget Crisis
	var d8: Dictionary = directive_mgr.activate_directive_for_day(8)
	assert(d8.get("id") == directive_mgr.DIR_BUDGET_CRISIS, "Day 8 must be Budget Crisis.")
	assert(float(d8.get("budget_mult", 1.0)) == 1.5, "Budget multiplier must be 1.5x.")

	# Day 14: Anti-Corruption Crackdown
	var d14: Dictionary = directive_mgr.activate_directive_for_day(14)
	assert(d14.get("id") == directive_mgr.DIR_ANTI_CORRUPTION, "Day 14 must be Anti-Corruption.")
	assert(float(d14.get("suspicion_mult", 1.0)) == 3.0, "Suspicion multiplier must be 3x.")
	assert(directive_mgr.is_sting_override(), "Day 14 must force sting trap override.")

	# Day 22: Election Sprint
	var d22: Dictionary = directive_mgr.activate_directive_for_day(22)
	assert(d22.get("id") == directive_mgr.DIR_ELECTION_SPRINT, "Day 22 must be Election Sprint.")
	assert(float(d22.get("opinion_mult", 1.0)) == 2.0, "Opinion multiplier must be 2.0x.")

	print("  -> Directives progression catalog fully mapped across mandate [OK]")
	print("  [PASS] Test 3: Daily Directives progression verified.\n")
	passed_tests += 1


func test_directive_impact_on_resolution() -> void:
	print("[TEST 4] Verifying Directive resolution modifiers (EPA, Budget, Election)...")
	var desk = _setup_desk()

	# 1. Day 3 EPA Audit: Rejection of eco violation gives 2x approval bonus (+30%)
	directive_mgr.set_active_directive(directive_mgr.DIR_EPA_AUDIT)
	var eco_ev := EventData.new()
	eco_ev.id = "EVT_TEST_ECO"
	eco_ev.violations = [{"id": "VIOL_FLOOD_ZONE", "tags": ["TAG_FLOOD"]}]

	var base_effects := {"public_opinion": 15.0, "suspicion": -10.0, "budget": 0}
	var modified: Dictionary = directive_mgr.apply_modifiers(
		base_effects, eco_ev, false, false
	)
	assert(
		modified.get("public_opinion") == 30.0,
		"EPA audit must double approval bonus on eco rejection (15 -> 30)."
	)
	print("  -> EPA Eco Rejection Approval: +%.1f%% [OK]" % modified.get("public_opinion"))

	# 2. Day 8 Budget Crisis: 1.5x budget multiplier and no opinion penalty for rejection
	directive_mgr.set_active_directive(directive_mgr.DIR_BUDGET_CRISIS)
	var costly_ev := EventData.new()
	costly_ev.id = "EVT_TEST_COSTLY"
	var base_budget_effects := {"public_opinion": -15.0, "budget": 20000}
	var mod_crisis: Dictionary = directive_mgr.apply_modifiers(
		base_budget_effects, costly_ev, false, false
	)
	assert(
		mod_crisis.get("public_opinion") == 0.0,
		"Budget crisis must waive opinion penalty on project rejection."
	)
	print("  -> Budget Crisis Zero Rejection Penalty: %.1f [OK]" % mod_crisis.get("public_opinion"))

	# 3. Day 22 Election Sprint: Opinion changes doubled
	directive_mgr.set_active_directive(directive_mgr.DIR_ELECTION_SPRINT)
	var norm_ev := EventData.new()
	norm_ev.id = "EVT_TEST_NORM"
	var base_op_effects := {"public_opinion": 12.0}
	var mod_election: Dictionary = directive_mgr.apply_modifiers(
		base_op_effects, norm_ev, true, false
	)
	assert(
		mod_election.get("public_opinion") == 24.0,
		"Election sprint must double opinion impacts (12 -> 24)."
	)
	print("  -> Election Sprint Double Opinion: +%.1f%% [OK]" % mod_election.get("public_opinion"))

	desk.queue_free()
	print("  [PASS] Test 4: Directive resolution impact verified.\n")
	passed_tests += 1


func test_twitch_tool_command_parsing_and_consensus() -> void:
	print("[TEST 5] Verifying Twitch tool command parsing, deduplication & consensus...")
	twitch_mgr.reset_tool_votes()

	var tool_pcts := {"uv": 0.0, "phone": 0.0, "coffee": 0.0, "total": 0}
	var tool_cb = func(p_uv: float, p_ph: float, p_cf: float, tot: int):
		tool_pcts["uv"] = p_uv
		tool_pcts["phone"] = p_ph
		tool_pcts["coffee"] = p_cf
		tool_pcts["total"] = tot

	twitch_mgr.tool_vote_updated.connect(tool_cb)

	# Viewer 1 votes UV Blacklight (!uv)
	twitch_mgr.register_tool_command("user1", "!uv")
	assert(tool_pcts["total"] == 1, "Total tool votes must be 1.")
	assert(tool_pcts["uv"] == 100.0, "UV vote must be 100%.")

	# Viewer 2 votes Phone Hotline in Turkish (!ihbar)
	twitch_mgr.register_tool_command("user2", "!ihbar")
	assert(tool_pcts["total"] == 2, "Total tool votes must be 2.")
	assert(tool_pcts["uv"] == 50.0 and tool_pcts["phone"] == 50.0, "50-50 split between UV & phone.")

	# Viewer 3 votes Espresso in Turkish (!kahve)
	twitch_mgr.register_tool_command("user3", "!kahve")
	assert(tool_pcts["total"] == 3, "Total tool votes must be 3.")

	# Viewer 1 revotes Phone (!tipline) -> deduplication check
	twitch_mgr.register_tool_command("user1", "!tipline")
	assert(tool_pcts["total"] == 3, "Total votes must remain 3 after revote.")
	assert(twitch_mgr.votes_uv == 0, "User 1's UV vote must be removed.")
	assert(twitch_mgr.votes_phone == 2, "Phone must have 2 votes.")
	assert(twitch_mgr.get_winning_tool() == "phone", "Consensus tool must be 'phone'.")
	print("  -> Winning tool consensus: %s [OK]" % twitch_mgr.get_winning_tool())

	twitch_mgr.tool_vote_updated.disconnect(tool_cb)
	print("  [PASS] Test 5: Twitch tool command parsing and consensus verified.\n")
	passed_tests += 1


func test_twitch_tool_execution_integration() -> void:
	print("[TEST 6] Verifying Twitch winning tool execution on DeskView...")
	var desk = _setup_desk()
	twitch_mgr.reset_tool_votes()

	# Chat overwhelmingly votes for UV Blacklight
	twitch_mgr.register_tool_command("viewer_alpha", "!uv")
	twitch_mgr.register_tool_command("viewer_beta", "!blacklight")

	assert(not desk.is_uv_active, "UV light must initially be off.")

	# Streamer clicks Execute Winning Tool or TwitchManager emits execution
	var executed: String = twitch_mgr.execute_winning_tool()
	assert(executed == "uv", "Executed tool must be 'uv'.")
	assert(desk.is_uv_active, "DeskView UV light must toggle to active upon execution.")
	print("  -> DeskView UV Blacklight activated via Twitch audience vote [OK]")

	# Next round: Chat votes for Coffee Espresso
	twitch_mgr.reset_tool_votes()
	twitch_mgr.register_tool_command("viewer_gamma", "!espresso")
	desk.current_inspect_focus = 2

	var exec_coffee: String = twitch_mgr.execute_winning_tool()
	assert(exec_coffee == "coffee", "Executed tool must be 'coffee'.")
	assert(desk.current_inspect_focus == 4, "Focus AP must replenish to 4.")
	print("  -> Focus AP refilled to 4 via Twitch audience coffee vote [OK]")

	desk.queue_free()
	print("  [PASS] Test 6: Twitch tool execution integration verified.\n")
	passed_tests += 1
