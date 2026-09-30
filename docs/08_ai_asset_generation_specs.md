# Modular Specification 08: AI Asset Generation Pipeline & Catalog

## Executive Technical Summary
This document provides the exact catalog, prompt engineering specifications, aspect ratios, target resolutions, and post-processing instructions for generating all visual assets required by the modernization initiative. AI agents tasked with asset creation must follow these deterministic prompts and import settings to ensure stylistic consistency (1970s–1980s bureaucratic retro-noir political thriller aesthetic) and seamless integration into Godot 4.

---

## 1. Global Art Style & Prompting Directives

### Art Direction Guidelines
- **Core Aesthetic**: Retro-political bureaucratic noir (influence: *Papers, Please*, *Suzerain*, *Disco Elysium*, 1970s government thriller cinematography).
- **Color Temperature**: Muted tungsten ambient, rich walnut and mahogany woods, burnished brass, aged tea-stained paper, dark ink, cold neon city accents outside.
- **Rendering Style**: Detailed 2.5D illustrated realism with subtle surface imperfections (scratches, dust, coffee rings, paper grain). Avoid hyper-glossy fantasy art, anime tropes, or futuristic sci-fi elements.
- **Negative Prompt Keywords**: `cartoon, anime, 3d render plastic, low resolution, flat vector, modern glass office, futuristic, neon fantasy, blurry, distorted text`.

---

## 2. Comprehensive Asset Catalog & Prompts

### Category A: Desk Surface & Base Environment (`assets/sprites/desk/`)

| Filename | Aspect Ratio | Resolution | Prompt Specification |
| :--- | :--- | :--- | :--- |
| `desk_mahogany_surface.png` | 16:9 | 1920x820 | `Top-down angled view of an executive vintage mahogany wood desk surface, rich dark wood grain, polished lacquer finish, subtle worn scratches, warm lighting, seamless horizontal texture.` |
| `blotter_leather_9patch.png` | 1:1 | 512x512 | `Overhead view of vintage dark navy leather desk blotter pad, fine leather texture, subtle edge stitching, gold leaf embossed borders, clean centered area for nine patch scaling.` |
| `brass_corner_clamp.png` | 1:1 | 256x256 | `Antique ornate brass corner protector clamp for executive desk blotter, embossed floral scrollwork, tarnished metal patina, isolated on pure white background.` |
| `office_wall_wainscoting.png` | 16:9 | 1920x400 | `Vintage mayoral office wall background, dark forest green damask wallpaper, dark walnut wainscoting wood paneling, moody atmospheric shadows.` |

---

### Category B: Interactive Desk Props (`assets/sprites/props/`)

| Filename | Aspect Ratio | Resolution | Prompt Specification |
| :--- | :--- | :--- | :--- |
| `telephone_rotary_base.png` | 1:1 | 512x512 | `Vintage 1970s red rotary telephone desk unit, heavy crimson bakelite casing, brass accents, circular chrome rotary dial numbers, top-down isometric angle, isolated on pure white background.` |
| `telephone_handset.png` | 4:3 | 512x384 | `Vintage red telephone receiver handset, ergonomic bakelite grip, coiled black wire attachment, isolated on pure white background.` |
| `bell_brass_normal.png` | 1:1 | 256x256 | `Antique polished brass reception service bell, round dome, top plunger button, cast bronze base, gleaming metallic reflections, isolated on pure white background.` |
| `shredder_chassis.png` | 4:3 | 512x384 | `Vintage industrial heavy-duty office paper shredder, matte black textured chassis, stainless steel intake slot, caution hazard stripes, power toggle switch, isolated on pure white background.` |
| `cigar_humidor_closed.png` | 4:3 | 512x384 | `Luxury Spanish cedar cigar humidor box, brass lock clasp, polished burl wood grain finish, executive desk prop, isolated on pure white background.` |
| `brochure_luxury_yacht.png` | 3:4 | 384x512 | `Glossy vintage sales brochure for a luxury Mediterranean yacht, gold foil logo, full-color ocean photograph, realistic paper fold crease, isolated on pure white background.` |
| `espresso_cup_saucer.png` | 1:1 | 256x256 | `Classic porcelain white espresso cup and saucer, filled with rich dark crema espresso, top-down angled perspective, isolated on pure white background.` |
| `stamp_rack_brass.png` | 16:9 | 640x360 | `Vintage cast bronze desk stamp holder stand with three carved resting slots, ornate Victorian scrollwork, built-in metal ink pad wells, isolated on pure white background.` |
| `stamp_handle_approve.png` | 3:4 | 384x512 | `Vintage turned mahogany wood rubber stamp handle, polished brass ferrule collar, emerald green enameled ring, rubber base with municipal crest, isolated on pure white background.` |
| `stamp_handle_reject.png` | 3:4 | 384x512 | `Vintage turned dark ebony wood rubber stamp handle, blackened iron collar, oxblood red enameled ring, heavy rubber base, isolated on pure white background.` |
| `stamp_handle_bribe.png` | 3:4 | 384x512 | `Opulent black lacquer and 24k gold leaf turned executive rubber stamp handle, ornate filigree engraving, heavy luxury desk tool, isolated on pure white background.` |

---

### Category C: Documents & Bureaucratic Paperwork (`assets/sprites/documents/`)

| Filename | Aspect Ratio | Resolution | Prompt Specification |
| :--- | :--- | :--- | :--- |
| `paper_parchment_base.png` | 3:4 | 768x1024 | `High resolution scan of aged governmental archival paper, subtle fiber texture, faint tea staining, rough deckled edges, blank central canvas for nine patch slicing, isolated on white background.` |
| `folder_manila_backing.png` | 3:4 | 800x1060 | `Heavyweight vintage manila legal dossier folder, top tab with red stamped CONFIDENTIAL watermark, metal binding prongs, subtle grease stains, isolated on pure white background.` |
| `paperclip_metal.png` | 1:1 | 256x256 | `Single metallic steel wire paperclip, realistic chrome reflection, casting faint drop shadow on white background.` |
| `stamp_decal_approve.png` | 1:1 | 512x512 | `Circular official governmental stamp imprint in faded emerald green ink, weathered rubber stamp texture, text 'APPROVED - OFFICE OF THE MAYOR' with central city crest, isolated on pure white background.` |
| `stamp_decal_reject.png` | 1:1 | 512x512 | `Bold rectangular bureaucratic stamp imprint in distressed red ink, text 'DENIED - MUNICIPAL DISAPPROVAL' with official serial number, ink bleed texture, isolated on pure white background.` |
| `stamp_decal_bribe.png` | 1:1 | 512x512 | `Secret gilded official monogram stamp in black and metallic gold ink, double eagle crest with ribbon, covert clearance seal, isolated on pure white background.` |

---

### Category D: Skyline City Panorama (`assets/sprites/skyline/`)

| Filename | Aspect Ratio | Resolution | Prompt Specification |
| :--- | :--- | :--- | :--- |
| `skyline_far_silhouette.png` | 16:9 | 1920x600 | `Atmospheric silhouette of a dense 1970s coastal metropolis skyline, varying skyscraper heights, distant hazy mountains, evening dusk sky, isolated against transparent background.` |
| `landmark_clock_tower.png` | 1:1 | 512x512 | `Historic Romanesque stone clock tower building, copper green spires, ornate clock face, architectural elevation illustration, isolated on pure white background.` |
| `landmark_factory_stacks.png` | 4:3 | 512x384 | `Heavy industrial brick factory smokestacks, iron catwalks, gritty retro urban industrial architecture, isolated on pure white background.` |
| `landmark_luxury_towers.png` | 3:4 | 384x512 | `Modernist high-rise glass luxury condominium towers, penthouse balconies, rooftop swimming pool, sleek capitalist architecture, isolated on pure white background.` |
| `window_mullion_frame.png` | 16:9 | 1920x360 | `Interior architectural window frame of an executive mayoral office, dark mahogany wood mullions, brass bevel joints, framing glass panes, cut out center for transparency.` |

---

## 3. Post-Processing & Godot 4 Import Rules

When assets are generated, the following automated pipeline steps must be executed:
1. **Background Removal**:
   - Assets generated with pure white backgrounds must have the white matte converted to transparent alpha channels (`RGBA8`).
2. **Godot Texture Import Parameters (`.import`)**:
   - For UI elements and icons: Set `compress/mode` to `Lossless` and disable mipmaps (`mipmaps/generate = false`) to ensure pixel-sharp UI rendering.
   - For desk surfaces and skyline backgrounds: Set `compress/mode` to `VRAM Compressed` (or `Lossy` for mobile) with `mipmaps/generate = true`.
   - Set texture filter to `Linear` for UI and `Linear Mipmap` for panoramic scenes.
3. **NinePatch Rect Margin Calibration**:
   - For paper and folder frames, define strict inner slicing margins (e.g. Left: 32, Top: 32, Right: 32, Bottom: 32) so text layouts scale dynamically across resolutions without corner distortion.

---

## 4. Verification & Acceptance Criteria
- [ ] Every generated asset conforms to the retro-bureaucratic color palette and visual tone.
- [ ] Transparent PNGs contain clean alpha channels without white halo fringes or jagged edges.
- [ ] Aspect ratios and dimensions strictly adhere to target slot sizes in `.tscn` files.
- [ ] Godot imports all generated assets without VRAM compression artifacts or texture format errors.
