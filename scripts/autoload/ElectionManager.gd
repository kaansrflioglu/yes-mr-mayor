extends Node

## ElectionManager.gd - Autoload managing the Mayoral Election Campaign Sprint (Days 23-30).
## Tracks district battleground polls, dynamic rivals, and election night ballot tallying.

signal polling_updated(incumbent_pct: float, rival_pct: float)
signal election_concluded(victory: bool, final_incumbent_pct: float)
signal campaign_started(rival_id: String, rival_name: String)

var is_campaign_active: bool = false
var rival_id: String = "reformer" # "reformer" (Vera Sterling) or "populist" (Big Vic)
var incumbent_poll: float = 48.0
var rival_poll: float = 52.0

var district_polls: Dictionary = {}


func _ready() -> void:
	reset_state()
	if GameManager != null:
		if GameManager.has_signal("game_restarted"):
			GameManager.game_restarted.connect(reset_state)
		if GameManager.has_signal("day_started"):
			GameManager.day_started.connect(activate_campaign)


func reset_state() -> void:
	is_campaign_active = false
	rival_id = "reformer"
	district_polls = {
		"DIST_CENTRAL": 50.0,
		"DIST_RIVERBED": 45.0,
		"DIST_INDUSTRIAL": 52.0,
		"DIST_HISTORIC": 46.0,
		"DIST_SUBURBS": 49.0
	}
	_recalculate_aggregate_poll()


func activate_campaign(day: int) -> void:
	if day >= 23 and not is_campaign_active:
		is_campaign_active = true

		# Select rival candidate dynamically based on player corruption & wealth
		var susp: float = GameManager.suspicion_level if GameManager != null else 0.0
		var wealth: int = GameManager.personal_wealth if GameManager != null else 0

		if susp > 40.0 or wealth > 80000:
			rival_id = "reformer"
		else:
			rival_id = "populist"

		_recalculate_aggregate_poll()
		campaign_started.emit(rival_id, get_rival_name())
		print("[ElectionManager] Election Sprint activated on Day %d vs rival: %s" % [day, rival_id])


func get_rival_name() -> String:
	if rival_id == "reformer":
		return "Vera Sterling"
	return "Victor 'Big Vic' Moreno"


func get_rival_title_key() -> String:
	if rival_id == "reformer":
		return "RIVAL_REFORMER_NAME"
	return "RIVAL_POPULIST_NAME"


func update_district_vote(district_id: String, delta: float) -> void:
	if district_polls.has(district_id):
		district_polls[district_id] = clampf(float(district_polls[district_id]) + delta, 10.0, 90.0)
		_recalculate_aggregate_poll()


func process_decision(event: EventData, approved: bool, took_bribe: bool = false) -> void:
	if not is_campaign_active or event == null:
		return

	var dist_id: String = "DIST_CENTRAL"
	if event.application_data != null and event.application_data.has("district_id"):
		dist_id = str(event.application_data.get("district_id", "DIST_CENTRAL"))
	elif "district_id" in event and event.get("district_id") != null:
		dist_id = str(event.get("district_id"))

	var has_viol: bool = event.has_violations()
	var delta: float = 0.0

	if approved:
		if has_viol or took_bribe:
			delta = -6.0
		else:
			delta = 4.0
	else:
		if has_viol:
			delta = 3.5
		else:
			delta = -4.0

	update_district_vote(dist_id, delta)


func _recalculate_aggregate_poll() -> void:
	var sum: float = 0.0
	for d in district_polls:
		sum += float(district_polls[d])
	var count: float = float(maxi(district_polls.size(), 1))
	incumbent_poll = sum / count
	rival_poll = 100.0 - incumbent_poll
	polling_updated.emit(incumbent_poll, rival_poll)


func run_election_tally() -> bool:
	var won_districts: int = 0
	for d in district_polls:
		if float(district_polls[d]) >= 50.0:
			won_districts += 1

	var victory: bool = (won_districts >= 3)
	election_concluded.emit(victory, incumbent_poll)
	return victory


func get_save_data() -> Dictionary:
	return {
		"is_campaign_active": is_campaign_active,
		"rival_id": rival_id,
		"incumbent_poll": incumbent_poll,
		"rival_poll": rival_poll,
		"district_polls": district_polls.duplicate(true)
	}


func load_save_data(data: Dictionary) -> void:
	if not (data is Dictionary):
		return
	is_campaign_active = bool(data.get("is_campaign_active", false))
	rival_id = str(data.get("rival_id", "reformer"))
	if data.has("district_polls") and data["district_polls"] is Dictionary:
		for d in data["district_polls"]:
			district_polls[d] = float(data["district_polls"][d])
	_recalculate_aggregate_poll()
