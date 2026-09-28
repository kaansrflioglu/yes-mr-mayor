extends Control

## DistrictMapModal.gd - Interactive fold-out architectural blueprint modal.
## Visualizes the 5 Municipal Districts and 5-Faction Political Standings.

signal closed

@onready var modal_container: Control = %ModalContainer
@onready var btn_close: Button = %BtnClose
@onready var factions_container: VBoxContainer = %FactionsContainer
@onready var districts_container: VBoxContainer = %DistrictsContainer
@onready var faction_mgr: Node = get_node_or_null("/root/FactionManager")

var _active_tween: Tween = null
var faction_rows: Dictionary = {}
var district_cards: Dictionary = {}


func _ready() -> void:
	if btn_close != null:
		btn_close.pressed.connect(close_modal)

	_populate_factions()
	_populate_districts()

	if faction_mgr != null:
		if faction_mgr.has_signal("faction_standing_changed"):
			faction_mgr.faction_standing_changed.connect(_on_faction_standing_changed)
		if faction_mgr.has_signal("district_updated"):
			faction_mgr.district_updated.connect(_on_district_updated)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("mayor_map") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_modal()


func open_modal() -> void:
	visible = true
	refresh_all()

	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()

	# Crisp blueprint fold-out animation
	if modal_container != null:
		modal_container.pivot_offset = modal_container.size * 0.5
		modal_container.scale = Vector2(0.85, 0.85)
		modal_container.modulate.a = 0.0

		_active_tween = create_tween().set_parallel(true)
		_active_tween.tween_property(modal_container, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_active_tween.tween_property(modal_container, "modulate:a", 1.0, 0.15)

	if btn_close != null:
		btn_close.grab_focus()


func close_modal() -> void:
	if not visible:
		return

	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()

	if modal_container != null:
		_active_tween = create_tween().set_parallel(true)
		_active_tween.tween_property(modal_container, "scale", Vector2(0.9, 0.9), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		_active_tween.tween_property(modal_container, "modulate:a", 0.0, 0.15)
		_active_tween.finished.connect(func():
			visible = false
			closed.emit()
		)
	else:
		visible = false
		closed.emit()


func refresh_all() -> void:
	if faction_mgr == null:
		return

	for f_id in faction_mgr.factions:
		_update_faction_row(f_id)

	for d_id in faction_mgr.districts:
		_update_district_card(d_id)


func _populate_factions() -> void:
	if factions_container == null or faction_mgr == null:
		return

	for child in factions_container.get_children():
		child.queue_free()
	faction_rows.clear()

	for f_id in faction_mgr.factions:
		var row := _create_faction_row(f_id, faction_mgr.factions[f_id])
		factions_container.add_child(row)
		faction_rows[f_id] = row
		_update_faction_row(f_id)


func _create_faction_row(f_id: String, f_data: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 56)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.12, 0.22, 0.85)
	style.border_color = f_data.get("color", Color.CYAN)
	style.set_border_width_all(1)
	style.border_width_left = 6
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	panel.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	panel.add_child(hbox)

	var name_lbl := Label.new()
	name_lbl.text = tr(f_data.get("name_key", f_id.capitalize()))
	name_lbl.custom_minimum_size = Vector2(170, 0)
	name_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	name_lbl.name = "NameLabel"
	hbox.add_child(name_lbl)

	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = float(f_data.get("value", 50.0))
	bar.show_percentage = false
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.custom_minimum_size = Vector2(100, 16)
	bar.name = "ProgressBar"

	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = f_data.get("color", Color.CYAN)
	bar_fill.corner_radius_top_left = 3
	bar_fill.corner_radius_top_right = 3
	bar_fill.corner_radius_bottom_right = 3
	bar_fill.corner_radius_bottom_left = 3
	bar.add_theme_stylebox_override("fill", bar_fill)
	hbox.add_child(bar)

	var val_lbl := Label.new()
	val_lbl.text = "%d%%" % int(bar.value)
	val_lbl.custom_minimum_size = Vector2(50, 0)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	val_lbl.add_theme_font_size_override("font_size", 14)
	val_lbl.name = "ValLabel"
	hbox.add_child(val_lbl)

	var status_lbl := Label.new()
	status_lbl.custom_minimum_size = Vector2(85, 0)
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	status_lbl.add_theme_font_size_override("font_size", 12)
	status_lbl.name = "StatusLabel"
	hbox.add_child(status_lbl)

	return panel


func _update_faction_row(f_id: String) -> void:
	if not faction_rows.has(f_id) or faction_mgr == null:
		return
	var row: Control = faction_rows[f_id]
	var f_data: Dictionary = faction_mgr.factions.get(f_id, {})
	var val: float = float(f_data.get("value", 50.0))

	var bar = row.find_child("ProgressBar", true, false) as ProgressBar
	var val_lbl = row.find_child("ValLabel", true, false) as Label
	var status_lbl = row.find_child("StatusLabel", true, false) as Label

	if bar != null:
		bar.value = val
	if val_lbl != null:
		val_lbl.text = "%d%%" % int(val)
		if val <= 15.0:
			val_lbl.modulate = Color(1.0, 0.2, 0.2)
		elif val >= 80.0:
			val_lbl.modulate = Color(0.2, 1.0, 0.4)
		else:
			val_lbl.modulate = Color(0.9, 0.95, 1.0)

	if status_lbl != null:
		if val <= 15.0:
			status_lbl.text = "CRISIS!"
			status_lbl.modulate = Color(1.0, 0.2, 0.2)
		elif val >= 80.0:
			status_lbl.text = "PERK ON"
			status_lbl.modulate = Color(0.2, 1.0, 0.4)
		else:
			status_lbl.text = "STABLE"
			status_lbl.modulate = Color(0.6, 0.75, 0.9)


func _populate_districts() -> void:
	if districts_container == null or faction_mgr == null:
		return

	for child in districts_container.get_children():
		child.queue_free()
	district_cards.clear()

	for d_id in faction_mgr.districts:
		var card := _create_district_card(d_id, faction_mgr.districts[d_id])
		districts_container.add_child(card)
		district_cards[d_id] = card
		_update_district_card(d_id)


func _create_district_card(d_id: String, d_data: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 72)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.1, 0.18, 0.9)
	style.border_color = Color(0.2, 0.6, 0.85, 0.7)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	card.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	card.add_child(vbox)

	var title_lbl := Label.new()
	title_lbl.text = tr(d_data.get("name_key", d_id))
	title_lbl.add_theme_font_size_override("font_size", 15)
	title_lbl.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
	title_lbl.name = "TitleLabel"
	vbox.add_child(title_lbl)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 18)
	vbox.add_child(hbox)

	# Metric 1: Prosperity
	var prosp_box := _create_metric_display("Prosperity", Color(0.3, 0.85, 0.4), "ProspVal")
	hbox.add_child(prosp_box)

	# Metric 2: Pollution
	var poll_box := _create_metric_display("Pollution", Color(0.9, 0.6, 0.2), "PollVal")
	hbox.add_child(poll_box)

	# Metric 3: Unrest
	var unrest_box := _create_metric_display("Unrest", Color(0.95, 0.3, 0.3), "UnrestVal")
	hbox.add_child(unrest_box)

	return card


func _create_metric_display(label_text: String, col: Color, val_node_name: String) -> Control:
	var cont := HBoxContainer.new()
	cont.add_theme_constant_override("separation", 6)
	cont.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var lbl := Label.new()
	lbl.text = label_text + ":"
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	cont.add_child(lbl)

	var val_lbl := Label.new()
	val_lbl.name = val_node_name
	val_lbl.text = "0%"
	val_lbl.add_theme_font_size_override("font_size", 13)
	val_lbl.add_theme_color_override("font_color", col)
	cont.add_child(val_lbl)

	return cont


func _update_district_card(d_id: String) -> void:
	if not district_cards.has(d_id) or faction_mgr == null:
		return
	var card: Control = district_cards[d_id]
	var stats: Dictionary = faction_mgr.districts.get(d_id, {})

	var prosp_lbl = card.find_child("ProspVal", true, false) as Label
	var poll_lbl = card.find_child("PollVal", true, false) as Label
	var unrest_lbl = card.find_child("UnrestVal", true, false) as Label

	if prosp_lbl != null:
		prosp_lbl.text = "%d%%" % int(stats.get("prosperity", 50.0))
	if poll_lbl != null:
		poll_lbl.text = "%d%%" % int(stats.get("pollution", 20.0))
	if unrest_lbl != null:
		unrest_lbl.text = "%d%%" % int(stats.get("unrest", 10.0))


func _on_faction_standing_changed(f_id: String, _new_val: float) -> void:
	_update_faction_row(f_id)


func _on_district_updated(d_id: String, _stats: Dictionary) -> void:
	_update_district_card(d_id)
