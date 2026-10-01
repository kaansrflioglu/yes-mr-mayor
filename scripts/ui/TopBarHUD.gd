extends PanelContainer

## TopBarHUD.gd - Heads-Up Display for mayor's office.
## Displays municipal metrics, offshore funds, day counter, and action buttons.
## Animates analog approval dial needle, rolling odometer counters, and danger tubes.

signal twitch_toggle_requested
signal settings_toggle_requested
signal pause_toggle_requested
signal map_toggle_requested

@onready var approval_bar: ProgressBar = %ApprovalBar
@onready var approval_label: Label = %ApprovalLabel
@onready var approval_needle: Sprite2D = (
	%ApprovalNeedle if has_node("%ApprovalNeedle") else null
)
@onready var budget_label: Label = %BudgetLabel
@onready var offshore_label: Label = %OffshoreLabel
@onready var suspicion_bar: ProgressBar = %SuspicionBar
@onready var suspicion_label: Label = %SuspicionLabel
@onready var day_label: Label = %DayLabel
@onready var clock_label: Label = %ClockLabel if has_node("%ClockLabel") else null
@onready var directive_label: Label = (
	%DirectiveLabel if has_node("%DirectiveLabel") else null
)

@onready var btn_settings: Button = %BtnSettings
@onready var btn_pause: Button = %BtnPause
@onready var btn_twitch: Button = %BtnTwitch if has_node("%BtnTwitch") else null
@onready var btn_map: Button = %BtnMap if has_node("%BtnMap") else null

var _displayed_budget: float = 100000.0
var _displayed_wealth: float = 0.0
var _budget_tween: Tween
var _wealth_tween: Tween
var _approval_tween: Tween
var _suspicion_tween: Tween

var _suspicion_material: ShaderMaterial = null


func _ready() -> void:
	if btn_settings != null:
		btn_settings.visible = false
		btn_settings.pressed.connect(func(): settings_toggle_requested.emit())
	if btn_pause != null:
		btn_pause.pressed.connect(func(): pause_toggle_requested.emit())
	if btn_twitch != null:
		btn_twitch.pressed.connect(func(): twitch_toggle_requested.emit())
	if btn_map != null:
		btn_map.pressed.connect(func(): map_toggle_requested.emit())

	if suspicion_bar != null and suspicion_bar.material is ShaderMaterial:
		_suspicion_material = suspicion_bar.material as ShaderMaterial

	GameManager.stats_changed.connect(_on_stats_changed)
	LocalizationManager.locale_changed.connect(_on_locale_changed)

	_update_settings_button_text()
	_sync_all_metrics(false)


func _on_stats_changed() -> void:
	_sync_all_metrics(true)


func _on_locale_changed(_locale: String) -> void:
	_update_settings_button_text()
	_sync_all_metrics(false)


func _update_settings_button_text() -> void:
	if btn_settings != null:
		btn_settings.text = "⚙️ " + tr("UI_SETTINGS_TOOLTIP").split("(")[0].strip_edges()
	if btn_pause != null:
		btn_pause.text = "⏸️ " + tr("UI_HUD_MENU")
		btn_pause.tooltip_text = tr("UI_HUD_MENU_TOOLTIP")
	if btn_map != null:
		btn_map.tooltip_text = tr("UI_DISTRICT_MAP_TOOLTIP") if tr(
			"UI_DISTRICT_MAP_TOOLTIP"
		) != "UI_DISTRICT_MAP_TOOLTIP" else "Municipal Blueprint Map (M)"


func _sync_all_metrics(animate: bool) -> void:
	# Month label (48-month mandate)
	var cur_m: int = GameManager.current_month
	var max_m: int = GameManager.MAX_MONTHS
	var month_str: String = tr("UI_MONTH")
	if month_str != "UI_MONTH" and "{month}" in month_str:
		day_label.text = month_str.format({"month": cur_m, "max": max_m})
	else:
		day_label.text = "%d. Ay / %d" % [cur_m, max_m]

	var target_opinion: float = GameManager.public_opinion
	var target_budget: float = float(GameManager.city_budget)
	var target_wealth: float = float(GameManager.offshore_account)
	var target_suspicion: float = GameManager.suspicion_meter

	# Analog approval needle angle: -60 deg at 0%, +60 deg at 100%
	var target_needle_rot: float = lerpf(
		-60.0, 60.0, clampf(target_opinion / 100.0, 0.0, 1.0)
	)

	_update_suspicion_shader(target_suspicion)

	if not animate:
		approval_bar.value = target_opinion
		approval_label.text = tr("UI_APPROVAL").format(
			{"opinion": "%.1f" % target_opinion}
		)
		if approval_needle != null:
			approval_needle.rotation_degrees = target_needle_rot

		_displayed_budget = target_budget
		budget_label.text = tr("UI_BUDGET").format(
			{"budget": _format_money(int(target_budget))}
		)

		_displayed_wealth = target_wealth
		offshore_label.text = tr("UI_WEALTH").format(
			{"wealth": _format_money(int(target_wealth))}
		)

		suspicion_bar.value = target_suspicion
		suspicion_label.text = tr("UI_SUSPICION").format(
			{"suspicion": "%.1f" % target_suspicion}
		)
		return

	# Smooth tween animations for telemetry instruments
	if _approval_tween and _approval_tween.is_valid():
		_approval_tween.kill()
	_approval_tween = create_tween().set_parallel(true)
	_approval_tween.tween_property(approval_bar, "value", target_opinion, 0.4)
	_approval_tween.tween_method(
		func(val: float):
			approval_label.text = tr("UI_APPROVAL").format(
				{"opinion": "%.1f" % val}
			),
		approval_bar.value, target_opinion, 0.4
	)
	if approval_needle != null:
		_approval_tween.tween_property(
			approval_needle, "rotation_degrees", target_needle_rot, 0.5
		).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Rolling odometer counter for city budget over 0.4s
	if _budget_tween and _budget_tween.is_valid():
		_budget_tween.kill()
	_budget_tween = create_tween()
	_budget_tween.tween_method(
		func(val: float):
			_displayed_budget = val
			budget_label.text = tr("UI_BUDGET").format(
				{"budget": _format_money(int(val))}
			),
		_displayed_budget, target_budget, 0.4
	)

	# Rolling odometer counter for offshore wealth over 0.4s
	if _wealth_tween and _wealth_tween.is_valid():
		_wealth_tween.kill()
	_wealth_tween = create_tween()
	_wealth_tween.tween_method(
		func(val: float):
			_displayed_wealth = val
			offshore_label.text = tr("UI_WEALTH").format(
				{"wealth": _format_money(int(val))}
			),
		_displayed_wealth, target_wealth, 0.4
	)

	# Suspicion vacuum tube tween
	if _suspicion_tween and _suspicion_tween.is_valid():
		_suspicion_tween.kill()
	_suspicion_tween = create_tween().set_parallel(true)
	_suspicion_tween.tween_property(suspicion_bar, "value", target_suspicion, 0.4)
	_suspicion_tween.tween_method(
		func(val: float):
			suspicion_label.text = tr("UI_SUSPICION").format(
				{"suspicion": "%.1f" % val}
			),
		suspicion_bar.value, target_suspicion, 0.4
	)


func _update_suspicion_shader(suspicion_val: float) -> void:
	if _suspicion_material == null:
		return
	if suspicion_val >= 75.0:
		var alert_strength: float = clampf(
			(suspicion_val - 75.0) / 25.0 * 0.7 + 0.3, 0.3, 1.0
		)
		_suspicion_material.set_shader_parameter("pulse_intensity", alert_strength)
	else:
		_suspicion_material.set_shader_parameter("pulse_intensity", 0.0)


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


## Updates the shift clock display and overtime highlight
func set_shift_time(formatted_time: String, is_overtime: bool) -> void:
	if clock_label != null:
		clock_label.text = "🕒 " + formatted_time
		if is_overtime:
			clock_label.modulate = Color(1.0, 0.35, 0.35, 1.0)
		else:
			clock_label.modulate = Color(0.85, 0.92, 1.0, 1.0)


## Updates the municipal executive directive label and tooltip
func set_directive_text(title: String, tooltip: String = "") -> void:
	if directive_label != null:
		directive_label.text = "📜 " + title
		directive_label.tooltip_text = tooltip
