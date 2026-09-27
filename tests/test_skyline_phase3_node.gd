extends Node

## test_skyline_phase3_node.gd - Acceptance tests for Skyline Visuals Expansion Phase 3.
## Validates:
## 1. Elevated Monorail looping transit animation across the rail bridge
## 2. Monorail lifecycle and manual pass trigger
## 3. Diurnal Day/Night sky and sun progression (Morning -> Rush Hour Amber -> Dusk)
## 4. Daily queue integration advancing time-of-day for later events in shift
## 5. Day started/ended ritual reset & progression

const SKYLINE_VIEW_SCENE: PackedScene = preload("res://scenes/desk/SkylineView.tscn")

var passed_tests: int = 0
var total_tests: int = 5
var skyline: Control = null


func _ready() -> void:
	print("\n============================================================")
	print(">>> RUNNING SKYLINE VISUALS EXPANSION: PHASE 3 TESTS <<<")
	print("============================================================\n")

	_run_tests_async()


func _run_tests_async() -> void:
	skyline = SKYLINE_VIEW_SCENE.instantiate()
	add_child(skyline)
	await get_tree().process_frame

	await test_criterion_1_monorail_looping_transit()
	await test_criterion_2_monorail_manual_pass_and_cleanup()
	await test_criterion_3_diurnal_rush_hour_progression()
	test_criterion_4_daily_queue_rush_hour_connection()
	test_criterion_5_day_lifecycle_transitions()

	print("\n============================================================")
	if passed_tests == total_tests:
		print(">>> ALL %d SKYLINE PHASE 3 TESTS PASSED SUCCESSFULLY! <<<" % total_tests)
	else:
		print(">>> TEST FAILURES DETECTED! (%d/%d passed) <<<" % [passed_tests, total_tests])
	print("============================================================\n")

	get_tree().quit(0 if passed_tests == total_tests else 1)


func test_criterion_1_monorail_looping_transit() -> void:
	print("[TEST 1] Verifying elevated monorail looping transit across the rail bridge...")

	GameManager.event_flags.clear()
	GameManager.event_flags["moving_monorail"] = true
	skyline.update_skyline()

	var prop_visible: bool = skyline.get_node("%PropMonorail").visible
	var is_animating: bool = skyline.is_monorail_animating()
	var train: Control = skyline.get_node("%MonorailTrain")

	# Allow train to glide for a short duration
	await get_tree().create_timer(0.3).timeout
	var train_moving: bool = (train != null and train.position.x >= 760.0)

	if prop_visible and is_animating and train_moving:
		print("  -> Monorail bridge visible and train actively traversing track.")
		print("  [PASS] Test 1: Elevated monorail looping transit verified.\n")
		passed_tests += 1
	else:
		printerr("  [FAIL] Test 1: Monorail loop state failed: ", [prop_visible, is_animating, train_moving], "\n")


func test_criterion_2_monorail_manual_pass_and_cleanup() -> void:
	print("[TEST 2] Verifying monorail manual pass trigger and cleanup...")

	# Deactivate monorail
	GameManager.event_flags["moving_monorail"] = false
	skyline.update_skyline()

	var stopped: bool = not skyline.is_monorail_animating()
	var prop_hidden: bool = not skyline.get_node("%PropMonorail").visible

	# Test manual pass trigger
	skyline.trigger_monorail_pass(1.0)
	var train: Control = skyline.get_node("%MonorailTrain")
	await get_tree().create_timer(0.2).timeout
	var pass_running: bool = (train != null and train.modulate.a > 0.0)

	# Wait for pass to complete
	await get_tree().create_timer(1.2).timeout
	var pass_completed: bool = (train.position.x == 760.0 or train.modulate.a <= 0.1)

	if stopped and prop_hidden and pass_running and pass_completed:
		print("  -> Deactivation cleanly stops loop and trigger_monorail_pass executes standalone transit.")
		print("  [PASS] Test 2: Monorail lifecycle and manual trigger verified.\n")
		passed_tests += 1
	else:
		printerr("  [FAIL] Test 2: Monorail cleanup failed: ", [stopped, prop_hidden, pass_running, pass_completed], "\n")


func test_criterion_3_diurnal_rush_hour_progression() -> void:
	print("[TEST 3] Verifying diurnal progression (Morning -> Rush Hour Amber -> Dusk)...")
	GameManager.event_flags.clear()

	var sun: Panel = skyline.get_node("%SunGlow")
	var sky: ColorRect = skyline.get_node("%SkyRect")

	# Morning (0.0)
	skyline.set_time_of_day_progress(0.0)
	await get_tree().create_timer(0.65).timeout
	var morning_sun_y: float = sun.position.y
	var morning_sky: Color = sky.color

	# Rush Hour Amber (0.75)
	skyline.set_time_of_day_progress(0.75)
	await get_tree().create_timer(0.65).timeout
	var rush_sun_y: float = sun.position.y
	var rush_sky: Color = sky.color

	# Dusk Twilight (1.0)
	skyline.set_time_of_day_progress(1.0)
	await get_tree().create_timer(0.65).timeout
	var dusk_sun_y: float = sun.position.y

	var sun_descends: bool = (rush_sun_y > morning_sun_y and dusk_sun_y > rush_sun_y)
	var amber_shift: bool = (rush_sky.r > rush_sky.b and morning_sky.b > morning_sky.r)

	if sun_descends and amber_shift:
		print("  -> Sun position descends (y: %.1f -> %.1f -> %.1f) and sky shifts to warm amber during rush hour." % [morning_sun_y, rush_sun_y, dusk_sun_y])
		print("  [PASS] Test 3: Diurnal rush hour transitions confirmed.\n")
		passed_tests += 1
	else:
		printerr("  [FAIL] Test 3: Diurnal states failed: ", [sun_descends, amber_shift], "\n")


func test_criterion_4_daily_queue_rush_hour_connection() -> void:
	print("[TEST 4] Verifying daily queue progression auto-advances shift time-of-day...")

	# Prepare mock queue of 4 events
	EventManager.daily_queue.clear()
	var ev1 := EventData.new()
	ev1.id = "MOCK_EV_1"
	var ev2 := EventData.new()
	ev2.id = "MOCK_EV_2"
	var ev3 := EventData.new()
	ev3.id = "MOCK_EV_3"
	var ev4 := EventData.new()
	ev4.id = "MOCK_EV_4"

	EventManager.daily_queue = [ev1, ev2, ev3, ev4]
	skyline._on_daily_queue_prepared(1, 4)
	var initial_progress: float = skyline.get_time_of_day_progress()

	# Pop Event 1 -> 3 remain
	EventManager.daily_queue.pop_front()
	skyline._on_event_presented(ev1)
	var p1: float = skyline.get_time_of_day_progress()

	# Pop Event 2 -> 2 remain
	EventManager.daily_queue.pop_front()
	skyline._on_event_presented(ev2)
	var p2: float = skyline.get_time_of_day_progress()

	# Pop Event 3 -> 1 remains (evening rush hour)
	EventManager.daily_queue.pop_front()
	skyline._on_event_presented(ev3)
	var p3: float = skyline.get_time_of_day_progress()

	# Pop Final Event -> 0 remain (rush hour peak)
	EventManager.daily_queue.pop_front()
	skyline._on_event_presented(ev4)
	var p4: float = skyline.get_time_of_day_progress()

	var progresses_increase: bool = (
		initial_progress == 0.0 and
		p2 > p1 and
		p3 > p2 and
		p4 >= 0.85
	)

	if progresses_increase:
		print("  -> Shift progression verified: Initial 0.0 -> %.2f -> %.2f -> %.2f -> %.2f (Peak Rush Hour)." % [p1, p2, p3, p4])
		print("  [PASS] Test 4: Daily queue connection properly simulates evening rush hour.\n")
		passed_tests += 1
	else:
		printerr("  [FAIL] Test 4: Queue progression sequence failed: ", [initial_progress, p1, p2, p3, p4], "\n")


func test_criterion_5_day_lifecycle_transitions() -> void:
	print("[TEST 5] Verifying Day Started (sunrise) & Day Ended (dusk) lifecycle events...")

	# Simulate day ended
	skyline._on_day_ended(1)
	var ended_progress: float = skyline.get_time_of_day_progress()

	# Simulate day started
	skyline._on_day_started(2)
	var started_progress: float = skyline.get_time_of_day_progress()

	if ended_progress == 1.0 and started_progress == 0.0:
		print("  -> Day Ended triggers dusk (1.0), Day Started triggers fresh morning sunrise (0.0).")
		print("  [PASS] Test 5: Day lifecycle signals operate correctly.\n")
		passed_tests += 1
	else:
		printerr("  [FAIL] Test 5: Day lifecycle progress failed: ", [ended_progress, started_progress], "\n")
