"""
Applet: Noderunners
Summary: Current song at Noderunners
Description: Shows the current song what is playing on Noderunners Radio.
Author: PMK (@pmk)
"""

load("animation.star", "animation")
load("http.star", "http")
load("images/background_image.gif", BACKGROUND_IMAGE_ASSET = "file")
load("render.star", "render")

BACKGROUND_IMAGE = BACKGROUND_IMAGE_ASSET.readall()

def get_current_song(ttl_seconds = 30):
    url = "https://jukebox.lighting/jukebox/status.json?chat_id=-1001672416970"
    response = http.get(url = url, ttl_seconds = ttl_seconds)
    if response.status_code == 200:
        return response.json()["title"]
    return "OFFLINE"

def metronome():
    return animation.Transformation(
        child = render.Box(
            width = 38,
            height = 22,
            child = render.Column(
                main_align = "start",
                cross_align = "center",
                children = [
                    render.Box(width = 1, height = 16, color = "#fff"),
                    render.Circle(diameter = 4, color = "#fc6a03"),
                ],
            ),
        ),
        duration = 100,
        delay = 0,
        origin = animation.Origin(0.5, 0),
        direction = "alternate",
        fill_mode = "forwards",
        keyframes = [
            animation.Keyframe(
                percentage = 0.0,
                transforms = [animation.Rotate(-55), animation.Rotate(0)],
                curve = "ease_in_out",
            ),
            animation.Keyframe(
                percentage = 0.5,
                transforms = [animation.Rotate(0), animation.Rotate(55)],
                curve = "ease_in_out",
            ),
            animation.Keyframe(
                percentage = 1.0,
                transforms = [animation.Rotate(-55), animation.Rotate(0)],
                curve = "ease_in_out",
            ),
        ],
    )

def tick_tock_next_block():
    color = "#fff"
    font = "Dina_r400-6"

    text_empty = [render.Text(content = "", color = color, font = font)] * 12
    text_tick = [render.Text(content = "TICK", color = color, font = font)] * 13
    text_tock = [render.Text(content = "TOCK", color = color, font = font)] * 13
    text_next = [render.Text(content = "NEXT", color = color, font = font)] * 13
    text_block = [render.Text(content = "BLOCK", color = color, font = font)] * 13

    return render.Animation(
        children = text_tick + text_empty + text_tock + text_empty + text_next + text_empty + text_block + text_empty,
    )

def now_playing(song):
    return render.Box(
        color = "#0008",
        width = 64,
        height = 9,
        child = render.Marquee(
            align = "center",
            width = 64,
            height = 10,
            child = render.Text(
                content = song,
                color = "#fff",
                font = "tb-8",
            ),
        ),
    )

def main():
    song = get_current_song()

    return render.Root(
        show_full_animation = True,
        max_age = 30,
        child = render.Stack(
            children = [
                render.Image(
                    src = BACKGROUND_IMAGE,
                    width = 64,
                    height = 32,
                ),
                render.Stack(
                    children = [
                        render.Padding(
                            pad = (29, 6, 0, 0),
                            child = tick_tock_next_block(),
                        ),
                        render.Padding(
                            pad = (22, 0, 0, 0),
                            child = metronome(),
                        ),
                        render.Padding(
                            pad = (0, 23, 0, 0),
                            child = now_playing(song),
                        ),
                    ],
                ),
            ],
        ),
    )
