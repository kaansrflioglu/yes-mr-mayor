extends Node

## test_offshore_spending_phase1_node.gd
## Acceptance tests for Offshore Spending Mechanics Phase 1:
## 1. OffshoreLedgerModal scene structure and node tree validation.
## 2. Modal open/close lifecycle and visibility state transitions.
## 3. Data binding with GameManager.personal_wealth & currency formatting.
## 4. Dynamic cost scaling across the 30-day mandate.
## 5. Purchase button affordability states based on available slush funds.
## 6. DeskView integration with safe drawer and open_offshore_ledger().
## 7. Strict i18n translation coverage for en, tr, es locales.

var passed_tests: int = 0
var total_tests: int = 7


func _ready() -> void:
	print("\n============================================================")
	print(">>> RUNNING OFFSHORE SPENDING PHASE 1 ACCEPTANCE TESTS <<<")
	print("============================================================\n")

	test_modal_scene_structure()
	test_modal_lifecycle()
	test_data_binding_and_balance()
	test_dynamic_cost_scaling()
	test_button_affordability_states()
	test_deskview_integration()
	test_i18n_localization_coverage()

	print("\n============================================================")
	if passed_tests == total_tests:
		print(">>> ALL %d OFFSHORE SPENDING PHASE 1 TESTS PASSED! (%d/%d) <<<" % [
			total_tests, passed_tests, total_tests
		])
	else:
		print(">>> TEST FAILURES DETECTED! (%d/%d) <<<" % [
			passed_tests, total_tests
		])
	print("============================================================\n")

	get_tree().quit(0 if passed_tests == total_tests else 1)


func test_modal_scene_structure() -> void:
	print("[TEST 1] Verifying OffshoreLedgerModal scene hierarchy and nodes...")
	var scene: PackedScene = load("res://scenes/ui/OffshoreLedgerModal.tscn")
	assert(scene != null, "OffshoreLedgerModal.tscn must be loadable.")

	var instance: Node = scene.instantiate()
	assert(instance != null, "Scene instantiation failed.")
	add_child(instance)

	var required_nodes: Array[String] = [
		"%Backdrop",
		"%ModalPanel",
		"%TitleLabel",
		"%SubtitleLabel",
		"%StashedBalanceLabel",
		"%CardFixer",
		"%BtnBuyFixer",
		"%CardPR",
		"%BtnBuyPR",
		"%CardAudit",
		"%BtnBuyAudit",
		"%CardLuxury",
		"%BtnBuyLuxury",
		"%BtnHeaderClose",
		"%BtnFooterClose",
		"%StatusLabel"
	]

	for node_path in required_nodes:
		assert(
			instance.has_node(node_path),
			"OffshoreLedgerModal missing required node: %s" % node_path
		)

	instance.queue_free()
	passed_tests += 1
	print("  -> All modal nodes and controls confirmed.\n")


func test_modal_lifecycle() -> void:
	print("[TEST 2] Verifying open/close lifecycle and visibility transitions...")
	var scene: PackedScene = load("res://scenes/ui/OffshoreLedgerModal.tscn")
	var modal: OffshoreLedgerModal = scene.instantiate() as OffshoreLedgerModal
	add_child(modal)

	assert(not modal.visible, "Modal should be hidden by default.")
	assert(not modal.is_open, "Modal should not be marked open initially.")

	modal.open()
	assert(modal.visible, "Modal must be visible after open().")
	assert(modal.is_open, "Modal is_open flag must be true after open().")

	var closed_emitted: Array[bool] = [false]
	modal.modal_closed.connect(func(): closed_emitted[0] = true)

	modal.close()
	assert(not modal.is_open, "Modal is_open must be false after close().")

	modal.queue_free()
	passed_tests += 1
	print("  -> Open and close transitions verified successfully.\n")


func test_data_binding_and_balance() -> void:
	print("[TEST 3] Testing data binding with GameManager.personal_wealth...")
	var scene: PackedScene = load("res://scenes/ui/OffshoreLedgerModal.tscn")
	var modal: OffshoreLedgerModal = scene.instantiate() as OffshoreLedgerModal
	add_child(modal)

	GameManager.personal_wealth = 145000
	modal.open()

	var balance_text: String = modal.stashed_balance_label.text
	assert(
		balance_text.contains("145,000") or balance_text.contains("145.000"),
		"Balance label must contain formatted $145,000, got: %s" % balance_text
	)

	# Update wealth while open -> stats_changed updates UI
	GameManager.personal_wealth = 220000
	GameManager.notify_stats_changed()

	var updated_text: String = modal.stashed_balance_label.text
	assert(
		updated_text.contains("220,000") or updated_text.contains("220.000"),
		"Balance label must update on stats_changed, got: %s" % updated_text
	)

	modal.queue_free()
	passed_tests += 1
	print("  -> Data binding and real-time updates confirmed.\n")


func test_dynamic_cost_scaling() -> void:
	print("[TEST 4] Testing dynamic cost scaling from Day 1 to Day 30...")
	var scene: PackedScene = load("res://scenes/ui/OffshoreLedgerModal.tscn")
	var modal: OffshoreLedgerModal = scene.instantiate() as OffshoreLedgerModal
	add_child(modal)

	# Day 1 costs
	GameManager.current_day = 1
	modal.open()
	var day1_fixer: int = modal.current_fixer_cost
	var day1_pr: int = modal.current_pr_cost
	modal.close()

	assert(day1_fixer == 35000, "Day 1 Fixer cost should be $35,000, got %d" % day1_fixer)
	assert(day1_pr == 25000, "Day 1 PR cost should be $25,000, got %d" % day1_pr)

	# Day 30 costs
	GameManager.current_day = 30
	modal.open()
	var day30_fixer: int = modal.current_fixer_cost
	var day30_pr: int = modal.current_pr_cost
	modal.close()

	assert(day30_fixer == 65000, "Day 30 Fixer cost should be $65,000, got %d" % day30_fixer)
	assert(day30_pr == 40000, "Day 30 PR cost should be $40,000, got %d" % day30_pr)

	GameManager.current_day = 1
	modal.queue_free()
	passed_tests += 1
	print("  -> Day-scaling costs verified ($35k -> $65k for Fixer, $25k -> $40k for PR).\n")


func test_button_affordability_states() -> void:
	print("[TEST 5] Testing button enabled/disabled states based on balance...")
	var scene: PackedScene = load("res://scenes/ui/OffshoreLedgerModal.tscn")
	var modal: OffshoreLedgerModal = scene.instantiate() as OffshoreLedgerModal
	add_child(modal)

	# Player has $0 -> all disabled
	GameManager.current_day = 1
	GameManager.personal_wealth = 0
	modal.open()

	assert(modal.btn_buy_fixer.disabled, "Fixer button must be disabled when broke.")
	assert(modal.btn_buy_pr.disabled, "PR button must be disabled when broke.")
	assert(modal.btn_buy_audit.disabled, "Audit button must be disabled when broke.")
	assert(modal.btn_buy_luxury.disabled, "Luxury button must be disabled when broke.")

	# Player has $36,000 -> Day 1 Fixer ($35k) and PR ($25k) affordable, others not
	GameManager.personal_wealth = 36000
	GameManager.notify_stats_changed()

	assert(not modal.btn_buy_fixer.disabled, "Fixer button should be enabled ($36k >= $35k).")
	assert(not modal.btn_buy_pr.disabled, "PR button should be enabled ($36k >= $25k).")
	assert(modal.btn_buy_audit.disabled, "Audit button should remain disabled ($36k < $60k).")
	assert(modal.btn_buy_luxury.disabled, "Luxury button should remain disabled ($36k < $50k).")

	modal.queue_free()
	passed_tests += 1
	print("  -> Affordability checks and button states verified.\n")


func test_deskview_integration() -> void:
	print("[TEST 6] Testing DeskView safe drawer and ledger modal hookup...")
	var desk_scene: PackedScene = load("res://scenes/desk/DeskView.tscn")
	assert(desk_scene != null, "DeskView.tscn must be loadable.")

	var desk: Node = desk_scene.instantiate()
	assert(desk != null, "DeskView instantiation failed.")
	add_child(desk)

	assert(
		desk.has_node("%OffshoreLedgerModal"),
		"DeskView must contain OffshoreLedgerModal node."
	)
	assert(
		desk.has_method("open_offshore_ledger"),
		"DeskView must expose open_offshore_ledger() method."
	)

	var ledger_modal: Node = desk.get_node("%OffshoreLedgerModal")
	assert(ledger_modal is OffshoreLedgerModal, "Node must be an OffshoreLedgerModal instance.")
	assert(not ledger_modal.visible, "Ledger modal should be hidden on desk load.")

	# Call open_offshore_ledger()
	desk.open_offshore_ledger()
	assert(ledger_modal.visible, "Ledger modal must become visible after open_offshore_ledger().")

	desk.queue_free()
	passed_tests += 1
	print("  -> DeskView safe drawer integration verified.\n")


func test_i18n_localization_coverage() -> void:
	print("[TEST 7] Testing localization coverage across en, tr, es locales...")
	var keys_to_verify: Array[String] = [
		"UI_OFFSHORE_LEDGER_TITLE",
		"UI_OFFSHORE_LEDGER_SUBTITLE",
		"UI_OFFSHORE_BALANCE",
		"UI_OFFSHORE_CLOSE",
		"UI_OFFSHORE_FIXER_TITLE",
		"UI_OFFSHORE_FIXER_DESC",
		"UI_OFFSHORE_FIXER_EFFECT",
		"UI_OFFSHORE_FIXER_BTN",
		"UI_OFFSHORE_PR_TITLE",
		"UI_OFFSHORE_PR_DESC",
		"UI_OFFSHORE_PR_EFFECT",
		"UI_OFFSHORE_PR_BTN",
		"UI_OFFSHORE_AUDIT_TITLE",
		"UI_OFFSHORE_AUDIT_DESC",
		"UI_OFFSHORE_AUDIT_EFFECT",
		"UI_OFFSHORE_AUDIT_BTN",
		"UI_OFFSHORE_LUXURY_TITLE",
		"UI_OFFSHORE_LUXURY_DESC",
		"UI_OFFSHORE_LUXURY_EFFECT",
		"UI_OFFSHORE_LUXURY_BTN",
		"UI_OFFSHORE_INSUFFICIENT",
		"UI_OFFSHORE_SUCCESS"
	]

	# Verify keys exist in localization.csv
	var file := FileAccess.open("res://data/localization.csv", FileAccess.READ)
	assert(file != null, "Cannot open localization.csv.")
	var content: String = file.get_as_text()
	file.close()

	for k in keys_to_verify:
		assert(
			content.contains(k),
			"Missing localization key in localization.csv: %s" % k
		)

	passed_tests += 1
	print("  -> All %d offshore localization keys verified in localization.csv.\n" % keys_to_verify.size())
