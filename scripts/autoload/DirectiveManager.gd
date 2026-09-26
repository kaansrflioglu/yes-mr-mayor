extends Node

## DirectiveManager.gd - Daily Municipal Executive Orders & Morning Modifiers.
## Alters shift rules, suspicion/approval scaling, and triggers federal inquiries.

signal directive_activated(directive: Dictionary)

const DIR_STANDARD: String = "DIR_STANDARD"
const DIR_EPA_AUDIT: String = "DIR_EPA_AUDIT"
const DIR_BUDGET_CRISIS: String = "DIR_BUDGET_CRISIS"
const DIR_ANTI_CORRUPTION: String = "DIR_ANTI_CORRUPTION"
const DIR_ELECTION_SPRINT: String = "DIR_ELECTION_SPRINT"

var active_directive: Dictionary = {}
var active_directive_id: String = DIR_STANDARD

var _directives_catalog: Dictionary = {
	DIR_STANDARD: {
		"id": DIR_STANDARD,
		"day_trigger": 1,
		"title_key": "DIR_STANDARD_TITLE",
		"desc_key": "DIR_STANDARD_DESC",
		"opinion_mult": 1.0,
		"suspicion_mult": 1.0,
		"budget_mult": 1.0,
		"eco_bonus": false,
		"budget_crisis": false,
		"anti_corruption": false,
		"election_sprint": false
	},
	DIR_EPA_AUDIT: {
		"id": DIR_EPA_AUDIT,
		"day_trigger": 3,
		"title_key": "DIR_EPA_AUDIT_TITLE",
		"desc_key": "DIR_EPA_AUDIT_DESC",
		"opinion_mult": 1.0,
		"suspicion_mult": 1.0,
		"budget_mult": 1.0,
		"eco_bonus": true,
		"budget_crisis": false,
		"anti_corruption": false,
		"election_sprint": false
	},
	DIR_BUDGET_CRISIS: {
		"id": DIR_BUDGET_CRISIS,
		"day_trigger": 8,
		"title_key": "DIR_BUDGET_CRISIS_TITLE",
		"desc_key": "DIR_BUDGET_CRISIS_DESC",
		"opinion_mult": 1.0,
		"suspicion_mult": 1.0,
		"budget_mult": 1.5,
		"eco_bonus": false,
		"budget_crisis": true,
		"anti_corruption": false,
		"election_sprint": false
	},
	DIR_ANTI_CORRUPTION: {
		"id": DIR_ANTI_CORRUPTION,
		"day_trigger": 14,
		"title_key": "DIR_ANTI_CORRUPTION_TITLE",
		"desc_key": "DIR_ANTI_CORRUPTION_DESC",
		"opinion_mult": 1.0,
		"suspicion_mult": 3.0,
		"budget_mult": 1.0,
		"eco_bonus": false,
		"budget_crisis": false,
		"anti_corruption": true,
		"election_sprint": false
	},
	DIR_ELECTION_SPRINT: {
		"id": DIR_ELECTION_SPRINT,
		"day_trigger": 22,
		"title_key": "DIR_ELECTION_SPRINT_TITLE",
		"desc_key": "DIR_ELECTION_SPRINT_DESC",
		"opinion_mult": 2.0,
		"suspicion_mult": 1.0,
		"budget_mult": 1.0,
		"eco_bonus": false,
		"budget_crisis": false,
		"anti_corruption": false,
		"election_sprint": true
	}
}


func _ready() -> void:
	reset_state()


## Resets active directive to standard administrative guidelines
func reset_state() -> void:
	set_active_directive(DIR_STANDARD)


## Sets active directive by string ID
func set_active_directive(dir_id: String) -> void:
	if _directives_catalog.has(dir_id):
		active_directive_id = dir_id
		active_directive = _directives_catalog[dir_id].duplicate(true)
	else:
		active_directive_id = DIR_STANDARD
		active_directive = _directives_catalog[DIR_STANDARD].duplicate(true)
	directive_activated.emit(active_directive)


## Evaluates which directive should be active for a given in-game day
func get_directive_for_day(day: int) -> Dictionary:
	if day >= 22:
		return _directives_catalog[DIR_ELECTION_SPRINT].duplicate(true)
	elif day >= 14:
		return _directives_catalog[DIR_ANTI_CORRUPTION].duplicate(true)
	elif day >= 8:
		return _directives_catalog[DIR_BUDGET_CRISIS].duplicate(true)
	elif day >= 3:
		return _directives_catalog[DIR_EPA_AUDIT].duplicate(true)
	else:
		return _directives_catalog[DIR_STANDARD].duplicate(true)


## Activates daily directive corresponding to day
func activate_directive_for_day(day: int) -> Dictionary:
	var d := get_directive_for_day(day)
	set_active_directive(str(d.get("id", DIR_STANDARD)))
	return active_directive


## Returns active directive dictionary
func get_active_directive() -> Dictionary:
	if active_directive.is_empty():
		reset_state()
	return active_directive


func get_active_title() -> String:
	var d := get_active_directive()
	return tr(str(d.get("title_key", "DIR_STANDARD_TITLE")))


func get_active_desc() -> String:
	var d := get_active_directive()
	return tr(str(d.get("desc_key", "DIR_STANDARD_DESC")))


## True if active directive turns all dirty bribes into undercover traps
func is_sting_override() -> bool:
	return bool(get_active_directive().get("anti_corruption", false))


## Applies directive multipliers and rules to a decision resolution dictionary
func apply_modifiers(
	effects: Dictionary,
	event: EventData,
	approved: bool,
	_took_bribe: bool
) -> Dictionary:
	var result: Dictionary = effects.duplicate(true)
	var dir := get_active_directive()

	# Opinion multipliers
	var op_mult: float = float(dir.get("opinion_mult", 1.0))
	if result.has("public_opinion"):
		result["public_opinion"] = float(result["public_opinion"]) * op_mult

	# Budget multipliers
	var bg_mult: float = float(dir.get("budget_mult", 1.0))
	if result.has("budget") and int(result["budget"]) > 0:
		result["budget"] = int(float(result["budget"]) * bg_mult)

	# Suspicion multipliers
	var susp_mult: float = float(dir.get("suspicion_mult", 1.0))
	if result.has("suspicion"):
		result["suspicion"] = float(result["suspicion"]) * susp_mult

	# Day 3 EPA Environmental Audit logic
	if bool(dir.get("eco_bonus", false)) and event != null:
		var has_eco_viol: bool = false
		for v in event.violations:
			var vid: String = str(v.get("id", "")).to_lower()
			if vid.contains("flood") or vid.contains("green") or vid.contains("hazard"):
				has_eco_viol = true
				break

		if has_eco_viol:
			if not approved:
				# Rejection of ecological disaster grants 2x approval bonus (+30%)
				result["public_opinion"] = float(result.get("public_opinion", 15.0)) * 2.0
			else:
				# Approving eco crime brings immediate Federal EPA Inquiry!
				result["suspicion"] = float(result.get("suspicion", 10.0)) + 25.0

	# Day 8 Budget Crisis: No public opinion penalty for rejecting costly projects
	if bool(dir.get("budget_crisis", false)):
		if not approved and float(result.get("public_opinion", 0.0)) < 0.0:
			result["public_opinion"] = 0.0

	return result
