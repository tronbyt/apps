"""
Applet: Florida Lighthouses
Summary: Displays Florida lighhouses
Description: Displays Florida Lighhouse locations.
Author: Robert Ison
"""

load("math.star", "math")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("support_files/florida_lighthouses.star", "FLORIDA_LIGHTHOUSES")
load("support_files/florida_map.star", "FLORIDA_MAP")
load("support_files/lighthouse_animation.gif", LIGHTHOUSE_GIF_ASSET = "file")
load("support_files/lighthouse_animation_2x.gif", LIGHTHOUSE_GIF_2X_ASSET = "file")

MAP_CITIES_COLOR = "#f00"
VISITED_COLOR = "#ffff00"
UNVISITED_COLOR = "#565a06"
BRIGHT_OUTLINE_COLOR = "#fff"
DULL_OUTLINE_COLOR = "#111"

CONFIG_PATTERN_LIGHTHOUSES = "Item_%s_%s"

def main(config):
    if canvas.is2x():
        LIGHTHOUSE_GIF = LIGHTHOUSE_GIF_2X_ASSET.readall()
        MAP_PIXEL_SIZE = [80, 50]
    else:
        LIGHTHOUSE_GIF = LIGHTHOUSE_GIF_ASSET.readall()
        MAP_PIXEL_SIZE = [45, 30]

    is_display_cities = config.bool("displayMajorCities")
    is_display_picks = config.bool("pickVisits")
    is_display_art = config.bool("displayArtwork")

    #Get the map area based on the points of the map
    map_area = define_map_area(FLORIDA_MAP)
    #map_points = get_map_points(FLORIDA_MAP, map_area, MAP_PIXEL_SIZE)

    # get just the coordinates from the Florida Lighthouses
    col_indexes = [3, 4]
    lighthouse_coordinates = [[row[col] for col in col_indexes] for row in FLORIDA_LIGHTHOUSES]

    #Just in case lighthouses expand the map area
    map_area = define_map_area(lighthouse_coordinates, map_area[0], map_area[1])

    map_items = []

    #Image Background
    if is_display_art:
        map_items.append(render.Padding(render.Image(src = LIGHTHOUSE_GIF), (0, 0, 0, 0)))

    #Display Map
    map_outline_color = BRIGHT_OUTLINE_COLOR
    if is_display_art:
        map_outline_color = DULL_OUTLINE_COLOR

    map_items = append_items_to_render(map_items, get_map_points(FLORIDA_MAP, map_area, MAP_PIXEL_SIZE), map_outline_color)

    # Major Cities: Orlando, Tallahassee, Miami, Jacksonville, Tampa, Ft. Myers, Pensacola
    if is_display_cities:
        map_items = append_items_to_render(map_items, get_map_points([[-81.29937, 28.4162], [-84.25342, 30.4551], [-80.20862, 25.7752], [-81.6616, 30.3369], [-82.4629, 28.1259], [-81.83182, 26.6196], [-87.1895, 30.4433]], map_area, MAP_PIXEL_SIZE), MAP_CITIES_COLOR)

    #All Lighthouses
    map_items = append_items_to_render(map_items, get_map_points(lighthouse_coordinates, map_area, MAP_PIXEL_SIZE), UNVISITED_COLOR)

    #Visited Lighthouses
    if is_display_picks:
        map_items = append_items_to_render(map_items, get_map_points(lighthouse_coordinates, map_area, MAP_PIXEL_SIZE, config), VISITED_COLOR)

    return render.Root(
        render.Stack(
            map_items,
        ),
    )

def define_map_area(map_coordinates, longitude_range = [], latitude_range = []):
    if not longitude_range:
        longitude_range = [map_coordinates[0][0], map_coordinates[0][0]]

    if not latitude_range:
        latitude_range = [map_coordinates[0][1], map_coordinates[0][1]]

    #find extremes
    for dot in map_coordinates:
        if (dot[0] < longitude_range[0]):
            longitude_range[0] = dot[0]
        if (dot[0] > longitude_range[1]):
            longitude_range[1] = dot[0]
        if (dot[1] < latitude_range[0]):
            latitude_range[0] = dot[1]
        if (dot[1] > latitude_range[1]):
            latitude_range[1] = dot[1]

    return [longitude_range, latitude_range]

def get_map_points(map_coordinates, map_area, pixel_area, config = []):
    map_array = [[0 for j in range(pixel_area[1])] for i in range(pixel_area[0])]

    for point in map_coordinates:
        x = int(math.round(abs(map_area[0][0] - point[0]) / abs(map_area[0][0] - map_area[0][1]) * (pixel_area[0] - 1)))
        y = pixel_area[1] - 1 - int(math.round(abs(map_area[1][0] - point[1]) / abs(map_area[1][0] - map_area[1][1]) * (pixel_area[1] - 1)))

        if map_array[x][y] == 0:
            if config:
                if config.bool(CONFIG_PATTERN_LIGHTHOUSES % (point[0], point[1])):
                    map_array[x][y] = 1
            else:
                map_array[x][y] = 1

    return map_array

def append_items_to_render(children, points, color):
    r = -1
    c = 0
    for row in points:
        r = r + 1
        c = 0
        for item in row:
            if (item > 0):
                children.append(render.Padding(render.Circle(diameter = 1, color = color), (r, c, 0, 0)))
            c = c + 1

    return children

def get_lighthouses(enabled):
    # default
    items = sorted(FLORIDA_LIGHTHOUSES, key = lambda x: x[0])
    icon = "towerCell"

    if enabled == "true":
        return [
            schema.Toggle(id = CONFIG_PATTERN_LIGHTHOUSES % (item[3], item[4]), name = item[0], desc = "%s" % item[5], icon = icon, default = False)
            for item in items
        ]
    else:
        return []

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "displayArtwork",
                name = "Display Background Image?",
                desc = "Display Background Image?",
                icon = "photoFilm",
                default = True,
            ),
            schema.Toggle(
                id = "displayMajorCities",
                name = "Display Cities?",
                desc = "Display major cities?",
                icon = "city",
                default = False,
            ),
            schema.Toggle(
                id = "pickVisits",
                name = "Highlight Visited?",
                desc = "Highlight the lighthouses you've visted?",
                icon = "highlighter",
                default = False,
            ),
            schema.Generated(
                id = "lighthouseList",
                source = "pickVisits",
                handler = get_lighthouses,
            ),
        ],
    )
