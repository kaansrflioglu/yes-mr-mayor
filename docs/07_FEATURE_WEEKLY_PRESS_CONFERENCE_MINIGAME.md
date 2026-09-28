# Feature Prompt Specification: Weekly Press Conference Minigame (Media Grilling)

## Feature Summary & Vision
While the daily tabloid newspaper (`DayEndSummary.tscn`) delivers great satirical feedback, the player currently experiences the media passively. 

This feature introduces a dynamic **Press Conference Minigame** occurring every Friday evening (Days 5, 10, 15, 20, 25, 30) or immediately following catastrophic scandals (suspicion > 70% or major bribe leaks). The Mayor steps behind the City Hall press podium facing blinding camera flashbulbs, murmuring reporters, and aggressive microphones to defend their controversial permits.

---

## Gameplay Mechanics

### 1. The Press Podium Canvas (`PressConferenceModal.tscn`)
- Visual Atmosphere:
  * Dimly lit press briefing room with acoustic wooden podium, city seal emblem, and multiple broadcast microphones.
  * Rapid procedural camera flashbulbs (strobe flashes using `ColorRect` flashes and audio shutter snaps).
  * Silhouette crowd of journalists with raised hands.
- Sequence:
  * Clarissa the secretary introduces the briefing.
  * The Mayor faces **2 to 3 sharp, contextual questions** dynamically generated from the player's recent controversial decisions (e.g. approving an illegal skyscraper, pocketing a harbor bribe, or defunding sanitation).

### 2. The 3 Journalist Archetypes
1. **Arthur Vance (The Daily Watchdog)**: Muckraking investigative reporter. Attacks corruption, forged seals, and sudden offshore wealth.
2. **Elena Rostova (Municipal Tribune)**: Pragmatic policy editor. Focuses on budget deficits, project delays, and union strikes.
3. **Rex Sterling (Channel 6 Action News)**: Sensationalist tabloid anchor. Demands answers on bizarre scandals, mob sightings, and luxury office rumors.

### 3. Mayoral Response Tactics
For each question, the player has 4 dialogue choices with distinct strategic payoffs:
1. **Spin the Narrative**:
   - Reframe the decision as bold visionary leadership.
   - *Roll*: If public opinion > 45%, grants +8.0% Opinion. If low, press ridicules the spin (+4.0% Suspicion).
2. **Scapegoat & Blame**:
   - Blame previous mayor, greedy contractors, or State Governor.
   - *Outcome*: Drops Suspicion by -6.0%, but alienates relevant council allies.
3. **No Comment / Stonewall**:
   - Refuse to answer on legal grounds.
   - *Outcome*: Neutral, but guarantees +4.0% Suspicion from reporter frustration.
4. **Deploy Media Distraction (Grand City Announcement)**:
   - Announce a new public park, festival, or tax holiday.
   - *Cost*: $20,000 from City Treasury.
   - *Outcome*: Completely wipes the scandal from headlines (+12.0% Public Opinion, -10.0% Suspicion).
5. **Clandestine Publisher Bribe (Offshore Slush Fund)**:
   - If player has $25,000+ in offshore account, quietly buy the newspaper's editorial board.
   - *Outcome*: Front-page praise tomorrow!

---

## Architecture & File Additions

### New Files to Create:
1. `scenes/summary/PressConferenceModal.tscn`: Custom presentation scene with podium, microphone cluster, flash particle effects, and question/answer card.
2. `scripts/ui/PressConferenceModal.gd`: Logic controlling reporter dialogue assembly, timer, response outcomes, and audio cues.
3. `data/press_questions.json`: Database of contextual journalist questions tied to event categories and flags.

### Files to Modify:
1. `scripts/desk/DeskView.gd`:
   - In `_on_daily_quota_completed()`: Check if day is a Friday (`day % 5 == 0`) or if suspicion > 70%.
   - If true, display `PressConferenceModal` before presenting the newspaper summary.
2. `scripts/autoload/AudioManager.gd`:
   - Add procedural audio synthesis for:
     * Camera shutter snaps & flash recharge whine (`play_camera_shutter()`)
     * Murmuring reporter crowd chatter (`set_crowd_murmur_active(bool)`)
     * Microphone feedback squeal on approach (`play_mic_feedback()`)
3. `data/localization.csv`:
   - Add dialogue lines and tactic labels for all supported languages (EN, TR, ES).

---

## Step-by-Step Implementation Instructions

### Step 1: Create `PressConferenceModal.gd`
```gdscript
class_name PressConferenceModal
extends Control

signal conference_finished

@onready var reporter_name_label: Label = %ReporterNameLabel
@onready var question_text_label: Label = %QuestionTextLabel
@onready var btn_spin: Button = %BtnSpin
@onready var btn_blame: Button = %BtnBlame
@onready var btn_stonewall: Button = %BtnStonewall
@onready var btn_distract: Button = %BtnDistract
@onready var flash_overlay: ColorRect = %FlashOverlay

var current_question_idx: int = 0
var active_questions: Array[Dictionary] = []

func _ready() -> void:
    btn_spin.pressed.connect(func(): _resolve_answer("spin"))
    btn_blame.pressed.connect(func(): _resolve_answer("blame"))
    btn_stonewall.pressed.connect(func(): _resolve_answer("stonewall"))
    btn_distract.pressed.connect(func(): _resolve_answer("distract"))

func start_conference(recent_events: Array[Dictionary]) -> void:
    visible = true
    _trigger_camera_flash()
    AudioManager.play_mic_feedback()
    AudioManager.set_crowd_murmur_active(true)
    
    active_questions = _generate_contextual_questions(recent_events)
    current_question_idx = 0
    _present_question()

func _trigger_camera_flash() -> void:
    AudioManager.play_camera_shutter()
    flash_overlay.modulate.a = 0.8
    var tween := create_tween()
    tween.tween_property(flash_overlay, "modulate:a", 0.0, 0.25)

func _resolve_answer(tactic: String) -> void:
    _trigger_camera_flash()
    match tactic:
        "spin":
            GameManager.apply_resolution({"public_opinion": 6.0, "suspicion": -2.0})
        "blame":
            GameManager.apply_resolution({"suspicion": -8.0, "public_opinion": -2.0})
        "stonewall":
            GameManager.apply_resolution({"suspicion": 5.0})
        "distract":
            if GameManager.city_budget >= 20000:
                GameManager.city_budget -= 20000
                GameManager.apply_resolution({"public_opinion": 12.0, "suspicion": -10.0})
                
    current_question_idx += 1
    if current_question_idx >= active_questions.size():
        AudioManager.set_crowd_murmur_active(false)
        conference_finished.emit()
        queue_free()
    else:
        _present_question()
```

---

## Verification & Automated Test Plan
Create test script `tests/test_press_conference.gd`:
1. **Trigger on Day 5**: Advance game to Day 5. Complete daily quota. Assert `PressConferenceModal` spawns before `DayEndSummary`.
2. **Contextual Question Binding**: Complete a day by approving a corrupt floodway project. Verify the first question generated references the floodway violation.
3. **Tactic Impact**: Choose "Distract" with sufficient budget. Verify -$20,000 budget, +12.0 opinion, and -10.0 suspicion applied.
