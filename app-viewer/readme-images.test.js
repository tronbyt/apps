import test from 'node:test';
import assert from 'node:assert/strict';

import { classifyReadmeImage, normalizeReadmeImageUrl } from './readme-images.js';

test('recognizes standard device screenshots at integer scales', () => {
  assert.equal(classifyReadmeImage({ width: 64, height: 32 }), 'standard');
  assert.equal(classifyReadmeImage({ width: 320, height: 160 }), 'standard');
});

test('recognizes supported wide and square screenshots', () => {
  assert.equal(classifyReadmeImage({
    width: 128,
    height: 64,
    supports2x: true
  }), 'wide');
  assert.equal(classifyReadmeImage({
    width: 256,
    height: 128,
    source: 'example@2x.gif',
    supports2x: true
  }), 'wide');
  assert.equal(classifyReadmeImage({
    width: 192,
    height: 192,
    supports64x64: true
  }), 'square');
});

test('does not classify unsupported or ordinary README artwork', () => {
  assert.equal(classifyReadmeImage({ width: 192, height: 192 }), null);
  assert.equal(classifyReadmeImage({ width: 1200, height: 630, supports2x: true }), null);
  assert.equal(classifyReadmeImage({ width: 15, height: 15, supports64x64: true }), null);
  assert.equal(classifyReadmeImage({ width: 0, height: 0 }), null);
});

test('converts GitHub blob image links to raw asset links', () => {
  assert.equal(
    normalizeReadmeImageUrl('https://github.com/example/community/blob/main/apps/demo/demo.gif'),
    'https://raw.githubusercontent.com/example/community/main/apps/demo/demo.gif'
  );
  assert.equal(normalizeReadmeImageUrl('demo.gif'), 'demo.gif');
});
