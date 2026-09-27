extends Node

## test_audio_ambience_phase3_node.gd
## Acceptance test suite for Audio Ambience Specification Phase 3:
## - Dynamic Audio Reactivity (opinion < 25% riot sirens, suspicion > 50% LPF cutoff, suspicion > 75% heartbeat)
## - Inspection Mode Audio Profile (CityExterior ducking by -6 dB, high-pass focus hum)
## - Tactile Micro-SFX (coffee clink, espresso sip, safe drawer slide, phone receiver slam)

var passed_tests: int = 0
var total_tests: int = 5


func _ready() -> void:
	print("\n============================================================")
	print(">>> RUNNING AUDIO AMBIENCE PHASE 3 ACCEPTANCE TESTS <<<")
	print("============================================================\n")

	test_criterion_1_opinion_riot_reactivity()
	test_criterion_2_suspicion_lpf_and_heartbeat()
	test_criterion_3_inspection_audio_profile()
	test_criterion_4_tactile_micro_sfx()
	test_criterion_5_procedural_stream_generators()

	print("\n============================================================")
	if passed_tests == total_tests:
		print(">>> ALL %d AUDIO AMBIENCE PHASE 3 TESTS PASSED! (%d/%d) <<<" % [
			total_tests, passed_tests, total_tests
		])
	else:
		print(">>> TEST FAILURES DETECTED! (%d/%d) <<<" % [passed_tests, total_tests])
	print("============================================================\n")

	get_tree().quit(0 if passed_tests == total_tests else 1)


func test_criterion_1_opinion_riot_reactivity() -> void:
	print("[TEST 1] Verifying Public Opinion (<25%) Riot Siren Reactivity...")

	# Trigger low opinion riot state
	AudioManager.update_dynamic_audio_reactivity(18.0, 20.0)
	assert(AudioManager.is_riot_siren_active(), "Riot sirens should be active when opinion < 25%.")

	var riot_player: AudioStreamPlayer = AudioManager.get_node_or_null("RiotSirenLoop")
	assert(riot_player != null, "RiotSirenLoop node must exist.")
	assert(riot_player.bus == "CityExterior", "RiotSirenLoop bus must be 'CityExterior'.")

	# Restore opinion >= 25%
	AudioManager.update_dynamic_audio_reactivity(55.0, 20.0)
	assert(not AudioManager.is_riot_siren_active(), "Riot sirens should be deactivated when opinion >= 25%.")

	passed_tests += 1
	print("  [PASS] Riot siren & chanting reaction to low opinion verified.")


func test_criterion_2_suspicion_lpf_and_heartbeat() -> void:
	print("[TEST 2] Verifying Federal Suspicion DSP Filter Modulation & Heartbeat...")

	# Normal suspicion (<50%): full frequency spectrum
	AudioManager.update_dynamic_audio_reactivity(50.0, 30.0)
	assert(
		is_equal_approx(AudioManager.get_bgm_lowpass_cutoff(), 20000.0),
		"BGM cutoff should be 20000 Hz under low suspicion."
	)
	assert(not AudioManager.is_heartbeat_active(), "Heartbeat should be inactive when suspicion <= 75%.")

	# Elevated suspicion (80%): LPF should drop and heartbeat activates
	AudioManager.update_dynamic_audio_reactivity(50.0, 80.0)
	assert(
		AudioManager.get_bgm_lowpass_cutoff() < 15000.0,
		"BGM cutoff should drop below 15000 Hz when suspicion > 50%."
	)
	assert(AudioManager.is_heartbeat_active(), "Heartbeat must activate when suspicion > 75%.")

	var heartbeat_player: AudioStreamPlayer = AudioManager.get_node_or_null("HeartbeatLoop")
	assert(heartbeat_player != null, "HeartbeatLoop node must exist.")
	assert(heartbeat_player.bus == "DeskAmbience", "HeartbeatLoop must route to 'DeskAmbience'.")

	# Maximum suspicion (100%): cutoff drops to 2500 Hz
	AudioManager.update_dynamic_audio_reactivity(50.0, 100.0)
	assert(
		is_equal_approx(AudioManager.get_bgm_lowpass_cutoff(), 2500.0),
		"BGM cutoff must drop to 2500 Hz at maximum suspicion."
	)

	# Reset suspicion to zero
	AudioManager.update_dynamic_audio_reactivity(50.0, 0.0)
	assert(not AudioManager.is_heartbeat_active(), "Heartbeat must be stopped.")
	assert(
		is_equal_approx(AudioManager.get_bgm_lowpass_cutoff(), 20000.0),
		"BGM cutoff must return to 20000 Hz."
	)

	passed_tests += 1
	print("  [PASS] Suspicion BGM Low-Pass filter and heartbeat reactions verified.")


func test_criterion_3_inspection_audio_profile() -> void:
	print("[TEST 3] Verifying Inspection Mode Audio Profile (Exterior Ducking & Focus Hum)...")

	var city_bus_idx := AudioServer.get_bus_index("CityExterior")
	assert(city_bus_idx != -1, "CityExterior bus must exist.")

	# Activate inspection mode
	AudioManager.set_inspection_mode_active(true)
	assert(AudioManager.is_inspection_audio_active(), "Inspection audio mode should be active.")
	assert(
		is_equal_approx(AudioServer.get_bus_volume_db(city_bus_idx), -10.0),
		"CityExterior should duck to -10.0 dB (-6 dB attenuation)."
	)

	var focus_player: AudioStreamPlayer = AudioManager.get_node_or_null("FocusHumLoop")
	assert(focus_player != null, "FocusHumLoop node must exist.")
	assert(focus_player.bus == "DeskAmbience", "FocusHumLoop must route to 'DeskAmbience'.")

	# Deactivate inspection mode
	AudioManager.set_inspection_mode_active(false)
	assert(not AudioManager.is_inspection_audio_active(), "Inspection audio mode should be inactive.")
	assert(
		is_equal_approx(AudioServer.get_bus_volume_db(city_bus_idx), -4.0),
		"CityExterior should restore to -4.0 dB."
	)

	passed_tests += 1
	print("  [PASS] Inspection mode exterior ducking and high-pass focus hum verified.")


func test_criterion_4_tactile_micro_sfx() -> void:
	print("[TEST 4] Verifying Tactile Micro-SFX Synthesis Methods...")

	assert(AudioManager.has_method("play_coffee_clink"), "Must have play_coffee_clink().")
	assert(AudioManager.has_method("play_coffee_sip"), "Must have play_coffee_sip().")
	assert(AudioManager.has_method("play_safe_drawer_slide"), "Must have play_safe_drawer_slide().")
	assert(AudioManager.has_method("play_phone_receiver_slam"), "Must have play_phone_receiver_slam().")
	assert(AudioManager.has_method("play_phone_hangup"), "Must have play_phone_hangup().")

	# Execute procedural sound synthesis
	AudioManager.play_coffee_clink()
	AudioManager.play_coffee_sip()
	AudioManager.play_safe_drawer_slide(true)
	AudioManager.play_safe_drawer_slide(false)
	AudioManager.play_phone_receiver_slam()
	AudioManager.play_phone_hangup()

	passed_tests += 1
	print("  [PASS] Tactile micro-SFX methods executed successfully.")


func test_criterion_5_procedural_stream_generators() -> void:
	print("[TEST 5] Verifying Phase 3 Procedural Stream Generators...")

	# Riot siren generator
	var siren_stream: AudioStreamWAV = AudioManager.generate_riot_siren_stream()
	assert(siren_stream != null, "Riot siren stream must not be null.")
	assert(siren_stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "Siren stream must loop forward.")
	assert(siren_stream.data.size() > 0, "Siren stream data must not be empty.")

	# Heartbeat generator
	var heartbeat_stream: AudioStreamWAV = AudioManager.generate_heartbeat_stream()
	assert(heartbeat_stream != null, "Heartbeat stream must not be null.")
	assert(heartbeat_stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "Heartbeat stream must loop forward.")
	assert(heartbeat_stream.data.size() > 0, "Heartbeat stream data must not be empty.")

	# Focus hum generator
	var focus_stream: AudioStreamWAV = AudioManager.generate_focus_hum_stream()
	assert(focus_stream != null, "Focus hum stream must not be null.")
	assert(focus_stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "Focus hum stream must loop forward.")
	assert(focus_stream.data.size() > 0, "Focus hum stream data must not be empty.")

	passed_tests += 1
	print("  [PASS] Procedural stream generators for Phase 3 verified.")
