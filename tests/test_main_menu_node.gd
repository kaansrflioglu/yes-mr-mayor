extends Node

## test_main_menu_node.gd - Automated test suite for Phase 4 Main Menu and HowToPlayModal.
## Validates UI bindings, continue button dynamic state, modal routing, and ESC hierarchy.

const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/menu/MainMenu.tscn")

var passed_tests: int = 0
var total_tests: int = 6
var main_menu: Control = null


func _ready() -> void:
	print("\n================================================")
	print(">>> RUNNING MAIN MENU & HOW TO PLAY TEST SUITE <<<")
	print("================================================\n")

	_run_all_tests()


func _run_all_tests() -> void:
	main_menu = MAIN_MENU_SCENE.instantiate()
	add_child(main_menu)
	await get_tree().process_frame

	await test_criterion_1_hierarchy_and_bindings()
	await test_criterion_2_continue_button_when_no_saves()
	await test_criterion_3_continue_button_when_save_exists()
	await test_criterion_4_how_to_play_modal_flow()
	await test_criterion_5_settings_and_load_modal_routing()
	await test_criterion_6_confirm_dialog_and_esc_hierarchy()

	main_menu.queue_free()
	main_menu = null

	print("\n================================================")
	if passed_tests == total_tests:
		print(">>> ALL %d MAIN MENU TESTS PASSED! (%d/%d) <<<" % [
			total_tests, passed_tests, total_tests
		])
	else:
		print(">>> MAIN MENU FAILURES DETECTED! (%d/%d) <<<" % [passed_tests, total_tests])
	print("================================================\n")

	get_tree().quit(0 if passed_tests == total_tests else 1)


func test_criterion_1_hierarchy_and_bindings() -> void:
	print("Test 1: Main Menu hierarchy and node bindings...")

	var btn_continue: Button = main_menu.get_node("%BtnContinue")
	var btn_new_game: Button = main_menu.get_node("%BtnNewGame")
	var btn_load_game: Button = main_menu.get_node("%BtnLoadGame")
	var btn_how_to_play: Button = main_menu.get_node("%BtnHowToPlay")
	var btn_settings: Button = main_menu.get_node("%BtnSettings")
	var btn_quit: Button = main_menu.get_node("%BtnQuit")

	var save_load_modal: Control = main_menu.get_node("%SaveLoadModal")
	var settings_modal: Control = main_menu.get_node("%SettingsModal")
	var how_to_play_modal: Control = main_menu.get_node("%HowToPlayModal")
	var confirm_overlay: Control = main_menu.get_node("%ConfirmOverlay")

	assert(btn_continue != null, "BtnContinue should exist")
	assert(btn_new_game != null, "BtnNewGame should exist")
	assert(btn_load_game != null, "BtnLoadGame should exist")
	assert(btn_how_to_play != null, "BtnHowToPlay should exist")
	assert(btn_settings != null, "BtnSettings should exist")
	assert(btn_quit != null, "BtnQuit should exist")

	assert(save_load_modal != null, "SaveLoadModal should exist")
	assert(settings_modal != null, "SettingsModal should exist")
	assert(how_to_play_modal != null, "HowToPlayModal should exist")
	assert(confirm_overlay != null, "ConfirmOverlay should exist")

	passed_tests += 1
	print("  -> Passed Criterion 1: Hierarchy and node bindings verified.")


func test_criterion_2_continue_button_when_no_saves() -> void:
	print("Test 2: Continue button disabled when no saves exist...")

	# Temporarily delete saves to test empty state
	var backup_slots: Dictionary = {}
	for slot in ["autosave", "slot_1", "slot_2", "slot_3"]:
		if SaveLoadManager.has_save(slot):
			backup_slots[slot] = SaveLoadManager.get_save_path(slot)
			SaveLoadManager.delete_save(slot)

	main_menu.call("_refresh_buttons")
	await get_tree().process_frame

	var btn_continue: Button = main_menu.get_node("%BtnContinue")
	var preview_label: Label = main_menu.get_node("%LabelContinuePreview")

	assert(SaveLoadManager.has_any_save() == false, "No saves should exist in this test step")
	assert(btn_continue.disabled == true, "BtnContinue must be disabled when no saves exist")
	assert(
		preview_label.text.to_lower().contains("no") \
		or preview_label.text.to_lower().contains("kay") \
		or preview_label.text.to_lower().contains("bulunamad"),
		"Preview label should reflect empty save state"
	)

	passed_tests += 1
	print("  -> Passed Criterion 2: Empty save state properly handled.")


func test_criterion_3_continue_button_when_save_exists() -> void:
	print("Test 3: Continue button enabled with preview metadata when save exists...")

	# Create a test save
	GameManager.current_day = 8
	GameManager.city_budget = 45000
	GameManager.public_opinion = 68.0
	var saved: bool = SaveLoadManager.save_game("slot_2")
	assert(saved == true, "Saving to slot_2 must succeed")

	main_menu.call("_refresh_buttons")
	await get_tree().process_frame

	var btn_continue: Button = main_menu.get_node("%BtnContinue")
	var preview_label: Label = main_menu.get_node("%LabelContinuePreview")

	assert(SaveLoadManager.has_any_save() == true, "Save should exist")
	assert(btn_continue.disabled == false, "BtnContinue must be enabled when a save exists")
	assert(preview_label.text.contains("Day 8"), "Preview text should contain Day 8")
	assert(preview_label.text.contains("45,000"), "Preview text should contain $45,000")
	assert(preview_label.text.contains("68%"), "Preview text should contain 68% approval")

	# Clean up test save
	SaveLoadManager.delete_save("slot_2")
	main_menu.call("_refresh_buttons")

	passed_tests += 1
	print("  -> Passed Criterion 3: Save metadata preview and continue enablement verified.")


func test_criterion_4_how_to_play_modal_flow() -> void:
	print("Test 4: How to Play modal open, tab switching, and close...")

	var htp_modal: Control = main_menu.get_node("%HowToPlayModal")
	var btn_htp: Button = main_menu.get_node("%BtnHowToPlay")

	assert(htp_modal.visible == false, "HowToPlayModal should start hidden")
	btn_htp.emit_signal("pressed")
	await get_tree().process_frame

	assert(htp_modal.get("is_open") == true, "HowToPlayModal should be open")
	assert(htp_modal.visible == true, "HowToPlayModal should be visible")

	# Switch through tabs
	var section_title: Label = htp_modal.get_node("%SectionTitle")
	htp_modal.call("_switch_tab", 1)
	assert(
		section_title.text.contains("FATE") or section_title.text.contains("KADER"),
		"Tab 1 should display Stamping & Fate content"
	)

	htp_modal.call("_switch_tab", 2)
	assert(
		section_title.text.contains("EMERGENCY") or section_title.text.contains("ACİL"),
		"Tab 2 should display Hotline Emergency content"
	)

	htp_modal.call("_switch_tab", 3)
	assert(
		section_title.text.contains("MORALITY") or section_title.text.contains("AHLAK") \
		or section_title.text.contains("İSVİÇRE"),
		"Tab 3 should display Offshore Morality content"
	)

	# Close modal
	var btn_close: Button = htp_modal.get_node("%BtnFooterClose")
	btn_close.emit_signal("pressed")
	await get_tree().create_timer(0.25).timeout

	assert(htp_modal.get("is_open") == false, "HowToPlayModal should be closed")

	passed_tests += 1
	print("  -> Passed Criterion 4: HowToPlayModal tabs and transitions verified.")


func test_criterion_5_settings_and_load_modal_routing() -> void:
	print("Test 5: Settings and Load modals routing from Main Menu...")

	var btn_settings: Button = main_menu.get_node("%BtnSettings")
	var settings_modal: Control = main_menu.get_node("%SettingsModal")
	btn_settings.emit_signal("pressed")
	await get_tree().process_frame

	assert(settings_modal.get("is_open") == true, "SettingsModal should open")
	settings_modal.call("close")
	await get_tree().create_timer(0.25).timeout
	assert(settings_modal.get("is_open") == false, "SettingsModal should close")

	var btn_load: Button = main_menu.get_node("%BtnLoadGame")
	var save_load_modal: Control = main_menu.get_node("%SaveLoadModal")
	btn_load.emit_signal("pressed")
	await get_tree().process_frame

	assert(save_load_modal.get("is_open") == true, "SaveLoadModal should open")
	assert(
		int(save_load_modal.get("current_mode")) == 1,
		"SaveLoadModal mode should be Mode.LOAD"
	)
	save_load_modal.call("close")
	await get_tree().create_timer(0.25).timeout
	assert(save_load_modal.get("is_open") == false, "SaveLoadModal should close")

	passed_tests += 1
	print("  -> Passed Criterion 5: SettingsModal & SaveLoadModal routing verified.")


func test_criterion_6_confirm_dialog_and_esc_hierarchy() -> void:
	print("Test 6: Confirmation dialog overlays and cancel hierarchy...")

	var confirm_overlay: Control = main_menu.get_node("%ConfirmOverlay")
	var btn_confirm_yes: Button = main_menu.get_node("%BtnConfirmYes")
	var btn_confirm_no: Button = main_menu.get_node("%BtnConfirmNo")

	# Test Quit trigger via cancel handler
	main_menu.call("_handle_cancel_request")
	await get_tree().process_frame

	assert(confirm_overlay.visible == true, "ConfirmOverlay should be visible for quit")
	var pending_act = main_menu.get("_pending_action")
	assert(int(pending_act) == 2, "Pending action should be QUIT (2)")

	btn_confirm_no.emit_signal("pressed")
	await get_tree().create_timer(0.2).timeout
	assert(confirm_overlay.visible == false, "ConfirmOverlay should close on cancel")

	# Test new game reset functionality
	GameManager.current_day = 12
	GameManager.city_budget = 99999
	main_menu.call("_start_new_term")
	assert(GameManager.current_day == 1, "GameManager day should reset to 1")
	assert(GameManager.city_budget == 100000, "City budget should reset to default 100000")

	passed_tests += 1
	print("  -> Passed Criterion 6: Confirm dialog and state reset verified.")
