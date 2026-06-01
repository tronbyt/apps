"""
Applet: OpenRouter Creds
Summary: Display remaining OpenRouter credits
Description: Shows remaining credits available on OpenRouter API.
Author: tavis
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

def round(num, precision):
    """Round a float to the specified number of significant digits"""
    return math.round(num * math.pow(10, precision)) / math.pow(10, precision)

def main(config):
    print("main called")
    api_key = config.get("api_key", "")
    text_color = config.str("text_color", "#0a0")
    warn_color = config.str("warn_color", "#D2691E")
    warn_threshold = float(config.get("warn_threshold", "1"))
    hide_threshold_str = config.get("hide_threshold", "20")
    hide_threshold = float(hide_threshold_str) if hide_threshold_str and hide_threshold_str != "" else None
    hide_if_unchanged_str = config.get("hide_if_unchanged", "30")
    hide_if_unchanged = int(hide_if_unchanged_str) if hide_if_unchanged_str and hide_if_unchanged_str != "" else 0
    print("config: warn_threshold=", warn_threshold, " hide_threshold=", hide_threshold, " hide_if_unchanged=", hide_if_unchanged)

    if api_key == "":
        print("no api_key configured")
        return render.Root(
            render.Text("Add API key", color = text_color),
        )

    headers = {"Authorization": "Bearer " + api_key}
    print("making request to OpenRouter credits API")
    resp = http.get("https://openrouter.ai/api/v1/credits", headers = headers)
    print("resp status: ", resp.status_code)
    if resp.status_code == 200:
        data = json.decode(resp.body())
        print("data: ", data)
        total = float(data["data"]["total_credits"])
        used = float(data["data"]["total_usage"])
        remaining = total - used
        print("total: ", total, " used: ", used, " remaining: ", remaining)

        if hide_threshold != None and remaining >= hide_threshold:
            print("above hide threshold, hiding")
            return []

        # Check cache for balance change detection
        if hide_if_unchanged > 0:
            cache_key = "openrouter_balance"
            cache_timestamp_key = "openrouter_balance_timestamp"

            cached_balance_str = cache.get(cache_key)
            cached_timestamp_str = cache.get(cache_timestamp_key)

            current_balance = round(remaining, 2)

            if cached_balance_str != None:
                cached_balance = float(cached_balance_str)
                print("cached_balance: ", cached_balance, " current_balance: ", current_balance)

                if cached_balance == current_balance and cached_timestamp_str != None:
                    # Balance hasn't changed, check how long it's been unchanged
                    cached_timestamp = int(cached_timestamp_str)
                    current_time = time.now().unix
                    elapsed_minutes = (current_time - cached_timestamp) / 60
                    print("balance unchanged for ", elapsed_minutes, " minutes")

                    if elapsed_minutes >= hide_if_unchanged:
                        print("balance unchanged for ", elapsed_minutes, " minutes, hiding")
                        return []
                else:
                    # Balance has changed, reset timestamp
                    print("balance changed, resetting timestamp")
                    cache.set(cache_key, str(current_balance), ttl_seconds = 86400)  # 24 hours
                    cache.set(cache_timestamp_key, str(time.now().unix), ttl_seconds = 86400)
            else:
                # First time, set cache
                print("setting initial cache")
                cache.set(cache_key, str(current_balance), ttl_seconds = 86400)
                cache.set(cache_timestamp_key, str(time.now().unix), ttl_seconds = 86400)

        val = round(remaining, 2)
        dollars = int(val)
        cents = int(round((val - dollars) * 100, 0))
        if cents == 100:
            dollars += 1
            cents = 0
        cents_str = "0" + str(cents) if cents < 10 else str(cents)
        display = "$" + str(dollars) + "." + cents_str

        # Determine color
        active_color = text_color if remaining > warn_threshold else warn_color
    else:
        print("API error: ", resp.status_code)
        display = "Error: %s" % resp.status_code
        active_color = text_color  # or warn, but probably normal for error

    return render.Root(
        child = render.Stack(
            children = [
                render.Box(
                    render.Column(
                        expanded = True,
                        main_align = "space_around",
                        children = [
                            render.Row(
                                expanded = True,
                                main_align = "center",
                                children = [
                                    render.WrappedText(
                                        content = "OpenRouter Credits",
                                        font = "tb-8",
                                        color = active_color,
                                    ),
                                ],
                            ),
                            render.Row(
                                expanded = True,
                                main_align = "center",
                                children = [
                                    render.Text(
                                        content = display,
                                        font = "6x13",
                                        color = active_color,
                                    ),
                                ],
                            ),
                        ],
                    ),
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "API Key",
                desc = "Your OpenRouter API key",
                icon = "key",
                secret = True,
            ),
            schema.Color(
                id = "text_color",
                name = "Text Color",
                desc = "Color for the text",
                icon = "brush",
                default = "#0a0",
            ),
            schema.Text(
                id = "warn_threshold",
                name = "Warning Threshold",
                desc = "Show warning color if credits below this value",
                icon = "user",
                default = "1",
            ),
            schema.Text(
                id = "hide_threshold",
                name = "Hide Threshold",
                desc = "Hide widget if credits above this value",
                default = "20",
                icon = "user",
            ),
            schema.Text(
                id = "hide_if_unchanged",
                name = "Hide if Unchanged (minutes)",
                desc = "Hide widget if balance hasn't changed for this many minutes (0 to disable)",
                default = "30",
                icon = "clock",
            ),
            schema.Color(
                id = "warn_color",
                name = "Warning Color",
                desc = "Color when credits are low",
                icon = "brush",
                default = "#D2691E",
            ),
        ],
    )
