"""
Applet: Bluebikes
Summary: Boston Bluebikes Status
Description: Displays Boston Bluebike Station Status (Available Bikes, E-Bikes, Docks).
Author: eric-pierce
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("images/bluebike_image.png", BLUEBIKE_IMAGE_ASSET = "file")
load("images/electric_bike_image.png", ELECTRIC_BIKE_IMAGE_ASSET = "file")
load("images/lightning_bolt_image.png", LIGHTNING_BOLT_IMAGE_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

BLUEBIKE_IMAGE = BLUEBIKE_IMAGE_ASSET.readall()
ELECTRIC_BIKE_IMAGE = ELECTRIC_BIKE_IMAGE_ASSET.readall()
LIGHTNING_BOLT_IMAGE = LIGHTNING_BOLT_IMAGE_ASSET.readall()

#Bluebikes Urls
BLUEBIKE_STATIONS_URL = "https://gbfs.lyft.com/gbfs/2.3/bos/en/station_information.json"
BLUEBIKE_STATION_STATUS_URL = "https://gbfs.lyft.com/gbfs/2.3/bos/en/station_status.json"
BLUEBIKE_MISSING_DATA = "DATA_NOT_FOUND"

#Images

#Station cache names
STATION_NAME_CACHE_SUFFIX = "_station_name"
STATION_STATUS_NAME_SUFFIX = "_station_status"
STATIONS_INFO_CACHE = "cache_stations_info"

def find_station_status_by_id(station_id):
    station_status_cached = cache.get(station_id + STATION_STATUS_NAME_SUFFIX)
    if station_status_cached != None:
        station_status = json.decode(station_status_cached)
        return station_status
    else:
        rep = http.get(BLUEBIKE_STATION_STATUS_URL)
        if rep.status_code != 200:
            fail("Bluebike request for find_station_status_by_id failed with status %d", rep.status_code)
        station_list = rep.json()["data"]["stations"]
        for station in station_list:
            if station["station_id"] == station_id:
                station_status = station
                cache.set(station_id + STATION_STATUS_NAME_SUFFIX, json.encode(station_status), ttl_seconds = 30)
                return station_status

    #unable to retrieve station status
    return BLUEBIKE_MISSING_DATA

def find_station_name_by_id(station_id):
    station_name = ""
    station_name_cached = cache.get(station_id + STATION_NAME_CACHE_SUFFIX)
    if station_name_cached != None:
        station_name = station_name_cached
    else:
        rep = http.get(BLUEBIKE_STATIONS_URL)
        if rep.status_code != 200:
            fail("Bluebike request for find_station_name_by_id failed with status %d", rep.status_code)
        station_list = rep.json()["data"]["stations"]
        for station in station_list:
            if station["station_id"] == station_id:
                station_name = station["name"]
                break
        cache.set(station_id + STATION_NAME_CACHE_SUFFIX, station_name, ttl_seconds = 600)
    return station_name

def get_all_stations():
    stations_info_cached = cache.get(STATIONS_INFO_CACHE)
    if stations_info_cached != None:
        stations_info = json.decode(stations_info_cached)
    else:
        rep = http.get(BLUEBIKE_STATIONS_URL)
        if rep.status_code != 200:
            fail("Bluebike request for get_all_stations failed with status %d", rep.status_code)
        stations_info = rep.json()["data"]["stations"]
        cache.set(STATIONS_INFO_CACHE, json.encode(stations_info), ttl_seconds = 600)
    return stations_info

def bluebike_station_search(pattern):
    station_list = get_all_stations()
    matching_stations_results = []
    for station in station_list:
        if pattern.upper() in station["name"].upper():
            matching_stations_results.append(
                schema.Option(
                    display = station["name"],
                    value = station["station_id"],
                ),
            )

    # Only show stations when we have a narrower set of results
    if len(matching_stations_results) > 60:
        return []
    else:
        return matching_stations_results

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Typeahead(
                id = "station",
                name = "Bluebike Station",
                desc = "Name of the Bluebike station",
                icon = "building",
                handler = bluebike_station_search,
            ),
        ],
    )

def main(config):
    station_config = config.get("station")
    if station_config == None:  # Generate fake data
        ebikes_available = "8"
        bikes_available = "2"
        docks_available = "5"
        station_name = "Fenway Outfield"
    else:
        station_config = json.decode(station_config)
        station_id = station_config["value"]
        station = find_station_status_by_id(station_id)

        # Number of ebikes
        ebikes_available = str(int(station["num_ebikes_available"]))

        # Number of docks
        docks_available = str(int(station["num_docks_available"]))

        # bikes_available includes classic and ebikes. Subtracting the ebikes to get classic (non-ebikes) count
        bikes_available = str(int(station["num_bikes_available"] - int(station["num_ebikes_available"])))
        station_name = find_station_name_by_id(station_id = station_id)
    return render.Root(
        render.Column(
            main_align = "space_evenly",
            expanded = True,
            children = [
                render.Marquee(
                    child = render.Text(
                        content = station_name,
                        font = "5x8",
                    ),
                    width = 64,
                ),
                render.Row(
                    cross_align = "center",
                    main_align = "space_evenly",
                    expanded = True,
                    children = [
                        render.Image(src = BLUEBIKE_IMAGE),
                        render.Text(content = bikes_available, font = "6x13"),
                        #render.Image(src = ELECTRIC_BIKE_IMAGE),
                        render.Image(src = LIGHTNING_BOLT_IMAGE),
                        render.Text(content = ebikes_available, font = "6x13"),
                    ],
                ),
                render.Row(
                    cross_align = "center",
                    main_align = "space_evenly",
                    expanded = True,
                    children = [
                        render.Text(content = "Docks:", font = "5x8", color = "4683B7"),
                        render.Text(content = docks_available, font = "5x8", color = "4683B7"),
                    ],
                ),
            ],
        ),
    )
