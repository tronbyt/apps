"""
Applet: Destiny 2 Stats
Summary: Display Destiny stats
Description: Gets the emblem, race, class, and light level of your most recently played Destiny 2 charact✗ Summary (what's the short and sweet of what this app does?): Gets the emblem, race, class, and light level of your most recently played Destiny 2 charact✗ Summary (what's the short and sweet of what this app does?): Gets the emblem, race, class, and light level of your most recently played Destiny 2 character.
Author: brandontod97
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("images/img_0ad593aa.png", IMG_0ad593aa_ASSET = "file")

API_BASE_URL = "https://www.bungie.net/platform"
API_USER_PROFILE = API_BASE_URL + "/User/GetBungieNetUserById/"
API_SEARCH_BUNGIE_ID = API_BASE_URL + "/User/Search/GlobalName/0/"
API_SEARCH_BUNGIE_ID_NAME = API_BASE_URL + "/Destiny2/SearchDestinyPlayerByBungieName/-1/"

def main(config):
    display_name = config.get("display_name")
    display_name_code = config.get("display_name_code")
    show_id = config.bool("show_id", False)
    displayed_character = ""

    api_key = config.get("api_key")

    character_cached = cache.get("character" + display_name + display_name_code)

    if character_cached != None:
        print("Displaying cached character data")
        displayed_character = json.decode(character_cached)

    else:
        print("No cached data. Hitting API")

        bungie_membership_id = ""
        bungie_membership_type = ""

        if api_key == None or display_name == None or display_name_code == None:
            api_key = "null value"
            display_name = "null value"
            display_name_code = "null value"

        apiResponse = http.post(
            API_SEARCH_BUNGIE_ID_NAME,
            headers = {"X-API-Key": api_key},
            json_body = {"displayName": display_name, "displayNameCode": display_name_code},
        )

        if apiResponse.json()["ErrorStatus"] == "ApiInvalidOrExpiredKey" or len(apiResponse.json()["Response"]) == 0:
            return render.Root(
                child = render.Column(
                    main_align = "center",
                    expanded = True,
                    children = [
                        render.Box(
                            height = 8,
                            child = render.Text("Invalid API"),
                        ),
                        render.Box(
                            height = 8,
                            child = render.Text("or"),
                        ),
                        render.Box(
                            height = 8,
                            child = render.Text("Invalid ID"),
                        ),
                    ],
                ),
            )
        else:
            print("Recieved valid response")
            bungie_membership_id = apiResponse.json()["Response"][0]["membershipId"]
            bungie_membership_type = apiResponse.json()["Response"][0]["membershipType"]

            apiMembershipInfo = http.get(
                API_BASE_URL + "/Destiny2/" + str(int(bungie_membership_type)) + "/Profile/" + bungie_membership_id + "/",
                params = {"components": "Characters"},
                headers = {"X-API-Key": api_key},
            )

            displayed_character = apiMembershipInfo.json()["Response"]["characters"]["data"][get_last_played_character(apiMembershipInfo.json()["Response"]["characters"]["data"])]

            # TODO: Determine if this cache call can be converted to the new HTTP cache.
            cache.set("character" + display_name + display_name_code, json.encode(displayed_character), ttl_seconds = 300)

    image = get_image("https://www.bungie.net" + displayed_character["emblemPath"])

    #TODO: Clean this up and send dictionary of values instead of all the needed values separately
    return get_view(show_id, image, displayed_character, display_name, display_name_code)

def get_last_played_character(characters_list):
    most_recent_character = {
        "id": "",
        "date": time.parse_time("1999-01-01T00:01:00.00Z"),
    }

    for character in characters_list:
        parsed_date = time.parse_time(characters_list[character]["dateLastPlayed"])

        if (parsed_date > most_recent_character["date"]):
            most_recent_character["date"] = parsed_date
            most_recent_character["id"] = character

    return most_recent_character["id"]

def get_image(url):
    if url:
        print("Getting " + url)
        response = http.get(url)

        if response.status_code == 200:
            return response.body()
        else:
            return IMG_0ad593aa_ASSET.readall()

    # Should never get here.
    return ""

def get_character_class(class_value):
    class_value = int(class_value)

    if (class_value == 0):
        return "Titan"

    elif (class_value == 1):
        return "Huntr"

    elif (class_value == 2):
        return "Wrlck"

    else:
        return "Unknown"

def get_character_race(race_value):
    race_value = int(race_value)

    if (race_value == 0):
        return "Human"

    elif (race_value == 1):
        return "Awokn"

    elif (race_value == 2):
        return "Exo"

    else:
        return "Unkn"

def get_view(show_id, image, displayed_character, display_name, display_name_code):
    no_username_view = render.Root(
        child = render.Row(
            cross_align = "center",
            children = [
                render.Image(src = image, width = 32, height = 32),
                render.Box(width = 1, height = 32, color = "#FFFFFF"),
                render.Column(
                    expanded = True,
                    main_align = "space_around",
                    cross_align = "right",
                    children = [
                        render.Box(
                            height = 6,
                            child = render.Text(get_character_race(displayed_character["raceType"])),
                        ),
                        render.Box(
                            height = 6,
                            child = render.Text(get_character_class(displayed_character["classType"])),
                        ),
                        render.Box(
                            height = 6,
                            child = render.Text(str(int(displayed_character["light"]))),
                        ),
                    ],
                ),
            ],
        ),
    )

    username_view = render.Root(
        child = render.Column(
            cross_align = "center",
            children = [
                render.Row(
                    cross_align = "center",
                    children = [
                        render.Image(src = image, width = 24, height = 24),
                        render.Box(width = 1, height = 22, color = "#FFFFFF"),
                        render.Column(
                            expanded = False,
                            main_align = "space_around",
                            cross_align = "right",
                            children = [
                                render.Box(
                                    height = 8,
                                    child = render.Text(get_character_race(displayed_character["raceType"])),
                                ),
                                render.Box(
                                    height = 8,
                                    child = render.Text(get_character_class(displayed_character["classType"])),
                                ),
                                render.Box(
                                    height = 8,
                                    child = render.Text(str(int(displayed_character["light"]))),
                                ),
                            ],
                        ),
                    ],
                ),
                render.Box(width = 64, height = 1, color = "#FFFFFF"),
                render.Box(width = 64, height = 1),
                render.Marquee(
                    width = 64,
                    child = render.Row(
                        children = [
                            render.Text(
                                font = "CG-pixel-4x5-mono",
                                content = display_name,
                            ),
                            render.Text(
                                font = "CG-pixel-4x5-mono",
                                color = "#808080",
                                content = "#" + display_name_code,
                            ),
                        ],
                    ),
                ),
            ],
        ),
    )

    if show_id:
        return username_view
    else:
        return no_username_view

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_key",
                name = "API Key",
                desc = "Your Bungie API key.",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "display_name",
                name = "Display Name",
                desc = "Your display name for your bungie account. This consists of your username before the # in your Bungie ID.",
                icon = "user",
            ),
            schema.Text(
                id = "display_name_code",
                name = "Display Code",
                desc = "Your display code for your bungie account. This consists of the numbers after the # in your Bungie ID.",
                icon = "code",
            ),
            schema.Toggle(
                id = "show_id",
                name = "Show ID",
                desc = "Show your Bungie ID.",
                icon = "idCard",
                default = False,
            ),
        ],
    )
