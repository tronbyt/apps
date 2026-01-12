// --- CONFIG ---
// Use GitHub Pages structure for both local and production
const APPS_DIR = '../apps';
const BROKEN_APPS_FILE = '../broken_apps.txt';
const IMAGE_EXTS = ['.png', '.jpg', '.jpeg', '.gif', '.webp'];
const MD_FILES = ['README.md', 'readme.md', 'index.md'];

// --- CACHE MANAGEMENT ---
// Simple in-memory cache to avoid redundant network requests
// Data persists for the duration of the browser session
const appCache = {
  appsList: null,
  brokenApps: null,
  isAppsListLoaded: false,
  isBrokenAppsLoaded: false
};

// Function to clear cache (useful for development or manual refresh)
function clearAppCache() {
  appCache.appsList = null;
  appCache.brokenApps = null;
  appCache.isAppsListLoaded = false;
  appCache.isBrokenAppsLoaded = false;
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
    const res = await fetch(BROKEN_APPS_FILE);
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
    const res = await fetch('apps.json');
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

function renderAppsList(apps, brokenApps = []) {
  const list = document.getElementById('apps-list');
  list.replaceChildren();
  apps.forEach(app => {
    const card = document.createElement('div');
    card.className = 'col-md-4';

    // Check if the app's star file is in the broken apps list
    const isBroken = app.starFile && brokenApps.includes(app.starFile);

    // Create card structure
    const cardDiv = document.createElement('div');
    cardDiv.className = 'card h-100';

    // Create image container with clickable link
    const imageContainer = document.createElement('div');
    imageContainer.className = 'position-relative';
    if (app.supports2x) {
      imageContainer.classList.add('app-2x');
    }

    // Create badge container
    const badgeContainer = document.createElement('div');
    badgeContainer.className = 'badge-container';
    
    // Add broken badge if needed
    if (isBroken) {
      const brokenBadge = document.createElement('div');
      brokenBadge.className = 'app-badge badge-broken';
      brokenBadge.title = 'This app is marked as broken';
      brokenBadge.setAttribute('data-bs-toggle', 'tooltip');
      brokenBadge.textContent = '⚠️';
      badgeContainer.appendChild(brokenBadge);
    }

    // Add 2x badge if needed
    if (app.supports2x) {
      const badge2x = document.createElement('div');
      badge2x.className = 'app-badge badge-2x';
      badge2x.title = 'Supports 2x resolution';
      badge2x.setAttribute('data-bs-toggle', 'tooltip');
      badge2x.textContent = '2X';
      badgeContainer.appendChild(badge2x);
    }

    // Wrap image in a link
    const imageLink = document.createElement('a');
    imageLink.href = `app.html?app=${encodeURIComponent(app.name)}`;
    imageLink.className = 'text-decoration-none';

    // Create image element
    let imageElement;
    if (app.supports2x && app.image2x) {
      imageElement = document.createElement('img');
      imageElement.src = `${APPS_DIR}/${app.image2x}`;
      imageElement.className = 'card-img-top';
      imageElement.alt = app.name;
    } else if (app.image) {
      imageElement = document.createElement('img');
      imageElement.src = `${APPS_DIR}/${app.image}`;
      imageElement.className = 'card-img-top';
      imageElement.alt = app.name; // Safe: alt attribute is automatically escaped
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
    titleLink.href = `app.html?app=${encodeURIComponent(app.name)}`;
    titleLink.className = 'text-decoration-none';

    const title = document.createElement('h5');
    title.className = 'card-title';
    title.textContent = app.displayName || app.name; // Use displayName from manifest or fallback to folder name

    if (isBroken) {
      const warningSpan = document.createElement('span');
      warningSpan.className = 'text-warning';
      warningSpan.title = 'Broken app';
      warningSpan.setAttribute('data-bs-toggle', 'tooltip');
      warningSpan.textContent = ' ⚠️';
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
    button.href = `app.html?app=${encodeURIComponent(app.name)}`;
    button.className = 'btn btn-primary mt-auto';
    button.textContent = '📄 View Details';

    cardBody.appendChild(button);

    // Assemble the card
    cardDiv.appendChild(imageContainer);
    cardDiv.appendChild(cardBody);
    card.appendChild(cardDiv);
    list.appendChild(card);
  });

  // Initialize tooltips
  const tooltips = document.querySelectorAll('[data-bs-toggle="tooltip"]');
  tooltips.forEach(tooltip => {
    new bootstrap.Tooltip(tooltip, {
      customClass: 'tooltip-custom'
    });
  });
}

function setupSearch(apps, brokenApps) {
  const search = document.getElementById('search');
  const clearButton = document.getElementById('clear-search');

  // Handle search input
  search.addEventListener('input', () => {
    const val = search.value.toLowerCase();
    renderAppsList(apps.filter(app =>
      app.name.toLowerCase().includes(val) ||
      (app.displayName && app.displayName.toLowerCase().includes(val)) ||
      (app.summary && app.summary.toLowerCase().includes(val))
    ), brokenApps);

    // Show/hide clear button based on input
    clearButton.style.display = val ? 'block' : 'none';
  });

  // Handle clear button click
  clearButton.addEventListener('click', () => {
    search.value = '';
    renderAppsList(apps, brokenApps);
    clearButton.style.display = 'none';
    search.focus(); // Return focus to search input
  });

  // Initially hide clear button
  clearButton.style.display = 'none';
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

function getAppNameFromURL() {
  const params = new URLSearchParams(window.location.search);
  return params.get('app');
}

async function renderAppDetail() {
  const appName = getAppNameFromURL();
  const container = document.getElementById('app-content');
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

  const brokenApps = await fetchBrokenApps();
  const isBroken = app.starFile && brokenApps.includes(app.starFile);

  // Add broken app warning if needed
  if (isBroken) {
    const brokenAlert = document.createElement('div');
    brokenAlert.className = 'alert alert-warning';

    const strongElement = document.createElement('strong');

    const warningIcon = document.createElement('span');
    warningIcon.title = 'This app has been reported as broken';
    warningIcon.setAttribute('data-bs-toggle', 'tooltip');
    warningIcon.textContent = '⚠️';

    strongElement.appendChild(warningIcon);
    strongElement.appendChild(document.createTextNode(' This app is marked as broken'));
    brokenAlert.appendChild(strongElement);
    container.appendChild(brokenAlert);
  }

  // Create app details section from manifest data
  const detailsSection = document.createElement('div');
  detailsSection.className = 'mb-4';

  // App title
  const title = document.createElement('h1');
  title.className = 'mb-3';
  title.textContent = app.displayName || app.name;
  detailsSection.appendChild(title);

  // App details table
  const detailsTable = document.createElement('div');
  detailsTable.className = 'row mb-4';

  const leftCol = document.createElement('div');
  leftCol.className = 'col-md-8';

  // Create details list
  const detailsList = document.createElement('dl');
  detailsList.className = 'row';

  // Add details from manifest
  if (app.author) {
    const authorTerm = document.createElement('dt');
    authorTerm.className = 'col-sm-3';
    authorTerm.textContent = 'Author:';
    const authorDesc = document.createElement('dd');
    authorDesc.className = 'col-sm-9';
    authorDesc.textContent = app.author;
    detailsList.appendChild(authorTerm);
    detailsList.appendChild(authorDesc);
  }

  if (app.recommendedInterval) {
    const intervalTerm = document.createElement('dt');
    intervalTerm.className = 'col-sm-3';
    intervalTerm.textContent = 'Update Interval:';
    const intervalDesc = document.createElement('dd');
    intervalDesc.className = 'col-sm-9';
    intervalDesc.textContent = `${app.recommendedInterval} minutes`;
    detailsList.appendChild(intervalTerm);
    detailsList.appendChild(intervalDesc);
  }

  if (app.description) {
    const descTerm = document.createElement('dt');
    descTerm.className = 'col-sm-3';
    descTerm.textContent = 'Description:';
    const descDesc = document.createElement('dd');
    descDesc.className = 'col-sm-9';
    descDesc.textContent = app.description;
    detailsList.appendChild(descTerm);
    detailsList.appendChild(descDesc);
  }

  leftCol.appendChild(detailsList);
  detailsTable.appendChild(leftCol);

  // Add app image if available
  if (app.image) {
    const rightCol = document.createElement('div');
    rightCol.className = 'col-md-4';

    const imageContainer = document.createElement('div');
    imageContainer.className = 'text-center';

    const image = document.createElement('img');
    image.src = `${APPS_DIR}/${app.image}`;
    image.alt = app.displayName || app.name;
    image.className = 'img-fluid rounded border';
    image.style.maxHeight = '200px';

    imageContainer.appendChild(image);
    rightCol.appendChild(imageContainer);
    detailsTable.appendChild(rightCol);
  }

  detailsSection.appendChild(detailsTable);
  container.appendChild(detailsSection);

  // Try to load markdown for additional details
  const md = await fetchAppMarkdown(appName);

  if (md) {
    // Add "More Details" section header
    const moreDetailsHeader = document.createElement('h2');
    moreDetailsHeader.className = 'mt-4 mb-3';
    moreDetailsHeader.textContent = 'Readme';
    container.appendChild(moreDetailsHeader);

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
        if (href && typeof href === 'string' && !href.match(/^(https?:\/\/|\/|apps\/)/)) {
          href = `${APPS_DIR}/${appName}/${href}`;
        }
        let out = `<img src="${href || ''}" alt="${text || ''}"`;
        if (title) out += ` title="${title}"`;
        out += ' />';
        return out;
      };

      // Create a div to hold the sanitized markdown content
      const markdownContainer = document.createElement('div');
      markdownContainer.innerHTML = DOMPurify.sanitize(marked.parse(md, { renderer }));
      container.appendChild(markdownContainer);
    } catch (error) {
      console.error('Marked.js error:', error);

      // Create error alert
      const errorAlert = document.createElement('div');
      errorAlert.className = 'alert alert-danger';
      errorAlert.textContent = 'Error rendering markdown: ' + error.message;
      container.appendChild(errorAlert);

      // Show raw markdown as fallback
      const pre = document.createElement('pre');
      pre.textContent = md; // Safe: textContent prevents XSS
      container.appendChild(pre);
    }
  }

  // Add buttons at the bottom - Back to Apps on left, Report Broken on right
  const reportContainer = document.createElement('div');
  reportContainer.className = 'mt-4 pt-4 border-top d-flex justify-content-between';

  // Back to Apps button (left side)
  const backButton = document.createElement('a');
  backButton.href = './';
  backButton.className = 'btn btn-secondary';
  backButton.textContent = '← Back to Apps';

  // Report Broken button (right side)
  const reportButton = document.createElement('a');
  const starFileText = app.starFile ? `\n\nStar file to add: \`${app.starFile}\`` : '\n\nNo .star file found for this app.';
  const reportUrl = `https://github.com/tronbyt/apps/issues/new?title=Report%20Broken%20App:%20${encodeURIComponent(appName)}&body=The%20app%20%60${encodeURIComponent(appName)}%60%20appears%20to%20be%20broken.%0A%0APlease%20add%20the%20following%20line%20to%20the%20%60broken_apps.txt%60%20file:${encodeURIComponent(starFileText)}`;
  reportButton.href = reportUrl;
  reportButton.target = '_blank';
  reportButton.className = 'btn btn-warning report-button';
  reportButton.textContent = isBroken ? '⚠️ Already Reported' : '🐛 Report Broken';

  reportContainer.appendChild(backButton);
  reportContainer.appendChild(reportButton);
  container.appendChild(reportContainer);

  // Initialize tooltips for the app detail page
  const tooltips = document.querySelectorAll('[data-bs-toggle="tooltip"]');
  tooltips.forEach(tooltip => {
    new bootstrap.Tooltip(tooltip, {
      customClass: 'tooltip-custom'
    });
  });
}

// --- INIT ---
document.addEventListener('DOMContentLoaded', async () => {
  if (document.getElementById('apps-list')) {
    // Index page - preload all data simultaneously
    const { apps, brokenApps } = await preloadAppData();
    renderAppsList(apps, brokenApps);
    setupSearch(apps, brokenApps);
    setupDotMatrixToggle();
  } else if (document.getElementById('app-content')) {
    // App detail page
    renderAppDetail();
    setupDotMatrixToggle();
  }
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
