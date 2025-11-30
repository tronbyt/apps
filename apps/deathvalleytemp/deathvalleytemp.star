"""
Applet: Death Valley Thermometer
Summary: Death Valley temp in F and C
Description: Based on the thermometers at Death Valley National Park, one of the hottest places on earth
Author: Kyle Stark @kaisle51
Thanks: Dubhouze-Tāvis/tavdog for general help and FtoC, Chad Milburn for dark mode logic, wshue0 for API stuff
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("images/celcius.png", CELCIUS_ASSET = "file")
load("images/celcius_white.png", CELCIUS_WHITE_ASSET = "file")
load("images/char_dash.png", CHAR_DASH_ASSET = "file")
load("images/char_e.png", CHAR_E_ASSET = "file")
load("images/char_eight.png", CHAR_EIGHT_ASSET = "file")
load("images/char_five.png", CHAR_FIVE_ASSET = "file")
load("images/char_four.png", CHAR_FOUR_ASSET = "file")
load("images/char_nine.png", CHAR_NINE_ASSET = "file")
load("images/char_one.png", CHAR_ONE_ASSET = "file")
load("images/char_r.png", CHAR_R_ASSET = "file")
load("images/char_seven.png", CHAR_SEVEN_ASSET = "file")
load("images/char_six.png", CHAR_SIX_ASSET = "file")
load("images/char_three.png", CHAR_THREE_ASSET = "file")
load("images/char_two.png", CHAR_TWO_ASSET = "file")
load("images/char_zero.png", CHAR_ZERO_ASSET = "file")
load("images/fahrenheit.png", FAHRENHEIT_ASSET = "file")
load("images/fahrenheit_white.png", FAHRENHEIT_WHITE_ASSET = "file")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")

IMG_CELCIUS = CELCIUS_ASSET.readall()
IMG_CELCIUS_WHITE = CELCIUS_WHITE_ASSET.readall()
IMG_FAHRENHEIT = FAHRENHEIT_ASSET.readall()
IMG_FAHRENHEIT_WHITE = FAHRENHEIT_WHITE_ASSET.readall()

DEFAULT_DARK_MODE = False
CACHE_TTL_SECONDS = 1799  #half hour
WEATHER_URL = "https://api.weather.gov/gridpoints/VEF/63,120/forecast/hourly"

def main(config):
    dark_mode = config.bool("dark_mode") if config.bool("dark_mode") != None and config.bool("dark_mode") != "" else DEFAULT_DARK_MODE

    tempF = get_cachable_data(WEATHER_URL, CACHE_TTL_SECONDS)
    tempFstring = str(int(math.round(float(tempF)))) if tempF != "Err" else "Err"
    tempFarray = []

    if len(tempFstring) == 2:
        tempFarray = ["x", tempFstring[0], tempFstring[1]]
    elif len(tempFstring) == 3:
        if tempFstring == "Err":
            tempFarray = ["E", "R", "R"]
        else:
            tempFarray = [tempFstring[0], tempFstring[1], tempFstring[2]]

    def FtoC(F):
        c = (float(F) - 32) * 0.55
        c = int(c * 10)
        return c / 10.0

    tempC = FtoC(tempF) if tempFstring != "Err" else ""
    tempCstring = str(int(tempC)) if tempFstring != "Err" else ""
    tempCarray = []

    if len(tempCstring) == 2:
        tempCarray = [tempCstring[0], tempCstring[1]]
    elif len(tempCstring) == 1:
        tempCarray = ["x", tempCstring[0]]
    else:
        tempCarray = ["-", "-"]

    def getTempDigit(digit):
        if digit == "1":
            return IMG_ONE
        elif digit == "2":
            return IMG_TWO
        elif digit == "3":
            return IMG_THREE
        elif digit == "4":
            return IMG_FOUR
        elif digit == "5":
            return IMG_FIVE
        elif digit == "6":
            return IMG_SIX
        elif digit == "7":
            return IMG_SEVEN
        elif digit == "8":
            return IMG_EIGHT
        elif digit == "9":
            return IMG_NINE
        elif digit == "0":
            return IMG_ZERO
        elif digit == "E":
            return IMG_E
        elif digit == "R":
            return IMG_R
        else:
            return IMG_DASH

    def generateImageF(i):
        if tempFarray[i] == "x":
            return render.Box(
                width = 9,
                height = 15,
                color = "#000",
            )
        else:
            return render.Image(
                src = base64.decode(getTempDigit(tempFarray[i])),
                width = 9,
                height = 15,
            )

    def layoutF():
        return render.Padding(
            child = render.Box(
                render.Row(
                    children = [
                        render.Box(
                            width = 1,
                            height = 15,
                            color = "#000",
                        ),
                        generateImageF(0),
                        generateImageF(1),
                        generateImageF(2),
                        render.Box(
                            width = 1,
                            height = 15,
                            color = "#000",
                        ),
                    ],
                ),
                color = "#000",
                width = 29,
                height = 15,
            ),
            pad = (11, 1, 0, 0),
        )

    def generateImageC(i):
        if tempCarray[i] == "x":
            return render.Box(
                width = 9,
                height = 15,
                color = "#000",
            )
        else:
            return render.Image(
                src = base64.decode(getTempDigit(tempCarray[i])),
                width = 9,
                height = 15,
            )

    def layoutC():
        return render.Padding(
            child = render.Box(
                render.Row(
                    children = [
                        render.Box(
                            width = 1,
                            height = 15,
                            color = "#000",
                        ),
                        generateImageC(0),
                        generateImageC(1),
                        render.Box(
                            width = 1,
                            height = 15,
                            color = "#000",
                        ),
                    ],
                ),
                color = "#000",
                width = 20,
                height = 15,
            ),
            pad = (11, 16, 0, 0),
        )

    return render.Root(
        child = render.Stack(
            children = [
                render.Box(
                    # border
                    width = 64,
                    height = 32,
                    color = "#fff" if dark_mode == False else "",
                ),
                render.Padding(
                    render.Box(
                        # inner box
                        width = 58,
                        height = 30,
                        color = "#e5ffff" if dark_mode == False else "",
                    ),
                    pad = (3, 1, 0, 0),
                ),
                render.Padding(
                    render.Image(
                        src = IMG_FAHRENHEIT if dark_mode == False else IMG_FAHRENHEIT_WHITE,
                        width = 12,
                        height = 12,
                    ),
                    pad = (42, 2, 0, 0),
                ),
                render.Padding(
                    render.Image(
                        src = IMG_CELCIUS if dark_mode == False else IMG_CELCIUS_WHITE,
                        width = 12,
                        height = 13,
                    ),
                    pad = (33, 17, 0, 0),
                ),
                layoutF(),
                layoutC(),
            ],
        ),
    )

def get_cachable_data(url, timeout):
    res = http.get(url = url, ttl_seconds = timeout)
    if res.status_code != 200:
        return "Err"

    temp_data = res.json()
    temp_f = str(temp_data["properties"]["periods"][0]["temperature"])

    return temp_f

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "dark_mode",
                name = "Dark mode",
                desc = "Toggle between light and dark modes",
                icon = "lightbulb",
                default = False,
            ),
        ],
    )

# number images
IMG_ONE = CHAR_ONE_ASSET.readall()
IMG_TWO = CHAR_TWO_ASSET.readall()
IMG_THREE = CHAR_THREE_ASSET.readall()
IMG_FOUR = CHAR_FOUR_ASSET.readall()
IMG_FIVE = CHAR_FIVE_ASSET.readall()
IMG_SIX = CHAR_SIX_ASSET.readall()
IMG_SEVEN = CHAR_SEVEN_ASSET.readall()
IMG_EIGHT = CHAR_EIGHT_ASSET.readall()
IMG_NINE = CHAR_NINE_ASSET.readall()
IMG_ZERO = CHAR_ZERO_ASSET.readall()
IMG_E = CHAR_E_ASSET.readall()
IMG_R = CHAR_R_ASSET.readall()
IMG_DASH = CHAR_DASH_ASSET.readall()
