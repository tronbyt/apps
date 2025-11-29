load("i18n.star", "tr")
load("images/closed.png", ICON_FRIDGE_CLOSED = "file")
load("images/open.png", ICON_FRIDGE_OPEN = "file")
load("render.star", "canvas", "render")

def main():
    font = "terminus-18" if canvas.is2x() else "tb-8"
    image_size = 40 if canvas.is2x() else 20

    return render.Root(
        delay = 1000,
        child = render.Box(
            child = render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Animation(
                        children = [
                            render.Image(src = ICON_FRIDGE_OPEN.readall(), width = image_size),
                            render.Image(src = ICON_FRIDGE_CLOSED.readall(), width = image_size),
                        ],
                    ),
                    render.WrappedText(tr("Close the fridge!"), font = font),
                ],
            ),
        ),
    )
