extends PanelContainer

## DocumentItem.gd - Tactile petition dossier sitting on mayor's desk.
## Houses both the Official Municipal Petition and the Inspector's Technical Report.
## Supports Papers, Please style cross-referencing and contradiction spotting.

signal stamped(approved: bool)
signal bribe_pocketed(amount: int)
signal slide_in_completed
signal slide_out_completed
signal data_point_selected(tag: String, label_text: String)
signal violation_uncovered(violation: Dictionary)

# Header & Tab Navigation
@onready var header_label: Label = %HeaderLabel
@onready var category_badge: Label = %CategoryBadge
@onready var tab_btn_app: Button = %TabBtnApp
@onready var tab_btn_rep: Button = %TabBtnRep
@onready var tab_btn_both: Button = %TabBtnBoth

# Pages
@onready var application_page: Control = %ApplicationPage
@onready var report_page: Control = %ReportPage

# Application Document Fields (Inspectable)
@onready var app_card_applicant: PanelContainer = %AppCardApplicant
@onready var title_label: Label = %TitleLabel
@onready var applicant_label: Label = %ApplicantLabel
@onready var app_card_district: PanelContainer = %AppCardDistrict
@onready var district_label: Label = %DistrictLabel
@onready var app_card_floors: PanelContainer = %AppCardFloors
@onready var floors_label: Label = %FloorsLabel
@onready var app_card_budget: PanelContainer = %AppCardBudget
@onready var budget_label: Label = %BudgetLabel
@onready var app_card_seal: PanelContainer = %AppCardSeal
@onready var seal_label: Label = %SealLabel
@onready var app_card_expiry: PanelContainer = %AppCardExpiry
@onready var expiry_label: Label = %ExpiryLabel
@onready var body_text_label: Label = %BodyTextLabel

# Inspector Report Fields (Inspectable)
@onready var rep_card_inspector: PanelContainer = %RepCardInspector
@onready var inspector_name_label: Label = %InspectorNameLabel
@onready var rep_card_measured: PanelContainer = %RepCardMeasured
@onready var measured_floors_label: Label = %MeasuredFloorsLabel
@onready var rep_card_hazard: PanelContainer = %RepCardHazard
@onready var hazard_label: Label = %HazardLabel
@onready var rep_card_tax: PanelContainer = %RepCardTax
@onready var tax_debt_label: Label = %TaxDebtLabel
@onready var rep_card_soil: PanelContainer = %RepCardSoil
@onready var soil_label: Label = %SoilLabel
@onready var inspector_notes_label: Label = %InspectorNotesLabel

# Bribe Container
@onready var bribe_container: PanelContainer = %BribeContainer
@onready var bribe_amount_label: Label = %BribeAmountLabel
@onready var btn_pocket_bribe: Button = %BtnPocketBribe

# Violation Alert Stamp
@onready var violation_alert_box: PanelContainer = %ViolationAlertBox
@onready var violation_alert_label: Label = %ViolationAlertLabel

# Stamp Overlay
@onready var stamp_overlay: PanelContainer = %StampOverlay
@onready var stamp_label: Label = %StampLabel

var current_event: EventData = null
var has_pocketed_bribe: bool = false
var is_stamped: bool = false
var is_inspect_mode: bool = false
var discovered_violations: Array[Dictionary] = []


func _ready() -> void:
	stamp_overlay.visible = false
	violation_alert_box.visible = false
	btn_pocket_bribe.pressed.connect(_on_pocket_bribe_pressed)

	tab_btn_app.pressed.connect(func(): _switch_dossier_tab(0))
	tab_btn_rep.pressed.connect(func(): _switch_dossier_tab(1))
	tab_btn_both.pressed.connect(func(): _switch_dossier_tab(2))

	_setup_all_inspectables()
	_switch_dossier_tab(0)


func setup_event(event: EventData) -> void:
	current_event = event
	is_stamped = false
	has_pocketed_bribe = false
	stamp_overlay.visible = false
	violation_alert_box.visible = false
	discovered_violations.clear()

	header_label.text = tr("UI_PETITION_HEADER")
	category_badge.text = event.category.to_upper()
	title_label.text = event.get_title()
	applicant_label.text = tr("UI_APPLICANT").format({"applicant": event.get_applicant()})
	body_text_label.text = event.get_description()

	tab_btn_app.text = tr("UI_TAB_APPLICATION")
	tab_btn_rep.text = tr("UI_TAB_REPORT")
	tab_btn_both.text = tr("UI_TAB_BOTH")

	var app: Dictionary = event.application_data
	var rep: Dictionary = event.report_data

	# Application Document data
	var dist_key: String = str(app.get("district_id", "DIST_CENTRAL"))
	district_label.text = tr("DOC_DISTRICT").format({"district": tr(dist_key)})

	var floors: int = int(app.get("floors", 4))
	floors_label.text = tr("DOC_FLOORS").format({"floors": floors})

	var budget_val: int = int(app.get("budget_stated", 50000))
	budget_label.text = tr("DOC_BUDGET").format({"amount": _format_money(budget_val)})

	var seal_key: String = str(app.get("seal_id", "SEAL_MINISTRY_VALID"))
	seal_label.text = tr("DOC_SEAL").format({"seal": tr(seal_key)})

	var expiry_val: String = str(app.get("expiry_date", "2026-12-31"))
	expiry_label.text = tr("DOC_EXPIRY").format({"date": expiry_val})

	# Inspector Report data
	var insp_key: String = str(rep.get("inspector_name_key", "INSP_KAYA"))
	inspector_name_label.text = tr("DOC_INSPECTOR").format({"name": tr(insp_key)})

	var meas_floors: int = int(rep.get("measured_floors", floors))
	measured_floors_label.text = tr("DOC_MEASURED_FLOORS").format({"floors": meas_floors})

	var hazard_key: String = str(rep.get("hazard_level", "HAZARD_NONE"))
	hazard_label.text = tr("DOC_HAZARD").format({"hazard": tr(hazard_key)})

	var tax_val: int = int(rep.get("tax_debt", 0))
	tax_debt_label.text = tr("DOC_TAX_STATUS").format({"debt": _format_money(tax_val)})

	var soil_key: String = str(rep.get("soil_status", "SOIL_GRADE_A"))
	soil_label.text = tr("DOC_SOIL_STATUS").format({"status": tr(soil_key)})

	var notes_key: String = str(rep.get("notes_key", "EVT_004_INSP_NOTES"))
	inspector_notes_label.text = tr("DOC_NOTES").format({"notes": tr(notes_key)})

	# Bribe envelope setup
	if event.bribe_offered > 0:
		bribe_container.visible = true
		bribe_amount_label.text = tr("UI_BRIBE_OFFERED").format({
			"amount": _format_money(event.bribe_offered)
		})
		btn_pocket_bribe.text = tr("UI_BRIBE_POCKET")
		btn_pocket_bribe.disabled = false
	else:
		bribe_container.visible = false


func switch_dossier_tab(tab_idx: int) -> void:
	AudioManager.play_page_flip()
	if tab_idx == 0:
		application_page.visible = true
		report_page.visible = false
	elif tab_idx == 1:
		application_page.visible = false
		report_page.visible = true
	else:
		# Side by side: both visible
		application_page.visible = true
		report_page.visible = true

	var active_color := Color(0.95, 0.82, 0.35, 1)
	var inactive_color := Color(0.7, 0.72, 0.8, 1)
	var col_app := active_color if tab_idx == 0 else inactive_color
	var col_rep := active_color if tab_idx == 1 else inactive_color
	var col_both := active_color if tab_idx == 2 else inactive_color
	tab_btn_app.set("theme_override_colors/font_color", col_app)
	tab_btn_rep.set("theme_override_colors/font_color", col_rep)
	tab_btn_both.set("theme_override_colors/font_color", col_both)


func _switch_dossier_tab(tab_idx: int) -> void:
	switch_dossier_tab(tab_idx)


func _setup_all_inspectables() -> void:
	_bind_inspectable(app_card_applicant, "app_applicant")
	_bind_inspectable(app_card_district, "app_district")
	_bind_inspectable(app_card_floors, "app_floors")
	_bind_inspectable(app_card_budget, "app_budget")
	_bind_inspectable(app_card_seal, "app_seal")
	_bind_inspectable(app_card_expiry, "app_expiry")

	_bind_inspectable(rep_card_inspector, "rep_inspector")
	_bind_inspectable(rep_card_measured, "rep_measured_floors")
	_bind_inspectable(rep_card_hazard, "rep_hazard")
	_bind_inspectable(rep_card_tax, "rep_tax_debt")
	_bind_inspectable(rep_card_soil, "rep_soil")


func _bind_inspectable(panel: PanelContainer, tag: String) -> void:
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
			_on_field_clicked(panel, tag)
	)
	panel.mouse_entered.connect(func():
		if is_inspect_mode:
			panel.modulate = Color(1.25, 1.2, 0.9, 1)
	)
	panel.mouse_exited.connect(func():
		panel.modulate = Color(1, 1, 1, 1)
	)


func _on_field_clicked(panel: PanelContainer, tag: String) -> void:
	var tween := create_tween()
	tween.tween_property(panel, "scale", Vector2(1.03, 1.03), 0.08)
	tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.1)
	data_point_selected.emit(tag, tag)


func set_inspect_mode(active: bool) -> void:
	is_inspect_mode = active


## Called when player finds a legitimate discrepancy
func mark_violation_found(violation: Dictionary) -> void:
	if not discovered_violations.has(violation):
		discovered_violations.append(violation)

	var viol_name_key: String = str(violation.get("name_key", "VIOL_HEIGHT_LIMIT"))
	var viol_name: String = tr(viol_name_key)

	violation_alert_box.visible = true
	violation_alert_label.text = tr("UI_DISCREPANCY_FOUND").format({"violation": viol_name})

	# Dramatic slap animation for violation alert
	violation_alert_box.scale = Vector2(1.3, 1.3)
	var tween := create_tween()
	tween.tween_property(
		violation_alert_box, "scale", Vector2(1.0, 1.0), 0.2
	).set_trans(Tween.TRANS_BOUNCE)

	violation_uncovered.emit(violation)


func _on_pocket_bribe_pressed() -> void:
	pocket_bribe()


## Public method to stash the bribe into personal safe
func pocket_bribe() -> void:
	if has_pocketed_bribe or current_event == null or current_event.bribe_offered <= 0:
		return

	has_pocketed_bribe = true
	btn_pocket_bribe.disabled = true
	btn_pocket_bribe.text = tr("UI_BRIBE_STASHED")

	var tween := create_tween()
	tween.tween_property(bribe_container, "scale", Vector2(1.08, 1.08), 0.1)
	tween.tween_property(bribe_container, "scale", Vector2(1.0, 1.0), 0.15)

	bribe_pocketed.emit(current_event.bribe_offered)


## Animates paper sliding onto desk
func animate_slide_in(from_pos: Vector2, to_pos: Vector2, rest_rotation: float = -0.01) -> void:
	position = from_pos
	rotation = 0.05
	modulate.a = 0.0

	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", to_pos, 0.55)
	tween.tween_property(self, "rotation", rest_rotation, 0.55)
	tween.tween_property(self, "modulate:a", 1.0, 0.4)
	tween.finished.connect(func(): slide_in_completed.emit())


## Ink stamp slam scale-tween
func apply_stamp_visual(approved: bool) -> void:
	if is_stamped:
		return
	is_stamped = true

	stamp_overlay.visible = true
	stamp_overlay.scale = Vector2(2.4, 2.4)
	stamp_overlay.modulate.a = 0.0

	if approved:
		stamp_label.text = tr("UI_STAMP_APPROVED")
		stamp_overlay.rotation = -0.16
		stamp_label.set("theme_override_colors/font_color", Color(0.12, 0.75, 0.38, 1))
	else:
		stamp_label.text = tr("UI_STAMP_REJECTED")
		stamp_overlay.rotation = 0.20
		stamp_label.set("theme_override_colors/font_color", Color(0.92, 0.22, 0.22, 1))

	var tween := create_tween().set_parallel(true)
	tween.tween_property(stamp_overlay, "scale", Vector2(1.0, 1.0), 0.22).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)
	tween.tween_property(stamp_overlay, "modulate:a", 1.0, 0.15)

	stamped.emit(approved)


## Slides stamped document out to the right offscreen
func animate_slide_out(to_pos: Vector2) -> void:
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position", to_pos, 0.45)
	tween.tween_property(self, "rotation", rotation + 0.12, 0.45)
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.finished.connect(func(): slide_out_completed.emit())


func _format_money(amount: int) -> String:
	var abs_str: String = str(absi(amount))
	var out: String = ""
	var count: int = 0
	for i in range(abs_str.length() - 1, -1, -1):
		out = abs_str[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "," + out
	return out
