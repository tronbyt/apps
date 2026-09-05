"""
Applet: SFBF Ferry
Summary: SF Bay Ferry schedules
Description: Display next departure times for SF Bay Ferry routes.
Author: nyergler
"""

load("encoding/csv.star", "csv")
load("images/sfbf_icon.png", SFBF_ICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

def main(config):
    route = config.str("route", "")
    direction = config.str("direction", "")
    stop = ""
    times = [""]
    displayDay = False
    displayTimes = []

    if route != "" and direction != "":
        n = time.now()

        # get the first route stop regardless of calendar for display purposes
        stop = "unknown"
        firstStop = [
            s["stop_name"]
            for s in get_csv(stops_csv)
            if s["stop_id"] in [
                [
                    st["stop_id"]
                    for st in get_csv(stop_times_csv)
                    if st["trip_id"] in [
                        t["trip_id"]
                        for t in get_trips(route, direction, [])
                    ] and st["stop_sequence"] == "1"
                ],
            ][0]
        ]
        if len(firstStop) > 0:
            stop = firstStop[0]

        # find the next day with service available from this stop
        day = n
        times = []
        for add in range(7):
            day = n + (time.hour * 24 * add)
            displayDay = add > 0
            trip_ids = [t["trip_id"] for t in get_trips(route, direction, get_services(day))]
            times = [
                st["departure_time"].rsplit(":", 1)[0]
                for st in get_csv(stop_times_csv)
                if st["trip_id"] in trip_ids and st["stop_sequence"] == "1"
            ]

            times = [
                t
                for t in times
                if displayDay or time.time(
                    # we use n here rather than day so we'll show the first times on following days
                    year = n.year,
                    month = n.month,
                    day = n.day,
                    hour = int(t.split(":")[0]),
                    minute = int(t.split(":")[1]),
                    location = "America/Los_Angeles",
                ) > n
            ]
            if len(times) > 0:
                break

        times = sorted(times)
        if len(times) < 1:
            times = ["No departures."]

        if displayDay:
            displayTimes.append(render.Text(day.format("Monday")))
        for t in times:
            displayTimes.append(render.Text(t))

    return render.Root(
        child = render.Column(
            expanded = True,
            children = [
                render.Marquee(
                    child = render.Text(stop),
                    width = 64,
                ),
                render.Row(
                    cross_align = "center",
                    expanded = True,
                    children = [
                        render.Image(
                            src = ICON,
                            width = 32,
                        ),
                        render.Column(
                            expanded = True,
                            children = displayTimes,
                        ),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    route_options = [
        schema.Option(display = r["route_long_name"], value = r["route_id"])
        for r in get_csv(routes_csv)
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "route",
                name = "Route?",
                desc = "Choose ferry route.",
                icon = "ship",
                default = route_options[0].value,
                options = route_options,
            ),
            schema.Generated(
                id = "direction",
                source = "route",
                handler = get_direction_options,
            ),
        ],
    )

def get_direction_options(route_id):
    """
    get_direction_options returns the schema for selecting the route direction.
    """
    directions = [
        schema.Option(display = d["direction"], value = d["direction_id"])
        for d in get_csv(directions_csv)
        if d["route_id"] == route_id
    ]

    return [
        schema.Dropdown(
            id = "direction",
            name = "Direction?",
            desc = "Choose direction.",
            icon = "compass",
            default = directions[0].value,
            options = directions,
        ),
    ]

def get_services(now):
    """
    get_services returns a list of service IDs valid for the given date.
    """
    day = now.format("Monday").lower()

    return [
        s["service_id"]
        for s in get_csv(calendar_csv)
        if s[day] == "1" and
           s["start_date"] <= now.format("20060102") and
           s["end_date"] >= now.format("20060102")
    ]

def get_trips(route_id, direction_id, services):
    """
    get_trips returns a list of trips for the given route and direction.

    The trips are returned as dicts.
    """
    return [
        t
        for t in get_csv(trips_csv)
        if t["route_id"] == route_id and
           t["direction_id"] == direction_id and (
            services == [] or t["service_id"] in services
        )
    ]

def get_csv(source):
    """
    get_csv returns a list of dictionaries, one for each row in the CSV source.

    The first row of the source is assumed to be the field names.
    """
    route_rows = csv.read_all(source)
    fields = route_rows[0]

    return [
        dict(zip(fields, row))
        for row in route_rows[1:]
    ]

calendar_csv = """
service_id,service_name,monday,tuesday,wednesday,thursday,friday,saturday,sunday,start_date,end_date
c_69270_b_80277_d_96,Year Round starting 04/03/23 (Weekend),0,0,0,0,0,1,1,20230403,20231008
c_69270_b_80277_d_31,Year Round starting 04/03/23 (Weekday),1,1,1,1,1,0,0,20230403,20231008
"""

routes_csv = """
agency_id,route_id,route_short_name,route_long_name,route_desc,route_type,route_url,route_color,route_text_color,route_sort_order,min_headway_minutes,eligibility_restricted,continuous_pickup,continuous_drop_off,tts_route_short_name,tts_route_long_name
873,11114,OA,Oakland & Alameda,,4,https://sanfranciscobayferry.com/oakland-alameda-ferry-route,4fab47,000000,0,25,0,1,1,,
873,11113,HB,Harbor Bay,,4,https://sanfranciscobayferry.com/harbor-bay-ferry-route,c74a5d,ffffff,1,,0,1,1,,
873,11112,SSF,South San Francisco,,4,https://sanfranciscobayferry.com/south-san-francisco-ferry-route,851f83,ffffff,2,60,0,1,1,,
873,11110,VJO,Vallejo,,4,https://sanfranciscobayferry.com/vallejo-ferry-route,008c99,000000,3,30,0,1,1,,
873,12419,RCH,Richmond,,4,https://sanfranciscobayferry.com/richmond-ferry-route,004576,ffffff,4,,0,1,1,,
873,19310,P41,San Francisco Pier 41 Short Hop,,4,https://sanfranciscobayferry.com/pier-41-short-hop,000000,ffffff,5,,0,1,1,,
873,19417,SEA,Alameda Seaplane,,4,https://sanfranciscobayferry.com/alameda-seaplane-ferry-route,df7a1c,000000,6,,0,1,1,,
"""

directions_csv = """
route_id,direction_id,direction
19417,1,West
19417,0,East
19310,1,West
19310,0,East
12419,1,South
12419,0,North
11114,1,West
11114,0,East
11113,1,West
11113,0,East
11112,1,South
11112,0,North
11110,1,South
11110,0,North
"""

stops_csv = """
stop_id,stop_code,platform_code,stop_name,stop_desc,stop_lat,stop_lon,zone_id,stop_url,location_type,parent_station,stop_timezone,position,direction,wheelchair_boarding,tts_stop_name
7201,7201,,San Francisco Ferry Building,,37.79476,-122.3922,,https://sanfranciscobayferry.com/terminals/downtown-san-francisco-ferry-terminal,1,,America/Los_Angeles,,,1,
72011,72011,E,San Francisco Ferry Building Gate E,,37.795106,-122.391612,,,0,7201,,,,1,
72012,72012,G,San Francisco Ferry Building Gate G,,37.79439,-122.39093,,,0,7201,,,,1,
72013,72013,F,San Francisco Ferry Building Gate F,,37.79476,-122.39125,,,0,7201,,,,1,
7205,7205,,South San Francisco Ferry Terminal,"911 Marina Blvd, South San Francisco in Oyster Point",37.662676,-122.377245,,https://sanfranciscobayferry.com/terminals/south-san-francisco-ferry-terminal,0,,America/Los_Angeles,,,1,
7206,7206,,Harbor Bay Ferry Terminal,"215 Adelphian Way, Alameda",37.7366,-122.25692,,https://sanfranciscobayferry.com/terminals/harbor-bay-ferry-terminal,0,,America/Los_Angeles,,,1,
7207,7207,,Alameda Seaplane Lagoon Ferry Terminal,"1701 Ferry Point Rd, Alameda in Alameda Point",37.77717,-122.29832,,https://sanfranciscobayferry.com/terminals/seaplane-lagoon-ferry-terminal,0,,America/Los_Angeles,,,1,
7208,7208,,Main Street Alameda Ferry Terminal,"2990 Main Street, Alameda in Alameda Point",37.79076,-122.29398,,https://sanfranciscobayferry.com/terminals/main-street-alameda-ferry-terminal,0,,America/Los_Angeles,,,1,
7209,7209,,Oakland Ferry Terminal,Near Clay St and Water St at Jack London Square,37.79509,-122.27976,,https://sanfranciscobayferry.com/terminals/oakland-ferry-terminal,0,,America/Los_Angeles,,,1,
7210,7210,,San Francisco Pier 41 Ferry Terminal,Near Powell Street and Embarcadero,37.80933,-122.41209,,https://sanfranciscobayferry.com/terminals/pier-41-ferry-terminal,0,,America/Los_Angeles,,,1,
7211,7211,,Richmond Ferry Terminal,"1453 Harbour Way South, Richmond near the Craneway Pavilion",37.90951,-122.35925,,https://sanfranciscobayferry.com/terminals/richmond-ferry-terminal,0,,America/Los_Angeles,,,1,
7212,7212,,Vallejo Ferry Terminal,"At the foot of Georgia St, Downtown Vallejo",38.10012,-122.26263,,https://sanfranciscobayferry.com/terminals/vallejo-ferry-terminal,0,,America/Los_Angeles,,,1,Valet-ho Ferry Terminal
7213,7213,,Mare Island Ferry Terminal,"1050 Nimitz Avenue, Vallejo",38.10127,-122.26949,,https://sanfranciscobayferry.com/terminals/mare-island-ferry-terminal,0,,America/Los_Angeles,,,1,
gatee,gatee,,Gate E,,37.79476,-122.3922,,,2,7201,,,,0,
gateef,gateef,,Gate EF,,37.79456,-122.39207,,,2,7201,,,,0,
gatef,gatef,,Gate F,,37.79438,-122.39186,,,2,7201,,,,0,
gateg,gateg,,Gate G,,37.79402,-122.39154,,,2,7201,,,,0,
middleentrance,middleentrance,,Middle Entrance,,37.79431,-122.3925,,,2,7201,,,,0,
northentrance,northentrance,,North Entrance,,37.794877,-122.392399,,,2,7201,,,,0,
southentrance,southentrance,,Southern Entrance,,37.793793,-122.391934,,,2,7201,,,,0,
"""

trips_csv = """
route_id,service_id,trip_id,trip_short_name,trip_headsign,direction_id,block_id,shape_id,bikes_allowed,wheelchair_accessible,trip_type,drt_max_travel_time,drt_avg_travel_time,drt_advance_book_min,drt_pickup_message,drt_drop_off_message,continuous_pickup_message,continuous_drop_off_message,tts_trip_headsign,tts_trip_short_name
11110,c_69270_b_80277_d_31,t_5567993_b_80277_tn_0,,Mare Island via Vallejo,0,VJO AM2,p_298493,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11110,c_69270_b_80277_d_31,t_5567994_b_80277_tn_0,,Vallejo,0,VJO PM2,p_179875,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11110,c_69270_b_80277_d_31,t_5568186_b_80277_tn_0,,Mare Island via Vallejo,0,VJO PM2,p_298493,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11110,c_69270_b_80277_d_31,t_5567997_b_80277_tn_0,,Vallejo,0,VJO PM2,p_179875,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11110,c_69270_b_80277_d_31,t_5568069_b_80277_tn_0,,Mare Island via Vallejo,0,VJO AM1,p_298493,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11110,c_69270_b_80277_d_31,t_5568072_b_80277_tn_0,,Vallejo,0,VJO AM1,p_179875,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11110,c_69270_b_80277_d_31,t_5568074_b_80277_tn_0,,Mare Island via Vallejo,0,VJO AM3,p_298493,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11110,c_69270_b_80277_d_31,t_5568075_b_80277_tn_0,,Mare Island via Vallejo,0,VJO PM3,p_298493,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11110,c_69270_b_80277_d_31,t_5567998_b_80277_tn_0,,Vallejo,0,VJO PM1,p_179875,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11110,c_69270_b_80277_d_31,t_5567999_b_80277_tn_0,,Mare Island via Vallejo,0,VJO PM1,p_298493,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11110,c_69270_b_80277_d_31,t_5568000_b_80277_tn_0,,Vallejo,0,VJO AM3,p_179875,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11110,c_69270_b_80277_d_31,t_5568001_b_80277_tn_0,,Vallejo,0,VJO PM3,p_179875,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11110,c_69270_b_80277_d_31,t_5568002_b_80277_tn_1,,Vallejo,0,VJO AM2,p_179875,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11110,c_69270_b_80277_d_31,t_5568003_b_80277_tn_0,,Vallejo,0,VJO AM1,p_179875,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11110,c_69270_b_80277_d_31,t_5568112_b_80277_tn_0,,San Francisco Ferry Building,1,VJO PM1,p_179862,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11110,c_69270_b_80277_d_31,t_5567988_b_80277_tn_0,,San Francisco Ferry Building via Vallejo,1,VJO AM2,p_180271,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11110,c_69270_b_80277_d_31,t_5567992_b_80277_tn_0,,San Francisco Ferry Building,1,VJO AM1,p_179862,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11110,c_69270_b_80277_d_31,t_5567996_b_80277_tn_0,,San Francisco Ferry Building,1,VJO AM2,p_1425745,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11110,c_69270_b_80277_d_31,t_5568004_b_80277_tn_0,,San Francisco Ferry Building,1,VJO PM1,p_179862,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11110,c_69270_b_80277_d_31,t_5568005_b_80277_tn_0,,San Francisco Ferry Building via Vallejo,1,VJO AM3,p_180271,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11110,c_69270_b_80277_d_31,t_5568006_b_80277_tn_0,,San Francisco Ferry Building,1,VJO AM3,p_179862,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11110,c_69270_b_80277_d_31,t_5568007_b_80277_tn_0,,San Francisco Ferry Building,1,VJO AM1,p_179862,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11110,c_69270_b_80277_d_31,t_5568077_b_80277_tn_0,,San Francisco Ferry Building,1,VJO PM2,p_179862,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11110,c_69270_b_80277_d_31,t_5568160_b_80277_tn_0,,San Francisco Ferry Building via Vallejo,1,VJO PM3,p_1425747,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11110,c_69270_b_80277_d_31,t_5568184_b_80277_tn_0,,San Francisco Ferry Building,1,VJO PM3,p_179862,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11110,c_69270_b_80277_d_31,t_5568185_b_80277_tn_0,,San Francisco Ferry Building,1,VJO PM2,p_179862,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11110,c_69270_b_80277_d_31,t_5567987_b_80277_tn_0,,San Francisco Ferry Building via Vallejo,1,VJO AM1,p_180271,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11110,c_69270_b_80277_d_96,t_5568022_b_80277_tn_0,,Mare Island via Vallejo,0,VJO WKND3,p_298493,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11110,c_69270_b_80277_d_96,t_5568023_b_80277_tn_0,,Vallejo,0,VJO WKND1,p_179875,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11110,c_69270_b_80277_d_96,t_5568024_b_80277_tn_0,,Vallejo,0,VJO WKND2,p_179875,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11110,c_69270_b_80277_d_96,t_5568025_b_80277_tn_0,,Mare Island via Vallejo,0,VJO WKND2,p_298493,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11110,c_69270_b_80277_d_96,t_5568026_b_80277_tn_0,,Vallejo,0,VJO WKND2,p_179875,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11110,c_69270_b_80277_d_96,t_5568027_b_80277_tn_0,,Vallejo,0,VJO WKND1,p_179875,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11110,c_69270_b_80277_d_96,t_5568078_b_80277_tn_0,,Mare Island via Vallejo,0,VJO WKND1,p_298493,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11110,c_69270_b_80277_d_96,t_5568079_b_80277_tn_0,,Vallejo,0,VJO WKND3,p_179875,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11110,c_69270_b_80277_d_96,t_5568029_b_80277_tn_0,,San Francisco Ferry Building via Vallejo,1,VJO WKND3,p_180271,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11110,c_69270_b_80277_d_96,t_5568080_b_80277_tn_0,,San Francisco Ferry Building,1,VJO WKND3,p_179862,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11110,c_69270_b_80277_d_96,t_5568030_b_80277_tn_0,,San Francisco Ferry Building,1,VJO WKND1,p_179862,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11110,c_69270_b_80277_d_96,t_5568031_b_80277_tn_0,,San Francisco Ferry Building,1,VJO WKND2,p_179862,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11110,c_69270_b_80277_d_96,t_5568032_b_80277_tn_0,,San Francisco Ferry Building,1,VJO WKND1,p_179862,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11110,c_69270_b_80277_d_96,t_5568033_b_80277_tn_0,,San Francisco Ferry Building,1,VJO WKND2,p_179862,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11110,c_69270_b_80277_d_96,t_5568034_b_80277_tn_0,,San Francisco Ferry Building via Vallejo,1,VJO WKND2,p_180271,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11110,c_69270_b_80277_d_96,t_5568028_b_80277_tn_0,,San Francisco Ferry Building via Vallejo,1,VJO WKND1,p_180271,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11112,c_69270_b_80277_d_31,t_5568152_b_80277_tn_0,,Alameda Main St via Oakland,0,SSF PM2,p_179316,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11112,c_69270_b_80277_d_31,t_5568113_b_80277_tn_0,,Oakland Ferry Terminal via Alameda Main St,0,SSF AM1,p_298507,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11112,c_69270_b_80277_d_31,t_5567995_b_80277_tn_0,,Alameda Main St via Oakland,0,SSF PM1,p_179316,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11112,c_69270_b_80277_d_31,t_5568151_b_80277_tn_0,,Alameda Main St via Oakland,0,SSF PM1,p_1434076,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11112,c_69270_b_80277_d_31,t_5568089_b_80277_tn_0,,South San Francisco,1,SSF PM1,p_1434079,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11112,c_69270_b_80277_d_31,t_5568088_b_80277_tn_0,,South San Francisco,1,SSF AM1,p_298487,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11112,c_69270_b_80277_d_31,t_5568114_b_80277_tn_0,,South San Francisco,1,SSF AM1,p_298487,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11112,c_69270_b_80277_d_31,t_5568115_b_80277_tn_0,,South San Francisco,1,SSF AM2,p_298487,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11113,c_69270_b_80277_d_31,t_5568117_b_80277_tn_0,,Harbor Bay Ferry Terminal,0,SSF PM1,p_531019,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11113,c_69270_b_80277_d_31,t_5568118_b_80277_tn_0,,Harbor Bay Ferry Terminal,0,HB PM1,p_531019,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11113,c_69270_b_80277_d_31,t_5568119_b_80277_tn_0,,Harbor Bay Ferry Terminal,0,HB PM1,p_531019,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11113,c_69270_b_80277_d_31,t_5568120_b_80277_tn_0,,Harbor Bay Ferry Terminal,0,HB PM1,p_531019,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11113,c_69270_b_80277_d_31,t_5568121_b_80277_tn_0,,Harbor Bay Ferry Terminal,0,HB PM1,p_531019,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11113,c_69270_b_80277_d_31,t_5568155_b_80277_tn_0,,Harbor Bay Ferry Terminal,0,RCH AM2,p_531019,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11113,c_69270_b_80277_d_31,t_5568054_b_80277_tn_0,,Harbor Bay Ferry Terminal,0,HB AM1,p_531019,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11113,c_69270_b_80277_d_31,t_5568055_b_80277_tn_0,,Harbor Bay Ferry Terminal,0,HB AM1,p_531019,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11113,c_69270_b_80277_d_31,t_5568081_b_80277_tn_0,,Harbor Bay Ferry Terminal,0,HB AM1,p_531019,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11113,c_69270_b_80277_d_31,t_5568116_b_80277_tn_0,,Harbor Bay Ferry Terminal,0,HB AM1,p_531019,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11113,c_69270_b_80277_d_31,t_5568058_b_80277_tn_0,,San Francisco Ferry Building,1,HB AM1,p_531020,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11113,c_69270_b_80277_d_31,t_5568056_b_80277_tn_0,,San Francisco Ferry Building,1,HB AM1,p_531020,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11113,c_69270_b_80277_d_31,t_5568057_b_80277_tn_0,,San Francisco Ferry Building,1,HB AM1,p_531020,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11113,c_69270_b_80277_d_31,t_5568059_b_80277_tn_0,,San Francisco Ferry Building,1,HB AM1,p_531020,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11113,c_69270_b_80277_d_31,t_5568060_b_80277_tn_0,,San Francisco Ferry Building,1,HB AM1,p_531020,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11113,c_69270_b_80277_d_31,t_5568122_b_80277_tn_0,,San Francisco Ferry Building,1,HB PM1,p_531020,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11113,c_69270_b_80277_d_31,t_5568123_b_80277_tn_0,,San Francisco Ferry Building,1,HB PM1,p_531020,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11113,c_69270_b_80277_d_31,t_5568124_b_80277_tn_0,,San Francisco Ferry Building,1,SSF AM1,p_531020,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11113,c_69270_b_80277_d_31,t_5568125_b_80277_tn_0,,San Francisco Ferry Building,1,HB PM1,p_531020,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11113,c_69270_b_80277_d_31,t_5568126_b_80277_tn_0,,San Francisco Ferry Building,1,HB PM1,p_531020,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11113,c_69270_b_80277_d_31,t_5568156_b_80277_tn_0,,San Francisco Ferry Building,1,RCH AM2,p_531020,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11113,c_69270_b_80277_d_31,t_5568159_b_80277_tn_0,,San Francisco Ferry Building,1,SSF AM2,p_1425744,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_31,t_5568179_b_80277_tn_0,,Oakland Ferry Terminal,0,VJO AM2,p_1426957,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_31,t_5567984_b_80277_tn_0,,Oakland Ferry Terminal,0,OA AM2,p_530949,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_31,t_5567985_b_80277_tn_0,,Oakland Ferry Terminal,0,OA PM2,p_530949,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_31,t_5567986_b_80277_tn_0,,Oakland Ferry Terminal,0,VJO PM3,p_530949,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_31,t_5568020_b_80277_tn_0,,Alameda Main St via Oakland,0,OA PM2,p_530962,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_31,t_5568021_b_80277_tn_0,,Oakland Ferry Terminal,0,SP PM,p_530949,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_31,t_5568061_b_80277_tn_0,,Alameda Main St,0,OA AM2,p_1303753,,1,,1.0t+0.00,1.0t+0.00,,,,,,Alameda Main Street,
11114,c_69270_b_80277_d_31,t_5568082_b_80277_tn_0,,Oakland Ferry Terminal,0,OA PM1,p_530949,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_31,t_5568083_b_80277_tn_0,,Oakland Ferry Terminal,0,SP AM,p_530949,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_31,t_5568084_b_80277_tn_0,,Oakland Ferry Terminal,0,OA PM1,p_530949,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_31,t_5568085_b_80277_tn_0,,Oakland Ferry Terminal,0,OA PM1,p_530949,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_31,t_5568086_b_80277_tn_0,,Oakland Ferry Terminal,0,OA PM1,p_530949,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_31,t_5568087_b_80277_tn_0,,Oakland Ferry Terminal,0,OA PM2,p_530949,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_31,t_5568091_b_80277_tn_0,,Alameda Main St,0,RCH AM1,p_1303753,,1,,1.0t+0.00,1.0t+0.00,,,,,,Alameda Main Street,
11114,c_69270_b_80277_d_31,t_5568127_b_80277_tn_0,,Alameda Main St,0,SSF AM2,p_1303753,,1,,1.0t+0.00,1.0t+0.00,,,,,,Alameda Main Street,
11114,c_69270_b_80277_d_31,t_5568128_b_80277_tn_0,,Oakland Ferry Terminal,0,OA AM1,p_530949,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_31,t_5568129_b_80277_tn_0,,Oakland Ferry Terminal,0,OA AM2,p_530949,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_31,t_5568188_b_80277_tn_0,,Oakland Ferry Terminal,0,SP PM,p_530949,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_31,t_5568130_b_80277_tn_0,,Oakland Ferry Terminal,0,OA AM1,p_530949,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_31,t_5568153_b_80277_tn_0,,San Francisco Ferry Building,1,OA AM2,p_1425735,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_31,t_5568183_b_80277_tn_0,,San Francisco Ferry Building via Oakland,1,RCH AM1,p_1426921,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_31,t_5568182_b_80277_tn_0,,San Francisco Ferry Building via Alameda Main St,1,SP PM,p_1434073,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_31,t_5568178_b_80277_tn_0,,San Francisco Ferry Building,1,VJO AM2,p_1425731,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_31,t_5568147_b_80277_tn_0,,San Francisco Ferry Building via Alameda Main St,1,OA PM2,p_530954,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_31,t_5568137_b_80277_tn_0,,San Francisco Ferry Building via Alameda Main St,1,OA PM2,p_530954,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_31,t_5568136_b_80277_tn_0,,San Francisco Ferry Building,1,OA PM1,p_788331,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_31,t_5568135_b_80277_tn_0,,San Francisco Ferry Building,1,OA AM1,p_788331,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_31,t_5568134_b_80277_tn_0,,San Francisco Ferry Building,1,OA AM2,p_788331,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_31,t_5568133_b_80277_tn_0,,San Francisco Ferry Building via Alameda Main St,1,SP PM,p_530954,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_31,t_5568132_b_80277_tn_0,,San Francisco Ferry Building,1,OA AM1,p_1425731,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_31,t_5568131_b_80277_tn_0,,San Francisco Ferry Building via Alameda Main St,1,OA PM1,p_530954,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_31,t_5568111_b_80277_tn_0,,San Francisco Ferry Building,1,SSF AM2,p_1425733,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_31,t_5568110_b_80277_tn_0,,San Francisco Ferry Building via Alameda Main St,1,VJO PM3,p_1434082,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_31,t_5568109_b_80277_tn_0,,San Francisco Ferry Building via Oakland,1,OA AM2,p_1426921,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_31,t_5568068_b_80277_tn_0,,San Francisco Ferry Building,1,SP AM,p_1425735,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_31,t_5568062_b_80277_tn_0,,San Francisco Ferry Building,1,OA AM1,p_788331,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_31,t_5567991_b_80277_tn_0,,San Francisco Ferry Building via Alameda Main St,1,OA PM1,p_530954,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_31,t_5567990_b_80277_tn_0,,San Francisco Ferry Building via Alameda Main St,1,OA PM1,p_530954,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_31,t_5567982_b_80277_tn_0,,San Francisco Ferry Building via Oakland,1,OA PM1,p_530966,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_96,t_5568043_b_80277_tn_0,,Alameda Main St,0,OA WKND3,p_1303753,,1,,1.0t+0.00,1.0t+0.00,,,,,,Alameda Main Street,
11114,c_69270_b_80277_d_96,t_5568044_b_80277_tn_0,,Alameda Main St,0,OA WKND2,p_1303753,,1,,1.0t+0.00,1.0t+0.00,,,,,,Alameda Main Street,
11114,c_69270_b_80277_d_96,t_5568045_b_80277_tn_0,,Alameda Main St,0,OA WKND2,p_1303753,,1,,1.0t+0.00,1.0t+0.00,,,,,,Alameda Main Street,
11114,c_69270_b_80277_d_96,t_5568038_b_80277_tn_0,,Alameda Main St,0,OA WKND1,p_1303753,,1,,1.0t+0.00,1.0t+0.00,,,,,,Alameda Main Street,
11114,c_69270_b_80277_d_96,t_5568036_b_80277_tn_0,,Alameda Main St,0,OA WKND2,p_1303753,,1,,1.0t+0.00,1.0t+0.00,,,,,,Alameda Main Street,
11114,c_69270_b_80277_d_96,t_5568035_b_80277_tn_0,,Alameda Main St,0,OA WKND1,p_1303753,,1,,1.0t+0.00,1.0t+0.00,,,,,,Alameda Main Street,
11114,c_69270_b_80277_d_96,t_5568037_b_80277_tn_0,,Alameda Main St,0,OA WKND1,p_1303753,,1,,1.0t+0.00,1.0t+0.00,,,,,,Alameda Main Street,
11114,c_69270_b_80277_d_96,t_5568236_b_80277_tn_0,,Alameda Main St,0,OA WKND3,p_1303753,,1,,1.0t+0.00,1.0t+0.00,,,,,,Alameda Main Street,
11114,c_69270_b_80277_d_96,t_5568039_b_80277_tn_0,,Alameda Main St,0,OA WKND3,p_1303753,,1,,1.0t+0.00,1.0t+0.00,,,,,,Alameda Main Street,
11114,c_69270_b_80277_d_96,t_5568070_b_80277_tn_0,,Oakland Ferry Terminal via Alameda Main St,0,RCH WKND2,p_530951,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_96,t_5568040_b_80277_tn_0,,Alameda Main St,0,OA WKND3,p_1303753,,1,,1.0t+0.00,1.0t+0.00,,,,,,Alameda Main Street,
11114,c_69270_b_80277_d_96,t_5568041_b_80277_tn_0,,Alameda Main St,0,OA WKND3,p_1303753,,1,,1.0t+0.00,1.0t+0.00,,,,,,Alameda Main Street,
11114,c_69270_b_80277_d_96,t_5568046_b_80277_tn_0,,Alameda Main St,0,OA WKND1,p_1303753,,1,,1.0t+0.00,1.0t+0.00,,,,,,Alameda Main Street,
11114,c_69270_b_80277_d_96,t_5568042_b_80277_tn_0,,Alameda Main St,0,OA WKND2,p_1303753,,1,,1.0t+0.00,1.0t+0.00,,,,,,Alameda Main Street,
11114,c_69270_b_80277_d_96,t_5568009_b_80277_tn_0,,San Francisco Ferry Building via Oakland,1,OA WKND1,p_530966,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_96,t_5568008_b_80277_tn_0,,San Francisco Ferry Building via Oakland,1,OA WKND3,p_530966,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_96,t_5568010_b_80277_tn_0,,San Francisco Ferry Building via Oakland,1,OA WKND1,p_530966,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_96,t_5568011_b_80277_tn_0,,San Francisco Ferry Building via Oakland,1,OA WKND1,p_530966,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_96,t_5568014_b_80277_tn_0,,San Francisco Ferry Building via Oakland,1,OA WKND1,p_530966,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_96,t_5568047_b_80277_tn_0,,San Francisco Ferry Building,1,OA WKND2,p_788331,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_96,t_5568015_b_80277_tn_0,,San Francisco Ferry Building via Oakland,1,OA WKND3,p_530966,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_96,t_5568016_b_80277_tn_0,,San Francisco Ferry Building via Oakland,1,OA WKND3,p_530966,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_96,t_5568237_b_80277_tn_0,,San Francisco Ferry Building via Oakland,1,OA WKND2,p_530966,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_96,t_5568238_b_80277_tn_0,,San Francisco Ferry Building via Oakland,1,OA WKND2,p_530966,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_96,t_5568017_b_80277_tn_0,,San Francisco Ferry Building via Oakland,1,OA WKND1,p_530966,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_96,t_5568239_b_80277_tn_0,,San Francisco Ferry Building via Oakland,1,OA WKND3,p_530966,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_96,t_5568240_b_80277_tn_0,,San Francisco Ferry Building via Oakland,1,OA WKND2,p_530966,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_96,t_5568019_b_80277_tn_0,,San Francisco Ferry Building via Oakland,1,OA WKND2,p_530966,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
11114,c_69270_b_80277_d_96,t_5568018_b_80277_tn_0,,San Francisco Ferry Building via Oakland,1,OA WKND3,p_530966,,1,,1.0t+0.00,1.0t+0.00,,,,,,,
12419,c_69270_b_80277_d_31,t_5568234_b_80277_tn_0,,Richmond,0,SSF AM2,p_531490,,1,,,,,,,,,,
12419,c_69270_b_80277_d_31,t_5567983_b_80277_tn_0,,Richmond,0,RCH PM1,p_898865,,1,,,,,,,,,,
12419,c_69270_b_80277_d_31,t_5568187_b_80277_tn_0,,Richmond,0,RCH AM2,p_898865,,1,,,,,,,,,,
12419,c_69270_b_80277_d_31,t_5568140_b_80277_tn_0,,Richmond,0,RCH PM1,p_898865,,1,,,,,,,,,,
12419,c_69270_b_80277_d_31,t_5568176_b_80277_tn_0,,Richmond,0,OA AM1,p_898865,,1,,,,,,,,,,
12419,c_69270_b_80277_d_31,t_5568063_b_80277_tn_0,,Richmond,0,RCH PM2,p_898865,,1,,,,,,,,,,
12419,c_69270_b_80277_d_31,t_5568064_b_80277_tn_0,,Richmond,0,RCH PM2,p_898865,,1,,,,,,,,,,
12419,c_69270_b_80277_d_31,t_5568150_b_80277_tn_0,,Richmond,0,RCH PM1,p_898865,,1,,,,,,,,,,
12419,c_69270_b_80277_d_31,t_5568065_b_80277_tn_0,,Richmond,0,RCH AM2,p_898865,,1,,,,,,,,,,
12419,c_69270_b_80277_d_31,t_5568138_b_80277_tn_0,,Richmond,0,RCH AM1,p_898865,,1,,,,,,,,,,
12419,c_69270_b_80277_d_31,t_5568139_b_80277_tn_0,,Richmond,0,RCH PM1,p_898865,,1,,,,,,,,,,
12419,c_69270_b_80277_d_31,t_5568071_b_80277_tn_0,,Richmond,0,RCH PM2,p_898865,,1,,,,,,,,,,
12419,c_69270_b_80277_d_31,t_5568073_b_80277_tn_0,,San Francisco Ferry Building,1,RCH PM2,p_898866,,1,,,,,,,,,,
12419,c_69270_b_80277_d_31,t_5567989_b_80277_tn_0,,San Francisco Ferry Building,1,RCH PM2,p_898866,,1,,,,,,,,,,
12419,c_69270_b_80277_d_31,t_5568066_b_80277_tn_0,,San Francisco Ferry Building,1,RCH AM1,p_898866,,1,,,,,,,,,,
12419,c_69270_b_80277_d_31,t_5568067_b_80277_tn_0,,San Francisco Ferry Building,1,OA AM1,p_898866,,1,,,,,,,,,,
12419,c_69270_b_80277_d_31,t_5568076_b_80277_tn_0,,San Francisco Ferry Building,1,RCH PM2,p_531492,,1,,,,,,,,,,
12419,c_69270_b_80277_d_31,t_5568141_b_80277_tn_0,,San Francisco Ferry Building,1,RCH AM2,p_898866,,1,,,,,,,,,,
12419,c_69270_b_80277_d_31,t_5568142_b_80277_tn_0,,San Francisco Ferry Building,1,RCH PM1,p_898866,,1,,,,,,,,,,
12419,c_69270_b_80277_d_31,t_5568143_b_80277_tn_0,,San Francisco Ferry Building,1,RCH PM1,p_898866,,1,,,,,,,,,,
12419,c_69270_b_80277_d_31,t_5568148_b_80277_tn_0,,San Francisco Ferry Building,1,RCH AM2,p_898866,,1,,,,,,,,,,
12419,c_69270_b_80277_d_31,t_5568149_b_80277_tn_0,,San Francisco Ferry Building,1,RCH PM1,p_898866,,1,,,,,,,,,,
12419,c_69270_b_80277_d_31,t_5568158_b_80277_tn_0,,San Francisco Ferry Building,1,RCH AM1,p_1425734,,1,,,,,,,,,,
12419,c_69270_b_80277_d_31,t_5568177_b_80277_tn_0,,San Francisco Ferry Building,1,RCH AM2,p_531492,,1,,,,,,,,,,
12419,c_69270_b_80277_d_31,t_5568181_b_80277_tn_0,,San Francisco Ferry Building,1,VJO PM2,p_898866,,1,,,,,,,,,,
12419,c_69270_b_80277_d_31,t_5568235_b_80277_tn_0,,San Francisco Ferry Building,1,SSF AM2,p_531492,,1,,,,,,,,,,
12419,c_69270_b_80277_d_96,t_5568052_b_80277_tn_0,,Richmond,0,RCH WKND2,p_531490,,1,,,,,,,,,,
12419,c_69270_b_80277_d_96,t_5568048_b_80277_tn_0,,Richmond,0,RCH WKND2,p_531490,,1,,,,,,,,,,
12419,c_69270_b_80277_d_96,t_5568049_b_80277_tn_0,,Richmond,0,RCH WKND2,p_531490,,1,,,,,,,,,,
12419,c_69270_b_80277_d_96,t_5568050_b_80277_tn_0,,Richmond,0,RCH WKND1,p_531490,,1,,,,,,,,,,
12419,c_69270_b_80277_d_96,t_5568051_b_80277_tn_0,,Richmond,0,RCH WKND1,p_531490,,1,,,,,,,,,,
12419,c_69270_b_80277_d_96,t_5568053_b_80277_tn_0,,San Francisco Ferry Building,1,RCH WKND1,p_531492,,1,,,,,,,,,,
12419,c_69270_b_80277_d_96,t_5568145_b_80277_tn_0,,San Francisco Ferry Building,1,RCH WKND2,p_531492,,1,,,,,,,,,,
12419,c_69270_b_80277_d_96,t_5568146_b_80277_tn_0,,San Francisco Ferry Building,1,RCH WKND2,p_531492,,1,,,,,,,,,,
12419,c_69270_b_80277_d_96,t_5582562_b_80277_tn_0,,San Francisco Ferry Building,1,RCH WKND2,p_1425734,,1,,,,,,,,,,
12419,c_69270_b_80277_d_96,t_5568144_b_80277_tn_0,,San Francisco Ferry Building,1,RCH WKND1,p_531492,,1,,,,,,,,,,
19310,c_69270_b_80277_d_96,t_5568172_b_80277_tn_0,,San Francisco Ferry Building,0,VJO WKND3,p_1304623,,1,,,,,,,,,,
19310,c_69270_b_80277_d_96,t_5568170_b_80277_tn_0,,San Francisco Ferry Building,0,RCH WKND1,p_1275835,,1,,,,,,,,,,
19310,c_69270_b_80277_d_96,t_5568173_b_80277_tn_0,,San Francisco Ferry Building,0,RCH WKND1,p_1275835,,1,,,,,,,,,,
19310,c_69270_b_80277_d_96,t_5568174_b_80277_tn_0,,Pier 41,1,RCH WKND1,p_1275834,,1,,,,,,,,,,
19310,c_69270_b_80277_d_96,t_5568171_b_80277_tn_0,,Pier 41,1,RCH WKND1,p_1275834,,1,,,,,,,,,,
19310,c_69270_b_80277_d_96,t_5568175_b_80277_tn_0,,Pier 41,1,VJO WKND3,p_1304622,,1,,,,,,,,,,
19417,c_69270_b_80277_d_31,t_5568154_b_80277_tn_0,,Alameda Seaplane,0,OA AM2,p_1276399,,1,,,,,,,,,,
19417,c_69270_b_80277_d_31,t_5568090_b_80277_tn_0,,Alameda Seaplane,0,OA PM2,p_1276399,,1,,,,,,,,,,
19417,c_69270_b_80277_d_31,t_5568092_b_80277_tn_0,,Alameda Seaplane,0,HB PM1,p_1276399,,1,,,,,,,,,,
19417,c_69270_b_80277_d_31,t_5568093_b_80277_tn_0,,Alameda Seaplane,0,SP AM,p_1276399,,1,,,,,,,,,,
19417,c_69270_b_80277_d_31,t_5568097_b_80277_tn_0,,Alameda Seaplane,0,SP AM,p_1276399,,1,,,,,,,,,,
19417,c_69270_b_80277_d_31,t_5568098_b_80277_tn_0,,Alameda Seaplane,0,SSF PM2,p_1276399,,1,,,,,,,,,,
19417,c_69270_b_80277_d_31,t_5568169_b_80277_tn_0,,Alameda Seaplane,0,OA AM2,p_1276399,,1,,,,,,,,,,
19417,c_69270_b_80277_d_31,t_5568167_b_80277_tn_0,,Alameda Seaplane,0,SP AM,p_1276399,,1,,,,,,,,,,
19417,c_69270_b_80277_d_31,t_5568166_b_80277_tn_0,,Alameda Seaplane,0,SP PM,p_1276399,,1,,,,,,,,,,
19417,c_69270_b_80277_d_31,t_5568165_b_80277_tn_0,,Alameda Seaplane,0,RCH AM1,p_1276399,,1,,,,,,,,,,
19417,c_69270_b_80277_d_31,t_5568099_b_80277_tn_0,,Alameda Seaplane,0,SP PM,p_1276399,,1,,,,,,,,,,
19417,c_69270_b_80277_d_31,t_5568100_b_80277_tn_0,,Alameda Seaplane,0,SP PM,p_1276399,,1,,,,,,,,,,
19417,c_69270_b_80277_d_31,t_5568101_b_80277_tn_0,,Alameda Seaplane,0,SP AM,p_1276399,,1,,,,,,,,,,
19417,c_69270_b_80277_d_31,t_5568189_b_80277_tn_0,,Alameda Seaplane,0,RCH PM2,p_1276399,,1,,,,,,,,,,
19417,c_69270_b_80277_d_31,t_5568102_b_80277_tn_0,,Alameda Seaplane,0,OA PM2,p_1276399,,1,,,,,,,,,,
19417,c_69270_b_80277_d_31,t_5568164_b_80277_tn_0,,San Francisco Ferry Building,1,SSF PM1,p_1276395,,1,,,,,,,,,,
19417,c_69270_b_80277_d_31,t_5567980_b_80277_tn_0,,San Francisco Ferry Building,1,OA AM2,p_1425732,,1,,,,,,,,,,
19417,c_69270_b_80277_d_31,t_5567981_b_80277_tn_0,,San Francisco Ferry Building,1,OA AM2,p_1425732,,1,,,,,,,,,,
19417,c_69270_b_80277_d_31,t_5568163_b_80277_tn_0,,San Francisco Ferry Building,1,SP AM,p_1276395,,1,,,,,,,,,,
19417,c_69270_b_80277_d_31,t_5568162_b_80277_tn_0,,San Francisco Ferry Building,1,RCH AM1,p_1276395,,1,,,,,,,,,,
19417,c_69270_b_80277_d_31,t_5568161_b_80277_tn_0,,San Francisco Ferry Building,1,RCH PM2,p_1425746,,1,,,,,,,,,,
19417,c_69270_b_80277_d_31,t_5568094_b_80277_tn_0,,San Francisco Ferry Building,1,OA PM2,p_1425732,,1,,,,,,,,,,
19417,c_69270_b_80277_d_31,t_5568095_b_80277_tn_0,,San Francisco Ferry Building,1,SP AM,p_1425732,,1,,,,,,,,,,
19417,c_69270_b_80277_d_31,t_5568096_b_80277_tn_0,,San Francisco Ferry Building,1,SP PM,p_1425732,,1,,,,,,,,,,
19417,c_69270_b_80277_d_31,t_5568106_b_80277_tn_0,,San Francisco Ferry Building,1,OA PM2,p_1276395,,1,,,,,,,,,,
19417,c_69270_b_80277_d_31,t_5568107_b_80277_tn_0,,San Francisco Ferry Building,1,SP PM,p_1276395,,1,,,,,,,,,,
19417,c_69270_b_80277_d_31,t_5568103_b_80277_tn_0,,San Francisco Ferry Building,1,SP AM,p_1276395,,1,,,,,,,,,,
19417,c_69270_b_80277_d_31,t_5568108_b_80277_tn_0,,San Francisco Ferry Building,1,SSF PM2,p_1276395,,1,,,,,,,,,,
19417,c_69270_b_80277_d_31,t_5568104_b_80277_tn_0,,San Francisco Ferry Building,1,SP AM,p_1276395,,1,,,,,,,,,,
19417,c_69270_b_80277_d_31,t_5568105_b_80277_tn_0,,San Francisco Ferry Building,1,SP AM,p_1276395,,1,,,,,,,,,,
"""

stop_times_csv = """
trip_id,arrival_time,departure_time,stop_id,stop_sequence,stop_headsign,pickup_type,drop_off_type,shape_dist_traveled,timepoint,start_service_area_id,end_service_area_id,start_service_area_radius,end_service_area_radius,continuous_pickup,continuous_drop_off,pickup_booking_rule_id,drop_off_booking_rule_id,start_pickup_drop_off_window,end_pickup_drop_off_window,mean_duration_factor,mean_duration_offset,safe_duration_factor,safe_duration_offset,tts_stop_headsign,min_arrival_time,max_departure_time
t_5567980_b_80277_tn_0,07:00:00,07:00:00,7207,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5567980_b_80277_tn_0,07:20:00,07:20:00,72012,2,,0,0,8823.6653714,1,,,,,1,1,,,,,,,,,,,
t_5567981_b_80277_tn_0,10:10:00,10:10:00,7207,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5567981_b_80277_tn_0,10:30:00,10:30:00,72012,2,,0,0,8823.6653714,1,,,,,1,1,,,,,,,,,,,
t_5567982_b_80277_tn_0,12:20:00,12:20:00,7208,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5567982_b_80277_tn_0,12:30:00,12:35:00,7209,2,,0,0,1514.88235720359,1,,,,,1,1,,,,,,,,,,,
t_5567982_b_80277_tn_0,13:00:00,13:00:00,72012,3,,0,0,11751.67690759,1,,,,,1,1,,,,,,,,,,,
t_5567983_b_80277_tn_0,15:00:00,15:00:00,72011,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5567983_b_80277_tn_0,15:35:00,15:35:00,7211,2,,0,0,16172.45960721,1,,,,,1,1,,,,,,,,,,,
t_5567984_b_80277_tn_0,08:35:00,08:35:00,72012,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5567984_b_80277_tn_0,09:00:00,09:00:00,7209,2,,0,0,10232.85652109,1,,,,,1,1,,,,,,,,,,,
t_5567985_b_80277_tn_0,14:05:00,14:05:00,72012,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5567985_b_80277_tn_0,14:30:00,14:30:00,7209,2,,0,0,10232.85652109,1,,,,,1,1,,,,,,,,,,,
t_5567986_b_80277_tn_0,15:15:00,15:15:00,72012,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5567986_b_80277_tn_0,15:40:00,15:40:00,7209,2,,0,0,10232.85652109,1,,,,,1,1,,,,,,,,,,,
t_5567987_b_80277_tn_0,05:15:00,05:15:00,7213,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5567987_b_80277_tn_0,05:20:00,05:30:00,7212,2,,0,0,654.85324880622,1,,,,,1,1,,,,,,,,,,,
t_5567987_b_80277_tn_0,06:30:00,06:30:00,72011,3,,0,0,45210.61910354,1,,,,,1,1,,,,,,,,,,,
t_5567988_b_80277_tn_0,05:45:00,05:45:00,7213,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5567988_b_80277_tn_0,05:50:00,06:00:00,7212,2,,0,0,654.85324880622,1,,,,,1,1,,,,,,,,,,,
t_5567988_b_80277_tn_0,07:00:00,07:00:00,72011,3,,0,0,45210.61910354,1,,,,,1,1,,,,,,,,,,,
t_5567989_b_80277_tn_0,16:45:00,16:45:00,7211,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5567989_b_80277_tn_0,17:20:00,17:20:00,72011,2,,0,0,16162.95419567,1,,,,,1,1,,,,,,,,,,,
t_5567990_b_80277_tn_0,13:40:00,13:40:00,7209,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5567990_b_80277_tn_0,13:50:00,13:55:00,7208,2,,0,0,1512.73427344327,1,,,,,1,1,,,,,,,,,,,
t_5567990_b_80277_tn_0,14:15:00,14:15:00,72012,3,,0,0,10468.93319248,1,,,,,1,1,,,,,,,,,,,
t_5567991_b_80277_tn_0,15:00:00,15:00:00,7209,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5567991_b_80277_tn_0,15:10:00,15:15:00,7208,2,,0,0,1512.73427344327,1,,,,,1,1,,,,,,,,,,,
t_5567991_b_80277_tn_0,15:35:00,15:35:00,72012,3,,0,0,10468.93319248,1,,,,,1,1,,,,,,,,,,,
t_5567992_b_80277_tn_0,07:45:00,07:45:00,7212,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5567992_b_80277_tn_0,08:45:00,08:45:00,72011,2,,0,0,44555.62718219,1,,,,,1,1,,,,,,,,,,,
t_5567993_b_80277_tn_0,11:05:00,11:05:00,72011,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5567993_b_80277_tn_0,12:05:00,12:10:00,7212,2,,0,0,44721.6497565864,1,,,,,1,1,,,,,,,,,,,
t_5567993_b_80277_tn_0,12:15:00,12:15:00,7213,3,,0,0,45332.71656957,1,,,,,1,1,,,,,,,,,,,
t_5567994_b_80277_tn_0,18:00:00,18:00:00,72011,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5567994_b_80277_tn_0,19:00:00,19:00:00,7212,2,,0,0,44721.64975656,1,,,,,1,1,,,,,,,,,,,
t_5567995_b_80277_tn_0,17:20:00,17:20:00,7205,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5567995_b_80277_tn_0,18:00:00,18:10:00,7209,2,,0,0,21765.5018380438,1,,,,,1,1,,,,,,,,,,,
t_5567995_b_80277_tn_0,18:20:00,18:20:00,7208,3,,0,0,23278.58121217,1,,,,,1,1,,,,,,,,,,,
t_5567996_b_80277_tn_0,08:15:00,08:15:00,7212,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5567996_b_80277_tn_0,09:15:00,09:15:00,72013,2,,0,0,44568.4799931,1,,,,,1,1,,,,,,,,,,,
t_5567997_b_80277_tn_0,15:40:00,15:40:00,72011,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5567997_b_80277_tn_0,16:40:00,16:40:00,7212,2,,0,0,44721.64975656,1,,,,,1,1,,,,,,,,,,,
t_5567998_b_80277_tn_0,13:55:00,13:55:00,72011,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5567998_b_80277_tn_0,14:55:00,14:55:00,7212,2,,0,0,44721.64975656,1,,,,,1,1,,,,,,,,,,,
t_5567999_b_80277_tn_0,17:20:00,17:20:00,72011,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5567999_b_80277_tn_0,18:20:00,18:25:00,7212,2,,0,0,44721.6497565864,1,,,,,1,1,,,,,,,,,,,
t_5567999_b_80277_tn_0,18:30:00,18:30:00,7213,3,,0,0,45332.71656957,1,,,,,1,1,,,,,,,,,,,
t_5568000_b_80277_tn_0,08:20:00,08:20:00,72011,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568000_b_80277_tn_0,09:20:00,09:20:00,7212,2,,0,0,44721.64975656,1,,,,,1,1,,,,,,,,,,,
t_5568001_b_80277_tn_0,16:35:00,16:35:00,72011,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568001_b_80277_tn_0,17:35:00,17:35:00,7212,2,,0,0,44721.64975656,1,,,,,1,1,,,,,,,,,,,
t_5568002_b_80277_tn_1,07:05:00,07:05:00,72011,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568002_b_80277_tn_1,08:05:00,08:05:00,7212,2,,0,0,44721.64975656,1,,,,,1,1,,,,,,,,,,,
t_5568003_b_80277_tn_0,06:35:00,06:35:00,72011,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568003_b_80277_tn_0,07:35:00,07:35:00,7212,2,,0,0,44721.64975656,1,,,,,1,1,,,,,,,,,,,
t_5568004_b_80277_tn_0,15:00:00,15:00:00,7212,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568004_b_80277_tn_0,16:00:00,16:00:00,72011,2,,0,0,44555.62718219,1,,,,,1,1,,,,,,,,,,,
t_5568005_b_80277_tn_0,07:00:00,07:00:00,7213,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568005_b_80277_tn_0,07:05:00,07:15:00,7212,2,,0,0,654.85324880622,1,,,,,1,1,,,,,,,,,,,
t_5568005_b_80277_tn_0,08:15:00,08:15:00,72011,3,,0,0,45210.61910354,1,,,,,1,1,,,,,,,,,,,
t_5568006_b_80277_tn_0,09:30:00,09:30:00,7212,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568006_b_80277_tn_0,10:30:00,10:30:00,72011,2,,0,0,44555.62718219,1,,,,,1,1,,,,,,,,,,,
t_5568007_b_80277_tn_0,11:00:00,11:00:00,7212,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568007_b_80277_tn_0,12:00:00,12:00:00,72011,2,,0,0,44555.62718219,1,,,,,1,1,,,,,,,,,,,
t_5568008_b_80277_tn_0,18:15:00,18:15:00,7208,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568008_b_80277_tn_0,18:25:00,18:35:00,7209,2,,0,0,1514.88235720359,1,,,,,1,1,,,,,,,,,,,
t_5568008_b_80277_tn_0,19:00:00,19:00:00,72012,3,,0,0,11751.67690759,1,,,,,1,1,,,,,,,,,,,
t_5568009_b_80277_tn_0,09:45:00,09:45:00,7208,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568009_b_80277_tn_0,09:55:00,10:05:00,7209,2,,0,0,1514.88235720359,1,,,,,1,1,,,,,,,,,,,
t_5568009_b_80277_tn_0,10:30:00,10:30:00,72012,3,,0,0,11751.67690759,1,,,,,1,1,,,,,,,,,,,
t_5568010_b_80277_tn_0,08:30:00,08:30:00,7208,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568010_b_80277_tn_0,08:40:00,08:50:00,7209,2,,0,0,1514.88235720359,1,,,,,1,1,,,,,,,,,,,
t_5568010_b_80277_tn_0,09:15:00,09:15:00,72012,3,,0,0,11751.67690759,1,,,,,1,1,,,,,,,,,,,
t_5568011_b_80277_tn_0,11:00:00,11:00:00,7208,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568011_b_80277_tn_0,11:10:00,11:20:00,7209,2,,0,0,1514.88235720359,1,,,,,1,1,,,,,,,,,,,
t_5568011_b_80277_tn_0,11:45:00,11:45:00,72012,3,,0,0,11751.67690759,1,,,,,1,1,,,,,,,,,,,
t_5568014_b_80277_tn_0,14:55:00,14:55:00,7208,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568014_b_80277_tn_0,15:05:00,15:15:00,7209,2,,0,0,1514.88235720359,1,,,,,1,1,,,,,,,,,,,
t_5568014_b_80277_tn_0,15:40:00,15:40:00,72012,3,,0,0,11751.67690759,1,,,,,1,1,,,,,,,,,,,
t_5568015_b_80277_tn_0,20:55:00,20:55:00,7208,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568015_b_80277_tn_0,21:05:00,21:10:00,7209,2,,0,0,1514.88235720359,1,,,,,1,1,,,,,,,,,,,
t_5568015_b_80277_tn_0,21:35:00,21:35:00,72012,3,,0,0,11751.67690759,1,,,,,1,1,,,,,,,,,,,
t_5568016_b_80277_tn_0,16:55:00,16:55:00,7208,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568016_b_80277_tn_0,17:05:00,17:15:00,7209,2,,0,0,1514.88235720359,1,,,,,1,1,,,,,,,,,,,
t_5568016_b_80277_tn_0,17:40:00,17:40:00,72012,3,,0,0,11751.67690759,1,,,,,1,1,,,,,,,,,,,
t_5568017_b_80277_tn_0,13:15:00,13:15:00,7208,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568017_b_80277_tn_0,13:25:00,13:35:00,7209,2,,0,0,1514.88235720359,1,,,,,1,1,,,,,,,,,,,
t_5568017_b_80277_tn_0,14:00:00,14:00:00,72012,3,,0,0,11751.67690759,1,,,,,1,1,,,,,,,,,,,
t_5568018_b_80277_tn_0,19:35:00,19:35:00,7208,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568018_b_80277_tn_0,19:45:00,19:55:00,7209,2,,0,0,1514.88235720359,1,,,,,1,1,,,,,,,,,,,
t_5568018_b_80277_tn_0,20:20:00,20:20:00,72012,3,,0,0,11751.67690759,1,,,,,1,1,,,,,,,,,,,
t_5568019_b_80277_tn_0,15:55:00,15:55:00,7208,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568019_b_80277_tn_0,16:05:00,16:15:00,7209,2,,0,0,1514.88235720359,1,,,,,1,1,,,,,,,,,,,
t_5568019_b_80277_tn_0,16:40:00,16:40:00,72012,3,,0,0,11751.67690759,1,,,,,1,1,,,,,,,,,,,
t_5568020_b_80277_tn_0,19:35:00,19:35:00,72012,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568020_b_80277_tn_0,20:00:00,20:05:00,7209,2,,0,0,10232.856521101,1,,,,,1,1,,,,,,,,,,,
t_5568020_b_80277_tn_0,20:15:00,20:15:00,7208,3,,0,0,11745.59079453,1,,,,,1,1,,,,,,,,,,,
t_5568021_b_80277_tn_0,20:00:00,20:00:00,72012,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568021_b_80277_tn_0,20:25:00,20:25:00,7209,2,,0,0,10232.85652109,1,,,,,1,1,,,,,,,,,,,
t_5568022_b_80277_tn_0,21:00:00,21:00:00,72011,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568022_b_80277_tn_0,22:00:00,22:10:00,7212,2,,0,0,44721.6497565864,1,,,,,1,1,,,,,,,,,,,
t_5568022_b_80277_tn_0,22:15:00,22:15:00,7213,3,,0,0,45332.71656957,1,,,,,1,1,,,,,,,,,,,
t_5568023_b_80277_tn_0,10:20:00,10:20:00,72011,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568023_b_80277_tn_0,11:20:00,11:20:00,7212,2,,0,0,44721.64975656,1,,,,,1,1,,,,,,,,,,,
t_5568024_b_80277_tn_0,14:40:00,14:40:00,72011,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568024_b_80277_tn_0,15:40:00,15:40:00,7212,2,,0,0,44721.64975656,1,,,,,1,1,,,,,,,,,,,
t_5568025_b_80277_tn_0,17:05:00,17:05:00,72011,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568025_b_80277_tn_0,18:05:00,18:10:00,7212,2,,0,0,44721.6497565864,1,,,,,1,1,,,,,,,,,,,
t_5568025_b_80277_tn_0,18:15:00,18:15:00,7213,3,,0,0,45332.71656957,1,,,,,1,1,,,,,,,,,,,
t_5568026_b_80277_tn_0,11:20:00,11:20:00,72011,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568026_b_80277_tn_0,12:20:00,12:20:00,7212,2,,0,0,44721.64975656,1,,,,,1,1,,,,,,,,,,,
t_5568027_b_80277_tn_0,13:40:00,13:40:00,72011,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568027_b_80277_tn_0,14:40:00,14:40:00,7212,2,,0,0,44721.64975656,1,,,,,1,1,,,,,,,,,,,
t_5568028_b_80277_tn_0,09:00:00,09:00:00,7213,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568028_b_80277_tn_0,09:05:00,09:15:00,7212,2,,0,0,654.85324880622,1,,,,,1,1,,,,,,,,,,,
t_5568028_b_80277_tn_0,10:15:00,10:15:00,72011,3,,0,0,45210.61910354,1,,,,,1,1,,,,,,,,,,,
t_5568029_b_80277_tn_0,15:20:00,15:20:00,7213,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568029_b_80277_tn_0,15:25:00,15:35:00,7212,2,,0,0,654.85324880622,1,,,,,1,1,,,,,,,,,,,
t_5568029_b_80277_tn_0,16:45:00,16:45:00,72011,3,,0,0,45210.61910354,1,,,,,1,1,,,,,,,,,,,
t_5568030_b_80277_tn_0,11:30:00,11:30:00,7212,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568030_b_80277_tn_0,12:30:00,12:30:00,72011,2,,0,0,44555.62718219,1,,,,,1,1,,,,,,,,,,,
t_5568031_b_80277_tn_0,12:30:00,12:30:00,7212,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568031_b_80277_tn_0,13:30:00,13:30:00,72011,2,,0,0,44555.62718219,1,,,,,1,1,,,,,,,,,,,
t_5568032_b_80277_tn_0,14:45:00,14:45:00,7212,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568032_b_80277_tn_0,15:55:00,15:55:00,72011,2,,0,0,44555.62718219,1,,,,,1,1,,,,,,,,,,,
t_5568033_b_80277_tn_0,15:45:00,15:45:00,7212,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568033_b_80277_tn_0,16:55:00,16:55:00,72011,2,,0,0,44555.62718219,1,,,,,1,1,,,,,,,,,,,
t_5568034_b_80277_tn_0,10:00:00,10:00:00,7213,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568034_b_80277_tn_0,10:05:00,10:15:00,7212,2,,0,0,654.85324880622,1,,,,,1,1,,,,,,,,,,,
t_5568034_b_80277_tn_0,11:15:00,11:15:00,72011,3,,0,0,45210.61910354,1,,,,,1,1,,,,,,,,,,,
t_5568035_b_80277_tn_0,12:50:00,12:50:00,72012,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568035_b_80277_tn_0,13:10:00,13:10:00,7208,2,,0,0,8975.40000977,1,,,,,1,1,,,,,,,,,,,
t_5568036_b_80277_tn_0,15:30:00,15:30:00,72012,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568036_b_80277_tn_0,15:50:00,15:50:00,7208,2,,0,0,8975.40000977,1,,,,,1,1,,,,,,,,,,,
t_5568037_b_80277_tn_0,10:35:00,10:35:00,72012,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568037_b_80277_tn_0,10:55:00,10:55:00,7208,2,,0,0,8975.40000977,1,,,,,1,1,,,,,,,,,,,
t_5568038_b_80277_tn_0,09:20:00,09:20:00,72012,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568038_b_80277_tn_0,09:40:00,09:40:00,7208,2,,0,0,8975.40000977,1,,,,,1,1,,,,,,,,,,,
t_5568039_b_80277_tn_0,17:50:00,17:50:00,72012,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568039_b_80277_tn_0,18:10:00,18:10:00,7208,2,,0,0,8975.40000977,1,,,,,1,1,,,,,,,,,,,
t_5568040_b_80277_tn_0,19:10:00,19:10:00,72012,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568040_b_80277_tn_0,19:30:00,19:30:00,7208,2,,0,0,8975.40000977,1,,,,,1,1,,,,,,,,,,,
t_5568041_b_80277_tn_0,16:30:00,16:30:00,72012,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568041_b_80277_tn_0,16:50:00,16:50:00,7208,2,,0,0,8975.40000977,1,,,,,1,1,,,,,,,,,,,
t_5568042_b_80277_tn_0,17:00:00,17:00:00,72012,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568042_b_80277_tn_0,17:20:00,17:20:00,7208,2,,0,0,8975.40000977,1,,,,,1,1,,,,,,,,,,,
t_5568043_b_80277_tn_0,20:30:00,20:30:00,72012,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568043_b_80277_tn_0,20:50:00,20:50:00,7208,2,,0,0,8975.40000977,1,,,,,1,1,,,,,,,,,,,
t_5568044_b_80277_tn_0,11:30:00,11:30:00,72012,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568044_b_80277_tn_0,11:50:00,11:50:00,7208,2,,0,0,8975.40000977,1,,,,,1,1,,,,,,,,,,,
t_5568045_b_80277_tn_0,13:45:00,13:45:00,72012,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568045_b_80277_tn_0,14:05:00,14:05:00,7208,2,,0,0,8975.40000977,1,,,,,1,1,,,,,,,,,,,
t_5568046_b_80277_tn_0,14:30:00,14:30:00,72012,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568046_b_80277_tn_0,14:50:00,14:50:00,7208,2,,0,0,8975.40000977,1,,,,,1,1,,,,,,,,,,,
t_5568047_b_80277_tn_0,10:55:00,10:55:00,7209,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568047_b_80277_tn_0,11:20:00,11:20:00,72012,2,,0,0,10236.7945504,1,,,,,1,1,,,,,,,,,,,
t_5568048_b_80277_tn_0,16:30:00,16:30:00,72013,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568048_b_80277_tn_0,17:05:00,17:05:00,7211,2,,0,0,16190.53076818,1,,,,,1,1,,,,,,,,,,,
t_5568049_b_80277_tn_0,18:00:00,18:00:00,72013,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568049_b_80277_tn_0,18:35:00,18:35:00,7211,2,,0,0,16190.53076818,1,,,,,1,1,,,,,,,,,,,
t_5568050_b_80277_tn_0,11:15:00,11:15:00,72013,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568050_b_80277_tn_0,11:50:00,11:50:00,7211,2,,0,0,16190.53076818,1,,,,,1,1,,,,,,,,,,,
t_5568051_b_80277_tn_0,14:05:00,14:05:00,72013,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568051_b_80277_tn_0,14:40:00,14:40:00,7211,2,,0,0,16190.53076818,1,,,,,1,1,,,,,,,,,,,
t_5568052_b_80277_tn_0,20:10:00,20:10:00,72013,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568052_b_80277_tn_0,20:45:00,20:45:00,7211,2,,0,0,16190.53076818,1,,,,,1,1,,,,,,,,,,,
t_5568053_b_80277_tn_0,09:50:00,09:50:00,7211,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568053_b_80277_tn_0,10:25:00,10:25:00,72013,2,,0,0,16183.16748101,1,,,,,1,1,,,,,,,,,,,
t_5568054_b_80277_tn_0,08:00:00,08:00:00,72013,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568054_b_80277_tn_0,08:25:00,08:25:00,7206,2,,0,0,13947.99011217,1,,,,,1,1,,,,,,,,,,,
t_5568055_b_80277_tn_0,07:00:00,07:00:00,72013,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568055_b_80277_tn_0,07:25:00,07:25:00,7206,2,,0,0,13947.99011217,1,,,,,1,1,,,,,,,,,,,
t_5568056_b_80277_tn_0,08:30:00,08:30:00,7206,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568056_b_80277_tn_0,08:55:00,08:55:00,72013,2,,0,0,13944.28765468,1,,,,,1,1,,,,,,,,,,,
t_5568057_b_80277_tn_0,07:30:00,07:30:00,7206,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568057_b_80277_tn_0,07:55:00,07:55:00,72013,2,,0,0,13944.28765468,1,,,,,1,1,,,,,,,,,,,
t_5568058_b_80277_tn_0,06:30:00,06:30:00,7206,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568058_b_80277_tn_0,06:55:00,06:55:00,72013,2,,0,0,13944.28765468,1,,,,,1,1,,,,,,,,,,,
t_5568059_b_80277_tn_0,09:30:00,09:30:00,7206,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568059_b_80277_tn_0,09:55:00,09:55:00,72013,2,,0,0,13944.28765468,1,,,,,1,1,,,,,,,,,,,
t_5568060_b_80277_tn_0,11:15:00,11:15:00,7206,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568060_b_80277_tn_0,11:40:00,11:40:00,72013,2,,0,0,13944.28765468,1,,,,,1,1,,,,,,,,,,,
t_5568061_b_80277_tn_0,11:20:00,11:20:00,72012,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568061_b_80277_tn_0,11:40:00,11:40:00,7208,2,,0,0,8975.40000977,1,,,,,1,1,,,,,,,,,,,
t_5568062_b_80277_tn_0,06:30:00,06:30:00,7209,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568062_b_80277_tn_0,06:55:00,06:55:00,72012,2,,0,0,10236.7945504,1,,,,,1,1,,,,,,,,,,,
t_5568063_b_80277_tn_0,16:00:00,16:00:00,72011,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568063_b_80277_tn_0,16:35:00,16:35:00,7211,2,,0,0,16172.45960721,1,,,,,1,1,,,,,,,,,,,
t_5568064_b_80277_tn_0,19:00:00,19:00:00,72011,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568064_b_80277_tn_0,19:35:00,19:35:00,7211,2,,0,0,16172.45960721,1,,,,,1,1,,,,,,,,,,,
t_5568065_b_80277_tn_0,10:25:00,10:25:00,72011,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568065_b_80277_tn_0,11:00:00,11:00:00,7211,2,,0,0,16172.45960721,1,,,,,1,1,,,,,,,,,,,
t_5568066_b_80277_tn_0,06:30:00,06:30:00,7211,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568066_b_80277_tn_0,07:05:00,07:05:00,72011,2,,0,0,16162.95419567,1,,,,,1,1,,,,,,,,,,,
t_5568067_b_80277_tn_0,10:40:00,10:40:00,7211,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568067_b_80277_tn_0,11:15:00,11:15:00,72011,2,,0,0,16162.95419567,1,,,,,1,1,,,,,,,,,,,
t_5568068_b_80277_tn_0,11:00:00,11:00:00,7209,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568068_b_80277_tn_0,11:25:00,11:25:00,72013,2,,0,0,10213.77463864,1,,,,,1,1,,,,,,,,,,,
t_5568069_b_80277_tn_0,12:10:00,12:10:00,72011,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568069_b_80277_tn_0,13:10:00,13:15:00,7212,2,,0,0,44721.6497565864,1,,,,,1,1,,,,,,,,,,,
t_5568069_b_80277_tn_0,13:20:00,13:20:00,7213,3,,0,0,45332.71656957,1,,,,,1,1,,,,,,,,,,,
t_5568070_b_80277_tn_0,21:40:00,21:40:00,72012,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568070_b_80277_tn_0,22:00:00,22:05:00,7208,2,,0,0,8975.40000973017,1,,,,,1,1,,,,,,,,,,,
t_5568070_b_80277_tn_0,22:15:00,22:15:00,7209,3,,0,0,10490.57967383,1,,,,,1,1,,,,,,,,,,,
t_5568071_b_80277_tn_0,17:25:00,17:25:00,72011,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568071_b_80277_tn_0,18:00:00,18:00:00,7211,2,,0,0,16172.45960721,1,,,,,1,1,,,,,,,,,,,
t_5568072_b_80277_tn_0,09:50:00,09:50:00,72011,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568072_b_80277_tn_0,10:50:00,10:50:00,7212,2,,0,0,44721.64975656,1,,,,,1,1,,,,,,,,,,,
t_5568073_b_80277_tn_0,18:10:00,18:10:00,7211,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568073_b_80277_tn_0,18:45:00,18:45:00,72011,2,,0,0,16162.95419567,1,,,,,1,1,,,,,,,,,,,
t_5568074_b_80277_tn_0,11:30:00,11:30:00,72011,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568074_b_80277_tn_0,12:30:00,12:35:00,7212,2,,0,0,44721.6497565864,1,,,,,1,1,,,,,,,,,,,
t_5568074_b_80277_tn_0,12:40:00,12:40:00,7213,3,,0,0,45332.71656957,1,,,,,1,1,,,,,,,,,,,
t_5568075_b_80277_tn_0,19:45:00,19:45:00,72011,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568075_b_80277_tn_0,20:45:00,20:50:00,7212,2,,0,0,44721.6497565864,1,,,,,1,1,,,,,,,,,,,
t_5568075_b_80277_tn_0,20:55:00,20:55:00,7213,3,,0,0,45332.71656957,1,,,,,1,1,,,,,,,,,,,
t_5568076_b_80277_tn_0,20:25:00,20:25:00,7211,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568076_b_80277_tn_0,21:00:00,21:00:00,72013,2,,0,0,16183.16748101,1,,,,,1,1,,,,,,,,,,,
t_5568077_b_80277_tn_0,16:45:00,16:45:00,7212,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568077_b_80277_tn_0,17:50:00,17:50:00,72011,2,,0,0,44555.62718219,1,,,,,1,1,,,,,,,,,,,
t_5568078_b_80277_tn_0,16:05:00,16:05:00,72011,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568078_b_80277_tn_0,17:05:00,17:10:00,7212,2,,0,0,44721.6497565864,1,,,,,1,1,,,,,,,,,,,
t_5568078_b_80277_tn_0,17:15:00,17:15:00,7213,3,,0,0,45332.71656957,1,,,,,1,1,,,,,,,,,,,
t_5568079_b_80277_tn_0,18:30:00,18:30:00,72011,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568079_b_80277_tn_0,19:30:00,19:30:00,7212,2,,0,0,44721.64975656,1,,,,,1,1,,,,,,,,,,,
t_5568080_b_80277_tn_0,19:40:00,19:40:00,7212,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568080_b_80277_tn_0,20:50:00,20:50:00,72011,2,,0,0,44555.62718219,1,,,,,1,1,,,,,,,,,,,
t_5568081_b_80277_tn_0,10:45:00,10:45:00,72013,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568081_b_80277_tn_0,11:10:00,11:10:00,7206,2,,0,0,13947.99011217,1,,,,,1,1,,,,,,,,,,,
t_5568082_b_80277_tn_0,16:25:00,16:25:00,72012,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568082_b_80277_tn_0,16:50:00,16:50:00,7209,2,,0,0,10232.85652109,1,,,,,1,1,,,,,,,,,,,
t_5568083_b_80277_tn_0,10:25:00,10:25:00,72012,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568083_b_80277_tn_0,10:50:00,10:50:00,7209,2,,0,0,10232.85652109,1,,,,,1,1,,,,,,,,,,,
t_5568084_b_80277_tn_0,13:10:00,13:10:00,72012,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568084_b_80277_tn_0,13:35:00,13:35:00,7209,2,,0,0,10232.85652109,1,,,,,1,1,,,,,,,,,,,
t_5568085_b_80277_tn_0,14:25:00,14:25:00,72012,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568085_b_80277_tn_0,14:50:00,14:50:00,7209,2,,0,0,10232.85652109,1,,,,,1,1,,,,,,,,,,,
t_5568086_b_80277_tn_0,17:25:00,17:25:00,72012,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568086_b_80277_tn_0,17:50:00,17:50:00,7209,2,,0,0,10232.85652109,1,,,,,1,1,,,,,,,,,,,
t_5568087_b_80277_tn_0,18:25:00,18:25:00,72012,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568087_b_80277_tn_0,18:50:00,18:50:00,7209,2,,0,0,10232.85652109,1,,,,,1,1,,,,,,,,,,,
t_5568088_b_80277_tn_0,08:00:00,08:00:00,7208,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568088_b_80277_tn_0,08:10:00,08:20:00,7209,2,,0,0,1514.88235720359,1,,,,,1,1,,,,,,,,,,,
t_5568088_b_80277_tn_0,09:00:00,09:00:00,7205,3,,0,0,23281.24861724,1,,,,,1,1,,,,,,,,,,,
t_5568089_b_80277_tn_0,16:10:00,16:10:00,7209,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568089_b_80277_tn_0,16:20:00,16:25:00,7208,2,,0,0,1512.73427344327,1,,,,,1,1,,,,,,,,,,,
t_5568089_b_80277_tn_0,17:05:00,17:05:00,7205,3,,0,0,21952.44904625,1,,,,,1,1,,,,,,,,,,,
t_5568090_b_80277_tn_0,16:30:00,16:30:00,72013,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568090_b_80277_tn_0,16:50:00,16:50:00,7207,2,,0,0,8881.09374369,1,,,,,1,1,,,,,,,,,,,
t_5568091_b_80277_tn_0,09:25:00,09:25:00,72012,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568091_b_80277_tn_0,09:45:00,09:45:00,7208,2,,0,0,8975.40000977,1,,,,,1,1,,,,,,,,,,,
t_5568092_b_80277_tn_0,20:25:00,20:25:00,72013,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568092_b_80277_tn_0,20:45:00,20:45:00,7207,2,,0,0,8881.09374369,1,,,,,1,1,,,,,,,,,,,
t_5568093_b_80277_tn_0,06:55:00,06:55:00,72013,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568093_b_80277_tn_0,07:15:00,07:15:00,7207,2,,0,0,8881.09374369,1,,,,,1,1,,,,,,,,,,,
t_5568094_b_80277_tn_0,17:00:00,17:00:00,7207,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568094_b_80277_tn_0,17:20:00,17:20:00,72012,2,,0,0,8823.6653714,1,,,,,1,1,,,,,,,,,,,
t_5568095_b_80277_tn_0,09:15:00,09:15:00,7207,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568095_b_80277_tn_0,09:35:00,09:35:00,72012,2,,0,0,8823.6653714,1,,,,,1,1,,,,,,,,,,,
t_5568096_b_80277_tn_0,18:50:00,18:50:00,7207,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568096_b_80277_tn_0,19:10:00,19:10:00,72012,2,,0,0,8823.6653714,1,,,,,1,1,,,,,,,,,,,
t_5568097_b_80277_tn_0,07:50:00,07:50:00,72013,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568097_b_80277_tn_0,08:10:00,08:10:00,7207,2,,0,0,8881.09374369,1,,,,,1,1,,,,,,,,,,,
t_5568098_b_80277_tn_0,19:00:00,19:00:00,72013,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568098_b_80277_tn_0,19:20:00,19:20:00,7207,2,,0,0,8881.09374369,1,,,,,1,1,,,,,,,,,,,
t_5568099_b_80277_tn_0,18:25:00,18:25:00,72013,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568099_b_80277_tn_0,18:45:00,18:45:00,7207,2,,0,0,8881.09374369,1,,,,,1,1,,,,,,,,,,,
t_5568100_b_80277_tn_0,17:30:00,17:30:00,72013,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568100_b_80277_tn_0,17:50:00,17:50:00,7207,2,,0,0,8881.09374369,1,,,,,1,1,,,,,,,,,,,
t_5568101_b_80277_tn_0,08:45:00,08:45:00,72013,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568101_b_80277_tn_0,09:05:00,09:05:00,7207,2,,0,0,8881.09374369,1,,,,,1,1,,,,,,,,,,,
t_5568102_b_80277_tn_0,15:30:00,15:30:00,72013,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568102_b_80277_tn_0,15:50:00,15:50:00,7207,2,,0,0,8881.09374369,1,,,,,1,1,,,,,,,,,,,
t_5568103_b_80277_tn_0,06:30:00,06:30:00,7207,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568103_b_80277_tn_0,06:50:00,06:50:00,72013,2,,0,0,8844.20040293,1,,,,,1,1,,,,,,,,,,,
t_5568104_b_80277_tn_0,07:25:00,07:25:00,7207,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568104_b_80277_tn_0,07:45:00,07:45:00,72013,2,,0,0,8844.20040293,1,,,,,1,1,,,,,,,,,,,
t_5568105_b_80277_tn_0,08:20:00,08:20:00,7207,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568105_b_80277_tn_0,08:40:00,08:40:00,72013,2,,0,0,8844.20040293,1,,,,,1,1,,,,,,,,,,,
t_5568106_b_80277_tn_0,16:00:00,16:00:00,7207,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568106_b_80277_tn_0,16:20:00,16:20:00,72013,2,,0,0,8844.20040293,1,,,,,1,1,,,,,,,,,,,
t_5568107_b_80277_tn_0,18:00:00,18:00:00,7207,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568107_b_80277_tn_0,18:20:00,18:20:00,72013,2,,0,0,8844.20040293,1,,,,,1,1,,,,,,,,,,,
t_5568108_b_80277_tn_0,20:25:00,20:25:00,7207,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568108_b_80277_tn_0,20:45:00,20:45:00,72013,2,,0,0,8844.20040293,1,,,,,1,1,,,,,,,,,,,
t_5568109_b_80277_tn_0,11:45:00,11:45:00,7208,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568109_b_80277_tn_0,11:55:00,12:05:00,7209,2,,0,0,1514.88235720359,1,,,,,1,1,,,,,,,,,,,
t_5568109_b_80277_tn_0,12:30:00,12:30:00,72013,3,,0,0,11728.65699583,1,,,,,1,1,,,,,,,,,,,
t_5568110_b_80277_tn_0,15:50:00,15:50:00,7209,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568110_b_80277_tn_0,16:00:00,16:05:00,7208,2,,0,0,1512.73427344327,1,,,,,1,1,,,,,,,,,,,
t_5568110_b_80277_tn_0,16:25:00,16:25:00,72011,3,,0,0,10497.7056272,1,,,,,1,1,,,,,,,,,,,
t_5568111_b_80277_tn_0,10:40:00,10:40:00,7208,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568111_b_80277_tn_0,11:00:00,11:00:00,72013,2,,0,0,8947.43468582,1,,,,,1,1,,,,,,,,,,,
t_5568112_b_80277_tn_0,12:50:00,12:50:00,7212,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568112_b_80277_tn_0,13:50:00,13:50:00,72011,2,,0,0,44555.62718219,1,,,,,1,1,,,,,,,,,,,
t_5568113_b_80277_tn_0,07:10:00,07:10:00,7205,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568113_b_80277_tn_0,07:50:00,07:50:00,7208,2,,0,0,20446.48975581,1,,,,,1,1,,,,,,,,,,,
t_5568114_b_80277_tn_0,06:05:00,06:05:00,7208,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568114_b_80277_tn_0,06:15:00,06:20:00,7209,2,,0,0,1514.88235720359,1,,,,,1,1,,,,,,,,,,,
t_5568114_b_80277_tn_0,07:00:00,07:00:00,7205,3,,0,0,23281.24861724,1,,,,,1,1,,,,,,,,,,,
t_5568115_b_80277_tn_0,07:05:00,07:05:00,7208,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568115_b_80277_tn_0,07:15:00,07:20:00,7209,2,,0,0,1514.88235720359,1,,,,,1,1,,,,,,,,,,,
t_5568115_b_80277_tn_0,08:00:00,08:00:00,7205,3,,0,0,23281.24861724,1,,,,,1,1,,,,,,,,,,,
t_5568116_b_80277_tn_0,09:00:00,09:00:00,72013,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568116_b_80277_tn_0,09:25:00,09:25:00,7206,2,,0,0,13947.99011217,1,,,,,1,1,,,,,,,,,,,
t_5568117_b_80277_tn_0,13:25:00,13:25:00,72013,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568117_b_80277_tn_0,13:50:00,13:50:00,7206,2,,0,0,13947.99011217,1,,,,,1,1,,,,,,,,,,,
t_5568118_b_80277_tn_0,17:40:00,17:40:00,72013,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568118_b_80277_tn_0,18:05:00,18:05:00,7206,2,,0,0,13947.99011217,1,,,,,1,1,,,,,,,,,,,
t_5568119_b_80277_tn_0,15:40:00,15:40:00,72013,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568119_b_80277_tn_0,16:05:00,16:05:00,7206,2,,0,0,13947.99011217,1,,,,,1,1,,,,,,,,,,,
t_5568120_b_80277_tn_0,16:40:00,16:40:00,72013,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568120_b_80277_tn_0,17:05:00,17:05:00,7206,2,,0,0,13947.99011217,1,,,,,1,1,,,,,,,,,,,
t_5568121_b_80277_tn_0,18:40:00,18:40:00,72013,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568121_b_80277_tn_0,19:05:00,19:05:00,7206,2,,0,0,13947.99011217,1,,,,,1,1,,,,,,,,,,,
t_5568122_b_80277_tn_0,17:10:00,17:10:00,7206,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568122_b_80277_tn_0,17:35:00,17:35:00,72013,2,,0,0,13944.28765468,1,,,,,1,1,,,,,,,,,,,
t_5568123_b_80277_tn_0,19:55:00,19:55:00,7206,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568123_b_80277_tn_0,20:20:00,20:20:00,72013,2,,0,0,13944.28765468,1,,,,,1,1,,,,,,,,,,,
t_5568124_b_80277_tn_0,10:20:00,10:20:00,7206,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568124_b_80277_tn_0,10:45:00,10:45:00,72013,2,,0,0,13944.28765468,1,,,,,1,1,,,,,,,,,,,
t_5568125_b_80277_tn_0,16:10:00,16:10:00,7206,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568125_b_80277_tn_0,16:35:00,16:35:00,72013,2,,0,0,13944.28765468,1,,,,,1,1,,,,,,,,,,,
t_5568126_b_80277_tn_0,18:10:00,18:10:00,7206,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568126_b_80277_tn_0,18:35:00,18:35:00,72013,2,,0,0,13944.28765468,1,,,,,1,1,,,,,,,,,,,
t_5568127_b_80277_tn_0,10:15:00,10:15:00,72012,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568127_b_80277_tn_0,10:35:00,10:35:00,7208,2,,0,0,8975.40000977,1,,,,,1,1,,,,,,,,,,,
t_5568128_b_80277_tn_0,07:05:00,07:05:00,72012,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568128_b_80277_tn_0,07:30:00,07:30:00,7209,2,,0,0,10232.85652109,1,,,,,1,1,,,,,,,,,,,
t_5568129_b_80277_tn_0,07:30:00,07:30:00,72012,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568129_b_80277_tn_0,07:55:00,07:55:00,7209,2,,0,0,10232.85652109,1,,,,,1,1,,,,,,,,,,,
t_5568130_b_80277_tn_0,08:10:00,08:10:00,72012,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568130_b_80277_tn_0,08:35:00,08:35:00,7209,2,,0,0,10232.85652109,1,,,,,1,1,,,,,,,,,,,
t_5568131_b_80277_tn_0,17:55:00,17:55:00,7209,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568131_b_80277_tn_0,18:05:00,18:10:00,7208,2,,0,0,1512.73427344327,1,,,,,1,1,,,,,,,,,,,
t_5568131_b_80277_tn_0,18:30:00,18:30:00,72012,3,,0,0,10468.93319248,1,,,,,1,1,,,,,,,,,,,
t_5568132_b_80277_tn_0,08:40:00,08:40:00,7209,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568132_b_80277_tn_0,09:05:00,09:05:00,72011,2,,0,0,10230.93080044,1,,,,,1,1,,,,,,,,,,,
t_5568133_b_80277_tn_0,20:30:00,20:30:00,7209,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568133_b_80277_tn_0,20:40:00,20:45:00,7208,2,,0,0,1512.73427344327,1,,,,,1,1,,,,,,,,,,,
t_5568133_b_80277_tn_0,21:05:00,21:05:00,72012,3,,0,0,10468.93319248,1,,,,,1,1,,,,,,,,,,,
t_5568134_b_80277_tn_0,08:00:00,08:00:00,7209,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568134_b_80277_tn_0,08:25:00,08:25:00,72012,2,,0,0,10236.7945504,1,,,,,1,1,,,,,,,,,,,
t_5568135_b_80277_tn_0,07:35:00,07:35:00,7209,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568135_b_80277_tn_0,08:00:00,08:00:00,72012,2,,0,0,10236.7945504,1,,,,,1,1,,,,,,,,,,,
t_5568136_b_80277_tn_0,16:55:00,16:55:00,7209,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568136_b_80277_tn_0,17:20:00,17:20:00,72012,2,,0,0,10236.7945504,1,,,,,1,1,,,,,,,,,,,
t_5568137_b_80277_tn_0,18:55:00,18:55:00,7209,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568137_b_80277_tn_0,19:05:00,19:10:00,7208,2,,0,0,1512.73427344327,1,,,,,1,1,,,,,,,,,,,
t_5568137_b_80277_tn_0,19:30:00,19:30:00,72012,3,,0,0,10468.93319248,1,,,,,1,1,,,,,,,,,,,
t_5568138_b_80277_tn_0,07:15:00,07:15:00,72011,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568138_b_80277_tn_0,07:50:00,07:50:00,7211,2,,0,0,16172.45960721,1,,,,,1,1,,,,,,,,,,,
t_5568139_b_80277_tn_0,18:00:00,18:00:00,72011,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568139_b_80277_tn_0,18:35:00,18:35:00,7211,2,,0,0,16172.45960721,1,,,,,1,1,,,,,,,,,,,
t_5568140_b_80277_tn_0,20:05:00,20:05:00,72011,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568140_b_80277_tn_0,20:40:00,20:40:00,7211,2,,0,0,16172.45960721,1,,,,,1,1,,,,,,,,,,,
t_5568141_b_80277_tn_0,09:00:00,09:00:00,7211,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568141_b_80277_tn_0,09:35:00,09:35:00,72011,2,,0,0,16162.95419567,1,,,,,1,1,,,,,,,,,,,
t_5568142_b_80277_tn_0,15:40:00,15:40:00,7211,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568142_b_80277_tn_0,16:15:00,16:15:00,72011,2,,0,0,16162.95419567,1,,,,,1,1,,,,,,,,,,,
t_5568143_b_80277_tn_0,19:25:00,19:25:00,7211,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568143_b_80277_tn_0,20:00:00,20:00:00,72011,2,,0,0,16162.95419567,1,,,,,1,1,,,,,,,,,,,
t_5568144_b_80277_tn_0,12:00:00,12:00:00,7211,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568144_b_80277_tn_0,12:35:00,12:35:00,72013,2,,0,0,16183.16748101,1,,,,,1,1,,,,,,,,,,,
t_5568145_b_80277_tn_0,17:15:00,17:15:00,7211,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568145_b_80277_tn_0,17:50:00,17:50:00,72013,2,,0,0,16183.16748101,1,,,,,1,1,,,,,,,,,,,
t_5568146_b_80277_tn_0,18:45:00,18:45:00,7211,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568146_b_80277_tn_0,19:20:00,19:20:00,72013,2,,0,0,16183.16748101,1,,,,,1,1,,,,,,,,,,,
t_5568147_b_80277_tn_0,14:35:00,14:35:00,7209,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568147_b_80277_tn_0,14:45:00,14:50:00,7208,2,,0,0,1512.73427344327,1,,,,,1,1,,,,,,,,,,,
t_5568147_b_80277_tn_0,15:10:00,15:10:00,72012,3,,0,0,10468.93319248,1,,,,,1,1,,,,,,,,,,,
t_5568148_b_80277_tn_0,07:30:00,07:30:00,7211,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568148_b_80277_tn_0,08:05:00,08:05:00,72011,2,,0,0,16162.95419567,1,,,,,1,1,,,,,,,,,,,
t_5568149_b_80277_tn_0,17:10:00,17:10:00,7211,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568149_b_80277_tn_0,17:45:00,17:45:00,72011,2,,0,0,16162.95419567,1,,,,,1,1,,,,,,,,,,,
t_5568150_b_80277_tn_0,16:30:00,16:30:00,72011,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568150_b_80277_tn_0,17:05:00,17:05:00,7211,2,,0,0,16172.45960721,1,,,,,1,1,,,,,,,,,,,
t_5568151_b_80277_tn_0,15:20:00,15:20:00,7205,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568151_b_80277_tn_0,16:00:00,16:00:00,7209,2,,0,0,21765.50183801,1,,,,,1,1,,,,,,,,,,,
t_5568152_b_80277_tn_0,16:20:00,16:20:00,7205,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568152_b_80277_tn_0,17:00:00,17:10:00,7209,2,,0,0,21765.5018380438,1,,,,,1,1,,,,,,,,,,,
t_5568152_b_80277_tn_0,17:20:00,17:20:00,7208,3,,0,0,23278.58121217,1,,,,,1,1,,,,,,,,,,,
t_5568153_b_80277_tn_0,09:05:00,09:05:00,7209,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568153_b_80277_tn_0,09:30:00,09:30:00,72013,2,,0,0,10213.77463864,1,,,,,1,1,,,,,,,,,,,
t_5568154_b_80277_tn_0,09:40:00,09:40:00,72013,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568154_b_80277_tn_0,10:00:00,10:00:00,7207,2,,0,0,8881.09374369,1,,,,,1,1,,,,,,,,,,,
t_5568155_b_80277_tn_0,11:50:00,11:50:00,72013,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568155_b_80277_tn_0,12:15:00,12:15:00,7206,2,,0,0,13947.99011217,1,,,,,1,1,,,,,,,,,,,
t_5568156_b_80277_tn_0,12:20:00,12:20:00,7206,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568156_b_80277_tn_0,12:45:00,12:45:00,72013,2,,0,0,13944.28765468,1,,,,,1,1,,,,,,,,,,,
t_5568158_b_80277_tn_0,08:00:00,08:00:00,7211,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568158_b_80277_tn_0,08:35:00,08:35:00,72012,2,,0,0,16121.04430654,1,,,,,1,1,,,,,,,,,,,
t_5568159_b_80277_tn_0,09:00:00,09:00:00,7206,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568159_b_80277_tn_0,09:25:00,09:25:00,72012,2,,0,0,13944.51777084,1,,,,,1,1,,,,,,,,,,,
t_5568160_b_80277_tn_0,13:45:00,13:45:00,7213,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568160_b_80277_tn_0,13:50:00,13:55:00,7212,2,,0,0,654.85324880622,1,,,,,1,1,,,,,,,,,,,
t_5568160_b_80277_tn_0,15:05:00,15:05:00,72012,3,,0,0,45255.83019891,1,,,,,1,1,,,,,,,,,,,
t_5568161_b_80277_tn_0,15:35:00,15:35:00,7207,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568161_b_80277_tn_0,15:55:00,15:55:00,72011,2,,0,0,9491.65937183,1,,,,,1,1,,,,,,,,,,,
t_5568162_b_80277_tn_0,11:00:00,11:00:00,7207,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568162_b_80277_tn_0,11:20:00,11:20:00,72013,2,,0,0,8844.20040293,1,,,,,1,1,,,,,,,,,,,
t_5568163_b_80277_tn_0,12:00:00,12:00:00,7207,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568163_b_80277_tn_0,12:20:00,12:20:00,72013,2,,0,0,8844.20040293,1,,,,,1,1,,,,,,,,,,,
t_5568164_b_80277_tn_0,13:00:00,13:00:00,7207,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568164_b_80277_tn_0,13:20:00,13:20:00,72013,2,,0,0,8844.20040293,1,,,,,1,1,,,,,,,,,,,
t_5568165_b_80277_tn_0,10:35:00,10:35:00,72013,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568165_b_80277_tn_0,10:55:00,10:55:00,7207,2,,0,0,8881.09374369,1,,,,,1,1,,,,,,,,,,,
t_5568166_b_80277_tn_0,22:20:00,22:20:00,72013,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568166_b_80277_tn_0,22:40:00,22:40:00,7207,2,,0,0,8881.09374369,1,,,,,1,1,,,,,,,,,,,
t_5568167_b_80277_tn_0,11:35:00,11:35:00,72013,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568167_b_80277_tn_0,11:55:00,11:55:00,7207,2,,0,0,8881.09374369,1,,,,,1,1,,,,,,,,,,,
t_5568169_b_80277_tn_0,13:00:00,13:00:00,72013,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568169_b_80277_tn_0,13:20:00,13:20:00,7207,2,,0,0,8881.09374369,1,,,,,1,1,,,,,,,,,,,
t_5568170_b_80277_tn_0,13:45:00,13:45:00,7210,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568170_b_80277_tn_0,13:55:00,13:55:00,72013,2,,0,0,3940.63770072,1,,,,,1,1,,,,,,,,,,,
t_5568171_b_80277_tn_0,13:25:00,13:25:00,72013,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568171_b_80277_tn_0,13:35:00,13:35:00,7210,2,,0,0,3935.11278675,1,,,,,1,1,,,,,,,,,,,
t_5568172_b_80277_tn_0,18:10:00,18:10:00,7210,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568172_b_80277_tn_0,18:20:00,18:20:00,72011,2,,0,0,3997.85926002,1,,,,,1,1,,,,,,,,,,,
t_5568173_b_80277_tn_0,10:55:00,10:55:00,7210,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568173_b_80277_tn_0,11:05:00,11:05:00,72013,2,,0,0,3940.63770072,1,,,,,1,1,,,,,,,,,,,
t_5568174_b_80277_tn_0,10:35:00,10:35:00,72013,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568174_b_80277_tn_0,10:45:00,10:45:00,7210,2,,0,0,3935.11278675,1,,,,,1,1,,,,,,,,,,,
t_5568175_b_80277_tn_0,17:50:00,17:50:00,72011,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568175_b_80277_tn_0,18:00:00,18:00:00,7210,2,,0,0,3979.95609241,1,,,,,1,1,,,,,,,,,,,
t_5568176_b_80277_tn_0,09:10:00,09:10:00,72011,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568176_b_80277_tn_0,09:45:00,09:45:00,7211,2,,0,0,16172.45960721,1,,,,,1,1,,,,,,,,,,,
t_5568177_b_80277_tn_0,11:05:00,11:05:00,7211,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568177_b_80277_tn_0,11:40:00,11:40:00,72013,2,,0,0,16183.16748101,1,,,,,1,1,,,,,,,,,,,
t_5568178_b_80277_tn_0,10:35:00,10:35:00,7209,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568178_b_80277_tn_0,11:00:00,11:00:00,72011,2,,0,0,10230.93080044,1,,,,,1,1,,,,,,,,,,,
t_5568179_b_80277_tn_0,10:05:00,10:05:00,72013,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568179_b_80277_tn_0,10:30:00,10:30:00,7209,2,,0,0,10206.55651845,1,,,,,1,1,,,,,,,,,,,
t_5568181_b_80277_tn_0,14:05:00,14:05:00,7211,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568181_b_80277_tn_0,14:35:00,14:35:00,72011,2,,0,0,16162.95419567,1,,,,,1,1,,,,,,,,,,,
t_5568182_b_80277_tn_0,21:40:00,21:40:00,7209,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568182_b_80277_tn_0,21:50:00,21:55:00,7208,2,,0,0,1512.73427344327,1,,,,,1,1,,,,,,,,,,,
t_5568182_b_80277_tn_0,22:15:00,22:15:00,72013,3,,0,0,10460.22413173,1,,,,,1,1,,,,,,,,,,,
t_5568183_b_80277_tn_0,09:50:00,09:50:00,7208,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568183_b_80277_tn_0,10:00:00,10:05:00,7209,2,,0,0,1514.88235720359,1,,,,,1,1,,,,,,,,,,,
t_5568183_b_80277_tn_0,10:30:00,10:30:00,72013,3,,0,0,11728.65699583,1,,,,,1,1,,,,,,,,,,,
t_5568184_b_80277_tn_0,18:40:00,18:40:00,7212,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568184_b_80277_tn_0,19:40:00,19:40:00,72011,2,,0,0,44555.62718219,1,,,,,1,1,,,,,,,,,,,
t_5568185_b_80277_tn_0,19:05:00,19:05:00,7212,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568185_b_80277_tn_0,20:05:00,20:05:00,72011,2,,0,0,44555.62718219,1,,,,,1,1,,,,,,,,,,,
t_5568186_b_80277_tn_0,20:10:00,20:10:00,72011,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568186_b_80277_tn_0,21:10:00,21:15:00,7212,2,,0,0,44721.6497565864,1,,,,,1,1,,,,,,,,,,,
t_5568186_b_80277_tn_0,21:20:00,21:20:00,7213,3,,0,0,45332.71656957,1,,,,,1,1,,,,,,,,,,,
t_5568187_b_80277_tn_0,08:15:00,08:15:00,72011,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568187_b_80277_tn_0,08:50:00,08:50:00,7211,2,,0,0,16172.45960721,1,,,,,1,1,,,,,,,,,,,
t_5568188_b_80277_tn_0,21:10:00,21:10:00,72012,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568188_b_80277_tn_0,21:35:00,21:35:00,7209,2,,0,0,10232.85652109,1,,,,,1,1,,,,,,,,,,,
t_5568189_b_80277_tn_0,21:05:00,21:05:00,72013,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568189_b_80277_tn_0,21:25:00,21:25:00,7207,2,,0,0,8881.09374369,1,,,,,1,1,,,,,,,,,,,
t_5568234_b_80277_tn_0,11:20:00,11:20:00,72013,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568234_b_80277_tn_0,11:55:00,11:55:00,7211,2,,0,0,16190.53076818,1,,,,,1,1,,,,,,,,,,,
t_5568235_b_80277_tn_0,12:00:00,12:00:00,7211,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568235_b_80277_tn_0,12:35:00,12:35:00,72013,2,,0,0,16183.16748101,1,,,,,1,1,,,,,,,,,,,
t_5568236_b_80277_tn_0,14:10:00,14:10:00,72012,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568236_b_80277_tn_0,14:30:00,14:30:00,7208,2,,0,0,8975.40000977,1,,,,,1,1,,,,,,,,,,,
t_5568237_b_80277_tn_0,11:55:00,11:55:00,7208,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568237_b_80277_tn_0,12:05:00,12:15:00,7209,2,,0,0,1514.88235720359,1,,,,,1,1,,,,,,,,,,,
t_5568237_b_80277_tn_0,12:40:00,12:40:00,72012,3,,0,0,11751.67690759,1,,,,,1,1,,,,,,,,,,,
t_5568238_b_80277_tn_0,14:10:00,14:10:00,7208,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568238_b_80277_tn_0,14:20:00,14:30:00,7209,2,,0,0,1514.88235720359,1,,,,,1,1,,,,,,,,,,,
t_5568238_b_80277_tn_0,14:55:00,14:55:00,72012,3,,0,0,11751.67690759,1,,,,,1,1,,,,,,,,,,,
t_5568239_b_80277_tn_0,14:35:00,14:35:00,7208,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568239_b_80277_tn_0,14:45:00,14:55:00,7209,2,,0,0,1514.88235720359,1,,,,,1,1,,,,,,,,,,,
t_5568239_b_80277_tn_0,15:20:00,15:20:00,72012,3,,0,0,11751.67690759,1,,,,,1,1,,,,,,,,,,,
t_5568240_b_80277_tn_0,17:25:00,17:25:00,7208,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5568240_b_80277_tn_0,17:35:00,17:45:00,7209,2,,0,0,1514.88235720359,1,,,,,1,1,,,,,,,,,,,
t_5568240_b_80277_tn_0,18:10:00,18:10:00,72012,3,,0,0,11751.67690759,1,,,,,1,1,,,,,,,,,,,
t_5582562_b_80277_tn_0,20:55:00,20:55:00,7211,1,,0,0,0,1,,,,,1,1,,,,,,,,,,,
t_5582562_b_80277_tn_0,21:30:00,21:30:00,72012,2,,0,0,16121.04430654,1,,,,,1,1,,,,,,,,,,,
"""

ICON = SFBF_ICON_ASSET.readall()
