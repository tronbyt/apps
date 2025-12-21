"""
Applet: Colorado14ers
Summary: Colorado 14ers Tracker
Description: Track your Colorado 14ers.
Author: Robert Ison
"""

load("humanize.star", "humanize")
load("images/blanca_peak.png", BLANCA_PEAK_ASSET = "file")
load("images/capitol_peak.png", CAPITOL_PEAK_ASSET = "file")
load("images/castle_peak.png", CASTLE_PEAK_ASSET = "file")
load("images/challenger_point.png", CHALLENGER_POINT_ASSET = "file")
load("images/crestone_needle.png", CRESTONE_NEEDLE_ASSET = "file")
load("images/crestone_peak.png", CRESTONE_PEAK_ASSET = "file")
load("images/culebra_peak.png", CULEBRA_PEAK_ASSET = "file")
load("images/ellingwood_point.png", ELLINGWOOD_POINT_ASSET = "file")
load("images/grays_peak.png", GRAYS_PEAK_ASSET = "file")
load("images/handies_peak.png", HANDIES_PEAK_ASSET = "file")
load("images/humboldt_peak.png", HUMBOLDT_PEAK_ASSET = "file")
load("images/huron_peak.png", HURON_PEAK_ASSET = "file")
load("images/kit_carson_peak.png", KIT_CARSON_PEAK_ASSET = "file")
load("images/la_plata_peak.png", LA_PLATA_PEAK_ASSET = "file")
load("images/little_bear_peak.png", LITTLE_BEAR_PEAK_ASSET = "file")
load("images/longs_peak.png", LONGS_PEAK_ASSET = "file")
load("images/maroon_peak.png", MAROON_PEAK_ASSET = "file")
load("images/missouri_mountain.png", MISSOURI_MOUNTAIN_ASSET = "file")
load("images/mt_antero.png", MT_ANTERO_ASSET = "file")
load("images/mt_belford.png", MT_BELFORD_ASSET = "file")
load("images/mt_bierstadt.png", MT_BIERSTADT_ASSET = "file")
load("images/mt_blue_sky.png", MT_BLUE_SKY_ASSET = "file")
load("images/mt_bross.png", MT_BROSS_ASSET = "file")
load("images/mt_columbia.png", MT_COLUMBIA_ASSET = "file")
load("images/mt_democrat.png", MT_DEMOCRAT_ASSET = "file")
load("images/mt_elbert.png", MT_ELBERT_ASSET = "file")
load("images/mt_eolus.png", MT_EOLUS_ASSET = "file")
load("images/mt_harvard.png", MT_HARVARD_ASSET = "file")
load("images/mt_holy_cross.png", MT_HOLY_CROSS_ASSET = "file")
load("images/mt_lincoln.png", MT_LINCOLN_ASSET = "file")
load("images/mt_lindsey.png", MT_LINDSEY_ASSET = "file")
load("images/mt_massive.png", MT_MASSIVE_ASSET = "file")
load("images/mt_oxford.png", MT_OXFORD_ASSET = "file")
load("images/mt_princeton.png", MT_PRINCETON_ASSET = "file")
load("images/mt_shavano.png", MT_SHAVANO_ASSET = "file")
load("images/mt_sherman.png", MT_SHERMAN_ASSET = "file")
load("images/mt_sneffels.png", MT_SNEFFELS_ASSET = "file")
load("images/mt_wilson.png", MT_WILSON_ASSET = "file")
load("images/mt_yale.png", MT_YALE_ASSET = "file")
load("images/pikes_peak.png", PIKES_PEAK_ASSET = "file")
load("images/pyramid_peak.png", PYRAMID_PEAK_ASSET = "file")
load("images/quandary_peak.png", QUANDARY_PEAK_ASSET = "file")
load("images/redcloud_peak.png", REDCLOUD_PEAK_ASSET = "file")
load("images/san_luis_peak.png", SAN_LUIS_PEAK_ASSET = "file")
load("images/snowmass_mountain.png", SNOWMASS_MOUNTAIN_ASSET = "file")
load("images/sunlight_peak.png", SUNLIGHT_PEAK_ASSET = "file")
load("images/sunshine_peak.png", SUNSHINE_PEAK_ASSET = "file")
load("images/tabeguache_peak.png", TABEGUACHE_PEAK_ASSET = "file")
load("images/torreys_peak.png", TORREYS_PEAK_ASSET = "file")
load("images/uncompahgre_peak.png", UNCOMPAHGRE_PEAK_ASSET = "file")
load("images/wetterhorn_peak.png", WETTERHORN_PEAK_ASSET = "file")
load("images/wilson_peak.png", WILSON_PEAK_ASSET = "file")
load("images/windom_peak.png", WINDOM_PEAK_ASSET = "file")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DISPLAY_OPTIONS = [
    schema.Option(value = "random", display = "Random 14er"),
    schema.Option(value = "visited", display = "Random visited 14er"),
    schema.Option(value = "unvisited", display = "Random unvisited 14er"),
]

MEASUREMENT_OPTIONS = [
    schema.Option(value = "metric", display = "Metric System"),
    schema.Option(value = "imperial", display = "Imperial System"),
]

SORT_OPTIONS = [
    schema.Option(value = "Name", display = "Sort by Mountain Name"),
    schema.Option(value = "Range", display = "Sort by Range name"),
    schema.Option(value = "Elevation", display = "Sort by Mountain Elevation"),
    schema.Option(value = "Hiking Distance", display = "Sort by Hiking Distance"),
    schema.Option(value = "Class", display = "Sort by Class"),
]

#Selected, Denver, Marquee Color, Visited, unvisitied
DEFAULT_COLORS = ["#0000ff", "#ff0000", "#65d0e6", "#ffff00", "#aaaaaa"]

COLORADO = [
    [-109.05, 41],
    [-102.05158, 41],
    [-102.4207, 37],
    [-109.04516, 37],
]

DENVER = [-104.88111, 39.7618]

MOUNTAIN_DATA = [
    {
        "Name": "Blanca Peak",
        "Range": "Sangre de Cristo Range",
        "XCoord": 32,
        "YCoord": 27,
        "Elevation": 4374,
        "Prominence": 1623,
        "Latitude Degrees": 37.5775,
        "Longitude Degrees": -105.4856,
        "Hiking Distance": 27.4,
        "Hiking Elevation Gain": 1981.2,
        "Class": "2+",
        "Outline": BLANCA_PEAK_ASSET.readall(),
        "Description": "Mt. Blanca is a challenging climb to the highest peak in the Sangre de Cristo and Sierra Blanca Massif Mountains.",
    },
    {
        "Name": "Capitol Peak",
        "Range": "Elk Mountains",
        "XCoord": 17,
        "YCoord": 14,
        "Elevation": 4309,
        "Prominence": 533,
        "Latitude Degrees": 39.1503,
        "Longitude Degrees": -107.0829,
        "Hiking Distance": 27.4,
        "Hiking Elevation Gain": 1615.44,
        "Class": "4",
        "Outline": CAPITOL_PEAK_ASSET.readall(),
        "Description": "A stunning mountain in the Maroon Bells-Snowmass Wilderness; said to be the most difficult 14er. It has one of the tallest northern mountain walls in Colorado.",
    },
    {
        "Name": "Castle Peak",
        "Range": "Elk Mountains",
        "XCoord": 20,
        "YCoord": 16,
        "Elevation": 4352.2,
        "Prominence": 721,
        "Latitude Degrees": 39.0097,
        "Longitude Degrees": -106.8614,
        "Hiking Distance": 21.7,
        "Hiking Elevation Gain": 1402.08,
        "Class": "2+",
        "Outline": CASTLE_PEAK_ASSET.readall(),
        "Description": "Found near Aspen, this is the tallest summit in the Maroon Bells-Snowmass Wilderness and the Elk Mountains. It's said to be the \"easiest\" 14er in the Elk Range.",
    },
    {
        "Name": "Challenger Point",
        "Range": "Sangre de Cristo Range",
        "XCoord": 30,
        "YCoord": 23,
        "Elevation": 4294,
        "Prominence": 92,
        "Latitude Degrees": 37.9804,
        "Longitude Degrees": -105.6066,
        "Hiking Distance": 21.7,
        "Hiking Elevation Gain": 1645.92,
        "Class": "2+",
        "Outline": CHALLENGER_POINT_ASSET.readall(),
        "Description": "Lying in front and to the west of Kit Carson Peak, the trail to the top of this high-rising peak includes a waterfall, lake, and awesome views. It was named for the crew of Space Shuttle Challenger.",
    },
    {
        "Name": "Crestone Needle",
        "Range": "Sangre de Cristo Range",
        "XCoord": 32,
        "YCoord": 24,
        "Elevation": 4329,
        "Prominence": 139,
        "Latitude Degrees": 37.9647,
        "Longitude Degrees": -105.5766,
        "Hiking Distance": 19.3,
        "Hiking Elevation Gain": 1341.12,
        "Class": "4",
        "Outline": CRESTONE_NEEDLE_ASSET.readall(),
        "Description": "One of the top 5 toughest and most rugged, this peak was one of the last 14ers climbed. The route is difficult to navigate and there are sections where class 3 technical climbing is required.",
    },
    {
        "Name": "Crestone Peak",
        "Range": "Sangre de Cristo Range",
        "XCoord": 31,
        "YCoord": 24,
        "Elevation": 4359,
        "Prominence": 1388,
        "Latitude Degrees": 37.9669,
        "Longitude Degrees": -105.5855,
        "Hiking Distance": 22.5,
        "Hiking Elevation Gain": 1737.36,
        "Outline": CRESTONE_PEAK_ASSET.readall(),
        "Description": "Often called \"The Peak,\" this remote mountain is the second highest summit in the Sangre de Cristo Range. It has two summits, with the western one being 34 ft. higher.",
    },
    {
        "Name": "Culebra Peak",
        "Range": "Culebra Range",
        "XCoord": 35,
        "YCoord": 31,
        "Elevation": 4283,
        "Prominence": 1471,
        "Latitude Degrees": 37.1224,
        "Longitude Degrees": -105.1858,
        "Hiking Distance": 8,
        "Hiking Elevation Gain": 822.96,
        "Class": "2",
        "Outline": CULEBRA_PEAK_ASSET.readall(),
        "Description": "This is the most historic 14er (dating back to the late 1600s) and the highest peak in the Culebra Range. It is also the only privately owned 14er.",
    },
    {
        "Name": "Ellingwood Point",
        "Range": "Sangre de Cristo Range",
        "XCoord": 32,
        "YCoord": 26,
        "Elevation": 4282,
        "Prominence": 104,
        "Latitude Degrees": 37.5826,
        "Longitude Degrees": -105.4927,
        "Hiking Distance": 27.4,
        "Hiking Elevation Gain": 1889.76,
        "Class": "2+",
        "Outline": ELLINGWOOD_POINT_ASSET.readall(),
        "Description": "Named after famous Colorado climber, Albert Ellingwood, this hike includes long exposure areas and a lake. The trail gets tricky, so best keep a detailed map at hand.",
    },
    {
        "Name": "Grays Peak",
        "Range": "Front Range",
        "XCoord": 29,
        "YCoord": 10,
        "Elevation": 4352,
        "Prominence": 844,
        "Latitude Degrees": 39.6339,
        "Longitude Degrees": -105.8176,
        "Hiking Distance": 12.1,
        "Hiking Elevation Gain": 914.4,
        "Class": "1",
        "Outline": GRAYS_PEAK_ASSET.readall(),
        "Description": "Tallest point in the Front Range and the Continental Divide, this mountain peak is easily spotted from the Great Plains.",
    },
    {
        "Name": "Handies Peak",
        "Range": "San Juan Mountains",
        "XCoord": 13,
        "YCoord": 24,
        "Elevation": 4284.8,
        "Prominence": 582,
        "Latitude Degrees": 37.913,
        "Longitude Degrees": -107.5044,
        "Hiking Distance": 9.3,
        "Hiking Elevation Gain": 762,
        "Class": "1",
        "Outline": HANDIES_PEAK_ASSET.readall(),
        "Description": "From American Basin, a steady climb reveals views of the Grenadier, La Garita, and Needle Mountains, plus the Mt. Sneffels Wilderness.",
    },
    {
        "Name": "Humboldt Peak",
        "Range": "Sangre de Cristo Range",
        "XCoord": 33,
        "YCoord": 23,
        "Elevation": 4289,
        "Prominence": 367,
        "Latitude Degrees": 37.9762,
        "Longitude Degrees": -105.5552,
        "Hiking Distance": 17.7,
        "Hiking Elevation Gain": 1280.16,
        "Class": "2",
        "Outline": HUMBOLDT_PEAK_ASSET.readall(),
        "Description": "This is one of the easier 14ers to hike in the area. There are views of Needle, Crestone Peak, and the Wet Valley on the way up.",
    },
    {
        "Name": "Huron Peak",
        "Range": "Sawatch Range",
        "XCoord": 23,
        "YCoord": 16,
        "Elevation": 4270.2,
        "Prominence": 434,
        "Latitude Degrees": 38.9455,
        "Longitude Degrees": -106.4381,
        "Hiking Distance": 11.3,
        "Hiking Elevation Gain": 1066.8,
        "Class": "2",
        "Outline": HURON_PEAK_ASSET.readall(),
        "Description": "Located along the western side of the Sawatch Range, this trail is a moderately steady hike with a more rugged climb to its summit.",
    },
    {
        "Name": "Kit Carson Peak",
        "Range": "Sangre de Cristo Range",
        "XCoord": 31,
        "YCoord": 23,
        "Elevation": 4319,
        "Prominence": 312,
        "Latitude Degrees": 37.9797,
        "Longitude Degrees": -105.6026,
        "Hiking Distance": 24.1,
        "Hiking Elevation Gain": 1905,
        "Class": "3-",
        "Outline": KIT_CARSON_PEAK_ASSET.readall(),
        "Description": "The fourth tallest point in the Sangre de Cristo Range, this peak has several sub-summits.",
    },
    {
        "Name": "La Plata Peak",
        "Range": "Sawatch Range",
        "XCoord": 23,
        "YCoord": 15,
        "Elevation": 4372,
        "Prominence": 560,
        "Latitude Degrees": 39.0294,
        "Longitude Degrees": -106.4729,
        "Hiking Distance": 14.9,
        "Hiking Elevation Gain": 1371.6,
        "Class": "2",
        "Outline": LA_PLATA_PEAK_ASSET.readall(),
        "Description": "Found in the Collegiate Peaks Wilderness in the San Isabel National forest, you can spot this mountain by its rocky summit and wide-spreading western flank.",
    },
    {
        "Name": "Little Bear Peak",
        "Range": "Sangre de Cristo Range",
        "XCoord": 31,
        "YCoord": 28,
        "Elevation": 4280,
        "Prominence": 115,
        "Latitude Degrees": 37.5666,
        "Longitude Degrees": -105.4972,
        "Hiking Distance": 22.5,
        "Hiking Elevation Gain": 1889.76,
        "Class": "4",
        "Outline": LITTLE_BEAR_PEAK_ASSET.readall(),
        "Description": "One of the toughest and most dangerous 14ers to scale, this monster stretches 6,000 ft. above the rest of the San Luis Valley. Climbers—beware of loose falling rock.",
    },
    {
        "Name": "Longs Peak",
        "Range": "Front Range",
        "XCoord": 31,
        "YCoord": 5,
        "Elevation": 4346,
        "Prominence": 896,
        "Latitude Degrees": 40.255,
        "Longitude Degrees": -105.6151,
        "Hiking Distance": 23.3,
        "Hiking Elevation Gain": 1554.48,
        "Class": "3",
        "Outline": LONGS_PEAK_ASSET.readall(),
        "Description": "One of the hardest yet most popular 14ers, Longs Peak is 90 minutes outside of Denver. The climb is difficult, requiring endurance and experienced scrambling and mountaineering skills.",
    },
    {
        "Name": "Maroon Peak",
        "Range": "Elk Mountains",
        "XCoord": 18,
        "YCoord": 15,
        "Elevation": 4317,
        "Prominence": 712,
        "Latitude Degrees": 39.0708,
        "Longitude Degrees": -106.989,
        "Hiking Distance": 19.3,
        "Hiking Elevation Gain": 1463.04,
        "Class": "3",
        "Outline": MAROON_PEAK_ASSET.readall(),
        "Description": "Maroon Peak connects to nearby North Maroon Peak, together called The Maroon Bells. Maroon Peak is the main point, and this set is known for its brilliant colors each Fall.",
    },
    {
        "Name": "Missouri Mountain",
        "Range": "Sawatch Range",
        "XCoord": 24,
        "YCoord": 16,
        "Elevation": 4289.8,
        "Prominence": 258,
        "Latitude Degrees": 38.9476,
        "Longitude Degrees": -106.3785,
        "Hiking Distance": 16.9,
        "Hiking Elevation Gain": 1371.6,
        "Class": "2",
        "Outline": MISSOURI_MOUNTAIN_ASSET.readall(),
        "Description": "In the Collegiate Peaks Wilderness, this mountain is popular for beginners and families with a summit granting some of the best views around.",
    },
    {
        "Name": "Mt. Antero",
        "Range": "Sawatch Range",
        "XCoord": 26,
        "YCoord": 19,
        "Elevation": 4351.4,
        "Prominence": 763,
        "Latitude Degrees": 38.6741,
        "Longitude Degrees": -106.2462,
        "Hiking Distance": 24.9,
        "Hiking Elevation Gain": 1584.96,
        "Class": "2",
        "Outline": MT_ANTERO_ASSET.readall(),
        "Description": "Highest mountain out of the southern Sawatch Range, located in the San Isabel National Forest. There are several moderately rated hiking routes on the mountain.",
    },
    {
        "Name": "Mt. Belford",
        "Range": "Sawatch Range",
        "XCoord": 24,
        "YCoord": 15,
        "Elevation": 4329.1,
        "Prominence": 408,
        "Latitude Degrees": 38.9607,
        "Longitude Degrees": -106.3607,
        "Hiking Distance": 12.9,
        "Hiking Elevation Gain": 1371.6,
        "Class": "2",
        "Outline": MT_BELFORD_ASSET.readall(),
        "Description": "Sits close to Mt. Oxford and Mt. Missouri. Its location and extravagant views make it a favorite among the 14ers.",
    },
    {
        "Name": "Mt. Bierstadt",
        "Range": "Front Range",
        "XCoord": 30,
        "YCoord": 11,
        "Elevation": 4287,
        "Prominence": 219,
        "Latitude Degrees": 39.5826,
        "Longitude Degrees": -105.6688,
        "Hiking Distance": 11.7,
        "Hiking Elevation Gain": 868.68,
        "Class": "2",
        "Outline": MT_BIERSTADT_ASSET.readall(),
        "Description": "In the Pike National Forest, this moderately rated peak is more accessible than other 14ers with its well-maintained trail and close vicinity to Denver.",
    },
    {
        "Name": "Mt. Blue Sky",
        "Range": "Front Range",
        "XCoord": 31,
        "YCoord": 11,
        "Elevation": 4350,
        "Prominence": 844,
        "Latitude Degrees": 39.5883,
        "Longitude Degrees": -105.6438,
        "Hiking Distance": 8.9,
        "Hiking Elevation Gain": 609.6,
        "Class": "2",
        "Outline": MT_BLUE_SKY_ASSET.readall(),
        "Description": "On the Rockies’ eastern edge, this peak offers a 14-mile scenic drive to its summit with wildlife and sweeping views.",
    },
    {
        "Name": "Mt. Bross",
        "Range": "Mosquito Range",
        "XCoord": 26,
        "YCoord": 13,
        "Elevation": 4321.6,
        "Prominence": 95,
        "Latitude Degrees": 39.3354,
        "Longitude Degrees": -106.1077,
        "Hiking Distance": 5.2,
        "Hiking Elevation Gain": 685.8,
        "Class": "2",
        "Outline": MT_BROSS_ASSET.readall(),
        "Description": "In Pike National Forest, this is the easiest of three 14ers sharing a trailhead with Mt. Democrat and Mt. Lincoln.",
    },
    {
        "Name": "Mt. Columbia",
        "Range": "Sawatch Range",
        "XCoord": 26,
        "YCoord": 16,
        "Elevation": 4290.8,
        "Prominence": 272,
        "Latitude Degrees": 38.9039,
        "Longitude Degrees": -106.2975,
        "Hiking Distance": 19.3,
        "Hiking Elevation Gain": 1295.4,
        "Class": "2",
        "Outline": MT_COLUMBIA_ASSET.readall(),
        "Description": "This Collegiate Peak overlooks the Arkansas River Valley and several fellow collegiate peaks. It's unpopular among hikers because of its battered, steep, and slippery trail.",
    },
    {
        "Name": "Mt. Democrat",
        "Range": "Mosquito Range",
        "XCoord": 24,
        "YCoord": 12,
        "Elevation": 4314.5,
        "Prominence": 234,
        "Latitude Degrees": 39.3396,
        "Longitude Degrees": -106.14,
        "Hiking Distance": 6.4,
        "Hiking Elevation Gain": 655.32,
        "Class": "2",
        "Outline": MT_DEMOCRAT_ASSET.readall(),
        "Description": "The first mountain in the DeCaliBron Loop, the climb to the summit is short and steep, granting 360-degree views of fellow 14ers.",
    },
    {
        "Name": "Mt. Elbert",
        "Range": "Sawatch Range",
        "XCoord": 23,
        "YCoord": 14,
        "Elevation": 4401.2,
        "Prominence": 2772,
        "Latitude Degrees": 39.1178,
        "Longitude Degrees": -106.4454,
        "Hiking Distance": 15.7,
        "Hiking Elevation Gain": 1371.6,
        "Class": "1",
        "Outline": MT_ELBERT_ASSET.readall(),
        "Description": "Highest peak in Colorado and the Rocky Mountains and the second-highest in the lower 48. Climb to the summit is reasonably moderate and suitable for a variety of skill levels.",
    },
    {
        "Name": "Mt. Eolus",
        "Range": "San Juan Mountains",
        "XCoord": 13,
        "YCoord": 27,
        "Elevation": 4295,
        "Prominence": 312,
        "Latitude Degrees": 37.6218,
        "Longitude Degrees": -107.6227,
        "Hiking Distance": 9.7,
        "Hiking Elevation Gain": 944.88,
        "Class": "3",
        "Outline": MT_EOLUS_ASSET.readall(),
        "Description": "This mountain has 2 summits with the southern point as the larger. It's in the Needle Mountains and was named after the Greek God of the winds.",
    },
    {
        "Name": "Mt. Harvard",
        "Range": "Sawatch Range",
        "XCoord": 25,
        "YCoord": 16,
        "Elevation": 4395.6,
        "Prominence": 719,
        "Latitude Degrees": 38.9244,
        "Longitude Degrees": -106.3207,
        "Hiking Distance": 22.5,
        "Hiking Elevation Gain": 1402.08,
        "Class": "2",
        "Outline": MT_HARVARD_ASSET.readall(),
        "Description": "The highest summit of the Collegiate Peaks and the fourth highest peak in the contiguous U.S., the climb begins gradually, steepens the closer you get to the summit.",
    },
    {
        "Name": "Mt. Lincoln",
        "Range": "Mosquito Range",
        "XCoord": 26,
        "YCoord": 12,
        "Elevation": 4356.5,
        "Prominence": 1177,
        "Latitude Degrees": 39.3515,
        "Longitude Degrees": -106.1116,
        "Hiking Distance": 9.7,
        "Hiking Elevation Gain": 792.48,
        "Class": "2",
        "Outline": MT_LINCOLN_ASSET.readall(),
        "Description": "This towering peak is the highest in the Mosquito Range and Park County, and the mountain was given its name in honor of President Lincoln.",
    },
    {
        "Name": "Mt. Lindsey",
        "Range": "Sangre de Cristo Range",
        "XCoord": 33,
        "YCoord": 26,
        "Elevation": 4282,
        "Prominence": 470,
        "Latitude Degrees": 37.5837,
        "Longitude Degrees": -105.4449,
        "Hiking Distance": 13.3,
        "Hiking Elevation Gain": 1066.8,
        "Class": "3-",
        "Outline": MT_LINDSEY_ASSET.readall(),
        "Description": "Most of the mountain is moderately easy to climb until you reach the ridge scramble that gets technical. Gear and helmet required.",
    },
    {
        "Name": "Mt. Massive",
        "Range": "Sawatch Range",
        "XCoord": 23,
        "YCoord": 13,
        "Elevation": 4398,
        "Prominence": 598,
        "Latitude Degrees": 39.1875,
        "Longitude Degrees": -106.4757,
        "Hiking Distance": 23.3,
        "Hiking Elevation Gain": 1371.6,
        "Class": "2",
        "Outline": MT_MASSIVE_ASSET.readall(),
        "Description": "Difficult but not technical, though best suited for experienced hikers. Second-highest peak in the Rockies and it has five summits along 3 miles that reach above 14,000 ft.",
    },
    {
        "Name": "Mt. of the Holy Cross",
        "Range": "Sawatch Range",
        "XCoord": 23,
        "YCoord": 11,
        "Elevation": 4270.5,
        "Prominence": 644,
        "Latitude Degrees": 39.4668,
        "Longitude Degrees": -106.4817,
        "Hiking Distance": 18.1,
        "Hiking Elevation Gain": 1706.88,
        "Class": "2",
        "Outline": MT_HOLY_CROSS_ASSET.readall(),
        "Description": "Northernmost mountain in the Sawatch, its northeastern side is often covered in snow that creates a crucifix design (hence the name given by Herbert Hoover.)",
    },
    {
        "Name": "Mt. Oxford",
        "Range": "Collegiate Peaks",
        "XCoord": 25,
        "YCoord": 15,
        "Elevation": 4315.9,
        "Prominence": 199,
        "Latitude Degrees": 38.9648,
        "Longitude Degrees": -106.3388,
        "Hiking Distance": 17.7,
        "Hiking Elevation Gain": 1798.32,
        "Class": "2",
        "Outline": MT_OXFORD_ASSET.readall(),
        "Description": "This mountain is only 1.5 miles from Mt. Belford, and the two are often hiked as a set. The climb to its peak isn't technical, although it's steep with a long-exposed ridgeline.",
    },
    {
        "Name": "Mt. Princeton",
        "Range": "Sawatch Range",
        "XCoord": 26,
        "YCoord": 18,
        "Elevation": 4329.3,
        "Prominence": 664,
        "Latitude Degrees": 38.7492,
        "Longitude Degrees": -106.2424,
        "Hiking Distance": 10.5,
        "Hiking Elevation Gain": 975.36,
        "Class": "2",
        "Outline": MT_PRINCETON_ASSET.readall(),
        "Description": "In the San Isabel National Forest, this peak grants breathtaking views of both the Arkansas Valley and the rest of the Sawatch Range. The hike requires no technical skills.",
    },
    {
        "Name": "Mt. Shavano",
        "Range": "Sawatch Range",
        "XCoord": 25,
        "YCoord": 19,
        "Elevation": 4337.7,
        "Prominence": 493,
        "Latitude Degrees": 38.6192,
        "Longitude Degrees": -106.2393,
        "Hiking Distance": 15.3,
        "Hiking Elevation Gain": 1371.6,
        "Class": "2",
        "Outline": MT_SHAVANO_ASSET.readall(),
        "Description": "Named for a Tabeguache Ute chief, this Sawatch Range peak in San Isabel National Forest features snowy eastern valleys resembling an angel with outstretched wings, the 'Angel of Shavano.'",
    },
    {
        "Name": "Mt. Sherman",
        "Range": "Mosquito Range",
        "XCoord": 26,
        "YCoord": 14,
        "Elevation": 4280,
        "Prominence": 259,
        "Latitude Degrees": 39.225,
        "Longitude Degrees": -106.1699,
        "Hiking Distance": 8.4,
        "Hiking Elevation Gain": 640.08,
        "Class": "1",
        "Outline": MT_SHERMAN_ASSET.readall(),
        "Description": "This peak easily blends into its neighboring ones. There are 2 routes to its summit, both featuring gentle ridgelines that make for a kinder climb.",
    },
    {
        "Name": "Mt. Sneffels",
        "Range": "Sneffels Range",
        "XCoord": 11,
        "YCoord": 23,
        "Elevation": 4315.4,
        "Prominence": 930,
        "Latitude Degrees": 38.0038,
        "Longitude Degrees": -107.7923,
        "Hiking Distance": 9.7,
        "Hiking Elevation Gain": 883.92,
        "Class": "3-",
        "Outline": MT_SNEFFELS_ASSET.readall(),
        "Description": "The highest peak in the Sneffels Range, the 'Queen of the San Juans' is a popular subject in photography and film.",
    },
    {
        "Name": "Mt. Wilson",
        "Range": "San Miguel Mountains",
        "XCoord": 9,
        "YCoord": 25,
        "Elevation": 4344,
        "Prominence": 1227,
        "Latitude Degrees": 37.8391,
        "Longitude Degrees": -107.9916,
        "Hiking Distance": 20.1,
        "Hiking Elevation Gain": 1341.12,
        "Class": "3",
        "Outline": MT_WILSON_ASSET.readall(),
        "Description": "The highest San Miguel Range peak, this Lizard Head Wilderness 14er sits near two others outside Telluride.",
    },
    {
        "Name": "Mt. Yale",
        "Range": "Sawatch Range",
        "XCoord": 25,
        "YCoord": 17,
        "Elevation": 4328.2,
        "Prominence": 578,
        "Latitude Degrees": 38.8442,
        "Longitude Degrees": -106.3138,
        "Hiking Distance": 15.3,
        "Hiking Elevation Gain": 1310.64,
        "Class": "2",
        "Outline": MT_YALE_ASSET.readall(),
        "Description": "Eighth tallest peak in the Sawatch Range, it is one of the only 14ers in the area that has a paved road leading to the trailhead.",
    },
    {
        "Name": "Pikes Peak",
        "Range": "Front Range",
        "XCoord": 36,
        "YCoord": 17,
        "Elevation": 4302.31,
        "Prominence": 1686,
        "Latitude Degrees": 38.8405,
        "Longitude Degrees": -105.0442,
        "Hiking Distance": 38.6,
        "Hiking Elevation Gain": 2316.48,
        "Class": "1",
        "Outline": PIKES_PEAK_ASSET.readall(),
        "Description": "There is a road to this mountain peak. As for hiking, the climb is long and steep, filled with difficult terrain.",
    },
    {
        "Name": "Pyramid Peak",
        "Range": "Elk Mountains",
        "XCoord": 19,
        "YCoord": 15,
        "Elevation": 4274.7,
        "Prominence": 499,
        "Latitude Degrees": 39.0717,
        "Longitude Degrees": -106.9502,
        "Hiking Distance": 13.3,
        "Hiking Elevation Gain": 1371.6,
        "Class": "4",
        "Outline": PYRAMID_PEAK_ASSET.readall(),
        "Description": "13 miles outside Aspen, technical mountain is made of sedimentary loose rugged rock. A helmet is required to scale its last 1,000 ft.",
    },
    {
        "Name": "Quandary Peak",
        "Range": "Mosquito Range",
        "XCoord": 26,
        "YCoord": 11,
        "Elevation": 4349.9,
        "Prominence": 343,
        "Latitude Degrees": 39.3973,
        "Longitude Degrees": -106.1064,
        "Hiking Distance": 10.9,
        "Hiking Elevation Gain": 1051.56,
        "Class": "1",
        "Outline": QUANDARY_PEAK_ASSET.readall(),
        "Description": "The highest summit of the Tenmile Range in the Rocky Mountains, this is one of the most climbed 14ers.",
    },
    {
        "Name": "Redcloud Peak",
        "Range": "San Juan Mountains",
        "XCoord": 14,
        "YCoord": 23,
        "Elevation": 4280,
        "Prominence": 438,
        "Latitude Degrees": 37.941,
        "Longitude Degrees": -107.4219,
        "Hiking Distance": 14.5,
        "Hiking Elevation Gain": 1127.76,
        "Class": "2",
        "Outline": REDCLOUD_PEAK_ASSET.readall(),
        "Description": "Named after the visible red coloring of its peak, this picturesque mountain is often hiked alongside Sunshine peak.",
    },
    {
        "Name": "San Luis Peak",
        "Range": "La Garita Mountains",
        "XCoord": 19,
        "YCoord": 24,
        "Elevation": 4273.8,
        "Prominence": 949,
        "Latitude Degrees": 37.9868,
        "Longitude Degrees": -106.9313,
        "Hiking Distance": 21.7,
        "Hiking Elevation Gain": 1097.28,
        "Class": "1",
        "Outline": SAN_LUIS_PEAK_ASSET.readall(),
        "Description": "Highest point in the La Garita Mountains, this remote and often desolate peak is tricky to reach as it sits 2 hours from any paved roads.",
    },
    {
        "Name": "Snowmass Mountain",
        "Range": "Elk Mountains",
        "XCoord": 17,
        "YCoord": 15,
        "Elevation": 4297.3,
        "Prominence": 351,
        "Latitude Degrees": 39.1188,
        "Longitude Degrees": -107.0665,
        "Hiking Distance": 35.4,
        "Hiking Elevation Gain": 1767.84,
        "Class": "3",
        "Outline": SNOWMASS_MOUNTAIN_ASSET.readall(),
        "Description": "The Elk Mountains’ fourth-highest peak has one of Colorado’s largest eastern snowfields and is invisible from roads.",
    },
    {
        "Name": "Sunlight Peak",
        "Range": "San Juan Mountains",
        "XCoord": 14,
        "YCoord": 26,
        "Elevation": 4287,
        "Prominence": 122,
        "Latitude Degrees": 37.6274,
        "Longitude Degrees": -107.5959,
        "Hiking Distance": 9.7,
        "Hiking Elevation Gain": 914.4,
        "Class": "4",
        "Outline": SUNLIGHT_PEAK_ASSET.readall(),
        "Description": "A lofty peak tucked in the Chicago Basin in the Needle Mountains, there's an extensive amount of exposure, scrambling and a summit block on the way to its top.",
    },
    {
        "Name": "Sunshine Peak",
        "Range": "San Juan Mountains",
        "XCoord": 14,
        "YCoord": 24,
        "Elevation": 4269,
        "Prominence": 153,
        "Latitude Degrees": 37.9228,
        "Longitude Degrees": -107.4256,
        "Hiking Distance": 19.7,
        "Hiking Elevation Gain": 1463.04,
        "Class": "2",
        "Outline": SUNSHINE_PEAK_ASSET.readall(),
        "Description": "Often paired with Redcloud, Sunshine has a red-rock summit and mixed trail-and-scree terrain.",
    },
    {
        "Name": "Tabeguache Peak",
        "Range": "Sawatch Range",
        "XCoord": 25,
        "YCoord": 18,
        "Elevation": 4316.7,
        "Prominence": 139,
        "Latitude Degrees": 38.6255,
        "Longitude Degrees": -106.2509,
        "Hiking Distance": 18.5,
        "Hiking Elevation Gain": 1706.88,
        "Class": "2",
        "Outline": TABEGUACHE_PEAK_ASSET.readall(),
        "Description": "In the southern Sawatch, this lesser-known 14er lies beside Mt. Shavano, with the climbing route now reversed to protect eroded trails.",
    },
    {
        "Name": "Torreys Peak",
        "Range": "Front Range",
        "XCoord": 29,
        "YCoord": 9,
        "Elevation": 4351,
        "Prominence": 171,
        "Latitude Degrees": 39.6428,
        "Longitude Degrees": -105.8212,
        "Hiking Distance": 12.5,
        "Hiking Elevation Gain": 914.4,
        "Class": "1",
        "Outline": TORREYS_PEAK_ASSET.readall(),
        "Description": "Near Denver and neighboring Grays Peak. It is the only 14er on the Continental Divide.",
    },
    {
        "Name": "Uncompahgre Peak",
        "Range": "San Juan Mountains",
        "XCoord": 14,
        "YCoord": 22,
        "Elevation": 4365,
        "Prominence": 1304,
        "Latitude Degrees": 38.0717,
        "Longitude Degrees": -107.4621,
        "Hiking Distance": 12.1,
        "Hiking Elevation Gain": 914.4,
        "Class": "2",
        "Outline": UNCOMPAHGRE_PEAK_ASSET.readall(),
        "Description": "This peak is the highest point in the San Juan Mountain Range and Colorado's largest Western Slope. It is one of the easier 14ers in its area.",
    },
    {
        "Name": "Wetterhorn Peak",
        "Range": "San Juan Mountains",
        "XCoord": 13,
        "YCoord": 23,
        "Elevation": 4274,
        "Prominence": 498,
        "Latitude Degrees": 38.0607,
        "Longitude Degrees": -107.5109,
        "Hiking Distance": 11.3,
        "Hiking Elevation Gain": 1005.84,
        "Class": "3",
        "Outline": WETTERHORN_PEAK_ASSET.readall(),
        "Description": "A beloved 14er that's great for hikers trying their hand at scree and scrambling, this rock-faced mountain can be found just outside of Lake City.",
    },
    {
        "Name": "Wilson Peak",
        "Range": "San Juan Mountains",
        "XCoord": 9,
        "YCoord": 24,
        "Elevation": 4274,
        "Prominence": 261,
        "Latitude Degrees": 37.8603,
        "Longitude Degrees": -107.9847,
        "Hiking Distance": 16.1,
        "Hiking Elevation Gain": 1188.72,
        "Class": "3",
        "Outline": WILSON_PEAK_ASSET.readall(),
        "Description": "This gorgeous rocky mountain is the highest peak in San Miguel County, and it's the face of all Coors products!",
    },
    {
        "Name": "Windom Peak",
        "Range": "Needle Mountains",
        "XCoord": 14,
        "YCoord": 27,
        "Elevation": 4296,
        "Prominence": 667,
        "Latitude Degrees": 37.6212,
        "Longitude Degrees": -107.5919,
        "Hiking Distance": 9.7,
        "Hiking Elevation Gain": 914.4,
        "Class": "2+",
        "Outline": WINDOM_PEAK_ASSET.readall(),
        "Description": "In the Weminuche Wilderness’ Needle Mountains, this popular multi-day hike requires no technical gear.",
    },
]

def add_copies_of_frame_to_frames(frames, items, number_of_frames):
    for _ in range(number_of_frames):
        frames.append(render.Stack(children = list(items)))

def main(config):
    show_instructions = config.bool("instructions", False)

    if show_instructions == True:
        return show_instructions_screen()

    show_mountain_outline = config.bool("outline", True)

    is_metric_system = config.get("measurement", MEASUREMENT_OPTIONS[0].value) == MEASUREMENT_OPTIONS[0].value

    display_candidates = []
    display_type = config.get("display", DISPLAY_OPTIONS[0].value)

    i = 0

    for mountain in MOUNTAIN_DATA:
        if (display_type == "random" or (display_type == "visited" and config.get("_%s" % mountain["Name"]) == "true") or (display_type == "unvisited" and config.get("_%s" % mountain["Name"]) != "true")):
            display_candidates.append(i)
        i = i + 1

    random_mountain = MOUNTAIN_DATA[randomize(0, len(MOUNTAIN_DATA) - 1)]

    # we have a random one, but if we have a valid filtered group to choose from, we'll do that now
    if (len(display_candidates) > 0):
        random_mountain = MOUNTAIN_DATA[display_candidates[randomize(0, len(display_candidates) - 1)]]

    random_mountain_position = [random_mountain["XCoord"], random_mountain["YCoord"]]

    Denver_position = get_screen_coordinates_from_actual(COLORADO, DENVER)

    hiking_distance = float(random_mountain["Hiking Distance"])
    hiking_elevation = float(random_mountain["Hiking Elevation Gain"])
    elevation_units = "meters"
    distance_units = "km"

    if is_metric_system == False:
        hiking_distance = math.round((hiking_distance / 1.6))
        hiking_elevation = math.round(3.38 * hiking_elevation)
        elevation_units = "feet"
        distance_units = "mile"

    # Over Time let's display little different aspects of the mountains
    if randomize(0, 1) == 1:
        mountain_description = "%s in the %s - %s %s is a class %s mountain.             " % (random_mountain["Name"], random_mountain["Range"], random_mountain["Description"], random_mountain["Name"], random_mountain["Class"])
    else:
        mountain_description = "%s is a class %s mountain. Expect a %s %s hike that has an elevation gain of %s %s.           " % (random_mountain["Name"], random_mountain["Class"], humanize.float("#,###.", hiking_distance), distance_units, humanize.float("#,###.", hiking_elevation), elevation_units)

    #Create Frames for Display
    animation_frames = []
    stacked_items = []

    base_layer = render.Box(color = "#000", height = 1, width = 1)

    if show_mountain_outline:
        animation_frames = get_mountain_outline(random_mountain)
        base_layer = render.Stack(children = animation_frames)
        stacked_items.append(base_layer)
        add_copies_of_frame_to_frames(animation_frames, stacked_items, 5)

    # Denver
    stacked_items.append(
        render.Padding(
            pad = (Denver_position[0], Denver_position[1], 0, 0),
            child =
                render.Circle(
                    color = config.get("denver_color", DEFAULT_COLORS[1]),
                    diameter = 1,
                ),
        ),
    )

    # Add Visited Points
    visited_mountain_points = get_positions(config, True, MOUNTAIN_DATA)
    for item in visited_mountain_points:
        stacked_items.append(item)
        animation_frames.append(render.Stack(children = list(stacked_items)))

    add_copies_of_frame_to_frames(animation_frames, stacked_items, 10)

    # Add Unvisited Points
    unvisited_mountain_points = get_positions(config, False, MOUNTAIN_DATA)
    for item in unvisited_mountain_points:
        stacked_items.append(item)
        animation_frames.append(render.Stack(children = list(stacked_items)))

    add_copies_of_frame_to_frames(animation_frames, stacked_items, 10)

    animation_frames.append(render.Stack(children = list(stacked_items)))

    # Selected Mountain
    stacked_items.append(
        render.Padding(
            pad = (random_mountain_position[0], random_mountain_position[1], 0, 0),
            child =
                render.Circle(
                    color = config.get("selected_color", DEFAULT_COLORS[0]),
                    diameter = 1,
                ),
        ),
    )

    add_copies_of_frame_to_frames(animation_frames, stacked_items, 60)

    all_elements = [
        render.Animation(children = animation_frames),
    ]

    show_information_bar = config.bool("information_bar", True)

    if show_information_bar:
        all_elements.append(
            render.Padding(
                pad = (0, 24, 0, 0),
                child =
                    render.Marquee(
                        width = 64,
                        offset_start = 15,
                        child = render.Text(content = mountain_description, color = config.get("marquee_color", DEFAULT_COLORS[2]), font = "tb-8", offset = 0),
                    ),
            ),
        )

    return render.Root(
        delay = 50,
        #child = render.Animation(children=animation_frames),
        child = render.Stack(children = all_elements),
        show_full_animation = True,
    )

def get_screen_coordinates_from_actual(map, location):
    SCREEN_WIDTH = 64
    SCREEN_HEIGHT = 32

    max_long = None
    min_long = None
    max_lat = None
    min_lat = None

    #get max_long, min_long, max_lat, min_lat
    for dot in map:
        if max_long == None or max_long < dot[0]:
            max_long = dot[0]
        if min_long == None or min_long > dot[0]:
            min_long = dot[0]
        if max_lat == None or max_lat < dot[1]:
            max_lat = dot[1]
        if min_lat == None or min_lat > dot[1]:
            min_lat = dot[1]

    range_x = abs(max_long - min_long)
    range_y = abs(max_lat - min_lat)

    coords = [0, 0]
    coords[0] = int((location[0] - min_long) / range_x * SCREEN_WIDTH)
    coords[1] = int((-(location[1] - max_lat)) / range_y * SCREEN_HEIGHT)

    return coords

def randomize(min, max):
    now = time.now()
    rand = int(str(now.nanosecond)[-6:-3]) / 1000
    return int(rand * (max + 1 - min) + min)

def show_instructions_screen():
    ##############################################################################################################################################################################################################################
    header = "Colorado 14ers"
    instructions_1 = "Screen represents State of Colorado. Random mountain is picked from a group (visited, unvisited, or all peaks). You decide if the selected mountain's outline appears."
    instructions_2 = " You check peaks you've visited. All peaks are displayed and color-coded based on your choices. Default Red is Denver, yellow is visited, grey is unvisited."
    instructions_3 = " You can sort the list of peaks by name, range, distance, elevation or class. "
    return render.Root(
        render.Column(
            children = [
                render.Marquee(
                    width = 64,
                    offset_start = 15,
                    child = render.Text(header, color = "#65d0e6", font = "5x8"),
                ),
                render.Marquee(
                    width = 64,
                    offset_start = len(header) * 5,
                    child = render.Text(instructions_1, color = "#f4a306"),
                ),
                render.Marquee(
                    offset_start = len(instructions_1) * 5,
                    width = 64,
                    child = render.Text(instructions_2, color = "#f4a306"),
                ),
                render.Marquee(
                    offset_start = (len(instructions_2) + len(instructions_1)) * 5,
                    width = 64,
                    child = render.Text(instructions_3, color = "#f4a306"),
                ),
            ],
        ),
        show_full_animation = True,
    )

def get_mountain_outline(mountain):
    image = mountain["Outline"]
    IMG_WIDTH = 64
    IMG_HEIGHT = 32
    frames = []

    for reveal_w in range(1, IMG_WIDTH + 1):
        cover_w = IMG_WIDTH - reveal_w

        frames.append(
            render.Stack(
                children = [
                    # background / base image (full)
                    render.Image(src = image),

                    # a Row that places a fixed-width Box at the right
                    render.Stack(
                        children = [
                            render.Image(src = image),  #render.Box(),  # expands to take remaining left space
                            add_padding_to_child_element(
                                render.Box(
                                    # the cover that hides the right-side pixel
                                    width = IMG_WIDTH,
                                    height = IMG_HEIGHT,
                                    color = "#000",  # set to your background color (not transparent)
                                ),
                                65 - cover_w,
                            ),
                        ],
                    ),
                ],
            ),
        )

    return frames

def get_positions(config, visited, mountains):
    children = []
    current_location = ""
    color = config.get("visited_color", DEFAULT_COLORS[3])
    if visited == False:
        color = config.get("unvisited_color", DEFAULT_COLORS[4])

    previous_items = []

    for item in mountains:
        if config.bool("_%s" % item["Name"], False) == visited:
            current_location = [item["XCoord"], item["YCoord"]]
            # Code used to check for duplicate locations on the map and for help adjusting overlaps.
            # orig_coordinates = get_screen_coordinates_from_actual(COLORADO, [item["Longitude Degrees"], item["Latitude Degrees"]])
            # if current_location[0] == orig_coordinates[0] and current_location[1] == orig_coordinates[1]:
            #     print("%s %s %s" % (item["Name"],orig_coordinates[0], orig_coordinates[1]))
            # else:
            #     print("Old: %s %s %s" % (item["Name"],orig_coordinates[0], orig_coordinates[1]))
            #     print("New: %s %s %s" % (item["Name"],current_location[0], current_location[1]))

            #See if this location is a duplicate
            # for x in previous_items:
            #     if x[0] == current_location[0]:
            #         if x[1] == current_location[1]:
            #             print("DUPLICATE %s %s %s" % (item["Name"], current_location[0], current_location[1]))

            previous_items.append(current_location)

            children.append(
                render.Padding(
                    pad = (current_location[0], current_location[1], 0, 0),
                    child =
                        render.Circle(
                            color = color,
                            diameter = 1,
                        ),
                ),
            )

    return children

def add_padding_to_child_element(element, left = 0, top = 0, right = 0, bottom = 0):
    padded_element = render.Padding(
        pad = (left, top, right, bottom),
        child = element,
    )

    return padded_element

def get_visited(type):
    display_data = sorted(MOUNTAIN_DATA, key = lambda m: m[type], reverse = False)

    description_type = type
    description_info = ""
    suffix = ""

    #Override in a couple cases
    if type == "Name":
        description_type = "Range"
    elif type == "Class":
        description_info = "Class: "
    elif type == "Elevation":
        description_type = "Range"
    elif type == "Hiking Distance":
        suffix = " km"

    return [
        schema.Toggle(id = "_%s" % (mountain["Name"]), name = mountain["Name"], desc = "%s%s%s" % (description_info, mountain[description_type], suffix), icon = "mountain")
        for mountain in display_data
    ]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "instructions",
                name = "Display Instructions",
                desc = "Learn all this app has to offer.",
                icon = "book",
                default = False,
            ),
            schema.Toggle(
                id = "information_bar",
                name = "Display Information Bar",
                desc = "Display Information about selected mountain.",
                icon = "book",
                default = False,
            ),
            schema.Toggle(
                id = "outline",
                name = "Display Mountain Outline",
                desc = "",
                icon = "layerGroup",
                default = False,
            ),
            schema.Color(
                id = "selected_color",
                name = "Color",
                desc = "Selected Mountain Color",
                icon = "brush",
                default = DEFAULT_COLORS[0],
            ),
            schema.Color(
                id = "denver_color",
                name = "Color",
                desc = "Denver Location Color",
                icon = "brush",
                default = DEFAULT_COLORS[1],
            ),
            schema.Color(
                id = "marquee_color",
                name = "Color",
                desc = "Scrolling Information Text Color",
                icon = "brush",
                default = DEFAULT_COLORS[2],
            ),
            schema.Color(
                id = "visited_color",
                name = "Color",
                desc = "Visited Location Color",
                icon = "brush",
                default = DEFAULT_COLORS[3],
            ),
            schema.Color(
                id = "unvisited_color",
                name = "Color",
                desc = "Unvisited Location Color",
                icon = "brush",
                default = DEFAULT_COLORS[4],
            ),
            schema.Dropdown(
                id = "measurement",
                name = "Measurement System",
                desc = "Measurement System",
                icon = "ruler",
                options = MEASUREMENT_OPTIONS,
                default = MEASUREMENT_OPTIONS[0].value,
            ),
            schema.Dropdown(
                id = "sort",
                name = "Sort List of Mountains",
                desc = "",
                icon = "sort",
                options = SORT_OPTIONS,
                default = SORT_OPTIONS[0].value,
            ),
            schema.Dropdown(
                id = "display",
                name = "Display",
                desc = "What to Display?",
                icon = "gear",
                options = DISPLAY_OPTIONS,
                default = DISPLAY_OPTIONS[0].value,
            ),
            schema.Generated(
                id = "visited",
                source = "sort",
                handler = get_visited,
            ),
        ],
    )
