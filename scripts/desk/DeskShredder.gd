class_name DeskShredder
extends Control

## DeskShredder.gd - Tactile electric paper shredder prop for evidence tampering.
## Handles document feeding animations, LED heat warnings, and obstruction tracking.

signal shred_requested
signal shred_completed

@onready var slot_button: Button = %SlotButton
@onready var status_led: ColorRect = %StatusLED
@onready var shred_particles: CPUParticles2D = %ShredParticles if has_node("%ShredParticles") else null

var daily_shred_count: int = 0
const MAX_SAFE_SHREDS_PER_DAY: int = 1


func _ready() -> void:
	if slot_button != null:
		slot_button.pressed.connect(_on_slot_pressed)
	update_led()


func update_led() -> void:
	if status_led == null:
		return
	if daily_shred_count == 0:
		status_led.color = Color(0.2, 0.9, 0.3, 1.0) # Green (Ready)
	elif daily_shred_count == 1:
		status_led.color = Color(0.9, 0.8, 0.2, 1.0) # Amber warning
	else:
		status_led.color = Color(0.9, 0.2, 0.2, 1.0) # Red danger (Jammed / Suspicious)


func _on_slot_pressed() -> void:
	shred_requested.emit()


func execute_shred_animation(doc_item: Control) -> void:
	daily_shred_count += 1
	update_led()

	if AudioManager != null and AudioManager.has_method("play_paper_shred"):
		AudioManager.play_paper_shred()

	if shred_particles != null:
		shred_particles.restart()
		shred_particles.emitting = true

	var tween := create_tween().set_parallel(true)
	if doc_item != null and is_instance_valid(doc_item):
		tween.tween_property(doc_item, "global_position", global_position + Vector2(20, 40), 0.45).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(doc_item, "scale", Vector2(0.1, 0.1), 0.45)
		tween.tween_property(doc_item, "rotation", 0.35, 0.45)
		tween.tween_property(doc_item, "modulate:a", 0.0, 0.4)

	tween.chain().tween_callback(func():
		shred_completed.emit()
	)


func reset_day() -> void:
	daily_shred_count = 0
	update_led()
