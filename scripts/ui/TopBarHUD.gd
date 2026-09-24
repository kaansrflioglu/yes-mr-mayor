extends PanelContainer

## TopBarHUD.gd - Heads-Up Display for mayor's office.
## Displays municipal metrics, offshore funds, day counter, and language selector.
## Animates counter values dynamically with tweens.

signal twitch_toggle_requested

@onready var approval_bar: ProgressBar = %ApprovalBar
@onready var approval_label: Label = %ApprovalLabel
@onready var budget_label: Label = %BudgetLabel
@onready var offshore_label: Label = %OffshoreLabel
@onready var suspicion_bar: ProgressBar = %SuspicionBar
@onready var suspicion_label: Label = %SuspicionLabel
@onready var day_label: Label = %DayLabel

@onready var btn_en: Button = %BtnEN
@onready var btn_tr: Button = %BtnTR
@onready var btn_es: Button = %BtnES
@onready var btn_twitch: Button = %BtnTwitch

var _displayed_budget: float = 100000.0
var _displayed_wealth: float = 0.0
var _budget_tween: Tween
var _wealth_tween: Tween
var _approval_tween: Tween
var _suspicion_tween: Tween


func _ready() -> void:
	btn_en.pressed.connect(func(): LocalizationManager.set_locale("en"))
	btn_tr.pressed.connect(func(): LocalizationManager.set_locale("tr"))
	btn_es.pressed.connect(func(): LocalizationManager.set_locale("es"))
	btn_twitch.pressed.connect(func(): twitch_toggle_requested.emit())

	GameManager.stats_changed.connect(_on_stats_changed)
	LocalizationManager.locale_changed.connect(_on_locale_changed)

	btn_twitch.text = tr("UI_TWITCH_TOGGLE")
	_sync_all_metrics(false)
	_update_active_locale_button(LocalizationManager.get_current_locale())


func _on_stats_changed() -> void:
	_sync_all_metrics(true)


func _on_locale_changed(_locale: String) -> void:
	btn_twitch.text = tr("UI_TWITCH_TOGGLE")
	_sync_all_metrics(false)
	_update_active_locale_button(LocalizationManager.get_current_locale())


func _update_active_locale_button(current_loc: String) -> void:
	btn_en.modulate = Color(1.0, 0.9, 0.4) if current_loc == "en" else Color(0.7, 0.7, 0.7)
	btn_tr.modulate = Color(1.0, 0.9, 0.4) if current_loc == "tr" else Color(0.7, 0.7, 0.7)
	btn_es.modulate = Color(1.0, 0.9, 0.4) if current_loc == "es" else Color(0.7, 0.7, 0.7)


func _sync_all_metrics(animate: bool) -> void:
	# Day label
	day_label.text = tr("UI_DAY").format({"day": GameManager.current_day})

	var target_opinion: float = GameManager.public_opinion
	var target_budget: float = float(GameManager.city_budget)
	var target_wealth: float = float(GameManager.offshore_account)
	var target_suspicion: float = GameManager.suspicion_meter

	if not animate:
		approval_bar.value = target_opinion
		approval_label.text = tr("UI_APPROVAL").format({"opinion": "%.1f" % target_opinion})

		_displayed_budget = target_budget
		budget_label.text = tr("UI_BUDGET").format({"budget": _format_money(int(target_budget))})

		_displayed_wealth = target_wealth
		offshore_label.text = tr("UI_WEALTH").format({"wealth": _format_money(int(target_wealth))})

		suspicion_bar.value = target_suspicion
		suspicion_label.text = tr("UI_SUSPICION").format({"suspicion": "%.1f" % target_suspicion})
		return

	# Smooth tween animation on value change
	if _approval_tween and _approval_tween.is_valid():
		_approval_tween.kill()
	_approval_tween = create_tween().set_parallel(true)
	_approval_tween.tween_property(approval_bar, "value", target_opinion, 0.5)
	_approval_tween.tween_method(
		func(val: float):
			approval_label.text = tr("UI_APPROVAL").format({"opinion": "%.1f" % val}),
		approval_bar.value, target_opinion, 0.5
	)

	if _budget_tween and _budget_tween.is_valid():
		_budget_tween.kill()
	_budget_tween = create_tween()
	_budget_tween.tween_method(
		func(val: float):
			_displayed_budget = val
			budget_label.text = tr("UI_BUDGET").format({"budget": _format_money(int(val))}),
		_displayed_budget, target_budget, 0.5
	)

	if _wealth_tween and _wealth_tween.is_valid():
		_wealth_tween.kill()
	_wealth_tween = create_tween()
	_wealth_tween.tween_method(
		func(val: float):
			_displayed_wealth = val
			offshore_label.text = tr("UI_WEALTH").format({"wealth": _format_money(int(val))}),
		_displayed_wealth, target_wealth, 0.5
	)

	if _suspicion_tween and _suspicion_tween.is_valid():
		_suspicion_tween.kill()
	_suspicion_tween = create_tween().set_parallel(true)
	_suspicion_tween.tween_property(suspicion_bar, "value", target_suspicion, 0.5)
	_suspicion_tween.tween_method(
		func(val: float):
			suspicion_label.text = tr("UI_SUSPICION").format({"suspicion": "%.1f" % val}),
		suspicion_bar.value, target_suspicion, 0.5
	)


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
