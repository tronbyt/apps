"""
Applet: Trolley Detector
Summary: SEPTA PCC Trolley Detector
Description: Shows the location of restored PCC trolleys running on SEPTA Route G1.
Author: radiocolin
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")

SEPTA_API = "https://www3.septa.org/api/TransitView/index.php?route=G1"
TROLLEY_STOPS = "{\"21481\":\"Haverford Av & 63rd St\",\"12196\":\"Richmond St & Allegheny Av\",\"650\":\"Richmond St & Cumberland St\",\"20984\":\"Richmond St & Huntingdon St\",\"21071\":\"Girard Av & 26th St\",\"30292\":\"Girard Av & 34th St - MBFS\",\"21035\":\"Girard Av & 54th St\",\"21100\":\"Girard Av & Columbia Av\",\"21081\":\"Girard Av & Ridge Av\",\"21005\":\"Girard Av & 16th St\",\"21021\":\"Girard Av & 31st St\",\"21061\":\"Girard Av & 42nd St\",\"21030\":\"Girard Av & 49th St\",\"21038\":\"Girard Av & 57th St\",\"20983\":\"Richmond St & Lehigh Av\",\"21033\":\"Girard Av & 52nd St\",\"21051\":\"Girard Av & 56th St\",\"21040\":\"Girard Av & 60th St\",\"20986\":\"Girard Av & Berks St\",\"21042\":\"Haverford Av & 62nd St\",\"649\":\"Richmond St & Cumberland St\",\"21086\":\"Girard Av & 12th St\",\"21070\":\"Girard Av & 27th St\",\"21018\":\"Girard Av & 28th St\",\"21022\":\"Girard Av & 33rd St\",\"20995\":\"Girard Av & 4th St\",\"21032\":\"Girard Av & 51st St\",\"21050\":\"Girard Av & 57th St\",\"21028\":\"Girard Av & Belmont Av\",\"24038\":\"Frankford Av & Richmond St\",\"21108\":\"Richmond St & Lehigh Av\",\"21016\":\"Girard Av & 26th St\",\"21069\":\"Girard Av & 28th St\",\"20993\":\"Girard Av & 2nd St\",\"21098\":\"Girard Av & Frankford Av- FS\",\"20978\":\"Girard Av & Front St\",\"30605\":\"Girard Av & Merion Av\",\"21105\":\"Girard Av & Richmond St\",\"31540\":\"Frankford Av & Girard Av - FS\",\"21110\":\"Richmond St & Cambria St\",\"21001\":\"Girard Av & 11th St\",\"21068\":\"Girard Av & 29th St\",\"30291\":\"Girard Av & 34th St - MBFS\",\"344\":\"Girard Av & 40th St - FS\",\"21101\":\"Girard Av & Palmer St\",\"20982\":\"Richmond St & Cambria St\",\"21113\":\"Richmond St & Clearfield St\",\"21075\":\"College Av & 24th St - FS\",\"21017\":\"Girard Av & 27th St\",\"21067\":\"Girard Av & 31st St\",\"21025\":\"Girard Av & 39th St\",\"21062\":\"Girard Av & 41st St\",\"21055\":\"Girard Av & 52nd St\",\"31443\":\"Girard Av & 62nd St\",\"21091\":\"Girard Av & 7th St\",\"21078\":\"Girard Av & Corinthian Av\",\"342\":\"Girard Av & Front St\",\"30550\":\"Girard Av & Merion Av\",\"21008\":\"Girard Av & Ridge Av\",\"21073\":\"Poplar St & Stillman St\",\"31347\":\"Frankford Av & Delaware Av Loop\",\"21087\":\"Girard Av & 11th St\",\"21006\":\"Girard Av & 17th St\",\"30290\":\"Girard Av & 19th St\",\"21009\":\"Girard Av & 20th St\",\"21063\":\"Girard Av & 39th St\",\"21044\":\"Girard Av & 63rd St - MBFS\",\"21072\":\"26th St & Poplar St\",\"30791\":\"Girard Av & 24th St\",\"349\":\"Girard Av & 59th St\",\"20996\":\"Girard Av & 5th St\",\"21093\":\"Girard Av & 5th St\",\"20998\":\"Girard Av & 7th St\",\"20999\":\"Girard Av & 8th St\",\"20979\":\"Richmond St & Clearfield St\",\"21114\":\"Richmond St & Allegheny Av\",\"21079\":\"Girard Av & 20th St\",\"21026\":\"Girard Av & 41st St\",\"21037\":\"Girard Av & 56th St\",\"345\":\"Girard Av & 59th St\",\"21090\":\"Girard Av & 8th St\",\"343\":\"Girard Av & Broad St\",\"352\":\"Girard Av & Broad St\",\"20989\":\"Girard Av & Columbia Av\",\"21014\":\"Poplar St & 25th St\",\"481\":\"Frankford Av & Girard Av\",\"21111\":\"Richmond St & Ann St\",\"21107\":\"Richmond St & Huntingdon St\",\"21082\":\"Girard Av & 17th St\",\"21080\":\"Girard Av & 19th St\",\"21053\":\"Girard Av & 54th St\",\"20981\":\"Richmond St & Ann St\",\"25779\":\"Richmond St & Girard Av\",\"21019\":\"Girard Av & 29th St\",\"21095\":\"Girard Av & 3rd St\",\"21048\":\"Girard Av & 60th St\",\"21103\":\"Girard Av & Berks St\",\"21058\":\"Girard Av & Lancaster Av\",\"12218\":\"Richmond St & Somerset St\",\"21041\":\"Haverford Av & 61st St\",\"21083\":\"Girard Av & 16th St\",\"21010\":\"Girard Av & Corinthian Av\",\"20988\":\"Girard Av & Palmer St\",\"341\":\"Richmond St & Westmoreland St Loop\",\"21002\":\"Girard Av & 12th St\",\"21096\":\"Girard Av & 2nd St\",\"20994\":\"Girard Av & 3rd St\",\"350\":\"Girard Av & 40th St\",\"23992\":\"Frankford Av & Richmond St\",\"21109\":\"Richmond St & Somerset St\",\"21027\":\"Girard Av & 42nd St\",\"21056\":\"Girard Av & 51st St\",\"21047\":\"Girard Av & 61st St\",\"21060\":\"Girard Av & Belmont Av - FS\"}"
TROLLEY_IMAGE = base64.decode("iVBORw0KGgoAAAANSUhEUgAAACYAAAAMCAYAAAAOCs/+AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAJqADAAQAAAABAAAADAAAAAAPgxf+AAAA30lEQVQ4EWNkQAJXr179D+Nqa2szwtgDQWO1fDA4EMVhkyZNgofYQIRSXl4e3D1gxkA7CDkQYI5jvLS5meRQunXzOrJZDGrqmih8UjnI5j1jswBrZwGRkzY+BHPy/OWJYoMVoxGkmoGsHtkoB8WPYC4TsuBgYjNuFWcgOSo3/gQHNNwf/ux/4GxyGMjmwcxiZClkJNlh/++gWs+ogsonlYdsHsysQRuVqHEC9eqffkgg6uvrwz1/8eJFMBsYwgwwX8El8TAImQXSis08FqBGeKGGZD7O6MWhHkkrBpMsswAM9VlIRGdcdwAAAABJRU5ErkJggg==")

def get_route_15():
    """Get trolley information for Route 15 (G1) using next_stop_id
    
    Returns:
      List of trolley render objects
    """
    trolley_ids = ["2320", "2321", "2322", "2323", "2324", "2325", "2326", "2327", "2328", "2329", "2330", "2331", "2332", "2333", "2334", "2335", "2336", "2337"]
    trolleys_found = []
    
    # Build lookup dictionary from hardcoded stops data
    stops_data = json.decode(TROLLEY_STOPS)
    stop_lookup = {}
    for stopid, stopname in stops_data.items():
        stop_lookup[stopid] = stopname
    
    r = http.get(SEPTA_API, ttl_seconds = 300)
    if r == None or r.status_code != 200:
        return trolleys_found
    
    result = r.json()
    if result == None or result.get("bus") == None:
        return trolleys_found
    
    for i in result.get("bus"):
        id = i.get("VehicleID")
        if id not in trolley_ids:
            continue
        next_stop_id = i.get("next_stop_id")
        if next_stop_id == None:
            continue
        stop_name = stop_lookup.get(str(next_stop_id))
        if stop_name == None:
            stop_name = "Stop #" + str(next_stop_id)
        destination = i.get("destination")
        if destination == "63rd-Girard":
            direction = "Westbound"
        elif destination == "Richmond-Westmoreland":
            direction = "Eastbound"
        else:
            direction = "Now"
        string = direction
        string += " at " + stop_name.replace("& ", "&\n")
        output = render.Column(
            children = [
                render.Row(
                    children = [
                        render.Box(width = 39, height = 14, child = render.Image(src = TROLLEY_IMAGE)),
                        render.Padding(child = render.WrappedText(id, font = "6x13"), pad = (1, 1, 0, 0)),
                    ],
                ),
                render.Padding(child = render.WrappedText(string, font = "tom-thumb", align = "center", width = 64), pad = (0, 1, 0, 0)),
            ],
        )
        trolleys_found.append(output)
    return trolleys_found

def main():
    trolleys = get_route_15()

    if len(trolleys) == 0:
        return render.Root(
            child = render.Column(
                children = [
                    render.Row(
                        children = [
                            render.Box(width = 64, height = 14, child = render.Image(src = TROLLEY_IMAGE)),
                        ],
                    ),
                    render.Padding(child = render.WrappedText("No trolleys spotted.\nCheck later!", font = "tom-thumb", align = "center", width = 64), pad = (0, 1, 0, 0)),
                ],
            ),
        )
    else:
        return render.Root(
            child = render.Animation(children = trolleys),
            delay = 5000,
            show_full_animation = True,
        )
