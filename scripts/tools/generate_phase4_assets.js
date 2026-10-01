const fs = require('fs');
const path = require('path');
const sharp = require('sharp');
const crypto = require('crypto');

function ensureDir(dirPath) {
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
  }
}

async function renderSvgToPng(svgString, width, height, outputPath) {
  ensureDir(path.dirname(outputPath));
  const buf = Buffer.from(svgString);
  await sharp(buf, { density: 300 })
    .resize(width, height)
    .png()
    .toFile(outputPath);
  console.log(`Rendered: ${outputPath} (${width}x${height})`);

  // Create .import file
  const relPath = outputPath.replace(/\\/g, '/');
  const importPath = outputPath + '.import';
  const uid = 'uid://' + crypto.randomBytes(8).toString('hex');
  const importContent = `[remap]

importer="texture"
type="CompressedTexture2D"
uid="${uid}"

[deps]

source_file="res://${relPath}"

[params]

compress/mode=0
compress/high_quality=false
compress/lossy_quality=0.7
compress/uastc_level=0
compress/rdo_quality_loss=0.0
compress/hdr_compression=1
compress/normal_map=0
compress/channel_pack=0
mipmaps/generate=false
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/channel_remap/red=0
process/channel_remap/green=1
process/channel_remap/blue=2
process/channel_remap/alpha=3
process/fix_alpha_border=true
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=0
detect_3d/compress_to=1
`;
  fs.writeFileSync(importPath, importContent, 'utf8');
}

async function main() {
  console.log('Generating Phase 4 Assets...');

  // =========================================================================
  // 1. HUD ASSETS (assets/sprites/hud/)
  // =========================================================================

  // 1.1 hud_header_frame.png (1920x72 NinePatch: Mahogany & Brass Frame)
  const hudFrameSvg = `
  <svg width="1920" height="72" viewBox="0 0 1920 72" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="woodGrad" x1="0%" y1="0%" x2="0%" y2="100%">
        <stop offset="0%" stop-color="#24140E"/>
        <stop offset="25%" stop-color="#1A0D08"/>
        <stop offset="75%" stop-color="#120804"/>
        <stop offset="100%" stop-color="#0A0402"/>
      </linearGradient>
      <linearGradient id="brassBevel" x1="0%" y1="0%" x2="0%" y2="100%">
        <stop offset="0%" stop-color="#F3E5AB"/>
        <stop offset="20%" stop-color="#D4AF37"/>
        <stop offset="80%" stop-color="#AA820A"/>
        <stop offset="100%" stop-color="#553D00"/>
      </linearGradient>
      <linearGradient id="bottomTrim" x1="0%" y1="0%" x2="0%" y2="100%">
        <stop offset="0%" stop-color="#D4AF37"/>
        <stop offset="50%" stop-color="#8C6B13"/>
        <stop offset="100%" stop-color="#3D2B00"/>
      </linearGradient>
    </defs>
    <!-- Dark Wood Panel Base -->
    <rect width="1920" height="72" fill="url(#woodGrad)"/>
    <!-- Top Brass Bevel Strip -->
    <rect x="0" y="0" width="1920" height="3" fill="url(#brassBevel)"/>
    <!-- Subtle Inner Dark Bevel -->
    <rect x="0" y="3" width="1920" height="1" fill="#000000" opacity="0.6"/>
    <!-- Bottom Heavy Brass Edge Rail -->
    <rect x="0" y="68" width="1920" height="4" fill="url(#bottomTrim)"/>
    <!-- Fine Filigree Pinstripe -->
    <line x1="16" y1="65" x2="1904" y2="65" stroke="#D4AF37" stroke-width="0.8" stroke-opacity="0.3" stroke-dasharray="8,4"/>
  </svg>`;
  await renderSvgToPng(hudFrameSvg, 1920, 72, 'assets/sprites/hud/hud_header_frame.png');

  // 1.2 city_emblem_badge.png (64x64 Gold Mayoral Crest)
  const cityEmblemSvg = `
  <svg width="64" height="64" viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <radialGradient id="badgeGold" cx="50%" cy="50%" r="50%">
        <stop offset="0%" stop-color="#FFF2A3"/>
        <stop offset="45%" stop-color="#E5B83B"/>
        <stop offset="85%" stop-color="#B8860B"/>
        <stop offset="100%" stop-color="#6B4E03"/>
      </radialGradient>
      <linearGradient id="crestRing" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="#FFF"/>
        <stop offset="50%" stop-color="#D4AF37"/>
        <stop offset="100%" stop-color="#553D00"/>
      </linearGradient>
    </defs>
    <!-- Outer Gilded Ring -->
    <circle cx="32" cy="32" r="30" fill="url(#badgeGold)" stroke="url(#crestRing)" stroke-width="2.5"/>
    <circle cx="32" cy="32" r="26" fill="#1C140A" stroke="#E5B83B" stroke-width="1.2" stroke-dasharray="2,2"/>
    <!-- Star & Scales of Justice -->
    <polygon points="32,10 34,16 40,16 35,20 37,26 32,22 27,26 29,20 24,16 30,16" fill="#FFF2A3"/>
    <!-- Architectural Dome Silhouette -->
    <path d="M 22,46 L 42,46 L 42,38 Q 32,28 22,38 Z" fill="url(#badgeGold)"/>
    <rect x="20" y="46" width="24" height="3" fill="#FFF2A3"/>
    <!-- Crossed Olive Branches -->
    <path d="M 12,34 Q 18,52 32,54 Q 46,52 52,34" fill="none" stroke="#E5B83B" stroke-width="1.8" stroke-linecap="round"/>
  </svg>`;
  await renderSvgToPng(cityEmblemSvg, 64, 64, 'assets/sprites/hud/city_emblem_badge.png');

  // 1.3 coin_stack_icon.png (48x48 Gold Coin Stack)
  const coinStackSvg = `
  <svg width="48" height="48" viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="coinGold" x1="0%" y1="0%" x2="0%" y2="100%">
        <stop offset="0%" stop-color="#FFF2A3"/>
        <stop offset="40%" stop-color="#E5B83B"/>
        <stop offset="100%" stop-color="#8C6B13"/>
      </linearGradient>
    </defs>
    <!-- Base Coin 1 -->
    <ellipse cx="24" cy="38" rx="16" ry="6" fill="#6B4E03"/>
    <path d="M 8,34 L 8,38 A 16,6 0 0,0 40,38 L 40,34 Z" fill="url(#coinGold)"/>
    <ellipse cx="24" cy="34" rx="16" ry="6" fill="#FFF2A3" stroke="#8C6B13" stroke-width="0.8"/>
    <!-- Coin 2 -->
    <path d="M 8,26 L 8,30 A 16,6 0 0,0 40,30 L 40,26 Z" fill="url(#coinGold)"/>
    <ellipse cx="24" cy="26" rx="16" ry="6" fill="#FFF2A3" stroke="#8C6B13" stroke-width="0.8"/>
    <!-- Coin 3 -->
    <path d="M 8,18 L 8,22 A 16,6 0 0,0 40,22 L 40,18 Z" fill="url(#coinGold)"/>
    <ellipse cx="24" cy="18" rx="16" ry="6" fill="#FFF2A3" stroke="#8C6B13" stroke-width="0.8"/>
    <!-- Coin 4 Top with Dollar Engraving -->
    <path d="M 8,10 L 8,14 A 16,6 0 0,0 40,14 L 40,10 Z" fill="url(#coinGold)"/>
    <ellipse cx="24" cy="10" rx="16" ry="6" fill="url(#coinGold)" stroke="#FFF" stroke-width="1"/>
    <text x="24" y="14" font-family="serif" font-weight="bold" font-size="10" fill="#422E00" text-anchor="middle">$</text>
  </svg>`;
  await renderSvgToPng(coinStackSvg, 48, 48, 'assets/sprites/hud/coin_stack_icon.png');

  // 1.4 offshore_safe_icon.png (48x48 Gold Bar / Vault Box)
  const safeIconSvg = `
  <svg width="48" height="48" viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="ingotGrad" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="#FFF9DB"/>
        <stop offset="30%" stop-color="#E5B83B"/>
        <stop offset="85%" stop-color="#A67C11"/>
        <stop offset="100%" stop-color="#553D00"/>
      </linearGradient>
    </defs>
    <!-- Heavy Gold Ingot Trapezoid -->
    <polygon points="12,14 36,14 42,34 6,34" fill="url(#ingotGrad)" stroke="#FFEAA7" stroke-width="1.2"/>
    <polygon points="14,16 34,16 32,24 16,24" fill="#FFEAA7" opacity="0.4"/>
    <!-- Stamp text: 999.9 FINE GOLD -->
    <text x="24" y="30" font-family="sans-serif" font-weight="900" font-size="6.5" fill="#422E00" text-anchor="middle" letter-spacing="0.5">999.9 GOLD</text>
  </svg>`;
  await renderSvgToPng(safeIconSvg, 48, 48, 'assets/sprites/hud/offshore_safe_icon.png');

  // 1.5 dial_approval_gauge.png (140x90 Semicircular Analog Gauge Face)
  const dialSvg = `
  <svg width="140" height="90" viewBox="0 0 140 90" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="gaugeArc" x1="0%" y1="0%" x2="100%" y2="0%">
        <stop offset="0%" stop-color="#E63946"/>
        <stop offset="35%" stop-color="#F4A261"/>
        <stop offset="65%" stop-color="#E9C46A"/>
        <stop offset="100%" stop-color="#2A9D8F"/>
      </linearGradient>
      <linearGradient id="bezelMetal" x1="0%" y1="0%" x2="0%" y2="100%">
        <stop offset="0%" stop-color="#4A453A"/>
        <stop offset="50%" stop-color="#26241E"/>
        <stop offset="100%" stop-color="#14130F"/>
      </linearGradient>
    </defs>
    <!-- Heavy Brass/Iron Bezel Casing -->
    <path d="M 6,84 A 64,64 0 0,1 134,84 Z" fill="url(#bezelMetal)" stroke="#8C6B13" stroke-width="3"/>
    <!-- Gauge Inner Parchment Arc -->
    <path d="M 16,84 A 54,54 0 0,1 124,84 Z" fill="#1C1814" stroke="#4A3F28" stroke-width="1.5"/>
    <!-- Chromatic Value Arc -->
    <path d="M 24,84 A 46,46 0 0,1 116,84" fill="none" stroke="url(#gaugeArc)" stroke-width="6" stroke-linecap="round"/>
    <!-- Calibration Tick Marks -->
    <g stroke="#D4AF37" stroke-width="1.5" stroke-linecap="round">
      <line x1="28" y1="84" x2="34" y2="84"/>
      <line x1="42" y1="52" x2="47" y2="56"/>
      <line x1="70" y1="40" x2="70" y2="47"/>
      <line x1="98" y1="52" x2="93" y2="56"/>
      <line x1="112" y1="84" x2="106" y2="84"/>
    </g>
    <!-- Sub-dial percentages -->
    <text x="32" y="80" font-family="sans-serif" font-weight="bold" font-size="8" fill="#E63946">0</text>
    <text x="68" y="58" font-family="sans-serif" font-weight="bold" font-size="8" fill="#E9C46A">50</text>
    <text x="104" y="80" font-family="sans-serif" font-weight="bold" font-size="8" fill="#2A9D8F">100</text>
    <!-- Pivot Hub -->
    <circle cx="70" cy="84" r="8" fill="#D4AF37" stroke="#3D2B00" stroke-width="2"/>
    <circle cx="70" cy="84" r="4" fill="#14130F"/>
  </svg>`;
  await renderSvgToPng(dialSvg, 140, 90, 'assets/sprites/hud/dial_approval_gauge.png');

  // 1.6 gauge_needle.png (16x64 Antique Meter Needle)
  const needleSvg = `
  <svg width="16" height="64" viewBox="0 0 16 64" xmlns="http://www.w3.org/2000/svg">
    <!-- Fine Tapered Needle Pointing Up with Pivot at (8, 56) -->
    <polygon points="8,4 11,50 8,56 5,50" fill="#E63946" stroke="#8C0D17" stroke-width="1"/>
    <!-- Counterweight teardrop below pivot -->
    <circle cx="8" cy="56" r="6" fill="#D4AF37" stroke="#1A1814" stroke-width="1.5"/>
    <circle cx="8" cy="56" r="2.5" fill="#1A1814"/>
  </svg>`;
  await renderSvgToPng(needleSvg, 16, 64, 'assets/sprites/hud/gauge_needle.png');

  // 1.7 suspicion_tube_bg.png (180x28 Segmented Glass Vacuum Tube)
  const tubeBgSvg = `
  <svg width="180" height="28" viewBox="0 0 180 28" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="tubeGlass" x1="0%" y1="0%" x2="0%" y2="100%">
        <stop offset="0%" stop-color="#1E2029"/>
        <stop offset="50%" stop-color="#0F1017"/>
        <stop offset="100%" stop-color="#05060A"/>
      </linearGradient>
      <linearGradient id="brassEndCap" x1="0%" y1="0%" x2="100%" y2="0%">
        <stop offset="0%" stop-color="#D4AF37"/>
        <stop offset="50%" stop-color="#F3E5AB"/>
        <stop offset="100%" stop-color="#AA820A"/>
      </linearGradient>
    </defs>
    <!-- Left & Right Brass Collar Caps -->
    <rect x="0" y="2" width="10" height="24" rx="2" fill="url(#brassEndCap)" stroke="#423000" stroke-width="1"/>
    <rect x="170" y="2" width="10" height="24" rx="2" fill="url(#brassEndCap)" stroke="#423000" stroke-width="1"/>
    <!-- Glass Chamber Tube -->
    <rect x="8" y="4" width="164" height="20" rx="4" fill="url(#tubeGlass)" stroke="#3A4052" stroke-width="1.5"/>
    <!-- Segmented Measurement Grids -->
    <g stroke="#4A5268" stroke-width="1" stroke-dasharray="2,14">
      <line x1="24" y1="4" x2="24" y2="24"/>
      <line x1="64" y1="4" x2="64" y2="24"/>
      <line x1="104" y1="4" x2="104" y2="24"/>
      <line x1="144" y1="4" x2="144" y2="24"/>
    </g>
    <!-- Glass Specular Reflection Highlight -->
    <line x1="12" y1="7" x2="168" y2="7" stroke="#FFF" stroke-width="1" stroke-opacity="0.25"/>
  </svg>`;
  await renderSvgToPng(tubeBgSvg, 180, 28, 'assets/sprites/hud/suspicion_tube_bg.png');

  // 1.8 suspicion_tube_fill.png (180x28 Glowing Crimson Neon Fill)
  const tubeFillSvg = `
  <svg width="180" height="28" viewBox="0 0 180 28" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="neonRed" x1="0%" y1="0%" x2="0%" y2="100%">
        <stop offset="0%" stop-color="#FFA8A8"/>
        <stop offset="40%" stop-color="#E63946"/>
        <stop offset="85%" stop-color="#A8101E"/>
        <stop offset="100%" stop-color="#6B050E"/>
      </linearGradient>
    </defs>
    <!-- Internal Glowing Fluid / Neon Filament -->
    <rect x="10" y="6" width="160" height="16" rx="3" fill="url(#neonRed)"/>
    <line x1="12" y1="9" x2="168" y2="9" stroke="#FFF" stroke-width="1.5" stroke-opacity="0.6"/>
  </svg>`;
  await renderSvgToPng(tubeFillSvg, 180, 28, 'assets/sprites/hud/suspicion_tube_fill.png');

  // 1.9 Quick Action Button Icons (32x32)
  const mapIconSvg = `
  <svg width="32" height="32" viewBox="0 0 32 32" xmlns="http://www.w3.org/2000/svg">
    <polygon points="4,7 11,4 21,8 28,5 28,25 21,28 11,24 4,27" fill="#1D3557" stroke="#48CAE4" stroke-width="2" stroke-linejoin="round"/>
    <line x1="11" y1="4" x2="11" y2="24" stroke="#48CAE4" stroke-width="1.5" stroke-dasharray="2,2"/>
    <line x1="21" y1="8" x2="21" y2="28" stroke="#48CAE4" stroke-width="1.5" stroke-dasharray="2,2"/>
  </svg>`;
  await renderSvgToPng(mapIconSvg, 32, 32, 'assets/sprites/hud/icon_blueprint_map.png');

  const antennaIconSvg = `
  <svg width="32" height="32" viewBox="0 0 32 32" xmlns="http://www.w3.org/2000/svg">
    <path d="M 8,26 L 16,8 L 24,26 M 11,20 L 21,20" stroke="#9D4EDD" stroke-width="2" stroke-linecap="round" fill="none"/>
    <circle cx="16" cy="7" r="2.5" fill="#E0AAFF"/>
    <path d="M 10,6 A 8,8 0 0,1 22,6" stroke="#C77DFF" stroke-width="1.5" fill="none" stroke-linecap="round"/>
    <path d="M 6,3 A 14,14 0 0,1 26,3" stroke="#9D4EDD" stroke-width="1.5" fill="none" stroke-linecap="round"/>
  </svg>`;
  await renderSvgToPng(antennaIconSvg, 32, 32, 'assets/sprites/hud/icon_broadcast_antenna.png');

  // =========================================================================
  // 2. DISTRICT MAP BLUEPRINT ASSETS (assets/sprites/map/)
  // =========================================================================

  // 2.1 blueprint_paper_grid.png (1200x760 Cyanotype Blueprint Texture)
  const blueprintSvg = `
  <svg width="1200" height="760" viewBox="0 0 1200 760" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="cyanotypeGrad" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="#091A30"/>
        <stop offset="50%" stop-color="#0D2545"/>
        <stop offset="100%" stop-color="#061224"/>
      </linearGradient>
      <pattern id="cyanGrid" width="40" height="40" patternUnits="userSpaceOnUse">
        <path d="M 40 0 L 0 0 0 40" fill="none" stroke="#1D4E89" stroke-width="0.75" stroke-opacity="0.5"/>
        <!-- Fine sub-grid -->
        <path d="M 20 0 L 20 40 M 0 20 L 40 20" fill="none" stroke="#1D4E89" stroke-width="0.35" stroke-opacity="0.3"/>
      </pattern>
    </defs>
    <!-- Deep Prussian Blue Base -->
    <rect width="1200" height="760" fill="url(#cyanotypeGrad)"/>
    <!-- Grid Overlay -->
    <rect width="1200" height="760" fill="url(#cyanGrid)"/>
    <!-- Outer Drafting Border with Measurements -->
    <rect x="20" y="20" width="1160" height="720" fill="none" stroke="#48CAE4" stroke-width="2.5" stroke-opacity="0.8"/>
    <rect x="26" y="26" width="1148" height="708" fill="none" stroke="#48CAE4" stroke-width="1" stroke-opacity="0.4"/>
    <!-- Corner Framing Markers -->
    <g stroke="#90E0EF" stroke-width="2">
      <path d="M 16,36 L 36,36 L 36,16"/>
      <path d="M 1184,36 L 1164,36 L 1164,16"/>
      <path d="M 16,724 L 36,724 L 36,744"/>
      <path d="M 1184,724 L 1164,724 L 1164,744"/>
    </g>
    <!-- Classic Architectural Compass Rose at Bottom Right -->
    <g transform="translate(1100,660)" stroke="#90E0EF" stroke-width="1.2" fill="none">
      <circle cx="0" cy="0" r="28" stroke-dasharray="3,3"/>
      <polygon points="0,-24 5,-6 24,0 5,6 0,24 -5,6 -24,0 -5,-6" fill="#0D2545" stroke="#48CAE4" stroke-width="1.5"/>
      <polygon points="0,-24 0,0 -5,-6" fill="#90E0EF"/>
      <polygon points="24,0 0,0 5,6" fill="#90E0EF"/>
      <polygon points="0,24 0,0 5,6" fill="#90E0EF"/>
      <polygon points="-24,0 0,0 -5,-6" fill="#90E0EF"/>
      <text x="0" y="-28" font-family="monospace" font-weight="bold" font-size="10" fill="#90E0EF" text-anchor="middle">N</text>
    </g>
    <!-- Technical Archive Stamp Box at Bottom Left -->
    <g transform="translate(45,660)">
      <rect x="0" y="0" width="280" height="55" fill="#061224" stroke="#48CAE4" stroke-width="1.5"/>
      <text x="10" y="16" font-family="monospace" font-weight="bold" font-size="10" fill="#CAF0F8">MUNICIPAL SURVEY OFFICE</text>
      <text x="10" y="32" font-family="monospace" font-size="8" fill="#90E0EF">SERIES 1978-B • SCALE: 1:25,000</text>
      <text x="10" y="46" font-family="monospace" font-size="8" fill="#00B4D8">CLASSIFICATION: MAYORAL EXECUTIVE</text>
    </g>
    <!-- River Winding Through Metropolis (Stylized Contour Wave) -->
    <path d="M 280,24 Q 450,220 380,420 T 520,736" fill="none" stroke="#0077B6" stroke-width="26" stroke-linecap="round" stroke-opacity="0.4"/>
    <path d="M 280,24 Q 450,220 380,420 T 520,736" fill="none" stroke="#48CAE4" stroke-width="2" stroke-opacity="0.6" stroke-dasharray="12,6"/>
  </svg>`;
  await renderSvgToPng(blueprintSvg, 1200, 760, 'assets/sprites/map/blueprint_paper_grid.png');

  // 2.2 District Vector Badges (64x64 PNG)
  const dCentralSvg = `
  <svg width="64" height="64" viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg">
    <circle cx="32" cy="32" r="30" fill="#0D2545" stroke="#48CAE4" stroke-width="2"/>
    <path d="M 18,48 L 46,48 L 46,30 L 32,16 L 18,30 Z" fill="#48CAE4" opacity="0.8"/>
    <rect x="28" y="36" width="8" height="12" fill="#0D2545"/>
  </svg>`;
  await renderSvgToPng(dCentralSvg, 64, 64, 'assets/sprites/map/district_stamp_central.png');

  const dRiverbedSvg = `
  <svg width="64" height="64" viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg">
    <circle cx="32" cy="32" r="30" fill="#0D2545" stroke="#00B4D8" stroke-width="2"/>
    <path d="M 12,24 Q 22,18 32,24 T 52,24 M 12,34 Q 22,28 32,34 T 52,34 M 12,44 Q 22,38 32,44 T 52,44" fill="none" stroke="#00B4D8" stroke-width="3" stroke-linecap="round"/>
  </svg>`;
  await renderSvgToPng(dRiverbedSvg, 64, 64, 'assets/sprites/map/district_stamp_riverbed.png');

  const dIndustrialSvg = `
  <svg width="64" height="64" viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg">
    <circle cx="32" cy="32" r="30" fill="#0D2545" stroke="#F4A261" stroke-width="2"/>
    <rect x="18" y="24" width="8" height="24" fill="#F4A261"/>
    <rect x="30" y="16" width="8" height="32" fill="#F4A261"/>
    <rect x="42" y="28" width="8" height="20" fill="#F4A261"/>
    <line x1="14" y1="48" x2="54" y2="48" stroke="#F4A261" stroke-width="2"/>
  </svg>`;
  await renderSvgToPng(dIndustrialSvg, 64, 64, 'assets/sprites/map/district_stamp_industrial.png');

  const dHistoricSvg = `
  <svg width="64" height="64" viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg">
    <circle cx="32" cy="32" r="30" fill="#0D2545" stroke="#E9C46A" stroke-width="2"/>
    <polygon points="16,22 32,12 48,22" fill="#E9C46A"/>
    <rect x="20" y="24" width="4" height="20" fill="#E9C46A"/>
    <rect x="30" y="24" width="4" height="20" fill="#E9C46A"/>
    <rect x="40" y="24" width="4" height="20" fill="#E9C46A"/>
    <rect x="16" y="44" width="32" height="4" fill="#E9C46A"/>
  </svg>`;
  await renderSvgToPng(dHistoricSvg, 64, 64, 'assets/sprites/map/district_stamp_historic.png');

  const dSuburbsSvg = `
  <svg width="64" height="64" viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg">
    <circle cx="32" cy="32" r="30" fill="#0D2545" stroke="#2A9D8F" stroke-width="2"/>
    <polygon points="16,34 26,24 36,34" fill="#2A9D8F"/>
    <rect x="20" y="34" width="12" height="14" fill="#2A9D8F"/>
    <polygon points="34,30 42,22 50,30" fill="#52B788"/>
    <rect x="38" y="30" width="8" height="18" fill="#52B788"/>
  </svg>`;
  await renderSvgToPng(dSuburbsSvg, 64, 64, 'assets/sprites/map/district_stamp_suburbs.png');

  console.log('All Phase 4 assets generated successfully!');
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
