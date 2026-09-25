extends Node

## SaveLoadManager.gd - Central manager for game serialization and slot persistence.
## Handles slot metadata, multi-slot save/load, deck reconstruction, and filesystem IO.

signal game_saved(slot_id: String)
signal game_loaded(slot_id: String)
signal save_deleted(slot_id: String)

const CURRENT_VERSION: String = "1.0"
const SAVES_DIR: String = "user://saves/"
const VALID_SLOTS: Array[String] = ["autosave", "slot_1", "slot_2", "slot_3"]
const AUTOSAVE_SLOT: String = "autosave"

var last_saved_slot: String = ""
var last_loaded_slot: String = ""


func _ready() -> void:
	_ensure_saves_dir()


## Ensures the saves directory exists under user://saves/
func _ensure_saves_dir() -> void:
	if not DirAccess.dir_exists_absolute(SAVES_DIR):
		var err := DirAccess.make_dir_recursive_absolute(SAVES_DIR)
		if err != OK:
			push_error("[SaveLoadManager] Failed to create saves directory: %s" % SAVES_DIR)


## Returns the absolute filesystem path for a given slot identifier
func get_save_path(slot_id: String) -> String:
	return "%s%s.json" % [SAVES_DIR, slot_id]


## Validates whether a slot ID is in the recognized list of slots
func is_valid_slot(slot_id: String) -> bool:
	return slot_id in VALID_SLOTS


## Checks if a save file exists for the given slot
func has_save(slot_id: String) -> bool:
	return FileAccess.file_exists(get_save_path(slot_id))


## Checks if any valid save slot exists in user://saves/
func has_any_save() -> bool:
	for slot_id in VALID_SLOTS:
		if has_save(slot_id):
			return true
	return false


## Returns the slot identifier with the latest timestamp, or empty string if none exist
func get_latest_save_slot() -> String:
	var latest_slot: String = ""
	var latest_time: int = -1
	for slot_id in VALID_SLOTS:
		if has_save(slot_id):
			var meta := get_slot_metadata(slot_id)
			var unix_time: int = int(meta.get("timestamp_unix", 0))
			if unix_time > latest_time:
				latest_time = unix_time
				latest_slot = slot_id
	return latest_slot


## Deletes the save file for the specified slot
func delete_save(slot_id: String) -> bool:
	if not has_save(slot_id):
		return false

	var path := get_save_path(slot_id)
	var err := DirAccess.remove_absolute(path)
	if err != OK:
		push_error("[SaveLoadManager] Failed to remove save at %s (code %d)" % [path, err])
		return false

	if last_saved_slot == slot_id:
		last_saved_slot = ""
	if last_loaded_slot == slot_id:
		last_loaded_slot = ""

	save_deleted.emit(slot_id)
	print("[SaveLoadManager] Save '%s' deleted successfully." % slot_id)
	return true


## Reads and returns metadata for a single slot without requiring full game state deserialization
func get_slot_metadata(slot_id: String) -> Dictionary:
	var default_name := _get_default_slot_name(slot_id)
	if not has_save(slot_id):
		return {
			"slot_id": slot_id,
			"save_name": default_name,
			"exists": false,
			"is_empty": true,
			"timestamp_unix": 0,
			"timestamp_str": "",
			"day": 0,
			"budget": 0,
			"city_budget": 0,
			"approval": 0.0,
			"public_opinion": 0.0,
			"suspicion": 0.0,
			"suspicion_level": 0.0,
			"offshore": 0,
			"offshore_account": 0,
			"personal_wealth": 0,
			"alignment": "",
			"version": CURRENT_VERSION
		}

	var path := get_save_path(slot_id)
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("[SaveLoadManager] Unable to open save file for metadata: %s" % path)
		return {
			"slot_id": slot_id,
			"save_name": default_name,
			"exists": false,
			"is_empty": true
		}

	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()

	if err != OK or not (json.data is Dictionary):
		push_error("[SaveLoadManager] Corrupt save file metadata at: %s" % path)
		return {
			"slot_id": slot_id,
			"save_name": default_name,
			"exists": false,
			"is_empty": true
		}

	var root_dict: Dictionary = json.data
	var meta: Dictionary = root_dict.get("metadata", {}).duplicate(true)
	meta["exists"] = true
	meta["is_empty"] = false
	if not meta.has("slot_id"):
		meta["slot_id"] = slot_id
	if not meta.has("save_name"):
		meta["save_name"] = default_name
	return meta


## Returns metadata dictionaries for all standard slots (autosave, slot_1, slot_2, slot_3)
func get_all_slots_metadata() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for slot_id in VALID_SLOTS:
		results.append(get_slot_metadata(slot_id))
	return results


## Serializes and writes complete game state to a save slot
func save_game(slot_id: String) -> bool:
	_ensure_saves_dir()
	var metadata := _build_metadata(slot_id)

	var game_state: Dictionary = {
		"current_day": GameManager.current_day,
		"is_game_over": GameManager.is_game_over,
		"city_budget": GameManager.city_budget,
		"public_opinion": GameManager.public_opinion,
		"personal_wealth": GameManager.personal_wealth,
		"suspicion_level": GameManager.suspicion_level,
		"event_flags": GameManager.event_flags.duplicate(true),
		"daily_history": GameManager.daily_history.duplicate(true),
		"active_event_id": GameManager.active_event.id if GameManager.active_event != null else ""
	}

	var draw_ids: Array[String] = []
	for ev in EventManager.draw_pile:
		if ev != null:
			draw_ids.append(ev.id)

	var discard_ids: Array[String] = []
	for ev in EventManager.discard_pile:
		if ev != null:
			discard_ids.append(ev.id)

	var queue_ids: Array[String] = []
	# If an active event is currently on desk and not yet discarded or in queue, keep it first
	if GameManager.active_event != null:
		var active_ev_id: String = GameManager.active_event.id
		if not discard_ids.has(active_ev_id) and not queue_ids.has(active_ev_id):
			queue_ids.append(active_ev_id)

	for ev in EventManager.daily_queue:
		if ev != null and not queue_ids.has(ev.id):
			queue_ids.append(ev.id)

	var deck_state: Dictionary = {
		"draw_pile_ids": draw_ids,
		"discard_pile_ids": discard_ids,
		"daily_queue_ids": queue_ids
	}

	var payload: Dictionary = {
		"version": CURRENT_VERSION,
		"metadata": metadata,
		"game_state": game_state,
		"deck_state": deck_state
	}

	var path := get_save_path(slot_id)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("[SaveLoadManager] Cannot open %s for write." % path)
		return false

	var json_str := JSON.stringify(payload, "\t")
	file.store_string(json_str)
	file.close()

	last_saved_slot = slot_id
	game_saved.emit(slot_id)
	print("[SaveLoadManager] Game saved to slot '%s' (%s)." % [slot_id, path])
	return true


## Deserializes and restores complete game state from a save slot
func load_game(slot_id: String) -> bool:
	var path := get_save_path(slot_id)
	if not FileAccess.file_exists(path):
		push_error("[SaveLoadManager] Save file missing: %s" % path)
		return false

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("[SaveLoadManager] Cannot open save file: %s" % path)
		return false

	var content := file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(content)
	if err != OK or not (json.data is Dictionary):
		push_error("[SaveLoadManager] Corrupt save JSON at %s" % path)
		return false

	var root_dict: Dictionary = json.data
	var game_state: Dictionary = root_dict.get("game_state", {})
	var deck_state: Dictionary = root_dict.get("deck_state", {})

	# 1. Restore GameManager state
	GameManager.current_day = int(game_state.get("current_day", 1))
	GameManager.is_game_over = bool(game_state.get("is_game_over", false))
	GameManager.city_budget = int(game_state.get("city_budget", 100000))
	GameManager.public_opinion = float(game_state.get("public_opinion", 50.0))
	GameManager.personal_wealth = int(game_state.get("personal_wealth", 0))
	GameManager.suspicion_level = float(game_state.get("suspicion_level", 0.0))

	GameManager.event_flags.clear()
	var flags: Dictionary = game_state.get("event_flags", {})
	for k in flags:
		GameManager.event_flags[k] = flags[k]

	GameManager.daily_history.clear()
	var hist: Array = game_state.get("daily_history", [])
	for item in hist:
		if item is Dictionary:
			GameManager.daily_history.append(item.duplicate(true))

	# 2. Restore EventManager deck state
	if EventManager.all_events.is_empty():
		EventManager.load_events_from_json()

	EventManager.draw_pile.clear()
	var draw_ids: Array = deck_state.get("draw_pile_ids", [])
	for id_val in draw_ids:
		var ev := _find_event(str(id_val))
		if ev != null:
			EventManager.draw_pile.append(ev)

	EventManager.discard_pile.clear()
	var discard_ids: Array = deck_state.get("discard_pile_ids", [])
	for id_val in discard_ids:
		var ev := _find_event(str(id_val))
		if ev != null:
			EventManager.discard_pile.append(ev)

	EventManager.daily_queue.clear()
	var queue_ids: Array = deck_state.get("daily_queue_ids", [])
	for id_val in queue_ids:
		var ev := _find_event(str(id_val))
		if ev != null:
			EventManager.daily_queue.append(ev)

	var active_id: String = str(game_state.get("active_event_id", ""))
	if not active_id.is_empty():
		GameManager.active_event = _find_event(active_id)
	else:
		GameManager.active_event = null

	GameManager.notify_stats_changed()

	last_loaded_slot = slot_id
	game_loaded.emit(slot_id)
	print("[SaveLoadManager] Successfully loaded slot '%s'." % slot_id)
	return true


func _build_metadata(slot_id: String) -> Dictionary:
	var now_unix: int = int(Time.get_unix_time_from_system())
	var dt := Time.get_datetime_dict_from_system()
	var dt_str := "%04d-%02d-%02d %02d:%02d:%02d" % [
		dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second
	]
	var alignment := _calculate_alignment(
		GameManager.suspicion_level, GameManager.personal_wealth
	)
	var default_name := _get_default_slot_name(slot_id)

	return {
		"slot_id": slot_id,
		"save_name": default_name,
		"timestamp_unix": now_unix,
		"timestamp_str": dt_str,
		"day": GameManager.current_day,
		"budget": GameManager.city_budget,
		"city_budget": GameManager.city_budget,
		"approval": GameManager.public_opinion,
		"public_opinion": GameManager.public_opinion,
		"suspicion": GameManager.suspicion_level,
		"suspicion_level": GameManager.suspicion_level,
		"offshore": GameManager.personal_wealth,
		"offshore_account": GameManager.personal_wealth,
		"personal_wealth": GameManager.personal_wealth,
		"alignment": alignment,
		"version": CURRENT_VERSION
	}


func _calculate_alignment(suspicion: float, offshore: int) -> String:
	if suspicion >= 50.0 or offshore >= 30000:
		return "Corrupt"
	if suspicion <= 15.0 and offshore == 0:
		return "Lawful"
	return "Moderate"


func _get_default_slot_name(slot_id: String) -> String:
	match slot_id:
		"autosave":
			return "Autosave"
		"slot_1":
			return "Slot 1"
		"slot_2":
			return "Slot 2"
		"slot_3":
			return "Slot 3"
		_:
			return slot_id.capitalize()


func _find_event(event_id: String) -> EventData:
	if EventManager != null:
		return EventManager.get_event_by_id(event_id)
	return null
