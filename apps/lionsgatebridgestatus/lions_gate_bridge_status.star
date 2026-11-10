"""
Applet: Lions Gate Bridge Status
Summary: Lions gate bridge traffic status
Description: Displays the current traffic pattern map and latest delay message for Vancouver's Lions gate bridge.
Author: Alysha Kwok
"""

load("http.star", "http")
load("render.star", "render", "canvas")
load("schema.star", "schema")

IMAGE_URL = "https://www.th.gov.bc.ca/ATIS/lgcws/images/Lions_gate/queue_map.gif"
INFO_URL = "https://www.th.gov.bc.ca/ATIS/lgcws/private_status.htm#dms1"

def clean_string(text):
    return text.replace("&nbsp", " ").strip()

def main(config):
    image_src = http.get(IMAGE_URL).body()
    info_src = http.get(INFO_URL).body()

    currentMessage = info_src.find("Current Requested Message")
    timeStart = info_src.find("at:", currentMessage) + len("at:")
    timeStart = info_src.find(",", timeStart) + len(",")
    timeEnd = info_src.find("<BR>", timeStart)
    time = info_src[timeStart:timeEnd]
    secStart = time.find(":") + len(":")
    secStart = time.find(":", secStart)
    if (secStart > 0):
        time = time[0:secStart]
    time = clean_string(time)

    message1Start = info_src.find("Message Phase 1")
    message1Start = info_src.find("<TD", message1Start)
    message1Start = info_src.find(">", message1Start) + len(">")
    message1End = info_src.find("</TD>", message1Start)
    message1 = info_src[message1Start:message1End]

    message2Start = info_src.find("<TD", message1End)
    message2Start = info_src.find(">", message2Start) + len(">")
    message2End = info_src.find("</TD>", message2Start)
    message2 = info_src[message2Start:message2End]

    delayMessage = clean_string(message1) + "\n" + clean_string(message2)

    return render.Root(
        delay = 3750, 
        child = render.Animation(
            children = [
                render.Padding(
                    child = render.Image(src = image_src, width = 150, height = 269),
                    pad = (-50, -145, 0, 0), # left, top, right, bottom 
                ),
                render.Stack(
                    children = [
                        render.WrappedText(content = delayMessage),
                        render.Box(
                            width = canvas.width(),
                            height = canvas.height(),
                            child = render.Column(
                                expanded = True,
                                main_align = "end",  
                                cross_align = "end",
                                children = [
                                    render.Row(
                                        expanded = True,
                                        main_align = "end",  
                                        cross_align = "end",
                                        children = [
                                            render.Text(content = time, font = "tom-thumb"),
                                        ]
                                    )
                                ],
                            ),
                        ),
                    ],
                )
            ]
        )
    )