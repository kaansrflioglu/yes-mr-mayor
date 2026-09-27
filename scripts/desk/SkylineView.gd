extends Control

## SkylineView.gd - Dynamic panoramic city window behind the mayor's desk.
## Restructured into 4 CanvasGroup layers (Sky, Distant, Midground, Foreground)
## with reactive CPU particle emitters and comprehensive decision reflections.

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
# 4. Midground Layer Props
# -----------------------------------------------------------------------------
@onready var prop_green_park: Control = %PropGreenPark
@onready var prop_golden_dinosaur: Control = %PropGoldenDinosaur
@onready var prop_metro_pit: Control = %PropMetroPit
@onready var prop_clean_metro: Control = %PropCleanMetro
@onready var prop_monorail: Control = %PropMonorail
@onready var prop_neon_casino: Control = %PropNeonCasino
@onready var prop_titanium_mayor: Control = %PropTitaniumMayor
@onready var prop_flood_catastrophe: Control = %PropFloodCatastrophe

# -----------------------------------------------------------------------------
# 5. Foreground Layer Props & Particles
# -----------------------------------------------------------------------------
@onready var prop_garbage_piles: Control = %PropGarbagePiles
@onready var prop_protest_mobs: Control = %PropProtestMobs
@onready var torch_fire_particles: CPUParticles2D = %TorchFireParticles
@onready var prop_police_siege: Control = %PropPoliceSiege


func _ready() -> void:
	if GameManager:
		GameManager.stats_changed.connect(update_skyline)
		if GameManager.has_signal("stats_updated"):
			GameManager.stats_updated.connect(update_skyline)
	update_skyline()


## Updates window view based on active event flags, environmental states, and public mood
func update_skyline() -> void:
	var flags: Dictionary = GameManager.event_flags if GameManager else {}

	# 1. Sky color transition (Smog vs Clear vs Riot gloom vs Catastrophe)
	var has_smog: bool = flags.get("toxic_smog", false) or flags.get("add_concrete_tower", false)
	var low_opinion: bool = (GameManager != null and GameManager.public_opinion <= 25.0)
	var high_suspicion: bool = (GameManager != null and GameManager.suspicion_meter >= 80.0)
	var is_flooded: bool = flags.get("flood_catastrophe", false)

	var target_sky_color := Color(0.38, 0.65, 0.88, 1.0) # Default clear azure
	var target_smog_alpha: float = 0.0

	if has_smog:
		target_sky_color = Color(0.52, 0.55, 0.38, 1.0) # Industrial yellow-gray smog
		target_smog_alpha = 0.55
	elif is_flooded:
		target_sky_color = Color(0.32, 0.38, 0.44, 1.0) # Stormy torrential slate
		target_smog_alpha = 0.35
	elif low_opinion:
		target_sky_color = Color(0.42, 0.44, 0.52, 1.0) # Overcast gloomy tension
		target_smog_alpha = 0.25

	if sky_rect and is_inside_tree():
		var sky_tween := create_tween().set_parallel(true)
		sky_tween.tween_property(sky_rect, "color", target_sky_color, 0.6)
		if smog_overlay:
			sky_tween.tween_property(smog_overlay, "color:a", target_smog_alpha, 0.6)

	# 2. Distant Layer Prop States
	_set_prop_state(prop_concrete_towers, flags.get("add_concrete_tower", false))
	_set_prop_state(prop_luxury_towers, flags.get("add_luxury_towers", false))
	_set_prop_state(
		prop_historic_clock_tower,
		flags.get("historic_clock_tower", false) and not flags.get("historic_rubble", false)
	)
	_set_prop_state(prop_historic_rubble, flags.get("historic_rubble", false))
	_set_prop_state(prop_toxic_chimneys, flags.get("toxic_smog", false))

	# 3. Midground Layer Prop States
	_set_prop_state(
		prop_green_park,
		flags.get("preserve_greenery", false) or flags.get("community_park", false)
	)
	_set_prop_state(prop_golden_dinosaur, flags.get("add_golden_dinosaur", false))
	_set_prop_state(prop_metro_pit, flags.get("abandoned_metro_pit", false))
	_set_prop_state(prop_clean_metro, flags.get("clean_metro_station", false))
	_set_prop_state(prop_monorail, flags.get("moving_monorail", false))
	_set_prop_state(prop_neon_casino, flags.get("neon_casino_strip", false))
	_set_prop_state(prop_titanium_mayor, flags.get("titanium_mayor_statue", false))
	_set_prop_state(prop_flood_catastrophe, is_flooded)

	# 4. Foreground Layer Prop States (Civil Unrest & Police Sieges)
	var protest_active: bool = flags.get("riot_crowds", false) or low_opinion
	var police_active: bool = flags.get("police_siege", false) or high_suspicion

	_set_prop_state(prop_garbage_piles, flags.get("garbage_piles", false))
	_set_prop_state(prop_protest_mobs, protest_active)
	_set_prop_state(prop_police_siege, police_active)

	# 5. Particle Systems State Updates
	_update_particles(flags, protest_active, is_flooded)


## Updates 2D particle emitter states based on environmental conditions
func _update_particles(flags: Dictionary, protest_active: bool, is_flooded: bool) -> void:
	# Rain particles: storm, flood catastrophe or weather_rain flag
	if rain_particles:
		var should_rain: bool = is_flooded or flags.get("weather_rain", false)
		rain_particles.emitting = should_rain

	# Chimney smoke particles: active when factory chimneys are spewing toxic smog
	if chimney_smoke_particles:
		var should_smoke: bool = flags.get("toxic_smog", false)
		chimney_smoke_particles.emitting = should_smoke

	# Torch fire particles: flickering flames above the angry protest crowd
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
# Public Weather & Particle Control API
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


func get_layer_sky() -> CanvasGroup:
	return layer_sky


func get_layer_distant() -> CanvasGroup:
	return layer_distant


func get_layer_midground() -> CanvasGroup:
	return layer_midground


func get_layer_foreground() -> CanvasGroup:
	return layer_foreground
