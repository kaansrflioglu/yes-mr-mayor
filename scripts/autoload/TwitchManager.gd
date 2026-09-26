extends Node

## TwitchManager.gd - Optional Twitch IRC WebSocket client for audience voting.
## Parses !approve, !reject, and !bribe commands from live stream chat.

signal vote_updated(approve_pct: float, reject_pct: float, bribe_pct: float, total: int)
signal tool_vote_updated(uv_pct: float, phone_pct: float, coffee_pct: float, total: int)
signal tool_action_executed(tool_name: String)
signal connection_status_changed(connected: bool, channel: String)
signal chat_message_received(user: String, message: String)

const TWITCH_WS_URL: String = "wss://irc-ws.chat.twitch.tv:443"

var ws: WebSocketPeer = WebSocketPeer.new()
var is_connected_to_twitch: bool = false
var active_channel: String = ""

var votes_approve: int = 0
var votes_reject: int = 0
var votes_bribe: int = 0
var voters_logged: Dictionary = {}

var votes_uv: int = 0
var votes_phone: int = 0
var votes_coffee: int = 0
var tool_voters_logged: Dictionary = {}


func _process(_delta: float) -> void:
	if not is_connected_to_twitch:
		return

	ws.poll()
	var state := ws.get_ready_state()

	if state == WebSocketPeer.STATE_OPEN:
		while ws.get_available_packet_count() > 0:
			var packet := ws.get_packet()
			var msg := packet.get_string_from_utf8()
			_handle_irc_raw_message(msg)
	elif state == WebSocketPeer.STATE_CLOSED:
		is_connected_to_twitch = false
		connection_status_changed.emit(false, active_channel)


## Connects anonymously to a Twitch channel chat
func connect_channel(channel_name: String) -> void:
	if channel_name.strip_edges().is_empty():
		return

	active_channel = channel_name.to_lower().strip_edges()
	if active_channel.begins_with("#"):
		active_channel = active_channel.substr(1)

	var err := ws.connect_to_url(TWITCH_WS_URL)
	if err != OK:
		push_warning("Failed to connect to Twitch WebSocket: %d" % err)
		return

	is_connected_to_twitch = true
	connection_status_changed.emit(true, active_channel)


## Disconnects from current Twitch session
func disconnect_channel() -> void:
	if is_connected_to_twitch:
		ws.close()
		is_connected_to_twitch = false
		connection_status_changed.emit(false, active_channel)


## Clears vote counts for the next document
func reset_votes() -> void:
	votes_approve = 0
	votes_reject = 0
	votes_bribe = 0
	voters_logged.clear()
	_emit_vote_update()


## Handles incoming raw IRC packets
func _handle_irc_raw_message(raw: String) -> void:
	var lines := raw.split("\r\n", false)
	for line in lines:
		if line.begins_with("PING"):
			ws.send_text("PONG :tmi.twitch.tv")
		elif "376 " in line or "Ready" in line:
			# Auth ready -> join channel
			ws.send_text("JOIN #" + active_channel)
		elif "PRIVMSG" in line:
			_parse_privmsg(line)


## Parses user chat commands
func _parse_privmsg(line: String) -> void:
	var user_end := line.find("!")
	var msg_start := line.find(" :", user_end)
	if user_end == -1 or msg_start == -1:
		return

	var user := line.substr(1, user_end - 1)
	var content := line.substr(msg_start + 2).strip_edges()

	chat_message_received.emit(user, content)
	register_chat_command(user, content)
	register_tool_command(user, content)


## Registers vote command from a viewer
func register_chat_command(user: String, command: String) -> void:
	var cmd := command.to_lower().strip_edges()
	var vote_type := ""

	if cmd in ["!approve", "!evet", "!onayla", "!yes"]:
		vote_type = "approve"
	elif cmd in ["!reject", "!hayir", "!reddet", "!no"]:
		vote_type = "reject"
	elif cmd in ["!bribe", "!rusvet", "!pocket"]:
		vote_type = "bribe"

	if vote_type.is_empty():
		return

	# Prevent duplicate votes per user on current document
	if voters_logged.has(user):
		var prev_vote: String = voters_logged[user]
		if prev_vote == "approve":
			votes_approve -= 1
		elif prev_vote == "reject":
			votes_reject -= 1
		elif prev_vote == "bribe":
			votes_bribe -= 1

	voters_logged[user] = vote_type
	if vote_type == "approve":
		votes_approve += 1
	elif vote_type == "reject":
		votes_reject += 1
	elif vote_type == "bribe":
		votes_bribe += 1

	_emit_vote_update()


## Registers inspector tool vote from chat (!uv, !phone, !coffee, !inspect)
func register_tool_command(user: String, command: String) -> void:
	var cmd := command.to_lower().strip_edges()
	var tool_type := ""

	if cmd in ["!uv", "!blacklight", "!mor", "!morisik"]:
		tool_type = "uv"
	elif cmd in ["!phone", "!call", "!tipline", "!telefon", "!ihbar"]:
		tool_type = "phone"
	elif cmd in ["!coffee", "!espresso", "!kahve", "!stamina"]:
		tool_type = "coffee"
	elif cmd in ["!inspect", "!incele"]:
		tool_type = "inspect"

	if tool_type.is_empty():
		return

	if tool_voters_logged.has(user):
		var prev_tool: String = tool_voters_logged[user]
		if prev_tool == "uv":
			votes_uv -= 1
		elif prev_tool == "phone":
			votes_phone -= 1
		elif prev_tool == "coffee":
			votes_coffee -= 1

	tool_voters_logged[user] = tool_type
	if tool_type == "uv":
		votes_uv += 1
	elif tool_type == "phone":
		votes_phone += 1
	elif tool_type == "coffee":
		votes_coffee += 1

	_emit_tool_vote_update()


func _emit_tool_vote_update() -> void:
	var total: int = votes_uv + votes_phone + votes_coffee
	var p_uv: float = (float(votes_uv) / float(total) * 100.0) if total > 0 else 0.0
	var p_ph: float = (float(votes_phone) / float(total) * 100.0) if total > 0 else 0.0
	var p_cf: float = (float(votes_coffee) / float(total) * 100.0) if total > 0 else 0.0
	tool_vote_updated.emit(p_uv, p_ph, p_cf, total)


func get_winning_tool() -> String:
	if votes_uv >= votes_phone and votes_uv >= votes_coffee:
		return "uv" if votes_uv > 0 else "none"
	if votes_phone >= votes_uv and votes_phone >= votes_coffee:
		return "phone" if votes_phone > 0 else "none"
	if votes_coffee >= votes_uv and votes_coffee >= votes_phone:
		return "coffee" if votes_coffee > 0 else "none"
	return "none"


func execute_winning_tool() -> String:
	var win_tool := get_winning_tool()
	if win_tool != "none":
		tool_action_executed.emit(win_tool)
	return win_tool


func reset_tool_votes() -> void:
	votes_uv = 0
	votes_phone = 0
	votes_coffee = 0
	tool_voters_logged.clear()
	_emit_tool_vote_update()


func _emit_vote_update() -> void:
	var total: int = votes_approve + votes_reject + votes_bribe
	var p_app: float = (float(votes_approve) / float(total) * 100.0) if total > 0 else 0.0
	var p_rej: float = (float(votes_reject) / float(total) * 100.0) if total > 0 else 0.0
	var p_bri: float = (float(votes_bribe) / float(total) * 100.0) if total > 0 else 0.0
	vote_updated.emit(p_app, p_rej, p_bri, total)


## Returns winning action consensus
func get_consensus_action() -> String:
	if votes_approve >= votes_reject and votes_approve >= votes_bribe:
		return "approve" if votes_approve > 0 else "none"
	if votes_reject >= votes_approve and votes_reject >= votes_bribe:
		return "reject" if votes_reject > 0 else "none"
	if votes_bribe >= votes_approve and votes_bribe >= votes_reject:
		return "bribe" if votes_bribe > 0 else "none"
	return "none"
