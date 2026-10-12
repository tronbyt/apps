import assert from 'node:assert/strict';
import test from 'node:test';

const replacedUrls = [];
const restoredPositions = [];

globalThis.window = {
  location: {
    href: 'http://127.0.0.1:8890/app-viewer/index.html?count=120',
    pathname: '/app-viewer/index.html',
    search: '?count=120'
  },
  history: {
    state: { viewer: true },
    replaceState(state, title, url) {
      replacedUrls.push({ state, title, url: String(url) });
    }
  },
  scrollTo(x, y) {
    restoredPositions.push({ x, y });
  },
  scrollY: 4321
};

globalThis.document = {
  addEventListener() {},
  fonts: { ready: Promise.resolve() }
};

globalThis.requestAnimationFrame = callback => {
  callback();
  return 1;
};

const {
  buildAppSourceUrl,
  filterAndSortApps,
  normalizeCatalogueMetadata,
  rememberViewerScroll,
  restoreViewerScroll
} = await import('./main.js');

test('saves catalogue scroll state before navigating to app details', () => {
  const currentTarget = {
    href: 'http://127.0.0.1:8890/app-viewer/details/example.html?count=120'
  };

  rememberViewerScroll({ currentTarget });

  assert.equal(
    replacedUrls.at(-1).url,
    'http://127.0.0.1:8890/app-viewer/index.html?count=120&scroll=4321'
  );
  assert.equal(
    currentTarget.href,
    'http://127.0.0.1:8890/app-viewer/details/example.html?count=120&scroll=4321'
  );
});

test('restores scroll immediately and again after fonts settle', async () => {
  restoredPositions.length = 0;

  restoreViewerScroll(4321);
  await document.fonts.ready;
  await Promise.resolve();

  assert.deepEqual(restoredPositions, [
    { x: 0, y: 4321 },
    { x: 0, y: 4321 },
    { x: 0, y: 4321 }
  ]);
});

test('accepts official or fork catalogue provenance without guessing invalid metadata', () => {
  const metadata = normalizeCatalogueMetadata({
    schemaVersion: 1,
    repository: 'github.com/Example-Fork/Apps',
    commit: 'ABCDEF0123456789ABCDEF0123456789ABCDEF01'
  });

  assert.deepEqual(metadata, {
    repository: 'github.com/example-fork/apps',
    commit: 'abcdef0123456789abcdef0123456789abcdef01'
  });
  assert.equal(
    buildAppSourceUrl(metadata, 'jsondisplay'),
    'https://github.com/example-fork/apps/tree/main/apps/jsondisplay'
  );
  assert.equal(normalizeCatalogueMetadata({
    schemaVersion: 1,
    repository: 'example.com/tronbyt/apps',
    commit: 'abcdef0123456789abcdef0123456789abcdef01'
  }), null);
  assert.equal(buildAppSourceUrl(null, 'jsondisplay'), null);
});

test('composes catalogue search, filters, broken state and sorting before batching', () => {
  const apps = [
    {
      name: 'alpha', displayName: 'Alpha', summary: 'Weather map', author: 'Alice',
      category: 'weather', tags: ['map'], supports2x: true, supports64x64: false,
      published: '2026-01-01T00:00:00Z', updated: '2026-03-01T00:00:00Z', starFile: 'alpha.star'
    },
    {
      name: 'beta', displayName: 'Beta', description: 'Transit times', author: 'Bob',
      category: 'transit', tags: ['local', 'map'], supports2x: false, supports64x64: true,
      published: '2026-02-01T00:00:00Z', updated: '2026-02-01T00:00:00Z', starFile: 'beta.star'
    },
    {
      name: 'gamma', displayName: 'Gamma', summary: 'Score board', author: 'Carol',
      category: 'sports', tags: ['scores'], supports2x: true, supports64x64: true,
      published: '2026-03-01T00:00:00Z', updated: '2026-01-01T00:00:00Z', broken: true
    }
  ];

  assert.deepEqual(filterAndSortApps(apps, { search: 'bob' }).map(app => app.name), ['beta']);
  assert.deepEqual(filterAndSortApps(apps, { tag: 'map', display: 'square' }).map(app => app.name), ['beta']);
  assert.deepEqual(filterAndSortApps(apps, {
    category: 'weather', display: 'wide', sort: 'alphabetical'
  }).map(app => app.name), ['alpha']);
  assert.deepEqual(filterAndSortApps(apps, {
    hideBroken: true, brokenApps: ['alpha.star'], sort: 'newest'
  }).map(app => app.name), ['beta']);
});
