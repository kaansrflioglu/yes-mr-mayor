class_name HotlineManager
extends RefCounted

## HotlineManager.gd - Gameplay controller for dynamic emergency hotline calls.
## Manages call database loading, filtering by day & flags, archetype metadata,
## audio routing, and decision consequence application.

const DEFAULT_CALLS_PATH: String = "res://data/hotline_calls.json"

var all_calls: Array[HotlineCallData] = []
var call_history: Array[Dictionary] = []


func _init(path: String = DEFAULT_CALLS_PATH) -> void:
	load_calls_from_json(path)


## Loads hotline calls from JSON database
func load_calls_from_json(path: String = DEFAULT_CALLS_PATH) -> bool:
	all_calls.clear()
	if not FileAccess.file_exists(path):
		push_warning("Hotline calls JSON not found at %s" % path)
		return false

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Cannot open hotline calls JSON at %s" % path)
		return false

	var json := JSON.new()
	var result := json.parse(file.get_as_text())
	if result != OK:
		var err := "Error parsing hotline calls JSON: %s" % json.get_error_message()
		push_error(err)
		return false

	if json.data is Array:
		for item in json.data:
			if item is Dictionary:
				all_calls.append(HotlineCallData.from_dict(item))

	print("[HotlineManager] Loaded %d dynamic hotline calls." % all_calls.size())
	return true


## Filters calls available on a given day with active event flags
func get_eligible_calls(day: int, event_flags: Dictionary = {}) -> Array[HotlineCallData]:
	var eligible: Array[HotlineCallData] = []
	for call_data in all_calls:
		if not call_data.is_available_on_day(day):
			continue
		if not call_data.required_flag.is_empty():
			if not event_flags.get(call_data.required_flag, false):
				continue
		eligible.append(call_data)
	return eligible


## Picks a random eligible call for the given day and state
func pick_next_call(day: int, event_flags: Dictionary = {}) -> HotlineCallData:
	var eligible := get_eligible_calls(day, event_flags)
	if eligible.is_empty():
		# Fallback to all_calls if pool is empty
		if not all_calls.is_empty():
			return all_calls[randi() % all_calls.size()]
		return null

	return eligible[randi() % eligible.size()]


## Returns visual styling, icon, and translation keys for an archetype
static func get_archetype_badge_data(archetype: String) -> Dictionary:
	match archetype.to_lower():
		"party_boss":
			return {
				"icon": "🌹",
				"badge_key": "HOTLINE_BADGE_PARTY_BOSS",
				"accent_color": Color(0.85, 0.15, 0.15, 1.0),
				"is_urgent": false
			}
		"police_chief":
			return {
				"icon": "🛡️",
				"badge_key": "HOTLINE_BADGE_POLICE_CHIEF",
				"accent_color": Color(0.12, 0.45, 0.90, 1.0),
				"is_urgent": true
			}
		"mafia":
			return {
				"icon": "🕶️",
				"badge_key": "HOTLINE_BADGE_MAFIA",
				"accent_color": Color(0.60, 0.25, 0.75, 1.0),
				"is_urgent": false
			}
		"journalist":
			return {
				"icon": "📰",
				"badge_key": "HOTLINE_BADGE_JOURNALIST",
				"accent_color": Color(0.92, 0.65, 0.10, 1.0),
				"is_urgent": false
			}
		"chief_engineer":
			return {
				"icon": "📐",
				"badge_key": "HOTLINE_BADGE_CHIEF_ENGINEER",
				"accent_color": Color(0.95, 0.45, 0.15, 1.0),
				"is_urgent": true
			}
		"whistleblower":
			return {
				"icon": "🕵️",
				"badge_key": "HOTLINE_BADGE_WHISTLEBLOWER",
				"accent_color": Color(0.15, 0.75, 0.45, 1.0),
				"is_urgent": true
			}
		_:
			return {
				"icon": "☎️",
				"badge_key": "UI_HOTLINE_TITLE",
				"accent_color": Color(0.85, 0.2, 0.2, 1.0),
				"is_urgent": false
			}


## Resolves effects of accepting or rejecting a hotline call
func resolve_call(call_data: HotlineCallData, accepted: bool, day: int) -> Dictionary:
	if call_data == null:
		return {}

	var effects: Dictionary = (
		call_data.effects_accept if accepted
		else call_data.effects_reject
	)

	# Apply through GameManager
	if GameManager != null and GameManager.has_method("apply_resolution"):
		GameManager.apply_resolution(effects)

	# Record in history
	var entry: Dictionary = {
		"day": day,
		"call_id": call_data.id,
		"archetype": call_data.caller_archetype,
		"accepted": accepted,
		"effects": effects.duplicate(true)
	}
	call_history.append(entry)
	if GameManager != null and GameManager.has_method("record_hotline_call"):
		GameManager.record_hotline_call(entry)
	return effects


## Returns headline localization key for end-of-day tabloid based on call and outcome
static func get_hotline_headline_key(archetype: String, accepted: bool) -> String:
	match archetype.to_lower():
		"party_boss":
			return (
				"HOTLINE_NEWS_PARTY_BOSS_APP" if accepted
				else "HOTLINE_NEWS_PARTY_BOSS_REJ"
			)
		"police_chief":
			return (
				"HOTLINE_NEWS_POLICE_APP" if accepted
				else "HOTLINE_NEWS_POLICE_REJ"
			)
		"mafia":
			return (
				"HOTLINE_NEWS_MAFIA_APP" if accepted
				else "HOTLINE_NEWS_MAFIA_REJ"
			)
		"journalist":
			return (
				"HOTLINE_NEWS_PRESS_APP" if accepted
				else "HOTLINE_NEWS_PRESS_REJ"
			)
		"chief_engineer":
			return (
				"HOTLINE_NEWS_ENGINEER_APP" if accepted
				else "HOTLINE_NEWS_ENGINEER_REJ"
			)
		"whistleblower":
			return (
				"HOTLINE_NEWS_WHISTLE_APP" if accepted
				else "HOTLINE_NEWS_WHISTLE_REJ"
			)
		_:
			return "HOTLINE_NEWS_GENERIC"
