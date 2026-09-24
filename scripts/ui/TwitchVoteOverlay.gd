extends PanelContainer

## TwitchVoteOverlay.gd - Floating UI overlay for live Twitch audience polling.
## Displays real-time vote percentages for !approve, !reject, and !bribe.

@onready var title_label: Label = %TitleLabel
@onready var status_label: Label = %StatusLabel
@onready var channel_input: LineEdit = %ChannelInput
@onready var btn_connect: Button = %BtnConnect
@onready var btn_close: Button = %BtnClose

@onready var approve_bar: ProgressBar = %ApproveBar
@onready var approve_label: Label = %ApproveLabel
@onready var reject_bar: ProgressBar = %RejectBar
@onready var reject_label: Label = %RejectLabel
@onready var bribe_bar: ProgressBar = %BribeBar
@onready var bribe_label: Label = %BribeLabel

@onready var total_votes_label: Label = %TotalVotesLabel

var _current_approve_pct: float = 0.0
var _current_reject_pct: float = 0.0
var _current_bribe_pct: float = 0.0
var _current_total_votes: int = 0
var _is_connected: bool = false
var _active_channel: String = ""


func _ready() -> void:
	btn_connect.pressed.connect(_on_connect_button_pressed)
	btn_close.pressed.connect(hide_overlay)
	channel_input.text_submitted.connect(func(_t: String): _on_connect_button_pressed())

	TwitchManager.vote_updated.connect(_on_twitch_vote_updated)
	TwitchManager.connection_status_changed.connect(_on_twitch_connection_changed)
	LocalizationManager.locale_changed.connect(func(_loc: String): _refresh_ui_text())

	_refresh_ui_text()


## Toggles visibility of Twitch vote overlay
func toggle_overlay() -> void:
	if visible:
		hide_overlay()
	else:
		show_overlay()


## Shows overlay with subtle pop-in
func show_overlay() -> void:
	visible = true
	modulate = Color(1.0, 1.0, 1.0, 0.0)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.2)


## Hides overlay
func hide_overlay() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.15)
	tw.tween_callback(func(): visible = false)


## Returns whether overlay is currently displayed
func is_overlay_visible() -> bool:
	return visible


func _on_connect_button_pressed() -> void:
	if _is_connected:
		TwitchManager.disconnect_channel()
	else:
		var ch := channel_input.text.strip_edges()
		if not ch.is_empty():
			TwitchManager.connect_channel(ch)


func _on_twitch_vote_updated(
	p_app: float, p_rej: float, p_bri: float, total: int
) -> void:
	_current_approve_pct = p_app
	_current_reject_pct = p_rej
	_current_bribe_pct = p_bri
	_current_total_votes = total
	_animate_vote_bars()


func _on_twitch_connection_changed(connected: bool, channel: String) -> void:
	_is_connected = connected
	_active_channel = channel
	_refresh_ui_text()


func _animate_vote_bars() -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_property(approve_bar, "value", _current_approve_pct, 0.35)
	tw.tween_property(reject_bar, "value", _current_reject_pct, 0.35)
	tw.tween_property(bribe_bar, "value", _current_bribe_pct, 0.35)
	_update_labels()


func _update_labels() -> void:
	approve_label.text = tr("UI_TWITCH_APPROVE_VOTES").format({
		"pct": "%.1f" % _current_approve_pct
	})
	reject_label.text = tr("UI_TWITCH_REJECT_VOTES").format({
		"pct": "%.1f" % _current_reject_pct
	})
	bribe_label.text = tr("UI_TWITCH_BRIBE_VOTES").format({
		"pct": "%.1f" % _current_bribe_pct
	})
	total_votes_label.text = tr("UI_TWITCH_TOTAL_VOTES").format({
		"count": str(_current_total_votes)
	})


func _refresh_ui_text() -> void:
	title_label.text = tr("UI_TWITCH_TITLE")
	channel_input.placeholder_text = tr("UI_TWITCH_CHANNEL_PLACEHOLDER")

	if _is_connected:
		btn_connect.text = tr("UI_TWITCH_DISCONNECT")
		btn_connect.modulate = Color(0.9, 0.4, 0.4)
		status_label.text = tr("UI_TWITCH_STATUS_CONNECTED").format({"channel": _active_channel})
		status_label.modulate = Color(0.4, 0.9, 0.5)
	else:
		btn_connect.text = tr("UI_TWITCH_CONNECT")
		btn_connect.modulate = Color(0.6, 0.5, 0.9)
		status_label.text = tr("UI_TWITCH_STATUS_OFFLINE")
		status_label.modulate = Color(0.6, 0.65, 0.75)

	_update_labels()
