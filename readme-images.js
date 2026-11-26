function isIntegerScale(width, height, canvasWidth, canvasHeight) {
  if (!Number.isFinite(width) || !Number.isFinite(height) || width <= 0 || height <= 0) {
    return false;
  }

  const widthScale = width / canvasWidth;
  const heightScale = height / canvasHeight;
  return Number.isInteger(widthScale) && widthScale === heightScale;
}

function has2xFilename(source = '') {
  try {
    const pathname = new URL(source, 'https://app-viewer.invalid/').pathname;
    return /(?:@|[-_])2x(?:[._-]|$)/i.test(pathname);
  } catch {
    return false;
  }
}

export function classifyReadmeImage({
  width,
  height,
  source = '',
  supports2x = false,
  supports64x64 = false
}) {
  if (supports64x64 && isIntegerScale(width, height, 64, 64)) {
    return 'square';
  }

  if (!isIntegerScale(width, height, 64, 32)) {
    return null;
  }

  if (supports2x && (
    has2xFilename(source) ||
    (width === 128 && height === 64)
  )) {
    return 'wide';
  }

  return 'standard';
}

export function normalizeReadmeImageUrl(value) {
  if (!value || typeof value !== 'string') return value;

  try {
    const url = new URL(value);
    const githubBlob = url.hostname === 'github.com'
      ? url.pathname.match(/^\/([^/]+)\/([^/]+)\/blob\/([^/]+)\/(.+)$/)
      : null;

    if (githubBlob) {
      const [, owner, repo, revision, path] = githubBlob;
      return `https://raw.githubusercontent.com/${owner}/${repo}/${revision}/${path}${url.search}${url.hash}`;
    }
  } catch {
    // Relative image URLs are resolved against the app directory elsewhere.
  }

  return value;
}
