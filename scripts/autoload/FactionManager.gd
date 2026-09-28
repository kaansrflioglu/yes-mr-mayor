extends Node

## FactionManager.gd - Autoload managing the 5-Faction Political Ecosystem
## and the Municipal District Blueprint simulation metrics.

signal faction_standing_changed(faction_id: String, new_val: float)
signal district_updated(district_id: String, stats: Dictionary)
signal faction_crisis_triggered(faction_id: String)
signal faction_perk_activated(faction_id: String)

var factions: Dictionary = {}
var districts: Dictionary = {}

var crisis_triggered_factions: Dictionary = {}


func _ready() -> void:
	reset_state()
	if GameManager != null and GameManager.has_signal("game_restarted"):
		GameManager.game_restarted.connect(reset_state)


func reset_state() -> void:
	factions = {
		"oligarchs": {"name_key": "FACTION_OLIGARCHS", "value": 50.0, "color": Color(0.9, 0.75, 0.2)},
		"unions": {"name_key": "FACTION_UNIONS", "value": 50.0, "color": Color(0.85, 0.35, 0.2)},
		"greens": {"name_key": "FACTION_GREENS", "value": 50.0, "color": Color(0.25, 0.8, 0.35)},
		"historic": {"name_key": "FACTION_HISTORIC", "value": 50.0, "color": Color(0.6, 0.4, 0.8)},
		"police": {"name_key": "FACTION_POLICE", "value": 50.0, "color": Color(0.2, 0.45, 0.9)}
	}

	districts = {
		"DIST_CENTRAL": {"name_key": "DIST_CENTRAL", "prosperity": 60.0, "pollution": 20.0, "unrest": 10.0},
		"DIST_RIVERBED": {"name_key": "DIST_RIVERBED", "prosperity": 30.0, "pollution": 35.0, "unrest": 25.0},
		"DIST_INDUSTRIAL": {"name_key": "DIST_INDUSTRIAL", "prosperity": 70.0, "pollution": 80.0, "unrest": 15.0},
		"DIST_HISTORIC": {"name_key": "DIST_HISTORIC", "prosperity": 55.0, "pollution": 15.0, "unrest": 5.0},
		"DIST_SUBURBS": {"name_key": "DIST_SUBURBS", "prosperity": 50.0, "pollution": 20.0, "unrest": 10.0}
	}

	crisis_triggered_factions.clear()


func adjust_faction(f_id: String, delta: float) -> void:
	if not factions.has(f_id):
		return

	var old_val: float = float(factions[f_id]["value"])
	var new_val: float = clampf(old_val + delta, 0.0, 100.0)
	factions[f_id]["value"] = new_val

	faction_standing_changed.emit(f_id, new_val)

	# Faction Crisis Check (< 15%)
	if new_val <= 15.0:
		faction_crisis_triggered.emit(f_id)
		crisis_triggered_factions[f_id] = true
	elif new_val > 25.0:
		crisis_triggered_factions.erase(f_id)

	# Perk Activation Check (> 80%)
	if old_val < 80.0 and new_val >= 80.0:
		faction_perk_activated.emit(f_id)


func get_faction_value(f_id: String) -> float:
	if factions.has(f_id):
		return float(factions[f_id].get("value", 50.0))
	return 50.0


func get_district_stats(dist_id: String) -> Dictionary:
	if districts.has(dist_id):
		return districts[dist_id].duplicate(true)
	return {}


func adjust_district(dist_id: String, stat: String, delta: float) -> void:
	if not districts.has(dist_id):
		return
	if districts[dist_id].has(stat):
		districts[dist_id][stat] = clampf(float(districts[dist_id][stat]) + delta, 0.0, 100.0)
		district_updated.emit(dist_id, districts[dist_id])


func process_decision(event: EventData, approved: bool, took_bribe: bool = false) -> void:
	if event == null:
		return

	var dist_id: String = "DIST_CENTRAL"
	if event.application_data != null and event.application_data.has("district_id"):
		dist_id = str(event.application_data.get("district_id", "DIST_CENTRAL"))
	elif "district_id" in event and event.get("district_id") != null:
		dist_id = str(event.get("district_id"))

	var category: String = event.category.to_lower()

	match category:
		"zoning", "development":
			adjust_faction("oligarchs", 6.0 if approved else -6.0)
			adjust_faction("historic", -8.0 if approved else 8.0)
			if districts.has(dist_id):
				districts[dist_id]["prosperity"] = clampf(districts[dist_id]["prosperity"] + (8.0 if approved else -4.0), 0.0, 100.0)
				districts[dist_id]["unrest"] = clampf(districts[dist_id]["unrest"] + (4.0 if approved else -2.0), 0.0, 100.0)
		"industrial":
			adjust_faction("oligarchs", 8.0 if approved else -4.0)
			adjust_faction("greens", -12.0 if approved else 10.0)
			if districts.has(dist_id):
				districts[dist_id]["pollution"] = clampf(districts[dist_id]["pollution"] + (15.0 if approved else -5.0), 0.0, 100.0)
				districts[dist_id]["prosperity"] = clampf(districts[dist_id]["prosperity"] + (10.0 if approved else -5.0), 0.0, 100.0)
		"labor", "transit", "infrastructure":
			adjust_faction("unions", 10.0 if approved else -10.0)
			adjust_faction("oligarchs", -4.0 if approved else 4.0)
			if districts.has(dist_id):
				districts[dist_id]["unrest"] = clampf(districts[dist_id]["unrest"] + (-8.0 if approved else 10.0), 0.0, 100.0)
				districts[dist_id]["prosperity"] = clampf(districts[dist_id]["prosperity"] + (6.0 if approved else -3.0), 0.0, 100.0)
		"emergency", "police":
			adjust_faction("police", 12.0 if approved else -12.0)
			if districts.has(dist_id):
				districts[dist_id]["unrest"] = clampf(districts[dist_id]["unrest"] + (-10.0 if approved else 12.0), 0.0, 100.0)
		"heritage", "culture", "historic":
			adjust_faction("historic", 10.0 if approved else -10.0)
			adjust_faction("oligarchs", -4.0 if approved else 4.0)
			if districts.has(dist_id):
				districts[dist_id]["prosperity"] = clampf(districts[dist_id]["prosperity"] + (5.0 if approved else -3.0), 0.0, 100.0)
		"parks", "environment", "eco":
			adjust_faction("greens", 12.0 if approved else -12.0)
			adjust_faction("oligarchs", -4.0 if approved else 4.0)
			if districts.has(dist_id):
				districts[dist_id]["pollution"] = clampf(districts[dist_id]["pollution"] + (-10.0 if approved else 5.0), 0.0, 100.0)
				districts[dist_id]["unrest"] = clampf(districts[dist_id]["unrest"] + (-5.0 if approved else 4.0), 0.0, 100.0)
		_:
			if category == "commerce":
				adjust_faction("oligarchs", 4.0 if approved else -4.0)
				if districts.has(dist_id):
					districts[dist_id]["prosperity"] = clampf(districts[dist_id]["prosperity"] + (4.0 if approved else -2.0), 0.0, 100.0)
			elif category == "social":
				adjust_faction("unions", 5.0 if approved else -5.0)
				if districts.has(dist_id):
					districts[dist_id]["unrest"] = clampf(districts[dist_id]["unrest"] + (-6.0 if approved else 6.0), 0.0, 100.0)

	if took_bribe:
		adjust_faction("oligarchs", 3.0)
		adjust_faction("police", -4.0)
		if districts.has(dist_id):
			districts[dist_id]["unrest"] = clampf(districts[dist_id]["unrest"] + 5.0, 0.0, 100.0)

	if districts.has(dist_id):
		district_updated.emit(dist_id, districts[dist_id])


## Returns bribe cash bonus multiplier (Oligarchs > 80% perk: +25% bonus cash)
func get_bribe_cash_multiplier() -> float:
	if get_faction_value("oligarchs") >= 80.0:
		return 1.25
	return 1.0


## Returns suspicion gain multiplier from bribes (Police > 80% perk: -50% suspicion from bribes)
func get_bribe_suspicion_multiplier() -> float:
	if get_faction_value("police") >= 80.0:
		return 0.5
	return 1.0


func get_save_data() -> Dictionary:
	var f_copy: Dictionary = {}
	for f_id in factions:
		var d = factions[f_id]
		f_copy[f_id] = {
			"value": d.get("value", 50.0),
			"name_key": d.get("name_key", "")
		}
	return {
		"factions": f_copy,
		"districts": districts.duplicate(true),
		"crisis_triggered": crisis_triggered_factions.duplicate(true)
	}


func load_save_data(data: Dictionary) -> void:
	if not (data is Dictionary):
		return

	if data.has("factions") and data["factions"] is Dictionary:
		for f_id in data["factions"]:
			if factions.has(f_id):
				factions[f_id]["value"] = float(data["factions"][f_id].get("value", 50.0))

	if data.has("districts") and data["districts"] is Dictionary:
		for d_id in data["districts"]:
			if districts.has(d_id):
				var loaded_d = data["districts"][d_id]
				districts[d_id]["prosperity"] = float(loaded_d.get("prosperity", 50.0))
				districts[d_id]["pollution"] = float(loaded_d.get("pollution", 20.0))
				districts[d_id]["unrest"] = float(loaded_d.get("unrest", 10.0))

	if data.has("crisis_triggered") and data["crisis_triggered"] is Dictionary:
		crisis_triggered_factions = data["crisis_triggered"].duplicate(true)
