// Builds the extension, then zips what each store wants into packages/:
//   ferret-chromium-<version>.zip  Chrome Web Store and Edge Add-ons
//   ferret-firefox-<version>.zip   addons.mozilla.org
//   ferret-source-<version>.zip    addons.mozilla.org asks for the source of
//                                  bundled code; it holds the committed files
//                                  of this folder, so it builds the same zip.
import { execFileSync } from 'node:child_process';
import { mkdir, readFile, rm } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = dirname(fileURLToPath(import.meta.url));
const out = join(root, 'packages');
const { version } = JSON.parse(await readFile(join(root, 'package.json'), 'utf8'));

const run = (command, args, cwd = root) =>
  execFileSync(command, args, { cwd, stdio: ['ignore', 'pipe', 'inherit'] }).toString();

const dirty = run('git', ['status', '--porcelain', '--', '.']).trim();
if (dirty && !process.argv.includes('--dirty')) {
  console.error('Commit the extension first: the source zip comes from git.\n' + dirty);
  console.error('Pass --dirty to package anyway (for a local try only).');
  process.exit(1);
}

run('node', ['build.mjs']);
await rm(out, { recursive: true, force: true });
await mkdir(out, { recursive: true });

for (const target of ['chromium', 'firefox']) {
  const zip = join(out, `ferret-${target}-${version}.zip`);
  run('zip', ['-q', '-X', '-r', zip, '.'], join(root, 'dist', target));
  console.log(`Packed packages/${target === 'chromium' ? 'ferret-chromium' : 'ferret-firefox'}-${version}.zip`);
}

const source = join(out, `ferret-source-${version}.zip`);
run('git', ['archive', '--format=zip', `--output=${source}`, 'HEAD:extensions/browser'], join(root, '..', '..'));
console.log(`Packed packages/ferret-source-${version}.zip`);
