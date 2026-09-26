extends Node

## GameManager.gd - Central state & game loop manager for "Yes, Mr. Mayor!"
## Manages day progression, core municipal metrics, event outcomes, and win/loss states.

signal stats_updated
signal stats_changed
signal game_ended(reason_key: String)
signal game_over(reason_key: String)
signal day_started(day_number: int)
signal day_ended(day_number: int)
signal event_presented(event: EventData)
signal event_resolved(event: EventData, approved: bool, bribe_taken: bool)
signal event_decided(event_id: String, approved: bool)

const MAX_DAYS: int = 30

var current_day: int = 1
var is_game_over: bool = false

## Core gameplay metrics (Section 2 & Phase 1)
var public_opinion: float = 50.0:
	set(val):
		public_opinion = clamp(val, 0.0, 100.0)

var city_budget: int = 100000

var personal_wealth: int = 0:
	set(val):
		personal_wealth = maxi(0, val)

var suspicion_level: float = 0.0:
	set(val):
		suspicion_level = clamp(val, 0.0, 100.0)

## Metric aliases aligned with PHASE_MAP.md
var offshore_account: int:
	get:
		return personal_wealth
	set(val):
		personal_wealth = val

var suspicion_meter: float:
	get:
		return suspicion_level
	set(val):
		suspicion_level = val

var treasury: int:
	get:
		return city_budget
	set(val):
		city_budget = val

## City visual flags & world state flags
var event_flags: Dictionary = {}

## Event management & daily history
var event_database: Array[EventData] = []
var active_event: EventData = null
var daily_history: Array[Dictionary] = []
var hotline_history: Array[Dictionary] = []


func _ready() -> void:
	load_events_database()


## Starts a fresh 30-day mandate
func start_new_game() -> void:
	current_day = 1
	is_game_over = false
	public_opinion = 50.0
	city_budget = 100000
	personal_wealth = 0
	suspicion_level = 0.0
	event_flags.clear()
	daily_history.clear()
	hotline_history.clear()
	active_event = null
	_notify_stats_changed()
	day_started.emit(current_day)


## Loads event definitions from JSON database
func load_events_database(path: String = "res://data/events.json") -> void:
	event_database.clear()
	if not FileAccess.file_exists(path):
		push_warning("Events database not found at %s" % path)
		return

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Failed to open events database: %s" % path)
		return

	var content := file.get_as_text()
	var json := JSON.new()
	var parse_result := json.parse(content)
	if parse_result != OK:
		var err_msg := "Failed to parse events JSON at %s (Line %d): %s" % [
			path, json.get_error_line(), json.get_error_message()
		]
		push_error(err_msg)
		return

	var data = json.data
	if data is Array:
		for item in data:
			if item is Dictionary:
				event_database.append(EventData.from_dict(item))
	print("[GameManager] Successfully loaded %d events." % event_database.size())


## Presents an event to the desk
func present_event(event: EventData) -> void:
	active_event = event
	event_presented.emit(event)


## Resolves the current event decision (Approve / Reject + Bribe Pocketing)
func resolve_event(event: EventData, approved: bool, took_bribe: bool) -> void:
	if is_game_over:
		return

	var effects: Dictionary = (
		event.effects_approve if approved
		else event.effects_reject
	)
	apply_resolution(effects)

	if took_bribe and event.bribe_offered > 0:
		pocket_bribe(event.bribe_offered)

	var headline_key: String = (
		event.news_headline_approve_key if approved
		else event.news_headline_reject_key
	)
	var record := {
		"day": current_day,
		"event_id": event.id,
		"approved": approved,
		"took_bribe": took_bribe,
		"headline_key": headline_key
	}
	daily_history.append(record)

	event_resolved.emit(event, approved, took_bribe)
	event_decided.emit(event.id, approved)


## Directly adds illicit cash to personal offshore safe and slightly raises suspicion
func pocket_bribe(amount: int, suspicion_delta: float = 3.0) -> void:
	personal_wealth += amount
	suspicion_level += suspicion_delta
	_notify_stats_changed()
	_evaluate_end_conditions()


## Applies stat deltas and flags from decision effects
func apply_resolution(effects: Dictionary) -> void:
	if "public_opinion" in effects:
		public_opinion += float(effects["public_opinion"])
	if "budget" in effects:
		city_budget += int(effects["budget"])
	if "personal_wealth" in effects:
		personal_wealth += int(effects["personal_wealth"])
	elif "offshore_account" in effects:
		personal_wealth += int(effects["offshore_account"])
	if "suspicion" in effects:
		suspicion_level += float(effects["suspicion"])
	elif "suspicion_meter" in effects:
		suspicion_level += float(effects["suspicion_meter"])
	if "city_visual_flag" in effects and not str(effects["city_visual_flag"]).is_empty():
		event_flags[effects["city_visual_flag"]] = true
	elif "city_flag" in effects and not str(effects["city_flag"]).is_empty():
		event_flags[effects["city_flag"]] = true
	if "unlocks_event_id" in effects and not str(effects["unlocks_event_id"]).is_empty():
		var unlocked_id: String = str(effects["unlocks_event_id"])
		if EventManager != null:
			EventManager.unlock_event(unlocked_id)

	_notify_stats_changed()
	_evaluate_end_conditions()


## Public method to notify listeners of municipal metrics updates
func notify_stats_changed() -> void:
	_notify_stats_changed()


## Emits both stats_updated (DESIGN_DOCUMENT) and stats_changed (PHASE_MAP)
func _notify_stats_changed() -> void:
	stats_updated.emit()
	stats_changed.emit()


## Advances to next day or triggers end condition
func advance_day() -> void:
	if is_game_over:
		return

	day_ended.emit(current_day)
	current_day += 1

	if current_day > MAX_DAYS:
		_evaluate_end_conditions()
	else:
		day_started.emit(current_day)


## Win / Loss evaluation (Section 2 & Phase 3)
func _evaluate_end_conditions() -> void:
	if is_game_over:
		return

	if suspicion_level >= 100.0:
		_trigger_game_end("END_ARRESTED")
	elif public_opinion <= 15.0:
		_trigger_game_end("END_RIOT")
	elif city_budget < -50000:
		_trigger_game_end("END_BANKRUPT")
	elif current_day > MAX_DAYS:
		if personal_wealth >= 250000:
			_trigger_game_end("END_FLED_TO_CAYMANS")
		elif public_opinion >= 50.0:
			_trigger_game_end("END_REELECTED")
		else:
			_trigger_game_end("END_LOST_ELECTION")


func _trigger_game_end(reason_key: String) -> void:
	is_game_over = true
	game_ended.emit(reason_key)
	game_over.emit(reason_key)


## Triggers immediate game end due to illicit bribe leak scandal
func trigger_bribe_leak_scandal() -> void:
	_trigger_game_end("END_BRIBE_LEAK_SCANDAL")


## Returns all event resolution records for a given day
func get_history_for_day(day_num: int) -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	for rec in daily_history:
		if int(rec.get("day", 0)) == day_num:
			records.append(rec)
	return records


## Records a resolved hotline call into daily records
func record_hotline_call(record: Dictionary) -> void:
	hotline_history.append(record)


## Returns all hotline records for a given day
func get_hotline_history_for_day(day_num: int) -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	for rec in hotline_history:
		if int(rec.get("day", 0)) == day_num:
			records.append(rec)
	return records

