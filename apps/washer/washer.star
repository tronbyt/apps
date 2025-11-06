load("encoding/base64.star", "base64")
load("render.star", "canvas", "render")

ICON_WASHER = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAAXNSR0IArs4c6QAAAhJJREFUOE9VVQFu4zAMo+x3Lti97NrtnbYGkpLTBAPaqLZEkZQWABII/elbAJnwU2HGMxzkMT56Sx64D0cmAsEIg84YGciqwQsu4Er8xcmZJ1REt/lbpj9d56609q7yTia4n7D13Un5jDGUzO2k6mb/mGshxkTuhZgTe28MJmh0vEQk1Rg/914YMZ1M0IxcTedOxKwgL+6NGAM7E2PwMgsMbJ4DYy4as1B2y0YAXxjDpOfz3Z0eAg/X5Fd3xCEblyiWbec6opHgjkumej8SfshNhHKAVC7b8Lzgi7PSXOSK6OOjYrCU951ZHJbtShQhZMvsrRRLYG2xexw4C42sRJpyY44hodh2+UW6ueUx7akSifx8+nd1Ao+DVNadGgh2aH83h/QVAqvtcM9Fmxa5UuoLVFvLtj+GOtXGNPy9qn0E3q//Svv97xuv1wvXdUlZGrg9212VD00+26G3JPpe+Pn5rUkpFu0LXF8XXDhdeDZN8nB4dCNLZbreRiTx7/fblpDSoWQ2v/Qv73ocna4Ssvhj1GrYifQoyAGQ8WuJEAunJsh7Gdty9OhxjBhx/Q8TlIr3mjNqd+VZPuay900msNd6LIN721UBb0KfR2KS8wOpqXgsTvqIK8wzWqXunScz2+xE1vvSqYylFlKNrpfgYzN3pJ1WIGsR30NdovR69mb2Vmnb978Fub+aJAon6d3rTePYH7N4gi5b+kNtAAAAAElFTkSuQmCC
""")

LOCALIZED_STRINGS = {
    "en": "Wash cycle has completed!",
    "de": "Waschmaschine ist fertig!",
}

def main(config):
    width, is2x = canvas.width(), canvas.is2x()
    lang = config.get("lang", "en")
    font = "terminus-18" if is2x else "tb-8"
    image_size = 40 if is2x else 20
    marquee_width = width - image_size - (width // 8)

    return render.Root(
        delay = 25 if is2x else 50,
        child = render.Box(
            child = render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Image(src = ICON_WASHER, width = image_size),
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
