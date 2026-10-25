"""
Applet: Subway Countdown
Summary: NYC subway arrivals, no API key
Description: Live NYC subway arrivals read straight from the MTA's own GTFS-realtime feeds.
Author: nsluke

Two layouts on one engine: a station board (ranked next-three-trains across
every line at the station, direction filterable down to one platform or both
at once, per-route delay tinting) and a big-number hero (one train, readable
across the room, walk-time aware).

Reads the MTA feeds directly - no API key, no third-party mirror. Pixlet has no
protobuf module, so this walks the GTFS-realtime wire format by hand. That is
possible because starlark-go strings are byte strings: http.get().body() is
byte-exact for all 256 values and .elem_ords() hands back the raw bytes. Parsing
the 190 KB numbered-lines feed costs ~15 ms.

Field notes, all confirmed against the live feeds and cross-checked with the
reference gtfs-realtime-bindings decoder:

  - Feeds need no key as of 2026-08. Routes map to eight feeds; the numbered
    lines share one 190 KB feed, the L is 30 KB.
  - Realtime stop ids are the parent stop plus a direction letter: 127 -> 127N.
  - A trip's destination is the stop_id of its LAST StopTimeUpdate. The feed only
    carries a train's remaining stops, so that is always its terminal. This is
    how you get "Far Rockaway-Mott Av" instead of the cryptic NYCT train id.
  - NyctTripDescriptor (TripDescriptor field 1001) carries is_assigned, which
    means "real equipment is running this trip", NOT "this trip is real". Across
    a whole-system sample it is set on 93% of trips already under way and on 1-4%
    of trips that have not left their terminal - and on only 14% of shuttle
    trips, which turn back constantly. So it must not be used as a ghost filter;
    doing that empties the Franklin Av Shuttle. It is used here only to label a
    not-yet-running train SCHED rather than counting it down as tracked fact.
  - Feeds serve trains with arrival times slightly in the past. Clamp, or you
    get a train stuck at "0" forever.
  - Live disruptions carry route_id only - never stop_id. The 183-of-197 alerts
    that DO carry stop_id are all planned work. So alerts match on route.
"""

load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

FEED_BASE = "https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/nyct%2Fgtfs"
ALERTS_URL = "https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/camsys%2Fsubway-alerts.json"

FEED_TTL = 20
ALERT_TTL = 120

# The MTA's current palette, from its own colour table (data.ny.gov 3uhz-sej2),
# which matches route_color in the GTFS static feed field for field. Note this is
# NOT the widely-copied older set (#EE352E red, #FCCC0A yellow, ...) that
# Wikipedia and most third-party sources still cite - the MTA has moved on.
COLORS = {
    "1": "#D82233",
    "2": "#D82233",
    "3": "#D82233",
    "4": "#009952",
    "5": "#009952",
    "6": "#009952",
    "7": "#9A38A1",
    "A": "#0062CF",
    "C": "#0062CF",
    "E": "#0062CF",
    "B": "#EB6800",
    "D": "#EB6800",
    "F": "#EB6800",
    "M": "#EB6800",
    "G": "#799534",
    "J": "#8E5C33",
    "Z": "#8E5C33",
    "L": "#7C858C",
    "N": "#F6BC26",
    "Q": "#F6BC26",
    "R": "#F6BC26",
    "W": "#F6BC26",
    "S": "#7C858C",
    "T": "#008EB7",
    "SI": "#08179C",
}

# route_text_color in the GTFS feed is black for exactly these four and white
# for every other route.
DARK_GLYPH = {"N": True, "Q": True, "R": True, "W": True}

# Which realtime feed carries each route.
FEED_OF = {
    "1": "",
    "2": "",
    "3": "",
    "4": "",
    "5": "",
    "6": "",
    "7": "",
    "GS": "",
    "A": "-ace",
    "C": "-ace",
    "E": "-ace",
    "H": "-ace",
    "B": "-bdfm",
    "D": "-bdfm",
    "F": "-bdfm",
    "M": "-bdfm",
    "FS": "-bdfm",
    "G": "-g",
    "J": "-jz",
    "Z": "-jz",
    "N": "-nqrw",
    "Q": "-nqrw",
    "R": "-nqrw",
    "W": "-nqrw",
    "L": "-l",
    "SI": "-si",
}

# The open data calls all three shuttles "S", but each rides a different feed
# under its own route id: GS (42 St) with the numbered lines, FS (Franklin Av)
# with the B/D/F/M, H (Rockaway Park) with the A/C/E. Resolve by stop id, or
# the Franklin Av Shuttle stations poll the wrong feed and show nothing.
SHUTTLE_FEED = {"9": "", "S": "-bdfm", "H": "-ace"}

def feeds_for(st):
    """Set of feed suffixes that can carry a train calling at this station."""
    out = {}
    for route in st["routes"]:
        if route == "S":
            out[SHUTTLE_FEED.get(st["id"][0], "")] = True
        else:
            out[FEED_OF.get(route, "")] = True
    return out

WHITE = "#FFFFFF"
DIM = "#5A5A5A"
GREY = "#8C8C8C"
AMBER = "#FFA33A"
GREEN = "#3DDC57"
RED = "#FF4436"

# --- BEGIN GENERATED STATION DATA ---

DIRS = [
    "Inbound",
    "Last Stop",
    "Outbound",
    "Manhattan",
    "Middle Village",
    "Brooklyn",
    "Downtown",
    "Uptown",
    "Ferry",
    "South Shore",
    "Prospect Park",
    "New Lots",
    "Queens",
    "Northbound",
    "Southbound",
    "Bay Ridge",
    "Pelham Bay",
    "Coney Island",
    "The Bronx",
    "Rockaway Park",
    "Jamaica",
    "Eastchester",
    "Flatbush",
    "Hudson Yards",
    "Rockaways",
    "Van Cortlandt",
    "Astoria",
    "Canarsie",
    "Far Rockaway",
    "West Side",
    "Ozone Park",
    "Tottenville",
    "Court Square",
    "Harlem",
    "Grand Central",
    "Franklin Av",
    "Uptown & Queens",
    "Woodlawn",
    "Westbound",
    "Times Square",
]

# stop_id|name|routes|north_label_idx|south_label_idx
# Leading newline is load-bearing: lookup searches for "\n<id>|".
STATIONS = """
101|Van Cortlandt Park-242 St|1|1|3
103|238 St|1|25|3
104|231 St|1|25|3
106|Marble Hill-225 St|1|18|6
107|215 St|1|18|6
108|207 St|1|18|6
109|Dyckman St|1|18|6
110|191 St|1|18|6
111|181 St|1|18|6
112|168 St-Washington Hts|1|7|6
113|157 St|1|7|6
114|145 St|1|7|6
115|137 St-City College|1|7|6
116|125 St|1|7|6
117|116 St-Columbia University|1|7|6
118|Cathedral Pkwy (110 St)|1|7|6
119|103 St|1|7|6
120|96 St|1,2,3|7|6
121|86 St|1|7|6
122|79 St|1|7|6
123|72 St|1,2,3|7|6
124|66 St-Lincoln Center|1|7|6
125|59 St-Columbus Circle|1|7|6
126|50 St|1|7|6
127|Times Sq-42 St|1,2,3|7|6
128|34 St-Penn Station|1,2,3|7|6
129|28 St|1|7|6
130|23 St|1|7|6
131|18 St|1|7|6
132|14 St|1,2,3|7|6
133|Christopher St-Stonewall|1|7|6
134|Houston St|1|7|6
135|Canal St|1|7|6
136|Franklin St|1|7|6
137|Chambers St|1,2,3|7|6
138|WTC Cortlandt|1|7|6
139|Rector St|1|7|6
142|South Ferry|1|7|1
201|Wakefield-241 St|2|1|3
204|Nereid Av|2,5|13|3
205|233 St|2,5|13|3
206|225 St|2,5|13|3
207|219 St|2,5|13|3
208|Gun Hill Rd|2,5|13|3
209|Burke Av|2,5|13|3
210|Allerton Av|2,5|13|3
211|Pelham Pkwy|2,5|13|3
212|Bronx Park East|2,5|13|3
213|E 180 St|2,5|13|3
214|West Farms Sq-E Tremont Av|2,5|13|3
215|174 St|2,5|13|3
216|Freeman St|2,5|13|3
217|Simpson St|2,5|13|3
218|Intervale Av|2,5|13|3
219|Prospect Av|2,5|13|3
220|Jackson Av|2,5|13|3
221|3 Av-149 St|2,5|13|3
222|149 St-Hostos|2,5|13|3
224|135 St|2,3|7|6
225|125 St|2,3|7|6
226|116 St|2,3|7|6
227|110 St-Malcolm X Plaza|2,3|7|6
228|Park Place|2,3|7|5
229|Fulton St|2,3|7|5
230|Wall St|2,3|7|5
231|Clark St|2,3|3|2
232|Borough Hall|2,3|3|2
233|Hoyt St|2,3|3|2
234|Nevins St|2,3,4,5|3|2
235|Atlantic Av-Barclays Ctr|2,3,4,5|3|2
236|Bergen St|2,3|3|2
237|Grand Army Plaza|2,3|3|2
238|Eastern Pkwy-Brooklyn Museum|2,3|3|2
239|Franklin Av-Medgar Evers College|2,3,4,5|3|2
241|President St-Medgar Evers College|2,5|3|22
242|Sterling St|2,5|3|22
243|Winthrop St|2,5|3|22
244|Church Av|2,5|3|22
245|Beverly Rd|2,5|3|22
246|Newkirk Av-Little Haiti|2,5|3|22
247|Flatbush Av-Brooklyn College|2,5|3|1
248|Nostrand Av|3|3|2
249|Kingston Av|3|3|2
250|Crown Hts-Utica Av|3,4|3|2
251|Sutter Av-Rutland Rd|3|3|11
252|Saratoga Av|3|3|11
253|Rockaway Av|3|3|11
254|Junius St|3|3|11
255|Pennsylvania Av|3|3|11
256|Van Siclen Av|3|3|11
257|New Lots Av|3|3|1
301|Harlem-148 St|3|1|6
302|145 St|3|33|6
401|Woodlawn|4|1|3
402|Mosholu Pkwy|4|37|3
405|Bedford Park Blvd-Lehman College|4|13|3
406|Kingsbridge Rd|4|13|3
407|Fordham Rd|4|13|3
408|183 St|4|13|3
409|Burnside Av|4|13|3
410|176 St|4|13|3
411|Mt Eden Av|4|13|3
412|170 St|4|13|3
413|167 St|4|13|3
414|161 St-Yankee Stadium|4|13|3
415|149 St-Hostos|4|13|3
416|138 St-Grand Concourse|4,5|13|3
418|Fulton St|4,5|7|6
419|Wall St|4,5|7|6
420|Bowling Green|4,5|7|6
423|Borough Hall|4,5|3|2
501|Eastchester-Dyre Av|5|1|3
502|Baychester Av|5|21|3
503|Gun Hill Rd|5|21|3
504|Pelham Pkwy|5|21|3
505|Morris Park|5|21|3
601|Pelham Bay Park|6|1|3
602|Buhre Av|6|16|3
603|Middletown Rd|6|16|3
604|Westchester Sq-E Tremont Av|6|16|3
606|Zerega Av|6|16|3
607|Castle Hill Av|6|16|3
608|Parkchester|6|13|3
609|St Lawrence Av|6|13|3
610|Morrison Av-Soundview|6|13|3
611|Elder Av|6|13|3
612|Whitlock Av|6|13|3
613|Hunts Point Av|6|13|3
614|Longwood Av|6|13|3
615|E 149 St|6|13|3
616|E 143 St-St Mary's St|6|13|3
617|Cypress Av|6|13|3
618|Brook Av|6|13|3
619|3 Av-138 St|6|13|3
621|125 St|4,5,6|18|6
622|116 St|6|18|6
623|110 St|6|18|6
624|103 St|6|18|6
625|96 St|6|18|6
626|86 St|4,5,6|7|6
627|77 St|6|7|6
628|68 St-Hunter College|6|7|6
629|59 St|4,5,6|7|6
630|51 St|6|7|6
631|Grand Central-42 St|4,5,6|7|6
632|33 St|6|7|6
633|28 St|6|7|6
634|23 St-Baruch College|6|7|6
635|14 St-Union Sq|4,5,6|7|6
636|Astor Pl|6|7|6
637|Bleecker St|6|7|6
638|Spring St|6|7|6
639|Canal St|6|7|6
640|Brooklyn Bridge-City Hall|4,5,6|7|6
701|Flushing-Main St|7|1|3
702|Mets-Willets Point|7|2|3
705|111 St|7|2|3
706|103 St-Corona Plaza|7|2|3
707|Junction Blvd|7|2|3
708|90 St-Elmhurst Av|7|2|3
709|82 St-Jackson Hts|7|2|3
710|74 St-Broadway|7|2|3
711|69 St|7|2|3
712|61 St-Woodside|7|2|3
713|52 St|7|2|3
714|46 St-Bliss St|7|2|3
715|40 St-Lowery St|7|2|3
716|33 St-Rawson St|7|2|3
718|Queensboro Plaza|7|2|3
719|Court Sq|7|2|3
720|Hunters Point Av|7|2|3
721|Vernon Blvd-Jackson Av|7|2|3
723|Grand Central-42 St|7|12|23
724|5 Av|7|12|23
725|Times Sq-42 St|7|12|23
726|34 St-Hudson Yards|7|1|12
901|Grand Central-42 St|S|39|1
902|Times Sq-42 St|S|1|34
A02|Inwood-207 St|A|1|6
A03|Dyckman St|A|7|6
A05|190 St|A|7|6
A06|181 St|A|7|6
A07|175 St|A|7|6
A09|168 St|A,C|7|6
A10|163 St-Amsterdam Av|C|7|6
A11|155 St|C|7|6
A12|145 St|A,C|7|6
A14|135 St|C,B|7|6
A15|125 St|A,C,B,D|7|6
A16|116 St|C,B|7|6
A17|Cathedral Pkwy (110 St)|C,B|7|6
A18|103 St|C,B|7|6
A19|96 St|C,B|7|6
A20|86 St|C,B|7|6
A21|81 St-Museum of Natural History|C,B|7|6
A22|72 St|C,B|7|6
A24|59 St-Columbus Circle|A,C,B,D|7|6
A25|50 St|C,E|7|6
A27|42 St-Port Authority Bus Terminal|A,C,E|7|6
A28|34 St-Penn Station|A,C,E|7|6
A30|23 St|C,E|7|6
A31|14 St|A,C,E|7|6
A32|W 4 St-Wash Sq|A,C,E|7|6
A33|Spring St|C,E|7|6
A34|Canal St|A,C,E|7|6
A36|Chambers St|A,C|7|5
A38|Fulton St|A,C|7|5
A40|High St|A,C|3|2
A41|Jay St-MetroTech|A,C,F|3|2
A42|Hoyt-Schermerhorn Sts|A,C,G|38|12
A43|Lafayette Av|C|3|2
A44|Clinton-Washington Avs|C|3|2
A45|Franklin Av|C|3|2
A46|Nostrand Av|A,C|3|2
A47|Kingston-Throop Avs|C|3|2
A48|Utica Av|A,C|3|2
A49|Ralph Av|C|3|2
A50|Rockaway Av|C|3|2
A51|Broadway Junction|A,C|3|2
A52|Liberty Av|C|3|2
A53|Van Siclen Av|C|3|2
A54|Shepherd Av|C|3|2
A55|Euclid Av|A,C|3|12
A57|Grant Av|A|3|12
A59|80 St|A|3|2
A60|88 St|A|3|2
A61|Rockaway Blvd|A|3|2
A63|104 St|A|3|30
A64|111 St|A|3|30
A65|Ozone Park-Lefferts Blvd|A|3|1
B04|21 St-Queensbridge|M|2|3
B06|Roosevelt Island|M|12|6
B08|Lexington Av/63 St|M,Q|36|6
B10|57 St|M|7|6
B12|9 Av|D|3|14
B13|Fort Hamilton Pkwy|D|3|14
B14|50 St|D|3|14
B15|55 St|D|3|14
B16|62 St|D|3|14
B17|71 St|D|3|14
B18|79 St|D|3|14
B19|18 Av|D|3|14
B20|20 Av|D|3|14
B21|Bay Pkwy|D|3|14
B22|25 Av|D|3|17
B23|Bay 50 St|D|3|17
D01|Norwood-205 St|D|1|3
D03|Bedford Park Blvd|B,D|13|3
D04|Kingsbridge Rd|B,D|13|3
D05|Fordham Rd|B,D|13|3
D06|182-183 Sts|B,D|13|3
D07|Tremont Av|B,D|13|3
D08|174-175 Sts|B,D|13|3
D09|170 St|B,D|13|3
D10|167 St|B,D|13|3
D11|161 St-Yankee Stadium|B,D|13|3
D12|155 St|B,D|18|6
D13|145 St|B,D|7|6
D14|7 Av|E,B,D|2|6
D15|47-50 Sts-Rockefeller Ctr|B,D,F,M|7|6
D16|42 St-Bryant Pk|B,D,F,M|7|6
D17|34 St-Herald Sq|B,D,F,M|7|6
D18|23 St|F,M|7|6
D19|14 St|F,M|7|6
D20|W 4 St-Wash Sq|B,D,F,M|7|6
D21|Broadway-Lafayette St|B,D,F,M|7|6
D22|Grand St|B,D|7|5
D24|Atlantic Av-Barclays Ctr|B,Q|3|14
D25|7 Av|B,Q|3|14
D26|Prospect Park|B,Q,S|13|14
D27|Parkside Av|Q|3|14
D28|Church Av|B,Q|3|14
D29|Beverley Rd|Q|3|14
D30|Cortelyou Rd|Q|3|14
D31|Newkirk Plaza|B,Q|3|14
D32|Avenue H|Q|3|14
D33|Avenue J|Q|3|14
D34|Avenue M|Q|3|14
D35|Kings Hwy|B,Q|3|14
D37|Avenue U|Q|3|14
D38|Neck Rd|Q|3|14
D39|Sheepshead Bay|B,Q|3|14
D40|Brighton Beach|B,Q|3|14
D41|Ocean Pkwy|Q|3|17
D42|W 8 St-NY Aquarium|F,Q|3|17
D43|Coney Island-Stillwell Av|D,F,N,Q|3|1
E01|World Trade Center|E|7|1
F01|Jamaica-179 St|F|1|3
F02|169 St|F|20|3
F03|Parsons Blvd|F|20|3
F04|Sutphin Blvd|F|20|3
F05|Briarwood|E,F|20|3
F06|Kew Gardens-Union Tpke|E,F|20|3
F07|75 Av|E,F|20|3
F09|Court Sq-23 St|E,F|2|3
F11|Lexington Av/53 St|E,F|12|6
F12|5 Av/53 St|E,F|12|6
F14|2 Av|F|7|6
F15|Delancey St-Essex St|F|7|5
F16|East Broadway|F|7|5
F18|York St|F|3|14
F20|Bergen St|F,G|13|14
F21|Carroll St|F,G|13|14
F22|Smith-9 Sts|F,G|13|14
F23|4 Av-9 St|F,G|13|14
F24|7 Av|F,G|13|14
F25|15 St-Prospect Park|F,G|13|14
F26|Fort Hamilton Pkwy|F,G|13|14
F27|Church Av|F,G|13|14
F29|Ditmas Av|F|3|14
F30|18 Av|F|3|14
F31|Avenue I|F|3|14
F32|Bay Pkwy|F|3|14
F33|Avenue N|F|3|14
F34|Avenue P|F|3|14
F35|Kings Hwy|F|3|14
F36|Avenue U|F|3|17
F38|Avenue X|F|3|17
F39|Neptune Av|F|3|17
G05|Jamaica Center-Parsons/Archer|E,J,Z|1|3
G06|Sutphin Blvd-Archer Av-JFK Airport|E,J,Z|20|3
G07|Jamaica-Van Wyck|E|20|3
G08|Forest Hills-71 Av|E,F,M,R|2|3
G09|67 Av|M,R|2|3
G10|63 Dr-Rego Park|M,R|2|3
G11|Woodhaven Blvd|M,R|2|3
G12|Grand Av-Newtown|M,R|2|3
G13|Elmhurst Av|M,R|2|3
G14|Jackson Hts-Roosevelt Av|E,F,M,R|2|3
G15|65 St|M,R|2|3
G16|Northern Blvd|M,R|2|3
G18|46 St|M,R|2|3
G19|Steinway St|M,R|2|3
G20|36 St|M,R|2|3
G21|Queens Plaza|E,F,R|2|3
G22|Court Sq|G|1|5
G24|21 St|G|32|5
G26|Greenpoint Av|G|12|14
G28|Nassau Av|G|12|14
G29|Metropolitan Av|G|12|14
G30|Broadway|G|12|14
G31|Flushing Av|G|12|14
G32|Myrtle-Willoughby Avs|G|12|14
G33|Bedford-Nostrand Avs|G|12|14
G34|Classon Av|G|12|14
G35|Clinton-Washington Avs|G|12|14
G36|Fulton St|G|12|14
H01|Aqueduct Racetrack|A|3|24
H02|Aqueduct-N Conduit Av|A|3|24
H03|Howard Beach-JFK Airport|A|3|24
H04|Broad Channel|A,S|0|24
H06|Beach 67 St|A|3|28
H07|Beach 60 St|A|3|28
H08|Beach 44 St|A|3|28
H09|Beach 36 St|A|3|28
H10|Beach 25 St|A|3|28
H11|Far Rockaway-Mott Av|A|3|1
H12|Beach 90 St|A,S|0|19
H13|Beach 98 St|A,S|0|19
H14|Beach 105 St|A,S|0|19
H15|Rockaway Park-Beach 116 St|A,S|0|1
J12|121 St|J,Z|20|3
J13|111 St|J|20|3
J14|104 St|J,Z|20|3
J15|Woodhaven Blvd|J,Z|20|3
J16|85 St-Forest Pkwy|J|20|3
J17|75 St-Elderts Ln|J,Z|20|3
J19|Cypress Hills|J|12|3
J20|Crescent St|J,Z|2|3
J21|Norwood Av|J,Z|2|3
J22|Cleveland St|J|2|3
J23|Van Siclen Av|J,Z|2|3
J24|Alabama Av|J,Z|2|3
J27|Broadway Junction|J,Z|2|3
J28|Chauncey St|J,Z|2|3
J29|Halsey St|J|2|3
J30|Gates Av|J,Z|2|3
J31|Kosciuszko St|J|2|3
L01|8 Av|L|1|5
L02|6 Av|L|29|5
L03|14 St-Union Sq|L|29|5
L05|3 Av|L|29|5
L06|1 Av|L|29|5
L08|Bedford Av|L|3|2
L10|Lorimer St|L|3|2
L11|Graham Av|L|3|2
L12|Grand St|L|3|2
L13|Montrose Av|L|3|2
L14|Morgan Av|L|3|2
L15|Jefferson St|L|3|2
L16|DeKalb Av|L|3|2
L17|Myrtle-Wyckoff Avs|L|3|2
L19|Halsey St|L|3|2
L20|Wilson Av|L|3|2
L21|Bushwick Av-Aberdeen St|L|3|2
L22|Broadway Junction|L|3|2
L24|Atlantic Av|L|3|27
L25|Sutter Av|L|3|27
L26|Livonia Av|L|3|27
L27|New Lots Av|L|3|27
L28|East 105 St|L|3|27
L29|Canarsie-Rockaway Pkwy|L|3|1
M01|Middle Village-Metropolitan Av|M|0|1
M04|Fresh Pond Rd|M|0|4
M05|Forest Av|M|0|4
M06|Seneca Av|M|0|4
M08|Myrtle-Wyckoff Avs|M|0|4
M09|Knickerbocker Av|M|0|4
M10|Central Av|M|0|4
M11|Myrtle Av|M,J,Z|2|3
M12|Flushing Av|M,J|2|3
M13|Lorimer St|M,J|2|3
M14|Hewes St|M,J|2|3
M16|Marcy Av|M,J,Z|2|3
M18|Delancey St-Essex St|M,J,Z|5|0
M19|Bowery|J,Z|5|6
M20|Canal St|J,Z|5|6
M21|Chambers St|J,Z|5|6
M22|Fulton St|J,Z|5|6
M23|Broad St|J,Z|5|1
N02|8 Av|N|3|17
N03|Fort Hamilton Pkwy|N|3|17
N04|New Utrecht Av|N|3|17
N05|18 Av|N|3|17
N06|20 Av|N|3|17
N07|Bay Pkwy|N|3|17
N08|Kings Hwy|N|3|17
N09|Avenue U|N|3|17
N10|86 St|N|3|17
Q01|Canal St|N,Q|7|6
Q03|72 St|Q|7|6
Q04|86 St|Q|7|6
Q05|96 St|Q|1|6
R01|Astoria-Ditmars Blvd|N,W|1|3
R03|Astoria Blvd|N,W|26|3
R04|30 Av|N,W|26|3
R05|Broadway|N,W|26|3
R06|36 Av|N,W|26|3
R08|39 Av-Dutch Kills|N,W|26|3
R09|Queensboro Plaza|N,W|26|3
R11|Lexington Av/59 St|N,R,W|12|6
R13|5 Av/59 St|N,R,W|12|6
R14|57 St-7 Av|N,Q,R,W|7|6
R15|49 St|N,R,W|7|6
R16|Times Sq-42 St|N,Q,R,W|7|6
R17|34 St-Herald Sq|N,Q,R,W|7|6
R18|28 St|R,W|7|6
R19|23 St|R,W|7|6
R20|14 St-Union Sq|N,Q,R,W|7|6
R21|8 St-NYU|R,W|7|6
R22|Prince St|R,W|7|6
R23|Canal St|R,W|7|6
R24|City Hall|R,W|7|6
R25|Cortlandt St|R,W|7|6
R26|Rector St|R,W|7|6
R27|Whitehall St-South Ferry|R,W|7|6
R28|Court St|R|3|14
R29|Jay St-MetroTech|R|3|14
R30|DeKalb Av|B,Q,R|3|14
R31|Atlantic Av-Barclays Ctr|D,N,R|3|14
R32|Union St|R|3|14
R33|4 Av-9 St|R|3|14
R34|Prospect Av|R|3|14
R35|25 St|R|3|14
R36|36 St|D,N,R|3|14
R39|45 St|R|3|14
R40|53 St|R|3|14
R41|59 St|N,R|3|14
R42|Bay Ridge Av|R|3|15
R43|77 St|R|3|15
R44|86 St|R|3|15
R45|Bay Ridge-95 St|R|3|1
S01|Franklin Av|S|1|10
S03|Park Pl|S|35|10
S04|Botanic Garden|S|35|10
S09|Tottenville|SI|8|1
S11|Arthur Kill|SI|8|31
S13|Richmond Valley|SI|8|31
S14|Pleasant Plains|SI|8|9
S15|Prince's Bay|SI|8|9
S16|Huguenot|SI|8|9
S17|Annadale|SI|8|9
S18|Eltingville|SI|8|9
S19|Great Kills|SI|8|9
S20|Bay Terrace|SI|8|9
S21|Oakwood Heights|SI|8|9
S22|New Dorp|SI|8|9
S23|Grant City|SI|8|9
S24|Jefferson Av|SI|8|9
S25|Dongan Hills|SI|8|9
S26|Old Town|SI|8|9
S27|Grasmere|SI|8|9
S28|Clifton|SI|8|9
S29|Stapleton|SI|8|9
S30|Tompkinsville|SI|8|9
S31|St George|SI|1|9
"""

# --- END GENERATED STATION DATA ---

# ---------------------------------------------------------------- stations

def station(stop_id):
    """Look up a parent stop. The table is one record per line, so a find for
    "\\n<id>|" is an exact-prefix match without splitting 12 KB of text."""
    i = STATIONS.find("\n" + stop_id + "|")
    if i < 0:
        return None
    j = STATIONS.find("\n", i + 1)
    f = STATIONS[i + 1:j].split("|")
    return {
        "id": f[0],
        "name": f[1],
        "routes": f[2].split(","),
        "north": DIRS[int(f[3])],
        "south": DIRS[int(f[4])],
    }

def station_name(stop_id):
    """Name for a realtime stop id (parent id plus N/S)."""
    s = station(stop_id[:-1])
    return s["name"] if s else stop_id

# The 44 stops that actually terminate a trip, in the short form the MTA's own
# countdown clocks use ("242 St", not "Van Cortlandt Park-242 St"). Two wins:
# it is what a rider sees on the platform, and every value fits the 55px name
# column, so the row renders as a still instead of a scrolling animation.
# Anything not listed - a reroute terminating somewhere unusual - falls back to
# the full station name and scrolls. Regenerate the candidate list with:
#   the last stop_time_update of every trip across all eight feeds.
TERMINALS = {
    "101": "242 St",
    "142": "South Ferry",
    "201": "241 St",
    "247": "Flatbush Av",
    "250": "Utica Av",
    "257": "New Lots Av",
    "301": "148 St",
    "401": "Woodlawn",
    "501": "Dyre Av",
    "601": "Pelham Bay",
    "608": "Parkchester",
    "640": "Bklyn Bridge",
    "701": "Main St",
    "726": "Hudson Yds",
    "901": "Grand Central",
    "902": "Times Sq",
    "A02": "Inwood-207 St",
    "A09": "168 St",
    "A55": "Euclid Av",
    "A65": "Lefferts Blvd",
    "D01": "Norwood-205 St",
    "D26": "Prospect Pk",
    "D40": "Brighton Bch",
    "D43": "Coney Island",
    "E01": "WTC",
    "F01": "179 St",
    "F27": "Church Av",
    "G05": "Jamaica Ctr",
    "G08": "Forest Hills",
    "G22": "Court Sq",
    "H11": "Far Rockaway",
    "H15": "Rockaway Pk",
    "H19": "Rockaway Pk",
    "L01": "8 Av",
    "L29": "Canarsie",
    "M01": "Middle Vlg",
    "M23": "Broad St",
    "Q05": "96 St",
    "R01": "Astoria",
    "R27": "Whitehall St",
    "R45": "95 St",
    "S01": "Franklin Av",
    "S09": "Tottenville",
    "S31": "St George",
}

def terminal_name(stop_id):
    """Where a train is going, as the platform signs word it."""
    parent = stop_id[:-1]
    short = TERMINALS.get(parent)
    if short:
        return short
    return station_name(stop_id)

# ------------------------------------------------- gtfs-realtime wire format
#
# Only the fields we need, skipping everything else by length:
#   FeedMessage   1 header        2 entity
#   FeedHeader    3 timestamp
#   FeedEntity    3 trip_update
#   TripUpdate    1 trip          2 stop_time_update
#   TripDescriptor 5 route_id     1001 nyct_trip_descriptor
#   NyctTripDescriptor            2 is_assigned
#   StopTimeUpdate 2 arrival      3 departure       4 stop_id
#   StopTimeEvent  2 time

def rd_varint(d, i):
    v = 0
    shift = 0
    for _ in range(10):
        b = d[i]
        i += 1
        v |= (b & 0x7F) << shift
        if b < 0x80:
            break
        shift += 7
    return v, i

def skip(d, i, wire):
    if wire == 0:
        _, i = rd_varint(d, i)
        return i
    if wire == 2:
        n, i = rd_varint(d, i)
        return i + n
    if wire == 5:
        return i + 4
    if wire == 1:
        return i + 8
    return i

def rd_len(d, i):
    n, i = rd_varint(d, i)
    return i, i + n

def ste_time(d, start, end):
    t = 0
    i = start
    for _ in range(8):
        if i >= end:
            break
        tag, i = rd_varint(d, i)
        if tag >> 3 == 2 and tag & 7 == 0:
            t, i = rd_varint(d, i)
        else:
            i = skip(d, i, tag & 7)
    return t

def parse_stop_time_update(body, d, start, end):
    stop, arrive, depart = "", 0, 0
    i = start
    for _ in range(16):
        if i >= end:
            break
        tag, i = rd_varint(d, i)
        field, wire = tag >> 3, tag & 7
        if field == 4 and wire == 2:
            i, k = rd_len(d, i)
            stop = body[i:k]
            i = k
        elif field == 2 and wire == 2:
            i, k = rd_len(d, i)
            arrive = ste_time(d, i, k)
            i = k
        elif field == 3 and wire == 2:
            i, k = rd_len(d, i)
            depart = ste_time(d, i, k)
            i = k
        else:
            i = skip(d, i, wire)
    return stop, arrive, depart

def parse_nyct_trip(d, start, end):
    assigned = False
    i = start
    for _ in range(12):
        if i >= end:
            break
        tag, i = rd_varint(d, i)
        field, wire = tag >> 3, tag & 7
        if field == 2 and wire == 0:
            v, i = rd_varint(d, i)
            assigned = v != 0
        else:
            i = skip(d, i, wire)
    return assigned

def parse_trip(body, d, start, end):
    route = ""
    assigned = False
    i = start
    for _ in range(16):
        if i >= end:
            break
        tag, i = rd_varint(d, i)
        field, wire = tag >> 3, tag & 7
        if field == 5 and wire == 2:
            i, k = rd_len(d, i)
            route = body[i:k]
            i = k
        elif field == 1001 and wire == 2:
            i, k = rd_len(d, i)
            assigned = parse_nyct_trip(d, i, k)
            i = k
        else:
            i = skip(d, i, wire)
    return route, assigned

def parse_trip_update(body, d, start, end, target):
    """Arrival at `target` for one trip, plus the trip's terminal stop."""
    route, assigned, when, last_stop = "", False, 0, ""
    i = start
    for _ in range(400):
        if i >= end:
            break
        tag, i = rd_varint(d, i)
        field, wire = tag >> 3, tag & 7
        if field == 1 and wire == 2:
            i, k = rd_len(d, i)
            route, assigned = parse_trip(body, d, i, k)
            i = k
        elif field == 2 and wire == 2:
            i, k = rd_len(d, i)
            stop, arrive, depart = parse_stop_time_update(body, d, i, k)
            if stop:
                last_stop = stop
            if stop == target:
                when = arrive if arrive > 0 else depart
            i = k
        else:
            i = skip(d, i, wire)
    if when <= 0:
        return None
    return {"route": route, "t": when, "dest": last_stop, "assigned": assigned}

def feed_arrivals(body, target):
    """Every arrival at `target` in one feed, plus the feed's own timestamp.

    Entities are prefiltered with a byte search for the encoded stop_id field
    (tag 0x22, length, id) so we only descend into the handful of trips that
    actually call at this stop."""
    d = list(body.elem_ords())
    n = len(d)

    # chr() is only byte-safe below 128; 0x22 is the stop_id field tag and the
    # length is always 4-5, so both encode as single bytes. (ord() is NOT safe
    # here - it UTF-8-decodes - which is why the reader uses elem_ords above.)
    needle = chr(0x22) + chr(len(target)) + target
    out = []
    feed_ts = 0
    i = 0
    for _ in range(4000):
        if i >= n:
            break
        tag, i = rd_varint(d, i)
        field, wire = tag >> 3, tag & 7
        if field == 1 and wire == 2:
            i, k = rd_len(d, i)
            if k > n:
                break
            h = i
            for _ in range(8):
                if h >= k:
                    break
                htag, h = rd_varint(d, h)
                if htag >> 3 == 3 and htag & 7 == 0:
                    feed_ts, h = rd_varint(d, h)
                else:
                    h = skip(d, h, htag & 7)
            i = k
        elif field == 2 and wire == 2:
            i, k = rd_len(d, i)
            if k > n:
                # Truncated response: stop rather than index past the end.
                break
            if body.find(needle, i, k) >= 0:
                e = i
                for _ in range(12):
                    if e >= k:
                        break
                    etag, e = rd_varint(d, e)
                    if etag >> 3 == 3 and etag & 7 == 2:
                        e, m = rd_len(d, e)
                        got = parse_trip_update(body, d, e, m, target)
                        if got:
                            out.append(got)
                        e = m
                    else:
                        e = skip(d, e, etag & 7)
            i = k
        else:
            i = skip(d, i, wire)
    return out, feed_ts

# ------------------------------------------------------------------ alerts
#
# The unplanned, currently-live alerts are exactly those whose active_period has
# no `end` and which carry no human_readable_active_period. That rule cuts ~197
# alerts down to the handful that a rider standing on the platform cares about.

ALERT_TOKEN = {
    "Part Suspended": ("NO TRAINS", 5),
    "Suspended": ("NO TRAINS", 5),
    "No Scheduled Service": ("NO SVC", 5),
    "Severe Delays": ("BIG DELAYS", 4),
    "Delays": ("DELAYS", 3),
    "Stops Skipped": ("SKIPPING", 3),
    "Reduced Service": ("LESS SVC", 3),
    "Express to Local": ("RUNNING LCL", 2),
    "Local to Express": ("RUNNING EXP", 2),
    "Boarding Change": ("BOARD CHG", 2),
    "Special Schedule": ("SPEC SCHED", 1),
    "Station Notice": ("NOTICE", 1),
    "Slow Speeds": ("SLOW", 2),
}

def route_alerts(routes, now):
    """Per-route live disruptions: route -> (token, rank).

    Alerts are matched by route, never by station: every live unplanned alert
    carries route_id only, and the alerts that do carry stop_ids are all
    planned work."""
    resp = http.get(ALERTS_URL, ttl_seconds = ALERT_TTL)
    if resp.status_code != 200:
        return {}

    wanted = {r: True for r in routes}
    out = {}
    for entity in resp.json().get("entity", []):
        alert = entity.get("alert")
        if not alert:
            continue

        kind = alert.get("transit_realtime.mercury_alert", {}).get("alert_type", "")
        if kind.startswith("Planned"):
            continue

        # Live and open-ended, not a scheduled window.
        live = False
        for period in alert.get("active_period", []):
            if period.get("end", 0) == 0 and period.get("start", 0) <= now:
                live = True
        if not live:
            continue

        token, rank = ALERT_TOKEN.get(kind, (kind.upper(), 2))
        for selector in alert.get("informed_entity", []):
            route = selector.get("route_id", "")
            if route in wanted and rank > out.get(route, ("", 0))[1]:
                out[route] = (token, rank)
    return out

def alert_strip(alerts):
    """"BIG DELAYS A  SKIPPING C" - worst first, routes grouped by token."""
    if not alerts:
        return ""
    ranked = sorted([(alerts[r][1], alerts[r][0], r) for r in alerts], reverse = True)
    groups = []
    for item in ranked:
        tok, r = item[1], item[2]
        if groups and groups[-1][0] == tok:
            groups[-1][1].append(r)
        else:
            groups.append([tok, [r]])
    return "  ".join([g[0] + " " + "".join(sorted(g[1])) for g in groups])

# ------------------------------------------------------------------ render

def bullet(route, size = 7):
    label = route
    if route in ("GS", "FS", "H", "S"):
        label = "S"
    elif route.endswith("X"):
        label = route[0]
    base = label[0]
    fill = COLORS.get(route, COLORS.get(base, "#666666"))
    glyph = "#000000" if base in DARK_GLYPH else WHITE
    if label == "G":
        # tom-thumb's G is a dead ringer for its 6 at this size. The CG pixel
        # font has a real flat-topped G, but Circle's child centering clips its
        # left column - so center it in a Box laid over a bare circle instead.
        return render.Stack(children = [
            render.Circle(color = fill, diameter = size),
            render.Box(width = size, height = size, child = render.Text(
                "G",
                font = "CG-pixel-3x5-mono",
                color = glyph,
            )),
        ])
    return render.Circle(
        color = fill,
        diameter = size,
        child = render.Text(label, font = "tom-thumb", color = glyph),
    )

def minutes_until(seconds):
    """Whole minutes, rounded up, never negative. A train 20 s in the past is
    'here now', not '-1'."""
    if seconds < 30:
        return 0
    return (seconds + 29) // 60

def hero_number(text, color):
    return render.Text(text, font = "10x20", color = color)

def fit_text(text, width, font, color):
    """Static Text when it fits, Marquee only when it genuinely overflows.

    render.Marquee animates unconditionally, so wrapping short text in one turns
    a 1-frame still into a ~150-frame WebP that the device must hold and replay.
    tom-thumb is at most 4px per character, so len*4 is a safe overestimate -
    it may scroll a hair early, but it never clips."""
    child = render.Text(text, font = font, color = color)
    if len(text) * 4 <= width:
        return child
    return render.Marquee(width = width, align = "start", child = child)

def top_row(train, stale, both):
    kids = [render.Box(width = 9, height = 7, child = bullet(train["route"]))]
    dest_width = 55
    if both:
        kids.append(render.Box(
            width = 5,
            height = 7,
            child = arrow_glyph(train["dir"] == "N", GREY),
        ))
        dest_width = 50
    kids.append(render.Box(width = dest_width, height = 7, child = fit_text(
        terminal_name(train["dest"]),
        dest_width,
        "tom-thumb",
        DIM if stale else WHITE,
    )))
    return render.Box(
        width = 64,
        height = 7,
        child = render.Row(cross_align = "center", children = kids),
    )

def context_line(st, direction, both):
    """Station, plus the MTA's own platform wording for this direction when both
    fit on one line. Keeping it inside 64px is what lets the row render as a
    still; the terminal up top already implies the direction, so the station
    name is the part worth keeping when only one will fit."""
    name = st["name"]
    if both:
        return name
    which = st["north"] if direction == "N" else st["south"]
    line = name + " " + which
    if len(line) * 4 <= 64:
        return line
    return name

def bottom_row(left, color):
    return render.Box(
        width = 64,
        height = 6,
        child = fit_text(left, 64, "tom-thumb", color),
    )

def middle_row(hero, hero_color, label, follow, follow_up = None):
    # 27px holds two digits of 10x20; 19px is one short of the font's line box
    # but the digits have no descender, so nothing clips.
    lines = [render.Text(label, font = "tom-thumb", color = GREY)]
    if follow:
        lines.append(render.Box(width = 1, height = 2))
        if follow_up == None:
            lines.append(render.Text(follow, font = "tom-thumb", color = DIM))
        else:
            # Both-directions mode: say which way the follow-up train runs.
            lines.append(render.Row(cross_align = "center", children = [
                render.Text(follow, font = "tom-thumb", color = DIM),
                render.Box(width = 2, height = 1),
                render.Box(width = 3, height = 7, child = arrow_glyph(follow_up, DIM)),
            ]))
    return render.Box(
        width = 64,
        height = 19,
        child = render.Row(
            cross_align = "center",
            children = [
                render.Box(width = 27, height = 19, child = hero_number(hero, hero_color)),
                render.Box(
                    width = 37,
                    height = 19,
                    child = render.Column(main_align = "center", children = lines),
                ),
            ],
        ),
    )

def message(text):
    return render.Root(
        child = render.Box(
            width = 64,
            height = 32,
            child = render.WrappedText(
                text,
                font = "tom-thumb",
                color = GREY,
                align = "center",
                width = 64,
            ),
        ),
    )

# ---------------------------------------------------- station-board face
#
# Halfway between the platform sign and a both-directions split: a ranked list
# of up to three trains across every line at the station, an optional
# direction filter (one platform, or both at once with a chevron per row),
# per-route delay tinting, and a bottom strip that names the disruption.
# Nothing renders blank: short text is static, only genuine overflow scrolls.

def arrow_glyph(up, color):
    """3x5 direction chevron: tip, full-width head, 1px tail."""
    tip = render.Row(children = [
        render.Box(width = 1, height = 1),
        render.Box(width = 1, height = 1, color = color),
    ])
    head = render.Box(width = 3, height = 1, color = color)
    tail = render.Row(children = [
        render.Box(width = 1, height = 1),
        render.Box(width = 1, height = 1, color = color),
    ])
    seq = [tip, head, tail, tail, tail]
    if not up:
        seq = [tail, tail, tail, head, tip]
    return render.Column(children = seq)

# The shared TERMINALS shorts target the hero layout's 55px column; the board
# rows have 40px (both) / 43px (single), so the long ones get a tighter form
# and everything else falls through. Scroll stays the exception.
BOARD_SHORT = {
    "Bklyn Bridge": "Bklyn Br",
    "Brighton Bch": "Brighton",
    "Coney Island": "Coney Is",
    "Far Rockaway": "Far Rckwy",
    "Flatbush Av": "Flatbush",
    "Forest Hills": "Forest Hls",
    "Franklin Av": "Franklin",
    "Grand Central": "Grand Ctrl",
    "Inwood-207 St": "Inwood",
    "Jamaica Ctr": "Jamaica",
    "Lefferts Blvd": "Lefferts",
    "New Lots Av": "New Lots",
    "Norwood-205 St": "Norwood",
    "Rockaway Pk": "Rckwy Pk",
    "South Ferry": "S Ferry",
    "Whitehall St": "Whitehall",
}

def board_dest(stop_id):
    name = terminal_name(stop_id)
    return BOARD_SHORT.get(name, name)

def board_row(t, now, both, delayed):
    mins = minutes_until(t["t"] - now)
    if not t["catch"]:
        col, dest_col = "#4A4A4A", "#4A4A4A"
    elif mins <= 0:
        col, dest_col = GREEN, WHITE
    elif delayed:
        col, dest_col = RED, WHITE
    else:
        col, dest_col = AMBER, WHITE
    kids = [render.Box(width = 8, height = 8, child = bullet(t["route"], 7))]
    if both:
        kids.append(render.Box(
            width = 5,
            height = 8,
            child = arrow_glyph(t["dir"] == "N", GREY),
        ))
        dest_width = 40
    else:
        # No chevron column - give the destination the same breathing room.
        kids.append(render.Box(width = 2, height = 8))
        dest_width = 43
    kids.append(render.Box(width = dest_width, height = 8, child = render.Row(
        expanded = True,
        main_align = "start",
        cross_align = "center",
        children = [fit_text(board_dest(t["dest"]), dest_width, "tom-thumb", dest_col)],
    )))
    kids.append(render.Box(
        width = 64 - 8 - (5 if both else 2) - dest_width,
        height = 8,
        child = render.Row(main_align = "end", expanded = True, children = [
            render.Text(str(mins), font = "tom-thumb", color = col),
        ]),
    ))
    return render.Box(
        width = 64,
        height = 8,
        child = render.Row(cross_align = "center", children = kids),
    )

def strip_row(st, direction, both, alerts, stale_mins):
    text = alert_strip(alerts)
    if text:
        color = RED
    elif stale_mins > 0:
        text = "STALE " + str(stale_mins) + "m"
        color = RED
    else:
        if not both:
            # Station plus a direction chevron - clearer than the dataset's
            # generic "Northbound"/"Southbound" wording, and it never scrolls
            # just because the label word was long.
            return render.Box(width = 64, height = 8, child = render.Row(
                cross_align = "center",
                children = [
                    render.Box(
                        width = 56,
                        height = 8,
                        child = fit_text(st["name"], 56, "tom-thumb", DIM),
                    ),
                    render.Box(
                        width = 3,
                        height = 8,
                        child = arrow_glyph(direction == "N", DIM),
                    ),
                ],
            ))
        text = st["name"]
        color = DIM
    return render.Box(width = 64, height = 8, child = fit_text(text, 64, "tom-thumb", color))

def board_face(st, direction, both, walk, trains, alerts, stale_mins, now):
    top = trains[:3]
    if walk > 0:
        catchable = [t for t in trains if t["catch"]]
        if catchable and not [t for t in top if t["catch"]]:
            # All three visible trains are ones you would miss - swap the last
            # slot for the first train you can actually make.
            top = top[:2] + [catchable[0]]
    rows = []
    for t in top:
        delayed = alerts.get(t["route"], ("", 0))[1] >= 3
        rows.append(board_row(t, now, both, delayed))
    for _ in range(3 - len(top)):
        rows.append(render.Box(width = 64, height = 8))
    rows.append(strip_row(st, direction, both, alerts, stale_mins))
    return render.Root(delay = 90, child = render.Column(children = rows))

def hero_face(st, direction, both, walk, trains, alerts, stale_mins, now):
    catchable = [t for t in trains if t["catch"]]
    hero = catchable[0] if catchable else trains[0]
    missed = len(catchable) == 0
    secs = hero["t"] - now
    stale = stale_mins > 0

    if walk > 0 and not missed:
        leave_in = minutes_until(secs - walk * 60)
        if leave_in <= 0:
            hero_text, hero_color, label = "GO", GREEN, "LEAVE NOW"
        else:
            hero_text, hero_color, label = str(leave_in), AMBER, "LEAVE IN"
    else:
        mins = minutes_until(secs)
        if missed:
            # Every train we know about arrives sooner than the walk takes.
            hero_text, hero_color, label = "--", DIM, "MISSED"
        elif mins == 0:
            hero_text, hero_color, label = str(mins), GREEN, "ARRIVING"
        elif hero["assigned"]:
            hero_text, hero_color, label = str(mins), AMBER, "MIN"
        else:
            # Scheduled, but the MTA has not put a train on it yet.
            hero_text, hero_color, label = str(mins), AMBER, "SCHED"

    if stale:
        hero_color = DIM

    # The next reachable train after the hero, so a "GO" is never a cliff edge.
    follow = ""
    follow_up = None
    rest = [t for t in catchable if t["t"] > hero["t"]]
    if rest:
        follow = "then " + str(minutes_until(rest[0]["t"] - now))
        if both:
            follow_up = rest[0]["dir"] == "N"

    strip = alert_strip(alerts)
    if strip:
        bottom = bottom_row(strip, RED)
    elif stale:
        bottom = bottom_row("STALE " + str(stale_mins) + "m", RED)
    else:
        bottom = bottom_row(context_line(st, direction, both), DIM)

    return render.Root(
        delay = 90,
        child = render.Column(
            children = [
                top_row(hero, stale, both),
                middle_row(hero_text, hero_color, label, follow, follow_up),
                bottom,
            ],
        ),
    )

# -------------------------------------------------------------------- main

def main(config):
    # Empty config must do NO network I/O: pixlet check profiles the app with an
    # empty config against a 1s budget that includes HTTP wall clock, and a
    # default that fetches would make CI hostage to the MTA being up. Real users
    # still land on a working app - the schema's own default fills this in.
    stop_id = config.str("station", "")
    if not stop_id:
        return message("Pick a station")

    layout = config.str("layout", "board")
    direction = config.str("direction", "B")
    walk_raw = config.str("walk", "0")
    walk = int(walk_raw) if walk_raw and walk_raw.isdigit() else 0

    st = station(stop_id)
    if not st:
        return message("Pick a station")
    both = direction == "B"
    letters = ["N", "S"] if both else [direction]

    trains = []
    feed_ts = 0
    reached = 0
    for suffix in feeds_for(st):
        resp = http.get(FEED_BASE + suffix, ttl_seconds = FEED_TTL)
        if resp.status_code != 200:
            continue
        reached += 1
        body = resp.body()
        for letter in letters:
            found, ts = feed_arrivals(body, stop_id + letter)
            for f in found:
                f["dir"] = letter
            trains.extend(found)
            feed_ts = max(feed_ts, ts)

    now = int(time.now().unix)

    if reached == 0:
        return message("MTA feed\nunreachable")

    trains = sorted([t for t in trains if t["t"] - now > -60], key = lambda t: t["t"])
    for t in trains:
        # With no walk configured every train is catchable - a train that left
        # 45 s ago reads as an arriving 0, not a dimmed ghost row.
        t["catch"] = walk == 0 or t["t"] - now + 45 >= walk * 60

    alerts = route_alerts(st["routes"], now)
    stale_mins = (now - feed_ts) // 60 if feed_ts > 0 and now - feed_ts > 180 else 0

    if not trains:
        strip = alert_strip(alerts)
        if strip:
            return message(strip)
        which = "either way" if both else (st["north"] if direction == "N" else st["south"])
        return message("No trains\n" + st["name"] + "\n" + which)

    if layout == "hero":
        return hero_face(st, direction, both, walk, trains, alerts, stale_mins, now)
    return board_face(st, direction, both, walk, trains, alerts, stale_mins, now)

def station_options():
    """Every station, disambiguated by the routes that serve it - there are 76
    duplicate station names (six "86 St", six "Canal St")."""
    options = []
    for line in STATIONS.strip().split("\n"):
        f = line.split("|")
        options.append(schema.Option(
            display = f[1] + " (" + f[2].replace(",", " ") + ")",
            value = f[0],
        ))
    return options

def get_schema():
    # Direction is a plain dropdown rather than a schema.Generated field keyed on
    # the station. Generated is documented as buggy, and losing the field would
    # leave the app unconfigurable; the station's own wording ("Uptown",
    # "Coney Island") is shown on the display instead, where it is more use.
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "station",
                name = "Station",
                desc = "Which station to watch.",
                icon = "train",
                default = "L08",
                options = station_options(),
            ),
            schema.Dropdown(
                id = "layout",
                name = "Layout",
                desc = "Station board lists the next three trains across every line; " +
                       "big number shows one train, readable across the room.",
                icon = "tableList",
                default = "board",
                options = [
                    schema.Option(display = "Station board - up to 3 trains", value = "board"),
                    schema.Option(display = "Big number - one train, huge", value = "hero"),
                ],
            ),
            schema.Dropdown(
                id = "direction",
                name = "Direction",
                desc = "One platform, or every train at the station. Railroad north is " +
                       "uptown, the Bronx and Queens; south is downtown and Brooklyn.",
                icon = "arrowsUpDown",
                default = "B",
                options = [
                    schema.Option(display = "Both directions", value = "B"),
                    schema.Option(display = "Northbound - uptown, Bronx, Queens", value = "N"),
                    schema.Option(display = "Southbound - downtown, Brooklyn", value = "S"),
                ],
            ),
            schema.Dropdown(
                id = "walk",
                name = "Walk to station",
                desc = "Minutes from your door to the platform. Big number counts down " +
                       "to when you leave; the board dims trains you would miss.",
                icon = "personWalking",
                default = "0",
                options = [
                    schema.Option(display = "Not set - show train times", value = "0"),
                ] + [
                    schema.Option(display = str(m) + " min", value = str(m))
                    for m in range(1, 31)
                ],
            ),
        ],
    )
