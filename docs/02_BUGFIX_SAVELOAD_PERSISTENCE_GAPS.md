# Prompt Specification: Complete Save/Load Persistence Gaps & Mid-Shift State Restoration

## Context & Problem Statement
In `c:/Users/User/Documents/yes-mr-mayor/scripts/autoload/SaveLoadManager.gd`, several critical components of the game state are missing from serialization and deserialization routines.

### Symptoms in Current Codebase
1. **Lost Hotline History**: `GameManager.hotline_history` is never serialized in `save_game()` and never restored in `load_game()`. As a result, when a player loads a game, their tabloid newspaper stories referencing emergency calls are empty, and `DayEndSummary.gd` falls back to default filler headlines.
2. **De-synced Daily Directives**: `DirectiveManager.active_directive_id` is omitted from the save file. In `DeskView._start_or_continue_shift()`, `DirectiveManager.activate_directive_for_day()` is only invoked if `EventManager.daily_queue.is_empty()`. When loading a mid-day save with remaining queue cards, the active directive remains `DIR_STANDARD`, breaking EPA Audits and Anti-Corruption Stings.
3. **Mid-Shift State Amnesia**: Saving the game from the pause menu mid-shift does not persist:
   - `current_shift_minutes` (resets from e.g. 16:30 back to 09:00 AM)
   - `is_overtime` (resets to false)
   - `current_inspect_focus` (resets back to max 4 focus)
   - `consecutive_false_inquiries` (resets to 0, wiping penalty risk)
   - `is_uv_active` (resets to false)

---

## Technical Objectives
1. Extend `SaveLoadManager` payload schema to include:
   - `hotline_history`: Array of completed emergency call records.
   - `directive_state`: Current active directive ID and custom flags.
   - `shift_state`: `shift_minutes`, `is_overtime`, `inspect_focus`, `consecutive_false_inquiries`, `is_uv_active`.
2. Update `SaveLoadManager.load_game()` to restore `GameManager.hotline_history` and re-apply `DirectiveManager`.
3. Update `DeskView._on_game_load_completed()` to consume `shift_state` and configure HUD/clock/focus accordingly.
4. Maintain backward compatibility with legacy version 1.0 saves by providing fallback defaults.

---

## Detailed Implementation Specification

### 1. Target File: `scripts/autoload/SaveLoadManager.gd`

#### In `save_game(slot_id: String) -> bool`:
Include `hotline_history`, `directive_state`, and `shift_state` inside the root payload dictionary:

```gdscript
var hotline_records: Array[Dictionary] = []
for h in GameManager.hotline_history:
    if h is Dictionary:
        hotline_records.append(h.duplicate(true))

var shift_data: Dictionary = {}
var tree := Engine.get_main_loop() as SceneTree
if tree != null and tree.current_scene != null:
    var desk = tree.current_scene.get_node_or_null("%DeskView")
    if desk == null and tree.current_scene.name == "DeskView":
        desk = tree.current_scene
    if desk != null:
        shift_data = {
            "shift_minutes": desk.current_shift_minutes,
            "is_overtime": desk.is_overtime,
            "inspect_focus": desk.current_inspect_focus,
            "consecutive_false_inquiries": desk.consecutive_false_inquiries,
            "is_uv_active": desk.is_uv_active
        }

var directive_data: Dictionary = {
    "active_directive_id": DirectiveManager.active_directive_id
}

var payload: Dictionary = {
    "version": "1.1",
    "metadata": metadata,
    "game_state": game_state,
    "deck_state": deck_state,
    "hotline_history": hotline_records,
    "directive_state": directive_data,
    "shift_state": shift_data
}
```

#### In `load_game(slot_id: String) -> bool`:
Restore the new subsections:

```gdscript
# Restore hotline history
GameManager.hotline_history.clear()
var hot_hist: Array = root_dict.get("hotline_history", [])
for item in hot_hist:
    if item is Dictionary:
        GameManager.hotline_history.append(item.duplicate(true))

# Restore DirectiveManager state
var dir_state: Dictionary = root_dict.get("directive_state", {})
var dir_id: String = str(dir_state.get("active_directive_id", ""))
if not dir_id.is_empty():
    DirectiveManager.set_active_directive(dir_id)
else:
    DirectiveManager.activate_directive_for_day(GameManager.current_day)

# Store transient shift_state for DeskView consumption
last_loaded_shift_state = root_dict.get("shift_state", {})
```

### 2. Target File: `scripts/desk/DeskView.gd`

#### In `_on_game_load_completed(_slot_id: String) -> void`:
Consume `SaveLoadManager.last_loaded_shift_state`:

```gdscript
func _on_game_load_completed(_slot_id: String) -> void:
    _was_paused_for_modal = false
    if active_document != null and is_instance_valid(active_document):
        active_document.queue_free()
        active_document = null
    if active_summary != null and is_instance_valid(active_summary):
        active_summary.queue_free()
        active_summary = null
    if active_game_over != null and is_instance_valid(active_game_over):
        active_game_over.queue_free()
        active_game_over = null

    next_day_box.visible = false
    inspect_status_panel.visible = false

    # Restore Shift Clock & Stamina State if saved mid-shift
    var saved_shift: Dictionary = SaveLoadManager.last_loaded_shift_state
    if not saved_shift.is_empty():
        current_shift_minutes = int(saved_shift.get("shift_minutes", SHIFT_START_MINUTES))
        is_overtime = bool(saved_shift.get("is_overtime", false))
        current_inspect_focus = int(saved_shift.get("inspect_focus", MAX_INSPECT_FOCUS))
        consecutive_false_inquiries = int(saved_shift.get("consecutive_false_inquiries", 0))
        is_uv_active = bool(saved_shift.get("is_uv_active", false))
    else:
        current_shift_minutes = SHIFT_START_MINUTES
        is_overtime = false
        current_inspect_focus = MAX_INSPECT_FOCUS
        consecutive_false_inquiries = 0
        is_uv_active = false

    _update_clock_ui()
    _update_focus_ui()
    _update_directive_ui()
    _present_next_document()
```

---

## Verification & Automated Test Plan
Create test script `tests/test_saveload_lifecycle_expansion.gd`:
1. **Hotline Persistence Test**: Add mock call `{ "call_id": "CALL_TEST", "accepted": true, "archetype": "party_boss" }` to `GameManager.hotline_history`. Save to `slot_1`. Clear `GameManager.hotline_history`. Load `slot_1`. Verify `GameManager.hotline_history.size() == 1` and matches.
2. **Directive Persistence Test**: Set `DirectiveManager.set_active_directive("DIR_ANTI_CORRUPTION")`. Save to `slot_1`. Reset directive state. Load `slot_1`. Assert `DirectiveManager.active_directive_id == "DIR_ANTI_CORRUPTION"`.
3. **Shift State Test**: Modify `current_shift_minutes = 960` (4:00 PM), `current_inspect_focus = 1`. Save and reload. Verify clock reads `"04:00 PM"` and focus is 1.
