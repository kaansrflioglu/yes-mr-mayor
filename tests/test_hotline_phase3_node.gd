extends Node

## test_hotline_phase3_node.gd
## Acceptance tests for Hotline Redesign Phase 3: Special Mechanics & Tabloid Integration
## 1. DocumentItem.highlight_suspicious_field execution and tab switching.
## 2. Reveal violation special mechanics on hotline accept.
## 3. GameManager hotline history recording and day query.
## 4. DayEndSummary newspaper headline population from hotline history.
## 5. Coverage of satirical headline keys across all archetypes and outcomes.

const DOCUMENT_SCENE: PackedScene = preload("res://scenes/desk/DocumentItem.tscn")
const DAY_SUMMARY_SCENE: PackedScene = preload("res://scenes/summary/DayEndSummary.tscn")
const RED_TELEPHONE_SCENE: PackedScene = preload("res://scenes/desk/RedTelephone.tscn")

var passed_tests: int = 0
var total_tests: int = 5


func _ready() -> void:
	print("\n============================================================")
	print(">>> RUNNING HOTLINE REDESIGN PHASE 3 ACCEPTANCE TESTS <<<")
	print("============================================================\n")

	test_document_highlight_suspicious_field()
	test_reveal_violation_mechanics()
	test_game_manager_hotline_history()
	test_day_end_summary_hotline_headline()
	test_all_archetypes_headline_keys()

	print("\n============================================================")
	if passed_tests == total_tests:
		print(">>> ALL %d HOTLINE PHASE 3 TESTS PASSED! (%d/%d) <<<" % [
			total_tests, passed_tests, total_tests
		])
	else:
		print(">>> TEST FAILURES DETECTED! (%d/%d) <<<" % [
			passed_tests, total_tests
		])
	print("============================================================\n")

	get_tree().quit(0 if passed_tests == total_tests else 1)


func test_document_highlight_suspicious_field() -> void:
	print("[TEST 1] Testing DocumentItem.highlight_suspicious_field()...")
	var doc: Control = DOCUMENT_SCENE.instantiate()
	add_child(doc)

	var evt := EventData.new()
	evt.id = "EVT_TEST_HIGHLIGHT"
	doc.setup_event(evt)

	var has_method: bool = doc.has_method("highlight_suspicious_field")
	if not has_method:
		printerr("  [FAIL] Test 1: highlight_suspicious_field method missing on DocumentItem.")
		doc.queue_free()
		return

	# Start on application tab
	doc.switch_dossier_tab(0)

	# Trigger highlight on report field (rep_soil) -> should switch to side-by-side
	doc.highlight_suspicious_field("rep_soil")
	var report_visible: bool = doc.report_page.visible

	# Trigger highlight on application seal
	doc.highlight_suspicious_field("app_seal")

	doc.queue_free()

	if has_method and report_visible:
		print("  -> highlight_suspicious_field executed and switched tab to show target.")
		print("  [PASS] Test 1: DocumentItem field highlight verified.\n")
		passed_tests += 1
	else:
		printerr("  [FAIL] Test 1: Tab switching or highlight failed.\n")


func test_reveal_violation_mechanics() -> void:
	print("[TEST 2] Testing reveal_violation mechanics via RedTelephone accept...")
	if GameManager == null:
		printerr("  [FAIL] Test 2: GameManager autoload missing.")
		return

	GameManager.start_new_game()
	var phone: Control = RED_TELEPHONE_SCENE.instantiate()
	add_child(phone)

	var tip_requested: Array[bool] = [false]
	phone.inspector_tip_requested.connect(func(): tip_requested[0] = true)

	# Create a call with reveal_violation: true
	var call := HotlineCallData.new()
	call.id = "CALL_TEST_WHISTLEBLOWER"
	call.caller_archetype = "whistleblower"
	call.effects_accept = {
		"budget": 0,
		"personal_wealth": 0,
		"public_opinion": 0.0,
		"suspicion": -5.0,
		"reveal_violation": true
	}

	phone.ring_telephone(call)
	phone.answer_call()
	phone.accept_deal()

	phone.queue_free()

	if tip_requested[0]:
		print("  -> Accepting tip call emitted inspector_tip_requested.")
		print("  [PASS] Test 2: Reveal violation mechanics verified.\n")
		passed_tests += 1
	else:
		printerr("  [FAIL] Test 2: inspector_tip_requested was not emitted.\n")


func test_game_manager_hotline_history() -> void:
	print("[TEST 3] Testing GameManager hotline history tracking...")
	if GameManager == null:
		printerr("  [FAIL] Test 3: GameManager missing.")
		return

	GameManager.start_new_game()

	var record_1 := {
		"day": 1,
		"call_id": "CALL_PARTY_PAC",
		"archetype": "party_boss",
		"accepted": true,
		"effects": {"budget": -30000}
	}
	var record_2 := {
		"day": 2,
		"call_id": "CALL_POLICE_RAID",
		"archetype": "police_chief",
		"accepted": false,
		"effects": {"public_opinion": 8.0}
	}

	GameManager.record_hotline_call(record_1)
	GameManager.record_hotline_call(record_2)

	var day_1_records := GameManager.get_hotline_history_for_day(1)
	var day_2_records := GameManager.get_hotline_history_for_day(2)
	var day_3_records := GameManager.get_hotline_history_for_day(3)

	var count_ok: bool = (
		day_1_records.size() == 1 and
		day_2_records.size() == 1 and
		day_3_records.size() == 0
	)

	if count_ok and day_1_records[0]["call_id"] == "CALL_PARTY_PAC":
		print("  -> Successfully recorded and retrieved hotline history per day.")
		print("  [PASS] Test 3: GameManager hotline history verified.\n")
		passed_tests += 1
	else:
		printerr("  [FAIL] Test 3: History query mismatch.\n")


func test_day_end_summary_hotline_headline() -> void:
	print("[TEST 4] Testing DayEndSummary integration with hotline history...")
	if GameManager == null:
		printerr("  [FAIL] Test 4: GameManager missing.")
		return

	GameManager.start_new_game()

	# Simulate day 1 call
	var record := {
		"day": 1,
		"call_id": "CALL_PARTY_PAC",
		"archetype": "party_boss",
		"accepted": true,
		"effects": {"budget": -30000}
	}
	GameManager.record_hotline_call(record)

	var summary: Control = DAY_SUMMARY_SCENE.instantiate()
	add_child(summary)
	summary.populate_summary(1)

	var headline_text: String = summary.headline_main.text
	var sub_text: String = summary.headline_sub.text
	var has_hotline_mention: bool = (
		headline_text.contains("Party") or
		headline_text.contains("PAC") or
		headline_text.contains("Parti") or
		sub_text.contains("Party") or
		sub_text.contains("PAC") or
		sub_text.contains("Parti") or
		sub_text.contains("☎️")
	)

	summary.queue_free()

	if has_hotline_mention:
		print("  -> Evening tabloid successfully printed hotline headline.")
		print("  [PASS] Test 4: DayEndSummary tabloid integration verified.\n")
		passed_tests += 1
	else:
		printerr("  [FAIL] Test 4: Tabloid did not reflect hotline call.\n")


func test_all_archetypes_headline_keys() -> void:
	print("[TEST 5] Testing tabloid headline keys across all 6 archetypes...")
	var archetypes: Array[String] = [
		"party_boss", "police_chief", "mafia",
		"journalist", "chief_engineer", "whistleblower"
	]

	var all_resolved: bool = true
	for arch in archetypes:
		var key_app := HotlineManager.get_hotline_headline_key(arch, true)
		var key_rej := HotlineManager.get_hotline_headline_key(arch, false)

		if key_app.is_empty() or key_rej.is_empty():
			all_resolved = false
			printerr("  [FAIL] Empty headline key for %s" % arch)
		else:
			print("  -> %s: APP='%s' | REJ='%s'" % [arch, key_app, key_rej])

	if all_resolved:
		print("  [PASS] Test 5: All archetype headline keys generated successfully.\n")
		passed_tests += 1
	else:
		printerr("  [FAIL] Test 5: Incomplete headline keys.\n")
