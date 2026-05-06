load("i18n.star", "tr")
load("images/coffee1.png", ICON_COFFEE_1 = "file")
load("images/coffee1@2x.png", ICON_COFFEE_1_2X = "file")
load("images/coffee2.png", ICON_COFFEE_2 = "file")
load("images/coffee2@2x.png", ICON_COFFEE_2_2X = "file")
load("images/coffee3.png", ICON_COFFEE_3 = "file")
load("images/coffee3@2x.png", ICON_COFFEE_3_2X = "file")
load("images/coffee4.png", ICON_COFFEE_4 = "file")
load("images/coffee4@2x.png", ICON_COFFEE_4_2X = "file")
load("render.star", "canvas", "render")

def main():
    font = "terminus-18" if canvas.is2x() else "tb-8"
    image_size = 40 if canvas.is2x() else 20

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
                            render.Image(src = ICON_COFFEE_1_2X.readall() if canvas.is2x() else ICON_COFFEE_1.readall(), width = image_size),
                            render.Image(src = ICON_COFFEE_2_2X.readall() if canvas.is2x() else ICON_COFFEE_2.readall(), width = image_size),
                            render.Image(src = ICON_COFFEE_3_2X.readall() if canvas.is2x() else ICON_COFFEE_3.readall(), width = image_size),
                            render.Image(src = ICON_COFFEE_4_2X.readall() if canvas.is2x() else ICON_COFFEE_4.readall(), width = image_size),
                        ],
                    ),
                    render.WrappedText(tr("Ready!"), font = font),
                ],
            ),
        ),
    )
