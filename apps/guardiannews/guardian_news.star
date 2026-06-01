"""
Applet: Guardian News
Summary: Latest news
Description: Show the latest Guardian top story from your preferred Edition.
Author: meejle
"""

load("http.star", "http")
load("images/news_icon.gif", NEWS_ICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

NEWS_ICON = NEWS_ICON_ASSET.readall()

def main(config):
    edition = config.get("edition", "uk")
    fontsize = config.get("fontsize", "tb-8")

    #For the sake of linting
    finalheadline = ""
    finalblurb = ""
    finalpillar = ""
    finalsection = ""
    blurbstripopst = ""
    blurbstripedst = ""
    blurbstripopem = ""
    blurbstripedem = ""
    blurbstripstbo = ""
    blurbstripedbo = ""
    blurbstripopit = ""
    blurbstripedit = ""

    if edition == "uk":
        GET_GUARDIAN = http.get("http://content.guardianapis.com/" + edition + "?show-editors-picks=true&api-key=2f517de6-c7e1-4c67-b79f-0c857fb7494a&show-fields=trailText", ttl_seconds = 900)
        if GET_GUARDIAN.status_code != 200:
            return connectionError()
        GET_UKHEADLINE = GET_GUARDIAN.json()["response"]["editorsPicks"][0]["webTitle"]
        GET_UKBLURB = GET_GUARDIAN.json()["response"]["editorsPicks"][0]["fields"]["trailText"]
        GET_UKPILLAR = GET_GUARDIAN.json()["response"]["editorsPicks"][0]["pillarName"]
        GET_UKSECTION = GET_GUARDIAN.json()["response"]["editorsPicks"][0]["sectionName"]
        finalheadline = str(GET_UKHEADLINE)
        finalblurb = str(GET_UKBLURB)
        finalpillar = str(GET_UKPILLAR)
        finalsection = str(GET_UKSECTION)
        blurbstripopst = finalblurb.replace("<strong>", "")
        blurbstripedst = blurbstripopst.replace("</strong>", "")
        blurbstripopem = blurbstripedst.replace("<em>", "")
        blurbstripedem = blurbstripopem.replace("</em>", "")
        blurbstripstbo = blurbstripedem.replace("<b>", "")
        blurbstripedbo = blurbstripstbo.replace("</b>", "")
        blurbstripopit = blurbstripedbo.replace("<i>", "")
        blurbstripedit = blurbstripopit.replace("</i>", "")
    if edition == "us":
        GET_GUARDIAN = http.get("http://content.guardianapis.com/" + edition + "?show-editors-picks=true&api-key=a13d8fc0-0142-4078-ace2-b88d89457a8b&show-fields=trailText", ttl_seconds = 900)
        if GET_GUARDIAN.status_code != 200:
            return connectionError()
        GET_USHEADLINE = GET_GUARDIAN.json()["response"]["editorsPicks"][0]["webTitle"]
        GET_USBLURB = GET_GUARDIAN.json()["response"]["editorsPicks"][0]["fields"]["trailText"]
        GET_USPILLAR = GET_GUARDIAN.json()["response"]["editorsPicks"][0]["pillarName"]
        GET_USSECTION = GET_GUARDIAN.json()["response"]["editorsPicks"][0]["sectionName"]
        finalheadline = str(GET_USHEADLINE)
        finalblurb = str(GET_USBLURB)
        finalpillar = str(GET_USPILLAR)
        finalsection = str(GET_USSECTION)
        blurbstripopst = finalblurb.replace("<strong>", "")
        blurbstripedst = blurbstripopst.replace("</strong>", "")
        blurbstripopem = blurbstripedst.replace("<em>", "")
        blurbstripedem = blurbstripopem.replace("</em>", "")
        blurbstripstbo = blurbstripedem.replace("<b>", "")
        blurbstripedbo = blurbstripstbo.replace("</b>", "")
        blurbstripopit = blurbstripedbo.replace("<i>", "")
        blurbstripedit = blurbstripopit.replace("</i>", "")
    if edition == "au":
        GET_GUARDIAN = http.get("http://content.guardianapis.com/" + edition + "?show-editors-picks=true&api-key=a13d8fc0-0142-4078-ace2-b88d89457a8b&show-fields=trailText", ttl_seconds = 900)
        if GET_GUARDIAN.status_code != 200:
            return connectionError()
        GET_AUHEADLINE = GET_GUARDIAN.json()["response"]["editorsPicks"][0]["webTitle"]
        GET_AUBLURB = GET_GUARDIAN.json()["response"]["editorsPicks"][0]["fields"]["trailText"]
        GET_AUPILLAR = GET_GUARDIAN.json()["response"]["editorsPicks"][0]["pillarName"]
        GET_AUSECTION = GET_GUARDIAN.json()["response"]["editorsPicks"][0]["sectionName"]
        finalheadline = str(GET_AUHEADLINE)
        finalblurb = str(GET_AUBLURB)
        finalpillar = str(GET_AUPILLAR)
        finalsection = str(GET_AUSECTION)
        blurbstripopst = finalblurb.replace("<strong>", "")
        blurbstripedst = blurbstripopst.replace("</strong>", "")
        blurbstripopem = blurbstripedst.replace("<em>", "")
        blurbstripedem = blurbstripopem.replace("</em>", "")
        blurbstripstbo = blurbstripedem.replace("<b>", "")
        blurbstripedbo = blurbstripstbo.replace("</b>", "")
        blurbstripopit = blurbstripedbo.replace("<i>", "")
        blurbstripedit = blurbstripopit.replace("</i>", "")
    if edition == "international":
        GET_GUARDIAN = http.get("http://content.guardianapis.com/" + edition + "?show-editors-picks=true&api-key=a13d8fc0-0142-4078-ace2-b88d89457a8b&show-fields=trailText", ttl_seconds = 900)
        if GET_GUARDIAN.status_code != 200:
            return connectionError()
        GET_INTLHEADLINE = GET_GUARDIAN.json()["response"]["editorsPicks"][0]["webTitle"]
        GET_INTLBLURB = GET_GUARDIAN.json()["response"]["editorsPicks"][0]["fields"]["trailText"]
        GET_INTLPILLAR = GET_GUARDIAN.json()["response"]["editorsPicks"][0]["pillarName"]
        GET_INTLSECTION = GET_GUARDIAN.json()["response"]["editorsPicks"][0]["sectionName"]
        finalheadline = str(GET_INTLHEADLINE)
        finalblurb = str(GET_INTLBLURB)
        finalpillar = str(GET_INTLPILLAR)
        finalsection = str(GET_INTLSECTION)
        blurbstripopst = finalblurb.replace("<strong>", "")
        blurbstripedst = blurbstripopst.replace("</strong>", "")
        blurbstripopem = blurbstripedst.replace("<em>", "")
        blurbstripedem = blurbstripopem.replace("</em>", "")
        blurbstripstbo = blurbstripedem.replace("<b>", "")
        blurbstripedbo = blurbstripstbo.replace("</b>", "")
        blurbstripopit = blurbstripedbo.replace("<i>", "")
        blurbstripedit = blurbstripopit.replace("</i>", "")

    #fallback
    pillarcol = "#ff5944"

    if finalpillar == "Opinion":
        pillarcol = "#ff7f0f"
    if finalpillar == "Sport":
        pillarcol = "#00b2ff"
    if finalpillar == "Arts":
        pillarcol = "#eacca0"
    if finalpillar == "Lifestyle":
        pillarcol = "#ffabdb"

    return render.Root(
        delay = 50,
        child = render.Marquee(
            scroll_direction = "vertical",
            height = 32,
            offset_start = 27,
            offset_end = 32,
            child = render.Column(
                main_align = "start",
                children = [
                    render.Image(width = 64, height = 32, src = NEWS_ICON),
                    render.WrappedText(content = finalsection, width = 64, color = "#fff", font = "CG-pixel-3x5-mono", linespacing = 1, align = "left"),
                    render.Box(width = 64, height = 1, color = pillarcol),
                    render.Box(width = 64, height = 2),
                    render.WrappedText(content = finalheadline, width = 64, color = pillarcol, font = fontsize, linespacing = 1, align = "left"),
                    render.Box(width = 64, height = 2),
                    render.WrappedText(content = blurbstripedit, width = 64, color = "#fff", font = fontsize, linespacing = 1, align = "left"),
                ],
            ),
        ),
    )

def connectionError(config):
    fontsize = config.get("fontsize", "tb-8")
    return render.Root(
        delay = 50,
        child = render.Marquee(
            scroll_direction = "vertical",
            height = 32,
            offset_start = 27,
            offset_end = 32,
            child = render.Column(
                main_align = "start",
                children = [
                    render.Image(width = 64, height = 32, src = NEWS_ICON),
                    render.WrappedText(content = "Error", width = 64, color = "#fff", font = "CG-pixel-3x5-mono", linespacing = 0, align = "left"),
                    render.Box(width = 64, height = 1),
                    render.Box(width = 64, height = 1, color = "#ff5944"),
                    render.Box(width = 64, height = 2),
                    render.WrappedText(content = "Couldn’t get the top story", width = 64, color = "#ff5944", font = fontsize, linespacing = 1, align = "left"),
                    render.Box(width = 64, height = 2),
                    render.WrappedText(content = "For the latest headlines, visit theguardian .com", width = 64, color = "#fff", font = fontsize, linespacing = 1, align = "left"),
                ],
            ),
        ),
    )

def get_schema():
    options = [
        schema.Option(
            display = "UK",
            value = "uk",
        ),
        schema.Option(
            display = "US",
            value = "us",
        ),
        schema.Option(
            display = "Australia",
            value = "au",
        ),
        schema.Option(
            display = "International",
            value = "international",
        ),
    ]

    fsoptions = [
        schema.Option(
            display = "Larger",
            value = "tb-8",
        ),
        schema.Option(
            display = "Smaller",
            value = "tom-thumb",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "edition",
                name = "Choose your Edition",
                desc = "Get news that’s relevant to you.",
                icon = "newspaper",
                default = options[0].value,
                options = options,
            ),
            schema.Dropdown(
                id = "fontsize",
                name = "Change the text size",
                desc = "To prevent long words falling off the edge.",
                icon = "textHeight",
                default = fsoptions[0].value,
                options = fsoptions,
            ),
        ],
    )
