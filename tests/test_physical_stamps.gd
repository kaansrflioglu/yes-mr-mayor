extends Node

## test_physical_stamps.gd - Verifies physical stamp drag & drop, miss return, document hit, and hotkey parity.

var passed_tests: int = 0
var total_tests: int = 3

@onready var game_mgr: Node = get_node("/root/GameManager")
@onready var event_mgr: Node = get_node("/root/EventManager")


func _ready() -> void:
	print("\n========================================================")
	print(">>> RUNNING PHYSICAL STAMP HANDLES ACCEPTANCE TESTS <<<")
	print("========================================================\n")

	await test_test_1_handle_drag_and_return_on_miss()
	await test_test_2_document_slam()
	await test_test_3_hotkey_parity()

	print("\n========================================================")
	if passed_tests == total_tests:
		print(">>> ALL 3 PHYSICAL STAMP TESTS PASSED! (3/3) <<<")
	else:
		print(">>> TEST FAILURES DETECTED! (%d/%d) <<<" % [passed_tests, total_tests])
	print("========================================================\n")

	get_tree().quit(0 if passed_tests == total_tests else 1)


func test_test_1_handle_drag_and_return_on_miss() -> void:
	print("[TEST 1] Verifying handle drag and return to rest position on miss...")
	game_mgr.start_new_game()

	var desk_scene: PackedScene = preload("res://scenes/desk/DeskView.tscn")
	var desk_instance = desk_scene.instantiate()
	desk_instance.name = "DeskView"
	add_child(desk_instance)

	assert(desk_instance.physical_stamp_rack != null, "PhysicalStampRack must be present in DeskView.")
	var rack = desk_instance.physical_stamp_rack
	var approve_handle = rack.approve_handle

	var orig_pos: Vector2 = approve_handle.position

	# Simulate dragging handle to outside position
	approve_handle.start_drag(Vector2(100, 100))
	approve_handle.global_position = Vector2(50, 50) # Far top-left outside document
	approve_handle.finish_slam(Vector2(50, 50))

	# Wait for return tween
	await get_tree().create_timer(0.4).timeout

	assert(desk_instance.active_document != null, "Active document must still exist.")
	assert(not desk_instance.active_document.is_stamped, "Document must NOT be stamped when dropped outside.")
	assert(approve_handle.position.distance_to(orig_pos) < 2.0, "Handle must return to rest position.")

	desk_instance.queue_free()
	print("  -> Missed drop handled cleanly: handle returned without triggering decision.")
	print("  [PASS] Test 1: Handle Drag & Return verified.\n")
	passed_tests += 1


func test_test_2_document_slam() -> void:
	print("[TEST 2] Verifying physical stamp slam over document triggers stamping...")
	game_mgr.start_new_game()

	var desk_scene: PackedScene = preload("res://scenes/desk/DeskView.tscn")
	var desk_instance = desk_scene.instantiate()
	desk_instance.name = "DeskView"
	add_child(desk_instance)

	assert(desk_instance.active_document != null, "Active document must be present.")
	var doc = desk_instance.active_document
	var doc_center: Vector2 = doc.global_position + (doc.size * 0.5)

	# Simulate dropping approve handle directly onto document center
	var rack = desk_instance.physical_stamp_rack
	var approve_handle = rack.approve_handle
	approve_handle.start_drag(doc_center)
	approve_handle.finish_slam(doc_center)

	await get_tree().process_frame
	await get_tree().process_frame

	assert(doc.is_stamped == true, "Document must be stamped upon direct hit.")
	assert(doc.stamp_overlay.visible == true, "Stamp overlay must be visible.")

	desk_instance.queue_free()
	print("  -> Physical drop onto document triggered stamp overlay and decision sequence.")
	print("  [PASS] Test 2: Document Slam verified.\n")
	passed_tests += 1


func test_test_3_hotkey_parity() -> void:
	print("[TEST 3] Verifying hotkey parity triggers stamp handle slam...")
	game_mgr.start_new_game()

	var desk_scene: PackedScene = preload("res://scenes/desk/DeskView.tscn")
	var desk_instance = desk_scene.instantiate()
	desk_instance.name = "DeskView"
	add_child(desk_instance)

	var doc = desk_instance.active_document
	assert(doc != null, "Active document must be present.")

	# Trigger approve via hotkey method
	desk_instance._on_approve_pressed()

	await get_tree().process_frame
	await get_tree().process_frame

	assert(doc.is_stamped == true, "Document must be stamped via hotkey parity.")

	desk_instance.queue_free()
	print("  -> Hotkey parity successfully executed physical stamp slam.")
	print("  [PASS] Test 3: Hotkey Parity verified.\n")
	passed_tests += 1
