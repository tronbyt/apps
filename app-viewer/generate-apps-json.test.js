import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';

import {
  adjustTemplateForNestedPage,
  buildAppMetaTags,
  buildAppPrerender,
  buildAuthorPrerender,
  buildSitemap,
  escapeHtmlAttribute,
  findMarkdown,
} from './generate-apps-json.js';

test('escapes values used in generated HTML', () => {
  assert.equal(
    escapeHtmlAttribute('Fish & Chips <Today> "Now"\nNext'),
    'Fish &amp; Chips &lt;Today&gt; &quot;Now&quot; Next'
  );
});

test('generated app metadata cannot close tags or attributes', () => {
  const app = {
    name: 'unsafe\" onload=\"alert(1)',
    displayName: '</title><script>alert(1)</script>',
    summary: '\"><img src=x onerror=alert(1)>',
  };
  const metadata = buildAppMetaTags(app, 'cards/preview\" onerror=\"alert(1).png');

  // The structured data is the only element added, and nothing in it can end it early
  const structured = metadata.match(/<script type="application\/ld\+json">([\s\S]*?)<\/script>/);
  assert.ok(structured);
  assert.doesNotMatch(structured[1], /</);
  assert.equal(JSON.parse(structured[1]).name, app.displayName);

  const tags = metadata.replace(structured[0], '');
  assert.doesNotMatch(tags, /<script|<img/i);
  assert.match(tags, /&lt;\/title&gt;&lt;script&gt;alert\(1\)&lt;\/script&gt;/);
  assert.match(tags, /&quot;&gt;&lt;img src=x onerror=alert\(1\)&gt;/);
  assert.match(tags, /preview&quot; onerror=&quot;alert\(1\)\.png/);
  assert.doesNotMatch(tags, /content="[^"]*" on(?:load|error)=/i);
});

test('app pages have share tags pointing at the app\'s card', () => {
  const metadata = buildAppMetaTags({ name: 'clock', displayName: 'Clock', summary: 'Tells the time' }, 'cards/clock-0123456789.png');
  assert.match(metadata, /<meta property="og:image" content="https:\/\/tronbyt\.github\.io\/apps\/cards\/clock-0123456789\.png">/);
  assert.match(metadata, /<meta property="og:image:width" content="1200">/);
  assert.match(metadata, /<meta name="twitter:card" content="summary_large_image">/);
  assert.match(metadata, /<link rel="canonical" href="https:\/\/tronbyt\.github\.io\/apps\/details\/clock\.html">/);
});

test('the details written into app and author pages are escaped', () => {
  const app = {
    name: 'bad',
    displayName: '<script>x</script>',
    description: '<img src=x onerror=alert(1)>',
    author: '<b>Author</b>',
    authorSlug: 'author',
    tags: ['"><script>'],
  };
  for (const html of [buildAppPrerender(app), buildAuthorPrerender({ displayName: '<i>Author</i>', apps: [app] })]) {
    assert.doesNotMatch(html, /<script|<img|<b>|<i>/i);
  }
  assert.match(buildAppPrerender(app), /href="\.\.\/authors\/author\.html"/);
  assert.match(buildAuthorPrerender({ displayName: 'Author', apps: [app] }), /href="\.\.\/details\/bad\.html"/);
});

test('the sitemap lists every page, with dates where an app has one', () => {
  const sitemap = buildSitemap(
    [{ name: 'clock', updated: '2026-10-01T12:00:00Z' }, { name: 'a&b' }],
    [{ slug: 'olly' }],
  );
  assert.match(sitemap, /<loc>https:\/\/tronbyt\.github\.io\/apps\/<\/loc>/);
  assert.match(sitemap, /<loc>https:\/\/tronbyt\.github\.io\/apps\/details\/clock\.html<\/loc><lastmod>2026-10-01<\/lastmod>/);
  assert.match(sitemap, /details\/a%26b\.html<\/loc><\/url>/);
  assert.match(sitemap, /<loc>https:\/\/tronbyt\.github\.io\/apps\/authors\/olly\.html<\/loc>/);
});

test('finds mixed-case README filenames and preserves their actual path', () => {
  assert.equal(findMarkdown(['manifest.yaml', 'README.MD']), 'README.MD');
  assert.equal(findMarkdown(['manifest.yaml', 'ReadMe.md']), 'ReadMe.md');
});

test('prefers conventional README names before case-insensitive fallbacks', () => {
  assert.equal(findMarkdown(['README.MD', 'README.md', 'index.md']), 'README.md');
  assert.equal(findMarkdown(['INDEX.MD', 'ReadMe.md']), 'ReadMe.md');
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
