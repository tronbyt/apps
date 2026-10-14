import assert from 'node:assert/strict';
import { mkdtempSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';

import {
  cardFileName,
  enlargement,
  fittingSize,
  isTileable,
  MAX_TILES,
  shrink,
  tiledCardFileName,
  tileGrid,
  wrapText,
} from './social-cards.js';

test('a card gets a new file name when anything on it changes', () => {
  const app = { name: 'clock', displayName: 'Clock', summary: 'Tells the time', author: 'Olly' };
  const name = cardFileName(app, Buffer.from('screenshot'));
  assert.match(name, /^clock-[0-9a-f]{10}\.png$/);
  assert.equal(cardFileName({ ...app }, Buffer.from('screenshot')), name);
  assert.notEqual(cardFileName({ ...app, summary: 'Tells the time well' }, Buffer.from('screenshot')), name);
  assert.notEqual(cardFileName({ ...app, author: 'Someone else' }, Buffer.from('screenshot')), name);
  assert.notEqual(cardFileName(app, Buffer.from('new screenshot')), name);
  assert.notEqual(cardFileName(app, null), name);
});

test('wraps text by words, splitting only words too long for a line', () => {
  assert.deepEqual(wrapText('Shows the time in a big font', 10, 5), ['Shows the', 'time in a', 'big font']);
  assert.deepEqual(wrapText('Alisdair/Akeslo/oleksii-ivanov', 12, 5), ['Alisdair/Ake', 'slo/oleksii-', 'ivanov']);
  assert.deepEqual(wrapText('one two three four five six', 9, 2), ['one two', 'three...']);
  assert.deepEqual(wrapText('   ', 10, 2), []);
});

test('picks the largest text size at which the longest word fits', () => {
  assert.equal(fittingSize('Clock', 416, [32, 24, 16]), 32);
  assert.equal(fittingSize('VisiblePlanets', 416, [32, 24, 16]), 24); // 14 characters: too wide at 32
  assert.equal(fittingSize('averyveryverylongappnamewithoutspaces', 416, [32, 24, 16]), 16);
});

test('recognises screenshots at a display size or a whole-number enlargement of one', () => {
  assert.equal(enlargement(64, 32), 1);
  assert.equal(enlargement(128, 64), 1); // A 2x screenshot is its own display size
  assert.equal(enlargement(64, 64), 1);
  assert.equal(enlargement(640, 320), 5); // 128x64 at 5x: never shrunk below the detail it might have
  assert.equal(enlargement(320, 160), 5); // 64x32 at 5x
  assert.equal(enlargement(320, 320), 5);
  assert.equal(enlargement(1732, 874), 0);
  assert.equal(enlargement(640, 360), 0);
});

test('shrinks an enlarged screenshot back to its pixels', () => {
  // A 2x1 image enlarged 3 times: a red pixel and a blue pixel
  const width = 6, height = 3;
  const data = Buffer.alloc(width * height * 4);
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const o = (y * width + x) * 4;
      data.set(x < 3 ? [255, 0, 0, 255] : [0, 0, 255, 255], o);
    }
  }
  const small = shrink({ data, width, height }, 3);
  assert.equal(small.width, 2);
  assert.equal(small.height, 1);
  assert.deepEqual([...small.data], [255, 0, 0, 255, 0, 0, 255, 255]);
});

test('tiles screenshots in the grid that makes them largest', () => {
  assert.deepEqual([tileGrid(1).columns, tileGrid(1).rows], [1, 1]);
  assert.deepEqual([tileGrid(2).columns, tileGrid(2).rows], [1, 2]); // Two 2:1 screenshots stack in a 640x360 area
  assert.deepEqual([tileGrid(4).columns, tileGrid(4).rows], [2, 2]);
  assert.deepEqual([tileGrid(MAX_TILES).columns, tileGrid(MAX_TILES).rows], [3, 3]);
  assert.ok(tileGrid(1).tileWidth > tileGrid(4).tileWidth);
  assert.ok(tileGrid(4).tileWidth > tileGrid(MAX_TILES).tileWidth);
});

test('an author card gets a new file name when its text or screenshots change', () => {
  const dir = mkdtempSync(join(tmpdir(), 'cards-'));
  const a = join(dir, 'a.webp');
  const b = join(dir, 'b.webp');
  writeFileSync(a, 'one');
  writeFileSync(b, 'two');
  const name = tiledCardFileName('author-olly', ['Olly', 2], [a, b]);
  assert.match(name, /^author-olly-[0-9a-f]{10}\.png$/);
  assert.equal(tiledCardFileName('author-olly', ['Olly', 2], [a, b]), name);
  assert.notEqual(tiledCardFileName('author-olly', ['Olly', 3], [a, b]), name);
  assert.notEqual(tiledCardFileName('author-olly', ['Olly', 2], [b, a]), name);
  writeFileSync(b, 'changed');
  assert.notEqual(tiledCardFileName('author-olly', ['Olly', 2], [a, b]), name);
  assert.ok(tiledCardFileName('author-olly', ['Olly', 2], [a, join(dir, 'missing.webp')])); // Unreadable files are tolerated
});

test('only tiles display renders with something lit', () => {
  const frame = lit => {
    const data = Buffer.alloc(64 * 32 * 4);
    for (let p = 0; p < 64 * 32; p++) {
      if (p < lit * 64 * 32) data.set([255, 255, 255, 255], p * 4);
      else data[p * 4 + 3] = 255;
    }
    return { data, width: 64, height: 32 };
  };
  assert.equal(isTileable({ pixels: true, frame: frame(0.2) }), true);
  assert.equal(isTileable({ pixels: true, frame: frame(0) }), false); // Blank
  assert.equal(isTileable({ pixels: true, frame: frame(0.01) }), false); // Nearly blank
  assert.equal(isTileable({ pixels: false, frame: frame(0.5) }), false); // A photo or odd-sized image
});
