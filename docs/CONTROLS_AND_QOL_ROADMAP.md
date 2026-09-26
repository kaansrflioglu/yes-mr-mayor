# Keyboard Controls, Accessibility & QoL Roadmap
**Project:** *Yes, Mr. Mayor!* (`yes-mr-mayor`)  
**Document Target:** User Experience, Input Mapping & Tactile Workflow Optimization  
**Module:** `project.godot` InputMap & `scripts/desk/DeskView.gd`  
**Status:** Approved Architectural Specification  

---

## 1. Problem Statement: Mouse-Heavy Inefficiency
In the current implementation of [`scripts/desk/DeskView.gd`](file:///c:/Users/User/Documents/yes-mr-mayor/scripts/desk/DeskView.gd#L87-L98):
```gdscript
func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_SPACE:
            _toggle_inspect_mode()
        elif event.keycode == KEY_TAB:
            _toggle_rulebook()
        elif event.keycode == KEY_ESCAPE:
            _handle_escape_key()
```
Only 3 keys exist. To stamp an approval, pocket a bribe, flip to the inspector report, or answer the phone, the player must constantly flick the mouse back and forth across a 1920x1080 canvas.

For a fast-paced, high-volume bureaucratic game (*Papers, Please* was legendary for its rapid keyboard shortcuts), **full keyboard hotkeys and tactile shortcut badges are essential for game feel and accessibility.**

---

## 2. Master Keybinding Layout

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          KEYBOARD CONTROLS SCHEME                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  [CORE MAYORAL ACTIONS]                                                     │
│  • [A] or [ENTER]      ➔ Slam APPROVE Stamp                                 │
│  • [D] or [BACKSPACE]  ➔ Slam REJECT Stamp (with discovered cause)          │
│  • [S] or [B]          ➔ Pocket Bribe into Safe Drawer                      │
│                                                                             │
│  [INVESTIGATION & REFERENCE]                                                │
│  • [SPACE]             ➔ Toggle Inspection Mode                             │
│  • [TAB]               ➔ Toggle Municipal Rulebook                          │
│  • [Q] / [E]           ➔ Flip Dossier Pages (Application ➔ Report ➔ Both)   │
│  • [1] - [4]           ➔ Rulebook Tabs (Zoning, Seals, Blacklist, Orders)   │
│                                                                             │
│  [DESK PERIPHERALS & SYSTEM]                                                │
│  • [T]                 ➔ Answer / Hang Up Red Telephone                     │
│  • [C]                 ➔ Drink Morning Coffee / Refill AP                   │
│  • [ESC]               ➔ Pause Menu / Close Active Modal                    │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. UI Keycap Badges & Visual Discoverability

To avoid forcing players to read a manual, UI buttons will feature small, stylish keycap badges:

```
┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐
│  [A]  ONAYLA     │    │  [D]  REDDET     │    │  [S]  CEBE İNDİR │
│   (APPROVED)     │    │   (REJECTED)     │    │  ($50,000 CASH)  │
└──────────────────┘    └──────────────────┘    └──────────────────┘
```

When a key is pressed:
- The corresponding on-screen button plays a tactile button-down press animation (`scale = Vector2(0.95, 0.95)`).
- Releasing the key triggers the audio punch (`play_stamp_thud()`).

---

## 4. InputMap Configuration (`project.godot`)

Configure native Godot input actions rather than hardcoding raw keycodes:
```ini
[input]
mayor_approve={ "deadzone": 0.5, "events": [Key(Keycode=A), Key(Keycode=Enter)] }
mayor_reject={ "deadzone": 0.5, "events": [Key(Keycode=D), Key(Keycode=Backspace)] }
mayor_bribe={ "deadzone": 0.5, "events": [Key(Keycode=S), Key(Keycode=B)] }
mayor_inspect={ "deadzone": 0.5, "events": [Key(Keycode=Space)] }
mayor_rulebook={ "deadzone": 0.5, "events": [Key(Keycode=Tab)] }
mayor_page_prev={ "deadzone": 0.5, "events": [Key(Keycode=Q)] }
mayor_page_next={ "deadzone": 0.5, "events": [Key(Keycode=E)] }
mayor_telephone={ "deadzone": 0.5, "events": [Key(Keycode=T)] }
```

---

## 5. Phased Implementation Plan

### Phase 1: InputMap Setup & Action Mapping
- Register all `mayor_*` input actions in `project.godot`.
- Update [`DeskView.gd`](file:///c:/Users/User/Documents/yes-mr-mayor/scripts/desk/DeskView.gd)`_unhandled_input()` to consume `Input.is_action_just_pressed()`:
  * Trigger `_on_approve_pressed()` on `mayor_approve`.
  * Trigger `_on_reject_pressed()` on `mayor_reject`.
  * Trigger bribe pocketing on `mayor_bribe`.
  * Trigger page flipping on `mayor_page_prev` / `next`.

### Phase 2: Visual Keycap Badges & Accessibility Settings
- Add small, semi-transparent keycap pill labels to `BtnStampApprove`, `BtnStampReject`, and `BtnPocketBribe`.
- Add a toggle in `SettingsModal`: *"Show Keyboard Hotkey Hints [ON/OFF]"*.

### Phase 3: Gamepad / Steam Deck Controller Support
- Map controller bumpers (`LB` / `RB`) to dossier page flips.
- Map face buttons: `A` (Approve), `B` (Reject), `X` (Pocket Bribe), `Y` (Inspect Mode).
- Add full UI focus navigation for seamless Steam Deck play.
