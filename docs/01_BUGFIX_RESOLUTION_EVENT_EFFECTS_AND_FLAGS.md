# Prompt Specification: Fix Event Resolution Stat Overwrites & Consequence Flag Propagation

## Context & Problem Statement
In `c:/Users/User/Documents/yes-mr-mayor/scripts/desk/DeskView.gd`, `_execute_stamping(approved: bool)` currently discards the carefully balanced `effects_approve` and `effects_reject` dictionaries authored in `data/events.json`. 

### Symptoms in Current Codebase
1. **Hardcoded Flattened Stats**: In `DeskView.gd` (lines 982-1020), `res_effects` hardcodes flat approval (+12.0 or -15.0), suspicion (-5.0 or +15.0), and flat budget (+20,000 or 0), completely ignoring `event.effects_approve["budget"]`, `event.effects_approve["public_opinion"]`, etc. High-stakes events that should cost $100,000 or grant +30 approval have no individual impact.
2. **Stripped Visual Flags**: `res_effects` fails to copy `city_visual_flag` (or `city_flag`) from `event.effects_approve` / `event.effects_reject`. As a result, `GameManager.event_flags` never receives visual flags from resolved events, causing `SkylineView.gd` to miss dynamic background transformations (e.g. `add_concrete_tower`, `preserve_greenery`, `flood_catastrophe`).
3. **Broken Event Chains (`unlocks_event_id`)**: `events.json` supports consequence chaining via `unlocks_event_id`. Because `res_effects` omits `unlocks_event_id`, `GameManager.apply_resolution()` never triggers `EventManager.unlock_event()`, leaving narrative event chains dormant.

---

## Technical Objectives
1. Refactor `DeskView._execute_stamping(approved: bool)` so that it starts from the author-defined `event.effects_approve` or `event.effects_reject` base dictionary.
2. Apply deduction modifiers (bonuses for finding violations or penalties for corrupt approvals) as deltas or multiplier overlays rather than destructive overwrites.
3. Preserve all non-numeric fields (`city_visual_flag`, `city_flag`, `unlocks_event_id`, `custom_headline_key`).
4. Ensure `DirectiveManager.apply_modifiers()` continues to wrap the final calculated dictionary.

---

## Detailed Implementation Specification

### 1. Target File: `scripts/desk/DeskView.gd`
In `_execute_stamping(approved: bool)`:
Replace the hardcoded `res_effects` construction with:

```gdscript
# Fetch base authored effects from EventData
var base_effects: Dictionary = (
    event.effects_approve.duplicate(true) if approved
    else event.effects_reject.duplicate(true)
)

var res_effects: Dictionary = base_effects.duplicate(true)

# Apply Deductive Context Overlays:
if approved:
    if has_viol:
        # Corrupt / Negligent approval of a project with known violations:
        # Severe penalty to opinion and spike in suspicion
        var viol_count: int = event.violations.size()
        var opinion_penalty: float = -12.0 * float(viol_count)
        var susp_spike: float = 12.0 * float(viol_count)
        
        res_effects["public_opinion"] = float(res_effects.get("public_opinion", 0.0)) + opinion_penalty
        res_effects["suspicion"] = float(res_effects.get("suspicion", 0.0)) + susp_spike
        if not took_bribe:
            # Negligent approval: citizens are bewildered why you allowed illegal works for free
            res_effects["public_opinion"] = float(res_effects.get("public_opinion", 0.0)) - 5.0
    else:
        # Honest approval of a fully compliant petition:
        # Bonus civic satisfaction and slight suspicion reduction
        res_effects["public_opinion"] = float(res_effects.get("public_opinion", 0.0)) + 6.0
        res_effects["suspicion"] = float(res_effects.get("suspicion", 0.0)) - 3.0
else:
    # Rejection logic:
    if has_viol:
        # Valid rejection with cause: Mayor praised for sharp vigilance!
        var discovered_count: int = active_document.discovered_violations.size() if ("discovered_violations" in active_document) else 1
        var vigilance_bonus: float = 8.0 + (float(discovered_count) * 4.0)
        res_effects["public_opinion"] = float(res_effects.get("public_opinion", 0.0)) + vigilance_bonus
        res_effects["suspicion"] = float(res_effects.get("suspicion", 0.0)) - 8.0
    else:
        # Wrongful rejection of legal application: Bureaucratic red-tape outrage!
        res_effects["public_opinion"] = float(res_effects.get("public_opinion", 0.0)) - 10.0
        res_effects["suspicion"] = float(res_effects.get("suspicion", 0.0)) + 4.0

# Ensure visual flags and unlocked event IDs are preserved
if base_effects.has("city_visual_flag"):
    res_effects["city_visual_flag"] = base_effects["city_visual_flag"]
if base_effects.has("city_flag"):
    res_effects["city_flag"] = base_effects["city_flag"]
if base_effects.has("unlocks_event_id"):
    res_effects["unlocks_event_id"] = base_effects["unlocks_event_id"]

# Apply Daily Executive Directive modifiers
res_effects = DirectiveManager.apply_modifiers(
    res_effects, event, approved, took_bribe
)

GameManager.apply_resolution(res_effects)
```

### 2. Target File: `scripts/autoload/GameManager.gd`
In `apply_resolution(effects: Dictionary)`:
Verify that `unlocks_event_id` triggers `EventManager.unlock_event(unlocked_id)`:
```gdscript
if "unlocks_event_id" in effects and not str(effects["unlocks_event_id"]).is_empty():
    var unlocked_id: String = str(effects["unlocks_event_id"])
    if EventManager != null and EventManager.has_method("unlock_event"):
        EventManager.unlock_event(unlocked_id)
```

---

## Verification & Automated Test Plan
Create test script `tests/test_event_resolution_fix.gd`:
1. **Test 1: Custom Budget Delta**: Load an event with `effects_approve = {"budget": -80000, "public_opinion": 25.0}`. Approve it. Assert `GameManager.city_budget == 100000 - 80000 = 20000`.
2. **Test 2: City Visual Flag Propagation**: Stamping an event with `city_visual_flag = "add_concrete_tower"` must set `GameManager.event_flags["add_concrete_tower"] == true` and trigger `SkylineView.update_skyline()`.
3. **Test 3: Consequence Chaining**: Stamping an event with `unlocks_event_id = "EVT_CONSEQUENCE_001"` must cause `EventManager.draw_pile` to contain `"EVT_CONSEQUENCE_001"`.
