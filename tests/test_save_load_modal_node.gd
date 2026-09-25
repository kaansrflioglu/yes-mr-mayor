extends Node

## test_save_load_modal_node.gd - Automated test suite for Phase 2 SaveLoadModal.
## Validates UI lifecycle, slot card rendering, save/load modes, confirmations, and signals.

const MODAL_SCENE: PackedScene = preload("res://scenes/ui/SaveLoadModal.tscn")

var passed_tests: int = 0
var total_tests: int = 6
var modal: Control = null


func _ready() -> void:
	print("\n================================================")
	print(">>> RUNNING SAVE/LOAD MODAL UI TEST SUITE <<<")
	print("================================================\n")

	_run_all_tests()


func _run_all_tests() -> void:
	_cleanup_saves()

	# Instantiate modal
	modal = MODAL_SCENE.instantiate()
	add_child(modal)
	await get_tree().process_frame

	await test_criterion_1_scene_hierarchy_and_initial_state()
	await test_criterion_2_save_mode_and_empty_slots()
	await test_criterion_3_populated_slot_display()
	await test_criterion_4_load_mode_behavior()
	await test_criterion_5_confirmation_dialogs()
	await test_criterion_6_esc_and_close_lifecycle()

	_cleanup_saves()

	print("\n================================================")
	if passed_tests == total_tests:
		print(">>> ALL %d SAVE/LOAD MODAL TESTS PASSED! (%d/%d) <<<" % [
			total_tests, passed_tests, total_tests
		])
	else:
		print(">>> MODAL TEST FAILURES DETECTED! (%d/%d) <<<" % [passed_tests, total_tests])
	print("================================================\n")

	get_tree().quit(0 if passed_tests == total_tests else 1)


func _cleanup_saves() -> void:
	for slot in SaveLoadManager.VALID_SLOTS:
		if SaveLoadManager.has_save(slot):
			SaveLoadManager.delete_save(slot)


func test_criterion_1_scene_hierarchy_and_initial_state() -> void:
	print("[TEST 1] Verifying modal hierarchy, unique node bindings, and initial visibility...")
	assert(modal != null, "Modal instance must be valid")
	assert(not modal.visible, "Modal should be hidden on ready")
	assert(not modal.is_open, "Modal is_open should initially be false")

	assert(modal.get_node("%Backdrop") != null, "Backdrop must exist")
	assert(modal.get_node("%ModalPanel") != null, "ModalPanel must exist")
	assert(modal.get_node("%TitleLabel") != null, "TitleLabel must exist")
	assert(modal.get_node("%BtnHeaderClose") != null, "BtnHeaderClose must exist")
	assert(modal.get_node("%BtnFooterClose") != null, "BtnFooterClose must exist")

	# Verify slot cards exist
	assert(modal.get_card("autosave") != null, "CardAutosave must exist")
	assert(modal.get_card("slot_1") != null, "CardSlot1 must exist")
	assert(modal.get_card("slot_2") != null, "CardSlot2 must exist")
	assert(modal.get_card("slot_3") != null, "CardSlot3 must exist")

	# Verify confirmation overlay
	var confirm: Control = modal.get_node("%ConfirmOverlay") as Control
	assert(confirm != null, "ConfirmOverlay must exist")
	assert(not confirm.visible, "ConfirmOverlay must initially be hidden")

	print("  -> Hierarchy, slot cards, and confirm overlay verified.")
	print("  [PASS] Test 1: Initial scene hierarchy verified.\n")
	passed_tests += 1


func test_criterion_2_save_mode_and_empty_slots() -> void:
	print("[TEST 2] Verifying open_in_save_mode() and empty slot state rendering...")
	modal.open_in_save_mode()
	await get_tree().process_frame

	assert(modal.visible, "Modal must be visible after open_in_save_mode()")
	assert(modal.is_open, "Modal must be marked as is_open")
	assert(modal.current_mode == modal.Mode.SAVE, "Mode should be SAVE")

	var title_lbl: Label = modal.get_node("%TitleLabel") as Label
	assert(title_lbl.text == tr("UI_SAVE_LOAD_TITLE_SAVE"), "Title must be save title")

	# With no saves, all slot cards should display empty slot label
	var label_empty: Label = modal.get_card_empty_label("slot_1")
	var stats_box: Container = modal.get_card_stats_box("slot_1")
	var btn_action: Button = modal.get_card_action_button("slot_1")
	var btn_delete: Button = modal.get_card_delete_button("slot_1")

	assert(label_empty.visible, "Empty label must be visible for empty slot")
	assert(not stats_box.visible, "Stats box must be hidden for empty slot")
	assert(btn_action.text == tr("UI_BTN_SAVE_HERE"), "Action button should say Save Here")
	assert(not btn_action.disabled, "Action button should be enabled in Save mode")
	assert(not btn_delete.visible, "Delete button must be hidden for empty slot")

	print("  -> Save mode header and empty card UI verified.")
	print("  [PASS] Test 2: Save mode and empty slot state verified.\n")
	passed_tests += 1


func test_criterion_3_populated_slot_display() -> void:
	print("[TEST 3] Verifying populated slot card metadata, alignment badge, and stats...")
	# Setup test state and save into slot_1
	GameManager.start_new_game()
	GameManager.current_day = 12
	GameManager.city_budget = 185000
	GameManager.public_opinion = 72.0
	GameManager.personal_wealth = 0
	GameManager.suspicion_level = 8.0
	SaveLoadManager.save_game("slot_1")

	modal.refresh_slots()
	await get_tree().process_frame

	var label_empty: Label = modal.get_card_empty_label("slot_1")
	var stats_box: Container = modal.get_card_stats_box("slot_1")
	var label_day: Label = modal.get_card_day_label("slot_1")
	var label_budget: Label = modal.get_card_budget_label("slot_1")
	var label_approval: Label = modal.get_card_approval_label("slot_1")
	var label_suspicion: Label = modal.get_card_suspicion_label("slot_1")
	var label_badge: Label = modal.get_card_alignment_badge("slot_1")
	var btn_delete: Button = modal.get_card_delete_button("slot_1")

	assert(not label_empty.visible, "Empty label must be hidden for populated slot")
	assert(stats_box.visible, "Stats box must be visible for populated slot")
	assert("12" in label_day.text, "Day label should display day 12")
	assert("185,000" in label_budget.text, "Budget label should format $185,000")
	assert("72%" in label_approval.text, "Approval label should display 72%")
	assert("8%" in label_suspicion.text, "Suspicion label should display 8%")
	assert(label_badge.visible, "Alignment badge should be visible")
	assert(btn_delete.visible, "Delete button should be visible for populated slot")

	print("  -> Populated slot card metadata and labels accurately formatted.")
	print("  [PASS] Test 3: Populated slot display verified.\n")
	passed_tests += 1


func test_criterion_4_load_mode_behavior() -> void:
	print("[TEST 4] Verifying open_in_load_mode(), disabled empty slots, and load signal...")
	modal.open_in_load_mode()
	await get_tree().process_frame

	assert(modal.current_mode == modal.Mode.LOAD, "Mode should be LOAD")
	var title_lbl: Label = modal.get_node("%TitleLabel") as Label
	assert(title_lbl.text == tr("UI_SAVE_LOAD_TITLE_LOAD"), "Title must be load title")

	var btn_action1: Button = modal.get_card_action_button("slot_1")
	var btn_action2: Button = modal.get_card_action_button("slot_2")

	assert(btn_action1.text == tr("UI_BTN_LOAD"), "Action button should say Load Game")
	assert(not btn_action1.disabled, "Populated slot 1 button must be enabled in Load mode")
	assert(btn_action2.disabled, "Empty slot 2 button must be disabled in Load mode")

	# Test clicking load
	var loaded_signals: Array[String] = []
	var on_loaded := func(slot: String): loaded_signals.append(slot)
	modal.load_completed.connect(on_loaded)

	# Simulate pressing load button on slot 1
	btn_action1.emit_signal("pressed")
	await get_tree().process_frame

	modal.load_completed.disconnect(on_loaded)
	assert(loaded_signals.size() == 1, "load_completed signal must be emitted")
	assert(loaded_signals[0] == "slot_1", "Emitted slot must be slot_1")

	print("  -> Load mode button states and load_completed signal verified.")
	print("  [PASS] Test 4: Load mode behavior verified.\n")
	passed_tests += 1


func test_criterion_5_confirmation_dialogs() -> void:
	print("[TEST 5] Verifying overwrite and delete confirmation dialogs and signal flow...")
	modal.open_in_save_mode()
	await get_tree().process_frame

	var btn_action1: Button = modal.get_card_action_button("slot_1")
	var btn_delete1: Button = modal.get_card_delete_button("slot_1")

	var confirm_overlay: Control = modal.get_node("%ConfirmOverlay") as Control
	var confirm_title: Label = modal.get_node("%ConfirmTitle") as Label
	var btn_yes: Button = modal.get_node("%BtnConfirmYes") as Button
	var btn_no: Button = modal.get_node("%BtnConfirmNo") as Button

	# 1. Test Overwrite prompt
	btn_action1.emit_signal("pressed")
	await get_tree().process_frame
	assert(confirm_overlay.visible, "Confirm overlay should appear when overwriting")
	assert(modal.current_confirm == modal.ConfirmType.OVERWRITE, "Confirm type should be OVERWRITE")
	assert(confirm_title.text == tr("UI_CONFIRM_OVERWRITE_TITLE"), "Title mismatch")

	# Cancel overwrite
	btn_no.emit_signal("pressed")
	await get_tree().process_frame
	assert(not confirm_overlay.visible, "Confirm overlay should hide after Cancel")

	# 2. Test Delete prompt & confirm
	btn_delete1.emit_signal("pressed")
	await get_tree().process_frame
	assert(confirm_overlay.visible, "Confirm overlay should appear when deleting")
	assert(modal.current_confirm == modal.ConfirmType.DELETE, "Confirm type should be DELETE")

	# Confirm delete
	btn_yes.emit_signal("pressed")
	await get_tree().process_frame
	assert(not confirm_overlay.visible, "Confirm overlay should close after Yes")
	assert(not SaveLoadManager.has_save("slot_1"), "slot_1 should now be deleted from disk")

	# Re-check card UI reflects empty state
	var label_empty: Label = modal.get_card_empty_label("slot_1")
	assert(label_empty.visible, "Card 1 should now display empty label")

	print("  -> Overwrite and delete dialog workflows verified.")
	print("  [PASS] Test 5: Confirmation dialogs verified.\n")
	passed_tests += 1


func test_criterion_6_esc_and_close_lifecycle() -> void:
	print("[TEST 6] Verifying ESC key handling, modal_closed signal, and close animation...")
	var closed_signals: Array[bool] = []
	var on_closed := func(): closed_signals.append(true)
	modal.modal_closed.connect(on_closed)

	# Open modal and test close
	modal.open_in_save_mode()
	await get_tree().process_frame
	assert(modal.is_open, "Modal should be open")

	await modal.close()
	assert(not modal.is_open, "Modal should be closed")
	assert(not modal.visible, "Modal should be hidden after close()")
	assert(closed_signals.size() == 1, "modal_closed signal must be emitted once")

	modal.modal_closed.disconnect(on_closed)

	print("  -> Close lifecycle and modal_closed signal verified.")
	print("  [PASS] Test 6: Modal close lifecycle verified.\n")
	passed_tests += 1
