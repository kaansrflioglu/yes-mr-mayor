extends Node

## AudioManager.gd - Central sound effects & atmospheric audio manager.
## Provides procedural audio synthesis and playback for tactile physical feedback.

const SAMPLE_RATE: float = 22050.0

var _audio_players: Array[AudioStreamPlayer] = []
const POOL_SIZE: int = 8


func _ready() -> void:
	var sfx_idx := AudioServer.get_bus_index("SFX")
	if sfx_idx == -1:
		AudioServer.add_bus()
		sfx_idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(sfx_idx, "SFX")
		AudioServer.set_bus_send(sfx_idx, "Master")

	for i in range(POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_audio_players.append(player)


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


## Plays mechanical office clock tick
func play_clock_tick() -> void:
	var duration: float = 0.06
	var samples: int = int(SAMPLE_RATE * duration)
	var buffer := PackedByteArray()
	buffer.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / SAMPLE_RATE
		var progress: float = float(i) / float(samples)
		var envelope: float = exp(-45.0 * progress)
		var click: float = sin(2.0 * PI * 1850.0 * t) * envelope
		var sample_f: float = clampf(click * 0.45, -1.0, 1.0)
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

