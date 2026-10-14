import { existsSync, readFileSync, readdirSync, writeFileSync, mkdirSync, rmSync } from 'fs';
import { join, extname, dirname, basename } from 'path';
import { createHash } from 'crypto';
import { load } from 'js-yaml';
import { fileURLToPath } from 'url';
import { buildAppCard, buildSiteCard, cardFileName, CARD_HEIGHT, CARD_WIDTH } from './social-cards.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Parse arguments
const args = process.argv.slice(2);
let outputFile = join(__dirname, 'apps.json');
let appsPath = join(__dirname, '../apps');
let withCards = true;
for (let i = 0; i < args.length; i++) {
  if (args[i] === '--output' && i + 1 < args.length) {
    outputFile = args[i + 1];
  } else if (args[i] === '--apps-path' && i + 1 < args.length) {
    appsPath = args[i + 1];
  } else if (args[i] === '--no-cards') {
    withCards = false; // Quicker local builds: pages still link to cards, but none are drawn
  }
}
const APPS_DIR = appsPath;
const outputDir = dirname(outputFile);
const OUTPUT_FILE = outputFile;
const IMAGE_EXTS = ['.png', '.jpg', '.jpeg', '.gif', '.webp'];
const MD_FILES = ['README.md', 'readme.md', 'index.md'];
const SITE_URL = 'https://tronbyt.github.io/apps/';
const SITE_NAME = 'Tronbyt App Viewer';
// The card for the home and author pages; index.html refers to it by this name
const SITE_CARD = 'cards/tronbyt-app-viewer.png';
const CARD_CONCURRENCY = 4;

function normalizeAuthor(author) {
  return author
    .normalize('NFKC')
    .trim()
    .replace(/\s+/g, ' ')
    .toLocaleLowerCase('en-US');
}

function slugifyAuthor(authorKey) {
  const slug = authorKey
    .normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');

  return slug || 'author';
}

function buildAuthorProfiles(apps) {
  const profilesByKey = new Map();

  for (const app of apps) {
    if (!app.author || !app.author.trim()) continue;

    const authorKey = normalizeAuthor(app.author);
    let profile = profilesByKey.get(authorKey);
    if (!profile) {
      profile = {
        key: authorKey,
        displayNames: new Map(),
        apps: []
      };
      profilesByKey.set(authorKey, profile);
    }

    profile.displayNames.set(app.author, (profile.displayNames.get(app.author) || 0) + 1);
    profile.apps.push(app);
  }

  const profiles = [...profilesByKey.values()];
  const profilesByBaseSlug = new Map();

  for (const profile of profiles) {
    profile.displayName = [...profile.displayNames.entries()]
      .sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0]))[0][0];
    profile.baseSlug = slugifyAuthor(profile.key);

    const matches = profilesByBaseSlug.get(profile.baseSlug) || [];
    matches.push(profile);
    profilesByBaseSlug.set(profile.baseSlug, matches);
  }

  for (const matchingProfiles of profilesByBaseSlug.values()) {
    for (const profile of matchingProfiles) {
      profile.slug = matchingProfiles.length === 1
        ? profile.baseSlug
        : `${profile.baseSlug}-${createHash('sha256').update(profile.key).digest('hex').slice(0, 8)}`;

      for (const app of profile.apps) {
        app.authorSlug = profile.slug;
      }
    }
  }

  return profiles.sort((a, b) => a.displayName.localeCompare(b.displayName));
}

export function escapeHtmlAttribute(value) {
  return String(value)
    .replace(/\r?\n/g, ' ')
    .replace(/&/g, '&amp;')
    .replace(/"/g, '&quot;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
}

// Open Graph / Twitter tags shared by every generated page
function socialTags({ title, description, url, image, imageAlt }) {
  return `<title>${escapeHtmlAttribute(title)}</title>
        <meta name="description" content="${escapeHtmlAttribute(description)}">
        <link rel="canonical" href="${escapeHtmlAttribute(url)}">
        <meta property="og:site_name" content="${SITE_NAME}">
        <meta property="og:title" content="${escapeHtmlAttribute(title)}">
        <meta property="og:description" content="${escapeHtmlAttribute(description)}">
        <meta property="og:url" content="${escapeHtmlAttribute(url)}">
        <meta property="og:type" content="website">
        <meta property="og:image" content="${escapeHtmlAttribute(image)}">
        <meta property="og:image:type" content="image/png">
        <meta property="og:image:width" content="${CARD_WIDTH}">
        <meta property="og:image:height" content="${CARD_HEIGHT}">
        <meta property="og:image:alt" content="${escapeHtmlAttribute(imageAlt)}">
        <meta name="twitter:card" content="summary_large_image">
        <meta name="twitter:title" content="${escapeHtmlAttribute(title)}">
        <meta name="twitter:description" content="${escapeHtmlAttribute(description)}">
        <meta name="twitter:image" content="${escapeHtmlAttribute(image)}">
        <meta name="twitter:image:alt" content="${escapeHtmlAttribute(imageAlt)}">`;
}

// JSON for a <script> element: "<" is escaped so the data can't end the element early
function scriptJson(value) {
  return JSON.stringify(value).replace(/</g, '\\u003c');
}

export function appPageUrl(app) {
  return `${SITE_URL}details/${encodeURIComponent(app.name)}.html`;
}

export function buildAppMetaTags(app, cardPath = SITE_CARD) {
  const name = app.displayName || app.name;
  const title = `${name} - Tronbyt App`;
  const description = app.summary || app.description || 'View details for this Tronbyt app.';
  const url = appPageUrl(app);
  const image = SITE_URL + cardPath;

  // Structured data, so search engines know the page describes an app
  const data = {
    '@context': 'https://schema.org',
    '@type': 'SoftwareApplication',
    name,
    description: app.description || app.summary || undefined,
    url,
    image,
    applicationCategory: 'Tronbyt app',
    applicationSubCategory: app.category || undefined,
    operatingSystem: 'Tronbyt',
    keywords: app.tags && app.tags.length ? app.tags.join(', ') : undefined,
    author: app.author ? { '@type': 'Person', name: app.author } : undefined,
    datePublished: app.published || undefined,
    dateModified: app.updated || undefined,
  };

  return `${socialTags({ title, description, url, image, imageAlt: `${name} on a Tronbyt display` })}
        <script type="application/ld+json">${scriptJson(data)}</script>
        <meta name="app-name" content="${escapeHtmlAttribute(app.name)}">`;
}

// The app's details written into the page, for search engines and sharing sites that don't run JavaScript.
// The page's script replaces it with the full details.
export function buildAppPrerender(app) {
  const name = app.displayName || app.name;
  const parts = [`<h1>${escapeHtmlAttribute(name)}</h1>`];
  if (app.summary && app.summary !== app.description) parts.push(`<p>${escapeHtmlAttribute(app.summary)}</p>`);
  if (app.description) parts.push(`<p>${escapeHtmlAttribute(app.description)}</p>`);
  if (app.author) {
    const author = escapeHtmlAttribute(app.author);
    parts.push(app.authorSlug
      ? `<p>By <a href="../authors/${encodeURIComponent(app.authorSlug)}.html">${author}</a></p>`
      : `<p>By ${author}</p>`);
  }
  if (app.tags && app.tags.length) {
    const tags = app.tags.map(tag => `<a href="../index.html?tag=${encodeURIComponent(tag)}">${escapeHtmlAttribute(tag)}</a>`);
    parts.push(`<p>Tags: ${tags.join(', ')}</p>`);
  }
  return parts.join('\n                ');
}

export function buildAuthorMetaTags(profile, cardPath = SITE_CARD) {
  const appCount = profile.apps.length;
  const title = `${profile.displayName} - Tronbyt Apps`;
  const description = `${appCount} Tronbyt ${appCount === 1 ? 'app' : 'apps'} by ${profile.displayName}.`;
  const url = `${SITE_URL}authors/${encodeURIComponent(profile.slug)}.html`;
  return `${socialTags({ title, description, url, image: SITE_URL + cardPath, imageAlt: SITE_NAME })}
        <meta name="author-slug" content="${escapeHtmlAttribute(profile.slug)}">
        <meta name="author-name" content="${escapeHtmlAttribute(profile.displayName)}">`;
}

// The author's apps written into the page as links, so search engines can find each app's page
export function buildAuthorPrerender(profile) {
  const apps = profile.apps
    .map(app => `<li><a href="../details/${encodeURIComponent(app.name)}.html">${escapeHtmlAttribute(app.displayName || app.name)}</a>${app.summary ? ` - ${escapeHtmlAttribute(app.summary)}` : ''}</li>`)
    .join('\n                    ');
  return `<h1>${escapeHtmlAttribute(profile.displayName)}</h1>
                <ul>
                    ${apps}
                </ul>`;
}

function sitemapDate(value) {
  const date = value ? new Date(value) : null;
  return date && !Number.isNaN(date.getTime()) ? date.toISOString().slice(0, 10) : null;
}

// Every page, for search engines
export function buildSitemap(apps, profiles) {
  const entry = (url, lastmod) =>
    `  <url><loc>${escapeHtmlAttribute(url)}</loc>${lastmod ? `<lastmod>${lastmod}</lastmod>` : ''}</url>`;
  return `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
${[
    entry(SITE_URL),
    ...apps.map(app => entry(appPageUrl(app), sitemapDate(app.updated || app.published))),
    ...profiles.map(profile => entry(`${SITE_URL}authors/${encodeURIComponent(profile.slug)}.html`)),
  ].join('\n')}
</urlset>
`;
}

// The screenshot shown on an app's card: 128x64 if there is one, then 64x32, then 64x64
function cardScreenshot(app) {
  const image = app.image2x || app.image || app.image64x64;
  return image ? join(APPS_DIR, image) : null;
}

// Work out each app's card file name (it depends on the screenshot, so a new screenshot gives a new card)
function planCards(apps) {
  return new Map(apps.map(app => {
    const screenshot = cardScreenshot(app);
    let bytes = null;
    try {
      bytes = screenshot ? readFileSync(screenshot) : null;
    } catch {
      // A missing screenshot gets the logo card
    }
    return [app.name, `cards/${cardFileName(app, bytes)}`];
  }));
}

async function generateCards(apps, cards) {
  const cardsDir = join(outputDir, 'cards');
  rmSync(cardsDir, { recursive: true, force: true }); // Only the current cards are published
  mkdirSync(cardsDir, { recursive: true });
  await buildSiteCard(apps.length, join(outputDir, SITE_CARD));

  const queue = [...apps];
  const worker = async () => {
    for (let app = queue.shift(); app; app = queue.shift()) {
      await buildAppCard(app, cardScreenshot(app), join(outputDir, cards.get(app.name)));
    }
  };
  await Promise.all(Array.from({ length: CARD_CONCURRENCY }, worker));
}

function parseManifest(appPath) {
  try {
    const manifestPath = join(appPath, 'manifest.yaml');
    if (existsSync(manifestPath)) {
      const content = readFileSync(manifestPath, 'utf8');
      return load(content);
    }
  } catch (e) {
    console.error(`Error parsing manifest for ${appPath}:`, e);
  }
  return null;
}

function findPreview(files, appName, manifest, starFile) {
  const fileSet = new Set(files);

  const check = (base, stripExt = false) => {
    if (!base) return null;
    const baseName = stripExt ? base.replace(/\.[^/.]+$/, "") : base;
    for (const ext of IMAGE_EXTS) {
      const fileName = `${baseName}${ext}`;
      if (fileSet.has(fileName)) {
        return fileName;
      }
    }
    return null;
  };

  return check(appName) ||
    check(manifest?.fileName, true) ||
    check(starFile, true) ||
    files.find(f => IMAGE_EXTS.includes(extname(f).toLowerCase()));
}

export function findMarkdown(files) {
  const exactMatch = MD_FILES.find(candidate => files.includes(candidate));
  if (exactMatch) return exactMatch;

  for (const candidate of MD_FILES) {
    const match = files.find(file => file.toLocaleLowerCase('en-US') === candidate.toLocaleLowerCase('en-US'));
    if (match) return match;
  }

  return undefined;
}

function getReadmeDescription(appPath, mdFile) {
  try {
    const mdPath = join(appPath, mdFile);
    const content = readFileSync(mdPath, 'utf8');

    // Simple cleanup: remove headers and get first line/paragraph
    const cleanText = content
      .replace(/^#{1,6}\s+/gm, '') // Remove markdown headers
      .replace(/^\s*[-*+]\s+/gm, '') // Remove list markers
      .split('\n')
      .find(line => line.trim().length > 10) // Find first substantial line
      ?.trim();

    if (!cleanText) return null;

    return cleanText.length > 120 ? cleanText.substring(0, 120) + '...' : cleanText;
  } catch (e) {
    return null; // Fail silently since this is just a fallback
  }
}

function scanApps() {
  const apps = [];
  const appDirs = readdirSync(APPS_DIR, { withFileTypes: true })
    .filter(dirent => dirent.isDirectory())
    .map(dirent => dirent.name);

  for (const appName of appDirs) {
    const appPath = join(APPS_DIR, appName);
    let files;
    try {
      files = readdirSync(appPath);
    } catch (e) {
      console.error(`Failed to read directory ${appPath}:`, e);
      continue;
    }
    const md = findMarkdown(files);
    const starFiles = files.filter(f => f.endsWith('.star'));
    const starFile = starFiles.length > 0 ? starFiles[0] : null; // Take the first .star file
    const manifest = parseManifest(appPath);
    const image = findPreview(files, appName, manifest, starFile);

    // Get description from manifest first, then fallback to README
    let description = null;
    let summary = null;
    let displayName = appName;
    let author = null;
    let recommendedInterval = null;
    let supports2x = false;
    let supports64x64 = false;
    let image2x = null;
    let image64x64 = null;
    let category = null;
    let tags = [];
    let published = null;
    let updated = null;
    let broken = false;
    let brokenReason = null;

    if (manifest) {
      summary = manifest.summary || null;
      description = manifest.desc || null;
      displayName = manifest.name || appName;
      author = manifest.author || null;
      recommendedInterval = manifest.recommendedInterval || null;
      supports2x = Boolean(manifest.supports2x);
      supports64x64 = Boolean(manifest.supports64x64);
      category = manifest.category || null;
      tags = manifest.tags || [];
      published = manifest.published || null;
      updated = manifest.updated || null;
      broken = Boolean(manifest.broken);
      brokenReason = manifest.brokenReason || null;
    }

    // Try to find the corresponding @2x image if the app supports it
    if (supports2x && image) {
        const ext = extname(image);
        const base = basename(image, ext);
        const candidate2x = `${base}@2x${ext}`;
        if (files.includes(candidate2x)) {
            image2x = `${appName}/${candidate2x}`;
        }
    }

    // Try to find the corresponding 64x64 image if the app supports square displays
    if (supports64x64 && image) {
        const ext = extname(image);
        const base = basename(image, ext);
        const candidate64x64 = `${base}@64x64${ext}`;
        if (files.includes(candidate64x64)) {
            image64x64 = `${appName}/${candidate64x64}`;
        }
    }

    // Fallback to README if no manifest description
    if (!description && md) {
      description = getReadmeDescription(appPath, md);
    }

    apps.push({
      name: appName,
      displayName: displayName,
      summary: summary,
      description: description,
      author: author,
      recommendedInterval: recommendedInterval,
      image: image ? `${appName}/${image}` : null,
      image2x: image2x,
      image64x64: image64x64,
      supports2x: supports2x,
      supports64x64: supports64x64,
      md: md ? `${appName}/${md}` : null,
      starFile: starFile,
      category: category,
      tags: tags,
      published: published,
      updated: updated,
      broken: broken,
      brokenReason: brokenReason
    });
  }
  return apps;
}

// Detail and author pages are written one folder down (details/, authors/), so their relative links need "../".
// Every link to the home page is adjusted: the header logo and the Back to Apps button both use it.
export function adjustTemplateForNestedPage(template) {
  return template
    .replace('href="style.css"', 'href="../style.css"')
    .replace('src="main.js"', 'src="../main.js"')
    .replaceAll('href="index.html"', 'href="../index.html"');
}

function generateHtmlFiles(apps, cards) {
  const detailsDir = join(outputDir, 'details');
  if (!existsSync(detailsDir)) {
    mkdirSync(detailsDir, { recursive: true });
  }

  const templatePath = join(__dirname, 'app.html');
  const template = adjustTemplateForNestedPage(readFileSync(templatePath, 'utf8'));

  for (const app of apps) {
    const appHtml = template
      .replace('<title>App Details</title>', buildAppMetaTags(app, cards.get(app.name)))
      .replace('<div id="app-content"></div>', `<div id="app-content">
                ${buildAppPrerender(app)}
            </div>`);
    writeFileSync(join(detailsDir, `${app.name}.html`), appHtml);
  }
}

function generateAuthorHtmlFiles(profiles) {
  const authorsDir = join(outputDir, 'authors');
  if (!existsSync(authorsDir)) {
    mkdirSync(authorsDir, { recursive: true });
  }

  const templatePath = join(__dirname, 'author.html');
  const template = adjustTemplateForNestedPage(readFileSync(templatePath, 'utf8'));

  for (const profile of profiles) {
    const authorHtml = template
      .replace('<title>Author Profile</title>', buildAuthorMetaTags(profile))
      .replace('<div id="author-content"></div>', `<div id="author-content">
                ${buildAuthorPrerender(profile)}
            </div>`);
    writeFileSync(join(authorsDir, `${profile.slug}.html`), authorHtml);
  }
}

async function main() {
  const apps = scanApps();
  const authorProfiles = buildAuthorProfiles(apps);
  writeFileSync(OUTPUT_FILE, JSON.stringify(apps, null, 2));
  console.log(`Generated ${OUTPUT_FILE} with ${apps.length} apps.`);

  // Generate static HTML pages with Open Graph tags
  const cards = planCards(apps);
  generateHtmlFiles(apps, cards);
  console.log(`Generated ${apps.length} static detail HTML pages with metadata.`);

  generateAuthorHtmlFiles(authorProfiles);
  console.log(`Generated ${authorProfiles.length} static author HTML pages with metadata.`);

  writeFileSync(join(outputDir, 'sitemap.xml'), buildSitemap(apps, authorProfiles));
  console.log('Generated sitemap.xml.');

  if (withCards) {
    const started = Date.now();
    await generateCards(apps, cards);
    console.log(`Generated ${apps.length + 1} social cards in ${Math.round((Date.now() - started) / 1000)}s.`);
  }
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  await main();
}
