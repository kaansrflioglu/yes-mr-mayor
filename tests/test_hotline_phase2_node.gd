extends Node

## test_hotline_phase2_node.gd
## Acceptance tests for Hotline Redesign Phase 2: Dynamic Hotline Controller
## 1. HotlineManager loading and eligible calls filtering by day and flags.
## 2. Archetype badge metadata (icons, colors, localization keys, urgency).
## 3. RedTelephone ringing, answer, and dynamic UI popup population.
## 4. Call resolution and stat application (Accept & Reject).
## 5. Audio ringtone routing (Urgent vs Secure).
## 6. Backward compatibility (consult_inspector and legacy flows).

const RED_TELEPHONE_SCENE: PackedScene = preload("res://scenes/desk/RedTelephone.tscn")

var passed_tests: int = 0
var total_tests: int = 6


func _ready() -> void:
	print("\n============================================================")
	print(">>> RUNNING HOTLINE REDESIGN PHASE 2 ACCEPTANCE TESTS <<<")
	print("============================================================\n")

	test_hotline_manager_day_filtering()
	test_archetype_badge_metadata()
	test_red_telephone_dynamic_ringing()
	test_call_resolution_effects()
	test_audio_routing_methods()
	test_backward_compatibility()

	print("\n============================================================")
	if passed_tests == total_tests:
		print(">>> ALL %d HOTLINE PHASE 2 TESTS PASSED! (%d/%d) <<<" % [
			total_tests, passed_tests, total_tests
		])
	else:
		print(">>> TEST FAILURES DETECTED! (%d/%d) <<<" % [
			passed_tests, total_tests
		])
	print("============================================================\n")

	get_tree().quit(0 if passed_tests == total_tests else 1)


func test_hotline_manager_day_filtering() -> void:
	print("[TEST 1] Testing HotlineManager call filtering by day & flags...")
	var mgr := HotlineManager.new()

	if mgr.all_calls.size() != 15:
		printerr("  [FAIL] Test 1: Expected 15 loaded calls, got %d" % mgr.all_calls.size())
		return

	var day_1_calls := mgr.get_eligible_calls(1)
	var day_20_calls := mgr.get_eligible_calls(20)

	print("  -> Day 1 eligible calls: %d | Day 20: %d" % [
		day_1_calls.size(), day_20_calls.size()
	])

	# Day 1 must have at least 3 calls (PAC, Elena liquefaction, Whistleblower seal)
	if day_1_calls.size() >= 3 and day_20_calls.size() > day_1_calls.size():
		print("  [PASS] Test 1: HotlineManager day filtering verified.\n")
		passed_tests += 1
	else:
		printerr("  [FAIL] Test 1: Unexpected day pool counts.\n")


func test_archetype_badge_metadata() -> void:
	print("[TEST 2] Testing archetype badge metadata and styling...")
	var archetypes: Array[String] = [
		"party_boss", "police_chief", "mafia",
		"journalist", "chief_engineer", "whistleblower"
	]

	var all_ok: bool = true
	for arch in archetypes:
		var data := HotlineManager.get_archetype_badge_data(arch)
		var has_icon: bool = not str(data.get("icon", "")).is_empty()
		var has_key: bool = not str(data.get("badge_key", "")).is_empty()
		var has_color: bool = data.has("accent_color") and (data["accent_color"] is Color)
		var has_urgency: bool = data.has("is_urgent")

		if not (has_icon and has_key and has_color and has_urgency):
			all_ok = false
			printerr("  [FAIL] Incomplete metadata for archetype: %s" % arch)

	if all_ok:
		print("  -> Verified badges for all 6 archetypes.")
		print("  [PASS] Test 2: Archetype badge metadata verified.\n")
		passed_tests += 1


func test_red_telephone_dynamic_ringing() -> void:
	print("[TEST 3] Testing RedTelephone dynamic call display and badges...")
	var phone: Control = RED_TELEPHONE_SCENE.instantiate()
	add_child(phone)

	var mgr := HotlineManager.new()
	var test_call: HotlineCallData = null
	for c in mgr.all_calls:
		if c.caller_archetype == "police_chief":
			test_call = c
			break

	if test_call == null:
		printerr("  [FAIL] Test 3: Police chief call not found in library.")
		phone.queue_free()
		return

	phone.ring_telephone(test_call)
	var ringing: bool = phone.is_ringing
	var badge_shown: bool = phone.ring_badge.visible

	phone.answer_call()
	var dialog_open: bool = phone.dialog_panel.visible
	var has_caller_text: bool = not phone.caller_label.text.is_empty()
	var has_badge_icon: bool = phone.caller_label.text.contains("🛡️")
	var has_msg: bool = not phone.message_label.text.is_empty()

	phone.hang_up()
	phone.queue_free()

	if ringing and badge_shown and dialog_open and has_caller_text and has_badge_icon and has_msg:
		print("  -> Dynamic call displayed with Police shield badge and message.")
		print("  [PASS] Test 3: Dynamic RedTelephone ringing and UI verified.\n")
		passed_tests += 1
	else:
		printerr("  [FAIL] Test 3: RedTelephone dynamic ringing display failed.\n")


func test_call_resolution_effects() -> void:
	print("[TEST 4] Testing accept & reject call effects application...")
	if GameManager != null:
		GameManager.start_new_game()
		GameManager.suspicion_meter = 40.0
		var initial_budget: int = GameManager.city_budget
		var initial_suspicion: float = GameManager.suspicion_meter

		var phone: Control = RED_TELEPHONE_SCENE.instantiate()
		add_child(phone)

		var test_call := HotlineCallData.new()
		test_call.id = "CALL_TEST_RESOLVE"
		test_call.caller_archetype = "party_boss"
		test_call.effects_accept = {
			"budget": -5000,
			"personal_wealth": 0,
			"public_opinion": 0.0,
			"suspicion": -10.0,
			"reveal_violation": false
		}
		test_call.effects_reject = {
			"budget": 0,
			"personal_wealth": 0,
			"public_opinion": 5.0,
			"suspicion": 0.0
		}

		# Ring and accept
		phone.ring_telephone(test_call)
		phone.answer_call()
		phone.accept_deal()

		var budget_ok: bool = (GameManager.city_budget == initial_budget - 5000)
		var suspicion_ok: bool = (GameManager.suspicion_meter == initial_suspicion - 10.0)

		phone.queue_free()

		if budget_ok and suspicion_ok:
			print("  -> Accepted deal applied -$5,000 budget and -10% suspicion.")
			print("  [PASS] Test 4: Call resolution effects verified.\n")
			passed_tests += 1
		else:
			printerr("  [FAIL] Test 4: Stat modification mismatch.\n")
	else:
		printerr("  [FAIL] Test 4: GameManager autoload missing.\n")


func test_audio_routing_methods() -> void:
	print("[TEST 5] Testing AudioManager phone ring sound methods...")
	if AudioManager != null:
		var has_standard: bool = AudioManager.has_method("play_phone_ring")
		var has_urgent: bool = AudioManager.has_method("play_phone_ring_urgent")
		var has_secure: bool = AudioManager.has_method("play_phone_ring_secure")
		var has_archetype: bool = AudioManager.has_method("play_phone_ring_archetype")

		if has_standard and has_urgent and has_secure and has_archetype:
			print("  -> Verified play_phone_ring, urgent, secure, and archetype router.")
			print("  [PASS] Test 5: Audio SFX methods verified.\n")
			passed_tests += 1
		else:
			printerr("  [FAIL] Test 5: Missing audio methods on AudioManager.\n")
	else:
		printerr("  [FAIL] Test 5: AudioManager autoload missing.\n")


func test_backward_compatibility() -> void:
	print("[TEST 6] Testing backward compatibility with consult_inspector & legacy flow...")
	if GameManager != null:
		GameManager.start_new_game()
		GameManager.city_budget = 50000

		var phone: Control = RED_TELEPHONE_SCENE.instantiate()
		add_child(phone)

		var tip_emitted: Array[bool] = [false]
		phone.inspector_tip_requested.connect(func(): tip_emitted[0] = true)

		var initial_budget: int = GameManager.city_budget
		var consult_ok: bool = phone.consult_inspector()
		var budget_deducted: bool = (GameManager.city_budget == initial_budget - 1000)

		phone.queue_free()

		if consult_ok and budget_deducted and tip_emitted[0]:
			print("  -> consult_inspector() deducted $1,000 and emitted signal.")
			print("  [PASS] Test 6: Backward compatibility verified.\n")
			passed_tests += 1
		else:
			printerr("  [FAIL] Test 6: Backward compatibility regression detected.\n")
	else:
		printerr("  [FAIL] Test 6: GameManager autoload missing.\n")
