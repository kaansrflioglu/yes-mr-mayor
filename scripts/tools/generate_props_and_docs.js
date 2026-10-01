const fs = require('fs');
const path = require('path');
const sharp = require('sharp');

async function renderSvgToPng(svgString, width, height, outputPath) {
  const buf = Buffer.from(svgString);
  await sharp(buf, { density: 300 })
    .resize(width, height)
    .png()
    .toFile(outputPath);
  console.log(`Rendered: ${outputPath} (${width}x${height})`);
}

// ----------------------------------------------------------------------
// CATEGORY A: DESK ENVIRONMENT
// ----------------------------------------------------------------------
async function generateDeskAssets() {
  // blotter_leather_9patch.png (512x512)
  const blotterSvg = `
  <svg width="512" height="512" viewBox="0 0 512 512" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="blotterBase" x1="0%" y1="0%" x2="0%" y2="100%">
        <stop offset="0%" stop-color="#18202C"/>
        <stop offset="50%" stop-color="#141A24"/>
        <stop offset="100%" stop-color="#0E121A"/>
      </linearGradient>
      <linearGradient id="goldEdge" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="#F2D06B"/>
        <stop offset="50%" stop-color="#D4AF37"/>
        <stop offset="100%" stop-color="#997C22"/>
      </linearGradient>
      <filter id="blotterShadow" x="-5%" y="-5%" width="110%" height="110%">
        <feDropShadow dx="0" dy="6" stdDeviation="8" flood-color="#000" flood-opacity="0.6"/>
      </filter>
    </defs>
    <!-- Blotter Pad Body -->
    <rect x="16" y="16" width="480" height="480" rx="8" fill="url(#blotterBase)" stroke="#222B3A" stroke-width="3" filter="url(#blotterShadow)"/>
    <!-- Outer Gold Leaf Border -->
    <rect x="32" y="32" width="448" height="448" rx="4" fill="none" stroke="url(#goldEdge)" stroke-width="2.5"/>
    <!-- Inner Fine Gold Stitching -->
    <rect x="42" y="42" width="428" height="428" rx="3" fill="none" stroke="#D4AF37" stroke-width="1.2" stroke-dasharray="6,4" stroke-opacity="0.85"/>
    <!-- Victorian Corner Filigree Accents -->
    <g stroke="url(#goldEdge)" stroke-width="1.5" fill="none">
      <path d="M 36,56 Q 56,56 56,36"/>
      <circle cx="50" cy="50" r="2.5" fill="#D4AF37"/>
      <path d="M 476,56 Q 456,56 456,36"/>
      <circle cx="462" cy="50" r="2.5" fill="#D4AF37"/>
      <path d="M 36,456 Q 56,456 56,476"/>
      <circle cx="50" cy="462" r="2.5" fill="#D4AF37"/>
      <path d="M 476,456 Q 456,456 456,476"/>
      <circle cx="462" cy="462" r="2.5" fill="#D4AF37"/>
    </g>
  </svg>`;
  await renderSvgToPng(blotterSvg, 512, 512, 'assets/sprites/desk/blotter_leather_9patch.png');

  // brass_corner_clamp.png (256x256)
  const clampSvg = `
  <svg width="256" height="256" viewBox="0 0 256 256" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="brassGrad" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="#FFEAA7"/>
        <stop offset="40%" stop-color="#D4AF37"/>
        <stop offset="80%" stop-color="#A68018"/>
        <stop offset="100%" stop-color="#60490E"/>
      </linearGradient>
      <filter id="clampShadow" x="-20%" y="-20%" width="140%" height="140%">
        <feDropShadow dx="4" dy="6" stdDeviation="5" flood-color="#000" flood-opacity="0.5"/>
      </filter>
    </defs>
    <!-- Triangular / L-shaped Corner Guard -->
    <path d="M 24,24 L 232,24 L 232,72 L 72,72 L 72,232 L 24,232 Z" fill="url(#brassGrad)" stroke="#523E0C" stroke-width="3" filter="url(#clampShadow)"/>
    <path d="M 36,36 L 216,36 L 216,60 L 60,60 L 60,216 L 36,216 Z" fill="none" stroke="#FFEAA7" stroke-width="1.5" stroke-opacity="0.7"/>
    <!-- Ornate Scrollwork Embellishment -->
    <path d="M 48,48 Q 110,48 110,110 Q 48,110 48,48" fill="#B3891B" fill-opacity="0.3" stroke="#523E0C" stroke-width="1.2"/>
    <!-- Brass Rivets -->
    <circle cx="48" cy="48" r="6" fill="#FFEAA7" stroke="#423108" stroke-width="1.5"/>
    <circle cx="196" cy="48" r="5" fill="#FFEAA7" stroke="#423108" stroke-width="1.5"/>
    <circle cx="48" cy="196" r="5" fill="#FFEAA7" stroke="#423108" stroke-width="1.5"/>
  </svg>`;
  await renderSvgToPng(clampSvg, 256, 256, 'assets/sprites/desk/brass_corner_clamp.png');
}

// ----------------------------------------------------------------------
// CATEGORY B: INTERACTIVE DESK PROPS
// ----------------------------------------------------------------------
async function generatePropAssets() {
  // 1. telephone_rotary_base.png (512x512)
  const phoneBaseSvg = `
  <svg width="512" height="512" viewBox="0 0 512 512" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="bakeliteRed" x1="0%" y1="0%" x2="0%" y2="100%">
        <stop offset="0%" stop-color="#B82424"/>
        <stop offset="50%" stop-color="#8C1919"/>
        <stop offset="100%" stop-color="#540E0E"/>
      </linearGradient>
      <radialGradient id="chromeDial" cx="50%" cy="50%" r="50%">
        <stop offset="0%" stop-color="#FFFFFF"/>
        <stop offset="60%" stop-color="#E0E0E0"/>
        <stop offset="90%" stop-color="#9E9E9E"/>
        <stop offset="100%" stop-color="#424242"/>
      </radialGradient>
      <filter id="phoneShadow" x="-20%" y="-20%" width="140%" height="140%">
        <feDropShadow dx="0" dy="12" stdDeviation="14" flood-color="#000" flood-opacity="0.6"/>
      </filter>
    </defs>
    <!-- Base Body (Trapezoid with curved corners) -->
    <path d="M 120,110 L 392,110 Q 440,110 450,170 L 476,380 Q 480,440 420,440 L 92,440 Q 32,440 36,380 L 62,170 Q 72,110 120,110 Z"
          fill="url(#bakeliteRed)" stroke="#380909" stroke-width="5" filter="url(#phoneShadow)"/>
    <!-- Top Cradle Rests for Handset -->
    <rect x="110" y="80" width="60" height="40" rx="8" fill="#420B0B" stroke="#220505" stroke-width="3"/>
    <rect x="342" y="80" width="60" height="40" rx="8" fill="#420B0B" stroke="#220505" stroke-width="3"/>
    <!-- Beveled Front Face -->
    <ellipse cx="256" cy="290" rx="140" ry="120" fill="#751313" stroke="#4A0C0C" stroke-width="2"/>
    <!-- Rotary Dial Background Ring -->
    <circle cx="256" cy="290" r="100" fill="#F4EBD9" stroke="#333333" stroke-width="4"/>
    <!-- Rotary Glass & Chrome Wheel -->
    <circle cx="256" cy="290" r="90" fill="url(#chromeDial)" fill-opacity="0.85" stroke="#BDBDBD" stroke-width="3"/>
    <!-- 10 Finger Holes with Numbers -->
    ${[0,1,2,3,4,5,6,7,8,9].map(i => {
      const angle = (i * 28 + 40) * (Math.PI / 180);
      const cx = 256 + Math.cos(angle) * 62;
      const cy = 290 + Math.sin(angle) * 62;
      const num = (i + 1) % 10;
      return `
        <circle cx="${cx.toFixed(1)}" cy="${cy.toFixed(1)}" r="14" fill="#F4EBD9" stroke="#424242" stroke-width="2"/>
        <text x="${cx.toFixed(1)}" y="${(cy + 5).toFixed(1)}" font-family="sans-serif" font-weight="bold" font-size="14" fill="#1A110B" text-anchor="middle">${num}</text>
      `;
    }).join('')}
    <!-- Center Brass Emblem -->
    <circle cx="256" cy="290" r="32" fill="#D4AF37" stroke="#8C6D1F" stroke-width="3"/>
    <text x="256" y="295" font-family="serif" font-weight="bold" font-size="11" fill="#2E2005" text-anchor="middle">OFFICE</text>
    <!-- Metal Finger Stop -->
    <path d="M 334,345 L 350,370 L 338,375 Z" fill="#C0C0C0" stroke="#333" stroke-width="1.5"/>
  </svg>`;
  await renderSvgToPng(phoneBaseSvg, 512, 512, 'assets/sprites/props/telephone_rotary_base.png');

  // 2. telephone_handset.png (512x384)
  const phoneHandsetSvg = `
  <svg width="512" height="384" viewBox="0 0 512 384" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="handsetRed" x1="0%" y1="0%" x2="100%" y2="0%">
        <stop offset="0%" stop-color="#C22929"/>
        <stop offset="35%" stop-color="#8C1919"/>
        <stop offset="70%" stop-color="#B82424"/>
        <stop offset="100%" stop-color="#540E0E"/>
      </linearGradient>
      <filter id="handsetShadow" x="-20%" y="-20%" width="140%" height="140%">
        <feDropShadow dx="6" dy="12" stdDeviation="10" flood-color="#000" flood-opacity="0.6"/>
      </filter>
    </defs>
    <!-- Left Earpiece Cone -->
    <ellipse cx="100" cy="192" rx="60" ry="80" fill="url(#handsetRed)" stroke="#380909" stroke-width="4" filter="url(#handsetShadow)"/>
    <ellipse cx="90" cy="192" rx="42" ry="62" fill="#540E0E" stroke="#220505" stroke-width="2"/>
    <!-- Center Connecting Handle Grip -->
    <path d="M 120,165 Q 256,130 392,165 L 392,219 Q 256,245 120,219 Z" fill="url(#handsetRed)" stroke="#380909" stroke-width="4"/>
    <!-- Right Mouthpiece Cone -->
    <ellipse cx="412" cy="192" rx="60" ry="80" fill="url(#handsetRed)" stroke="#380909" stroke-width="4"/>
    <ellipse cx="422" cy="192" rx="42" ry="62" fill="#540E0E" stroke="#220505" stroke-width="2"/>
    <!-- Mouthpiece sound holes -->
    <circle cx="422" cy="192" r="4" fill="#1A0404"/>
    <circle cx="422" cy="172" r="3.5" fill="#1A0404"/>
    <circle cx="422" cy="212" r="3.5" fill="#1A0404"/>
    <circle cx="407" cy="182" r="3.5" fill="#1A0404"/>
    <circle cx="407" cy="202" r="3.5" fill="#1A0404"/>
    <circle cx="437" cy="182" r="3.5" fill="#1A0404"/>
    <circle cx="437" cy="202" r="3.5" fill="#1A0404"/>
    <!-- Coiled Cable Tail -->
    <path d="M 460,225 Q 490,260 470,290 Q 450,320 480,350" fill="none" stroke="#2B2B2B" stroke-width="8" stroke-linecap="round"/>
  </svg>`;
  await renderSvgToPng(phoneHandsetSvg, 512, 384, 'assets/sprites/props/telephone_handset.png');

  // 3. bell_brass_normal.png (256x256)
  const bellSvg = `
  <svg width="256" height="256" viewBox="0 0 256 256" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="bellDome" x1="0%" y1="0%" x2="100%" y2="0%">
        <stop offset="0%" stop-color="#9E781B"/>
        <stop offset="30%" stop-color="#FFEAA7"/>
        <stop offset="60%" stop-color="#D4AF37"/>
        <stop offset="100%" stop-color="#6E500E"/>
      </linearGradient>
      <linearGradient id="bellBase" x1="0%" y1="0%" x2="0%" y2="100%">
        <stop offset="0%" stop-color="#4E342E"/>
        <stop offset="100%" stop-color="#261713"/>
      </linearGradient>
      <filter id="bellShadow" x="-20%" y="-20%" width="140%" height="140%">
        <feDropShadow dx="0" dy="8" stdDeviation="6" flood-color="#000" flood-opacity="0.5"/>
      </filter>
    </defs>
    <!-- Stepped Heavy Bronze Pedestal -->
    <ellipse cx="128" cy="216" rx="96" ry="24" fill="url(#bellBase)" stroke="#1A0D0A" stroke-width="3" filter="url(#bellShadow)"/>
    <ellipse cx="128" cy="206" rx="84" ry="18" fill="#5D4037" stroke="#3E2723" stroke-width="2"/>
    <!-- Domed Brass Bell -->
    <path d="M 52,192 C 52,110 86,88 128,88 C 170,88 204,110 204,192 Z" fill="url(#bellDome)" stroke="#5A400B" stroke-width="3"/>
    <ellipse cx="128" cy="192" rx="76" ry="14" fill="#B3891B" stroke="#5A400B" stroke-width="2"/>
    <!-- Chrome Plunger Top Shaft -->
    <rect x="123" y="44" width="10" height="46" rx="2" fill="#ECEFF1" stroke="#455A64" stroke-width="2"/>
    <!-- Plunger Push Button -->
    <ellipse cx="128" cy="42" rx="24" ry="12" fill="#CFD8DC" stroke="#37474F" stroke-width="2.5"/>
    <ellipse cx="128" cy="40" rx="16" ry="7" fill="#FFFFFF"/>
  </svg>`;
  await renderSvgToPng(bellSvg, 256, 256, 'assets/sprites/props/bell_brass_normal.png');

  // 4. shredder_chassis.png (512x384)
  const shredderSvg = `
  <svg width="512" height="384" viewBox="0 0 512 384" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="chassisMatte" x1="0%" y1="0%" x2="0%" y2="100%">
        <stop offset="0%" stop-color="#373B44"/>
        <stop offset="50%" stop-color="#252830"/>
        <stop offset="100%" stop-color="#181A20"/>
      </linearGradient>
      <pattern id="hazardStripe" width="24" height="24" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">
        <rect width="12" height="24" fill="#FFC107"/>
        <rect x="12" width="12" height="24" fill="#212121"/>
      </pattern>
      <filter id="shredderShadow" x="-10%" y="-10%" width="120%" height="120%">
        <feDropShadow dx="0" dy="10" stdDeviation="10" flood-color="#000" flood-opacity="0.6"/>
      </filter>
    </defs>
    <!-- Heavy-Duty Housing -->
    <rect x="36" y="32" width="440" height="320" rx="16" fill="url(#chassisMatte)" stroke="#0E1014" stroke-width="4" filter="url(#shredderShadow)"/>
    <!-- Intake Throat Cavity -->
    <rect x="76" y="64" width="360" height="48" rx="6" fill="#0D0E12" stroke="#545B69" stroke-width="3"/>
    <!-- Hazard Warning Border Below Slot -->
    <rect x="76" y="118" width="360" height="16" fill="url(#hazardStripe)" stroke="#212121" stroke-width="1"/>
    <!-- Stainless Steel Intake Teeth Inside Slot -->
    <g stroke="#90A4AE" stroke-width="2">
      ${Array.from({length: 22}).map((_, i) => `<line x1="${88 + i * 16}" y1="68" x2="${88 + i * 16}" y2="108"/>`).join('')}
    </g>
    <!-- Power Toggle Switch & Status Lamp -->
    <circle cx="110" cy="180" r="14" fill="#F44336" stroke="#B71C1C" stroke-width="2"/>
    <circle cx="110" cy="180" r="6" fill="#FF8A80"/>
    <text x="140" y="186" font-family="sans-serif" font-weight="bold" font-size="14" fill="#ECEFF1">MAIN POWER</text>
    <!-- Industrial Vents -->
    <g fill="#14161C">
      ${[0, 1, 2, 3, 4].map(r => `<rect x="76" y="${220 + r * 18}" width="360" height="10" rx="3"/>`).join('')}
    </g>
  </svg>`;
  await renderSvgToPng(shredderSvg, 512, 384, 'assets/sprites/props/shredder_chassis.png');

  // 5. cigar_humidor_closed.png (512x384)
  const humidorSvg = `
  <svg width="512" height="384" viewBox="0 0 512 384" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="burlWood" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="#4E2714"/>
        <stop offset="35%" stop-color="#6D371C"/>
        <stop offset="70%" stop-color="#3A1C0E"/>
        <stop offset="100%" stop-color="#241108"/>
      </linearGradient>
      <linearGradient id="brassLock" x1="0%" y1="0%" x2="0%" y2="100%">
        <stop offset="0%" stop-color="#FFE082"/>
        <stop offset="100%" stop-color="#A68018"/>
      </linearGradient>
      <filter id="humidorShadow" x="-10%" y="-10%" width="120%" height="120%">
        <feDropShadow dx="0" dy="10" stdDeviation="12" flood-color="#000" flood-opacity="0.6"/>
      </filter>
    </defs>
    <!-- Box Body -->
    <rect x="46" y="56" width="420" height="272" rx="10" fill="url(#burlWood)" stroke="#190B05" stroke-width="5" filter="url(#humidorShadow)"/>
    <!-- Lid Separation Line -->
    <line x1="46" y1="140" x2="466" y2="140" stroke="#120703" stroke-width="4"/>
    <line x1="46" y1="142" x2="466" y2="142" stroke="#8A4826" stroke-width="1.5" stroke-opacity="0.6"/>
    <!-- Gold Inlay Border on Top Lid -->
    <rect x="66" y="74" width="380" height="50" rx="4" fill="none" stroke="#D4AF37" stroke-width="2" stroke-opacity="0.8"/>
    <!-- Front Brass Keyhole Clasp -->
    <rect x="236" y="125" width="40" height="34" rx="4" fill="url(#brassLock)" stroke="#5E460B" stroke-width="2"/>
    <circle cx="256" cy="138" r="4" fill="#241A04"/>
    <polygon points="253,138 259,138 261,152 251,152" fill="#241A04"/>
  </svg>`;
  await renderSvgToPng(humidorSvg, 512, 384, 'assets/sprites/props/cigar_humidor_closed.png');

  // 6. brochure_luxury_yacht.png (384x512)
  const brochureSvg = `
  <svg width="384" height="512" viewBox="0 0 384 512" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="oceanGrad" x1="0%" y1="0%" x2="0%" y2="100%">
        <stop offset="0%" stop-color="#006994"/>
        <stop offset="100%" stop-color="#002D4A"/>
      </linearGradient>
      <filter id="brochureShadow" x="-10%" y="-10%" width="120%" height="120%">
        <feDropShadow dx="4" dy="8" stdDeviation="8" flood-color="#000" flood-opacity="0.45"/>
      </filter>
    </defs>
    <!-- Trifold Pamphlet Base -->
    <rect x="24" y="24" width="336" height="464" rx="4" fill="#FFFFFF" stroke="#CFD8DC" stroke-width="2" filter="url(#brochureShadow)"/>
    <!-- Ocean Photo Section -->
    <rect x="36" y="36" width="312" height="240" fill="url(#oceanGrad)"/>
    <!-- Luxury Yacht Vector Silhouette -->
    <polygon points="80,200 280,200 250,225 100,225" fill="#FFFFFF" stroke="#001B2E" stroke-width="2"/>
    <polygon points="120,165 240,165 260,200 130,200" fill="#ECEFF1"/>
    <rect x="160" y="140" width="60" height="25" fill="#B0BEC5"/>
    <line x1="190" y1="110" x2="190" y2="140" stroke="#FFFFFF" stroke-width="3"/>
    <!-- Gold Foil Header -->
    <text x="192" y="320" font-family="serif" font-weight="bold" font-size="20" fill="#B3891B" text-anchor="middle" letter-spacing="2">POSEIDON YACHTS</text>
    <text x="192" y="342" font-family="sans-serif" font-size="12" fill="#546E7A" text-anchor="middle" letter-spacing="3">MEDITERRANEAN CHARTER</text>
    <!-- Trifold Vertical Crease Line -->
    <line x1="136" y1="24" x2="136" y2="488" stroke="#000000" stroke-width="1.5" stroke-opacity="0.15"/>
    <line x1="248" y1="24" x2="248" y2="488" stroke="#000000" stroke-width="1.5" stroke-opacity="0.15"/>
  </svg>`;
  await renderSvgToPng(brochureSvg, 384, 512, 'assets/sprites/props/brochure_luxury_yacht.png');

  // 7. espresso_cup_saucer.png (256x256)
  const espressoSvg = `
  <svg width="256" height="256" viewBox="0 0 256 256" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <radialGradient id="cremaGrad" cx="45%" cy="45%" r="55%">
        <stop offset="0%" stop-color="#C68B59"/>
        <stop offset="50%" stop-color="#6F3F19"/>
        <stop offset="85%" stop-color="#361B07"/>
        <stop offset="100%" stop-color="#1A0D03"/>
      </radialGradient>
      <filter id="cupShadow" x="-20%" y="-20%" width="140%" height="140%">
        <feDropShadow dx="4" dy="8" stdDeviation="6" flood-color="#000" flood-opacity="0.5"/>
      </filter>
    </defs>
    <!-- Porcelain Saucer -->
    <ellipse cx="128" cy="138" rx="100" ry="70" fill="#F5F5F5" stroke="#D6D6D6" stroke-width="3" filter="url(#cupShadow)"/>
    <ellipse cx="128" cy="138" rx="72" ry="50" fill="#EAEAEA" stroke="#CCCCCC" stroke-width="1.5"/>
    <!-- Cup Rim & Interior -->
    <ellipse cx="128" cy="120" rx="58" ry="46" fill="#FFFFFF" stroke="#D6D6D6" stroke-width="4"/>
    <!-- Rich Espresso with Crema Swirl -->
    <ellipse cx="128" cy="120" rx="48" ry="38" fill="url(#cremaGrad)"/>
    <path d="M 115,115 Q 128,105 140,118 Q 130,128 118,122" fill="none" stroke="#DDB892" stroke-width="2.5" stroke-linecap="round"/>
    <!-- Porcelain Handle -->
    <path d="M 184,115 Q 212,120 196,140 Q 180,140 180,132" fill="none" stroke="#FFFFFF" stroke-width="8" stroke-linecap="round"/>
  </svg>`;
  await renderSvgToPng(espressoSvg, 256, 256, 'assets/sprites/props/espresso_cup_saucer.png');

  // 8. stamp_rack_brass.png (640x360)
  const stampRackSvg = `
  <svg width="640" height="360" viewBox="0 0 640 360" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="bronzeStand" x1="0%" y1="0%" x2="100%" y2="0%">
        <stop offset="0%" stop-color="#5E4314"/>
        <stop offset="35%" stop-color="#C29B38"/>
        <stop offset="70%" stop-color="#E5C158"/>
        <stop offset="100%" stop-color="#5E4314"/>
      </linearGradient>
      <filter id="rackShadow" x="-10%" y="-10%" width="120%" height="120%">
        <feDropShadow dx="0" dy="10" stdDeviation="8" flood-color="#000" flood-opacity="0.5"/>
      </filter>
    </defs>
    <!-- Base Tray with Ink Wells -->
    <rect x="40" y="270" width="560" height="60" rx="12" fill="url(#bronzeStand)" stroke="#382608" stroke-width="4" filter="url(#rackShadow)"/>
    <!-- 3 Ink Wells: Green (Approve), Red (Reject), Gold (Covert) -->
    <ellipse cx="160" cy="300" rx="42" ry="18" fill="#143324" stroke="#D4AF37" stroke-width="2"/>
    <ellipse cx="320" cy="300" rx="42" ry="18" fill="#4A0C0C" stroke="#D4AF37" stroke-width="2"/>
    <ellipse cx="480" cy="300" rx="42" ry="18" fill="#42310C" stroke="#D4AF37" stroke-width="2"/>
    <!-- Vertical Support Pillars -->
    <rect x="80" y="80" width="24" height="194" rx="4" fill="url(#bronzeStand)" stroke="#382608" stroke-width="3"/>
    <rect x="536" y="80" width="24" height="194" rx="4" fill="url(#bronzeStand)" stroke="#382608" stroke-width="3"/>
    <!-- Horizontal Crossbar with 3 Hanging Hooks -->
    <rect x="60" y="80" width="520" height="24" rx="6" fill="url(#bronzeStand)" stroke="#382608" stroke-width="3"/>
    <!-- 3 U-shaped Resting Slots -->
    <path d="M 140,80 L 140,130 A 20,20 0 0,0 180,130 L 180,80" fill="none" stroke="url(#bronzeStand)" stroke-width="12" stroke-linecap="round"/>
    <path d="M 300,80 L 300,130 A 20,20 0 0,0 340,130 L 340,80" fill="none" stroke="url(#bronzeStand)" stroke-width="12" stroke-linecap="round"/>
    <path d="M 460,80 L 460,130 A 20,20 0 0,0 500,130 L 500,80" fill="none" stroke="url(#bronzeStand)" stroke-width="12" stroke-linecap="round"/>
  </svg>`;
  await renderSvgToPng(stampRackSvg, 640, 360, 'assets/sprites/props/stamp_rack_brass.png');

  // 9. stamp_handle_approve.png (384x512)
  const stampApproveSvg = `
  <svg width="384" height="512" viewBox="0 0 384 512" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="woodHandle" x1="0%" y1="0%" x2="100%" y2="0%">
        <stop offset="0%" stop-color="#4E2714"/>
        <stop offset="40%" stop-color="#8D4924"/>
        <stop offset="70%" stop-color="#5E3018"/>
        <stop offset="100%" stop-color="#2D1509"/>
      </linearGradient>
      <filter id="handleShadow" x="-20%" y="-10%" width="140%" height="120%">
        <feDropShadow dx="8" dy="12" stdDeviation="10" flood-color="#000" flood-opacity="0.55"/>
      </filter>
    </defs>
    <!-- Top Turned Knob -->
    <circle cx="192" cy="70" r="54" fill="url(#woodHandle)" stroke="#220D04" stroke-width="4" filter="url(#handleShadow)"/>
    <!-- Turned Shaft Waist -->
    <path d="M 160,118 Q 176,210 148,290 L 236,290 Q 208,210 224,118 Z" fill="url(#woodHandle)" stroke="#220D04" stroke-width="4"/>
    <!-- Polished Brass Collar -->
    <rect x="136" y="290" width="112" height="36" rx="4" fill="#D4AF37" stroke="#665214" stroke-width="3"/>
    <!-- Emerald Green Enameled Ring (Approve) -->
    <rect x="136" y="326" width="112" height="24" fill="#2D6A4F" stroke="#133827" stroke-width="2"/>
    <!-- Rubber Mount Base -->
    <rect x="72" y="350" width="240" height="90" rx="8" fill="#2D1509" stroke="#120602" stroke-width="4"/>
    <!-- Rubber Stamp Pad -->
    <rect x="80" y="440" width="224" height="30" rx="4" fill="#2D6A4F" stroke="#133827" stroke-width="2"/>
    <text x="192" y="462" font-family="sans-serif" font-weight="bold" font-size="18" fill="#A3E4D7" text-anchor="middle">APPROVED</text>
  </svg>`;
  await renderSvgToPng(stampApproveSvg, 384, 512, 'assets/sprites/props/stamp_handle_approve.png');

  // 10. stamp_handle_reject.png (384x512)
  const stampRejectSvg = `
  <svg width="384" height="512" viewBox="0 0 384 512" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="ebonyHandle" x1="0%" y1="0%" x2="100%" y2="0%">
        <stop offset="0%" stop-color="#1A1A1A"/>
        <stop offset="40%" stop-color="#3D3D3D"/>
        <stop offset="70%" stop-color="#242424"/>
        <stop offset="100%" stop-color="#0F0F0F"/>
      </linearGradient>
      <filter id="handleShadowR" x="-20%" y="-10%" width="140%" height="120%">
        <feDropShadow dx="8" dy="12" stdDeviation="10" flood-color="#000" flood-opacity="0.55"/>
      </filter>
    </defs>
    <!-- Top Turned Knob -->
    <circle cx="192" cy="70" r="54" fill="url(#ebonyHandle)" stroke="#000" stroke-width="4" filter="url(#handleShadowR)"/>
    <!-- Shaft -->
    <path d="M 160,118 Q 176,210 148,290 L 236,290 Q 208,210 224,118 Z" fill="url(#ebonyHandle)" stroke="#000" stroke-width="4"/>
    <!-- Blackened Iron Collar -->
    <rect x="136" y="290" width="112" height="36" rx="4" fill="#424242" stroke="#212121" stroke-width="3"/>
    <!-- Oxblood Red Enameled Ring (Reject) -->
    <rect x="136" y="326" width="112" height="24" fill="#A61C1C" stroke="#540808" stroke-width="2"/>
    <!-- Base -->
    <rect x="72" y="350" width="240" height="90" rx="8" fill="#1A1A1A" stroke="#0A0A0A" stroke-width="4"/>
    <!-- Stamp Pad -->
    <rect x="80" y="440" width="224" height="30" rx="4" fill="#A61C1C" stroke="#540808" stroke-width="2"/>
    <text x="192" y="462" font-family="sans-serif" font-weight="bold" font-size="18" fill="#FADBD8" text-anchor="middle">DENIED</text>
  </svg>`;
  await renderSvgToPng(stampRejectSvg, 384, 512, 'assets/sprites/props/stamp_handle_reject.png');

  // 11. stamp_handle_bribe.png (384x512)
  const stampBribeSvg = `
  <svg width="384" height="512" viewBox="0 0 384 512" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="goldLeaf" x1="0%" y1="0%" x2="100%" y2="0%">
        <stop offset="0%" stop-color="#C8963E"/>
        <stop offset="40%" stop-color="#FFDF78"/>
        <stop offset="70%" stop-color="#D4AF37"/>
        <stop offset="100%" stop-color="#805B17"/>
      </linearGradient>
      <filter id="handleShadowB" x="-20%" y="-10%" width="140%" height="120%">
        <feDropShadow dx="8" dy="12" stdDeviation="10" flood-color="#000" flood-opacity="0.55"/>
      </filter>
    </defs>
    <!-- Top Gilded Finial -->
    <circle cx="192" cy="70" r="54" fill="url(#goldLeaf)" stroke="#523B10" stroke-width="4" filter="url(#handleShadowB)"/>
    <!-- Black Lacquer Shaft with Gold Spirals -->
    <path d="M 160,118 Q 176,210 148,290 L 236,290 Q 208,210 224,118 Z" fill="#141414" stroke="#000" stroke-width="4"/>
    <path d="M 162,150 Q 192,170 220,150" fill="none" stroke="url(#goldLeaf)" stroke-width="4"/>
    <path d="M 158,210 Q 192,230 224,210" fill="none" stroke="url(#goldLeaf)" stroke-width="4"/>
    <!-- Heavy Gilded Collar -->
    <rect x="136" y="290" width="112" height="36" rx="4" fill="url(#goldLeaf)" stroke="#523B10" stroke-width="3"/>
    <rect x="136" y="326" width="112" height="24" fill="#C8963E" stroke="#523B10" stroke-width="2"/>
    <!-- Base -->
    <rect x="72" y="350" width="240" height="90" rx="8" fill="#1F1A12" stroke="#0D0B08" stroke-width="4"/>
    <!-- Stamp Pad -->
    <rect x="80" y="440" width="224" height="30" rx="4" fill="#C8963E" stroke="#523B10" stroke-width="2"/>
    <text x="192" y="462" font-family="serif" font-weight="bold" font-size="17" fill="#FFF2CC" text-anchor="middle">OFFICIAL SEAL</text>
  </svg>`;
  await renderSvgToPng(stampBribeSvg, 384, 512, 'assets/sprites/props/stamp_handle_bribe.png');
}

// ----------------------------------------------------------------------
// CATEGORY C: DOCUMENTS & PAPERWORK
// ----------------------------------------------------------------------
async function generateDocumentAssets() {
  // 1. paper_parchment_base.png (768x1024)
  const paperSvg = `
  <svg width="768" height="1024" viewBox="0 0 768 1024" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="paperAged" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="#FAF5E8"/>
        <stop offset="40%" stop-color="#F4EBD9"/>
        <stop offset="85%" stop-color="#EFE2CA"/>
        <stop offset="100%" stop-color="#E2D2B4"/>
      </linearGradient>
      <filter id="docShadow" x="-10%" y="-10%" width="120%" height="120%">
        <feDropShadow dx="3" dy="8" stdDeviation="10" flood-color="#000" flood-opacity="0.4"/>
      </filter>
    </defs>
    <!-- Paper Sheet with Slightly Irregular Deckled Edges -->
    <rect x="24" y="24" width="720" height="976" rx="4" fill="url(#paperAged)" stroke="#C4B598" stroke-width="2.5" filter="url(#docShadow)"/>
    <!-- Faint Horizontal Ruling / Watermark Lines -->
    <g stroke="#8C795C" stroke-width="0.8" stroke-opacity="0.18">
      ${Array.from({length: 28}).map((_, i) => `<line x1="64" y1="${160 + i * 28}" x2="704" y2="${160 + i * 28}"/>`).join('')}
    </g>
    <!-- Official Governmental Header Crest Watermark -->
    <circle cx="384" cy="90" r="32" fill="none" stroke="#7A684C" stroke-width="1.5" stroke-opacity="0.35"/>
    <text x="384" y="96" font-family="serif" font-weight="bold" font-size="14" fill="#7A684C" fill-opacity="0.4" text-anchor="middle">CITY ADMINISTRATION</text>
  </svg>`;
  await renderSvgToPng(paperSvg, 768, 1024, 'assets/sprites/documents/paper_parchment_base.png');

  // 2. folder_manila_backing.png (800x1060)
  const folderSvg = `
  <svg width="800" height="1060" viewBox="0 0 800 1060" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="manilaGrad" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="#E5D4AC"/>
        <stop offset="50%" stop-color="#D8C59A"/>
        <stop offset="100%" stop-color="#C2AE81"/>
      </linearGradient>
      <filter id="folderShadow" x="-10%" y="-10%" width="120%" height="120%">
        <feDropShadow dx="4" dy="10" stdDeviation="12" flood-color="#000" flood-opacity="0.5"/>
      </filter>
    </defs>
    <!-- Manila Folder with Top Right Filing Tab -->
    <path d="M 32,70 L 460,70 L 510,24 L 740,24 Q 768,24 768,52 L 768,1020 Q 768,1036 740,1036 L 32,1036 Q 16,1036 16,1016 L 16,90 Q 16,70 32,70 Z"
          fill="url(#manilaGrad)" stroke="#9E8A61" stroke-width="4" filter="url(#folderShadow)"/>
    <!-- Brass Prong Fasteners at Top -->
    <rect x="220" y="86" width="30" height="10" rx="3" fill="#D4AF37" stroke="#7A6319" stroke-width="1.5"/>
    <rect x="520" y="86" width="30" height="10" rx="3" fill="#D4AF37" stroke="#7A6319" stroke-width="1.5"/>
    <!-- Red Stamped Watermark: CONFIDENTIAL -->
    <g transform="rotate(-15 400 500)">
      <rect x="180" y="470" width="440" height="70" fill="none" stroke="#B71C1C" stroke-width="5" stroke-dasharray="14,6" stroke-opacity="0.5"/>
      <text x="400" y="522" font-family="sans-serif" font-weight="900" font-size="44" fill="#B71C1C" fill-opacity="0.5" text-anchor="middle" letter-spacing="6">CONFIDENTIAL</text>
    </g>
  </svg>`;
  await renderSvgToPng(folderSvg, 800, 1060, 'assets/sprites/documents/folder_manila_backing.png');

  // 3. paperclip_metal.png (256x256)
  const clipSvg = `
  <svg width="256" height="256" viewBox="0 0 256 256" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="chromeWire" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="#FFFFFF"/>
        <stop offset="50%" stop-color="#B0BEC5"/>
        <stop offset="100%" stop-color="#546E7A"/>
      </linearGradient>
      <filter id="clipShadow" x="-20%" y="-20%" width="140%" height="140%">
        <feDropShadow dx="3" dy="5" stdDeviation="4" flood-color="#000" flood-opacity="0.45"/>
      </filter>
    </defs>
    <!-- Looped Steel Paperclip -->
    <path d="M 80,180 L 80,60 A 30,30 0 0,1 140,60 L 140,195 A 45,45 0 0,1 50,195 L 50,85 A 15,15 0 0,1 80,85 L 80,175"
          fill="none" stroke="url(#chromeWire)" stroke-width="12" stroke-linecap="round" stroke-linejoin="round" filter="url(#clipShadow)"/>
  </svg>`;
  await renderSvgToPng(clipSvg, 256, 256, 'assets/sprites/documents/paperclip_metal.png');

  // 4. stamp_decal_approve.png (512x512)
  const decalApproveSvg = `
  <svg width="512" height="512" viewBox="0 0 512 512" xmlns="http://www.w3.org/2000/svg">
    <!-- Double Circle Rubber Stamp Ring -->
    <circle cx="256" cy="256" r="220" fill="none" stroke="#2D6A4F" stroke-width="9" stroke-dasharray="24,6" stroke-opacity="0.9"/>
    <circle cx="256" cy="256" r="195" fill="none" stroke="#2D6A4F" stroke-width="4" stroke-opacity="0.9"/>
    <!-- Stamp Text Along Arch -->
    <path id="circlePathTop" d="M 86,256 A 170,170 0 0,1 426,256" fill="none"/>
    <text font-family="sans-serif" font-weight="900" font-size="28" fill="#2D6A4F" letter-spacing="4">
      <textPath href="#circlePathTop" startOffset="50%" text-anchor="middle">OFFICE OF THE MAYOR</textPath>
    </text>
    <!-- Center Banner -->
    <rect x="60" y="226" width="392" height="60" fill="#2D6A4F" rx="4"/>
    <text x="256" y="268" font-family="sans-serif" font-weight="900" font-size="40" fill="#FFFFFF" text-anchor="middle" letter-spacing="4">APPROVED</text>
    <!-- Bottom Arch -->
    <path id="circlePathBottom" d="M 426,256 A 170,170 0 0,1 86,256" fill="none"/>
    <text font-family="sans-serif" font-weight="bold" font-size="22" fill="#2D6A4F" letter-spacing="3">
      <textPath href="#circlePathBottom" startOffset="50%" text-anchor="middle">MUNICIPAL DECREE</textPath>
    </text>
  </svg>`;
  await renderSvgToPng(decalApproveSvg, 512, 512, 'assets/sprites/documents/stamp_decal_approve.png');

  // 5. stamp_decal_reject.png (512x512)
  const decalRejectSvg = `
  <svg width="512" height="512" viewBox="0 0 512 512" xmlns="http://www.w3.org/2000/svg">
    <!-- Heavy Weathered Rectangular Frame -->
    <rect x="36" y="116" width="440" height="280" rx="8" fill="none" stroke="#A61C1C" stroke-width="12" stroke-dasharray="32,8" stroke-opacity="0.95"/>
    <rect x="52" y="132" width="408" height="248" rx="4" fill="none" stroke="#A61C1C" stroke-width="4" stroke-opacity="0.9"/>
    <!-- Large Bold Text -->
    <text x="256" y="240" font-family="sans-serif" font-weight="900" font-size="64" fill="#A61C1C" text-anchor="middle" letter-spacing="6">DENIED</text>
    <line x1="80" y1="270" x2="432" y2="270" stroke="#A61C1C" stroke-width="6"/>
    <text x="256" y="315" font-family="sans-serif" font-weight="bold" font-size="22" fill="#A61C1C" text-anchor="middle" letter-spacing="3">MUNICIPAL DISAPPROVAL</text>
    <text x="256" y="348" font-family="monospace" font-size="15" fill="#A61C1C" text-anchor="middle">SEC. 4-B // CODE VIOLATION</text>
  </svg>`;
  await renderSvgToPng(decalRejectSvg, 512, 512, 'assets/sprites/documents/stamp_decal_reject.png');

  // 6. stamp_decal_bribe.png (512x512)
  const decalBribeSvg = `
  <svg width="512" height="512" viewBox="0 0 512 512" xmlns="http://www.w3.org/2000/svg">
    <!-- Ornate Double-Eagle Monogram Stamp -->
    <circle cx="256" cy="256" r="220" fill="none" stroke="#C8963E" stroke-width="8" stroke-opacity="0.9"/>
    <circle cx="256" cy="256" r="200" fill="none" stroke="#C8963E" stroke-width="3" stroke-dasharray="10,6" stroke-opacity="0.8"/>
    <!-- Double-Headed Eagle Silhouette -->
    <path d="M 256,120 L 270,160 L 330,170 L 285,210 L 300,270 L 256,240 L 212,270 L 227,210 L 182,170 L 242,160 Z"
          fill="#C8963E" fill-opacity="0.85"/>
    <!-- Clearance Ribbons -->
    <rect x="76" y="280" width="360" height="48" rx="4" fill="#C8963E"/>
    <text x="256" y="313" font-family="serif" font-weight="bold" font-size="24" fill="#1C1408" text-anchor="middle" letter-spacing="3">SPECIAL CLEARANCE</text>
    <text x="256" y="360" font-family="serif" font-size="18" fill="#C8963E" text-anchor="middle">COVERT EXECUTIVE PRIVILEGE</text>
  </svg>`;
  await renderSvgToPng(decalBribeSvg, 512, 512, 'assets/sprites/documents/stamp_decal_bribe.png');
}

// ----------------------------------------------------------------------
// CATEGORY D: SKYLINE PANORAMA
// ----------------------------------------------------------------------
async function generateSkylineAssets() {
  // 1. skyline_far_silhouette.png (1920x600)
  const skylineSvg = `
  <svg width="1920" height="600" viewBox="0 0 1920 600" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="duskSky" x1="0%" y1="0%" x2="0%" y2="100%">
        <stop offset="0%" stop-color="#141724"/>
        <stop offset="45%" stop-color="#2D2336"/>
        <stop offset="85%" stop-color="#5C3630"/>
        <stop offset="100%" stop-color="#2B1A24"/>
      </linearGradient>
    </defs>
    <!-- Dusk Sky Backdrop -->
    <rect width="1920" height="600" fill="url(#duskSky)"/>
    <!-- Distant Mountains -->
    <polygon points="0,480 300,380 650,490 1100,360 1550,470 1920,400 1920,600 0,600" fill="#181926" fill-opacity="0.7"/>
    <!-- Mid-ground City Silhouettes -->
    ${[
      [40, 160, 220], [120, 200, 280], [240, 140, 320], [320, 260, 390],
      [460, 180, 290], [560, 220, 340], [680, 190, 420], [800, 280, 360],
      [940, 150, 440], [1050, 230, 380], [1180, 170, 350], [1300, 250, 410],
      [1450, 180, 330], [1580, 220, 370], [1720, 190, 430], [1820, 140, 310]
    ].map(([x, w, h]) => `
      <rect x="${x}" y="${600 - h}" width="${w}" height="${h}" fill="#11131C"/>
      <!-- Window Lights Pattern -->
      ${Array.from({length: Math.floor(h / 30)}).map((_, r) => 
        (r % 2 === 0) ? `<circle cx="${x + 25}" cy="${600 - h + 20 + r * 28}" r="2" fill="#FFE082" fill-opacity="0.6"/>
                         <circle cx="${x + w - 25}" cy="${600 - h + 20 + r * 28}" r="2" fill="#FFE082" fill-opacity="0.6"/>` : ''
      ).join('')}
    `).join('')}
    <!-- Red Radio Tower Antenna Beacons -->
    <line x1="280" y1="280" x2="280" y2="180" stroke="#8C2525" stroke-width="3"/>
    <circle cx="280" cy="176" r="4" fill="#FF1744"/>
    <line x1="990" y1="160" x2="990" y2="80" stroke="#8C2525" stroke-width="3"/>
    <circle cx="990" cy="76" r="5" fill="#FF1744"/>
    <line x1="1760" y1="170" x2="1760" y2="90" stroke="#8C2525" stroke-width="3"/>
    <circle cx="1760" cy="86" r="5" fill="#FF1744"/>
  </svg>`;
  await renderSvgToPng(skylineSvg, 1920, 600, 'assets/sprites/skyline/skyline_far_silhouette.png');

  // 2. landmark_clock_tower.png (512x512)
  const clockTowerSvg = `
  <svg width="512" height="512" viewBox="0 0 512 512" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="stoneWall" x1="0%" y1="0%" x2="100%" y2="0%">
        <stop offset="0%" stop-color="#3D3833"/>
        <stop offset="50%" stop-color="#6E655C"/>
        <stop offset="100%" stop-color="#3D3833"/>
      </linearGradient>
      <filter id="towerShadow" x="-10%" y="-10%" width="120%" height="120%">
        <feDropShadow dx="4" dy="8" stdDeviation="8" flood-color="#000" flood-opacity="0.5"/>
      </filter>
    </defs>
    <!-- Tower Body -->
    <rect x="160" y="160" width="192" height="340" fill="url(#stoneWall)" stroke="#24211D" stroke-width="4" filter="url(#towerShadow)"/>
    <!-- Oxidized Copper Spire Roof -->
    <polygon points="144,160 256,24 368,160" fill="#3D7A68" stroke="#1D4036" stroke-width="4"/>
    <!-- Ornate Clock Face -->
    <circle cx="256" cy="240" r="56" fill="#FDF7E7" stroke="#2B241A" stroke-width="6"/>
    <circle cx="256" cy="240" r="48" fill="#F4EBD9" stroke="#8C795C" stroke-width="1.5"/>
    <!-- Roman Numerals / Hour Markers -->
    ${[0,1,2,3,4,5,6,7,8,9,10,11].map(h => {
      const angle = (h * 30 - 90) * (Math.PI / 180);
      return `<circle cx="${(256 + Math.cos(angle) * 40).toFixed(1)}" cy="${(240 + Math.sin(angle) * 40).toFixed(1)}" r="2.5" fill="#1A110B"/>`;
    }).join('')}
    <!-- Clock Hands (10:10) -->
    <line x1="256" y1="240" x2="236" y2="212" stroke="#1A110B" stroke-width="4" stroke-linecap="round"/>
    <line x1="256" y1="240" x2="284" y2="226" stroke="#1A110B" stroke-width="3" stroke-linecap="round"/>
    <circle cx="256" cy="240" r="5" fill="#D4AF37"/>
    <!-- Gothic Arched Windows Below Clock -->
    <path d="M 216,400 L 216,350 A 20,20 0 0,1 256,350 L 256,400 Z" fill="#1C1E26" stroke="#3D3833" stroke-width="3"/>
    <path d="M 276,400 L 276,350 A 20,20 0 0,1 316,350 L 316,400 Z" fill="#1C1E26" stroke="#3D3833" stroke-width="3"/>
  </svg>`;
  await renderSvgToPng(clockTowerSvg, 512, 512, 'assets/sprites/skyline/landmark_clock_tower.png');

  // 3. landmark_factory_stacks.png (512x384)
  const factorySvg = `
  <svg width="512" height="384" viewBox="0 0 512 384" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="brickRed" x1="0%" y1="0%" x2="100%" y2="0%">
        <stop offset="0%" stop-color="#4A1C16"/>
        <stop offset="50%" stop-color="#80382E"/>
        <stop offset="100%" stop-color="#3B140F"/>
      </linearGradient>
    </defs>
    <!-- Factory Boiler House Base -->
    <polygon points="60,260 160,220 260,260 260,370 60,370" fill="#2E2421" stroke="#1A1311" stroke-width="3"/>
    <polygon points="260,260 360,220 460,260 460,370 260,370" fill="#3D302C" stroke="#1A1311" stroke-width="3"/>
    <!-- 3 Heavy Smokestacks -->
    <!-- Stack 1 -->
    <polygon points="120,50 148,50 156,230 112,230" fill="url(#brickRed)" stroke="#260C08" stroke-width="3"/>
    <rect x="117" y="70" width="34" height="14" fill="#E0E0E0"/>
    <rect x="115" y="110" width="38" height="14" fill="#E0E0E0"/>
    <!-- Stack 2 (Tall Center) -->
    <polygon points="230,24 262,24 272,230 220,230" fill="url(#brickRed)" stroke="#260C08" stroke-width="3"/>
    <rect x="228" y="48" width="36" height="16" fill="#E0E0E0"/>
    <rect x="226" y="94" width="40" height="16" fill="#E0E0E0"/>
    <!-- Stack 3 -->
    <polygon points="340,60 368,60 376,230 332,230" fill="url(#brickRed)" stroke="#260C08" stroke-width="3"/>
    <rect x="337" y="80" width="34" height="14" fill="#E0E0E0"/>
    <rect x="335" y="120" width="38" height="14" fill="#E0E0E0"/>
    <!-- Iron Catwalks -->
    <line x1="90" y1="160" x2="390" y2="160" stroke="#1F2024" stroke-width="4"/>
  </svg>`;
  await renderSvgToPng(factorySvg, 512, 384, 'assets/sprites/skyline/landmark_factory_stacks.png');

  // 4. landmark_luxury_towers.png (384x512)
  const towersSvg = `
  <svg width="384" height="512" viewBox="0 0 384 512" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="glassTower" x1="0%" y1="0%" x2="100%" y2="0%">
        <stop offset="0%" stop-color="#1E374B"/>
        <stop offset="50%" stop-color="#36648B"/>
        <stop offset="100%" stop-color="#142634"/>
      </linearGradient>
    </defs>
    <!-- Tower 1 (Tall) -->
    <rect x="64" y="60" width="130" height="430" fill="url(#glassTower)" stroke="#0E1A24" stroke-width="3"/>
    <!-- Balconies & Glass Panes -->
    ${Array.from({length: 14}).map((_, i) => `
      <rect x="74" y="${80 + i * 28}" width="110" height="16" rx="2" fill="#81D4FA" fill-opacity="0.5"/>
      <line x1="64" y1="${100 + i * 28}" x2="194" y2="${100 + i * 28}" stroke="#ECEFF1" stroke-width="1.5"/>
    `).join('')}
    <!-- Penthouse Terrace & Swimming Pool -->
    <rect x="64" y="44" width="130" height="16" fill="#00BCD4" stroke="#0E1A24" stroke-width="2"/>
    <!-- Tower 2 (Right Stepped) -->
    <rect x="210" y="140" width="110" height="350" fill="url(#glassTower)" stroke="#0E1A24" stroke-width="3"/>
    ${Array.from({length: 11}).map((_, i) => `
      <rect x="220" y="${160 + i * 28}" width="90" height="16" rx="2" fill="#81D4FA" fill-opacity="0.45"/>
    `).join('')}
  </svg>`;
  await renderSvgToPng(towersSvg, 384, 512, 'assets/sprites/skyline/landmark_luxury_towers.png');

  // 5. window_mullion_frame.png (1920x360)
  const windowFrameSvg = `
  <svg width="1920" height="360" viewBox="0 0 1920 360" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="frameMahogany" x1="0%" y1="0%" x2="0%" y2="100%">
        <stop offset="0%" stop-color="#3D1D10"/>
        <stop offset="40%" stop-color="#5E2C18"/>
        <stop offset="100%" stop-color="#24110A"/>
      </linearGradient>
    </defs>
    <!-- Top Heavy Header Beam -->
    <rect x="0" y="0" width="1920" height="40" fill="url(#frameMahogany)" stroke="#190B06" stroke-width="3"/>
    <!-- Bottom Window Sill -->
    <rect x="0" y="320" width="1920" height="40" fill="url(#frameMahogany)" stroke="#190B06" stroke-width="3"/>
    <!-- Left & Right Outer Mullions -->
    <rect x="0" y="40" width="40" height="280" fill="url(#frameMahogany)" stroke="#190B06" stroke-width="3"/>
    <rect x="1880" y="40" width="40" height="280" fill="url(#frameMahogany)" stroke="#190B06" stroke-width="3"/>
    <!-- Vertical Division Mullions -->
    <rect x="470" y="40" width="30" height="280" fill="url(#frameMahogany)" stroke="#190B06" stroke-width="2"/>
    <rect x="945" y="40" width="30" height="280" fill="url(#frameMahogany)" stroke="#190B06" stroke-width="2"/>
    <rect x="1420" y="40" width="30" height="280" fill="url(#frameMahogany)" stroke="#190B06" stroke-width="2"/>
    <!-- Horizontal Cross Mullion -->
    <rect x="40" y="160" width="1840" height="20" fill="url(#frameMahogany)" stroke="#190B06" stroke-width="2"/>
    <!-- Brass Hinges & Corner Brackets -->
    ${[470, 945, 1420].map(x => `
      <circle cx="${x + 15}" cy="170" r="6" fill="#D4AF37" stroke="#5E430B" stroke-width="1.5"/>
    `).join('')}
  </svg>`;
  await renderSvgToPng(windowFrameSvg, 1920, 360, 'assets/sprites/skyline/window_mullion_frame.png');
}

async function main() {
  console.log('Generating Desk Assets...');
  await generateDeskAssets();
  console.log('Generating Prop Assets...');
  await generatePropAssets();
  console.log('Generating Document Assets...');
  await generateDocumentAssets();
  console.log('Generating Skyline Assets...');
  await generateSkylineAssets();
  console.log('ALL ASSETS GENERATED SUCCESSFULLY!');
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
