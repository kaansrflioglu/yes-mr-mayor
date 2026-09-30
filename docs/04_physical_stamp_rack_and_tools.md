# Modular Specification 04: Physical Stamp Rack, Handles, and Ink Stamping Mechanics

## Executive Technical Summary
The definitive tactile climax of every decision in "Yes, Mr. Mayor!" is physically grasping a mayoral stamp, lifting it from its rack, aligning it over the petition, and slamming it down onto official paper. The current implementation in `res://scenes/desk/PhysicalStampRack.tscn` and `res://scenes/desk/PhysicalStampHandle.tscn` uses elementary `StyleBoxFlat` geometric shapes (brown rounded pill rectangles for handles and flat colored squares for ink pads). This document specifies the comprehensive visual transformation of the stamp rack and handles into weighty, high-detail desk apparatuses with realistic inking physics, squash-and-stretch impacts, and wet ink absorption shaders.

---

## 1. Technical Context & Affected Scenes
- **Rack Scene**: `res://scenes/desk/PhysicalStampRack.tscn`
- **Rack Script**: `res://scripts/desk/PhysicalStampRack.gd`
- **Handle Scene**: `res://scenes/desk/PhysicalStampHandle.tscn`
- **Handle Script**: `res://scripts/desk/PhysicalStampHandle.gd`
- **Associated Assets**:
  - `res://assets/sprites/desk/stamp_rack_brass.png`
  - `res://assets/sprites/props/stamp_handle_approve.png`
  - `res://assets/sprites/props/stamp_handle_reject.png`
  - `res://assets/sprites/props/stamp_handle_bribe.png`
  - `res://assets/sprites/documents/stamp_decal_approve.png`
  - `res://assets/sprites/documents/stamp_decal_reject.png`
  - `res://assets/sprites/documents/stamp_decal_bribe.png`

---

## 2. Asset & Sprite Modeling Specifications

### 2.1. The Stamp Rack Base (`PhysicalStampRack.tscn`)
Replace `StyleBoxFlat_stand` with a composite 2.5D visual assembly:
1. **Rack Frame Texture** (`stamp_rack_brass.png` - 320x180):
   - Heavy cast-iron base with polished brass holding arms and carved rest cradles for three handles.
   - Felt-lined grooves to prevent scuffing.
2. **Textured Ink Pads**:
   - Instead of flat colored panels, create recessed metal tins with porous, inky sponge textures:
     - `ink_pad_green.png`: Deep emerald green ink well with wet reflective center.
     - `ink_pad_red.png`: Crimson vermilion ink well with dried ink crusted along outer edges.
     - `ink_pad_gold.png`: Shimmering metallic gold/bronze ink well for corruption stamps.

### 2.2. The Turned Wood Stamp Handles (`PhysicalStampHandle.tscn`)
Construct bespoke 2.5D rendered sprites (80x140 px) for each stamp type:
1. **Handle Anatomy**:
   - Ergonomic turned hardwood knob (mahogany or walnut).
   - Polished brass ferrule collar with engraved municipal crest.
   - Rubber die base with raised reverse lettering.
2. **Variants**:
   - `stamp_handle_approve.png`: Warm wood tone, emerald enameled metal band, green rubber base.
   - `stamp_handle_reject.png`: Dark ebony wood tone, oxblood enameled band, red rubber base.
   - `stamp_handle_bribe.png`: Glossy black lacquer, solid 24k gold ferrule, gilded rubber base.

---

## 3. Dynamic Drag, Lift & Impact Physics

Upgrade `PhysicalStampHandle.gd` with deterministic visual behaviors:

### 3.1. Lift & Cast Shadow Behavior
When the player clicks and drags a stamp handle:
- **Visual Elevation**:
  - Scale handle from `1.0` to `1.18` over 0.1s (`TRANS_BACK`, `EASE_OUT`).
  - Decouple the `ShadowVisual` panel/sprite: expand shadow radius and offset downwards by 36px with 40% blur to convey real 3D desk elevation.
- **Dynamic 3D Inertia Tilt**:
  - Sample cursor motion delta: `var delta_x = current_pos.x - last_pos.x`.
  - Rotate handle sprite: `HandleVisual.rotation_degrees = clamp(delta_x * 0.15, -15.0, 15.0)`.

### 3.2. Ghost Stamp Alignment Preview
While dragging a stamp over `DocumentDropZone`:
- Project a translucent ghost footprint (opacity 0.35) of the stamp decal directly beneath the handle onto the document surface.
- The ghost aligns to the prospective stamp position, giving the player precise aiming feedback.

### 3.3. Slam Down & Impact Squash
When the player releases the mouse over a valid target or presses the shortcut key:
1. **Impact Motion Sequence**:
   - Handle snaps to desk plane in 0.05s.
   - Shadow collapses instantly to base (offset Y: 2px).
   - **Squash-and-Stretch**: Handle scale tweens to `Vector2(1.25, 0.75)` on impact frame, rebounding to `Vector2(1.0, 1.0)` over 0.18s using `TRANS_ELASTIC`.
2. **Desk Haptic Shake**:
   - Trigger `shake_root` micro-shake in `DeskView.gd` (magnitude: 4.0px, duration: 0.12s).
3. **Decal Deposition**:
   - Spawn a permanent stamp imprint node inside the active `DocumentItem`.

---

## 4. Wet Ink Decal & Paper Bleed Shaders

Create `res://assets/shaders/stamp_ink_bleed.gdshader`:
When a stamp is applied, the ink should visually appear wet with a slight specular glint before absorbing into the porous paper fibers over 1.2 seconds.

```glsl
shader_type canvas_item;

uniform float dry_progress : hint_range(0.0, 1.0) = 1.0;
uniform sampler2D paper_grain_texture;
uniform vec4 ink_color : source_color = vec4(0.1, 0.45, 0.2, 1.0);

void fragment() {
    vec4 decal = texture(TEXTURE, UV);
    if (decal.a < 0.01) {
        discard;
    }
    
    // Sample microscopic paper grain roughness
    vec4 grain = texture(paper_grain_texture, UV * 3.0);
    
    // Wet ink has higher saturation and subtle gloss sheen
    float wetness = 1.0 - dry_progress;
    vec3 wet_ink = ink_color.rgb * 1.25;
    vec3 dry_ink = ink_color.rgb * mix(0.85, 1.0, grain.r);
    
    vec3 current_ink = mix(dry_ink, wet_ink, wetness);
    
    // Ink bleeding along paper fibers at edges
    float bleed_alpha = smoothstep(0.1, 0.5, decal.a + (grain.g - 0.5) * 0.15 * dry_progress);
    
    COLOR = vec4(current_ink, decal.a * bleed_alpha);
}
```

---

## 5. Verification & Acceptance Criteria
- [ ] Stamp handles visually look like tactile 3D wooden tools rather than flat UI cards.
- [ ] Dragging stamps creates intuitive elevation via dynamic shadows and tilt.
- [ ] Stamping impacts produce crisp, satisfying squash-and-stretch tweens accompanied by screen micro-shake.
- [ ] Applied stamp decals feature natural ink bleed, varied rotational offset (+/- 3 degrees), and paper grain interaction.
- [ ] Both drag-and-drop and hotkey (`A` / `D` / `S`) stamping trigger identical visual fidelity.
