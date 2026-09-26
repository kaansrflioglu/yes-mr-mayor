# Audio Ambience, Office Ambience & Procedural BGM Specification
**Project:** *Yes, Mr. Mayor!* (`yes-mr-mayor`)  
**Document Target:** Sound Design, Audio Architecture & Procedural Ambience  
**Module:** `scripts/autoload/AudioManager.gd` & Audio Bus Routing  
**Status:** Approved Architectural Specification  

---

## 1. Problem Statement: The Dead Silence Pathology
In the current build:
- [`scripts/autoload/AudioManager.gd`](file:///c:/Users/User/Documents/yes-mr-mayor/scripts/autoload/AudioManager.gd) synthesizes crisp procedural sound effects for stamps, paper slides, telephone bells, and discrepancy chimes.
- **However, between player mouse clicks, the game is 100% dead silent.**
- There is no background music (BGM), no ambient room tone, no ticking clock, and no city street noise.
- This creates an eerie, sterile feeling that strips away the gritty, smoky, tension-filled atmosphere of a 1980s municipal government office.

---

## 2. Multi-Layered Soundscape Architecture

To create an immersive, living office, the audio system should run **4 continuous, dynamically mixed audio layers**:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           AUDIO MANAGER SOUNDSCAPE                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  [LAYER 1: BGM (Low-Fi Bureaucratic Noir)]                                  │
│  • Gentle electric piano chords (Rhodes/Wurlitzer style) at 65-75 BPM       │
│  • Muffled bassline, subtle vinyl record crackle                            │
│  • Volume: -14 dB (unobtrusive, atmospheric backdrop)                       │
│                                                                             │
│  [LAYER 2: DESK INTERIOR AMBIENCE]                                          │
│  • Steady mechanical wall clock ticking (1 tick per second)                 │
│  • Low 50Hz hum of vintage fluorescent ceiling lights                       │
│  • Occasional subtle wooden desk creak                                      │
│                                                                             │
│  [LAYER 3: DYNAMIC WINDOW / EXTERIOR AMBIENCE] (Tied to City State)         │
│  • Default: Low muffled city traffic rumble & distant car horns             │
│  • Low Approval (<25%): Chanting crowds, police sirens, megaphone bursts    │
│  • Rain / Weather Flag: Gentle rain patter tapping against the window pane  │
│                                                                             │
│  [LAYER 4: PROCEDURAL TACTILE SFX]                                          │
│  • Existing stamp thud, paper rustle, coin drawer, telephone bell           │
│  • Added: Coffee mug clink, lighter flick, pen scribble, drawer slide       │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Dynamic Audio Reactivity (Game State Linking)

The soundscape should not be static; it must dynamically respond to `GameManager` metrics:

| Game Metric / State | Audio Reaction & DSP Modulation |
| :--- | :--- |
| **Federal Suspicion > 75%** | • BGM low-pass filter drops from 20 kHz to 2.5 kHz (claustrophobic, muffled tension). <br>• Subtle rapid heartbeat thud added to background. |
| **Public Opinion < 25%** | • Exterior riot crowd chanting and police sirens fade in on window bus. <br>• Distant glass shatter sound triggers every 45–60 seconds. |
| **Inspection Mode Active** | • Exterior sounds duck by -6 dB. <br>• High-pass focus hum activates to emphasize analytical thinking. |
| **Shift Over / Tabloid Time** | • BGM transitions to a triumphant or somber acoustic brass recap stinger. |

---

## 4. Technical Audio Bus Layout (`default_bus_layout.tres`)

```
[Master] (0 dB)
  ├── [BGM] (-12 dB) ➔ LowPassFilter (dynamic cutoff on high suspicion)
  ├── [Ambience] (-16 dB)
  │     ├── [DeskAmbience] (-18 dB, Clock Tick, Lamp Hum)
  │     └── [CityExterior] (-20 dB, Traffic, Sirens, Rain)
  └── [SFX] (0 dB) ➔ Limiter (prevents clipping on heavy stamps)
```

---

## 5. Phased Implementation Plan

### Phase 1: Audio Bus Configuration & Continuous Ambience Loop
- Configure `BGM` and `Ambience` audio buses in `AudioManager.gd`.
- Generate procedural rhythmic clock tick audio stream (soft woodblock/snare click at 60 BPM).
- Implement `_init_ambience_loops()` with auto-looping `AudioStreamPlayer` nodes that persist seamlessly across days.

### Phase 2: Noir Office BGM System
- Integrate a royalty-free / custom lo-fi noir jazz track or procedural multi-oscillator chord generator (ambient Rhodes chords in D minor / A minor).
- Add smooth volume fading when switching between Main Menu, Desk View, and Day End Summary.

### Phase 3: Dynamic City Reactivity & Micro-SFX
- Connect `GameManager.stats_changed` to an audio tween:
  * Blend in riot siren streams when `public_opinion < 25.0`.
  * Adjust BGM low-pass filter cutoff based on `suspicion_meter`.
- Add tactile micro-SFX:
  * Coffee cup clink when toggling inspect mode.
  * Desk drawer slide sound when opening/closing the offshore safe.
  * Heavy telephone receiver slam when hanging up.
