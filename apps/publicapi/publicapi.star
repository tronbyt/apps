"""
Applet: Public Api
Summary: View random public apis
Description: Display a random public api from https://github.com/marcelscruz/public-apis
Author: noahpodgurski
"""

load("http.star", "http")
load("render.star", "render")
load("random.star", "random")
load("time.star", "time")

REFRESH_TIME = 86400*7 #once a week

# colors
YELLOW = "8eb707"
BLUE = "079ab7"

def get_all_apis():
    res = http.get("https://raw.githubusercontent.com/marcelscruz/public-apis/refs/heads/main/db/resources.json", ttl_seconds = REFRESH_TIME)
    if res.status_code != 200:
        fail("get_all_apis failed with status %d", res.status_code)
    return res.json()

def main():
    random.seed(time.now().unix // 30)
    all_apis = get_all_apis().get("entries")
    if not all_apis:
        fail("API response is missing 'entries' key or it is empty")
    random_api = all_apis[random.number(0, len(all_apis)-1)]

    return render.Root(
        child = render.Box(
            width = 64,
            height = 32,
            child = render.Padding(
                pad = (0, 1, 0, 0),
                child = render.Column(
                    main_align = "center",
                    cross_align = "center",
                    expanded = True,
                    children = [
                        render.WrappedText(align = "center", content = random_api["API"], color = YELLOW) if len(random_api["API"]) < 28 else render.Marquee(
                            offset_start = 32,
                            offset_end = 32,
                            width = 64,
                            height = 6,
                            child = render.Text(random_api["API"], color = YELLOW),
                        ),
                        render.Box(width = 64, height = 1, color = "857fc6"),
                        render.WrappedText(align = "center", content = random_api["Category"], font = "tom-thumb", color = BLUE) if len(random_api["Category"]) < 14 else render.Marquee(
                            offset_start = 32,
                            offset_end = 32,
                            width = 64,
                            height = 6,
                            child = render.Text(random_api["Category"], font = "tom-thumb", color = BLUE),
                        ),
                        # render.WrappedText("Auth: %s" % random_api["Auth"], font = "tom-thumb") if random_api["Auth"] else None,
                        render.WrappedText(align = "center", content = random_api["Description"], font = "tom-thumb") if len(random_api["Description"]) < 28 else render.Marquee(
                            offset_start = 32,
                            offset_end = 32,
                            width = 64,
                            child = render.Text(random_api["Description"], font = "tom-thumb"),
                        ),
                    ],
                ),
            ),
        ),
    )
