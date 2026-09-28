# Prompt Specification: Refine Discrepancy Matching, Expand Inspectable Fields & Fix Hotline Call Cooldowns

## Context & Problem Statement
The core investigation gameplay loop in `c:/Users/User/Documents/yes-mr-mayor/scripts/` has three subtle logic defects that harm player intuition and difficulty balancing:

### 1. Over-Permissive Discrepancy Matching
In `EventData.gd`, `find_matching_violation(tag_a: String, tag_b: String)` iterates through `violations` where each violation has a list of `tags`. If a violation lists 3 tags:
`"tags": ["app_district", "rule_zoning_river", "rep_hazard"]`
A player can simply click `app_district` and `rep_hazard` on the dossier and instantly uncover the violation without ever opening or cross-referencing the Municipal Rulebook! This bypasses the intended *Papers, Please* deduction mechanic.

### 2. Missing Inspectable Narrative Fields
In `DocumentItem.gd`, only structured technical fields (`district`, `floors`, `budget`, `seal`, `expiry`, `measured_floors`, `hazard`, `tax_debt`, `soil`) are inspectable. The petition narrative description (`body_text_label`) and the inspector's handwritten notes (`inspector_notes_label`) are static labels without click handlers or inspection bindings, preventing narrative-based contradictions.

### 3. Hotline Repetition & Unexpected Shift Time Penalty
- In `HotlineManager.gd`, `pick_next_call()` selects randomly from all eligible calls with zero cooldown or tracking of previously answered calls. In a 30-day run with 15 calls, players frequently encounter duplicate dialogues back-to-back.
- In `RedTelephone.gd`, when the player accepts an incoming emergency call with `"reveal_violation": true` (such as a Whistleblower or Chief Engineer leak), it emits `inspector_tip_requested`. In `DeskView._on_inspector_tip_requested()`, this silently subtracts 30 shift minutes (`PHONE_INQUIRY_TIME_COST_MINUTES`), penalizing the player with overtime fines for accepting an urgent call they did not initiate!

---

## Technical Objectives
1. **Enforce Cross-Category Token Pairing**:
   - In `EventData.find_matching_violation()`, require valid token pairings (e.g. Document Field vs. Rulebook Rule, or Application Field vs. Inspector Report Field).
2. **Make Narrative Texts Inspectable**:
   - Bind `body_text_label` (`app_description`) and `inspector_notes_label` (`rep_notes`) to the inspection system in `DocumentItem.gd`.
3. **Hotline Tracking & Fair Time Cost**:
   - Add a `seen_call_ids: Array[String]` and cooldown set to `HotlineManager`.
   - Separate `inspector_tip_requested` into `consultation_tip_requested` (charges $1,000 + 30 mins) and `whistleblower_tip_revealed` (intel provided for free as part of call acceptance).

---

## Detailed Implementation Specification

### 1. Target File: `scripts/resources/EventData.gd`
Update `find_matching_violation(tag_a: String, tag_b: String) -> Dictionary`:

```gdscript
func find_matching_violation(tag_a: String, tag_b: String) -> Dictionary:
    var norm_a: String = tag_a.to_lower()
    var norm_b: String = tag_b.to_lower()
    
    # Disallow matching two identical categories (e.g. two rulebook rules or two application fields)
    var is_a_rule := norm_a.begins_with("rule_")
    var is_b_rule := norm_b.begins_with("rule_")
    var is_a_app := norm_a.begins_with("app_")
    var is_b_app := norm_b.begins_with("app_")
    var is_a_rep := norm_a.begins_with("rep_")
    var is_b_rep := norm_b.begins_with("rep_")
    
    # Must be (App vs Rule), (Rep vs Rule), or (App vs Rep contradiction)
    var is_valid_pair := (is_a_rule != is_b_rule) or (is_a_app and is_b_rep) or (is_a_rep and is_b_app)
    if not is_valid_pair:
        return {}

    for v in violations:
        var targets: Array = v.get("tags", [])
        var has_a: bool = false
        var has_b: bool = false
        for t in targets:
            var target_str := str(t).to_lower()
            if target_str == norm_a:
                has_a = true
            if target_str == norm_b:
                has_b = true
        if has_a and has_b:
            return v
    return {}
```

### 2. Target File: `scripts/desk/DocumentItem.gd`
Add bindings for `body_text_label` and `inspector_notes_label`:

```gdscript
# In _setup_all_inspectables():
_bind_inspectable(body_text_label.get_parent() as PanelContainer, "app_description")
_bind_inspectable(inspector_notes_label.get_parent() as PanelContainer, "rep_notes")
```
Update `highlight_suspicious_field(field_tag: String)` to handle `"app_description"` and `"rep_notes"`.

### 3. Target File: `scripts/gameplay/HotlineManager.gd`
Add unique call tracking:

```gdscript
var seen_call_ids: Array[String] = []

func pick_next_call(day: int, event_flags: Dictionary = {}) -> HotlineCallData:
    var eligible := get_eligible_calls(day, event_flags)
    var unvisited: Array[HotlineCallData] = []
    
    for c in eligible:
        if not seen_call_ids.has(c.id):
            unvisited.append(c)
            
    if not unvisited.is_empty():
        var chosen: HotlineCallData = unvisited[randi() % unvisited.size()]
        seen_call_ids.append(chosen.id)
        return chosen
        
    # If all eligible calls seen, allow recycling
    if not eligible.is_empty():
        return eligible[randi() % eligible.size()]
    return null
```

### 4. Target Files: `scripts/desk/RedTelephone.gd` & `scripts/desk/DeskView.gd`
1. In `RedTelephone.gd`:
   - Emit signal `whistleblower_tip_revealed` instead of `inspector_tip_requested` when `active_call.has_reveal_violation(true)`.
2. In `DeskView.gd`:
   - Connect `red_telephone.whistleblower_tip_revealed.connect(_on_whistleblower_tip_revealed)`.
   - `_on_whistleblower_tip_revealed()` reveals the violation without advancing `current_shift_minutes`.

---

## Verification & Automated Test Plan
Create test script `tests/test_inspection_and_hotline_fixes.gd`:
1. **Rulebook Requirement Test**: Calling `evaluate_discrepancy("app_district", "rep_hazard")` for a zoning height violation should NOT match unless paired with `"rule_zoning_river"`.
2. **Hotline Unique Tracking**: Ring the telephone 5 times in a loop. Verify that no call ID repeats until the candidate pool is exhausted.
3. **Shift Time Integrity**: Answering a Whistleblower call must not advance the shift clock. Calling `consult_inspector()` voluntarily must advance the clock by exactly 30 minutes and deduct $1,000 from the city budget.
