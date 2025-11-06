load("encoding/base64.star", "base64")
load("render.star", "canvas", "render")

ICON_OPEN = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAAXNSR0IArs4c6QAAAoRJREFUOE9lVEtWG0EMLPWYba4SWJMF4BMEjpH483wQ7MHkGDgniCEPZ41zlWzxtPKqpBkH4sV4plutLpWqZDBzg0M/N8Acrk/jVu4YNxVi/NOnKZzB/OOim8MM5nrJhHxnpC6xPpHpYJzjTsQwuy7gaYbEdiR8GwBUJkg0ThRKHoiYqyklto/1CQTj3IkowVTvshzH4v6nEKiCqI9HcPv1IikwlIbV5OEoaqgXXVe1ufv1jIeXA65PT/B9f8Dn0xE2e36PsPl9wM3HER72B9xOLnShlShZqXt2vFal3+2eVWpQlKhU7bvGJG/nn86VqFjpqTRnNyvRlUY8uK4RYVED1/iqTmanB1E4Oq9orAlqJBsHOu/QlGZoxKzdphwCLTeioxGymo4DNBy11jjbN4U7tXYoeQszzNc/sPxyGYiSg1ADsPj2hNVkHMiZprK6ktrNLnORHWNp8/VW/KmbKV7SYNKiYXH/pLqXmbRWR2lKiNzSDpRLKQ3md9vgq6dR6N5pvBeKO9rpWHTx7P8JrWB2t0U7u4pS/gD2YZCcwNZc4/usfcRqeolAKAGmU0isO0oxzNttMJ8tuT5rpEHecHN2gs3La/g2jd1OrtBVR0O6wnqgUVC74IHL6rBBwg656CGXEMVm/6r31fRKcZRcYVPCI/FUU+hPd8zvHoVvOb3MeRDNSgyYraOKNvfpMJ7lmRwOgHd18OoguL74Xs1ZUwyeHGeaPkDRMAjz5QAcLH6cWqmzMN3RelFXfqd5Q/xE2KtzmH3JVeLVbBzGYphcAs/RFRMomsi40OGwGAaNWfDPtA4Cs6Sj/yT2fpL09GgeZmjOzxRMDNIQtex0jOrHX7roeBnwFyJ6fy+gno16AAAAAElFTkSuQmCC
""")

LOCALIZED_STRINGS = {
    "en": "Open",
    "de": "Offen",
}

def main(config):
    lang = config.get("lang", "en")
    font = "terminus-18" if canvas.is2x() else "tb-8"
    image_size = 40 if canvas.is2x() else 20

    return render.Root(
        child = render.Box(
            render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Image(src = ICON_OPEN, width = image_size),
                    render.Text(LOCALIZED_STRINGS[lang], font = font),
                ],
            ),
        ),
    )
