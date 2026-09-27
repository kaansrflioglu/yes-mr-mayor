extends Node

## test_audio_ambience_phase2_node.gd
## Acceptance test suite for Audio Ambience Specification Phase 2:
## - Lo-Fi Bureaucratic Noir Procedural BGM Generation (14s D minor / A minor loop)
## - BGM Player Setup & Routing on "BGM" Audio Bus
## - Dynamic Context Switching & Smooth Volume Fading (menu, desk, summary, pause, game_over)
## - SettingsManager BGM Volume and Mute Integration

var passed_tests: int = 0
var total_tests: int = 5


func _ready() -> void:
	print("\n============================================================")
	print(">>> RUNNING AUDIO AMBIENCE PHASE 2 ACCEPTANCE TESTS <<<")
	print("============================================================\n")

	test_criterion_1_procedural_noir_bgm_stream()
	test_criterion_2_bgm_player_and_bus()
	test_criterion_3_context_switching_and_fading()
	test_criterion_4_bgm_play_stop_lifecycle()
	test_criterion_5_settings_manager_bgm_controls()

	print("\n============================================================")
	if passed_tests == total_tests:
		print(">>> ALL %d AUDIO AMBIENCE PHASE 2 TESTS PASSED! (%d/%d) <<<" % [
			total_tests, passed_tests, total_tests
		])
	else:
		print(">>> TEST FAILURES DETECTED! (%d/%d) <<<" % [passed_tests, total_tests])
	print("============================================================\n")

	get_tree().quit(0 if passed_tests == total_tests else 1)


func test_criterion_1_procedural_noir_bgm_stream() -> void:
	print("[TEST 1] Verifying Procedural Lo-Fi Noir BGM Stream...")

	assert(AudioManager.has_method("generate_noir_bgm_stream"), "Must have generate_noir_bgm_stream().")
	var stream: AudioStreamWAV = AudioManager.generate_noir_bgm_stream()
	assert(stream != null, "Noir BGM stream must not be null.")
	assert(stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "Stream must loop forward.")
	assert(stream.data.size() > 0, "BGM stream data must not be empty.")
	assert(
		is_equal_approx(stream.mix_rate, AudioManager.SAMPLE_RATE),
		"Sample rate must match AudioManager.SAMPLE_RATE."
	)

	var expected_samples: int = int(AudioManager.SAMPLE_RATE * 14.0)
	assert(stream.loop_end == expected_samples, "Loop end must match 14-second sample count.")

	passed_tests += 1
	print("  [PASS] Procedural 14s Lo-Fi Noir BGM stream generated successfully.")


func test_criterion_2_bgm_player_and_bus() -> void:
	print("[TEST 2] Verifying BGM AudioStreamPlayer & Bus Routing...")

	var bgm_player: AudioStreamPlayer = AudioManager.get_node_or_null("NoirBGMPlayer")
	assert(bgm_player != null, "NoirBGMPlayer node must exist under AudioManager.")
	assert(bgm_player.bus == "BGM", "NoirBGMPlayer bus must be 'BGM'.")
	assert(bgm_player.stream != null, "NoirBGMPlayer must have stream assigned.")
	assert(AudioManager.is_bgm_playing(), "BGM should be playing by default.")

	passed_tests += 1
	print("  [PASS] BGM player initialized and routed to 'BGM' bus.")


func test_criterion_3_context_switching_and_fading() -> void:
	print("[TEST 3] Verifying Dynamic BGM Context Switching...")

	assert(AudioManager.has_method("set_bgm_context"), "Must have set_bgm_context().")
	assert(AudioManager.has_method("get_bgm_context"), "Must have get_bgm_context().")

	# Test menu context
	AudioManager.set_bgm_context("menu", 0.05)
	assert(AudioManager.get_bgm_context() == "menu", "Context should be 'menu'.")

	# Test desk context
	AudioManager.set_bgm_context("desk", 0.05)
	assert(AudioManager.get_bgm_context() == "desk", "Context should be 'desk'.")

	# Test summary context
	AudioManager.set_bgm_context("summary", 0.05)
	assert(AudioManager.get_bgm_context() == "summary", "Context should be 'summary'.")

	# Test pause context
	AudioManager.set_bgm_context("pause", 0.05)
	assert(AudioManager.get_bgm_context() == "pause", "Context should be 'pause'.")

	# Test game over context
	AudioManager.set_bgm_context("game_over", 0.05)
	assert(AudioManager.get_bgm_context() == "game_over", "Context should be 'game_over'.")

	passed_tests += 1
	print("  [PASS] Context switching across menu, desk, summary, pause, and game over verified.")


func test_criterion_4_bgm_play_stop_lifecycle() -> void:
	print("[TEST 4] Verifying BGM Play / Stop Lifecycle...")

	assert(AudioManager.has_method("play_bgm"), "Must have play_bgm().")
	assert(AudioManager.has_method("stop_bgm"), "Must have stop_bgm().")

	# Stop BGM
	AudioManager.stop_bgm(0.0)
	var bgm_player: AudioStreamPlayer = AudioManager.get_node_or_null("NoirBGMPlayer")
	assert(bgm_player != null, "NoirBGMPlayer must exist.")

	# Resume BGM
	AudioManager.play_bgm(0.05)
	assert(AudioManager.is_bgm_playing(), "BGM should be playing after play_bgm().")

	passed_tests += 1
	print("  [PASS] BGM play and stop lifecycle verified.")


func test_criterion_5_settings_manager_bgm_controls() -> void:
	print("[TEST 5] Verifying SettingsManager BGM Volume & Mute...")

	# Volume test
	SettingsManager.set_bgm_volume(0.4)
	assert(is_equal_approx(SettingsManager.bgm_volume, 0.4), "BGM volume must be 0.4.")

	var bgm_bus_idx := AudioServer.get_bus_index("BGM")
	assert(bgm_bus_idx != -1, "BGM bus must exist.")
	var expected_db := linear_to_db(0.4)
	assert(
		is_equal_approx(AudioServer.get_bus_volume_db(bgm_bus_idx), expected_db),
		"BGM bus volume db must match linear_to_db(0.4)."
	)

	# Mute test
	SettingsManager.set_bgm_muted(true)
	assert(SettingsManager.bgm_muted, "bgm_muted should be true.")
	assert(AudioServer.is_bus_mute(bgm_bus_idx), "BGM bus must be muted.")

	SettingsManager.set_bgm_muted(false)
	assert(not SettingsManager.bgm_muted, "bgm_muted should be false.")
	assert(not AudioServer.is_bus_mute(bgm_bus_idx), "BGM bus must be unmuted.")

	passed_tests += 1
	print("  [PASS] SettingsManager BGM volume and mute integration verified.")
