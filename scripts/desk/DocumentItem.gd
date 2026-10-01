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
@onready var department_crest: TextureRect = (
	%DepartmentCrest if has_node("%DepartmentCrest") else null
)
@onready var tab_btn_app: Button = %TabBtnApp
@onready var tab_btn_rep: Button = %TabBtnRep
@onready var tab_btn_both: Button = %TabBtnBoth

# Pages
@onready var pages_container: HBoxContainer = (
	%PagesContainer if has_node("%PagesContainer") else null
)
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
@onready var bribe_keycap: Control = %BribeKeycap if has_node("%BribeKeycap") else null

# Violation Alert Stamp & China Marker Layer
@onready var violation_alert_box: PanelContainer = %ViolationAlertBox
@onready var violation_alert_label: Label = %ViolationAlertLabel
@onready var discrepancy_line_layer: Control = (
	%DiscrepancyLineLayer if has_node("%DiscrepancyLineLayer") else null
)

# Stamp Overlay & Decal
@onready var stamp_overlay: PanelContainer = %StampOverlay
@onready var stamp_label: Label = %StampLabel
@onready var stamp_decal: TextureRect = (
	%StampDecal if has_node("%StampDecal") else null
)

# Visual Shadow & Paper Elevation
@onready var paper_shadow: Panel = %PaperShadow if has_node("%PaperShadow") else null

# UV Blacklight
@onready var uv_overlay: Control = %UVOverlay if has_node("%UVOverlay") else null
@onready var uv_seal_label: Label = %UVSealLabel if has_node("%UVSealLabel") else null
@onready var uv_bribe_label: Label = %UVBribeLabel if has_node("%UVBribeLabel") else null
@onready var uv_expiry_label: Label = (
	%UVExpiryLabel if has_node("%UVExpiryLabel") else null
)

var current_event: EventData = null
var has_pocketed_bribe: bool = false
var is_stamped: bool = false
var is_inspect_mode: bool = false
var is_uv_active: bool = false
var discovered_violations: Array[Dictionary] = []
var current_tab_idx: int = 0

# Dragging & Physical Inertia
var is_doc_dragging: bool = false
var drag_mouse_offset: Vector2 = Vector2.ZERO
var prev_mouse_pos: Vector2 = Vector2.ZERO


func _ready() -> void:
	stamp_overlay.visible = false
	violation_alert_box.visible = false
	if uv_overlay != null:
		uv_overlay.visible = false
	btn_pocket_bribe.pressed.connect(_on_pocket_bribe_pressed)
	if SettingsManager != null:
		set_keycap_hint_visible(SettingsManager.show_hotkey_hints)

	tab_btn_app.pressed.connect(func(): _switch_dossier_tab(0))
	tab_btn_rep.pressed.connect(func(): _switch_dossier_tab(1))
	tab_btn_both.pressed.connect(func(): _switch_dossier_tab(2))

	gui_input.connect(_on_document_gui_input)

	_setup_all_inspectables()
	_switch_dossier_tab(0)
	setup_focus_mode()


func _on_document_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_start_document_drag(event.global_position)
			elif is_doc_dragging:
				_finish_document_drag()


func _start_document_drag(mouse_glob: Vector2) -> void:
	is_doc_dragging = true
	drag_mouse_offset = global_position - mouse_glob
	prev_mouse_pos = mouse_glob
	z_index = 40

	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.03, 1.03), 0.12).set_trans(
		Tween.TRANS_QUAD
	).set_ease(Tween.EASE_OUT)
	if paper_shadow != null:
		tween.tween_property(paper_shadow, "position:y", 28.0, 0.12)
		tween.tween_property(paper_shadow, "modulate:a", 0.55, 0.12)


func _finish_document_drag() -> void:
	is_doc_dragging = false
	z_index = 0

	var rest_rot: float = randf_range(-0.015, 0.015)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, 0.15).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation", rest_rot, 0.15).set_trans(Tween.TRANS_QUAD)
	if paper_shadow != null:
		tween.tween_property(paper_shadow, "position:y", 14.0, 0.15)
		tween.tween_property(paper_shadow, "modulate:a", 0.42, 0.15)


func _process(delta: float) -> void:
	if is_doc_dragging:
		var cur_mouse := get_global_mouse_position()
		var target_pos := cur_mouse + drag_mouse_offset
		var vel_x: float = (cur_mouse.x - prev_mouse_pos.x) / maxf(delta, 0.001)
		prev_mouse_pos = cur_mouse
		global_position = target_pos
		rotation = clampf(vel_x * 0.00008, -0.06, 0.06)


func setup_focus_mode(custom_focus_box: StyleBox = null) -> void:
	var focus_box: StyleBox = custom_focus_box
	if focus_box == null:
		var fb := StyleBoxFlat.new()
		fb.draw_center = false
		fb.border_width_left = 2
		fb.border_width_top = 2
		fb.border_width_right = 2
		fb.border_width_bottom = 2
		fb.border_color = Color(1.0, 0.85, 0.35, 1.0)
		fb.corner_radius_top_left = 4
		fb.corner_radius_top_right = 4
		fb.corner_radius_bottom_right = 4
		fb.corner_radius_bottom_left = 4
		focus_box = fb

	var doc_btns: Array[Button] = [tab_btn_app, tab_btn_rep, tab_btn_both]
	if btn_pocket_bribe != null:
		doc_btns.append(btn_pocket_bribe)

	for b in doc_btns:
		if b != null and is_instance_valid(b):
			b.focus_mode = Control.FOCUS_ALL
			b.add_theme_stylebox_override("focus", focus_box)

	tab_btn_app.focus_neighbor_right = tab_btn_rep.get_path()
	tab_btn_app.focus_neighbor_left = tab_btn_both.get_path()

	tab_btn_rep.focus_neighbor_left = tab_btn_app.get_path()
	tab_btn_rep.focus_neighbor_right = tab_btn_both.get_path()

	tab_btn_both.focus_neighbor_left = tab_btn_rep.get_path()
	tab_btn_both.focus_neighbor_right = tab_btn_app.get_path()

	if btn_pocket_bribe != null:
		tab_btn_app.focus_neighbor_bottom = btn_pocket_bribe.get_path()
		tab_btn_rep.focus_neighbor_bottom = btn_pocket_bribe.get_path()
		tab_btn_both.focus_neighbor_bottom = btn_pocket_bribe.get_path()
		btn_pocket_bribe.focus_neighbor_top = tab_btn_app.get_path()


func setup_event(event: EventData) -> void:
	current_event = event
	is_stamped = false
	has_pocketed_bribe = false
	stamp_overlay.visible = false
	violation_alert_box.visible = false
	discovered_violations.clear()
	_clear_discrepancy_lines()
	_update_uv_watermarks()

	header_label.text = tr("UI_PETITION_HEADER")
	category_badge.text = event.category.to_upper()
	title_label.text = event.get_title()
	applicant_label.text = tr("UI_APPLICANT").format({"applicant": event.get_applicant()})
	body_text_label.text = event.get_description()

	tab_btn_app.text = tr("UI_TAB_APPLICATION")
	tab_btn_rep.text = tr("UI_TAB_REPORT")
	tab_btn_both.text = tr("UI_TAB_BOTH")

	# Update Department Crest
	_update_department_crest(event.category)

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


func _update_department_crest(category: String) -> void:
	if department_crest == null:
		return
	var cat_lower := category.to_lower()
	var crest_path := "res://assets/sprites/documents/crest_housing.png"

	if "sanitation" in cat_lower or "waste" in cat_lower or "health" in cat_lower:
		crest_path = "res://assets/sprites/documents/crest_sanitation.png"
	elif "police" in cat_lower or "security" in cat_lower or "crime" in cat_lower:
		crest_path = "res://assets/sprites/documents/crest_police.png"
	elif (
		"treasury" in cat_lower or "tax" in cat_lower
		or "finance" in cat_lower or "budget" in cat_lower
	):
		crest_path = "res://assets/sprites/documents/crest_treasury.png"
	elif "oligarch" in cat_lower or "corruption" in cat_lower or "corporate" in cat_lower:
		crest_path = "res://assets/sprites/documents/crest_oligarch.png"
	elif "housing" in cat_lower or "zoning" in cat_lower or "construction" in cat_lower:
		crest_path = "res://assets/sprites/documents/crest_housing.png"

	if ResourceLoader.exists(crest_path):
		department_crest.texture = load(crest_path)


func switch_dossier_tab(tab_idx: int) -> void:
	current_tab_idx = tab_idx
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
	var inactive_color := Color(0.3, 0.28, 0.24, 1)
	var col_app := active_color if tab_idx == 0 else inactive_color
	var col_rep := active_color if tab_idx == 1 else inactive_color
	var col_both := active_color if tab_idx == 2 else inactive_color
	tab_btn_app.set("theme_override_colors/font_color", col_app)
	tab_btn_rep.set("theme_override_colors/font_color", col_rep)
	tab_btn_both.set("theme_override_colors/font_color", col_both)


func flip_next_page() -> void:
	var next_idx: int = (current_tab_idx + 1) % 3
	switch_dossier_tab(next_idx)


func flip_prev_page() -> void:
	var prev_idx: int = (current_tab_idx - 1 + 3) % 3
	switch_dossier_tab(prev_idx)


func _switch_dossier_tab(tab_idx: int) -> void:
	switch_dossier_tab(tab_idx)


func _setup_all_inspectables() -> void:
	_bind_inspectable(app_card_applicant, "app_applicant")
	_bind_inspectable(app_card_district, "app_district")
	_bind_inspectable(app_card_floors, "app_floors")
	_bind_inspectable(app_card_budget, "app_budget")
	_bind_inspectable(app_card_seal, "app_seal")
	_bind_inspectable(app_card_expiry, "app_expiry")
	if body_text_label != null:
		var parent_panel = body_text_label.get_parent() as Control
		var app_target: Control = (
			parent_panel if parent_panel is PanelContainer else body_text_label
		)
		_bind_inspectable(app_target, "app_description")

	_bind_inspectable(rep_card_inspector, "rep_inspector")
	_bind_inspectable(rep_card_measured, "rep_measured_floors")
	_bind_inspectable(rep_card_hazard, "rep_hazard")
	_bind_inspectable(rep_card_tax, "rep_tax_debt")
	_bind_inspectable(rep_card_soil, "rep_soil")
	if inspector_notes_label != null:
		var parent_panel = inspector_notes_label.get_parent() as Control
		var rep_target: Control = (
			parent_panel if parent_panel is PanelContainer else inspector_notes_label
		)
		_bind_inspectable(rep_target, "rep_notes")


func _bind_inspectable(panel: Control, tag: String) -> void:
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


func _on_field_clicked(panel: Control, tag: String) -> void:
	var tween := create_tween()
	tween.tween_property(panel, "scale", Vector2(1.03, 1.03), 0.08)
	tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.1)
	data_point_selected.emit(tag, tag)


func set_inspect_mode(active: bool) -> void:
	is_inspect_mode = active


func set_keycap_hint_visible(hint_visible: bool) -> void:
	if bribe_keycap != null:
		bribe_keycap.visible = hint_visible


## Called when player finds a legitimate discrepancy
func mark_violation_found(violation: Dictionary) -> void:
	if not discovered_violations.has(violation):
		discovered_violations.append(violation)

	var viol_name_key: String = str(violation.get("name_key", "VIOL_HEIGHT_LIMIT"))
	var viol_name: String = tr(viol_name_key)

	violation_alert_box.visible = true
	violation_alert_label.text = tr("UI_DISCREPANCY_FOUND").format({"violation": viol_name})

	# Dramatic bounce animation for violation alert
	violation_alert_box.scale = Vector2(1.3, 1.3)
	var tween := create_tween()
	tween.tween_property(
		violation_alert_box, "scale", Vector2(1.0, 1.0), 0.2
	).set_trans(Tween.TRANS_BOUNCE)

	# Hand-drawn red china marker underline
	var tags: Array = violation.get("tags", [])
	if not tags.is_empty():
		_draw_china_marker_for_tag(str(tags[0]))

	violation_uncovered.emit(violation)


## Highlights a suspicious field on the dossier with red pencil and glow
func highlight_suspicious_field(field_tag: String = "") -> void:
	var target_panel: Control = _get_panel_for_tag(field_tag)

	# If the field is on a hidden page, switch to side-by-side view
	var norm_tag := field_tag.to_lower()
	if norm_tag.begins_with("rep_") and report_page != null and not report_page.visible:
		switch_dossier_tab(2)
	elif norm_tag.begins_with("app_") and application_page != null and not application_page.visible:
		switch_dossier_tab(2)

	if target_panel != null:
		var tween := create_tween().set_loops(3)
		tween.tween_property(target_panel, "modulate", Color(1.5, 1.35, 0.35, 1.0), 0.22)
		tween.tween_property(target_panel, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.22)
		_draw_china_marker_for_panel(target_panel)


func _get_panel_for_tag(field_tag: String) -> Control:
	var norm_tag := field_tag.to_lower()
	match norm_tag:
		"app_applicant": return app_card_applicant
		"app_district": return app_card_district
		"app_floors": return app_card_floors
		"app_budget": return app_card_budget
		"app_seal": return app_card_seal
		"app_expiry": return app_card_expiry
		"app_description":
			var bp: Control = (
				body_text_label.get_parent() as Control if body_text_label != null else null
			)
			return bp if bp is PanelContainer else body_text_label
		"rep_inspector": return rep_card_inspector
		"rep_measured_floors": return rep_card_measured
		"rep_hazard": return rep_card_hazard
		"rep_tax_debt": return rep_card_tax
		"rep_soil": return rep_card_soil
		"rep_notes":
			var ip: Control = (
				inspector_notes_label.get_parent() as Control
				if inspector_notes_label != null else null
			)
			return ip if ip is PanelContainer else inspector_notes_label
		_:
			return app_card_seal if app_card_seal != null else app_card_applicant


func _draw_china_marker_for_tag(tag: String) -> void:
	var panel := _get_panel_for_tag(tag)
	if panel != null:
		_draw_china_marker_for_panel(panel)


func _draw_china_marker_for_panel(panel: Control) -> void:
	if discrepancy_line_layer == null or panel == null:
		return
	if not is_inside_tree() or not panel.is_inside_tree():
		return

	var rect: Rect2 = panel.get_global_rect()
	var local_top_left: Vector2 = rect.position - discrepancy_line_layer.global_position
	var width: float = rect.size.x
	var height: float = rect.size.y

	var line := Line2D.new()
	line.default_color = Color(0.7, 0.13, 0.13, 0.85) # Crimson red china marker
	line.width = 3.0
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND

	# Underline path with slight organic wobble
	var start_pt: Vector2 = local_top_left + Vector2(4.0, height + 1.0)
	var mid_pt1: Vector2 = local_top_left + Vector2(width * 0.35, height + randf_range(0.0, 3.0))
	var mid_pt2: Vector2 = local_top_left + Vector2(width * 0.7, height + randf_range(-1.0, 2.0))
	var end_pt: Vector2 = local_top_left + Vector2(width - 4.0, height + 1.0)

	line.add_point(start_pt)
	line.add_point(mid_pt1)
	line.add_point(mid_pt2)
	line.add_point(end_pt)

	discrepancy_line_layer.add_child(line)


func _clear_discrepancy_lines() -> void:
	if discrepancy_line_layer != null:
		for c in discrepancy_line_layer.get_children():
			c.queue_free()


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


## Ink stamp slam scale-tween (default center position)
func apply_stamp_visual(approved: bool) -> void:
	var def_pos: Vector2 = global_position + (size * 0.5)
	var def_rot: float = -0.16 if approved else 0.20
	apply_stamp_visual_at(def_pos, def_rot, approved)


## Ink stamp slam scale-tween at specific target global coordinate and rotation
func apply_stamp_visual_at(target_pos: Vector2, stamp_rot: float, approved: bool) -> void:
	if is_stamped:
		return
	is_stamped = true

	stamp_overlay.visible = true
	stamp_overlay.position = (target_pos - global_position) - (stamp_overlay.size * 0.5)
	stamp_overlay.rotation = stamp_rot
	stamp_overlay.scale = Vector2(2.4, 2.4)
	stamp_overlay.modulate.a = 0.0

	var ink_col: Color
	if approved:
		stamp_label.text = tr("UI_STAMP_APPROVED")
		stamp_label.set("theme_override_colors/font_color", Color(0.12, 0.75, 0.38, 1))
		ink_col = Color(0.12, 0.55, 0.28, 1.0)
		var app_decal := "res://assets/sprites/documents/stamp_decal_approve.png"
		if stamp_decal != null and ResourceLoader.exists(app_decal):
			stamp_decal.texture = load(app_decal)
	else:
		stamp_label.text = tr("UI_STAMP_REJECTED")
		stamp_label.set("theme_override_colors/font_color", Color(0.92, 0.22, 0.22, 1))
		ink_col = Color(0.85, 0.18, 0.18, 1.0)
		var rej_decal := "res://assets/sprites/documents/stamp_decal_reject.png"
		if stamp_decal != null and ResourceLoader.exists(rej_decal):
			stamp_decal.texture = load(rej_decal)

	# Configure ink absorption & drying shader
	if stamp_decal != null and stamp_decal.material is ShaderMaterial:
		var sm := stamp_decal.material as ShaderMaterial
		sm.set_shader_parameter("ink_color", ink_col)
		sm.set_shader_parameter("dry_progress", 0.0)
		var bleed_tween := create_tween()
		bleed_tween.tween_method(func(val: float):
			if is_instance_valid(sm):
				sm.set_shader_parameter("dry_progress", val)
		, 0.0, 1.0, 1.2)

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


## Toggles tactical UV blacklight on the document
func set_uv_blacklight(active: bool) -> void:
	is_uv_active = active
	if uv_overlay != null:
		uv_overlay.visible = active
		if uv_overlay.material is ShaderMaterial:
			uv_overlay.material.set_shader_parameter("uv_active", active)
	_update_uv_watermarks()


## Updates UV ink markings based on event data
func _update_uv_watermarks() -> void:
	if not is_uv_active:
		if uv_seal_label != null:
			uv_seal_label.visible = false
		if uv_bribe_label != null:
			uv_bribe_label.visible = false
		if uv_expiry_label != null:
			uv_expiry_label.visible = false
		return

	if current_event == null:
		return

	var has_forged_seal: bool = false
	var has_expired_permit: bool = false
	for viol in current_event.violations:
		var v_id: String = str(viol.get("id", ""))
		if v_id == "VIOL_FORGED_SEAL":
			has_forged_seal = true
		elif v_id == "VIOL_PERMIT_EXPIRED":
			has_expired_permit = true

	if uv_seal_label != null:
		uv_seal_label.visible = true
		if has_forged_seal:
			uv_seal_label.text = tr("UI_UV_FORGED_SEAL")
			uv_seal_label.modulate = Color(1.0, 0.25, 0.45, 1.0)
		else:
			uv_seal_label.text = tr("UI_UV_AUTHENTIC_SEAL")
			uv_seal_label.modulate = Color(0.25, 1.0, 0.65, 1.0)

	if uv_bribe_label != null and current_event.has_bribe():
		uv_bribe_label.visible = true
		if current_event.is_federal_sting:
			uv_bribe_label.text = tr("UI_UV_STING_BRIBE")
			uv_bribe_label.modulate = Color(1.0, 0.15, 0.15, 1.0)
		elif current_event.has_violations():
			uv_bribe_label.text = tr("UI_UV_MARKED_BRIBE")
			uv_bribe_label.modulate = Color(1.0, 0.45, 0.25, 1.0)
		else:
			uv_bribe_label.text = tr("UI_UV_CLEAN_BRIBE")
			uv_bribe_label.modulate = Color(0.35, 0.9, 1.0, 1.0)

	if uv_expiry_label != null:
		uv_expiry_label.visible = has_expired_permit
		if has_expired_permit:
			uv_expiry_label.text = tr("UI_UV_ALTERED_DATA")
			uv_expiry_label.modulate = Color(1.0, 0.25, 0.45, 1.0)
