# Modular Specification 07: Menus, Modal Windows, and Narrative Epilogues

## Executive Technical Summary
Narrative impact in "Yes, Mr. Mayor!" depends heavily on the framing of choices and consequences. The game currently implements critical narrative transitions—such as the Main Menu (`MainMenu.tscn`), Morning Briefing (`MorningBriefingCard.tscn`), Rulebook (`Rulebook.tscn`), Offshore Ledger (`OffshoreLedgerModal.tscn`), Press Conferences (`PressConferenceModal.tscn`), and Endings (`GameOverModal.tscn`)—using standard grey containers and flat rectangular buttons. This document specifies the visual overhaul of these interfaces into thematic, tactile artifacts (newspaper front pages, leather-bound municipal codebooks, confidential filing cabinets, and live television press conferences).

---

## 1. Technical Context & Affected Scenes
- **Main Menu**: `res://scenes/menu/MainMenu.tscn`
- **Rulebook**: `res://scenes/desk/Rulebook.tscn`
- **Morning Briefing**: `res://scenes/ui/MorningBriefingCard.tscn`
- **Offshore Ledger**: `res://scenes/ui/OffshoreLedgerModal.tscn`
- **Press Conference**: `res://scenes/summary/PressConferenceModal.tscn`
- **Day End & Endings**:
  - `res://scenes/summary/DayEndSummary.tscn`
  - `res://scenes/summary/MayoralReportCardModal.tscn`
  - `res://scenes/summary/GameOverModal.tscn`
  - `res://scenes/summary/ElectionNightModal.tscn`
- **Settings & Saves**:
  - `res://scenes/ui/SettingsModal.tscn`
  - `res://scenes/ui/SaveLoadModal.tscn`
  - `res://scenes/ui/PauseMenu.tscn`

---

## 2. Scene-Specific Architectural Modernization

### 2.1. Cinematic Main Menu (`MainMenu.tscn`)
Replace the current geometric backdrop (`StyleBoxFlat_sky_horizon` and building blocks) with an atmospheric establishing shot:
1. **Background Art**:
   - High-rise panoramic perspective of the metropolis at dusk.
   - Rain streaking down the panoramic glass with distant amber and neon skyscraper lights.
2. **Foreground Office**:
   - The mayoral desk viewed in dramatic chiaroscuro silhouette.
   - An unoccupied leather executive chair, steaming coffee cup, and the glowing red telephone.
3. **Menu Navigation**:
   - Gold-embossed mayoral seal (`seal_mayoral_crest_gold.png`) at top center.
   - Buttons styled as official executive folders with crisp hover lighting and tactile mechanical clicks.

### 2.2. Morning Briefing Newspaper (`MorningBriefingCard.tscn`)
Reconstruct the morning briefing card into an authentic morning broadsheet newspaper (*The Daily Metropolitan*):
1. **Paper Canvas**:
   - Newsprint paper texture with off-white/gray tone, folding creases, and ink smudge details.
2. **Typography & Layout**:
   - Classic blackletter newspaper masthead (*The Daily Gazette* / *The Metropolitan Post*).
   - Multi-column layout with bold headlines and lead paragraphs detailing player actions from the prior day.
   - Halftone black-and-white press photograph illustrating the primary crisis (e.g., strikes, factory opening, or ribbon-cutting).
3. **Halftone Newspaper Shader**:
   - Apply `res://assets/shaders/newspaper_halftone.gdshader` to images to create genuine dot-matrix printing aesthetics.

### 2.3. The Municipal Rulebook (`Rulebook.tscn`)
Transform the current dark rectangle into a tangible, leather-bound hardback tome:
1. **Cover & Binding**:
   - Embossed burgundy/navy leather cover with gilded municipal crest and metal corner protectors.
   - Ribbon page marker resting between pages.
2. **Interior Pages & Tabs**:
   - Aged parchment paper with double-page spread.
   - Colored index tabs on the right margin (Zoning, Police, Health, Directives, Factions) that slide slightly outwards when hovered.
   - Handwritten margin notes in red ink annotating regulatory loopholes and mayoral privileges.

### 2.4. The Offshore Bribe Ledger (`OffshoreLedgerModal.tscn`)
Replace standard modal panels with a secret Swiss bank ledger:
1. **Visual Style**:
   - Black goatskin pocket ledger with gold foil serial number.
   - Marbleized endpapers and fountain pen calligraphy entries.
   - Stash compartment showing stacks of hundred-dollar bills and Cayman Island bearer bonds.

### 2.5. Press Conference & Election Night (`PressConferenceModal.tscn`, `ElectionNightModal.tscn`)
1. **Live Broadcast Presentation**:
   - Camera lens CRT overlay with subtle scanlines and chromatic aberration.
   - Lectern with forest of branded microphones (WMAY News, Channel 7, Daily Tribune).
   - Reporter flashbulb particles (`GPUParticles2D`) creating burst flashes during controversial answers.
2. **Reporter Sentiment Dials**:
   - Hostile vs. Friendly press meters showing journalist approval in real-time.

---

## 3. Newspaper Halftone Shader Implementation

Create `res://assets/shaders/newspaper_halftone.gdshader`:
```glsl
shader_type canvas_item;

uniform float dot_density = 120.0;
uniform float contrast = 1.25;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    float luma = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
    luma = pow(luma, contrast);
    
    vec2 grid_uv = fract(UV * dot_density) - vec2(0.5);
    float dist = length(grid_uv);
    
    float radius = sqrt(1.0 - luma) * 0.55;
    float dot_val = smoothstep(radius, radius - 0.08, dist);
    
    vec3 paper_tone = vec3(0.92, 0.89, 0.82);
    vec3 ink_tone = vec3(0.12, 0.11, 0.13);
    
    COLOR = vec4(mix(paper_tone, ink_tone, dot_val), tex.a);
}
```

---

## 4. Verification & Acceptance Criteria
- [ ] Main Menu feels atmospheric and cinematic, instantly establishing a serious political drama tone.
- [ ] Morning briefings look like genuine vintage newspapers with readable headlines and authentic halftone photos.
- [ ] The Municipal Rulebook presents as a tangible physical book with working tab animations.
- [ ] Press Conference modals produce believable camera flashes and television broadcast framing.
- [ ] No generic modal popups remain in the game flow.
