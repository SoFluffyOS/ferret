// Builds the extension for Chromium and Firefox into dist/<target>/.
// Everything is bundled locally; nothing is loaded from the network.
import { build } from 'esbuild';
import { cp, mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

import { manifestFor } from './manifest.mjs';

const root = dirname(fileURLToPath(import.meta.url));
const targets = ['chromium', 'firefox'];
const entries = {
  background: 'src/background.ts',
  popup: 'src/popup/popup.ts',
  options: 'src/options/options.ts',
};
const pages = ['src/popup/popup.html', 'src/options/options.html', 'src/ui.css'];

const { version } = JSON.parse(await readFile(join(root, 'package.json'), 'utf8'));

for (const target of targets) {
  const out = join(root, 'dist', target);
  await rm(out, { recursive: true, force: true });
  await mkdir(out, { recursive: true });

  await build({
    entryPoints: Object.fromEntries(
      Object.entries(entries).map(([name, path]) => [name, join(root, path)]),
    ),
    outdir: out,
    bundle: true,
    format: 'iife',
    target: target === 'firefox' ? 'firefox128' : 'chrome116',
    legalComments: 'none',
    logLevel: 'warning',
  });

  for (const page of pages) {
    await cp(join(root, page), join(out, page.split('/').pop()));
  }

  await cp(join(root, 'icons'), join(out, 'icons'), { recursive: true });
  await writeFile(
    join(out, 'manifest.json'),
    `${JSON.stringify(manifestFor(target, version), null, 2)}\n`,
  );
  console.log(`Built dist/${target}`);
}
