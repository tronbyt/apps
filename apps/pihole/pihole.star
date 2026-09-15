"""
Applet: PiHole
Summary: PiHole stats for Tidbyt
Description: Display Pi-hole blocking statistics on Tidbyt.
Author: siva801
"""

load("http.star", "http")
load("humanize.star", "humanize")
load("images/pihole_logo.png", PIHOLE_LOGO_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

PIHOLE_LOGO = PIHOLE_LOGO_ASSET.readall()

HOST = ""
API_KEY = ""
VERSION = "v5"
GREEN = "#00cc00"
RED = "#ff4136"

TTL_SECONDS = 60

version_options = [
    schema.Option(
        display = "V5",
        value = "v5",
    ),
    schema.Option(
        display = "V6",
        value = "v6",
    ),
]

def get_pihole_stats(endpoint, api_key, ttl):
    resp = http.get("%s/admin/api.php" % endpoint, params = {"summaryRaw": "", "auth": api_key}, ttl_seconds = ttl)
    if resp.status_code != 200:
        print("PiHole request failed with status %d", resp.status_code)
        summary = None
    else:
        summary = resp.json()

    resp = http.get("%s/admin/api.php" % endpoint, params = {"overTimeData10mins": "", "auth": api_key}, ttl_seconds = ttl)
    if resp.status_code != 200:
        print("PiHole request failed with status %d", resp.status_code)
        plot_data = None
    else:
        plot_data = resp.json()
    return summary, plot_data

def get_pihole_v6_stats(endpoint, api_key, ttl):
    resp = http.post("%s/api/auth" % endpoint, json_body = {"password": api_key}, ttl_seconds = ttl)
    if resp.status_code != 200:
        print("PiHole request failed with status %d", resp.status_code)
    sid = resp.json()["session"]["sid"]

    resp = http.get("%s/api/stats/summary" % endpoint, params = {"sid": sid}, ttl_seconds = ttl)
    if resp.status_code != 200:
        print("PiHole request failed with status %d", resp.status_code)
        summary = None
    else:
        summary = resp.json()

    resp = http.get("%s/api/history" % endpoint, params = {"sid": sid}, ttl_seconds = ttl)
    if resp.status_code != 200:
        print("PiHole request failed with status %d", resp.status_code)
        plot_data = None
    else:
        plot_data = resp.json()
    return summary, plot_data

def main(config):
    host = config.str("host", HOST)
    api_key = config.str("api_key", API_KEY)
    version = config.str("version", VERSION)
    ttl = int(config.get("ttl", TTL_SECONDS))

    total_queries = 0
    total_ads = 0
    query_plot = []
    ad_plot = []

    if config.str("host", HOST) == "" or config.str("api_key", API_KEY) == "":
        return render.Root(
            render.Column(
                expanded = True,
                main_align = "space_between",
                children = [
                    render.Padding(
                        pad = (2, 1, 1, 0),
                        child = render.Row(
                            expanded = True,
                            main_align = "space_between",
                            children = [
                                render.Column(
                                    children = [
                                        render.Image(PIHOLE_LOGO, width = 10),
                                    ],
                                ),
                                render.Column(
                                    cross_align = "end",
                                    children = [
                                        render.Text("Add Host", color = RED),
                                        render.Text("Add Key", color = RED),
                                    ],
                                ),
                            ],
                        ),
                    ),
                ],
            ),
        )

    else:
        if not host.startswith("http"):
            host = "http://" + host
        summary, plot_data = get_pihole_stats(host, api_key, ttl) if version == "v5" else get_pihole_v6_stats(host, api_key, ttl)

        if not summary or not plot_data:
            return render.Root(
                render.Column(
                    expanded = True,
                    main_align = "space_around",
                    children = [
                        render.Marquee(
                            width = 64,
                            child = render.Text("Error! Check APP config.", color = RED),
                        ),
                    ],
                ),
            )

        total_queries = summary["dns_queries_today"] if version == "v5" else summary["queries"]["total"]
        total_ads = summary["ads_blocked_today"] if version == "v5" else summary["queries"]["blocked"]
        ads_percentage = summary["ads_percentage_today"] if version == "v5" else summary["queries"]["percent_blocked"]

        if version == "v5":
            query_plot_time_buckets = sorted(plot_data["domains_over_time"].keys())
            for idx, time_bucket in enumerate(query_plot_time_buckets):
                if idx >= len(query_plot):
                    query_plot.append(plot_data["domains_over_time"][time_bucket])
                else:
                    query_plot[idx] = plot_data["domains_over_time"][time_bucket]
            ad_plot_time_buckets = sorted(plot_data["ads_over_time"].keys())
            for idx, time_bucket in enumerate(ad_plot_time_buckets):
                if idx >= len(ad_plot):
                    ad_plot.append(plot_data["ads_over_time"][time_bucket])
                else:
                    ad_plot[idx] = plot_data["ads_over_time"][time_bucket]
        else:
            query_plot = [x["total"] for x in plot_data["history"]]
            ad_plot = [x["blocked"] for x in plot_data["history"]]

        return render.Root(
            render.Column(
                expanded = True,
                main_align = "space_between",
                children = [
                    render.Padding(
                        pad = (2, 1, 1, 0),
                        child = render.Row(
                            expanded = True,
                            main_align = "space_between",
                            children = [
                                render.Column(
                                    children = [
                                        render.Image(PIHOLE_LOGO, width = 10),
                                    ],
                                ),
                                render.Column(
                                    cross_align = "end",
                                    children = [
                                        render.Text(humanize.comma(int(total_queries))),
                                        render.Row(
                                            children = [
                                                render.Text(humanize.comma(int(total_ads)), color = RED),
                                                render.Text(" (" + humanize.ftoa(ads_percentage, 0) + "%)", color = RED),
                                            ],
                                        ),
                                    ],
                                ),
                            ],
                        ),
                    ),
                    render.Row(
                        expanded = True,
                        children = [
                            render.Stack(
                                children = [
                                    render.Plot(
                                        data = list(enumerate(query_plot)),
                                        width = 64,
                                        height = 14,
                                        color = GREEN,
                                        fill = True,
                                        y_lim = (0, max(query_plot)),
                                    ),
                                    render.Plot(
                                        data = list(enumerate(ad_plot)),
                                        width = 64,
                                        height = 14,
                                        color = RED,
                                        fill = True,
                                        fill_color = "#660500",
                                        y_lim = (0, max(ad_plot)),
                                    ),
                                ],
                            ),
                        ],
                    ),
                ],
            ),
        )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "host",
                name = "Host",
                desc = "Pi-hole Host name/ip[:port]",
                icon = "computer",
            ),
            schema.Text(
                id = "api_key",
                name = "API Key",
                desc = "Pi-hole API Key",
                icon = "key",
                secret = True,
            ),
            schema.Dropdown(
                id = "version",
                name = "Version",
                desc = "Pi-hole Version",
                icon = "v",
                default = version_options[0].value,
                options = version_options,
            ),
            schema.Text(
                id = "ttl",
                name = "ttl",
                desc = "TTL For http cache",
                icon = "v",
                default = "60",
            ),
        ],
    )
