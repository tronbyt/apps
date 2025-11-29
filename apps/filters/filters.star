load("i18n.star", "tr")
load("images/icon_filter1.png", ICON_FILTER1_ASSET = "file")
load("images/icon_filter2.png", ICON_FILTER2_ASSET = "file")
load("images/icon_filter3.png", ICON_FILTER3_ASSET = "file")
load("render.star", "canvas", "render")

ICON_FILTER1 = ICON_FILTER1_ASSET.readall()
ICON_FILTER2 = ICON_FILTER2_ASSET.readall()
ICON_FILTER3 = ICON_FILTER3_ASSET.readall()

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
                            render.Image(src = ICON_FILTER1, width = image_size),
                            render.Image(src = ICON_FILTER2, width = image_size),
                            render.Image(src = ICON_FILTER3, width = image_size),
                        ],
                    ),
                    render.WrappedText(tr("Change the filters!"), font = font),
                ],
            ),
        ),
    )
