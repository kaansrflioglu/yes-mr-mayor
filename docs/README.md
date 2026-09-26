# "Yes, Mr. Mayor!" Architectural & Game Design Documentation Suite
**Repository:** `kaansrflioglu/yes-mr-mayor`  
**Engine:** Godot 4.x (GDScript)  
**Standard:** Strict i18n (`en`, `tr`, `es`) | Data-Driven Simulation  

Welcome to the central design and engineering documentation directory. Below is the complete roadmap of all systems, content expansions, and quality-of-life improvements designed to elevate the game into a rich, replayable political satire.

---

## 📚 Master Documentation Index

| Document | Category | Key Focus & Summary |
| :--- | :--- | :--- |
| **1. [EVENT_EXPANSION_ROADMAP.md](file:///c:/Users/User/Documents/yes-mr-mayor/docs/EVENT_EXPANSION_ROADMAP.md)** | **Content & Lore** | **8-Phase Master Plan (180 Total Events):** Full narrative scaling from Day 1 to Day 30 without repeats, branching consequence chains, and turnkey AI generation prompts in `en`, `tr`, `es`. |
| **2. [INVESTIGATION_MECHANICS_REDESIGN.md](file:///c:/Users/User/Documents/yes-mr-mayor/docs/INVESTIGATION_MECHANICS_REDESIGN.md)** | **Core Loop** | **Beyond Brute-Force Clicking:** Replaces mindless spam-clicking with Focus AP (Coffee Sips), 09:00–17:00 shift clock time pressure, false accusation penalties, and tactile inspection tools. |
| **3. [HOTLINE_SYSTEM_REDESIGN.md](file:///c:/Users/User/Documents/yes-mr-mayor/docs/HOTLINE_SYSTEM_REDESIGN.md)** | **Gameplay** | **Dynamic Red Telephone:** Replaces the single hardcoded PAC deal with 6 unique caller archetypes (Police Chief, Mafia Don, Tabloid Journalist, City Engineer, Whistleblower). |
| **4. [OFFSHORE_SPENDING_MECHANICS.md](file:///c:/Users/User/Documents/yes-mr-mayor/docs/OFFSHORE_SPENDING_MECHANICS.md)** | **Economy** | **Offshore Safe Money Sinks:** Gives dirty bribe money actual utility (retaining defense fixers to wipe suspicion, bribing tabloids for approval, buying vanity desk assets). |
| **5. [AUDIO_AMBIENCE_SPECIFICATION.md](file:///c:/Users/User/Documents/yes-mr-mayor/docs/AUDIO_AMBIENCE_SPECIFICATION.md)** | **Atmosphere** | **Living Soundscape & Lo-Fi Noir BGM:** Eliminates dead silence on the desk canvas with continuous clock ticking, fluorescent hum, distant city sirens, and dynamic reactive music. |
| **6. [SKYLINE_VISUALS_EXPANSION.md](file:///c:/Users/User/Documents/yes-mr-mayor/docs/SKYLINE_VISUALS_EXPANSION.md)** | **Visuals** | **Dynamic City Window Evolution:** Animates torches and placards during protests (<25% opinion), flashing police squad cars, moving monorails, and catastrophic floods. |
| **7. [CONTROLS_AND_QOL_ROADMAP.md](file:///c:/Users/User/Documents/yes-mr-mayor/docs/CONTROLS_AND_QOL_ROADMAP.md)** | **Input & UX** | **Tactile Keyboard Shortcuts:** Quick-stamping (`A` Approve / `D` Reject), bribe stashing (`S`), dossier flipping (`Q`/`E`), and on-screen keycap badges for fluid play. |
| **8. [MORNING_BRIEFING_RITUAL.md](file:///c:/Users/User/Documents/yes-mr-mayor/docs/MORNING_BRIEFING_RITUAL.md)** | **Pacing** | **Pre-Shift Morning Ritual:** Calming morning coffee sip, daily secretarial post-it memos with shift modifiers, and a brass desk bell to summon the first petitioner. |

---

## 🛠️ Recommended Implementation Sequence
When transitioning from documentation to active feature implementation, the recommended order of development is:
1. **Quick Wins (Sprint 1):** Keyboard Shortcuts (`CONTROLS_AND_QOL_ROADMAP.md`) & Focus AP Limits (`INVESTIGATION_MECHANICS_REDESIGN.md`).
2. **Audio & Atmosphere (Sprint 2):** Continuous Ambience & Clock Tick (`AUDIO_AMBIENCE_SPECIFICATION.md`).
3. **Gameplay Depth (Sprint 3):** Dynamic Hotline Callers (`HOTLINE_SYSTEM_REDESIGN.md`) & Safe Ledger Sinks (`OFFSHORE_SPENDING_MECHANICS.md`).
4. **Visual Polish (Sprint 4):** Skyline Protest Crowds (`SKYLINE_VISUALS_EXPANSION.md`) & Morning Rituals (`MORNING_BRIEFING_RITUAL.md`).
5. **Content Scaling (Sprint 5):** Generating Event Phases 1 through 8 via [`EVENT_EXPANSION_ROADMAP.md`](file:///c:/Users/User/Documents/yes-mr-mayor/docs/EVENT_EXPANSION_ROADMAP.md).
