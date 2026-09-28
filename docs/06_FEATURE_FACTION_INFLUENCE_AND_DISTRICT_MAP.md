# Feature Prompt Specification: Municipal Faction Influence & District Blueprint Map

## Feature Summary & Vision
Currently, the mayoral administration is measured exclusively by four high-level scalars: `public_opinion`, `city_budget`, `personal_wealth`, and `suspicion_level`. However, real city politics is an intricate game of **competing interest groups** and **geographic district tensions**.

This feature introduces a **5-Faction Political Ecosystem** and an interactive, fold-out **Municipal Blueprint Map** on the mayor's desk. Every permit decision directly shifts faction favorability and transforms district prosperity, crime rates, and environmental stability.

---

## Gameplay Mechanics

### 1. The 5 Municipal Factions
| Faction | Favored Decisions | Disliked Decisions | Threshold Benefit (>80%) | Crisis Threshold (<15%) |
| :--- | :--- | :--- | :--- | :--- |
| **Real Estate Oligarchs** | Commercial towers, zoning variances, high budgets | Historic preservation, strict eco-limits | Generous bribes (+25% bonus cash) | Capital flight: City budget growth stalls |
| **Labor Unions** | Municipal infrastructure, public works, fair wages | Privatization, budget cuts, corporate tax breaks | Free shift stamina (Union coffee deliveries) | General strike: Shift quota doubled, public unrest |
| **Green Coalition** | Parks, clean transit, floodway protection | Toxic chimneys, industrial zoning, concrete sprawl | Eco-grants (Federal green subsidies) | Eco-protests: City hall surrounded by mobs |
| **Historic Society** | Heritage preservation, building height caps | High-rise demolition, neon casinos | Cultural tourism revenue (+10% opinion) | Vandalism & elite legal challenges |
| **Police Union** | Law enforcement funding, surveillance permits | Budget cuts, police chief dismissals | Reduced suspicion gains from bribes (-50%) | Police strike: Flasher sirens & riot threats |

### 2. The Fold-Out Desk Blueprint Map (`DistrictMapModal.tscn`)
- Positioned as a folded cyan blueprint on the desk blotter beside the rulebook.
- Opens with a tactile crisp paper unfold animation (`M` key or clicking the blueprint).
- Displays the 5 Municipal Districts:
  1. `DIST_CENTRAL` (Financial core, luxury skyline, government plaza).
  2. `DIST_RIVERBED` (Ecological floodplain, docks, vulnerable slums).
  3. `DIST_INDUSTRIAL` (Manufacturing plants, refineries, railway depot).
  4. `DIST_HISTORIC` (Old town clock tower, cobblestone boulevards).
  5. `DIST_SUBURBS` (Residential housing, suburban schools, commuter belt).
- Interactive District Metrics:
  * **Prosperity**: Influenced by approved developments.
  * **Pollution**: Raised by heavy industrial permits; creates smog.
  * **Unrest**: Raised by rejected community petitions or high corruption.

### 3. Faction Crisis & Ultimatum Hotline Calls
- When any faction favor drops below 15%, a high-priority emergency call triggers on the **Red Telephone**.
- The faction leader demands an immediate concession (e.g. firing an inspector, rejecting a rival permit, or paying emergency subsidies).
- Refusal risks immediate riots, strikes, or press leaks!

---

## Architecture & File Additions

### New Files to Create:
1. `scripts/autoload/FactionManager.gd`: Autoload managing faction standings, perks, ultimatums, and district stats.
2. `scenes/desk/DistrictMapModal.tscn`: UI modal presenting the architectural vector blueprint of the 5 districts and live faction trackers.
3. `scripts/ui/DistrictMapModal.gd`: Controller for district visualization, hover tooltips, and faction breakdown.

### Files to Modify:
1. `project.godot`:
   - Register autoload `FactionManager="*res://scripts/autoload/FactionManager.gd"`.
   - Register input action `mayor_map` mapped to Key `M`.
2. `scripts/desk/DeskView.gd`:
   - Add blueprint prop to desk.
   - Forward permit decisions to `FactionManager.process_decision(event, approved, took_bribe)`.
3. `scripts/ui/TopBarHUD.gd`:
   - Add compact mini-meter or faction overview button.
4. `data/events.json`:
   - Tag events with `faction_id` and district impacts.

---

## Step-by-Step Implementation Instructions

### Step 1: Create `FactionManager.gd`
```gdscript
extends Node

signal faction_standing_changed(faction_id: String, new_val: float)
signal district_updated(district_id: String, stats: Dictionary)
signal faction_crisis_triggered(faction_id: String)

var factions: Dictionary = {
    "oligarchs": {"name_key": "FACTION_OLIGARCHS", "value": 50.0, "color": Color(0.9, 0.75, 0.2)},
    "unions": {"name_key": "FACTION_UNIONS", "value": 50.0, "color": Color(0.85, 0.35, 0.2)},
    "greens": {"name_key": "FACTION_GREENS", "value": 50.0, "color": Color(0.25, 0.8, 0.35)},
    "historic": {"name_key": "FACTION_HISTORIC", "value": 50.0, "color": Color(0.6, 0.4, 0.8)},
    "police": {"name_key": "FACTION_POLICE", "value": 50.0, "color": Color(0.2, 0.45, 0.9)}
}

var districts: Dictionary = {
    "DIST_CENTRAL": {"prosperity": 60.0, "pollution": 20.0, "unrest": 10.0},
    "DIST_RIVERBED": {"prosperity": 30.0, "pollution": 35.0, "unrest": 25.0},
    "DIST_INDUSTRIAL": {"prosperity": 70.0, "pollution": 80.0, "unrest": 15.0},
    "DIST_HISTORIC": {"prosperity": 55.0, "pollution": 15.0, "unrest": 5.0},
    "DIST_SUBURBS": {"prosperity": 50.0, "pollution": 20.0, "unrest": 10.0}
}

func adjust_faction(f_id: String, delta: float) -> void:
    if factions.has(f_id):
        factions[f_id]["value"] = clampf(factions[f_id]["value"] + delta, 0.0, 100.0)
        faction_standing_changed.emit(f_id, factions[f_id]["value"])
        if factions[f_id]["value"] <= 15.0:
            faction_crisis_triggered.emit(f_id)

func process_decision(event: EventData, approved: bool, _took_bribe: bool) -> void:
    if event == null:
        return
        
    var dist_id: String = str(event.application_data.get("district_id", "DIST_CENTRAL"))
    var category: String = event.category.to_lower()
    
    match category:
        "zoning":
            adjust_faction("oligarchs", 6.0 if approved else -6.0)
            adjust_faction("historic", -8.0 if approved else 8.0)
        "industrial":
            adjust_faction("oligarchs", 8.0 if approved else -4.0)
            adjust_faction("greens", -12.0 if approved else 10.0)
            if districts.has(dist_id):
                districts[dist_id]["pollution"] = clampf(districts[dist_id]["pollution"] + (15.0 if approved else -5.0), 0.0, 100.0)
        "labor", "transit":
            adjust_faction("unions", 10.0 if approved else -10.0)
            adjust_faction("oligarchs", -4.0 if approved else 4.0)
        "emergency", "police":
            adjust_faction("police", 12.0 if approved else -12.0)
            
    if districts.has(dist_id):
        district_updated.emit(dist_id, districts[dist_id])
```

---

## Verification & Automated Test Plan
Create test script `tests/test_factions_and_map.gd`:
1. **Decision Impact**: Approve an industrial event. Verify Green Coalition drops by 12 points and Real Estate Oligarchs rises by 8 points.
2. **Crisis Trigger**: Drive Union favor below 15%. Verify `faction_crisis_triggered` signal fires with `"unions"`.
3. **Map Modal Navigation**: Press `M` key. Verify `DistrictMapModal` opens, displays all 5 districts, and reflects modified pollution/prosperity values.
