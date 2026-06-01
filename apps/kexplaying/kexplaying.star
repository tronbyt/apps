"""
Applet: KEXPlaying
Summary: KEXP Now Playing
Description: Displays song, artist, and info currently streaming on kexp.org.
Author: Ken Winke
"""

load("http.star", "http")
load("images/kexp_logo.png", KEXP_LOGO_ASSET = "file")
load("images/kexp_mic.jpg", KEXP_MIC_ASSET = "file")
load("images/kexp_vinyl.png", KEXP_VINYL_ASSET = "file")
load("render.star", "render")

KEXP_LOGO = KEXP_LOGO_ASSET.readall()
KEXP_MIC = KEXP_MIC_ASSET.readall()
KEXP_VINYL = KEXP_VINYL_ASSET.readall()

KEXP_PLAY = "https://api.kexp.org/v2/plays/?format=json&limit=2"
KEXP_SHOW = "https://api.kexp.org/v1/show.json?limit=1"

def api_error():
    print("Error connecting to the API")
    return render.Root(
        child = render.Row(
            cross_align = "center",
            main_align = "space_between",
            expanded = True,
            children = [
                render.Padding(child = render.Image(src = KEXP_VINYL, height = 26, width = 26), pad = 1),
                render.Column(
                    cross_align = "end",
                    main_align = "space_between",
                    children = [
                        render.Text("Unable", font = "tb-8", color = "#FF2222"),
                        render.Text("to", font = "tb-8", color = "#FF2222"),
                        render.Text("connect", font = "tb-8", color = "#FF2222"),
                        render.Text("to KEXP", font = "tb-8", color = "#FF2222"),
                    ],
                ),
            ],
        ),
    )

def now_playing(song, artist, album):
    return render.Root(
        child = render.Column(
            children = [
                render.Stack(
                    children = [
                        render.Box(
                            width = 64,
                            height = 24,
                            color = "e68a00",
                        ),
                        render.Row(
                            expanded = True,
                            main_align = "space_evenly",
                            children = [
                                render.Padding(
                                    child = render.Image(src = album, height = 22, width = 22),
                                    pad = 1,
                                ),
                                render.Padding(
                                    child = render.Image(src = KEXP_LOGO, height = 22, width = 22),
                                    pad = 1,
                                ),
                            ],
                        ),
                    ],
                ),
                render.Stack(
                    children = [
                        render.Box(
                            width = 64,
                            height = 12,
                            color = "#000000",
                        ),
                        render.Marquee(
                            width = 64,
                            offset_start = 64,
                            child = render.Text("%s - %s" % (song, artist), font = "tb-8", color = "#e6e6e6"),
                        ),
                    ],
                ),
            ],
        ),
    )

def main():
    jplay = http.get(url = KEXP_PLAY, ttl_seconds = 120)
    jshow = http.get(url = KEXP_SHOW, ttl_seconds = 120)

    if (jplay.status_code or jshow.status_code) != 200:
        return api_error()

    playtype = jplay.json()["results"][0]["play_type"]

    host = jshow.json()["results"][0]["hosts"][0].get("name", "")
    if host == "":
        host = "KEXP DJ"

    song = jplay.json()["results"][0].get("song", host)
    artist = jplay.json()["results"][0].get("artist", "Airbreak")

    if playtype == "airbreak":
        hostimg = jshow.json()["results"][0]["hosts"][0].get("newimageuri", "")
        if hostimg == "":
            album = KEXP_MIC
        else:
            album = http.get(hostimg).body()
    elif playtype == "trackplay":
        thumbnail = jplay.json()["results"][0].get("thumbnail_uri", "")
        if thumbnail == "":
            album = KEXP_VINYL
        else:
            album = http.get(thumbnail).body()
    else:
        song = "- - - - -"
        artist = "- - - -"
        album = KEXP_VINYL

    return now_playing(song, artist, album)
