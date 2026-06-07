load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

API_BASE = "https://rt.ambientweather.net/v1"
LABEL_W = 28
CHART_W = 36
ROW_H = 8

TEMP_COLOR = "#FF6B35"
TEMP_FILL = "#3D1800"
HUMID_COLOR = "#4FC3F7"
HUMID_FILL = "#003D5C"
DEW_COLOR = "#A8D8A8"
DEW_FILL = "#1A3D1A"
RAIN_COLOR = "#90CAF9"

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "API Key",
                desc = "Your Ambient Weather API key (ambientweather.net/account)",
                icon = "key",
                default = "",
            ),
            schema.Text(
                id = "app_key",
                name = "Application Key",
                desc = "Your Ambient Weather application key",
                icon = "key",
                default = "",
            ),
            schema.Text(
                id = "mac_address",
                name = "Device MAC Address",
                desc = "MAC address of your weather station (leave blank to use first device)",
                icon = "wifi",
                default = "",
            ),
        ],
    )

def smooth(data, window):
    n = len(data)
    if n < window:
        return data
    half = window // 2
    result = []
    for i in range(n):
        start = i - half
        end = i + half + 1
        if start < 0:
            start = 0
        if end > n:
            end = n
        total = 0.0
        for j in range(start, end):
            total += data[j][1]
        result.append((data[i][0], total / (end - start)))
    return result

def build_plot_data(records, field):
    vals = []
    for r in records:
        v = r.get(field)
        if v != None:
            vals.append(v)
    n = len(vals)
    data = []
    for i in range(n):
        data.append((i, vals[n - 1 - i]))
    return data

def make_sparkline(data, color, fill_color):
    if len(data) < 2:
        return render.Box(width = CHART_W, height = ROW_H)
    y_vals = [pt[1] for pt in data]
    y_min = y_vals[0]
    y_max = y_vals[0]
    for v in y_vals:
        if v < y_min:
            y_min = v
        if v > y_max:
            y_max = v
    margin = (y_max - y_min) * 0.1
    if margin == 0:
        margin = 1.0
    return render.Plot(
        data = data,
        width = CHART_W,
        height = ROW_H,
        color = color,
        fill_color = fill_color,
        fill = True,
        x_lim = (0, len(data) - 1),
        y_lim = (y_min - margin, y_max + margin),
    )

def spark_row(value_str, color, sparkline):
    return render.Row(
        children = [
            render.Box(width = LABEL_W, height = ROW_H, child = render.Text(content = value_str, color = color, font = "tb-8")),
            sparkline,
        ],
    )

def fmt_temp(val, prefix):
    return "%s%d°F" % (prefix, int(val + 0.5))

def fmt_humid(val):
    return "H:%d%%" % int(val + 0.5)

def fmt_rain(val):
    rounded = int(val * 100 + 0.5)
    whole = rounded // 100
    frac = rounded % 100
    frac_str = str(frac)
    if len(frac_str) < 2:
        frac_str = "0" + frac_str
    return "%d.%s\"" % (whole, frac_str)

def main(config):
    api_key = config.get("api_key") or ""
    app_key = config.get("app_key") or ""
    mac = (config.get("mac_address") or "").strip()

    if not api_key or not app_key:
        return error_screen("no API keys")

    auth = "apiKey=%s&applicationKey=%s" % (api_key, app_key)

    if not mac:
        rep = http.get("%s/devices?%s" % (API_BASE, auth), ttl_seconds = 300)
        if rep.status_code != 200:
            return error_screen("HTTP %d" % rep.status_code)
        devices = rep.json()
        if not devices:
            return error_screen("no device")
        mac = (devices[0].get("macAddress") or "").strip()
        if not mac:
            return error_screen("no MAC")

    rep = http.get(
        "%s/devices/%s?%s&limit=288" % (API_BASE, mac, auth),
        ttl_seconds = 300,
    )
    if rep.status_code != 200:
        return error_screen("HTTP %d" % rep.status_code)

    records = rep.json()
    if not records:
        return error_screen("no data")

    latest = records[0]
    temp = latest.get("tempf") or 0.0
    humidity = latest.get("humidity") or 0.0
    dew = latest.get("dewPoint") or 0.0
    rain_today = latest.get("dailyrainin") or 0.0
    rain_rate = latest.get("rainratein") or 0.0

    temp_plot = make_sparkline(smooth(build_plot_data(records, "tempf"), 9), TEMP_COLOR, TEMP_FILL)
    humid_plot = make_sparkline(smooth(build_plot_data(records, "humidity"), 9), HUMID_COLOR, HUMID_FILL)
    dew_plot = make_sparkline(smooth(build_plot_data(records, "dewPoint"), 9), DEW_COLOR, DEW_FILL)

    rain_row = render.Row(
        expanded = True,
        main_align = "space_between",
        cross_align = "center",
        children = [
            render.Text(content = fmt_rain(rain_today), color = RAIN_COLOR, font = "tb-8"),
            render.Text(content = "%s/h" % fmt_rain(rain_rate), color = RAIN_COLOR, font = "tb-8"),
        ],
    )

    return render.Root(
        child = render.Column(
            children = [
                spark_row(fmt_temp(temp, "T:"), TEMP_COLOR, temp_plot),
                spark_row(fmt_humid(humidity), HUMID_COLOR, humid_plot),
                spark_row(fmt_temp(dew, "D:"), DEW_COLOR, dew_plot),
                rain_row,
            ],
        ),
    )

def error_screen(msg):
    return render.Root(
        child = render.Column(
            children = [
                render.Text(content = "wx", color = "#FFFFFF", font = "tb-8"),
                render.Text(content = "error", color = "#FF4444", font = "tb-8"),
                render.Text(content = msg, color = "#888888", font = "tb-8"),
            ],
        ),
    )
