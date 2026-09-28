# Feature Prompt Specification: Tactile Desk Shredder & Evidence Tampering

## Feature Summary & Vision
In "Yes, Mr. Mayor!", the player navigates the razor-thin line between civic duty and clandestine enrichment. One of the most iconic tropes of municipal corruption is destroying incriminating evidence.

This feature adds a tactile, physical **Electric Paper Shredder** to the desk beside the safe drawer. When faced with catastrophic dossiers, federal subpoenas, or toxic bribes, the player can choose to bypass standard Approval/Rejection and feed the document directly into the shredder teeth.

---

## Gameplay Mechanics

### 1. The Physical Shredder Prop
- Located on the lower-left or right edge of the desk canvas (`DeskView.tscn`).
- Visual state:
  * Sleek industrial desktop shredder with an illuminated LED power light (Green = Ready, Yellow = Motor Warming, Red = Jammmed/Overheated).
  * Shreddable documents can be dragged into the slot or triggered via dedicated hotkey (`X` / `mayor_shred`) or clicking the shredder button.

### 2. Action & Consequence Flow
1. **Shredding the Active Document**:
   - The document slides into the shredder slot with a procedural motor grinding and paper slicing sound (`AudioManager.play_paper_shred()`).
   - The document splits into multi-slice confetti strips with a CPU particle burst of falling paper ribbons.
   - Suspicion drops immediately (`suspicion_level -= 15.0`) because concrete proof of the violation/scandal has been destroyed.
   - Bribe status:
     * If the document contained a Federal Sting trap, shredding the dossier successfully destroys the wiretap evidence, granting +10 Public Opinion ("Mayor exposes corrupt lobbyist attempted trap!").
     * If the player already pocketed the bribe and then shreds the document, suspicion drops by -20%, but the applicant's company becomes furious and leaks an anonymous tip later.
2. **Obstruction of Justice Risk**:
   - The shredder has a daily motor heat/capacity gauge: 1 shred per day is safe.
   - Shredding a second document on the same day causes the shredder to smoke, increases city council suspicion (`+25% suspicion`), and sets the flag `FLAG_SHREDDER_EVIDENCE_TAMPERED`.
   - Under `DIR_ANTI_CORRUPTION` directive, shredding any document triggers an immediate emergency press leak or auditor subpoena!

---

## Architecture & File Additions

### New Files to Create:
1. `scenes/desk/DeskShredder.tscn`: Custom Control node with shredder casing, paper slot, LED indicator, and `CPUParticles2D` for shredded paper confetti.
2. `scripts/desk/DeskShredder.gd`: Controller handling click/drag detection, shredding animations, and signal emissions.

### Files to Modify:
1. `scripts/desk/DeskView.gd`:
   - Add `@onready var desk_shredder = %DeskShredder`.
   - Connect `desk_shredder.shred_requested.connect(_on_shred_requested)`.
   - Handle shredding sequence: cancel inspect mode, animate document into shredder, apply resolution consequences, and present the next document.
2. `scripts/autoload/AudioManager.gd`:
   - Add procedural motor hum, blade chew, and paper slicing sound synthesis (`play_paper_shred()`).
3. `project.godot`:
   - Register new input action `mayor_shred` mapped to Key `X` and Joypad Button `Y`.
4. `data/localization.csv`:
   - Add keys: `UI_SHREDDER_TOOL`, `UI_SHREDDER_READY`, `UI_SHREDDER_JAMMED`, `UI_SHREDDER_CONFIRM`, `SHREDDER_NEWS_HEADLINE`.

---

## Step-by-Step Implementation Instructions

### Step 1: Create `DeskShredder.gd`
```gdscript
class_name DeskShredder
extends Control

signal shred_requested
signal shred_completed

@onready var slot_button: Button = %SlotButton
@onready var status_led: ColorRect = %StatusLED
@onready var shred_particles: CPUParticles2D = %ShredParticles

var daily_shred_count: int = 0
const MAX_SAFE_SHREDS_PER_DAY: int = 1

func _ready() -> void:
    slot_button.pressed.connect(_on_slot_pressed)
    update_led()

func update_led() -> void:
    if daily_shred_count == 0:
        status_led.color = Color(0.2, 0.9, 0.3, 1.0) # Green
    elif daily_shred_count == 1:
        status_led.color = Color(0.9, 0.8, 0.2, 1.0) # Amber warning
    else:
        status_led.color = Color(0.9, 0.2, 0.2, 1.0) # Red danger

func _on_slot_pressed() -> void:
    shred_requested.emit()

func execute_shred_animation(doc_item: Control) -> void:
    daily_shred_count += 1
    update_led()
    
    AudioManager.play_paper_shred()
    if shred_particles != null:
        shred_particles.emitting = true
        
    var tween := create_tween().set_parallel(true)
    tween.tween_property(doc_item, "position", global_position + Vector2(20, 40), 0.45).set_trans(Tween.TRANS_CUBIC)
    tween.tween_property(doc_item, "scale", Vector2(0.1, 0.1), 0.45)
    tween.tween_property(doc_item, "rotation", 0.35, 0.45)
    tween.tween_property(doc_item, "modulate:a", 0.0, 0.4)
    
    tween.chain().tween_callback(func():
        shred_completed.emit()
    )

func reset_day() -> void:
    daily_shred_count = 0
    update_led()
```

### Step 2: Integrate into `DeskView.gd`
```gdscript
func _on_shred_requested() -> void:
    if is_processing_decision or active_document == null:
        return
        
    is_processing_decision = true
    _set_stamps_enabled(false)
    
    var event: EventData = GameManager.active_event
    var is_sting: bool = event.is_federal_sting
    var took_bribe: bool = active_document.has_pocketed_bribe
    
    desk_shredder.execute_shred_animation(active_document)
    desk_shredder.shred_completed.connect(func():
        var res_effects: Dictionary = {}
        if is_sting:
            # Foiled federal entrapment!
            res_effects = {
                "public_opinion": 10.0,
                "suspicion": -20.0
            }
        else:
            var penalty: float = 25.0 if desk_shredder.daily_shred_count > 1 else 0.0
            res_effects = {
                "public_opinion": -5.0 if desk_shredder.daily_shred_count > 1 else 0.0,
                "suspicion": -15.0 + penalty
            }
            
        GameManager.apply_resolution(res_effects)
        
        var record := {
            "day": GameManager.current_day,
            "event_id": event.id,
            "approved": false,
            "took_bribe": took_bribe,
            "shredded": true,
            "headline_key": "NEWS_DOC_SHREDDED"
        }
        GameManager.daily_history.append(record)
        _present_next_document()
    , CONNECT_ONE_SHOT)
```

---

## Verification & Automated Test Plan
Create test script `tests/test_shredder_mechanics.gd`:
1. **Shred Action**: Trigger `desk_shredder.shred_requested`. Verify document animates into shredder, `GameManager.suspicion_level` drops by 15.0, and the next document is presented.
2. **Overuse Consequence**: Shred 2 documents in the same day. Assert `daily_shred_count == 2` and second shred incurs +25.0 suspicion penalty.
3. **Daily Reset**: Trigger `advance_day()`. Assert `desk_shredder.daily_shred_count == 0` and LED returns to green.
