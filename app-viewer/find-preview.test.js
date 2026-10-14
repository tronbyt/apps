import assert from 'node:assert/strict';
import test from 'node:test';

import { findPreview } from './generate-apps-json.js';

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
