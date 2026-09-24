extends Control

## SkylineView.gd - Dynamic panoramic city window behind the mayor's desk.
## Visually morphs reflecting municipal decisions, zoning projects, and absurd monuments.

@onready var sky_rect: ColorRect = %SkyRect
@onready var sun_glow: Panel = %SunGlow
@onready var smog_overlay: ColorRect = %SmogOverlay

@onready var prop_concrete_towers: Control = %PropConcreteTowers
@onready var prop_green_park: Control = %PropGreenPark
@onready var prop_golden_dinosaur: Control = %PropGoldenDinosaur
@onready var prop_metro_pit: Control = %PropMetroPit
@onready var prop_clean_metro: Control = %PropCleanMetro
@onready var prop_garbage_piles: Control = %PropGarbagePiles
@onready var prop_toxic_chimneys: Control = %PropToxicChimneys


func _ready() -> void:
	GameManager.stats_changed.connect(update_skyline)
	update_skyline()


## Updates window view based on active event flags and public mood
func update_skyline() -> void:
	var flags: Dictionary = GameManager.event_flags

	# 1. Sky color transition (Smog vs Clear vs Riot gloom)
	var has_smog: bool = flags.get("toxic_smog", false) or flags.get("add_concrete_tower", false)
	var low_opinion: bool = (GameManager.public_opinion <= 25.0)

	var target_sky_color := Color(0.38, 0.65, 0.88, 1) # Default clear azure
	var target_smog_alpha: float = 0.0

	if has_smog:
		target_sky_color = Color(0.52, 0.55, 0.38, 1) # Industrial yellow-gray smog
		target_smog_alpha = 0.55
	elif low_opinion:
		target_sky_color = Color(0.42, 0.44, 0.52, 1) # Overcast gloomy tension
		target_smog_alpha = 0.25

	var sky_tween := create_tween().set_parallel(true)
	sky_tween.tween_property(sky_rect, "color", target_sky_color, 0.6)
	sky_tween.tween_property(smog_overlay, "color:a", target_smog_alpha, 0.6)

	# 2. Dynamic City Props (At least 4 major municipal decision reflections)
	_set_prop_state(prop_concrete_towers, flags.get("add_concrete_tower", false))
	_set_prop_state(
		prop_green_park,
		flags.get("preserve_greenery", false) or flags.get("community_park", false)
	)
	_set_prop_state(prop_golden_dinosaur, flags.get("add_golden_dinosaur", false))
	_set_prop_state(prop_metro_pit, flags.get("abandoned_metro_pit", false))
	_set_prop_state(prop_clean_metro, flags.get("clean_metro_station", false))
	_set_prop_state(prop_garbage_piles, flags.get("garbage_piles", false))
	_set_prop_state(prop_toxic_chimneys, flags.get("toxic_smog", false))


func _set_prop_state(prop: Control, is_active: bool) -> void:
	if prop == null:
		return
	if is_active and not prop.visible:
		prop.visible = true
		prop.scale = Vector2(0.8, 0.8)
		prop.modulate.a = 0.0
		var tween := create_tween().set_parallel(true)
		tween.tween_property(prop, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK)
		tween.tween_property(prop, "modulate:a", 1.0, 0.3)
	elif not is_active:
		prop.visible = false
