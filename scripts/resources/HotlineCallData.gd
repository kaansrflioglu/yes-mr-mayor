class_name HotlineCallData
extends Resource

## HotlineCallData.gd - Resource data model representing a dynamic incoming hotline call
## on the Mayor's red emergency desk telephone.
## Strict i18n compliant: all narrative texts use translation keys.

@export var id: String = ""
## Archetypes: party_boss, police_chief, mafia, journalist, chief_engineer, whistleblower
@export var caller_archetype: String = ""
@export var caller_name_key: String = ""
@export var caller_title_key: String = ""
@export var message_key: String = ""
@export var accept_btn_key: String = ""
@export var reject_btn_key: String = ""

@export var effects_accept: Dictionary = {
	"budget": 0,
	"personal_wealth": 0,
	"public_opinion": 0.0,
	"suspicion": 0.0,
	"reveal_violation": false
}

@export var effects_reject: Dictionary = {
	"budget": 0,
	"personal_wealth": 0,
	"public_opinion": 0.0,
	"suspicion": 0.0,
	"reveal_violation": false
}

@export var min_day: int = 1
@export var max_day: int = 30
@export var required_flag: String = ""


## Factory method to instantiate HotlineCallData from a Dictionary (e.g. from hotline_calls.json)
static func from_dict(dict: Dictionary) -> HotlineCallData:
	var call_data := HotlineCallData.new()
	call_data.id = str(dict.get("id", ""))
	call_data.caller_archetype = str(dict.get("caller_archetype", ""))
	call_data.caller_name_key = str(dict.get("caller_name_key", ""))
	call_data.caller_title_key = str(dict.get("caller_title_key", ""))
	call_data.message_key = str(dict.get("message_key", ""))
	call_data.accept_btn_key = str(dict.get("accept_btn_key", ""))
	call_data.reject_btn_key = str(dict.get("reject_btn_key", ""))

	if dict.has("effects_accept") and dict["effects_accept"] is Dictionary:
		call_data.effects_accept = dict["effects_accept"].duplicate(true)
	if dict.has("effects_reject") and dict["effects_reject"] is Dictionary:
		call_data.effects_reject = dict["effects_reject"].duplicate(true)

	call_data.min_day = int(dict.get("min_day", 1))
	call_data.max_day = int(dict.get("max_day", 30))
	call_data.required_flag = str(dict.get("required_flag", ""))
	return call_data


## Serializes HotlineCallData into a standard Dictionary
func to_dict() -> Dictionary:
	return {
		"id": id,
		"caller_archetype": caller_archetype,
		"caller_name_key": caller_name_key,
		"caller_title_key": caller_title_key,
		"message_key": message_key,
		"accept_btn_key": accept_btn_key,
		"reject_btn_key": reject_btn_key,
		"effects_accept": effects_accept.duplicate(true),
		"effects_reject": effects_reject.duplicate(true),
		"min_day": min_day,
		"max_day": max_day,
		"required_flag": required_flag
	}


## Strict i18n accessors using Godot's TranslationServer via tr()
func get_caller_name() -> String:
	return tr(caller_name_key) if not caller_name_key.is_empty() else ""

func get_caller_title() -> String:
	return tr(caller_title_key) if not caller_title_key.is_empty() else ""

func get_message() -> String:
	return tr(message_key) if not message_key.is_empty() else ""

func get_accept_text() -> String:
	return tr(accept_btn_key) if not accept_btn_key.is_empty() else ""

func get_reject_text() -> String:
	return tr(reject_btn_key) if not reject_btn_key.is_empty() else ""

func is_available_on_day(day: int) -> bool:
	return day >= min_day and day <= max_day

func has_reveal_violation(accepted: bool) -> bool:
	var eff := effects_accept if accepted else effects_reject
	return bool(eff.get("reveal_violation", false))
