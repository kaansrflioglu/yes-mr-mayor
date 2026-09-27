extends Node

## test_skyline_phase1_node.gd - Acceptance tests for Skyline Visuals Expansion Phase 1.
## Validates:
## 1. 4 CanvasGroup layers (Sky, Distant, Midground, Foreground)
## 2. 2D Particle Emitters (Rain, Chimney Smoke, Protest Torch Fire)
## 3. Expanded Decision Matrix Props & Particle Reaction to flags/mood
## 4. Integration with DeskView scene

const DESK_VIEW_SCENE: PackedScene = preload("res://scenes/desk/DeskView.tscn")
const SKYLINE_VIEW_SCENE: PackedScene = preload("res://scenes/desk/SkylineView.tscn")

var passed_tests: int = 0
var total_tests: int = 4
var skyline: Control = null
var desk_view: Control = null


func _ready() -> void:
	print("\n============================================================")
	print(">>> RUNNING SKYLINE VISUALS EXPANSION: PHASE 1 TESTS <<<")
	print("============================================================\n")

	_run_tests_async()


func _run_tests_async() -> void:
	skyline = SKYLINE_VIEW_SCENE.instantiate()
	add_child(skyline)
	await get_tree().process_frame

	test_criterion_1_canvas_group_layers()
	test_criterion_2_particle_emitters()
	test_criterion_3_expanded_matrix_and_reactions()
	await test_criterion_4_desk_view_layer_integration()

	print("\n============================================================")
	if passed_tests == total_tests:
		print(">>> ALL %d SKYLINE PHASE 1 TESTS PASSED SUCCESSFULLY! <<<" % total_tests)
	else:
		print(">>> TEST FAILURES DETECTED! (%d/%d passed) <<<" % [passed_tests, total_tests])
	print("============================================================\n")

	get_tree().quit(0 if passed_tests == total_tests else 1)


func test_criterion_1_canvas_group_layers() -> void:
	print("[TEST 1] Verifying 4 CanvasGroup layers (Sky, Distant, Midground, Foreground)...")
	var l_sky: CanvasGroup = skyline.get_layer_sky()
	var l_dist: CanvasGroup = skyline.get_layer_distant()
	var l_mid: CanvasGroup = skyline.get_layer_midground()
	var l_fore: CanvasGroup = skyline.get_layer_foreground()

	var valid_types: bool = (
		l_sky is CanvasGroup and
		l_dist is CanvasGroup and
		l_mid is CanvasGroup and
		l_fore is CanvasGroup
	)

	var valid_names: bool = (
		skyline.has_node("%LayerSky") and
		skyline.has_node("%LayerDistant") and
		skyline.has_node("%LayerMidground") and
		skyline.has_node("%LayerForeground")
	)

	if valid_types and valid_names:
		print("  -> LayerSky, LayerDistant, LayerMidground, LayerForeground validated as CanvasGroup nodes.")
		print("  [PASS] Test 1: CanvasGroup 4-layer structure confirmed.\n")
		passed_tests += 1
	else:
		printerr("  [FAIL] Test 1: CanvasGroup layer validation failed: ", [valid_types, valid_names], "\n")


func test_criterion_2_particle_emitters() -> void:
	print("[TEST 2] Verifying 2D CPU particle emitters (Rain, Smoke, Torch Fire)...")
	var rain: CPUParticles2D = skyline.get_node("%RainParticles")
	var smoke: CPUParticles2D = skyline.get_node("%ChimneySmokeParticles")
	var torch: CPUParticles2D = skyline.get_node("%TorchFireParticles")

	var nodes_exist: bool = (rain != null and smoke != null and torch != null)
	if not nodes_exist:
		printerr("  [FAIL] Test 2: One or more particle emitter nodes missing.\n")
		return

	# Test Rain API
	skyline.set_rain_active(true)
	var rain_on: bool = skyline.is_rain_active()
	skyline.set_rain_active(false)
	var rain_off: bool = not skyline.is_rain_active()

	# Test Smoke trigger via toxic_smog
	GameManager.event_flags["toxic_smog"] = true
	skyline.update_skyline()
	var smoke_on: bool = skyline.is_smoke_active()
	GameManager.event_flags["toxic_smog"] = false
	skyline.update_skyline()
	var smoke_off: bool = not skyline.is_smoke_active()

	# Test Torch fire trigger via low opinion
	GameManager.public_opinion = 15.0
	skyline.update_skyline()
	var torch_on: bool = skyline.is_torch_fire_active()
	GameManager.public_opinion = 70.0
	GameManager.event_flags["riot_crowds"] = false
	skyline.update_skyline()
	var torch_off: bool = not skyline.is_torch_fire_active()

	if rain_on and rain_off and smoke_on and smoke_off and torch_on and torch_off:
		print("  -> Rain, Chimney Smoke, and Torch Fire particle emitters fully reactive.")
		print("  [PASS] Test 2: Particle systems functioning correctly.\n")
		passed_tests += 1
	else:
		printerr("  [FAIL] Test 2: Particle states unexpected: ", [rain_on, rain_off, smoke_on, smoke_off, torch_on, torch_off], "\n")


func test_criterion_3_expanded_matrix_and_reactions() -> void:
	print("[TEST 3] Verifying expanded prop matrix flags & environmental reactivity...")

	# Luxury Towers
	GameManager.event_flags["add_luxury_towers"] = true
	skyline.update_skyline()
	var lux_visible: bool = skyline.get_node("%PropLuxuryTowers").visible

	# Historic Clock Tower vs Rubble
	GameManager.event_flags["historic_clock_tower"] = true
	GameManager.event_flags["historic_rubble"] = false
	skyline.update_skyline()
	var clock_visible: bool = skyline.get_node("%PropHistoricClockTower").visible

	GameManager.event_flags["historic_rubble"] = true
	skyline.update_skyline()
	var rubble_visible: bool = skyline.get_node("%PropHistoricRubble").visible
	var clock_hidden: bool = not skyline.get_node("%PropHistoricClockTower").visible

	# Monorail & Neon Casino
	GameManager.event_flags["moving_monorail"] = true
	GameManager.event_flags["neon_casino_strip"] = true
	skyline.update_skyline()
	var monorail_visible: bool = skyline.get_node("%PropMonorail").visible
	var casino_visible: bool = skyline.get_node("%PropNeonCasino").visible

	# Titanium Mayor & Flood Catastrophe
	GameManager.event_flags["titanium_mayor_statue"] = true
	GameManager.event_flags["flood_catastrophe"] = true
	skyline.update_skyline()
	var statue_visible: bool = skyline.get_node("%PropTitaniumMayor").visible
	var flood_visible: bool = skyline.get_node("%PropFloodCatastrophe").visible
	var flood_rain: bool = skyline.is_rain_active()

	# Police Siege
	GameManager.event_flags["police_siege"] = true
	skyline.update_skyline()
	var police_visible: bool = skyline.get_node("%PropPoliceSiege").visible

	var all_props_pass: bool = (
		lux_visible and
		clock_visible and
		rubble_visible and
		clock_hidden and
		monorail_visible and
		casino_visible and
		statue_visible and
		flood_visible and
		flood_rain and
		police_visible
	)

	if all_props_pass:
		print("  -> Luxury towers, clock/rubble, monorail, casino, statue, flood, and police siege verified.")
		print("  [PASS] Test 3: Expanded prop matrix operates seamlessly.\n")
		passed_tests += 1
	else:
		printerr("  [FAIL] Test 3: One or more prop states failed validation.\n")


func test_criterion_4_desk_view_layer_integration() -> void:
	print("[TEST 4] Verifying SkylineView mounting inside DeskView...")
	desk_view = DESK_VIEW_SCENE.instantiate()
	add_child(desk_view)
	await get_tree().process_frame

	var desk_skyline: Control = desk_view.get_node("%SkylineView")
	if desk_skyline == null:
		printerr("  [FAIL] Test 4: %SkylineView not found in DeskView.\n")
		return

	var has_sky: bool = desk_skyline.has_node("%LayerSky")
	var has_rain: bool = desk_skyline.has_node("%RainParticles")
	var has_protest: bool = desk_skyline.has_node("%PropProtestMobs")

	if has_sky and has_rain and has_protest:
		print("  -> DeskView successfully hosts restructured 4-layer SkylineView.")
		print("  [PASS] Test 4: DeskView integration confirmed.\n")
		passed_tests += 1
	else:
		printerr("  [FAIL] Test 4: DeskView child nodes check failed.\n")
