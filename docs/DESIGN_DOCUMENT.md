# Technical Specification & GDD: "Yes, Mr. Mayor!" (Satirical Municipal Simulator)

Target Engine: **Godot 4.3+**  
Architecture: **Data-Driven, Fully Localized (i18n), Single-Developer Viable, 2D Control/CanvasItem Based**

---

## 1. Executive Summary & Constraints

* **Genre:** Bureaucracy Simulation / Satirical Strategy (Inspired by *Papers, Please* and *Reigns*).
* **Platform:** PC (Steam), 1920x1080 fixed base resolution (Scale Mode: `canvas_items`, Aspect: `keep`).
* **Visual Style:** Minimalist 2D tactile office desk layout + procedural background dynamic city skyline.
* **Strict Rule - Localization First (i18n):** Hardcoded user-facing strings are strictly forbidden anywhere in `.gd` code or scene node text properties. All text must pass through Godot’s built-in `TranslationServer` via `tr("KEY_NAME")` and dedicated CSV localization files.

---

## 2. Core Game Loop & Metrics

Players balance 4 active numerical variables across a 30-day mandate leading to an election:

| Metric | Range | Engine Type | Failure State / Consequence |
|---|---|---|---|
| **Public Approval** | $0.0 - 100.0$ | `float` | $< 50.0\%$ on Day 30 loses election. $< 15.0\%$ triggers instant riots/coup. |
| **City Budget** | $-\infty \dots +\infty$ | `int` | Deficits freeze public works, initiate municipal worker strikes. |
| **Offshore Account (Bribes)** | $0 \dots +\infty$ | `int` | Personal illicit funds used for troll campaigns, spin doctors, or exile escapes. |
| **Federal Suspicion** | $0.0 - 100.0$ | `float` | At $100.0\%$, federal auditors raid city hall (Instant Arrest Game Over). |

---

## 3. Strict Localization Architecture (i18n Standard)

### 3.1 Localization Database Structure
All narrative text and UI labels are referenced via string keys in a central localization table stored at `res://data/localization.csv`:

```csv
keys,en,tr,es
UI_TITLE,"Mr. Mayor: Paper Trail","Sayın Başkanım","Señor Alcalde"
UI_DAY,"Day: {day}","Gün: {day}","Día: {day}"
UI_STAMP_APPROVED,"APPROVED","ONAYLANDI","APROBADO"
UI_STAMP_REJECTED,"REJECTED","REDDEDİLDİ","RECHAZADO"
UI_BRIBE_POCKET,"Pocket Cash","Cebe İndir","Embolsarse"
EVT_001_TITLE,"Riverbed Housing Permit","Dere Yatağı Konut İzni","Permiso Cauce Fluvial"
EVT_001_DESC,"MegaCorp wants to build 20 luxury towers on the dry riverbed. It violates zoning laws, but they brought a gift briefcase.","Mega Yapı A.Ş. dere yatağına 20 katlı rezidans yapmak istiyor. İmara aykırı ama yanlarında bir çanta hediye getirdiler.","MegaCorp quiere construir 20 torres en el lecho del río. Viola la ley, pero trajeron un maletín."
EVT_001_NEWS_APP,"Flood sweeps luxury apartments! Mayor seen on private jet.","Yeni rezidansları su bastı! Başkan helikopter turunda görüntülendi.","¡Las inundaciones arrasan apartamentos de lujo! El alcalde viaja en jet."
EVT_001_NEWS_REJ,"Mayor protects ecological reserves; construction lobby furious.","Başkan rant çetelerine geçit vermedi: Yeşil alan korundu.","El alcalde protege las reservas ecológicas; los constructores enfurecen."
```

### 3.2 Dynamic Text Rule in GDScript
All runtime text must strictly invoke `tr()`:
```gdscript
# Correct:
status_label.text = tr("UI_DAY").format({"day": GameManager.current_day})

# Strictly Forbidden:
status_label.text = "Day: " + str(GameManager.current_day) # VIOLATION
```

---

## 4. Data-Driven Event Schema (`res://data/events.json`)

All daily interactions are defined purely by keys, numerical deltas, and state flags.

```json
[
  {
    "id": "EVT_001",
    "category": "zoning",
    "title_key": "EVT_001_TITLE",
    "description_key": "EVT_001_DESC",
    "applicant_key": "COMP_MEGACORP",
    "bribe_offered": 50000,
    "effects_approve": {
      "budget": 25000,
      "personal_wealth": 50000,
      "public_opinion": -15.0,
      "suspicion": 20.0,
      "city_visual_flag": "add_concrete_tower"
    },
    "effects_reject": {
      "budget": 0,
      "personal_wealth": 0,
      "public_opinion": 5.0,
      "suspicion": -5.0,
      "city_visual_flag": "preserve_greenery"
    },
    "news_headline_approve_key": "EVT_001_NEWS_APP",
    "news_headline_reject_key": "EVT_001_NEWS_REJ"
  }
]
```

---

## 5. Scene Hierarchy & Interaction Design

```
res://scenes/
 ├── MainDesk.tscn              # Primary Gameplay Canvas
 │    ├── DeskUI (Control)
 │    │    ├── DossierHolder    # Folder containing incoming documents
 │    │    ├── StampApprove     # Drag-and-drop or clickable green seal
 │    │    ├── StampReject      # Drag-and-drop or clickable red seal
 │    │    ├── SafeDrawer       # Hidden drawer to store bribe envelopes
 │    │    └── RedTelephone     # Ringing emergency mechanic (random calls)
 │    ├── CityBackdrop (2D)
 │    │    ├── SkyLayer
 │    │    ├── SkylineTileMap   # Dynamically spawns towers/parks based on flags
 │    │    └── WeatherVFX (GPU) # Rain/Smog overlays
 │    └── HUD (Top Bar)
 │         ├── PublicScoreBar
 │         ├── BudgetCounter
 │         ├── SuspicionGauge
 │         └── LanguageSelector # Dynamic language toggle [EN, TR, ES]
```

---

## 6. Core Autoload Scripts

### 6.1 `GameManager.gd` (`res://scripts/autoload/GameManager.gd`)

```gdscript
extends Node

signal stats_updated
signal game_ended(reason_key: String)

var current_day: int = 1
const MAX_DAYS: int = 30

var public_opinion: float = 50.0:
	set(val):
		public_opinion = clamp(val, 0.0, 100.0)
var city_budget: int = 100000
var personal_wealth: int = 0
var suspicion_level: float = 0.0:
	set(val):
		suspicion_level = clamp(val, 0.0, 100.0)

var event_flags: Dictionary = {}

func apply_resolution(effects: Dictionary) -> void:
	if "public_opinion" in effects:
		public_opinion += effects["public_opinion"]
	if "budget" in effects:
		city_budget += effects["budget"]
	if "personal_wealth" in effects:
		personal_wealth += effects["personal_wealth"]
	if "suspicion" in effects:
		suspicion_level += effects["suspicion"]
	if "city_visual_flag" in effects:
		event_flags[effects["city_visual_flag"]] = true

	stats_updated.emit()
	_evaluate_end_conditions()

func _evaluate_end_conditions() -> void:
	if suspicion_level >= 100.0:
		game_ended.emit("END_ARRESTED")
	elif public_opinion <= 15.0:
		game_ended.emit("END_RIOT")
	elif current_day > MAX_DAYS:
		if public_opinion >= 50.0:
			game_ended.emit("END_REELECTED")
		else:
			game_ended.emit("END_LOST_ELECTION")
```

### 6.2 `LocalizationManager.gd` (`res://scripts/autoload/LocalizationManager.gd`)

```gdscript
extends Node

const SUPPORTED_LOCALES: Array[String] = ["en", "tr", "es"]

func set_locale(locale_code: String) -> void:
	if locale_code in SUPPORTED_LOCALES:
		TranslationServer.set_locale(locale_code)
	else:
		push_warning("Locale %s not supported, falling back to English." % locale_code)
		TranslationServer.set_locale("en")
```

---

## 7. Streamer & Virality Features

1. **End-of-Day Tabloid Headline:** Every finished day presents a newspaper cover with satirical headlines based on decisions made during the shift (`news_headline_*_key`).
2. **The "Bribe Drawer" Temptation:** Bribes are never automatically taken. A glowing suitcase/envelope sits on the desk; the streamer must physically drag or click it into their private drawer, creating audible, clip-worthy "corruption" moments for their audience.
3. **Twitch Chat Integration Readiness:** Ready-to-bind vote triggers for chat polling:
   * Action 1: `approve`
   * Action 2: `reject`
   * Action 3: `take_bribe`

---

## 8. AntiGravity Implementation Directives

When generating code for this specification:
1. **Never use inline static strings** for anything visible on screen. Always implement `tr("KEY")`.
2. Keep UI modular using Godot's built-in `VBoxContainer`, `HBoxContainer`, and `MarginContainer` for clean text scaling across different language lengths.
3. Provide `.csv` header and data definitions alongside any new gameplay events created.