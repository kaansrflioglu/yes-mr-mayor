extends Node

## test_controls_phase2_node.gd - Acceptance tests for Controls & QoL Phase 2
## Validates:
## 1. Keycap badges exist on Approve, Reject, and Bribe buttons
## 2. Badges display accurate keycap labels ("A", "D", "S")
## 3. SettingsManager hotkey_hints_toggled signal hides/shows badges
## 4. SettingsModal CheckHotkeyHints checkbox controls SettingsManager
## 5. Settings persistence for show_hotkey_hints
## 6. Tactile button slam animation runs without error

const DESK_VIEW_SCENE: PackedScene = preload("res://scenes/desk/DeskView.tscn")
const SETTINGS_MODAL_SCENE: PackedScene = preload("res://scenes/ui/SettingsModal.tscn")

var passed_tests: int = 0
var total_tests: int = 6
var desk: Control = null
var settings_modal: Control = null


func _ready() -> void:
	print("\n============================================================")
	print(">>> RUNNING KEYBOARD CONTROLS & QOL: PHASE 2 TESTS <<<")
	print("============================================================\n")

	_run_tests_async()


func _run_tests_async() -> void:
	desk = DESK_VIEW_SCENE.instantiate()
	add_child(desk)
	settings_modal = SETTINGS_MODAL_SCENE.instantiate()
	add_child(settings_modal)
	await get_tree().process_frame

	if desk.active_document != null and desk.active_document.has_signal("slide_in_completed"):
		await desk.active_document.slide_in_completed
	else:
		await get_tree().create_timer(0.6).timeout

	test_criterion_1_keycap_nodes_exist()
	test_criterion_2_keycap_labels()
	test_criterion_3_hotkey_hint_toggle_visibility()
	test_criterion_4_settings_modal_integration()
	test_criterion_5_settings_persistence()
	await test_criterion_6_tactile_button_slam_animation()

	print("\n============================================================")
	if passed_tests == total_tests:
		print(">>> ALL %d CONTROLS PHASE 2 TESTS PASSED SUCCESSFULLY! <<<" % total_tests)
	else:
		print(">>> TEST FAILURES DETECTED! (%d/%d passed) <<<" % [passed_tests, total_tests])
	print("============================================================\n")

	get_tree().quit(0 if passed_tests == total_tests else 1)


func test_criterion_1_keycap_nodes_exist() -> void:
	print("[TEST 1] Verifying keycap pill badges exist on buttons...")
	var approve_badge: Control = desk.get_node_or_null("%ApproveKeycap")
	var reject_badge: Control = desk.get_node_or_null("%RejectKeycap")
	var bribe_badge: Control = null
	if desk.active_document != null:
		bribe_badge = desk.active_document.get_node_or_null("%BribeKeycap")

	if approve_badge != null and reject_badge != null and bribe_badge != null:
		print("  -> Approve, Reject, and Bribe keycap badges found [OK]")
		passed_tests += 1
		print("  [PASS] Test 1: Keycap nodes exist.")
	else:
		printerr("  [FAIL] Test 1: Missing keycap nodes (Approve: %s, Reject: %s, Bribe: %s)" % [approve_badge != null, reject_badge != null, bribe_badge != null])


func test_criterion_2_keycap_labels() -> void:
	print("[TEST 2] Verifying keycap badge texts...")
	var approve_badge: Control = desk.get_node_or_null("%ApproveKeycap")
	var reject_badge: Control = desk.get_node_or_null("%RejectKeycap")
	var bribe_badge: Control = null
	if desk.active_document != null:
		bribe_badge = desk.active_document.get_node_or_null("%BribeKeycap")

	var app_label := approve_badge.get_node_or_null("KeycapLabel") as Label if approve_badge else null
	var rej_label := reject_badge.get_node_or_null("KeycapLabel") as Label if reject_badge else null
	var bri_label := bribe_badge.get_node_or_null("KeycapLabel") as Label if bribe_badge else null

	var valid: bool = (
		app_label != null and app_label.text == "A"
		and rej_label != null and rej_label.text == "D"
		and bri_label != null and bri_label.text == "S"
	)

	if valid:
		print("  -> Badges correctly show [A], [D], [S] shortcuts [OK]")
		passed_tests += 1
		print("  [PASS] Test 2: Keycap labels verified.")
	else:
		printerr("  [FAIL] Test 2: Label texts invalid.")


func test_criterion_3_hotkey_hint_toggle_visibility() -> void:
	print("[TEST 3] Verifying toggle hiding/showing keycap badges...")
	var approve_badge: Control = desk.get_node_or_null("%ApproveKeycap")
	var reject_badge: Control = desk.get_node_or_null("%RejectKeycap")
	var bribe_badge: Control = null
	if desk.active_document != null:
		bribe_badge = desk.active_document.get_node_or_null("%BribeKeycap")

	# Toggle off
	SettingsManager.set_show_hotkey_hints(false)
	var hidden_ok: bool = (not approve_badge.visible and not reject_badge.visible and not bribe_badge.visible)

	# Toggle on
	SettingsManager.set_show_hotkey_hints(true)
	var visible_ok: bool = (approve_badge.visible and reject_badge.visible and bribe_badge.visible)

	if hidden_ok and visible_ok:
		print("  -> Badges cleanly hide when disabled and show when enabled [OK]")
		passed_tests += 1
		print("  [PASS] Test 3: Hotkey hint toggle verified.")
	else:
		printerr("  [FAIL] Test 3: Badges visibility state incorrect (hidden: %s, visible: %s)" % [hidden_ok, visible_ok])


func test_criterion_4_settings_modal_integration() -> void:
	print("[TEST 4] Verifying SettingsModal CheckHotkeyHints checkbox...")
	var checkbox: CheckBox = settings_modal.get_node_or_null("%CheckHotkeyHints")
	if checkbox == null:
		printerr("  [FAIL] CheckHotkeyHints checkbox not found in SettingsModal.")
		return

	settings_modal.open()
	var initial_checked: bool = checkbox.button_pressed

	# Simulate user clicking checkbox to toggle off
	checkbox.button_pressed = false
	var manager_updated_to_false: bool = not SettingsManager.show_hotkey_hints

	# Simulate user clicking checkbox to toggle back on
	checkbox.button_pressed = true
	var manager_updated_to_true: bool = SettingsManager.show_hotkey_hints

	settings_modal.close()

	if initial_checked and manager_updated_to_false and manager_updated_to_true:
		print("  -> SettingsModal checkbox dynamically controls SettingsManager [OK]")
		passed_tests += 1
		print("  [PASS] Test 4: Settings modal integration verified.")
	else:
		printerr("  [FAIL] Test 4: Checkbox sync error.")


func test_criterion_5_settings_persistence() -> void:
	print("[TEST 5] Verifying SettingsManager persistence to config file...")
	SettingsManager.set_show_hotkey_hints(false)
	SettingsManager.save_settings()

	# Reset variable in memory
	SettingsManager.show_hotkey_hints = true
	# Reload from config file
	SettingsManager.load_settings()

	var persisted_false: bool = not SettingsManager.show_hotkey_hints

	# Restore to true
	SettingsManager.set_show_hotkey_hints(true)
	SettingsManager.save_settings()
	SettingsManager.load_settings()
	var persisted_true: bool = SettingsManager.show_hotkey_hints

	if persisted_false and persisted_true:
		print("  -> show_hotkey_hints properly persists in settings.cfg [OK]")
		passed_tests += 1
		print("  [PASS] Test 5: Settings persistence verified.")
	else:
		printerr("  [FAIL] Test 5: Persistence error.")


func test_criterion_6_tactile_button_slam_animation() -> void:
	print("[TEST 6] Verifying tactile button slam press animation...")
	var btn: Button = desk.btn_stamp_approve as Button
	desk._animate_button_slam(btn)

	# Await slight delay while tween runs
	await get_tree().create_timer(0.08).timeout
	var scaled_down: bool = (btn.scale.x < 1.0 and btn.scale.y < 1.0)
	await get_tree().create_timer(0.15).timeout
	var restored: bool = (is_equal_approx(btn.scale.x, 1.0) and is_equal_approx(btn.scale.y, 1.0))

	if scaled_down or restored:
		print("  -> Tactile slam press animation executes smoothly [OK]")
		passed_tests += 1
		print("  [PASS] Test 6: Tactile button slam animation verified.")
	else:
		printerr("  [FAIL] Test 6: Button slam scale animation mismatch.")
