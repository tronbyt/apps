"""
Applet: Order Moments
Summary: Celebrate major moments
Description: Get celebratory notifications when you hit specific order milestones.
Author: Shopify
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("hash.star", "hash")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/alien_error.gif", ALIEN_ERROR_ASSET = "file")
load("images/celebrate_fireworks.gif", CELEBRATE_FIREWORKS_ASSET = "file")
load("images/starfield.gif", STARFIELD_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

ALIEN_ERROR = ALIEN_ERROR_ASSET.readall()
CELEBRATE_FIREWORKS = CELEBRATE_FIREWORKS_ASSET.readall()
STARFIELD = STARFIELD_ASSET.readall()

# Messages
ERROR_TEXT = "We hit a snag. Please check your app."

# Endpoints
REST_ENDPOINT = "https://{}.myshopify.com/admin/api/2022-10/{}.json"
COUNT_ENDPOINT = "orders/count"

# Metafield definitions
METAFIELD_ENDPOINT = "metafields"
METAFIELD_UPDATE_ENDPOINT = "metafields/{}"
METAFIELD_DESCRIPTION = "A number of sales last celebrated by this store's TidByt Display"
METAFIELD_NAMESPACE = "tidbyt"
METAFIELD_KEY = "lastcelebration"
METAFIELD_OWNER = "shop"

# Cache definitions
CACHE_TTL = 600
CACHE_ID_ORDERS = "{}-{}-orders"
CACHE_ID_METAFIELD = "{}-{}-metafields"

# Milestone definitions are a list of Tuples where the first element is a base number of sales
# and the second element is an increment at which celebrations happen after that base.
MILESTONE_DEFINITIONS = [
    (0, 10),
    (100, 25),
    (500, 50),
    (1000, 100),
    (2000, 250),
    (5000, 500),
    (10000, 1000),
    (100000, 5000),
    (500000, 10000),
    (1000000, 100000),
]

# MAIN
# ----
def main(config):
    store_name = config.get("store_name")
    api_token = config.get("api_token")

    # If applet isn't configured, say so
    if not store_name or not api_token:
        print("Error ❌: Missing store name (%s) or API token (%s)" % (store_name, api_token))
        return error_view(ERROR_TEXT)

    # Get our current order count, and if it failed skip rendering
    order_count = get_order_count(store_name, api_token)
    if order_count < 0:
        return []

    # Get our latest celebration, and if it failed skip rendering
    celebration = get_latest_celebration(store_name, api_token)
    if celebration.get("error"):
        return []

    # Get our latest milestone based on our orders and update
    # our celebration if we passed a new one
    milestone = get_milestone(order_count)
    if milestone > celebration["orders"]:
        new_celebration = {
            "orders": milestone,
        }
        if celebration.get("id"):
            new_celebration["id"] = celebration["id"]
        store_latest_celebration(new_celebration, store_name, api_token)
        celebration = new_celebration

    if should_celebrate(celebration):
        print("Celebrating.")
        return render.Root(
            render.Stack(
                children = [
                    render.Image(CELEBRATE_FIREWORKS),
                    render.Box(
                        render.Column(
                            cross_align = "center",
                            children = [
                                render.Text(get_formatted_number(milestone)),
                                render.Text("orders!"),
                            ],
                        ),
                    ),
                ],
            ),
        )

    # There's nothing to celebrate today, so skip rendering.
    print("Skipping celebration.")
    return []

# GET FORMATTED NUMBER
# Takes a milestone number and formats it in a friendly way
# -----------------------------------------------------------------------------------------
# milestone: A number to be formatted
# Returns: A string representing a friendly formatted number
def get_formatted_number(number):
    if number % 1000000000 == 0:
        return "%sB" % humanize.comma(number // 1000000000)
    elif number % 1000000 == 0:
        return "%sM" % humanize.comma(number // 1000000)
    elif number % 1000 == 0:
        return "%sk" % humanize.comma(number // 1000)
    else:
        return humanize.comma(number)

# GET MILESTONE
# Returns a milestone based on our milestone definitions for a provided order count
# -----------------------------------------------------------------------------------------
# Returns: a number representing the most applicable milestone for a number of orders.
def get_milestone(order_count):
    previous = MILESTONE_DEFINITIONS[0]
    for base, step in MILESTONE_DEFINITIONS:
        if order_count > base:
            previous = (base, step)
            continue

        return ((order_count - previous[0]) // previous[1]) * previous[1] + previous[0]

    # Should never get here.
    return 0

# SHOULD CELEBRATE
# Returns whether or not we should celebrate now, given the previous celebration milestone
# -----------------------------------------------------------------------------------------
# last_celebration: A dict with data from the last celebration
# orders: A number of current orders
def should_celebrate(last_celebration):
    # If we don't have a date for our last celebration, we know it's new
    if last_celebration.get("date") == None:
        return True

    now = time.now().in_location("utc")
    lcd = last_celebration["date"]
    day_of_week = lcd.format("Mon")
    time_since = now - lcd

    print("Last celebrated %d orders on %s (%s, %d hours ago - currently %s)" % (last_celebration["orders"], lcd, day_of_week, time_since.hours, now))

    # We want to celebrate for 24 hours of weekday time. So:
    # - If the order milestone happened on a Friday, add 48 hours to the
    #   celebration time.
    # - If the order milestone happened on a Saturday or Sunday, celebrate
    #   until the end of the day on Monday.
    additional_time = 0
    if day_of_week == "Fri":
        additional_time = 48
    elif day_of_week[0] == "S":
        if day_of_week == "Sat":
            additional_time = (time.time(year = lcd.year, month = lcd.month, day = lcd.day + 1, hour = 23, minute = 59) - lcd).hours
        else:
            additional_time = (time.time(year = lcd.year, month = lcd.month, day = lcd.day, hour = 23, minute = 59) - lcd).hours

    # We celebrate if the time since the last milestone is less than the celebration duration
    return time_since.hours < (24 + additional_time)

# GET LATEST CELEBRATION
# Retrieves remote data representing our latest celebration from a shop metafield.
# -----------------------------------------------------------------------------------------
# store_name: A name of a Shopify store for the API call
# api_token: A Shopify API token
# Returns: A dict with id, date, and orders keys, or a dict with an error key if failed
def get_latest_celebration(store_name, api_token):
    # Check our cache
    cache_key = CACHE_ID_METAFIELD.format(hash.sha1(store_name), hash.sha1(api_token))
    cached_metafields = cache.get(cache_key)

    if not cached_metafields:
        # Nothing was cached, so fetch it now
        url = REST_ENDPOINT.format(store_name, METAFIELD_ENDPOINT)
        headers = {"Content-Type": "application/json", "X-Shopify-Access-Token": api_token}
        response = http.get(url = url, params = {"owner-resource": METAFIELD_OWNER}, headers = headers, ttl_seconds = CACHE_TTL)

        if response.status_code != 200:
            print("get_latest_celebration Error ❌: Status code %d, URL %s, Body %s" % (response.status_code, response.url, response.body()))
            return {"error": response.status_code}

        metafields = response.json()

    else:
        # Use our cached value
        print("Cache 💾: Found cached value for key %s" % cache_key)
        metafields = json.decode(cached_metafields)

    # Find the metafield with our namespace and key and return it
    for metafield in metafields["metafields"]:
        if metafield["namespace"] == METAFIELD_NAMESPACE and metafield["key"] == METAFIELD_KEY:
            return {
                "id": metafield["id"],
                "date": time.parse_time(metafield["updated_at"]).in_location("utc"),
                "orders": metafield["value"],
            }

    # If nothing was celebrated yet, our last number of celebrated orders is 0 on the epoch
    return {
        "orders": 0,
        "date": time.from_timestamp(0),
    }

# STORE LATEST CELEBRATION
# Creates or updates remote data representing our latest celebration as a shop metafield.
# -----------------------------------------------------------------------------------------
# celebration: A dict with 'id' and 'orders' keys
# store_name: A name of a Shopify store for the API call
# api_token: A Shopify API token
# Returns: True if successful, False otherwise
def store_latest_celebration(celebration, store_name, api_token):
    headers = {"Content-Type": "application/json", "X-Shopify-Access-Token": api_token}

    if not celebration.get("id"):
        # An ID isn't already available, so we're storing our data as a metafield
        # for the first time.

        url = REST_ENDPOINT.format(store_name, METAFIELD_ENDPOINT)

        payload = {
            "namespace": METAFIELD_NAMESPACE,
            "type": "number_integer",
            "key": METAFIELD_KEY,
            "description": METAFIELD_DESCRIPTION,
            "value": celebration["orders"],
        }

        response = http.post(url = url, headers = headers, json_body = {"metafield": payload})
        if response.status_code != 201:
            print("store_latest_celebration Error ❌: Status code %d, URL %s, Body %s" % (response.status_code, response.url, response.body()))
            return False

        return True

    else:
        # An ID is available, so we're updating our existing metafield with a new order count.

        url = REST_ENDPOINT.format(store_name, METAFIELD_UPDATE_ENDPOINT.format("%d" % celebration["id"]))
        payload = {"value": celebration["orders"]}
        response = http.put(url = url, headers = headers, json_body = {"metafield": payload})

        if response.status_code != 200:
            print("store_latest_celebration Error ❌: Status code %d, URL %s, Body %s" % (response.status_code, response.url, response.body()))
            return False

        return True

# GET ORDER COUNT
# Gets a number of orders for a provided store name using a provided API token
# -----------------------------------------------------------------------------------------
# store_name: A store name
# api_token: An API token
# Returns: A number representing the order count for a store, or -1 if the count couldn't be fetched
def get_order_count(store_name, api_token):
    # Check our cache
    cache_key = CACHE_ID_ORDERS.format(hash.sha1(store_name), hash.sha1(api_token))
    cached_orders = cache.get(cache_key)

    if not cached_orders:
        # Nothing was in the cache, so fetch our orders now
        url = REST_ENDPOINT.format(store_name, COUNT_ENDPOINT)
        headers = {"Content-Type": "application/json", "X-Shopify-Access-Token": api_token}
        response = http.get(url = url, params = {"status": "any"}, headers = headers, ttl_seconds = CACHE_TTL)

        # If there was any error, return -1
        if response.status_code != 200:
            print("get_order_count Error ❌: Status code %d, URL %s, Body %s" % (response.status_code, response.url, response.body()))
            return -1

        order_count = response.json()

    else:
        # Use our cached value
        print("Cache 💾: Found cached value for key %s" % cache_key)
        order_count = json.decode(cached_orders)

    # Return our count value
    return order_count["count"]

# Error View
# Renders an error message
# -----------------------------------------------------------------------------------------
# message: A message to display as a rendered error
# Returns: A Pixlet root element
def error_view(message):
    return render.Root(
        render.Stack(
            children = [
                render.Image(STARFIELD),
                render.Column(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        render.Image(ALIEN_ERROR),
                        render.Marquee(
                            width = 64,
                            offset_start = 64,
                            child = render.Text(content = message, color = "#FF0"),
                        ),
                    ],
                ),
            ],
        ),
    )

# Get Schema
# Return a Pixlet Schema for this Celebrate Applet
# -----------------------------------------------------------------------------------------
# Returns: A Pixlet schema
def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_token",
                name = "API Token",
                desc = "The API Token for your Shopify Private App",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "store_name",
                name = "Shopify Store Name",
                desc = "The Shopify store name used for API access",
                icon = "store",
            ),
        ],
    )
