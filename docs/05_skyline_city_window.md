# Modular Specification 05: Skyline City Window & Parallax Atmosphere

## Executive Technical Summary
The panoramic window behind the mayoral desk in `res://scenes/desk/SkylineView.tscn` connects the mayor's micro-decisions at the desk with the macro-reality of the city outside. Currently, the city skyline is rendered using primitive geometric `StyleBoxFlat` rectangles (`StyleBoxFlat_concrete_towers`, `StyleBoxFlat_luxury_towers`, and `StyleBoxFlat_historic_clock`). This document outlines the technical transition to an atmospheric multi-layer parallax city panorama featuring dynamic time-of-day sky gradients, reactive architectural landmarks, particle-driven smog and weather, working municipal clock towers, and a glass-surface rain shader.

---

## 1. Technical Context & Affected Scenes
- **Primary Scene**: `res://scenes/desk/SkylineView.tscn`
- **Primary Scripts**:
  - `res://scripts/desk/SkylineView.gd`
  - `res://scripts/desk/PoliceFlasher.gd`
- **Associated Assets**:
  - `res://assets/sprites/skyline/`
  - `res://assets/shaders/sky_gradient.gdshader`
  - `res://assets/shaders/window_rain.gdshader`
  - `res://assets/shaders/window_lights_twinkle.gdshader`

---

## 2. Multi-Layer Window Visual Pipeline

The window in `SkylineView.tscn` (1920x340 viewport area) must be restructured into distinct depth layers:

```
SkylineView (Control, 1920x340, Clip Children enabled)
├── Layer0_SkyDome (ColorRect with sky_gradient shader)
│   ├── CelestialBody (Sprite2D, Sun / Moon / Smog orb)
│   └── CloudLayer (Parallax2D / CanvasItem moving cloud silhouettes)
├── Layer1_FarSkyline (TextureRect, distant mountain & skyscraper silhouettes)
│   └── WindowLightsShader (Randomized subtle window flickering)
├── Layer2_MidgroundDistricts (Node2D, modular district landmarks)
│   ├── HistoricClockTower (Sprite2D with rotating minute/hour hands)
│   ├── IndustrialSmokestacks (Sprite2D with GPUParticles2D smoke plumes)
│   ├── LuxuryCondoTowers (Dynamic visibility based on Oligarch decisions)
│   ├── MunicipalParkTrees (Sprite2D canopy, reacting to deforestation decisions)
│   └── MonumentSlot (Dino statue, Mayoral monolith, or empty plinth)
├── Layer3_TrafficArtery (Control, street level light streams)
│   ├── HeadlightParticles (GPUParticles2D moving rightwards, warm white)
│   ├── TaillightParticles (GPUParticles2D moving leftwards, ruby red)
│   └── PoliceEmergencyFlasher (PoliceFlasher.gd with radial gradient light blooms)
├── Layer4_WeatherAndCrisisFX (Control)
│   ├── SmogOverlay (Volumetric fog density driven by industrial decisions)
│   ├── RiotSmokeColumns (Black billowing smoke during civil unrest)
│   └── ElectionFireworks (Celebratory bursts on Day 10 victory)
└── Layer5_WindowGlassAndFrame (TextureRect, foreground boundary)
    ├── WindowRainOverlay (ColorRect with window_rain shader)
    ├── GlassDirtAndScratches (Subtle grime texture)
    └── ArchitecturalWindowMullions (Heavy mahogany window frame with bevels)
```

---

## 3. Dynamic Visual States & Landmark System

In `SkylineView.gd`, landmarks toggle and transform based on game events and faction standings:

### 3.1. The Historic Municipal Clock Tower
- Replace `StyleBoxFlat_historic_clock` with high-detail Romanesque clock tower sprite: `res://assets/sprites/skyline/landmark_clock_tower.png`.
- Add two child `Sprite2D` nodes for the clock hands (`clock_hand_hour.png`, `clock_hand_minute.png`).
- Connect rotation to `DeskView.gd` shift minutes (`current_shift_minutes`):
  ```gdscript
  func update_clock_visual(minutes_since_midnight: int) -> void:
      var hours: float = float(minutes_since_midnight) / 60.0
      var mins: float = float(minutes_since_midnight % 60)
      hour_hand.rotation = deg_to_rad(hours * 30.0)
      minute_hand.rotation = deg_to_rad(mins * 6.0)
  ```

### 3.2. Industrial Smog vs. Luxury Metropolis
- **Heavy Industry State**:
  - `landmark_factory_stacks.png` activated.
  - Smoke particle rate scales with industrial directives.
  - Layer 4 smog density increases, tinting the sky sickly amber/gray.
- **Oligarch Luxury State**:
  - `landmark_luxury_towers.png` (gilded glass skyscrapers) appears when oligarch influence > 70.
  - Penthouse helipads and neon corporate logos illuminate at dusk.
- **Civil Unrest / Riots**:
  - When approval < 25 or riots trigger, spawn `res://assets/sprites/skyline/fx_smoke_billow.png` over low-income districts.
  - `PoliceFlasher.gd` activates rotating red/blue light blooms reflecting onto the window mullions.

---

## 4. Atmospheric Shaders

### 4.1. Dynamic Sky Dome Gradient Shader
Create `res://assets/shaders/sky_gradient.gdshader`:
Transitions smoothly between morning (09:00), noon (12:00), sunset (17:00), and overtime night (18:00+).
```glsl
shader_type canvas_item;

uniform vec4 zenith_color : source_color;
uniform vec4 horizon_color : source_color;
uniform vec4 pollution_tint : source_color = vec4(0.8, 0.6, 0.4, 0.0);
uniform float pollution_amount : hint_range(0.0, 1.0) = 0.2;

void fragment() {
    float y = 1.0 - UV.y;
    vec4 base_sky = mix(horizon_color, zenith_color, smoothstep(0.0, 1.0, y));
    vec4 polluted_sky = mix(base_sky, pollution_tint, pollution_amount * (1.0 - y * 0.5));
    COLOR = polluted_sky;
}
```

### 4.2. Rain Droplets on Glass Shader
Create `res://assets/shaders/window_rain.gdshader`:
Generates animated procedural rain streaks and droplet distortions on the window pane during storm events.
```glsl
shader_type canvas_item;

uniform float rain_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float rain_speed = 1.2;

void fragment() {
    if (rain_intensity <= 0.01) {
        COLOR = vec4(0.0);
        return;
    }
    
    vec2 uv = UV * vec2(30.0, 10.0);
    uv.y += TIME * rain_speed;
    
    float drop = fract(sin(dot(floor(uv), vec2(12.9898, 78.233))) * 43758.5453);
    float streak = smoothstep(0.85, 0.95, drop) * smoothstep(0.0, 0.1, fract(uv.y));
    
    vec4 water_tint = vec4(0.9, 0.95, 1.0, 0.25 * rain_intensity * streak);
    COLOR = water_tint;
}
```

---

## 5. Verification & Acceptance Criteria
- [ ] No primitive flat-color rectangles are visible through the mayor's office window.
- [ ] The clock tower hands rotate synchronously with in-game shift hours.
- [ ] The sky gradient smoothly transitions as shift time progresses from 09:00 AM to overtime.
- [ ] Emergency flashers and riot smoke properly respond to game crisis states without clipping the window frame.
- [ ] Frame rate remains locked at 60 FPS under `GL Compatibility` mode during active rain and particle emissions.
