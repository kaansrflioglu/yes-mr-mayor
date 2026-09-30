extends PanelContainer

## GameOverModal.gd - Game over cutscene card for "Yes, Mr. Mayor!"
## Displays narrative outcome, final tenure statistics, and mandate restart.

signal restart_requested
signal main_menu_requested

@onready var title_label: Label = %TitleLabel
@onready var reason_header: Label = %ReasonHeader
@onready var narrative_label: Label = %NarrativeLabel
@onready var stats_header: Label = %StatsHeader
@onready var days_survived_label: Label = %DaysSurvivedLabel
@onready var treasury_label: Label = %TreasuryLabel
@onready var stash_label: Label = %StashLabel
@onready var btn_restart: Button = %BtnRestart
@onready var btn_main_menu: Button = %BtnMainMenu if has_node("%BtnMainMenu") else null


func _ready() -> void:
	btn_restart.pressed.connect(func(): restart_requested.emit())
	if btn_main_menu != null:
		btn_main_menu.pressed.connect(func(): main_menu_requested.emit())


## Displays game over outcome based on reason key
func show_game_over(reason_key: String) -> void:
	visible = true
	title_label.text = tr("UI_GAME_OVER_TITLE")
	narrative_label.text = tr(reason_key)
	stats_header.text = tr("UI_FINAL_STATS")

	if reason_key == "END_REELECTED":
		reason_header.text = "🏆 MANDATE EXTENDED: 4 MORE YEARS"
		reason_header.set("theme_override_colors/font_color", Color(1.0, 0.85, 0.25, 1))
	elif reason_key == "END_FLED_TO_CAYMANS" or reason_key == "END_CAYMAN_EXILE":
		reason_header.text = "🌴 " + tr("UI_ENDING_CAYMANS_HEADER")
		reason_header.set("theme_override_colors/font_color", Color(0.35, 0.85, 1.0, 1))
	elif reason_key == "END_BRIBE_LEAK_SCANDAL" or reason_key == "END_FEDERAL_SUPERMAX":
		reason_header.text = "🚨 " + tr("UI_ENDING_SCANDAL_HEADER")
		reason_header.set("theme_override_colors/font_color", Color(0.95, 0.25, 0.25, 1))
	elif reason_key == "END_SAINT":
		reason_header.text = "🕊️ " + tr("TITLE_CIVIC_SAINT")
		reason_header.set("theme_override_colors/font_color", Color(0.95, 0.85, 0.25, 1))
	elif reason_key == "END_TEFLON_DON":
		reason_header.text = "👑 " + tr("TITLE_TEFLON_MASTERMIND")
		reason_header.set("theme_override_colors/font_color", Color(0.95, 0.78, 0.22, 1))
	elif reason_key == "END_ECO_UTOPIA":
		reason_header.text = "🌿 " + tr("TITLE_EMERALD_METROPOLIS")
		reason_header.set("theme_override_colors/font_color", Color(0.2, 0.85, 0.4, 1))
	elif reason_key == "END_CORPORATE_PUPPET":
		reason_header.text = "💼 " + tr("TITLE_CORPORATE_PUPPET")
		reason_header.set("theme_override_colors/font_color", Color(0.3, 0.6, 0.9, 1))
	elif reason_key == "END_MOB_VICEROY":
		reason_header.text = "🕶️ " + tr("TITLE_SHADOW_CONSIGLIERE")
		reason_header.set("theme_override_colors/font_color", Color(0.9, 0.5, 0.2, 1))
	elif reason_key == "END_SHADOW_JUNTA":
		reason_header.text = "🎖️ " + tr("TITLE_EMERGENCY_AUTOCRAT")
		reason_header.set("theme_override_colors/font_color", Color(0.9, 0.3, 0.2, 1))
	elif reason_key == "END_AUSTERE_ACCOUNTANT":
		reason_header.text = "📊 " + tr("TITLE_AUSTERE_TECHNOCRAT")
		reason_header.set("theme_override_colors/font_color", Color(0.4, 0.7, 0.9, 1))
	elif reason_key == "END_REVOLUTION_STORM":
		reason_header.text = "🔥 " + tr("TITLE_OUSTED_TYRANT")
		reason_header.set("theme_override_colors/font_color", Color(0.95, 0.25, 0.25, 1))
	elif reason_key == "END_MUNICIPAL_BANKRUPT":
		reason_header.text = "📉 " + tr("TITLE_BANKRUPT_SPENDTHRIFT")
		reason_header.set("theme_override_colors/font_color", Color(0.85, 0.35, 0.15, 1))
	elif reason_key == "END_ONE_TERM_MEDIOCRE":
		reason_header.text = "📦 " + tr("TITLE_FORGOTTEN_MAYOR")
		reason_header.set("theme_override_colors/font_color", Color(0.7, 0.7, 0.7, 1))
	else:
		reason_header.text = "🚨 ADMINISTRATION COLLAPSED"
		reason_header.set("theme_override_colors/font_color", Color(0.95, 0.25, 0.25, 1))

	var months_clamped: int = mini(GameManager.current_month, GameManager.MAX_MONTHS)
	var month_surv_str: String = tr("UI_MONTHS_SURVIVED")
	if month_surv_str != "UI_MONTHS_SURVIVED" and "{months}" in month_surv_str:
		days_survived_label.text = month_surv_str.format({"months": months_clamped, "max": GameManager.MAX_MONTHS})
	else:
		days_survived_label.text = tr("UI_DAYS_SURVIVED").format({"days": months_clamped}).replace("Gün", "Ay").replace("Days", "Months").replace("30", str(GameManager.MAX_MONTHS))
	treasury_label.text = tr("UI_FINAL_TREASURY").format({
		"budget": _format_money(GameManager.city_budget)
	})
	stash_label.text = tr("UI_FINAL_STASH").format({
		"wealth": _format_money(GameManager.offshore_account)
	})
	btn_restart.text = tr("UI_GAME_OVER_RESTART")
	if btn_main_menu != null:
		btn_main_menu.text = tr("UI_GAME_OVER_MAIN_MENU")

	_animate_entrance()


func _animate_entrance() -> void:
	scale = Vector2(0.85, 0.85)
	modulate.a = 0.0

	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.4)
	tween.tween_property(self, "modulate:a", 1.0, 0.3)


func _format_money(amount: int) -> String:
	var sign_str: String = "-" if amount < 0 else ""
	var abs_str: String = str(absi(amount))
	var out: String = ""
	var count: int = 0
	for i in range(abs_str.length() - 1, -1, -1):
		out = abs_str[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "," + out
	return sign_str + out
