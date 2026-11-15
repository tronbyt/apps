# SolarEdge Proxy for Tronbyt

A small service for your Raspberry Pi that logs in to the **SolarEdge Monitoring API V2**
(OAuth 2.0 "Site Access"), keeps the login alive, and serves a simple JSON endpoint that the
**SolarEdge Summary** Tronbyt app reads.

SolarEdge retired the old site-ID + API-key access. The new login uses OAuth tokens that expire
every 2 hours and rotate on every refresh, which a Tronbyt app cannot store. The proxy does that
job, so the app only needs the proxy's address and a password.

```
SolarEdge cloud  <--OAuth, every ~30 min-->  solaredge-proxy (Pi, port 10001)  <--http, LAN-->  Tronbyt server  -->  Tidbyt
                                              keeps tokens + cached numbers                      solaredgesummary.star
```

## Contents of this package

| File | What it is |
|---|---|
| `app.py` | The proxy (Flask + background poller). Also runs the smoke test: `python app.py check` |
| `login.py` | One-time authorization: follows SolarEdge's documented login flow and saves the tokens |
| `requirements.txt` | Python dependencies (`solaredge` client pinned to 3.3.0) |
| `solaredge-proxy.service` | systemd unit (starts at boot, restarts on failure) |
| `solaredge-proxy.env.example` | Template for `/etc/solaredge-proxy.env` |
| `../solaredgesummary/solaredgesummary.star` | The updated Tronbyt app (shows Today / Week / Month / Year / Lifetime) |

The live monitor app (`solaredge`) is **not** covered here. See "Not included" at the end.

## What the app shows

Five screens, with production (sun, green) and consumption (plug, red):

- **Today**: since local midnight
- **Week**: the last 7 days including today
- **Month**: month to date
- **Year**: year to date
- **Lifetime**: since the system was installed

## How it keeps within the free API quota

The SolarEdge free tier allows about **2,000 API calls per month** (about 64 per day). The proxy
makes the calls itself on a fixed schedule, so how often Tronbyt redraws the app never costs a call.

| What | When | Calls |
|---|---|---|
| Completed totals (week, month, year, lifetime up to the end of yesterday) | once a day, after local midnight | up to 4 |
| "Today" (production + consumption since midnight) | every 30 min, around the clock | 48 |
| One-time site details (time zone, install date) | first start only | 1 |

Week, month, year and lifetime on screen are *completed total + today*. That is **about 52 calls per
day, roughly 1,600 per month** (1,612 in a 31-day month), which leaves about 20% of the free quota spare.
Consumption keeps accumulating overnight, so "today" is refreshed every 30 minutes at night too.
30 minutes is the shortest interval that fits the free tier (every 20 minutes would need about 2,350 a month).

Safety nets:

- The proxy counts its own calls per calendar month and **stops calling at 1,800** (`SOLAREDGE_MONTHLY_CREDIT_LIMIT`). That is about 190 calls above a normal month, so repeated failures plus many `check` runs (4 calls each) could reach it.
- Cached data is saved to disk, so restarts and reboots cost no calls.
- If the Pi is offline, the proxy backs off and does not count the failed attempts.
- On errors it backs off 2, 4, 8 ... up to 30 minutes. If SolarEdge says the quota is used up (HTTP 429), it pauses for hours.

To use fewer calls, set `POLL_DAY_MINUTES=60` and `POLL_NIGHT_MINUTES=120` in the env file (about 24 calls a day, roughly 750 a month).

---

## Part 0: Requirements

- The Raspberry Pi that runs your Tronbyt server.
- **Python 3.10 or newer** on the Pi. Check with `python3 --version`. Raspberry Pi OS "Bookworm" or newer
  is fine. Older releases (Bullseye has 3.9) will not work with the SolarEdge client.
- The mySolarEdge login that owns your site.

## Part 1: Create a SolarEdge "Site Access" application

This gives the proxy permission to read your own site. It is a one-time step on SolarEdge's developer portal.
SolarEdge describes it in its developer docs (the *Applications* page and the *Homeowner and Self-Access Guide*):
<https://api-docs.solaredge.com/docs/developer-platform/df8kx5j4z9vi0-homeowner-and-self-access-guide>

1. Go to the SolarEdge developer portal (<https://developer.solaredge.com>) and sign in with your mySolarEdge (homeowner) account. Fill in the developer profile if asked. The Free tier is provisioned automatically (it allows one application).
2. Click **Create Application**. **Step 1, details:** a name (3 to 100 characters, **English letters and numbers only**, so no hyphens, e.g. `TronbytSolarProxy`), a description (10 to 500 characters, letters and numbers only) and API Service **Monitoring API**.
3. **Step 2, access type:** choose **Site Access**. This cannot be changed later. Then fill in:
   - **Allowed Redirect URI(s):** exactly `http://localhost:8080/oauth/callback` (required). This is where SolarEdge sends the browser after you approve. The authorization link itself only contains your Client ID, so the redirect address and the scopes always come from these application settings.
   - **Allowed Origin URL(s):** only needed for apps that call the API from a web browser. This proxy runs on a server, so leave it empty. If the form insists on a value, use `http://localhost:8080`.
   - **Allowed Returned URL(s):** optional, leave empty.
   - **Scopes:** enable both **`SITE_DATA`** and **`DEVICE_DATA`**. Scopes cannot be edited afterwards.
4. **Step 3, finished:** SolarEdge shows the **Client ID** (a UUID) and the **Client Secret**. **The secret is shown only once.** Copy both into a password manager, tick *I have saved my credentials*, and continue.

Afterwards:

- The Client ID can always be read again on the application's **Credentials** tab. The secret cannot, but you can click **Regenerate** there. The old secret stops working immediately, so update `/etc/solaredge-proxy.env` and restart the service. Existing access tokens keep working until they expire (about 2 hours), and refresh tokens work only with the new secret.
- The Redirect, Origin and Returned URLs can be edited later on the **OAuth Settings** tab. Name and description can be edited too. Access type and scopes cannot.
- The application's status must be **Active**. A suspended or disabled application cannot call the API.

The **Client ID and Secret are fixed credentials for your application.** They do not expire, and the proxy never
refreshes or changes them. What the proxy refreshes automatically are the *login tokens* (access token every
2 hours, refresh token on each use).

The redirect URI must match character for character. Nothing is ever listening there, and you do **not** need to
set up anything in Cloudflare for it. After you approve access, your browser ends up on a "can't connect" page
that contains a code in its address bar (Part 3).

## Part 2: Install the proxy on the Pi

```bash
sudo apt update
sudo apt install -y python3 python3-pip python3-venv

sudo mkdir -p /opt/solaredge-proxy
sudo chown $USER:$USER /opt/solaredge-proxy
```

Copy these files from this folder onto the Pi, for example from your computer (replace `RASPBERRY_PI_IP` with the Pi's address, and `pi` with your Pi user name if different):

```bash
scp app.py login.py requirements.txt solaredge-proxy.service solaredge-proxy.env.example \
    pi@RASPBERRY_PI_IP:/opt/solaredge-proxy/
```

Then, on the Pi:

```bash
cd /opt/solaredge-proxy
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

If you get an "externally-managed-environment" error, the virtual environment is not active.
Run `source venv/bin/activate` and try again.

## Part 3: Authorize the proxy (one time)

This is the step that replaces the old API key. `login.py` follows SolarEdge's documented flow: it prints the
authorization link, you approve access in your browser, and it exchanges the code for tokens.

> **Replace every placeholder.** Words in capitals such as `YOUR_CLIENT_ID` or `RASPBERRY_PI_IP` are
> placeholders. Put your own value in, including in links. A link that still contains `YOUR_CLIENT_ID` makes
> SolarEdge's page fail with "Configuration Error 400.4".

```bash
sudo mkdir -p /var/lib/solaredge-proxy
sudo chown $USER:$USER /var/lib/solaredge-proxy
chmod 700 /var/lib/solaredge-proxy

cd /opt/solaredge-proxy
source venv/bin/activate
python login.py --client-id YOUR_CLIENT_ID
```

Use the Client ID (a UUID) from your application's **Credentials** tab. The token is saved to
`/var/lib/solaredge-proxy/token.json` unless you pass `--output`.

1. It asks for the **client secret** (typing is hidden). Paste it.
2. It prints a **link** that looks like `https://connect.solaredge.com/authorize?client_id=` followed by your Client ID. Check that your real Client ID is in it. Open the link in a browser **on your computer** (the link is the same wherever you open it).
3. Sign in with your mySolarEdge account, pick your site and approve access.
4. The browser is sent to your registered Redirect URI, `http://localhost:8080/oauth/callback?code=...&site_id=...`, and shows a "can't connect" or "refused" error. **That is expected.**
5. Copy the **entire address from the address bar** and paste it into the terminal at the prompt. Do this promptly: the code is single-use and expires quickly.
6. You should see: `Saved the token for site NNNNNNN to /var/lib/solaredge-proxy/token.json (mode 600).`

Notes:

- If the message says the code is invalid, it was already used or has expired. Run `python login.py` again and use a fresh address.
- If you registered an `https` address on a domain you own as the Redirect URI instead of `localhost`, nothing changes here: the browser lands on whatever that address shows (an error or 404 page is fine) and you copy its address.
- If you ever need to change the redirect address, edit it on the application's **OAuth Settings** tab on the developer portal. The script does not need any option for it.
- **The refresh token expires after 14 days without use.** This is stated in SolarEdge's Homeowner and Self-Access Guide, which also says each successful refresh returns a new refresh token and restarts the 14 days, so a connection that refreshes regularly never expires, and you must always store the newest one. The proxy does exactly that (it saves the token file after every refresh and refreshes at least every 2 hours while it runs), but it means you should do Parts 4 to 6 within a few days of this step, not weeks later.
- **Use the token file in one place only.** SolarEdge replaces the refresh token on every use, so a second copy of `token.json` (on a laptop, in a backup) stops working the moment the proxy refreshes, and using it can break the proxy's login too.

## Part 4: Configure the proxy

```bash
sudo cp /opt/solaredge-proxy/solaredge-proxy.env.example /etc/solaredge-proxy.env
sudo nano /etc/solaredge-proxy.env
```

Fill in at least:

```
SOLAREDGE_CLIENT_ID=your_client_id_here
SOLAREDGE_CLIENT_SECRET=your_client_secret_here
PROXY_API_KEY=a_long_random_string
PORT=10001
```

Generate a random key with `openssl rand -hex 24`.
Keep comments on their own lines in this file (systemd does not support trailing comments).

Then lock the file down. Mode 640 with your own group lets you load it as your normal user for the test in
Part 5, while keeping it unreadable to other users:

```bash
sudo chown root:$(id -gn) /etc/solaredge-proxy.env
sudo chmod 640 /etc/solaredge-proxy.env
```

(`$(id -gn)` is the main group of the user you are logged in as, so this works whatever your user name is.)

## Part 5: Test the connection to SolarEdge (about 4 API calls)

```bash
cd /opt/solaredge-proxy
source venv/bin/activate
set -a; source /etc/solaredge-proxy.env; set +a
python app.py check
```

A healthy run prints the site ID, time zone and install date, then three sets of numbers
(today so far, the last 3 days plus today, and the last 3 full days) and a consistency line:

```
Consistency (whole window minus the two parts): production +0 Wh, consumption +0 Wh
```

What to look for:

- **Production and consumption both show kWh values.** If consumption says `n/a`, SolarEdge is not returning consumption for your site, which usually means there is no consumption meter.
- **The consistency differences are small** (a few Wh at most). Large differences mean the day boundaries are off, so please tell me what it printed.
- **Any error text.** `AUTH PROBLEM` means Part 3 or the client ID/secret in Part 4 needs another look. An `API ERROR` with HTTP 403 means the application in Part 1 is missing a scope.

Do not move on until this works.

## Part 6: Run it as a service

```bash
sudo cp /opt/solaredge-proxy/solaredge-proxy.service /etc/systemd/system/
sudo chmod 644 /etc/systemd/system/solaredge-proxy.service

# The file assumes the user "pi". Set it to the user you are logged in as:
sudo sed -i "s/^User=.*/User=$(whoami)/; s/^Group=.*/Group=$(id -gn)/" /etc/systemd/system/solaredge-proxy.service
grep -E "^(User|Group)=" /etc/systemd/system/solaredge-proxy.service

sudo systemctl daemon-reload
sudo systemctl enable solaredge-proxy.service
sudo systemctl start solaredge-proxy.service
sudo systemctl status solaredge-proxy.service
```

You should see **active (running)**. The service listens on port **10001**.
The `grep` line should show your own user name. It must be an account that exists on the Pi and that owns `/opt/solaredge-proxy` and `/var/lib/solaredge-proxy` (the user who ran Parts 2 and 3).
The port is set in the `ExecStart` line of that file, so change it there if 10001 is taken.
The log folder `/var/log/solaredge-proxy` is created for you by the service.

### Starting automatically after a reboot

The `systemctl enable` command above is what makes the proxy start every time the Pi boots, so
there is nothing more to set up. To confirm it:

```bash
sudo systemctl is-enabled solaredge-proxy.service   # should print: enabled
sudo systemctl is-active  solaredge-proxy.service   # should print: active
```

To test it for real, reboot and look again after a minute or two:

```bash
sudo reboot
# ... then, once the Pi is back:
sudo systemctl status solaredge-proxy.service
sudo journalctl -b -u solaredge-proxy.service      # log of the current boot only
curl http://localhost:10001/health
```

What makes this reliable:

- **It waits for the network** (`After=network-online.target` in the service file) and **restarts itself** 10 seconds after any crash or failed start (`Restart=always`).
- **Nothing is lost on a reboot.** The login token and the cached numbers live in `/var/lib/solaredge-proxy/`, and the settings in `/etc/solaredge-proxy.env`. After a reboot the proxy shows the saved numbers straight away and only calls SolarEdge when a refresh is due, so reboots cost almost no API calls.
- **Boot order does not matter.** The proxy and the Tronbyt server start independently. If Tronbyt draws the app before the proxy is ready, that one drawing shows an error and the next one works.
- The only limit is the 14-day rule: if the Pi stays off for more than 14 days, you have to authorize again (see Re-authorizing).

If `is-enabled` prints `disabled`, run `sudo systemctl enable --now solaredge-proxy.service`.
If you edit the service file later, run `sudo systemctl daemon-reload` and then
`sudo systemctl restart solaredge-proxy.service`. To stop it starting at boot, use
`sudo systemctl disable solaredge-proxy.service`.

## Part 7: Check that it works

Watch the log during the first start (the first fetch takes 10 to 15 seconds):

```bash
sudo journalctl -u solaredge-proxy.service -f
```

You should see lines like `Poller started`, `Fetching site details (one-time call)`, `Completed week: production ...`,
and `Today: production ... (calls this month: 6)`.

Then request the data from any computer on your network:

```bash
curl http://RASPBERRY_PI_IP:10001/health
curl -H "X-API-Key: YOUR_PROXY_API_KEY" http://RASPBERRY_PI_IP:10001/api/solar
curl -H "X-API-Key: YOUR_PROXY_API_KEY" http://RASPBERRY_PI_IP:10001/api/status
```

`/api/solar` returns this structure:

```json
{
  "timezone": "America/New_York",
  "timestamp": "2026-11-15T14:02:11+00:00",
  "data_age_seconds": 412,
  "stale": false,
  "periods": {
    "day":      {"production_wh": 11328, "consumption_wh": 15576},
    "week":     {"production_wh": 86328, "consumption_wh": 120000},
    "month":    {"production_wh": 177328, "consumption_wh": 250000},
    "year":     {"production_wh": 4135328, "consumption_wh": 5100000},
    "lifetime": {"production_wh": 9753280, "consumption_wh": 11000000}
  }
}
```

(The numbers above are placeholders.) `/api/status` shows how many API calls were used this month, when the
access token expires, and the last error, if any. Until the first fetch finishes, `/api/solar` answers
HTTP 503 with an `error` message, and the Tronbyt app displays that message.

## Part 8: Update the Tronbyt app

The app is `solaredgesummary.star`. Install it on your Tronbyt server as a custom app (or from the
`tronbyt/apps` repository), and keep the `images` folder (`sun_sum.png`, `plug_sum.gif`) next to it,
because the app loads those.

In the app's settings enter:

| Field | Value |
|---|---|
| **Proxy URL** | `http://RASPBERRY_PI_IP:10001` (base address only, **not** `/api/solar`) |
| **Proxy API Key** | the `PROXY_API_KEY` from `/etc/solaredge-proxy.env` |

Things to know:

- **Replace the old API key.** The old app stored your SolarEdge API key in a field called `api_key`. The new app reuses that field name for the *proxy* key, so an existing installation keeps the old value until you replace it. The old **Site ID** field is gone because the site comes from the login.
- **Demo numbers.** If the screen shows 6.28 kWh and 3.14 kWh for today, that is built-in demo data, shown when the URL or key is empty.
- **The Tronbyt server draws the app**, not the Tidbyt. The URL only has to be reachable from the Pi. If Tronbyt runs in Docker, use the Pi's LAN IP rather than `localhost`. Giving the Pi a fixed IP (for example a DHCP reservation in your router) avoids surprises.
- **Red messages.** The app shows the proxy's error text on screen, for example when login needs renewing. If the proxy has not been able to refresh for about 75 minutes (2.5 times the poll interval), the app adds a red "stale" screen after the normal five.

---

## Day-to-day

```bash
sudo systemctl status  solaredge-proxy.service
sudo systemctl restart solaredge-proxy.service
sudo journalctl -u solaredge-proxy.service -n 50
sudo tail -f /var/log/solaredge-proxy/error.log
```

**Run `python app.py check` only while the service is stopped** (`sudo systemctl stop solaredge-proxy.service`, then start it again afterwards). If the test refreshes the login, SolarEdge replaces the refresh token, and the running service would still hold the old one. The service normally recovers on its own when it sees the updated token file, but stopping it first avoids the problem.

**Updating the code:** copy the new `app.py` to `/opt/solaredge-proxy/`, then restart the service.

**Log rotation** (optional; replace `YOUR_USER` and `YOUR_GROUP` with the output of `whoami` and `id -gn`):

```bash
sudo nano /etc/logrotate.d/solaredge-proxy
```

```
/var/log/solaredge-proxy/*.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
    create 0644 YOUR_USER YOUR_GROUP
}
```

**Files the proxy writes** (in `/var/lib/solaredge-proxy/`):

- `token.json` is the OAuth login, rewritten after every token refresh, mode 600. Do not copy it elsewhere.
- `state.json` holds cached numbers, site details and the monthly call counter. It is safe to delete, but rebuilding it costs about 6 API calls and the monthly counter restarts from zero.

## Re-authorizing

You need to repeat Part 3 if any of these happen:

- The proxy was off for **more than 14 days** (SolarEdge expires a refresh token that goes 14 days without use).
- SolarEdge ends the grant (for example it expires).
- You revoked access in SolarEdge, or the token file was copied and used elsewhere.

Symptoms: the display shows a red message such as *SolarEdge refused the token request (invalid_grant)*, or `/api/status` reports an `auth_error`.

Run `python login.py --client-id YOUR_CLIENT_ID` from Part 3 again. It writes to the same token file.
The proxy notices the new file within about 30 seconds and carries on. No restart is needed, and no calls are wasted while it waits.

## Troubleshooting

| Symptom | Likely cause and fix |
|---|---|
| "Configuration Error 400.4" on SolarEdge's authorization page | The most common cause is a link that still contains the placeholder `YOUR_CLIENT_ID` instead of your real Client ID. Open the link printed by `login.py` and check the part after `client_id=`. If your real Client ID is in it, check on the developer portal that it is the UUID from the **Credentials** tab (not the application name or an App ID), that the application is **Active** with access type **Site Access**, and that the **OAuth Settings** tab lists your Redirect URI exactly (`http`/`https`, port, path and trailing slash). If it still fails, contact SolarEdge developer support. |
| `invalid_request` / "Invalid code" while running `login.py` | The authorization code was already used or has expired. Run `python login.py` again and paste a fresh address. |
| `status=217/USER`, "Failed to determine user credentials: No such process" | The `User=` in `/etc/systemd/system/solaredge-proxy.service` is not an account on this Pi (the file ships with `pi`). Run `whoami`, set `User=` and `Group=` to that name (see Part 6), then `sudo systemctl daemon-reload` and `sudo systemctl restart solaredge-proxy.service`. |
| `No usable token file ...` | Part 3 was not done, or `SOLAREDGE_TOKEN_FILE` points somewhere else. |
| `invalid_client` / token request refused right away | Wrong client ID or secret in `/etc/solaredge-proxy.env`, or the secret was regenerated on the portal. Fix it and run `sudo systemctl restart solaredge-proxy.service`. |
| `invalid_grant` | Refresh token expired or already used. Re-authorize (see above). |
| HTTP 403 | The Site Access application is missing a scope (Part 1), or your plan does not include that endpoint. |
| HTTP 400 on the lifetime call | The API may limit very long time windows. Set `SOLAREDGE_OVERVIEW_CHUNK_DAYS=366` in the env file and restart. |
| Consumption is 0 or `n/a` | SolarEdge reports no consumption for the site (no consumption meter, or it is not enabled). `/api/solar` includes a `warning` in that case. |
| `Rate limited / quota reached` | 429 from SolarEdge. The proxy pauses (15 minutes, or 6 hours if the monthly quota is gone). Check `/api/status` for `credits_used`, and consider `POLL_DAY_MINUTES=60` and `POLL_NIGHT_MINUTES=120`. |
| `Monthly credit guard reached` | The proxy's own counter hit 1,800 and it stopped on purpose. Raise `SOLAREDGE_MONTHLY_CREDIT_LIMIT` or lower the polling rate. The counter resets at the start of the next calendar month. |
| Could not determine the site time zone | Set `SOLAREDGE_TIMEZONE=America/New_York` (your zone) in the env file. |
| Tronbyt shows "Proxy Error: 401" | The Proxy API Key in the app does not match `PROXY_API_KEY`. |
| Tronbyt shows "Proxy Error: 404" | The Proxy URL includes `/api/solar`. Remove it. |
| Connection refused | Check `systemctl status`, the port (`sudo ss -tulpn \| grep 10001`) and any firewall (`sudo ufw allow 10001/tcp`). |
| Numbers look slightly different from the SolarEdge website | The website may use other cut-off times or rounding. Compare a full past day first. |

## Security notes

- Keep the proxy on your local network. If you ever expose it, put HTTPS in front of it (reverse proxy, VPN or Cloudflare Tunnel). The Tronbyt app sends its key in a header over plain http on your LAN.
- `PROXY_API_KEY` is required. If it is empty, every request is refused.
- `token.json` (mode 600) and `/etc/solaredge-proxy.env` (owner root, your group, mode 640) contain secrets. Do not commit them to Git or paste them into issues.

## Not verified against the live SolarEdge API

I did not have access to a SolarEdge account while building this. The logic is covered by 13 automated checks
against a stand-in for the SolarEdge client (window arithmetic, call counts, unit conversion, restart
persistence, credit guard, auth and offline handling, token file safety, and the HTTP endpoints), and the
API calls follow the `solaredge` 3.3.0 client library. Your first real run is the real test, which is
what `python app.py check` is for. The points it will settle:

- Whether `overview` accepts very long windows in a single call (the lifetime total). If not, use `SOLAREDGE_OVERVIEW_CHUNK_DAYS`.
- Whether SolarEdge counts each call as exactly one credit, and whether its billing cycle matches the calendar month (the proxy's counter assumes both).
- Whether the login and token requests behave as SolarEdge's documentation describes (the request formats follow that documentation exactly and are covered by tests against a stand-in).

## Not included: the live monitor app

The other app (`solaredge`, live power flow and autarky) is not converted. It needs data refreshed every
few minutes, which does not fit a 2,000-calls-a-month quota, and SolarEdge's live power-flow call is part of
the Advanced Monitoring API, which is limited to certain plans (others get HTTP 403). It would have to be
rebuilt from meter and battery telemetry, and it would show data that is minutes to half an hour old.
We can revisit it once this summary app is running.
