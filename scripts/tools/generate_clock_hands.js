const fs = require('fs');
const sharp = require('sharp');

async function createClockHands() {
  const hourSvg = `
  <svg width="24" height="80" viewBox="0 0 24 80" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="brassH" x1="0%" y1="0%" x2="100%" y2="0%">
        <stop offset="0%" stop-color="#FFE082"/>
        <stop offset="50%" stop-color="#D4AF37"/>
        <stop offset="100%" stop-color="#8C6D1F"/>
      </linearGradient>
    </defs>
    <path d="M 12,6 L 17,28 L 14,70 A 5,5 0 0,1 10,70 L 7,28 Z" fill="url(#brassH)" stroke="#3E2D07" stroke-width="1.5"/>
    <circle cx="12" cy="70" r="4" fill="#D4AF37" stroke="#3E2D07" stroke-width="1.5"/>
  </svg>`;
  await sharp(Buffer.from(hourSvg)).png().toFile('assets/sprites/skyline/clock_hand_hour.png');

  const minSvg = `
  <svg width="20" height="110" viewBox="0 0 20 110" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="brassM" x1="0%" y1="0%" x2="100%" y2="0%">
        <stop offset="0%" stop-color="#FFE082"/>
        <stop offset="50%" stop-color="#D4AF37"/>
        <stop offset="100%" stop-color="#8C6D1F"/>
      </linearGradient>
    </defs>
    <path d="M 10,4 L 14,35 L 12,98 A 4,4 0 0,1 8,98 L 6,35 Z" fill="url(#brassM)" stroke="#3E2D07" stroke-width="1.2"/>
    <circle cx="10" cy="98" r="3.5" fill="#D4AF37" stroke="#3E2D07" stroke-width="1.5"/>
  </svg>`;
  await sharp(Buffer.from(minSvg)).png().toFile('assets/sprites/skyline/clock_hand_minute.png');
  console.log('Clock hands generated!');
}

createClockHands().catch(console.error);
