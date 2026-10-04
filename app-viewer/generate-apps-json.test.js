import assert from 'node:assert/strict';
import test from 'node:test';

import { buildAppMetaTags, escapeHtmlAttribute, findMarkdown } from './generate-apps-json.js';

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
