extends Control

## RedTelephone.gd - Red emergency telephone on the mayor's desk.
## Rings randomly for high-stakes split-second deals from party bosses.

signal call_resolved(accepted: bool)

@onready var phone_button: Button = %PhoneButton
@onready var ring_badge: Label = %RingBadge
@onready var dialog_panel: PanelContainer = %DialogPanel
@onready var caller_label: Label = %CallerLabel
@onready var message_label: Label = %MessageLabel
@onready var btn_accept: Button = %BtnAccept
@onready var btn_hangup: Button = %BtnHangup

var is_ringing: bool = false
var _wobble_tween: Tween


func _ready() -> void:
	ring_badge.visible = false
	dialog_panel.visible = false
	phone_button.pressed.connect(_on_phone_clicked)
	btn_accept.pressed.connect(_on_accept_pressed)
	btn_hangup.pressed.connect(_on_hangup_pressed)


## Triggers random emergency call
func ring_telephone() -> void:
	if is_ringing or dialog_panel.visible:
		return

	is_ringing = true
	ring_badge.visible = true
	AudioManager.play_phone_ring()
	_start_wobble_animation()


func _start_wobble_animation() -> void:
	if _wobble_tween and _wobble_tween.is_valid():
		_wobble_tween.kill()

	_wobble_tween = create_tween().set_loops(4)
	_wobble_tween.tween_property(phone_button, "rotation", 0.08, 0.06)
	_wobble_tween.tween_property(phone_button, "rotation", -0.08, 0.06)
	_wobble_tween.tween_property(phone_button, "rotation", 0.0, 0.04)


func _on_phone_clicked() -> void:
	answer_call()


## Public method to answer the ringing hotline
func answer_call() -> void:
	if is_ringing:
		is_ringing = false
		ring_badge.visible = false
		if _wobble_tween and _wobble_tween.is_valid():
			_wobble_tween.kill()
		phone_button.rotation = 0.0

		_open_call_dialog()


func _open_call_dialog() -> void:
	dialog_panel.visible = true
	caller_label.text = "📞 PARTY BOSS (ENCRYPTED LINE)"
	message_label.text = (
		"Listen, Mr. Mayor! Divert $30,000 from the municipal budget to our "
		+ "super PAC right now, and our senators will suppress 20% of your federal suspicion!"
	)
	btn_accept.text = "Wire $30,000 (Drop 20% Suspicion)"
	btn_hangup.text = "Hang Up (Reject Deal)"

	dialog_panel.scale = Vector2(0.9, 0.9)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(dialog_panel, "scale", Vector2.ONE, 0.25)


func _on_accept_pressed() -> void:
	accept_deal()


## Public method to accept the party boss deal
func accept_deal() -> void:
	dialog_panel.visible = false
	AudioManager.play_cash_register()
	GameManager.apply_resolution({
		"budget": -30000,
		"suspicion": -20.0
	})
	call_resolved.emit(true)


func _on_hangup_pressed() -> void:
	reject_deal()


## Public method to reject the party boss deal
func reject_deal() -> void:
	dialog_panel.visible = false
	call_resolved.emit(false)
