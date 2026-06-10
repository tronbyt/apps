"""
Applet: Zigbyt Weather
Summary: Displays date/time/weather
Description: Displays time, date, temperature (F/C), and weather condition glyph. Weather data by Open-Meteo.
Author: ryan-doucette
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_LATITUDE = "42.3601"
DEFAULT_LONGITUDE = "-71.0589"
DEFAULT_TIMEZONE = "America/New_York"
FORECAST_TTL_SECONDS = 2700  # 45 minutes
COORDINATE_SCALE = 100

# -------------------------
# Icons
# -------------------------
SUNNY = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAABBUlEQVR4AZRStXVtMRBc6Rb2f2yIzbmZKjBjMW7AkDxmbMLMJLLmJZdpzhEuzQIlwfT5OhblhRk6c34H7l8s1JCfmx79GykPnGm/1P2DDnQj6NJ/3WcXuIsGPxJV9iBb7Ef1+YcesBvrYBIy6ECX4iAaVP4tk1FdbvTAv2zkw5hiOQugiMi/JTKyw2AQuazuhNWdsed8OHqNnkSFoJiw2HWgOHzZVnoJ998KaVl3o8esV5+dGfJtrBwOXqDrsXMhqplSuEoq4n6GIo7HFhH4rVFx1MZeRBsHfJ9cxA+SavBdWaM71WLfdpDeQRuRkwYJo3yWY5T/1kUgFzLHoGcmXH6mODsDAPL7WsCj9djSAAAAAElFTkSuQmCC
""")
PARTLY_SUNNY = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAABkElEQVR4AbWTA8xVcRyGTzbGrOGzD7LdnKbspoyZWVMN2Ziy6/Kzbdu61nvUYdZve+49et6/ie8V4slliI+dQvxpIZ5aAysV/HuShdoG6+wRwrUhZjTSyAHCtTk2jAtb+m3pybp+6muA6IPEmKmwxq2HMXYjDJEhMCzo/z2HgJU8zrFZuE6YOQQW6gZ3H+CAgDHKgw+hLwCiLx8EC3lI+l4uabIQTz6QRTWfIoF3Yc+RHz4QBnrst4eSQEZ+S5boLLgcKOv2Fhd1IbfSgRmqIcTNEJLjyb3fk22ll9DggECdDcjvgLMBGPrDAG/8XDzLTcHJrF48KO3mZZnyHqCwCxnFDkxQr3uEOqAw/RzulELgeCbwuRGakGobUNCJli/jj54g9oa6y8uOxGV4VlQhB9wqEUOSW7UhhV3waJfRsGAwd32tNmV/QJIlzuYDKW2KXM9R3A0rIe02vvhNJGBipmVnXLmVmnb71duSytPv6303uSFcaLBjl0StHasA9NPth7id393KlrgV/+Uw/fVxZgGDILVlwzRoygAAAABJRU5ErkJggg==
""")
CLOUDY = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAABPElEQVR4Ac1QBVJsQRD7yg3Qe3ChvQenoBwtwd3d3d3lybq773boQaZmH1oKU5XxdCf59bPG1C0qJu/Qu6Bhfc3E4IoJWzfw90tkJlVN3FJsSQdWzRL0Afj9IXn6FnUzd7iduiPMa5KoopUV1b5NvkfPzD3Jz8vG86pDFMOCLu9yjHpha3cX/2WB0RsqvJAEVng/ywWPvITrEHAVBLacJO5KFKkFiisW8nWQ4E4CvpSEKKQWiSrJ08as9iRXdLoKAVqY4IhDkp28N6KEcz+wqBMWNBzIAt1AGQc4cORDTo+SJIkCrsTT3quo8aZAzgTafWnYACULll3gxxLZZlSsHyCJVrVAUXZ6Bx7re1LJ4j5CG2bs4wL8bi2yIAsAKNMi6GLv+2zlgB93rfAmsa/H4HDzyt0b/UnU/Pr28QC9tCc1jo0+vwAAAABJRU5ErkJggg==
""")
RAINY = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAABa0lEQVR4AZ2RA4xdURiEb92oUW0jrN04adSobtTGdts1Y264sbMKnq21bV0/K1jrzD7bc435Jv8cKpe0q5B10qinSpFpFW8NNNnrFbDRL+JK0QAdDVOPAPQGDx5lBZksNJ7HACtkYN4LBNLRJ6Axr9lA45eJxWbAcDf0zOGJmcNK4NliYXExp1m9gjM6hvh7hFBaJ4Ajqf+oGNwwMKC7HTiXBtDTaO3kIvMGjh4en9I6YchC4H3wuzR9uWjiC5tjpamSAlZRbU4I6OPxJV4ci9OdAjkYtAIJEHvsO3BcRxN/UoAAfm4OJ2MQM0s25jxJPwwmjNcUCEEyINTV78QOmkdtIBOO0MftfgEfE8azJxpjPYnoS+rByOBLJ49/AxweJb8nu30ikAGy2wEco/Kpiyfbk66MgHUAR/MC9AzhF70ZADzMVCEysvjeb8XBkg8YtccAe71WvKYKlYHFHwsLZkDETiB5IgD4EP12CDXNok84P9B7AAAAAElFTkSuQmCC
""")
SNOWY = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAABuklEQVR4Aa2TRboUQRCEC3eHA7Bih645B2sOwRlw9wPg7u7u7oz79HPX+ol8WjM4vPq++DojOyWixf3qAKOv51hwGMa4vz0XYxy7Gqf1Thrupqm7m2HVHzUC46/HeHPxq+dW0pr7cVOxBu79ZfOnWt4mGqHUBvkWeFrwXEuAqbgxPOyTsPx+hkkVzV/ruB+v95TVPIhcM7woeq7EPbdT1lyBzntpVrp0LSti9b652Nq/NdXY31wSz4lbbLlbKc9lDZKVcEjZfa7zLYXW4a3pJigGPIQNfZANnk2GD/LtfTloKFphwKshVf5qghoNuHUnxTJ591l5/WlDoQWq7r904Uk2MF8P77kmJ/X04yqIVSPVSJ1spRRfL7WwyI3o0fucPfhOC83Mi2Ca5S4VmZJvYm4tTL+RYOaNMlMbG5ldX89Mq334hel3I6Y5YLQ1vG5gVrmds7Kx33LCeEk+LRwExhiP2jgpfuR1ilkPa5kOjHLW/ErbEjAxameXCtbcUUFCmxTvUNN647ZAfJsWbLKBL6RqSIEVmI1HWebY1XI23YpMusWGpzFmWNOgfEyBHftdjQxew9/5RzzMfwP7YHv3O44B3AAAAABJRU5ErkJggg==
""")
FOG = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAQAAAC1+jfqAAABUklEQVR42nWRTUgCQRiGB+rQpVN0CSG8SrfwYogQnYKwQ6fOdQ8KJCioWyxlBoFJO4oeu3UpQth+UEs3dxQil6IMxH50FjwX+razrWhG78MwP+/3fcN8Q/5X4VRD6sneFCdVPb0mViF3KLVdl8pBvzaiTqTHzKOoJ+rThnPrYiOP0gYFxQG2mkG/lRublgN0+aiv6FSVTO3SSIBahCE92+XlGTkgr558KGBQcQFqswPJ2PPYQZqL4Yc0zhDrVDEsWx9kxwxtskiC2khfpm0svZd0MJRQxp0V0rlm95EYLg6OOnRzcLyhgBdUcCXsz8NkyE14nKOLZq0i5tcGaYtXOf5SvbZa4I3OEcPBp3qp+9Avz5qPD9BF0WZnIcwi3eQTN5sb/TFv+x8cbN8yFAbBbSurZFYIiQ+Rjs4H8uNMYtDA7rMPqQXSKzbPWiI7h0zkt/MN+5wg+66RiEsAAAAASUVORK5CYII=
""")
STORMY = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAB9ElEQVR4AWIgBBoAlZMDjF1bFIbPe7WDMqpt227UBrWC2nZ7M2Ft87IIao1tey7Gtj3z9eyxsZJv8/9XNn0YovDj/gVfzBUBnJbaE0oDU5VG4lUGeKsHM3845UOEAjq2KYFKj58w10UkueLL80bieOiuz8BMn8UTQxrj1MEMqjXW8kYPRzwpuOrPuRpzIvSIy8MrLh+icyEkg1KnRHTC0BQvw+CiL1zy55MkIiGfM/H5UE1sHgSkC3HzKGVOelNUneCDMNYlPBsC0+FrVK1JrS/Dw0+LyeUCn8JSxSryJVl8W4amiMkFv7TaBPYBf8FxGqW/J6AKLeaqL99EglwZmkGsokA2fxJku6xPx2oCCfa7wx+FckAB/4sEmmZXkEd+aHblaeMwcwWO08F8bAm247fwa0RvSQTwf2I+c+IKWWHKY51crxTthAKWRuQyUKVnrMZAb9n8RQYBlhPgz7iHUnW8DWGIqFVGLsn0VxvZ+1bPFK2JkXL7hlgqDtMP4jjDQz6DXP6MysFzevfaJ2tkkxDJ9RF1OKOfe9JJjL8zMF5lYEe1DqT/sRibj/m4U7XP1cSCNwb6Vawkgq5KPVdq5kIZamNT++4xn7CB36NMUt2oKxBLlxkh2p9M9FHp2VpXi/kYHRYjprb0ecZKLYS8/DkNx/4ByCkyy+TwT9QAAAAASUVORK5CYII=
""")
MOONY = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAIAAAD9iXMrAAAAJklEQVR4AWOgJfj/2hoZEVBEwDDyFFGujiKlQC6+QCFsPIoiGgIAUHxEoZEA1osAAAAASUVORK5CYII=
""")
MOONYISH = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAIAAAD9iXMrAAAAPklEQVR4AWOgCPx/bQ1HhBVBuIQVUaDu/Pn/cABRh18RimqCihAAKAtxDEgdLqUQKYTBQA4OhM12TMRAQwAAO6yyLU4DCE8AAAAASUVORK5CYII=
""")

# -------------------------
# Weather code -> icons
# -------------------------
def weather_glyph(code, night = False):
    # Map Open-Meteo weather codes to local 16x16 icon assets.
    if code == 0:
        return MOONY if night else SUNNY
    if code in [1, 2]:
        return MOONYISH if night else PARTLY_SUNNY
    if code == 3:
        return CLOUDY
    if code in [45, 48]:
        return FOG
    if code in [51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82]:
        return RAINY
    if code in [71, 73, 75, 77, 85, 86]:
        return SNOWY
    if code in [95, 96, 99]:
        return STORMY
    return SUNNY

# -------------------------
# Weather fetch
# -------------------------
def round_coord(value):
    return str(math.round(float(value) * COORDINATE_SCALE) / COORDINATE_SCALE)

def fetch_weather(lat, lng, timezone):
    tz = timezone if timezone != None and timezone != "" else "auto"
    rounded_lat = round_coord(lat)
    rounded_lng = round_coord(lng)

    url = (
        "https://api.open-meteo.com/v1/forecast" +
        "?latitude=" + rounded_lat +
        "&longitude=" + rounded_lng +
        "&current=temperature_2m,is_day,weather_code" +
        "&temperature_unit=fahrenheit" +
        "&forecast_days=1" +
        "&timezone=" + tz
    )

    resp = http.get(url = url, ttl_seconds = FORECAST_TTL_SECONDS)

    if not resp:
        return None, "No response"

    if resp.status_code != 200:
        if resp.status_code == 502:
            return None, "Bad gateway"
        if resp.status_code == 429:
            return None, "Rate limit"

        return None, "Error: " + str(resp.status_code)

    body = resp.body()
    if not body:
        return None, "Empty body"

    return json.decode(body), None

# -------------------------
# Time helpers
# -------------------------
def get_time_strings(timezone = None):
    if timezone != None and timezone != "":
        now = time.now().in_location(timezone)
    else:
        now = time.now()

    return now.format("3:04 PM"), now.format("Jan. 2, 2006")

def get_location(config):
    saved_location = config.get("location")
    if saved_location:
        location = json.decode(saved_location)
        return {
            "lat": location["lat"],
            "lng": location["lng"],
            "timezone": location.get("timezone", DEFAULT_TIMEZONE),
        }

    return {
        "lat": DEFAULT_LATITUDE,
        "lng": DEFAULT_LONGITUDE,
        "timezone": DEFAULT_TIMEZONE,
    }

# -------------------------
# Main
# -------------------------
def main(config):
    location = get_location(config)

    weather, error_type = fetch_weather(
        location["lat"],
        location["lng"],
        location.get("timezone", ""),
    )

    location_timezone = location.get("timezone", "")
    if type(weather) == "dict" and weather.get("timezone", ""):
        location_timezone = weather.get("timezone", location_timezone)

    time_str, date_str = get_time_strings(location_timezone)

    # -------------------------
    # HARD ERROR
    # -------------------------
    if not weather or type(weather) != "dict":
        return render.Root(
            child = render.Box(
                child = render.Column(
                    expanded = True,
                    children = [
                        # Top: Date (left aligned)
                        render.Row(
                            expanded = True,
                            main_align = "space_between",
                            children = [
                                render.Padding(
                                    pad = (3, 2, 0, 0),
                                    child = render.Text(date_str),
                                ),
                            ],
                        ),
                        render.Row(
                            expanded = True,
                            main_align = "space_between",
                            children = [
                                # Time (left aligned)
                                render.Padding(
                                    pad = (3, 2, 0, 0),
                                    child = render.Text(time_str, color = "#C0FFB8"),
                                ),
                            ],
                        ),
                        render.Row(
                            expanded = True,
                            main_align = "space_between",
                            children = [
                                # Error message (left aligned)
                                render.Padding(
                                    pad = (3, 2, 0, 0),
                                    child = render.Text(error_type or "Error", color = "#f8c76c"),
                                ),
                            ],
                        ),
                    ],
                ),
            ),
        )

    current = weather.get("current")
    if not current or type(current) != "dict":
        return render.Root(
            child = render.Box(
                width = 64,
                height = 32,
                child = render.Column(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.Text("Weather"),
                        render.Text("data"),
                        render.Text("error"),
                    ],
                ),
            ),
        )

    temp_f = current.get("temperature_2m", 0.0)
    temp_c = (temp_f - 32) * 5 / 9
    night = int(current.get("is_day", 1)) == 0
    icon = weather_glyph(current.get("weather_code", 0), night)

    # -------------------------
    # SUCCESS UI
    # -------------------------
    return render.Root(
        child = render.Box(
            child = render.Column(
                expanded = True,
                children = [
                    # Top: Date (left aligned)
                    render.Padding(
                        pad = (3, 2, 0, 0),
                        child = render.Text(date_str),
                    ),

                    # Bottom section: Time/Temp on left, icon on right
                    render.Row(
                        expanded = True,
                        main_align = "space_between",
                        children = [
                            # Left column: Time and Temps
                            render.Column(
                                main_align = "start",
                                children = [
                                    # Time (left aligned)
                                    render.Padding(
                                        pad = (3, 2, 0, 0),
                                        child = render.Text(time_str, font = "tb-8", color = "#C0FFB8"),
                                    ),

                                    # Temps (left aligned)
                                    render.Padding(
                                        pad = (3, 2, 0, 0),
                                        child = render.Row(
                                            children = [
                                                render.Text(str(int(temp_f)) + "F", color = "#FF7D7D"),
                                                render.Padding(
                                                    pad = (3, 0, 0, 0),
                                                    child = render.Text(str(int(temp_c)) + "C", color = "#9bc8ff"),
                                                ),
                                            ],
                                        ),
                                    ),
                                ],
                            ),
                            # Right column: icon at bottom right
                            render.Column(
                                main_align = "end",
                                children = [
                                    render.Padding(
                                        pad = (0, 3, 6, 0),
                                        child = render.Image(src = icon, width = 16, height = 16),
                                    ),
                                ],
                            ),
                        ],
                    ),
                ],
            ),
        ),
    )

# -------------------------
# Config
# -------------------------
def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for weather and local time.",
                icon = "locationDot",
            ),
        ],
    )
