// --- CONFIG ---
const APPS_DIR = '../apps';
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
    let buttonHtml;
    if (app.md) {
      buttonHtml = `<a href="app.html?app=${encodeURIComponent(app.name)}" class="btn btn-primary mt-auto">📄 View Details</a>`;
    } else {
      buttonHtml = `<button class="btn btn-secondary mt-auto" disabled>🚫 No Details</button>`;
    }

    let imageHtml;
    if (app.image) {
      imageHtml = `<img src="${APPS_DIR}/${app.image}" class="card-img-top" alt="${app.name}">`;
    } else {
      imageHtml = `<div class="card-img-top d-flex align-items-center justify-content-center bg-secondary text-white">No Image</div>`;
    }

    card.innerHTML = `
      <div class="card h-100">
        <div class="position-relative">
          ${imageHtml}
          ${isBroken ? '<div class="broken-badge" title="This app is marked as broken" data-bs-toggle="tooltip">⚠️</div>' : ''}
        </div>
        <div class="card-body d-flex flex-column">
          <h5 class="card-title">${app.name}${isBroken ? ' <span class="text-warning" title="Broken app" data-bs-toggle="tooltip">⚠️</span>' : ''}</h5>
          ${app.description ? `<p class="card-description small mb-3">${app.description}</p>` : ''}
          ${buttonHtml}
        </div>
      </div>
    `;
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
    } catch {}
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
    container.innerHTML = '<div class="alert alert-danger">App not specified.</div>';
    return;
  }

  // Get app data and check if app is broken
  const apps = await fetchAppsList();
  const app = apps.find(a => a.name === appName);
  const brokenApps = await fetchBrokenApps();
  const isBroken = app && app.starFiles && app.starFiles.some(starFile => brokenApps.includes(starFile));

  const md = await fetchAppMarkdown(appName);
  let content = '';

  if (isBroken) {
    content += '<div class="alert alert-warning"><strong><span title="This app has been reported as broken" data-bs-toggle="tooltip">⚠️</span> This app is marked as broken</strong></div>';
  }

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
          href = `../apps/${appName}/${href}`;
        }
        let out = `<img src="${href || ''}" alt="${text || ''}"`;
        if (title) out += ` title="${title}"`;
        out += ' />';
        return out;
      };
      content += DOMPurify.sanitize(marked.parse(md, { renderer }));
    } catch (error) {
      console.error('Marked.js error:', error);
      content += '<div class="alert alert-danger">Error rendering markdown: ' + error.message + '</div>';
      content += '<pre>' + md + '</pre>'; // Show raw markdown as fallback
    }
  } else {
    content += '<div class="alert alert-warning">No documentation available.</div>';
  }

  // Add Report Broken button
  const reportUrl = `https://github.com/tronbyt/apps/issues/new?title=Report%20Broken%20App:%20${encodeURIComponent(appName)}&body=The%20app%20%60${encodeURIComponent(appName)}%60%20appears%20to%20be%20broken.%0A%0APlease%20add%20the%20appropriate%20.star%20file%20to%20the%20%60broken_apps.txt%60%20file.`;
  content += `
    <div class="mt-4 pt-4 border-top">
      <a href="${reportUrl}" target="_blank" class="btn btn-warning" style="font-family: 'Press Start 2P', monospace;">
        ${isBroken ? '⚠️ Already Reported' : '🐛 Report Broken'}
      </a>
    </div>
  `;

  container.innerHTML = content;

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
