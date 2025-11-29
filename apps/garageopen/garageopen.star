load("i18n.star", "tr")
load("images/open.png", ICON_OPEN = "file")
load("render.star", "canvas", "render")

def main():
    font = "terminus-18" if canvas.is2x() else "tb-8"
    image_size = 40 if canvas.is2x() else 20

    return render.Root(
        child = render.Box(
            render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Image(src = ICON_OPEN.readall(), width = image_size),
                    render.Text(tr("Open"), font = font),
                ],
            ),
        ),
    )
