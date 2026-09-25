extends Node

## test_master_node.gd - Phase 6 Master End-to-End Test Suite.
## Validates the entire Save/Load & Menu architecture from Phase 1 through Phase 5.

const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/menu/MainMenu.tscn")
const DESK_VIEW_SCENE: PackedScene = preload("res://scenes/desk/DeskView.tscn")
const PAUSE_MENU_SCENE: PackedScene = preload("res://scenes/ui/PauseMenu.tscn")
const SAVE_LOAD_MODAL_SCENE: PackedScene = preload("res://scenes/ui/SaveLoadModal.tscn")
const SAVE_TOAST_SCENE: PackedScene = preload("res://scenes/ui/SaveToast.tscn")
const GAME_OVER_SCENE: PackedScene = preload("res://scenes/summary/GameOverModal.tscn")

var passed_suites: int = 0
var total_suites: int = 5


func _ready() -> void:
	print("\n=======================================================")
	print(">>> RUNNING PHASE 6 MASTER SAVE & MENU TEST SUITE <<<")
	print("=======================================================\n")

	_run_master_suite()


func _run_master_suite() -> void:
	_cleanup_all_saves()

	await _run_suite_1_core_save_load_engine()
	await _run_suite_2_save_load_modal_ui()
	await _run_suite_3_pause_menu_and_esc_hierarchy()
	await _run_suite_4_main_menu_and_title_flow()
	await _run_suite_5_autosave_toast_and_game_over()

	_cleanup_all_saves()

	print("\n=======================================================")
	if passed_suites == total_suites:
		print(">>> ALL %d MASTER ARCHITECTURE SUITES PASSED! (%d/%d) <<<" % [
			total_suites, passed_suites, total_suites
		])
	else:
		print(">>> MASTER SUITE FAILURES DETECTED! (%d/%d) <<<" % [
			passed_suites, total_suites
		])
	print("=======================================================\n")

	get_tree().quit(0 if passed_suites == total_suites else 1)


func _cleanup_all_saves() -> void:
	for slot in SaveLoadManager.VALID_SLOTS:
		if SaveLoadManager.has_save(slot):
			SaveLoadManager.delete_save(slot)


# -----------------------------------------------------------------------------
# SUITE 1: Core Engine Serialization & Restoration
# -----------------------------------------------------------------------------
func _run_suite_1_core_save_load_engine() -> void:
	print("[SUITE 1] Core Save/Load Engine & State Restoration...")

	# Prepare state: Day 14, $42,000, 31% opinion, 55k wealth, 62% suspicion
	GameManager.current_day = 14
	GameManager.city_budget = 42000
	GameManager.public_opinion = 31.0
	GameManager.personal_wealth = 55000
	GameManager.suspicion_level = 62.0
	GameManager.event_flags.clear()
	GameManager.event_flags["master_test_flag"] = true

	var save_ok := SaveLoadManager.save_game("slot_1")
	assert(save_ok, "Save to slot_1 must succeed")
	assert(SaveLoadManager.has_save("slot_1"), "File slot_1.json must exist")

	# Reset and reload
	GameManager.start_new_game()
	assert(GameManager.current_day == 1, "GameManager day reset failed")

	var load_ok := SaveLoadManager.load_game("slot_1")
	assert(load_ok, "Load from slot_1 must succeed")

	assert(GameManager.current_day == 14, "Restored day mismatch")
	assert(GameManager.city_budget == 42000, "Restored city_budget mismatch")
	assert(is_equal_approx(GameManager.public_opinion, 31.0), "Restored opinion mismatch")
	assert(GameManager.personal_wealth == 55000, "Restored wealth mismatch")
	assert(is_equal_approx(GameManager.suspicion_level, 62.0), "Restored suspicion mismatch")
	assert(GameManager.event_flags.get("master_test_flag", false), "Event flag mismatch")

	passed_suites += 1
	print("  [PASS] Suite 1: Core Save/Load Engine verified.\n")


# -----------------------------------------------------------------------------
# SUITE 2: Save/Load Modal UI & Confirmations
# -----------------------------------------------------------------------------
func _run_suite_2_save_load_modal_ui() -> void:
	print("[SUITE 2] Save/Load Modal UI & Dialog Flows...")

	var modal: Control = SAVE_LOAD_MODAL_SCENE.instantiate()
	add_child(modal)
	await get_tree().process_frame

	# Test Save mode
	modal.call("open_in_save_mode")
	assert(modal.get("is_open") == true, "Modal should open in save mode")
	assert(int(modal.get("current_mode")) == 0, "Current mode should be Mode.SAVE")

	# Test Load mode
	modal.call("open_in_load_mode")
	assert(int(modal.get("current_mode")) == 1, "Current mode should be Mode.LOAD")

	# Check populated card slot_1 metadata
	var meta: Dictionary = SaveLoadManager.get_slot_metadata("slot_1")
	assert(meta.get("exists", false) == true, "slot_1 metadata exists")
	assert(int(meta.get("day", 0)) == 14, "slot_1 day should be 14")

	# Close modal
	modal.call("close")
	await get_tree().create_timer(0.2).timeout
	assert(modal.get("is_open") == false, "Modal should close")

	modal.queue_free()
	await get_tree().process_frame

	passed_suites += 1
	print("  [PASS] Suite 2: Save/Load Modal UI verified.\n")


# -----------------------------------------------------------------------------
# SUITE 3: In-Game Pause Menu & ESC Hierarchy
# -----------------------------------------------------------------------------
func _run_suite_3_pause_menu_and_esc_hierarchy() -> void:
	print("[SUITE 3] In-Game Pause Menu & ESC Navigation Hierarchy...")

	var desk_view: Control = DESK_VIEW_SCENE.instantiate()
	add_child(desk_view)
	await get_tree().process_frame

	var pause_menu: Control = desk_view.get_node("%PauseMenu")
	var settings_modal: Control = desk_view.get_node("%SettingsModal")
	var save_load_modal: Control = desk_view.get_node("%SaveLoadModal")

	# 1. Trigger PauseMenu via DeskView
	desk_view.call("_toggle_pause_menu")
	assert(pause_menu.get("is_open") == true, "PauseMenu should be open")

	# 2. Open SaveLoad from Pause
	desk_view.call("_on_pause_save_requested")
	assert(save_load_modal.get("is_open") == true, "SaveLoadModal should be open")
	assert(pause_menu.get("is_open") == false, "PauseMenu should be suspended")

	# 3. ESC closes SaveLoad and re-opens Pause
	desk_view.call("_handle_escape_key")
	await get_tree().create_timer(0.2).timeout
	assert(save_load_modal.get("is_open") == false, "SaveLoadModal closed by ESC")
	assert(pause_menu.get("is_open") == true, "PauseMenu restored after modal close")

	# 4. ESC closes PauseMenu back to gameplay
	desk_view.call("_handle_escape_key")
	assert(pause_menu.get("is_open") == false, "PauseMenu closed by ESC")

	desk_view.queue_free()
	await get_tree().process_frame

	passed_suites += 1
	print("  [PASS] Suite 3: Pause Menu & ESC hierarchy verified.\n")


# -----------------------------------------------------------------------------
# SUITE 4: Main Menu Title Screen & Municipal Manual
# -----------------------------------------------------------------------------
func _run_suite_4_main_menu_and_title_flow() -> void:
	print("[SUITE 4] Main Menu Title Screen & Modal Navigation...")

	var main_menu: Control = MAIN_MENU_SCENE.instantiate()
	add_child(main_menu)
	await get_tree().process_frame

	var btn_continue: Button = main_menu.get_node("%BtnContinue")
	var preview_label: Label = main_menu.get_node("%LabelContinuePreview")

	# Save exists in slot_1 -> Continue must be enabled
	main_menu.call("_refresh_buttons")
	assert(btn_continue.disabled == false, "Continue button must be enabled when save exists")
	assert(preview_label.text.contains("Day 14"), "Preview must reflect Day 14")

	# Open & switch Municipal Manual (HowToPlayModal)
	var htp_modal: Control = main_menu.get_node("%HowToPlayModal")
	main_menu.call("_on_how_to_play_pressed")
	assert(htp_modal.get("is_open") == true, "HowToPlayModal opened")

	htp_modal.call("_switch_tab", 2)
	var title_lbl: Label = htp_modal.get_node("%SectionTitle")
	assert(title_lbl.text.contains("EMERGENCY") or title_lbl.text.contains("ACİL"), "Tab 2 active")

	htp_modal.call("close")
	await get_tree().create_timer(0.2).timeout
	assert(htp_modal.get("is_open") == false, "HowToPlayModal closed")

	main_menu.queue_free()
	await get_tree().process_frame

	passed_suites += 1
	print("  [PASS] Suite 4: Main Menu Title Screen verified.\n")


# -----------------------------------------------------------------------------
# SUITE 5: Autosave on Shift End & Game Over Lifecycle
# -----------------------------------------------------------------------------
func _run_suite_5_autosave_toast_and_game_over() -> void:
	print("[SUITE 5] Autosave on Shift End & Post-Game Over Purge...")

	var desk_view: Control = DESK_VIEW_SCENE.instantiate()
	add_child(desk_view)
	await get_tree().process_frame

	if SaveLoadManager.has_save("autosave"):
		SaveLoadManager.delete_save("autosave")

	# Trigger quota completed -> autosave created & SaveToast triggered
	GameManager.current_day = 6
	desk_view.call("_on_daily_quota_completed")
	await get_tree().process_frame

	assert(SaveLoadManager.has_save("autosave"), "Autosave file must exist after quota")
	var toast: Control = desk_view.get_node_or_null("%SaveToast")
	assert(toast != null and toast.visible == true, "SaveToast must be visible")

	# Trigger game over -> autosave purged
	desk_view.call("_on_game_over", "END_RIOT")
	await get_tree().process_frame

	assert(
		SaveLoadManager.has_save("autosave") == false,
		"Autosave must be purged after game over"
	)

	# Verify GameOverModal buttons
	var active_go: Control = desk_view.get("active_game_over")
	assert(active_go != null, "GameOverModal instantiated")
	var btn_restart: Button = active_go.get_node("%BtnRestart")
	var btn_main_menu: Button = active_go.get_node("%BtnMainMenu")
	assert(btn_restart != null, "BtnRestart exists")
	assert(btn_main_menu != null, "BtnMainMenu exists")

	# Restart mandate -> resets to day 1
	desk_view.call("_on_restart_mandate")
	assert(GameManager.current_day == 1, "Mandate restarted on Day 1")

	desk_view.queue_free()
	await get_tree().process_frame

	passed_suites += 1
	print("  [PASS] Suite 5: Autosave & Game Over Lifecycle verified.\n")
