"""
Applet: VGK Next Game
Summary: Shows next VGK Game
Description: Shows the date of the next Vegas Golden Knights game.
Author: theimpossibleleap
"""

load("http.star", "http")
load("images/img.png", IMG_ASSET = "file")
load("render.star", "render")
load("time.star", "time")

IMG = IMG_ASSET.readall()

timestamp = time.now().format("2006-01-02")

vgkNextGameWeek = "https://api-web.nhle.com/v1/club-schedule/VGK/week/" + timestamp

DEFAULT_TIMEZONE = "US/Pacific"

def main():
    device_tz = time.tz()

    def convertTime(utcTimestamp):
        t = time.parse_time(utcTimestamp)
        pst = t.in_location(device_tz)
        pst.format("2006-01-02T15:04:05Z07:00")

        return pst.format("3:04PM")

    response = http.get(vgkNextGameWeek.format(ttl_seconds = 3600))

    d = response.json()

    if response.status_code != 200:
        fail("Server request failed with status %d", response.status_code)

    if len(d["games"]) == 0:
        nextStartDate = "> 1 week"
        nextStartTime = ""
        nextHomeTeam = ""
        nextAwayTeam = ""
        at = "Go Knights"
    else:
        nextStartDate = d["games"][0]["gameDate"]
        nextStartTime = convertTime(d["games"][0]["startTimeUTC"])

        nextStartDate = nextStartDate.split("-")
        year = nextStartDate.pop(0)[2:4]
        nextStartDate.append(year)
        nextStartDate = "-".join(nextStartDate)

        nextHomeTeam = d["games"][0]["homeTeam"]["abbrev"]
        nextAwayTeam = d["games"][0]["awayTeam"]["abbrev"]
        at = " @ "

    return render.Root(
        delay = 500,
        child = render.Box(
            child = render.Row(
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Image(IMG),
                    render.Column(
                        children = [
                            render.Box(
                                child = render.Column(
                                    children = [
                                        render.Text(content = "NEXT GAME:", font = "tom-thumb", color = "C8102E"),
                                        render.Text(content = "" + nextAwayTeam + at + nextHomeTeam, font = "tom-thumb", color = "B4975A"),
                                        render.Text(content = "" + nextStartDate, font = "tom-thumb"),
                                        render.Animation(
                                            children = [
                                                render.Text(content = "" + nextStartTime, font = "tom-thumb"),
                                                render.Text(content = "" + nextStartTime.replace(":", " "), font = "tom-thumb"),
                                            ],
                                        ),
                                    ],
                                ),
                            ),
                        ],
                    ),
                ],
            ),
        ),
    )
