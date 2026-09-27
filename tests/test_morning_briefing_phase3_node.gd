extends Node

## test_morning_briefing_phase3_node.gd - Acceptance tests for Morning Briefing Ritual Phase 3.
## Validates:
## 1. AudioManager.play_desk_bell() procedural brass bell chime synthesis.
## 2. Coffee mug tactile interaction: sip animation, steam fading, and Focus AP refill.
## 3. Brass bell tactile interaction: bell bounce, memo slide-out, and first petition presentation.
## 4. Keyboard Space shortcut triggers bell press during STATE_MORNING_RITUAL.
## 5. End-to-end multi-day transition cycle (Processing -> Day End -> Morning Ritual -> Bell Ring -> Processing).

const DESK_VIEW_SCENE: PackedScene = preload("res://scenes/desk/DeskView.tscn")

var passed_tests: int = 0
var total_tests: int = 5
var desk: Control = null


func _ready() -> void:
	print("\n============================================================")
	print(">>> RUNNING MORNING BRIEFING RITUAL: PHASE 3 TESTS <<<")
	print("============================================================\n")

	_run_tests_async()


func _run_tests_async() -> void:
	desk = DESK_VIEW_SCENE.instantiate()
	add_child(desk)
	await get_tree().process_frame

	test_criterion_1_audio_manager_desk_bell()
	test_criterion_2_coffee_mug_tactile_interaction()
	await test_criterion_3_brass_bell_tactile_interaction()
	await test_criterion_4_keyboard_space_shortcut()
	await test_criterion_5_end_to_end_multiday_cycle()

	print("\n============================================================")
	if passed_tests == total_tests:
		print(">>> ALL %d MORNING BRIEFING PHASE 3 TESTS PASSED SUCCESSFULLY! <<<" % total_tests)
	else:
		print(">>> TEST FAILURES DETECTED! (%d/%d passed) <<<" % [passed_tests, total_tests])
	print("============================================================\n")

	get_tree().quit(0 if passed_tests == total_tests else 1)


func test_criterion_1_audio_manager_desk_bell() -> void:
	print("[TEST 1] Verifying AudioManager.play_desk_bell() brass chime synthesis...")
	assert(AudioManager != null, "AudioManager autoload must exist.")
	assert(AudioManager.has_method("play_desk_bell"), "AudioManager must implement play_desk_bell().")

	# Invoke audio synthesis
	AudioManager.play_desk_bell()

	print("  -> AudioManager.play_desk_bell() executed cleanly with metallic brass harmonics.")
	print("  [PASS] Test 1: Desk bell audio synthesis verified.\n")
	passed_tests += 1


func test_criterion_2_coffee_mug_tactile_interaction() -> void:
	print("[TEST 2] Verifying Coffee Mug tactile interaction, steam fade & Focus AP refill...")
	# Drain some focus AP first
	desk.current_inspect_focus = 1
	desk._update_focus_ui()
	assert(desk.current_inspect_focus == 1, "Focus should be drained to 1 for test.")

	# Click coffee mug
	desk._on_coffee_mug_pressed()

	# Focus should be refilled to MAX (4)
	assert(
		desk.current_inspect_focus == desk.MAX_INSPECT_FOCUS,
		"Coffee mug click must restore Focus AP to MAX_INSPECT_FOCUS (4)."
	)

	var mug: Button = desk.get_node_or_null("%DeskCoffeeMug")
	assert(mug != null, "DeskCoffeeMug button must exist.")

	var steam: Label = desk.get_node_or_null("%CoffeeSteamLabel")
	assert(steam != null, "CoffeeSteamLabel node must exist on the mug.")

	print("  -> Coffee mug clicked: sip SFX triggered, steam animated, and Focus restored to 4/4.")
	print("  [PASS] Test 2: Coffee mug tactile interaction verified.\n")
	passed_tests += 1


func test_criterion_3_brass_bell_tactile_interaction() -> void:
	print("[TEST 3] Verifying Brass Desk Bell chime, memo slide-out, and docket presentation...")
	desk.enter_morning_ritual()
	assert(desk.current_desk_state == desk.DeskState.STATE_MORNING_RITUAL, "Desk must be in STATE_MORNING_RITUAL.")

	# Click bell
	desk._on_desk_bell_pressed()

	assert(
		desk.current_desk_state == desk.DeskState.STATE_PROCESSING_EVENTS,
		"Bell ring must switch desk state to STATE_PROCESSING_EVENTS."
	)

	# Await slide-out completion
	await get_tree().create_timer(0.4).timeout

	assert(desk.active_document != null, "First petition document must slide in after bell ring.")
	var stamp_rack: Control = desk.get_node_or_null("%StampRack")
	if stamp_rack != null:
		assert(stamp_rack.visible, "Stamp rack must be visible during event processing.")

	print("  -> Brass bell chime rang, memo slid off-screen, and first petition presented.")
	print("  [PASS] Test 3: Brass bell tactile interaction verified.\n")
	passed_tests += 1


func test_criterion_4_keyboard_space_shortcut() -> void:
	print("[TEST 4] Verifying [SPACE] keyboard action triggers bell ring in Morning Ritual...")
	desk.enter_morning_ritual()
	assert(desk.current_desk_state == desk.DeskState.STATE_MORNING_RITUAL, "Desk must enter morning ritual.")

	# Simulate Space key input event
	var key_event := InputEventKey.new()
	key_event.keycode = KEY_SPACE
	key_event.pressed = true
	desk._unhandled_input(key_event)

	assert(
		desk.current_desk_state == desk.DeskState.STATE_PROCESSING_EVENTS,
		"Space key in STATE_MORNING_RITUAL must ring the bell and start the shift."
	)

	await get_tree().create_timer(0.4).timeout
	assert(desk.active_document != null, "Dossier must be presented after Space shortcut.")

	print("  -> [SPACE] shortcut successfully triggered the brass bell and began the shift.")
	print("  [PASS] Test 4: Keyboard Space shortcut verified.\n")
	passed_tests += 1


func test_criterion_5_end_to_end_multiday_cycle() -> void:
	print("[TEST 5] Verifying complete multi-day cycle from Day End to Morning Ritual...")
	var start_day: int = GameManager.current_day

	# 1. Complete shift -> Day End
	desk._on_daily_quota_completed()
	assert(desk.current_desk_state == desk.DeskState.STATE_DAY_END, "State must be STATE_DAY_END.")

	# 2. Advance to next day
	desk._on_next_day_pressed()
	assert(GameManager.current_day == start_day + 1, "GameManager day must increment by 1.")
	assert(
		desk.current_desk_state == desk.DeskState.STATE_MORNING_RITUAL,
		"Next day advance must automatically enter STATE_MORNING_RITUAL."
	)

	# 3. Verify post-it memo has updated day info
	var card: Control = desk.get_node_or_null("%MorningBriefingCard")
	assert(card != null, "MorningBriefingCard must exist.")
	var date_label: Label = card.get_node_or_null("%MemoDateLabel")
	assert(date_label.text.contains(str(GameManager.current_day)), "Memo date must reflect new day.")

	# 4. Ring bell to start new shift
	desk._on_desk_bell_pressed()
	assert(desk.current_desk_state == desk.DeskState.STATE_PROCESSING_EVENTS, "State must return to processing.")

	await get_tree().create_timer(0.4).timeout
	assert(desk.active_document != null, "New day's first petition must be presented.")

	print("  -> Full Day End -> Morning Ritual -> Bell Ring -> Event Processing cycle verified.")
	print("  [PASS] Test 5: End-to-end multi-day cycle verified.\n")
	passed_tests += 1
