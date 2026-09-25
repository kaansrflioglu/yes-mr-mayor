extends Node

## test_settings_node.gd - Automated test suite for municipal settings system.
## Validates Audio, Display, Language switching, SettingsModal UI, and persistence.

const DESK_VIEW_SCENE: PackedScene = preload("res://scenes/desk/DeskView.tscn")

var passed_tests: int = 0
var total_tests: int = 5
var desk_view: Control = null


func _ready() -> void:
	print("\n==============================================")
	print(">>> RUNNING MUNICIPAL SETTINGS TEST SUITE <<<")
	print("==============================================\n")

	_run_tests_async()


func _run_tests_async() -> void:
	desk_view = DESK_VIEW_SCENE.instantiate()
	add_child(desk_view)
	await get_tree().process_frame

	test_criterion_1_audio_volume_and_mute()
	test_criterion_2_display_and_window_modes()
	test_criterion_3_language_switching()
	await test_criterion_4_modal_ui_and_esc_toggle()
	test_criterion_5_config_persistence()

	print("\n==============================================")
	if passed_tests == total_tests:
		print(">>> ALL 5 SETTINGS TESTS PASSED SUCCESSFULLY! (5/5) <<<")
	else:
		print(">>> TEST FAILURES DETECTED! (%d/%d) <<<" % [passed_tests, total_tests])
	print("==============================================\n")

	get_tree().quit(0 if passed_tests == total_tests else 1)


func test_criterion_1_audio_volume_and_mute() -> void:
	print("[TEST 1] Verifying Audio settings (Master, SFX, and Mute)...")
	# Change master volume
	SettingsManager.set_master_volume(0.5)
	assert(is_equal_approx(SettingsManager.master_volume, 0.5), "Master volume should be 0.5")

	# Check AudioServer Master bus
	var master_idx := AudioServer.get_bus_index("Master")
	assert(master_idx != -1, "Master bus must exist")
	var expected_db := linear_to_db(0.5)
	assert(
		is_equal_approx(AudioServer.get_bus_volume_db(master_idx), expected_db),
		"Master bus volume db mismatch"
	)

	# Change SFX volume
	SettingsManager.set_sfx_volume(0.3)
	assert(is_equal_approx(SettingsManager.sfx_volume, 0.3), "SFX volume should be 0.3")

	var sfx_idx := AudioServer.get_bus_index("SFX")
	assert(sfx_idx != -1, "SFX bus must exist")
	assert(
		is_equal_approx(AudioServer.get_bus_volume_db(sfx_idx), linear_to_db(0.3)),
		"SFX bus volume db mismatch"
	)

	# Test muting
	SettingsManager.set_master_muted(true)
	assert(AudioServer.is_bus_mute(master_idx) == true, "Master bus should be muted")
	SettingsManager.set_master_muted(false)
	assert(AudioServer.is_bus_mute(master_idx) == false, "Master bus should be unmuted")

	print("  -> Master (50%), SFX (30%), and Mute routing verified.")
	print("  [PASS] Test 1: Audio settings verified.\n")
	passed_tests += 1


func test_criterion_2_display_and_window_modes() -> void:
	print("[TEST 2] Verifying Display settings (Windowed, Fullscreen, Borderless, VSync)...")
	# Test window modes
	SettingsManager.set_window_mode(SettingsManager.WindowMode.FULLSCREEN)
	assert(
		SettingsManager.window_mode == SettingsManager.WindowMode.FULLSCREEN,
		"Mode should be Fullscreen"
	)

	SettingsManager.set_window_mode(SettingsManager.WindowMode.WINDOWED)
	assert(
		SettingsManager.window_mode == SettingsManager.WindowMode.WINDOWED,
		"Mode should be Windowed"
	)

	# Test resolutions
	var test_res := Vector2i(1600, 900)
	SettingsManager.set_resolution(test_res)
	assert(SettingsManager.resolution == test_res, "Resolution should be 1600x900")

	# Test VSync
	SettingsManager.set_vsync(false)
	assert(SettingsManager.vsync == false, "VSync should be false")
	SettingsManager.set_vsync(true)
	assert(SettingsManager.vsync == true, "VSync should be true")

	print("  -> Fullscreen, Windowed, 1600x900 resolution, and VSync toggled safely.")
	print("  [PASS] Test 2: Display settings verified.\n")
	passed_tests += 1


func test_criterion_3_language_switching() -> void:
	print("[TEST 3] Verifying real-time Language switching (TR, EN, ES)...")
	SettingsManager.set_locale("tr")
	assert(LocalizationManager.get_current_locale() == "tr", "Locale should be TR")
	assert(tr("UI_TAB_AUDIO") == "SES", "TR translation mismatch for SES")

	SettingsManager.set_locale("en")
	assert(LocalizationManager.get_current_locale() == "en", "Locale should be EN")
	assert(tr("UI_TAB_AUDIO") == "AUDIO", "EN translation mismatch for AUDIO")

	SettingsManager.set_locale("es")
	assert(LocalizationManager.get_current_locale() == "es", "Locale should be ES")
	assert(tr("UI_TAB_AUDIO") == "AUDIO", "ES translation mismatch")

	# Reset back to TR
	SettingsManager.set_locale("tr")
	print("  -> Language dynamically switched across TR, EN, ES.")
	print("  [PASS] Test 3: Language selection verified.\n")
	passed_tests += 1


func test_criterion_4_modal_ui_and_esc_toggle() -> void:
	print("[TEST 4] Verifying SettingsModal UI lifecycle, tabs, clean HUD and ESC toggle...")
	var hud: Control = desk_view.get_node("TopBarHUD") as Control
	assert(hud != null, "TopBarHUD must exist in DeskView")
	assert(hud.has_node("%BtnSettings"), "BtnSettings must exist in TopBarHUD")
	assert(not hud.has_node("%BtnEN"), "BtnEN must be removed from main HUD screen")
	assert(not hud.has_node("%BtnTwitch"), "BtnTwitch must be removed from main HUD screen")

	var modal: Control = desk_view.get_node("%SettingsModal") as Control
	assert(modal != null, "SettingsModal must exist in DeskView")
	assert(not modal.is_open, "Modal should initially be closed")

	# Open modal
	modal.open()
	assert(modal.is_open, "Modal should be marked open")
	assert(modal.visible, "Modal should be visible")

	# Tab switching
	modal.btn_tab_display.emit_signal("pressed")
	assert(modal.content_display.visible, "Display tab content must be visible")
	assert(not modal.content_audio.visible, "Audio tab content must be hidden")

	modal.btn_tab_language.emit_signal("pressed")
	assert(modal.content_language.visible, "Language tab content must be visible")

	modal.btn_tab_twitch.emit_signal("pressed")
	assert(modal.content_twitch.visible, "Twitch tab content must be visible")

	modal.btn_tab_audio.emit_signal("pressed")
	assert(modal.content_audio.visible, "Audio tab content must be visible")

	# Test close
	await modal.close()
	assert(not modal.is_open, "Modal should be closed")
	assert(not modal.visible, "Modal should be hidden")

	print("  -> Main HUD clean. Modal tabs (Audio, Display, Lang, Twitch) verified.")
	print("  [PASS] Test 4: SettingsModal UI verified.\n")
	passed_tests += 1


func test_criterion_5_config_persistence() -> void:
	print("[TEST 5] Verifying user://settings.cfg persistence and reload...")
	# Configure specific values
	SettingsManager.set_master_volume(0.65)
	SettingsManager.set_sfx_volume(0.42)
	SettingsManager.set_window_mode(SettingsManager.WindowMode.WINDOWED)
	SettingsManager.set_resolution(Vector2i(1366, 768))
	SettingsManager.set_vsync(false)
	SettingsManager.set_locale("tr")
	SettingsManager.save_settings()

	# Verify file written
	var cfg := ConfigFile.new()
	var err := cfg.load(SettingsManager.CONFIG_PATH)
	assert(err == OK, "settings.cfg must load successfully")
	assert(
		is_equal_approx(cfg.get_value("audio", "master_volume"), 0.65),
		"Saved master volume mismatch"
	)
	assert(
		is_equal_approx(cfg.get_value("audio", "sfx_volume"), 0.42),
		"Saved sfx volume mismatch"
	)
	assert(
		cfg.get_value("display", "resolution_x") == 1366,
		"Saved resolution_x mismatch"
	)
	assert(
		cfg.get_value("localization", "locale") == "tr",
		"Saved locale mismatch"
	)

	# Simulate fresh reload
	SettingsManager.master_volume = 1.0
	SettingsManager.load_settings()
	assert(
		is_equal_approx(SettingsManager.master_volume, 0.65),
		"Loaded master volume mismatch"
	)
	assert(
		SettingsManager.resolution == Vector2i(1366, 768),
		"Loaded resolution mismatch"
	)

	print("  -> Preferences saved to user://settings.cfg and restored on reload.")
	print("  [PASS] Test 5: Config persistence verified.\n")
	passed_tests += 1
