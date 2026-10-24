"""
Applet: Tides & Temp
Summary: Display tides / water temp
Description: Display predicted tides from NOAA tide stations and water temperature from NDBC buoy stations. See https://tidesandcurrents.noaa.gov/tide_predictions.html for NOAA tide station IDs. See https://www.ndbc.noaa.gov/obs.shtml for NDBC buoy station IDs.
Author: sudeepban
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/img.gif", IMG_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

IMG = IMG_ASSET.readall()

NOAA_TIDES_URL = "https://api.tidesandcurrents.noaa.gov/api/prod/datagetter?station={station_id}&product=predictions&datum=MLLW&time_zone=gmt&interval=hilo&units=english&application=DataAPI_Sample&format=json&range=48&begin_date={begin_date}"
NOAA_TIDES_STATION_ID_DEFAULT = 8533071

NDBC_BUOY_URL = "https://www.ndbc.noaa.gov/data/realtime2/{station_id}.txt"
NDBC_BUOY_STATION_ID_DEFAULT = 44091

LOW_TIDE_COLOR_DEFAULT = "#088F8F"
HIGH_TIDE_COLOR_DEFAULT = "#1F51FF"
WATER_TEMPERATURE_COLOR_DEFAULT = "#EEDC82"

TIMEZONE_DEFAULT = "America/New_York"
TIMEZONE_GMT = "GMT"

DATE_FORMAT = "20060102"
DATETIME_FORMAT = "2006-01-02 15:04"
TIME_FORMAT = "03:04 PM"

def main(config):
    location = config.get("location")
    timezone = json.decode(location).get("timezone") if location else TIMEZONE_DEFAULT
    noaaTidesStationID = config.str("noaaTidesStationID", str(NOAA_TIDES_STATION_ID_DEFAULT))
    ndbcBuoyStationID = config.str("ndbcBuoyStationID", str(NDBC_BUOY_STATION_ID_DEFAULT))
    lowTideColor = config.str("lowTideColor", LOW_TIDE_COLOR_DEFAULT)
    highTideColor = config.str("highTideColor", HIGH_TIDE_COLOR_DEFAULT)
    waterTempColor = config.str("waterTempColor", WATER_TEMPERATURE_COLOR_DEFAULT)

    now = time.now().in_location(TIMEZONE_GMT)
    prevdate = (now - time.parse_duration("12h")).format(DATE_FORMAT)

    resp = http.get(NOAA_TIDES_URL.format(begin_date = prevdate, station_id = noaaTidesStationID), ttl_seconds = 3600)
    if resp.status_code != 200:
        fail("NOAA tides request failed with status", resp.status_code)

    resp_json = resp.json()
    if "predictions" not in resp_json:
        print("NOAA tides response missing predictions")
        return render.Root(
            child = render.Box(
                child = render.Text("No Data", color = "#FF0000"),
            ),
        )

    resp_predictions = resp_json["predictions"]
    data_predictions = []
    prev_tide = {}
    curr_tide_pct = None

    # Process NOAA predicted tides for the specified station ID
    # Extract previous high / low and next high / low to compute current estimated tide percentage
    # Extract next two high / low for display
    for resp_prediction in resp_predictions:
        prediction = {}
        prediction_time = time.parse_time(resp_prediction["t"], format = DATETIME_FORMAT, location = TIMEZONE_GMT).in_location(timezone)
        if prediction_time.unix - now.unix < 0:
            prev_tide["time"] = prediction_time
            prev_tide["height"] = float(resp_prediction["v"])
            water_temp = str(prev_tide["height"])
            continue

        if not curr_tide_pct:
            next_tide = {}
            next_tide["time"] = prediction_time
            next_tide["height"] = float(resp_prediction["v"])

            # Estimate current tide based on linear interpolation between previous high / low and next high / low
            slope = (next_tide["height"] - prev_tide["height"]) / (next_tide["time"].unix - prev_tide["time"].unix)
            curr_tide = prev_tide["height"] + slope * (now.unix - prev_tide["time"].unix)

            # Compute current tide percentage based on estimated current tide and previous / next high / low
            curr_tide_pct = int(100 * abs(curr_tide - min(next_tide["height"], prev_tide["height"])) / abs(next_tide["height"] - prev_tide["height"]))

        time_diff = prediction_time.unix - now.unix
        prediction["time"] = prediction_time.format(TIME_FORMAT)
        prediction["type"] = "HI" if resp_prediction["type"] == "H" else "LO"
        prediction["color"] = highTideColor if resp_prediction["type"] == "H" else lowTideColor
        prediction["hours"] = int(time_diff / 60 / 60)
        prediction["minutes"] = int((time_diff - prediction["hours"] * 60 * 60) / 60)

        data_predictions.append(prediction)
        if len(data_predictions) == 2:
            break

    disp_predictions = []

    disp_predictions.append(render.Box(height = 1, width = 1))
    for data_prediction in data_predictions:
        disp_predictions.append(render.Text(data_prediction["type"] + " " + data_prediction["time"], color = data_prediction["color"]))
        disp_predictions.append(render.Text(str(data_prediction["hours"]) + " hr " + str(data_prediction["minutes"]) + " min", font = "tom-thumb", color = "#ffffff"))
        disp_predictions.append(render.Box(height = 1, width = 1))

    resp = http.get(NDBC_BUOY_URL.format(station_id = ndbcBuoyStationID), ttl_seconds = 600)
    if resp.status_code != 200:
        fail("NDBC buoy request failed with status", resp.status_code)

    # Process NDBC buoy data for the specified station ID
    # Extract water temperature in Celsius and convert to Fahrenheit
    water_temp = int(9 / 5 * float(resp.body().splitlines()[2].split()[14]) + 32)

    return render.Root(
        delay = 350,
        child = render.Row(
            [
                render.Column(
                    children = disp_predictions,
                    main_align = "center",
                    cross_align = "center",
                    expanded = True,
                ),
                render.Column(
                    children = [
                        render.Image(src = IMG, width = 20, height = 10),
                        # Variable box height based on current tide percentage
                        render.Box(height = 1 + int(16 * curr_tide_pct / 100), color = "#99ccff"),
                        render.Row(
                            children = [
                                render.Text(str(water_temp) + "F", color = waterTempColor, font = "tom-thumb"),
                                render.Box(height = 1, width = 1),
                            ],
                        ),
                    ],
                    main_align = "end",
                    cross_align = "end",
                    expanded = True,
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for timezone",
                icon = "locationDot",
            ),
            schema.Text(
                id = "noaaTidesStationID",
                name = "NOAA Tides Station ID",
                desc = "Station ID for predicted tides",
                icon = "gear",
                default = str(NOAA_TIDES_STATION_ID_DEFAULT),
            ),
            schema.Text(
                id = "ndbcBuoyStationID",
                name = "NDBC Buoy Station ID",
                desc = "Station ID for water temperature",
                icon = "gear",
                default = str(NDBC_BUOY_STATION_ID_DEFAULT),
            ),
            schema.Color(
                id = "highTideColor",
                name = "High tide color",
                desc = "Color for the high tide time",
                icon = "brush",
                default = HIGH_TIDE_COLOR_DEFAULT,
            ),
            schema.Color(
                id = "lowTideColor",
                name = "Low tide color",
                desc = "Color for the low tide time",
                icon = "brush",
                default = LOW_TIDE_COLOR_DEFAULT,
            ),
            schema.Color(
                id = "waterTempColor",
                name = "Water temperature color",
                desc = "Color for the water temperature",
                icon = "brush",
                default = WATER_TEMPERATURE_COLOR_DEFAULT,
            ),
        ],
    )
