extends Node

## test_shredder_mechanics.gd - Verifies DeskShredder prop, evidence tampering, overuse penalty, and daily reset.

var passed_tests: int = 0
var total_tests: int = 3

@onready var game_mgr: Node = get_node("/root/GameManager")
@onready var event_mgr: Node = get_node("/root/EventManager")


func _ready() -> void:
	print("\n========================================================")
	print(">>> RUNNING TACTILE DESK SHREDDER MECHANICS TESTS <<<")
	print("========================================================\n")

	await test_test_1_shred_action_and_suspicion_drop()
	await test_test_2_overuse_consequence()
	test_test_3_daily_reset()

	print("\n========================================================")
	if passed_tests == total_tests:
		print(">>> ALL 3 SHREDDER MECHANICS TESTS PASSED! (3/3) <<<")
	else:
		print(">>> TEST FAILURES DETECTED! (%d/%d) <<<" % [passed_tests, total_tests])
	print("========================================================\n")

	get_tree().quit(0 if passed_tests == total_tests else 1)


func test_test_1_shred_action_and_suspicion_drop() -> void:
	print("[TEST 1] Verifying shred action and suspicion reduction...")
	game_mgr.start_new_game()
	event_mgr.reset_deck()
	game_mgr.suspicion_level = 50.0

	var desk_scene: PackedScene = preload("res://scenes/desk/DeskView.tscn")
	var desk_instance = desk_scene.instantiate()
	desk_instance.name = "DeskView"
	add_child(desk_instance)

	assert(desk_instance.desk_shredder != null, "DeskShredder prop must be instanced in DeskView.")
	assert(desk_instance.desk_shredder.daily_shred_count == 0, "Initial shred count must be 0.")

	var initial_susp: float = game_mgr.suspicion_level
	# Trigger shred requested
	desk_instance._on_shred_requested()
	await desk_instance.desk_shredder.shred_completed

	assert(desk_instance.desk_shredder.daily_shred_count == 1, "Daily shred count must be 1.")
	assert(game_mgr.suspicion_level < initial_susp, "Suspicion must drop after shredding evidence.")

	desk_instance.queue_free()
	print("  -> First shred succeeded: Suspicion %f -> %f" % [initial_susp, game_mgr.suspicion_level])
	print("  [PASS] Test 1: Shred Action & Suspicion Drop verified.\n")
	passed_tests += 1


func test_test_2_overuse_consequence() -> void:
	print("[TEST 2] Verifying overuse consequence (+25% suspicion and tamper flag)...")
	game_mgr.start_new_game()
	event_mgr.reset_deck()
	game_mgr.suspicion_level = 30.0

	var desk_scene: PackedScene = preload("res://scenes/desk/DeskView.tscn")
	var desk_instance = desk_scene.instantiate()
	desk_instance.name = "DeskView"
	add_child(desk_instance)

	# First shred: safe
	desk_instance._on_shred_requested()
	await desk_instance.desk_shredder.shred_completed
	await get_tree().process_frame

	var susp_after_first: float = game_mgr.suspicion_level

	# Second shred: dangerous overuse
	desk_instance._on_shred_requested()
	await desk_instance.desk_shredder.shred_completed
	await get_tree().process_frame

	assert(desk_instance.desk_shredder.daily_shred_count == 2, "Daily shred count must be 2.")
	assert(game_mgr.suspicion_level > susp_after_first, "Suspicion must increase after overuse penalty.")
	assert(game_mgr.event_flags.get("FLAG_SHREDDER_EVIDENCE_TAMPERED", false) == true, "FLAG_SHREDDER_EVIDENCE_TAMPERED must be set.")

	desk_instance.queue_free()
	print("  -> Overuse shred penalty applied: Suspicion rose by +10 net (%f -> %f)" % [susp_after_first, game_mgr.suspicion_level])
	print("  [PASS] Test 2: Overuse Consequence verified.\n")
	passed_tests += 1


func test_test_3_daily_reset() -> void:
	print("[TEST 3] Verifying shredder daily counter and LED reset...")
	var shredder_scene: PackedScene = preload("res://scenes/desk/DeskShredder.tscn")
	var shredder_instance: Control = shredder_scene.instantiate()
	add_child(shredder_instance)

	shredder_instance.daily_shred_count = 3
	shredder_instance.update_led()
	assert(shredder_instance.status_led.color == Color(0.9, 0.2, 0.2, 1.0), "LED must be red when jammed.")

	shredder_instance.reset_day()
	assert(shredder_instance.daily_shred_count == 0, "Counter must be 0 after reset.")
	assert(shredder_instance.status_led.color == Color(0.2, 0.9, 0.3, 1.0), "LED must be green after reset.")

	shredder_instance.queue_free()
	print("  -> Shredder successfully reset to green state.")
	print("  [PASS] Test 3: Daily Reset verified.\n")
	passed_tests += 1
