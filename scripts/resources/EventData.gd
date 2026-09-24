class_name EventData
extends Resource

## EventData - Data model representing a bureaucratic petition / decision in "Yes, Mr. Mayor!"
## Strict i18n compliant: all narrative and display texts use
## translation keys instead of raw strings.

## Unique event identifier (e.g., "EVT_001")
@export var id: String = ""

## Category for filtering or thematic grouping (e.g. "zoning", "budget", "social", "emergency")
@export var category: String = "zoning"

## Localization keys for narrative texts (Strict i18n standard)
@export var title_key: String = ""
@export var description_key: String = ""
@export var applicant_key: String = ""

## Illicit cash bribe offered to the mayor (deposited into personal safe if pocketed)
@export var bribe_offered: int = 0

## Numerical & state impacts on approval
## Keys: "budget" (int), "personal_wealth" (int), "public_opinion" (float),
## "suspicion" (float), "city_visual_flag" (String)
@export var effects_approve: Dictionary = {
	"budget": 0,
	"personal_wealth": 0,
	"public_opinion": 0.0,
	"suspicion": 0.0,
	"city_visual_flag": ""
}

## Numerical & state impacts on rejection
@export var effects_reject: Dictionary = {
	"budget": 0,
	"personal_wealth": 0,
	"public_opinion": 0.0,
	"suspicion": 0.0,
	"city_visual_flag": ""
}

## Satirical newspaper headline keys for end-of-day tabloid
@export var news_headline_approve_key: String = ""
@export var news_headline_reject_key: String = ""


## Factory method to instantiate EventData from a Dictionary (e.g., loaded from events.json)
static func from_dict(dict: Dictionary) -> EventData:
	var event := EventData.new()
	event.id = str(dict.get("id", ""))
	event.category = str(dict.get("category", "general"))
	event.title_key = str(dict.get("title_key", ""))
	event.description_key = str(dict.get("description_key", ""))
	event.applicant_key = str(dict.get("applicant_key", ""))
	event.bribe_offered = int(dict.get("bribe_offered", 0))
	
	if dict.has("effects_approve") and dict["effects_approve"] is Dictionary:
		event.effects_approve = dict["effects_approve"].duplicate(true)
	if dict.has("effects_reject") and dict["effects_reject"] is Dictionary:
		event.effects_reject = dict["effects_reject"].duplicate(true)
		
	event.news_headline_approve_key = str(dict.get("news_headline_approve_key", ""))
	event.news_headline_reject_key = str(dict.get("news_headline_reject_key", ""))
	return event


## Serializes EventData into a standard Dictionary
func to_dict() -> Dictionary:
	return {
		"id": id,
		"category": category,
		"title_key": title_key,
		"description_key": description_key,
		"applicant_key": applicant_key,
		"bribe_offered": bribe_offered,
		"effects_approve": effects_approve.duplicate(true),
		"effects_reject": effects_reject.duplicate(true),
		"news_headline_approve_key": news_headline_approve_key,
		"news_headline_reject_key": news_headline_reject_key
	}


## Strict i18n accessors using Godot's TranslationServer via tr()
func get_title() -> String:
	return tr(title_key) if not title_key.is_empty() else ""

func get_description() -> String:
	return tr(description_key) if not description_key.is_empty() else ""

func get_applicant() -> String:
	return tr(applicant_key) if not applicant_key.is_empty() else ""

func get_news_headline(approved: bool) -> String:
	var key := news_headline_approve_key if approved else news_headline_reject_key
	return tr(key) if not key.is_empty() else ""
