"""
SolarEdge API Proxy Service for Tronbyt / Tidbyt
================================================

Talks to the SolarEdge Monitoring API V2 using Site Access (OAuth 2.0),
keeps the rotating tokens on disk, and serves a small JSON endpoint that the
Tronbyt "SolarEdge Summary" app reads.

Why a background poller instead of fetching on every request?
  * The free SolarEdge tier allows about 2,000 calls per month, so the number
    of API calls must not depend on how often Tronbyt renders the app.
  * Requests are answered instantly from memory, so the display never waits.

Call budget (default settings, about 52 calls/day = ~1,600/month):
  * "Completed" totals (week, month, year, lifetime up to the end of
    yesterday): fetched once per day after local midnight  (max 4 calls)
  * "Today" (production + consumption since local midnight): every 30 minutes
    around the clock, because consumption continues overnight (48 calls)
  * Week/month/year/lifetime shown = completed total + today.
  * A monthly hard stop (SOLAREDGE_MONTHLY_CREDIT_LIMIT) protects the quota.

Endpoints
  GET /health        no auth, for monitoring
  GET /api/solar     X-API-Key required, data for the Tronbyt app
  GET /api/status    X-API-Key required, credits used, token and error state

Run the one-off API smoke test with:   python app.py check
"""

import copy
import hmac
import json
import logging
import os
import sys
import tempfile
import threading
import time
from datetime import date, datetime, timedelta, timezone
from datetime import time as dtime
from zoneinfo import ZoneInfo

import httpx
from flask import Flask, jsonify, request
from solaredge import (
    MonitoringClient,
    OAuth2,
    OAuthToken,
    SolarEdgeAPIError,
    SolarEdgeAuthError,
    SolarEdgeError,
    SolarEdgeOAuthError,
    SolarEdgeRateLimitError,
)

logging.basicConfig(
    level=os.environ.get("LOG_LEVEL", "INFO"),
    format="%(asctime)s %(levelname)s %(message)s",
)
log = logging.getLogger("solaredge-proxy")

app = Flask(__name__)

# --------------------------------------------------------------------------
# Configuration (environment variables, see solaredge-proxy.env.example)
# --------------------------------------------------------------------------
CLIENT_ID = os.environ.get("SOLAREDGE_CLIENT_ID", "")
CLIENT_SECRET = os.environ.get("SOLAREDGE_CLIENT_SECRET", "")
PROXY_API_KEY = os.environ.get("PROXY_API_KEY", "")
SITE_ID_ENV = os.environ.get("SOLAREDGE_SITE_ID", "").strip()

TOKEN_FILE = os.environ.get("SOLAREDGE_TOKEN_FILE", "/var/lib/solaredge-proxy/token.json")
STATE_FILE = os.environ.get("SOLAREDGE_STATE_FILE", "/var/lib/solaredge-proxy/state.json")

# Optional overrides. If both are set the proxy never needs the site-details call.
TIMEZONE_ENV = os.environ.get("SOLAREDGE_TIMEZONE", "").strip()          # e.g. America/New_York
LIFETIME_START_ENV = os.environ.get("SOLAREDGE_LIFETIME_START", "").strip()  # e.g. 2021-06-01

POLL_DAY_MINUTES = int(os.environ.get("POLL_DAY_MINUTES", "30"))
POLL_NIGHT_MINUTES = int(os.environ.get("POLL_NIGHT_MINUTES", "30"))
DAY_START_HOUR = int(os.environ.get("DAY_START_HOUR", "6"))
DAY_END_HOUR = int(os.environ.get("DAY_END_HOUR", "21"))

# Stop calling the API once this many calls were made in a calendar month.
MONTHLY_CREDIT_LIMIT = int(os.environ.get("SOLAREDGE_MONTHLY_CREDIT_LIMIT", "1800"))

# 0 = fetch each window with one call. If the API rejects very long windows
# (HTTP 400 on the lifetime call), set to e.g. 366 to split them into chunks.
OVERVIEW_CHUNK_DAYS = int(os.environ.get("SOLAREDGE_OVERVIEW_CHUNK_DAYS", "0"))

CALL_GAP_SECONDS = 1.0       # stay far below the 10 calls/minute limit
LOOP_SECONDS = 30            # how often the poller checks whether anything is due

UNIT_TO_WH = {"WH": 1.0, "KWH": 1e3, "MWH": 1e6, "GWH": 1e9}


class NeedsAuth(Exception):
    """The token file is missing/invalid or SolarEdge rejected our credentials."""


# --------------------------------------------------------------------------
# Small helpers
# --------------------------------------------------------------------------
def atomic_write_json(path, data):
    """Write JSON so that a crash can never leave a half-written file."""
    directory = os.path.dirname(path) or "."
    fd, tmp = tempfile.mkstemp(dir=directory, prefix=".tmp-", suffix=".json")
    try:
        with os.fdopen(fd, "w") as fh:
            json.dump(data, fh, indent=2)
            fh.write("\n")
            fh.flush()
            os.fsync(fh.fileno())
        os.chmod(tmp, 0o600)
        os.replace(tmp, path)
    except Exception:
        try:
            os.remove(tmp)
        except OSError:
            pass
        raise


def to_wh(block):
    """Convert a {'total': x, 'unit': 'KWH'} block to Wh. None if no total."""
    if not isinstance(block, dict) or block.get("total") is None:
        return None
    unit = str(block.get("unit") or "WH").upper()
    return float(block["total"]) * UNIT_TO_WH.get(unit, 1.0)


def local_midnight(d, tz):
    return datetime.combine(d, dtime.min, tzinfo=tz)


def parse_date(text):
    """Accept 'YYYY-MM-DD' or an ISO timestamp; return a date or None."""
    try:
        return date.fromisoformat(str(text)[:10])
    except (TypeError, ValueError):
        return None


# --------------------------------------------------------------------------
# The data source: tokens, API calls, caching, credit accounting
# --------------------------------------------------------------------------
class SolarEdgeSource:
    def __init__(self):
        self.state_lock = threading.Lock()    # protects self.state (short holds)
        self.refresh_lock = threading.Lock()  # one refresh at a time
        self.state = self._load_state()
        self.client = None
        self.auth = None
        self.auth_error = None
        self.last_error = None
        self.retry_after = 0.0
        self.failures = 0
        self._token_mtime = None
        self._last_guard_log = 0.0

    # ---- state file ------------------------------------------------------
    @staticmethod
    def _load_state():
        try:
            with open(STATE_FILE) as fh:
                return json.load(fh)
        except (OSError, ValueError):
            return {}

    def _save_state(self):
        try:
            with self.state_lock:
                snapshot = copy.deepcopy(self.state)
            atomic_write_json(STATE_FILE, snapshot)
        except OSError as exc:
            log.error("Could not save state file %s: %s", STATE_FILE, exc)

    # ---- token handling --------------------------------------------------
    def _save_token(self, token):
        """Called by the OAuth client after EVERY refresh.

        SolarEdge rotates the refresh token on each use and the old one stops
        working, so this write is what keeps the proxy logged in across
        restarts. Retry a few times; the new token also stays in memory.
        """
        for attempt in range(1, 4):
            try:
                atomic_write_json(TOKEN_FILE, token.to_dict())
                self._token_mtime = os.path.getmtime(TOKEN_FILE)
                log.info("Saved refreshed SolarEdge token")
                return
            except OSError as exc:
                log.error("Saving token failed (attempt %d/3): %s", attempt, exc)
                time.sleep(0.5)
        log.critical(
            "COULD NOT SAVE THE REFRESHED TOKEN to %s. The proxy keeps working "
            "until it restarts; fix the disk/permissions problem now, or re-run "
            "the login step after the next restart.",
            TOKEN_FILE,
        )

    def _token_file_changed(self):
        try:
            return os.path.getmtime(TOKEN_FILE) != self._token_mtime
        except OSError:
            return False

    def _ensure_client(self):
        if self.client is not None:
            return self.client
        if not (CLIENT_ID and CLIENT_SECRET):
            raise NeedsAuth("SOLAREDGE_CLIENT_ID / SOLAREDGE_CLIENT_SECRET are not set")
        try:
            with open(TOKEN_FILE) as fh:
                token = OAuthToken.from_dict(json.load(fh))
            self._token_mtime = os.path.getmtime(TOKEN_FILE)
        except (OSError, ValueError, SolarEdgeError) as exc:
            raise NeedsAuth(
                f"No usable token file at {TOKEN_FILE} ({exc}). "
                "Run 'python -m solaredge login' and copy the token file there."
            )
        self.auth = OAuth2(
            token,
            client_id=CLIENT_ID,
            client_secret=CLIENT_SECRET,
            on_token_update=self._save_token,
        )
        self.client = MonitoringClient(oauth=self.auth)
        return self.client

    def _reset_client(self):
        if self.client is not None:
            try:
                self.client.close()
            except Exception:
                pass
        self.client = None
        self.auth = None

    # ---- credit accounting and API calls -----------------------------------
    def _credits(self, month_key):
        credits = self.state.setdefault("credits", {})
        if credits.get("month") != month_key:
            credits["month"] = month_key
            credits["used"] = 0
        return credits

    def _api(self, month_key, func, *args):
        """One API call, counted against the monthly budget (even if it fails)."""
        with self.state_lock:
            self._credits(month_key)["used"] += 1
        self._save_state()
        time.sleep(CALL_GAP_SECONDS)
        try:
            return func(*args)
        except httpx.ConnectError:
            # The request never reached SolarEdge (Pi offline, DNS down), so it
            # cost no credit. Don't let an outage eat the monthly budget.
            with self.state_lock:
                self._credits(month_key)["used"] -= 1
            raise

    # ---- site info (timezone, install date), fetched once ----------------------
    def _site_id(self):
        if SITE_ID_ENV:
            return int(SITE_ID_ENV)
        if self.auth is not None and self.auth.token.site_id:
            return int(self.auth.token.site_id)
        raise NeedsAuth("Site ID unknown: set SOLAREDGE_SITE_ID in the env file")

    def _site_info(self, month_key):
        site = self.state.get("site") or {}
        tzname = TIMEZONE_ENV or site.get("timezone")
        start = LIFETIME_START_ENV or site.get("installed")
        if tzname and start:
            return {"timezone": tzname, "installed": start}

        log.info("Fetching site details (one-time call)")
        data = self._api(month_key, self.client.get_site_details, self._site_id())
        data = data.get("details", data) if isinstance(data, dict) else {}
        tzname = tzname or (data.get("location") or {}).get("timezone")
        if not tzname:
            raise RuntimeError(
                "Could not determine the site time zone; set SOLAREDGE_TIMEZONE "
                "(e.g. America/New_York) in the env file."
            )
        installed = start or parse_date(data.get("installationDate"))
        installed = installed.isoformat() if isinstance(installed, date) else (installed or "2010-01-01")
        info = {"timezone": tzname, "installed": installed}
        with self.state_lock:
            self.state["site"] = info
        self._save_state()
        return info

    # ---- the one data call -------------------------------------------------
    def _overview(self, month_key, start, end):
        """Production and consumption in Wh between two aware datetimes.

        Returns (production_wh, consumption_wh_or_None).
        """
        if OVERVIEW_CHUNK_DAYS > 0 and (end - start) > timedelta(days=OVERVIEW_CHUNK_DAYS):
            prod, cons, has_cons = 0.0, 0.0, False
            cursor = start
            while cursor < end:
                nxt = min(cursor + timedelta(days=OVERVIEW_CHUNK_DAYS), end)
                p, c = self._overview(month_key, cursor, nxt)
                prod += p
                if c is not None:
                    cons += c
                    has_cons = True
                cursor = nxt
            return prod, (cons if has_cons else None)

        data = self._api(month_key, self.client.get_overview, self._site_id(), start, end)
        prod = to_wh((data or {}).get("production"))
        cons = to_wh((data or {}).get("consumption"))
        return (prod or 0.0), cons

    # ---- scheduling --------------------------------------------------------
    def refresh_if_due(self):
        """Fetch whatever is due. Called by the poller thread every 30 s."""
        with self.refresh_lock:
            if self.auth_error:
                if not self._token_file_changed():
                    return
                log.info("Token file changed, retrying authorization")
                self.auth_error = None
                self._reset_client()
            if time.time() < self.retry_after:
                return
            try:
                # _refresh returns a note when it deliberately did nothing
                # (credit guard), otherwise None.
                self.last_error = self._refresh()
                self.failures = 0
            except NeedsAuth as exc:
                self.auth_error = str(exc)
                self.last_error = str(exc)
                log.error("Authorization needed: %s", exc)
            except SolarEdgeOAuthError as exc:
                # The token endpoint refused us. 400/401/403 are deterministic:
                # wrong client secret, or the refresh token is used up/expired.
                if exc.status_code in (400, 401, 403):
                    self.auth_error = (
                        f"SolarEdge refused the token request ({exc.error or exc.status_code}): "
                        "run the login step again and replace the token file"
                    )
                    self.last_error = self.auth_error
                    self._reset_client()
                    log.error("%s", self.auth_error)
                else:
                    self._note_failure(exc)
            except SolarEdgeAuthError as exc:
                self.auth_error = f"SolarEdge rejected the request (401/403): {exc}"
                self.last_error = self.auth_error
                self._reset_client()
                log.error("%s", self.auth_error)
            except SolarEdgeRateLimitError as exc:
                # No Retry-After header usually means the monthly quota is used up.
                pause = 6 * 3600 if exc.retry_after is None else 15 * 60
                self.last_error = f"Rate limited / quota reached: {exc}"
                self.retry_after = time.time() + pause
                log.error("%s (pausing %d min)", self.last_error, pause // 60)
            except Exception as exc:  # network errors, timeouts, bad responses ...
                self._note_failure(exc)

    def _note_failure(self, exc):
        """Transient failure: back off 2, 4, 8 ... up to 30 minutes."""
        self.failures += 1
        self.last_error = f"{type(exc).__name__}: {exc}"
        delay = min(30 * 60, 120 * 2 ** (self.failures - 1))
        self.retry_after = time.time() + delay
        log.error("Refresh failed (%s); retrying in %ds", self.last_error, delay)

    def _refresh(self):
        self._ensure_client()
        month_key_probe = datetime.now(timezone.utc).strftime("%Y-%m")
        site = self._site_info(month_key_probe)
        tz = ZoneInfo(site["timezone"])
        now_local = datetime.now(tz)
        today = now_local.date()
        month_key = today.strftime("%Y-%m")

        completed_due = (self.state.get("completed") or {}).get("for") != today.isoformat()
        ttl_min = POLL_DAY_MINUTES if DAY_START_HOUR <= now_local.hour < DAY_END_HOUR else POLL_NIGHT_MINUTES
        t = self.state.get("today") or {}
        today_due = t.get("date") != today.isoformat() or (time.time() - t.get("fetched_at", 0)) >= ttl_min * 60
        if not (completed_due or today_due):
            return

        windows = self._completed_windows(today, site, tz) if completed_due else {}
        needed = len(windows) + (1 if today_due else 0)
        with self.state_lock:
            used = self._credits(month_key)["used"]
        if used + needed > MONTHLY_CREDIT_LIMIT:
            if time.time() - self._last_guard_log > 3600:
                log.warning("Monthly credit guard: %d used + %d needed > limit %d. Not calling the API.",
                            used, needed, MONTHLY_CREDIT_LIMIT)
                self._last_guard_log = time.time()
            return f"Monthly credit guard reached ({used}/{MONTHLY_CREDIT_LIMIT}), not calling the API"

        if completed_due:
            end = local_midnight(today, tz)
            done = {"for": today.isoformat()}
            for name, start_date in windows.items():
                prod, cons = self._overview(month_key, local_midnight(start_date, tz), end)
                done[name] = {"production_wh": prod, "consumption_wh": cons or 0.0}
                log.info("Completed %s: production %.0f Wh, consumption %s",
                         name, prod, "n/a" if cons is None else f"{cons:.0f} Wh")
            # Windows that are empty today (e.g. 1st of the month) are zero.
            for name in ("week", "month", "year", "lifetime"):
                done.setdefault(name, {"production_wh": 0.0, "consumption_wh": 0.0})
            with self.state_lock:
                self.state["completed"] = done
            self._save_state()

        if today_due:
            prod, cons = self._overview(month_key, local_midnight(today, tz), datetime.now(tz))
            with self.state_lock:
                self.state["today"] = {
                    "date": today.isoformat(),
                    "production_wh": prod,
                    "consumption_wh": cons or 0.0,
                    "has_consumption": cons is not None,
                    "fetched_at": time.time(),
                }
            self._save_state()
            log.info("Today: production %.0f Wh, consumption %s (calls this month: %d)",
                     prod, "n/a" if cons is None else f"{cons:.0f} Wh", self.state["credits"]["used"])

    @staticmethod
    def _completed_windows(today, site, tz):
        """Start dates of the windows that end at midnight today. Empty ones are skipped."""
        windows = {"week": today - timedelta(days=6)}   # last 7 days including today
        if today.day > 1:
            windows["month"] = today.replace(day=1)
        if not (today.month == 1 and today.day == 1):
            windows["year"] = date(today.year, 1, 1)
        installed = parse_date(site.get("installed")) or date(2010, 1, 1)
        if installed < today:
            windows["lifetime"] = installed
        return windows

    # ---- what the HTTP endpoints serve -------------------------------------
    def snapshot(self):
        with self.state_lock:
            completed = copy.deepcopy(self.state.get("completed"))
            today = copy.deepcopy(self.state.get("today"))
            site = copy.deepcopy(self.state.get("site") or {})
        if not completed or not today:
            return None

        def total(name):
            c = completed.get(name, {})
            return {
                "production_wh": c.get("production_wh", 0.0) + today["production_wh"],
                "consumption_wh": c.get("consumption_wh", 0.0) + today["consumption_wh"],
            }

        tzname = site.get("timezone") or TIMEZONE_ENV or "UTC"
        try:
            local_today = datetime.now(ZoneInfo(tzname)).date().isoformat()
        except Exception:
            local_today = None
        age = time.time() - today["fetched_at"]
        stale = age > max(POLL_NIGHT_MINUTES, POLL_DAY_MINUTES) * 60 * 2.5 or today["date"] != local_today
        result = {
            "timezone": tzname,
            "timestamp": datetime.fromtimestamp(today["fetched_at"], timezone.utc).isoformat(),
            "data_age_seconds": int(age),
            "stale": bool(stale),
            "periods": {
                "day": {"production_wh": today["production_wh"], "consumption_wh": today["consumption_wh"]},
                "week": total("week"),
                "month": total("month"),
                "year": total("year"),
                "lifetime": total("lifetime"),
            },
        }
        if not today.get("has_consumption", True):
            result["warning"] = "SolarEdge reports no consumption data (no consumption meter?)"
        if self.auth_error:
            result["warning"] = f"Authorization needed: {self.auth_error}"
        return result

    def status(self):
        with self.state_lock:
            credits = copy.deepcopy(self.state.get("credits") or {})
            today = copy.deepcopy(self.state.get("today") or {})
            completed = copy.deepcopy(self.state.get("completed") or {})
        token = self.auth.token if self.auth else None
        return {
            "authorized": self.auth is not None and not self.auth_error,
            "auth_error": self.auth_error,
            "last_error": self.last_error,
            "site_id": SITE_ID_ENV or (token.site_id if token else None),
            "access_token_expires_at": (
                datetime.fromtimestamp(token.expires_at, timezone.utc).isoformat()
                if token and token.expires_at else None
            ),
            "credits_month": credits.get("month"),
            "credits_used": credits.get("used", 0),
            "credits_limit": MONTHLY_CREDIT_LIMIT,
            "today_fetched_at": (
                datetime.fromtimestamp(today["fetched_at"], timezone.utc).isoformat()
                if today.get("fetched_at") else None
            ),
            "completed_for": completed.get("for"),
        }

    def error_message(self):
        return self.auth_error or self.last_error or "No data yet, the first fetch is still running"


source = SolarEdgeSource()


def poller():
    log.info("Poller started (day %d min, night %d min, daylight %02d-%02d h, credit limit %d)",
             POLL_DAY_MINUTES, POLL_NIGHT_MINUTES, DAY_START_HOUR, DAY_END_HOUR, MONTHLY_CREDIT_LIMIT)
    while True:
        try:
            source.refresh_if_due()
        except Exception:  # never let the thread die
            log.exception("Unexpected error in poller")
        time.sleep(LOOP_SECONDS)


# --------------------------------------------------------------------------
# HTTP endpoints
# --------------------------------------------------------------------------
def authorized():
    supplied = request.headers.get("X-API-Key") or request.args.get("api_key") or ""
    return bool(PROXY_API_KEY) and hmac.compare_digest(supplied, PROXY_API_KEY)


@app.route("/health")
def health():
    return jsonify({"status": "healthy", "timestamp": datetime.now(timezone.utc).isoformat()})


@app.route("/api/solar")
def get_solar_data():
    if not authorized():
        return jsonify({"error": "Unauthorized"}), 401
    data = source.snapshot()
    if data is None:
        return jsonify({"error": source.error_message()}), 503
    return jsonify(data)


@app.route("/api/status")
@app.route("/api/token/status")
def get_status():
    if not authorized():
        return jsonify({"error": "Unauthorized"}), 401
    return jsonify(source.status())


# --------------------------------------------------------------------------
# One-off smoke test:  python app.py check      (uses about 4 API calls)
# --------------------------------------------------------------------------
def run_check():
    print("SolarEdge proxy check (uses about 4 API calls)\n")
    src = SolarEdgeSource()
    try:
        src._ensure_client()
        month_key = datetime.now(timezone.utc).strftime("%Y-%m")
        site = src._site_info(month_key)
    except NeedsAuth as exc:
        print("AUTH PROBLEM:", exc)
        return 1
    except SolarEdgeError as exc:
        print("API ERROR while reading site details:", exc)
        return 1
    tz = ZoneInfo(site["timezone"])
    now = datetime.now(tz)
    today = now.date()
    month_key = today.strftime("%Y-%m")
    print(f"Site {src._site_id()}  time zone {site['timezone']}  installed {site['installed']}")
    print(f"Local time now: {now:%Y-%m-%d %H:%M %Z}\n")

    try:
        t0 = local_midnight(today, tz)
        start3 = local_midnight(today - timedelta(days=3), tz)
        tp, tc = src._overview(month_key, t0, now)
        ap, ac = src._overview(month_key, start3, now)
        bp, bc = src._overview(month_key, start3, t0)
    except SolarEdgeError as exc:
        print("API ERROR:", exc)
        return 1

    def kwh(x):
        return "n/a" if x is None else f"{x / 1000:.2f} kWh"

    print(f"Today so far          production {kwh(tp)}   consumption {kwh(tc)}")
    print(f"Last 3 days + today   production {kwh(ap)}   consumption {kwh(ac)}")
    print(f"Last 3 full days      production {kwh(bp)}   consumption {kwh(bc)}")
    diff_p = ap - (bp + tp)
    print(f"\nConsistency (whole window minus the two parts): production {diff_p:+.0f} Wh", end="")
    if ac is not None and bc is not None and tc is not None:
        print(f", consumption {ac - (bc + tc):+.0f} Wh")
    else:
        print()
    if tc is None:
        print("NOTE: no consumption total returned. Check that the site has a consumption meter.")
    print("\nOK. Differences of a few Wh are normal; large ones mean the window boundaries need adjusting.")
    return 0


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "check":
        sys.exit(run_check())
    if not PROXY_API_KEY:
        sys.exit("PROXY_API_KEY must be set")
    threading.Thread(target=poller, daemon=True).start()
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 10001)))
else:
    # Imported by gunicorn: start the poller in the (single) worker process.
    if not PROXY_API_KEY:
        log.error("PROXY_API_KEY is not set: every request will be refused")
    if not os.environ.get("SOLAREDGE_PROXY_NO_POLLER"):
        threading.Thread(target=poller, daemon=True).start()
