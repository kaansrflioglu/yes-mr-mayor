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
  console.log('Generating Phase 5 Narrative Framing & Transition Assets...\n');

  // ==========================================
  // 1. MORNING BRIEFING NEWSPAPER ASSETS
  // ==========================================

  // 1.1 newspaper_paper_base.png (800x1000 Broadsheet Paper Canvas)
  const newspaperPaperSvg = `
  <svg width="800" height="1000" viewBox="0 0 800 1000" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="newsprint" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="#F7F5EE"/>
        <stop offset="40%" stop-color="#EFECE2"/>
        <stop offset="80%" stop-color="#E6E1D3"/>
        <stop offset="100%" stop-color="#DCD6C5"/>
      </linearGradient>
      <linearGradient id="foldCrease" x1="0%" y1="0%" x2="0%" y2="100%">
        <stop offset="0%" stop-color="#000000" stop-opacity="0.12"/>
        <stop offset="48%" stop-color="#000000" stop-opacity="0.04"/>
        <stop offset="50%" stop-color="#FFFFFF" stop-opacity="0.18"/>
        <stop offset="52%" stop-color="#000000" stop-opacity="0.08"/>
        <stop offset="100%" stop-color="#000000" stop-opacity="0.0"/>
      </linearGradient>
    </defs>
    <!-- Paper Sheet Base with Aged Deckled Border -->
    <rect width="800" height="1000" fill="url(#newsprint)"/>
    <rect x="12" y="12" width="776" height="976" fill="none" stroke="#2B261F" stroke-width="2" stroke-opacity="0.85"/>
    <rect x="16" y="16" width="768" height="968" fill="none" stroke="#2B261F" stroke-width="0.8" stroke-opacity="0.5"/>
    
    <!-- Masthead Top Banner Divider -->
    <line x1="20" y1="120" x2="780" y2="120" stroke="#1A1815" stroke-width="3"/>
    <line x1="20" y1="126" x2="780" y2="126" stroke="#1A1815" stroke-width="1"/>
    
    <!-- Issue Metadata Band -->
    <rect x="20" y="127" width="760" height="22" fill="#E2DDD0" opacity="0.6"/>
    <line x1="20" y1="150" x2="780" y2="150" stroke="#1A1815" stroke-width="1.2"/>
    
    <!-- 3-Column Editorial Grid Lines -->
    <line x1="270" y1="156" x2="270" y2="960" stroke="#1A1815" stroke-width="0.8" stroke-opacity="0.35"/>
    <line x1="530" y1="156" x2="530" y2="960" stroke="#1A1815" stroke-width="0.8" stroke-opacity="0.35"/>
    
    <!-- Center Horizontal Fold Crease Shadow -->
    <rect x="0" y="485" width="800" height="30" fill="url(#foldCrease)"/>
    
    <!-- Vignette Age Stains on Edges -->
    <rect x="0" y="0" width="800" height="1000" fill="none" stroke="#54432A" stroke-width="8" stroke-opacity="0.08"/>
  </svg>`;
  await renderSvgToPng(newspaperPaperSvg, 800, 1000, 'assets/sprites/ui/newspaper_paper_base.png');

  // 1.2 newspaper_photo_strike.png (512x320 Industrial Strike News Photo)
  const strikePhotoSvg = `
  <svg width="512" height="320" viewBox="0 0 512 320" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="photoSky" x1="0%" y1="0%" x2="0%" y2="100%">
        <stop offset="0%" stop-color="#D0D0D0"/>
        <stop offset="50%" stop-color="#909090"/>
        <stop offset="100%" stop-color="#505050"/>
      </linearGradient>
    </defs>
    <!-- Background Factory Sky -->
    <rect width="512" height="320" fill="url(#photoSky)"/>
    
    <!-- Factory Silhouette with Smokestacks -->
    <polygon points="40,180 80,180 80,80 100,80 100,180 180,180 180,120 200,120 200,180 260,180 320,140 380,180 480,180 480,240 40,240" fill="#2B2B2B"/>
    <rect x="85" y="60" width="10" height="20" fill="#1C1C1C"/>
    <rect x="185" y="100" width="10" height="20" fill="#1C1C1C"/>
    
    <!-- Billowing Factory Smog Clouds -->
    <circle cx="90" cy="50" r="28" fill="#E8E8E8" opacity="0.7"/>
    <circle cx="120" cy="40" r="36" fill="#C0C0C0" opacity="0.6"/>
    <circle cx="190" cy="80" r="24" fill="#D8D8D8" opacity="0.6"/>
    
    <!-- Ground / Pavement -->
    <rect x="0" y="240" width="512" height="80" fill="#181818"/>
    
    <!-- Crowd of Striking Workers Silhouettes & Placards -->
    <!-- Placard poles and signs -->
    <line x1="120" y1="180" x2="120" y2="240" stroke="#000" stroke-width="3"/>
    <rect x="90" y="140" width="60" height="40" fill="#FFF" stroke="#000" stroke-width="2"/>
    <line x1="95" y1="152" x2="145" y2="152" stroke="#000" stroke-width="3"/>
    <line x1="95" y1="162" x2="145" y2="162" stroke="#000" stroke-width="2"/>
    <line x1="100" y1="172" x2="140" y2="172" stroke="#000" stroke-width="2"/>
    
    <line x1="220" y1="170" x2="220" y2="235" stroke="#000" stroke-width="3"/>
    <rect x="190" y="130" width="65" height="40" fill="#FFF" stroke="#000" stroke-width="2"/>
    <line x1="195" y1="142" x2="250" y2="142" stroke="#000" stroke-width="3"/>
    <line x1="200" y1="152" x2="245" y2="152" stroke="#000" stroke-width="3"/>
    
    <line x1="340" y1="175" x2="340" y2="240" stroke="#000" stroke-width="3"/>
    <rect x="310" y="145" width="60" height="35" fill="#FFF" stroke="#000" stroke-width="2"/>
    <line x1="315" y1="158" x2="365" y2="158" stroke="#000" stroke-width="3"/>
    
    <!-- Worker Figures (Heads and Shoulders) -->
    <circle cx="80" cy="225" r="16" fill="#111"/>
    <rect x="62" y="240" width="36" height="60" rx="8" fill="#111"/>
    
    <circle cx="140" cy="220" r="17" fill="#1A1A1A"/>
    <rect x="120" y="236" width="40" height="64" rx="8" fill="#1A1A1A"/>
    
    <circle cx="210" cy="215" r="18" fill="#0A0A0A"/>
    <rect x="188" y="232" width="44" height="68" rx="8" fill="#0A0A0A"/>
    
    <circle cx="280" cy="222" r="16" fill="#181818"/>
    <rect x="262" y="238" width="38" height="62" rx="8" fill="#181818"/>
    
    <circle cx="350" cy="218" r="17" fill="#101010"/>
    <rect x="330" y="234" width="42" height="66" rx="8" fill="#101010"/>
    
    <circle cx="420" cy="226" r="15" fill="#202020"/>
    <rect x="404" y="240" width="34" height="60" rx="8" fill="#202020"/>
    
    <!-- Raised Fist in Center -->
    <path d="M 245,210 L 252,190 L 260,190 L 262,210 Z" fill="#0A0A0A"/>
    
    <!-- Press Photo Dark Border Frame -->
    <rect width="512" height="320" fill="none" stroke="#111" stroke-width="4"/>
  </svg>`;
  await renderSvgToPng(strikePhotoSvg, 512, 320, 'assets/sprites/ui/newspaper_photo_strike.png');

  // 1.3 newspaper_photo_ribbon.png (512x320 Ribbon Cutting News Photo)
  const ribbonPhotoSvg = `
  <svg width="512" height="320" viewBox="0 0 512 320" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="plazaGrad" x1="0%" y1="0%" x2="0%" y2="100%">
        <stop offset="0%" stop-color="#E8E8E8"/>
        <stop offset="50%" stop-color="#A8A8A8"/>
        <stop offset="100%" stop-color="#383838"/>
      </linearGradient>
    </defs>
    <rect width="512" height="320" fill="url(#plazaGrad)"/>
    
    <!-- Civic Center Pillars in Background -->
    <rect x="40" y="40" width="30" height="200" fill="#666"/>
    <rect x="120" y="40" width="30" height="200" fill="#666"/>
    <rect x="200" y="40" width="30" height="200" fill="#666"/>
    <rect x="280" y="40" width="30" height="200" fill="#666"/>
    <rect x="360" y="40" width="30" height="200" fill="#666"/>
    <rect x="440" y="40" width="30" height="200" fill="#666"/>
    <!-- Pediment Roof Architrave -->
    <rect x="20" y="20" width="472" height="24" fill="#444"/>
    
    <!-- Red Ceremonial Ribbon Stretched Across -->
    <path d="M 20,180 Q 256,210 492,180" fill="none" stroke="#222" stroke-width="14"/>
    <path d="M 20,180 Q 256,210 492,180" fill="none" stroke="#888" stroke-width="10"/>
    
    <!-- Mayor in Formal Suit with Oversized Scissors -->
    <!-- Dignitary left -->
    <circle cx="170" cy="140" r="18" fill="#1A1A1A"/>
    <polygon points="150,158 190,158 196,270 144,270" fill="#2A2A2A"/>
    <!-- Mayor Center holding scissors -->
    <circle cx="256" cy="130" r="22" fill="#0A0A0A"/>
    <polygon points="230,152 282,152 290,280 222,280" fill="#141414"/>
    <!-- White shirt collar and tie -->
    <polygon points="250,152 262,152 258,190 254,190" fill="#E8E8E8"/>
    <polygon points="254,160 258,160 260,195 256,205 252,195" fill="#333"/>
    <!-- Oversized Scissors -->
    <line x1="240" y1="180" x2="272" y2="195" stroke="#FFF" stroke-width="4"/>
    <line x1="240" y1="195" x2="272" y2="180" stroke="#FFF" stroke-width="4"/>
    
    <!-- Dignitary right -->
    <circle cx="340" cy="142" r="18" fill="#222"/>
    <polygon points="320,160 360,160 366,270 314,270" fill="#2D2D2D"/>
    
    <!-- Photo Edge Frame -->
    <rect width="512" height="320" fill="none" stroke="#111" stroke-width="4"/>
  </svg>`;
  await renderSvgToPng(ribbonPhotoSvg, 512, 320, 'assets/sprites/ui/newspaper_photo_ribbon.png');

  // 1.4 newspaper_photo_scandal.png (512x320 Nocturnal Scandal News Photo)
  const scandalPhotoSvg = `
  <svg width="512" height="320" viewBox="0 0 512 320" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <radialGradient id="searchlight" cx="65%" cy="35%" r="70%">
        <stop offset="0%" stop-color="#FFFFFF" stop-opacity="0.85"/>
        <stop offset="40%" stop-color="#C0C0C0" stop-opacity="0.4"/>
        <stop offset="100%" stop-color="#000000" stop-opacity="0.0"/>
      </radialGradient>
    </defs>
    <!-- Midnight Black Background -->
    <rect width="512" height="320" fill="#0C0D12"/>
    
    <!-- City Hall Nocturnal Silhouette -->
    <rect x="60" y="90" width="392" height="150" fill="#1E2028"/>
    <!-- Dome Top -->
    <path d="M 216,90 A 40,40 0 0,1 296,90 Z" fill="#2C2E3A"/>
    <rect x="252" y="38" width="8" height="24" fill="#3C3E4A"/>
    
    <!-- Searchlight Cones -->
    <polygon points="30,300 240,80 320,80 180,300" fill="url(#searchlight)"/>
    <polygon points="460,300 200,60 280,60 360,300" fill="url(#searchlight)"/>
    
    <!-- Police Cars with Flashing Light Bars -->
    <rect x="50" y="240" width="140" height="45" rx="6" fill="#181A22"/>
    <circle cx="80" cy="285" r="14" fill="#000" stroke="#444" stroke-width="2"/>
    <circle cx="160" cy="285" r="14" fill="#000" stroke="#444" stroke-width="2"/>
    <!-- Flashing Roof Lightbar -->
    <rect x="95" y="232" width="50" height="8" rx="2" fill="#E8E8E8"/>
    <rect x="100" y="232" width="20" height="8" fill="#FFF"/>
    
    <rect x="320" y="244" width="140" height="45" rx="6" fill="#181A22"/>
    <circle cx="350" cy="289" r="14" fill="#000" stroke="#444" stroke-width="2"/>
    <circle cx="430" cy="289" r="14" fill="#000" stroke="#444" stroke-width="2"/>
    <rect x="365" y="236" width="50" height="8" rx="2" fill="#E8E8E8"/>
    
    <!-- Agents Carrying Seized Evidence Boxes -->
    <circle cx="230" cy="235" r="12" fill="#0A0A0A"/>
    <rect x="218" y="247" width="24" height="40" fill="#0A0A0A"/>
    <rect x="228" y="252" width="22" height="18" fill="#C8C8C8" stroke="#333" stroke-width="1.5"/>
    
    <circle cx="280" cy="235" r="12" fill="#0A0A0A"/>
    <rect x="268" y="247" width="24" height="40" fill="#0A0A0A"/>
    <rect x="278" y="252" width="22" height="18" fill="#C8C8C8" stroke="#333" stroke-width="1.5"/>
    
    <!-- Photo Frame -->
    <rect width="512" height="320" fill="none" stroke="#111" stroke-width="4"/>
  </svg>`;
  await renderSvgToPng(scandalPhotoSvg, 512, 320, 'assets/sprites/ui/newspaper_photo_scandal.png');

  // ==========================================
  // 2. MUNICIPAL RULEBOOK ASSETS
  // ==========================================

  // 2.1 rulebook_leather_cover.png (1000x700 Executive Leather Bound Tome)
  const rulebookCoverSvg = `
  <svg width="1000" height="700" viewBox="0 0 1000 700" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="leatherGrad" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="#2D1115"/>
        <stop offset="35%" stop-color="#1F0A0D"/>
        <stop offset="70%" stop-color="#140608"/>
        <stop offset="100%" stop-color="#0A0204"/>
      </linearGradient>
      <linearGradient id="goldLeaf" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="#FFF5B8"/>
        <stop offset="40%" stop-color="#D4AF37"/>
        <stop offset="80%" stop-color="#AA820A"/>
        <stop offset="100%" stop-color="#553D00"/>
      </linearGradient>
      <linearGradient id="brassCorner" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="#F3E5AB"/>
        <stop offset="50%" stop-color="#C59B27"/>
        <stop offset="100%" stop-color="#6B4E03"/>
      </linearGradient>
    </defs>
    <!-- Deep Burgundy Leather Base -->
    <rect width="1000" height="700" rx="16" fill="url(#leatherGrad)"/>
    
    <!-- Gilded Double Filigree Outer Border -->
    <rect x="24" y="24" width="952" height="652" rx="10" fill="none" stroke="url(#goldLeaf)" stroke-width="3.5"/>
    <rect x="34" y="34" width="932" height="632" rx="6" fill="none" stroke="url(#goldLeaf)" stroke-width="1.2" stroke-dasharray="6,4"/>
    
    <!-- Center Spine Ridge Crease (Double Page Illusion) -->
    <line x1="500" y1="20" x2="500" y2="680" stroke="#050102" stroke-width="12" stroke-opacity="0.8"/>
    <line x1="497" y1="20" x2="497" y2="680" stroke="url(#goldLeaf)" stroke-width="1" stroke-opacity="0.4"/>
    <line x1="503" y1="20" x2="503" y2="680" stroke="url(#goldLeaf)" stroke-width="1" stroke-opacity="0.4"/>
    
    <!-- Brass Corner Clamps -->
    <!-- Top-Left -->
    <polygon points="10,10 80,10 10,80" fill="url(#brassCorner)" stroke="#3D2B00" stroke-width="1.5"/>
    <circle cx="28" cy="28" r="4" fill="#3D2B00"/>
    <!-- Top-Right -->
    <polygon points="990,10 920,10 990,80" fill="url(#brassCorner)" stroke="#3D2B00" stroke-width="1.5"/>
    <circle cx="972" cy="28" r="4" fill="#3D2B00"/>
    <!-- Bottom-Left -->
    <polygon points="10,690 80,690 10,620" fill="url(#brassCorner)" stroke="#3D2B00" stroke-width="1.5"/>
    <circle cx="28" cy="672" r="4" fill="#3D2B00"/>
    <!-- Bottom-Right -->
    <polygon points="990,690 920,690 990,620" fill="url(#brassCorner)" stroke="#3D2B00" stroke-width="1.5"/>
    <circle cx="972" cy="672" r="4" fill="#3D2B00"/>
    
    <!-- Embossed Gold Foil Emblem on Left Panel -->
    <g transform="translate(250, 350)">
      <circle cx="0" cy="0" r="90" fill="none" stroke="url(#goldLeaf)" stroke-width="2.5"/>
      <circle cx="0" cy="0" r="76" fill="none" stroke="url(#goldLeaf)" stroke-width="1" stroke-dasharray="3,3"/>
      <!-- Balance of Justice Scales -->
      <line x1="0" y1="-50" x2="0" y2="45" stroke="url(#goldLeaf)" stroke-width="4"/>
      <line x1="-45" y1="-30" x2="45" y2="-30" stroke="url(#goldLeaf)" stroke-width="3"/>
      <polygon points="-45,-30 -58,0 -32,0" fill="none" stroke="url(#goldLeaf)" stroke-width="2"/>
      <polygon points="45,-30 32,0 58,0" fill="none" stroke="url(#goldLeaf)" stroke-width="2"/>
      <polygon points="0,45 -25,60 25,60" fill="url(#goldLeaf)"/>
    </g>
  </svg>`;
  await renderSvgToPng(rulebookCoverSvg, 1000, 700, 'assets/sprites/ui/rulebook_leather_cover.png');

  // 2.2 rulebook_bookmark_ribbon.png (48x240 Silk Bookmark Ribbon)
  const ribbonSvg = `
  <svg width="48" height="240" viewBox="0 0 48 240" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="silkRed" x1="0%" y1="0%" x2="100%" y2="0%">
        <stop offset="0%" stop-color="#8A0C16"/>
        <stop offset="35%" stop-color="#D91E2E"/>
        <stop offset="65%" stop-color="#F24E5D"/>
        <stop offset="100%" stop-color="#6B050D"/>
      </linearGradient>
    </defs>
    <!-- Ribbon Body with Chevron Notch Tail -->
    <path d="M 4,0 L 44,0 L 44,210 L 24,185 L 4,210 Z" fill="url(#silkRed)" stroke="#4A0007" stroke-width="1.2"/>
    <!-- Gold Trim Edge Pinstripe -->
    <line x1="8" y1="0" x2="8" y2="200" stroke="#FFE082" stroke-width="0.8" opacity="0.6"/>
    <line x1="40" y1="0" x2="40" y2="200" stroke="#FFE082" stroke-width="0.8" opacity="0.6"/>
  </svg>`;
  await renderSvgToPng(ribbonSvg, 48, 240, 'assets/sprites/ui/rulebook_bookmark_ribbon.png');

  // ==========================================
  // 3. OFFSHORE BRIBE LEDGER ASSETS
  // ==========================================

  // 3.1 ledger_goatskin_cover.png (900x640 Black Goatskin Pocket Ledger)
  const ledgerCoverSvg = `
  <svg width="900" height="640" viewBox="0 0 900 640" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="blackGoatskin" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="#1F2128"/>
        <stop offset="45%" stop-color="#14151B"/>
        <stop offset="85%" stop-color="#0A0B0E"/>
        <stop offset="100%" stop-color="#040507"/>
      </linearGradient>
      <linearGradient id="foilGold" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="#FFF2A3"/>
        <stop offset="50%" stop-color="#D4AF37"/>
        <stop offset="100%" stop-color="#735400"/>
      </linearGradient>
    </defs>
    <rect width="900" height="640" rx="14" fill="url(#blackGoatskin)"/>
    
    <!-- Gold Foil Pinstripe Frame -->
    <rect x="20" y="20" width="860" height="600" rx="8" fill="none" stroke="url(#foilGold)" stroke-width="2"/>
    <rect x="26" y="26" width="848" height="588" rx="5" fill="none" stroke="url(#foilGold)" stroke-width="0.8" stroke-dasharray="4,4"/>
    
    <!-- Secret Swiss Ledger Stamp Header -->
    <text x="450" y="80" font-family="serif" font-weight="bold" font-size="20" fill="url(#foilGold)" text-anchor="middle" letter-spacing="4">CONFIDENTIAL OFFSHORE HOLDINGS</text>
    <text x="450" y="105" font-family="monospace" font-size="12" fill="#B39230" text-anchor="middle" letter-spacing="2">NO. 884-X-CH • PRIVATE NUMBERED ACCOUNT</text>
    <line x1="220" y1="120" x2="680" y2="120" stroke="url(#foilGold)" stroke-width="1.5"/>
    
    <!-- Marbled Ledger Paper Inside Inset -->
    <rect x="40" y="140" width="820" height="460" rx="6" fill="#F3EFE0" stroke="#333" stroke-width="1.5"/>
    <!-- Accounting Table Ruling Lines (Classic Light Blue & Red Ledger) -->
    <line x1="40" y1="180" x2="860" y2="180" stroke="#C94C4C" stroke-width="1.8"/>
    <line x1="40" y1="184" x2="860" y2="184" stroke="#C94C4C" stroke-width="0.8"/>
    
    <!-- Horizontal Blue Accounting Rules -->
    <g stroke="#9BB5D1" stroke-width="0.9">
      <line x1="40" y1="220" x2="860" y2="220"/>
      <line x1="40" y1="256" x2="860" y2="256"/>
      <line x1="40" y1="292" x2="860" y2="292"/>
      <line x1="40" y1="328" x2="860" y2="328"/>
      <line x1="40" y1="364" x2="860" y2="364"/>
      <line x1="40" y1="400" x2="860" y2="400"/>
      <line x1="40" y1="436" x2="860" y2="436"/>
      <line x1="40" y1="472" x2="860" y2="472"/>
      <line x1="40" y1="508" x2="860" y2="508"/>
      <line x1="40" y1="544" x2="860" y2="544"/>
      <line x1="40" y1="580" x2="860" y2="580"/>
    </g>
    
    <!-- Vertical Red Accounting Margin Columns -->
    <line x1="160" y1="140" x2="160" y2="600" stroke="#C94C4C" stroke-width="1.2"/>
    <line x1="560" y1="140" x2="560" y2="600" stroke="#C94C4C" stroke-width="1.2"/>
    <line x1="720" y1="140" x2="720" y2="600" stroke="#C94C4C" stroke-width="1.2"/>
  </svg>`;
  await renderSvgToPng(ledgerCoverSvg, 900, 640, 'assets/sprites/ui/ledger_goatskin_cover.png');

  // 3.2 money_stack_bribe.png (256x160 Stack of Banknotes)
  const moneyStackSvg = `
  <svg width="256" height="160" viewBox="0 0 256 160" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="billGreen" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="#C5E3CE"/>
        <stop offset="50%" stop-color="#93C8A2"/>
        <stop offset="100%" stop-color="#5B936C"/>
      </linearGradient>
      <linearGradient id="bankStrap" x1="0%" y1="0%" x2="0%" y2="100%">
        <stop offset="0%" stop-color="#EBE7D8"/>
        <stop offset="50%" stop-color="#D6CEB6"/>
        <stop offset="100%" stop-color="#B8AE92"/>
      </linearGradient>
    </defs>
    <!-- Drop Shadow -->
    <polygon points="18,140 238,140 248,155 28,155" fill="#000" opacity="0.35"/>
    
    <!-- Lower Stack Layers (Depth) -->
    <polygon points="20,120 220,120 236,105 36,105" fill="#3D684B" stroke="#254330" stroke-width="1"/>
    <polygon points="20,110 220,110 236,95 36,95" fill="#4A7B59" stroke="#254330" stroke-width="1"/>
    <polygon points="20,100 220,100 236,85 36,85" fill="#588E6A" stroke="#254330" stroke-width="1"/>
    <polygon points="20,90 220,90 236,75 36,75" fill="#69A17C" stroke="#254330" stroke-width="1"/>
    
    <!-- Top Banknote Face -->
    <polygon points="20,80 220,80 236,65 36,65" fill="url(#billGreen)" stroke="#254330" stroke-width="1.5"/>
    
    <!-- Banknote Details -->
    <polygon points="30,78 210,78 224,67 44,67" fill="none" stroke="#2B5438" stroke-width="1" stroke-dasharray="3,1.5"/>
    <ellipse cx="128" cy="72" rx="28" ry="6" fill="none" stroke="#2B5438" stroke-width="1.2"/>
    <text x="128" y="75" font-family="serif" font-weight="bold" font-size="10" fill="#22422C" text-anchor="middle">100</text>
    
    <!-- Paper Currency Strap Binding -->
    <polygon points="112,81 144,81 154,64 122,64" fill="url(#bankStrap)" stroke="#5A4E33" stroke-width="1"/>
    <line x1="113" y1="81" x2="113" y2="120" stroke="#7A6C4D" stroke-width="1"/>
    <line x1="143" y1="81" x2="143" y2="120" stroke="#7A6C4D" stroke-width="1"/>
    <rect x="113" y="81" width="30" height="39" fill="url(#bankStrap)"/>
    <text x="128" y="104" font-family="sans-serif" font-weight="bold" font-size="7" fill="#802020" text-anchor="middle">$10,000</text>
  </svg>`;
  await renderSvgToPng(moneyStackSvg, 256, 160, 'assets/sprites/ui/money_stack_bribe.png');

  // ==========================================
  // 4. PRESS CONFERENCE ASSETS
  // ==========================================

  // 4.1 press_microphone_cluster.png (320x180 Cluster of Podium Microphones)
  const microClusterSvg = `
  <svg width="320" height="180" viewBox="0 0 320 180" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="metalChrome" x1="0%" y1="0%" x2="100%" y2="0%">
        <stop offset="0%" stop-color="#E8E8E8"/>
        <stop offset="50%" stop-color="#999999"/>
        <stop offset="100%" stop-color="#444444"/>
      </linearGradient>
      <linearGradient id="podiumWood" x1="0%" y1="0%" x2="0%" y2="100%">
        <stop offset="0%" stop-color="#552211"/>
        <stop offset="50%" stop-color="#3A160A"/>
        <stop offset="100%" stop-color="#240D06"/>
      </linearGradient>
    </defs>
    <!-- Podium Top Rail -->
    <rect x="20" y="140" width="280" height="40" rx="4" fill="url(#podiumWood)" stroke="#1A0803" stroke-width="2"/>
    <line x1="20" y1="143" x2="300" y2="143" stroke="#D4AF37" stroke-width="2"/>
    
    <!-- Mic 1: Left Angled (Channel 7 Blue Cube) -->
    <line x1="90" y1="140" x2="110" y2="70" stroke="url(#metalChrome)" stroke-width="5" stroke-linecap="round"/>
    <rect x="96" y="44" width="28" height="26" rx="3" fill="#1565C0" stroke="#0D47A1" stroke-width="1.5"/>
    <text x="110" y="62" font-family="sans-serif" font-weight="900" font-size="14" fill="#FFF" text-anchor="middle">7</text>
    <ellipse cx="110" cy="36" rx="9" ry="12" fill="#282828" stroke="#111" stroke-width="1.5"/>
    
    <!-- Mic 2: Center Tall (WMAY News Mayoral Red Cube) -->
    <line x1="160" y1="140" x2="160" y2="50" stroke="url(#metalChrome)" stroke-width="6" stroke-linecap="round"/>
    <rect x="144" y="24" width="32" height="28" rx="3" fill="#C62828" stroke="#B71C1C" stroke-width="1.5"/>
    <text x="160" y="42" font-family="sans-serif" font-weight="bold" font-size="8.5" fill="#FFF" text-anchor="middle">WMAY</text>
    <ellipse cx="160" cy="14" rx="10" ry="13" fill="#222" stroke="#111" stroke-width="1.5"/>
    
    <!-- Mic 3: Right Angled (Tribune Radio Yellow/Black Cube) -->
    <line x1="230" y1="140" x2="210" y2="70" stroke="url(#metalChrome)" stroke-width="5" stroke-linecap="round"/>
    <rect x="196" y="44" width="28" height="26" rx="3" fill="#F9A825" stroke="#F57F17" stroke-width="1.5"/>
    <text x="210" y="61" font-family="sans-serif" font-weight="900" font-size="10" fill="#1A1A1A" text-anchor="middle">TRIB</text>
    <ellipse cx="210" cy="36" rx="9" ry="12" fill="#282828" stroke="#111" stroke-width="1.5"/>
  </svg>`;
  await renderSvgToPng(microClusterSvg, 320, 180, 'assets/sprites/ui/press_microphone_cluster.png');

  // 4.2 press_flash_particle.png (32x32 Camera Flash Starburst)
  const flashParticleSvg = `
  <svg width="32" height="32" viewBox="0 0 32 32" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <radialGradient id="flashGlow" cx="50%" cy="50%" r="50%">
        <stop offset="0%" stop-color="#FFFFFF"/>
        <stop offset="25%" stop-color="#E8F4FF"/>
        <stop offset="60%" stop-color="#90CAF9" stop-opacity="0.6"/>
        <stop offset="100%" stop-color="#2196F3" stop-opacity="0.0"/>
      </radialGradient>
    </defs>
    <!-- Soft Glow Core -->
    <circle cx="16" cy="16" r="15" fill="url(#flashGlow)"/>
    <!-- 4-point Diamond Star Rays -->
    <polygon points="16,1 18,14 31,16 18,18 16,31 14,18 1,16 14,14" fill="#FFFFFF"/>
    <circle cx="16" cy="16" r="3.5" fill="#FFFFFF"/>
  </svg>`;
  await renderSvgToPng(flashParticleSvg, 32, 32, 'assets/sprites/ui/press_flash_particle.png');

  // ==========================================
  // 5. MAIN MENU CINEMATIC ASSETS
  // ==========================================

  // 5.1 menu_twilight_city.png (1920x1080 High-Rise Dusk Establishing Shot)
  const menuBackdropSvg = `
  <svg width="1920" height="1080" viewBox="0 0 1920 1080" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="twilightSky" x1="0%" y1="0%" x2="0%" y2="100%">
        <stop offset="0%" stop-color="#080A14"/>
        <stop offset="30%" stop-color="#14182B"/>
        <stop offset="55%" stop-color="#2D1A38"/>
        <stop offset="75%" stop-color="#5C2642"/>
        <stop offset="88%" stop-color="#9C4444"/>
        <stop offset="96%" stop-color="#E07938"/>
        <stop offset="100%" stop-color="#F2A65A"/>
      </linearGradient>
      <linearGradient id="deskWood" x1="0%" y1="0%" x2="0%" y2="100%">
        <stop offset="0%" stop-color="#24140D"/>
        <stop offset="30%" stop-color="#150C07"/>
        <stop offset="100%" stop-color="#080402"/>
      </linearGradient>
      <radialGradient id="lampGlow" cx="25%" cy="80%" r="45%">
        <stop offset="0%" stop-color="#FFEAA7" stop-opacity="0.25"/>
        <stop offset="50%" stop-color="#F39C12" stop-opacity="0.08"/>
        <stop offset="100%" stop-color="#000000" stop-opacity="0.0"/>
      </radialGradient>
    </defs>
    
    <!-- 1. Dusk Twilight Sky -->
    <rect width="1920" height="1080" fill="url(#twilightSky)"/>
    
    <!-- 2. Far Layer Mountain Silhouettes -->
    <polygon points="0,750 240,710 520,740 850,700 1200,730 1550,690 1920,740 1920,850 0,850" fill="#10111A" opacity="0.6"/>
    
    <!-- 3. Distant City Skyline Silhouettes -->
    <g fill="#121420">
      <rect x="80" y="520" width="90" height="330"/>
      <polygon points="80,520 125,480 170,520"/>
      <rect x="210" y="460" width="110" height="390"/>
      <rect x="360" y="540" width="80" height="310"/>
      <rect x="480" y="420" width="140" height="430"/>
      <polygon points="480,420 550,380 620,420"/>
      <rect x="660" y="490" width="100" height="360"/>
      <rect x="800" y="440" width="130" height="410"/>
      <rect x="970" y="390" width="160" height="460"/>
      <polygon points="1045,390 1050,320 1055,390"/>
      <rect x="1170" y="470" width="110" height="380"/>
      <rect x="1320" y="430" width="130" height="420"/>
      <rect x="1490" y="500" width="100" height="350"/>
      <rect x="1630" y="460" width="120" height="390"/>
      <polygon points="1630,460 1690,410 1750,460"/>
      <rect x="1780" y="530" width="90" height="320"/>
    </g>
    
    <!-- 4. Midground Illuminated Towers with Lit Windows -->
    <g fill="#0B0C14">
      <rect x="150" y="560" width="120" height="300"/>
      <rect x="310" y="510" width="140" height="350"/>
      <rect x="520" y="470" width="160" height="390"/>
      <rect x="730" y="540" width="130" height="320"/>
      <rect x="910" y="460" width="180" height="400"/>
      <polygon points="995,460 1000,410 1005,460"/>
      <rect x="1140" y="520" width="150" height="340"/>
      <rect x="1340" y="480" width="170" height="380"/>
      <rect x="1560" y="530" width="130" height="330"/>
      <rect x="1730" y="580" width="120" height="280"/>
    </g>
    
    <!-- Golden & Cyan Illuminated Window Dots in Towers -->
    <g fill="#FFEAA7" opacity="0.6">
      <rect x="330" y="540" width="6" height="8"/><rect x="350" y="540" width="6" height="8"/><rect x="380" y="540" width="6" height="8"/>
      <rect x="330" y="560" width="6" height="8"/><rect x="360" y="560" width="6" height="8"/><rect x="410" y="560" width="6" height="8"/>
      <rect x="340" y="580" width="6" height="8"/><rect x="380" y="580" width="6" height="8"/>
      <rect x="550" y="500" width="8" height="10"/><rect x="580" y="500" width="8" height="10"/><rect x="620" y="500" width="8" height="10"/>
      <rect x="560" y="530" width="8" height="10"/><rect x="600" y="530" width="8" height="10"/>
      <rect x="940" y="490" width="8" height="10"/><rect x="980" y="490" width="8" height="10"/><rect x="1030" y="490" width="8" height="10"/>
      <rect x="950" y="520" width="8" height="10"/><rect x="1000" y="520" width="8" height="10"/><rect x="1040" y="520" width="8" height="10"/>
      <rect x="1370" y="510" width="8" height="10"/><rect x="1420" y="510" width="8" height="10"/><rect x="1460" y="510" width="8" height="10"/>
    </g>
    <g fill="#81ECEC" opacity="0.5">
      <rect x="370" y="540" width="6" height="8"/><rect x="400" y="570" width="6" height="8"/>
      <rect x="590" y="510" width="8" height="10"/><rect x="640" y="540" width="8" height="10"/>
      <rect x="960" y="500" width="8" height="10"/><rect x="1010" y="530" width="8" height="10"/>
      <rect x="1390" y="530" width="8" height="10"/><rect x="1440" y="550" width="8" height="10"/>
    </g>
    
    <!-- 5. Massive High-Rise Office Window Mullions -->
    <line x1="480" y1="0" x2="480" y2="850" stroke="#05060A" stroke-width="18"/>
    <line x1="960" y1="0" x2="960" y2="850" stroke="#05060A" stroke-width="22"/>
    <line x1="1440" y1="0" x2="1440" y2="850" stroke="#05060A" stroke-width="18"/>
    <line x1="0" y1="360" x2="1920" y2="360" stroke="#05060A" stroke-width="16"/>
    
    <!-- 6. Foreground Chiaroscuro Executive Desk & Chair Silhouette -->
    <!-- Heavy Mahogany Desk Plinth across bottom -->
    <rect x="0" y="850" width="1920" height="230" fill="url(#deskWood)"/>
    <line x1="0" y1="850" x2="1920" y2="850" stroke="#D4AF37" stroke-width="4" stroke-opacity="0.8"/>
    <line x1="0" y1="854" x2="1920" y2="854" stroke="#000" stroke-width="2"/>
    
    <!-- Banker's Lamp Warm Glow on Left Side -->
    <rect x="0" y="700" width="800" height="380" fill="url(#lampGlow)"/>
    
    <!-- High-back Executive Chair Silhouette in Center -->
    <path d="M 860,650 Q 960,620 1060,650 L 1080,850 L 840,850 Z" fill="#060304"/>
    <ellipse cx="960" cy="650" rx="90" ry="25" fill="#0E0709"/>
    
    <!-- Steaming Coffee Cup on Left Desk -->
    <rect x="360" y="820" width="30" height="32" rx="4" fill="#1C140E"/>
    <path d="M 390,826 Q 402,836 390,846" fill="none" stroke="#1C140E" stroke-width="3"/>
    <path d="M 370,812 Q 365,800 375,788" fill="none" stroke="#FFF" stroke-width="1.2" opacity="0.3"/>
    <path d="M 380,814 Q 388,802 382,786" fill="none" stroke="#FFF" stroke-width="1.2" opacity="0.25"/>
    
    <!-- Red Telephone Silhouette on Right Desk -->
    <rect x="1560" y="818" width="56" height="34" rx="6" fill="#4A0E12"/>
    <path d="M 1550,816 Q 1588,804 1626,816" fill="none" stroke="#7A181E" stroke-width="8" stroke-linecap="round"/>
    <!-- Glowing Red Indicator LED -->
    <circle cx="1588" cy="834" r="3" fill="#FF3333"/>
    <circle cx="1588" cy="834" r="7" fill="#FF0000" opacity="0.3"/>
  </svg>`;
  await renderSvgToPng(menuBackdropSvg, 1920, 1080, 'assets/sprites/menu/menu_twilight_city.png');

  // 5.2 seal_mayoral_crest_gold.png (256x256 Gold Foil Embossed Mayoral Seal)
  const sealGoldSvg = `
  <svg width="256" height="256" viewBox="0 0 256 256" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <radialGradient id="sealGoldBase" cx="50%" cy="50%" r="50%">
        <stop offset="0%" stop-color="#FFF8CC"/>
        <stop offset="35%" stop-color="#F2CA4B"/>
        <stop offset="70%" stop-color="#B8860B"/>
        <stop offset="95%" stop-color="#6E4E03"/>
        <stop offset="100%" stop-color="#3A2800"/>
      </radialGradient>
      <linearGradient id="ringShine" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="#FFFFFF"/>
        <stop offset="40%" stop-color="#E5B83B"/>
        <stop offset="80%" stop-color="#996515"/>
        <stop offset="100%" stop-color="#4D330A"/>
      </linearGradient>
    </defs>
    <!-- Outer Scalloped Medal Edge -->
    <circle cx="128" cy="128" r="122" fill="url(#sealGoldBase)" stroke="url(#ringShine)" stroke-width="4"/>
    <circle cx="128" cy="128" r="110" fill="#1C1408" stroke="url(#ringShine)" stroke-width="2.5"/>
    <circle cx="128" cy="128" r="104" fill="none" stroke="#E5B83B" stroke-width="1.2" stroke-dasharray="4,3"/>
    
    <!-- Concentric Inner Gilded Core -->
    <circle cx="128" cy="128" r="72" fill="url(#sealGoldBase)" stroke="#3A2800" stroke-width="2"/>
    <circle cx="128" cy="128" r="66" fill="#1C1408"/>
    
    <!-- Central Heraldic Mayoral Double-Headed Eagle & Key -->
    <!-- Key of the City -->
    <line x1="128" y1="88" x2="128" y2="168" stroke="#FFEAA7" stroke-width="5" stroke-linecap="round"/>
    <circle cx="128" cy="88" r="10" fill="none" stroke="#FFEAA7" stroke-width="4"/>
    <rect x="128" y="152" width="12" height="4" fill="#FFEAA7"/>
    <rect x="128" y="162" width="16" height="4" fill="#FFEAA7"/>
    
    <!-- Spread Heraldic Wings -->
    <path d="M 128,110 Q 90,80 68,105 Q 85,125 128,135 Z" fill="#FFEAA7" opacity="0.9"/>
    <path d="M 128,110 Q 166,80 188,105 Q 171,125 128,135 Z" fill="#FFEAA7" opacity="0.9"/>
    
    <!-- Laurel Wreath Around Rim -->
    <path d="M 45,130 Q 55,200 128,212 Q 201,200 211,130" fill="none" stroke="url(#ringShine)" stroke-width="4" stroke-linecap="round"/>
    
    <!-- Circular Latin Mayoral Inscription -->
    <text x="128" y="44" font-family="serif" font-weight="900" font-size="11.5" fill="#FFEAA7" text-anchor="middle" letter-spacing="3.5">OFFICIUM PRAETORIS</text>
    <text x="128" y="234" font-family="serif" font-weight="bold" font-size="10.5" fill="#FFEAA7" text-anchor="middle" letter-spacing="3">CONCORDIA CIVITATIS</text>
    
    <!-- Five Authority Stars -->
    <polygon points="128,62 130,67 135,67 131,70 133,75 128,72 123,75 125,70 121,67 126,67" fill="#FFF"/>
  </svg>`;
  await renderSvgToPng(sealGoldSvg, 256, 256, 'assets/sprites/menu/seal_mayoral_crest_gold.png');

  console.log('\nAll 12 Phase 5 Assets Generated Successfully!\n');
}

main().catch(err => {
  console.error('Asset generation failed:', err);
  process.exit(1);
});
