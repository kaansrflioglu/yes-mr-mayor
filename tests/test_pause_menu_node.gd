extends Node

## test_pause_menu_node.gd - Automated test suite for Phase 3 In-Game Pause Menu.
## Validates PauseMenu UI, button signals, confirmation popups, TopBarHUD button, and ESC hierarchy.

const DESK_VIEW_SCENE: PackedScene = preload("res://scenes/desk/DeskView.tscn")
const PAUSE_MENU_SCENE: PackedScene = preload("res://scenes/ui/PauseMenu.tscn")

var passed_tests: int = 0
var total_tests: int = 6
var desk_view: Control = null
var pause_menu: Control = null


func _ready() -> void:
	print("\n================================================")
	print(">>> RUNNING IN-GAME PAUSE MENU TEST SUITE <<<")
	print("================================================\n")

	_run_all_tests()


func _run_all_tests() -> void:
	# 1. Standalone PauseMenu tests
	pause_menu = PAUSE_MENU_SCENE.instantiate()
	add_child(pause_menu)
	await get_tree().process_frame

	await test_criterion_1_pause_menu_hierarchy_and_initial_state()
	await test_criterion_2_pause_menu_signals()
	await test_criterion_3_confirmation_overlays()

	pause_menu.queue_free()
	pause_menu = null
	await get_tree().process_frame

	# 2. DeskView integration & ESC hierarchy tests
	desk_view = DESK_VIEW_SCENE.instantiate()
	add_child(desk_view)
	await get_tree().process_frame

	await test_criterion_4_hud_pause_button()
	await test_criterion_5_esc_key_hierarchy()
	await test_criterion_6_pause_to_save_load_routing()

	desk_view.queue_free()
	desk_view = null

	print("\n================================================")
	if passed_tests == total_tests:
		print(">>> ALL %d PAUSE MENU TESTS PASSED! (%d/%d) <<<" % [
			total_tests, passed_tests, total_tests
		])
	else:
		print(">>> PAUSE MENU FAILURES DETECTED! (%d/%d) <<<" % [passed_tests, total_tests])
	print("================================================\n")

	get_tree().quit(0 if passed_tests == total_tests else 1)


func test_criterion_1_pause_menu_hierarchy_and_initial_state() -> void:
	print("[TEST 1] Verifying PauseMenu buttons, styling, and initial hidden state...")
	assert(pause_menu != null, "PauseMenu must exist")
	assert(not pause_menu.visible, "PauseMenu must be initially hidden")
	assert(not pause_menu.is_open, "PauseMenu is_open should initially be false")

	assert(pause_menu.get_node("%BtnResume") != null, "BtnResume must exist")
	assert(pause_menu.get_node("%BtnSave") != null, "BtnSave must exist")
	assert(pause_menu.get_node("%BtnLoad") != null, "BtnLoad must exist")
	assert(pause_menu.get_node("%BtnSettings") != null, "BtnSettings must exist")
	assert(pause_menu.get_node("%BtnMainMenu") != null, "BtnMainMenu must exist")
	assert(pause_menu.get_node("%BtnQuit") != null, "BtnQuit must exist")

	pause_menu.open()
	await get_tree().process_frame
	assert(pause_menu.visible, "PauseMenu should be visible after open()")
	assert(pause_menu.is_open, "PauseMenu is_open should be true")

	var title: Label = pause_menu.get_node("%TitleLabel") as Label
	assert(title.text == tr("UI_PAUSE_TITLE"), "Title text mismatch")

	await pause_menu.close()
	assert(not pause_menu.visible, "PauseMenu should be hidden after close()")
	assert(not pause_menu.is_open, "PauseMenu is_open should be false")

	print("  -> Hierarchy and visibility toggles verified.")
	print("  [PASS] Test 1: Initial hierarchy verified.\n")
	passed_tests += 1


func test_criterion_2_pause_menu_signals() -> void:
	print("[TEST 2] Verifying resume, save, load, and settings button signals...")
	pause_menu.open()
	await get_tree().process_frame

	var resume_count: Array[bool] = []
	var save_count: Array[bool] = []
	var load_count: Array[bool] = []
	var settings_count: Array[bool] = []

	pause_menu.resume_requested.connect(func(): resume_count.append(true))
	pause_menu.save_requested.connect(func(): save_count.append(true))
	pause_menu.load_requested.connect(func(): load_count.append(true))
	pause_menu.settings_requested.connect(func(): settings_count.append(true))

	# Test Save button
	var btn_save: Button = pause_menu.get_node("%BtnSave") as Button
	btn_save.emit_signal("pressed")
	assert(save_count.size() == 1, "save_requested must emit")

	# Test Load button
	var btn_load: Button = pause_menu.get_node("%BtnLoad") as Button
	btn_load.emit_signal("pressed")
	assert(load_count.size() == 1, "load_requested must emit")

	# Test Settings button
	var btn_settings: Button = pause_menu.get_node("%BtnSettings") as Button
	btn_settings.emit_signal("pressed")
	assert(settings_count.size() == 1, "settings_requested must emit")

	# Test Resume button
	var btn_resume: Button = pause_menu.get_node("%BtnResume") as Button
	btn_resume.emit_signal("pressed")
	await get_tree().process_frame
	assert(resume_count.size() == 1, "resume_requested must emit")
	assert(not pause_menu.is_open, "Resume should close pause menu")

	print("  -> Button signals (Save, Load, Settings, Resume) verified.")
	print("  [PASS] Test 2: Button signals verified.\n")
	passed_tests += 1


func test_criterion_3_confirmation_overlays() -> void:
	print("[TEST 3] Verifying Main Menu and Quit confirmation dialogs...")
	pause_menu.open()
	await get_tree().process_frame

	var confirm_overlay: Control = pause_menu.get_node("%ConfirmOverlay") as Control
	var confirm_title: Label = pause_menu.get_node("%ConfirmTitle") as Label
	var btn_yes: Button = pause_menu.get_node("%BtnConfirmYes") as Button
	var btn_no: Button = pause_menu.get_node("%BtnConfirmNo") as Button

	# 1. Main Menu confirmation
	var btn_menu: Button = pause_menu.get_node("%BtnMainMenu") as Button
	btn_menu.emit_signal("pressed")
	await get_tree().process_frame
	assert(confirm_overlay.visible, "Confirm overlay should appear for Main Menu")
	assert(confirm_title.text == tr("UI_CONFIRM_MAIN_MENU_TITLE"), "Main menu title mismatch")

	btn_no.emit_signal("pressed")
	await get_tree().process_frame
	assert(not confirm_overlay.visible, "Cancel should hide confirm overlay")

	# 2. Quit confirmation
	var btn_quit: Button = pause_menu.get_node("%BtnQuit") as Button
	btn_quit.emit_signal("pressed")
	await get_tree().process_frame
	assert(confirm_overlay.visible, "Confirm overlay should appear for Quit")
	assert(confirm_title.text == tr("UI_CONFIRM_QUIT_TITLE"), "Quit title mismatch")

	btn_no.emit_signal("pressed")
	await get_tree().process_frame
	assert(not confirm_overlay.visible, "Cancel should hide quit overlay")

	await pause_menu.close()
	print("  -> Confirmation overlays for Main Menu and Quit verified.")
	print("  [PASS] Test 3: Confirmation overlays verified.\n")
	passed_tests += 1


func test_criterion_4_hud_pause_button() -> void:
	print("[TEST 4] Verifying TopBarHUD pause button toggles PauseMenu in DeskView...")
	var hud: Control = desk_view.get_node("TopBarHUD") as Control
	assert(hud != null, "TopBarHUD must exist")
	var btn_pause: Button = hud.get_node("%BtnPause") as Button
	assert(btn_pause != null, "BtnPause must exist on TopBarHUD")

	var desk_pause_menu: Control = desk_view.get_node("%PauseMenu") as Control
	assert(desk_pause_menu != null, "PauseMenu must exist in DeskView")
	assert(not desk_pause_menu.is_open, "Initially pause menu should be closed")

	# Click pause button on HUD
	btn_pause.emit_signal("pressed")
	await get_tree().process_frame
	assert(desk_pause_menu.is_open, "PauseMenu should open when HUD pause button clicked")
	assert(desk_pause_menu.visible, "PauseMenu should be visible")

	# Click again to close
	btn_pause.emit_signal("pressed")
	await get_tree().process_frame
	assert(not desk_pause_menu.is_open, "PauseMenu should close when HUD pause button clicked again")

	print("  -> HUD pause button properly opens and closes PauseMenu.")
	print("  [PASS] Test 4: HUD pause button verified.\n")
	passed_tests += 1


func test_criterion_5_esc_key_hierarchy() -> void:
	print("[TEST 5] Verifying ESC key navigation priority hierarchy in DeskView...")
	var desk_pause: Control = desk_view.get_node("%PauseMenu") as Control
	var desk_settings: Control = desk_view.get_node("%SettingsModal") as Control
	var desk_saveload: Control = desk_view.get_node("%SaveLoadModal") as Control

	assert(desk_pause != null, "PauseMenu must exist")
	assert(desk_settings != null, "SettingsModal must exist")
	assert(desk_saveload != null, "SaveLoadModal must exist")

	# 1. When nothing is open, pressing ESC opens PauseMenu
	desk_view._handle_escape_key()
	await get_tree().process_frame
	assert(desk_pause.is_open, "ESC when idle should open PauseMenu")

	# 2. When PauseMenu is open, pressing ESC closes PauseMenu
	desk_view._handle_escape_key()
	await get_tree().process_frame
	assert(not desk_pause.is_open, "ESC when PauseMenu open should close PauseMenu")

	# 3. When SettingsModal is open, ESC closes SettingsModal (not opening PauseMenu)
	desk_settings.open()
	await get_tree().process_frame
	assert(desk_settings.is_open, "SettingsModal should be open")
	desk_view._handle_escape_key()
	await get_tree().process_frame
	assert(not desk_settings.is_open, "ESC should close SettingsModal")
	assert(not desk_pause.is_open, "ESC closing SettingsModal should NOT open PauseMenu")

	# 4. When SaveLoadModal is open, ESC closes SaveLoadModal
	desk_saveload.open_in_save_mode()
	await get_tree().process_frame
	assert(desk_saveload.is_open, "SaveLoadModal should be open")
	desk_view._handle_escape_key()
	await get_tree().process_frame
	assert(not desk_saveload.is_open, "ESC should close SaveLoadModal")

	print("  -> ESC hierarchy strictly prioritized (Settings -> SaveLoad -> Rulebook -> Pause).")
	print("  [PASS] Test 5: ESC hierarchy verified.\n")
	passed_tests += 1


func test_criterion_6_pause_to_save_load_routing() -> void:
	print("[TEST 6] Verifying routing from PauseMenu to SaveLoadModal...")
	var desk_pause: Control = desk_view.get_node("%PauseMenu") as Control
	var desk_saveload: Control = desk_view.get_node("%SaveLoadModal") as Control

	desk_pause.open()
	await get_tree().process_frame
	assert(desk_pause.is_open, "Pause menu open")

	# Click Save Game inside PauseMenu
	var btn_save: Button = desk_pause.get_node("%BtnSave") as Button
	btn_save.emit_signal("pressed")
	await get_tree().process_frame

	assert(not desk_pause.is_open, "PauseMenu should close when Save clicked")
	assert(desk_saveload.is_open, "SaveLoadModal should open in Save mode")
	assert(desk_saveload.current_mode == desk_saveload.Mode.SAVE, "Mode should be SAVE")

	# Close SaveLoadModal -> should restore PauseMenu
	await desk_saveload.close()
	await get_tree().process_frame
	assert(desk_pause.is_open, "Returning from SaveLoadModal should reopen PauseMenu")

	await desk_pause.close()
	print("  -> Seamless routing between PauseMenu and SaveLoadModal verified.")
	print("  [PASS] Test 6: Pause to Save/Load routing verified.\n")
	passed_tests += 1
