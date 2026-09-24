# Development Roadmap & Phase Guide: "Yes, Mr. Mayor!"

Target Engine: **Godot 4.3+ (Compatibility Renderer)**  
Project Style: **Data-Driven 2D Bureaucracy Simulation**  
Language: **GDScript (Typed)**  
Localization Standard: **English Base Keys + `tr()` + CSV**

---

## Phase Overview

| Phase | Title | Focus Area | Deliverable |
|---|---|---|---|
| **Phase 1** | Foundation & Data Architecture | Autoloads, Event Models, Math Core | Headless playable loop without visual assets |
| **Phase 2** | Desk Interaction & Tactile UI | Control nodes, Stamps, Tweens, Bribe drawer | Interactive document approval/rejection loop |
| **Phase 3** | Day Loop, Headlines & Endings | Daily quota, Tabloid recap, Win/Fail checks | 30-day run with working game-over screens |
| **Phase 4** | Juice, Dynamic Backdrop & Audio | Skyline TileMap, SFX, Ringing Telephone | Atmospheric satirical experience |
| **Phase 5** | Twitch Integration, i18n QA & Polish | Twitch IRC WebSocket, Multi-language test, Build | Steam & itch.io ready release candidate |

---

## Phase 1: Foundation & Data Architecture

### Objective
Build the mathematical backbone, event definitions, and localization foundation so the game logic runs deterministically before UI layout work begins.

### Directory Structure to Create
```text
res://
├── assets/
│   ├── audio/
│   ├── sprites/
│   └── fonts/
├── data/
│   ├── localization.csv
│   └── events.json
├── scenes/
│   ├── autoload/
│   ├── desk/
│   ├── hud/
│   └── summary/
└── scripts/
    ├── autoload/
    ├── models/
    └── desk/
```

### Tasks
1. **Custom Resource / Event Model (`res://scripts/models/EventData.gd`):**
   - Define fields: `id: String`, `title_key: String`, `desc_key: String`, `applicant_key: String`.
   - Define numeric impact dictionaries: `effects_approve: Dictionary`, `effects_reject: Dictionary`.
   - Support keys: `budget`, `public_opinion`, `offshore_account`, `suspicion`, `city_flag`.
2. **Autoload: `GameManager.gd` (`res://scripts/autoload/GameManager.gd`):**
   - Manage core variables:
     - `public_opinion: float` ($0.0 - 100.0$)
     - `city_budget: int` ($-\infty \dots +\infty$)
     - `offshore_account: int` ($0 \dots +\infty$)
     - `suspicion_meter: float` ($0.0 - 100.0$)
     - `current_day: int` ($1 \dots 30$)
   - Declare signals:
     - `stats_changed`
     - `event_resolved(event_id: String, approved: bool)`
     - `day_ended(day_number: int)`
     - `game_over(reason_key: String)`
3. **Autoload: `EventManager.gd` (`res://scripts/autoload/EventManager.gd`):**
   - Load `res://data/events.json` at startup.
   - Maintain active deck, discard pile, and queue of daily events.
4. **Localization Setup:**
   - Create initial `res://data/localization.csv` containing UI labels and first 5 test events.
   - Configure Godot Project Settings -> Localization -> Translations to track the CSV.

### Acceptance Criteria
- [ ] Running a test harness triggers `EventManager.draw_next_event()`.
- [ ] Applying an approval updates all 4 variables and emits `stats_changed`.
- [ ] Clamping works: `public_opinion` and `suspicion_meter` never exceed $0.0 - 100.0$.
- [ ] `tr("UI_TITLE")` outputs valid text in both English and Turkish.

---

## Phase 2: Desk Interaction & Tactile UI

### Objective
Create the primary game scene (`DeskView.tscn`) and tactile document handling inspired by *Papers, Please*.

### Key Scenes to Build
1. **`res://scenes/desk/DeskView.tscn`:**
   - Root `Control` node set to Full Rect (1920x1080).
   - Layout slots:
     - `TopBarHUD` (Approval bar, Budget display, Offshore safe indicator, Suspicion gauge).
     - `DocumentDropZone` (Center desk space).
     - `StampRack` (Green Stamp: Approve, Red Stamp: Reject).
     - `SafeDrawer` (Clickable drawer on desk corner to stash bribes).
2. **`res://scenes/desk/DocumentItem.tscn`:**
   - PanelContainer with dynamic labels (`TitleLabel`, `ApplicantLabel`, `BodyTextLabel`).
   - Stamp overlay targets (`Sprite2D` / `TextureRect` with modulate for stamped ink effect).
   - Tween animations: slide-in from bottom-left, rotate slightly on rest, slide-out to right on resolution.

### Tasks
- Implement drag-and-drop or click-to-stamp mechanic.
- Stamping triggers a micro-camera shake and an ink slam scale-tween.
- Stashing the optional bribe envelope into the drawer before stamping adds illicit funds to `offshore_account` while slightly raising `suspicion_meter`.

### Acceptance Criteria
- [ ] Document slides smoothly onto desk with dynamic text localized via `tr()`.
- [ ] Stamping green or red emits choice to `GameManager` and moves document offscreen.
- [ ] Top bar counters animate dynamically using `create_tween()` on value changes.

---

## Phase 3: Day Loop, Tabloids & Endings

### Objective
Structure daily quotas (3–5 documents per shift), morning briefings, tabloid front pages, and win/fail state evaluations.

### Key Scenes to Build
1. **`res://scenes/summary/DayEndSummary.tscn`:**
   - Fullscreen modal showing daily financial report (official balance sheet vs. illegal kickbacks).
   - Newspaper front page rendering dynamic headline (`news_headline_approve_key` / `news_headline_reject_key`).
2. **`res://scenes/summary/GameOverModal.tscn`:**
   - Cutscene card explaining final outcome based on `game_over` reason key.

### Game Over Logic Table
| Code Key | Trigger Condition | Consequence Narrative |
|---|---|---|
| `END_ARRESTED` | `suspicion_meter >= 100.0` | Federal auditor raid; handcuffed in city hall. |
| `END_RIOT` | `public_opinion <= 15.0` | Angry mob storms municipal building. |
| `END_BANKRUPT` | `city_budget < -50000` consecutive | City enters receivership / state takeover. |
| `END_LOST_ELECTION` | Reached Day 30 and `public_opinion < 50.0` | Crushing election defeat; exiled to opposition. |
| `END_REELECTED` | Reached Day 30 and `public_opinion >= 50.0` | Landslide victory; four more years of corruption. |

### Tasks
- Implement shift quota: 4 documents per calendar day.
- Display `DayEndSummary` after the 4th document.
- Advance `current_day` and clear transient flags on "Start Next Day" click.

### Acceptance Criteria
- [ ] Reaching Day 31 triggers election victory/loss assessment.
- [ ] Reaching 100% suspicion instantly interrupts the shift with an arrest screen.
- [ ] End-of-day newspaper reflects choices made during that exact shift.

---

## Phase 4: Satirical Juice, Dynamic Skyline & Audio

### Objective
Turn functional UI into an engaging audiovisual comedy playground built for streaming clips.

### Tasks
1. **Dynamic Backdrop Skyline (`res://scenes/desk/SkylineView.tscn`):**
   - Visible through office window behind the desk.
   - Renders modular layers:
     - `SkyTile`: Switches from clear sun to industrial smog if heavy zoning approved.
     - `CityProps`: Spawns absurd monuments (e.g., giant golden dinosaur, concrete high-rises) based on `event_flags`.
2. **Red Emergency Telephone:**
   - Rings randomly (audio cue + visual wobble animation).
   - Clicking opens urgent split-second bribery deals from political bosses or party heads.
3. **Sound FX Implementation (`AudioManager.gd`):**
   - Heavy physical stamp thud.
   - Paper slide / shuffle rustle.
   - Cash register / counting machine rattle for bribe drawer.
   - Distant street sirens and car horns scaling with low approval.

### Acceptance Criteria
- [ ] Office window visually changes reflecting at least 4 major municipal decisions.
- [ ] Every mechanical action (stamp, drawer pull, phone pickup) has satisfying audio feedback.

---

## Phase 5: Twitch Integration, Polish & Release

### Objective
Integrate audience-driven decision mechanics, multi-language validation, and export release binaries.

### Tasks
1. **Twitch Chat Polling (Optional / Toggleable):**
   - Simple WebSocket client listening to Twitch IRC channel.
   - Chat voting commands: `!approve`, `!reject`, `!bribe`.
   - On-screen percentage bar showing chat vote consensus for streamer reference.
2. **Localization QA:**
   - Verify English (`en`), Turkish (`tr`), and Spanish (`es`) character sets (UTF-8 without BOM).
   - Ensure dynamic container sizes prevent text clipping regardless of word length.
3. **Build & Export Presets:**
   - Windows Desktop (.exe).
   - Web / HTML5 export tested on Chromium and Firefox.

### Acceptance Criteria
- [ ] Zero unlocalized raw strings in game logs during full 30-day playthrough.
- [ ] Web build runs at stable 60 FPS in browser with Compatibility Renderer.
- [ ] Export templates build cleanly without missing resource warnings.