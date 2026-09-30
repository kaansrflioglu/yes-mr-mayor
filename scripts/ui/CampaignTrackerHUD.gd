extends PanelContainer

## CampaignTrackerHUD.gd - Heads-Up Display polling widget during Days 23-30.
## Displays the live electoral battle between the Mayor and their rival candidate.

@onready var poll_bar: ProgressBar = %PollBar
@onready var incumbent_label: Label = %IncumbentLabel
@onready var rival_label: Label = %RivalLabel
@onready var election_badge: Label = %ElectionBadge

@onready var election_mgr: Node = get_node_or_null("/root/ElectionManager")


func _ready() -> void:
	visible = false
	if election_mgr != null:
		if election_mgr.has_signal("polling_updated"):
			election_mgr.polling_updated.connect(_on_polling_updated)
		if election_mgr.has_signal("campaign_started"):
			election_mgr.campaign_started.connect(_on_campaign_started)

	_check_initial_visibility()


func _check_initial_visibility() -> void:
	if election_mgr != null and election_mgr.is_campaign_active:
		visible = true
		_update_display(election_mgr.incumbent_poll, election_mgr.rival_poll)


func _on_campaign_started(_r_id: String, _r_name: String) -> void:
	visible = true
	if election_mgr != null:
		_update_display(election_mgr.incumbent_poll, election_mgr.rival_poll)


func _on_polling_updated(incumbent_pct: float, rival_pct: float) -> void:
	if not visible:
		visible = true
	_update_display(incumbent_pct, rival_pct)


func _update_display(incumbent_pct: float, rival_pct: float) -> void:
	if poll_bar != null:
		poll_bar.value = incumbent_pct

	if incumbent_label != null:
		incumbent_label.text = "🏛️ %s: %d%%" % [tr("UI_INCUMBENT_SHORT"), int(round(incumbent_pct))]

	if rival_label != null:
		var r_name: String = election_mgr.get_rival_name() if election_mgr != null else "Rival"
		rival_label.text = "🎯 %s: %d%%" % [r_name, int(round(rival_pct))]

	if election_badge != null and GameManager != null:
		var months_left: int = maxi(GameManager.MAX_MONTHS - GameManager.current_month, 0)
		var badge_pattern: String = tr("UI_ELECTION_COUNTDOWN_MONTH")
		if badge_pattern != "UI_ELECTION_COUNTDOWN_MONTH" and "{months}" in badge_pattern:
			election_badge.text = badge_pattern.format({"months": months_left})
		else:
			election_badge.text = tr("UI_ELECTION_COUNTDOWN").format({"days": months_left}).replace("Gün", "Ay").replace("Days", "Months")
