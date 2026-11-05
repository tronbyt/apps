load("i18n.star", "tr")
load("images/recycle_closed.png", ICON_RECYCLE_CLOSED = "file")
load("images/recycle_closed@2x.png", ICON_RECYCLE_CLOSED_2X = "file")
load("images/recycle_open.png", ICON_RECYCLE_OPEN = "file")
load("images/recycle_open@2x.png", ICON_RECYCLE_OPEN_2X = "file")
load("images/trash_closed.png", ICON_TRASH_CLOSED = "file")
load("images/trash_closed@2x.png", ICON_TRASH_CLOSED_2X = "file")
load("images/trash_open.png", ICON_TRASH_OPEN = "file")
load("images/trash_open@2x.png", ICON_TRASH_OPEN_2X = "file")
load("render.star", "canvas", "render")

def main():
    font = "terminus-18" if canvas.is2x() else "tb-8"
    image_size = 40 if canvas.is2x() else 20

    return render.Root(
        delay = 1000,
        child = render.Box(
            child = render.Animation(
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Image(src = (ICON_TRASH_CLOSED_2X if canvas.is2x() else ICON_TRASH_CLOSED).readall(), width = image_size),
                            render.WrappedText(tr("Trash\nDay!"), font = font),
                        ],
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Image(src = (ICON_TRASH_OPEN_2X if canvas.is2x() else ICON_TRASH_OPEN).readall(), width = image_size),
                            render.WrappedText(tr("Trash\nDay!"), font = font),
                        ],
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Image(src = (ICON_RECYCLE_CLOSED_2X if canvas.is2x() else ICON_RECYCLE_CLOSED).readall(), width = image_size),
                            render.WrappedText(tr("Recycling Day!"), font = font),
                        ],
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Image(src = (ICON_RECYCLE_OPEN_2X if canvas.is2x() else ICON_RECYCLE_OPEN).readall(), width = image_size),
                            render.WrappedText(tr("Recycling Day!"), font = font),
                        ],
                    ),
                ],
            ),
        ),
    )
