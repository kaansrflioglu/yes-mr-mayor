extends Control

## SkylineView.gd - Dynamic panoramic city window behind the mayor's desk.
## Features 4 CanvasGroup layers, reactive CPU particles, dynamic lighting,
## looping emergency flashers, elevated monorail transit, and day/night rush hour transitions.

# -----------------------------------------------------------------------------
# 1. CanvasGroup Layers (Layer Matrix)
# -----------------------------------------------------------------------------
@onready var layer_sky: CanvasGroup = %LayerSky
@onready var layer_distant: CanvasGroup = %LayerDistant
@onready var layer_midground: CanvasGroup = %LayerMidground
@onready var layer_foreground: CanvasGroup = %LayerForeground

# -----------------------------------------------------------------------------
# 2. Sky Dome & Atmosphere Nodes
# -----------------------------------------------------------------------------
@onready var sky_rect: ColorRect = %SkyRect
@onready var sun_glow: Panel = %SunGlow
@onready var smog_overlay: ColorRect = %SmogOverlay
@onready var rain_particles: CPUParticles2D = %RainParticles
@onready var rain_overlay: ColorRect = %RainOverlay if has_node("%RainOverlay") else null
@onready var clock_hour_hand: Sprite2D = %ClockHourHand if has_node("%ClockHourHand") else null
@onready var clock_minute_hand: Sprite2D = %ClockMinuteHand if has_node("%ClockMinuteHand") else null

# -----------------------------------------------------------------------------
# 3. Distant Layer Props & Particles
# -----------------------------------------------------------------------------
@onready var prop_concrete_towers: Control = %PropConcreteTowers
@onready var prop_luxury_towers: Control = %PropLuxuryTowers
@onready var prop_historic_clock_tower: Control = %PropHistoricClockTower
@onready var prop_historic_rubble: Control = %PropHistoricRubble
@onready var prop_toxic_chimneys: Control = %PropToxicChimneys
@onready var chimney_smoke_particles: CPUParticles2D = %ChimneySmokeParticles

# -----------------------------------------------------------------------------
# 4. Midground Layer Props, Lighting & Monorail
# -----------------------------------------------------------------------------
@onready var prop_green_park: Control = %PropGreenPark
@onready var prop_golden_dinosaur: Control = %PropGoldenDinosaur
@onready var prop_metro_pit: Control = %PropMetroPit
@onready var prop_clean_metro: Control = %PropCleanMetro
@onready var prop_monorail: Control = %PropMonorail
@onready var monorail_train: Control = %MonorailTrain
@onready var prop_neon_casino: Control = %PropNeonCasino
@onready var casino_sign: Label = %CasinoSign
@onready var prop_titanium_mayor: Control = %PropTitaniumMayor
@onready var prop_flood_catastrophe: Control = %PropFloodCatastrophe

# -----------------------------------------------------------------------------
# 5. Foreground Layer Props, Civil Unrest & Police Siege
# -----------------------------------------------------------------------------
@onready var prop_garbage_piles: Control = %PropGarbagePiles
@onready var prop_protest_mobs: Control = %PropProtestMobs
@onready var torch_fire_particles: CPUParticles2D = %TorchFireParticles
@onready var prop_police_siege: Control = %PropPoliceSiege
@onready var red_light: Node = %RedLight
@onready var blue_light: Node = %BlueLight
@onready var red_light_2: Node = %RedLight2
@onready var blue_light_2: Node = %BlueLight2

# -----------------------------------------------------------------------------
# 6. Monorail Movement Constants
# -----------------------------------------------------------------------------
const MONORAIL_START_X: float = 760.0
const MONORAIL_END_X: float = 1440.0
const MONORAIL_DURATION: float = 5.0
const MONORAIL_INTERVAL: float = 25.0

# -----------------------------------------------------------------------------
# 7. Day / Night & Daily Queue Progress
# -----------------------------------------------------------------------------
var daily_time_progress: float = 0.0:
	set(val):
		daily_time_progress = clampf(val, 0.0, 1.0)

var _daily_total_events: int = 4

# -----------------------------------------------------------------------------
# 8. Active Tweens
# -----------------------------------------------------------------------------
var _police_lights_tween: Tween = null
var _neon_tween: Tween = null
var _monorail_tween: Tween = null
var _sky_tween: Tween = null


func _ready() -> void:
	if GameManager:
		GameManager.stats_changed.connect(update_skyline)
		if GameManager.has_signal("stats_updated"):
			GameManager.stats_updated.connect(update_skyline)
		if GameManager.has_signal("event_presented"):
			GameManager.event_presented.connect(_on_event_presented)
		if GameManager.has_signal("day_started"):
			GameManager.day_started.connect(_on_day_started)
		if GameManager.has_signal("day_ended"):
			GameManager.day_ended.connect(_on_day_ended)
	if EventManager:
		if EventManager.has_signal("daily_queue_prepared"):
			EventManager.daily_queue_prepared.connect(_on_daily_queue_prepared)
	update_skyline()


func _exit_tree() -> void:
	_stop_police_lights()
	_stop_neon_casino()
	_stop_monorail()
	if _sky_tween and _sky_tween.is_valid():
		_sky_tween.kill()


## Updates window view dynamically based on event flags, public opinion, suspicion, and time of day
func update_skyline() -> void:
	var flags: Dictionary = GameManager.event_flags if GameManager != null else {}

	# 1. Dynamic Metric Thresholds
	var low_opinion: bool = (GameManager != null and GameManager.public_opinion < 25.0)
	var high_opinion: bool = (GameManager != null and GameManager.public_opinion >= 75.0)
	var high_suspicion: bool = (GameManager != null and GameManager.suspicion_meter >= 80.0)

	var has_smog: bool = flags.get("toxic_smog", false) or flags.get("add_concrete_tower", false)
	var is_flooded: bool = flags.get("flood_catastrophe", false)
	var is_sunset_flag: bool = flags.get("weather_sunset", false)
	var is_night_flag: bool = flags.get("weather_night", false)

	# 2. Dynamic Sky Color & Atmosphere Palette based on Time & Events
	var target_sky_color: Color
	var target_smog_alpha: float = 0.0
	var target_sun_y: float = 40.0

	# Calculate base diurnal progression (Morning -> Midday -> Evening Rush Hour -> Dusk)
	if daily_time_progress < 0.4:
		# Morning to Midday
		var factor: float = daily_time_progress / 0.4
		target_sky_color = Color(0.38, 0.65, 0.88, 1.0).lerp(Color(0.40, 0.68, 0.92, 1.0), factor)
		target_sun_y = lerpf(40.0, 48.0, factor)
	elif daily_time_progress < 0.8:
		# Midday to Evening Rush Hour (Golden Hour Amber)
		var factor: float = (daily_time_progress - 0.4) / 0.4
		target_sky_color = Color(0.40, 0.68, 0.92, 1.0).lerp(Color(0.85, 0.52, 0.32, 1.0), factor)
		target_sun_y = lerpf(48.0, 95.0, factor)
	else:
		# Evening Rush Hour to Dusk Twilight
		var factor: float = (daily_time_progress - 0.8) / 0.2
		target_sky_color = Color(0.85, 0.52, 0.32, 1.0).lerp(Color(0.24, 0.20, 0.32, 1.0), factor)
		target_sun_y = lerpf(95.0, 135.0, factor)

	# Crisis & Environmental Overrides
	if has_smog:
		target_sky_color = Color(0.52, 0.55, 0.38, 1.0) # Industrial ochre smog
		target_smog_alpha = 0.55
	elif is_flooded:
		target_sky_color = Color(0.30, 0.36, 0.42, 1.0) # Torrential storm slate
		target_smog_alpha = 0.35
	elif is_night_flag:
		target_sky_color = Color(0.12, 0.14, 0.22, 1.0) # Night noir
		target_smog_alpha = 0.15
		target_sun_y = 160.0
	elif is_sunset_flag:
		target_sky_color = Color(0.85, 0.52, 0.32, 1.0) # Forced sunset amber
		target_smog_alpha = 0.10
		target_sun_y = 100.0
	elif high_suspicion:
		target_sky_color = Color(0.36, 0.28, 0.38, 1.0) # Tense twilight purple
		target_smog_alpha = 0.20
	elif low_opinion:
		target_sky_color = Color(0.42, 0.44, 0.52, 1.0) # Overcast gloomy unrest
		target_smog_alpha = 0.25
	elif high_opinion and daily_time_progress < 0.6:
		target_sky_color = Color(0.42, 0.70, 0.95, 1.0) # Radiant golden-era blue
		target_smog_alpha = 0.0

	# Smooth atmosphere transitions
	if sky_rect and is_inside_tree():
		if _sky_tween and _sky_tween.is_valid():
			_sky_tween.kill()
		_sky_tween = create_tween().set_parallel(true)
		_sky_tween.tween_property(sky_rect, "color", target_sky_color, 0.6)
		if smog_overlay:
			_sky_tween.tween_property(smog_overlay, "color:a", target_smog_alpha, 0.6)
		if sun_glow:
			_sky_tween.tween_property(sun_glow, "position:y", target_sun_y, 0.8)

		if sky_rect.material is ShaderMaterial:
			var sm := sky_rect.material as ShaderMaterial
			var pol: float = 0.6 if has_smog else (0.3 if flags.get("add_concrete_tower", false) else 0.0)
			sm.set_shader_parameter("pollution_amount", pol)
			sm.set_shader_parameter("zenith_color", target_sky_color.darkened(0.25))
			sm.set_shader_parameter("horizon_color", target_sky_color.lightened(0.15))

	# 3. Distant Layer Prop States
	_set_prop_state(prop_concrete_towers, flags.get("add_concrete_tower", false))
	_set_prop_state(prop_luxury_towers, flags.get("add_luxury_towers", false))
	_set_prop_state(
		prop_historic_clock_tower,
		flags.get("historic_clock_tower", true) and not flags.get("historic_rubble", false)
	)
	_set_prop_state(prop_historic_rubble, flags.get("historic_rubble", false))
	_set_prop_state(prop_toxic_chimneys, flags.get("toxic_smog", false))

	# 4. Midground Layer Prop States
	_set_prop_state(
		prop_green_park,
		flags.get("preserve_greenery", false) or flags.get("community_park", false)
	)
	_set_prop_state(prop_golden_dinosaur, flags.get("add_golden_dinosaur", false))
	_set_prop_state(prop_metro_pit, flags.get("abandoned_metro_pit", false))
	_set_prop_state(prop_clean_metro, flags.get("clean_metro_station", false))

	# Monorail Elevated Transit
	var monorail_active: bool = flags.get("moving_monorail", false)
	_set_prop_state(prop_monorail, monorail_active)
	if monorail_active:
		_animate_monorail()
	else:
		_stop_monorail()

	# Neon Casino
	var casino_active: bool = flags.get("neon_casino_strip", false)
	_set_prop_state(prop_neon_casino, casino_active)
	if casino_active:
		_animate_neon_casino()
	else:
		_stop_neon_casino()

	_set_prop_state(prop_titanium_mayor, flags.get("titanium_mayor_statue", false))
	_set_prop_state(prop_flood_catastrophe, is_flooded)

	# 5. Foreground Layer Prop States (Civil Unrest & Police Siege)
	var protest_active: bool = flags.get("riot_crowds", false) or low_opinion
	var police_active: bool = flags.get("police_siege", false) or high_suspicion

	_set_prop_state(prop_garbage_piles, flags.get("garbage_piles", false))
	_set_prop_state(prop_protest_mobs, protest_active)
	_set_prop_state(prop_police_siege, police_active)

	# 6. Police Emergency Light Flashers
	if police_active:
		_animate_police_lights()
	else:
		_stop_police_lights()

	# 7. Particle Systems State Updates
	_update_particles(flags, protest_active, is_flooded)


## Updates 2D particle emitter states based on environmental conditions
func _update_particles(flags: Dictionary, protest_active: bool, is_flooded: bool) -> void:
	var should_rain: bool = is_flooded or flags.get("weather_rain", false)
	if rain_particles:
		rain_particles.emitting = should_rain

	if rain_overlay and rain_overlay.material is ShaderMaterial:
		var rm := rain_overlay.material as ShaderMaterial
		rm.set_shader_parameter("rain_intensity", 0.75 if should_rain else 0.0)

	if chimney_smoke_particles:
		var should_smoke: bool = flags.get("toxic_smog", false)
		chimney_smoke_particles.emitting = should_smoke

	if torch_fire_particles:
		torch_fire_particles.emitting = protest_active


## Synchronizes municipal clock hands with desk shift minutes
func update_clock_visual(minutes_since_midnight: int) -> void:
	var hours: float = float(minutes_since_midnight) / 60.0
	var mins: float = float(minutes_since_midnight % 60)
	if clock_hour_hand:
		clock_hour_hand.rotation = deg_to_rad(hours * 30.0)
	if clock_minute_hand:
		clock_minute_hand.rotation = deg_to_rad(mins * 6.0)


func _set_prop_state(prop: Control, is_active: bool) -> void:
	if prop == null:
		return
	if is_active and not prop.visible:
		prop.visible = true
		prop.scale = Vector2(0.8, 0.8)
		prop.modulate.a = 0.0
		if is_inside_tree():
			var tween := create_tween().set_parallel(true)
			tween.tween_property(prop, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK)
			tween.tween_property(prop, "modulate:a", 1.0, 0.3)
		else:
			prop.scale = Vector2.ONE
			prop.modulate.a = 1.0
	elif not is_active:
		prop.visible = false


# -----------------------------------------------------------------------------
# Monorail Looping Tween & Transit Movement (Phase 3)
# -----------------------------------------------------------------------------

## Starts the 25-second periodic monorail train crossing the bridge
func _animate_monorail() -> void:
	if _monorail_tween and _monorail_tween.is_valid():
		return
	if monorail_train == null or not is_inside_tree():
		return

	_monorail_tween = create_tween().set_loops()
	monorail_train.position.x = MONORAIL_START_X
	monorail_train.modulate.a = 0.0

	# 1. Fade in gliding onto bridge
	_monorail_tween.tween_property(monorail_train, "modulate:a", 1.0, 0.3)
	# 2. Smooth horizontal transit across the rail bridge
	_monorail_tween.parallel().tween_property(
		monorail_train, "position:x", MONORAIL_END_X, MONORAIL_DURATION
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# 3. Fade out exiting the bridge
	_monorail_tween.tween_property(monorail_train, "modulate:a", 0.0, 0.3)
	# 4. Reset position to bridge entrance
	_monorail_tween.tween_callback(func():
		if monorail_train:
			monorail_train.position.x = MONORAIL_START_X
	)
	# 5. Rest interval before next train pass (every 25 seconds)
	var rest_time: float = maxf(1.0, MONORAIL_INTERVAL - MONORAIL_DURATION)
	_monorail_tween.tween_interval(rest_time)


## Stops monorail loop and resets train
func _stop_monorail() -> void:
	if _monorail_tween and _monorail_tween.is_valid():
		_monorail_tween.kill()
		_monorail_tween = null
	if monorail_train:
		monorail_train.position.x = MONORAIL_START_X
		monorail_train.modulate.a = 0.0


## Manually triggers an immediate monorail pass across the bridge
func trigger_monorail_pass(duration: float = MONORAIL_DURATION) -> void:
	if monorail_train == null or not is_inside_tree():
		return
	if _monorail_tween and _monorail_tween.is_valid():
		_monorail_tween.kill()
		_monorail_tween = null

	monorail_train.position.x = MONORAIL_START_X
	monorail_train.modulate.a = 0.0

	var pass_tween := create_tween()
	pass_tween.tween_property(monorail_train, "modulate:a", 1.0, 0.3)
	pass_tween.parallel().tween_property(
		monorail_train, "position:x", MONORAIL_END_X, duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pass_tween.tween_property(monorail_train, "modulate:a", 0.0, 0.3)
	pass_tween.tween_callback(func():
		if monorail_train:
			monorail_train.position.x = MONORAIL_START_X
		if GameManager and GameManager.event_flags.get("moving_monorail", false):
			_animate_monorail()
	)


# -----------------------------------------------------------------------------
# Dynamic Lighting & Tweened Animations (Phase 2)
# -----------------------------------------------------------------------------

## Starts alternating emergency flashers across squad cars
func _animate_police_lights() -> void:
	if _police_lights_tween and _police_lights_tween.is_valid():
		return
	if red_light == null or blue_light == null:
		return

	_police_lights_tween = create_tween().set_loops()

	# Strobe Step 1: Red lights on, Blue lights off
	_police_lights_tween.tween_property(red_light, "energy", 1.8, 0.2)
	if red_light_2:
		_police_lights_tween.parallel().tween_property(red_light_2, "energy", 0.0, 0.2)
	_police_lights_tween.parallel().tween_property(blue_light, "energy", 0.0, 0.2)
	if blue_light_2:
		_police_lights_tween.parallel().tween_property(blue_light_2, "energy", 1.8, 0.2)

	# Strobe Step 2: Red lights dim
	_police_lights_tween.tween_property(red_light, "energy", 0.0, 0.2)
	if blue_light_2:
		_police_lights_tween.parallel().tween_property(blue_light_2, "energy", 0.0, 0.2)

	# Strobe Step 3: Blue lights on, Red lights off
	_police_lights_tween.tween_property(blue_light, "energy", 1.8, 0.2)
	if red_light_2:
		_police_lights_tween.parallel().tween_property(red_light_2, "energy", 1.8, 0.2)

	# Strobe Step 4: Blue lights dim
	_police_lights_tween.tween_property(blue_light, "energy", 0.0, 0.2)
	if red_light_2:
		_police_lights_tween.parallel().tween_property(red_light_2, "energy", 0.0, 0.2)


## Stops emergency flashers and rests indicators
func _stop_police_lights() -> void:
	if _police_lights_tween and _police_lights_tween.is_valid():
		_police_lights_tween.kill()
		_police_lights_tween = null

	if red_light and "energy" in red_light:
		red_light.energy = 0.0
	if blue_light and "energy" in blue_light:
		blue_light.energy = 0.0
	if red_light_2 and "energy" in red_light_2:
		red_light_2.energy = 0.0
	if blue_light_2 and "energy" in blue_light_2:
		blue_light_2.energy = 0.0


## Pulsing neon sign glow for the underground casino strip
func _animate_neon_casino() -> void:
	if _neon_tween and _neon_tween.is_valid():
		return
	if casino_sign == null or not is_inside_tree():
		return

	_neon_tween = create_tween().set_loops()
	_neon_tween.tween_property(casino_sign, "modulate", Color(1.4, 0.5, 1.3, 1.0), 0.4)
	_neon_tween.tween_property(casino_sign, "modulate", Color(0.4, 1.2, 1.4, 1.0), 0.4)
	_neon_tween.tween_property(casino_sign, "modulate", Color(1.0, 0.3, 0.7, 0.6), 0.2)
	_neon_tween.tween_property(casino_sign, "modulate", Color(1.4, 0.5, 1.3, 1.0), 0.2)


func _stop_neon_casino() -> void:
	if _neon_tween and _neon_tween.is_valid():
		_neon_tween.kill()
		_neon_tween = null
	if casino_sign:
		casino_sign.modulate = Color.WHITE


# -----------------------------------------------------------------------------
# Signal Callbacks: Daily Queue & Event Progression (Phase 3)
# -----------------------------------------------------------------------------
func _on_event_presented(_event: EventData) -> void:
	if EventManager != null and not EventManager.daily_queue.is_empty():
		var remaining: int = EventManager.daily_queue.size()
		var completed: int = maxi(0, _daily_total_events - remaining - 1)
		daily_time_progress = clampf(float(completed) / float(maxi(1, _daily_total_events - 1)), 0.0, 1.0)
	elif EventManager != null and EventManager.daily_queue.is_empty():
		# Final event of the quota -> Rush hour peak
		daily_time_progress = 0.9
	update_skyline()


func _on_daily_queue_prepared(_day: int, event_count: int) -> void:
	_daily_total_events = maxi(1, event_count)
	daily_time_progress = 0.0
	update_skyline()


func _on_day_started(_day: int) -> void:
	play_morning_sunrise_transition()


func _on_day_ended(_day: int) -> void:
	daily_time_progress = 1.0
	update_skyline()


## Plays morning sunrise window tint transition (warm rose/gold pre-dawn into crisp morning sky)
func play_morning_sunrise_transition(duration: float = 1.0) -> void:
	daily_time_progress = 0.0
	if not is_inside_tree() or sky_rect == null:
		update_skyline()
		return

	if _sky_tween and _sky_tween.is_valid():
		_sky_tween.kill()

	# Start from a warm golden pre-dawn horizon tint
	sky_rect.color = Color(0.85, 0.58, 0.42, 1.0)
	if sun_glow != null:
		sun_glow.position.y = 80.0
	if smog_overlay != null:
		smog_overlay.color.a = 0.1

	var target_sky_color := Color(0.38, 0.65, 0.88, 1.0)
	var target_sun_y := 40.0

	_sky_tween = create_tween().set_parallel(true)
	_sky_tween.tween_property(sky_rect, "color", target_sky_color, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if sun_glow != null:
		_sky_tween.tween_property(sun_glow, "position:y", target_sun_y, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if smog_overlay != null:
		_sky_tween.tween_property(smog_overlay, "color:a", 0.0, duration)
	_sky_tween.chain().tween_callback(func():
		update_skyline()
	)


# -----------------------------------------------------------------------------
# Public Weather, Lighting, Monorail & Particle Control API
# -----------------------------------------------------------------------------
func set_time_of_day_progress(progress: float) -> void:
	daily_time_progress = progress
	update_skyline()


func get_time_of_day_progress() -> float:
	return daily_time_progress


func is_monorail_animating() -> bool:
	return _monorail_tween != null and _monorail_tween.is_valid()


func set_rain_active(is_active: bool) -> void:
	if rain_particles:
		rain_particles.emitting = is_active


func is_rain_active() -> bool:
	return rain_particles != null and rain_particles.emitting


func is_smoke_active() -> bool:
	return chimney_smoke_particles != null and chimney_smoke_particles.emitting


func is_torch_fire_active() -> bool:
	return torch_fire_particles != null and torch_fire_particles.emitting


func is_police_lights_animating() -> bool:
	return _police_lights_tween != null and _police_lights_tween.is_valid()


func is_neon_animating() -> bool:
	return _neon_tween != null and _neon_tween.is_valid()


func get_layer_sky() -> CanvasGroup:
	return layer_sky


func get_layer_distant() -> CanvasGroup:
	return layer_distant


func get_layer_midground() -> CanvasGroup:
	return layer_midground


func get_layer_foreground() -> CanvasGroup:
	return layer_foreground
