# Modular Specification 01: Design System, Typography, and Global Theming

## Executive Technical Summary
This document specifies the architectural foundation for overhauling the visual presentation of "Yes, Mr. Mayor!". The current implementation relies entirely on untextured, procedural `StyleBoxFlat` instances with hardcoded RGB values, flat solid borders, and default fallback system fonts. This phase establishes a unified bureaucratic-noir design system, introduces dedicated retro-governmental typography, creates shared theme resources (`.tres`), and establishes NinePatchRect slice conventions to be consumed across all UI scenes.

---

## 1. Technical Context & Engine Constraints
- **Target Engine**: Godot Engine 4.x (`4.7` branch).
- **Renderer**: `GL Compatibility` (Mobile / Web / Low-spec desktop profile).
- **Target Viewport**: 1920x1080 (`window/stretch/mode="canvas_items"`, `aspect="keep"`).
- **Font Directory**: `res://assets/fonts/`
- **Theme Directory**: `res://resources/themes/`
- **UI Slice Directory**: `res://assets/sprites/ui/slices/`

---

## 2. Core Color Palette Tokens & Visual Identity

| Token Name | Hex Code | Visual Application | Technical Target |
| :--- | :--- | :--- | :--- |
| `PALETTE_WOOD_DARK` | `#1A110B` | Deep walnut desk background, outer casing frames | `DeskView.tscn` desk background |
| `PALETTE_WOOD_MID` | `#331E14` | Rich mahogany desk surface, wooden shelf elements | Blotter borders, shelf trims |
| `PALETTE_LEATHER_NAVY` | `#141A24` | Bureaucratic blotter leather, executive folder bindings | Central desk blotter, rulebook cover |
| `PALETTE_PARCHMENT` | `#F4EBD9` | Official municipal paperwork, dossier background | `DocumentItem.tscn` paper base |
| `PALETTE_PARCHMENT_DIRT` | `#D9CCA7` | Aged legal paper, coffee-stained carbon copies | Inspection cards, violation reports |
| `PALETTE_INK_BLACK` | `#1E1F22` | Typewriter text, official print, rubber stamp ink | Document labels, descriptions |
| `PALETTE_BRASS_GOLD` | `#D4AF37` | Desk fittings, drawer handles, official seal borders | Prop accents, stamp handles, trims |
| `PALETTE_GOV_GREEN` | `#2D6A4F` | Approval ink, municipal surplus, safe indicators | Stamp Approve, positive stat deltas |
| `PALETTE_STAMP_RED` | `#A61C1C` | Rejection ink, violation warnings, emergency phone | Stamp Reject, hotline phone, alerts |
| `PALETTE_BRIBE_GOLD` | `#C8963E` | Kickback indicators, gold leaf insignias, offshore | Bribe envelopes, offshore ledger |
| `PALETTE_UV_CYAN` | `#00F0FF` | Hidden fluorescent markings, counterfeit watermarks | UV blacklight revelation shader |

---

## 3. Typography Architecture & Font Assets

### Required Font Files
All fonts must be downloaded or generated as open-source OFL `.ttf` or `.otf` assets and placed in `res://assets/fonts/`:
1. `SpecialElite-Regular.ttf` (or equivalent distressed typewriter monospace):
   - **Role**: Primary document body, memos, event descriptions, typewriter stamps.
   - **Path**: `res://assets/fonts/SpecialElite-Regular.ttf`
2. `Cinzel-Bold.ttf` (or equivalent classical governmental serif):
   - **Role**: Mayoral decree titles, city department crests, modal headings, seal text.
   - **Path**: `res://assets/fonts/Cinzel-Bold.ttf`
3. `Inter-Medium.ttf` & `Inter-Bold.ttf` (clean modern legible grotesque sans):
   - **Role**: HUD metrics, numeric counters, button actions, keycap tooltips, settings sliders.
   - **Path**: `res://assets/fonts/Inter-Medium.ttf`, `res://assets/fonts/Inter-Bold.ttf`

---

## 4. Phase-by-Phase Implementation Plan

### Phase 1: Directory Scaffolding & Font Ingestion
1. Create directory paths:
   - `res://assets/fonts/`
   - `res://assets/sprites/ui/slices/`
   - `res://assets/sprites/ui/icons/`
   - `res://resources/themes/`
2. Verify font import configurations in Godot:
   - Set subpixel positioning to `Auto`.
   - Set hinting to `Normal`.
   - Ensure antialiasing is enabled with `LCD Subpixel` or `Grayscale`.

### Phase 2: Theme Resource Generation (`mayoral_theme.tres`)
Create `res://resources/themes/mayoral_theme.tres` with the following configuration:
1. **Default Font**: Set to `res://assets/fonts/Inter-Medium.ttf` at size 16.
2. **Button Styles**:
   - `normal`: NinePatch StyleBox (`res://assets/sprites/ui/slices/btn_brass_normal.png`) with 6px margins, modulation `#D4AF37`.
   - `hover`: NinePatch StyleBox (`res://assets/sprites/ui/slices/btn_brass_hover.png`) with inner golden glow.
   - `pressed`: NinePatch StyleBox (`res://assets/sprites/ui/slices/btn_brass_pressed.png`) with 2px vertical offset.
   - `disabled`: Muted charcoal tone `#25272C` with lowered opacity (0.5).
3. **PanelContainer Styles**:
   - `panel_parchment`: NinePatch StyleBox (`res://assets/sprites/ui/slices/panel_parchment_9patch.png`) with 12px margins.
   - `panel_dark_leather`: NinePatch StyleBox (`res://assets/sprites/ui/slices/panel_leather_9patch.png`) with brass rivet corners.
   - `panel_modal_frame`: Heavy bevel border with outer dropshadow (32px radius, 40% black).
4. **Label Configurations**:
   - Type `LabelTypewriter`: Font `SpecialElite-Regular.ttf`, size 15, font_color `#1E1F22`.
   - Type `LabelDecreeHeader`: Font `Cinzel-Bold.ttf`, size 22, font_color `#1A110B`.
   - Type `LabelHUDValue`: Font `Inter-Bold.ttf`, size 18, font_color `#F4EBD9`.

### Phase 3: Project-Wide Default Theme Assignment
1. Open `project.godot`.
2. Under `[gui]`, configure:
   ```ini
   [gui]
   theme/custom="res://resources/themes/mayoral_theme.tres"
   theme/custom_font="res://assets/fonts/Inter-Medium.ttf"
   ```
3. Ensure backward compatibility: scenes with inline `override_styles` must be systematically upgraded to use Theme Types rather than scattered inline `StyleBoxFlat` instances.

---

## 5. Verification & Acceptance Criteria
- [ ] No raw system fallback fonts (e.g. Arial, Liberation Sans default) appear anywhere in the interface.
- [ ] Resizing the game window maintains crisp font rasterization and proper NinePatch border scaling without edge distortion.
- [ ] `mayoral_theme.tres` opens in Godot Editor without missing resource warnings or broken UIDs.
- [ ] Color values strictly follow the defined `PALETTE_*` constants for visual harmony across scenes.
