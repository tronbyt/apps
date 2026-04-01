import { existsSync, readFileSync, readdirSync, writeFileSync, mkdirSync } from 'fs';
import { join, extname, dirname, basename } from 'path';
import { load } from 'js-yaml';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const APPS_DIR = join(__dirname, '../apps');

// Parse --output argument
const args = process.argv.slice(2);
let outputFile = join(__dirname, 'apps.json');
for (let i = 0; i < args.length; i++) {
  if (args[i] === '--output' && i + 1 < args.length) {
    outputFile = args[i + 1];
  }
}
const outputDir = dirname(outputFile);
const OUTPUT_FILE = outputFile;
const IMAGE_EXTS = ['.png', '.jpg', '.jpeg', '.gif', '.webp'];
const MD_FILES = ['README.md', 'readme.md', 'index.md'];

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

function findMarkdown(files) {
  return files.find(f => MD_FILES.includes(f));
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
    let image2x = null;
    let category = null;
    let tags = [];

    if (manifest) {
      summary = manifest.summary || null;
      description = manifest.desc || null;
      displayName = manifest.name || appName;
      author = manifest.author || null;
      recommendedInterval = manifest.recommendedInterval || null;
      supports2x = Boolean(manifest.supports2x);
      category = manifest.category || null;
      tags = manifest.tags || [];
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
      supports2x: supports2x,
      md: md ? `${appName}/${md}` : null,
      starFile: starFile,
      category: category,
      tags: tags
    });
  }
  return apps;
}

function generateHtmlFiles(apps) {
  const detailsDir = join(outputDir, 'details');
  if (!existsSync(detailsDir)) {
    mkdirSync(detailsDir);
  }

  const templatePath = join(__dirname, 'app.html');
  let template = readFileSync(templatePath, 'utf8');

  // Adjust relative paths in template
  template = template.replace('href="style.css"', 'href="../style.css"');
  template = template.replace('src="main.js"', 'src="../main.js"');
  template = template.replace('href="index.html"', 'href="../index.html"');

  for (const app of apps) {
    const title = app.displayName ? `${app.displayName} - Tronbyt App` : 'Tronbyt App';
    const description = app.summary || app.description || 'View details for this Tronbyt app.';
    const imageUrl = app.image ? `https://tronbyt.github.io/apps/apps/${app.image}` : `https://avatars.githubusercontent.com/u/200508996?s=400&v=4`;
    const url = `https://tronbyt.github.io/apps/details/${encodeURIComponent(app.name)}.html`;

    const metaTags = `<title>${title}</title>
        <meta name="description" content="${description.replace(/"/g, '&quot;').replace(/\n/g, ' ')}">
        <meta property="og:title" content="${title.replace(/"/g, '&quot;')}">
        <meta property="og:description" content="${description.replace(/"/g, '&quot;').replace(/\n/g, ' ')}">
        <meta property="og:image" content="${imageUrl}">
        <meta property="og:url" content="${url}">
        <meta property="og:type" content="website">
        <meta name="twitter:card" content="summary_large_image">
        <meta name="twitter:title" content="${title.replace(/"/g, '&quot;')}">
        <meta name="twitter:description" content="${description.replace(/"/g, '&quot;').replace(/\n/g, ' ')}">
        <meta name="twitter:image" content="${imageUrl}">
        <meta name="app-name" content="${app.name}">`;

    const appHtml = template.replace('<title>App Details</title>', metaTags);
    writeFileSync(join(detailsDir, `${app.name}.html`), appHtml);
  }
}

function main() {
  const apps = scanApps();
  writeFileSync(OUTPUT_FILE, JSON.stringify(apps, null, 2));
  console.log(`Generated ${OUTPUT_FILE} with ${apps.length} apps.`);

  // Generate static HTML pages with Open Graph tags
  generateHtmlFiles(apps);
  console.log(`Generated ${apps.length} static detail HTML pages with metadata.`);
}

main();
