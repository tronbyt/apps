"""
Applet: NOAA Buoy
Summary: Display buoy weather data
Description: Display swell,wind,temperature,misc data for user specified buoy. Find buoy_id's here : https://www.ndbc.noaa.gov/obs.shtml
Author: tavdog
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")
load("xpath.star", "xpath")

print_debug = True

default_location = """
{
    "lat": "20.8911",
    "lng": "-156.5047",
    "description": "Wailuku, HI, USA",
    "locality": "Maui",
    "place_id": "ChIJCSF8lBZEwokRhngABHRcdoI",
    "timezone": "America/Honolulu"
}
"""

def debug_print(arg):
    if print_debug:
        print(arg)


# Extract the value cell text following a label inside the Wave Summary table
# Looks for: ... <td>LABEL</td><td> VALUE </td>
def td_value(wave_section, label):
    i = wave_section.find(label)
    if i == -1:
        return None
    j = wave_section.find("</td><td", i)
    if j == -1:
        return None
    k = wave_section.find('>', j)
    if k == -1:
        return None
    l = wave_section.find("</td>", k)
    if l == -1:
        return None
    return wave_section[k + 1:l].strip()

def swell_over_threshold(thresh, units, data, use_wind_swell):  # assuming threshold is already in preferred units
    if use_wind_swell:
        height = data.get("WIND_WVHT", "0")
    else:
        height = data.get("WVHT", "0")
    if thresh == "" or float(thresh) == 0.0:
        return True
    elif units == "m":
        height = float(height) / 3.281
        height = int(height * 10)
        height = height / 10.0

    return float(height) >= float(thresh)

def FtoC(F):  # returns rounded to 1 decimal
    if F == "--":
        return "--"
    c = (float(F) - 32) * 0.55
    c = int(c * 10)
    return c / 10.0

def fetch_data(buoy_id, last_data):
    debug_print("fetching....")
    data = dict()
    url = "https://www.ndbc.noaa.gov/station_page.php?station=%s" % buoy_id.lower()
    debug_print("url: " + url)
    resp = http.get(url, ttl_seconds = 600)  # 10 minutes http cache time
    debug_print(resp)
    if resp.status_code != 200 or "Invalid Station ID" in resp.body():
        if len(last_data) != 0:
            if "stale" not in last_data:
                last_data["stale"] = 1
            else:
                last_data["stale"] = last_data["stale"] + 1
            debug_print("stale counter to :" + str(last_data["stale"]))
            return last_data
        elif resp.status_code == 404:
            data["name"] = buoy_id
            data["error"] = "No Data"
            return data
        elif "Invalid Station ID" in resp.body():
            data["name"] = buoy_id
            data["error"] = "Invalid Station"
            return data
        else:
            data["name"] = buoy_id
            data["error"] = "Code: " + str(resp.status_code)
            return data

    html = resp.body()
    data["name"] = buoy_id  # fallback, no name in desktop page

    # Extract station name from page title if available
    title_match = re.findall(r"<title>.*Station (\w+) - (.+?) -.*</title>", html)
    if len(title_match) > 0:
        data["name"] = title_match[0][1].strip()

    # Weather Conditions section - try desktop format first
    weather_start = html.find('<section id="metdata"')
    if weather_start != -1:
        weather_end = html.find('</section>', weather_start)
        if weather_end != -1:
            weather_section = html[weather_start:weather_end]

            # Air Temperature
            atmp_match = re.findall(r'Air Temperature[^>]*</td><td[^>]*>\s*([0-9.]+)\s*°F', weather_section)
            if len(atmp_match) > 0:
                data["ATMP"] = atmp_match[0]

            # Water Temperature
            wtmp_match = re.findall(r'Water Temperature[^>]*</td><td[^>]*>\s*([0-9.]+)\s*°F', weather_section)
            if len(wtmp_match) > 0:
                data["WTMP"] = wtmp_match[0]

    # Wave Summary section - desktop format
    # First try to find structured table format (like the HTML you provided)
    wave_start = html.find('<section id="wavedata"')
    debug_print("Structured wave section search result: " + str(wave_start))
    wave_summary_found = False

    if wave_start != -1:
        # Found structured table format
        wave_end = html.find('</section>', wave_start)
        if wave_end != -1:
            wave_summary_found = True
            wave_section = html[wave_start:wave_end]
            debug_print("Found structured wave section, length: " + str(len(wave_section)))


        # Parse desktop Wave Summary table using label->value td extraction
        # WVHT
        cell = td_value(wave_section, "Significant Wave Height (WVHT):")
        if cell != None:
            m = re.match(r"\s*([0-9.]+)\s*ft", cell)
            if len(m) > 0:
                data["WVHT"] = m[0][1]

        # SWH (prefer SWH for swell height; override WVHT if present)
        cell = td_value(wave_section, "Swell Height (SwH):")
        if cell != None:
            m = re.match(r"\s*([0-9.]+)\s*ft", cell)
            if len(m) > 0:
                data["SWH"] = m[0][1]
                # Always use SwH as the swell height shown by this app
                data["WVHT"] = data["SWH"]

        # DPD (swell period; override any other period)
        cell = td_value(wave_section, "Swell Period (SwP):")
        if cell != None:
            m = re.match(r"\s*([0-9.]+)\s*sec", cell)
            if len(m) > 0:
                data["DPD"] = m[0][1]
                data["WIND_DPD"] = None  # ensure UI uses swell period unless wind_swell is chosen

        # APD (fallback for DPD if missing)
        cell = td_value(wave_section, "Average Wave Period (APD):")
        if cell != None:
            m = re.match(r"\s*([0-9.]+)\s*sec", cell)
            if len(m) > 0:
                if "DPD" not in data:
                    data["DPD"] = m[0][1]
                data["APD"] = m[0][1]

        # MWD (use swell direction, not mean direction)
        cell = td_value(wave_section, "Swell Direction (SwD):")
        if cell != None:
            m = re.match(r"\s*([A-Z]+)", cell)
            if len(m) > 0:
                data["MWD"] = m[0][1]
                data["WIND_MWD"] = None  # ensure UI uses swell direction unless wind_swell is chosen

        # WIND_WVHT
        cell = td_value(wave_section, "Wind Wave Height (WWH):")
        if cell != None:
            m = re.match(r"\s*([0-9.]+)\s*ft", cell)
            if len(m) > 0:
                data["WIND_WVHT"] = m[0][1]

        # WIND_DPD
        cell = td_value(wave_section, "Wind Wave Period (WWP):")
        if cell != None:
            m = re.match(r"\s*([0-9.]+)\s*sec", cell)
            if len(m) > 0:
                data["WIND_DPD"] = m[0][1]

        # WIND_MWD
        cell = td_value(wave_section, "Wind Wave Direction (WWD):")
        if cell != None:
            m = re.match(r"\s*([A-Z]+)", cell)
            if len(m) > 0:
                data["WIND_MWD"] = m[0][1]

        # STEEPNESS
        cell = td_value(wave_section, "Wave Steepness (STEEPNESS):")
        if cell != None:
            m = re.match(r"\s*([A-Z]+)", cell)
            if len(m) > 0:
                data["STEEPNESS"] = m[0][1]


    # Additional data extraction for wind and other metrics from desktop format
    # Parse values directly from the Conditions table using td_value helper
    # Wind Direction (WDIR)
    cell = td_value(html, "Wind Direction (WDIR):")
    if cell != None:
        m = re.match(r"\s*([A-Z]+)", cell)
        if len(m) > 0:
            data["WDIR"] = m[0][1]

    # Wind Speed (WSPD)
    cell = td_value(html, "Wind Speed (WSPD):")
    if cell != None:
        m = re.match(r"\s*([0-9.]+)\s*kts", cell)
        if len(m) > 0:
            data["WSPD"] = m[0][1]
    # Fallbacks: use 10m or 20m wind speed if base WSPD missing
    if "WSPD" not in data:
        cell = td_value(html, "Wind Speed at 10 meters (WSPD10M):")
        if cell != None:
            m = re.match(r"\s*([0-9.]+)\s*kts", cell)
            if len(m) > 0:
                data["WSPD"] = m[0][1]
    if "WSPD" not in data:
        cell = td_value(html, "Wind Speed at 20 meters (WSPD20M):")
        if cell != None:
            m = re.match(r"\s*([0-9.]+)\s*kts", cell)
            if len(m) > 0:
                data["WSPD"] = m[0][1]

    # Wind Gust (GST)
    cell = td_value(html, "Wind Gust (GST):")
    if cell != None:
        m = re.match(r"\s*([0-9.]+)\s*kts", cell)
        if len(m) > 0:
            data["GST"] = m[0][1]

    # Air Temperature (ATMP)
    cell = td_value(html, "Air Temperature (ATMP):")
    if cell != None:
        m = re.match(r"\s*([0-9.]+)", cell)
        if len(m) > 0:
            data["ATMP"] = m[0][1]

    # Water Temperature (WTMP)
    cell = td_value(html, "Water Temperature (WTMP):")
    if cell != None:
        m = re.match(r"\s*([0-9.]+)", cell)
        if len(m) > 0:
            data["WTMP"] = m[0][1]

    # Atmospheric Pressure (PRES)
    cell = td_value(html, "Atmospheric Pressure (PRES):")
    if cell != None:
        m = re.match(r"\s*([0-9.]+)", cell)
        if len(m) > 0:
            data["PRES"] = m[0][1]

    # Pressure Tendency (PTDY) - store as raw cell, or parse numeric change if desired
    cell = td_value(html, "Pressure Tendency (PTDY):")
    if cell != None:
        # Capture signed numeric change
        m = re.match(r"\s*([+\-]?[0-9.]+)", cell)
        if len(m) > 0:
            data["PTDY"] = m[0][1]

    # Fallback to last_data for missing fields
    # If Wave Summary section was not found, mark data as stale and use last_data for swell fields
    if not wave_summary_found and len(last_data) != 0:
        if "stale" not in data:
            data["stale"] = 1
        else:
            data["stale"] = data["stale"] + 1
        debug_print("Wave Summary missing, using last data. Stale counter: " + str(data.get("stale", 0)))

        # Use last_data for swell-related fields when wave summary is missing
        for k in ["WVHT", "DPD", "MWD", "WIND_WVHT", "WIND_DPD", "WIND_MWD", "SWH", "APD", "STEEPNESS"]:
            if k not in data or data[k] == None:
                data[k] = last_data.get(k)

    # General fallback for all fields
    for k in ["WVHT", "DPD", "MWD", "WTMP", "ATMP", "WSPD", "GST", "WDIR", "WIND_WVHT", "WIND_DPD", "WIND_MWD", "SWH", "APD", "STEEPNESS"]:
        if k not in data or data[k] == None:
            data[k] = last_data.get(k)

    return data

def main(config):
    debug_print("##########################")
    data = dict()

    buoy_id = config.get("buoy_id", "")

    if buoy_id == "none" or buoy_id == "":  # if manual input is empty load from local selection
        local_selection = config.get("local_buoy_id", '{"display": "Station 51213 - South Lanai", "value": "51213"}')  # default is Waimea
        local_selection = json.decode(local_selection)
        if "value" in local_selection:
            buoy_id = local_selection["value"]
        else:
            buoy_id = "51213"

    buoy_name = config.get("buoy_name", "")
    h_unit_pref = config.get("h_units", "feet")
    t_unit_pref = config.get("t_units", "F")
    min_size = config.get("min_size", "0")

    # ensure we have a valid numer for min_size
    if len(re.findall("[0-9]+", min_size)) <= 0:
        min_size = "0"

    # CACHING FOR MAIN DATA OBJECT
    cache_key = "noaa_buoy_%s" % (buoy_id)
    cache_str = cache.get(cache_key)  #  not actually a json object yet, just a string
    if cache_str != None:  # and cache_str != "{}":
        debug_print("cache :" + cache_str)
        data = json.decode(cache_str)

    # CACHING FOR USECACHE : use this cache item to control wether to fetch new data or not, and update the main data cache
    usecache_key = "noaa_buoy_%s_usecache" % (buoy_id)
    usecache = cache.get(usecache_key)  #  not actually a json object yet, just a string
    if usecache and len(data) != 0:
        debug_print("using cache since usecache_key is set")
    else:
        debug_print("no usecache so fetching data")
        data = fetch_data(buoy_id, data)  # we pass in old data object so we can re-use data if missing from fetched data
        if data != None:
            if "stale" in data and data["stale"] > 2:
                debug_print("expring stale cache")

                # Custom cacheing determines if we have very stale data. Can't use http cache
                cache.set(cache_key, json.encode(data), ttl_seconds = 1)  # 1 sec expire almost immediately
            else:
                debug_print("Setting cache with : " + str(data))

                # Custom cacheing determines if we have very stale data. Can't use http cache
                cache.set(cache_key, json.encode(data), ttl_seconds = 1800)  # 30 minutes, should never actually expire because always getting re set

                # Custom cacheing determines if we have very stale data. Can't use http cache
                cache.set(cache_key + "_usecache", '{"usecache":"true"}', ttl_seconds = 600)  # 10 minutes

    if buoy_name == "" and "name" in data:
        debug_print("setting buoy_name to : " + data["name"])
        buoy_name = data["name"]

        # trim to max width of 14 chars or two words
        if len(buoy_name) > 14:
            buoy_name = buoy_name[:13]
            buoy_name = buoy_name.strip()

    # colors based on swell size
    color_small = "#00AAFF"  #blue
    color_medium = "#AAEEDD"  #cyanish
    color_big = "#00FF00"  #green
    color_huge = "#FF0000"  # red
    swell_color = color_medium

    # ERROR #################################################
    if "error" in data:  # if we have error key, then we got no good swell data, display the error
        #debug_print("buoy_id: " + str(buoy_id))
        return render.Root(
            child = render.Box(
                render.Column(
                    expanded = True,
                    cross_align = "center",
                    main_align = "space_evenly",
                    children = [
                        render.Text(
                            content = "Buoy:" + str(buoy_id),
                            font = "tb-8",
                            color = swell_color,
                        ),
                        render.Text(
                            content = "Error",
                            font = "tb-8",
                            color = "#FF0000",
                        ),
                        render.Text(
                            content = data["error"],
                            color = "#FF0000",
                        ),
                    ],
                ),
            ),
        )

    elif (data.get("DPD") and config.bool("display_swell", True)):
        # If wind swell option is selected and wind swell data is present, display wind swell instead of ground swell
        show_wind_swell = config.bool("wind_swell", False)
        use_wind = show_wind_swell and data.get("WIND_WVHT") and data.get("WIND_DPD")
        if use_wind:
            height = data["WIND_WVHT"]
            period = data["WIND_DPD"]
            mwd = data.get("WIND_MWD", "--")
        else:
            height = data["WVHT"]
            period = data["DPD"]
            mwd = data.get("MWD", "--")
        if type(height) == type(""):
            if height.replace(".", "", 1).isdigit():
                height_f = float(height)
            else:
                height_f = 0.0
        else:
            height_f = float(height)
        if (height_f < 2):
            swell_color = color_small
        elif (height_f < 5):
            swell_color = color_medium
        elif (height_f < 12):
            swell_color = color_big
        elif (height_f >= 13):
            swell_color = color_huge

        unit_display = "f"
        if h_unit_pref == "meters":
            unit_display = "m"

            # Only convert if height is a number
            if type(height) == type("") and height.replace(".", "", 1).isdigit():
                height = float(height) / 3.281
                height = int(height * 10)
                height = height / 10.0
            elif type(height) != type(""):
                height = float(height) / 3.281
                height = int(height * 10)
                height = height / 10.0

        wtemp = ""
        if (data.get("WTMP") and config.bool("display_temps", True)):
            wt = data["WTMP"]
            if (t_unit_pref == "C"):
                wt = FtoC(wt)
            wt = int(float(wt) + 0.5)
            wtemp = " %s%s" % (str(wt), t_unit_pref)

        if not swell_over_threshold(min_size, h_unit_pref, data, use_wind):
            return []

        period_display = str(int(float(period) + 0.5)) if type(period) == type("") and period.replace(".", "", 1).isdigit() else str(period)
        return render.Root(
            child = render.Box(
                render.Column(
                    cross_align = "center",
                    main_align = "center",
                    children = [
                        render.Text(
                            content = buoy_name,
                            font = "tb-8",
                            color = swell_color,
                        ),
                        render.Text(
                            content = "%s%s %ss" % (height, unit_display, period_display),
                            font = "6x13",
                            color = swell_color,
                        ),
                        render.Text(
                            content = "%s°%s" % (mwd, wtemp),
                            color = "#FFAA00",
                        ),
                    ],
                ),
            ),
        )
        #WIND#################################################

    elif (data.get("WSPD") and data.get("WDIR") and config.bool("display_wind", True)):
        gust = ""
        avg = data["WSPD"]
        avg = str(int(float(avg) + 0.5))
        if "GST" in data:
            gust = data["GST"]
            gust = int(float(gust) + 0.5)
            gust = "g" + str(gust)

        atemp = ""
        if "ATMP" in data and config.get("display_temps") == "true":  # we have some room at the bottom for wtmp if desired
            at = data["ATMP"]
            if (t_unit_pref == "C"):
                at = FtoC(at)
            at = int(float(at) + 0.5)
            atemp = " %s%s" % (str(at), t_unit_pref)

        return render.Root(
            child = render.Box(
                render.Column(
                    cross_align = "center",
                    main_align = "center",
                    children = [
                        render.Text(
                            content = buoy_name,
                            font = "tb-8",
                            color = swell_color,
                        ),
                        render.Text(
                            content = "%s%s kts" % (avg, gust),
                            font = "6x13",
                            color = swell_color,
                        ),
                        render.Text(
                            content = "%s°%s" % (data["WDIR"], atemp),
                            color = "#FFAA00",
                        ),
                    ],
                ),
            ),
        )
        #TEMPS#################################################

    elif (config.bool("display_temps", False)):
        air = "--"
        if data.get("ATMP"):
            air = data["ATMP"]
            air = int(float(air) + 0.5)
        water = "--"
        if data.get("WTMP"):
            water = data["WTMP"]

        if (t_unit_pref == "C"):
            water = FtoC(water)
            air = FtoC(air)

        return render.Root(
            child = render.Box(
                render.Column(
                    cross_align = "center",
                    main_align = "center",
                    children = [
                        render.Text(
                            content = buoy_name,
                            font = "tb-8",
                            color = swell_color,
                        ),
                        render.Text(
                            content = "Air:%s°%s" % (air, t_unit_pref),
                            font = "6x13",
                            color = swell_color,
                        ),
                        render.Text(
                            content = "Water : %s°%s" % (water, t_unit_pref),
                            color = "#1166FF",
                        ),
                    ],
                ),
            ),
        )

    elif (config.bool("display_misc", False)):
        # MISC ################################################################
        # DEW with PRES with ATMP    or  TIDE with WTMP with SAL  or
        if "TIDE" in data:  # do some tide stuff, usually wtmp is included and somties SAL?
            water = "--"
            if data.get("WTMP"):
                water = data["WTMP"]

            if (t_unit_pref == "C"):
                water = FtoC(water)

            return render.Root(
                child = render.Box(
                    render.Column(
                        cross_align = "center",
                        main_align = "center",
                        children = [
                            render.Text(
                                content = buoy_name,
                                font = "tb-8",
                                color = swell_color,
                            ),
                            render.Text(
                                content = "Tide: %s %s" % (data["TIDE"], "ft"),
                                #font = "6x13",
                                color = swell_color,
                            ),
                            render.Text(
                                content = "Water : %s°%s" % (water, t_unit_pref),
                                color = "#1166FF",
                            ),
                        ],
                    ),
                ),
            )
        if data.get("DEW") or data.get("VIS"):
            lines = list()  # start with at least one blank
            if data.get("DEW"):
                dew = data["DEW"]
                if (t_unit_pref == "C"):
                    dew = FtoC(dew)

                lines.append("DEW: " + data["DEW"] + t_unit_pref)

            if data.get("VIS"):
                vis = data["VIS"]
                lines.append("VIS: " + vis)
                #debug_print("doing vis")

            if data.get("PRES"):
                lines.append("PRES: " + data["PRES"])

            if len(lines) < 2:
                lines.append("")
            return render.Root(
                child = render.Box(
                    render.Column(
                        cross_align = "center",
                        main_align = "center",
                        children = [
                            render.Text(
                                content = buoy_name,
                                font = "tb-8",
                                color = swell_color,
                            ),
                            render.Text(
                                content = lines[0],
                                #font = "6x13",
                                color = swell_color,
                            ),
                            render.Text(
                                content = lines[1],
                                color = "#1166FF",
                            ),
                        ],
                    ),
                ),
            )
            # Even if no misc data, check if we have swell data to display instead of "Nothing to Display"

        elif data.get("DPD"):
            # If wind swell option is selected and wind swell data is present, display wind swell instead of ground swell
            show_wind_swell = config.bool("wind_swell", False)
            use_wind = show_wind_swell and data.get("WIND_WVHT") and data.get("WIND_DPD")
            if use_wind:
                height = data["WIND_WVHT"]
                period = data["WIND_DPD"]
                mwd = data.get("WIND_MWD", "--")
            else:
                height = data["WVHT"]
                period = data["DPD"]
                mwd = data.get("MWD", "--")
            if type(height) == type(""):
                if height.replace(".", "", 1).isdigit():
                    height_f = float(height)
                else:
                    height_f = 0.0
            else:
                height_f = float(height)
            if (height_f < 2):
                swell_color = color_small
            elif (height_f < 5):
                swell_color = color_medium
            elif (height_f < 12):
                swell_color = color_big
            elif (height_f >= 13):
                swell_color = color_huge

            unit_display = "f"
            if h_unit_pref == "meters":
                unit_display = "m"

                # Only convert if height is a number
                if type(height) == type("") and height.replace(".", "", 1).isdigit():
                    height = float(height) / 3.281
                    height = int(height * 10)
                    height = height / 10.0
                elif type(height) != type(""):
                    height = float(height) / 3.281
                    height = int(height * 10)
                    height = height / 10.0

            wtemp = ""
            if (data.get("WTMP") and config.bool("display_temps", True)):
                wt = data["WTMP"]
                if (t_unit_pref == "C"):
                    wt = FtoC(wt)
                wt = int(float(wt) + 0.5)
                wtemp = " %s%s" % (str(wt), t_unit_pref)

            if not swell_over_threshold(min_size, h_unit_pref, data, use_wind):
                return []

            period_display = str(int(float(period) + 0.5)) if type(period) == type("") and period.replace(".", "", 1).isdigit() else str(period)

            # Add stale indicator if data is stale
            buoy_display_name = buoy_name
            if "stale" in data and data["stale"] > 0:
                buoy_display_name = buoy_name + "*"

            return render.Root(
                child = render.Box(
                    render.Column(
                        cross_align = "center",
                        main_align = "center",
                        children = [
                            render.Text(
                                content = buoy_display_name,
                                font = "tb-8",
                                color = swell_color,
                            ),
                            render.Text(
                                content = "%s%s %ss" % (height, unit_display, period_display),
                                font = "6x13",
                                color = swell_color,
                            ),
                            render.Text(
                                content = "%s°%s" % (mwd, wtemp),
                                color = "#FFAA00",
                            ),
                        ],
                    ),
                ),
            )
        else:
            return render.Root(
                child = render.Box(
                    render.Column(
                        cross_align = "center",
                        main_align = "center",
                        children = [
                            render.Text(
                                content = buoy_name,
                                font = "tb-8",
                                color = swell_color,
                            ),
                            render.Text(
                                content = "Nothing to",
                                font = "tb-8",
                                color = "#FF0000",
                            ),
                            render.Text(
                                content = "Display",
                                color = "#FF0000",
                            ),
                        ],
                    ),
                ),
            )
    else:
        # Check if we have swell data to display instead of "Nothing to Display"
        if data.get("DPD"):
            # If wind swell option is selected and wind swell data is present, display wind swell instead of ground swell
            show_wind_swell = config.bool("wind_swell", False)
            use_wind = show_wind_swell and data.get("WIND_WVHT") and data.get("WIND_DPD")
            if use_wind:
                height = data["WIND_WVHT"]
                period = data["WIND_DPD"]
                mwd = data.get("WIND_MWD", "--")
            else:
                height = data["WVHT"]
                period = data["DPD"]
                mwd = data.get("MWD", "--")
            if type(height) == type(""):
                if height.replace(".", "", 1).isdigit():
                    height_f = float(height)
                else:
                    height_f = 0.0
            else:
                height_f = float(height)
            if (height_f < 2):
                swell_color = color_small
            elif (height_f < 5):
                swell_color = color_medium
            elif (height_f < 12):
                swell_color = color_big
            elif (height_f >= 13):
                swell_color = color_huge

            unit_display = "f"
            if h_unit_pref == "meters":
                unit_display = "m"

                # Only convert if height is a number
                if type(height) == type("") and height.replace(".", "", 1).isdigit():
                    height = float(height) / 3.281
                    height = int(height * 10)
                    height = height / 10.0
                elif type(height) != type(""):
                    height = float(height) / 3.281
                    height = int(height * 10)
                    height = height / 10.0

            wtemp = ""
            if (data.get("WTMP") and config.bool("display_temps", True)):
                wt = data["WTMP"]
                if (t_unit_pref == "C"):
                    wt = FtoC(wt)
                wt = int(float(wt) + 0.5)
                wtemp = " %s%s" % (str(wt), t_unit_pref)

            if not swell_over_threshold(min_size, h_unit_pref, data, use_wind):
                return []

            period_display = str(int(float(period) + 0.5)) if type(period) == type("") and period.replace(".", "", 1).isdigit() else str(period)

            # Add stale indicator if data is stale
            buoy_display_name = buoy_name
            if "stale" in data and data["stale"] > 0:
                buoy_display_name = buoy_name + "*"

            return render.Root(
                child = render.Box(
                    render.Column(
                        cross_align = "center",
                        main_align = "center",
                        children = [
                            render.Text(
                                content = buoy_display_name,
                                font = "tb-8",
                                color = swell_color,
                            ),
                            render.Text(
                                content = "%s%s %ss" % (height, unit_display, period_display),
                                font = "6x13",
                                color = swell_color,
                            ),
                            render.Text(
                                content = "%s°%s" % (mwd, wtemp),
                                color = "#FFAA00",
                            ),
                        ],
                    ),
                ),
            )
        else:
            return render.Root(
                child = render.Box(
                    render.Column(
                        cross_align = "center",
                        main_align = "center",
                        children = [
                            render.Text(
                                content = buoy_name,
                                font = "tb-8",
                                color = swell_color,
                            ),
                            render.Text(
                                content = "Nothing to",
                                font = "tb-8",
                                color = "#FF0000",
                            ),
                            render.Text(
                                content = "Display",
                                color = "#FF0000",
                            ),
                        ],
                    ),
                ),
            )

def get_stations(location):
    station_options = list()

    #https://www.ndbc.noaa.gov/rss/ndbc_obs_search.php?lat=20.8911&lon=-156.5047
    loc = json.decode(location)  # See example location above.
    url = "https://www.ndbc.noaa.gov/rss/ndbc_obs_search.php?lat=%s&lon=%s" % (loc["lat"], loc["lng"])

    #debug_print(url)
    resp = http.get(url)
    if resp.status_code != 200:
        return []
    else:
        # channel/item/title
        # parse Station KLIH1 - 1615680 - KAHULUI, KAHULUI HARBOR, HI

        rss_titles = xpath.loads(resp.body()).query_all("/rss/channel/item/title")

        #debug_print(rss_titles)
        for rss_title in rss_titles:
            matches = re.match(r"Station\ (\w+) \-\s+(.+)$", rss_title)

            #debug_print(matches)
            if len(matches) > 0:
                #debug_print(matches[0][1] + " : " ,matches[0][0] )#+ matches[2])
                station_options.append(
                    schema.Option(
                        display = matches[0][0],
                        value = matches[0][1],
                    ),
                )
    return station_options

def get_schema():
    h_unit_options = [
        schema.Option(display = "feet", value = "feet"),
        schema.Option(display = "meters", value = "meters"),
    ]
    t_unit_options = [
        schema.Option(display = "C", value = "C"),
        schema.Option(display = "F", value = "F"),
    ]

    #    stations_list = get_stations(default_location)
    return schema.Schema(
        version = "1",
        fields = [
            schema.LocationBased(
                id = "local_buoy_id",
                name = "Local Buoy",
                icon = "monument",
                desc = "Location Based Buoys",
                handler = get_stations,
            ),
            schema.Text(
                id = "buoy_id",
                name = "Buoy ID - optional",
                icon = "monument",
                desc = "",
            ),
            schema.Toggle(
                id = "display_swell",
                name = "Display Swell",
                desc = "if available",
                icon = "gear",
                default = True,
            ),
            schema.Toggle(
                id = "wind_swell",
                name = "Display Wind Swell",
                desc = "instead of ground swell.",
                icon = "gear",
                default = False,
            ),
            schema.Toggle(
                id = "display_wind",
                name = "Display Wind",
                desc = "if available",
                icon = "gear",
                default = True,
            ),
            schema.Toggle(
                id = "display_temps",
                name = "Display Temperatures",
                icon = "gear",
                desc = "if available",
                default = True,
            ),
            schema.Toggle(
                id = "display_misc",
                name = "Display Misc.",
                desc = "if available",
                icon = "gear",
                default = True,
            ),
            schema.Dropdown(
                id = "h_units",
                name = "Height Units",
                icon = "quoteRight",
                desc = "Wave height units preference",
                options = h_unit_options,
                default = "feet",
            ),
            schema.Dropdown(
                id = "t_units",
                name = "Temperature Units",
                icon = "quoteRight",
                desc = "C or F",
                options = t_unit_options,
                default = "F",
            ),
            schema.Text(
                id = "min_size",
                name = "Minimum Swell Size",
                icon = "water",
                desc = "Only display if swell is above minimum size",
                default = "",
            ),
            schema.Text(
                id = "buoy_name",
                name = "Custom Display Name",
                icon = "user",
                desc = "Leave blank to use NOAA defined name",
                default = "",
            ),
        ],
    )
