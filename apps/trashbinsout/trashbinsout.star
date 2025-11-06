load("encoding/base64.star", "base64")
load("render.star", "canvas", "render")

ICON_TRASH_OPEN = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAAXNSR0IArs4c6QAAAhBJREFUOE9lVMuxpDAMlM5AFDOEBhMTEBomCuDsXXW3DFXvAlX+yP2T3M2rWbXqZvh4NTePFYsli2+t+OOLxdiNFZ7gdnyw7xXFcs3N+unDg252LQcPVzf3anE4i+IRViYE7MWpxPN+qZp185iv2rnswJMoX0fFDnV1BgiDmhZwM0lV6+dvK3SuB6tKkmQnDViQFHiEKKp5TR2pa1xIxHHoXorV1Pv1OCizgPACnHRqvFQcyNy637cxuNddYJKyNAQ2aB8Ux7AKlqXowN8EfKXCzC4UZTbARzUbxH7+0OG12DCNpCaxzm23Yf4C1bmW5n7GR8HTBYCsNkx54bAonsrG8+dSVNDxIGOq7EY1sGr6Meb97wOq93pYh4J0LmQ4twJJQp6mn3wjbUdkqRXzQA0R6mLd/GVoEV5HHoeZMtyirAZjl/0JdlAOjaChEMIsIgyadDkoP2aoVwAEcSaCaJ8HYaDpfyO7WA6HEdma11YefbOL4HIjy6j0MuXeinWTKMdVr3A2YxUFKVW2XIZHQU536KwUVVtqmLSpAtO2ohajK+8+18iQKROHQoqdw0sDSojo+FOl7bJR0c/oX868blL+1OeUMfm5XcveJglTwMi1YDcdpGgOT3akTNEEfY8RtqtOR8BRV/xzBD0iP9M6hyiH30sOXs9l5RDzhlQxadr4lgw53mkBnFXe2Bk5vv5f/AdzJFkmDHdD4AAAAABJRU5ErkJggg==
""")

LOCALIZED_STRINGS = {
    "en": "Bins are out!",
    "de": "Mülltonne draussen!",
}

def main(config):
    lang = config.get("lang", "en")
    font = "terminus-18" if canvas.is2x() else "tb-8"
    image_size = 40 if canvas.is2x() else 20

    return render.Root(
        child = render.Box(
            child = render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Image(src = ICON_TRASH_OPEN, width = image_size),
                    render.WrappedText(LOCALIZED_STRINGS[lang], font = font),
                ],
            ),
        ),
    )
