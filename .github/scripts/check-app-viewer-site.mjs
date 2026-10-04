import { existsSync, readFileSync, readdirSync, realpathSync } from 'node:fs';
import { dirname, isAbsolute, join, relative, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const REQUIRED_FILES = [
  'index.html',
  'app.html',
  'main.js',
  'style.css',
  'apps.json',
  'catalogue-meta.json',
];

function filesBelow(directory) {
  const files = [];
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    const path = join(directory, entry.name);
    if (entry.isDirectory()) files.push(...filesBelow(path));
    else files.push(path);
  }
  return files;
}

function localReference(reference) {
  return reference &&
    !reference.startsWith('#') &&
    !reference.startsWith('//') &&
    !/^[a-z][a-z0-9+.-]*:/i.test(reference);
}

function referencesInHtml(contents) {
  const references = [];
  for (const match of contents.matchAll(/<script\b[^>]*\bsrc\s*=\s*["']([^"']+)["'][^>]*>/gi)) {
    references.push(match[1]);
  }
  for (const match of contents.matchAll(/<link\b[^>]*>/gi)) {
    const tag = match[0];
    if (!/\brel\s*=\s*["'][^"']*\bstylesheet\b[^"']*["']/i.test(tag)) continue;
    const href = tag.match(/\bhref\s*=\s*["']([^"']+)["']/i);
    if (href) references.push(href[1]);
  }
  return references;
}

function referencesInJavaScript(contents) {
  const references = [];
  const staticImport = /(?:import|export)\s+(?:[^"']*?\s+from\s+)?["']([^"']+)["']/g;
  const dynamicImport = /import\s*\(\s*["']([^"']+)["']\s*\)/g;
  for (const match of contents.matchAll(staticImport)) references.push(match[1]);
  for (const match of contents.matchAll(dynamicImport)) references.push(match[1]);
  return references;
}

function resolveReference(root, source, reference) {
  const withoutSuffix = reference.split(/[?#]/, 1)[0];
  let decoded;
  try {
    decoded = decodeURIComponent(withoutSuffix);
  } catch {
    return null;
  }

  return decoded.startsWith('/')
    ? resolve(root, `.${decoded}`)
    : resolve(dirname(source), decoded);
}

export function missingSiteReferences(rootDirectory) {
  const root = resolve(rootDirectory);
  const missing = [];
  const scriptsToCheck = [];
  const checkedScripts = new Set();

  for (const required of REQUIRED_FILES) {
    if (!existsSync(join(root, required))) missing.push(`${required} (required)`);
  }

  const checkReference = (source, reference) => {
    if (!localReference(reference)) return;
    const target = resolveReference(root, source, reference);
    const targetRelative = target ? relative(root, target) : '';
    const outsideRoot = !target || targetRelative.startsWith('..') || isAbsolute(targetRelative);
    if (outsideRoot || !existsSync(target)) {
      missing.push(`${relative(root, source)} -> ${reference}`);
      return;
    }
    if (/\.(?:m?js)$/i.test(target)) scriptsToCheck.push(target);
  };

  for (const source of filesBelow(root).filter((file) => file.endsWith('.html'))) {
    const contents = readFileSync(source, 'utf8');
    for (const reference of referencesInHtml(contents)) {
      checkReference(source, reference);
    }
  }

  while (scriptsToCheck.length > 0) {
    const source = scriptsToCheck.pop();
    if (checkedScripts.has(source)) continue;
    checkedScripts.add(source);

    const contents = readFileSync(source, 'utf8');
    for (const reference of referencesInJavaScript(contents)) {
      checkReference(source, reference);
    }
  }

  return missing;
}

export function main() {
  const root = process.argv[2];
  if (!root || !existsSync(root)) throw new Error('site directory does not exist');

  const missing = missingSiteReferences(root);
  if (missing.length > 0) {
    console.error('Generated App Viewer has missing local references:');
    for (const reference of missing) console.error(`- ${reference}`);
    process.exitCode = 1;
    return;
  }

  console.log('Generated App Viewer local references are complete.');
}

const invokedPath = process.argv[1];
if (invokedPath && realpathSync(fileURLToPath(import.meta.url)) === realpathSync(resolve(invokedPath))) {
  main();
}
