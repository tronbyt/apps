"""Zabbix Problems for Tronbyt. Configure your own URL and read-only API token.

Copyright 2026 Silas Suessmilch. SPDX-License-Identifier: Apache-2.0
Requires Tronbyt Pixlet with canvas support. No external assets required.
"""

load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

COLORS = ["#97AAB3", "#7499FF", "#FFC859", "#FFA059", "#E97659", "#E45959"]
NAMES = ["None", "Info", "Warning", "Average", "High", "Disaster"]

def number(config, key, default, low, high):
    value = str(config.get(key, str(default)))
    if not value.isdigit():
        return default
    return max(low, min(high, int(value)))

def enabled(config, key, default = False):
    return str(config.get(key, str(default))).lower() in ["true", "1", "yes"]

def endpoint(value):
    value = value.strip().rstrip("/")
    if not value.startswith("https://"):
        return None

    # Accept a frontend base URL or the exact JSON-RPC endpoint.
    authority = value[8:].split("/")[0]
    if not authority or "@" in authority or "?" in value or "#" in value:
        return None
    if not value.endswith("/api_jsonrpc.php"):
        value += "/api_jsonrpc.php"
    return value

def rpc(url, token, method, params):
    response = http.post(
        url = url,
        headers = {"Authorization": "Bearer " + token, "Content-Type": "application/json-rpc"},
        json_body = {"jsonrpc": "2.0", "method": method, "params": params, "id": 1},
        ttl_seconds = 60,
    )
    if response.status_code in [401, 403]:
        return None, "Access denied"
    if response.status_code == 429:
        return None, "Rate limited"
    if response.status_code != 200:
        return None, "HTTP %s" % response.status_code
    if not response.body().lstrip().startswith("{"):
        return None, "Not JSON / SSO?"

    # Starlark cannot catch transport or JSON decoding exceptions. Pixlet
    # reports those as render failures; never translate them into zero problems.
    data = response.json()
    if type(data) != "dict":
        return None, "Invalid reply"
    if "error" in data:
        # Do not expose response bodies, credentials or private server details.
        return None, "API error / role?"
    if "result" not in data:
        return None, "Missing result"
    return data["result"], None

def filters(config):
    minimum = number(config, "min_severity", 2, 0, 5)
    params = {"source": 0, "object": 0, "recent": False, "severities": list(range(minimum, 6))}
    if not enabled(config, "include_suppressed"):
        params["suppressed"] = False
    if enabled(config, "unacknowledged_only"):
        params["acknowledged"] = False
    groups = config.get("groupids", "").strip()
    if groups:
        ids = [part.strip() for part in groups.split(",")]
        for groupid in ids:
            if not groupid.isdigit() or int(groupid) < 1:
                return None, "Invalid group IDs"
        params["groupids"] = ids
    return params, None

def fetch_problems(config, url, token):
    base, error = filters(config)
    if error:
        return None, 0, error
    count_params = dict(base)
    count_params["countOutput"] = True
    total, error = rpc(url, token, "problem.get", count_params)
    if error:
        return None, 0, error
    if not str(total).isdigit():
        return None, 0, "Invalid count"
    total = int(total)
    if total == 0:
        return [], 0, None

    maximum = number(config, "max_problems", 3, 1, 3)
    problems = []

    # Zabbix 7.0 problem.get only supports sorting by eventid, not severity.
    # Query severity buckets to avoid dropping older critical problems.
    for severity in range(5, min(base["severities"]) - 1, -1):
        params = dict(base)
        params.update({
            "severities": [severity],
            "output": ["eventid", "objectid", "name", "clock", "severity", "acknowledged"],
            "sortfield": ["eventid"],
            "sortorder": "DESC",
            "limit": maximum - len(problems),
        })
        rows, error = rpc(url, token, "problem.get", params)
        if error:
            return None, total, error
        if type(rows) != "list":
            return None, total, "Invalid problems"
        for row in rows:
            if type(row) != "dict" or "objectid" not in row or "name" not in row:
                return None, total, "Invalid problem"
            problems.append(row)
        if len(problems) >= maximum:
            break
    if not problems:
        return None, total, "State changed"

    triggers, error = rpc(url, token, "trigger.get", {
        "triggerids": list({p["objectid"]: True for p in problems}.keys()),
        "output": ["triggerid"],
        "selectHosts": ["hostid", "name", "host"],
    })
    if error:
        return None, total, error
    if type(triggers) != "list":
        return None, total, "Invalid hosts"
    names = {}
    for trigger in triggers:
        names[trigger["triggerid"]] = ", ".join([h.get("name") or h.get("host", "?") for h in trigger.get("hosts", [])])
    for problem in problems:
        problem["host"] = names.get(problem["objectid"]) or "Host unavailable"
    return problems, total, None

def age(clock, now):
    seconds = max(0, now - int(clock))
    if seconds >= 86400:
        return "%dd" % (seconds // 86400)
    if seconds >= 3600:
        return "%dh" % (seconds // 3600)
    return "%dm" % (seconds // 60)

def shorten(text, length):
    text = " ".join(str(text).split())
    return text if len(text) <= length else text[:length - 3] + "..."

def text(value, color = "#FFFFFF"):
    font = "tb-8" if canvas.is2x() else "tom-thumb"
    return render.Text(content = value, font = font, color = color)

def panel(title, host, message, footer, color):
    big = canvas.is2x()
    width = canvas.width()

    # The 1x layout uses four bands: 6 + 6 + 12 + 6 = 30 pixels.
    # The 2x layout uses 10 + 10 + 28 + 10 = 58 pixels.
    return render.Box(width = width, height = canvas.height(), color = "#000000", child = render.Padding(
        pad = (2, 1, 2, 1),
        child = render.Column(cross_align = "start", children = [
            text(shorten(title, 20 if big else 15), color),
            text(shorten(host, 20 if big else 15), "#C5D8E8"),
            render.WrappedText(
                content = shorten(message, 60 if big else 30),
                width = width - 4,
                height = 28 if big else 12,
                font = "tb-8" if big else "tom-thumb",
                color = "#FFFFFF",
                wordbreak = True,
            ),
            text(shorten(footer, 20 if big else 15), color),
        ]),
    ))

def status(message, color):
    return render.Root(child = panel("ZABBIX", "", message, "", color), max_age = 180)

def main(config):
    now = int(time.now().unix)
    demo = enabled(config, "demo")
    if demo:
        problems = [
            {"host": "pve-01", "name": "Storage space below 10 percent", "severity": "4", "clock": str(now - 7200), "acknowledged": "0"},
            {"host": "backup-01", "name": "Backup job failed", "severity": "3", "clock": str(now - 2400), "acknowledged": "1"},
            {"host": "switch-01", "name": "Packet loss above threshold", "severity": "2", "clock": str(now - 900), "acknowledged": "0"},
        ][:number(config, "max_problems", 3, 1, 3)]
        total = 3
    else:
        url = endpoint(config.get("url", ""))
        token = config.get("token", "").strip()
        if not url or not token:
            return status("Set HTTPS URL and API token", "#FFC859")
        problems, total, error = fetch_problems(config, url, token)
        if error:
            return status(error, "#E45959")
        if not problems:
            return status("No matching problems", "#59D98E")

    pages = []
    for i, problem in enumerate(problems):
        severity = max(0, min(5, int(problem.get("severity", "0"))))
        header = "DEMO ZABBIX" if demo else "ZABBIX %s" % total
        footer = "%s %s %s/%s" % (NAMES[severity][:4], age(problem.get("clock", now), now), i + 1, len(problems))
        if problem.get("acknowledged") == "1":
            footer += " A"
        page = panel(header, problem["host"], problem["name"], footer, COLORS[severity])

        # Each page stays 4 seconds; maximum three pages keeps output under
        # Pixlet's default 15-second animation duration.
        pages.extend([page] * 4)
    return render.Root(child = render.Animation(children = pages), delay = 1000, max_age = 180)

def get_schema():
    return schema.Schema(version = "1", fields = [
        schema.Text(id = "url", name = "Zabbix URL", desc = "HTTPS frontend URL or full /api_jsonrpc.php endpoint.", icon = "link"),
        schema.Text(id = "token", name = "API token", desc = "Token for a user with read access to the desired hosts and permission for problem.get and trigger.get.", icon = "key", secret = True),
        schema.Dropdown(id = "min_severity", name = "Minimum severity", desc = "Include this severity and higher.", icon = "filter", default = "2", options = [
            schema.Option(display = "Not classified", value = "0"),
            schema.Option(display = "Information", value = "1"),
            schema.Option(display = "Warning", value = "2"),
            schema.Option(display = "Average", value = "3"),
            schema.Option(display = "High", value = "4"),
            schema.Option(display = "Disaster", value = "5"),
        ]),
        schema.Text(id = "groupids", name = "Host group IDs", desc = "Optional comma-separated numeric IDs. Empty means all groups visible to the token.", icon = "server"),
        schema.Toggle(id = "unacknowledged_only", name = "Unacknowledged only", desc = "Hide acknowledged problems.", icon = "check", default = False),
        schema.Toggle(id = "include_suppressed", name = "Include suppressed", desc = "Include problems suppressed manually or by maintenance.", icon = "eye", default = False),
        schema.Dropdown(id = "max_problems", name = "Problems per cycle", desc = "Highest severity first, newest first within each severity. Four seconds per problem.", icon = "list", default = "3", options = [
            schema.Option(display = "1", value = "1"),
            schema.Option(display = "2", value = "2"),
            schema.Option(display = "3", value = "3"),
        ]),
        schema.Toggle(id = "demo", name = "Demo mode", desc = "Show fictional sample problems without network requests. Disable for live monitoring.", icon = "display", default = False),
    ])
