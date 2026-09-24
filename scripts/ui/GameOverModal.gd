extends PanelContainer

## GameOverModal.gd - Game over cutscene card for "Yes, Mr. Mayor!"
## Displays narrative outcome, final tenure statistics, and mandate restart.

signal restart_requested

@onready var title_label: Label = %TitleLabel
@onready var reason_header: Label = %ReasonHeader
@onready var narrative_label: Label = %NarrativeLabel
@onready var stats_header: Label = %StatsHeader
@onready var days_survived_label: Label = %DaysSurvivedLabel
@onready var treasury_label: Label = %TreasuryLabel
@onready var stash_label: Label = %StashLabel
@onready var btn_restart: Button = %BtnRestart


func _ready() -> void:
	btn_restart.pressed.connect(func(): restart_requested.emit())


## Displays game over outcome based on reason key
func show_game_over(reason_key: String) -> void:
	visible = true
	title_label.text = tr("UI_GAME_OVER_TITLE")
	narrative_label.text = tr(reason_key)
	stats_header.text = tr("UI_FINAL_STATS")

	var is_victory: bool = (reason_key == "END_REELECTED")
	if is_victory:
		reason_header.text = "🏆 MANDATE EXTENDED: 4 MORE YEARS"
		reason_header.set("theme_override_colors/font_color", Color(1.0, 0.85, 0.25, 1))
	else:
		reason_header.text = "🚨 ADMINISTRATION COLLAPSED"
		reason_header.set("theme_override_colors/font_color", Color(0.95, 0.25, 0.25, 1))

	var days_clamped: int = mini(GameManager.current_day, GameManager.MAX_DAYS)
	days_survived_label.text = tr("UI_DAYS_SURVIVED").format({"days": days_clamped})
	treasury_label.text = tr("UI_FINAL_TREASURY").format({
		"budget": _format_money(GameManager.city_budget)
	})
	stash_label.text = tr("UI_FINAL_STASH").format({
		"wealth": _format_money(GameManager.offshore_account)
	})
	btn_restart.text = tr("UI_RETRY")

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
