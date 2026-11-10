import assert from 'node:assert/strict';
import { mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { test } from 'node:test';

import { missingSiteReferences } from './check-app-viewer-site.mjs';
import { catalogueMetadata } from './write-app-viewer-catalogue-metadata.mjs';

test('catalogue metadata identifies the repository and full commit', () => {
  assert.deepEqual(
    catalogueMetadata('Tronbyt/Apps', 'A'.repeat(40)),
    {
      schemaVersion: 1,
      repository: 'github.com/tronbyt/apps',
      commit: 'a'.repeat(40),
    },
  );
});

test('catalogue metadata rejects invalid build provenance', () => {
  assert.throws(() => catalogueMetadata('tronbyt/apps/extra', 'a'.repeat(40)));
  assert.throws(() => catalogueMetadata('tronbyt/apps', 'not-a-commit'));
});

function siteFixture(t) {
  const root = mkdtempSync(join(tmpdir(), 'app-viewer-site-'));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  for (const file of ['app.html', 'style.css', 'apps.json', 'catalogue-meta.json']) {
    writeFileSync(join(root, file), '');
  }
  return root;
}

test('site check follows complete local scripts, modules, and styles', (t) => {
  const root = siteFixture(t);
  writeFileSync(
    join(root, 'index.html'),
    '<link href="style.css" rel="stylesheet"><script type="module" src="main.js"></script>',
  );
  writeFileSync(join(root, 'main.js'), "import './readme-images.js';\n");
  writeFileSync(join(root, 'readme-images.js'), 'export const supported = true;\n');

  assert.deepEqual(missingSiteReferences(root), []);
});

test('site check reports missing local references', (t) => {
  const root = siteFixture(t);
  writeFileSync(join(root, 'main.js'), '');
  writeFileSync(join(root, 'index.html'), '<script type="module" src="missing.js"></script>');

  assert.deepEqual(missingSiteReferences(root), ['index.html -> missing.js']);
});

test('site check ignores unrelated JavaScript copied with app assets', (t) => {
  const root = siteFixture(t);
  writeFileSync(join(root, 'index.html'), '<script src="main.js"></script>');
  writeFileSync(join(root, 'main.js'), '');
  writeFileSync(join(root, 'unused-app-asset.js'), "import './not-deployed.js';\n");

  assert.deepEqual(missingSiteReferences(root), []);
});
