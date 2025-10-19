"""
Enphase API Proxy Service for Tidbyt
Handles OAuth token refresh and provides simple endpoint for Tidbyt app

Note: Today's consumption is not available via Enphase public API.
"""

from flask import Flask, jsonify, request
import requests
import os
from datetime import datetime, timedelta
from functools import wraps
import time

app = Flask(__name__)

token_store = {"access_token": None, "refresh_token": None, "expires_at": None}

# Cache storage
cache_store = {
    "hourly_data": None,  # Frequently updated data (summary + today's production)
    "hourly_timestamp": None,
    "daily_data": None,   # Lifetime data (updated once per day)
    "daily_timestamp": None,
}

# Hourly cache for summary (includes today's production)
HOURLY_CACHE = 3600  # 1 hour

# Daily cache for lifetime data (doesn't change much)
DAILY_CACHE = 86400  # 24 hours

ENPHASE_API_BASE = "https://api.enphaseenergy.com/api/v4"
ENPHASE_AUTH_URL = "https://api.enphaseenergy.com/oauth/token"

API_KEY = os.environ.get("ENPHASE_API_KEY")
CLIENT_ID = os.environ.get("ENPHASE_CLIENT_ID")
CLIENT_SECRET = os.environ.get("ENPHASE_CLIENT_SECRET")
SYSTEM_ID = os.environ.get("ENPHASE_SYSTEM_ID")
PROXY_API_KEY = os.environ.get("PROXY_API_KEY", "your-secret-key-here")

if not token_store["access_token"]:
    token_store["access_token"] = os.environ.get("ENPHASE_ACCESS_TOKEN")
    token_store["refresh_token"] = os.environ.get("ENPHASE_REFRESH_TOKEN")
    if token_store["access_token"]:
        token_store["expires_at"] = datetime.now() + timedelta(hours=1)


def refresh_access_token():
    if not token_store["refresh_token"]:
        raise Exception("No refresh token available")
    
    data = {"grant_type": "refresh_token", "refresh_token": token_store["refresh_token"]}
    auth = (CLIENT_ID, CLIENT_SECRET)
    response = requests.post(ENPHASE_AUTH_URL, data=data, auth=auth)
    
    if response.status_code == 200:
        token_data = response.json()
        token_store["access_token"] = token_data["access_token"]
        token_store["refresh_token"] = token_data.get("refresh_token", token_store["refresh_token"])
        token_store["expires_at"] = datetime.now() + timedelta(seconds=token_data.get("expires_in", 3600))
        return token_store["access_token"]
    else:
        raise Exception(f"Token refresh failed: {response.status_code}")


def get_valid_access_token():
    if token_store["access_token"] and token_store["expires_at"]:
        if datetime.now() + timedelta(minutes=5) < token_store["expires_at"]:
            return token_store["access_token"]
    return refresh_access_token()


def call_enphase_api(endpoint, params=None):
    access_token = get_valid_access_token()
    headers = {"Authorization": f"Bearer {access_token}", "key": API_KEY}
    url = f"{ENPHASE_API_BASE}/{endpoint}"
    response = requests.get(url, headers=headers, params=params)
    
    if response.status_code == 401:
        access_token = refresh_access_token()
        headers["Authorization"] = f"Bearer {access_token}"
        response = requests.get(url, headers=headers, params=params)
    
    response.raise_for_status()
    return response.json()


@app.route("/health")
def health():
    return jsonify({"status": "healthy", "timestamp": datetime.now().isoformat()})


@app.route("/api/solar")
def get_solar_data():
    auth_key = request.headers.get("X-API-Key") or request.args.get("api_key")
    if auth_key != PROXY_API_KEY:
        return jsonify({"error": "Unauthorized"}), 401
    
    try:
        now = datetime.utcnow()
        today = datetime(now.year, now.month, now.day)
        month_start = datetime(now.year, now.month, 1)
        year_start = datetime(now.year, 1, 1)
        week_start = today - timedelta(days=6)
        
        # STEP 1: Get summary data (refreshed hourly) - 1 API call
        hourly_age = time.time() - cache_store["hourly_timestamp"] if cache_store["hourly_timestamp"] else float('inf')
        
        if hourly_age < HOURLY_CACHE and cache_store["hourly_data"]:
            print(f"Using cached summary (age: {int(hourly_age)}s)")
            summary = cache_store["hourly_data"]["summary"]
            day_prod = cache_store["hourly_data"]["day_prod"]
        else:
            print("Fetching fresh summary data...")
            summary = call_enphase_api(f"systems/{SYSTEM_ID}/summary")
            day_prod = summary.get("energy_today", 0)
            
            cache_store["hourly_data"] = {
                "summary": summary,
                "day_prod": day_prod
            }
            cache_store["hourly_timestamp"] = time.time()
        
        timezone = summary.get("timezone", "America/New_York")
        
        # STEP 2: Get lifetime data (refreshed daily) - 2 API calls per day
        daily_age = time.time() - cache_store["daily_timestamp"] if cache_store["daily_timestamp"] else float('inf')
        
        if daily_age < DAILY_CACHE and cache_store["daily_data"]:
            print(f"Using cached lifetime data (age: {int(daily_age/3600)}h)")
            prod_data = cache_store["daily_data"]["production"]
            cons_data = cache_store["daily_data"]["consumption"]
            start_date = cache_store["daily_data"]["prod_start_date"]
            cons_start_date = cache_store["daily_data"]["cons_start_date"]
        else:
            print("Fetching fresh lifetime data...")
            prod_data_raw = call_enphase_api(f"systems/{SYSTEM_ID}/energy_lifetime")
            cons_data_raw = call_enphase_api(f"systems/{SYSTEM_ID}/consumption_lifetime")
            
            prod_data = prod_data_raw.get("production", [])
            start_date = datetime.strptime(prod_data_raw["start_date"], "%Y-%m-%d")
            
            cons_data = cons_data_raw.get("consumption", [])
            cons_start_date = datetime.strptime(cons_data_raw["start_date"], "%Y-%m-%d")
            
            cache_store["daily_data"] = {
                "production": prod_data,
                "consumption": cons_data,
                "prod_start_date": start_date,
                "cons_start_date": cons_start_date
            }
            cache_store["daily_timestamp"] = time.time()
        
        # STEP 3: Calculate periods from cached lifetime data
        month_prod = sum(v for i, v in enumerate(prod_data) if v and month_start <= (start_date + timedelta(days=i)) < today)
        year_prod = sum(v for i, v in enumerate(prod_data) if v and year_start <= (start_date + timedelta(days=i)) < today)
        week_prod = sum(v for i, v in enumerate(prod_data) if v and week_start <= (start_date + timedelta(days=i)) < today)
        lifetime_prod = sum(v for v in prod_data if v)
        
        # Add today's production
        month_prod += day_prod
        year_prod += day_prod
        week_prod += day_prod
        lifetime_prod += day_prod
        
        # Calculate consumption periods
        day_cons = 0
        month_cons = sum(v for i, v in enumerate(cons_data) if v and month_start <= (cons_start_date + timedelta(days=i)) < today)
        year_cons = sum(v for i, v in enumerate(cons_data) if v and year_start <= (cons_start_date + timedelta(days=i)) < today)
        week_cons = sum(v for i, v in enumerate(cons_data) if v and week_start <= (cons_start_date + timedelta(days=i)) < today)
        lifetime_cons = sum(v for v in cons_data if v)
        
        result = {
            "timezone": timezone,
            "timestamp": now.isoformat(),
            "periods": {
                "day": {"production_wh": day_prod, "consumption_wh": day_cons},
                "week": {"production_wh": week_prod, "consumption_wh": week_cons},
                "month": {"production_wh": month_prod, "consumption_wh": month_cons},
                "year": {"production_wh": year_prod, "consumption_wh": year_cons},
                "lifetime": {"production_wh": lifetime_prod, "consumption_wh": lifetime_cons}
            }
        }
        
        response = jsonify(result)
        response.headers['Cache-Control'] = f'public, max-age={HOURLY_CACHE}'
        return response
    
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/api/token/status")
def token_status():
    auth_key = request.headers.get("X-API-Key") or request.args.get("api_key")
    if auth_key != PROXY_API_KEY:
        return jsonify({"error": "Unauthorized"}), 401
    
    return jsonify({
        "has_tokens": token_store["access_token"] is not None,
        "expires_at": token_store["expires_at"].isoformat() if token_store["expires_at"] else None,
    })


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 10000))
    app.run(host="0.0.0.0", port=port)
