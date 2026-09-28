extends Node

## test_black_market_expansion.gd - Acceptance test suite for Office Customization & Black Market Expansion (Spec 09).

var passed_tests: int = 0
var total_tests: int = 3

@onready var game_mgr: Node = get_node("/root/GameManager")
@onready var save_mgr: Node = get_node("/root/SaveLoadManager")


func _ready() -> void:
	print("\n========================================================")
	print(">>> RUNNING BLACK MARKET & OFFICE CUSTOMIZATION TESTS <<<")
	print("========================================================\n")

	await test_test_1_espresso_machine_buff()
	await test_test_2_investment_dividends()
	await test_test_3_save_load_persistence()

	print("\n========================================================")
	if passed_tests == total_tests:
		print(">>> ALL 3 BLACK MARKET TESTS PASSED! (3/3) <<<")
	else:
		print(">>> TEST FAILURES DETECTED! (%d/%d) <<<" % [passed_tests, total_tests])
	print("========================================================\n")

	get_tree().quit(0 if passed_tests == total_tests else 1)


func test_test_1_espresso_machine_buff() -> void:
	print("[TEST 1] Verifying Espresso Machine buff (+1 max focus pip & prop visibility)...")
	game_mgr.start_new_game()

	var desk_scene: PackedScene = preload("res://scenes/desk/DeskView.tscn")
	var desk_instance = desk_scene.instantiate()
	desk_instance.name = "DeskView"
	add_child(desk_instance)

	assert(desk_instance._get_max_focus() == 4, "Initial max focus must be 4")
	assert(desk_instance.prop_espresso_machine != null, "PropEspressoMachine node must exist")
	assert(desk_instance.prop_espresso_machine.visible == false, "Prop must initially be hidden")

	# Unlock Espresso Machine
	game_mgr.event_flags["FLAG_EQUIP_ESPRESSO_MACHINE"] = true
	game_mgr.notify_stats_changed()

	assert(desk_instance._get_max_focus() == 5, "Max focus must expand to 5 with Espresso Machine")
	assert(desk_instance.prop_espresso_machine.visible == true, "Espresso machine desk prop must be visible")

	desk_instance.queue_free()
	print("  -> Espresso Machine successfully expanded max focus to 5 and revealed desk prop.")
	print("  [PASS] Test 1: Espresso Machine Buff verified.\n")
	passed_tests += 1


func test_test_2_investment_dividends() -> void:
	print("[TEST 2] Verifying Panama Shell holding generates +4% daily dividend on offshore wealth...")
	game_mgr.start_new_game()
	game_mgr.personal_wealth = 100000
	game_mgr.event_flags["FLAG_INVEST_PANAMA_SHELL"] = true

	game_mgr.advance_day()

	assert(game_mgr.personal_wealth == 104000, "Personal wealth must rise from $100K to $104K (+4%%), got: %d" % game_mgr.personal_wealth)

	print("  -> Daily turnover credited +$4,000 dividend to offshore funds.")
	print("  [PASS] Test 2: Investment Dividends verified.\n")
	passed_tests += 1


func test_test_3_save_load_persistence() -> void:
	print("[TEST 3] Verifying Dictaphone unlock persists across save/load lifecycle...")
	game_mgr.start_new_game()
	game_mgr.event_flags["FLAG_EQUIP_DICTAPHONE"] = true

	var slot_id := "test_black_market"
	var save_ok: bool = save_mgr.save_game(slot_id)
	assert(save_ok, "Save must succeed")

	# Clear flags
	game_mgr.event_flags.clear()
	assert(not game_mgr.event_flags.has("FLAG_EQUIP_DICTAPHONE"), "Flags must be cleared")

	# Load game
	var load_ok: bool = save_mgr.load_game(slot_id)
	assert(load_ok, "Load must succeed")
	assert(game_mgr.event_flags.get("FLAG_EQUIP_DICTAPHONE", false) == true, "Dictaphone flag must be restored")

	var desk_scene: PackedScene = preload("res://scenes/desk/DeskView.tscn")
	var desk_instance = desk_scene.instantiate()
	desk_instance.name = "DeskView"
	add_child(desk_instance)

	assert(desk_instance.prop_dictaphone != null, "PropDictaphone node must exist")
	assert(desk_instance.prop_dictaphone.visible == true, "Dictaphone prop must be visible on loaded desk")

	desk_instance.queue_free()
	save_mgr.delete_save(slot_id)

	print("  -> Dictaphone black market upgrade reliably persisted across save/load.")
	print("  [PASS] Test 3: Save/Load Persistence verified.\n")
	passed_tests += 1
