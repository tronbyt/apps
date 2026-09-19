load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")

def fetch_icon(url):
    if url == None:
        return None
    res = http.get(url, ttl_seconds = 86400)
    if res.status_code != 200:
        return None
    return res.body()

def fetch_server_data(server_id):
    url = "https://api.battlemetrics.com/servers/" + server_id
    res = http.get(url, ttl_seconds = 600)
    if res.status_code != 200:
        return None

    body = json.decode(res.body())
    data = body["data"]
    attrs = data["attributes"]
    game_id = data["relationships"]["game"]["data"]["id"]

    result = {
        "name": attrs["name"],
        "players": attrs["players"],
        "max_players": attrs["maxPlayers"],
        "status": attrs["status"],
        "game_id": game_id,
        "details": attrs["details"],
    }

    fallback = json.encode({"name": result["name"], "game_id": game_id})
    cache.set("bm_fallback_" + server_id, fallback, ttl_seconds = 3600)

    return result
