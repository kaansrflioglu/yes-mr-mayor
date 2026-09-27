extends Control

## SkylineView.gd - Dynamic panoramic city window behind the mayor's desk.
## Features 4 CanvasGroup layers, reactive CPU particles, dynamic lighting,
## looping emergency flashers, and world-state reactivity.

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
# 4. Midground Layer Props & Lighting
# -----------------------------------------------------------------------------
@onready var prop_green_park: Control = %PropGreenPark
@onready var prop_golden_dinosaur: Control = %PropGoldenDinosaur
@onready var prop_metro_pit: Control = %PropMetroPit
@onready var prop_clean_metro: Control = %PropCleanMetro
@onready var prop_monorail: Control = %PropMonorail
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
# 6. Active Tweens
# -----------------------------------------------------------------------------
var _police_lights_tween: Tween = null
var _neon_tween: Tween = null
var _sky_tween: Tween = null


func _ready() -> void:
	if GameManager:
		GameManager.stats_changed.connect(update_skyline)
		if GameManager.has_signal("stats_updated"):
			GameManager.stats_updated.connect(update_skyline)
	update_skyline()


func _exit_tree() -> void:
	_stop_police_lights()
	_stop_neon_casino()
	if _sky_tween and _sky_tween.is_valid():
		_sky_tween.kill()


## Updates window view dynamically based on event flags, public opinion, and suspicion thresholds
func update_skyline() -> void:
	var flags: Dictionary = GameManager.event_flags if GameManager != null else {}

	# 1. Dynamic Metric Thresholds
	var low_opinion: bool = (GameManager != null and GameManager.public_opinion < 25.0)
	var high_opinion: bool = (GameManager != null and GameManager.public_opinion >= 75.0)
	var high_suspicion: bool = (GameManager != null and GameManager.suspicion_meter >= 80.0)

	var has_smog: bool = flags.get("toxic_smog", false) or flags.get("add_concrete_tower", false)
	var is_flooded: bool = flags.get("flood_catastrophe", false)
	var is_sunset: bool = flags.get("weather_sunset", false)
	var is_night: bool = flags.get("weather_night", false)

	# 2. Dynamic Sky Color & Atmosphere Palette
	var target_sky_color := Color(0.38, 0.65, 0.88, 1.0) # Default clear azure
	var target_smog_alpha: float = 0.0

	if has_smog:
		target_sky_color = Color(0.52, 0.55, 0.38, 1.0) # Industrial ochre smog
		target_smog_alpha = 0.55
	elif is_flooded:
		target_sky_color = Color(0.30, 0.36, 0.42, 1.0) # Torrential storm slate
		target_smog_alpha = 0.35
	elif is_night:
		target_sky_color = Color(0.12, 0.14, 0.22, 1.0) # Night noir
		target_smog_alpha = 0.15
	elif is_sunset:
		target_sky_color = Color(0.85, 0.52, 0.32, 1.0) # Sunset amber
		target_smog_alpha = 0.10
	elif high_suspicion:
		target_sky_color = Color(0.36, 0.28, 0.38, 1.0) # Tense twilight purple
		target_smog_alpha = 0.20
	elif low_opinion:
		target_sky_color = Color(0.42, 0.44, 0.52, 1.0) # Overcast gloomy unrest
		target_smog_alpha = 0.25
	elif high_opinion:
		target_sky_color = Color(0.42, 0.70, 0.95, 1.0) # Radiant golden-era blue
		target_smog_alpha = 0.0

	if sky_rect and is_inside_tree():
		if _sky_tween and _sky_tween.is_valid():
			_sky_tween.kill()
		_sky_tween = create_tween().set_parallel(true)
		_sky_tween.tween_property(sky_rect, "color", target_sky_color, 0.6)
		if smog_overlay:
			_sky_tween.tween_property(smog_overlay, "color:a", target_smog_alpha, 0.6)

	# 3. Distant Layer Prop States
	_set_prop_state(prop_concrete_towers, flags.get("add_concrete_tower", false))
	_set_prop_state(prop_luxury_towers, flags.get("add_luxury_towers", false))
	_set_prop_state(
		prop_historic_clock_tower,
		flags.get("historic_clock_tower", false) and not flags.get("historic_rubble", false)
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
	_set_prop_state(prop_monorail, flags.get("moving_monorail", false))
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
	if rain_particles:
		var should_rain: bool = is_flooded or flags.get("weather_rain", false)
		rain_particles.emitting = should_rain

	if chimney_smoke_particles:
		var should_smoke: bool = flags.get("toxic_smog", false)
		chimney_smoke_particles.emitting = should_smoke

	if torch_fire_particles:
		torch_fire_particles.emitting = protest_active


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
# Public Weather, Lighting & Particle Control API
# -----------------------------------------------------------------------------
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
