// Social cards: the 1200x630 images shown when an App Viewer page is shared (Open Graph / Twitter cards).
// Each card shows the app's screenshot as an LED dot matrix, with its name, summary and author.
import { createHash } from 'crypto';
import { readFileSync } from 'fs';
import { join } from 'path';
import opentype from 'opentype.js';
import sharp from 'sharp';

export const CARD_WIDTH = 1200;
export const CARD_HEIGHT = 630;

// Change this when the card design changes, so every card gets a new file name and sharing sites fetch it again
const CARD_VERSION = 1;

const SOCIAL_DIR = new URL('./social/', import.meta.url);
const LOGO = readFileSync(new URL('tronbyt-logo.png', SOCIAL_DIR));
const BACKGROUND = '#181818';
const TITLE_COLOR = '#ffd700';
const TEXT_COLOR = '#e0e0e0';
const AUTHOR_COLOR = '#9ccfc1';
const SITE_COLOR = '#888888';

// The screen area of the card
const SCREEN_LEFT = 60;
const SCREEN_TOP = 150;
const SCREEN_WIDTH = 640;
const SCREEN_HEIGHT = 360;
const TEXT_LEFT = 740;
const TEXT_WIDTH = 416;

// Largest first, so an enlargement is shrunk no further than it needs to be
const DISPLAYS = [[128, 64], [64, 64], [64, 32]];

// Text is drawn as shapes from the font file, so cards look the same wherever they are built, whatever fonts are
// installed. Press Start 2P is monospaced (every character is `size` wide) and drawn on an 8 pixel grid, so sizes
// are multiples of 8 and lines are wrapped by character count.
const font = opentype.parse(readFileSync(new URL('PressStart2P-Regular.ttf', SOCIAL_DIR)).buffer);

// The file name for an app's card: changes whenever anything shown on the card changes
export function cardFileName(app, screenshot) {
  const hash = createHash('sha256')
    .update(JSON.stringify([CARD_VERSION, app.displayName || app.name, app.summary || app.description || '', app.author || '']))
    .update(screenshot || '')
    .digest('hex')
    .slice(0, 10);
  return `${app.name}-${hash}.png`;
}

export function wrapText(text, perLine, maxLines) {
  const lines = [];
  let line = '';
  for (let word of text.split(/\s+/).filter(Boolean)) {
    while ([...word].length > perLine) { // A word longer than a line is split
      if (line) {
        lines.push(line);
        line = '';
      }
      lines.push([...word].slice(0, perLine).join(''));
      word = [...word].slice(perLine).join('');
    }
    if (!line) line = word;
    else if ([...line].length + 1 + [...word].length <= perLine) line += ' ' + word;
    else {
      lines.push(line);
      line = word;
    }
  }
  if (line) lines.push(line);
  if (lines.length > maxLines) {
    lines.length = maxLines;
    lines[maxLines - 1] = [...lines[maxLines - 1]].slice(0, perLine - 3).join('').trimEnd() + '...';
  }
  return lines;
}

// The largest of the sizes at which the longest word fits on a line, so words aren't split if it can be helped
export function fittingSize(text, width, sizes) {
  const longest = Math.max(0, ...text.split(/\s+/).map(word => [...word].length));
  return sizes.find(size => longest * size <= width) || sizes[sizes.length - 1];
}

async function renderText(text, size, width, color, maxLines) {
  const lineHeight = Math.round(size * 1.6);
  const known = [...text].map(ch => (font.charToGlyph(ch).index ? ch : '?')).join(''); // Characters the font lacks
  const lines = wrapText(known, Math.floor(width / size), maxLines);
  if (!lines.length) return null;
  const path = lines.map((line, i) => font.getPath(line, 0, i * lineHeight + size, size).toPathData(2)).join(' ');
  const textWidth = Math.max(...lines.map(line => [...line].length)) * size;
  const textHeight = (lines.length - 1) * lineHeight + size;
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${textWidth}" height="${textHeight}" shape-rendering="crispEdges"><path d="${path}" fill="${color}"/></svg>`;
  return sharp(Buffer.from(svg)).png().toBuffer({ resolveWithObject: true });
}

function litFraction(data) {
  let lit = 0;
  for (let p = 0; p < data.length; p += 4) {
    if (data[p + 3] > 0 && data[p] + data[p + 1] + data[p + 2] > 90) lit++;
  }
  return lit / (data.length / 4);
}

// The frame with the most lit pixels, sampling up to 24 frames of an animation (many apps start on a blank frame)
async function bestFrame(file) {
  const { pages = 1 } = await sharp(file, { animated: true, limitInputPixels: false }).metadata();
  const samples = Math.min(pages, 24);
  let best = null;
  for (let i = 0; i < samples; i++) {
    const page = Math.floor((i * pages) / samples);
    const { data, info } = await sharp(file, { page, limitInputPixels: false })
      .ensureAlpha()
      .raw()
      .toBuffer({ resolveWithObject: true });
    const lit = litFraction(data);
    if (!best || lit > best.lit) best = { lit, data, width: info.width, height: info.height };
  }
  return best;
}

// If a screenshot is a display's pixels enlarged by a whole number (e.g. 640x320 is 64x32 at 10x), the scale;
// 1 if it is a display's own size, 0 if it is neither (a photo, or an odd size)
export function enlargement(width, height) {
  if (DISPLAYS.some(([w, h]) => width === w && height === h)) return 1;
  for (const [w, h] of DISPLAYS) {
    if (width % w === 0 && height % h === 0 && width / w === height / h) return width / w;
  }
  return 0;
}

// Shrink an enlarged screenshot back to its real pixels, taking the middle of each block
export function shrink({ data, width, height }, scale) {
  const w = width / scale;
  const h = height / scale;
  const out = Buffer.alloc(w * h * 4);
  const middle = Math.floor(scale / 2);
  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      const from = ((y * scale + middle) * width + x * scale + middle) * 4;
      data.copy(out, (y * w + x) * 4, from, from + 4);
    }
  }
  return { data: out, width: w, height: h };
}

// Draw each pixel as a round LED; unlit LEDs are shown faintly, like a real panel
function dotMatrix({ data, width, height }, cell) {
  const w = width * cell;
  const h = height * cell;
  const out = Buffer.alloc(w * h * 4);
  const radius = cell * 0.42;
  const centre = (cell - 1) / 2;
  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      const o = (y * w + x) * 4;
      out[o + 3] = 255;
      const dx = (x % cell) - centre;
      const dy = (y % cell) - centre;
      if (dx * dx + dy * dy > radius * radius) continue; // The gap between LEDs stays black
      const s = (Math.floor(y / cell) * width + Math.floor(x / cell)) * 4;
      const alpha = data[s + 3] / 255;
      const r = data[s] * alpha;
      const g = data[s + 1] * alpha;
      const b = data[s + 2] * alpha;
      const off = r + g + b < 30;
      out[o] = off ? 0x1c : r;
      out[o + 1] = off ? 0x1c : g;
      out[o + 2] = off ? 0x1c : b;
    }
  }
  return sharp(out, { raw: { width: w, height: h, channels: 4 } }).png().toBuffer();
}

// The screen area: the screenshot as an LED dot matrix; a photo, odd-sized screenshot or one with a grid already
// drawn on, fitted as it is; or the Tronbyt logo when there is no screenshot
async function screenImage(file) {
  if (!file) {
    const size = 240;
    return { input: await sharp(LOGO).resize(size, size).png().toBuffer(), width: size, height: size };
  }
  let frame = await bestFrame(file);
  let scale = enlargement(frame.width, frame.height);
  if (scale > 1) {
    const small = shrink(frame, scale);
    // A screenshot with a grid or dots already drawn on loses most of its lit pixels when shrunk
    if (litFraction(small.data) < frame.lit * 0.5) scale = 0;
    else frame = small;
  }
  if (scale === 0) {
    const { data, info } = await sharp(frame.data, { raw: { width: frame.width, height: frame.height, channels: 4 } })
      .resize(SCREEN_WIDTH, SCREEN_HEIGHT, { fit: 'inside' })
      .png()
      .toBuffer({ resolveWithObject: true });
    return { input: data, width: info.width, height: info.height };
  }
  const cell = Math.floor(Math.min(SCREEN_WIDTH / frame.width, SCREEN_HEIGHT / frame.height));
  return { input: await dotMatrix(frame, cell), width: frame.width * cell, height: frame.height * cell };
}

async function header() {
  const title = await renderText('Tronbyt App Viewer', 32, 900, TITLE_COLOR, 1);
  return [
    { input: await sharp(LOGO).resize(64, 64).png().toBuffer(), left: 60, top: 40 },
    { input: title.data, left: 144, top: 40 + Math.round((64 - title.info.height) / 2) },
  ];
}

async function footer() {
  const site = await renderText('tronbyt.github.io/apps', 16, 600, SITE_COLOR, 1);
  return { input: site.data, left: CARD_WIDTH - 60 - site.info.width, top: CARD_HEIGHT - 40 - site.info.height };
}

// Stack text blocks ([image, gap after]) in the text column, centred against the screen
function textColumn(blocks) {
  const shown = blocks.filter(([block]) => block);
  const height = shown.reduce((total, [block, gap], i) => total + block.info.height + (i < shown.length - 1 ? gap : 0), 0);
  let top = SCREEN_TOP + Math.max(0, Math.round((SCREEN_HEIGHT - height) / 2));
  return shown.map(([block, gap]) => {
    const layer = { input: block.data, left: TEXT_LEFT, top };
    top += block.info.height + gap;
    return layer;
  });
}

async function writeCard(screen, blocks, outFile) {
  const left = SCREEN_LEFT + Math.round((SCREEN_WIDTH - screen.width) / 2);
  const top = SCREEN_TOP + Math.round((SCREEN_HEIGHT - screen.height) / 2);
  const bezel = (grow, colour) => ({
    input: { create: { width: screen.width + grow * 2, height: screen.height + grow * 2, channels: 4, background: colour } },
    left: left - grow,
    top: top - grow,
  });
  await sharp({ create: { width: CARD_WIDTH, height: CARD_HEIGHT, channels: 4, background: BACKGROUND } })
    .composite([
      ...(await header()),
      bezel(12, '#444444'),
      bezel(10, '#000000'),
      { input: screen.input, left, top },
      ...textColumn(blocks),
      await footer(),
    ])
    .png({ compressionLevel: 9 })
    .toFile(outFile);
}

// An app's card. If its screenshot can't be read, the card shows the Tronbyt logo instead.
export async function buildAppCard(app, screenshotFile, outFile) {
  let screen;
  try {
    screen = await screenImage(screenshotFile);
  } catch (error) {
    console.warn(`Couldn't use the screenshot for ${app.name} in its social card: ${error.message}`);
    screen = await screenImage(null);
  }
  const name = app.displayName || app.name;
  const summary = app.summary || app.description || '';
  await writeCard(screen, [
    [await renderText(name, fittingSize(name, TEXT_WIDTH, [32, 24, 16]), TEXT_WIDTH, TITLE_COLOR, 2), 32],
    [await renderText(summary, 16, TEXT_WIDTH, TEXT_COLOR, 5), 28],
    [app.author ? await renderText(`by ${app.author}`, fittingSize(`by ${app.author}`, TEXT_WIDTH, [16, 8]), TEXT_WIDTH, AUTHOR_COLOR, 2) : null, 0],
  ], outFile);
}

// The card for the home page and author pages
export async function buildSiteCard(appCount, outFile) {
  await writeCard(await screenImage(null), [
    [await renderText('Browse Tronbyt apps', 32, TEXT_WIDTH, TITLE_COLOR, 2), 32],
    [await renderText(`Screenshots, details and documentation for ${appCount.toLocaleString('en-US')} apps for Tronbyt displays.`, 16, TEXT_WIDTH, TEXT_COLOR, 5), 0],
  ], outFile);
}
