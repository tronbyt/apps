load("i18n.star", "tr")
load("images/closed.png", ICON_FRIDGE_CLOSED = "file")
load("images/closed@2x.png", ICON_FRIDGE_CLOSED_2X = "file")
load("images/open.png", ICON_FRIDGE_OPEN = "file")
load("images/open@2x.png", ICON_FRIDGE_OPEN_2X = "file")
load("render.star", "canvas", "render")

def main():
    scale = 2 if canvas.is2x() else 1
    image_size = 20 * scale

    open_img = (ICON_FRIDGE_OPEN_2X if scale == 2 else ICON_FRIDGE_OPEN).readall()
    closed_img = (ICON_FRIDGE_CLOSED_2X if scale == 2 else ICON_FRIDGE_CLOSED).readall()

    # Alternate between open and closed fridge images every second
    open_frame = render.Image(src = open_img, width = image_size)
    closed_frame = render.Image(src = closed_img, width = image_size)
    frames = [open_frame] * (10 * scale) + [closed_frame] * (10 * scale)

    return render.Root(
        delay = 100 // scale,
        child = render.Box(
            child = render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Animation(
                        children = frames,
                    ),
                    render.Marquee(
                        width = canvas.width() - image_size,
                        child = render.Text(tr("Close the fridge!")),
                    ),
                ],
            ),
        ),
    )
