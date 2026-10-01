const fs = require('fs');
const path = require('path');

const scenes = [
  'scenes/desk/DeskView.tscn',
  'scenes/desk/SkylineView.tscn',
  'scenes/desk/RedTelephone.tscn',
  'scenes/desk/DeskShredder.tscn'
];

let hasErrors = false;

for (const scn of scenes) {
  const content = fs.readFileSync(scn, 'utf8');
  console.log(`Validating ${scn}...`);
  
  // Extract ext_resources
  const extRegex = /\[ext_resource[^\]]+path="([^"]+)"[^\]]*\]/g;
  let match;
  while ((match = extRegex.exec(content)) !== null) {
    const resPath = match[1];
    const fsPath = resPath.replace('res://', '');
    if (!fs.existsSync(fsPath)) {
      console.error(`  ERROR in ${scn}: Resource not found: ${resPath} (resolved: ${fsPath})`);
      hasErrors = true;
    } else {
      console.log(`  OK resource: ${resPath}`);
    }
  }

  // Check sub_resources references
  const subIds = new Set();
  const subDefRegex = /\[sub_resource[^\]]+id="([^"]+)"[^\]]*\]/g;
  while ((match = subDefRegex.exec(content)) !== null) {
    subIds.add(match[1]);
  }
  const subRefRegex = /SubResource\("([^"]+)"\)/g;
  while ((match = subRefRegex.exec(content)) !== null) {
    const refId = match[1];
    if (!subIds.has(refId)) {
      console.error(`  ERROR in ${scn}: Missing SubResource definition for "${refId}"`);
      hasErrors = true;
    }
  }
}

if (!hasErrors) {
  console.log('\nALL SCENES VALIDATED SUCCESSFULLY WITH ZERO MISSING RESOURCES OR BROKEN REFERENCES!');
} else {
  console.error('\nVALIDATION FAILED WITH ERRORS!');
  process.exit(1);
}
