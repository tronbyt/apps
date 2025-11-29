"""
Applet: Oura Ring
Summary: View your Oura Ring scores
Description: Displays the three scores from your Oura Ring along with a historical chart over the past seven days.
Author: Aiden Vigue
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("images/activity_icon.png", ACTIVITY_ICON_ASSET = "file")
load("images/readiness_icon.png", READINESS_ICON_ASSET = "file")
load("images/sleep_icon.png", SLEEP_ICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

ACTIVITY_ICON = ACTIVITY_ICON_ASSET.readall()
READINESS_ICON = READINESS_ICON_ASSET.readall()
SLEEP_ICON = SLEEP_ICON_ASSET.readall()

def readinessIcon(score, dim):
    return render.Padding(pad = (0, 0, 0, 0), child = render.Row(children = [render.Padding(pad = (0, 1, 0, 0), child = render.Image(src = READINESS_ICON)), render.Padding(pad = (2, 2, 0, 0), child = render.Text(str(score), font = "tom-thumb", color = "#FFF" if not dim else "#444"))]))

def activityIcon(score, dim):
    return render.Padding(pad = (0, 0, 0, 0), child = render.Row(children = [render.Image(src = ACTIVITY_ICON), render.Padding(pad = (2, 2, 0, 0), child = render.Text(str(score), font = "tom-thumb", color = "#FFF" if not dim else "#444"))]))

def sleepIcon(score, dim):
    return render.Padding(pad = (0, 0, 0, 0), child = render.Row(children = [render.Padding(pad = (0, 1, 0, 0), child = render.Image(src = SLEEP_ICON)), render.Padding(pad = (2, 2, 0, 0), child = render.Text(str(score), font = "tom-thumb", color = "#FFF" if not dim else "#444"))]))

def activityView(readiness_scores, activity_scores, sleep_scores):
    avg = cal_average(activity_scores)
    points = []
    for index, score in enumerate(activity_scores):
        points.append((index, score - avg))

    return render.Column(
        children = [render.Row(children = [readinessIcon(readiness_scores[-1], True), activityIcon(activity_scores[-1], False), sleepIcon(sleep_scores[-1], True)], main_align = "space_evenly", expanded = True), render.Plot(
            data = points,
            width = 64,
            height = 19,
            color = "#0f0",
            color_inverted = "#F33",
            fill = True,
        )],
        main_align = "space_between",
        expanded = True,
    )

def readinessView(readiness_scores, activity_scores, sleep_scores):
    avg = cal_average(readiness_scores)
    points = []
    for index, score in enumerate(readiness_scores):
        points.append((index, score - avg))

    return render.Column(
        children = [render.Row(children = [readinessIcon(readiness_scores[-1], False), activityIcon(activity_scores[-1], True), sleepIcon(sleep_scores[-1], True)], main_align = "space_evenly", expanded = True), render.Plot(
            data = points,
            width = 64,
            height = 19,
            color = "#0f0",
            color_inverted = "#F33",
            fill = True,
        )],
        main_align = "space_between",
        expanded = True,
    )

def sleepView(readiness_scores, activity_scores, sleep_scores):
    avg = cal_average(sleep_scores)
    points = []
    for index, score in enumerate(sleep_scores):
        points.append((index, score - avg))

    return render.Column(
        children = [render.Row(children = [readinessIcon(readiness_scores[-1], True), activityIcon(activity_scores[-1], True), sleepIcon(sleep_scores[-1], False)], main_align = "space_evenly", expanded = True), render.Plot(
            data = points,
            width = 64,
            height = 19,
            color = "#0f0",
            color_inverted = "#F33",
            fill = True,
        )],
        main_align = "space_between",
        expanded = True,
    )

def errorView(message):
    return render.Root(child = render.WrappedText(
        content = message,
        width = 64,
        color = "#fff",
    ))

def main(config):
    apikey = config.get("apikey", "notset")

    sleep_scores = [78, 86, 67, 92, 65, 82, 85]
    activity_scores = [76, 95, 71, 80, 66, 91, 83]
    readiness_scores = [62, 73, 68, 70, 88, 79, 61]

    if apikey != "notset":
        days = config.get("days", "7")

        now = time.now()
        from_date = (now - time.parse_duration(str(int(days) * 24) + "h")).format("2006-01-02")
        to_date = now.format("2006-01-02")

        sleep_data = None
        sleep_dto = cache.get("oura_sleep_data_" + apikey)
        if sleep_dto != None:
            sleep_data = json.decode(sleep_dto)
        else:
            rep = http.get("https://api.ouraring.com/v2/usercollection/daily_sleep?start_date=" + from_date + "&" + "end_date=" + to_date, headers = {"Authorization": "Bearer " + apikey})
            if rep.status_code != 200:
                return errorView("API error")
            sleep_data = rep.json()

            # TODO: Determine if this cache call can be converted to the new HTTP cache.
            cache.set("oura_sleep_data_" + apikey, json.encode(sleep_data), ttl_seconds = 1800)

        activity_data = None
        activity_dto = cache.get("oura_activity_data_" + apikey)
        if activity_dto != None:
            activity_data = json.decode(activity_dto)
        else:
            rep = http.get("https://api.ouraring.com/v2/usercollection/daily_activity?start_date=" + from_date + "&" + "end_date=" + to_date, headers = {"Authorization": "Bearer " + apikey})
            if rep.status_code != 200:
                return errorView("API error")
            activity_data = rep.json()

            # TODO: Determine if this cache call can be converted to the new HTTP cache.
            cache.set("oura_activity_data_" + apikey, json.encode(activity_data), ttl_seconds = 1800)

        readiness_data = None
        readiness_dto = cache.get("oura_readiness_data_" + apikey)
        if readiness_dto != None:
            readiness_data = json.decode(readiness_dto)
        else:
            rep = http.get("https://api.ouraring.com/v2/usercollection/daily_readiness?start_date=" + from_date + "&" + "end_date=" + to_date, headers = {"Authorization": "Bearer " + apikey})
            if rep.status_code != 200:
                return errorView("API error")
            readiness_data = rep.json()

            # TODO: Determine if this cache call can be converted to the new HTTP cache.
            cache.set("oura_readiness_data_" + apikey, json.encode(readiness_data), ttl_seconds = 1800)

        #Populate array of last 7 scores.
        for day in sleep_data["data"]:
            sleep_scores.append(int(day["score"]))

        for day in activity_data["data"]:
            activity_scores.append(int(day["score"]))

        for day in readiness_data["data"]:
            readiness_scores.append(int(day["score"]))

    return render.Root(
        delay = 2000,
        child = render.Animation(
            children = [
                readinessView(readiness_scores, activity_scores, sleep_scores),
                activityView(readiness_scores, activity_scores, sleep_scores),
                sleepView(readiness_scores, activity_scores, sleep_scores),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "apikey",
                name = "Oura PAT",
                desc = "Oura API Key. Get yours at cloud.ouraring.com",
                icon = "user",
                default = "",
                secret = True,
            ),
            schema.Text(
                id = "days",
                name = "Graph Lookback",
                desc = "Number of previous days to graph",
                icon = "calendar",
                default = "7",
            ),
        ],
    )

def cal_average(num):
    sum_num = 0
    for t in num:
        sum_num = sum_num + t

    avg = sum_num / len(num)
    return avg
