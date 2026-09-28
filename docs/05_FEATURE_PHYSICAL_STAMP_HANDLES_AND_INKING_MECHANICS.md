# Feature Prompt Specification: Physical Rubber Stamp Handles & Dynamic Inking Mechanics

## Feature Summary & Vision
Currently, approvals and rejections in `DeskView.tscn` are triggered via flat GUI button presses (`%BtnStampApprove` and `%BtnStampReject`). While functional, bureaucratic satire games thrive on **tactile, visceral weight**.

This feature introduces **Physical 2.5D Rubber Stamp Handles** resting in a polished wooden stamp carousel on the mayoral desk. Players can either use keyboard hotkeys for instant stamping or pick up, drag, and physically slam the heavy brass/wooden stamp anywhere on the petition dossier with dynamic ink transfer, angle jitter, ink smudges, and desk resonance.

---

## Gameplay & Visual Mechanics

### 1. The Physical Stamp Carousel
- Replaces the generic `%StampRack` with a stylized wooden desk stand containing:
  1. **Green Approved Stamp** (Polished oak handle, emerald rubber base).
  2. **Red Rejected Stamp** (Mahogany handle, crimson rubber base).
  3. **Gold Luxury Stamp** (Solid 24k gold handle, unlocked via Offshore Ledger).
  4. **Felt Inking Pad Box** (Dual-compartment black and red ink reservoir).

### 2. Interaction Modes
1. **Quick-Action Hotkeys (`A` / `D` / Gamepad Triggers)**:
   - Picking the stamp lifts it with a swift arc above the dossier, hovers momentarily, and slams down with satisfying elastic squash & stretch.
2. **Tactile Drag-and-Drop Stamping**:
   - Clicking and holding a stamp handle detaches it from the rack, casting a dynamic soft drop shadow below the cursor.
   - Releasing over the document slams the stamp at the exact cursor coordinate with dynamic rotation tilt.
3. **Ink Freshness & Smudge Dynamics**:
   - Each stamp has an ink saturation counter (starts at 100%).
   - Stamping reduces saturation by 25%. Lower saturation produces faint, weathered ink impressions.
   - Clicking the ink pad re-dips the stamp with a squishy felt sound (`AudioManager.play_ink_pad_dip()`).
   - If the player drags the document immediately after stamping, fresh wet ink leaves a subtle, satisfying directional smudge!

---

## Architecture & File Additions

### New Files to Create:
1. `scenes/desk/PhysicalStampRack.tscn`: Custom 2.5D visual container with stamp handle nodes, spring physics tweens, and ink reservoir.
2. `scripts/desk/PhysicalStampHandle.gd`: Node script handling drag-and-drop mechanics, cursor tracking, lift elevation shadows, and slam physics.

### Files to Modify:
1. `scripts/desk/DeskView.gd`:
   - Replace or bind `btn_stamp_approve` and `btn_stamp_reject` events to `PhysicalStampRack`.
   - Forward drop coordinate and angle jitter to `active_document.apply_stamp_visual_at(pos, rot, approved)`.
2. `scripts/desk/DocumentItem.gd`:
   - Extend `apply_stamp_visual()` to accept a target position, rotation angle, and ink opacity.
3. `scripts/autoload/AudioManager.gd`:
   - Add multi-layered procedural stamp acoustics:
     * High wood knock (handle impact)
     * Heavy low-frequency desk thud (desk resonance)
     * Wet rubber peel (stamp lifting off damp paper)

---

## Step-by-Step Implementation Instructions

### Step 1: Create `PhysicalStampHandle.gd`
```gdscript
class_name PhysicalStampHandle
extends Control

signal stamp_slammed(approved: bool, hit_global_pos: Vector2, hit_rotation: float)

@export var is_approve_stamp: bool = true
@onready var handle_sprite: Control = %HandleVisual
@onready var shadow_sprite: Control = %ShadowVisual

var is_dragging: bool = false
var rest_position: Vector2 = Vector2.ZERO
var drag_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
    rest_position = position
    gui_input.connect(_on_gui_input)

func _on_gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            if event.pressed:
                start_drag(event.global_position)
            elif is_dragging:
                finish_slam(event.global_position)

func start_drag(mouse_glob: Vector2) -> void:
    is_dragging = true
    drag_offset = global_position - mouse_glob
    z_index = 50
    # Lift animation: stamp scales up, shadow displaces down-right
    var tween := create_tween().set_parallel(true)
    tween.tween_property(handle_sprite, "scale", Vector2(1.18, 1.18), 0.12)
    tween.tween_property(shadow_sprite, "position", Vector2(16, 24), 0.12)
    tween.tween_property(shadow_sprite, "modulate:a", 0.35, 0.12)

func _process(_delta: float) -> void:
    if is_dragging:
        global_position = get_global_mouse_position() + drag_offset

func finish_slam(mouse_glob: Vector2) -> void:
    is_dragging = false
    z_index = 0
    
    # Random angle jitter between -6 and +6 degrees
    var slam_rot: float = deg_to_rad(randf_range(-6.0, 6.0))
    
    # Slam animation: stamp squash and return
    var tween := create_tween()
    tween.tween_property(handle_sprite, "scale", Vector2(0.9, 0.9), 0.06).set_trans(Tween.TRANS_QUAD)
    tween.tween_property(handle_sprite, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_ELASTIC)
    
    stamp_slammed.emit(is_approve_stamp, mouse_glob, slam_rot)
    
    # Return handle smoothly to rack
    var return_tween := create_tween()
    return_tween.tween_property(self, "position", rest_position, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
```

### Step 2: Update `DocumentItem.gd` for Freeform Stamp Position
```gdscript
func apply_stamp_visual_at(target_pos: Vector2, stamp_rot: float, approved: bool) -> void:
    if is_stamped:
        return
    is_stamped = true

    stamp_overlay.visible = true
    # Convert global drop point to local document coordinate
    stamp_overlay.position = to_local(target_pos) - (stamp_overlay.size * 0.5)
    stamp_overlay.rotation = stamp_rot
    
    if approved:
        stamp_label.text = tr("UI_STAMP_APPROVED")
        stamp_label.set("theme_override_colors/font_color", Color(0.12, 0.78, 0.38, 1.0))
    else:
        stamp_label.text = tr("UI_STAMP_REJECTED")
        stamp_label.set("theme_override_colors/font_color", Color(0.92, 0.22, 0.22, 1.0))
        
    var tween := create_tween().set_parallel(true)
    tween.tween_property(stamp_overlay, "scale", Vector2(1.0, 1.0), 0.18).from(Vector2(2.2, 2.2)).set_trans(Tween.TRANS_BACK)
    tween.tween_property(stamp_overlay, "modulate:a", 1.0, 0.12).from(0.0)
    
    stamped.emit(approved)
```

---

## Verification & Automated Test Plan
Create test script `tests/test_physical_stamps.gd`:
1. **Handle Drag & Return**: Drag the Approve stamp to `Vector2(600, 400)` and release outside the document. Verify the stamp returns safely to `rest_position` without triggering a decision.
2. **Document Slam**: Release the stamp over `active_document`. Assert `active_document.is_stamped == true` and decision sequence begins.
3. **Hotkey Parity**: Pressing `mayor_approve` must lift the physical stamp and slam it onto the center of the document automatically.
