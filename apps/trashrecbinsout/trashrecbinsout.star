load("i18n.star", "tr")
load("images/recycle_open.png", ICON_RECYCLE_OPEN = "file")
load("images/trash_open.png", ICON_TRASH_OPEN = "file")
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
                            render.Image(src = ICON_TRASH_OPEN.readall(), width = image_size),
                            render.Image(src = ICON_RECYCLE_OPEN.readall(), width = image_size),
                        ],
                    ),
                    render.WrappedText(tr("Bins are out!"), font = font),
                ],
            ),
        ),
    )
