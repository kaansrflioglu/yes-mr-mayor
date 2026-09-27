extends Node

## AudioManager.gd - Central sound effects & atmospheric audio manager.
## Provides procedural audio synthesis and playback for tactile physical feedback.

const SAMPLE_RATE: float = 22050.0

var _audio_players: Array[AudioStreamPlayer] = []
const POOL_SIZE: int = 8

var _clock_player: AudioStreamPlayer = null
var _lamp_hum_player: AudioStreamPlayer = null
var _city_exterior_player: AudioStreamPlayer = null
var _ambience_initialized: bool = false
var _ambience_active: bool = true
var _clock_tick_enabled: bool = true
var _lamp_hum_enabled: bool = true
var _city_rumble_enabled: bool = true


func _ready() -> void:
	_setup_audio_buses()

	for i in range(POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_audio_players.append(player)

	_init_ambience_loops()


func _setup_audio_buses() -> void:
	_ensure_bus("SFX", "Master", 0.0)
	_ensure_bus_limiter("SFX")

	_ensure_bus("BGM", "Master", -12.0)
	_ensure_bus_lowpass("BGM")

	_ensure_bus("Ambience", "Master", -16.0)
	_ensure_bus("DeskAmbience", "Ambience", -2.0)
	_ensure_bus("CityExterior", "Ambience", -4.0)


func _ensure_bus(bus_name: String, send_to: String = "Master", vol_db: float = 0.0) -> int:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		AudioServer.add_bus()
		idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, send_to)
		AudioServer.set_bus_volume_db(idx, vol_db)
	return idx


func _ensure_bus_limiter(bus_name: String) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	for i in range(AudioServer.get_bus_effect_count(idx)):
		if AudioServer.get_bus_effect(idx, i) is AudioEffectLimiter:
			return
	var limiter := AudioEffectLimiter.new()
	limiter.ceiling_db = -0.1
	limiter.threshold_db = 0.0
	AudioServer.add_bus_effect(idx, limiter)


func _ensure_bus_lowpass(bus_name: String) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	for i in range(AudioServer.get_bus_effect_count(idx)):
		if AudioServer.get_bus_effect(idx, i) is AudioEffectLowPassFilter:
			return
	var lpf := AudioEffectLowPassFilter.new()
	lpf.cutoff_hz = 20000.0
	AudioServer.add_bus_effect(idx, lpf)


## Plays a heavy tactile physical stamp thud with ink slam punch
func play_stamp_thud(approved: bool) -> void:
	var duration: float = 0.22
	var samples: int = int(SAMPLE_RATE * duration)
	var buffer := PackedByteArray()
	buffer.resize(samples * 2)

	var start_freq: float = 140.0 if approved else 110.0
	var end_freq: float = 40.0

	for i in range(samples):
		var t: float = float(i) / SAMPLE_RATE
		var progress: float = float(i) / float(samples)
		var freq: float = lerpf(start_freq, end_freq, progress * progress)
		var envelope: float = exp(-18.0 * progress)

		# Sine kick wave + noise crack
		var sine_val: float = sin(2.0 * PI * freq * t)
		var noise_val: float = randf_range(-0.4, 0.4) * (1.0 - progress)
		var sample_f: float = clampf((sine_val * 0.75 + noise_val * 0.25) * envelope, -1.0, 1.0)

		var sample_int: int = int(sample_f * 32767.0)
		buffer.encode_s16(i * 2, sample_int)

	_play_raw_wav(buffer, int(SAMPLE_RATE))


## Plays crisp paper slide / shuffle rustle
func play_paper_slide() -> void:
	var duration: float = 0.28
	var samples: int = int(SAMPLE_RATE * duration)
	var buffer := PackedByteArray()
	buffer.resize(samples * 2)

	for i in range(samples):
		var progress: float = float(i) / float(samples)
		var envelope: float = sin(PI * progress) * (1.0 - progress * 0.4)
		var noise_val: float = randf_range(-0.35, 0.35) * envelope
		var sample_int: int = int(clampf(noise_val, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, sample_int)

	_play_raw_wav(buffer, int(SAMPLE_RATE))


## Plays metallic cash register rattle & coin drop for safe drawer
func play_cash_register() -> void:
	var duration: float = 0.35
	var samples: int = int(SAMPLE_RATE * duration)
	var buffer := PackedByteArray()
	buffer.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / SAMPLE_RATE
		var progress: float = float(i) / float(samples)
		var envelope: float = exp(-9.0 * progress)

		# Dual high chime harmonics (1800 Hz & 2400 Hz)
		var chime: float = (
			sin(2.0 * PI * 1850.0 * t) * 0.5 + sin(2.0 * PI * 2450.0 * t) * 0.5
		) * envelope

		# Coin rattle burst at start
		var rattle: float = 0.0
		if progress < 0.15:
			rattle = randf_range(-0.4, 0.4) * (1.0 - progress / 0.15)

		var sample_f: float = clampf(chime * 0.7 + rattle * 0.3, -1.0, 1.0)
		buffer.encode_s16(i * 2, int(sample_f * 32767.0))

	_play_raw_wav(buffer, int(SAMPLE_RATE))


## Plays vintage rotary telephone bell ring
func play_phone_ring() -> void:
	var duration: float = 0.45
	var samples: int = int(SAMPLE_RATE * duration)
	var buffer := PackedByteArray()
	buffer.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / SAMPLE_RATE
		var progress: float = float(i) / float(samples)
		# Rapid tremolo pulse (20 Hz)
		var pulse: float = 1.0 if sin(2.0 * PI * 20.0 * t) > 0.0 else 0.2
		var bell: float = (
			sin(2.0 * PI * 853.0 * t) * 0.5 + sin(2.0 * PI * 960.0 * t) * 0.5
		) * pulse * (1.0 - progress * 0.3)

		var sample_int: int = int(clampf(bell * 0.45, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, sample_int)

	_play_raw_wav(buffer, int(SAMPLE_RATE))


## Plays frantic double-pulse high ring for urgent calls (Police, Engineer, Whistleblower)
func play_phone_ring_urgent() -> void:
	var duration: float = 0.40
	var samples: int = int(SAMPLE_RATE * duration)
	var buffer := PackedByteArray()
	buffer.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / SAMPLE_RATE
		var progress: float = float(i) / float(samples)
		var burst: float = 1.0 if sin(2.0 * PI * 35.0 * t) > 0.0 else 0.1
		var bell: float = (
			sin(2.0 * PI * 1050.0 * t) * 0.6 + sin(2.0 * PI * 1320.0 * t) * 0.4
		) * burst * (1.0 - progress * 0.25)

		var sample_int: int = int(clampf(bell * 0.5, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, sample_int)

	_play_raw_wav(buffer, int(SAMPLE_RATE))


## Plays calm encrypted secure warble for discreet backroom calls (Party, Mafia, Press)
func play_phone_ring_secure() -> void:
	var duration: float = 0.38
	var samples: int = int(SAMPLE_RATE * duration)
	var buffer := PackedByteArray()
	buffer.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / SAMPLE_RATE
		var progress: float = float(i) / float(samples)
		var warble: float = 0.7 + sin(2.0 * PI * 12.0 * t) * 0.3
		var tone: float = (
			sin(2.0 * PI * 620.0 * t) * 0.55 + sin(2.0 * PI * 740.0 * t) * 0.45
		) * warble * exp(-3.0 * progress)

		var sample_int: int = int(clampf(tone * 0.45, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, sample_int)

	_play_raw_wav(buffer, int(SAMPLE_RATE))


## Plays archetype-specific incoming hotline ringtone
func play_phone_ring_archetype(archetype: String = "") -> void:
	match archetype.to_lower():
		"police_chief", "chief_engineer", "whistleblower":
			play_phone_ring_urgent()
		"party_boss", "mafia", "journalist":
			play_phone_ring_secure()
		_:
			play_phone_ring()


## Plays investigative discovery chime when a valid discrepancy is uncovered
func play_discrepancy_match() -> void:
	var duration: float = 0.45
	var samples: int = int(SAMPLE_RATE * duration)
	var buffer := PackedByteArray()
	buffer.resize(samples * 2)

	# Harmonic major triad chime (523 Hz C5, 659 Hz E5, 784 Hz G5, 1046 Hz C6)
	for i in range(samples):
		var t: float = float(i) / SAMPLE_RATE
		var progress: float = float(i) / float(samples)
		var envelope: float = exp(-6.0 * progress)

		var note1: float = sin(2.0 * PI * 523.25 * t)
		var note2: float = sin(2.0 * PI * 659.25 * t)
		var note3: float = sin(2.0 * PI * 783.99 * t)
		var note4: float = sin(2.0 * PI * 1046.50 * t)
		var chime: float = (note1 * 0.3 + note2 * 0.3 + note3 * 0.25 + note4 * 0.25) * envelope

		var sample_f: float = clampf(chime * 0.7, -1.0, 1.0)
		buffer.encode_s16(i * 2, int(sample_f * 32767.0))

	_play_raw_wav(buffer, int(SAMPLE_RATE))


## Plays low error buzz when inspection doesn't find a contradiction
func play_discrepancy_fail() -> void:
	var duration: float = 0.22
	var samples: int = int(SAMPLE_RATE * duration)
	var buffer := PackedByteArray()
	buffer.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / SAMPLE_RATE
		var progress: float = float(i) / float(samples)
		var envelope: float = exp(-12.0 * progress)
		# Low square-ish buzz (120 Hz)
		var buzz: float = (1.0 if sin(2.0 * PI * 120.0 * t) > 0.0 else -1.0) * 0.25
		var sample_f: float = clampf(buzz * envelope, -1.0, 1.0)
		buffer.encode_s16(i * 2, int(sample_f * 32767.0))

	_play_raw_wav(buffer, int(SAMPLE_RATE))


## Plays warm coffee sip / gulp sound effect
func play_coffee_sip() -> void:
	var duration: float = 0.32
	var samples: int = int(SAMPLE_RATE * duration)
	var buffer := PackedByteArray()
	buffer.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / SAMPLE_RATE
		var progress: float = float(i) / float(samples)
		var envelope: float = sin(PI * progress) * exp(-3.5 * progress)
		var freq1: float = lerpf(340.0, 180.0, progress)
		var freq2: float = lerpf(680.0, 360.0, progress)
		var wave: float = sin(2.0 * PI * freq1 * t) * 0.6 + sin(2.0 * PI * freq2 * t) * 0.4
		var bubble_noise: float = randf_range(-0.15, 0.15) if progress < 0.35 else 0.0
		var sample_f: float = clampf((wave + bubble_noise) * envelope * 0.75, -1.0, 1.0)
		buffer.encode_s16(i * 2, int(sample_f * 32767.0))

	_play_raw_wav(buffer, int(SAMPLE_RATE))


## Plays mechanical shutter/click when toggling inspection mode
func play_inspect_toggle() -> void:
	var duration: float = 0.12
	var samples: int = int(SAMPLE_RATE * duration)
	var buffer := PackedByteArray()
	buffer.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / SAMPLE_RATE
		var progress: float = float(i) / float(samples)
		var envelope: float = exp(-28.0 * progress)
		var click: float = sin(2.0 * PI * 1400.0 * t) * envelope
		var sample_f: float = clampf(click * 0.5, -1.0, 1.0)
		buffer.encode_s16(i * 2, int(sample_f * 32767.0))

	_play_raw_wav(buffer, int(SAMPLE_RATE))


## Plays soft binder / rulebook page turn sound
func play_page_flip() -> void:
	var duration: float = 0.20
	var samples: int = int(SAMPLE_RATE * duration)
	var buffer := PackedByteArray()
	buffer.resize(samples * 2)

	for i in range(samples):
		var progress: float = float(i) / float(samples)
		var envelope: float = sin(PI * progress)
		var noise_val: float = randf_range(-0.3, 0.3) * envelope
		var sample_int: int = int(clampf(noise_val, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, sample_int)

	_play_raw_wav(buffer, int(SAMPLE_RATE))


## Plays tactile mechanical office clock tick
func play_clock_tick() -> void:
	var duration: float = 0.12
	var samples: int = int(SAMPLE_RATE * duration)
	var buffer := PackedByteArray()
	buffer.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / SAMPLE_RATE
		var click: float = sin(2.0 * PI * 1550.0 * t) * exp(-120.0 * t) * 0.55
		var body: float = sin(2.0 * PI * 520.0 * t) * exp(-40.0 * t) * 0.35
		var noise: float = randf_range(-0.2, 0.2) * exp(-150.0 * t)
		var sample_f: float = clampf((click + body + noise) * 0.70, -1.0, 1.0)
		buffer.encode_s16(i * 2, int(sample_f * 32767.0))

	_play_raw_wav(buffer, int(SAMPLE_RATE))


## Plays fluorescent UV tube hum & switch click
func play_uv_toggle() -> void:
	var duration: float = 0.2
	var samples: int = int(SAMPLE_RATE * duration)
	var buffer := PackedByteArray()
	buffer.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / SAMPLE_RATE
		var progress: float = float(i) / float(samples)
		var envelope: float = exp(-12.0 * progress)
		var click: float = (
			sin(2.0 * PI * 920.0 * t) * 0.4 if progress < 0.2 else 0.0
		)
		var hum: float = sin(2.0 * PI * 120.0 * t) * 0.35 * envelope
		var sample_f: float = clampf((click + hum) * 0.7, -1.0, 1.0)
		buffer.encode_s16(i * 2, int(sample_f * 32767.0))

	_play_raw_wav(buffer, int(SAMPLE_RATE))


## Plays rotary telephone dial pulse / tone
func play_phone_dial() -> void:
	var duration: float = 0.22
	var samples: int = int(SAMPLE_RATE * duration)
	var buffer := PackedByteArray()
	buffer.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / SAMPLE_RATE
		var progress: float = float(i) / float(samples)
		var envelope: float = exp(-14.0 * progress)
		var dtmf: float = (
			sin(2.0 * PI * 770.0 * t) * 0.5 + sin(2.0 * PI * 1336.0 * t) * 0.5
		) * envelope
		var ratchet: float = (
			randf_range(-0.25, 0.25) * envelope if progress < 0.25 else 0.0
		)
		var sample_f: float = clampf((dtmf * 0.6 + ratchet * 0.4), -1.0, 1.0)
		buffer.encode_s16(i * 2, int(sample_f * 32767.0))

	_play_raw_wav(buffer, int(SAMPLE_RATE))


## Plays two-tone emergency federal siren for sting operations
func play_alarm_siren() -> void:
	var duration: float = 0.55
	var samples: int = int(SAMPLE_RATE * duration)
	var buffer := PackedByteArray()
	buffer.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / SAMPLE_RATE
		var progress: float = float(i) / float(samples)
		var freq: float = 720.0 if fmod(t, 0.18) < 0.09 else 940.0
		var envelope: float = sin(PI * progress)
		var wave: float = sin(2.0 * PI * freq * t) * envelope
		var sample_f: float = clampf(wave * 0.7, -1.0, 1.0)
		buffer.encode_s16(i * 2, int(sample_f * 32767.0))

	_play_raw_wav(buffer, int(SAMPLE_RATE))


## Plays heavy authoritative gavel/stamp sound for executive directives
func play_directive_stamp() -> void:
	var duration: float = 0.35
	var samples: int = int(SAMPLE_RATE * duration)
	var buffer := PackedByteArray()
	buffer.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / SAMPLE_RATE
		var progress: float = float(i) / float(samples)
		var envelope: float = exp(-18.0 * progress)
		var thud: float = sin(2.0 * PI * 110.0 * t) * envelope
		var wood: float = sin(2.0 * PI * 420.0 * t) * exp(-35.0 * progress)
		var noise: float = randf_range(-0.2, 0.2) * exp(-50.0 * progress)
		var sample_f: float = clampf(thud * 0.6 + wood * 0.3 + noise * 0.1, -1.0, 1.0)
		buffer.encode_s16(i * 2, int(sample_f * 32767.0))

	_play_raw_wav(buffer, int(SAMPLE_RATE))


## Plays electric document shredder motor chew and paper tear for Fixer
func play_paper_shredder() -> void:
	var duration: float = 0.44
	var samples: int = int(SAMPLE_RATE * duration)
	var buffer := PackedByteArray()
	buffer.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / SAMPLE_RATE
		var progress: float = float(i) / float(samples)
		var envelope: float = sin(PI * progress) * (1.0 - progress * 0.3)
		# Motor buzz (sawtooth-like at 68 Hz)
		var motor: float = (fmod(t * 68.0, 1.0) - 0.5) * 0.4
		# Paper shredding tearing chatter (noise modulated at 16 Hz)
		var chatter: float = 1.0 if sin(2.0 * PI * 16.0 * t) > 0.0 else 0.4
		var tear: float = randf_range(-0.5, 0.5) * chatter * envelope
		var sample_f: float = clampf(motor * 0.5 + tear * 0.5, -1.0, 1.0)
		buffer.encode_s16(i * 2, int(sample_f * 32767.0))

	_play_raw_wav(buffer, int(SAMPLE_RATE))


## Plays mechanical camera shutter click and high capacitor flash burst for PR Astroturf
func play_camera_flash() -> void:
	var duration: float = 0.32
	var samples: int = int(SAMPLE_RATE * duration)
	var buffer := PackedByteArray()
	buffer.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / SAMPLE_RATE
		var progress: float = float(i) / float(samples)
		# Dual shutter click at t=0 and t=0.06
		var click1: float = randf_range(-0.6, 0.6) * exp(-120.0 * t)
		var click2: float = randf_range(-0.5, 0.5) * exp(-100.0 * maxf(0.0, t - 0.06)) if t >= 0.06 else 0.0
		# Flash capacitor whine/pop
		var flash: float = sin(2.0 * PI * (2400.0 - 1200.0 * progress) * t) * exp(-10.0 * progress) * 0.35
		var sample_f: float = clampf(click1 + click2 + flash, -1.0, 1.0)
		buffer.encode_s16(i * 2, int(sample_f * 32767.0))

	_play_raw_wav(buffer, int(SAMPLE_RATE))


## Plays heavy 24K solid gold metallic stamp clang with rich brass resonance
func play_gold_stamp() -> void:
	var duration: float = 0.52
	var samples: int = int(SAMPLE_RATE * duration)
	var buffer := PackedByteArray()
	buffer.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / SAMPLE_RATE
		var progress: float = float(i) / float(samples)
		var envelope: float = exp(-8.0 * progress)
		# Deep heavy bass thud
		var bass: float = sin(2.0 * PI * 92.0 * t) * exp(-22.0 * progress) * 0.6
		# Golden bell/chime harmonics (1350 Hz & 2180 Hz)
		var gold_ring: float = (
			sin(2.0 * PI * 1350.0 * t) * 0.55 + sin(2.0 * PI * 2180.0 * t) * 0.45
		) * envelope * 0.5
		# Metallic surface impact snap
		var snap: float = randf_range(-0.3, 0.3) * exp(-45.0 * progress)
		var sample_f: float = clampf(bass + gold_ring + snap, -1.0, 1.0)
		buffer.encode_s16(i * 2, int(sample_f * 32767.0))

	_play_raw_wav(buffer, int(SAMPLE_RATE))


## Helper to build an AudioStreamWAV from raw 16-bit PCM bytes
func _play_raw_wav(data: PackedByteArray, rate: int) -> void:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = data

	var player := _get_available_player()
	if player:
		player.stream = stream
		player.play()


func _get_available_player() -> AudioStreamPlayer:
	for player in _audio_players:
		if not player.playing:
			return player
	return _audio_players[0]


## Initializes the 3 persistent ambience loop players: Clock Tick, Lamp Hum, and City Exterior
func _init_ambience_loops() -> void:
	if _ambience_initialized:
		return
	_ambience_initialized = true

	# 1. Steady mechanical wall clock ticking (60 BPM / 1 tick per sec)
	_clock_player = AudioStreamPlayer.new()
	_clock_player.name = "ClockTickLoop"
	_clock_player.bus = "DeskAmbience"
	_clock_player.stream = generate_clock_tick_stream()
	add_child(_clock_player)

	# 2. Low 50Hz hum of vintage fluorescent ceiling lights
	_lamp_hum_player = AudioStreamPlayer.new()
	_lamp_hum_player.name = "LampHumLoop"
	_lamp_hum_player.bus = "DeskAmbience"
	_lamp_hum_player.stream = generate_lamp_hum_stream()
	add_child(_lamp_hum_player)

	# 3. Dynamic window / exterior city traffic rumble
	_city_exterior_player = AudioStreamPlayer.new()
	_city_exterior_player.name = "CityExteriorLoop"
	_city_exterior_player.bus = "CityExterior"
	_city_exterior_player.stream = generate_city_rumble_stream()
	add_child(_city_exterior_player)

	start_office_ambience()


## Starts or resumes all enabled office ambience loops
func start_office_ambience() -> void:
	_ambience_active = true
	if _clock_player and _clock_tick_enabled and not _clock_player.playing:
		_clock_player.play()
	if _lamp_hum_player and _lamp_hum_enabled and not _lamp_hum_player.playing:
		_lamp_hum_player.play()
	if _city_exterior_player and _city_rumble_enabled and not _city_exterior_player.playing:
		_city_exterior_player.play()


## Stops all office ambience loops
func stop_office_ambience() -> void:
	_ambience_active = false
	if _clock_player and _clock_player.playing:
		_clock_player.stop()
	if _lamp_hum_player and _lamp_hum_player.playing:
		_lamp_hum_player.stop()
	if _city_exterior_player and _city_exterior_player.playing:
		_city_exterior_player.stop()


## Toggles overall ambience state
func set_ambience_active(active: bool) -> void:
	if active:
		start_office_ambience()
	else:
		stop_office_ambience()


## Returns true if ambience is currently active
func is_ambience_playing() -> bool:
	return _ambience_active


## Enables or disables the clock tick loop
func set_clock_tick_enabled(enabled: bool) -> void:
	_clock_tick_enabled = enabled
	if not _clock_player:
		return
	if enabled and _ambience_active and not _clock_player.playing:
		_clock_player.play()
	elif not enabled and _clock_player.playing:
		_clock_player.stop()


## Enables or disables the fluorescent lamp hum loop
func set_lamp_hum_enabled(enabled: bool) -> void:
	_lamp_hum_enabled = enabled
	if not _lamp_hum_player:
		return
	if enabled and _ambience_active and not _lamp_hum_player.playing:
		_lamp_hum_player.play()
	elif not enabled and _lamp_hum_player.playing:
		_lamp_hum_player.stop()


## Enables or disables the exterior city rumble loop
func set_city_rumble_enabled(enabled: bool) -> void:
	_city_rumble_enabled = enabled
	if not _city_exterior_player:
		return
	if enabled and _ambience_active and not _city_exterior_player.playing:
		_city_exterior_player.play()
	elif not enabled and _city_exterior_player.playing:
		_city_exterior_player.stop()


## Sets linear volume for Ambience bus (0.0 to 1.0)
func set_ambience_volume(linear_vol: float) -> void:
	var idx := AudioServer.get_bus_index("Ambience")
	if idx != -1:
		if linear_vol <= 0.001:
			AudioServer.set_bus_mute(idx, true)
		else:
			AudioServer.set_bus_mute(idx, false)
			AudioServer.set_bus_volume_db(idx, linear_to_db(linear_vol))


func is_clock_tick_enabled() -> bool:
	return _clock_tick_enabled


func is_lamp_hum_enabled() -> bool:
	return _lamp_hum_enabled


func is_city_rumble_enabled() -> bool:
	return _city_rumble_enabled


## Generates a seamless 2-beat rhythmic wall clock tick audio stream (60 BPM)
func generate_clock_tick_stream() -> AudioStreamWAV:
	var duration: float = 2.0
	var samples: int = int(SAMPLE_RATE * duration)
	var buffer := PackedByteArray()
	buffer.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / SAMPLE_RATE
		var sample_f: float = 0.0

		# Beat 1: "Tick" at t = 0.0s (Crisp, higher pitch)
		if t < 0.12:
			var click: float = sin(2.0 * PI * 1650.0 * t) * exp(-140.0 * t)
			var wood: float = sin(2.0 * PI * 580.0 * t) * exp(-45.0 * t)
			var noise: float = randf_range(-0.25, 0.25) * exp(-180.0 * t)
			sample_f = (click * 0.55 + wood * 0.35 + noise * 0.10) * 0.40
		# Beat 2: "Tock" at t = 1.0s (Warmer, lower pitch)
		elif t >= 1.0 and t < 1.12:
			var t_rel: float = t - 1.0
			var click: float = sin(2.0 * PI * 1320.0 * t_rel) * exp(-140.0 * t_rel)
			var wood: float = sin(2.0 * PI * 480.0 * t_rel) * exp(-45.0 * t_rel)
			var noise: float = randf_range(-0.25, 0.25) * exp(-180.0 * t_rel)
			sample_f = (click * 0.55 + wood * 0.35 + noise * 0.10) * 0.36

		var sample_int: int = int(clampf(sample_f, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, sample_int)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(SAMPLE_RATE)
	stream.stereo = false
	stream.data = buffer
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = samples
	return stream


## Generates a seamless 50Hz fluorescent lamp hum audio stream (perfect phase alignment)
func generate_lamp_hum_stream() -> AudioStreamWAV:
	var duration: float = 1.0  # Exactly 50 cycles of 50 Hz
	var samples: int = int(SAMPLE_RATE * duration)
	var buffer := PackedByteArray()
	buffer.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / SAMPLE_RATE
		# 50Hz fundamental + 100Hz/150Hz/350Hz vintage ballast harmonics
		var h1: float = sin(2.0 * PI * 50.0 * t) * 0.45
		var h2: float = sin(2.0 * PI * 100.0 * t) * 0.32
		var h3: float = sin(2.0 * PI * 150.0 * t) * 0.16
		var h7: float = sin(2.0 * PI * 350.0 * t) * 0.07
		var wobble: float = 1.0 + 0.04 * sin(2.0 * PI * 3.0 * t)
		var hum: float = (h1 + h2 + h3 + h7) * wobble * 0.06

		var sample_int: int = int(clampf(hum, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, sample_int)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(SAMPLE_RATE)
	stream.stereo = false
	stream.data = buffer
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = samples
	return stream


## Generates a seamless muffled city traffic rumble audio stream
func generate_city_rumble_stream() -> AudioStreamWAV:
	var duration: float = 3.0  # Frequencies are exact multiples of 1/3 Hz
	var samples: int = int(SAMPLE_RATE * duration)
	var buffer := PackedByteArray()
	buffer.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / SAMPLE_RATE
		var r1: float = sin(2.0 * PI * 54.0 * t) * 0.45
		var r2: float = sin(2.0 * PI * 78.0 * t) * 0.35
		var r3: float = sin(2.0 * PI * 114.0 * t) * 0.20
		var swell: float = 0.85 + 0.15 * sin(2.0 * PI * (1.0 / 3.0) * t)
		var rumble: float = (r1 + r2 + r3) * swell * 0.08

		var sample_int: int = int(clampf(rumble, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, sample_int)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(SAMPLE_RATE)
	stream.stereo = false
	stream.data = buffer
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = samples
	return stream

