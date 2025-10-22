"""
Applet: Trolley Detector
Summary: SEPTA PCC Trolley Detector
Description: Shows the location of restored PCC trolleys running on SEPTA Route G1.
Author: radiocolin
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")

SEPTA_API = "https://www3.septa.org/api/TransitView/index.php?route=G1"
SEPTA_STOPS_API = "https://www3.septa.org/api/Stops/?req1=G1"
TROLLEY_IMAGE = base64.decode("iVBORw0KGgoAAAANSUhEUgAAACYAAAAMCAYAAAAOCs/+AAAAAXNSR0IArs4c6QAAAERlWElmTU0AKgAAAAgAAYdpAAQAAAABAAAAGgAAAAAAA6ABAAMAAAABAAEAAKACAAQAAAABAAAAJqADAAQAAAABAAAADAAAAAAPgxf+AAAA30lEQVQ4EWNkQAJXr179D+Nqa2szwtgDQWO1fDA4EMVhkyZNgofYQIRSXl4e3D1gxkA7CDkQYI5jvLS5meRQunXzOrJZDGrqmih8UjnI5j1jswBrZwGRkzY+BHPy/OWJYoMVoxGkmoGsHtkoB8WPYC4TsuBgYjNuFWcgOSo3/gQHNNwf/ux/4GxyGMjmwcxiZClkJNlh/++gWs+ogsonlYdsHsysQRuVqHEC9eqffkgg6uvrwz1/8eJFMBsYwgwwX8El8TAImQXSis08FqBGeKGGZD7O6MWhHkkrBpMsswAM9VlIRGdcdwAAAABJRU5ErkJggg==")

def get_route_15():
    """Get trolley information for Route 15 (G1) using next_stop_id
    
    Returns:
      List of trolley render objects
    """
    trolley_ids = ["2320", "2321", "2322", "2323", "2324", "2325", "2326", "2327", "2328", "2329", "2330", "2331", "2332", "2333", "2334", "2335", "2336", "2337"]
    trolleys_found = []
    
    # Fetch stops data once and build lookup dictionary
    stops_r = http.get(SEPTA_STOPS_API, ttl_seconds = 300)
    stops_data = stops_r.json()
    stop_lookup = {}
    for stop in stops_data:
        stop_lookup[stop.get("stopid")] = stop.get("stopname")
    
    r = http.get(SEPTA_API, ttl_seconds = 300)
    result = r.json()
    for i in result.get("bus"):
        id = i.get("VehicleID")
        if id not in trolley_ids:
            continue
        next_stop_id = i.get("next_stop_id")
        if next_stop_id == None:
            continue
        stop_name = stop_lookup.get(str(next_stop_id))
        if stop_name == None:
            continue
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
