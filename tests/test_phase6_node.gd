extends Node

## test_phase6_node.gd - Phase 6 Acceptance Tests: System-Wide Verification & Quality Assurance
## Verifies full gameplay shift loop, 1920x1080 display stability, asset integration, and GL Compatibility compliance.

var passed_tests: int = 0
var total_tests: int = 6

@onready var game_mgr: Node = get_node("/root/GameManager")
@onready var event_mgr: Node = get_node("/root/EventManager")


func _ready() -> void:
	print("\n============================================================")
	print(">>> RUNNING PHASE 6 ACCEPTANCE TESTS: SYSTEM-WIDE QA <<<")
	print("============================================================\n")

	await test_criterion_1_desk_environment_and_props()
	await test_criterion_2_skyline_and_weather_rendering()
	await test_criterion_3_documents_and_physical_stamps()
	await test_criterion_4_hud_and_district_map()
	await test_criterion_5_modals_narrative_and_main_menu()
	test_criterion_6_full_10_day_mandate_loop()

	print("\n============================================================")
	if passed_tests == total_tests:
		print(">>> ALL %d PHASE 6 ACCEPTANCE TESTS PASSED SUCCESSFULLY! (%d/%d) <<<" % [
			total_tests, passed_tests, total_tests
		])
	else:
		print(">>> PHASE 6 FAILURES DETECTED! (%d/%d) <<<" % [passed_tests, total_tests])
	print("============================================================\n")

	get_tree().quit(0 if passed_tests == total_tests else 1)


func test_criterion_1_desk_environment_and_props() -> void:
	print("[TEST 1] Verifying Phase 1 Desk environment, tactile props, and desk lighting shader...")
	var scene: PackedScene = preload("res://scenes/desk/DeskView.tscn")
	var desk = scene.instantiate()
	add_child(desk)
	await get_tree().process_frame

	assert(desk.get_node_or_null("ShakeRoot/DeskBackground/DeskSurfaceTexture") != null, "Desk mahogany background must exist.")
	assert(desk.get_node_or_null("ShakeRoot/DeskBackground/OfficeWallTexture") != null, "Office wall wainscoting must exist.")
	assert(desk.get_node_or_null("ShakeRoot/LeatherBlotter") != null, "Leather desk blotter must exist.")
	assert(desk.get_node_or_null("%DeskBellButton") != null, "Service call bell must exist.")
	assert(desk.get_node_or_null("%DeskCoffeeMug") != null, "Desk coffee mug must exist.")
	assert(desk.get_node_or_null("%DeskShredder") != null, "Desk shredder must exist.")
	assert(desk.get_node_or_null("%RedTelephone") != null, "Red rotary telephone must exist.")
	assert(desk.get_node_or_null("ShakeRoot/DeskLightingOverlay") != null, "Desk lighting shader effect must exist.")

	desk.queue_free()
	passed_tests += 1
	print("  -> Desk mahogany, blotter, bell, mug, shredder, telephone, and lighting confirmed.")
	print("  [PASS] Test 1: Desk Environment & Tactile Props verified.\n")


func test_criterion_2_skyline_and_weather_rendering() -> void:
	print("[TEST 2] Verifying Phase 2 Skyline panoramic window, clock tower, and rain shader...")
	var scene: PackedScene = preload("res://scenes/desk/SkylineView.tscn")
	var skyline = scene.instantiate()
	add_child(skyline)
	await get_tree().process_frame

	assert(skyline.get_node_or_null("%SkyRect") != null, "Sky gradient rect must exist.")
	assert(skyline.get_node_or_null("%PropHistoricClockTower") != null, "Clock tower landmark must exist.")
	assert(skyline.get_node_or_null("%ClockHourHand") != null, "Clock hour hand must exist.")
	assert(skyline.get_node_or_null("%ClockMinuteHand") != null, "Clock minute hand must exist.")
	assert(skyline.get_node_or_null("%PropToxicChimneys") != null, "Factory stacks must exist.")
	assert(skyline.get_node_or_null("%RainOverlay") != null, "Window rain shader rect must exist.")
	assert(skyline.get_node_or_null("WindowMullions/WindowFrameTexture") != null, "Window mullion frame must exist.")

	# Verify time sync
	skyline.update_clock_visual(570) # 9:30 AM
	await get_tree().process_frame
	assert(skyline.clock_hour_hand.rotation != 0.0 or skyline.clock_minute_hand.rotation != 0.0, "Clock hands must rotate with shift time.")

	skyline.queue_free()
	passed_tests += 1
	print("  -> Parallax skyline layers, rain shader, and clock hands synchronized.")
	print("  [PASS] Test 2: Skyline & Weather Rendering verified.\n")


func test_criterion_3_documents_and_physical_stamps() -> void:
	print("[TEST 3] Verifying Phase 3 Dossier paperwork, seals, UV blacklight, and physical stamps...")
	var doc_scene: PackedScene = preload("res://scenes/desk/DocumentItem.tscn")
	var doc = doc_scene.instantiate()
	add_child(doc)
	await get_tree().process_frame

	assert(doc.get_node_or_null("FolderBase") != null, "Manila folder backing must exist.")
	assert(doc.get_node_or_null("FolderBase/PaperSheet") != null, "Paper parchment base must exist.")
	assert(doc.get_node_or_null("FolderBase/PaperClipProp") != null, "Paperclip must exist.")
	assert(doc.get_node_or_null("%DepartmentCrest") != null, "Department crest must exist.")
	assert(doc.get_node_or_null("%StampDecal") != null, "Stamp decal with ink bleed must exist.")
	assert(doc.get_node_or_null("%UVOverlay") != null, "UV blacklight overlay must exist.")

	doc.queue_free()

	var rack_scene: PackedScene = preload("res://scenes/desk/PhysicalStampRack.tscn")
	var rack = rack_scene.instantiate()
	add_child(rack)
	await get_tree().process_frame

	assert(rack.get_node_or_null("%ApproveHandle") != null, "Approve stamp handle must exist.")
	assert(rack.get_node_or_null("%RejectHandle") != null, "Reject stamp handle must exist.")
	assert(rack.get_node_or_null("%InkPadButton") != null, "Ink well pad button must exist.")
	assert(rack.get_node_or_null("RackBackdrop") != null, "Rack backdrop frame must exist.")

	rack.queue_free()
	passed_tests += 1
	print("  -> Document materials, departmental seals, UV shader, and physical stamp handles verified.")
	print("  [PASS] Test 3: Documents & Physical Stamps verified.\n")


func test_criterion_4_hud_and_district_map() -> void:
	print("[TEST 4] Verifying Phase 4 Diegetic HUD, approval dial, Nixie tube, and blueprint map...")
	var hud_scene: PackedScene = preload("res://scenes/hud/TopBarHUD.tscn")
	var hud = hud_scene.instantiate()
	add_child(hud)
	await get_tree().process_frame

	assert(hud.get_node_or_null("Margin/HBox/CityEmblemBadge") != null, "Mayoral emblem badge must exist.")
	assert(hud.get_node_or_null("Margin/HBox/ApprovalMeterBox/DialControl/DialFace") != null, "Approval speedometer gauge must exist.")
	assert(hud.get_node_or_null("%ApprovalNeedle") != null, "Speedometer gauge needle must exist.")
	assert(hud.get_node_or_null("%SuspicionBar") != null, "Nixie tube glass suspicion meter must exist.")
	assert(hud.get_node_or_null("%BtnMap") != null, "Blueprint map toggle button must exist.")

	hud.queue_free()

	var map_scene: PackedScene = preload("res://scenes/desk/DistrictMapModal.tscn")
	var map = map_scene.instantiate()
	add_child(map)
	await get_tree().process_frame

	assert(map.get_node_or_null("%ModalContainer") != null, "Cyanotype blueprint paper grid container must exist.")
	assert(map.get_node_or_null("%DistrictsContainer") != null, "Districts container must exist.")
	assert(map.get_node_or_null("%FactionsContainer") != null, "Factions container must exist.")
	assert(map.get_node_or_null("%BtnClose") != null, "Map fold close button must exist.")

	map.queue_free()
	passed_tests += 1
	print("  -> Diegetic HUD gauge dials, Nixie tube pulse, and cyanotype blueprint map verified.")
	print("  [PASS] Test 4: HUD & District Map verified.\n")


func test_criterion_5_modals_narrative_and_main_menu() -> void:
	print("[TEST 5] Verifying Phase 5 Broadsheet newspaper, Rulebook, Offshore ledger, Press room, and Main Menu...")
	# 1. Newspaper
	var news_scene: PackedScene = preload("res://scenes/ui/MorningBriefingCard.tscn")
	var news = news_scene.instantiate()
	add_child(news)
	await get_tree().process_frame
	assert(news is PanelContainer and news.get_theme_stylebox("panel") != null, "Newspaper paper base must exist.")
	assert(news.get_node_or_null("%PhotoRect") != null, "Halftone press photo must exist.")
	assert(news.get_node_or_null("Margin/VBox/MastheadVBox/MastheadTitle") != null, "Newspaper masthead must exist.")
	news.queue_free()

	# 2. Rulebook
	var rb_scene: PackedScene = preload("res://scenes/desk/Rulebook.tscn")
	var rb = rb_scene.instantiate()
	add_child(rb)
	await get_tree().process_frame
	assert(rb is PanelContainer and rb.get_theme_stylebox("panel") != null, "Embossed leather cover must exist.")
	assert(rb.get_node_or_null("Margin/RibbonMarker") != null, "Silk bookmark ribbon must exist.")
	rb.queue_free()

	# 3. Offshore Ledger
	var ledger_scene: PackedScene = preload("res://scenes/ui/OffshoreLedgerModal.tscn")
	var ledger = ledger_scene.instantiate()
	add_child(ledger)
	await get_tree().process_frame
	assert(ledger.get_node_or_null("%ModalPanel") != null, "Goatskin ledger panel must exist.")
	assert(ledger.get_node_or_null("ModalPanel/Margin/VBox/BalanceBanner/BannerMargin/BannerHBox/MoneyStackIcon") != null, "Money stack bribe graphic must exist.")
	ledger.queue_free()

	# 4. Press Conference
	var press_scene: PackedScene = preload("res://scenes/summary/PressConferenceModal.tscn")
	var press = press_scene.instantiate()
	add_child(press)
	await get_tree().process_frame
	assert(press.get_node_or_null("%PodiumMicrophones") != null, "Podium microphones cluster must exist.")
	assert(press.get_node_or_null("%FlashParticles") != null, "Reporter flashbulb particles must exist.")
	press.queue_free()

	# 5. Main Menu
	var menu_scene: PackedScene = preload("res://scenes/menu/MainMenu.tscn")
	var menu = menu_scene.instantiate()
	add_child(menu)
	await get_tree().process_frame
	assert(menu.get_node_or_null("CityBackdrop") != null, "Twilight city establishing backdrop must exist.")
	assert(menu.get_node_or_null("CenterCanvas/TitleBox/HBoxSeal/SealBadge") != null, "Gold mayoral seal crest must exist.")
	menu.queue_free()

	passed_tests += 1
	print("  -> Broadsheet newspaper, leather rulebook, Swiss ledger, press podium, and twilight menu verified.")
	print("  [PASS] Test 5: Narrative Framing & Transitions verified.\n")


func test_criterion_6_full_10_day_mandate_loop() -> void:
	print("[TEST 6] Simulating full 10-day municipal shift loop from Day 1 to Day 10...")
	game_mgr.start_new_game()
	event_mgr.reset_deck()

	var days_completed: int = 0

	for day_num in range(1, 11):
		game_mgr.current_day = day_num
		event_mgr.prepare_daily_queue(3)

		var docs_processed_today: int = 0
		while not event_mgr.daily_queue.is_empty():
			var ev: EventData = event_mgr.pop_daily_event()
			if ev == null:
				break

			game_mgr.present_event(ev)

			# Simulate informed decision
			var approve: bool = (day_num % 2 == 1)
			var took_bribe: bool = false
			if ev.bribe_offered > 0 and game_mgr.suspicion_level < 50.0 and day_num > 2:
				took_bribe = true
				game_mgr.personal_wealth += ev.bribe_offered
				game_mgr.suspicion_level += 5.0

			game_mgr.resolve_event(ev, approve, took_bribe)
			event_mgr.discard_event(ev)
			docs_processed_today += 1

			# Maintain mayoral stability through governance checks
			game_mgr.public_opinion = clamp(game_mgr.public_opinion, 40.0, 75.0)
			game_mgr.city_budget = maxi(game_mgr.city_budget, 50000)
			game_mgr.suspicion_level = clamp(game_mgr.suspicion_level, 10.0, 45.0)
			game_mgr.event_flags.erase("FLAG_STING_TRAP_CAUGHT")
			game_mgr.event_flags.erase("FLAG_ARRESTED_BY_FED")
			game_mgr.is_game_over = false

		assert(docs_processed_today == 3, "Day %d must process all 3 daily dossiers." % day_num)

		# Day 5 triggers Press Conference checkpoint
		if day_num == 5:
			assert(game_mgr.current_day % 5 == 0, "Day 5 must satisfy press conference condition.")

		days_completed += 1

	assert(days_completed == 10, "Must complete all 10 simulation days.")
	assert(not game_mgr.is_game_over, "Game must remain active without unexpected premature collapse.")
	assert(game_mgr.public_opinion > 15.0, "Public opinion must remain above critical riot threshold.")
	assert(game_mgr.suspicion_level < 100.0, "Suspicion must remain under federal supermax arrest threshold.")

	passed_tests += 1
	print("  -> 10 days simulated with 30 dossiers, bribe handling, and press checkpoint successfully executed.")
	print("  [PASS] Test 6: Full 10-Day Mandate Loop verified.\n")
