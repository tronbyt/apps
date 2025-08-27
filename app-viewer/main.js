// --- CONFIG ---
// Use different paths for local development vs GitHub Pages
const APPS_DIR = window.location.hostname === 'tronbyt.github.io' ? '..' : '../apps';
const IMAGE_EXTS = ['.png', '.jpg', '.jpeg', '.gif', '.webp'];
const MD_FILES = ['README.md', 'readme.md', 'index.md'];
const BROKEN_APPS_FILE = '../broken_apps.txt';

// --- INDEX PAGE LOGIC ---
async function fetchBrokenApps() {
  try {
    const res = await fetch(BROKEN_APPS_FILE);
    if (res.ok) {
      const text = await res.text();
      return text.split('\n').map(line => line.trim()).filter(line => line);
    }
  } catch (e) {
    console.error('Failed to load broken apps:', e);
  }
  return [];
}

async function fetchAppsList() {
  // Load the generated apps.json file
  try {
    const res = await fetch('apps.json');
    if (res.ok) {
      return await res.json();
    }
  } catch (e) {
    console.error('Failed to load apps.json:', e);
  }
  return [];
}

function renderAppsList(apps, brokenApps = []) {
  const list = document.getElementById('apps-list');
  list.innerHTML = '';
  apps.forEach(app => {
    const card = document.createElement('div');
    card.className = 'col-md-4';

    // Check if any of the app's star files are in the broken apps list
    const isBroken = app.starFiles && app.starFiles.some(starFile => brokenApps.includes(starFile));

    // Create card structure
    const cardDiv = document.createElement('div');
    cardDiv.className = 'card h-100';

    // Create image container
    const imageContainer = document.createElement('div');
    imageContainer.className = 'position-relative';

    // Create image element
    let imageElement;
    if (app.image) {
      imageElement = document.createElement('img');
      imageElement.src = `${APPS_DIR}/${app.image}`;
      imageElement.className = 'card-img-top';
      imageElement.alt = app.name; // Safe: alt attribute is automatically escaped
    } else {
      imageElement = document.createElement('div');
      imageElement.className = 'card-img-top d-flex align-items-center justify-content-center bg-secondary text-white';
      imageElement.textContent = 'No Image';
    }
    imageContainer.appendChild(imageElement);

    // Add broken badge if needed
    if (isBroken) {
      const brokenBadge = document.createElement('div');
      brokenBadge.className = 'broken-badge';
      brokenBadge.title = 'This app is marked as broken';
      brokenBadge.setAttribute('data-bs-toggle', 'tooltip');
      brokenBadge.textContent = '⚠️';
      imageContainer.appendChild(brokenBadge);
    }

    // Create card body
    const cardBody = document.createElement('div');
    cardBody.className = 'card-body d-flex flex-column';

    // Create title
    const title = document.createElement('h5');
    title.className = 'card-title';
    title.textContent = app.name; // Safe: textContent prevents XSS

    if (isBroken) {
      const warningSpan = document.createElement('span');
      warningSpan.className = 'text-warning';
      warningSpan.title = 'Broken app';
      warningSpan.setAttribute('data-bs-toggle', 'tooltip');
      warningSpan.textContent = ' ⚠️';
      title.appendChild(warningSpan);
    }

    cardBody.appendChild(title);

    // Create description if it exists
    if (app.description) {
      const description = document.createElement('p');
      description.className = 'card-description small mb-3';
      description.textContent = app.description; // Safe: textContent prevents XSS
      cardBody.appendChild(description);
    }

    // Create button
    let button;
    if (app.md) {
      button = document.createElement('a');
      button.href = `app.html?app=${encodeURIComponent(app.name)}`;
      button.className = 'btn btn-primary mt-auto';
      button.textContent = '📄 View Details';
    } else {
      button = document.createElement('button');
      button.className = 'btn btn-secondary mt-auto';
      button.disabled = true;
      button.textContent = '🚫 No Details';
    }

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
  search.addEventListener('input', () => {
    const val = search.value.toLowerCase();
    renderAppsList(apps.filter(app => app.name.toLowerCase().includes(val)), brokenApps);
  });
}

// --- APP DETAIL PAGE LOGIC ---
async function fetchAppMarkdown(appName) {
  // Try to fetch the markdown file
  for (const mdFile of MD_FILES) {
    try {
      const res = await fetch(`${APPS_DIR}/${appName}/${mdFile}`);
      if (res.ok) return await res.text();
    } catch (e) {
      console.error(`Failed to fetch markdown for ${appName}/${mdFile}:`, e);
    }
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
  container.innerHTML = '';

  // Get app data and check if app is broken
  const apps = await fetchAppsList();
  const app = apps.find(a => a.name === appName);
  const brokenApps = await fetchBrokenApps();
  const isBroken = app && app.starFiles && app.starFiles.some(starFile => brokenApps.includes(starFile));

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

  const md = await fetchAppMarkdown(appName);

  if (md) {
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
          const basePath = window.location.hostname === 'tronbyt.github.io' ? '..' : '../apps';
          href = `${basePath}/${appName}/${href}`;
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
  } else {
    // No documentation available
    const noDocsAlert = document.createElement('div');
    noDocsAlert.className = 'alert alert-warning';
    noDocsAlert.textContent = 'No documentation available.';
    container.appendChild(noDocsAlert);
  }

  // Add Report Broken button
  const reportContainer = document.createElement('div');
  reportContainer.className = 'mt-4 pt-4 border-top';

  const reportButton = document.createElement('a');
  const reportUrl = `https://github.com/tronbyt/apps/issues/new?title=Report%20Broken%20App:%20${encodeURIComponent(appName)}&body=The%20app%20%60${encodeURIComponent(appName)}%60%20appears%20to%20be%20broken.%0A%0APlease%20add%20the%20appropriate%20.star%20file%20to%20the%20%60broken_apps.txt%60%20file.`;
  reportButton.href = reportUrl;
  reportButton.target = '_blank';
  reportButton.className = 'btn btn-warning report-button';
  reportButton.textContent = isBroken ? '⚠️ Already Reported' : '🐛 Report Broken';

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
    // Index page
    const apps = await fetchAppsList();
    const brokenApps = await fetchBrokenApps();
    renderAppsList(apps, brokenApps);
    setupSearch(apps, brokenApps);
  } else if (document.getElementById('app-content')) {
    // App detail page
    renderAppDetail();
  }
});
