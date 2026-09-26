# Panoramic City Skyline Evolution & Environmental Reactions
**Project:** *Yes, Mr. Mayor!* (`yes-mr-mayor`)  
**Document Target:** Visual Polish, Skyline Rendering & World-State Reactivity  
**Module:** `scripts/desk/SkylineView.gd` & `scenes/desk/SkylineView.tscn`  
**Status:** Approved Architectural Specification  

---

## 1. Problem Statement: An Underutilized Narrative Canvas
The panoramic window behind the Mayor's desk is one of the most prominent visual assets in the game. In [`scripts/desk/SkylineView.gd`](file:///c:/Users/User/Documents/yes-mr-mayor/scripts/desk/SkylineView.gd), it currently only checks 7 basic flags:
```gdscript
_set_prop_state(prop_concrete_towers, flags.get("add_concrete_tower", false))
_set_prop_state(prop_green_park, flags.get("preserve_greenery", false))
_set_prop_state(prop_golden_dinosaur, flags.get("add_golden_dinosaur", false))
_set_prop_state(prop_metro_pit, flags.get("abandoned_metro_pit", false))
_set_prop_state(prop_clean_metro, flags.get("clean_metro_station", false))
_set_prop_state(prop_garbage_piles, flags.get("garbage_piles", false))
_set_prop_state(prop_toxic_chimneys, flags.get("toxic_smog", false))
```
In an expanded 180-event campaign, dozens of player decisions should visibly reshape the metropolis. If the Mayor approves a corrupt high-roller casino, neon signs should flicker outside; if citizens are on the brink of revolt, protest mobs with torches should gather outside city hall.

---

## 2. Expanded Visual Prop & Environmental Matrix

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           SKYLINE WINDOW COMPOSITE                          │
├─────────────────────────────────────────────────────────────────────────────┤
│  [LAYER 1: SKY DOME & WEATHER]                                              │
│  • Dynamic gradient: Azure Noon ➔ Sunset Amber ➔ Night Noir ➔ Smog Ochre   │
│  • Rain particle emitter against glass panes during storms                  │
│                                                                             │
│  [LAYER 2: DISTANT METROPOLIS & MOUNTAINS]                                  │
│  • Historical Old Town clock tower (or demolished rubble)                   │
│  • Megacorp glass monoliths & active construction cranes                   │
│  • Heavy industrial refinery plumes / glowing toxic smoke stacks            │
│                                                                             │
│  [LAYER 3: MIDGROUND INFRASTRUCTURE]                                        │
│  • Monorail / Elevated train line (moving train sprite on approval)         │
│  • Golden Dinosaur theme park roller-coaster silhouettes                    │
│  • Riverbed floodwaters or pristine community botanical reserve             │
│                                                                             │
│  [LAYER 4: FOREGROUND STREET LEVEL (CIVIL UNREST)]                          │
│  • Protest mob with placards & burning torches when Public Opinion < 25%   │
│  • Police barricades & squad cars with alternating red/blue flashing lights│
│  • Uncollected garbage piles spilling onto streets after strikes            │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Decision Flag Mapping for 8 Event Phases

| Flag Key | Source Event Category | Visual Reflection on Window |
| :--- | :--- | :--- |
| `riot_crowds` | `public_opinion < 25.0` | Animated silhouette crowd with waving pitchforks, signs, and flickering flame particles. |
| `police_siege` | `suspicion > 80.0` | Police tape across gates; 3 squad cars parked with rhythmic red/blue light flashes. |
| `add_luxury_towers` | Phase 1 (Zoning) | 3 gleaming glass towers with illuminated penthouse suites and rooftop helipads. |
| `historic_rubble` | Phase 1 (Demolitions) | Ruined stone masonry with a yellow construction crane over the old clock tower. |
| `moving_monorail` | Phase 2 (Transit) | Sleek modern train periodically gliding horizontally across the elevated rail bridge. |
| `neon_casino_strip` | Phase 4 (Underground) | Vivid pulsing magenta/cyan neon signs ("VIP LOUNGE", "GOLDEN SLOTS") over warehouses. |
| `titanium_mayor_statue`| Phase 5 (Satire) | Massive 80-meter golden/titanium statue of the Mayor with glowing eyes overlooking downtown. |
| `flood_catastrophe` | Phase 6 (Disaster) | Muddy floodwaters submerging lower-story brownstones and floating cars. |

---

## 4. Phased Implementation Plan

### Phase 1: Visual Layering & Particle Systems
- Restructure `scenes/desk/SkylineView.tscn` into 4 CanvasGroup layers (Sky, Distant, Midground, Foreground).
- Add a 2D CPU/GPU particle emitter for:
  * Gentle vertical rain drops.
  * Flickering torch fire for protest crowds.
  * Industrial smoke puffs from factory chimneys.

### Phase 2: Dynamic Lighting & Tweened State Changes
- In `SkylineView.gd`, expand `update_skyline()` to check opinion and suspicion thresholds dynamically.
- Implement an alternating timer/tween for police squad car emergency flashers:
  ```gdscript
  func _animate_police_lights() -> void:
      var tween := create_tween().set_loops()
      tween.tween_property(red_light, "energy", 1.8, 0.2)
      tween.tween_property(red_light, "energy", 0.0, 0.2)
      tween.tween_property(blue_light, "energy", 1.8, 0.2)
      tween.tween_property(blue_light, "energy", 0.0, 0.2)
  ```

### Phase 3: Moving Props & Replay Variety
- Add a looping tween for the elevated monorail train crossing the bridge every 25 seconds.
- Connect Day/Night transitions so later events in the daily queue feel like the evening rush hour.
