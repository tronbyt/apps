"""
Applet: EFF Headlines
Author: hainish
Summary: EFF Headlines tidbyt
Description: Get the latest headlines from the Electronic Frontier Foundation.
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("qrcode.star", "qrcode")
load("random.star", "random")
load("re.star", "re")
load("render.star", "render")

EFF_XML_URL = "https://www.eff.org/rss/updates.xml"

def main():
    clean_titles = []
    clean_guids = []

    rep = http.get(EFF_XML_URL, ttl_seconds = 3600)
    if rep.status_code != 200:
        fail("EFF XML request failed with status %d", rep.status_code)
    body = rep.body()

    dirty_titles = re.findall("<title>.+</title>", body)
    for title in dirty_titles[1:11]:
        clean_titles.append(title.replace("<title>", "").replace("</title>", ""))

    dirty_guids = re.findall("<guid isPermaLink=\"false\">.+ at https://www\\.eff\\.org</guid>", body)
    for guid in dirty_guids[:10]:
        clean_guids.append(guid.replace("<guid isPermaLink=\"false\">", "").replace(" at https://www.eff.org</guid>", ""))

    index = random.number(0, 9)

    url = "https://eff.org/node/" + clean_guids[index]
    headline = clean_titles[index]

    data = cache.get(url)
    if data == None:
        code = qrcode.generate(
            url = url,
            size = "large",
            color = "#fff",
            background = "#000",
        )

        cache.set(url, base64.encode(code), ttl_seconds = 3600)
    else:
        code = base64.decode(data)

    return render.Root(
        child = render.Stack(children = [
            render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Padding(
                        child = render.Image(src = code),
                        pad = 1,
                    ),
                    render.Marquee(
                        child = render.WrappedText(
                            content = headline,
                            color = "#aaf",
                            font = "tom-thumb",
                            width = 32,
                        ),
                        height = 32,
                        scroll_direction = "vertical",
                        offset_start = 32,
                        offset_end = 32,
                    ),
                ],
            ),
            render.Row(main_align = "end", expanded = True, children = [
                render.Box(width = 13, height = 6, color = "#000"),
            ]),
            render.Row(main_align = "end", expanded = True, children = [
                render.Text(content = "EFF", color = "#a00", font = "tom-thumb"),
            ]),
        ]),
    )
