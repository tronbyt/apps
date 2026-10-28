"""
Applet: Colorado14ers
Summary: Colorado 14ers Tracker
Description: Track your Colorado 14ers.
Author: Robert Ison
"""

load("cache.star", "cache")
load("colorado14ers_data.star", "MOUNTAIN_OUTLINES")
load("encoding/json.star", "json")
load("humanize.star", "humanize")
load("math.star", "math")
load("random.star", "random")
load("render.star", "canvas", "render")
load("schema.star", "schema")


def is_square():
    """True on a 64x64 panel.

    Panels are told apart by SHAPE, never by size: the 128x64 wide panel is
    also 64 tall.
    """
    w, h = canvas.size()
    return h == w

def center_on_square(child, width = None, height = None):
    """Centre `child` on the square (64x64); other panels get it unchanged.

    A scene hand-laid for 64x32 passes its size so the Box that centres it
    has the scene's bounds rather than the panel's.
    """
    if not is_square():
        return child
    if width != None and height != None:
        child = render.Box(width = width, height = height, child = child)
    return render.Box(width = canvas.width(), height = canvas.height(), child = child)

display_options = [
    schema.Option(value = "random", display = "Random 14er"),
    schema.Option(value = "visited", display = "Random visited 14er"),
    schema.Option(value = "unvisited", display = "Random unvisited 14er"),
]

measurement_options = [
    schema.Option(value = "metric", display = "Metric System"),
    schema.Option(value = "imperial", display = "Imperial System"),
]

sort_options = [
    schema.Option(value = "Name", display = "Sort by Mountain Name"),
    schema.Option(value = "Range", display = "Sort by Range name"),
    schema.Option(value = "Elevation", display = "Sort by Mountain Elevation"),
    schema.Option(value = "Hiking Distance", display = "Sort by Hiking Distance"),
    schema.Option(value = "Class", display = "Sort by Class"),
]

scroll_speed_options = [
    schema.Option(
        display = "Slow Scroll",
        value = "60",
    ),
    schema.Option(
        display = "Medium Scroll",
        value = "45",
    ),
    schema.Option(
        display = "Fast Scroll",
        value = "30",
    ),
]

#Selected, Denver, Marquee Color, Visited, unvisitied
default_colors = ["#0000ff", "#ff0000", "#65d0e6", "#ffff00", "#aaaaaa"]

km_to_miles = 0.621371
meters_to_feet = 3.28084

colorado = [
    [-109.05, 41],
    [-102.05158, 41],
    [-102.4207, 37],
    [-109.04516, 37],
]

mountain_data = [
    {
        "Name": "Blanca Peak", "Range": "Sangre de Cristo Range",
        "XCoord": 32, "YCoord": 27,
        "Elevation": 4374, "Prominence": 1623,
        "Latitude Degrees": 37.5775, "Longitude Degrees": -105.4856,
        "Hiking Distance": 27.4, "Hiking Elevation Gain": 1981.2, "Class": "2+",
        "Description": "Highest summit in the Sangre de Cristo Range.",
    },
    {
        "Name": "Capitol Peak", "Range": "Elk Mountains",
        "XCoord": 17, "YCoord": 14,
        "Elevation": 4309, "Prominence": 533,
        "Latitude Degrees": 39.1503, "Longitude Degrees": -107.0829,
        "Hiking Distance": 27.4, "Hiking Elevation Gain": 1615.44, "Class": "4",
        "Description": "A rugged Elk Mountains summit in the Maroon Bells-Snowmass Wilderness.",
    },
    {
        "Name": "Castle Peak", "Range": "Elk Mountains",
        "XCoord": 20, "YCoord": 16,
        "Elevation": 4352.2, "Prominence": 721,
        "Latitude Degrees": 39.0097, "Longitude Degrees": -106.8614,
        "Hiking Distance": 21.7, "Hiking Elevation Gain": 1402.08, "Class": "2+",
        "Description": "Highest summit in the Elk Mountains, near Aspen.",
    },
    {
        "Name": "Challenger Point", "Range": "Sangre de Cristo Range",
        "XCoord": 30, "YCoord": 23,
        "Elevation": 4294, "Prominence": 92,
        "Latitude Degrees": 37.9804, "Longitude Degrees": -105.6066,
        "Hiking Distance": 21.7, "Hiking Elevation Gain": 1645.92, "Class": "2+",
        "Description": "Named in memory of the Space Shuttle Challenger crew.",
    },
    {
        "Name": "Crestone Needle", "Range": "Sangre de Cristo Range",
        "XCoord": 32, "YCoord": 24,
        "Elevation": 4329, "Prominence": 139,
        "Latitude Degrees": 37.9647, "Longitude Degrees": -105.5766,
        "Hiking Distance": 19.3, "Hiking Elevation Gain": 1341.12, "Class": "4",
        "Description": "A rugged, sharply sculpted summit beside Crestone Peak.",
    },
    {
        "Name": "Crestone Peak", "Range": "Sangre de Cristo Range",
        "XCoord": 31, "YCoord": 24,
        "Elevation": 4359, "Prominence": 1388,
        "Latitude Degrees": 37.9669, "Longitude Degrees": -105.5855,
        "Hiking Distance": 22.5, "Hiking Elevation Gain": 1737.36, "Class": "3",
        "Description": "Second-highest summit in the Sangre de Cristo Range.",
    },
    {
        "Name": "Culebra Peak", "Range": "Sangre de Cristo Range",
        "XCoord": 35, "YCoord": 31,
        "Elevation": 4283, "Prominence": 1471,
        "Latitude Degrees": 37.1224, "Longitude Degrees": -105.1858,
        "Hiking Distance": 8, "Hiking Elevation Gain": 822.96, "Class": "2",
        "Description": "A privately owned summit in the Culebra Range.",
    },
    {
        "Name": "Ellingwood Point", "Range": "Sangre de Cristo Range",
        "XCoord": 32, "YCoord": 26,
        "Elevation": 4282, "Prominence": 104,
        "Latitude Degrees": 37.5826, "Longitude Degrees": -105.4927,
        "Hiking Distance": 27.4, "Hiking Elevation Gain": 1889.76, "Class": "2+",
        "Description": "Named for Colorado mountaineer Albert Ellingwood.",
    },
    {
        "Name": "Grays Peak", "Range": "Front Range",
        "XCoord": 29, "YCoord": 10,
        "Elevation": 4352, "Prominence": 844,
        "Latitude Degrees": 39.6339, "Longitude Degrees": -105.8176,
        "Hiking Distance": 12.1, "Hiking Elevation Gain": 914.4, "Class": "1",
        "Description": "Highest summit in the Front Range.",
    },
    {
        "Name": "Handies Peak", "Range": "San Juan Mountains",
        "XCoord": 13, "YCoord": 24,
        "Elevation": 4284.8, "Prominence": 582,
        "Latitude Degrees": 37.913, "Longitude Degrees": -107.5044,
        "Hiking Distance": 9.3, "Hiking Elevation Gain": 762, "Class": "1",
        "Description": "A San Juan summit reached from American Basin.",
    },
    {
        "Name": "Humboldt Peak", "Range": "Sangre de Cristo Range",
        "XCoord": 33, "YCoord": 23,
        "Elevation": 4289, "Prominence": 367,
        "Latitude Degrees": 37.9762, "Longitude Degrees": -105.5552,
        "Hiking Distance": 17.7, "Hiking Elevation Gain": 1280.16, "Class": "2",
        "Description": "Overlooks the neighboring Crestone peaks and the Wet Mountain Valley.",
    },
    {
        "Name": "Huron Peak", "Range": "Sawatch Range",
        "XCoord": 23, "YCoord": 16,
        "Elevation": 4270.2, "Prominence": 434,
        "Latitude Degrees": 38.9455, "Longitude Degrees": -106.4381,
        "Hiking Distance": 11.3, "Hiking Elevation Gain": 1066.8, "Class": "2",
        "Description": "A western Sawatch summit with a rugged final climb.",
    },
    {
        "Name": "Kit Carson Peak", "Range": "Sangre de Cristo Range",
        "XCoord": 31, "YCoord": 23,
        "Elevation": 4319, "Prominence": 312,
        "Latitude Degrees": 37.9797, "Longitude Degrees": -105.6026,
        "Hiking Distance": 24.1, "Hiking Elevation Gain": 1905, "Class": "3-",
        "Description": "A Sangre de Cristo summit with several subsidiary peaks.",
    },
    {
        "Name": "La Plata Peak", "Range": "Sawatch Range",
        "XCoord": 23, "YCoord": 15,
        "Elevation": 4372, "Prominence": 560,
        "Latitude Degrees": 39.0294, "Longitude Degrees": -106.4729,
        "Hiking Distance": 14.9, "Hiking Elevation Gain": 1371.6, "Class": "2",
        "Description": "A rocky summit in the Collegiate Peaks Wilderness.",
    },
    {
        "Name": "Little Bear Peak", "Range": "Sangre de Cristo Range",
        "XCoord": 31, "YCoord": 28,
        "Elevation": 4280, "Prominence": 115,
        "Latitude Degrees": 37.5666, "Longitude Degrees": -105.4972,
        "Hiking Distance": 22.5, "Hiking Elevation Gain": 1889.76, "Class": "4",
        "Description": "A rugged summit rising above the San Luis Valley.",
    },
    {
        "Name": "Longs Peak", "Range": "Front Range",
        "XCoord": 31, "YCoord": 5,
        "Elevation": 4346, "Prominence": 896,
        "Latitude Degrees": 40.255, "Longitude Degrees": -105.6151,
        "Hiking Distance": 23.3, "Hiking Elevation Gain": 1554.48, "Class": "3",
        "Description": "Known for the Diamond, its dramatic east face.",
    },
    {
        "Name": "Maroon Peak", "Range": "Elk Mountains",
        "XCoord": 18, "YCoord": 15,
        "Elevation": 4317, "Prominence": 712,
        "Latitude Degrees": 39.0708, "Longitude Degrees": -106.989,
        "Hiking Distance": 19.3, "Hiking Elevation Gain": 1463.04, "Class": "3",
        "Description": "With North Maroon Peak, it forms the Maroon Bells.",
    },
    {
        "Name": "Missouri Mountain", "Range": "Sawatch Range",
        "XCoord": 24, "YCoord": 16,
        "Elevation": 4289.8, "Prominence": 258,
        "Latitude Degrees": 38.9476, "Longitude Degrees": -106.3785,
        "Hiking Distance": 16.9, "Hiking Elevation Gain": 1371.6, "Class": "2",
        "Description": "A Sawatch summit in the Collegiate Peaks Wilderness.",
    },
    {
        "Name": "Mt. Antero", "Range": "Sawatch Range",
        "XCoord": 26, "YCoord": 19,
        "Elevation": 4351.4, "Prominence": 763,
        "Latitude Degrees": 38.6741, "Longitude Degrees": -106.2462,
        "Hiking Distance": 24.9, "Hiking Elevation Gain": 1584.96, "Class": "2",
        "Description": "A southern Sawatch summit in San Isabel National Forest.",
    },
    {
        "Name": "Mt. Belford", "Range": "Sawatch Range",
        "XCoord": 24, "YCoord": 15,
        "Elevation": 4329.1, "Prominence": 408,
        "Latitude Degrees": 38.9607, "Longitude Degrees": -106.3607,
        "Hiking Distance": 12.9, "Hiking Elevation Gain": 1371.6, "Class": "2",
        "Description": "A Sawatch summit near Mt. Oxford and Missouri Mountain.",
    },
    {
        "Name": "Mt. Bierstadt", "Range": "Front Range",
        "XCoord": 30, "YCoord": 11,
        "Elevation": 4287, "Prominence": 219,
        "Latitude Degrees": 39.5826, "Longitude Degrees": -105.6688,
        "Hiking Distance": 11.7, "Hiking Elevation Gain": 868.68, "Class": "2",
        "Description": "A Front Range summit near Denver.",
    },
    {
        "Name": "Mt. Blue Sky", "Range": "Front Range",
        "XCoord": 31, "YCoord": 11,
        "Elevation": 4350, "Prominence": 844,
        "Latitude Degrees": 39.5883, "Longitude Degrees": -105.6438,
        "Hiking Distance": 8.9, "Hiking Elevation Gain": 609.6, "Class": "2",
        "Description": "A Front Range summit reached by the Mount Blue Sky Scenic Byway.",
    },
    {
        "Name": "Mt. Bross", "Range": "Mosquito Range",
        "XCoord": 26, "YCoord": 13,
        "Elevation": 4321.6, "Prominence": 95,
        "Latitude Degrees": 39.3354, "Longitude Degrees": -106.1077,
        "Hiking Distance": 5.2, "Hiking Elevation Gain": 685.8, "Class": "2",
        "Description": "A Mosquito Range summit near Mt. Democrat and Mt. Lincoln.",
    },
    {
        "Name": "Mt. Columbia", "Range": "Sawatch Range",
        "XCoord": 26, "YCoord": 16,
        "Elevation": 4290.8, "Prominence": 272,
        "Latitude Degrees": 38.9039, "Longitude Degrees": -106.2975,
        "Hiking Distance": 19.3, "Hiking Elevation Gain": 1295.4, "Class": "2",
        "Description": "A Collegiate Peak overlooking the Arkansas River Valley.",
    },
    {
        "Name": "Mt. Democrat", "Range": "Mosquito Range",
        "XCoord": 24, "YCoord": 12,
        "Elevation": 4314.5, "Prominence": 234,
        "Latitude Degrees": 39.3396, "Longitude Degrees": -106.14,
        "Hiking Distance": 6.4, "Hiking Elevation Gain": 655.32, "Class": "2",
        "Description": "A Mosquito Range summit on the DeCaLiBron Loop.",
    },
    {
        "Name": "Mt. Elbert", "Range": "Sawatch Range",
        "XCoord": 23, "YCoord": 14,
        "Elevation": 4401.2, "Prominence": 2772,
        "Latitude Degrees": 39.1178, "Longitude Degrees": -106.4454,
        "Hiking Distance": 15.7, "Hiking Elevation Gain": 1371.6, "Class": "1",
        "Description": "Highest summit in Colorado and the Rocky Mountains.",
    },
    {
        "Name": "Mt. Eolus", "Range": "San Juan Mountains",
        "XCoord": 13, "YCoord": 27,
        "Elevation": 4295, "Prominence": 312,
        "Latitude Degrees": 37.6218, "Longitude Degrees": -107.6227,
        "Hiking Distance": 9.7, "Hiking Elevation Gain": 944.88, "Class": "3",
        "Description": "A Chicago Basin summit in the Needle Mountains.",
    },
    {
        "Name": "Mt. Harvard", "Range": "Sawatch Range",
        "XCoord": 25, "YCoord": 16,
        "Elevation": 4395.6, "Prominence": 719,
        "Latitude Degrees": 38.9244, "Longitude Degrees": -106.3207,
        "Hiking Distance": 22.5, "Hiking Elevation Gain": 1402.08, "Class": "2",
        "Description": "Highest summit of the Collegiate Peaks.",
    },
    {
        "Name": "Mt. Lincoln", "Range": "Mosquito Range",
        "XCoord": 26, "YCoord": 12,
        "Elevation": 4356.5, "Prominence": 1177,
        "Latitude Degrees": 39.3515, "Longitude Degrees": -106.1116,
        "Hiking Distance": 9.7, "Hiking Elevation Gain": 792.48, "Class": "2",
        "Description": "Highest summit in the Mosquito Range, named for President Lincoln.",
    },
    {
        "Name": "Mt. Lindsey", "Range": "Sangre de Cristo Range",
        "XCoord": 33, "YCoord": 26,
        "Elevation": 4282, "Prominence": 470,
        "Latitude Degrees": 37.5837, "Longitude Degrees": -105.4449,
        "Hiking Distance": 13.3, "Hiking Elevation Gain": 1066.8, "Class": "3-",
        "Description": "A Sangre de Cristo summit with a rocky upper ridge.",
    },
    {
        "Name": "Mt. Massive", "Range": "Sawatch Range",
        "XCoord": 23, "YCoord": 13,
        "Elevation": 4398, "Prominence": 598,
        "Latitude Degrees": 39.1875, "Longitude Degrees": -106.4757,
        "Hiking Distance": 23.3, "Hiking Elevation Gain": 1371.6, "Class": "2",
        "Description": "Its long summit ridge includes five summits above 14,000 feet.",
    },
    {
        "Name": "Mt. of the Holy Cross", "Range": "Sawatch Range",
        "XCoord": 23, "YCoord": 11,
        "Elevation": 4270.5, "Prominence": 644,
        "Latitude Degrees": 39.4668, "Longitude Degrees": -106.4817,
        "Hiking Distance": 18.1, "Hiking Elevation Gain": 1706.88, "Class": "2",
        "Description": "Named for the cross-shaped snowfield on its northeast face.",
    },
    {
        "Name": "Mt. Oxford", "Range": "Sawatch Range",
        "XCoord": 25, "YCoord": 15,
        "Elevation": 4315.9, "Prominence": 199,
        "Latitude Degrees": 38.9648, "Longitude Degrees": -106.3388,
        "Hiking Distance": 17.7, "Hiking Elevation Gain": 1798.32, "Class": "2",
        "Description": "Often climbed together with nearby Mt. Belford.",
    },
    {
        "Name": "Mt. Princeton", "Range": "Sawatch Range",
        "XCoord": 26, "YCoord": 18,
        "Elevation": 4329.3, "Prominence": 664,
        "Latitude Degrees": 38.7492, "Longitude Degrees": -106.2424,
        "Hiking Distance": 10.5, "Hiking Elevation Gain": 975.36, "Class": "2",
        "Description": "Overlooks the Arkansas River Valley from the Sawatch Range.",
    },
    {
        "Name": "Mt. Shavano", "Range": "Sawatch Range",
        "XCoord": 25, "YCoord": 19,
        "Elevation": 4337.7, "Prominence": 493,
        "Latitude Degrees": 38.6192, "Longitude Degrees": -106.2393,
        "Hiking Distance": 15.3, "Hiking Elevation Gain": 1371.6, "Class": "2",
        "Description": "Known for the angel-shaped snowfield called the Angel of Shavano.",
    },
    {
        "Name": "Mt. Sherman", "Range": "Mosquito Range",
        "XCoord": 26, "YCoord": 14,
        "Elevation": 4280, "Prominence": 259,
        "Latitude Degrees": 39.225, "Longitude Degrees": -106.1699,
        "Hiking Distance": 8.4, "Hiking Elevation Gain": 640.08, "Class": "1",
        "Description": "A Mosquito Range summit with broad, gentle ridgelines.",
    },
    {
        "Name": "Mt. Sneffels", "Range": "San Juan Mountains",
        "XCoord": 11, "YCoord": 23,
        "Elevation": 4315.4, "Prominence": 930,
        "Latitude Degrees": 38.0038, "Longitude Degrees": -107.7923,
        "Hiking Distance": 9.7, "Hiking Elevation Gain": 883.92, "Class": "3-",
        "Description": "Known as the Queen of the San Juans.",
    },
    {
        "Name": "Mt. Wilson", "Range": "San Juan Mountains",
        "XCoord": 9, "YCoord": 25,
        "Elevation": 4344, "Prominence": 1227,
        "Latitude Degrees": 37.8391, "Longitude Degrees": -107.9916,
        "Hiking Distance": 20.1, "Hiking Elevation Gain": 1341.12, "Class": "3",
        "Description": "A San Miguel Mountains summit in the Lizard Head Wilderness.",
    },
    {
        "Name": "Mt. Yale", "Range": "Sawatch Range",
        "XCoord": 25, "YCoord": 17,
        "Elevation": 4328.2, "Prominence": 578,
        "Latitude Degrees": 38.8442, "Longitude Degrees": -106.3138,
        "Hiking Distance": 15.3, "Hiking Elevation Gain": 1310.64, "Class": "2",
        "Description": "A Collegiate Peak with a paved road to its Denny Creek trailhead.",
    },
    {
        "Name": "Pikes Peak", "Range": "Front Range",
        "XCoord": 36, "YCoord": 17,
        "Elevation": 4302.31, "Prominence": 1686,
        "Latitude Degrees": 38.8405, "Longitude Degrees": -105.0442,
        "Hiking Distance": 38.6, "Hiking Elevation Gain": 2316.48, "Class": "1",
        "Description": "A Front Range landmark with a road to its summit.",
    },
    {
        "Name": "Pyramid Peak", "Range": "Elk Mountains",
        "XCoord": 19, "YCoord": 15,
        "Elevation": 4274.7, "Prominence": 499,
        "Latitude Degrees": 39.0717, "Longitude Degrees": -106.9502,
        "Hiking Distance": 13.3, "Hiking Elevation Gain": 1371.6, "Class": "4",
        "Description": "A rugged Elk Mountains summit near Aspen.",
    },
    {
        "Name": "Quandary Peak", "Range": "Tenmile Range",
        "XCoord": 26, "YCoord": 11,
        "Elevation": 4349.9, "Prominence": 343,
        "Latitude Degrees": 39.3973, "Longitude Degrees": -106.1064,
        "Hiking Distance": 10.9, "Hiking Elevation Gain": 1051.56, "Class": "1",
        "Description": "Highest summit in the Tenmile Range.",
    },
    {
        "Name": "Redcloud Peak", "Range": "San Juan Mountains",
        "XCoord": 14, "YCoord": 23,
        "Elevation": 4280, "Prominence": 438,
        "Latitude Degrees": 37.941, "Longitude Degrees": -107.4219,
        "Hiking Distance": 14.5, "Hiking Elevation Gain": 1127.76, "Class": "2",
        "Description": "Named for its red summit rocks; often climbed with Sunshine Peak.",
    },
    {
        "Name": "San Luis Peak", "Range": "San Juan Mountains",
        "XCoord": 19, "YCoord": 24,
        "Elevation": 4273.8, "Prominence": 949,
        "Latitude Degrees": 37.9868, "Longitude Degrees": -106.9313,
        "Hiking Distance": 21.7, "Hiking Elevation Gain": 1097.28, "Class": "1",
        "Description": "Highest summit in the remote La Garita Mountains.",
    },
    {
        "Name": "Snowmass Mountain", "Range": "Elk Mountains",
        "XCoord": 17, "YCoord": 15,
        "Elevation": 4297.3, "Prominence": 351,
        "Latitude Degrees": 39.1188, "Longitude Degrees": -107.0665,
        "Hiking Distance": 35.4, "Hiking Elevation Gain": 1767.84, "Class": "3",
        "Description": "Known for the broad snowfield on its eastern slopes.",
    },
    {
        "Name": "Sunlight Peak", "Range": "San Juan Mountains",
        "XCoord": 14, "YCoord": 26,
        "Elevation": 4287, "Prominence": 122,
        "Latitude Degrees": 37.6274, "Longitude Degrees": -107.5959,
        "Hiking Distance": 9.7, "Hiking Elevation Gain": 914.4, "Class": "4",
        "Description": "A Chicago Basin summit with an exposed summit block.",
    },
    {
        "Name": "Sunshine Peak", "Range": "San Juan Mountains",
        "XCoord": 14, "YCoord": 24,
        "Elevation": 4269, "Prominence": 153,
        "Latitude Degrees": 37.9228, "Longitude Degrees": -107.4256,
        "Hiking Distance": 19.7, "Hiking Elevation Gain": 1463.04, "Class": "2",
        "Description": "Often climbed together with neighboring Redcloud Peak.",
    },
    {
        "Name": "Tabeguache Peak", "Range": "Sawatch Range",
        "XCoord": 25, "YCoord": 18,
        "Elevation": 4316.7, "Prominence": 139,
        "Latitude Degrees": 38.6255, "Longitude Degrees": -106.2509,
        "Hiking Distance": 18.5, "Hiking Elevation Gain": 1706.88, "Class": "2",
        "Description": "A southern Sawatch summit beside Mt. Shavano.",
    },
    {
        "Name": "Torreys Peak", "Range": "Front Range",
        "XCoord": 29, "YCoord": 9,
        "Elevation": 4351, "Prominence": 171,
        "Latitude Degrees": 39.6428, "Longitude Degrees": -105.8212,
        "Hiking Distance": 12.5, "Hiking Elevation Gain": 914.4, "Class": "1",
        "Description": "Neighbors Grays Peak on the Continental Divide.",
    },
    {
        "Name": "Uncompahgre Peak", "Range": "San Juan Mountains",
        "XCoord": 14, "YCoord": 22,
        "Elevation": 4365, "Prominence": 1304,
        "Latitude Degrees": 38.0717, "Longitude Degrees": -107.4621,
        "Hiking Distance": 12.1, "Hiking Elevation Gain": 914.4, "Class": "2",
        "Description": "Highest summit in the San Juan Mountains.",
    },
    {
        "Name": "Wetterhorn Peak", "Range": "San Juan Mountains",
        "XCoord": 13, "YCoord": 23,
        "Elevation": 4274, "Prominence": 498,
        "Latitude Degrees": 38.0607, "Longitude Degrees": -107.5109,
        "Hiking Distance": 11.3, "Hiking Elevation Gain": 1005.84, "Class": "3",
        "Description": "A rocky San Juan summit near Lake City.",
    },
    {
        "Name": "Wilson Peak", "Range": "San Juan Mountains",
        "XCoord": 9, "YCoord": 24,
        "Elevation": 4274, "Prominence": 261,
        "Latitude Degrees": 37.8603, "Longitude Degrees": -107.9847,
        "Hiking Distance": 16.1, "Hiking Elevation Gain": 1188.72, "Class": "3",
        "Description": "Known for its appearance on Coors branding.",
    },
    {
        "Name": "Windom Peak", "Range": "San Juan Mountains",
        "XCoord": 14, "YCoord": 27,
        "Elevation": 4296, "Prominence": 667,
        "Latitude Degrees": 37.6212, "Longitude Degrees": -107.5919,
        "Hiking Distance": 9.7, "Hiking Elevation Gain": 914.4, "Class": "2+",
        "Description": "A Chicago Basin summit in the Needle Mountains.",
    },
]


denver = [-104.88111, 39.7618]

# Preserve one-pixel markers on both display resolutions.
REVEAL_STEPS = 32
CLASS_ORDER = {"1": 10, "1+": 11, "2-": 19, "2": 20, "2+": 21, "3-": 29, "3": 30, "3+": 31, "4-": 39, "4": 40, "4+": 41, "5": 50}

def choose_unseen_mountain(candidates):
    if len(candidates) == 0:
        fail("Cannot choose from an empty mountain list.")

    names = sorted([
        mountain["Name"]
        for mountain in candidates
    ])

    # Each eligible mountain set has its own selection history.
    cache_key = (
        "colorado14ers_shuffle_v1:" +
        json.encode(names)
    )

    raw = cache.get(cache_key)

    if raw != None:
        state = json.decode(raw)
    else:
        state = {}

    remaining = [
        name
        for name in state.get("remaining", [])
        if name in names
    ]

    last = state.get("last", "")

    # Refill only after every eligible mountain has been shown.
    starting_new_cycle = len(remaining) == 0

    if starting_new_cycle:
        remaining = list(names)

    # Avoid an immediate repeat across the cycle boundary,
    # unless only one mountain is eligible.
    choices = list(remaining)

    if starting_new_cycle and len(choices) > 1:
        choices = [
            name
            for name in choices
            if name != last
        ]

    selected_name = choices[random_index(len(choices))]

    remaining = [
        name
        for name in remaining
        if name != selected_name
    ]

    cache.set(
        cache_key,
        json.encode({
            "remaining": remaining,
            "last": selected_name,
        }),
        ttl_seconds = 2592000,
    )

    for mountain in candidates:
        if mountain["Name"] == selected_name:
            return mountain

    fail("Selected mountain was not found: " + selected_name)

def get_layout():
    double_size = canvas.is2x()
    width = canvas.width()
    height = canvas.height()
    bar_height = 16 if double_size else 8
    return {
        "display_width": width,
        "display_height": height,
        "map_width": width,
        "map_height": height - bar_height,
        "marquee_height": bar_height,
        "marquee_y": height - bar_height,
        "font": "terminus-16" if double_size else "5x8",
        "character_width": 8 if double_size else 5,
    }

def get_delay(config):
    value = config.str("scroll", "60")
    return int(value) if value in ["60", "45", "30"] else 60

def get_screen_coordinates_from_actual(map_points, location, screen_width, screen_height):
    longitudes = [point[0] for point in map_points]
    latitudes = [point[1] for point in map_points]
    min_long = min(longitudes)
    max_long = max(longitudes)
    min_lat = min(latitudes)
    max_lat = max(latitudes)
    if max_long == min_long or max_lat == min_lat:
        return [0, 0]
    x = int((location[0] - min_long) / (max_long - min_long) * (screen_width - 1))
    y = int((max_lat - location[1]) / (max_lat - min_lat) * (screen_height - 1))
    return [max(0, min(x, screen_width - 1)), max(0, min(y, screen_height - 1))]

def get_mountain_position(mountain, layout):
    return get_screen_coordinates_from_actual(
        colorado,
        [mountain["Longitude Degrees"], mountain["Latitude Degrees"]],
        layout["map_width"],
        layout["map_height"],
    )

def add_padding_to_child_element(element, left = 0, top = 0, right = 0, bottom = 0):
    return render.Padding(pad = (left, top, right, bottom), child = element)

def point_widget(position, color):
    return add_padding_to_child_element(
        render.Circle(color = color, diameter = 1),
        position[0],
        position[1],
    )

def fitted_outline(mountain, layout):
    key = (
        mountain["Name"].lower()
        .replace(".", "")
        .replace(" ", "_")
    )

    if key == "mt_of_the_holy_cross":
        key = "mt_holy_cross"

    if key not in MOUNTAIN_OUTLINES:
        fail("No outline pixel map found for: " + mountain["Name"])

    data = MOUNTAIN_OUTLINES[key]

    source_height = len(data)
    source_width = len(data[0])

    width = layout["map_width"]
    height = layout["map_height"]

    outline_color = "#fbbc28"

    # Extract only the uppermost pixel in each source column.
    # Interior mountain details are intentionally excluded.
    source_tops = []

    for x in range(source_width):
        top_y = None

        for y in range(source_height):
            if data[y][x] != 0:
                top_y = y
                break

        source_tops.append(top_y)

    visible_columns = [
        x
        for x in range(source_width)
        if source_tops[x] != None
    ]

    if len(visible_columns) == 0:
        return render.Box(
            width = width,
            height = height,
        )

    # Fill any empty source columns using the nearest column
    # that contains a contour pixel.
    filled_tops = []

    for x in range(source_width):
        if source_tops[x] != None:
            filled_tops.append(source_tops[x])
        else:
            nearest_x = visible_columns[0]

            for candidate_x in visible_columns:
                if abs(candidate_x - x) < abs(nearest_x - x):
                    nearest_x = candidate_x

            filled_tops.append(source_tops[nearest_x])

    # Calculate the skyline height at every output column.
    # Scale coordinates rather than resampling a thin bitmap.
    output_tops = []

    for x in range(width):
        if width > 1:
            source_x = (
                x * (source_width - 1) +
                (width - 1) // 2
            ) // (width - 1)
        else:
            source_x = 0

        source_y = filled_tops[source_x]

        if source_height > 1:
            output_y = (
                source_y * (height - 1) +
                (source_height - 1) // 2
            ) // (source_height - 1)
        else:
            output_y = 0

        output_tops.append(output_y)

    # Move the entire contour upward until its highest
    # point reaches row zero. Nothing is cropped.
    upward_shift = min(output_tops)

    skyline = [
        y - upward_shift
        for y in output_tops
    ]

    layers = [
        render.Box(
            width = width,
            height = height,
        ),
    ]

    # Draw each column and bridge changes in height.
    # These short vertical sections belong to the contour;
    # they are not interior ridgelines.
    for x in range(width):
        current_y = skyline[x]

        if x == 0:
            previous_y = current_y
        else:
            previous_y = skyline[x - 1]

        top = min(previous_y, current_y)
        bottom = max(previous_y, current_y)

        layers.append(
            render.Padding(
                pad = (x, top, 0, 0),
                child = render.Box(
                    width = 1,
                    height = bottom - top + 1,
                    color = outline_color,
                ),
            ),
        )

    return render.Stack(children = layers)

def outline_reveal_frames(outline, layout):
    frames = []
    for step in range(1, REVEAL_STEPS + 1):
        revealed = (layout["map_width"] * step + REVEAL_STEPS - 1) // REVEAL_STEPS
        children = [outline]
        if revealed < layout["map_width"]:
            children.append(add_padding_to_child_element(
                render.Box(width = layout["map_width"] - revealed, height = layout["map_height"], color = "#000000"),
                revealed,
            ))
        frames.append(render.Stack(children = children))
    return frames

def add_copies_of_frame_to_frames(frames, items, number_of_frames):
    for _ in range(number_of_frames):
        frames.append(render.Stack(children = list(items)))

def get_positions(config, visited, mountains, layout):
    color = config.str("visited_color", default_colors[3]) if visited else config.str("unvisited_color", default_colors[4])
    return [
        point_widget(get_mountain_position(mountain, layout), color)
        for mountain in mountains
        if config.bool("_%s" % mountain["Name"], False) == visited
    ]

def random_index(count):
    return 0 if count <= 1 else min(int(random.float() * count), count - 1)

def mountain_message(mountain, metric):
    distance = mountain["Hiking Distance"]
    gain = mountain["Hiking Elevation Gain"]
    elevation = mountain["Elevation"]
    distance_unit = "km"
    height_unit = "m"
    if not metric:
        distance *= km_to_miles
        gain *= meters_to_feet
        elevation *= meters_to_feet
        distance_unit = "mi"
        height_unit = "ft"
    distance_text = humanize.float("#,###.#", distance)
    gain_text = humanize.float("#,###.", math.round(gain))
    elevation_text = humanize.float("#,###.", math.round(elevation))

    statistics = "%s - %s. Summit %s %s. Listed hike: Class %s, %s %s, gain %s %s." % (
        mountain["Name"],
        mountain["Range"],
        elevation_text,
        height_unit,
        mountain["Class"],
        distance_text,
        distance_unit,
        gain_text,
        height_unit,
    )

    # Retain source descriptions as descriptive text, not route instructions.
    if random.float() >= 0.5:
        return statistics + " " + mountain["Description"]
    return statistics

def message_screen(config, layout, message):
    return render.Root(
        child = center_on_square(render.Column(children = [
            render.Text("Colorado 14ers", font = layout["font"], color = "#65D0E6"),
            render.Marquee(width = layout["display_width"], child = render.Text(message, font = layout["font"], color = "#FFAA00")),
        ])),
        show_full_animation = True,
        delay = get_delay(config),
    )

def main(config):
    layout = get_layout()
    if config.bool("instructions", False):
        return show_instructions_screen(config, layout)
    display_type = config.str("display", "random")
    if display_type not in ["random", "visited", "unvisited"]:
        display_type = "random"
    candidates = [
        mountain
        for mountain in mountain_data
        if display_type == "random" or
           (display_type == "visited" and config.bool("_%s" % mountain["Name"], False)) or
           (display_type == "unvisited" and not config.bool("_%s" % mountain["Name"], False))
    ]
    if not candidates:
        message = "No peaks marked visited. Mark your visited peaks in settings." if display_type == "visited" else "All tracked peaks marked visited!"
        return message_screen(config, layout, message)
    
    selected = choose_unseen_mountain(candidates)

    frames = []
    layers = []
    if config.bool("outline", False):
        outline = fitted_outline(selected, layout)
        frames.extend(outline_reveal_frames(outline, layout))
        layers.append(outline)
        add_copies_of_frame_to_frames(frames, layers, 5)
    denver_position = get_screen_coordinates_from_actual(colorado, denver, layout["map_width"], layout["map_height"])
    layers.append(point_widget(denver_position, config.str("denver_color", default_colors[1])))
    for visited in [True, False]:
        for marker in get_positions(config, visited, mountain_data, layout):
            layers.append(marker)
            frames.append(render.Stack(children = list(layers)))
        add_copies_of_frame_to_frames(frames, layers, 10)
    selected_marker = point_widget(get_mountain_position(selected, layout), config.str("selected_color", default_colors[0]))
    selected_layers = list(layers) + [selected_marker]

    # A one-pixel selected marker pulses without increasing its footprint.
    for _ in range(3):
        add_copies_of_frame_to_frames(frames, selected_layers, 8)
        add_copies_of_frame_to_frames(frames, layers, 4)
    add_copies_of_frame_to_frames(frames, selected_layers, 24)
    elements = [render.Animation(children = frames)]
    if config.bool("information_bar", False):
        message = mountain_message(selected, config.str("measurement", "metric") != "imperial")
        elements.append(add_padding_to_child_element(
            render.Marquee(
                width = layout["display_width"],
                offset_start = 15,
                child = render.Text(message, font = layout["font"], color = config.str("marquee_color", default_colors[2])),
            ),
            0,
            layout["marquee_y"],
        ))

    return render.Root(child = render.Stack(children = elements), show_full_animation = True, delay = get_delay(config))

def show_instructions_screen(config, layout):
    messages = [
        "Colorado 14ers",
        "Pick a random peak from all, visited, or unvisited. Mark your visited peaks in settings. No matches produces a message rather than selecting an unrelated peak.",
        "Red marks Denver; yellow is visited; grey is unvisited. The selected peak pulses in its selected color. Every marker stays one pixel on either display.",
        "Optional mountain silhouettes are fitted and centered without stretching. Sort the checklist by name, range, elevation, hiking distance, or class. Listed hike figures do not identify a route or trailhead; verify current details before a trip.",
    ]
    children = []
    offset = 15
    for index in range(len(messages)):
        message = messages[index]
        children.append(render.Marquee(
            width = layout["display_width"],
            offset_start = offset,
            child = render.Text(message, font = layout["font"], color = "#65D0E6" if index == 0 else "#F4A306"),
        ))
        offset += len(message) * layout["character_width"]
    return render.Root(child = center_on_square(render.Column(children = children)), show_full_animation = True, delay = get_delay(config))

def get_sorted_mountain_toggles(sort_key):
    if sort_key not in ["Name", "Range", "Elevation", "Hiking Distance", "Class"]:
        sort_key = "Name"
    if sort_key == "Class":
        display_data = sorted(mountain_data, key = lambda mountain: (CLASS_ORDER.get(mountain["Class"], 999), mountain["Name"]))
    else:
        display_data = sorted(mountain_data, key = lambda mountain: (mountain[sort_key], mountain["Name"]))
    toggles = []
    for mountain in display_data:
        description = mountain["Range"]
        if sort_key == "Class":
            description = "Listed route class: " + mountain["Class"]
        elif sort_key == "Elevation":
            description = "Summit: %s m / %s ft" % (
                humanize.float("#,###", math.round(mountain["Elevation"])),
                humanize.float("#,###", math.round(mountain["Elevation"] * meters_to_feet)),
            )
        elif sort_key == "Hiking Distance":
            description = "Listed hike: %s km / %s mi" % (
                humanize.float("#,###.0", mountain["Hiking Distance"]),
                humanize.float("#,###.0", mountain["Hiking Distance"] * km_to_miles),
            )
        toggles.append(schema.Toggle(
            id = "_%s" % mountain["Name"],
            name = mountain["Name"],
            desc = description,
            icon = "mountain",
            default = False,
        ))
    return toggles

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
            schema.Dropdown(
                id = "scroll",
                name = "Scroll",
                desc = "Scroll Speed",
                icon = "scroll",
                options = scroll_speed_options,
                default = scroll_speed_options[0].value,
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
                default = default_colors[0],
            ),
            schema.Color(
                id = "denver_color",
                name = "Color",
                desc = "Denver Location Color",
                icon = "brush",
                default = default_colors[1],
            ),
            schema.Color(
                id = "marquee_color",
                name = "Color",
                desc = "Scrolling Information Text Color",
                icon = "brush",
                default = default_colors[2],
            ),
            schema.Color(
                id = "visited_color",
                name = "Color",
                desc = "Visited Location Color",
                icon = "brush",
                default = default_colors[3],
            ),
            schema.Color(
                id = "unvisited_color",
                name = "Color",
                desc = "Unvisited Location Color",
                icon = "brush",
                default = default_colors[4],
            ),
            schema.Dropdown(
                id = "measurement",
                name = "Measurement System",
                desc = "Measurement System",
                icon = "ruler",
                options = measurement_options,
                default = measurement_options[0].value,
            ),
            schema.Dropdown(
                id = "sort",
                name = "Sort List of Mountains",
                desc = "",
                icon = "sort",
                options = sort_options,
                default = sort_options[0].value,
            ),
            schema.Dropdown(
                id = "display",
                name = "Display",
                desc = "What to Display?",
                icon = "gear",
                options = display_options,
                default = display_options[0].value,
            ),
            schema.Generated(
                id = "visited",
                source = "sort",
                handler = get_sorted_mountain_toggles,
            ),
        ],
    )
