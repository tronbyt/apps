load("render.star", "render")

def main():
    return render.Root(
        child = render.Column(
            main_align = "space_evenly",
            cross_align = "center",
            expanded = True,
            children = [
                render.Text("Claudius", font = "tb-8", color = "#d97757"),
                render.Text("Waiting for", font = "CG-pixel-3x5-mono", color = "#fff"),
                render.Text("Mac app", font = "CG-pixel-3x5-mono", color = "#888"),
            ],
        ),
    )
