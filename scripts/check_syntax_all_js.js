const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const dir = path.join(__dirname, '..', 'admin-web');
const files = [];

function getFiles(d) {
  for (const f of fs.readdirSync(d)) {
    const fp = path.join(d, f);
    if (fs.statSync(fp).isDirectory()) {
      if (f !== 'node_modules' && f !== '.git') getFiles(fp);
    } else if (f.endsWith('.js')) {
      files.push(fp);
    }
  }
}

getFiles(dir);

console.log(`Checking syntax of ${files.length} JavaScript files...`);

let hasError = false;
for (const file of files) {
  try {
    // node --check checks syntax without executing
    execSync(`node --check "${file}"`, { stdio: 'pipe' });
    console.log(`PASS: ${path.relative(dir, file)}`);
  } catch (err) {
    hasError = true;
    console.error(`FAIL: ${path.relative(dir, file)}`);
    console.error(err.stderr.toString());
  }
}

if (hasError) {
  process.exit(1);
} else {
  console.log('All JS files passed syntax check!');
}
