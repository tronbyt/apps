import { classifyReadmeImage, normalizeReadmeImageUrl } from './readme-images.js';

// --- CONFIG ---
// Use GitHub Pages structure for both local and production
const isDetailsPage = window.location.pathname.includes('/details/');
const isAuthorPage = window.location.pathname.includes('/authors/');
const isNestedPage = isDetailsPage || isAuthorPage;
const BASE_PATH = isNestedPage ? '../' : '';
const APPS_DIR = isNestedPage ? '../apps' : 'apps';
const BROKEN_APPS_FILE = isNestedPage ? '../broken_apps.txt' : 'broken_apps.txt';
const CATALOGUE_META_FILE = isNestedPage ? '../catalogue-meta.json' : 'catalogue-meta.json';
const IMAGE_EXTS = ['.png', '.jpg', '.jpeg', '.gif', '.webp'];
const MD_FILES = ['README.md', 'readme.md', 'index.md'];
const DEFAULT_SORT_ORDER = 'updated';
const APP_BATCH_SIZE = 60;
const SEARCH_DEBOUNCE_MS = 150;
const VIEWER_STATE_PARAMS = ['q', 'category', 'display', 'sort', 'tag', 'hideBroken', 'count', 'scroll'];
let appListObserver = null;

function getViewerStateParams(search = window.location.search) {
  const source = new URLSearchParams(search);
  const state = new URLSearchParams();
  VIEWER_STATE_PARAMS.forEach(name => {
    if (source.has(name)) state.set(name, source.get(name));
  });
  return state;
}

// The catalogue's state (search, filters, scroll) arrives on a detail or author page in its address, then is kept in
// the page's history entry instead (see tidyPageAddress), where it survives a reload
function currentViewerState() {
  const fromAddress = getViewerStateParams();
  return fromAddress.toString() ? fromAddress : getViewerStateParams(window.history.state?.viewerState || '');
}

function buildViewerStateUrl(path) {
  const params = currentViewerState();
  const query = params.toString();
  return `${path}${query ? `?${query}` : ''}`;
}

export function rememberViewerScroll(event) {
  const scrollY = Math.round(window.scrollY);
  const catalogueUrl = new URL(window.location.href);
  const detailUrl = new URL(event.currentTarget.href, window.location.href);

  if (scrollY > 0) {
    catalogueUrl.searchParams.set('scroll', String(scrollY));
    detailUrl.searchParams.set('scroll', String(scrollY));
  } else {
    catalogueUrl.searchParams.delete('scroll');
    detailUrl.searchParams.delete('scroll');
  }

  // Save the position on the catalogue history entry itself. The browser can
  // then restore it when the detail page uses history.back(), even if the
  // dynamically generated catalogue must be rebuilt instead of coming from
  // the back/forward cache. Keep it on the detail URL as the fallback too.
  window.history.replaceState(window.history.state, '', catalogueUrl);
  event.currentTarget.href = detailUrl.href;
}

// Takes the catalogue's state and any ".html" out of a detail or author page's address, so what's in the address bar is
// the page's own clean link and can be copied and shared. The state moves into the history entry, so Back to Apps still
// returns to the same place, even after a reload.
export function tidyPageAddress() {
  const url = new URL(window.location.href);
  const viewerState = currentViewerState().toString();
  VIEWER_STATE_PARAMS.forEach(name => url.searchParams.delete(name));
  url.pathname = url.pathname.replace(/\.html$/, '');
  if (url.href !== window.location.href || viewerState !== (window.history.state?.viewerState || '')) {
    window.history.replaceState({ ...(window.history.state || {}), viewerState }, '', url);
  }
}

// The page's clean link, for sharing
export function shareablePageUrl(href = window.location.href) {
  const url = new URL(href);
  url.search = '';
  url.hash = '';
  url.pathname = url.pathname.replace(/\.html$/, '');
  return url.href;
}

// Share goes on the same row as the Back to Apps button at the top of the page, on the right
function placeShareButton(title) {
  const backToApps = document.querySelector('body > .container > a.btn-secondary');
  if (!backToApps) return;
  const topRow = document.createElement('div');
  topRow.className = 'page-top-row';
  backToApps.replaceWith(topRow);
  backToApps.classList.remove('mb-3');
  topRow.appendChild(backToApps);
  topRow.appendChild(createShareButton(title));
}

// "Share": the share sheet on phones and tablets, otherwise copies the link
function createShareButton(title) {
  const button = document.createElement('button');
  button.type = 'button';
  button.className = 'btn btn-info share-button';
  button.textContent = '🔗 Share';
  button.addEventListener('click', async () => {
    const url = shareablePageUrl();
    if (navigator.share && window.matchMedia('(pointer: coarse)').matches) {
      try {
        await navigator.share({ title, url });
      } catch {
        // Cancelled
      }
      return;
    }
    try {
      await navigator.clipboard.writeText(url);
      button.textContent = '✓ Link copied';
      setTimeout(() => { button.textContent = '🔗 Share'; }, 2000);
    } catch {
      window.prompt('Copy this link:', url);
    }
  });
  return button;
}

export function restoreViewerScroll(scrollY) {
  const restore = () => window.scrollTo(0, scrollY);

  // Restore immediately when the catalogue is already laid out (for example,
  // from the back/forward cache), then correct once the web font has finished
  // loading because it can change card heights above the saved position.
  restore();
  const fontsReady = document.fonts?.ready || Promise.resolve();
  fontsReady.then(() => {
    restore();
    requestAnimationFrame(() => requestAnimationFrame(restore));
  });
}

// --- CACHE MANAGEMENT ---
// Simple in-memory cache to avoid redundant network requests
// Data persists only for this page lifetime; each page load revalidates it.
const appCache = {
  appsList: null,
  brokenApps: null,
  catalogueMetadata: null,
  isAppsListLoaded: false,
  isBrokenAppsLoaded: false,
  isCatalogueMetadataLoaded: false
};

// Function to clear cache (useful for development or manual refresh)
function clearAppCache() {
  appCache.appsList = null;
  appCache.brokenApps = null;
  appCache.catalogueMetadata = null;
  appCache.isAppsListLoaded = false;
  appCache.isBrokenAppsLoaded = false;
  appCache.isCatalogueMetadataLoaded = false;
}

// Function to preload all data (useful for optimizing initial page load)
async function preloadAppData() {
  const [apps, brokenApps] = await Promise.all([
    fetchAppsList(),
    fetchBrokenApps()
  ]);
  return { apps, brokenApps };
}

// --- INDEX PAGE LOGIC ---
async function fetchBrokenApps() {
  // Return cached data if available
  if (appCache.isBrokenAppsLoaded) {
    console.log('📋 Using cached broken apps data');
    return appCache.brokenApps;
  }

  console.log('🔄 Fetching broken apps from server...');
  try {
    const res = await fetch(BROKEN_APPS_FILE, { cache: 'no-cache' });
    if (res.ok) {
      const text = await res.text();
      const brokenApps = text.split('\n').map(line => line.trim()).filter(line => line);

      // Cache the result
      appCache.brokenApps = brokenApps;
      appCache.isBrokenAppsLoaded = true;
      console.log(`✅ Cached ${brokenApps.length} broken apps`);

      return brokenApps;
    }
  } catch (e) {
    console.error('Failed to load broken apps:', e);
  }

  // Cache empty array as fallback
  appCache.brokenApps = [];
  appCache.isBrokenAppsLoaded = true;
  return [];
}

async function fetchAppsList() {
  // Return cached data if available
  if (appCache.isAppsListLoaded) {
    console.log('📋 Using cached apps list data');
    return appCache.appsList;
  }

  console.log('🔄 Fetching apps list from server...');
  // Load the generated apps.json file
  try {
    const res = await fetch(BASE_PATH + 'apps.json', { cache: 'no-cache' });
    if (res.ok) {
      const apps = await res.json();

      // Cache the result
      appCache.appsList = apps;
      appCache.isAppsListLoaded = true;
      console.log(`✅ Cached ${apps.length} apps`);

      return apps;
    }
  } catch (e) {
    console.error('Failed to load apps.json:', e);
  }

  // Cache empty array as fallback
  appCache.appsList = [];
  appCache.isAppsListLoaded = true;
  return [];
}

async function fetchCatalogueMetadata() {
  if (appCache.isCatalogueMetadataLoaded) return appCache.catalogueMetadata;

  try {
    const response = await fetch(CATALOGUE_META_FILE, { cache: 'no-cache' });
    if (response.ok) {
      appCache.catalogueMetadata = normalizeCatalogueMetadata(await response.json());
    }
  } catch (error) {
    console.warn('Catalogue provenance is unavailable:', error);
  }

  appCache.isCatalogueMetadataLoaded = true;
  return appCache.catalogueMetadata;
}

export function normalizeCatalogueMetadata(metadata) {
  const validRepository = typeof metadata?.repository === 'string' &&
    /^github\.com\/[a-z0-9_.-]+\/[a-z0-9_.-]+$/i.test(metadata.repository);
  const validCommit = typeof metadata?.commit === 'string' &&
    /^(?:[a-f0-9]{40}|[a-f0-9]{64})$/i.test(metadata.commit);

  if (metadata?.schemaVersion !== 1 || !validRepository || !validCommit) return null;

  return {
    repository: metadata.repository.toLowerCase(),
    commit: metadata.commit.toLowerCase()
  };
}

export function buildAppSourceUrl(metadata, appName) {
  if (!metadata) return null;
  return `https://${metadata.repository}/tree/main/apps/${encodeURIComponent(appName)}`;
}

function createPixelGithubIcon() {
  const icon = document.createElement('img');
  icon.src = `${BASE_PATH}github-logo.svg`;
  icon.alt = '';
  icon.className = 'github-pixel-icon';
  return icon;
}

function renderAppsList(
  apps,
  brokenApps = [],
  displayMode = 'standard',
  { limit = apps.length, onLoadMore = null } = {}
) {
  const list = document.getElementById('apps-list');
  appListObserver?.disconnect();
  appListObserver = null;
  list.querySelectorAll('[data-bs-toggle="tooltip"]').forEach(element => {
    bootstrap.Tooltip.getInstance(element)?.dispose();
  });
  list.replaceChildren();
  apps.slice(0, limit).forEach(app => {
    const card = document.createElement('div');
    card.className = 'col-6 col-md-4 app-list-item';

    // Check if the app's star file is in the broken apps list
    const isBroken = isAppBroken(app, brokenApps);

    // Create card structure
    const cardDiv = document.createElement('div');
    cardDiv.className = 'card h-100';

    // Create image container with clickable link
    const imageContainer = document.createElement('div');
    imageContainer.className = 'position-relative';
    if (displayMode === 'wide') {
      imageContainer.classList.add('app-2x');
    } else if (displayMode === 'square') {
      imageContainer.classList.add('app-square');
    }

    // Create badge container
    const badgeContainer = document.createElement('div');
    badgeContainer.className = 'badge-container';
    
    // Add 2x badge if needed
    if (displayMode === 'standard' && app.supports2x) {
      const badge2x = document.createElement('div');
      badge2x.className = 'app-badge badge-2x pixel-tooltip';
      badge2x.dataset.tooltip = 'Supports Wide / 2x';
      badge2x.setAttribute('aria-label', 'Supports Wide / 2x');
      badge2x.setAttribute('tabindex', '0');
      badge2x.textContent = '2X';
      badgeContainer.appendChild(badge2x);
    }

    // URL for app details page
    const detailUrl = buildViewerStateUrl(BASE_PATH + `details/${encodeURIComponent(app.name)}`);

    // Wrap image in a link
    const imageLink = document.createElement('a');
    imageLink.href = detailUrl;
    imageLink.className = 'text-decoration-none';
    imageLink.addEventListener('click', rememberViewerScroll);

    // Create image element
    let imageElement;
    if (displayMode === 'square' && app.image64x64) {
      imageElement = document.createElement('img');
      imageElement.src = `${APPS_DIR}/${app.image64x64}`;
      imageElement.className = 'card-img-top';
      imageElement.alt = `${app.name} square preview`;
      imageElement.loading = 'lazy';
      imageElement.decoding = 'async';
    } else if (displayMode === 'wide' && app.image2x) {
      imageElement = document.createElement('img');
      imageElement.src = `${APPS_DIR}/${app.image2x}`;
      imageElement.className = 'card-img-top';
      imageElement.alt = app.name;
      imageElement.loading = 'lazy';
      imageElement.decoding = 'async';
    } else if (app.image) {
      imageElement = document.createElement('img');
      imageElement.src = `${APPS_DIR}/${app.image}`;
      imageElement.className = 'card-img-top';
      imageElement.alt = app.name; // Safe: alt attribute is automatically escaped
      imageElement.loading = 'lazy';
      imageElement.decoding = 'async';
    } else {
      imageElement = document.createElement('div');
      imageElement.className = 'card-img-top d-flex align-items-center justify-content-center bg-secondary text-white';
      imageElement.textContent = 'No Image';
    }
    imageLink.appendChild(imageElement);
    imageContainer.appendChild(imageLink);
    imageContainer.appendChild(badgeContainer);

    // Create card body
    const cardBody = document.createElement('div');
    cardBody.className = 'card-body d-flex flex-column';

    // Create clickable title
    const titleLink = document.createElement('a');
    titleLink.href = detailUrl;
    titleLink.className = 'text-decoration-none d-block';
    titleLink.addEventListener('click', rememberViewerScroll);

    const title = document.createElement('h5');
    title.className = 'card-title app-card-title';

    const titleText = document.createElement('span');
    titleText.textContent = app.displayName || app.name; // Use displayName from manifest or fallback to folder name
    title.appendChild(titleText);

    if (isBroken) {
      const warningSpan = document.createElement('span');
      warningSpan.className = 'app-card-broken-icon text-warning pixel-tooltip';
      warningSpan.dataset.tooltip = 'Broken app';
      warningSpan.setAttribute('aria-label', 'Broken app');
      warningSpan.setAttribute('tabindex', '0');
      warningSpan.textContent = '⚠️';
      title.appendChild(warningSpan);
    }

    titleLink.appendChild(title);
    cardBody.appendChild(titleLink);

    // Create summary/description if it exists (use summary first, then description)
    const cardText = app.summary || app.description;
    if (cardText) {
      const description = document.createElement('p');
      description.className = 'card-description small mb-3';
      description.textContent = cardText; // Safe: textContent prevents XSS
      cardBody.appendChild(description);
    }

    // Create button - all apps should have details from manifest
    const button = document.createElement('a');
    button.href = detailUrl;
    button.className = 'btn btn-primary mt-auto';
    button.textContent = '📄 View Details';
    button.addEventListener('click', rememberViewerScroll);

    cardBody.appendChild(button);

    // Assemble the card
    cardDiv.appendChild(imageContainer);
    cardDiv.appendChild(cardBody);
    card.appendChild(cardDiv);
    list.appendChild(card);
  });

  if (limit < apps.length && onLoadMore) {
    const moreContainer = document.createElement('div');
    moreContainer.className = 'col-12 d-flex justify-content-center app-list-more';
    moreContainer.setAttribute('aria-live', 'polite');

    const moreButton = document.createElement('button');
    moreButton.type = 'button';
    moreButton.className = 'btn btn-secondary';
    moreButton.textContent = `Load more (${apps.length - limit} remaining)`;
    moreButton.addEventListener('click', onLoadMore);

    moreContainer.appendChild(moreButton);
    list.appendChild(moreContainer);

    if ('IntersectionObserver' in window) {
      moreButton.hidden = true;
      const loadingText = document.createElement('span');
      loadingText.className = 'app-list-loading';
      loadingText.textContent = 'More apps load automatically as you scroll';
      moreContainer.appendChild(loadingText);

      appListObserver = new IntersectionObserver(entries => {
        if (!entries.some(entry => entry.isIntersecting)) return;
        appListObserver?.disconnect();
        appListObserver = null;
        loadingText.textContent = 'Loading more apps…';
        onLoadMore();
      }, { rootMargin: '600px 0px' });
      appListObserver.observe(moreContainer);
    }
  }
}

function isAppBroken(app, brokenApps = []) {
  return app.broken === true || Boolean(app.starFile && brokenApps.includes(app.starFile));
}

export function filterAndSortApps(apps, {
  search = '',
  category = '',
  tag = '',
  display = 'standard',
  sort = DEFAULT_SORT_ORDER,
  hideBroken = false,
  brokenApps = []
} = {}) {
  const searchValue = search.toLowerCase();
  const filtered = apps.filter(app => {
    const matchesSearch = !searchValue ||
      app.name.toLowerCase().includes(searchValue) ||
      (app.displayName && app.displayName.toLowerCase().includes(searchValue)) ||
      (app.summary && app.summary.toLowerCase().includes(searchValue)) ||
      (app.description && app.description.toLowerCase().includes(searchValue)) ||
      (app.author && app.author.toLowerCase().includes(searchValue)) ||
      (app.category && app.category.toLowerCase().includes(searchValue)) ||
      (app.tags && app.tags.some(value => value.toLowerCase().includes(searchValue)));
    const matchesCategory = !category || app.category === category;
    const matchesTag = !tag || (app.tags && app.tags.includes(tag));
    const matchesDisplay = display === 'standard' ||
      (display === 'wide' && app.supports2x) ||
      (display === 'square' && app.supports64x64);
    const matchesBroken = !hideBroken || !isAppBroken(app, brokenApps);
    return matchesSearch && matchesCategory && matchesTag && matchesDisplay && matchesBroken;
  });

  return filtered.sort((a, b) => {
    if (sort === 'newest') {
      const dateA = a.published ? new Date(a.published) : new Date(0);
      const dateB = b.published ? new Date(b.published) : new Date(0);
      return dateB - dateA;
    }
    if (sort === 'updated') {
      const dateA = a.updated ? new Date(a.updated) : new Date(0);
      const dateB = b.updated ? new Date(b.updated) : new Date(0);
      return dateB - dateA;
    }

    const nameA = (a.displayName || a.name).toLowerCase();
    const nameB = (b.displayName || b.name).toLowerCase();
    return nameA.localeCompare(nameB);
  });
}

function setupSearch(apps, brokenApps) {
  const search = document.getElementById('search');
  const clearButton = document.getElementById('clear-search');
  const selectedTagFilter = document.getElementById('selected-tag-filter');
  const selectedTagLabel = document.getElementById('selected-tag-label');
  const clearTagFilter = document.getElementById('clear-tag-filter');
  const categoryFilter = document.getElementById('category-filter');
  const displayFilter = document.getElementById('display-filter');
  const sortOrder = document.getElementById('sort-order');
  const hideBrokenApps = document.getElementById('hide-broken-apps');
  const queryParams = new URLSearchParams(window.location.search);
  const requestedScroll = Number.parseInt(queryParams.get('scroll') || '', 10);
  const requestedCount = Number.parseInt(queryParams.get('count') || '', 10);
  let visibleCount = Number.isFinite(requestedCount) && requestedCount > APP_BATCH_SIZE
    ? requestedCount
    : APP_BATCH_SIZE;
  let searchTimer;

  if (queryParams.get('hideBroken') === '1') {
    hideBrokenApps.checked = true;
  } else {
    try {
      hideBrokenApps.checked = localStorage.getItem('hideBrokenApps') === 'true';
    } catch {
      hideBrokenApps.checked = false;
    }
  }

  // Extract and populate categories
  const categories = [...new Set(apps.map(app => app.category).filter(Boolean))].sort();
  categories.forEach(cat => {
    const option = document.createElement('option');
    option.value = cat;
    option.textContent = cat.charAt(0).toUpperCase() + cat.slice(1);
    categoryFilter.appendChild(option);
  });

  const knownTags = new Set(apps.flatMap(app => app.tags || []));
  const requestedTag = queryParams.get('tag');
  let selectedTag = requestedTag && knownTags.has(requestedTag) ? requestedTag : '';

  search.value = queryParams.get('q') || '';

  const requestedCategory = queryParams.get('category');
  if (requestedCategory && categories.includes(requestedCategory)) {
    categoryFilter.value = requestedCategory;
  }

  const requestedDisplay = queryParams.get('display');
  if (['standard', 'wide', 'square'].includes(requestedDisplay)) {
    displayFilter.value = requestedDisplay;
  }

  const requestedSort = queryParams.get('sort');
  if (['updated', 'alphabetical', 'newest'].includes(requestedSort)) {
    sortOrder.value = requestedSort;
  }

  function updateSelectedTag() {
    selectedTagLabel.textContent = selectedTag;
    selectedTagFilter.hidden = !selectedTag;
  }

  updateSelectedTag();

  function filterApps({ resetVisible = true } = {}) {
    if (resetVisible) visibleCount = APP_BATCH_SIZE;
    const searchVal = search.value.toLowerCase();
    const categoryVal = categoryFilter.value;
    const displayVal = displayFilter.value;
    const sortVal = sortOrder.value;

    const url = new URL(window.location.href);
    const setOrDelete = (name, value, defaultValue = '') => {
      if (value && value !== defaultValue) {
        url.searchParams.set(name, value);
      } else {
        url.searchParams.delete(name);
      }
    };
    setOrDelete('q', search.value.trim());
    setOrDelete('category', categoryVal);
    setOrDelete('display', displayVal, 'standard');
    setOrDelete('sort', sortVal, DEFAULT_SORT_ORDER);
    setOrDelete('tag', selectedTag);
    setOrDelete('hideBroken', hideBrokenApps.checked ? '1' : '');
    setOrDelete('count', visibleCount > APP_BATCH_SIZE ? String(visibleCount) : '');
    url.searchParams.delete('scroll');
    window.history.replaceState({}, '', url);

    const filtered = filterAndSortApps(apps, {
      search: searchVal,
      category: categoryVal,
      tag: selectedTag,
      display: displayVal,
      sort: sortVal,
      hideBroken: hideBrokenApps.checked,
      brokenApps
    });

    renderAppsList(filtered, brokenApps, displayVal, {
      limit: visibleCount,
      onLoadMore: () => {
        visibleCount += APP_BATCH_SIZE;
        filterApps({ resetVisible: false });
      }
    });

    // The clear button belongs to the search field, so only show it for text.
    clearButton.style.display = searchVal ? 'block' : 'none';
  }

  // Handle search input
  search.addEventListener('input', () => {
    window.clearTimeout(searchTimer);
    searchTimer = window.setTimeout(filterApps, SEARCH_DEBOUNCE_MS);
  });

  // Handle filter changes
  categoryFilter.addEventListener('change', filterApps);
  displayFilter.addEventListener('change', filterApps);
  sortOrder.addEventListener('change', filterApps);
  hideBrokenApps.addEventListener('change', () => {
    try {
      localStorage.setItem('hideBrokenApps', String(hideBrokenApps.checked));
    } catch {
      // Filtering still works for this page when storage is unavailable.
    }
    filterApps();
  });

  // Handle clear button click
  clearButton.addEventListener('click', () => {
    window.clearTimeout(searchTimer);
    search.value = '';
    filterApps();
    search.focus();
  });

  clearTagFilter.addEventListener('click', () => {
    selectedTag = '';
    updateSelectedTag();
    filterApps();
    search.focus();
  });

  filterApps({ resetVisible: false });
  if (Number.isFinite(requestedScroll) && requestedScroll > 0) {
    restoreViewerScroll(requestedScroll);
  }
}

// --- APP DETAIL PAGE LOGIC ---
async function fetchAppMarkdown(appName) {
  const apps = await fetchAppsList();
  const app = apps.find(a => a.name === appName);

  if (!app || !app.md) {
    return null;
  }

  try {
    const response = await fetch(`${APPS_DIR}/${app.md}`);
    if (response.ok) {
      return await response.text();
    }
  } catch (error) {
    console.error('Error fetching markdown:', error);
  }

  return null;
}

function resolveAppAssetUrl(value, appName) {
  if (!value || typeof value !== 'string') return value;
  value = normalizeReadmeImageUrl(value);
  const normalizedAppsDir = APPS_DIR.replace(/\/+$/, '');
  if (value === normalizedAppsDir || value.startsWith(`${normalizedAppsDir}/`)) return value;
  if (/^(?:[a-z][a-z0-9+.-]*:|\/\/|\/|apps\/)/i.test(value)) return value;
  return `${APPS_DIR}/${appName}/${value}`;
}

function formatManifestDate(value) {
  if (!value) return null;
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  return new Intl.DateTimeFormat('en-GB', {
    day: 'numeric',
    month: 'long',
    year: 'numeric',
    timeZone: 'UTC'
  }).format(date);
}

function getAppNameFromURL() {
  const params = new URLSearchParams(window.location.search);
  const paramApp = params.get('app');
  if (paramApp) return paramApp;

  // Try parsing from meta tag if on nested details page
  const metaApp = document.querySelector('meta[name="app-name"]');
  if (metaApp) return metaApp.getAttribute('content');

  // Fallback to filename
  const pathname = window.location.pathname;
  if (pathname.includes('/details/')) {
    const match = pathname.match(/\/details\/([^/]+?)(?:\.html)?$/);
    if (match) return decodeURIComponent(match[1]);
  }

  return null;
}

function configureBackToAppsLink(link, fallbackUrl) {
  link.href = fallbackUrl;
  link.addEventListener('click', event => {
    if (event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;

    try {
      const referrer = new URL(document.referrer);
      const catalogueUrl = new URL(fallbackUrl, window.location.href);
      const catalogueDirectory = catalogueUrl.pathname.replace(/index\.html$/, '');
      const cameFromCatalogue = referrer.origin === window.location.origin &&
        (referrer.pathname === catalogueUrl.pathname || referrer.pathname === catalogueDirectory);
      if (!cameFromCatalogue) return;
    } catch {
      return;
    }

    event.preventDefault();
    window.history.back();
  });
}

async function renderAppDetail() {
  const appName = getAppNameFromURL();
  const container = document.getElementById('app-content');
  const backToAppsUrl = buildViewerStateUrl(`${BASE_PATH}index.html`);
  const headerBackButton = document.querySelector('body > .container > a.btn-secondary');
  if (headerBackButton) configureBackToAppsLink(headerBackButton, backToAppsUrl);
  if (!appName) {
    // Safe: static HTML content
    container.innerHTML = '<div class="alert alert-danger">App not specified.</div>';
    return;
  }

  // Clear container and create elements programmatically
  container.replaceChildren();

  // Get app data and check if app is broken
  const apps = await fetchAppsList();
  const app = apps.find(a => a.name === appName);

  if (!app) {
    const notFoundAlert = document.createElement('div');
    notFoundAlert.className = 'alert alert-danger';
    notFoundAlert.textContent = 'App not found.';
    container.appendChild(notFoundAlert);
    return;
  }

  const [brokenApps, catalogueMetadata] = await Promise.all([
    fetchBrokenApps(),
    fetchCatalogueMetadata()
  ]);
  const isBroken = isAppBroken(app, brokenApps);
  const appSourceUrl = buildAppSourceUrl(catalogueMetadata, appName);

  // Create app details section from manifest data
  const detailsSection = document.createElement('div');
  detailsSection.className = 'app-summary mb-4';

  // App title
  const title = document.createElement('h1');
  title.className = 'mb-3';
  title.textContent = app.displayName || app.name;
  detailsSection.appendChild(title);

  // App details and previews
  const detailsTable = document.createElement('div');
  detailsTable.className = 'app-details-layout mb-4';

  const leftCol = document.createElement('div');
  leftCol.className = 'app-details-metadata';

  if (app.description) {
    const description = document.createElement('p');
    description.className = 'app-summary-description';
    description.textContent = app.description;
    leftCol.appendChild(description);
  }

  // Create details list
  const detailsList = document.createElement('dl');
  detailsList.className = 'app-metadata';

  // Add details from manifest
  if (app.author) {
    const authorTerm = document.createElement('dt');
    authorTerm.textContent = 'Author:';
    const authorDesc = document.createElement('dd');
    if (app.authorSlug) {
      const authorLink = document.createElement('a');
      authorLink.href = `${BASE_PATH}authors/${encodeURIComponent(app.authorSlug)}`;
      authorLink.className = 'author-link';
      authorLink.textContent = app.author;
      authorDesc.appendChild(authorLink);
    } else {
      authorDesc.textContent = app.author;
    }
    detailsList.appendChild(authorTerm);
    detailsList.appendChild(authorDesc);
  }

  if (app.recommendedInterval) {
    const intervalTerm = document.createElement('dt');
    intervalTerm.textContent = 'Update Interval:';
    const intervalDesc = document.createElement('dd');
    intervalDesc.textContent = `${app.recommendedInterval} minutes`;
    detailsList.appendChild(intervalTerm);
    detailsList.appendChild(intervalDesc);
  }

  if (app.published) {
    const publishedTerm = document.createElement('dt');
    publishedTerm.textContent = 'Published:';
    const publishedDesc = document.createElement('dd');
    const publishedTime = document.createElement('time');
    publishedTime.dateTime = app.published;
    publishedTime.textContent = formatManifestDate(app.published);
    publishedDesc.appendChild(publishedTime);
    detailsList.appendChild(publishedTerm);
    detailsList.appendChild(publishedDesc);
  }

  if (app.updated) {
    const updatedTerm = document.createElement('dt');
    updatedTerm.textContent = 'Last Updated:';
    const updatedDesc = document.createElement('dd');
    const updatedTime = document.createElement('time');
    updatedTime.dateTime = app.updated;
    updatedTime.textContent = formatManifestDate(app.updated);
    updatedDesc.appendChild(updatedTime);
    detailsList.appendChild(updatedTerm);
    detailsList.appendChild(updatedDesc);
  }

  const displaysTerm = document.createElement('dt');
  displaysTerm.textContent = 'Displays:';
  const displaysDesc = document.createElement('dd');
  displaysDesc.className = 'app-display-capabilities';
  const displayCapabilities = [
    { mode: 'standard', label: 'Standard / 1x' }
  ];
  if (app.supports2x) {
    displayCapabilities.push({ mode: 'wide', label: 'Wide / 2x' });
  }
  if (app.supports64x64) {
    displayCapabilities.push({ mode: 'square', label: 'Square' });
  }
  displayCapabilities.forEach(({ mode, label }) => {
    const link = document.createElement('a');
    link.href = `${BASE_PATH}index.html?display=${mode}`;
    link.textContent = label;
    displaysDesc.appendChild(link);
  });
  detailsList.appendChild(displaysTerm);
  detailsList.appendChild(displaysDesc);

  leftCol.appendChild(detailsList);

  if (isBroken) {
    const brokenNotice = document.createElement('aside');
    brokenNotice.className = 'app-broken-notice';
    brokenNotice.setAttribute('aria-label', 'Broken app warning');

    const brokenIcon = document.createElement('span');
    brokenIcon.className = 'app-broken-icon';
    brokenIcon.setAttribute('aria-hidden', 'true');
    brokenIcon.textContent = '⚠️';

    const brokenText = document.createElement('div');
    const brokenHeading = document.createElement('strong');
    brokenHeading.textContent = 'Marked as broken';
    const brokenReason = document.createElement('p');
    brokenReason.textContent = app.brokenReason || 'No reason has been provided.';

    brokenText.appendChild(brokenHeading);
    brokenText.appendChild(brokenReason);
    brokenNotice.appendChild(brokenIcon);
    brokenNotice.appendChild(brokenText);
    leftCol.appendChild(brokenNotice);
  }
  detailsTable.appendChild(leftCol);

  // Add app image if available
  if (app.image || app.image2x || app.image64x64) {
    const rightCol = document.createElement('div');
    rightCol.className = 'app-details-previews';

    const imageContainer = document.createElement('div');
    imageContainer.className = 'app-preview-gallery';

    const hasWidePreview = Boolean(app.supports2x && app.image2x);
    const previewCount = Number(hasWidePreview) + Number(Boolean(app.image)) + Number(Boolean(app.image64x64));
    if (previewCount === 1 && !hasWidePreview) {
      imageContainer.classList.add('app-preview-gallery-single');
    }

    function appendPreview(imagePath, previewClass, dimensions, altText, maskClass = '') {
      const figure = document.createElement('figure');
      figure.className = `app-preview ${previewClass} mb-0`;
      if (maskClass) figure.classList.add(maskClass);

      const image = document.createElement('img');
      image.src = `${APPS_DIR}/${imagePath}`;
      image.alt = altText;
      image.loading = 'lazy';
      image.decoding = 'async';
      image.className = 'app-preview-image img-fluid rounded border';
      if (previewClass === 'app-preview-square') {
        image.classList.add('app-preview-image-square');
      }

      const badge = document.createElement('span');
      badge.className = 'app-badge badge-dimensions app-preview-badge';
      badge.textContent = dimensions;

      figure.appendChild(image);
      figure.appendChild(badge);
      imageContainer.appendChild(figure);
    }

    if (hasWidePreview) {
      appendPreview(
        app.image2x,
        'app-preview-wide',
        '128×64',
        `${app.displayName || app.name} 128×64 preview`,
        'app-2x'
      );
    }

    if (app.image) {
      appendPreview(
        app.image,
        'app-preview-standard',
        '64×32',
        `${app.displayName || app.name} 64×32 preview`
      );
    }

    if (app.image64x64) {
      appendPreview(
        app.image64x64,
        'app-preview-square',
        '64×64',
        `${app.displayName || app.name} 64×64 preview`
      );
    }

    rightCol.appendChild(imageContainer);
    detailsTable.appendChild(rightCol);
  }

  detailsSection.appendChild(detailsTable);

  if (app.tags?.length) {
    const tags = document.createElement('nav');
    tags.className = 'app-tags';
    tags.setAttribute('aria-label', 'App tags');

    const tagsLabel = document.createElement('span');
    tagsLabel.className = 'app-tags-label';
    tagsLabel.textContent = 'Tags:';
    tags.appendChild(tagsLabel);

    app.tags.forEach(tag => {
      const tagLink = document.createElement('a');
      tagLink.className = 'app-tag-pill';
      tagLink.href = `${BASE_PATH}index.html?tag=${encodeURIComponent(tag)}`;
      tagLink.textContent = tag;
      tags.appendChild(tagLink);
    });

    detailsSection.appendChild(tags);
  }

  container.appendChild(detailsSection);

  // Try to load markdown for additional details
  const md = await fetchAppMarkdown(appName);

  if (md) {
    const readmeSection = document.createElement('section');
    readmeSection.className = 'app-readme-section';

    // Add README section header
    const moreDetailsHeader = document.createElement('h2');
    moreDetailsHeader.className = 'mb-3';
    moreDetailsHeader.textContent = 'Readme';
    readmeSection.appendChild(moreDetailsHeader);

    try {
      // Custom renderer to fix image paths
      const renderer = new marked.Renderer();
      renderer.image = function(href, title, text) {
        // Handle both old and new marked.js API
        if (typeof href === 'object' && href !== null) {
          // New API: href is a token object
          const token = href;
          href = token.href;
          title = token.title;
          text = token.text;
        }

        // If href is relative, prefix with correct app path
        href = resolveAppAssetUrl(href, appName);
        let out = `<img src="${href || ''}" alt="${text || ''}"`;
        if (title) out += ` title="${title}"`;
        out += ' />';
        return out;
      };

      // Create a div to hold the sanitized markdown content
      const markdownContainer = document.createElement('div');
      markdownContainer.className = 'app-readme';
      markdownContainer.innerHTML = DOMPurify.sanitize(marked.parse(md, { renderer }));
      markdownContainer.querySelectorAll('img').forEach(image => {
        const resolvedSrc = resolveAppAssetUrl(image.getAttribute('src'), appName);
        if (resolvedSrc) image.src = resolvedSrc;
        if (!image.alt) image.alt = `${app.displayName || app.name} screenshot`;
        image.referrerPolicy = 'no-referrer';
        image.loading = 'lazy';
        image.decoding = 'async';

        const classifyImage = () => {
          const kind = classifyReadmeImage({
            width: image.naturalWidth,
            height: image.naturalHeight,
            source: image.currentSrc || image.src,
            supports2x: app.supports2x,
            supports64x64: app.supports64x64
          });
          if (!kind) return;
          image.classList.add('readme-device-screenshot', `readme-device-${kind}`);
        };

        if (image.complete) {
          if (image.naturalWidth > 0) classifyImage();
        } else {
          image.addEventListener('load', classifyImage, { once: true });
        }
      });
      readmeSection.appendChild(markdownContainer);
    } catch (error) {
      console.error('Marked.js error:', error);

      // Create error alert
      const errorAlert = document.createElement('div');
      errorAlert.className = 'alert alert-danger';
      errorAlert.textContent = 'Error rendering markdown: ' + error.message;
      readmeSection.appendChild(errorAlert);

      // Show raw markdown as fallback
      const pre = document.createElement('pre');
      pre.textContent = md; // Safe: textContent prevents XSS
      readmeSection.appendChild(pre);
    }

    container.appendChild(readmeSection);
  }

  placeShareButton(`${app.displayName || appName} - Tronbyt App`);

  // Add buttons at the bottom - Back to Apps on left, Report Issue on right
  const reportContainer = document.createElement('div');
  reportContainer.className = 'detail-footer mt-4 pt-4 border-top d-flex justify-content-between';

  // Back to Apps button (left side)
  const backButton = document.createElement('a');
  configureBackToAppsLink(backButton, backToAppsUrl);
  backButton.className = 'btn btn-secondary';
  backButton.textContent = '← Back to Apps';

  // Report Issue button (right side)
  const rightActions = document.createElement('div');
  rightActions.className = 'detail-actions';

  let sourceLink = null;
  if (appSourceUrl) {
    sourceLink = document.createElement('a');
    sourceLink.href = appSourceUrl;
    sourceLink.target = '_blank';
    sourceLink.rel = 'noopener';
    sourceLink.className = 'app-source-link pixel-tooltip';
    sourceLink.dataset.tooltip = 'View app source on GitHub';
    sourceLink.setAttribute('aria-label', 'View app source on GitHub');
    sourceLink.appendChild(createPixelGithubIcon());
  }

  let reportControl;
  if (isBroken) {
    const reportTooltip = document.createElement('span');
    reportTooltip.className = 'd-inline-block';
    reportTooltip.title = 'Already Reported';
    reportTooltip.setAttribute('data-bs-toggle', 'tooltip');
    reportTooltip.setAttribute('tabindex', '0');

    const reportButton = document.createElement('button');
    reportButton.type = 'button';
    reportButton.className = 'btn btn-warning report-button';
    reportButton.disabled = true;
    reportButton.textContent = '🐛 Report Issue';
    reportTooltip.appendChild(reportButton);
    reportControl = reportTooltip;
  } else {
    const reportButton = document.createElement('a');
    const reportTitle = `Feedback for app: ${app.displayName || appName}`;
    const appReference = appSourceUrl
      ? `App folder: [\`apps/${appName}\`](${appSourceUrl})`
      : `App: \`apps/${appName}\``;
    const reportBody = `${appReference}\n\nPlease describe your feedback, problem, or suggestion:`;
    const reportUrl = `https://github.com/tronbyt/apps/issues/new?title=${encodeURIComponent(reportTitle)}&body=${encodeURIComponent(reportBody)}`;
    reportButton.href = reportUrl;
    reportButton.target = '_blank';
    reportButton.rel = 'noopener';
    reportButton.className = 'btn btn-warning report-button';
    reportButton.textContent = '🐛 Report Issue';
    reportControl = reportButton;
  }

  reportContainer.appendChild(backButton);
  rightActions.appendChild(reportControl);
  if (sourceLink) rightActions.appendChild(sourceLink);
  reportContainer.appendChild(rightActions);
  container.appendChild(reportContainer);

  // Initialize tooltips for the app detail page
  const tooltips = document.querySelectorAll('[data-bs-toggle="tooltip"]');
  tooltips.forEach(tooltip => {
    new bootstrap.Tooltip(tooltip, {
      customClass: 'tooltip-custom'
    });
  });
}

// --- AUTHOR PROFILE PAGE LOGIC ---
function getAuthorSlugFromURL() {
  const metaAuthor = document.querySelector('meta[name="author-slug"]');
  if (metaAuthor) return metaAuthor.getAttribute('content');

  const pathname = window.location.pathname;
  if (pathname.includes('/authors/')) {
    const match = pathname.match(/\/authors\/([^/]+?)(?:\.html)?$/);
    if (match) return decodeURIComponent(match[1]);
  }

  return null;
}

async function renderAuthorProfile() {
  const container = document.getElementById('author-content');
  const authorSlug = getAuthorSlugFromURL();

  if (!authorSlug) {
    container.innerHTML = '<div class="alert alert-danger">Author not specified.</div>';
    return;
  }

  const { apps, brokenApps } = await preloadAppData();
  const authorApps = apps.filter(app => app.authorSlug === authorSlug);

  if (authorApps.length === 0) {
    container.innerHTML = '<div class="alert alert-danger">Author not found.</div>';
    return;
  }

  const metaAuthorName = document.querySelector('meta[name="author-name"]');
  const authorName = metaAuthorName?.getAttribute('content') || authorApps[0].author;

  container.replaceChildren(); // Remove the summary written into the page for search engines

  const header = document.createElement('div');
  header.className = 'author-profile-header mb-4';

  const title = document.createElement('h1');
  title.className = 'main-title mb-3';
  title.textContent = authorName;

  placeShareButton(`${authorName} - Tronbyt Apps`);

  header.appendChild(title);
  header.appendChild(createDisplayCounts(authorApps));
  container.appendChild(header);

  // Display and Sort, as on the catalogue. They start from the catalogue's choices when the page was opened from it.
  const state = currentViewerState();
  // Only the displays at least one of the author's apps supports (every app works on a standard display)
  const displayOptions = DISPLAY_OPTIONS.filter(([value]) => value === 'standard' ||
    (value === 'wide' && authorApps.some(app => app.supports2x)) ||
    (value === 'square' && authorApps.some(app => app.supports64x64)));
  const displayFilter = createFilterSelect('display-filter', 'Display', displayOptions,
    displayOptions.some(([value]) => value === state.get('display')) ? state.get('display') : 'standard');
  const sortOrder = createFilterSelect('sort-order', 'Sort', SORT_OPTIONS,
    SORT_OPTIONS.some(([value]) => value === state.get('sort')) ? state.get('sort') : DEFAULT_SORT_ORDER);
  const filters = document.createElement('div');
  filters.className = 'author-filters mb-4';
  if (displayOptions.length > 1) filters.appendChild(displayFilter); // Only Standard: nothing to choose
  if (authorApps.length > 1) filters.appendChild(sortOrder); // Nothing to sort with one app

  // The page's dot matrix setting sits to the right of the menus
  const dotMatrix = document.getElementById('dot-matrix-toggle')?.closest('.form-check');
  if (dotMatrix) {
    const emptyWrapper = dotMatrix.parentElement;
    dotMatrix.classList.add('author-filters-dot-matrix');
    filters.appendChild(dotMatrix);
    if (emptyWrapper && !emptyWrapper.children.length) emptyWrapper.remove();
  }
  container.appendChild(filters);

  const list = document.createElement('div');
  list.id = 'apps-list';
  list.className = 'row g-4';
  container.appendChild(list);

  function showApps() {
    const display = displayFilter.value;
    const sort = sortOrder.value;

    // Remember the choices with the rest of the catalogue's state, so the app pages opened from here and Back to
    // Apps keep them, without adding them to the address
    const saved = currentViewerState();
    if (display === 'standard') saved.delete('display'); else saved.set('display', display);
    if (sort === DEFAULT_SORT_ORDER) saved.delete('sort'); else saved.set('sort', sort);
    window.history.replaceState({ ...(window.history.state || {}), viewerState: saved.toString() }, '', window.location.href);

    renderAppsList(filterAndSortApps(authorApps, { display, sort }), brokenApps, display);
  }

  displayFilter.addEventListener('change', showApps);
  sortOrder.addEventListener('change', showApps);
  showApps();
}

// A row of app counts: the total, then how many support each display (every app works on a standard display).
// Used in an author's panel and, for the whole catalogue, in the footer, where each count also shows its share of the total.
function createDisplayCounts(apps, { showPercent = false } = {}) {
  const count = document.createElement('span');
  count.className = 'display-counts-total';
  count.textContent = `${apps.length.toLocaleString('en-US')} ${apps.length === 1 ? 'app' : 'apps'}`;

  const displayCounts = document.createElement('div');
  displayCounts.className = 'display-counts';
  displayCounts.appendChild(count);
  // The counts for each display wrap within their own block, so a wrapped line starts under the first of them
  const countClip = document.createElement('div');
  countClip.className = 'display-counts-clip';
  const countList = document.createElement('div');
  countList.className = 'display-counts-list';
  countClip.appendChild(countList);
  displayCounts.appendChild(countClip);
  for (const [value, label] of DISPLAY_OPTIONS) {
    const supported = apps.filter(app => value === 'standard' ||
      (value === 'wide' && app.supports2x) || (value === 'square' && app.supports64x64)).length;
    if (!supported) continue;
    const box = document.createElement('span');
    box.className = 'display-count';
    const name = document.createElement('span');
    name.textContent = label;
    const number = document.createElement('span');
    number.className = 'display-count-number';
    number.textContent = `${supported.toLocaleString('en-US')} ${supported === 1 ? 'app' : 'apps'}`;
    const text = document.createElement('span');
    text.className = 'display-count-text';
    text.appendChild(name);
    // The share stays with its count, so the two wrap together
    if (showPercent) {
      const percent = document.createElement('span');
      percent.className = 'display-count-percent';
      percent.textContent = `(${formatShare(supported, apps.length)})`;
      number.appendChild(percent);
    }
    text.appendChild(number);
    box.appendChild(text);
    countList.appendChild(box);
  }
  return displayCounts;
}

// A share of the total as a whole percentage, never rounded up to 100% or down to 0%
function formatShare(part, total) {
  const percent = Math.round(part / total * 100);
  if (part < total && percent === 100) return '99%';
  if (part > 0 && percent === 0) return '<1%';
  return `${percent}%`;
}

// A thin footer on every page: a link to Tronbyt, and the catalogue's app counts
async function renderSiteFooter() {
  const page = document.querySelector('body > .container');
  if (!page || page.querySelector('.site-footer')) return;
  const apps = await fetchAppsList();

  const footer = document.createElement('footer');
  footer.className = 'site-footer';
  const link = document.createElement('a');
  link.href = 'https://tronbyt.com/';
  link.target = '_blank';
  link.rel = 'noopener';
  link.textContent = 'Learn about Tronbyt';
  footer.appendChild(link);
  if (apps.length) footer.appendChild(createDisplayCounts(apps, { showPercent: true }));
  page.appendChild(footer);
}

const DISPLAY_OPTIONS = [['standard', 'Standard / 1x'], ['wide', 'Wide / 2x'], ['square', 'Square']];
const SORT_OPTIONS = [['alphabetical', 'A-Z'], ['newest', 'Newest'], ['updated', 'Last Updated']];

function createFilterSelect(id, label, options, selected) {
  const select = document.createElement('select');
  select.id = id;
  select.className = 'form-select';
  select.setAttribute('aria-label', label);
  for (const [value, text] of options) {
    const option = document.createElement('option');
    option.value = value;
    option.textContent = `${label}: ${text}`;
    option.selected = value === selected;
    select.appendChild(option);
  }
  return select;
}

// --- INIT ---
document.addEventListener('DOMContentLoaded', async () => {
  if (document.getElementById('author-content')) {
    // Author profile page
    tidyPageAddress();
    await renderAuthorProfile();
    setupDotMatrixToggle();
  } else if (document.getElementById('apps-list')) {
    // Index page - preload all data simultaneously
    const { apps, brokenApps } = await preloadAppData();
    setupSearch(apps, brokenApps);
    setupDotMatrixToggle();
  } else if (document.getElementById('app-content')) {
    // App detail page
    tidyPageAddress();
    setupDotMatrixToggle();
    await renderAppDetail();
  }
  renderSiteFooter();
});

// --- DOT MATRIX TOGGLE ---
function setupDotMatrixToggle() {
  const toggle = document.getElementById('dot-matrix-toggle');
  if (!toggle) return;

  // Load saved preference from localStorage, default to true (enabled)
  const savedState = localStorage.getItem('dotMatrixEnabled');
  if (savedState === null) {
    // First time visiting - use the default checked state
    toggle.checked = true;
    document.body.classList.add('dot-matrix-enabled');
    localStorage.setItem('dotMatrixEnabled', 'true');
  } else if (savedState === 'true') {
    toggle.checked = true;
    document.body.classList.add('dot-matrix-enabled');
  } else {
    toggle.checked = false;
    document.body.classList.remove('dot-matrix-enabled');
  }

  // Handle toggle changes
  toggle.addEventListener('change', function() {
    if (this.checked) {
      document.body.classList.add('dot-matrix-enabled');
      localStorage.setItem('dotMatrixEnabled', 'true');
    } else {
      document.body.classList.remove('dot-matrix-enabled');
      localStorage.setItem('dotMatrixEnabled', 'false');
    }
  });
}
