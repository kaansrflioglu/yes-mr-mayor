extends ColorRect
class_name PoliceFlasher

## PoliceFlasher.gd - Emergency flasher bar for squad cars in SkylineView.
## Supports tweening 'energy' property (0.0 to 1.8) for alternating police siren effects.

@export var base_color: Color = Color.WHITE

var energy: float = 0.0:
	set(val):
		energy = val
		_apply_energy(val)


func _ready() -> void:
	if base_color == Color.WHITE:
		base_color = color
	_apply_energy(energy)


func _apply_energy(val: float) -> void:
	var intensity: float = clampf(val / 1.8, 0.0, 1.0)
	modulate.a = 0.15 + (intensity * 0.85)
	if intensity > 0.7:
		color = base_color.lightened(0.25)
	else:
		color = base_color
