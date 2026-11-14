load("http.star", "http")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("strings.star", "strings")

# P2000 app for Tronbyt Server and Open HUB75 panels.
# Rendering happens on the Tronbyt Server; the panel receives the resulting WebP.
DEFAULT_API = "https://beta.alarmeringdroid.nl/api2/find/"
REGION_NAMES = {
    "1": "Amsterdam-Amstelland",
    "2": "Groningen",
    "3": "Noord- en Oost-Gelderland",
    "4": "Zaanstreek-Waterland",
    "5": "Hollands Midden",
    "6": "Brabant-Noord",
    "7": "Fryslan",
    "8": "Gelderland-Midden",
    "9": "Kennemerland",
    "10": "Rotterdam-Rijnmond",
    "11": "Brabant-Zuidoost",
    "12": "Drenthe",
    "13": "Gelderland-Zuid",
    "14": "Zuid-Holland-Zuid",
    "15": "Limburg-Noord",
    "17": "IJsselland",
    "18": "Utrecht",
    "19": "Gooi en Vechtstreek",
    "20": "Zeeland",
    "21": "Limburg-Zuid",
    "23": "Twente",
    "24": "Noord-Holland Noord",
    "25": "Haaglanden",
    "26": "Midden- en West-Brabant",
    "27": "Flevoland",
}

def csv(value):
    values = []
    for part in value.split(","):
        part = part.strip()
        if part:
            values.append(part)
    return values

def selected_regions(config):
    regions = []
    for field in ["region_1", "region_2", "region_3"]:
        value = config.str(field, "")
        if value and value != "0" and value not in regions:
            regions.append(value)

    # Backward compatibility for installations saved with schema version 1.
    if not regions:
        return csv(config.str("regions", ""))
    return regions

def capcodes_for(message):
    codes = []
    for cap in message.get("capcodes", []):
        code = str(cap.get("capcode", ""))
        if code:
            codes.append(code)
    return codes

def matches(message, regions, wanted_caps):
    if not regions or str(message.get("regioid", "")) not in regions:
        return False
    if not wanted_caps:
        return True
    for code in capcodes_for(message):
        if code in wanted_caps:
            return True
    return False

def service_kind(message):
    source = (message.get("dienst", "") + " " + message.get("capstring", "") + " " + message.get("tekstmelding", "")).lower()
    if "trauma" in source or "lifeliner" in source or "mmt" in source or "0120901" in source:
        return "lifeliner"
    if "brandweer" in source or "brw" in source:
        return "brandweer"
    if "politie" in source:
        return "politie"
    if "ambulance" in source or "ambu" in source or "rav" in source or "mka" in source:
        return "ambulance"
    return "overige"

def service_enabled(message, config):
    kind = service_kind(message)
    return config.bool("service_" + kind, True)

def latest_message(config):
    response = http.get(config.str("api_url", DEFAULT_API), ttl_seconds = 15)
    if response.status_code != 200:
        return None, "API %d" % response.status_code
    data = response.json()
    messages = data.get("meldingen", data.get("messages", data.get("results", [])))
    regions = selected_regions(config)
    wanted_caps = csv(config.str("capcodes", ""))
    for message in messages:
        if matches(message, regions, wanted_caps) and service_enabled(message, config):
            return message, ""
    return None, "Geen melding"

def service_info(message):
    kind = service_kind(message)
    if kind == "lifeliner":
        return "HELI", "#ffd400"
    if kind == "brandweer":
        return "BRAND", "#ff3b30"
    if kind == "politie":
        return "POL", "#3b82f6"
    if kind == "ambulance":
        return "AMB", "#26d07c"
    return "P2000", "#00d9ff"

def text_for(message):
    return message.get("tekstmelding", message.get("melding", message.get("message", "")))

def region_name(message):
    name = message.get("regio", "")
    if name:
        return name
    return REGION_NAMES.get(str(message.get("regioid", "")), "Onbekende regio")

def error_screen(title):
    return render.Root(
        child = render.Box(
            width = canvas.width(),
            height = canvas.height(),
            color = "#000000",
            child = render.Padding(
                pad = 2,
                child = render.Column(children = [
                    render.Text(content = "P2000", font = "tb-8", color = "#00d9ff"),
                    render.Text(content = title, font = "CG-pixel-3x5-mono", color = "#ffcc00"),
                ]),
            ),
        ),
    )

def main(config):
    message, error = latest_message(config)
    if message == None:
        return error_screen(error)

    service, accent = service_info(message)
    timestamp = message.get("tijd", "")
    if message.get("datum", ""):
        timestamp = message.get("datum") + " " + timestamp
    place = strings.truncate(message.get("plaats", message.get("regio", "Onbekend")), 19, "")
    description = text_for(message)
    region = strings.truncate(region_name(message), 25, "...")

    return render.Root(
        child = render.Box(
            width = canvas.width(),
            height = canvas.height(),
            color = "#000000",
            child = render.Padding(
                pad = 1,
                child = render.Column(children = [
                    render.Row(children = [
                        render.Text(content = service, font = "CG-pixel-3x5-mono", color = accent),
                        render.Text(content = " " + timestamp, font = "CG-pixel-3x5-mono", color = "#b0b8c4"),
                    ]),
                    render.Text(content = place, font = "tb-8", color = "#ffffff"),
                    render.Marquee(
                        width = canvas.width() - 2,
                        child = render.Text(content = description, font = "CG-pixel-3x5-mono", color = "#d5dbe5"),
                        offset_start = 0,
                        offset_end = 0,
                        delay = 12,
                    ),
                    render.Text(content = region, font = "CG-pixel-3x5-mono", color = accent),
                ]),
            ),
        ),
    )

def region_options():
    return [
        # Dropdown option values may not be empty in the Pixlet schema.
        schema.Option(display = "Geen", value = "0"),
        schema.Option(display = "Amsterdam-Amstelland", value = "1"),
        schema.Option(display = "Groningen", value = "2"),
        schema.Option(display = "Noord- en Oost-Gelderland", value = "3"),
        schema.Option(display = "Zaanstreek-Waterland", value = "4"),
        schema.Option(display = "Hollands Midden", value = "5"),
        schema.Option(display = "Brabant-Noord", value = "6"),
        schema.Option(display = "Fryslan", value = "7"),
        schema.Option(display = "Gelderland-Midden", value = "8"),
        schema.Option(display = "Kennemerland", value = "9"),
        schema.Option(display = "Rotterdam-Rijnmond", value = "10"),
        schema.Option(display = "Brabant-Zuidoost", value = "11"),
        schema.Option(display = "Drenthe", value = "12"),
        schema.Option(display = "Gelderland-Zuid", value = "13"),
        schema.Option(display = "Zuid-Holland-Zuid", value = "14"),
        schema.Option(display = "Limburg-Noord", value = "15"),
        schema.Option(display = "IJsselland", value = "17"),
        schema.Option(display = "Utrecht", value = "18"),
        schema.Option(display = "Gooi en Vechtstreek", value = "19"),
        schema.Option(display = "Zeeland", value = "20"),
        schema.Option(display = "Limburg-Zuid", value = "21"),
        schema.Option(display = "Twente", value = "23"),
        schema.Option(display = "Noord-Holland Noord", value = "24"),
        schema.Option(display = "Haaglanden", value = "25"),
        schema.Option(display = "Midden- en West-Brabant", value = "26"),
        schema.Option(display = "Flevoland", value = "27"),
    ]

def get_schema():
    options = region_options()
    return schema.Schema(
        # This is the Pixlet schema format version, not the app revision.
        # Tronbyt currently expects schema format version 1.
        version = "1",
        fields = [
            schema.Dropdown(
                id = "region_1",
                name = "Regio 1",
                desc = "Primaire veiligheidsregio.",
                icon = "mapLocationDot",
                default = "9",
                options = options,
            ),
            schema.Dropdown(
                id = "region_2",
                name = "Regio 2",
                desc = "Optionele tweede veiligheidsregio.",
                icon = "mapLocationDot",
                default = "0",
                options = options,
            ),
            schema.Dropdown(
                id = "region_3",
                name = "Regio 3",
                desc = "Optionele derde veiligheidsregio.",
                icon = "mapLocationDot",
                default = "0",
                options = options,
            ),
            schema.Toggle(
                id = "service_brandweer",
                name = "Brandweer",
                desc = "Toon brandweermeldingen.",
                icon = "fireFlameCurved",
                default = True,
            ),
            schema.Toggle(
                id = "service_politie",
                name = "Politie",
                desc = "Toon politiemeldingen.",
                icon = "shieldHalved",
                default = True,
            ),
            schema.Toggle(
                id = "service_ambulance",
                name = "Ambulance",
                desc = "Toon ambulance- en RAV-meldingen.",
                icon = "truckMedical",
                default = True,
            ),
            schema.Toggle(
                id = "service_lifeliner",
                name = "Lifeliner / traumaheli",
                desc = "Toon MMT- en traumahelimeldingen.",
                icon = "helicopter",
                default = True,
            ),
            schema.Toggle(
                id = "service_overige",
                name = "Overige diensten",
                desc = "Toon meldingen die niet onder de vier diensten vallen.",
                icon = "towerBroadcast",
                default = True,
            ),
            schema.Text(
                id = "capcodes",
                name = "Capcodes",
                desc = "Optioneel, komma-gescheiden. Leeg toont alle capcodes in de gekozen regio's.",
                icon = "towerBroadcast",
                default = "",
            ),
            schema.Text(
                id = "api_url",
                name = "P2000 API URL",
                desc = "Standaard: Alarmeringdroid API v2.",
                icon = "link",
                default = DEFAULT_API,
            ),
        ],
    )
