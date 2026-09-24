extends PanelContainer

## DocumentItem.gd - Tactile petition document sitting on mayor's desk.
## Inspired by Papers, Please: handles paper slide-in, stamping slam tween, and bribe envelope.

signal stamped(approved: bool)
signal bribe_pocketed(amount: int)
signal slide_in_completed
signal slide_out_completed

@onready var header_label: Label = %HeaderLabel
@onready var category_badge: Label = %CategoryBadge
@onready var title_label: Label = %TitleLabel
@onready var applicant_label: Label = %ApplicantLabel
@onready var body_text_label: Label = %BodyTextLabel

@onready var bribe_container: PanelContainer = %BribeContainer
@onready var bribe_amount_label: Label = %BribeAmountLabel
@onready var btn_pocket_bribe: Button = %BtnPocketBribe

@onready var stamp_overlay: PanelContainer = %StampOverlay
@onready var stamp_label: Label = %StampLabel

var current_event: EventData = null
var has_pocketed_bribe: bool = false
var is_stamped: bool = false


func _ready() -> void:
	stamp_overlay.visible = false
	btn_pocket_bribe.pressed.connect(_on_pocket_bribe_pressed)


func setup_event(event: EventData) -> void:
	current_event = event
	is_stamped = false
	has_pocketed_bribe = false
	stamp_overlay.visible = false

	header_label.text = tr("UI_PETITION_HEADER")
	category_badge.text = event.category.to_upper()
	title_label.text = event.get_title()
	applicant_label.text = tr("UI_APPLICANT").format({"applicant": event.get_applicant()})
	body_text_label.text = event.get_description()

	# Bribe suitcase / envelope
	if event.bribe_offered > 0:
		bribe_container.visible = true
		bribe_amount_label.text = tr("UI_BRIBE_OFFERED").format({
			"amount": _format_money(event.bribe_offered)
		})
		btn_pocket_bribe.text = tr("UI_BRIBE_POCKET")
		btn_pocket_bribe.disabled = false
	else:
		bribe_container.visible = false


func _on_pocket_bribe_pressed() -> void:
	pocket_bribe()


## Public method to stash the bribe into personal safe
func pocket_bribe() -> void:
	if has_pocketed_bribe or current_event == null or current_event.bribe_offered <= 0:
		return

	has_pocketed_bribe = true
	btn_pocket_bribe.disabled = true
	btn_pocket_bribe.text = tr("UI_BRIBE_STASHED")

	# Little celebratory squeeze tween on bribe box
	var tween := create_tween()
	tween.tween_property(bribe_container, "scale", Vector2(1.08, 1.08), 0.1)
	tween.tween_property(bribe_container, "scale", Vector2(1.0, 1.0), 0.15)

	bribe_pocketed.emit(current_event.bribe_offered)


## Animates tactile paper sliding onto desk with slight angle
func animate_slide_in(from_pos: Vector2, to_pos: Vector2, rest_rotation: float = -0.02) -> void:
	position = from_pos
	rotation = 0.08
	modulate.a = 0.0

	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", to_pos, 0.6)
	tween.tween_property(self, "rotation", rest_rotation, 0.6)
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
		stamp_overlay.rotation = -0.18
		stamp_label.set("theme_override_colors/font_color", Color(0.12, 0.75, 0.38, 1))
	else:
		stamp_label.text = tr("UI_STAMP_REJECTED")
		stamp_overlay.rotation = 0.22
		stamp_label.set("theme_override_colors/font_color", Color(0.92, 0.22, 0.22, 1))

	var tween := create_tween().set_parallel(true)
	tween.tween_property(stamp_overlay, "scale", Vector2(1.0, 1.0), 0.25).set_trans(
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
