const fs = require('fs');
const path = require('path');
const sharp = require('sharp');
const crypto = require('crypto');

async function renderSvgToPng(svgString, width, height, outputPath) {
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
  console.log('Generating Phase 3 Assets...');

  // 1. crest_sanitation.png (80x80)
  const sanitationSvg = `
  <svg width="80" height="80" viewBox="0 0 80 80" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <radialGradient id="sanBg" cx="50%" cy="50%" r="50%">
        <stop offset="0%" stop-color="#2D6A4F"/>
        <stop offset="80%" stop-color="#1B4332"/>
        <stop offset="100%" stop-color="#081C15"/>
      </radialGradient>
      <linearGradient id="sanGold" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="#E9D8A6"/>
        <stop offset="100%" stop-color="#CA6702"/>
      </linearGradient>
    </defs>
    <!-- Outer Shield / Circle -->
    <circle cx="40" cy="40" r="36" fill="url(#sanBg)" stroke="url(#sanGold)" stroke-width="3"/>
    <circle cx="40" cy="40" r="32" fill="none" stroke="#52B788" stroke-width="1" stroke-dasharray="3,2"/>
    <!-- Gear Motif -->
    <g transform="translate(40,40)">
      <circle cx="0" cy="0" r="14" fill="none" stroke="url(#sanGold)" stroke-width="4"/>
      <!-- Gear Teeth -->
      <rect x="-3" y="-18" width="6" height="5" fill="url(#sanGold)"/>
      <rect x="-3" y="13" width="6" height="5" fill="url(#sanGold)"/>
      <rect x="-18" y="-3" width="5" height="6" fill="url(#sanGold)"/>
      <rect x="13" y="-3" width="5" height="6" fill="url(#sanGold)"/>
      <rect x="-14" y="-14" width="5" height="5" fill="url(#sanGold)" transform="rotate(45)"/>
      <rect x="-14" y="9" width="5" height="5" fill="url(#sanGold)" transform="rotate(45)"/>
      <rect x="9" y="-14" width="5" height="5" fill="url(#sanGold)" transform="rotate(45)"/>
      <rect x="9" y="9" width="5" height="5" fill="url(#sanGold)" transform="rotate(45)"/>
      <!-- Crossed Broom and Wrench -->
      <line x1="-16" y1="16" x2="16" y2="-16" stroke="#D8F3DC" stroke-width="3" stroke-linecap="round"/>
      <line x1="-16" y1="-16" x2="16" y2="16" stroke="#D8F3DC" stroke-width="3" stroke-linecap="round"/>
      <circle cx="0" cy="0" r="4" fill="url(#sanGold)"/>
    </g>
  </svg>`;
  await renderSvgToPng(sanitationSvg, 80, 80, 'assets/sprites/documents/crest_sanitation.png');

  // 2. crest_police.png (80x80)
  const policeSvg = `
  <svg width="80" height="80" viewBox="0 0 80 80" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <radialGradient id="polBg" cx="50%" cy="50%" r="50%">
        <stop offset="0%" stop-color="#1D3557"/>
        <stop offset="85%" stop-color="#0F1F38"/>
        <stop offset="100%" stop-color="#050C17"/>
      </radialGradient>
      <linearGradient id="polGold" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="#F4D06F"/>
        <stop offset="100%" stop-color="#AA820A"/>
      </linearGradient>
    </defs>
    <!-- 7-point Police Star / Shield -->
    <circle cx="40" cy="40" r="36" fill="url(#polBg)" stroke="url(#polGold)" stroke-width="3"/>
    <polygon points="40,10 46,24 61,24 49,34 54,48 40,40 26,48 31,34 19,24 34,24" fill="url(#polGold)" opacity="0.25"/>
    <!-- Scales of Justice -->
    <g transform="translate(40,40)">
      <!-- Center Pillar -->
      <line x1="0" y1="-18" x2="0" y2="16" stroke="url(#polGold)" stroke-width="2.5" stroke-linecap="round"/>
      <line x1="-6" y1="16" x2="6" y2="16" stroke="url(#polGold)" stroke-width="3" stroke-linecap="round"/>
      <!-- Crossbeam -->
      <line x1="-16" y1="-10" x2="16" y2="-10" stroke="url(#polGold)" stroke-width="2.5" stroke-linecap="round"/>
      <circle cx="0" cy="-10" r="2.5" fill="#FFF"/>
      <!-- Left Pan -->
      <line x1="-16" y1="-10" x2="-21" y2="2" stroke="#A8DADC" stroke-width="1.2"/>
      <line x1="-16" y1="-10" x2="-11" y2="2" stroke="#A8DADC" stroke-width="1.2"/>
      <path d="M -23,2 Q -16,8 -9,2 Z" fill="url(#polGold)"/>
      <!-- Right Pan -->
      <line x1="16" y1="-10" x2="11" y2="2" stroke="#A8DADC" stroke-width="1.2"/>
      <line x1="16" y1="-10" x2="21" y2="2" stroke="#A8DADC" stroke-width="1.2"/>
      <path d="M 9,2 Q 16,8 23,2 Z" fill="url(#polGold)"/>
    </g>
  </svg>`;
  await renderSvgToPng(policeSvg, 80, 80, 'assets/sprites/documents/crest_police.png');

  // 3. crest_treasury.png (80x80)
  const treasurySvg = `
  <svg width="80" height="80" viewBox="0 0 80 80" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <radialGradient id="treBg" cx="50%" cy="50%" r="50%">
        <stop offset="0%" stop-color="#4A2E00"/>
        <stop offset="85%" stop-color="#2B1A00"/>
        <stop offset="100%" stop-color="#140C00"/>
      </radialGradient>
      <linearGradient id="goldCoins" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="#FFE066"/>
        <stop offset="50%" stop-color="#F4A261"/>
        <stop offset="100%" stop-color="#E76F51"/>
      </linearGradient>
    </defs>
    <!-- Outer Octagon / Coin Rim -->
    <circle cx="40" cy="40" r="36" fill="url(#treBg)" stroke="url(#goldCoins)" stroke-width="3"/>
    <circle cx="40" cy="40" r="32" fill="none" stroke="#D4AF37" stroke-width="1" stroke-dasharray="2,3"/>
    <!-- Cornucopia and Vault Key Motif -->
    <g transform="translate(40,40)">
      <!-- Crossed Keys -->
      <path d="M -12,-12 L 12,12 M -9,-15 C -15,-15 -15,-9 -9,-9 C -6,-9 -6,-15 -9,-15 Z M 10,7 L 12,9 M 7,10 L 9,12" stroke="url(#goldCoins)" stroke-width="2.5" stroke-linecap="round" fill="none"/>
      <path d="M 12,-12 L -12,12 M 9,-15 C 15,-15 15,-9 9,-9 C 6,-9 6,-15 9,-15 Z M -10,7 L -12,9 M -7,10 L -9,12" stroke="url(#goldCoins)" stroke-width="2.5" stroke-linecap="round" fill="none"/>
      <!-- Golden Coin Center -->
      <circle cx="0" cy="0" r="8" fill="url(#goldCoins)" stroke="#FFF" stroke-width="1"/>
      <text x="0" y="3.5" font-family="serif" font-weight="bold" font-size="9" fill="#3D2000" text-anchor="middle">$</text>
    </g>
  </svg>`;
  await renderSvgToPng(treasurySvg, 80, 80, 'assets/sprites/documents/crest_treasury.png');

  // 4. crest_housing.png (80x80)
  const housingSvg = `
  <svg width="80" height="80" viewBox="0 0 80 80" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <radialGradient id="houBg" cx="50%" cy="50%" r="50%">
        <stop offset="0%" stop-color="#3D2619"/>
        <stop offset="85%" stop-color="#24140B"/>
        <stop offset="100%" stop-color="#120703"/>
      </radialGradient>
      <linearGradient id="brickGold" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="#E07A5F"/>
        <stop offset="50%" stop-color="#F2CC8F"/>
        <stop offset="100%" stop-color="#81B29A"/>
      </linearGradient>
    </defs>
    <!-- Architectural Pediment & Columns -->
    <circle cx="40" cy="40" r="36" fill="url(#houBg)" stroke="#F2CC8F" stroke-width="3"/>
    <circle cx="40" cy="40" r="32" fill="none" stroke="#E07A5F" stroke-width="1.2"/>
    <g transform="translate(40,40)">
      <!-- Pediment (Triangle Roof) -->
      <polygon points="0,-22 -20,-10 20,-10" fill="#F2CC8F"/>
      <!-- Entablature bar -->
      <rect x="-21" y="-9" width="42" height="3" fill="#F2CC8F"/>
      <!-- Columns -->
      <rect x="-18" y="-5" width="4" height="18" fill="#F2CC8F"/>
      <rect x="-7" y="-5" width="4" height="18" fill="#F2CC8F"/>
      <rect x="3" y="-5" width="4" height="18" fill="#F2CC8F"/>
      <rect x="14" y="-5" width="4" height="18" fill="#F2CC8F"/>
      <!-- Silhouette Tenements behind columns -->
      <rect x="-12" y="0" width="8" height="13" fill="#E07A5F"/>
      <rect x="-1" y="-3" width="7" height="16" fill="#E07A5F"/>
      <!-- Base Plinth -->
      <rect x="-22" y="14" width="44" height="4" fill="#F2CC8F"/>
    </g>
  </svg>`;
  await renderSvgToPng(housingSvg, 80, 80, 'assets/sprites/documents/crest_housing.png');

  // 5. crest_oligarch.png (80x80)
  const oligarchSvg = `
  <svg width="80" height="80" viewBox="0 0 80 80" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <radialGradient id="oliBg" cx="50%" cy="50%" r="50%">
        <stop offset="0%" stop-color="#1A1829"/>
        <stop offset="85%" stop-color="#0E0D17"/>
        <stop offset="100%" stop-color="#05040A"/>
      </radialGradient>
      <linearGradient id="pureGold" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="#FFF3B0"/>
        <stop offset="40%" stop-color="#E09F3E"/>
        <stop offset="100%" stop-color="#9E2A2B"/>
      </linearGradient>
    </defs>
    <!-- Imperial Crown & Golden Eagle -->
    <circle cx="40" cy="40" r="36" fill="url(#oliBg)" stroke="url(#pureGold)" stroke-width="3"/>
    <circle cx="40" cy="40" r="32" fill="none" stroke="#E09F3E" stroke-width="1.2" stroke-dasharray="4,2"/>
    <g transform="translate(40,42)">
      <!-- Eagle Wings -->
      <path d="M 0,-6 Q -14,-22 -22,-14 Q -16,-6 -14,-1 Q -24,-12 -26,-2 Q -18,2 -12,5 L 0,8 L 12,5 Q 18,2 26,-2 Q 24,-12 14,-1 Q 16,-6 22,-14 Q 14,-22 0,-6 Z" fill="url(#pureGold)"/>
      <!-- Eagle Body & Head -->
      <circle cx="0" cy="-8" r="4.5" fill="#FFF3B0"/>
      <polygon points="0,-12 -3,-8 3,-8" fill="#FFF3B0"/>
      <!-- Clutching Offshore Bond Scroll -->
      <rect x="-12" y="8" width="24" height="6" rx="2" fill="#FFF3B0" stroke="#9E2A2B" stroke-width="1"/>
      <line x1="-9" y1="11" x2="9" y2="11" stroke="#9E2A2B" stroke-width="1.2"/>
    </g>
  </svg>`;
  await renderSvgToPng(oligarchSvg, 80, 80, 'assets/sprites/documents/crest_oligarch.png');

  // 6. paper_grain.png (256x256)
  const grainSvg = `
  <svg width="256" height="256" viewBox="0 0 256 256" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <filter id="noiseFilter">
        <feTurbulence type="fractalNoise" baseFrequency="0.65" numOctaves="4" stitchTiles="stitch"/>
        <feColorMatrix type="matrix" values="
          0.33 0.33 0.33 0 0
          0.33 0.33 0.33 0 0
          0.33 0.33 0.33 0 0
          0    0    0    1 0"/>
      </filter>
    </defs>
    <rect width="256" height="256" fill="#F0EDE4"/>
    <rect width="256" height="256" filter="url(#noiseFilter)" opacity="0.35"/>
  </svg>`;
  await renderSvgToPng(grainSvg, 256, 256, 'assets/sprites/documents/paper_grain.png');

  // 7. ink_pad_green.png (120x120)
  const inkPadGreenSvg = `
  <svg width="120" height="120" viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="tinRim" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="#4A453A"/>
        <stop offset="50%" stop-color="#2D2B24"/>
        <stop offset="100%" stop-color="#1A1814"/>
      </linearGradient>
      <radialGradient id="wetGreen" cx="50%" cy="50%" r="50%">
        <stop offset="0%" stop-color="#2EC4B6"/>
        <stop offset="45%" stop-color="#1B6A47"/>
        <stop offset="85%" stop-color="#0E442B"/>
        <stop offset="100%" stop-color="#062416"/>
      </radialGradient>
      <filter id="dropShadow" x="-10%" y="-10%" width="120%" height="120%">
        <feDropShadow dx="0" dy="4" stdDeviation="4" flood-color="#000" flood-opacity="0.5"/>
      </filter>
    </defs>
    <!-- Heavy Cast Tin Base -->
    <rect x="10" y="10" width="100" height="100" rx="14" fill="url(#tinRim)" stroke="#8A7A5D" stroke-width="2.5" filter="url(#dropShadow)"/>
    <!-- Recessed Ink Felt Pad -->
    <rect x="18" y="18" width="84" height="84" rx="8" fill="url(#wetGreen)" stroke="#113B26" stroke-width="2"/>
    <!-- Wet Sheen Highlight -->
    <ellipse cx="60" cy="52" rx="26" ry="18" fill="#52B788" opacity="0.35"/>
    <ellipse cx="54" cy="46" rx="8" ry="5" fill="#FFFFFF" opacity="0.45"/>
  </svg>`;
  await renderSvgToPng(inkPadGreenSvg, 120, 120, 'assets/sprites/props/ink_pad_green.png');

  // 8. ink_pad_red.png (120x120)
  const inkPadRedSvg = `
  <svg width="120" height="120" viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="tinRimRed" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="#4A453A"/>
        <stop offset="50%" stop-color="#2D2B24"/>
        <stop offset="100%" stop-color="#1A1814"/>
      </linearGradient>
      <radialGradient id="wetRed" cx="50%" cy="50%" r="50%">
        <stop offset="0%" stop-color="#E63946"/>
        <stop offset="45%" stop-color="#A81824"/>
        <stop offset="85%" stop-color="#660A12"/>
        <stop offset="100%" stop-color="#3B0308"/>
      </radialGradient>
      <filter id="dropShadow" x="-10%" y="-10%" width="120%" height="120%">
        <feDropShadow dx="0" dy="4" stdDeviation="4" flood-color="#000" flood-opacity="0.5"/>
      </filter>
    </defs>
    <!-- Heavy Cast Tin Base -->
    <rect x="10" y="10" width="100" height="100" rx="14" fill="url(#tinRimRed)" stroke="#8A7A5D" stroke-width="2.5" filter="url(#dropShadow)"/>
    <!-- Recessed Ink Felt Pad with crusted dark rim -->
    <rect x="18" y="18" width="84" height="84" rx="8" fill="url(#wetRed)" stroke="#4A060C" stroke-width="2"/>
    <!-- Wet Sheen Highlight -->
    <ellipse cx="60" cy="52" rx="26" ry="18" fill="#FF6B6B" opacity="0.35"/>
    <ellipse cx="54" cy="46" rx="8" ry="5" fill="#FFFFFF" opacity="0.45"/>
  </svg>`;
  await renderSvgToPng(inkPadRedSvg, 120, 120, 'assets/sprites/props/ink_pad_red.png');

  // 9. ink_pad_gold.png (120x120)
  const inkPadGoldSvg = `
  <svg width="120" height="120" viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="tinRimGold" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="#5E4E2C"/>
        <stop offset="50%" stop-color="#3D3219"/>
        <stop offset="100%" stop-color="#241D0D"/>
      </linearGradient>
      <radialGradient id="wetGold" cx="50%" cy="50%" r="50%">
        <stop offset="0%" stop-color="#FFE066"/>
        <stop offset="45%" stop-color="#D4AF37"/>
        <stop offset="80%" stop-color="#997C22"/>
        <stop offset="100%" stop-color="#574309"/>
      </radialGradient>
      <filter id="dropShadow" x="-10%" y="-10%" width="120%" height="120%">
        <feDropShadow dx="0" dy="4" stdDeviation="4" flood-color="#000" flood-opacity="0.5"/>
      </filter>
    </defs>
    <!-- Heavy Cast Tin Base -->
    <rect x="10" y="10" width="100" height="100" rx="14" fill="url(#tinRimGold)" stroke="#D4AF37" stroke-width="2.5" filter="url(#dropShadow)"/>
    <!-- Recessed Ink Felt Pad -->
    <rect x="18" y="18" width="84" height="84" rx="8" fill="url(#wetGold)" stroke="#665014" stroke-width="2"/>
    <!-- Wet Metallic Sheen Highlight -->
    <ellipse cx="60" cy="52" rx="26" ry="18" fill="#FFF9DB" opacity="0.4"/>
    <ellipse cx="54" cy="46" rx="8" ry="5" fill="#FFFFFF" opacity="0.6"/>
  </svg>`;
  await renderSvgToPng(inkPadGoldSvg, 120, 120, 'assets/sprites/props/ink_pad_gold.png');

  console.log('All Phase 3 assets generated successfully!');
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
