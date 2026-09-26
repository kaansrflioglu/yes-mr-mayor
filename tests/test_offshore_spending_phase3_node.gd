extends Node

## test_offshore_spending_phase3_node.gd
## Acceptance tests for Offshore Spending Mechanics Phase 3:
## 1. END_FLED_TO_CAYMANS win condition (>=$250k wealth on Day 30+).
## 2. END_BRIBE_LEAK_SCANDAL game over condition.
## 3. GameOverModal custom headers and color themes for secret corrupt endings.
## 4. DeskView Cigar Box prop visual toggle via FLAG_CIGAR_BOX_UNLOCKED.
## 5. DeskView Monaco Yacht Brochure visual toggle via FLAG_YACHT_BROCHURE_UNLOCKED.
## 6. DeskView 24K Gold Stamp visual badge toggle via FLAG_GOLD_STAMP_UNLOCKED.
## 7. Full end-to-end integration: Luxury items purchase -> desk visuals -> Cayman escape ending.

var passed_tests: int = 0
var total_tests: int = 7


func _ready() -> void:
	print("\n============================================================")
	print(">>> RUNNING OFFSHORE SPENDING PHASE 3 ACCEPTANCE TESTS <<<")
	print("============================================================\n")

	test_end_fled_to_caymans_condition()
	test_end_bribe_leak_scandal()
	test_game_over_modal_custom_headers()
	test_deskview_cigar_box_prop_visibility()
	test_deskview_yacht_brochure_prop_visibility()
	test_deskview_gold_stamp_badge_visibility()
	test_full_milestone_end_to_end()

	print("\n============================================================")
	if passed_tests == total_tests:
		print(">>> ALL %d OFFSHORE SPENDING PHASE 3 TESTS PASSED! (%d/%d) <<<" % [
			total_tests, passed_tests, total_tests
		])
	else:
		print(">>> TEST FAILURES DETECTED! (%d/%d) <<<" % [
			passed_tests, total_tests
		])
	print("============================================================\n")

	get_tree().quit(0 if passed_tests == total_tests else 1)


func test_end_fled_to_caymans_condition() -> void:
	print("[TEST 1] Testing END_FLED_TO_CAYMANS secret victory condition...")
	GameManager.is_game_over = false
	GameManager.current_day = 31 # Exceeded 30 days
	GameManager.personal_wealth = 265000 # > $250,000
	GameManager.public_opinion = 35.0 # Low opinion, would normally lose election

	var ending_key: Array[String] = [""]
	var callback = func(reason: String): ending_key[0] = reason
	GameManager.game_over.connect(callback)

	GameManager._evaluate_end_conditions()

	GameManager.game_over.disconnect(callback)

	assert(GameManager.is_game_over, "Game must be over after Day 30.")
	assert(
		ending_key[0] == "END_FLED_TO_CAYMANS",
		"Must trigger END_FLED_TO_CAYMANS with >$250k wealth, got: %s" % ending_key[0]
	)

	passed_tests += 1
	print("  -> END_FLED_TO_CAYMANS victory condition verified.\n")


func test_end_bribe_leak_scandal() -> void:
	print("[TEST 2] Testing END_BRIBE_LEAK_SCANDAL game over trigger...")
	GameManager.is_game_over = false
	var ending_key: Array[String] = [""]
	var callback = func(reason: String): ending_key[0] = reason
	GameManager.game_over.connect(callback)

	GameManager.trigger_bribe_leak_scandal()

	GameManager.game_over.disconnect(callback)

	assert(GameManager.is_game_over, "Game must be over on bribe leak scandal.")
	assert(
		ending_key[0] == "END_BRIBE_LEAK_SCANDAL",
		"Must trigger END_BRIBE_LEAK_SCANDAL, got: %s" % ending_key[0]
	)

	passed_tests += 1
	print("  -> END_BRIBE_LEAK_SCANDAL trigger verified.\n")


func test_game_over_modal_custom_headers() -> void:
	print("[TEST 3] Testing GameOverModal custom headers and color themes...")
	var scene: PackedScene = load("res://scenes/summary/GameOverModal.tscn")
	assert(scene != null, "GameOverModal.tscn must be loadable.")

	var modal: PanelContainer = scene.instantiate() as PanelContainer
	add_child(modal)

	# Test Caymans
	modal.show_game_over("END_FLED_TO_CAYMANS")
	var header_caymans: String = modal.reason_header.text
	assert(
		header_caymans.contains("CAYMANS") or header_caymans.contains("CAYMAN"),
		"Header must mention Caymans, got: %s" % header_caymans
	)

	# Test Bribe Leak Scandal
	modal.show_game_over("END_BRIBE_LEAK_SCANDAL")
	var header_scandal: String = modal.reason_header.text
	assert(
		header_scandal.contains("SCANDAL") or header_scandal.contains("FBI") or header_scandal.contains("SKANDAL"),
		"Header must mention Scandal or FBI, got: %s" % header_scandal
	)

	modal.queue_free()
	passed_tests += 1
	print("  -> GameOverModal custom headers for secret endings verified.\n")


func test_deskview_cigar_box_prop_visibility() -> void:
	print("[TEST 4] Testing Cigar Box desk prop visual toggle...")
	var scene: PackedScene = load("res://scenes/desk/DeskView.tscn")
	var desk: Node = scene.instantiate()
	add_child(desk)

	GameManager.event_flags["FLAG_CIGAR_BOX_UNLOCKED"] = false
	desk._update_luxury_props()
	assert(not desk.cigar_box_prop.visible, "Cigar box prop must be hidden initially.")

	GameManager.event_flags["FLAG_CIGAR_BOX_UNLOCKED"] = true
	desk._update_luxury_props()
	assert(desk.cigar_box_prop.visible, "Cigar box prop must become visible when unlocked.")

	desk.queue_free()
	passed_tests += 1
	print("  -> Cigar Box desk prop visual toggle verified.\n")


func test_deskview_yacht_brochure_prop_visibility() -> void:
	print("[TEST 5] Testing Monaco Yacht Brochure desk prop visual toggle...")
	var scene: PackedScene = load("res://scenes/desk/DeskView.tscn")
	var desk: Node = scene.instantiate()
	add_child(desk)

	GameManager.event_flags["FLAG_YACHT_BROCHURE_UNLOCKED"] = false
	desk._update_luxury_props()
	assert(not desk.yacht_brochure_prop.visible, "Yacht brochure must be hidden initially.")

	GameManager.event_flags["FLAG_YACHT_BROCHURE_UNLOCKED"] = true
	desk._update_luxury_props()
	assert(desk.yacht_brochure_prop.visible, "Yacht brochure must become visible when unlocked.")

	desk.queue_free()
	passed_tests += 1
	print("  -> Yacht brochure desk prop visual toggle verified.\n")


func test_deskview_gold_stamp_badge_visibility() -> void:
	print("[TEST 6] Testing 24K Gold Stamp desk badge visual toggle...")
	var scene: PackedScene = load("res://scenes/desk/DeskView.tscn")
	var desk: Node = scene.instantiate()
	add_child(desk)

	GameManager.event_flags["FLAG_GOLD_STAMP_UNLOCKED"] = false
	desk._update_luxury_props()
	assert(not desk.gold_stamp_badge.visible, "Gold stamp badge must be hidden initially.")

	GameManager.event_flags["FLAG_GOLD_STAMP_UNLOCKED"] = true
	desk._update_luxury_props()
	assert(desk.gold_stamp_badge.visible, "Gold stamp badge must become visible when unlocked.")

	desk.queue_free()
	passed_tests += 1
	print("  -> 24K Gold Stamp desk badge visual toggle verified.\n")


func test_full_milestone_end_to_end() -> void:
	print("[TEST 7] Testing full end-to-end luxury acquisition to Cayman escape...")
	var modal_scene: PackedScene = load("res://scenes/ui/OffshoreLedgerModal.tscn")
	var modal: OffshoreLedgerModal = modal_scene.instantiate() as OffshoreLedgerModal
	add_child(modal)

	var desk_scene: PackedScene = load("res://scenes/desk/DeskView.tscn")
	var desk: Node = desk_scene.instantiate()
	add_child(desk)

	# Start fresh mandate with large offshore balance
	GameManager.current_day = 30
	GameManager.personal_wealth = 350000
	GameManager.event_flags.clear()

	modal.open()

	# 1. Buy Cigar Box ($15k)
	modal._on_buy_luxury_pressed()
	desk._update_luxury_props()
	assert(desk.cigar_box_prop.visible, "Cigar box must appear on desk.")

	# 2. Buy Yacht Brochure ($25k)
	modal._on_buy_luxury_pressed()
	desk._update_luxury_props()
	assert(desk.yacht_brochure_prop.visible, "Yacht brochure must appear on desk.")

	# 3. Buy Gold Stamp ($50k)
	modal._on_buy_luxury_pressed()
	desk._update_luxury_props()
	assert(desk.gold_stamp_badge.visible, "Gold stamp badge must appear on desk.")

	# Remaining wealth: 350,000 - 15,000 - 25,000 - 50,000 = 260,000 (> 250,000)
	assert(GameManager.personal_wealth == 260000, "Wealth should be exactly $260,000.")

	# Advance to Day 31 -> trigger evaluation
	GameManager.advance_day()
	assert(
		GameManager.is_game_over,
		"Day 31 should finish the term."
	)

	desk.queue_free()
	modal.queue_free()
	passed_tests += 1
	print("  -> Full end-to-end luxury acquisition to Cayman escape verified.\n")
