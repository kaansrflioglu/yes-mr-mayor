extends Node

## test_monthly_mandate_and_approval_crisis.gd
## Acceptance test suite for the 48-Month Mandate, Dynamic Approval Crisis, and Expanded Event Pool.

var passed_tests: int = 0
var total_tests: int = 6

@onready var game_mgr: Node = get_node("/root/GameManager")
@onready var endings_mgr: Node = get_node("/root/EndingsManager")
@onready var event_mgr: Node = get_node("/root/EventManager")
@onready var election_mgr: Node = get_node("/root/ElectionManager")


func _ready() -> void:
	print("\n========================================================")
	print(">>> RUNNING 48-MONTH MANDATE & APPROVAL SYSTEM TESTS <<<")
	print("========================================================\n")

	test_1_mandate_initialization_and_timeline()
	test_2_approval_drop_below_50_does_not_end_game()
	test_3_catastrophic_approval_drop_triggers_revolution()
	test_4_full_term_election_at_month_48()
	test_5_expanded_event_pool_coverage()
	test_6_topbar_month_display()

	print("\n========================================================")
	if passed_tests == total_tests:
		print(">>> ALL 6 48-MONTH MANDATE TESTS PASSED! (6/6) <<<")
	else:
		print(">>> FAILURES ENCOUNTERED: %d/%d passed <<<" % [passed_tests, total_tests])
	print("========================================================\n")

	get_tree().quit(0 if passed_tests == total_tests else 1)


func test_1_mandate_initialization_and_timeline() -> void:
	print("[TEST 1] Verifying 48-month mandate configuration and progress...")
	game_mgr.start_new_game()

	assert(game_mgr.MAX_MONTHS == 48, "MAX_MONTHS must be 48")
	assert(game_mgr.current_month == 1, "Game must start at Month 1")
	assert(game_mgr.current_day == 1, "current_day alias must equal current_month")

	# Advance 3 months
	game_mgr.advance_month()
	game_mgr.advance_month()
	game_mgr.advance_month()

	assert(game_mgr.current_month == 4, "Current month must be 4 after 3 advancements")
	assert(game_mgr.current_day == 4, "current_day alias must track current_month")
	assert(game_mgr.is_game_over == false, "Game must continue normally during Month 4")

	print("  -> Mandate correctly tracks 48 months (Current: Month %d / 48)." % game_mgr.current_month)
	print("  [PASS] Test 1: Mandate Timeline Initialization verified.\n")
	passed_tests += 1


func test_2_approval_drop_below_50_does_not_end_game() -> void:
	print("[TEST 2] Verifying public opinion dropping below 50% does NOT trigger game over...")
	game_mgr.start_new_game()
	game_mgr.current_month = 15 # Mid-term Year 2

	# Simulate tough decisions dropping approval to 35% and 25%
	game_mgr.public_opinion = 35.0
	game_mgr.apply_resolution({"public_opinion": -10.0}) # Now 25%

	assert(game_mgr.public_opinion == 25.0, "Public opinion should be 25.0%")
	assert(game_mgr.is_game_over == false, "Player must NOT lose the game when opinion drops below 50%!")

	# EndingsManager evaluation should not trigger game over prematurely
	var eval: Dictionary = endings_mgr.evaluate_mandate()
	assert(eval["end_key"].is_empty(), "Premature ending must not trigger at Month 15 when opinion is 25%")

	print("  -> Confirmed: Approval at 25.0%% does NOT cause game over during ongoing term.")
	print("  [PASS] Test 2: Approval Drop Under 50% Resilience verified.\n")
	passed_tests += 1


func test_3_catastrophic_approval_drop_triggers_revolution() -> void:
	print("[TEST 3] Verifying catastrophic collapse (<= 15%) triggers riot revolution...")
	game_mgr.start_new_game()
	game_mgr.current_month = 20

	# Plunge opinion to critical disaster zone
	game_mgr.apply_resolution({"public_opinion": -40.0}) # 50 - 40 = 10% <= 15%

	assert(game_mgr.public_opinion <= 15.0, "Opinion must be <= 15%")
	assert(game_mgr.is_game_over == true, "Catastrophic collapse <= 15% must trigger Game Over")

	var eval: Dictionary = endings_mgr.evaluate_mandate()
	assert(eval["end_key"] == "END_REVOLUTION_STORM", "Expected END_REVOLUTION_STORM, got: %s" % eval["end_key"])

	print("  -> Revolution storm triggered as expected on <= 15%% disaster collapse.")
	print("  [PASS] Test 3: Catastrophic Collapse verified.\n")
	passed_tests += 1


func test_4_full_term_election_at_month_48() -> void:
	print("[TEST 4] Verifying 48th Month Election Night verdict (Approval >= 50% vs < 50%)...")
	
	# Scenario A: Win reelection on high approval at Month 48
	game_mgr.start_new_game()
	game_mgr.current_month = 48
	game_mgr.public_opinion = 65.0
	game_mgr.advance_month() # Advance past month 48 -> triggers term end

	assert(game_mgr.is_game_over == true, "Term completion must end the game")
	var eval_win: Dictionary = endings_mgr.evaluate_mandate()
	assert(eval_win["end_key"] == "END_REELECTED", "Expected END_REELECTED on Month 48 victory")

	# Scenario B: Defeat on low approval at Month 48
	game_mgr.start_new_game()
	game_mgr.current_month = 48
	game_mgr.public_opinion = 35.0 # Low approval at election time!
	game_mgr.advance_month()

	assert(game_mgr.is_game_over == true, "Term completion must end the game")
	var eval_loss: Dictionary = endings_mgr.evaluate_mandate()
	assert(eval_loss["end_key"] == "END_ONE_TERM_MEDIOCRE", "Expected one-term ending on election defeat")

	print("  -> Verified: Month 48 cleanly evaluates democratic reelection vs defeat.")
	print("  [PASS] Test 4: Month 48 Election Reckoning verified.\n")
	passed_tests += 1


func test_5_expanded_event_pool_coverage() -> void:
	print("[TEST 5] Verifying 200+ event pool and eligibility across Year 3 & Year 4...")
	assert(game_mgr.event_database.size() >= 200, "Event database must contain at least 200 events")

	# Check that events exist for Month 40-48 (Year 4 Campaign sprint)
	var campaign_events: int = 0
	for ev in game_mgr.event_database:
		if ev.day_range.size() >= 2 and ev.day_range[1] >= 40:
			campaign_events += 1

	assert(campaign_events >= 20, "At least 20 events must be eligible for late-term (Months 40-48)")

	# Verify prepare_daily_queue works smoothly in Month 44
	game_mgr.current_month = 44
	var queue: Array[EventData] = event_mgr.prepare_daily_queue(4)
	assert(queue.size() > 0, "Daily queue must successfully draw events in Month 44")

	print("  -> Event database loaded %d events. Late-mandate queue verified." % game_mgr.event_database.size())
	print("  [PASS] Test 5: Expanded Event Pool verified.\n")
	passed_tests += 1


func test_6_topbar_month_display() -> void:
	print("[TEST 6] Verifying TopBarHUD Month counter formatting...")
	var topbar_scene = load("res://scenes/hud/TopBarHUD.tscn")
	assert(topbar_scene != null, "TopBarHUD scene must exist")

	var hud = topbar_scene.instantiate()
	add_child(hud)
	game_mgr.current_month = 12
	game_mgr.notify_stats_changed()

	var day_label: Label = hud.find_child("DayLabel", true, false)
	assert(day_label != null, "DayLabel must exist on HUD")
	assert("12" in day_label.text, "HUD label must contain current month '12'")

	hud.queue_free()
	print("  -> HUD successfully reflects Month 12.")
	print("  [PASS] Test 6: HUD Month Display verified.\n")
	passed_tests += 1
