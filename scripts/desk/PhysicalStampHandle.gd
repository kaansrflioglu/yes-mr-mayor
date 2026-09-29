class_name PhysicalStampHandle
extends Control

## PhysicalStampHandle.gd - Tactile 2.5D draggable stamp handle with elevation and slam physics.

signal stamp_slammed(approved: bool, hit_global_pos: Vector2, hit_rotation: float)

@export var is_approve_stamp: bool = true:
	set(val):
		is_approve_stamp = val
		_update_appearance()

@onready var handle_sprite: Control = %HandleVisual if has_node("%HandleVisual") else self
@onready var shadow_sprite: Control = %ShadowVisual if has_node("%ShadowVisual") else null
@onready var rubber_base: Panel = %RubberBase if has_node("%RubberBase") else null
@onready var stamp_icon: Label = %StampIcon if has_node("%StampIcon") else null

var is_dragging: bool = false
var rest_position: Vector2 = Vector2.ZERO
var has_captured_rest: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var is_animating_slam: bool = false


func _ready() -> void:
	gui_input.connect(_on_gui_input)
	_update_appearance()
	_deferred_capture_rest.call_deferred()


func _deferred_capture_rest() -> void:
	if not has_captured_rest and not is_dragging and not is_animating_slam:
		rest_position = position
		has_captured_rest = true


func _update_appearance() -> void:
	if rubber_base == null or stamp_icon == null:
		return

	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 2

	if is_approve_stamp:
		style.bg_color = Color(0.15, 0.65, 0.35, 1.0)
		style.border_color = Color(0.1, 0.45, 0.25, 1.0)
		stamp_icon.text = "✔"
		tooltip_text = tr("UI_STAMP_APPROVED")
	else:
		style.bg_color = Color(0.85, 0.2, 0.2, 1.0)
		style.border_color = Color(0.55, 0.1, 0.1, 1.0)
		stamp_icon.text = "✖"
		tooltip_text = tr("UI_STAMP_REJECTED")

	rubber_base.add_theme_stylebox_override("panel", style)


func _on_gui_input(event: InputEvent) -> void:
	if is_animating_slam:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				start_drag(event.global_position)
			elif is_dragging:
				finish_slam(event.global_position)


func start_drag(mouse_glob: Vector2) -> void:
	if not has_captured_rest:
		rest_position = position
		has_captured_rest = true
	is_dragging = true
	drag_offset = global_position - mouse_glob
	z_index = 50

	var tween := create_tween().set_parallel(true)
	if handle_sprite != null:
		tween.tween_property(handle_sprite, "scale", Vector2(1.18, 1.18), 0.12)
	if shadow_sprite != null:
		tween.tween_property(shadow_sprite, "position", Vector2(16, 24), 0.12)
		tween.tween_property(shadow_sprite, "modulate:a", 0.35, 0.12)


func _process(_delta: float) -> void:
	if is_dragging:
		global_position = get_global_mouse_position() + drag_offset


func finish_slam(mouse_glob: Vector2) -> void:
	is_dragging = false
	z_index = 0

	var slam_rot: float = deg_to_rad(randf_range(-6.0, 6.0))

	var tween := create_tween()
	if handle_sprite != null:
		tween.tween_property(handle_sprite, "scale", Vector2(0.9, 0.9), 0.06).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(handle_sprite, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_ELASTIC)

	stamp_slammed.emit(is_approve_stamp, mouse_glob, slam_rot)

	# Return handle smoothly to rack
	var return_tween := create_tween()
	return_tween.tween_property(self, "position", rest_position, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## Animate hotkey slam directly onto target position
func trigger_hotkey_slam(target_glob: Vector2) -> void:
	if is_dragging or is_animating_slam:
		return
	if not has_captured_rest:
		rest_position = position
		has_captured_rest = true
	is_animating_slam = true
	z_index = 50

	var slam_rot: float = deg_to_rad(randf_range(-5.0, 5.0))

	var tween := create_tween()
	# Lift & arc to document center
	tween.tween_property(self, "global_position", target_glob, 0.18).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(handle_sprite, "scale", Vector2(1.2, 1.2), 0.18)

	# Slam down
	tween.tween_callback(func():
		stamp_slammed.emit(is_approve_stamp, target_glob, slam_rot)
	)
	tween.tween_property(handle_sprite, "scale", Vector2(0.9, 0.9), 0.06)
	tween.tween_property(handle_sprite, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_ELASTIC)

	# Return to rack
	tween.tween_property(self, "position", rest_position, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func():
		is_animating_slam = false
		z_index = 0
	)
