load("i18n.star", "tr")
load("images/icon.png", ICON = "file")
load("render.star", "canvas", "render")

def main():
    width, is2x = canvas.width(), canvas.is2x()
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
                    render.Image(src = ICON.readall(), width = image_size),
                    render.Marquee(
                        width = marquee_width,
                        offset_start = marquee_width,
                        offset_end = marquee_width,
                        child = render.Text(tr("Dishwashing cycle has completed!"), font = font),
                    ),
                ],
            ),
        ),
    )
