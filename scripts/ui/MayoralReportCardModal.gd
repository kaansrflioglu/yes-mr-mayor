extends PanelContainer

## MayoralReportCardModal.gd - Archival dossier post-mortem scorecard
## Displays civic performance letter grade (S-F), historic title,
## district prosperity breakdown, 10-year city epilogue, and mandate restart.

signal restart_requested
signal main_menu_requested

@onready var title_label: Label = %TitleLabel
@onready var historic_title_label: Label = %HistoricTitleLabel
@onready var grade_badge: PanelContainer = %GradeBadge
@onready var grade_label: Label = %GradeLabel
@onready var narrative_label: Label = %NarrativeLabel
@onready var epilogue_label: Label = %EpilogueLabel if has_node("%EpilogueLabel") else null
@onready var days_survived_label: Label = %DaysSurvivedLabel
@onready var treasury_label: Label = %TreasuryLabel
@onready var stash_label: Label = %StashLabel
@onready var opinion_label: Label = %OpinionLabel if has_node("%OpinionLabel") else null
@onready var suspicion_label: Label = %SuspicionLabel if has_node("%SuspicionLabel") else null
@onready var district_list: VBoxContainer = %DistrictList if has_node("%DistrictList") else null
@onready var btn_restart: Button = %BtnRestart
@onready var btn_main_menu: Button = %BtnMainMenu if has_node("%BtnMainMenu") else null


func _ready() -> void:
	if btn_restart != null:
		btn_restart.pressed.connect(func(): restart_requested.emit())
	if btn_main_menu != null:
		btn_main_menu.pressed.connect(func(): main_menu_requested.emit())


## Setup and populate the scorecard with an evaluation dictionary
func setup(eval_dict: Dictionary) -> void:
	show_report_card(eval_dict)


## Polymorphic entry point matching GameOverModal
func show_game_over(reason_key: String) -> void:
	var eval: Dictionary = {}
	if Engine.has_singleton("EndingsManager") or has_node("/root/EndingsManager"):
		var em = get_node_or_null("/root/EndingsManager")
		if em != null and em.has_method("evaluate_mandate"):
			eval = em.evaluate_mandate()

	if eval.is_empty():
		eval = {
			"end_key": reason_key,
			"letter_grade": "F" if reason_key in ["END_ARRESTED", "END_RIOT"] else "C",
			"title_key": "TITLE_CONVICTED_FELON" if reason_key == "END_ARRESTED" else "TITLE_OUSTED_TYRANT",
			"epilogue_text": tr(reason_key),
			"stats": {
				"budget": GameManager.city_budget,
				"wealth": GameManager.personal_wealth,
				"opinion": GameManager.public_opinion,
				"suspicion": GameManager.suspicion_level,
				"day": GameManager.current_day
			}
		}
	elif not reason_key.is_empty() and eval.get("end_key", "") != reason_key:
		eval["end_key"] = reason_key

	show_report_card(eval)


## Displays the official archival scorecard and starts grade stamp animations
func show_report_card(eval_dict: Dictionary) -> void:
	visible = true

	var letter_grade: String = str(eval_dict.get("letter_grade", "C"))
	var title_key: String = str(eval_dict.get("title_key", "TITLE_CIVIC_SAINT"))
	var epilogue_text: String = str(eval_dict.get("epilogue_text", ""))
	var stats: Dictionary = eval_dict.get("stats", {})

	# Header & Title
	title_label.text = tr("REPORT_CARD_HEADER")
	var loc_title: String = tr(title_key)
	if loc_title == title_key:
		loc_title = title_key.replace("TITLE_", "").replace("_", " ").capitalize()
	historic_title_label.text = "« " + loc_title + " »"

	# Grade Stamp
	grade_label.text = letter_grade
	var grade_color: Color = Color(0.95, 0.78, 0.22, 1.0)
	if EndingsManager != null and EndingsManager.GRADE_COLORS.has(letter_grade):
		grade_color = EndingsManager.GRADE_COLORS[letter_grade]
	grade_label.set("theme_override_colors/font_color", grade_color)
	if grade_badge != null:
		var sb: StyleBoxFlat = grade_badge.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		if sb != null:
			sb.border_color = grade_color
			grade_badge.add_theme_stylebox_override("panel", sb)

	# Epilogue & Narrative
	if epilogue_text.is_empty():
		epilogue_text = tr(str(eval_dict.get("end_key", "")))
	narrative_label.text = epilogue_text
	if epilogue_label != null:
		epilogue_label.text = epilogue_text

	# Telemetry Statistics
	var day_val: int = int(stats.get("day", GameManager.current_day))
	var budget_val: int = int(stats.get("budget", GameManager.city_budget))
	var wealth_val: int = int(stats.get("wealth", GameManager.personal_wealth))
	var opinion_val: float = float(stats.get("opinion", GameManager.public_opinion))
	var susp_val: float = float(stats.get("suspicion", GameManager.suspicion_level))

	days_survived_label.text = "%d / %d Days" % [mini(day_val, GameManager.MAX_DAYS), GameManager.MAX_DAYS]
	treasury_label.text = _format_money(budget_val)
	treasury_label.set("theme_override_colors/font_color", Color(0.2, 0.8, 0.4) if budget_val >= 0 else Color(0.9, 0.3, 0.2))

	stash_label.text = _format_money(wealth_val)
	stash_label.set("theme_override_colors/font_color", Color(0.95, 0.8, 0.2) if wealth_val > 0 else Color(0.7, 0.7, 0.7))

	if opinion_label != null:
		opinion_label.text = "%.1f%%" % opinion_val
		opinion_label.set("theme_override_colors/font_color", Color(0.2, 0.8, 0.4) if opinion_val >= 50.0 else Color(0.9, 0.3, 0.2))

	if suspicion_label != null:
		suspicion_label.text = "%.1f%%" % susp_val
		suspicion_label.set("theme_override_colors/font_color", Color(0.9, 0.3, 0.2) if susp_val >= 60.0 else Color(0.2, 0.8, 0.4))

	# Populate District Breakdown
	_populate_districts(eval_dict.get("districts", {}))

	# Buttons
	if btn_restart != null:
		btn_restart.text = tr("REPORT_CARD_RESTART")
	if btn_main_menu != null:
		btn_main_menu.text = tr("REPORT_CARD_MAIN_MENU")

	_animate_entrance()


func _populate_districts(districts: Dictionary) -> void:
	if district_list == null:
		return

	for child in district_list.get_children():
		child.queue_free()

	for d_id in districts.keys():
		var data: Dictionary = districts[d_id]
		var d_name: String = tr(str(data.get("name_key", d_id)))
		var prosp: float = float(data.get("prosperity", 50.0))

		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var name_lbl := Label.new()
		name_lbl.text = "• " + d_name
		name_lbl.custom_minimum_size = Vector2(160, 0)
		name_lbl.add_theme_font_size_override("font_size", 13)
		name_lbl.set("theme_override_colors/font_color", Color(0.8, 0.85, 0.9))
		row.add_child(name_lbl)

		var bar := ProgressBar.new()
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.custom_minimum_size = Vector2(100, 14)
		bar.show_percentage = false
		bar.min_value = 0.0
		bar.max_value = 100.0
		bar.value = prosp
		row.add_child(bar)

		var val_lbl := Label.new()
		val_lbl.text = " %.0f%%" % prosp
		val_lbl.custom_minimum_size = Vector2(50, 0)
		val_lbl.add_theme_font_size_override("font_size", 13)
		val_lbl.set("theme_override_colors/font_color", Color(0.9, 0.85, 0.3) if prosp >= 60.0 else Color(0.6, 0.65, 0.7))
		row.add_child(val_lbl)

		district_list.add_child(row)


func _animate_entrance() -> void:
	scale = Vector2(0.85, 0.85)
	modulate.a = 0.0

	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.35)
	tween.tween_property(self, "modulate:a", 1.0, 0.3)

	# Slam grade stamp with slight delay
	if grade_badge != null:
		grade_badge.scale = Vector2(2.5, 2.5)
		grade_badge.modulate.a = 0.0
		var stamp_tween := create_tween()
		stamp_tween.tween_interval(0.2)
		stamp_tween.set_parallel(true)
		stamp_tween.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		stamp_tween.tween_property(grade_badge, "scale", Vector2.ONE, 0.35)
		stamp_tween.tween_property(grade_badge, "modulate:a", 1.0, 0.15)
		stamp_tween.chain().tween_callback(func():
			if AudioManager != null and AudioManager.has_method("play_stamp_thud"):
				AudioManager.play_stamp_thud(true)
		)


func _format_money(amount: int) -> String:
	var sign_str: String = "-$" if amount < 0 else "+$"
	var abs_str: String = str(absi(amount))
	var out: String = ""
	var count: int = 0
	for i in range(abs_str.length() - 1, -1, -1):
		out = abs_str[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "," + out
	return sign_str + out
