# "Yes, Mr. Mayor!" - Main Menu & Save/Load System Architecture Plan

This document outlines the architectural plan and modular phase prompts for adding a **Main Menu**, an **In-Game Save/Load System**, an **In-Game Pause Menu**, and **Autosave** to *"Yes, Mr. Mayor!"*.

---

## 🏛️ Executive Summary & Core Objectives

### The Problem
Currently, the game launches directly into the daily municipal shift (`DeskView.tscn`). Players have no title screen, cannot save their progress across play sessions, cannot load previous saves, and have no pause menu to take a break or return to the main menu.

### Target State
1. **Title / Main Menu (`MainMenu.tscn`):**
   - High-impact aesthetic: Panoramic city skyline background with dynamic lighting, subtle ambient audio, and official mayoral desk aesthetic.
   - Actions: **Continue** (smart latest save loader), **New Game** (with overwrite warning), **Load Game** (slot picker), **Settings** (unified modal), **How to Play / Field Manual**, and **Quit**.
2. **Robust Save/Load System (`SaveLoadManager.gd` Autoload):**
   - Multi-slot architecture: `autosave.json`, `slot_1.json`, `slot_2.json`, `slot_3.json` under `user://saves/`.
   - Comprehensive state serialization: Municipal treasury, public opinion, offshore funds, suspicion, current day, deck state (draw pile, discard pile, daily queue), event flags (visual skyline modifications), and shift decisions history.
   - Metadata previews: Each slot displays save timestamp, Day number, Treasury amount, Approval %, and Corrupt/Lawful badge.
3. **In-Game Pause Menu & Save Dialog (`PauseMenu.tscn` & `SaveLoadModal.tscn`):**
   - ESC key hierarchy: Closes topmost modal (Settings, Rulebook, Hotline) -> if none open, opens Pause Menu.
   - Pause menu options: **Resume**, **Save Game**, **Load Game**, **Settings**, **Main Menu**, **Quit to Desktop**.
4. **Autosave on Shift End:**
   - Automatically saves to `autosave.json` whenever the daily quota is reached before the newspaper summary.
   - Displays a discreet toast indicator: *"💾 Shift Saved / Gün Kaydedildi"*.

---

## 🗺️ Implementation Phases Overview

| Phase | Milestone | Primary Deliverables |
|---|---|---|
| **Phase 1** | **Save/Load Core Engine** | `SaveLoadManager.gd` autoload, serialization schemas, slot reader/writer, `user://saves/` filesystem management |
| **Phase 2** | **Save & Load Modal UI** | `SaveLoadModal.tscn` & `SaveLoadModal.gd`, slot cards with metadata, overwrite & delete confirmation dialogs |
| **Phase 3** | **In-Game Pause Menu** | `PauseMenu.tscn` & `PauseMenu.gd`, ESC key integration in `DeskView.gd`, HUD pause button, return-to-menu routing |
| **Phase 4** | **Main Menu Title Screen** | `MainMenu.tscn` & `MainMenu.gd`, atmospheric skyline backdrop, navigation flow, project main scene update |
| **Phase 5** | **Autosave & Seamless Lifecycle** | End-of-shift autosave trigger, save toast notification, game state reset on new game, election victory/defeat save cleanup |
| **Phase 6** | **Automated Test Suite & QA** | `TestRunnerSaveLoad.tscn`, slot round-trip tests, pause lifecycle tests, regression check on all existing test runners |

---

## 📋 Modular Execution Prompts (English)

---

### 🔹 PHASE 1: Save/Load Core Engine Architecture
```markdown
### Prompt for Phase 1: Implement SaveLoadManager Autoload & State Serialization

**Goal:** Create a robust, modular Save/Load manager (`SaveLoadManager.gd`) registered as a Godot autoload in `project.godot`.

**Requirements:**
1. **Directory & File Structure:**
   - Manage save files inside `user://saves/`. Ensure the directory is created if missing.
   - Support fixed slots: `slot_1`, `slot_2`, `slot_3`, and `autosave`.
   - Save format: Formatted JSON with `.json` extension.
2. **State Serialization:**
   - `GameManager` state: `current_day`, `city_budget`, `public_opinion`, `personal_wealth`, `suspicion_level`, `event_flags`, `daily_history`, `is_game_over`.
   - `EventManager` state: `draw_pile` (event IDs), `discard_pile` (event IDs), `daily_queue` (event IDs).
   - Metadata payload: `save_name`, `timestamp` (Unix & ISO-8601 string), `day`, `budget`, `approval`, `suspicion`, `offshore`, `version`.
3. **Core Methods to Implement:**
   - `save_game(slot_id: String) -> bool`
   - `load_game(slot_id: String) -> bool`
   - `has_save(slot_id: String) -> bool`
   - `get_slot_metadata(slot_id: String) -> Dictionary`
   - `get_all_slots_metadata() -> Array[Dictionary]`
   - `delete_save(slot_id: String) -> bool`
   - `get_latest_save_slot() -> String`
   - `has_any_save() -> bool`
4. **Signals:**
   - `game_saved(slot_id: String)`
   - `game_loaded(slot_id: String)`
   - `save_deleted(slot_id: String)`
5. **Autoload Registration:**
   - Add `SaveLoadManager="*res://scripts/autoload/SaveLoadManager.gd"` to `project.godot`.
6. **Code Standards:**
   - GDScript strict typing, max line length <= 100 characters, no `class_name` conflict with autoload.
```

---

### 🔹 PHASE 2: Save/Load Modal UI (`SaveLoadModal.tscn`)
```markdown
### Prompt for Phase 2: Build the Save & Load Slot Selector Modal

**Goal:** Build a visual slot selection modal (`SaveLoadModal.tscn` and `SaveLoadModal.gd`) matching the game's dark glassmorphism and gold municipal styling.

**Requirements:**
1. **Visual Styling:**
   - Backdrop dimmer (`ColorRect` with `Color(0, 0, 0, 0.7)`).
   - Centered panel with gold/bronze border, corner radius, drop shadow.
   - Header with dynamic title: "💾 SAVE GAME / KAYDET" or "📂 LOAD GAME / YÜKLE".
   - Close button (`✕`) at the top right.
2. **Slot Cards (Autosave + Slot 1, 2, 3):**
   - For populated slots: Display Slot Name, Day number, Date & Time, Treasury amount ($), Public Approval %, Federal Suspicion %.
   - For empty slots: Display "[EMPTY SLOT / BOŞ KAYIT]" with disabled load button or save prompt.
   - Action buttons per card:
     - In Save Mode: "Save Here" (prompts overwrite confirmation if occupied).
     - In Load Mode: "Load Game" (loads and switches scene to DeskView).
     - "Delete" button (trash icon or red button) with confirmation popup.
3. **Confirmation Dialogs:**
   - Overwrite confirmation: "Are you sure you want to overwrite this save?"
   - Delete confirmation: "Permanently delete this saved term?"
4. **Localization:**
   - Add all necessary localization keys to `data/localization.csv` (EN, TR, ES).
5. **Integration Hooks:**
   - Public methods: `open_in_save_mode()`, `open_in_load_mode()`, `close()`.
   - Signals: `save_completed(slot_id)`, `load_completed(slot_id)`, `modal_closed`.
```

---

### 🔹 PHASE 3: In-Game Pause Menu (`PauseMenu.tscn`)
```markdown
### Prompt for Phase 3: Create In-Game Pause Menu & ESC Hierarchy

**Goal:** Implement an in-game pause menu accessible via the ESC key and a TopBar pause button, allowing players to pause, save, load, adjust settings, or return to the main menu.

**Requirements:**
1. **Scene Design (`PauseMenu.tscn` & `PauseMenu.gd`):**
   - Fullscreen modal overlay (`z_index = 70`).
   - Title: "⏸️ PAUSED / OYUN DURDURULDU".
   - Vertical button rack:
     - **Resume Game (Devam Et)**: Closes pause menu.
     - **Save Game (Oyunu Kaydet)**: Opens `SaveLoadModal` in Save mode.
     - **Load Game (Kayıtlı Oyunu Yükle)**: Opens `SaveLoadModal` in Load mode.
     - **Settings (Ayarlar)**: Opens `SettingsModal`.
     - **Main Menu (Ana Menüye Dön)**: Prompts unsaved progress warning, then transitions to `MainMenu.tscn`.
     - **Quit to Desktop (Masaüstüne Çık)**: Prompts confirmation, then quits application.
2. **ESC Key Navigation Hierarchy in `DeskView.gd`:**
   - Order of priority when ESC is pressed:
     1. If `SettingsModal` is open -> Close Settings.
     2. If `SaveLoadModal` is open -> Close Save/Load.
     3. If `RedTelephone` dialog is open -> Disregard or close hotline.
     4. If `Rulebook` is open -> Close Rulebook.
     5. If `PauseMenu` is open -> Resume game (close Pause Menu).
     6. If none are open -> Open `PauseMenu`.
3. **HUD Pause Button:**
   - Add a subtle pause button (`⏸️`) to `TopBarHUD` next to `BtnSettings`.
4. **State Integrity:**
   - Ensure timers and document dragging are properly paused or locked while the pause menu is open.
```

---

### 🔹 PHASE 4: Main Menu Title Screen (`MainMenu.tscn`)
```markdown
### Prompt for Phase 4: Build Main Menu Scene & Set as Project Main Scene

**Goal:** Create a polished, immersive Main Menu scene (`MainMenu.tscn` and `MainMenu.gd`) and set it as the primary entry scene in `project.godot`.

**Requirements:**
1. **Visual & Aesthetic Design:**
   - Panoramic Skyline background (day/sunset/night cityscape with animated glowing windows).
   - Leather blotter silhouette foreground with civic seal and gold typography:
     - Game Title: **"YES, MR. MAYOR"** / Subtitle: *"A Municipal Deduction & Morality Simulator"*.
   - Ambient office audio: Soft rain or gentle municipal brass theme via `AudioManager`.
2. **Menu Action Rack:**
   - **Continue (Devam Et)**:
     - Dynamically enabled only if `SaveLoadManager.has_any_save()` is true.
     - Automatically loads `SaveLoadManager.get_latest_save_slot()` and transitions to `DeskView.tscn`.
     - Subtitle under button showing quick preview: *"Day X • $Treasury • %Approval"*.
   - **New Game (Yeni Oyun)**:
     - If existing saves exist: Prompts confirmation *"Starting a new game will begin from Day 1. Proceed?"*.
     - Calls `GameManager.start_new_game()`, `EventManager.reset_deck()`, transitions to `DeskView.tscn`.
   - **Load Game (Kayıt Yükle)**:
     - Opens `SaveLoadModal` in Load mode.
   - **Settings (Ayarlar)**:
     - Instances/opens `SettingsModal` (Audio, Video, Language, Twitch).
   - **How to Play / Municipal Manual (Nasıl Oynanır)**:
     - Modal explaining Dossier inspection, Rulebook cross-referencing, Stamping consequences, and Offshore Safe.
   - **Quit to Desktop (Çıkış)**:
     - Confirmation prompt, calls `get_tree().quit()`.
3. **Project Settings Update:**
   - Update `project.godot`: `run/main_scene="res://scenes/menu/MainMenu.tscn"`.
4. **Transitions:**
   - Smooth scene transitions (fade to black / slide) when switching between MainMenu and DeskView.
```

---

### 🔹 PHASE 5: Autosave on Shift End & Lifecycle Hooks
```markdown
### Prompt for Phase 5: Integrate End-of-Day Autosave & Notification Toast

**Goal:** Wire automatic saving into the gameplay loop so players never lose progress, and add in-game feedback toasts.

**Requirements:**
1. **Autosave Trigger:**
   - In `DeskView.gd`, when the daily quota of documents is completed (`_on_daily_quota_completed()` or advancing via `btn_next_day`), call `SaveLoadManager.save_game("autosave")`.
2. **Save Toast Notification:**
   - Create a subtle toast widget (`SaveToast.tscn` or panel) in `DeskView`.
   - Displays icon and text: *"💾 Progress Saved (Day X) / İlerleme Kaydedildi"*.
   - Slides down from top HUD or floats in bottom corner, stays for 2.0s, and fades out.
3. **Post-Game Over Lifecycle:**
   - When game over occurs (Arrest, Riot, Bankruptcy, Term Completion), clean up or archive the current active save so players cannot reload into a dead end, while offering a "Restart Term" or "Return to Main Menu" button.
4. **Localization:**
   - Localize all toast strings in `localization.csv`.
```

---

### 🔹 PHASE 6: Automated Test Suite & QA Verification
```markdown
### Prompt for Phase 6: Build Automated Test Suite for Save/Load & Menu Flow

**Goal:** Create a comprehensive, headless-friendly test suite (`TestRunnerSaveLoad.tscn` & `test_save_load_node.gd`) verifying all new features and ensuring zero regressions.

**Requirements:**
1. **Test Coverage:**
   - `test_save_serialization`: Verifies saving creates valid JSON with all required keys.
   - `test_state_restoration`: Mutates GameManager stats (Day 14, $42,000, 31% opinion), saves to test slot, resets GameManager, loads slot, and asserts all values match.
   - `test_deck_restoration`: Ensures drawn and discarded cards maintain exact deck order upon reload.
   - `test_slot_metadata`: Verifies timestamp, preview text, and slot listing.
   - `test_main_menu_buttons`: Tests `has_any_save()` state reflecting in `btn_continue.disabled`.
   - `test_pause_menu_esc_hierarchy`: Simulates ESC input and validates menu open/close transitions.
2. **Regression Testing:**
   - Execute and confirm 100% pass on:
     - `res://tests/TestRunnerSaveLoad.tscn`
     - `res://tests/TestRunnerSettings.tscn`
     - `res://tests/TestRunnerDeduction.tscn`
     - `res://tests/TestRunnerPhase4.tscn`
     - `res://tests/TestRunnerPhase5.tscn`
3. **Constraint Adherence:**
   - Max line length <= 100 characters.
   - No leaks or dangling nodes.
```

---

## 🛠️ File Structure Plan

```
yes-mr-mayor/
├── docs/
│   └── MAIN_MENU_AND_SAVE_SYSTEM_PLAN.md      <-- This specification document
├── scenes/
│   ├── menu/
│   │   ├── MainMenu.tscn                     <-- Title screen scene
│   │   └── HowToPlayModal.tscn               <-- Manual / instructions modal
│   └── ui/
│       ├── SettingsModal.tscn                <-- Existing unified settings
│       ├── SaveLoadModal.tscn                <-- Slot selector modal
│       ├── PauseMenu.tscn                    <-- In-game pause menu
│       └── SaveToast.tscn                    <-- Autosave pop-up toast
├── scripts/
│   ├── autoload/
│   │   └── SaveLoadManager.gd                <-- Save/Load singleton & serializer
│   ├── menu/
│   │   ├── MainMenu.gd                       <-- Title screen controller
│   │   └── HowToPlayModal.gd                 <-- Instructions controller
│   └── ui/
│       ├── SaveLoadModal.gd                  <-- Slot selector logic
│       ├── PauseMenu.gd                      <-- Pause menu controller
│       └── SaveToast.gd                      <-- Toast animation controller
└── tests/
    ├── TestRunnerSaveLoad.tscn               <-- Automated test runner
    └── test_save_load_node.gd                <-- Test assertion suite
```

---

## 🔒 Save Data JSON Schema Specification

```json
{
  "version": "1.0",
  "metadata": {
    "slot_id": "slot_1",
    "timestamp_unix": 1727258400,
    "timestamp_str": "2026-09-25 10:15:00",
    "day": 8,
    "city_budget": 145000,
    "public_opinion": 68.5,
    "offshore_account": 25000,
    "suspicion_level": 15.0,
    "alignment": "Moderate"
  },
  "game_state": {
    "current_day": 8,
    "is_game_over": false,
    "city_budget": 145000,
    "public_opinion": 68.5,
    "personal_wealth": 25000,
    "suspicion_level": 15.0,
    "event_flags": {
      "tower_constructed": true,
      "park_funded": true
    },
    "daily_history": [
      {
        "day": 1,
        "event_id": "EVT_001",
        "approved": true,
        "took_bribe": false,
        "headline_key": "EVT_001_NEWS_APP"
      }
    ]
  },
  "deck_state": {
    "draw_pile_ids": ["EVT_004", "EVT_007", "EVT_009"],
    "discard_pile_ids": ["EVT_001", "EVT_002", "EVT_003"],
    "daily_queue_ids": ["EVT_005", "EVT_006"]
  }
}
```
