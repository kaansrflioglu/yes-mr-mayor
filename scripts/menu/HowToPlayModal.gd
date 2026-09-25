extends Control

## HowToPlayModal.gd - Interactive municipal manual and operating guidelines.
## Provides structured tabs explaining dossier inspection, decision stamps, hotline, and safe.

signal modal_closed

var is_open: bool = false
var _active_tab: int = 0

@onready var backdrop: ColorRect = %Backdrop
@onready var modal_panel: PanelContainer = %ModalPanel
@onready var title_label: Label = %TitleLabel
@onready var btn_header_close: Button = %BtnHeaderClose
@onready var btn_footer_close: Button = %BtnFooterClose

@onready var btn_tab_inspect: Button = %BtnTabInspect
@onready var btn_tab_stamps: Button = %BtnTabStamps
@onready var btn_tab_hotline: Button = %BtnTabHotline
@onready var btn_tab_offshore: Button = %BtnTabOffshore

@onready var section_badge: Label = %SectionBadge
@onready var section_title: Label = %SectionTitle
@onready var section_desc: Label = %SectionDesc
@onready var tip_label: Label = %TipLabel

var _tab_buttons: Array[Button] = []


func _ready() -> void:
	visible = false
	_tab_buttons = [
		btn_tab_inspect,
		btn_tab_stamps,
		btn_tab_hotline,
		btn_tab_offshore
	]
	_connect_events()
	_update_locale_texts()
	_switch_tab(0)
	LocalizationManager.locale_changed.connect(func(_loc): _on_locale_changed())


func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func open() -> void:
	is_open = true
	visible = true
	_update_locale_texts()
	_switch_tab(_active_tab)

	modal_panel.scale = Vector2(0.95, 0.95)
	modulate.a = 0.0

	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.22)
	tween.tween_property(modal_panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK)

	AudioManager.play_inspect_toggle()


func close() -> void:
	if not is_open:
		return
	is_open = false

	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.18)
	tween.tween_property(modal_panel, "scale", Vector2(0.95, 0.95), 0.18)
	tween.chain().tween_callback(func():
		visible = false
		modal_closed.emit()
	)

	AudioManager.play_paper_slide()


func _connect_events() -> void:
	btn_header_close.pressed.connect(close)
	btn_footer_close.pressed.connect(close)

	btn_tab_inspect.pressed.connect(func(): _switch_tab(0))
	btn_tab_stamps.pressed.connect(func(): _switch_tab(1))
	btn_tab_hotline.pressed.connect(func(): _switch_tab(2))
	btn_tab_offshore.pressed.connect(func(): _switch_tab(3))


func _switch_tab(index: int) -> void:
	_active_tab = index
	AudioManager.play_inspect_toggle()

	for i in range(_tab_buttons.size()):
		var btn := _tab_buttons[i]
		if i == index:
			btn.modulate = Color(1.0, 0.95, 0.7, 1.0)
		else:
			btn.modulate = Color(0.7, 0.75, 0.85, 0.7)

	_render_tab_content(index)


func _render_tab_content(index: int) -> void:
	match index:
		0:
			section_badge.text = "SECTION 01 // AUDITING & DISCREPANCIES"
			section_title.text = tr("UI_HTP_TITLE_INSPECT")
			section_desc.text = tr("UI_HTP_BODY_INSPECT")
			tip_label.text = "TIP: Counterfeit seals omit 'T.C.' or show years prior to 2026."
		1:
			section_badge.text = "SECTION 02 // STAMPING & FATE"
			section_title.text = tr("UI_HTP_TITLE_STAMPS")
			section_desc.text = tr("UI_HTP_BODY_STAMPS")
			tip_label.text = (
				"TIP: Rejecting corrupt barons earns trust; "
				+ "approving megaprojects funds city treasury."
			)
		2:
			section_badge.text = "SECTION 03 // EMERGENCY PROTOCOLS"
			section_title.text = tr("UI_HTP_TITLE_HOTLINE")
			section_desc.text = tr("UI_HTP_BODY_HOTLINE")
			tip_label.text = "TIP: When the red phone rings, answer promptly before time runs out."
		3:
			section_badge.text = "SECTION 04 // MORALITY & WEALTH"
			section_title.text = tr("UI_HTP_TITLE_OFFSHORE")
			section_desc.text = tr("UI_HTP_BODY_OFFSHORE")
			tip_label.text = (
				"TIP: Bribes fatten your Swiss safe, "
				+ "but excess corruption triggers federal arrest."
			)


func _update_locale_texts() -> void:
	title_label.text = tr("UI_HOW_TO_PLAY_TITLE")
	btn_tab_inspect.text = tr("UI_HTP_TAB_INSPECT")
	btn_tab_stamps.text = tr("UI_HTP_TAB_STAMPS")
	btn_tab_hotline.text = tr("UI_HTP_TAB_HOTLINE")
	btn_tab_offshore.text = tr("UI_HTP_TAB_OFFSHORE")
	btn_footer_close.text = tr("UI_HTP_BTN_CLOSE")
	_render_tab_content(_active_tab)


func _on_locale_changed() -> void:
	if is_open:
		_update_locale_texts()
