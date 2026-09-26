class_name OffshoreLedgerModal
extends Control

## OffshoreLedgerModal.gd - Illicit funds and clandestine money sinks modal.
## Enables spending personal wealth accumulated in the Mayor's secret offshore safe.
## Fully localized (en, tr, es) and data-driven with dynamic scaling.

signal modal_closed
signal fixer_purchased(cost: int, suspicion_drop: float)
signal pr_campaign_purchased(cost: int, opinion_gain: float, scandal_triggered: bool)
signal audit_leak_purchased(cost: int)
signal luxury_item_purchased(item_id: String, cost: int)

@onready var backdrop: ColorRect = %Backdrop
@onready var modal_panel: PanelContainer = %ModalPanel
@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var stashed_balance_label: Label = %StashedBalanceLabel
@onready var status_label: Label = %StatusLabel

# Card 1: Fixer
@onready var fixer_title: Label = %FixerTitle
@onready var fixer_desc: Label = %FixerDesc
@onready var fixer_effect: Label = %FixerEffect
@onready var fixer_cost_label: Label = %FixerCostLabel
@onready var btn_buy_fixer: Button = %BtnBuyFixer

# Card 2: PR
@onready var pr_title: Label = %PRTitle
@onready var pr_desc: Label = %PRDesc
@onready var pr_effect: Label = %PREffect
@onready var pr_cost_label: Label = %PRCostLabel
@onready var btn_buy_pr: Button = %BtnBuyPR

# Card 3: Audit Intel
@onready var audit_title: Label = %AuditTitle
@onready var audit_desc: Label = %AuditDesc
@onready var audit_effect: Label = %AuditEffect
@onready var audit_cost_label: Label = %AuditCostLabel
@onready var btn_buy_audit: Button = %BtnBuyAudit

# Card 4: Desk Luxury
@onready var luxury_title: Label = %LuxuryTitle
@onready var luxury_desc: Label = %LuxuryDesc
@onready var luxury_effect: Label = %LuxuryEffect
@onready var luxury_cost_label: Label = %LuxuryCostLabel
@onready var btn_buy_luxury: Button = %BtnBuyLuxury

# Close buttons
@onready var btn_header_close: Button = %BtnHeaderClose
@onready var btn_footer_close: Button = %BtnFooterClose

var is_open: bool = false
var _status_tween: Tween = null

# Dynamic cost cache
var current_fixer_cost: int = 40000
var current_pr_cost: int = 30000
var current_audit_cost: int = 60000
var current_luxury_cost: int = 50000


func _ready() -> void:
	visible = false
	_connect_signals()
	LocalizationManager.locale_changed.connect(func(_l): _update_locale_texts())
	if GameManager != null and GameManager.has_signal("stats_changed"):
		GameManager.stats_changed.connect(_on_stats_changed)


func _connect_signals() -> void:
	btn_header_close.pressed.connect(close)
	btn_footer_close.pressed.connect(close)

	btn_buy_fixer.pressed.connect(_on_buy_fixer_pressed)
	btn_buy_pr.pressed.connect(_on_buy_pr_pressed)
	btn_buy_audit.pressed.connect(_on_buy_audit_pressed)
	btn_buy_luxury.pressed.connect(_on_buy_luxury_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


## Opens the ledger modal with smooth slide-up and scale transition
func open() -> void:
	if is_open:
		return
	is_open = true
	visible = true

	if status_label:
		status_label.text = ""

	_calculate_dynamic_costs()
	_update_locale_texts()
	_refresh_button_states()

	# Audio cue: cash register / safe lock
	if AudioManager != null and AudioManager.has_method("play_cash_register"):
		AudioManager.play_cash_register()

	# Slide up & scale in
	backdrop.modulate = Color(1, 1, 1, 0.0)
	modal_panel.scale = Vector2(0.92, 0.92)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(backdrop, "modulate:a", 1.0, 0.2)
	tween.tween_property(modal_panel, "scale", Vector2.ONE, 0.28).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)


## Closes the ledger modal with smooth fade out
func close() -> void:
	if not is_open:
		return
	is_open = false

	var tween := create_tween().set_parallel(true)
	tween.tween_property(backdrop, "modulate:a", 0.0, 0.18)
	tween.tween_property(modal_panel, "scale", Vector2(0.92, 0.92), 0.18).set_trans(
		Tween.TRANS_QUAD
	).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(func():
		visible = false
		modal_closed.emit()
	)


func _on_stats_changed() -> void:
	if is_open:
		_refresh_balance_display()
		_refresh_button_states()


## Calculates day-scaling costs according to OFFSHORE_SPENDING_MECHANICS.md
func _calculate_dynamic_costs() -> void:
	var day: int = GameManager.current_day if GameManager != null else 1

	# Fixer: scales from $35,000 up to $65,000 as day progresses (Day 1: $35k -> Day 30: $65k)
	var day_factor: float = clampf(float(day - 1) / 29.0, 0.0, 1.0)
	current_fixer_cost = int(35000 + day_factor * 30000)

	# PR Astroturf: $25,000 to $40,000
	current_pr_cost = int(25000 + day_factor * 15000)

	# Audit Intel: flat $60,000
	current_audit_cost = 60000

	# Luxury item: Solid Gold Stamp is $50,000
	current_luxury_cost = 50000


func _update_locale_texts() -> void:
	title_label.text = tr("UI_OFFSHORE_LEDGER_TITLE")
	subtitle_label.text = tr("UI_OFFSHORE_LEDGER_SUBTITLE")
	btn_footer_close.text = tr("UI_OFFSHORE_CLOSE")

	_refresh_balance_display()

	# Fixer card
	fixer_title.text = tr("UI_OFFSHORE_FIXER_TITLE")
	fixer_desc.text = tr("UI_OFFSHORE_FIXER_DESC")
	fixer_effect.text = tr("UI_OFFSHORE_FIXER_EFFECT")
	fixer_cost_label.text = _format_money(current_fixer_cost)
	btn_buy_fixer.text = tr("UI_OFFSHORE_FIXER_BTN").format({"cost": _format_money(current_fixer_cost)})

	# PR card
	pr_title.text = tr("UI_OFFSHORE_PR_TITLE")
	pr_desc.text = tr("UI_OFFSHORE_PR_DESC")
	pr_effect.text = tr("UI_OFFSHORE_PR_EFFECT")
	pr_cost_label.text = _format_money(current_pr_cost)
	btn_buy_pr.text = tr("UI_OFFSHORE_PR_BTN").format({"cost": _format_money(current_pr_cost)})

	# Audit card
	audit_title.text = tr("UI_OFFSHORE_AUDIT_TITLE")
	audit_desc.text = tr("UI_OFFSHORE_AUDIT_DESC")
	audit_effect.text = tr("UI_OFFSHORE_AUDIT_EFFECT")
	audit_cost_label.text = _format_money(current_audit_cost)
	btn_buy_audit.text = tr("UI_OFFSHORE_AUDIT_BTN").format({"cost": _format_money(current_audit_cost)})

	# Luxury card
	luxury_title.text = tr("UI_OFFSHORE_LUXURY_TITLE")
	luxury_desc.text = tr("UI_OFFSHORE_LUXURY_DESC")
	luxury_effect.text = tr("UI_OFFSHORE_LUXURY_EFFECT")
	luxury_cost_label.text = _format_money(current_luxury_cost)
	btn_buy_luxury.text = tr("UI_OFFSHORE_LUXURY_BTN")


func _refresh_balance_display() -> void:
	var wealth: int = GameManager.personal_wealth if GameManager != null else 0
	stashed_balance_label.text = tr("UI_OFFSHORE_BALANCE").format({"wealth": _format_money(wealth)})


func _refresh_button_states() -> void:
	var wealth: int = GameManager.personal_wealth if GameManager != null else 0
	btn_buy_fixer.disabled = (wealth < current_fixer_cost)
	btn_buy_pr.disabled = (wealth < current_pr_cost)
	btn_buy_audit.disabled = (wealth < current_audit_cost)
	btn_buy_luxury.disabled = (wealth < current_luxury_cost)


# --- Purchase Action Handlers ---

func _on_buy_fixer_pressed() -> void:
	var wealth: int = GameManager.personal_wealth if GameManager != null else 0
	if wealth < current_fixer_cost:
		_show_feedback(tr("UI_OFFSHORE_INSUFFICIENT"), Color(0.9, 0.3, 0.3, 1.0))
		return

	# Deduct wealth and reduce federal suspicion by 25%
	GameManager.personal_wealth -= current_fixer_cost
	var suspicion_drop: float = 25.0
	if GameManager != null:
		GameManager.suspicion_level = maxf(0.0, GameManager.suspicion_level - suspicion_drop)
		GameManager.notify_stats_changed()

	if AudioManager != null and AudioManager.has_method("play_cash_register"):
		AudioManager.play_cash_register()

	_show_feedback(tr("UI_OFFSHORE_SUCCESS"), Color(0.4, 0.9, 0.5, 1.0))
	fixer_purchased.emit(current_fixer_cost, suspicion_drop)
	_refresh_balance_display()
	_refresh_button_states()


func _on_buy_pr_pressed() -> void:
	var wealth: int = GameManager.personal_wealth if GameManager != null else 0
	if wealth < current_pr_cost:
		_show_feedback(tr("UI_OFFSHORE_INSUFFICIENT"), Color(0.9, 0.3, 0.3, 1.0))
		return

	GameManager.personal_wealth -= current_pr_cost
	var suspicion: float = GameManager.suspicion_level if GameManager != null else 0.0

	# 20% scandal chance if suspicion > 75%
	var scandal_triggered: bool = false
	if suspicion >= 75.0 and randf() < 0.20:
		scandal_triggered = true
		if GameManager != null:
			GameManager.public_opinion = maxf(0.0, GameManager.public_opinion - 20.0)
			GameManager.event_flags["FLAG_PR_SCANDAL"] = true
			GameManager.notify_stats_changed()
		_show_feedback("🚨 " + tr("UI_OFFSHORE_PR_SCANDAL"), Color(0.95, 0.3, 0.3, 1.0))
	else:
		var opinion_gain: float = 18.0
		if GameManager != null:
			GameManager.public_opinion = minf(100.0, GameManager.public_opinion + opinion_gain)
			GameManager.notify_stats_changed()
		_show_feedback(tr("UI_OFFSHORE_SUCCESS"), Color(0.4, 0.9, 0.5, 1.0))

	if AudioManager != null and AudioManager.has_method("play_cash_register"):
		AudioManager.play_cash_register()

	pr_campaign_purchased.emit(current_pr_cost, 18.0, scandal_triggered)
	_refresh_balance_display()
	_refresh_button_states()


func _on_buy_audit_pressed() -> void:
	var wealth: int = GameManager.personal_wealth if GameManager != null else 0
	if wealth < current_audit_cost:
		_show_feedback(tr("UI_OFFSHORE_INSUFFICIENT"), Color(0.9, 0.3, 0.3, 1.0))
		return

	if GameManager != null and GameManager.event_flags.get("AUDIT_LEAK_REMAINING", 0) > 0:
		_show_feedback(tr("UI_OFFSHORE_AUDIT_ACTIVE"), Color(0.9, 0.8, 0.3, 1.0))
		return

	GameManager.personal_wealth -= current_audit_cost
	if GameManager != null:
		GameManager.event_flags["AUDIT_LEAK_REMAINING"] = 3
		GameManager.notify_stats_changed()

	if AudioManager != null and AudioManager.has_method("play_cash_register"):
		AudioManager.play_cash_register()

	_show_feedback(tr("UI_OFFSHORE_SUCCESS"), Color(0.4, 0.9, 0.5, 1.0))
	audit_leak_purchased.emit(current_audit_cost)
	_refresh_balance_display()
	_refresh_button_states()


func _on_buy_luxury_pressed() -> void:
	var wealth: int = GameManager.personal_wealth if GameManager != null else 0
	if wealth < current_luxury_cost:
		_show_feedback(tr("UI_OFFSHORE_INSUFFICIENT"), Color(0.9, 0.3, 0.3, 1.0))
		return

	# Gold Stamp vanity item
	GameManager.personal_wealth -= current_luxury_cost
	if GameManager != null:
		GameManager.event_flags["FLAG_GOLD_STAMP_UNLOCKED"] = true
		GameManager.notify_stats_changed()

	if AudioManager != null and AudioManager.has_method("play_cash_register"):
		AudioManager.play_cash_register()

	_show_feedback(tr("UI_OFFSHORE_SUCCESS"), Color(0.4, 0.9, 0.5, 1.0))
	luxury_item_purchased.emit("gold_stamp", current_luxury_cost)
	_refresh_balance_display()
	_refresh_button_states()


func _show_feedback(msg: String, color: Color) -> void:
	if not status_label:
		return
	status_label.text = msg
	status_label.add_theme_color_override("font_color", color)
	status_label.modulate.a = 1.0

	if _status_tween and _status_tween.is_valid():
		_status_tween.kill()

	_status_tween = create_tween()
	_status_tween.tween_interval(3.0)
	_status_tween.tween_property(status_label, "modulate:a", 0.0, 0.5)


func _format_money(amount: int) -> String:
	var s := str(abs(amount))
	var res := ""
	var cnt := 0
	for i in range(s.length() - 1, -1, -1):
		if cnt > 0 and cnt % 3 == 0:
			res = "," + res
		res = s[i] + res
		cnt += 1
	var prefix := "-" if amount < 0 else ""
	return "%s$%s" % [prefix, res]
