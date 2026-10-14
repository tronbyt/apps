import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';

import {
  adjustTemplateForNestedPage,
  buildAppMetaTags,
  escapeHtmlAttribute,
  findMarkdown,
  findPreview,
} from './generate-apps-json.js';

test('escapes values used in generated HTML', () => {
  assert.equal(
    escapeHtmlAttribute('Fish & Chips <Today> "Now"\nNext'),
    'Fish &amp; Chips &lt;Today&gt; &quot;Now&quot; Next'
  );
});

test('generated app metadata cannot close tags or attributes', () => {
  const metadata = buildAppMetaTags({
    name: 'unsafe\" onload=\"alert(1)',
    displayName: '</title><script>alert(1)</script>',
    summary: '\"><img src=x onerror=alert(1)>',
    image: 'preview\" onerror=\"alert(1).webp'
  });

  assert.doesNotMatch(metadata, /<script|<img/i);
  assert.match(metadata, /&lt;\/title&gt;&lt;script&gt;alert\(1\)&lt;\/script&gt;/);
  assert.match(metadata, /&quot;&gt;&lt;img src=x onerror=alert\(1\)&gt;/);
  assert.match(metadata, /preview&quot; onerror=&quot;alert\(1\)\.webp/);
  assert.doesNotMatch(metadata, /content="[^"]*" on(?:load|error)=/i);
});

test('finds mixed-case README filenames and preserves their actual path', () => {
  assert.equal(findMarkdown(['manifest.yaml', 'README.MD']), 'README.MD');
  assert.equal(findMarkdown(['manifest.yaml', 'ReadMe.md']), 'ReadMe.md');
});

test('prefers conventional README names before case-insensitive fallbacks', () => {
  assert.equal(findMarkdown(['README.MD', 'README.md', 'index.md']), 'README.md');
  assert.equal(findMarkdown(['INDEX.MD', 'ReadMe.md']), 'ReadMe.md');
});

test('picks the same preview screenshot as Tronbyt Server', () => {
  const manifest = { packageName: 'biorhythm', fileName: 'biorhythm.star' };
  // A Pixlet render (.webp) wins over an older photo with the same name
  assert.equal(findPreview(['biorhythm.png', 'biorhythm.webp', 'README.md'], 'biorhythm', manifest, 'biorhythm.star'), 'biorhythm.webp');
  // .jpg isn't a preview format, so an old photo can't hide the render
  assert.equal(findPreview(['iquit.jpg', 'iquit.webp'], 'iquit', { packageName: 'iquit' }, 'iquit.star'), 'iquit.webp');
  // packageName, then the .star file's name, then "screenshot"
  assert.equal(findPreview(['screenshot.png', 'chess_viewer.webp'], 'chessviewer', { packageName: 'chessviewer', fileName: 'chess_viewer.star' }, 'chess_viewer.star'), 'chess_viewer.webp');
  assert.equal(findPreview(['screenshot.png', 'screenshot.webp'], 'rainradar', { packageName: 'rainradar' }, 'rain_radar.star'), 'screenshot.webp');
  assert.equal(findPreview(['other.png', 'screenshot.gif'], 'app', {}, 'app.star'), 'screenshot.gif');
  // Without a conventional name, any image is better than none
  assert.equal(findPreview(['demo.jpg', 'app.star'], 'app', {}, 'app.star'), 'demo.jpg');
  assert.equal(findPreview(['app.star', 'README.md'], 'app', {}, 'app.star'), null);
});

for (const page of ['app.html', 'author.html']) {
  test(`${page}: every home link works from a nested page`, () => {
    const html = adjustTemplateForNestedPage(readFileSync(new URL(page, import.meta.url), 'utf8'));
    assert.equal(html.includes('href="index.html"'), false);
    assert.equal(html.match(/href="\.\.\/index\.html"/g).length, 2); // The header logo and Back to Apps
    assert.ok(html.includes('class="home-link"'));
    assert.ok(html.includes('href="../style.css"'));
    assert.ok(html.includes('src="../main.js"'));
  });
}
