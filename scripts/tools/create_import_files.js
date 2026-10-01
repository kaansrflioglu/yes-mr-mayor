const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

function getUid() {
  return 'uid://' + crypto.randomBytes(8).toString('hex');
}

function createImportFile(filePath, isBackground = false) {
  const relPath = filePath.replace(/\\/g, '/');
  const importPath = filePath + '.import';
  
  const compressMode = isBackground ? 2 : 0; // 2: VRAM Compressed, 0: Lossless
  const generateMipmaps = isBackground ? 'true' : 'false';

  const content = `[remap]

importer="texture"
type="CompressedTexture2D"
uid="${getUid()}"

[deps]

source_file="res://${relPath}"

[params]

compress/mode=${compressMode}
compress/high_quality=false
compress/lossy_quality=0.7
compress/uastc_level=0
compress/rdo_quality_loss=0.0
compress/hdr_compression=1
compress/normal_map=0
compress/channel_pack=0
mipmaps/generate=${generateMipmaps}
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

  fs.writeFileSync(importPath, content, 'utf8');
  console.log(`Generated: ${importPath}`);
}

function processDirectory(dir) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      processDirectory(fullPath);
    } else if (entry.isFile() && entry.name.endsWith('.png')) {
      const isBg = entry.name.includes('desk_mahogany') || 
                   entry.name.includes('office_wall') || 
                   entry.name.includes('skyline_far');
      createImportFile(fullPath, isBg);
    }
  }
}

processDirectory('assets/sprites');
console.log('All .import files generated successfully!');
