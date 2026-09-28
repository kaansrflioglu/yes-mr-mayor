extends Node

## EndingsManager.gd - Evaluates full mayoral mandate telemetry and determines
## the 12 distinct narrative endings, civic performance grade (S-F), historic title,
## district prosperity evolution, and 10-year municipal epilogue.

signal mandate_evaluated(evaluation: Dictionary)

const GRADE_COLORS := {
	"S": Color(0.95, 0.78, 0.22, 1.0), # Imperial Gold
	"A": Color(0.18, 0.80, 0.44, 1.0), # Civic Emerald
	"B": Color(0.20, 0.60, 0.95, 1.0), # Technocrat Blue
	"C": Color(0.90, 0.50, 0.15, 1.0), # Compromise Amber
	"D": Color(0.85, 0.35, 0.15, 1.0), # Mediocre Rust
	"F": Color(0.90, 0.20, 0.20, 1.0), # Catastrophic Red
}


## Evaluates the complete game state and returns comprehensive mandate report card data
func evaluate_mandate() -> Dictionary:
	var wealth: int = GameManager.personal_wealth
	var opinion: float = GameManager.public_opinion
	var susp: float = GameManager.suspicion_level
	var budget: int = GameManager.city_budget
	var flags: Dictionary = GameManager.event_flags
	var day: int = GameManager.current_day

	# Faction standings
	var f_greens: float = 50.0
	var f_oligarchs: float = 50.0
	var f_police: float = 50.0
	var f_unions: float = 50.0
	var f_historic: float = 50.0

	if Engine.has_singleton("FactionManager"):
		var fm = Engine.get_singleton("FactionManager")
		if fm != null and "factions" in fm and fm.factions.size() > 0:
			f_greens = float(fm.factions.get("greens", {}).get("value", 50.0))
			f_oligarchs = float(fm.factions.get("oligarchs", {}).get("value", 50.0))
			f_police = float(fm.factions.get("police", {}).get("value", 50.0))
			f_unions = float(fm.factions.get("unions", {}).get("value", 50.0))
			f_historic = float(fm.factions.get("historic", {}).get("value", 50.0))
	elif FactionManager != null and FactionManager.factions.size() > 0:
		f_greens = float(FactionManager.factions.get("greens", {}).get("value", 50.0))
		f_oligarchs = float(FactionManager.factions.get("oligarchs", {}).get("value", 50.0))
		f_police = float(FactionManager.factions.get("police", {}).get("value", 50.0))
		f_unions = float(FactionManager.factions.get("unions", {}).get("value", 50.0))
		f_historic = float(FactionManager.factions.get("historic", {}).get("value", 50.0))

	var end_key: String = ""
	var letter_grade: String = "C"
	var title_key: String = ""

	# 1. Sudden Failure Endings (Unconditional over-threshold checks)
	if susp >= 100.0 or flags.get("FLAG_STING_TRAP_CAUGHT", false) or flags.get("FLAG_ARRESTED_BY_FED", false):
		end_key = "END_FEDERAL_SUPERMAX"
		letter_grade = "F"
		title_key = "TITLE_CONVICTED_FELON"
	elif opinion <= 15.0:
		end_key = "END_REVOLUTION_STORM"
		letter_grade = "F"
		title_key = "TITLE_OUSTED_TYRANT"
	elif budget < -50000:
		end_key = "END_MUNICIPAL_BANKRUPT"
		letter_grade = "D"
		title_key = "TITLE_BANKRUPT_SPENDTHRIFT"
	elif day >= GameManager.MAX_DAYS:
		# 2. Full Mandate Endings (Evaluated on Day 30 or upon mandate completion)
		# Priority 1: Civic Saint (S) - Pristine virtue, zero offshore wealth, high opinion, near zero suspicion
		if opinion >= 85.0 and wealth == 0 and susp <= 15.0:
			end_key = "END_SAINT"
			letter_grade = "S"
			title_key = "TITLE_CIVIC_SAINT"
		# Priority 2: Teflon Mastermind (S) - Corrupt genius who amassed wealth while keeping public adoration
		elif wealth >= 200000 and opinion >= 65.0 and susp <= 30.0:
			end_key = "END_TEFLON_DON"
			letter_grade = "S"
			title_key = "TITLE_TEFLON_MASTERMIND"
		# Priority 3: Eco Utopia (S) - Green revolution without toxic air flags
		elif f_greens >= 80.0 and not flags.get("FLAG_TOXIC_CHIMNEYS", false) and not flags.get("city_flag_polluted_air", false):
			end_key = "END_ECO_UTOPIA"
			letter_grade = "S"
			title_key = "TITLE_EMERALD_METROPOLIS"
		# Priority 4: Corporate Puppet (B) - Oligarch corporate takeover
		elif f_oligarchs >= 80.0 or flags.get("FLAG_MEGACORP_TAKEOVER", false):
			end_key = "END_CORPORATE_PUPPET"
			letter_grade = "B"
			title_key = "TITLE_CORPORATE_PUPPET"
		# Priority 5: Mob Viceroy (C) - Syndicate partnership
		elif (flags.get("FLAG_ALLIED_MAFIA", false) or flags.get("FLAG_MAFIA_VICEROY", false)) and wealth >= 100000:
			end_key = "END_MOB_VICEROY"
			letter_grade = "C"
			title_key = "TITLE_SHADOW_CONSIGLIERE"
		# Priority 6: Shadow Junta (C) - Police state lockdown
		elif susp >= 80.0 and (f_police >= 80.0 or flags.get("FLAG_CURFEW_ENACTED", false)):
			end_key = "END_SHADOW_JUNTA"
			letter_grade = "C"
			title_key = "TITLE_EMERGENCY_AUTOCRAT"
		# Priority 7: Cayman Exile (B) - Fleeing with huge personal offshore loot
		elif wealth >= 250000:
			end_key = "END_CAYMAN_EXILE"
			letter_grade = "B"
			title_key = "TITLE_OFFSHORE_CORSAIR"
		# Priority 8: Cold Technocrat / Austere Accountant (B) - Large treasury surplus with moderate opinion
		elif budget >= 250000 and opinion >= 45.0 and opinion <= 65.0:
			end_key = "END_AUSTERE_ACCOUNTANT"
			letter_grade = "B"
			title_key = "TITLE_AUSTERE_TECHNOCRAT"
		# Priority 9: Re-elected People's Mayor (A) - Solid democratic victory
		elif opinion >= 50.0:
			end_key = "END_REELECTED"
			letter_grade = "A"
			title_key = "TITLE_PEOPLES_MAYOR"
		# Priority 10: Forgotten Interim (D) - Lackluster approval, forgotten administration
		else:
			end_key = "END_ONE_TERM_MEDIOCRE"
			letter_grade = "D"
			title_key = "TITLE_FORGOTTEN_MAYOR"

	var district_data: Dictionary = {}
	if FactionManager != null and FactionManager.districts.size() > 0:
		district_data = FactionManager.districts.duplicate(true)
	else:
		district_data = {
			"DIST_CENTRAL": {"name_key": "DIST_CENTRAL", "prosperity": 60.0},
			"DIST_RIVERBED": {"name_key": "DIST_RIVERBED", "prosperity": 35.0},
			"DIST_INDUSTRIAL": {"name_key": "DIST_INDUSTRIAL", "prosperity": 70.0},
			"DIST_HISTORIC": {"name_key": "DIST_HISTORIC", "prosperity": 55.0},
			"DIST_SUBURBS": {"name_key": "DIST_SUBURBS", "prosperity": 50.0}
		}

	var result: Dictionary = {
		"end_key": end_key,
		"letter_grade": letter_grade,
		"title_key": title_key,
		"grade_color": GRADE_COLORS.get(letter_grade, Color.WHITE),
		"epilogue_text": _generate_epilogue(end_key, flags),
		"stats": {
			"wealth": wealth,
			"opinion": opinion,
			"suspicion": susp,
			"budget": budget,
			"day": mini(day, GameManager.MAX_DAYS)
		},
		"factions": {
			"greens": f_greens,
			"oligarchs": f_oligarchs,
			"police": f_police,
			"unions": f_unions,
			"historic": f_historic
		},
		"districts": district_data
	}

	mandate_evaluated.emit(result)
	return result


## Generates the procedural 10-year historical epilogue based on ending outcome and flags
func _generate_epilogue(end_key: String, _flags: Dictionary) -> String:
	if end_key.is_empty():
		return ""
	var loc_key: String = end_key + "_EPILOGUE"
	var text: String = tr(loc_key)
	if text == loc_key:
		text = tr(end_key)
	return text
