extends Node

## test_autosave_lifecycle_node.gd - Automated test suite for Phase 5 Autosave & Lifecycle.
## Validates end-of-shift autosave, SaveToast notifications, and game over cleanup.

const DESK_VIEW_SCENE: PackedScene = preload("res://scenes/desk/DeskView.tscn")
const GAME_OVER_SCENE: PackedScene = preload("res://scenes/summary/GameOverModal.tscn")
const SAVE_TOAST_SCENE: PackedScene = preload("res://scenes/ui/SaveToast.tscn")

var passed_tests: int = 0
var total_tests: int = 6
var desk_view: Control = null


func _ready() -> void:
	print("\n==================================================")
	print(">>> RUNNING AUTOSAVE & LIFECYCLE TEST SUITE <<<")
	print("==================================================\n")

	_run_all_tests()


func _run_all_tests() -> void:
	desk_view = DESK_VIEW_SCENE.instantiate()
	add_child(desk_view)
	await get_tree().process_frame

	await test_criterion_1_save_toast_scene()
	await test_criterion_2_autosave_trigger_on_shift_end()
	await test_criterion_3_autosave_metadata_integrity()
	await test_criterion_4_game_over_cleanup_lifecycle()
	await test_criterion_5_game_over_modal_buttons_and_signals()
	await test_criterion_6_deskview_game_over_flow()

	desk_view.queue_free()
	desk_view = null

	print("\n==================================================")
	if passed_tests == total_tests:
		print(">>> ALL %d AUTOSAVE & LIFECYCLE TESTS PASSED! (%d/%d) <<<" % [
			total_tests, passed_tests, total_tests
		])
	else:
		print(">>> FAILURES DETECTED! (%d/%d) <<<" % [passed_tests, total_tests])
	print("==================================================\n")

	get_tree().quit(0 if passed_tests == total_tests else 1)


func test_criterion_1_save_toast_scene() -> void:
	print("Test 1: SaveToast standalone component and animation...")

	var toast: Control = SAVE_TOAST_SCENE.instantiate()
	add_child(toast)
	await get_tree().process_frame

	assert(toast.visible == false, "SaveToast should start hidden")
	var label: Label = toast.get_node("%ToastLabel")
	assert(label != null, "ToastLabel must exist")

	toast.call("show_toast", 5)
	await get_tree().process_frame

	assert(toast.visible == true, "SaveToast should be visible after show_toast")
	assert(label.text.contains("5"), "ToastLabel should contain day number 5")

	toast.queue_free()
	await get_tree().process_frame

	passed_tests += 1
	print("  -> Passed Criterion 1: SaveToast component verified.")


func test_criterion_2_autosave_trigger_on_shift_end() -> void:
	print("Test 2: Autosave trigger upon daily quota completion...")

	if SaveLoadManager.has_save("autosave"):
		SaveLoadManager.delete_save("autosave")

	assert(SaveLoadManager.has_save("autosave") == false, "Autosave should not exist initially")

	GameManager.current_day = 4
	desk_view.call("_on_daily_quota_completed")
	await get_tree().process_frame

	assert(SaveLoadManager.has_save("autosave") == true, "Autosave file must be created")

	var save_toast: Control = desk_view.get_node_or_null("%SaveToast")
	assert(save_toast != null, "SaveToast must exist in DeskView")
	assert(save_toast.visible == true, "SaveToast should be displayed in DeskView")

	passed_tests += 1
	print("  -> Passed Criterion 2: Autosave and toast trigger verified.")


func test_criterion_3_autosave_metadata_integrity() -> void:
	print("Test 3: Autosave metadata accurately mirrors day and stats...")

	var meta := SaveLoadManager.get_slot_metadata("autosave")
	assert(meta.get("exists", false) == true, "Autosave metadata must exist")
	assert(int(meta.get("day", 0)) == 4, "Metadata day should match day 4")
	assert(meta.get("slot_id") == "autosave", "Slot ID should be autosave")

	passed_tests += 1
	print("  -> Passed Criterion 3: Autosave metadata verified.")


func test_criterion_4_game_over_cleanup_lifecycle() -> void:
	print("Test 4: Game over cleanup clears active autosave slot...")

	# Ensure autosave exists
	assert(SaveLoadManager.has_save("autosave") == true, "Autosave should exist before cleanup")

	# Perform game over cleanup
	SaveLoadManager.handle_game_over_cleanup()
	assert(
		SaveLoadManager.has_save("autosave") == false,
		"Autosave must be purged after game over cleanup"
	)

	passed_tests += 1
	print("  -> Passed Criterion 4: Post-game over save purge verified.")


func test_criterion_5_game_over_modal_buttons_and_signals() -> void:
	print("Test 5: GameOverModal Restart and Main Menu buttons and signals...")

	var modal: PanelContainer = GAME_OVER_SCENE.instantiate()
	add_child(modal)
	await get_tree().process_frame

	var btn_restart: Button = modal.get_node("%BtnRestart")
	var btn_main_menu: Button = modal.get_node("%BtnMainMenu")
	assert(btn_restart != null, "BtnRestart must exist in GameOverModal")
	assert(btn_main_menu != null, "BtnMainMenu must exist in GameOverModal")

	modal.call("show_game_over", "END_ARRESTED")
	assert(modal.visible == true, "GameOverModal should be visible")

	var restart_emitted: Array[bool] = []
	var menu_emitted: Array[bool] = []
	modal.restart_requested.connect(func(): restart_emitted.append(true))
	modal.main_menu_requested.connect(func(): menu_emitted.append(true))

	btn_restart.emit_signal("pressed")
	btn_main_menu.emit_signal("pressed")

	assert(restart_emitted.size() == 1, "restart_requested must be emitted")
	assert(menu_emitted.size() == 1, "main_menu_requested must be emitted")

	modal.queue_free()
	await get_tree().process_frame

	passed_tests += 1
	print("  -> Passed Criterion 5: GameOverModal buttons and signals verified.")


func test_criterion_6_deskview_game_over_flow() -> void:
	print("Test 6: DeskView game over lifecycle and restart mandate...")

	# Create a dummy autosave
	SaveLoadManager.save_game("autosave")
	assert(SaveLoadManager.has_save("autosave") == true, "Autosave should exist before game over")

	# Trigger game over on DeskView
	desk_view.call("_on_game_over", "END_BANKRUPTCY")
	await get_tree().process_frame

	assert(
		SaveLoadManager.has_save("autosave") == false,
		"DeskView game over must purge autosave"
	)

	# Verify active_game_over is instantiated
	var active_go: Control = desk_view.get("active_game_over")
	assert(active_go != null, "active_game_over should be instantiated")

	# Restart mandate
	desk_view.call("_on_restart_mandate")
	await get_tree().process_frame

	assert(GameManager.current_day == 1, "GameManager day should reset to 1")
	assert(GameManager.is_game_over == false, "GameManager is_game_over should be false")

	passed_tests += 1
	print("  -> Passed Criterion 6: DeskView game over workflow verified.")
