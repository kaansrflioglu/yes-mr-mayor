const fs = require('fs');
const path = require('path');
const sharp = require('sharp');

// Create directories if they do not exist
const dirs = [
  'assets/sprites/desk',
  'assets/sprites/props',
  'assets/sprites/documents',
  'assets/sprites/skyline',
  'assets/sprites/ui/slices',
  'assets/sprites/ui/icons',
  'resources/themes'
];
dirs.forEach(d => fs.mkdirSync(d, { recursive: true }));

async function renderSvgToPng(svgString, width, height, outputPath) {
  const buf = Buffer.from(svgString);
  await sharp(buf, { density: 300 })
    .resize(width, height)
    .png()
    .toFile(outputPath);
  console.log(`Rendered: ${outputPath} (${width}x${height})`);
}

// -------------------------------------------------------------
// UI SLICES
// -------------------------------------------------------------
async function generateUiSlices() {
  // Button Brass Normal (96x96)
  const btnNormalSvg = `
  <svg width="96" height="96" viewBox="0 0 96 96" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="brassBorder" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="#FFE082"/>
        <stop offset="50%" stop-color="#D4AF37"/>
        <stop offset="100%" stop-color="#8C6D1F"/>
      </linearGradient>
      <linearGradient id="btnBg" x1="0%" y1="0%" x2="0%" y2="100%">
        <stop offset="0%" stop-color="#362919"/>
        <stop offset="100%" stop-color="#21190E"/>
      </linearGradient>
    </defs>
    <rect x="2" y="2" width="92" height="92" rx="6" fill="url(#btnBg)" stroke="url(#brassBorder)" stroke-width="3"/>
    <rect x="6" y="6" width="84" height="84" rx="4" fill="none" stroke="#D4AF37" stroke-width="1" stroke-opacity="0.4"/>
    <!-- Corner Rivets -->
    <circle cx="8" cy="8" r="2.5" fill="#FFE082" stroke="#5D4037" stroke-width="0.8"/>
    <circle cx="88" cy="8" r="2.5" fill="#FFE082" stroke="#5D4037" stroke-width="0.8"/>
    <circle cx="8" cy="88" r="2.5" fill="#FFE082" stroke="#5D4037" stroke-width="0.8"/>
    <circle cx="88" cy="88" r="2.5" fill="#FFE082" stroke="#5D4037" stroke-width="0.8"/>
  </svg>`;
  await renderSvgToPng(btnNormalSvg, 96, 96, 'assets/sprites/ui/slices/btn_brass_normal.png');

  // Button Brass Hover (96x96)
  const btnHoverSvg = `
  <svg width="96" height="96" viewBox="0 0 96 96" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="brassBorderHov" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="#FFF59D"/>
        <stop offset="50%" stop-color="#FFD54F"/>
        <stop offset="100%" stop-color="#B28900"/>
      </linearGradient>
      <linearGradient id="btnBgHov" x1="0%" y1="0%" x2="0%" y2="100%">
        <stop offset="0%" stop-color="#4E3B24"/>
        <stop offset="100%" stop-color="#2D2113"/>
      </linearGradient>
      <filter id="glow" x="-20%" y="-20%" width="140%" height="140%">
        <feGaussianBlur stdDeviation="3" result="blur"/>
        <feComposite in="SourceGraphic" in2="blur" operator="over"/>
      </filter>
    </defs>
    <rect x="2" y="2" width="92" height="92" rx="6" fill="url(#btnBgHov)" stroke="url(#brassBorderHov)" stroke-width="3" filter="url(#glow)"/>
    <rect x="6" y="6" width="84" height="84" rx="4" fill="none" stroke="#FFF59D" stroke-width="1.5" stroke-opacity="0.7"/>
    <circle cx="8" cy="8" r="2.5" fill="#FFF59D" stroke="#8C6D1F" stroke-width="0.8"/>
    <circle cx="88" cy="8" r="2.5" fill="#FFF59D" stroke="#8C6D1F" stroke-width="0.8"/>
    <circle cx="8" cy="88" r="2.5" fill="#FFF59D" stroke="#8C6D1F" stroke-width="0.8"/>
    <circle cx="88" cy="88" r="2.5" fill="#FFF59D" stroke="#8C6D1F" stroke-width="0.8"/>
  </svg>`;
  await renderSvgToPng(btnHoverSvg, 96, 96, 'assets/sprites/ui/slices/btn_brass_hover.png');

  // Button Brass Pressed (96x96)
  const btnPressedSvg = `
  <svg width="96" height="96" viewBox="0 0 96 96" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="brassBorderPress" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="#8C6D1F"/>
        <stop offset="100%" stop-color="#554010"/>
      </linearGradient>
      <linearGradient id="btnBgPress" x1="0%" y1="0%" x2="0%" y2="100%">
        <stop offset="0%" stop-color="#19130B"/>
        <stop offset="100%" stop-color="#2D2214"/>
      </linearGradient>
    </defs>
    <rect x="2" y="4" width="92" height="90" rx="6" fill="url(#btnBgPress)" stroke="url(#brassBorderPress)" stroke-width="3"/>
    <rect x="6" y="8" width="84" height="82" rx="4" fill="none" stroke="#D4AF37" stroke-width="1" stroke-opacity="0.3"/>
    <circle cx="8" cy="10" r="2.5" fill="#B28900" stroke="#332205" stroke-width="0.8"/>
    <circle cx="88" cy="10" r="2.5" fill="#B28900" stroke="#332205" stroke-width="0.8"/>
    <circle cx="8" cy="88" r="2.5" fill="#B28900" stroke="#332205" stroke-width="0.8"/>
    <circle cx="88" cy="88" r="2.5" fill="#B28900" stroke="#332205" stroke-width="0.8"/>
  </svg>`;
  await renderSvgToPng(btnPressedSvg, 96, 96, 'assets/sprites/ui/slices/btn_brass_pressed.png');

  // Button Disabled (96x96)
  const btnDisabledSvg = `
  <svg width="96" height="96" viewBox="0 0 96 96" xmlns="http://www.w3.org/2000/svg">
    <rect x="2" y="2" width="92" height="92" rx="6" fill="#25272C" stroke="#3C3F46" stroke-width="2"/>
    <rect x="6" y="6" width="84" height="84" rx="4" fill="none" stroke="#50545C" stroke-width="1" stroke-dasharray="3,3"/>
  </svg>`;
  await renderSvgToPng(btnDisabledSvg, 96, 96, 'assets/sprites/ui/slices/btn_brass_disabled.png');

  // Panel Parchment 9Patch (128x128)
  const panelParchmentSvg = `
  <svg width="128" height="128" viewBox="0 0 128 128" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="parchGrad" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="#FDF8EB"/>
        <stop offset="50%" stop-color="#F4EBD9"/>
        <stop offset="100%" stop-color="#EADBBE"/>
      </linearGradient>
      <filter id="parchShadow" x="-10%" y="-10%" width="120%" height="120%">
        <feDropShadow dx="2" dy="3" stdDeviation="3" flood-color="#000" flood-opacity="0.35"/>
      </filter>
    </defs>
    <rect x="4" y="4" width="120" height="120" rx="3" fill="url(#parchGrad)" stroke="#BFAF8F" stroke-width="2" filter="url(#parchShadow)"/>
    <rect x="8" y="8" width="112" height="112" rx="2" fill="none" stroke="#8C795C" stroke-width="0.8" stroke-opacity="0.5"/>
  </svg>`;
  await renderSvgToPng(panelParchmentSvg, 128, 128, 'assets/sprites/ui/slices/panel_parchment_9patch.png');

  // Panel Leather 9Patch (128x128)
  const panelLeatherSvg = `
  <svg width="128" height="128" viewBox="0 0 128 128" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="leatherGrad" x1="0%" y1="0%" x2="0%" y2="100%">
        <stop offset="0%" stop-color="#1A222E"/>
        <stop offset="100%" stop-color="#11161F"/>
      </linearGradient>
    </defs>
    <rect x="2" y="2" width="124" height="124" rx="4" fill="url(#leatherGrad)" stroke="#2C3B4E" stroke-width="2"/>
    <!-- Gold Stitching -->
    <rect x="6" y="6" width="116" height="116" rx="2" fill="none" stroke="#D4AF37" stroke-width="1.2" stroke-dasharray="4,3" stroke-opacity="0.8"/>
    <!-- Brass Corner Rivets -->
    <circle cx="8" cy="8" r="2.5" fill="#D4AF37" stroke="#66521A" stroke-width="0.8"/>
    <circle cx="120" cy="8" r="2.5" fill="#D4AF37" stroke="#66521A" stroke-width="0.8"/>
    <circle cx="8" cy="120" r="2.5" fill="#D4AF37" stroke="#66521A" stroke-width="0.8"/>
    <circle cx="120" cy="120" r="2.5" fill="#D4AF37" stroke="#66521A" stroke-width="0.8"/>
  </svg>`;
  await renderSvgToPng(panelLeatherSvg, 128, 128, 'assets/sprites/ui/slices/panel_leather_9patch.png');

  // Panel Modal Frame (128x128)
  const panelModalSvg = `
  <svg width="128" height="128" viewBox="0 0 128 128" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="modalWood" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="#3A2014"/>
        <stop offset="100%" stop-color="#1C100A"/>
      </linearGradient>
    </defs>
    <rect x="2" y="2" width="124" height="124" rx="6" fill="#141A24" stroke="url(#modalWood)" stroke-width="6"/>
    <rect x="8" y="8" width="112" height="112" rx="3" fill="none" stroke="#D4AF37" stroke-width="1.5"/>
  </svg>`;
  await renderSvgToPng(panelModalSvg, 128, 128, 'assets/sprites/ui/slices/panel_modal_frame.png');
}

generateUiSlices().catch(console.error);
