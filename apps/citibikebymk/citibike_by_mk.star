load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("images/img_bike_src.jpg", IMG_BIKE_SRC_ASSET = "file")
load("images/img_park_src.png", IMG_PARK_SRC_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

IMG_BIKE_SRC = IMG_BIKE_SRC_ASSET.readall()
IMG_PARK_SRC = IMG_PARK_SRC_ASSET.readall()

ttls = 60

def get_resp_stations():
    data = cache.get("data_stations")
    if not data:
        print("Stations data not cached")
        url = "https://gbfs.lyft.com/gbfs/2.3/bkn/en/station_information.json"
        resp = http.get(url)
        data = resp.json()["data"]
        print("Response Stations: ", resp.status_code)

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set("data_stations", json.encode(data), ttl_seconds = ttls)
    else:
        print("Station data cached")
        data = json.decode(data)
    print("Stations Data returning as", type(data))
    return data

def get_resp_bikes():
    data = cache.get("data_bikes")
    if not data:
        print("Bike Data not cached")
        url_bikes = "https://gbfs.lyft.com/gbfs/2.3/bkn/en/station_status.json"
        resp = http.get(url_bikes)
        data = resp.json()["data"]["stations"]
        print("Response Availability: ", resp.status_code)

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set("data_bikes", json.encode(data), ttl_seconds = ttls)
    else:
        print("Bikes data cached")
        data = json.decode(data)
    print("Bikes Data returning as", type(data))
    return data

w = 15
h = int(w * 0.75)

img_bike = render.Image(src = IMG_BIKE_SRC, width = w, height = h)

img_park = render.Image(src = IMG_PARK_SRC, width = w, height = h)

############ STATION IDs
def pop_stations(data):
    dic = {}
    for s in data:
        dic.update({s["name"]: {"ext_id": s["station_id"], "leg_id": s["station_id"]}})
    return dict(sorted(dic.items()))

###########

def get_info(stat_name, type, bike_data, station_list):
    stat_ids = station_list[stat_name]
    leg_id = stat_ids["leg_id"]
    info = [i for i in bike_data if i["station_id"] == leg_id][0]
    docs_avail = int(info["num_docks_available"])
    bikes_avail = int(info["num_bikes_available"])
    res = {
        "docks": "  Docks: " + str(docs_avail),
        "bikes": "  Bikes: " + str(bikes_avail),
    }
    return res[type]

def get_col_children(stat_name, bike_data, station_list):
    l = []
    l.append(render.Marquee(child = render.Text(stat_name, color = "#45b6fe"), width = 70, scroll_direction = "horizontal"))
    l.append(render.Row(children = [img_bike, render.Text(get_info(stat_name, "bikes", bike_data, station_list))], cross_align = "center"))
    l.append(render.Row(children = [img_park, render.Text(get_info(stat_name, "docks", bike_data, station_list))], cross_align = "center"))
    l.append(render.Text(""))
    return l

def get_stat_col(stat_name, bike_data, station_list):
    l = get_col_children(stat_name, bike_data, station_list)
    return render.Column(children = l)

def get_col_list(bike_data, station_list):
    col_list = [get_stat_col(s, bike_data, station_list) for s in station_list]
    return col_list

def main(config):
    data_stat = get_resp_stations()
    station_ids = pop_stations(data_stat["stations"])
    data_bikes = get_resp_bikes()
    default = station_ids.keys()[0]
    def_str = '{"display":"%s","value":"%s"}' % (default, default)
    option = config.get("search_station", def_str)
    station = json.decode(option)

    station_name = station["value"]
    info = get_stat_col(station_name, data_bikes, station_ids)
    return render.Root(
        child = info,
        delay = 80,
    )

def search_station(pattern):
    data_stat = get_resp_stations()
    station_ids = pop_stations(data_stat["stations"])
    pattern = pattern.lower()
    return [schema.Option(value = s, display = s) for s in station_ids.keys() if pattern in (s.lower())]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Typeahead(
                id = "search_station",
                name = "Station",
                desc = "The station for which you need availability",
                icon = "gear",
                # default = options[0].value,
                # options = options,
                handler = search_station,
            ),
        ],
    )
