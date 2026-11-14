load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("time.star", "time")

def fetch_server_name(server_id):
    url = "https://api.battlemetrics.com/servers/" + server_id
    res = http.get(url, ttl_seconds = 600)
    if res.status_code != 200:
        return None
    body = json.decode(res.body())
    name = body["data"]["attributes"]["name"]
    cache.set("bm_history_name_" + server_id, name, ttl_seconds = 3600)
    return name

def fetch_24h_history(server_id):
    # 30-minute resolution over a 24h window = 48 points.
    # Use UTC so the formatted timestamp's 'Z' is truthful.
    now = time.now().in_location("UTC")

    # Floor to nearest 30-min boundary (e.g. 23:50 → 23:30)
    offset = time.parse_duration(str(now.unix % 1800) + "s")
    stop = now - offset
    start = stop - time.parse_duration("24h")
    stop = stop.format("2006-01-02T15:04:05") + "Z"
    start = start.format("2006-01-02T15:04:05") + "Z"
    url = (
        "https://api.battlemetrics.com/servers/" + server_id +
        "/player-count-history?start=" + start +
        "&stop=" + stop +
        "&resolution=30"
    )
    res = http.get(url, ttl_seconds = 1800)
    if res.status_code != 200:
        return None
    body = json.decode(res.body())
    data = body["data"]
    cache.set("bm_history_" + server_id, json.encode(data), ttl_seconds = 1800)
    return data
