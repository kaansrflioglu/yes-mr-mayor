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

var _bgm_player: AudioStreamPlayer = null
var _bgm_tween: Tween = null
var _current_bgm_context: String = "menu"

var _riot_siren_player: AudioStreamPlayer = null
var _heartbeat_player: AudioStreamPlayer = null
var _focus_hum_player: AudioStreamPlayer = null
var _is_inspect_mode_active: bool = false
var _riot_active: bool = false
var _heartbeat_active: bool = false


func _ready() -> void:
	_setup_audio_buses()

	for i in range(POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_audio_players.append(player)

	_init_ambience_loops()
	_init_bgm_system()
	_init_reactive_audio_players()

	if GameManager != null and GameManager.has_signal("stats_changed"):
		GameManager.stats_changed.connect(_on_game_stats_changed)


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


## Plays warm espresso coffee sip with liquid intake flutter and gentle rim release
func play_coffee_sip() -> void:
	var duration: float = 0.32
	var samples: int = int(SAMPLE_RATE * duration)
	var buffer := PackedByteArray()
	buffer.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / SAMPLE_RATE
		var progress: float = float(i) / float(samples)
		var envelope: float = sin(PI * progress) * (1.0 - progress * 0.2)
		var flutter: float = 0.7 + 0.3 * sin(2.0 * PI * 24.0 * t)
		var slurp: float = randf_range(-0.35, 0.35) * flutter * envelope

		var clink: float = 0.0
		if t >= 0.25:
			clink = sin(2.0 * PI * 2400.0 * t) * exp(-50.0 * (t - 0.25)) * 0.22

		var sample_f: float = clampf(slurp * 0.70 + clink, -1.0, 1.0)
		buffer.encode_s16(i * 2, int(sample_f * 32767.0))

	_play_raw_wav(buffer, int(SAMPLE_RATE))


## Plays crisp metallic chime of a polished brass desk reception service bell
func play_desk_bell() -> void:
	var duration: float = 0.75
	var samples: int = int(SAMPLE_RATE * duration)
	var buffer := PackedByteArray()
	buffer.resize(samples * 2)

	# Metallic brass harmonics: Fundamental (2093 Hz C7), Overtones (2793 Hz F7, 4186 Hz C8, 5587 Hz F8)
	var f0: float = 2093.0
	var f1: float = 2793.8
	var f2: float = 4186.0
	var f3: float = 5587.6

	for i in range(samples):
		var t: float = float(i) / SAMPLE_RATE
		var progress: float = float(i) / float(samples)
		var strike: float = minf(1.0, float(i) / (SAMPLE_RATE * 0.003))
		var envelope_fund: float = exp(-4.5 * progress) * strike
		var envelope_high: float = exp(-9.0 * progress) * strike

		var v0: float = sin(2.0 * PI * f0 * t) * 0.45 * envelope_fund
		var v1: float = sin(2.0 * PI * f1 * t) * 0.28 * envelope_fund
		var v2: float = sin(2.0 * PI * f2 * t) * 0.18 * envelope_high
		var v3: float = sin(2.0 * PI * f3 * t) * 0.12 * envelope_high

		# Initial metallic contact click / chime tap
		var tap: float = 0.0
		if progress < 0.02:
			tap = randf_range(-0.15, 0.15) * (1.0 - progress / 0.02)

		var chime: float = (v0 + v1 + v2 + v3 + tap) * 0.85
		var sample_f: float = clampf(chime, -1.0, 1.0)
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


## Initializes the persistent BGM player
func _init_bgm_system() -> void:
	if _bgm_player != null:
		return

	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.name = "NoirBGMPlayer"
	_bgm_player.bus = "BGM"
	_bgm_player.stream = generate_noir_bgm_stream()
	add_child(_bgm_player)
	play_bgm(1.2)


## Starts or resumes the Lo-Fi Noir background music
func play_bgm(fade_duration: float = 1.0) -> void:
	if not _bgm_player:
		return
	if not _bgm_player.playing:
		_bgm_player.volume_db = -50.0
		_bgm_player.play()
	fade_bgm_to(0.0, fade_duration)


## Fades out and pauses/stops the background music
func stop_bgm(fade_duration: float = 1.0) -> void:
	if not _bgm_player or not _bgm_player.playing:
		return
	if not is_inside_tree():
		_bgm_player.stop()
		return
	if _bgm_tween and _bgm_tween.is_valid():
		_bgm_tween.kill()
	_bgm_tween = create_tween()
	_bgm_tween.tween_property(_bgm_player, "volume_db", -50.0, fade_duration)
	_bgm_tween.tween_callback(func():
		if _bgm_player:
			_bgm_player.stop()
	)


## Smoothly fades BGM player volume_db to target_db over duration seconds
func fade_bgm_to(target_db: float, duration: float = 1.0) -> void:
	if not _bgm_player:
		return
	if not _bgm_player.playing and target_db > -45.0:
		_bgm_player.volume_db = -50.0
		_bgm_player.play()

	if not is_inside_tree():
		_bgm_player.volume_db = target_db
		return

	if _bgm_tween and _bgm_tween.is_valid():
		_bgm_tween.kill()
	_bgm_tween = create_tween()
	_bgm_tween.tween_property(_bgm_player, "volume_db", target_db, maxf(0.05, duration))


## Sets the game context for dynamic BGM volume adjustment
func set_bgm_context(context_name: String, fade_duration: float = 1.0) -> void:
	_current_bgm_context = context_name
	var target_db: float = 0.0
	match context_name:
		"menu":
			target_db = -2.0
		"desk":
			target_db = 0.0
		"summary":
			target_db = -4.0
		"pause":
			target_db = -8.0
		"game_over":
			target_db = -16.0
		_:
			target_db = 0.0

	fade_bgm_to(target_db, fade_duration)


func get_bgm_context() -> String:
	return _current_bgm_context


func is_bgm_playing() -> bool:
	return _bgm_player != null and _bgm_player.playing


func get_bgm_volume_db() -> float:
	return _bgm_player.volume_db if _bgm_player else -50.0


## Generates a seamless 14-second Lo-Fi Bureaucratic Noir jazz electric piano & muffled bass loop (~68.6 BPM)
func generate_noir_bgm_stream() -> AudioStreamWAV:
	var duration: float = 14.0
	var samples: int = int(SAMPLE_RATE * duration)
	var buffer := PackedByteArray()
	buffer.resize(samples * 2)

	# 4-bar progression (3.5s per bar in D minor / A minor noir palette)
	# Bar 0: Dm9        (Bass D2=73.42,  Chord: F3=174.61, A3=220.00, C4=261.63, E4=329.63)
	# Bar 1: Bbmaj7#11  (Bass Bb1=58.27, Chord: F3=174.61, A3=220.00, D4=293.66, E4=329.63)
	# Bar 2: Gm9        (Bass G1=48.99,  Chord: F3=174.61, Bb3=233.08, D4=293.66, A4=440.00)
	# Bar 3: A7alt      (Bass A1=55.00,  Chord: G3=196.00, Bb3=233.08, C#4=277.18, F4=349.23)
	var chord_freqs: Array[Array] = [
		[174.61, 220.00, 261.63, 329.63],
		[174.61, 220.00, 293.66, 329.63],
		[174.61, 233.08, 293.66, 440.00],
		[196.00, 233.08, 277.18, 349.23]
	]
	var bass_roots: Array[float] = [73.42, 58.27, 48.99, 55.00]
	var bass_walks: Array[float] = [55.00, 43.65, 73.42, 69.30]

	for i in range(samples):
		var t: float = float(i) / SAMPLE_RATE
		var bar_idx: int = clampi(int(t / 3.5), 0, 3)
		var t_bar: float = t - float(bar_idx) * 3.5

		# Rhodes chords: Strike 1 at t=0, Strike 2 (softer) at t=1.75
		var env1: float = exp(-0.85 * t_bar) * clampf(t_bar / 0.015, 0.0, 1.0)
		var env2: float = 0.0
		if t_bar >= 1.75:
			var t2: float = t_bar - 1.75
			env2 = exp(-1.2 * t2) * clampf(t2 / 0.015, 0.0, 1.0) * 0.52

		var current_chord: Array = chord_freqs[bar_idx]
		var chord_sum: float = 0.0

		for note_idx in range(current_chord.size()):
			var f: float = current_chord[note_idx]
			# Fundamental + subtle warm vibrato (4.2 Hz)
			var vib: float = sin(2.0 * PI * (f + 0.45 * sin(2.0 * PI * 4.2 * t)) * t)
			# Metallic bell-like tine harmonic (fast decay)
			var tine1: float = sin(2.0 * PI * f * 3.5 * t) * exp(-14.0 * t_bar) * 0.20
			var tine2: float = 0.0
			if t_bar >= 1.75:
				tine2 = sin(2.0 * PI * f * 3.5 * t) * exp(-14.0 * (t_bar - 1.75)) * 0.12

			var note_val: float = (vib * 0.70 + sin(2.0 * PI * f * t) * 0.30) * (env1 + env2) + (tine1 + tine2)
			chord_sum += note_val * 0.11

		# Muffled Bassline: Root on beat 1, walking fifth/passing note on beat 3
		var bass_f: float = bass_roots[bar_idx]
		var bass_env: float = exp(-0.75 * t_bar) * clampf(t_bar / 0.02, 0.0, 1.0)
		if t_bar >= 1.75:
			bass_f = bass_walks[bar_idx]
			bass_env = exp(-0.95 * (t_bar - 1.75)) * clampf((t_bar - 1.75) / 0.02, 0.0, 1.0) * 0.85

		var bass_tone: float = (sin(2.0 * PI * bass_f * t) * 0.75 + sin(2.0 * PI * bass_f * 2.0 * t) * 0.25) * bass_env * 0.24

		# Subtle vinyl crackle / surface warmth
		var vinyl_hum: float = sin(2.0 * PI * 43.0 * t) * 0.003 + sin(2.0 * PI * 227.0 * t) * 0.002
		var pop_phase: float = fmod(t + float(bar_idx) * 0.37, 0.875)
		var vinyl_pop: float = sin(2.0 * PI * 740.0 * t) * exp(-120.0 * pop_phase) * 0.012

		var total_signal: float = chord_sum + bass_tone + vinyl_hum + vinyl_pop

		# Smooth seam crossfade for the last 0.03 seconds
		if t >= 13.97:
			var fade: float = (14.0 - t) / 0.03
			total_signal *= fade

		var sample_int: int = int(clampf(total_signal, -1.0, 1.0) * 32767.0)
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


## Initializes reactive audio players for riots, high suspicion heartbeat, and inspect focus hum
func _init_reactive_audio_players() -> void:
	# Riot sirens & crowd chanting for low approval (<25%)
	_riot_siren_player = AudioStreamPlayer.new()
	_riot_siren_player.name = "RiotSirenLoop"
	_riot_siren_player.bus = "CityExterior"
	_riot_siren_player.stream = generate_riot_siren_stream()
	_riot_siren_player.volume_db = -60.0
	add_child(_riot_siren_player)

	# High suspicion heartbeat thud (>75%)
	_heartbeat_player = AudioStreamPlayer.new()
	_heartbeat_player.name = "HeartbeatLoop"
	_heartbeat_player.bus = "DeskAmbience"
	_heartbeat_player.stream = generate_heartbeat_stream()
	_heartbeat_player.volume_db = -60.0
	add_child(_heartbeat_player)

	# High-pass focus hum when inspect mode is active
	_focus_hum_player = AudioStreamPlayer.new()
	_focus_hum_player.name = "FocusHumLoop"
	_focus_hum_player.bus = "DeskAmbience"
	_focus_hum_player.stream = generate_focus_hum_stream()
	_focus_hum_player.volume_db = -60.0
	add_child(_focus_hum_player)


func _on_game_stats_changed() -> void:
	if GameManager == null:
		return
	update_dynamic_audio_reactivity(GameManager.public_opinion, GameManager.suspicion_level, 0.8)


var _bgm_cutoff_tween: Tween = null


## Dynamically adjusts audio DSP modulation and ambient streams based on game state
func update_dynamic_audio_reactivity(opinion: float, suspicion: float, duration: float = 0.0) -> void:
	# 1. Public Opinion < 25%: Exterior riot crowd chanting & sirens
	if opinion < 25.0:
		_riot_active = true
		if _riot_siren_player:
			if not _riot_siren_player.playing:
				_riot_siren_player.volume_db = -60.0
				_riot_siren_player.play()
			if is_inside_tree() and duration > 0.05:
				var tween := create_tween()
				tween.tween_property(_riot_siren_player, "volume_db", -4.0, 1.2)
			else:
				_riot_siren_player.volume_db = -4.0
	else:
		_riot_active = false
		if _riot_siren_player and _riot_siren_player.playing:
			if is_inside_tree() and duration > 0.05:
				var tween := create_tween()
				tween.tween_property(_riot_siren_player, "volume_db", -60.0, 1.5)
				tween.tween_callback(func():
					if _riot_siren_player and not _riot_active:
						_riot_siren_player.stop()
				)
			else:
				_riot_siren_player.stop()

	# 2. Federal Suspicion: BGM Low-Pass cutoff modulation (20kHz down to 2.5kHz on high suspicion)
	if suspicion > 50.0:
		var progress: float = clampf((suspicion - 50.0) / 50.0, 0.0, 1.0)
		var target_cutoff: float = lerpf(20000.0, 2500.0, progress)
		set_bgm_lowpass_cutoff(target_cutoff, duration)
	else:
		set_bgm_lowpass_cutoff(20000.0, duration)

	# 3. Federal Suspicion > 75%: Anxious heartbeat thud
	if suspicion > 75.0:
		_heartbeat_active = true
		if _heartbeat_player:
			if not _heartbeat_player.playing:
				_heartbeat_player.volume_db = -60.0
				_heartbeat_player.play()
			if is_inside_tree() and duration > 0.05:
				var tween := create_tween()
				tween.tween_property(_heartbeat_player, "volume_db", -6.0, 1.0)
			else:
				_heartbeat_player.volume_db = -6.0
	else:
		_heartbeat_active = false
		if _heartbeat_player and _heartbeat_player.playing:
			if is_inside_tree() and duration > 0.05:
				var tween := create_tween()
				tween.tween_property(_heartbeat_player, "volume_db", -60.0, 1.0)
				tween.tween_callback(func():
					if _heartbeat_player and not _heartbeat_active:
						_heartbeat_player.stop()
				)
			else:
				_heartbeat_player.stop()


## Smoothly modulates BGM low-pass filter cutoff frequency
func set_bgm_lowpass_cutoff(target_cutoff_hz: float, duration: float = 0.8) -> void:
	var bgm_idx := AudioServer.get_bus_index("BGM")
	if bgm_idx == -1:
		return
	var lpf: AudioEffectLowPassFilter = null
	for i in range(AudioServer.get_bus_effect_count(bgm_idx)):
		var eff := AudioServer.get_bus_effect(bgm_idx, i)
		if eff is AudioEffectLowPassFilter:
			lpf = eff as AudioEffectLowPassFilter
			break
	if lpf:
		var clamped_cutoff: float = clampf(target_cutoff_hz, 500.0, 20500.0)
		if _bgm_cutoff_tween and _bgm_cutoff_tween.is_valid():
			_bgm_cutoff_tween.kill()
		if is_inside_tree() and duration > 0.05:
			_bgm_cutoff_tween = create_tween()
			_bgm_cutoff_tween.tween_property(lpf, "cutoff_hz", clamped_cutoff, duration)
		else:
			lpf.cutoff_hz = clamped_cutoff


## Returns current BGM low-pass cutoff frequency
func get_bgm_lowpass_cutoff() -> float:
	var bgm_idx := AudioServer.get_bus_index("BGM")
	if bgm_idx == -1:
		return 20000.0
	for i in range(AudioServer.get_bus_effect_count(bgm_idx)):
		var eff := AudioServer.get_bus_effect(bgm_idx, i)
		if eff is AudioEffectLowPassFilter:
			return (eff as AudioEffectLowPassFilter).cutoff_hz
	return 20000.0


## Activates or deactivates inspection mode audio profile (exterior ducking & focus hum)
func set_inspection_mode_active(active: bool) -> void:
	_is_inspect_mode_active = active
	var city_idx := AudioServer.get_bus_index("CityExterior")
	if city_idx != -1:
		# Duck exterior sounds by -6 dB during inspection
		var target_vol: float = -10.0 if active else -4.0
		AudioServer.set_bus_volume_db(city_idx, target_vol)

	if _focus_hum_player:
		if active:
			if not _focus_hum_player.playing:
				_focus_hum_player.volume_db = -50.0
				_focus_hum_player.play()
			if is_inside_tree():
				var tween := create_tween()
				tween.tween_property(_focus_hum_player, "volume_db", -14.0, 0.4)
			else:
				_focus_hum_player.volume_db = -14.0
		else:
			if _focus_hum_player.playing:
				if is_inside_tree():
					var tween := create_tween()
					tween.tween_property(_focus_hum_player, "volume_db", -50.0, 0.3)
					tween.tween_callback(func():
						if _focus_hum_player and not _is_inspect_mode_active:
							_focus_hum_player.stop()
					)
				else:
					_focus_hum_player.stop()


func is_riot_siren_active() -> bool:
	return _riot_active


func is_heartbeat_active() -> bool:
	return _heartbeat_active


func is_inspection_audio_active() -> bool:
	return _is_inspect_mode_active


## Generates a seamless 4-second exterior riot siren & distant chanting audio stream
func generate_riot_siren_stream() -> AudioStreamWAV:
	var duration: float = 4.0
	var samples: int = int(SAMPLE_RATE * duration)
	var buffer := PackedByteArray()
	buffer.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / SAMPLE_RATE
		# Smooth two-cycle siren pitch glide with continuous phase integration
		var phase: float = 2.0 * PI * 850.0 * t - (260.0 / 0.5) * cos(2.0 * PI * 0.5 * t)
		var siren_tone: float = sin(phase) * 0.40

		# Distant crowd murmur & megaphone chanting
		var crowd_rumble: float = (
			sin(2.0 * PI * 110.0 * t) * 0.5 + sin(2.0 * PI * 165.0 * t) * 0.5
		) * (0.6 + 0.4 * sin(2.0 * PI * 1.5 * t)) * 0.35
		var crowd_noise: float = randf_range(-0.15, 0.15) * (0.5 + 0.5 * sin(2.0 * PI * 1.5 * t)) * 0.25

		var total: float = (siren_tone + crowd_rumble + crowd_noise) * 0.15
		buffer.encode_s16(i * 2, int(clampf(total, -1.0, 1.0) * 32767.0))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(SAMPLE_RATE)
	stream.stereo = false
	stream.data = buffer
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = samples
	return stream


## Generates a seamless 0.8-second rapid heartbeat thud stream (75 BPM)
func generate_heartbeat_stream() -> AudioStreamWAV:
	var duration: float = 0.8
	var samples: int = int(SAMPLE_RATE * duration)
	var buffer := PackedByteArray()
	buffer.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / SAMPLE_RATE
		var sample_f: float = 0.0

		# Beat 1: "Lub" at t = 0.0s
		if t < 0.20:
			var thud1: float = sin(2.0 * PI * 65.0 * t) * exp(-28.0 * t) * 0.55
			var sub1: float = sin(2.0 * PI * 42.0 * t) * exp(-18.0 * t) * 0.45
			sample_f = thud1 + sub1
		# Beat 2: "Dub" at t = 0.22s
		elif t >= 0.22 and t < 0.42:
			var t2: float = t - 0.22
			var thud2: float = sin(2.0 * PI * 80.0 * t2) * exp(-30.0 * t2) * 0.45
			var sub2: float = sin(2.0 * PI * 50.0 * t2) * exp(-20.0 * t2) * 0.35
			sample_f = thud2 + sub2

		buffer.encode_s16(i * 2, int(clampf(sample_f * 0.38, -1.0, 1.0) * 32767.0))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(SAMPLE_RATE)
	stream.stereo = false
	stream.data = buffer
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = samples
	return stream


## Generates a seamless 1.0-second crystalline high-pass focus hum stream
func generate_focus_hum_stream() -> AudioStreamWAV:
	var duration: float = 1.0
	var samples: int = int(SAMPLE_RATE * duration)
	var buffer := PackedByteArray()
	buffer.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / SAMPLE_RATE
		var f1: float = sin(2.0 * PI * 520.0 * t) * 0.55
		var f2: float = sin(2.0 * PI * 1040.0 * t) * 0.30
		var f3: float = sin(2.0 * PI * 2080.0 * t) * 0.15
		var swell: float = 0.90 + 0.10 * sin(2.0 * PI * 2.0 * t)
		var hum: float = (f1 + f2 + f3) * swell * 0.04

		buffer.encode_s16(i * 2, int(clampf(hum, -1.0, 1.0) * 32767.0))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(SAMPLE_RATE)
	stream.stereo = false
	stream.data = buffer
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = samples
	return stream


## Plays delicate ceramic coffee mug clink with bell harmonic resonance
func play_coffee_clink() -> void:
	var duration: float = 0.24
	var samples: int = int(SAMPLE_RATE * duration)
	var buffer := PackedByteArray()
	buffer.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / SAMPLE_RATE
		var ping1: float = sin(2.0 * PI * 2750.0 * t) * exp(-24.0 * t) * 0.45
		var ping2: float = sin(2.0 * PI * 3820.0 * t) * exp(-28.0 * t) * 0.35
		var body: float = sin(2.0 * PI * 420.0 * t) * exp(-50.0 * t) * 0.25
		var snap: float = randf_range(-0.15, 0.15) * exp(-120.0 * t)

		var sample_f: float = clampf((ping1 + ping2 + body + snap) * 0.65, -1.0, 1.0)
		buffer.encode_s16(i * 2, int(sample_f * 32767.0))

	_play_raw_wav(buffer, int(SAMPLE_RATE))


## Plays heavy steel drawer slide friction and mechanical latch/tumbler click
func play_safe_drawer_slide(opening: bool = true) -> void:
	var duration: float = 0.38
	var samples: int = int(SAMPLE_RATE * duration)
	var buffer := PackedByteArray()
	buffer.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / SAMPLE_RATE
		var progress: float = float(i) / float(samples)
		var envelope: float = sin(PI * progress)

		# Bearing slide roller friction
		var slide_noise: float = randf_range(-0.30, 0.30) * envelope * 0.50
		var rumble: float = sin(2.0 * PI * 135.0 * t) * (0.6 + 0.4 * sin(2.0 * PI * 32.0 * t)) * envelope * 0.35

		# Tumbler snap click (at start for opening, at end for closing)
		var latch: float = 0.0
		if opening and t < 0.08:
			latch = sin(2.0 * PI * 1250.0 * t) * exp(-60.0 * t) * 0.55
		elif not opening and t >= 0.30:
			var t_latch: float = t - 0.30
			latch = sin(2.0 * PI * 110.0 * t) * exp(-28.0 * t_latch) * 0.65

		var sample_f: float = clampf(slide_noise + rumble + latch, -1.0, 1.0)
		buffer.encode_s16(i * 2, int(sample_f * 32767.0))

	_play_raw_wav(buffer, int(SAMPLE_RATE))


## Plays heavy telephone handset receiver slam into cradle with spring bell chatter
func play_phone_receiver_slam() -> void:
	var duration: float = 0.30
	var samples: int = int(SAMPLE_RATE * duration)
	var buffer := PackedByteArray()
	buffer.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / SAMPLE_RATE
		# Impact 1 at t=0
		var thud1: float = sin(2.0 * PI * 135.0 * t) * exp(-35.0 * t) * 0.65
		var crack1: float = randf_range(-0.35, 0.35) * exp(-80.0 * t)

		# Rebound impact at t=0.04s
		var thud2: float = 0.0
		if t >= 0.04:
			thud2 = sin(2.0 * PI * 220.0 * t) * exp(-45.0 * (t - 0.04)) * 0.35

		# Resonant bell chatter from the violent impact
		var bell: float = (
			sin(2.0 * PI * 850.0 * t) * 0.6 + sin(2.0 * PI * 1120.0 * t) * 0.4
		) * exp(-22.0 * t) * 0.30

		var sample_f: float = clampf((thud1 + crack1 + thud2 + bell) * 0.70, -1.0, 1.0)
		buffer.encode_s16(i * 2, int(sample_f * 32767.0))

	_play_raw_wav(buffer, int(SAMPLE_RATE))


## Convenient alias for play_phone_receiver_slam
func play_phone_hangup() -> void:
	play_phone_receiver_slam()


## Plays motor grinding, paper tearing, and confetti ribbon dispersal sound for Desk Shredder
func play_paper_shred() -> void:
	var duration: float = 0.55
	var samples: int = int(SAMPLE_RATE * duration)
	var buffer := PackedByteArray()
	buffer.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / SAMPLE_RATE
		var progress: float = float(i) / float(samples)
		var envelope: float = sin(PI * progress)

		# Motor hum (110 Hz square/saw oscillation)
		var motor: float = (sin(2.0 * PI * 110.0 * t) + 0.4 * sin(2.0 * PI * 220.0 * t)) * 0.35

		# Blade teeth chew (fluttering high-frequency grinding)
		var flutter: float = 0.5 + 0.5 * sin(2.0 * PI * 38.0 * t)
		var blade_noise: float = randf_range(-0.45, 0.45) * flutter

		# Paper shredding crinkle
		var paper_slice: float = randf_range(-0.3, 0.3) * (1.0 if sin(2.0 * PI * 80.0 * t) > 0.0 else 0.2)

		var combined: float = (motor + blade_noise + paper_slice) * envelope
		var sample_f: float = clampf(combined * 0.75, -1.0, 1.0)
		buffer.encode_s16(i * 2, int(sample_f * 32767.0))

	_play_raw_wav(buffer, int(SAMPLE_RATE))


## Plays squishy felt and suction release sound when stamp handle is dipped in ink
func play_ink_pad_dip() -> void:
	var duration: float = 0.22
	var samples: int = int(SAMPLE_RATE * duration)
	var buffer := PackedByteArray()
	buffer.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / SAMPLE_RATE
		var progress: float = float(i) / float(samples)
		var envelope: float = sin(PI * progress)
		var squish: float = sin(2.0 * PI * (140.0 - 50.0 * progress) * t) * 0.4
		var wet_noise: float = randf_range(-0.3, 0.3) * exp(-15.0 * progress)
		var sample_f: float = clampf((squish + wet_noise) * envelope * 0.65, -1.0, 1.0)
		buffer.encode_s16(i * 2, int(sample_f * 32767.0))

	_play_raw_wav(buffer, int(SAMPLE_RATE))





