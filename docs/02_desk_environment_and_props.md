# Modular Specification 02: Desk Environment, Lighting, and Tactile Props

## Executive Technical Summary
This document specifies the technical and artistic overhaul of the primary gameplay environment in `res://scenes/desk/DeskView.tscn` and its child prop scenes. The existing implementation depicts the mayor's office using uniform flat color panels (`StyleBoxFlat_desk_bg` at `#1F242E`, `StyleBoxFlat_blotter` at `#29303D`, and solid rectangular buttons for physical props). This specification defines the transition to a rich, photorealistic 2.5D tactile desk with bespoke wood and leather textures, overhead lamp cone lighting, interactive 2D prop sprites with tweened micro-animations, and ambient particles.

---

## 1. Technical Context & Affected Scenes
- **Primary Scene**: `res://scenes/desk/DeskView.tscn`
- **Primary Script**: `res://scripts/desk/DeskView.gd`
- **Sub-Scenes**:
  - `res://scenes/desk/RedTelephone.tscn`
  - `res://scenes/desk/DeskShredder.tscn`
  - `res://scenes/desk/PhysicalStampRack.tscn`
- **Asset Directories**:
  - `res://assets/sprites/desk/`
  - `res://assets/sprites/props/`
  - `res://assets/shaders/`

---

## 2. Desk Architecture & Layering Hierarchy

The scene tree within `DeskView.tscn` must be organized in the following z-index and render order:

```
DeskView (Control, 1920x1080)
├── BackgroundLayer (CanvasItem)
│   ├── WindowFrameContainer (Houses SkylineView.tscn)
│   └── OfficeWallTexture (Dark green/navy wallpaper with wainscoting)
├── DeskSurfaceLayer (TextureRect, 1920x820, anchored to bottom)
│   ├── DeskWoodTexture (Mahogany wood grain with varnish sheen)
│   ├── LeatherBlotter (NinePatchRect, centered, dark navy leather with gold tooling)
│   ├── BrassBlotterCorners (TextureRect x4, ornate corner protectors)
│   └── SafeDrawerSlot (Visual indentation with slide-out drawer)
├── PropsLayer (Control)
│   ├── RedTelephone (scenes/desk/RedTelephone.tscn, Left: 32, Top: 340)
│   ├── PhysicalStampRack (scenes/desk/PhysicalStampRack.tscn, Right: 300, Top: 480)
│   ├── DeskShredder (scenes/desk/DeskShredder.tscn, Left: 32, Bottom: 100)
│   ├── BrassServiceBell (TextureButton with squash Tween, Center-Right)
│   ├── CigarBoxProp (Interactive bribe stash container)
│   ├── EspressoCupProp (Ceramic cup with GPUParticles2D steam)
│   └── DictaphoneProp (Vintage cassette recorder with rotating spool wheels)
├── DocumentInteractionLayer (Control)
│   └── DocumentDropZone (Active dossier, draggable papers, inspection focus)
└── LightingAndAtmosphereLayer (CanvasItem, mouse_filter = MOUSE_FILTER_IGNORE)
    ├── DeskLampSpotlight (PointLight2D or Multiplicative CanvasItem Shader)
    ├── DustMotesParticles (GPUParticles2D ambient floating dust motes)
    └── VignetteOverlay (Soft radial edge darkening)
```

---

## 3. Prop Modernization Directives

### 3.1. Desk Surface & Leather Blotter
1. Replace `PanelContainer` using `StyleBoxFlat_desk_bg` with a `TextureRect`:
   - Texture: `res://assets/sprites/desk/desk_mahogany_surface.png` (1920x820, seamless horizontal wood grain, deep gloss highlights).
2. Replace `StyleBoxFlat_blotter` with `NinePatchRect`:
   - Texture: `res://assets/sprites/desk/blotter_leather_9patch.png` (Margins: 24px each side, debossed border stitching, subtle paper scuffs).
   - Add four corner decorative sprites: `res://assets/sprites/desk/brass_corner_clamp.png` (64x64).

### 3.2. Red Hotline Telephone (`RedTelephone.tscn`)
1. Remove generic red button (`StyleBoxFlat_phone_btn`).
2. Implement composite sprite hierarchy:
   - `TelephoneBase` (`res://assets/sprites/props/telephone_rotary_base.png` - 200x180): Heavy bakelite 1970s crimson telephone body with chrome dial.
   - `TelephoneHandset` (`res://assets/sprites/props/telephone_handset.png`): Resting on cradle or lifted when active.
   - `CordSprite` (Line2D or procedural bezier curve simulating spring coiled cord connecting handset to base).
   - `IndicatorLight` (Sprite2D with additive blend mode `#FF2222` modulated during ringing).
3. Visual Behavior & Tweens in `RedTelephone.gd`:
   - When incoming call triggers:
     - Shake animation: Rapid horizontal jitter (+/- 4px, 0.04s loop).
     - Indicator light pulse (alpha ping-pong 0.2 to 1.0 at 4Hz).
   - On click / pickup:
     - Handset lifts vertically (Y offset -60px with slight 12 deg tilt) with sound effect cue.

### 3.3. Brass Service Bell
1. Replace flat yellow rectangle (`StyleBoxFlat_brass_bell`) with a `TextureButton`:
   - Textures:
     - Normal: `res://assets/sprites/props/bell_brass_normal.png` (96x96, polished brass dome).
     - Hover: `res://assets/sprites/props/bell_brass_hover.png` (Specular highlight sheen).
     - Pressed: `res://assets/sprites/props/bell_brass_pressed.png` (Depressed plunger, squashed dome).
2. Micro-animation:
   - On `pressed`: Scale dome Y by 0.88 for 0.08s, then bounce back with spring ease `TRANS_ELASTIC`.

### 3.4. Industrial Desk Shredder (`DeskShredder.tscn`)
1. Replace flat grey panel (`StyleBoxFlat_casing`) with:
   - Texture: `res://assets/sprites/props/shredder_chassis.png` (Matte black textured plastic casing, danger hazard chevron stripes across paper intake).
   - Intake Slot: Chrome metal slit with deep shadow depth.
   - LED Status: Green power light; flashing amber/red during paper destruction.
2. Shredding Effect:
   - Integrate `CPUParticles2D` or `GPUParticles2D` emitting falling white/off-white paper confetti ribbons downwards into the collection bin.

### 3.5. Bribe Drawer & Corrupt Props
1. **Cigar Box Prop (`cigar_box_prop`)**:
   - Replace brown flat button with `res://assets/sprites/props/cigar_humidor_closed.png`.
   - Hover shows slight open lid revealing Cuban cigars and rolled bank notes.
2. **Yacht Brochure Prop (`yacht_brochure_prop`)**:
   - Replace flat blue button with glossy brochure cover: `res://assets/sprites/props/brochure_luxury_yacht.png`.
3. **Espresso Machine & Cup**:
   - High-detail ceramic demitasse cup with saucer.
   - Add `GPUParticles2D` for faint rising steam using additive blend and low-velocity vertical motion.

---

## 4. Office Lighting & Atmosphere Shader

Create `res://assets/shaders/desk_lighting.gdshader`:
- Combines an overhead banker's lamp spotlight cone (warm incandescent amber `#FFF4D6`) centered over the active document area.
- Subtle peripheral falloff to dark cool navy vignette at screen boundaries.
- Animated dust mote blending.

```glsl
shader_type canvas_item;

uniform vec2 lamp_center = vec2(0.5, 0.65);
uniform float lamp_radius = 0.55;
uniform float lamp_intensity = 1.15;
uniform vec4 ambient_darkness : source_color = vec4(0.04, 0.06, 0.1, 0.45);
uniform vec4 lamp_tint : source_color = vec4(1.0, 0.95, 0.85, 1.0);

void fragment() {
    vec2 uv = UV;
    float dist = distance(uv, lamp_center);
    float falloff = smoothstep(lamp_radius, lamp_radius * 0.2, dist);
    
    vec4 scene_col = texture(TEXTURE, uv);
    vec4 lit_col = scene_col * lamp_tint * lamp_intensity;
    vec4 final_col = mix(scene_col * (vec4(1.0) - ambient_darkness), lit_col, falloff);
    
    COLOR = final_col;
}
```

---

## 5. Verification & Acceptance Criteria
- [ ] No placeholder solid color rectangles remain on the desk surface.
- [ ] The Red Telephone shakes and lights up smoothly upon incoming calls without clipping its bounding box.
- [ ] The Brass Bell demonstrates crisp tactile squash/stretch feedback upon interaction.
- [ ] Steam particles from the espresso cup do not impact frame rate (under 0.2ms GPU cost).
- [ ] Shaders render properly under `GL Compatibility` mode without compilation warnings.
