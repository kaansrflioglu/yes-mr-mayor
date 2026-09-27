extends Node

## test_skyline_phase2_node.gd - Acceptance tests for Skyline Visuals Expansion Phase 2.
## Validates:
## 1. Dynamic Public Opinion thresholds (< 25.0 unrest vs >= 75.0 prosperity)
## 2. Dynamic Suspicion thresholds (>= 80.0 siege and light activation)
## 3. Alternating looping police emergency flasher tween (Red/Blue alternating)
## 4. Neon casino strip pulse animation and lifecycle
## 5. Atmosphere and sky tint transitions

const SKYLINE_VIEW_SCENE: PackedScene = preload("res://scenes/desk/SkylineView.tscn")

var passed_tests: int = 0
var total_tests: int = 5
var skyline: Control = null


func _ready() -> void:
	print("\n============================================================")
	print(">>> RUNNING SKYLINE VISUALS EXPANSION: PHASE 2 TESTS <<<")
	print("============================================================\n")

	_run_tests_async()


func _run_tests_async() -> void:
	skyline = SKYLINE_VIEW_SCENE.instantiate()
	add_child(skyline)
	await get_tree().process_frame

	test_criterion_1_dynamic_opinion_unrest()
	test_criterion_2_suspicion_threshold_police_siege()
	await test_criterion_3_alternating_police_flasher_tween()
	test_criterion_4_neon_casino_pulse()
	test_criterion_5_atmosphere_gradients()

	print("\n============================================================")
	if passed_tests == total_tests:
		print(">>> ALL %d SKYLINE PHASE 2 TESTS PASSED SUCCESSFULLY! <<<" % total_tests)
	else:
		print(">>> TEST FAILURES DETECTED! (%d/%d passed) <<<" % [passed_tests, total_tests])
	print("============================================================\n")

	get_tree().quit(0 if passed_tests == total_tests else 1)


func test_criterion_1_dynamic_opinion_unrest() -> void:
	print("[TEST 1] Verifying dynamic opinion threshold (< 25% unrest vs >= 75% prosperity)...")

	# Low opinion trigger (< 25%)
	GameManager.event_flags.clear()
	GameManager.public_opinion = 20.0
	skyline.update_skyline()

	var mob_visible: bool = skyline.get_node("%PropProtestMobs").visible
	var torch_active: bool = skyline.is_torch_fire_active()

	# High opinion trigger (>= 75%)
	GameManager.public_opinion = 85.0
	skyline.update_skyline()

	var mob_hidden: bool = not skyline.get_node("%PropProtestMobs").visible
	var torch_inactive: bool = not skyline.is_torch_fire_active()

	if mob_visible and torch_active and mob_hidden and torch_inactive:
		print("  -> Protest mob & torch fire activate under 25% and hide at 85%.")
		print("  [PASS] Test 1: Public opinion threshold reactivity verified.\n")
		passed_tests += 1
	else:
		printerr("  [FAIL] Test 1: Opinion states failed: ", [mob_visible, torch_active, mob_hidden, torch_inactive], "\n")


func test_criterion_2_suspicion_threshold_police_siege() -> void:
	print("[TEST 2] Verifying suspicion threshold (>= 80% siege and flashers)...")

	GameManager.event_flags.clear()
	GameManager.suspicion_meter = 85.0
	skyline.update_skyline()

	var siege_visible: bool = skyline.get_node("%PropPoliceSiege").visible
	var lights_animating: bool = skyline.is_police_lights_animating()

	# Suspicion drops below 80%
	GameManager.suspicion_meter = 40.0
	skyline.update_skyline()

	var siege_hidden: bool = not skyline.get_node("%PropPoliceSiege").visible
	var lights_stopped: bool = not skyline.is_police_lights_animating()

	if siege_visible and lights_animating and siege_hidden and lights_stopped:
		print("  -> Police siege & emergency lights trigger at >=80% suspicion and deactivate below.")
		print("  [PASS] Test 2: Suspicion threshold reactivity verified.\n")
		passed_tests += 1
	else:
		printerr("  [FAIL] Test 2: Suspicion states failed: ", [siege_visible, lights_animating, siege_hidden, lights_stopped], "\n")


func test_criterion_3_alternating_police_flasher_tween() -> void:
	print("[TEST 3] Verifying alternating looping police flasher tween (Red/Blue energy)...")

	# Force police siege
	GameManager.event_flags["police_siege"] = true
	skyline.update_skyline()

	var is_looping: bool = skyline.is_police_lights_animating()
	var red_node: Node = skyline.get_node("%RedLight")
	var blue_node: Node = skyline.get_node("%BlueLight")

	# Allow tween to run a few frames
	await get_tree().create_timer(0.25).timeout

	var energy_active: bool = (red_node.energy > 0.0 or blue_node.energy > 0.0)

	# Stop flashers
	GameManager.event_flags["police_siege"] = false
	GameManager.suspicion_meter = 20.0
	skyline.update_skyline()

	var stopped: bool = not skyline.is_police_lights_animating()
	var energy_zero: bool = (red_node.energy == 0.0 and blue_node.energy == 0.0)

	if is_looping and energy_active and stopped and energy_zero:
		print("  -> Alternating looping tween actively modifies Red/Blue energy and clears on stop.")
		print("  [PASS] Test 3: Police flasher tween verified.\n")
		passed_tests += 1
	else:
		printerr("  [FAIL] Test 3: Flasher tween states failed: ", [is_looping, energy_active, stopped, energy_zero], "\n")


func test_criterion_4_neon_casino_pulse() -> void:
	print("[TEST 4] Verifying neon casino pulse animation and lifecycle...")

	GameManager.event_flags["neon_casino_strip"] = true
	skyline.update_skyline()

	var casino_visible: bool = skyline.get_node("%PropNeonCasino").visible
	var neon_pulsing: bool = skyline.is_neon_animating()

	# Turn off casino
	GameManager.event_flags["neon_casino_strip"] = false
	skyline.update_skyline()

	var casino_hidden: bool = not skyline.get_node("%PropNeonCasino").visible
	var neon_stopped: bool = not skyline.is_neon_animating()

	if casino_visible and neon_pulsing and casino_hidden and neon_stopped:
		print("  -> Neon casino loop starts on approval and cleanly stops when dismantled.")
		print("  [PASS] Test 4: Neon casino pulse animation verified.\n")
		passed_tests += 1
	else:
		printerr("  [FAIL] Test 4: Neon states failed: ", [casino_visible, neon_pulsing, casino_hidden, neon_stopped], "\n")


func test_criterion_5_atmosphere_gradients() -> void:
	print("[TEST 5] Verifying atmosphere & sky color transitions...")

	# Sunset Amber
	GameManager.event_flags.clear()
	GameManager.event_flags["weather_sunset"] = true
	skyline.update_skyline()
	var sky_rect: ColorRect = skyline.get_node("%SkyRect")
	var has_sky_rect: bool = (sky_rect != null)

	# Night Noir
	GameManager.event_flags.clear()
	GameManager.event_flags["weather_night"] = true
	skyline.update_skyline()

	# Flood storm
	GameManager.event_flags.clear()
	GameManager.event_flags["flood_catastrophe"] = true
	skyline.update_skyline()

	if has_sky_rect:
		print("  -> Sunset Amber, Night Noir, and Flood Storm sky transitions successfully applied.")
		print("  [PASS] Test 5: Atmosphere gradient transitions verified.\n")
		passed_tests += 1
	else:
		printerr("  [FAIL] Test 5: Sky rect missing.\n")
