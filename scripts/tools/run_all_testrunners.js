const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const godotBinary = 'C:\\Program Files (x86)\\Godot Engine\\Godot_v4.7.2-stable_win64_console.exe';
const testsDir = path.join(__dirname, '..', '..', 'tests');

const testFiles = fs.readdirSync(testsDir)
  .filter(f => f.startsWith('TestRunner') && f.endsWith('.tscn'))
  .sort();

console.log(`Found ${testFiles.length} TestRunner scenes to execute.\n`);

let passed = 0;
let failed = 0;
const failures = [];

for (const tf of testFiles) {
  process.stdout.write(`Running ${tf}... `);
  try {
    const cmd = `"${godotBinary}" --headless --path . "res://tests/${tf}"`;
    const output = execSync(cmd, { cwd: path.join(__dirname, '..', '..'), stdio: 'pipe' }).toString();
    console.log('PASSED');
    passed++;
  } catch (err) {
    console.log('FAILED');
    failed++;
    failures.push({
      file: tf,
      output: err.stdout ? err.stdout.toString() : err.message
    });
  }
}

console.log(`\n========================================`);
console.log(`TEST SUITE SUMMARY: ${passed} PASSED, ${failed} FAILED`);
console.log(`========================================\n`);

if (failed > 0) {
  console.log('Failure details:');
  for (const f of failures) {
    console.log(`\n--- ${f.file} ---`);
    console.log(f.output.slice(-800));
  }
  process.exit(1);
} else {
  console.log('ALL TEST RUNNERS PASSED WITH ZERO ERRORS!');
  process.exit(0);
}
