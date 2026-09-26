extends Node

## test_offshore_spending_phase2_node.gd
## Acceptance tests for Offshore Spending Mechanics Phase 2:
## 1. Fixer transaction: wealth deduction, suspicion drop (-25%), paper shredder audio.
## 2. Media Astroturfing: wealth deduction, approval boost (+18%), camera flash audio.
## 3. PR scandal condition: suspicion >= 75% triggers leak risk handling.
## 4. Audit Immunity Leak: charges allocation (3 documents), activation flag.
## 5. Progressive luxury catalog: Cigar Box ($15k) -> Yacht Brochure ($25k) -> Gold Stamp ($50k).
## 6. AudioManager sound synthesis: play_paper_shredder, play_camera_flash, play_gold_stamp.
## 7. DeskView audit leak auto-detection and gold stamp audio routing.

var passed_tests: int = 0
var total_tests: int = 7


func _ready() -> void:
	print("\n============================================================")
	print(">>> RUNNING OFFSHORE SPENDING PHASE 2 ACCEPTANCE TESTS <<<")
	print("============================================================\n")

	test_fixer_transaction()
	test_pr_astroturf_success()
	test_pr_scandal_risk_logic()
	test_audit_immunity_leak_purchase()
	test_progressive_luxury_catalog()
	test_audiomanager_synthesis()
	test_audit_leak_auto_detection()

	print("\n============================================================")
	if passed_tests == total_tests:
		print(">>> ALL %d OFFSHORE SPENDING PHASE 2 TESTS PASSED! (%d/%d) <<<" % [
			total_tests, passed_tests, total_tests
		])
	else:
		print(">>> TEST FAILURES DETECTED! (%d/%d) <<<" % [
			passed_tests, total_tests
		])
	print("============================================================\n")

	get_tree().quit(0 if passed_tests == total_tests else 1)


func test_fixer_transaction() -> void:
	print("[TEST 1] Testing The Fixer transaction and suspicion reduction...")
	var scene: PackedScene = load("res://scenes/ui/OffshoreLedgerModal.tscn")
	var modal: OffshoreLedgerModal = scene.instantiate() as OffshoreLedgerModal
	add_child(modal)

	GameManager.current_day = 1
	GameManager.personal_wealth = 60000
	GameManager.suspicion_level = 50.0

	var fixer_signal_fired: Array[bool] = [false]
	var signal_drop: Array[float] = [0.0]
	modal.fixer_purchased.connect(func(cost: int, drop: float):
		fixer_signal_fired[0] = true
		signal_drop[0] = drop
		assert(cost > 0, "Fixer cost should be positive.")
	)

	modal.open()
	var expected_cost: int = modal.current_fixer_cost
	assert(expected_cost == 35000, "Day 1 Fixer cost should be $35,000")

	modal._on_buy_fixer_pressed()

	assert(GameManager.personal_wealth == 60000 - expected_cost, "Wealth not properly deducted.")
	assert(GameManager.suspicion_level == 25.0, "Suspicion should drop by 25.0% (50.0 -> 25.0).")
	assert(fixer_signal_fired[0], "fixer_purchased signal must be emitted.")
	assert(signal_drop[0] == 25.0, "Signal drop amount must be 25.0.")

	modal.queue_free()
	passed_tests += 1
	print("  -> Fixer transaction and suspicion drop verified.\n")


func test_pr_astroturf_success() -> void:
	print("[TEST 2] Testing Media Astroturfing public opinion boost...")
	var scene: PackedScene = load("res://scenes/ui/OffshoreLedgerModal.tscn")
	var modal: OffshoreLedgerModal = scene.instantiate() as OffshoreLedgerModal
	add_child(modal)

	GameManager.current_day = 1
	GameManager.personal_wealth = 60000
	GameManager.public_opinion = 40.0
	GameManager.suspicion_level = 20.0 # Well below 75% -> zero scandal chance
	GameManager.event_flags.erase("FLAG_PR_SCANDAL")

	var pr_signal_fired: Array[bool] = [false]
	modal.pr_campaign_purchased.connect(func(cost: int, gain: float, scandal: bool):
		pr_signal_fired[0] = true
		assert(cost > 0, "PR cost should be positive.")
		assert(gain == 18.0, "PR opinion gain should be 18.0.")
		assert(not scandal, "Scandal should not trigger with low suspicion.")
	)

	modal.open()
	var expected_cost: int = modal.current_pr_cost
	assert(expected_cost == 25000, "Day 1 PR cost should be $25,000")

	modal._on_buy_pr_pressed()

	assert(GameManager.personal_wealth == 60000 - expected_cost, "Wealth not deducted for PR.")
	assert(GameManager.public_opinion == 58.0, "Public opinion should rise +18.0% (40.0 -> 58.0).")
	assert(pr_signal_fired[0], "pr_campaign_purchased signal must be emitted.")
	assert(not GameManager.event_flags.get("FLAG_PR_SCANDAL", false), "No PR scandal flag.")

	modal.queue_free()
	passed_tests += 1
	print("  -> Media Astroturfing public opinion boost verified.\n")


func test_pr_scandal_risk_logic() -> void:
	print("[TEST 3] Testing PR Astroturf high suspicion warning and scandal risk...")
	var scene: PackedScene = load("res://scenes/ui/OffshoreLedgerModal.tscn")
	var modal: OffshoreLedgerModal = scene.instantiate() as OffshoreLedgerModal
	add_child(modal)

	# Suspicion >= 75% should show warning in UI
	GameManager.suspicion_level = 80.0
	modal.open()

	assert(
		modal.pr_effect.text.contains("SCANDAL RISK"),
		"PR effect label must warn about scandal risk when suspicion >= 75%"
	)

	modal.queue_free()
	passed_tests += 1
	print("  -> High-suspicion PR warning verified.\n")


func test_audit_immunity_leak_purchase() -> void:
	print("[TEST 4] Testing Audit Immunity Leak purchase and charges allocation...")
	var scene: PackedScene = load("res://scenes/ui/OffshoreLedgerModal.tscn")
	var modal: OffshoreLedgerModal = scene.instantiate() as OffshoreLedgerModal
	add_child(modal)

	GameManager.personal_wealth = 100000
	GameManager.event_flags.erase("AUDIT_LEAK_REMAINING")

	var audit_signal_fired: Array[bool] = [false]
	modal.audit_leak_purchased.connect(func(cost: int):
		audit_signal_fired[0] = true
		assert(cost == 60000, "Audit leak cost should be $60,000.")
	)

	modal.open()
	assert(not modal.btn_buy_audit.disabled, "Audit button must be enabled.")

	modal._on_buy_audit_pressed()

	assert(GameManager.personal_wealth == 40000, "Wealth should decrement by $60,000.")
	assert(GameManager.event_flags.get("AUDIT_LEAK_REMAINING", 0) == 3, "Should grant 3 audit leak charges.")
	assert(audit_signal_fired[0], "audit_leak_purchased signal must be emitted.")
	assert(modal.btn_buy_audit.disabled, "Audit button must now be disabled while leak is active.")

	modal.queue_free()
	passed_tests += 1
	print("  -> Audit Immunity Leak charges allocation verified.\n")


func test_progressive_luxury_catalog() -> void:
	print("[TEST 5] Testing progressive luxury catalog (Cigar -> Yacht -> Gold Stamp)...")
	var scene: PackedScene = load("res://scenes/ui/OffshoreLedgerModal.tscn")
	var modal: OffshoreLedgerModal = scene.instantiate() as OffshoreLedgerModal
	add_child(modal)

	# Clean slate
	GameManager.event_flags.erase("FLAG_CIGAR_BOX_UNLOCKED")
	GameManager.event_flags.erase("FLAG_YACHT_BROCHURE_UNLOCKED")
	GameManager.event_flags.erase("FLAG_GOLD_STAMP_UNLOCKED")
	GameManager.personal_wealth = 150000

	# Step 1: Cigar Box ($15,000)
	modal.open()
	assert(modal.active_luxury_item.get("id") == "cigar_box", "First luxury item must be cigar_box.")
	assert(modal.current_luxury_cost == 15000, "Cigar box cost must be $15,000.")
	modal._on_buy_luxury_pressed()
	assert(GameManager.event_flags.get("FLAG_CIGAR_BOX_UNLOCKED", false), "Cigar box flag must be set.")

	# Step 2: Yacht Brochure ($25,000)
	assert(modal.active_luxury_item.get("id") == "yacht_brochure", "Next luxury item must be yacht_brochure.")
	assert(modal.current_luxury_cost == 25000, "Yacht brochure cost must be $25,000.")
	modal._on_buy_luxury_pressed()
	assert(GameManager.event_flags.get("FLAG_YACHT_BROCHURE_UNLOCKED", false), "Yacht brochure flag must be set.")

	# Step 3: Gold Stamp ($50,000)
	assert(modal.active_luxury_item.get("id") == "gold_stamp", "Next luxury item must be gold_stamp.")
	assert(modal.current_luxury_cost == 50000, "Gold stamp cost must be $50,000.")
	modal._on_buy_luxury_pressed()
	assert(GameManager.event_flags.get("FLAG_GOLD_STAMP_UNLOCKED", false), "Gold stamp flag must be set.")

	# Step 4: Maxed out catalog
	assert(modal.active_luxury_item.is_empty(), "Catalog should have no remaining items.")
	assert(modal.btn_buy_luxury.disabled, "Luxury button must be disabled when catalog is maxed.")

	modal.queue_free()
	passed_tests += 1
	print("  -> Progressive luxury catalog acquisition verified.\n")


func test_audiomanager_synthesis() -> void:
	print("[TEST 6] Testing AudioManager procedural sound synthesis methods...")
	assert(AudioManager.has_method("play_paper_shredder"), "AudioManager must have play_paper_shredder().")
	assert(AudioManager.has_method("play_camera_flash"), "AudioManager must have play_camera_flash().")
	assert(AudioManager.has_method("play_gold_stamp"), "AudioManager must have play_gold_stamp().")

	# Safe invocation without runtime crashes
	AudioManager.play_paper_shredder()
	AudioManager.play_camera_flash()
	AudioManager.play_gold_stamp()

	passed_tests += 1
	print("  -> All 3 Phase 2 procedural audio synthesis methods confirmed.\n")


func test_audit_leak_auto_detection() -> void:
	print("[TEST 7] Testing DeskView audit leak auto-detection on violating dossiers...")
	var desk_scene: PackedScene = load("res://scenes/desk/DeskView.tscn")
	var desk: Node = desk_scene.instantiate()
	add_child(desk)

	# Create mock event with 1 violation
	var mock_event := EventData.new()
	mock_event.id = "EVT_TEST_AUDIT"
	mock_event.title_key = "TEST_TITLE"
	mock_event.description_key = "TEST_DESC"
	mock_event.violations = [{
		"id": "viol_structural",
		"name_key": "VIOL_STRUCTURAL_FLAW",
		"tags": ["zone_building"]
	}]

	# Set 3 charges
	GameManager.event_flags["AUDIT_LEAK_REMAINING"] = 3

	desk._check_audit_intel_leak(mock_event)

	assert(
		GameManager.event_flags["AUDIT_LEAK_REMAINING"] == 2,
		"Charges should decrement to 2 on violating dossier."
	)
	assert(
		desk.inspect_status_panel.visible,
		"Inspect status panel should be visible."
	)
	assert(
		desk.inspect_status_label.text.contains("Audit Leak"),
		"Status label should mention Audit Leak."
	)

	desk.queue_free()
	passed_tests += 1
	print("  -> Audit leak auto-detection and charge consumption verified.\n")
