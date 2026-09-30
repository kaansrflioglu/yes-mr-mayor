# Modular Specification 06: HUD Metrics, District Map, and Information Displays

## Executive Technical Summary
This document specifies the visual modernization of the mayoral telemetry systems: the upper status bar (`TopBarHUD.tscn`), the interactive municipal map (`DistrictMapModal.tscn`), the election campaign tracker (`CampaignTrackerHUD.tscn`), and the live audience voting interface (`TwitchVoteOverlay.tscn`). Currently, these interfaces are rendered using plain horizontal progress bars with solid colors (`StyleBoxFlat_bar_fill` in flat green and `StyleBoxFlat_susp_fill` in flat red) and simple grid buttons. This specification redesigns them into bespoke analog gauges, guilloché currency counters, architectural blueprint maps, and broadcast-ready voter analytics.

---

## 1. Technical Context & Affected Scenes
- **HUD Scene**: `res://scenes/hud/TopBarHUD.tscn`
- **HUD Script**: `res://scripts/ui/TopBarHUD.gd`
- **District Map Scene**: `res://scenes/desk/DistrictMapModal.tscn`
- **District Map Script**: `res://scripts/ui/DistrictMapModal.gd`
- **Campaign Tracker Scene**: `res://scenes/hud/CampaignTrackerHUD.tscn`
- **Twitch Overlay Scene**: `res://scenes/hud/TwitchVoteOverlay.tscn`
- **Asset Directories**:
  - `res://assets/sprites/hud/`
  - `res://assets/sprites/map/`

---

## 2. TopBarHUD Analog Instrument Redesign

The upper bar (1920x72) must look like an executive mahogany-and-brass instrument panel mounted above the office window.

```
TopBarHUD (PanelContainer, 1920x72)
├── BrassTrimHeader (NinePatchRect, dark wood veneer with gold bevel border)
└── HBoxContainer (Center-aligned telemetry modules)
    ├── CityEmblemBadge (TextureRect, official mayoral gold crest)
    ├── ShiftClockWidget (VBoxContainer)
    │   ├── DayBanner (Label, Cinzel-Bold: "DAY 4 / 10")
    │   └── AnalogClockDisplay (TextureRect, vintage flip-clock readout: "14:15")
    ├── TreasuryMeter (HBoxContainer)
    │   ├── CoinStackIcon (TextureRect, embossed brass coin pile)
    │   └── OdometerCounter (Label with rolling number ticker animation)
    ├── ApprovalDial (Control, analog semicircular gauge)
    │   ├── DialFace (TextureRect, arc from red through yellow to green)
    │   └── NeedleIndicator (Sprite2D, rotating needle driven by approval percentage)
    ├── SuspicionGauge (Control, wiretap / danger indicator)
    │   ├── DangerMeterBacking (TextureProgressBar, segmented glass tubes)
    │   └── CriticalPulseAura (CanvasItem pulsating red glow when suspicion > 75%)
    └── QuickActionButtons (HBoxContainer)
        ├── BtnDistrictMap (TextureButton, folded blueprint icon)
        ├── BtnRulebook (TextureButton, municipal lawbook icon)
        ├── BtnTwitchStatus (TextureButton, retro broadcast antenna icon)
        └── BtnSettings (TextureButton, brass gear icon)
```

### 2.1. Odometer Currency Animation
In `TopBarHUD.gd`, replace instant numeric text assignment with an interpolated rolling odometer counter:
- When treasury increases or decreases, smoothly tween numeric value over 0.4s using `Tween.interpolate_method()`.
- Display currency formatted with thousands separators (e.g., `$1,250,000`).

### 2.2. Analog Approval Dial & Suspicion Tube
- **Approval Gauge**:
  - Replace flat `ProgressBar` with an analog dial face (`dial_approval_gauge.png`).
  - Needle rotates from -60 deg (0% Approval) to +60 deg (100% Approval).
  - Tween needle movement with spring damping (`TRANS_BACK`, `EASE_OUT`).
- **Suspicion Warning Gauge**:
  - Visualized as a vacuum tube or seismic meter filled with bubbling amber/red filament.
  - When Suspicion > 75%, trigger a heartbeat pulse shader or modulating alpha aura.

---

## 3. District Map Blueprint Modal (`DistrictMapModal.tscn`)

The current district map uses plain button grids with flat background colors. It must be converted into an authentic municipal master plan blueprint.

### 3.1. Visual Layout
1. **Background Canvas**:
   - `res://assets/sprites/map/blueprint_paper_grid.png`: Indigo cyanotype blueprint texture with white architectural gridlines, drafting ruler borders, and folded paper creases.
2. **Interactive District Sectors**:
   - Five distinct municipal sectors represented as clickable polygonal regions with vector-style hatched styling:
     - *District 1: Old Town & Civic Center* (Colonial architecture, cobblestone grid).
     - *District 2: Waterfront & Cargo Docks* (Pier outlines, crane silhouettes, ocean waves).
     - *District 3: Industrial Smelt District* (Rail lines, smokestack icons).
     - *District 4: Financial Core & Skyline* (Modern skyscrapers, banking plazas).
     - *District 5: North Hill Suburbs* (Curving cul-de-sacs, parkland foliage).
3. **Heatmap Filter Buttons**:
   - Brass toggle switches for viewing:
     - **Crime Heatmap**: Crimson tinted overlay across high-crime districts.
     - **Economic Health**: Emerald green hatching over profitable districts.
     - **Faction Control**: Color-coded crests marking Oligarch, Worker, or Police dominance.

---

## 4. Campaign Tracker & Twitch Voting Interfaces

### 4.1. Campaign Tracker HUD (`CampaignTrackerHUD.tscn`)
- Displays real-time voter turnout projections leading up to Day 10 Election Night.
- Replaces plain bar with a tri-color segmented electoral bar:
  - Blue: Incumbent Mayoral Loyalists.
  - Red: Opposition Candidate Coalition.
  - Gray: Undecided / Apathetic Voters.
- Features dynamic polling confidence margin markers (+/- 3%).

### 4.2. Twitch Voting Broadcast Banner (`TwitchVoteOverlay.tscn`)
- Modernized to mimic an authentic election night television news crawl or live town hall graphic.
- Animated voting percentages bar with Twitch chat command indicators (`!approve`, `!reject`, `!bribe`).
- Dynamic voter avatar icons populating the live decision stream.

---

## 5. Verification & Acceptance Criteria
- [ ] Top bar meters render with analog dial and odometer animations instead of plain Godot progress bars.
- [ ] Suspicion gauge pulses with distinct urgency when crossing critical thresholds.
- [ ] District Map opens as an authentic architectural blueprint with clear district outlines and working heatmap filters.
- [ ] Hovering over district sectors highlights the territory with a crisp drafting glow.
- [ ] All icons and text remain legible at 1920x1080 resolution without visual distortion.
