extends Node

## EventManager.gd - Manages event loading, active deck, discard pile, and daily queue.
## Follows Phase 1 architecture from PHASE_MAP.md.

signal event_drawn(event: EventData)
signal deck_exhausted
signal daily_queue_prepared(day: int, event_count: int)

const DEFAULT_EVENTS_PATH: String = "res://data/events.json"
const DEFAULT_DAILY_QUOTA: int = 4

var all_events: Array[EventData] = []
var draw_pile: Array[EventData] = []
var discard_pile: Array[EventData] = []
var daily_queue: Array[EventData] = []


func _ready() -> void:
	load_events_from_json(DEFAULT_EVENTS_PATH)
	reset_deck()


## Loads events from JSON database
func load_events_from_json(path: String = DEFAULT_EVENTS_PATH) -> bool:
	all_events.clear()
	if not FileAccess.file_exists(path):
		push_warning("Events JSON not found at %s" % path)
		return false

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Cannot open events JSON at %s" % path)
		return false

	var json := JSON.new()
	var result := json.parse(file.get_as_text())
	if result != OK:
		var err := "Error parsing events JSON (Line %d): %s" % [
			json.get_error_line(), json.get_error_message()
		]
		push_error(err)
		return false

	if json.data is Array:
		for item in json.data:
			if item is Dictionary:
				all_events.append(EventData.from_dict(item))

	print("[EventManager] Loaded %d events into library." % all_events.size())
	return true


## Resets draw pile with all loaded events (excluding consequence events) and shuffles
func reset_deck() -> void:
	draw_pile.clear()
	discard_pile.clear()
	daily_queue.clear()
	for ev in all_events:
		if ev.category != "consequence":
			draw_pile.append(ev)
	draw_pile.shuffle()


## Unlocks a consequence event into the active draw pile
func unlock_event(event_id: String) -> void:
	var ev: EventData = get_event_by_id(event_id)
	if ev != null:
		if not draw_pile.has(ev) and not daily_queue.has(ev) and not discard_pile.has(ev):
			draw_pile.push_front(ev)
			print("[EventManager] Unlocked consequence event into deck: %s" % event_id)



## Checks if an event is valid for a given day according to its day_range
func is_event_eligible_for_day(event: EventData, day: int) -> bool:
	if event == null:
		return false
	if event.day_range.size() >= 2:
		return day >= event.day_range[0] and day <= event.day_range[1]
	return true


## Draws the next candidate from draw pile, reshuffling discard pile if needed
func _draw_candidate() -> EventData:
	if draw_pile.is_empty():
		if discard_pile.is_empty():
			deck_exhausted.emit()
			return null
		draw_pile = discard_pile.duplicate()
		discard_pile.clear()
		draw_pile.shuffle()
	return draw_pile.pop_back()


## Draws the next event from the active deck or reshuffles discard pile if empty
func draw_next_event() -> EventData:
	var event: EventData = _draw_candidate()
	if event != null:
		event_drawn.emit(event)
	return event


## Prepares a daily quota of events for the shift, respecting day_range
func prepare_daily_queue(quota: int = DEFAULT_DAILY_QUOTA) -> Array[EventData]:
	daily_queue.clear()
	var current_day: int = GameManager.current_day
	var temp_ineligible: Array[EventData] = []
	
	while daily_queue.size() < quota:
		var candidate: EventData = _draw_candidate()
		if candidate == null:
			break
		if is_event_eligible_for_day(candidate, current_day):
			daily_queue.append(candidate)
			event_drawn.emit(candidate)
		else:
			temp_ineligible.append(candidate)
			# Guard to avoid infinite loop if all remaining cards are ineligible
			if draw_pile.is_empty() and discard_pile.is_empty():
				break
	
	# Return temporarily set aside events back into the draw pile
	for ev in temp_ineligible:
		draw_pile.append(ev)
	draw_pile.shuffle()

	daily_queue_prepared.emit(current_day, daily_queue.size())
	return daily_queue


## Pops the next event from the daily queue
func pop_daily_event() -> EventData:
	if daily_queue.is_empty():
		return null
	return daily_queue.pop_front()


## Sends an event to discard pile
func discard_event(event: EventData) -> void:
	if event != null and not discard_pile.has(event):
		discard_pile.append(event)


## Checks if any events are remaining in draw pile or daily queue
func has_events() -> bool:
	return not draw_pile.is_empty() or not discard_pile.is_empty()


## Returns an event definition from library by its unique ID
func get_event_by_id(event_id: String) -> EventData:
	if all_events.is_empty():
		load_events_from_json()
	for ev in all_events:
		if ev != null and ev.id == event_id:
			return ev
	return null
