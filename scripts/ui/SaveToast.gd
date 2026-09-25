extends Control

## SaveToast.gd - Non-intrusive HUD notification banner confirming autosaves.
## Gracefully slides into view from top HUD, displays day progress, and fades out.

@onready var toast_panel: PanelContainer = %ToastPanel
@onready var toast_label: Label = %ToastLabel

var _tween: Tween


func _ready() -> void:
	visible = false
	modulate.a = 0.0


## Displays the save notification toast for a given day
func show_toast(day: int, custom_msg: String = "") -> void:
	if _tween and _tween.is_valid():
		_tween.kill()

	var msg: String = custom_msg
	if msg.is_empty():
		msg = tr("UI_TOAST_AUTOSAVE").format({"day": day})

	toast_label.text = msg
	visible = true
	modulate.a = 0.0
	toast_panel.position.y = -50.0

	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(self, "modulate:a", 1.0, 0.28)
	_tween.tween_property(toast_panel, "position:y", 14.0, 0.28).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)

	_tween.chain().tween_interval(2.0)

	_tween.chain().set_parallel(true)
	_tween.tween_property(self, "modulate:a", 0.0, 0.35)
	_tween.tween_property(toast_panel, "position:y", -50.0, 0.35)
	_tween.chain().tween_callback(func():
		visible = false
	)
