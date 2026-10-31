# Enphase Solar Summary for Tidbyt

Display your Enphase solar system's production and consumption data on your Tidbyt device, showing daily, weekly, monthly, yearly, and lifetime statistics.

## Overview

This project consists of two components:
1. **Python Proxy Service** - Deployed on Render.com to handle Enphase API authentication and token refresh
2. **Tidbyt App** - Starlark app that displays the solar data on your Tidbyt device

## Features

- ✅ Real-time solar production (including today)
- ✅ Historical consumption data (week, month, year, lifetime)
- ✅ Automatic OAuth token refresh
- ✅ 5 rotating screens: Today → Week → Month → Year → Lifetime


## Prerequisites

Before starting, you'll need:
- Enphase solar system with Enlighten account
- Enphase Developer account (free)
- Render.com account (free tier works)
- GitHub account (for deployment)
- Tidbyt device

---

## Part 1: Enphase API Setup

### Step 1: Register for Enphase Developer Account

1. Go to [Enphase Developer Portal](https://developer-v4.enphase.com/)
2. Sign up for a developer account
3. Choose the **Watt Plan** (free) or higher

### Step 2: Create an Application

1. Log in to the [Developer Portal](https://developer-v4.enphase.com/admin/applications)
2. Click **"Create New Application"**
3. Fill in:
   - **Application Name**: "Tidbyt Solar Display" (or your choice)
   - **Redirect URI**: `https://api.enphaseenergy.com/oauth/redirect_uri`
4. Save and note down:
   - **API Key**
   - **Client ID**
   - **Client Secret**

### Step 3: Find Your System ID

1. Log in to [Enlighten](https://enlighten.enphaseenergy.com/)
2. Go to your system dashboard
3. Look at the URL: `https://enlighten.enphaseenergy.com/systems/XXXXXX`
4. The number **XXXXXX** is your **System ID**

### Step 4: Get Initial OAuth Tokens

Create a file called `get_tokens.py`:

```python
import requests
from urllib.parse import urlencode

# Your Enphase credentials
CLIENT_ID = "your_client_id_here"
CLIENT_SECRET = "your_client_secret_here"
REDIRECT_URI = "https://api.enphaseenergy.com/oauth/redirect_uri"

# Step 1: Print authorization URL
auth_params = {
    "response_type": "code",
    "client_id": CLIENT_ID,
    "redirect_uri": REDIRECT_URI
}
auth_url = f"https://api.enphaseenergy.com/oauth/authorize?{urlencode(auth_params)}"
print(f"1. Visit this URL and authorize:\n{auth_url}\n")

# Step 2: Get authorization code
auth_code = input("2. Paste the authorization code from the redirect URL: ")

# Step 3: Exchange code for tokens
token_data = {
    "grant_type": "authorization_code",
    "code": auth_code,
    "redirect_uri": REDIRECT_URI,
}

response = requests.post(
    "https://api.enphaseenergy.com/oauth/token",
    data=token_data,
    auth=(CLIENT_ID, CLIENT_SECRET)
)

if response.status_code == 200:
    tokens = response.json()
    print("\n✅ Success! Save these tokens:\n")
    print(f"Access Token: {tokens['access_token']}")
    print(f"Refresh Token: {tokens['refresh_token']}")
else:
    print(f"\n❌ Error: {response.status_code}")
    print(response.text)
```

Run it:
```bash
pip install requests
python get_tokens.py
```

**Save the Access Token and Refresh Token** - you'll need them for Render!

---

## Part 2: Deploy Proxy Service to Render.com

### Step 1: Prepare Your Code

1. Create a new directory:
```bash
mkdir enphase-tidbyt-proxy
cd enphase-tidbyt-proxy
```

2. Create `app.py` with the Python proxy code (from the artifact)

3. Create `requirements.txt`:
```
Flask==3.0.0
requests==2.31.0
gunicorn==21.2.0
pytz==2024.1
```

4. Create `.gitignore`:
```
__pycache__/
*.pyc
.env
venv/
.DS_Store
```

### Step 2: Push to GitHub

```bash
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/enphase-tidbyt-proxy.git
git push -u origin main
```

### Step 3: Deploy on Render.com

1. Go to [Render Dashboard](https://dashboard.render.com/)
2. Click **"New +"** → **"Web Service"**
3. Connect your GitHub repository
4. Configure:
   - **Name**: `enphase-proxy` (or your choice)
   - **Environment**: `Python 3`
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `gunicorn app:app`
   - **Instance Type**: `Free`

### Step 4: Add Environment Variables

Click **"Environment"** tab and add:

| Variable | Value | Notes |
|----------|-------|-------|
| `ENPHASE_API_KEY` | Your API key | From Enphase Developer Portal |
| `ENPHASE_CLIENT_ID` | Your client ID | From app registration |
| `ENPHASE_CLIENT_SECRET` | Your client secret | Keep this secret! |
| `ENPHASE_SYSTEM_ID` | Your system ID | From Enlighten URL |
| `ENPHASE_ACCESS_TOKEN` | Initial access token | From get_tokens.py |
| `ENPHASE_REFRESH_TOKEN` | Initial refresh token | From get_tokens.py |
| `PROXY_API_KEY` | Create a random string | e.g., `tidbyt-secret-key-12345` |

### Step 5: Deploy and Test

1. Click **"Create Web Service"**
2. Wait for deployment (2-5 minutes)
3. Your service URL will be: `https://your-app-name.onrender.com`

**Test it:**
```bash
# Health check
curl https://your-app-name.onrender.com/health

# Get solar data (replace with your PROXY_API_KEY)
curl -H "X-API-Key: your-proxy-api-key" \
  https://your-app-name.onrender.com/api/solar
```

You should see JSON with your solar data!

---

## Part 3: Configure Tidbyt App

### Step 1: Install the App

1. Copy the Tidbyt Starlark code (from the artifact) into a file called `enphase_summary.star`
2. Use the Tidbyt CLI or Pixlet to install:

```bash
# Using Pixlet
pixlet serve enphase_summary.star

# Or push to your Tidbyt
pixlet push YOUR_DEVICE_ID enphase_summary.star \
  proxy_url="https://your-app-name.onrender.com" \
  api_key="your-proxy-api-key"
```

### Step 2: Configure the App

In the Tidbyt app configuration:
- **Proxy URL**: `https://your-app-name.onrender.com` (no trailing slash)
- **Proxy API Key**: Your `PROXY_API_KEY` from Render
- **Render Interval (minutes)**: 5 recommended (no more than 15min to prevent render.com service from shutting down)

---

## Understanding the Display

The Tidbyt cycles through 5 screens, each showing for 3 seconds:

### Screen 1: Energy Today
- 🌞 **Production**: Today's solar production (up to 2hrs delay)
- 🔌 **Consumption**: Today's solar production (up to 2hrs delay)

### Screen 2: Energy Week
- Last 7 days of production and consumption

### Screen 3: Energy Month
- Month-to-date production and consumption

### Screen 4: Energy Year
- Year-to-date production and consumption

### Screen 5: Energy Life
- Total lifetime production and consumption

---

## Troubleshooting

### "Proxy Error 401"
- Check that `PROXY_API_KEY` matches in both Render and Tidbyt
- Verify the URL is correct (no trailing slash)

### "Proxy Error 500"
- Check Render logs: Dashboard → Your Service → **Logs** tab
- Verify all environment variables are set correctly
- Check that tokens haven't expired

### Token Expired
Tokens expire periodically. To refresh:
1. Run `get_tokens.py` again to get new tokens
2. Update `ENPHASE_ACCESS_TOKEN` and `ENPHASE_REFRESH_TOKEN` in Render
3. The service will automatically restart

### Data Not Updating
- Production updates in real-time ✅
- Week/Month/Year/Lifetime update daily with new data


---

## Maintenance

### Token Refresh
The proxy automatically refreshes OAuth tokens. No manual intervention needed unless tokens expire completely.

### Check Status
```bash
curl -H "X-API-Key: your-proxy-api-key" \
  https://your-app-name.onrender.com/api/token/status
```

### Update Code
To update the proxy:
```bash
git add .
git commit -m "Update proxy"
git push
```
Render will automatically redeploy.

---

## Security

- ✅ All credentials stored as environment variables
- ✅ HTTPS encryption by default
- ✅ API key authentication for proxy access
- ✅ OAuth token auto-refresh
- ⚠️ Keep `PROXY_API_KEY` secret - don't share publicly

---


## Credits

- Original SolarEdge app by ckyr and ingmarstein
- Converted to Enphase by ckyr - claude.ai
- Icons: Sun and plug from original app



---

**Enjoy your solar stats on Tidbyt!** ☀️📊
