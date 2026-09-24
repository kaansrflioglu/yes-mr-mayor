extends PanelContainer

## Rulebook.gd - Municipal Code & Regulatory Manual
## Provides zoning rules, authentic seal references, corporate blacklist, and daily directives.
## Supports Papers, Please style inspection by emitting rule tags when clicked.

signal rule_tag_selected(tag: String, label_text: String)
signal visibility_toggled(is_open: bool)

@onready var tab_btn_zoning: Button = %TabBtnZoning
@onready var tab_btn_seals: Button = %TabBtnSeals
@onready var tab_btn_blacklist: Button = %TabBtnBlacklist
@onready var tab_btn_orders: Button = %TabBtnOrders

@onready var page_zoning: Control = %PageZoning
@onready var page_seals: Control = %PageSeals
@onready var page_blacklist: Control = %PageBlacklist
@onready var page_orders: Control = %PageOrders

@onready var title_label: Label = %TitleLabel
@onready var btn_close: Button = %BtnClose

# Inspectable items in rulebook
@onready var rule_historic_box: PanelContainer = %RuleHistoricBox
@onready var rule_river_box: PanelContainer = %RuleRiverBox
@onready var rule_central_box: PanelContainer = %RuleCentralBox
@onready var rule_green_box: PanelContainer = %RuleGreenBox
@onready var rule_industrial_box: PanelContainer = %RuleIndustrialBox
@onready var rule_tax_box: PanelContainer = %RuleTaxBox
@onready var rule_seal_box: PanelContainer = %RuleSealBox
@onready var rule_blacklist_box: PanelContainer = %RuleBlacklistBox
@onready var rule_orders_box: PanelContainer = %RuleOrdersBox

var is_open: bool = false
var is_inspect_mode: bool = false
var selected_tag: String = ""


func _ready() -> void:
	tab_btn_zoning.pressed.connect(func(): _switch_tab(0))
	tab_btn_seals.pressed.connect(func(): _switch_tab(1))
	tab_btn_blacklist.pressed.connect(func(): _switch_tab(2))
	tab_btn_orders.pressed.connect(func(): _switch_tab(3))
	btn_close.pressed.connect(toggle_rulebook)

	_setup_inspectable(rule_historic_box, "rule_zoning_historic", tr("RULE_ZONING_HISTORIC"))
	_setup_inspectable(rule_river_box, "rule_zoning_river", tr("RULE_ZONING_RIVER"))
	_setup_inspectable(rule_central_box, "rule_zoning_central", tr("RULE_ZONING_CENTRAL"))
	_setup_inspectable(rule_green_box, "rule_zoning_green", tr("RULE_ZONING_GREEN"))
	_setup_inspectable(rule_industrial_box, "rule_zoning_industrial", tr("RULE_ZONING_INDUSTRIAL"))
	_setup_inspectable(rule_tax_box, "rule_tax_guide", tr("RULE_TAX_GUIDE"))
	_setup_inspectable(rule_seal_box, "rule_seal_guide", tr("RULE_SEAL_GUIDE"))
	_setup_inspectable(rule_blacklist_box, "rule_blacklist_guide", tr("RULE_BLACKLIST_GUIDE"))
	_setup_inspectable(rule_orders_box, "rule_order_d1", tr("RULE_ORDER_D1"))

	_update_locale_texts()
	LocalizationManager.locale_changed.connect(func(_l): _update_locale_texts())
	_switch_tab(0)


func _update_locale_texts() -> void:
	title_label.text = tr("UI_RULEBOOK_TITLE")
	tab_btn_zoning.text = tr("UI_TAB_ZONING")
	tab_btn_seals.text = tr("UI_TAB_SEALS")
	tab_btn_blacklist.text = tr("UI_TAB_BLACKLIST")
	tab_btn_orders.text = tr("UI_TAB_ORDERS")


func switch_tab(tab_idx: int) -> void:
	AudioManager.play_page_flip()
	page_zoning.visible = (tab_idx == 0)
	page_seals.visible = (tab_idx == 1)
	page_blacklist.visible = (tab_idx == 2)
	page_orders.visible = (tab_idx == 3)

	var active_color := Color(0.95, 0.82, 0.35, 1)
	var inactive_color := Color(0.7, 0.72, 0.8, 1)
	var col_zoning := active_color if tab_idx == 0 else inactive_color
	var col_seals := active_color if tab_idx == 1 else inactive_color
	var col_black := active_color if tab_idx == 2 else inactive_color
	var col_orders := active_color if tab_idx == 3 else inactive_color

	tab_btn_zoning.set("theme_override_colors/font_color", col_zoning)
	tab_btn_seals.set("theme_override_colors/font_color", col_seals)
	tab_btn_blacklist.set("theme_override_colors/font_color", col_black)
	tab_btn_orders.set("theme_override_colors/font_color", col_orders)


func _switch_tab(tab_idx: int) -> void:
	switch_tab(tab_idx)


func toggle_rulebook() -> void:
	is_open = not is_open
	visible = is_open
	AudioManager.play_page_flip()
	visibility_toggled.emit(is_open)


func set_inspect_mode(active: bool) -> void:
	is_inspect_mode = active
	_refresh_highlight_styles()


func clear_selection() -> void:
	selected_tag = ""
	_refresh_highlight_styles()


func _setup_inspectable(panel: PanelContainer, tag: String, text_preview: String) -> void:
	if panel == null:
		return
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.gui_input.connect(func(event: InputEvent):
		var is_click: bool = (
			event is InputEventMouseButton
			and event.button_index == MOUSE_BUTTON_LEFT
			and event.pressed
		)
		if is_click:
			_on_rule_clicked(tag, text_preview, panel)
	)
	panel.mouse_entered.connect(func():
		if is_inspect_mode:
			panel.modulate = Color(1.2, 1.2, 1.2, 1)
	)
	panel.mouse_exited.connect(func():
		panel.modulate = Color(1, 1, 1, 1)
	)


func _on_rule_clicked(tag: String, text_preview: String, panel: PanelContainer) -> void:
	selected_tag = tag
	var tween := create_tween()
	tween.tween_property(panel, "scale", Vector2(1.02, 1.02), 0.08)
	tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.1)
	rule_tag_selected.emit(tag, text_preview)


func _refresh_highlight_styles() -> void:
	# Subtle visual hint for inspect mode
	modulate = Color(1.02, 1.02, 1.0, 1.0) if is_inspect_mode else Color(1, 1, 1, 1)
