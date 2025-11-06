load("encoding/base64.star", "base64")
load("render.star", "canvas", "render")

ICON_CLOSED = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAAXNSR0IArs4c6QAAAktJREFUOE9lVNF1IjEMlHZJPSQVwJVwXBnAR6CObD5IyuBSAlwFIfWEte/NjOSFF+CZXVuWRiON3Myqu1u1/OST48g8XqvfvuMZp9W0rbNqjq9XXMKC17BkABrrZi7cxFVL23yCj7gDT/JeFQW/UsaIDB/V6l0Es57RhGzyDXz0xZWRaykN1P793x2azGRYL5kNsuq6XrRoiX26cBsD1e79TLRMNECESWLiwbBdEkjXdXQoBoP2sRY+7d7OjCzekD4Ko//K/0gUAd0MaPGBUxTX3cVcKdX2bydeWj3NkBBR4OzjciW3f55mrZYg9e/XSA5JQd+LThQNxuBuB4eqUMKYUKqJGIg2scLwZb20vu/ESrYgED4fTqzP6vGhFQkGx89v7c8fgnwV9/h1ZcBhs7Dee/IdId1KHW13OCdt0T6BJRDTmGlFW0fFXre/rCOyaBuogCkfTpCNreb91Lhu9nH55vvvx9nU5O7cR6xXcIj2QQHBGDZLhcOz1JIVzY5E9cBdVJ6NHsnBZNjAYcciBoduZSz2jP4za0iYmZsdL+Cq2mo+mygBws8rgw8bpcwmVNtIantwGKpNJWQ/EuGNuLM3WZT1gimH6NKh2ibrJH2iCFJMov0xk6rby3YhtbTb6OG4eDdZqFdkFfMlCW8BNPZwjsZWnSGsJHkaitMUuRFza+wfqUdlNWecEk0doJTgqg2HzLeNr6CAyoyRp8ZQwaSUzEUjKQ8l53BOjcbsS9ThKEcz6RHC2NI8oMMc7znq5IMDftK7pkEoWxPqP1goXzJ7NgxkAAAAAElFTkSuQmCC
""")

LOCALIZED_STRINGS = {
    "en": "Closed",
    "de": "Zu",
}

def main(config):
    lang = config.get("lang", "en")
    font = "terminus-18" if canvas.is2x() else "tb-8"
    image_size = 40 if canvas.is2x() else 20

    return render.Root(
        child = render.Box(
            render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Image(src = ICON_CLOSED, width = image_size),
                    render.Text(LOCALIZED_STRINGS[lang], font = font),
                ],
            ),
        ),
    )
