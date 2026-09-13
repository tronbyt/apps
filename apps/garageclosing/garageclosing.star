load("i18n.star", "tr")
load("images/closed.png", ICON_CLOSED = "file")
load("images/closed@2x.png", ICON_CLOSED_2X = "file")
load("images/closing1.png", ICON_CLOSING_1 = "file")
load("images/closing1@2x.png", ICON_CLOSING_1_2X = "file")
load("images/closing2.png", ICON_CLOSING_2 = "file")
load("images/closing2@2x.png", ICON_CLOSING_2_2X = "file")
load("images/closing3.png", ICON_CLOSING_3 = "file")
load("images/closing3@2x.png", ICON_CLOSING_3_2X = "file")
load("images/closing4.png", ICON_CLOSING_4 = "file")
load("images/closing4@2x.png", ICON_CLOSING_4_2X = "file")
load("images/open.png", ICON_OPEN = "file")
load("images/open@2x.png", ICON_OPEN_2X = "file")
load("render.star", "canvas", "render")

def main():
    font = "terminus-18" if canvas.is2x() else "tb-8"
    image_size = 40 if canvas.is2x() else 20
    closed_image = (ICON_CLOSED_2X if canvas.is2x() else ICON_CLOSED).readall()

    return render.Root(
        delay = 500,
        child = render.Box(
            child = render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Animation(
                        children = [
                            render.Image(src = (ICON_OPEN_2X if canvas.is2x() else ICON_OPEN).readall(), width = image_size),
                            render.Image(src = (ICON_CLOSING_1_2X if canvas.is2x() else ICON_CLOSING_1).readall(), width = image_size),
                            render.Image(src = (ICON_CLOSING_2_2X if canvas.is2x() else ICON_CLOSING_2).readall(), width = image_size),
                            render.Image(src = (ICON_CLOSING_3_2X if canvas.is2x() else ICON_CLOSING_3).readall(), width = image_size),
                            render.Image(src = (ICON_CLOSING_4_2X if canvas.is2x() else ICON_CLOSING_4).readall(), width = image_size),
                            render.Image(src = closed_image, width = image_size),
                            render.Image(src = closed_image, width = image_size),
                        ],
                    ),
                    render.Text(tr("Closing"), font = font),
                ],
            ),
        ),
    )
