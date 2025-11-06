load("encoding/base64.star", "base64")
load("render.star", "canvas", "render")

ICON_TRASH_OPEN = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAAXNSR0IArs4c6QAAAhBJREFUOE9lVMuxpDAMlM5AFDOEBhMTEBomCuDsXXW3DFXvAlX+yP2T3M2rWbXqZvh4NTePFYsli2+t+OOLxdiNFZ7gdnyw7xXFcs3N+unDg252LQcPVzf3anE4i+IRViYE7MWpxPN+qZp185iv2rnswJMoX0fFDnV1BgiDmhZwM0lV6+dvK3SuB6tKkmQnDViQFHiEKKp5TR2pa1xIxHHoXorV1Pv1OCizgPACnHRqvFQcyNy637cxuNddYJKyNAQ2aB8Ux7AKlqXowN8EfKXCzC4UZTbARzUbxH7+0OG12DCNpCaxzm23Yf4C1bmW5n7GR8HTBYCsNkx54bAonsrG8+dSVNDxIGOq7EY1sGr6Meb97wOq93pYh4J0LmQ4twJJQp6mn3wjbUdkqRXzQA0R6mLd/GVoEV5HHoeZMtyirAZjl/0JdlAOjaChEMIsIgyadDkoP2aoVwAEcSaCaJ8HYaDpfyO7WA6HEdma11YefbOL4HIjy6j0MuXeinWTKMdVr3A2YxUFKVW2XIZHQU536KwUVVtqmLSpAtO2ohajK+8+18iQKROHQoqdw0sDSojo+FOl7bJR0c/oX868blL+1OeUMfm5XcveJglTwMi1YDcdpGgOT3akTNEEfY8RtqtOR8BRV/xzBD0iP9M6hyiH30sOXs9l5RDzhlQxadr4lgw53mkBnFXe2Bk5vv5f/AdzJFkmDHdD4AAAAABJRU5ErkJggg==
""")
ICON_RECYCLE_OPEN = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAAXNSR0IArs4c6QAAAh1JREFUOE9tVFtSw0AMk8sRm5Sj0Md3X1dJyhGpGUnezTIDw6TJPmxZkh0AMoJP/gf4qo/+5JsP6Bzfva2fulp7QEREpg4kvxAJ7O/vupF4XXbDbe+nojhB+qPuClIkN507kMFFZ5+uDRWwnnm746nzDaIDElkAkVEZcqglnF4r851P5g18X3ixqCFcUVAUMVqniuV2XlxXUeX1SEw3o+ffejIVplUCVI2sUpSweuHQvhNvYhCEUjLw9e0SAbwYWMuuRhx2LAwQiT2RjGUUANNgAQfWsZZwjNQkch2Oh+n+o4+SH8vJB8Vl8xjRnT8G1V36JooUVhhxpWARWL8ShyeDA+sxMT8D6xE4PBKv887eHbRhFWLHaOwicQRg4cVnM3OqAxiUmecH8LoQ+V8aivWquGQlwpKnq0gky1dJjMSBAc+7zbtUonnY0lsac/j25fL8Z5Xs1muWSnxfPpqZS4BqPR0rdLw03X6wHG3Y+dGs49JIw/y0TcSh/Otm40l3W4ltLyb218R6AuZHlgDmcaEoTCC9EitV9lTZBoh92BAa5kR7uC+l/KryA/PdLmhTRgG34SO6+sAYUbLk1hVqwWotGbt6mm80dK307nOC1t8tXSRmenETdbtY3Uz+FPzvQBgnp3u4vP5/PxfpytNas7FXs1TGLksPg2GYNK0LamiIcHVHx18gbLkhoBWwOYvpNp5rZmmAVsAeb5i5hPELehlcK15Cc30AAAAASUVORK5CYII=
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
        delay = 1000,
        child = render.Box(
            child = render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Animation(
                        children = [
                            render.Image(src = ICON_TRASH_OPEN, width = image_size),
                            render.Image(src = ICON_RECYCLE_OPEN, width = image_size),
                        ],
                    ),
                    render.WrappedText(LOCALIZED_STRINGS[lang], font = font),
                ],
            ),
        ),
    )
