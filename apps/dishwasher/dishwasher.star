load("encoding/base64.star", "base64")
load("render.star", "canvas", "render")

ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAAXNSR0IArs4c6QAAAjNJREFUOE9dVEtyKkEMk7uPBCzDNuTEkGVgSXKkab+SZA/U6wXU9MeWJdkREZl4XwkkENF7gUQivI1AICP1XxvI9Lf2tc2fdIS1Ft5eay/qjPcUpBYDzDGUxskU+JWbwcYYaMwZ4dj84VWhbDQMnljJN1NnwhYhxIK6tkSMgZUbZkyhHXNgrQ0juL90noth03cYkI+FnviMlsmwVgohD4myC/CFVzGu2kFybUoiToWwnwrhAst8XwrMW521HoqEKo9VdMISxzBZ2pxz573ZLSIblMptJ2xd1e4BieJlruYupi0AnC9P7f3cTrue4giAA+4Fmy3G5HmS9JiFRDhwvvzhfjvIOuevJ+63oywmd7JkcUiVm9ngVXkDW24Whaoj8HF54vF9EhKZN4CPyy8e1yOv6w6riighbS7Csym3tYpDJzCi08uXQvzrPQuPXKyqS5b91EcuWca2yuevP/zcjkU+KRE7TsSg3wf3RtmmlbTy5avcKmDw0VMi8FQp6qLLfuLBs2pVGXuXSwS6rTa1EXszjeJ6dA3VwiKeAT9Zts/kDIpSTrGxy3DiY9r1JP9+PRQ6U6LQkTh/Uvmj0oj3QWeYlpo2xtDDoXwrHhm0Gk2IWmUHaN6nB4h7uRykXqbKo9C8fNgzi4RbKJdOGGxX0mQblW3alD1NbLyeIP+L0pPW1rDV7N0eGfs84B553CexR5y7wkJ7Ark6LbWdvnva7AO2UFVL9XSpcWpbtJSet/t6n0j/AENviC1XLMEuAAAAAElFTkSuQmCC
""")

LOCALIZED_STRINGS = {
    "de": "Spülmaschine ist fertig!",
    "en": "Dishwashing cycle has completed!",
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
                    render.Image(src = ICON, width = image_size),
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
