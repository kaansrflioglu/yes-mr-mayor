class_name ElectionNightModal
extends Control

## ElectionNightModal.gd - Climax Election Night ballot tally modal.
## Sequentially tallies all 5 districts and determines re-election victory or defeat.

signal election_completed(victory: bool)

@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var districts_vbox: VBoxContainer = %DistrictsVBox
@onready var outcome_banner: PanelContainer = %OutcomeBanner
@onready var outcome_label: Label = %OutcomeLabel
@onready var outcome_sublabel: Label = %OutcomeSublabel
@onready var btn_proceed: Button = %BtnProceed

@onready var election_mgr: Node = get_node_or_null("/root/ElectionManager")

var is_tallying: bool = false
var victory_result: bool = false


func _ready() -> void:
	visible = false
	if btn_proceed != null:
		btn_proceed.pressed.connect(_on_proceed_pressed)


func start_election_tally() -> void:
	visible = true
	is_tallying = true
	if outcome_banner != null:
		outcome_banner.visible = false
	if btn_proceed != null:
		btn_proceed.visible = false

	for child in districts_vbox.get_children():
		child.queue_free()

	if election_mgr == null:
		_show_outcome(false, 0)
		return

	var district_list: Array[String] = [
		"DIST_CENTRAL", "DIST_RIVERBED", "DIST_INDUSTRIAL", "DIST_HISTORIC", "DIST_SUBURBS"
	]

	var won_districts: int = 0

	for d_id in district_list:
		var pct: float = float(election_mgr.district_polls.get(d_id, 50.0))
		var won: bool = (pct >= 50.0)
		if won:
			won_districts += 1

		var card := _create_district_tally_row(d_id, pct, won)
		districts_vbox.add_child(card)

		if AudioManager != null and AudioManager.has_method("play_discrepancy_match"):
			AudioManager.play_discrepancy_match()

		await get_tree().create_timer(0.25).timeout

	victory_result = (won_districts >= 3)
	if election_mgr.has_method("run_election_tally"):
		victory_result = election_mgr.run_election_tally()

	_show_outcome(victory_result, won_districts)


func _create_district_tally_row(d_id: String, pct: float, won: bool) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 48)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.08, 0.14, 0.85)
	style.border_color = Color(0.25, 0.85, 0.45) if won else Color(0.9, 0.3, 0.3)
	style.set_border_width_all(1)
	style.border_width_left = 6
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	panel.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	panel.add_child(hbox)

	var name_lbl := Label.new()
	name_lbl.text = tr(d_id)
	name_lbl.custom_minimum_size = Vector2(180, 0)
	name_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	hbox.add_child(name_lbl)

	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = pct
	bar.show_percentage = false
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.custom_minimum_size = Vector2(100, 16)

	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = Color(0.2, 0.75, 0.4) if won else Color(0.85, 0.25, 0.25)
	bar_fill.corner_radius_top_left = 3
	bar_fill.corner_radius_top_right = 3
	bar_fill.corner_radius_bottom_right = 3
	bar_fill.corner_radius_bottom_left = 3
	bar.add_theme_stylebox_override("fill", bar_fill)
	hbox.add_child(bar)

	var pct_lbl := Label.new()
	pct_lbl.text = "%d%%" % int(round(pct))
	pct_lbl.custom_minimum_size = Vector2(50, 0)
	pct_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pct_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pct_lbl.add_theme_font_size_override("font_size", 14)
	pct_lbl.add_theme_color_override("font_color", Color(0.25, 0.85, 0.45) if won else Color(0.9, 0.3, 0.3))
	hbox.add_child(pct_lbl)

	var tag_lbl := Label.new()
	tag_lbl.text = "WON ✓" if won else "LOST ✗"
	tag_lbl.custom_minimum_size = Vector2(75, 0)
	tag_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tag_lbl.add_theme_font_size_override("font_size", 13)
	tag_lbl.add_theme_color_override("font_color", Color(0.25, 0.85, 0.45) if won else Color(0.9, 0.3, 0.3))
	hbox.add_child(tag_lbl)

	return panel


func _show_outcome(victory: bool, won_count: int) -> void:
	if outcome_banner != null:
		outcome_banner.visible = true
	if outcome_label != null:
		outcome_label.text = tr("ELECTION_VICTORY_TITLE") if victory else tr("ELECTION_DEFEAT_TITLE")
		outcome_label.add_theme_color_override("font_color", Color(0.25, 0.9, 0.45) if victory else Color(0.95, 0.25, 0.25))

	if outcome_sublabel != null:
		var key := "ELECTION_VICTORY_SUB" if victory else "ELECTION_DEFEAT_SUB"
		outcome_sublabel.text = tr(key).format({"won": won_count, "total": 5})

	if btn_proceed != null:
		btn_proceed.visible = true
		btn_proceed.grab_focus()


func _on_proceed_pressed() -> void:
	visible = false
	election_completed.emit(victory_result)
