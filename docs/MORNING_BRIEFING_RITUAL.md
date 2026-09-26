# Morning Briefing, Daily Modifiers & Desk Transition Ritual
**Project:** *Yes, Mr. Mayor!* (`yes-mr-mayor`)  
**Document Target:** Pacing, Atmosphere & Narrative Bridge Design  
**Module:** `scripts/desk/DeskView.gd` & `scripts/ui/MorningBriefingCard.gd`  
**Status:** Approved Architectural Specification  

---

## 1. Problem Statement: Abrupt Shift Pacing
Currently in [`scripts/desk/DeskView.gd`](file:///c:/Users/User/Documents/yes-mr-mayor/scripts/desk/DeskView.gd#L223-L245):
```gdscript
func _on_next_day_pressed() -> void:
    _start_or_continue_shift()
```
The instant the player finishes reading the evening newspaper and clicks "Start Next Day", the desk immediately slams the first heavy petition down with a paper rustle.

There is **zero narrative breathing room** between days:
- The player never experiences the calm morning before the storm.
- There is no sense of a new working day dawning over the city.
- No daily directives, weather warnings, or secretarial post-it notes prepare the Mayor for the day's special challenges.

---

## 2. The Morning Office Ritual (Pre-Shift Phase)

Before the waiting room doors open and applicants begin filing in, the Mayor enjoys a 3-part **Morning Office Ritual**:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           THE MORNING MAYOR'S DESK                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  [1. THE STEAMING COFFEE MUG]                                               │
│  • A warm ceramic mug sitting on a coaster.                                 │
│  • Clicking it plays a satisfying coffee sip SFX and sets starting Focus AP │
│                                                                             │
│  [2. THE SECRETARY'S POST-IT MEMO]                                         │
│  • A yellow sticky note slapped on the desk blotter:                        │
│    "Good morning, Mr. Mayor! Environmental auditors are in town today.      │
│     The Governor's office called twice before 8 AM. Be careful with river   │
│     permits!"                                                               │
│                                                                             │
│  [3. THE DESK SERVICE BELL ("CALL FIRST DOCKET")]                           │
│  • A polished brass reception bell on the desk.                             │
│  • When ready, the player presses [SPACE] or clicks the bell:               │
│    *DING!* ➔ Doors unlock ➔ First petitioner enters ➔ Shift officially begins│
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Daily Modifiers & Dynamic Morning Memos

Each morning memo communicates a **Daily Modifier** that alters gameplay for that shift:

| Day | Secretarial Memo Text | In-Game Shift Modifier |
| :--- | :--- | :--- |
| **Day 3** | *"Auditors from the Ministry of Ecology are dining across the street."* | Environmental violations grant **2x Public Approval** if rejected, but **2x Suspicion** if approved. |
| **Day 7** | *"Sanitation union representatives are picketing on the east lawn."* | Any decision affecting public works or wages has immediate public opinion impact. |
| **Day 12**| *"Federal subpoena rumors are flying. Shredder is oiled and ready."* | Bribe amounts are 25% higher, but all suspicion gains increase by +5%. |
| **Day 18**| *"Heatwave! The air conditioning in City Hall is broken."* | Mayor's Focus AP regenerates slower; coffee costs $1,000. |
| **Day 28**| *"Election in 48 hours! Pollsters say you're leading by 2%."* | All public opinion gains and losses are doubled. |

---

## 4. Phased Implementation Plan

### Phase 1: Pre-Shift State in `DeskView.gd`
- Introduce state machine: `STATE_MORNING_RITUAL ➔ STATE_PROCESSING_EVENTS ➔ STATE_DAY_END`.
- When advancing day, hide stamp buttons and spawn the **Morning Post-It Note** and **Brass Bell** on the desk center.
- Play morning sunrise window tint transition in `SkylineView.gd`.

### Phase 2: Post-It Memo Generator & Localization
- Create `data/morning_memos.json` with 30 unique day-specific secretarial memos in `en`, `tr`, and `es`.
- Add charming hand-written font styling to the yellow post-it note panel.

### Phase 3: Tactile Interactions & Brass Bell Audio
- Clicking the coffee cup triggers a pleasant sip animation with steam fading.
- Clicking the brass desk bell plays a crisp metallic chime (`play_desk_bell()`), smoothly sliding the memo off-screen and sliding the first petition in.
