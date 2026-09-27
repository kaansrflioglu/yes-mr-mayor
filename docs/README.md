# "Yes, Mr. Mayor!" Architectural & Game Design Documentation Suite
**Repository:** `kaansrflioglu/yes-mr-mayor`  
**Engine:** Godot 4.x (GDScript)  
**Standard:** Strict i18n (`en`, `tr`, `es`) | Data-Driven Simulation  

Welcome to the central design and engineering documentation directory. Below is the complete roadmap of all systems, content expansions, and quality-of-life improvements designed to elevate the game into a rich, replayable political satire.

---

## 📚 Master Documentation Index

| Document | Category | Key Focus & Summary | Status |
| :--- | :--- | :--- | :---: |
| **1. [EVENT_EXPANSION_ROADMAP.md](EVENT_EXPANSION_ROADMAP.md)** | **Content & Lore** | **8-Phase Master Plan (180 Total Events):** Full narrative scaling from Day 1 to Day 30 without repeats, branching consequence chains, and turnkey AI generation prompts in `en`, `tr`, `es`. | ✅ **Completed** |
| **2. [INVESTIGATION_MECHANICS_REDESIGN.md](INVESTIGATION_MECHANICS_REDESIGN.md)** | **Core Loop** | **Beyond Brute-Force Clicking:** Replaces mindless spam-clicking with Focus AP (Coffee Sips), 09:00–17:00 shift clock time pressure, false accusation penalties, and tactile inspection tools. | ✅ **Completed** |
| **3. [HOTLINE_SYSTEM_REDESIGN.md](HOTLINE_SYSTEM_REDESIGN.md)** | **Gameplay** | **Dynamic Red Telephone:** Replaces the single hardcoded PAC deal with 6 unique caller archetypes (Police Chief, Mafia Don, Tabloid Journalist, City Engineer, Whistleblower). | ✅ **Completed** |
| **4. [OFFSHORE_SPENDING_MECHANICS.md](OFFSHORE_SPENDING_MECHANICS.md)** | **Economy** | **Offshore Safe Money Sinks:** Gives dirty bribe money actual utility (retaining defense fixers to wipe suspicion, bribing tabloids for approval, buying vanity desk assets). | ✅ **Completed** |
| **5. [AUDIO_AMBIENCE_SPECIFICATION.md](AUDIO_AMBIENCE_SPECIFICATION.md)** | **Atmosphere** | **Living Soundscape & Lo-Fi Noir BGM:** Eliminates dead silence on the desk canvas with continuous clock ticking, fluorescent hum, distant city sirens, and dynamic reactive music. | ✅ **Completed** |
| **6. [SKYLINE_VISUALS_EXPANSION.md](SKYLINE_VISUALS_EXPANSION.md)** | **Visuals** | **Dynamic City Window Evolution:** Animates torches and placards during protests (<25% opinion), flashing police squad cars, moving monorails, and catastrophic floods. | ✅ **Completed** |
| **7. [CONTROLS_AND_QOL_ROADMAP.md](CONTROLS_AND_QOL_ROADMAP.md)** | **Input & UX** | **Tactile Keyboard Shortcuts:** Quick-stamping (`A` Approve / `D` Reject), bribe stashing (`S`), dossier flipping (`Q`/`E`), and on-screen keycap badges for fluid play. | ✅ **Completed** |
| **8. [MORNING_BRIEFING_RITUAL.md](MORNING_BRIEFING_RITUAL.md)** | **Pacing** | **Pre-Shift Morning Ritual:** Calming morning coffee sip, daily secretarial post-it memos with shift modifiers, and a brass desk bell to summon the first petitioner. | ✅ **Completed** |

---

## 🛠️ Implementation Status & Test Verification
All 5 sequential sprints across the 8 architectural specifications are **100% implemented, integrated, and verified via automated test runners**:
1. **Sprint 1 (Quick Wins):** Keyboard Shortcuts ([CONTROLS_AND_QOL_ROADMAP.md](CONTROLS_AND_QOL_ROADMAP.md)) & Focus AP Limits ([INVESTIGATION_MECHANICS_REDESIGN.md](INVESTIGATION_MECHANICS_REDESIGN.md)) — *Verified (`TestRunnerControlsPhase1-3`, `TestRunnerInvestigation`)*.
2. **Sprint 2 (Audio & Atmosphere):** Continuous Ambience & Clock Tick ([AUDIO_AMBIENCE_SPECIFICATION.md](AUDIO_AMBIENCE_SPECIFICATION.md)) — *Verified (`TestRunnerAudioAmbiencePhase1-3`)*.
3. **Sprint 3 (Gameplay Depth):** Dynamic Hotline Callers ([HOTLINE_SYSTEM_REDESIGN.md](HOTLINE_SYSTEM_REDESIGN.md)) & Safe Ledger Sinks ([OFFSHORE_SPENDING_MECHANICS.md](OFFSHORE_SPENDING_MECHANICS.md)) — *Verified (`TestRunnerHotlinePhase1-3`, `TestRunnerOffshorePhase1-3`)*.
4. **Sprint 4 (Visual Polish):** Skyline Protest Crowds ([SKYLINE_VISUALS_EXPANSION.md](SKYLINE_VISUALS_EXPANSION.md)) & Morning Rituals ([MORNING_BRIEFING_RITUAL.md](MORNING_BRIEFING_RITUAL.md)) — *Verified (`TestRunnerSkylinePhase1-3`, `TestRunnerMorningBriefingPhase1-3`)*.
5. **Sprint 5 (Content Scaling):** 180-Event 8-Phase Library & i18n ([EVENT_EXPANSION_ROADMAP.md](EVENT_EXPANSION_ROADMAP.md)) — *Verified (`TestRunnerDeduction`, `TestRunnerPhase1-5`)*.
