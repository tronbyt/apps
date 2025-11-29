"""
Applet: WowCharacterStats
Summary: Show stats for a WoW toon
Description: Show statistics for a World of Warcraft character. Stats shown include name, class, item level, Mythic+ rating, and raid progress.
Author: KDubs
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("images/dh_icon.png", DH_ICON_ASSET = "file")
load("images/dk_icon.png", DK_ICON_ASSET = "file")
load("images/druid_icon.png", DRUID_ICON_ASSET = "file")
load("images/evoker_icon.png", EVOKER_ICON_ASSET = "file")
load("images/hunter_icon.png", HUNTER_ICON_ASSET = "file")
load("images/mage_icon.png", MAGE_ICON_ASSET = "file")
load("images/monk_icon.png", MONK_ICON_ASSET = "file")
load("images/paladin_icon.png", PALADIN_ICON_ASSET = "file")
load("images/priest_icon.png", PRIEST_ICON_ASSET = "file")
load("images/rogue_icon.png", ROGUE_ICON_ASSET = "file")
load("images/shaman_icon.png", SHAMAN_ICON_ASSET = "file")
load("images/warlock_icon.png", WARLOCK_ICON_ASSET = "file")
load("images/warrior_icon.png", WARRIOR_ICON_ASSET = "file")
load("images/wow_icon.png", WOW_ICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

DH_ICON = DH_ICON_ASSET.readall()
DK_ICON = DK_ICON_ASSET.readall()
DRUID_ICON = DRUID_ICON_ASSET.readall()
EVOKER_ICON = EVOKER_ICON_ASSET.readall()
HUNTER_ICON = HUNTER_ICON_ASSET.readall()
MAGE_ICON = MAGE_ICON_ASSET.readall()
MONK_ICON = MONK_ICON_ASSET.readall()
PALADIN_ICON = PALADIN_ICON_ASSET.readall()
PRIEST_ICON = PRIEST_ICON_ASSET.readall()
ROGUE_ICON = ROGUE_ICON_ASSET.readall()
SHAMAN_ICON = SHAMAN_ICON_ASSET.readall()
WARLOCK_ICON = WARLOCK_ICON_ASSET.readall()
WARRIOR_ICON = WARRIOR_ICON_ASSET.readall()
WOW_ICON = WOW_ICON_ASSET.readall()

RAID_COLORS = {
    "Raid Finder": "#1eff00",
    "Normal": "#0070dd",
    "Heroic": "#a335ee",
    "Mythic": "#ff8000",
}

DEFAULT_CHARACTER = "chinpokodin"
DEFAULT_REALM = "firetree"
DEFAULT_REGION = "us"
DEFAULT_AUTH_TTL = 86399

CURRENT_EXPANSION = "The War Within"
CURRENT_INSTANCE = "Manaforge Omega"

def main(config):
    character_name = config.get("character", DEFAULT_CHARACTER).lower()
    realm_name = config.get("realm", DEFAULT_REALM).replace(" ", "-").lower()
    region = config.get("region", DEFAULT_REGION)
    client_id = config.get("client")
    client_secret = config.get("secret")

    if not client_id or not client_secret:
        return render.Root(
            child = render.Row(
                expanded = True,
                main_align = "center",
                cross_align = "center",
                children = [
                    render.WrappedText(
                        content = "Client ID/Secret required.",
                        align = "center",
                    ),
                ],
            ),
        )

    blizzard_auth_url = "https://oauth.battle.net/token?grant_type=client_credentials"
    blizzard_profile_url = "https://%s.api.blizzard.com/profile/wow/character/%s/%s?namespace=profile-%s&locale=en_US" % (region, realm_name, character_name, region)
    blizzard_mythic_url = "https://%s.api.blizzard.com/profile/wow/character/%s/%s/mythic-keystone-profile?namespace=profile-%s&locale=en_US" % (region, realm_name, character_name, region)
    blizzard_raid_url = "https://%s.api.blizzard.com/profile/wow/character/%s/%s/encounters/raids?namespace=profile-%s&locale=en_US" % (region, realm_name, character_name, region)

    access_token = get_auth_token(blizzard_auth_url, client_id, client_secret)

    if access_token == None:
        return render.Root(
            child = render.Row(
                main_align = "center",
                cross_align = "center",
                expanded = True,
                children = [
                    render.WrappedText(
                        content = "Auth failure!",
                        align = "center",
                    ),
                ],
            ),
        )

    player_profile = fetch_data(blizzard_profile_url, access_token)
    player_mythic = fetch_data(blizzard_mythic_url, access_token)
    player_raids = fetch_data(blizzard_raid_url, access_token)

    if player_profile == None:
        return render.Root(
            child = render.Row(
                main_align = "center",
                cross_align = "center",
                expanded = True,
                children = [
                    render.WrappedText(
                        content = "%s - %s (%s) not found." % (character_name, realm_name, region),
                        align = "center",
                    ),
                ],
            ),
        )

    faction_color = "#f00"
    if player_profile["faction"]["name"] == "Alliance":
        faction_color = "#00f"

    return render.Root(
        delay = 3750,
        child = render.Column(
            expanded = True,
            main_align = "space_around",
            cross_align = "center",
            children = [
                render.Marquee(
                    width = 64,
                    align = "center",
                    child = render.Text(
                        content = player_profile["name"],
                        color = determine_class_color(player_profile),
                    ),
                ),
                render.Row(
                    expanded = True,
                    main_align = "start",
                    cross_align = "center",
                    children = [
                        render.Padding(
                            pad = (2, 1, 0, 1),
                            child = render.Image(src = determine_icon(player_profile)),
                        ),
                        render.Box(
                            height = 24,
                            width = 40,
                            padding = 1,
                            child = render.Animation(
                                children = [
                                    render.Column(
                                        cross_align = "center",
                                        main_align = "space_evenly",
                                        expanded = True,
                                        children = [
                                            render.Text(
                                                content = "lvl %d" % player_profile["level"],
                                                font = "tom-thumb",
                                            ),
                                            render.Text(
                                                content = "%s" % player_profile["faction"]["name"],
                                                font = "tom-thumb",
                                                color = faction_color,
                                            ),
                                            render.Text(
                                                content = "ilvl %d" % player_profile["equipped_item_level"],
                                                font = "tom-thumb",
                                            ),
                                        ],
                                    ),
                                    render.Column(
                                        cross_align = "center",
                                        main_align = "space_evenly",
                                        expanded = True,
                                        children = [
                                            get_mythic_plus_io(player_mythic),
                                            get_raid_progress(player_raids),
                                        ],
                                    ),
                                ],
                            ),
                        ),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    options = [
        schema.Option(
            display = "North America",
            value = "us",
        ),
        schema.Option(
            display = "Europe",
            value = "eu",
        ),
        schema.Option(
            display = "Korea",
            value = "kr",
        ),
        schema.Option(
            display = "Taiwan",
            value = "tw",
        ),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "character",
                name = "Character Name",
                desc = "The name of the WoW character to display",
                icon = "user",
            ),
            schema.Text(
                id = "realm",
                name = "Realm Name",
                desc = "The name of the realm where the character resides",
                icon = "earthAmericas",
            ),
            schema.Dropdown(
                id = "region",
                name = "Region",
                desc = "Region the realm is located in.",
                icon = "globe",
                default = options[0].value,
                options = options,
            ),
            schema.Text(
                id = "client",
                name = "Client Id",
                desc = "Battle.net Client ID",
                icon = "user",
            ),
            schema.Text(
                id = "secret",
                name = "Client Secret",
                desc = "Battle.net Client Secret",
                icon = "key",
            ),
        ],
    )

def get_auth_token(url, id, secret):
    token = cache.get("access_token")
    if token != None:
        print("Valid Auth token found!")
    else:
        print("Auth Token is not valid. Calling API to fetch new token...")
        headers = {
            "Authorization": "Basic %s" % base64.encode("%s:%s" % (id, secret)),
        }
        response = http.post(url, headers = headers)
        if response.status_code != 200:
            print("Blizzard request failed with status %d" % response.status_code)
            return None

        # cache call is needed because ttl is dynamic based on the response body values
        cache.set(
            "access_token",
            json.decode(response.body())["access_token"],
            ttl_seconds = json.decode(response.body())["expires_in"],
        )
        token = json.decode(response.body())["access_token"]

    return token

def fetch_data(url, token):
    headers = {
        "Authorization": "Bearer %s" % token,
    }
    response = http.get(url, headers = headers, ttl_seconds = 300)
    if response.status_code != 200:
        print("Blizzard request failed with status %d" % response.status_code)
        return None

    return response.json()

def determine_icon(profile):
    player_class = profile["character_class"]["name"]

    if player_class == "Warrior":
        return WARRIOR_ICON
    elif player_class == "Shaman":
        return SHAMAN_ICON
    elif player_class == "Death Knight":
        return DK_ICON
    elif player_class == "Demon Hunter":
        return DH_ICON
    elif player_class == "Druid":
        return DRUID_ICON
    elif player_class == "Hunter":
        return HUNTER_ICON
    elif player_class == "Evoker":
        return EVOKER_ICON
    elif player_class == "Mage":
        return MAGE_ICON
    elif player_class == "Monk":
        return MONK_ICON
    elif player_class == "Paladin":
        return PALADIN_ICON
    elif player_class == "Priest":
        return PRIEST_ICON
    elif player_class == "Warlock":
        return WARLOCK_ICON
    elif player_class == "Rogue":
        return ROGUE_ICON

    return WOW_ICON

def determine_class_color(profile):
    player_class = profile["character_class"]["name"]

    if player_class == "Death Knight":
        return "#C41E3A"
    elif player_class == "Demon Hunter":
        return "#A330C9"
    elif player_class == "Druid":
        return "#FF7C0A"
    elif player_class == "Evoker":
        return "#33937F"
    elif player_class == "Hunter":
        return "#AAD372"
    elif player_class == "Mage":
        return "#3FC7EB"
    elif player_class == "Monk":
        return "#00FF98"
    elif player_class == "Paladin":
        return "#F48CBA"
    elif player_class == "Priest":
        return "#FFFFFF"
    elif player_class == "Rogue":
        return "#FFF468"
    elif player_class == "Shaman":
        return "#0070DD"
    elif player_class == "Warlock":
        return "#8788EE"
    elif player_class == "Warrior":
        return "#C69B6D"

    return "#FFF"

def rgb_to_hex(r, g, b):
    r = "%x" % r
    g = "%x" % g
    b = "%x" % b
    return "#%s%s%s" % (pad_hex(r), pad_hex(g), pad_hex(b))

def pad_hex(i):
    if len(i) == 1:
        return "0%s" % i
    else:
        return i

def get_raid_progress(progress):
    status = "N/A raid"
    raid_level = "none"

    if "expansions" in progress:
        for expansion in progress["expansions"]:
            if expansion["expansion"]["name"] == CURRENT_EXPANSION:
                for instance in expansion["instances"]:
                    if instance["instance"]["name"] == CURRENT_INSTANCE:
                        for mode in instance["modes"]:
                            status = "%d/%d %s" % (
                                mode["progress"]["completed_count"],
                                mode["progress"]["total_count"],
                                mode["difficulty"]["type"][:1],
                            )
                            raid_level = mode["difficulty"]["name"]

    if raid_level != "none":
        return render.Text(
            content = status,
            font = "tom-thumb",
            color = RAID_COLORS[raid_level],
        )
    else:
        return render.Text(
            content = status,
            font = "tom-thumb",
        )

def get_mythic_plus_io(mythic):
    if "current_mythic_rating" in mythic:
        return render.Text(
            content = "%d io" % mythic["current_mythic_rating"]["rating"],
            font = "tom-thumb",
            color = rgb_to_hex(
                mythic["current_mythic_rating"]["color"]["r"],
                mythic["current_mythic_rating"]["color"]["g"],
                mythic["current_mythic_rating"]["color"]["b"],
            ),
        )
    else:
        return render.Text(
            content = "N/A io",
            font = "tom-thumb",
        )
