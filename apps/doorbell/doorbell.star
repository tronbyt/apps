load("i18n.star", "tr")
load("images/press1.png", ICON_PRESS1 = "file")
load("images/press2.png", ICON_PRESS2 = "file")
load("images/press3.png", ICON_PRESS3 = "file")
load("render.star", "canvas", "render")

def main():
    is2x = canvas.is2x()
    font = "terminus-18" if is2x else "tb-8"
    image_size = 40 if is2x else 20

    return render.Root(
        delay = 500,
        child = render.Box(
            child = render.Animation(
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Image(src = ICON_PRESS1.readall(), width = image_size),
                        ],
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Image(src = ICON_PRESS2.readall(), width = image_size),
                        ],
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Image(src = ICON_PRESS3.readall(), width = image_size),
                            render.Column(
                                expanded = True,
                                main_align = "center",
                                children = [
                                    render.Text(tr("Ding"), font = font),
                                    render.Text(tr("Dong"), font = font, color = "#000"),
                                ],
                            ),
                        ],
                    ),
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Image(src = ICON_PRESS3.readall(), width = image_size),
                            render.Column(
                                expanded = True,
                                main_align = "center",
                                children = [
                                    render.Text(tr("Ding"), font = font),
                                    render.Text(tr("Dong"), font = font),
                                ],
                            ),
                        ],
                    ),
                ],
            ),
        ),
    )
