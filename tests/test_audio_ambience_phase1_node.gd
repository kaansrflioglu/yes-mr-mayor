extends Node

## test_audio_ambience_phase1_node.gd
## Acceptance test suite for Audio Ambience Specification Phase 1:
## - Audio Bus Configuration (SFX, BGM, Ambience, DeskAmbience, CityExterior)
## - Continuous Ambience Loops (Clock Tick, Lamp Hum, City Exterior)
## - Procedural stream generators and tactile clock tick SFX

var passed_tests: int = 0
var total_tests: int = 5


func _ready() -> void:
	print("\n============================================================")
	print(">>> RUNNING AUDIO AMBIENCE PHASE 1 ACCEPTANCE TESTS <<<")
	print("============================================================\n")

	test_criterion_1_bus_hierarchy()
	test_criterion_2_procedural_stream_generators()
	test_criterion_3_ambience_players_and_buses()
	test_criterion_4_ambience_controls_and_toggles()
	test_criterion_5_tactile_clock_tick()

	print("\n============================================================")
	if passed_tests == total_tests:
		print(">>> ALL %d AUDIO AMBIENCE PHASE 1 TESTS PASSED! (%d/%d) <<<" % [
			total_tests, passed_tests, total_tests
		])
	else:
		print(">>> TEST FAILURES DETECTED! (%d/%d) <<<" % [passed_tests, total_tests])
	print("============================================================\n")

	get_tree().quit(0 if passed_tests == total_tests else 1)


func test_criterion_1_bus_hierarchy() -> void:
	print("[TEST 1] Verifying Audio Bus Hierarchy & DSP Filters...")

	# SFX bus
	var sfx_idx := AudioServer.get_bus_index("SFX")
	assert(sfx_idx != -1, "SFX bus must exist.")
	assert(AudioServer.get_bus_send(sfx_idx) == "Master", "SFX bus must route to Master.")
	var has_limiter: bool = false
	for i in range(AudioServer.get_bus_effect_count(sfx_idx)):
		if AudioServer.get_bus_effect(sfx_idx, i) is AudioEffectLimiter:
			has_limiter = true
			break
	assert(has_limiter, "SFX bus must have AudioEffectLimiter.")

	# BGM bus
	var bgm_idx := AudioServer.get_bus_index("BGM")
	assert(bgm_idx != -1, "BGM bus must exist.")
	assert(AudioServer.get_bus_send(bgm_idx) == "Master", "BGM bus must route to Master.")
	var has_lpf: bool = false
	for i in range(AudioServer.get_bus_effect_count(bgm_idx)):
		if AudioServer.get_bus_effect(bgm_idx, i) is AudioEffectLowPassFilter:
			has_lpf = true
			break
	assert(has_lpf, "BGM bus must have AudioEffectLowPassFilter.")

	# Ambience bus
	var amb_idx := AudioServer.get_bus_index("Ambience")
	assert(amb_idx != -1, "Ambience bus must exist.")
	assert(AudioServer.get_bus_send(amb_idx) == "Master", "Ambience bus must route to Master.")

	# DeskAmbience bus
	var desk_amb_idx := AudioServer.get_bus_index("DeskAmbience")
	assert(desk_amb_idx != -1, "DeskAmbience bus must exist.")
	assert(AudioServer.get_bus_send(desk_amb_idx) == "Ambience", "DeskAmbience must route to Ambience.")

	# CityExterior bus
	var city_idx := AudioServer.get_bus_index("CityExterior")
	assert(city_idx != -1, "CityExterior bus must exist.")
	assert(AudioServer.get_bus_send(city_idx) == "Ambience", "CityExterior must route to Ambience.")

	passed_tests += 1
	print("  [PASS] Bus layout & routing verified.")


func test_criterion_2_procedural_stream_generators() -> void:
	print("[TEST 2] Verifying Procedural Audio Stream Generators...")

	# Clock tick generator (2.0s, 60 BPM)
	var clock_stream: AudioStreamWAV = AudioManager.generate_clock_tick_stream()
	assert(clock_stream != null, "Clock tick stream must not be null.")
	assert(clock_stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "Clock tick stream must loop forward.")
	assert(clock_stream.data.size() > 0, "Clock tick data must not be empty.")

	# Lamp hum generator (1.0s, 50 Hz harmonic loop)
	var lamp_stream: AudioStreamWAV = AudioManager.generate_lamp_hum_stream()
	assert(lamp_stream != null, "Lamp hum stream must not be null.")
	assert(lamp_stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "Lamp hum stream must loop forward.")
	assert(lamp_stream.data.size() > 0, "Lamp hum data must not be empty.")

	# City rumble generator (3.0s, low traffic rumble)
	var city_stream: AudioStreamWAV = AudioManager.generate_city_rumble_stream()
	assert(city_stream != null, "City rumble stream must not be null.")
	assert(city_stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "City rumble stream must loop forward.")
	assert(city_stream.data.size() > 0, "City rumble data must not be empty.")

	passed_tests += 1
	print("  [PASS] Procedural stream generation and loop modes verified.")


func test_criterion_3_ambience_players_and_buses() -> void:
	print("[TEST 3] Verifying Ambience Players and Channel Routing...")

	assert(AudioManager.has_method("start_office_ambience"), "Must have start_office_ambience().")
	assert(AudioManager.has_method("stop_office_ambience"), "Must have stop_office_ambience().")
	assert(AudioManager.is_ambience_playing(), "Office ambience should be active by default.")

	# Check child players
	var clock_player: AudioStreamPlayer = AudioManager.get_node_or_null("ClockTickLoop")
	assert(clock_player != null, "ClockTickLoop player node must exist.")
	assert(clock_player.bus == "DeskAmbience", "ClockTickLoop must be routed to DeskAmbience.")

	var lamp_player: AudioStreamPlayer = AudioManager.get_node_or_null("LampHumLoop")
	assert(lamp_player != null, "LampHumLoop player node must exist.")
	assert(lamp_player.bus == "DeskAmbience", "LampHumLoop must be routed to DeskAmbience.")

	var city_player: AudioStreamPlayer = AudioManager.get_node_or_null("CityExteriorLoop")
	assert(city_player != null, "CityExteriorLoop player node must exist.")
	assert(city_player.bus == "CityExterior", "CityExteriorLoop must be routed to CityExterior.")

	passed_tests += 1
	print("  [PASS] Ambient AudioStreamPlayers exist and are bound to correct buses.")


func test_criterion_4_ambience_controls_and_toggles() -> void:
	print("[TEST 4] Verifying Ambience Controls and Layer Toggles...")

	# Mute / Unmute clock
	AudioManager.set_clock_tick_enabled(false)
	assert(not AudioManager.is_clock_tick_enabled(), "Clock tick should be disabled.")
	AudioManager.set_clock_tick_enabled(true)
	assert(AudioManager.is_clock_tick_enabled(), "Clock tick should be enabled.")

	# Mute / Unmute lamp hum
	AudioManager.set_lamp_hum_enabled(false)
	assert(not AudioManager.is_lamp_hum_enabled(), "Lamp hum should be disabled.")
	AudioManager.set_lamp_hum_enabled(true)
	assert(AudioManager.is_lamp_hum_enabled(), "Lamp hum should be enabled.")

	# Mute / Unmute city rumble
	AudioManager.set_city_rumble_enabled(false)
	assert(not AudioManager.is_city_rumble_enabled(), "City rumble should be disabled.")
	AudioManager.set_city_rumble_enabled(true)
	assert(AudioManager.is_city_rumble_enabled(), "City rumble should be enabled.")

	# Master ambience toggle
	AudioManager.stop_office_ambience()
	assert(not AudioManager.is_ambience_playing(), "Ambience should be stopped.")
	AudioManager.start_office_ambience()
	assert(AudioManager.is_ambience_playing(), "Ambience should be restarted.")

	# Ambience volume
	AudioManager.set_ambience_volume(0.6)
	var amb_idx := AudioServer.get_bus_index("Ambience")
	assert(not AudioServer.is_bus_mute(amb_idx), "Ambience bus should not be muted at 0.6 volume.")

	passed_tests += 1
	print("  [PASS] Ambience layer controls & volume adjustment verified.")


func test_criterion_5_tactile_clock_tick() -> void:
	print("[TEST 5] Verifying Tactile Clock Tick SFX Method...")

	assert(AudioManager.has_method("play_clock_tick"), "AudioManager must implement play_clock_tick().")
	AudioManager.play_clock_tick()

	passed_tests += 1
	print("  [PASS] Tactile play_clock_tick() executed successfully.")
