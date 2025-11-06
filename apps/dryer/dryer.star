load("encoding/base64.star", "base64")
load("render.star", "canvas", "render")

ICON_DRYER = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAAXNSR0IArs4c6QAAAiRJREFUOE9NVEGSwzAIE/ZDm76syUNtdiSBs50cmtiAkASBQCIBRCCAftFnPfrOKwFkoi6BP0fw5xR8jYjoSH3YeysweZinmi8zUDmdiEnGCCbxd93phAjsvTBjVCknH2O4AUacHhyWLMg7k6Vchg0lH17eayOYIBdGjEo4sfQ+kckCgcV7jCSyzZh5cBGl2idXey2MOYsXIlyYYzaDvFRciVG1aYQsZhIqoS/ysBQyS9LB5DR/579a9G2iNy6hVr96JSJy1rQzmQl3ZSMsdOWKpZhpuOKwylBVckj4FMBhjboURkgA+8LnAqEY1auW1RpV3pjTrJqCxJgUqTUEiGhKeXkEKd7dVVnKLRPVkopD1XamlFbqakPGyNRZ6IyvC/Gfw9abDayVStjq3s8P1/U9/Nz3g8/3UnF2Q7vs3Jh2dE2PISjvXokYLcIgbNz3jevzPSP3qMilu+RT3qXVyvdWWYQmshDSyDMmfs+N73UdS9w/JyN/4nuE2x89055QTwqf4o1tiKNIPGzzcptM9Dw3Pp/rHUtxOM7OeBNSJSomHwKrkp814FVkqwjV8BLZiaCVWuVaFLq8yyYdyNnt6kW1kVHVMt6xkaEZKd2tyjJ2WYUuhdXsAZW95NN3R2ZNl/ZmT1bPQVbCd1H1QL+D73Ew30zrSfGKs2Xj36Zr09bEeiH07jtr0lNha9Qo9hYqlXXsbVtr/rWBp6F3q1G9k/4q1bP9B/iZniiwNfaqAAAAAElFTkSuQmCC
""")

LOCALIZED_STRINGS = {
    "de": "Trockner ist fertig!",
    "en": "Drying cycle has completed!",
}

def main(config):
    width, is2x = canvas.width(), canvas.is2x()
    lang = config.get("lang", "en")
    font = "terminus-16" if is2x else "tb-8"
    image_size = 40 if is2x else 20
    marquee_width = width - image_size - (width // 8)

    return render.Root(
        delay = 25 if is2x else 50,
        child = render.Box(
            render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Image(src = ICON_DRYER, width = image_size),
                    render.Marquee(
                        width = marquee_width,
                        offset_start = marquee_width,
                        offset_end = marquee_width,
                        child = render.Text(LOCALIZED_STRINGS[lang], font = font),
                    ),
                ],
            ),
        ),
    )
