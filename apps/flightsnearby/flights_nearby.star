"""
Applet: Flights Nearby
Summary: Flights nearby
Description: Find the closest flight to your location.
Author: eddichen
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")  #for easy reading numbers and times
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("images/img_0d507427.png", IMG_0d507427_ASSET = "file")
load("images/img_1ff9bbd5.png", IMG_1ff9bbd5_ASSET = "file")
load("images/img_267cc39a.png", IMG_267cc39a_ASSET = "file")
load("images/img_2cc0784f.png", IMG_2cc0784f_ASSET = "file")
load("images/img_35c4d1cd.png", IMG_35c4d1cd_ASSET = "file")
load("images/img_3bcf3d20.png", IMG_3bcf3d20_ASSET = "file")
load("images/img_4efad5ed.png", IMG_4efad5ed_ASSET = "file")
load("images/img_5857d1fc.png", IMG_5857d1fc_ASSET = "file")
load("images/img_6249c021.png", IMG_6249c021_ASSET = "file")
load("images/img_74ffc22d.png", IMG_74ffc22d_ASSET = "file")
load("images/img_780f9f33.png", IMG_780f9f33_ASSET = "file")
load("images/img_7a132dd3.png", IMG_7a132dd3_ASSET = "file")
load("images/img_846d6581.png", IMG_846d6581_ASSET = "file")
load("images/img_89970317.png", IMG_89970317_ASSET = "file")
load("images/img_8daf375d.png", IMG_8daf375d_ASSET = "file")
load("images/img_920088e3.png", IMG_920088e3_ASSET = "file")
load("images/img_95ff6baf.png", IMG_95ff6baf_ASSET = "file")
load("images/img_9e5a1eb2.png", IMG_9e5a1eb2_ASSET = "file")
load("images/img_a4c40ebb.png", IMG_a4c40ebb_ASSET = "file")
load("images/img_b93d45c4.png", IMG_b93d45c4_ASSET = "file")
load("images/img_ba07d7ec.png", IMG_ba07d7ec_ASSET = "file")
load("images/img_bbc52586.png", IMG_bbc52586_ASSET = "file")
load("images/img_bf094e0f.png", IMG_bf094e0f_ASSET = "file")
load("images/img_ca7a9d4e.png", IMG_ca7a9d4e_ASSET = "file")
load("images/img_cfe7b571.png", IMG_cfe7b571_ASSET = "file")
load("images/img_dd9c5e24.png", IMG_dd9c5e24_ASSET = "file")
load("images/img_e9aae2f6.png", IMG_e9aae2f6_ASSET = "file")
load("images/img_f336b78a.png", IMG_f336b78a_ASSET = "file")
load("images/img_f3812730.png", IMG_f3812730_ASSET = "file")
load("images/img_f3b3e221.png", IMG_f3b3e221_ASSET = "file")

DEFAULT_LOCATION = json.encode({
    "lat": "51.4395598",
    "lng": "-0.1013327",
    "description": "London Bridge, London, UK",
    "locality": "London",
    "place_id": "",
    "timezone": "",
})
DEFAULT_DISTANCE = "10"
DEFAULT_CACHE = 180
FLIGHT_RADAR_URL = "https://flight-radar1.p.rapidapi.com/flights/list-in-boundary"
TAILS = {
    "AA": IMG_846d6581_ASSET.readall(),
    "AY": IMG_e9aae2f6_ASSET.readall(),
    "B6": IMG_bf094e0f_ASSET.readall(),
    "BA": IMG_2cc0784f_ASSET.readall(),
    "CX": IMG_267cc39a_ASSET.readall(),
    "DL": IMG_f3b3e221_ASSET.readall(),
    "EK": IMG_5857d1fc_ASSET.readall(),
    "EY": IMG_89970317_ASSET.readall(),
    "FZ": IMG_3bcf3d20_ASSET.readall(),
    "IB": IMG_cfe7b571_ASSET.readall(),
    "IX": IMG_6249c021_ASSET.readall(),
    "JL": IMG_1ff9bbd5_ASSET.readall(),
    "KM": IMG_0d507427_ASSET.readall(),
    "LA": IMG_ba07d7ec_ASSET.readall(),
    "MH": IMG_4efad5ed_ASSET.readall(),
    "MS": IMG_dd9c5e24_ASSET.readall(),
    "OZ": IMG_780f9f33_ASSET.readall(),
    "PR": IMG_35c4d1cd_ASSET.readall(),
    "QF": IMG_f336b78a_ASSET.readall(),
    "QR": IMG_74ffc22d_ASSET.readall(),
    "Q4": IMG_7a132dd3_ASSET.readall(),
    "RJ": IMG_8daf375d_ASSET.readall(),
    "TG": IMG_95ff6baf_ASSET.readall(),
    "TK": IMG_9e5a1eb2_ASSET.readall(),
    "SK": IMG_f3812730_ASSET.readall(),
    "SQ": IMG_b93d45c4_ASSET.readall(),
    "U2": IMG_920088e3_ASSET.readall(),
    "UA": IMG_ca7a9d4e_ASSET.readall(),
    "UL": IMG_bbc52586_ASSET.readall(),
    "WY": IMG_a4c40ebb_ASSET.readall(),
}

# (degrees–>radians)
def deg_to_rad(num):
    return num * (math.pi / 180)

# (radians–>degrees)
def rad_to_deg(num):
    return (180 * num) / math.pi

def get_bounding_box(centrePoint, distance):
    distance = int(distance)
    if distance < 0:
        fail("Distance must be greater than 0")

    # coordinate limits
    MIN_LAT = deg_to_rad(-90)
    MAX_LAT = deg_to_rad(90)
    MIN_LON = deg_to_rad(-180)
    MAX_LON = deg_to_rad(180)

    # earth's radius (km)
    R = 6378.1

    # angular distance in radians on a great circle
    radDist = distance / R

    # centre point coordinates (deg)
    degLat = centrePoint[0]
    degLon = centrePoint[1]

    # centre point coordinates (rad)
    radLat = deg_to_rad(degLat)
    radLon = deg_to_rad(degLon)

    # minimum and maximum latitudes for given distance
    minLat = radLat - radDist
    maxLat = radLat + radDist

    # minimum and maximum longitudes for given distance
    minLon = 0
    maxLon = 0

    # define deltaLon to help determine min and max longitudes
    deltaLon = math.asin(math.sin(radDist) / math.cos(radLat))
    if (minLat > MIN_LAT) and (maxLat < MAX_LAT):
        minLon = radLon - deltaLon
        maxLon = radLon + deltaLon
        if minLon < MIN_LON:
            minLon = minLon + 2 * math.pi
        if maxLon > MAX_LON:
            maxLon = maxLon - 2 * math.pi

        # a pole is within the given distance
    else:
        minLat = math.max(minLat, MIN_LAT)
        maxLat = math.min(maxLat, MAX_LAT)
        minLon = MIN_LON
        maxLon = MAX_LON
    return [
        str(rad_to_deg(minLat)),
        str(rad_to_deg(minLon)),
        str(rad_to_deg(maxLat)),
        str(rad_to_deg(maxLon)),
    ]

def is_key_present(k):
    if k in TAILS:
        return TAILS[k]
    else:
        return TAILS["Q4"]

def reduce_accuracy(coord):
    coord_list = coord.split(".")
    coord_remainder = coord_list[1]
    if len(coord_remainder) > 3:
        coord_remainder = coord_remainder[0:3]
    return ".".join([coord_list[0], coord_remainder])

def update_display(tail, text):
    return render.Row(
        children = [
            render.Box(
                width = 32,
                child = render.Image(tail),
            ),
            render.Box(
                child = render.Column(
                    children = text,
                ),
            ),
        ],
    )

def get_bearing(lat_1, lng_1, lat_2, lng_2):
    lat_1 = math.radians(float(lat_1))
    lat_2 = math.radians(float(lat_2))
    lng_1 = math.radians(float(lng_1))
    lng_2 = math.radians(float(lng_2))

    #Let ‘R’ be the radius of Earth,
    #‘L’ be the longitude,
    #‘θ’ be latitude,
    #‘β‘ be get_Bearing.
    #β = atan2(X,Y) where
    #X = cos θb * sin ∆L
    #Y = cos θa * sin θb – sin θa * cos θb * cos ∆L

    x = math.cos(lat_2) * math.sin((lng_2 - lng_1))
    y = math.cos(lat_1) * math.sin(lat_2) - math.sin(lat_1) * math.cos(lat_2) * math.cos((lng_2 - lng_1))
    bearing = math.degrees(math.atan2(x, y))

    # our compass brackets are broken up in 45 degree increments from 0 8
    # to find the right bracket we need degrees from 0 to 360 then divide by 45 and round
    # what we get though is degrees -180 to 0 to 180 so this will convert to 0 to 360
    if bearing < 0:
        bearing = 360 + bearing

    return get_cardinal_point(bearing)

def get_cardinal_point(deg):
    # have bearning in degrees, now convert to cardinal point
    compass_brackets = ["North", "Northeast", "East", "Southeast", "South", "Southwest", "West", "Northwest", "North"]
    return compass_brackets[int(math.round(deg / 45))]

def main(config):
    api_key = config.get("key")
    hide_when_nothing_to_display = config.bool("hide", True)
    extend = config.bool("extend", True)

    if (api_key == "") or (api_key == None):
        tail = TAILS["Q4"]
        text = [
            render.Text("Add"),
            render.Text("API"),
            render.Text("Key"),
        ]
        return render.Root(
            child = update_display(tail, text),
        )

    location = json.decode(config.get("location", DEFAULT_LOCATION))

    orig_lat = location["lat"]
    orig_lng = location["lng"]

    lat = reduce_accuracy(orig_lat)
    lng = reduce_accuracy(orig_lng)

    cache_key = "_".join([lat, lng])

    flight_cached = cache.get(cache_key)
    if flight_cached != None:
        print("Hit! Displaying cached data.")
        flight = json.decode(flight_cached)
    else:
        print("Miss! Contacting Flight Radar")
        centrePoint = [float(lat), float(lng)]
        boundingBox = get_bounding_box(centrePoint, config.get("distance", DEFAULT_DISTANCE))
        rep = http.get(
            FLIGHT_RADAR_URL,
            params = {"bl_lat": boundingBox[0], "bl_lng": boundingBox[1], "tr_lat": boundingBox[2], "tr_lng": boundingBox[3], "altitude": "1000,60000"},
            headers = {"X-RapidAPI-Key": api_key, "X-RapidAPI-Host": "flight-radar1.p.rapidapi.com"},
        )
        if rep.status_code != 200:
            fail("Failed to fetch flights with status code:", rep.status_code)

        if rep.json()["aircraft"]:
            flights = rep.json()["aircraft"]
            if flights and len(flights) > 1:
                middle = (len(flights) // 2)
                flight = flights[middle]
            else:
                flight = flights[0]
        else:
            flight = []

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set(cache_key, json.encode(flight), ttl_seconds = DEFAULT_CACHE)

    if flight:
        origin = flight[12]
        destination = flight[13]
        flightNumber = flight[14]
        aircraftType = flight[9]
        airline = flightNumber[0:2]
        tail = is_key_present(airline)

        if extend:
            text = [
                render.Text("%s" % origin),
                render.Text("%s" % destination),
                render.Text("%s" % flightNumber),
                render.Marquee(
                    width = 32,
                    child = render.Text("Look %s for %s flying at %s feet, heading %s at %s mph" % (get_bearing(orig_lat, orig_lng, flight[2], flight[3]), aircraftType, humanize.comma(flight[5]), get_cardinal_point(flight[4]), humanize.comma(flight[6])), color = "#fff"),
                ),
            ]
        else:
            text = [
                render.Text("%s" % origin),
                render.Text("%s" % destination),
                render.Text("%s" % flightNumber),
                render.Text("%s" % aircraftType),
            ]
    elif hide_when_nothing_to_display == True:
        return []
    else:
        tail = TAILS["Q4"]
        text = [
            render.Text("No"),
            render.Text("Flights"),
            render.Text("Nearby"),
        ]

    return render.Root(
        child = update_display(tail, text),
        show_full_animation = True,
    )

def get_schema():
    options = [
        schema.Option(
            display = "1km",
            value = "1",
        ),
        schema.Option(
            display = "5km",
            value = "5",
        ),
        schema.Option(
            display = "10km",
            value = "10",
        ),
        schema.Option(
            display = "20km",
            value = "20",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Your current location",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "distance",
                name = "Distance",
                desc = "Search distance from your location.",
                icon = "rulerHorizontal",
                default = options[1].value,
                options = options,
            ),
            schema.Toggle(
                id = "hide",
                name = "Hide",
                desc = "Hide app when no flights nearby?",
                icon = "gear",
                default = False,
            ),
            schema.Toggle(
                id = "extend",
                name = "Extend",
                desc = "Show extended data for nearest flight?",
                icon = "gear",
                default = False,
            ),
            schema.Text(
                id = "key",
                name = "API key",
                desc = "Flight Radar API key",
                icon = "key",
                secret = True,
            ),
        ],
    )
