extends PanelContainer

## DayEndSummary.gd - End-of-Day Tabloid Newspaper & Financial Summary.
## Displays satirical headlines reflecting choices made during the shift.

signal next_day_requested

@onready var masthead_label: Label = %MastheadLabel
@onready var issue_label: Label = %IssueLabel
@onready var headline_main: Label = %HeadlineMain
@onready var headline_sub: Label = %HeadlineSub

@onready var financial_header: Label = %FinancialHeader
@onready var treasury_label: Label = %TreasuryLabel
@onready var offshore_label: Label = %OffshoreLabel
@onready var approval_label: Label = %ApprovalLabel
@onready var suspicion_label: Label = %SuspicionLabel
@onready var btn_next_day: Button = %BtnNextDay

var presented_day: int = 1


func _ready() -> void:
	btn_next_day.pressed.connect(func(): next_day_requested.emit())


## Populates newspaper headlines and financial balance from shift history
func populate_summary(day_num: int) -> void:
	presented_day = day_num
	masthead_label.text = tr("UI_TABLOID_HEADER")
	issue_label.text = tr("UI_TABLOID_SUBHEADER").format({"day": day_num})
	financial_header.text = tr("UI_FINANCIAL_REPORT")

	# Fetch shift history for today
	var history: Array[Dictionary] = GameManager.get_history_for_day(day_num)
	var hotline_records: Array[Dictionary] = []
	if GameManager != null and GameManager.has_method("get_hotline_history_for_day"):
		hotline_records = GameManager.get_hotline_history_for_day(day_num)

	if not hotline_records.is_empty():
		var last_hotline: Dictionary = hotline_records[hotline_records.size() - 1]
		var arch: String = str(last_hotline.get("archetype", ""))
		var accepted: bool = bool(last_hotline.get("accepted", false))
		var hotline_key: String = HotlineManager.get_hotline_headline_key(arch, accepted)
		var hotline_text: String = tr(hotline_key)

		if history.is_empty():
			headline_main.text = hotline_text
			headline_sub.text = tr("HOTLINE_NEWS_GENERIC")
			headline_sub.visible = true
		else:
			var last_record: Dictionary = history[history.size() - 1]
			var main_key: String = str(last_record.get("headline_key", ""))
			headline_main.text = (
				tr(main_key) if not main_key.is_empty() else tr("EVT_001_NEWS_APP")
			)
			headline_sub.text = "☎️ " + hotline_text
			headline_sub.visible = true
	elif history.is_empty():
		headline_main.text = tr("EVT_001_NEWS_APP")
		headline_sub.text = tr("EVT_002_NEWS_REJ")
	else:
		var last_record: Dictionary = history[history.size() - 1]
		var main_key: String = str(last_record.get("headline_key", ""))
		headline_main.text = tr(main_key) if not main_key.is_empty() else tr("EVT_001_NEWS_APP")

		if history.size() >= 2:
			var second_record: Dictionary = history[history.size() - 2]
			var sub_key: String = str(second_record.get("headline_key", ""))
			headline_sub.text = tr(sub_key) if not sub_key.is_empty() else ""
			headline_sub.visible = true
		else:
			headline_sub.visible = false

	# Financial balance
	treasury_label.text = tr("UI_OFFICIAL_BALANCE").format({
		"budget": _format_money(GameManager.city_budget)
	})
	offshore_label.text = tr("UI_ILLICIT_KICKBACKS").format({
		"wealth": _format_money(GameManager.offshore_account)
	})
	approval_label.text = tr("UI_DAILY_APPROVAL").format({
		"opinion": "%.1f" % GameManager.public_opinion
	})
	suspicion_label.text = tr("UI_DAILY_SUSPICION").format({
		"suspicion": "%.1f" % GameManager.suspicion_meter
	})

	btn_next_day.text = tr("UI_START_NEXT_DAY").format({"day": day_num + 1})


## Drop & slam paper animation
func animate_newspaper_delivery() -> void:
	scale = Vector2(1.5, 1.5)
	rotation = -0.06
	modulate.a = 0.0

	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.45)
	tween.tween_property(self, "rotation", 0.0, 0.45)
	tween.tween_property(self, "modulate:a", 1.0, 0.25)


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
