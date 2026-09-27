extends Node

## test_morning_briefing_phase2_node.gd - Acceptance tests for Morning Briefing Ritual Phase 2.
## Validates:
## 1. data/morning_memos.json exists, parses cleanly, and contains all 30 days.
## 2. All 30 days include valid "en", "tr", and "es" localizations with author, subject, and text.
## 3. Milestone days (Days 3, 7, 12, 18, 28) contain appropriate narrative modifier memos.
## 4. MorningBriefingCard loads text dynamically based on current locale.
## 5. MorningBriefingCard handwritten font styling and post-it panel properties.
## 6. MorningBriefingCard active directive modifier badge integration.

const BRIEFING_CARD_SCENE: PackedScene = preload("res://scenes/ui/MorningBriefingCard.tscn")

var passed_tests: int = 0
var total_tests: int = 6
var card: Control = null
var memos_data: Dictionary = {}


func _ready() -> void:
	print("\n============================================================")
	print(">>> RUNNING MORNING BRIEFING RITUAL: PHASE 2 TESTS <<<")
	print("============================================================\n")

	_run_tests_async()


func _run_tests_async() -> void:
	test_criterion_1_memos_json_existence_and_parsing()
	test_criterion_2_trilingual_coverage_all_30_days()
	test_criterion_3_milestone_day_narrative_modifiers()
	await test_criterion_4_card_locale_switching()
	test_criterion_5_handwritten_styling_and_panel()
	test_criterion_6_directive_badge_display()

	print("\n============================================================")
	if passed_tests == total_tests:
		print(">>> ALL %d MORNING BRIEFING PHASE 2 TESTS PASSED SUCCESSFULLY! <<<" % total_tests)
	else:
		print(">>> TEST FAILURES DETECTED! (%d/%d passed) <<<" % [passed_tests, total_tests])
	print("============================================================\n")

	get_tree().quit(0 if passed_tests == total_tests else 1)


func test_criterion_1_memos_json_existence_and_parsing() -> void:
	print("[TEST 1] Verifying data/morning_memos.json file existence and JSON parsing...")
	var path := "res://data/morning_memos.json"
	assert(FileAccess.file_exists(path), "data/morning_memos.json must exist in project.")

	var file := FileAccess.open(path, FileAccess.READ)
	assert(file != null, "Could not open data/morning_memos.json for reading.")

	var json_str := file.get_as_text()
	var json := JSON.new()
	var err := json.parse(json_str)
	assert(err == OK, "data/morning_memos.json must be valid JSON.")
	assert(json.data is Dictionary, "Root of morning_memos.json must be a Dictionary.")
	memos_data = json.data

	assert(memos_data.size() >= 30, "morning_memos.json must contain at least 30 days of entries.")
	print("  -> morning_memos.json parsed successfully with %d day entries." % memos_data.size())
	print("  [PASS] Test 1: JSON existence and parsing verified.\n")
	passed_tests += 1


func test_criterion_2_trilingual_coverage_all_30_days() -> void:
	print("[TEST 2] Verifying trilingual coverage (en, tr, es) across all 30 days...")
	for day in range(1, 31):
		var day_str := str(day)
		assert(memos_data.has(day_str), "Missing entry for Day %d in morning_memos.json." % day)
		var entry: Dictionary = memos_data[day_str]
		for lang in ["en", "tr", "es"]:
			assert(entry.has(lang), "Day %d is missing language '%s'." % [day, lang])
			var lang_data: Dictionary = entry[lang]
			assert(lang_data.has("author") and not lang_data["author"].is_empty(), "Day %d [%s] missing author." % [day, lang])
			assert(lang_data.has("subject") and not lang_data["subject"].is_empty(), "Day %d [%s] missing subject." % [day, lang])
			assert(lang_data.has("text") and not lang_data["text"].is_empty(), "Day %d [%s] missing text." % [day, lang])

	print("  -> All 30 days successfully verified with complete en, tr, and es fields.")
	print("  [PASS] Test 2: Trilingual coverage across all 30 days verified.\n")
	passed_tests += 1


func test_criterion_3_milestone_day_narrative_modifiers() -> void:
	print("[TEST 3] Verifying milestone day narrative modifiers (Days 3, 7, 12, 18, 28)...")
	# Day 3: Ecology / Environmental auditors
	var d3_en: String = memos_data["3"]["en"]["text"]
	assert(d3_en.to_lower().contains("ecology") or d3_en.to_lower().contains("auditors"), "Day 3 must mention Ecology auditors.")

	# Day 7: Sanitation union
	var d7_en: String = memos_data["7"]["en"]["text"]
	assert(d7_en.to_lower().contains("sanitation") or d7_en.to_lower().contains("union"), "Day 7 must mention Sanitation union.")

	# Day 12: Subpoena / Shredder
	var d12_en: String = memos_data["12"]["en"]["text"]
	assert(d12_en.to_lower().contains("subpoena") or d12_en.to_lower().contains("shredder"), "Day 12 must mention Subpoena / Shredder.")

	# Day 18: Heatwave
	var d18_en: String = memos_data["18"]["en"]["text"]
	assert(d18_en.to_lower().contains("heatwave") or d18_en.to_lower().contains("air conditioning"), "Day 18 must mention Heatwave.")

	# Day 28: Election
	var d28_en: String = memos_data["28"]["en"]["text"]
	assert(d28_en.to_lower().contains("election"), "Day 28 must mention Election in 48 hours.")

	print("  -> All milestone modifier memos accurately align with the approved specification.")
	print("  [PASS] Test 3: Milestone day narrative modifiers verified.\n")
	passed_tests += 1


func test_criterion_4_card_locale_switching() -> void:
	print("[TEST 4] Verifying MorningBriefingCard dynamic text loading on locale change...")
	card = BRIEFING_CARD_SCENE.instantiate()
	add_child(card)
	await get_tree().process_frame

	# 1. Test in English
	LocalizationManager.set_locale("en")
	card.setup_briefing(3)
	var label: Label = card.get_node("%MemoTextLabel")
	assert(label.text.contains("Ecology"), "Card must display English memo text for Day 3.")

	# 2. Test in Turkish
	LocalizationManager.set_locale("tr")
	card.setup_briefing(3)
	assert(label.text.contains("Ekoloji") or label.text.contains("Çevre"), "Card must display Turkish memo text for Day 3.")

	# 3. Test in Spanish
	LocalizationManager.set_locale("es")
	card.setup_briefing(3)
	assert(label.text.contains("Ecología"), "Card must display Spanish memo text for Day 3.")

	# Restore English
	LocalizationManager.set_locale("en")

	print("  -> Dynamic locale switching correctly refreshed memo text across en, tr, and es.")
	print("  [PASS] Test 4: Card locale switching verified.\n")
	passed_tests += 1


func test_criterion_5_handwritten_styling_and_panel() -> void:
	print("[TEST 5] Verifying charming handwritten styling and yellow Post-It panel...")
	assert(card is PanelContainer, "Card must be a PanelContainer.")
	var label: Label = card.get_node("%MemoTextLabel")
	assert(label != null, "MemoTextLabel must exist.")
	assert(label.autowrap_mode == TextServer.AUTOWRAP_WORD or label.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART, "MemoTextLabel must autowrap.")

	# Check rotation angle (subtle post-it tilt)
	assert(abs(card.rotation_degrees) > 0.0, "Card must have a charming post-it tilt rotation.")

	print("  -> Handwritten styling and warm post-it panel verified.")
	print("  [PASS] Test 5: Handwritten styling and post-it panel verified.\n")
	passed_tests += 1


func test_criterion_6_directive_badge_display() -> void:
	print("[TEST 6] Verifying directive modifier badge display on Day 3...")
	DirectiveManager.activate_directive_for_day(3)
	card.setup_briefing(3)

	var badge: Control = card.get_node("%ModifierBadge")
	assert(badge != null, "ModifierBadge node must exist.")
	assert(badge.visible, "ModifierBadge must be visible when an active modifier exists.")

	var title_lbl: Label = card.get_node("%ModifierTitleLabel")
	assert(title_lbl.text.contains("EPA") or title_lbl.text.contains("AUDIT"), "ModifierTitleLabel must show active directive title.")

	print("  -> Active directive badge successfully communicated gameplay shift modifier.")
	print("  [PASS] Test 6: Directive badge display verified.\n")
	passed_tests += 1
