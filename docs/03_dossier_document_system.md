# Modular Specification 03: Dossier & Document Item Visual Architecture

## Executive Technical Summary
The core gameplay of "Yes, Mr. Mayor!" centers on inspecting dossiers, spotting bureaucratic discrepancies, reading departmental petitions, and rendering verdicts. In the existing code (`scenes/desk/DocumentItem.tscn`), documents are represented as uniform off-white `StyleBoxFlat` panels with rudimentary text boxes, flat status badges, and basic button tabs. This specification outlines the complete visual redesign of the dossier system into a tangible, authentic multi-layered paperwork simulator with distressed parchment textures, departmental emblems, physical paperclips, forensic magnifying overlays, and a dynamic UV fluorescence shader.

---

## 1. Technical Context & Affected Files
- **Primary Scene**: `res://scenes/desk/DocumentItem.tscn`
- **Primary Script**: `res://scripts/desk/DocumentItem.gd`
- **Dependencies**:
  - `res://scripts/desk/DeskView.gd` (Dossier spawning and drag handling)
  - `res://assets/sprites/documents/`
  - `res://assets/shaders/uv_blacklight.gdshader`
  - `res://assets/shaders/magnifying_glass.gdshader`

---

## 2. Dossier Visual Anatomy & Layer Structure

The modernized `DocumentItem` hierarchy requires dedicated visual sub-layers to replicate realistic paper behavior:

```
DocumentItem (Control, 680x880, Transform pivot centered)
├── PaperShadow (TextureRect, soft directional shadow offset downwards)
├── FolderBase (NinePatchRect, manila cardstock backing with tabbed edges)
├── PaperSheet (NinePatchRect / TextureRect, authentic fiber parchment)
│   ├── EdgeWearOverlay (TextureRect, subtle dog-eared corners, frayed rim)
│   ├── StainsOverlay (TextureRect, randomized coffee ring, faint ink smudge)
│   ├── DepartmentalHeader (HBoxContainer)
│   │   ├── DepartmentCrest (TextureRect, 80x80 metallic or engraved stamp)
│   │   ├── CityMottoBanner (Label with Cinzel-Bold)
│   │   └── DocumentSerialBox (Label with monospaced typewriter font)
│   ├── PaperClipProp (TextureRect, metallic paperclip fastening supplemental notes)
│   ├── ContentContainer (VBoxContainer, margins 32px)
│   │   ├── DecreeTitle (Label with SpecialElite-Regular)
│   │   ├── PetitionerBioRow (HBoxContainer with portrait photo & thumbprint)
│   │   ├── CaseBodyRichText (RichTextLabel styled with typewriter BBCode)
│   │   └── FinancialImpactRow (Engraved accounting tabular ledger)
│   ├── DiscrepancyHighlights (Control, custom draw lines with red china marker)
│   └── StampImpressionLayer (Control, receiving stamp textures with blend modes)
├── BribeEnvelopeUnderlay (Control, semi-exposed brown envelope containing cash)
└── UVFluorescenceLayer (CanvasItem with uv_blacklight shader)
```

---

## 3. High-Fidelity Asset Specifications

### 3.1. Parchment & Manila Folder Textures
1. `res://assets/sprites/documents/paper_parchment_base.png` (720x940):
   - High-resolution scanned paper texture with fiber grain, slightly yellowed edges, and 9-patch border slices (margins: 32px).
2. `res://assets/sprites/documents/folder_manila_backing.png`:
   - Heavyweight manila cardstock with labeled departmental index tabs (e.g., *ZONING*, *TREASURY*, *POLICE*, *CONFIDENTIAL*).
3. `res://assets/sprites/documents/paperclip_metal.png` (48x96):
   - Bent silver paperclip casting a crisp contact shadow across the top-right edge.

### 3.2. Departmental Crests & Emblems (80x80 PNG with transparency)
Provide authentic governmental seals for each city department:
- `crest_sanitation.png`: Crossed broom and gear in industrial green.
- `crest_police.png`: Star crest with balancing scales in midnight navy.
- `crest_treasury.png`: Cornucopia and coins in burnished bronze.
- `crest_housing.png`: Tenement silhouettes enclosed in an architectural pediment.
- `crest_oligarch.png`: Golden eagle clutching an offshore bond certificate.

### 3.3. Petitioner Portraits & Thumbprints
- Replace empty avatar rectangles with distressed monochrome passport-style photographs (100x120) with staple punctures on top and biometric fingerprint ink stamps on bottom.

---

## 4. Forensic Inspection & Shader Mechanics

### 4.1. UV Blacklight Fluorescence Shader
When `btn_toggle_uv` (Hotkey: `U`) is toggled in `DeskView.gd`, a UV inspection light activates. This reveals invisible ink markings, secret oligarch bribes, altered dates, or counterfeit seals.

Create `res://assets/shaders/uv_blacklight.gdshader`:
```glsl
shader_type canvas_item;

uniform bool uv_active = false;
uniform sampler2D secret_mask_texture : hint_default_black;
uniform vec4 glow_color : source_color = vec4(0.0, 0.94, 1.0, 1.0);
uniform float flicker_speed = 8.0;

void fragment() {
    vec4 base_color = texture(TEXTURE, UV);
    
    if (!uv_active) {
        COLOR = base_color;
    } else {
        // Darken regular paper to deep purple/blacklight tone
        vec4 blacklight_tone = base_color * vec4(0.18, 0.14, 0.32, 1.0);
        
        // Sample hidden fluorescent mask
        vec4 mask = texture(secret_mask_texture, UV);
        float pulse = 0.9 + 0.1 * sin(TIME * flicker_speed);
        vec4 fluorescent_emission = mask.r * glow_color * pulse * 2.2;
        
        COLOR = blacklight_tone + fluorescent_emission;
    }
}
```

### 4.2. Discrepancy Red Pen Markup
In `DocumentItem.gd`, when an inquiry or discrepancy is detected:
- Do not render generic yellow selection boxes.
- Draw naturalistic hand-drawn red pencil loops or underlines using `Line2D` with antialiasing and variable line width (`width_curve`), tinted `#B22222`.

---

## 5. Physical Document Dragging & Inertia

Upgrade document drag-and-drop feedback in `DocumentItem.gd`:
1. **Lift Animation**:
   - On `mouse_down` / drag start: Scale paper smoothly from `1.0` to `1.03` over 0.12s.
   - Expand `PaperShadow` blur and offset (Y offset increases from 8px to 28px).
2. **Dynamic Tilt / Inertia**:
   - Compute cursor velocity: `var vel = (event.position - prev_pos) / delta`.
   - Apply slight rotational tilt proportional to horizontal velocity: `rotation = clamp(vel.x * 0.0008, -0.08, 0.08)`.
   - On release: Snap rotation back to rest angle with slight randomized desk tilt (`randf_range(-0.02, 0.02)` rad).

---

## 6. Verification & Acceptance Criteria
- [ ] Dossier papers exhibit realistic paper fiber texture, aged borders, and no flat solid panels.
- [ ] Toggling UV inspection immediately shifts document presentation to ultraviolet tone and reveals glowing fluorescent cues.
- [ ] Dragging documents across the desk produces smooth rotational tilt and dynamic shadow scaling without stuttering.
- [ ] Departmental crests are crisp and properly scaled without blurring or pixelation.
- [ ] Document text remains 100% readable with high contrast against the textured paper background.
