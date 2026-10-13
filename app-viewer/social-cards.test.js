import assert from 'node:assert/strict';
import test from 'node:test';

import { cardFileName, enlargement, fittingSize, shrink, wrapText } from './social-cards.js';

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
