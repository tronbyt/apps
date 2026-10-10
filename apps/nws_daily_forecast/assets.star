"""
Image assets for nws_daily_forecast.

The `file` loader returns opaque handles whose `.readall()` only works in the
file where the load() lives, so the loads, readall() calls, and the resulting
dicts all belong here. The main applet imports the dicts.
"""

load("images/cloudy.png", _CLOUDY = "file")
load("images/foggy.png", _FOGGY = "file")
load("images/haily.png", _HAILY = "file")
load("images/moony.png", _MOONY = "file")
load("images/moonyish.png", _MOONYISH = "file")
load("images/rainy.png", _RAINY = "file")
load("images/sleety.png", _SLEETY = "file")
load("images/sleety2.png", _SLEETY2 = "file")
load("images/snowy.png", _SNOWY = "file")
load("images/snowy2.png", _SNOWY2 = "file")
load("images/sunny.png", _SUNNY = "file")
load("images/sunnyish.png", _SUNNYISH = "file")
load("images/thundery.png", _THUNDERY = "file")
load("images/tornady.png", _TORNADY = "file")
load("images/wind_e.png", _WIND_E = "file")
load("images/wind_n.png", _WIND_N = "file")
load("images/wind_ne.png", _WIND_NE = "file")
load("images/wind_nw.png", _WIND_NW = "file")
load("images/wind_s.png", _WIND_S = "file")
load("images/wind_se.png", _WIND_SE = "file")
load("images/wind_sw.png", _WIND_SW = "file")
load("images/wind_w.png", _WIND_W = "file")
load("images/windy.png", _WINDY = "file")

WEATHER_ICONS = {
    "cloudy": _CLOUDY.readall(),
    "foggy": _FOGGY.readall(),
    "haily": _HAILY.readall(),
    "moony": _MOONY.readall(),
    "moonyish": _MOONYISH.readall(),
    "rainy": _RAINY.readall(),
    "sleety": _SLEETY.readall(),
    "sleety2": _SLEETY2.readall(),
    "snowy": _SNOWY.readall(),
    "snowy2": _SNOWY2.readall(),
    "sunny": _SUNNY.readall(),
    "sunnyish": _SUNNYISH.readall(),
    "thundery": _THUNDERY.readall(),
    "tornady": _TORNADY.readall(),
    "windy": _WINDY.readall(),
}

WIND_ICONS = {
    "E": _WIND_E.readall(),
    "N": _WIND_N.readall(),
    "NE": _WIND_NE.readall(),
    "NW": _WIND_NW.readall(),
    "S": _WIND_S.readall(),
    "SE": _WIND_SE.readall(),
    "SW": _WIND_SW.readall(),
    "W": _WIND_W.readall(),
}
