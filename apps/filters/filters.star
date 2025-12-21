load("i18n.star", "tr")
load("images/icon_filter1.png", ICON_FILTER1_ASSET = "file")
load("images/icon_filter1@2x.png", ICON_FILTER1_2X_ASSET = "file")
load("images/icon_filter2.png", ICON_FILTER2_ASSET = "file")
load("images/icon_filter2@2x.png", ICON_FILTER2_2X_ASSET = "file")
load("images/icon_filter3.png", ICON_FILTER3_ASSET = "file")
load("images/icon_filter3@2x.png", ICON_FILTER3_2X_ASSET = "file")
load("render.star", "canvas", "render")

def main():
    if canvas.is2x() == 2:
        image_size = 40
        font = "terminus-18"
        icon_filter1 = ICON_FILTER1_2X_ASSET.readall()
        icon_filter2 = ICON_FILTER2_2X_ASSET.readall()
        icon_filter3 = ICON_FILTER3_2X_ASSET.readall()
    else:
        image_size = 20
        font = "tb-8"
        icon_filter1 = ICON_FILTER1_ASSET.readall()
        icon_filter2 = ICON_FILTER2_ASSET.readall()
        icon_filter3 = ICON_FILTER3_ASSET.readall()

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
                            render.Image(src = icon_filter1, width = image_size),
                            render.Image(src = icon_filter2, width = image_size),
                            render.Image(src = icon_filter3, width = image_size),
                        ],
                    ),
                    render.WrappedText(tr("Change the filters!"), font = font),
                ],
            ),
        ),
    )
