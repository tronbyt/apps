const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');

const APPS_DIR = path.join(__dirname, '../apps');
const OUTPUT_FILE = path.join(__dirname, 'apps.json');
const IMAGE_EXTS = ['.png', '.jpg', '.jpeg', '.gif', '.webp'];
const MD_FILES = ['README.md', 'readme.md', 'index.md'];

function parseManifest(appPath) {
  try {
    const manifestPath = path.join(appPath, 'manifest.yaml');
    if (fs.existsSync(manifestPath)) {
      const content = fs.readFileSync(manifestPath, 'utf8');
      return yaml.load(content);
    }
  } catch (e) {
    console.error(`Error parsing manifest for ${appPath}:`, e);
  }
  return null;
}

function findFirstImage(files) {
  return files.find(f => IMAGE_EXTS.includes(path.extname(f).toLowerCase()));
}

function findMarkdown(files) {
  return files.find(f => MD_FILES.includes(f));
}

function getReadmeDescription(appPath, mdFile) {
  try {
    const mdPath = path.join(appPath, mdFile);
    const content = fs.readFileSync(mdPath, 'utf8');

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
  const appDirs = fs.readdirSync(APPS_DIR, { withFileTypes: true })
    .filter(dirent => dirent.isDirectory())
    .map(dirent => dirent.name);

  for (const appName of appDirs) {
    const appPath = path.join(APPS_DIR, appName);
    let files;
    try {
      files = fs.readdirSync(appPath);
    } catch (e) {
      console.error(`Failed to read directory ${appPath}:`, e);
      continue;
    }
    const image = findFirstImage(files);
    const md = findMarkdown(files);
    const starFiles = files.filter(f => f.endsWith('.star'));
    const starFile = starFiles.length > 0 ? starFiles[0] : null; // Take the first .star file
    const manifest = parseManifest(appPath);

    // Get description from manifest first, then fallback to README
    let description = null;
    let summary = null;
    let displayName = appName;
    let author = null;
    let recommendedInterval = null;

    if (manifest) {
      summary = manifest.summary || null;
      description = manifest.desc || null;
      displayName = manifest.name || appName;
      author = manifest.author || null;
      recommendedInterval = manifest.recommended_interval || null;
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
      md: md ? `${appName}/${md}` : null,
      starFile: starFile
    });
  }
  return apps;
}

function main() {
  const apps = scanApps();
  fs.writeFileSync(OUTPUT_FILE, JSON.stringify(apps, null, 2));
  console.log(`Generated ${OUTPUT_FILE} with ${apps.length} apps.`);
}

main();
