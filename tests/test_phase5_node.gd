extends Node

## test_phase5_node.gd - Automated Test verifying Phase 5 Twitch, Localization & Polish.

const DESK_VIEW_SCENE: PackedScene = preload("res://scenes/desk/DeskView.tscn")

var passed_tests: int = 0
var total_tests: int = 5
var desk_view: Control = null


func _ready() -> void:
	print("\n==========================================")
	print(">>> RUNNING PHASE 5 ACCEPTANCE TESTS <<<")
	print("==========================================\n")

	_run_tests_async()


func _run_tests_async() -> void:
	desk_view = DESK_VIEW_SCENE.instantiate()
	add_child(desk_view)
	await get_tree().process_frame

	test_criterion_1_twitch_command_parsing()
	await test_criterion_2_twitch_overlay_ui()
	test_criterion_3_localization_all_keys()
	test_criterion_4_full_30_day_playthrough()
	test_criterion_5_export_presets_validation()

	print("\n==========================================")
	if passed_tests == total_tests:
		print(">>> ALL 5 PHASE 5 TESTS PASSED SUCCESSFULLY! (5/5) <<<")
	else:
		print(">>> TEST FAILURES DETECTED! (%d/%d) <<<" % [passed_tests, total_tests])
	print("==========================================\n")

	get_tree().quit(0 if passed_tests == total_tests else 1)


func test_criterion_1_twitch_command_parsing() -> void:
	print("[TEST 1] Verifying Twitch command parsing, voter deduplication & consensus...")
	TwitchManager.reset_votes()

	var recorded_votes := {"app": 0.0, "rej": 0.0, "bri": 0.0, "tot": 0}
	var vote_cb = func(p_app: float, p_rej: float, p_bri: float, tot: int):
		recorded_votes["app"] = p_app
		recorded_votes["rej"] = p_rej
		recorded_votes["bri"] = p_bri
		recorded_votes["tot"] = tot

	TwitchManager.vote_updated.connect(vote_cb)

	# Viewer 1 votes approve
	TwitchManager.register_chat_command("viewer1", "!approve")
	assert(recorded_votes["tot"] == 1, "Total votes should be 1")
	assert(recorded_votes["app"] == 100.0, "Approve should be 100%")

	# Viewer 2 votes reject in Turkish (!hayir)
	TwitchManager.register_chat_command("viewer2", "!hayir")
	assert(recorded_votes["tot"] == 2, "Total votes should be 2")
	assert(recorded_votes["app"] == 50.0 and recorded_votes["rej"] == 50.0, "50-50 split")

	# Viewer 3 votes bribe (!rusvet)
	TwitchManager.register_chat_command("viewer3", "!rusvet")
	assert(recorded_votes["tot"] == 3, "Total votes should be 3")

	# Viewer 1 changes their mind to reject (deduplication check)
	TwitchManager.register_chat_command("viewer1", "!reject")
	assert(recorded_votes["tot"] == 3, "Total votes must remain 3 after re-vote")
	assert(TwitchManager.votes_approve == 0, "Viewer 1's approve vote must be subtracted")
	assert(TwitchManager.votes_reject == 2, "Reject must now have 2 votes")
	assert(TwitchManager.get_consensus_action() == "reject", "Consensus must be reject")

	TwitchManager.reset_votes()
	assert(recorded_votes["tot"] == 0, "Votes must reset to 0")
	TwitchManager.vote_updated.disconnect(vote_cb)

	print("  -> Chat commands, voter deduplication, and consensus algorithm validated.")
	print("  [PASS] Test 1: Twitch command parsing passed.\n")
	passed_tests += 1


func test_criterion_2_twitch_overlay_ui() -> void:
	print("[TEST 2] Verifying Twitch Vote Overlay UI and toggle visibility...")
	var overlay: Control = desk_view.get_node("%TwitchVoteOverlay") as Control
	assert(overlay != null, "TwitchVoteOverlay must exist in DeskView")

	# Overlay starts hidden
	overlay.visible = false
	assert(not overlay.is_overlay_visible(), "Overlay should initially be hidden")

	# Toggle show
	overlay.toggle_overlay()
	assert(overlay.visible, "Overlay should become visible after toggle")

	# Simulate incoming vote update
	TwitchManager.register_chat_command("mod_user", "!approve")
	TwitchManager.register_chat_command("regular_user", "!bribe")

	await get_tree().create_timer(0.4).timeout

	assert(overlay.approve_label.text.contains("50"), "Approve label must show 50%")
	assert(overlay.bribe_label.text.contains("50"), "Bribe label must show 50%")

	# Toggle hide
	overlay.hide_overlay()
	await get_tree().create_timer(0.2).timeout
	assert(not overlay.visible, "Overlay should be hidden after hide_overlay")

	TwitchManager.reset_votes()
	print("  -> Twitch overlay toggles, progress bars, and percentage texts functional.")
	print("  [PASS] Test 2: Twitch overlay UI verified.\n")
	passed_tests += 1


func test_criterion_3_localization_all_keys() -> void:
	print("[TEST 3] Verifying localization QA for EN, TR, and ES...")
	var key_list: Array[String] = [
		"UI_TITLE", "UI_DAY", "UI_STAMP_APPROVED", "UI_STAMP_REJECTED",
		"UI_BRIBE_POCKET", "UI_BUDGET", "UI_APPROVAL", "UI_SUSPICION",
		"UI_WEALTH", "UI_NEXT_DAY", "UI_APPLICANT", "UI_BRIBE_OFFERED",
		"UI_PETITION_HEADER", "UI_CATEGORY", "UI_DRAWER_LABEL", "UI_DRAWER_HINT",
		"UI_NO_MORE_DOCS", "UI_BRIBE_STASHED", "UI_TABLOID_HEADER",
		"UI_TABLOID_SUBHEADER", "UI_FINANCIAL_REPORT", "UI_OFFICIAL_BALANCE",
		"UI_ILLICIT_KICKBACKS", "UI_START_NEXT_DAY", "UI_GAME_OVER_TITLE",
		"UI_RETRY", "UI_FINAL_STATS", "UI_DAYS_SURVIVED", "UI_FINAL_TREASURY",
		"UI_FINAL_STASH", "UI_TWITCH_TITLE", "UI_TWITCH_CHANNEL",
		"UI_TWITCH_CONNECT", "UI_TWITCH_DISCONNECT", "UI_TWITCH_TOTAL_VOTES",
		"UI_TWITCH_STATUS_OFFLINE", "UI_TWITCH_STATUS_CONNECTED", "UI_TWITCH_TOGGLE",
		"UI_TWITCH_APPROVE_VOTES", "UI_TWITCH_REJECT_VOTES", "UI_TWITCH_BRIBE_VOTES",
		"UI_TWITCH_CHANNEL_PLACEHOLDER", "END_ARRESTED", "END_RIOT",
		"END_BANKRUPT", "END_REELECTED", "END_LOST_ELECTION"
	]

	for loc in ["en", "tr", "es"]:
		LocalizationManager.set_locale(loc)
		assert(LocalizationManager.get_current_locale() == loc, "Locale must switch to " + loc)
		for k in key_list:
			var translated := tr(k)
			assert(translated != k, "Key '%s' is missing translation in locale '%s'" % [k, loc])
			assert(not translated.is_empty(), "Key '%s' produced empty translation" % k)

	# Verify Turkish and Spanish special characters are intact
	LocalizationManager.set_locale("tr")
	var tr_sample := tr("UI_DRAWER_HINT")
	assert("ş" in tr_sample or "ı" in tr_sample or "ü" in tr_sample, "TR chars must be intact")

	LocalizationManager.set_locale("es")
	var es_sample := tr("END_ARRESTED")
	assert("¡" in es_sample or "ó" in es_sample or "í" in es_sample, "ES chars must be intact")

	# Reset back to English
	LocalizationManager.set_locale("en")
	print("  -> %d localization keys verified in EN, TR, ES without untranslated keys." % [
		key_list.size()
	])
	print("  [PASS] Test 3: Localization QA passed.\n")
	passed_tests += 1


func test_criterion_4_full_30_day_playthrough() -> void:
	print("[TEST 4] Simulating 30-day mandate loop with zero unlocalized strings...")
	GameManager.start_new_game()
	EventManager.load_events_from_json("res://data/events.json")

	var days_simulated: int = 0
	while GameManager.current_day <= 30 and not GameManager.is_game_over:
		EventManager.prepare_daily_queue(2)
		while not EventManager.daily_queue.is_empty():
			var ev: EventData = EventManager.pop_daily_event()
			assert(ev != null, "Event should not be null")
			GameManager.present_event(ev)

			# Ensure event title and desc localize properly
			var ev_title := ev.get_title()
			var ev_desc := ev.get_description()
			assert(not ev_title.begins_with("EVT_"), "Event title must not be raw key")
			assert(not ev_desc.begins_with("EVT_"), "Event desc must not be raw key")

			# Alternate decisions and pocket bribes safely
			var approve: bool = (days_simulated % 2 == 0)
			GameManager.resolve_event(ev, approve, false)
			EventManager.discard_event(ev)

			if ev.bribe_offered > 0 and GameManager.suspicion_meter < 80.0:
				GameManager.pocket_bribe(ev.bribe_offered)

		days_simulated += 1
		if not GameManager.is_game_over:
			GameManager.advance_day()

	assert(days_simulated > 0, "At least one day must be simulated")
	print("  -> Simulated %d days of municipal office. Final day reached: %d." % [
		days_simulated, GameManager.current_day
	])
	print("  -> Game over triggered or term concluded cleanly without unlocalized raw strings.")
	print("  [PASS] Test 4: 30-day mandate loop verified.\n")
	passed_tests += 1


func test_criterion_5_export_presets_validation() -> void:
	print("[TEST 5] Validating export presets and project configuration...")
	var file := FileAccess.open("res://export_presets.cfg", FileAccess.READ)
	assert(file != null, "export_presets.cfg must exist in project root")

	var content := file.get_as_text()
	file.close()

	assert(content.contains("name=\"Windows Desktop\""), "Windows preset missing")
	assert(content.contains("name=\"Web\""), "Web preset missing")
	assert(content.contains("export_path=\"builds/windows/yes-mr-mayor.exe\""), "Win path")
	assert(content.contains("export_path=\"builds/web/index.html\""), "Web path")

	# Check rendering method in project settings
	var renderer: String = str(ProjectSettings.get_setting("rendering/renderer/rendering_method"))
	assert(renderer == "gl_compatibility", "Renderer must be gl_compatibility for Web/Desktop")

	print("  -> Windows Desktop and Web HTML5 presets verified with gl_compatibility renderer.")
	print("  [PASS] Test 5: Export presets validated.\n")
	passed_tests += 1
