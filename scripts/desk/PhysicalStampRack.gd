class_name PhysicalStampRack
extends Control

## PhysicalStampRack.gd - Wooden desk rack housing physical stamp handles and inking felt pad.

signal stamp_dropped(approved: bool, hit_global_pos: Vector2, hit_rotation: float)

@onready var approve_handle: Control = %ApproveHandle
@onready var reject_handle: Control = %RejectHandle
@onready var ink_pad_button: Button = %InkPadButton if has_node("%InkPadButton") else null

var ink_saturation: float = 1.0


func _ready() -> void:
	if approve_handle != null:
		approve_handle.stamp_slammed.connect(_on_stamp_slammed)
	if reject_handle != null:
		reject_handle.stamp_slammed.connect(_on_stamp_slammed)
	if ink_pad_button != null:
		ink_pad_button.pressed.connect(_on_ink_pad_pressed)


func _on_stamp_slammed(approved: bool, hit_pos: Vector2, hit_rot: float) -> void:
	ink_saturation = maxf(0.25, ink_saturation - 0.25)
	stamp_dropped.emit(approved, hit_pos, hit_rot)


func _on_ink_pad_pressed() -> void:
	ink_saturation = 1.0
	if AudioManager != null and AudioManager.has_method("play_ink_pad_dip"):
		AudioManager.play_ink_pad_dip()

	if ink_pad_button != null:
		var tween := create_tween()
		tween.tween_property(ink_pad_button, "scale", Vector2(0.94, 0.94), 0.06)
		tween.tween_property(ink_pad_button, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK)


func trigger_hotkey_slam(approved: bool, target_glob: Vector2) -> void:
	var target_handle: Control = approve_handle if approved else reject_handle
	if target_handle != null and target_handle.has_method("trigger_hotkey_slam"):
		target_handle.trigger_hotkey_slam(target_glob)
	else:
		_on_stamp_slammed(approved, target_glob, 0.0)
