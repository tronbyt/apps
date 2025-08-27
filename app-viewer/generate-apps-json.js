const fs = require('fs');
const path = require('path');

const APPS_DIR = path.join(__dirname, '../apps');
const OUTPUT_FILE = path.join(__dirname, 'apps.json');
const IMAGE_EXTS = ['.png', '.jpg', '.jpeg', '.gif', '.webp'];
const MD_FILES = ['README.md', 'readme.md', 'index.md'];

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
    // Remove markdown formatting and get first 100 chars
    const plainText = content
      .replace(/#{1,6}\s+/g, '') // Remove headers
      .replace(/\*\*(.*?)\*\*/g, '$1') // Remove bold
      .replace(/\*(.*?)\*/g, '$1') // Remove italic
      .replace(/\[(.*?)\]\(.*?\)/g, '$1') // Remove links
      .replace(/`(.*?)`/g, '$1') // Remove inline code
      .replace(/^\s*[-*+]\s+/gm, '') // Remove list markers
      .replace(/\n+/g, ' ') // Replace newlines with spaces
      .trim();

    return plainText.length > 100 ? plainText.substring(0, 100) + '...' : plainText;
  } catch {
    return null;
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
    } catch {
      continue;
    }
    const image = findFirstImage(files);
    const md = findMarkdown(files);
    const starFiles = files.filter(f => f.endsWith('.star'));
    const description = md ? getReadmeDescription(appPath, md) : null;

    apps.push({
      name: appName,
      image: image ? `${appName}/${image}` : null,
      md: md ? `${appName}/${md}` : null,
      description: description,
      starFiles: starFiles
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
