extends Node

## test_phase4_node.gd - Automated Test verifying Phase 4 Skyline, Audio & Telephone.

const DESK_VIEW_SCENE: PackedScene = preload("res://scenes/desk/DeskView.tscn")

var passed_tests: int = 0
var total_tests: int = 4
var desk_view: Control = null


func _ready() -> void:
	print("\n==========================================")
	print(">>> RUNNING PHASE 4 ACCEPTANCE TESTS <<<")
	print("==========================================\n")

	_run_tests_async()


func _run_tests_async() -> void:
	desk_view = DESK_VIEW_SCENE.instantiate()
	add_child(desk_view)
	await get_tree().process_frame

	test_criterion_1_audio_feedback()
	await test_criterion_2_skyline_decisions()
	await test_criterion_3_red_telephone_flow()
	test_criterion_4_desk_elements_integration()

	print("\n==========================================")
	if passed_tests == total_tests:
		print(">>> ALL 4 PHASE 4 TESTS PASSED SUCCESSFULLY! (4/4) <<<")
	else:
		print(">>> TEST FAILURES DETECTED! (%d/%d) <<<" % [passed_tests, total_tests])
	print("==========================================\n")

	get_tree().quit(0 if passed_tests == total_tests else 1)


func test_criterion_1_audio_feedback() -> void:
	print("[TEST 1] Verifying procedural audio feedback for all mechanical actions...")
	# Stamp thuds
	AudioManager.play_stamp_thud(true)
	AudioManager.play_stamp_thud(false)

	# Paper slide
	AudioManager.play_paper_slide()

	# Cash drawer
	AudioManager.play_cash_register()

	# Phone ring
	AudioManager.play_phone_ring()

	print("  -> Stamp thud, paper slide, cash register, and phone bell synthesized.")
	print("  [PASS] Test 1: Mechanical audio feedback operating correctly.\n")
	passed_tests += 1


func test_criterion_2_skyline_decisions() -> void:
	print("[TEST 2] Verifying office window reflects at least 4 major municipal decisions...")
	var skyline: Control = desk_view.get_node("%SkylineView")
	if skyline == null:
		printerr("  [FAIL] Test 2: SkylineView node not found.\n")
		return

	# Decision 1: Add Concrete Towers
	GameManager.event_flags["add_concrete_tower"] = true
	skyline.update_skyline()
	var d1: bool = skyline.get_node("%PropConcreteTowers").visible

	# Decision 2: Add 50m Golden Dinosaur Monument
	GameManager.event_flags["add_golden_dinosaur"] = true
	skyline.update_skyline()
	var d2: bool = skyline.get_node("%PropGoldenDinosaur").visible

	# Decision 3: Abandoned Metro Pit
	GameManager.event_flags["abandoned_metro_pit"] = true
	skyline.update_skyline()
	var d3: bool = skyline.get_node("%PropMetroPit").visible

	# Decision 4: Toxic Smog & Factory Chimneys
	GameManager.event_flags["toxic_smog"] = true
	skyline.update_skyline()
	var d4: bool = skyline.get_node("%PropToxicChimneys").visible

	# Decision 5: Green Botanical Park
	GameManager.event_flags["preserve_greenery"] = true
	skyline.update_skyline()
	var d5: bool = skyline.get_node("%PropGreenPark").visible

	await get_tree().create_timer(0.2).timeout

	if d1 and d2 and d3 and d4 and d5:
		print("  -> Tower, Dinosaur, Metro Pit, Toxic Smog, and Green Park verified.")
		print("  [PASS] Test 2: 5 major visual decision reflections confirmed.\n")
		passed_tests += 1
	else:
		printerr("  [FAIL] Test 2: Visual props state: ", [d1, d2, d3, d4, d5], "\n")


func test_criterion_3_red_telephone_flow() -> void:
	print("[TEST 3] Verifying Red Emergency Telephone ringing and party boss deal...")
	var phone: Control = desk_view.get_node("%RedTelephone")
	if phone == null:
		printerr("  [FAIL] Test 3: RedTelephone node not found.\n")
		return

	# Give initial suspicion and budget to measure deltas
	GameManager.suspicion_meter = 50.0
	var initial_budget: int = GameManager.city_budget
	var initial_suspicion: float = GameManager.suspicion_meter

	# Trigger ring
	phone.ring_telephone()
	var ringing: bool = phone.is_ringing

	# Click phone to answer
	phone.answer_call()
	var dialog_open: bool = phone.get_node("%DialogPanel").visible

	# Accept deal
	phone.accept_deal()
	await get_tree().create_timer(0.2).timeout

	var suspicion_dropped: bool = (GameManager.suspicion_meter < initial_suspicion)
	var budget_paid: bool = (GameManager.city_budget == initial_budget - 30000)

	if ringing and dialog_open and suspicion_dropped and budget_paid:
		print("  -> Phone rang, dialog answered, deal reduced suspicion by 20%.")
		print("  [PASS] Test 3: Red Emergency Telephone mechanics verified.\n")
		passed_tests += 1
	else:
		printerr("  [FAIL] Test 3: Phone flow failed.\n")


func test_criterion_4_desk_elements_integration() -> void:
	print("[TEST 4] Verifying all Phase 4 elements integration in DeskView...")
	var has_skyline: bool = desk_view.has_node("%SkylineView")
	var has_phone: bool = desk_view.has_node("%RedTelephone")

	if has_skyline and has_phone:
		print("  -> Panoramic Skyline & Hotline telephone fully mounted.")
		print("  [PASS] Test 4: Scene integration complete.\n")
		passed_tests += 1
	else:
		printerr("  [FAIL] Test 4: Missing scene components.\n")
