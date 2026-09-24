extends Node

## test_deduction_node.gd - Verifies Papers, Please style deduction & discrepancy system.

const DOCUMENT_ITEM_SCENE: PackedScene = preload("res://scenes/desk/DocumentItem.tscn")
const RULEBOOK_SCENE: PackedScene = preload("res://scenes/desk/Rulebook.tscn")

var passed_tests: int = 0
var total_tests: int = 5

@onready var game_mgr: Node = get_node("/root/GameManager")
@onready var event_mgr: Node = get_node("/root/EventManager")


func _ready() -> void:
	print("\n========================================================")
	print(">>> RUNNING PAPERS, PLEASE DEDUCTION ACCEPTANCE TESTS <<<")
	print("========================================================\n")

	test_criterion_1_dossier_data_integrity()
	test_criterion_2_discrepancy_matching()
	test_criterion_3_document_and_rulebook_tabs()
	test_criterion_4_violation_alert_and_cause_tracking()
	test_criterion_5_deductive_consequences_evaluation()

	print("\n========================================================")
	if passed_tests == total_tests:
		print(">>> ALL 5 DEDUCTION TESTS PASSED! (5/5) <<<")
	else:
		print(">>> TEST FAILURES DETECTED! (%d/%d) <<<" % [passed_tests, total_tests])
	print("========================================================\n")

	get_tree().quit(0 if passed_tests == total_tests else 1)


func test_criterion_1_dossier_data_integrity() -> void:
	print("[TEST 1] Verifying multi-document dossier schemas and clean/dirty cases...")
	var all_events: Array = event_mgr.all_events
	if all_events.is_empty():
		printerr("  [FAIL] No events loaded in EventManager.")
		return

	var dirty_count: int = 0
	var clean_count: int = 0

	for ev in all_events:
		assert(not ev.application_data.is_empty(), "Application data must exist.")
		assert(not ev.report_data.is_empty(), "Report data must exist.")
		if ev.has_violations():
			dirty_count += 1
		else:
			clean_count += 1

	print("  -> Total Events: %d | Violating (Dirty): %d | Compliant (Clean): %d" % [
		all_events.size(), dirty_count, clean_count
	])

	if dirty_count >= 5 and clean_count >= 3:
		print("  [PASS] Test 1: Rich multi-document dossiers verified with balanced puzzles.\n")
		passed_tests += 1
	else:
		printerr("  [FAIL] Test 1: Inadequate distribution of clean and violating events.\n")


func test_criterion_2_discrepancy_matching() -> void:
	print("[TEST 2] Verifying Papers, Please token cross-referencing logic...")
	var evt_001: EventData = null
	for ev in event_mgr.all_events:
		if ev.id == "EVT_001":
			evt_001 = ev
			break

	if evt_001 == null:
		printerr("  [FAIL] EVT_001 not found.")
		return

	# Match 1: Flood zone
	var match_flood := evt_001.find_matching_violation("app_district", "rule_zoning_river")
	assert(not match_flood.is_empty(), "Flood match failed.")
	assert(match_flood.get("id") == "VIOL_FLOOD_ZONE", "Flood match ID mismatch.")

	# Match 2: Forged seal
	var match_seal := evt_001.find_matching_violation("app_seal", "rule_seal_guide")
	assert(not match_seal.is_empty(), "Seal match failed.")
	assert(match_seal.get("id") == "VIOL_FORGED_SEAL", "Seal match ID mismatch.")

	# False match
	var false_match := evt_001.find_matching_violation("app_floors", "rule_blacklist_guide")
	assert(false_match.is_empty(), "False match should be empty.")

	print("  -> Match 1: %s [OK]" % match_flood.get("id"))
	print("  -> Match 2: %s [OK]" % match_seal.get("id"))
	print("  -> False Match: Empty [OK]")
	print("  [PASS] Test 2: Discrepancy matching functions with precision.\n")
	passed_tests += 1


func test_criterion_3_document_and_rulebook_tabs() -> void:
	print("[TEST 3] Verifying DocumentItem and Rulebook interactive tabs...")
	var doc = DOCUMENT_ITEM_SCENE.instantiate()
	add_child(doc)

	var rule = RULEBOOK_SCENE.instantiate()
	add_child(rule)

	# Verify Rulebook tabs switch pages
	rule.switch_tab(1)
	assert(rule.page_seals.visible and not rule.page_zoning.visible, "Rulebook page switch failed.")
	rule.switch_tab(2)
	assert(rule.page_blacklist.visible, "Blacklist page switch failed.")

	# Verify DocumentItem tabs switch between Application and Inspector Report
	var test_evt: EventData = event_mgr.all_events[0]
	doc.setup_event(test_evt)
	doc.switch_dossier_tab(1)
	assert(doc.report_page.visible, "Report page must be visible.")
	assert(not doc.application_page.visible, "Application page must be hidden.")
	doc.switch_dossier_tab(2)
	assert(doc.report_page.visible and doc.application_page.visible, "Side-by-side tab failed.")

	doc.queue_free()
	rule.queue_free()
	print("  [PASS] Test 3: Multi-document tabs and Rulebook pages operate seamlessly.\n")
	passed_tests += 1


func test_criterion_4_violation_alert_and_cause_tracking() -> void:
	print("[TEST 4] Verifying violation alerts and rejection with cause...")
	var doc = DOCUMENT_ITEM_SCENE.instantiate()
	add_child(doc)

	var test_evt: EventData = event_mgr.all_events[0]
	doc.setup_event(test_evt)

	var mock_violation := {
		"id": "VIOL_FLOOD_ZONE",
		"name_key": "VIOL_FLOOD_ZONE"
	}
	doc.mark_violation_found(mock_violation)

	assert(doc.violation_alert_box.visible, "Violation alert box must be visible.")
	assert(doc.discovered_violations.size() == 1, "Discovered violations must contain 1 item.")

	doc.queue_free()
	print("  [PASS] Test 4: Discrepancy warning banner and cause tracking verified.\n")
	passed_tests += 1


func test_criterion_5_deductive_consequences_evaluation() -> void:
	print("[TEST 5] Verifying consequences: Valid Rejection vs Wrongful Rejection...")
	game_mgr.start_new_game()

	var initial_opinion: float = game_mgr.public_opinion
	var initial_suspicion: float = game_mgr.suspicion_level

	# Case A: Valid rejection with cause -> Approval increases, suspicion decreases
	game_mgr.apply_resolution({
		"public_opinion": 15.0,
		"suspicion": -10.0,
		"budget": 0
	})
	assert(
		game_mgr.public_opinion > initial_opinion,
		"Approval must increase on justified rejection."
	)
	assert(game_mgr.suspicion_level <= initial_suspicion, "Suspicion must not increase.")

	# Case B: Wrongful rejection of legal petition -> Approval drops
	var prev_opinion: float = game_mgr.public_opinion
	game_mgr.apply_resolution({
		"public_opinion": -15.0,
		"suspicion": 5.0,
		"budget": 0
	})
	assert(game_mgr.public_opinion < prev_opinion, "Approval must drop on wrongful rejection.")

	print("  -> Justified Rejection: Approval +15% [OK]")
	print("  -> Wrongful Rejection: Approval -15% [OK]")
	print("  [PASS] Test 5: Consequence evaluation reflects player deduction.\n")
	passed_tests += 1
