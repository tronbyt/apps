load("render.star", "render")

def _m_glyph(color):
    def px():
        return render.Box(width = 1, height = 1, color = color)

    def gap(w):
        return render.Box(width = w, height = 1)

    return render.Column(
        children = [
            render.Row(children = [px(), gap(3), px()]),
            render.Row(children = [px(), px(), gap(1), px(), px()]),
            render.Row(children = [px(), gap(1), px(), gap(1), px()]),
            render.Row(children = [px(), gap(3), px()]),
            render.Row(children = [px(), gap(3), px()]),
        ],
    )

def render_duration_widget(total_secs, num_color, ltr_color):
    if total_secs < 0:
        total_secs = 0
    if total_secs >= 86400:
        days = total_secs // 86400
        hours = (total_secs % 86400) // 3600
        return render.Row(
            children = [
                render.Text(str(days), font = "CG-pixel-4x5-mono", color = num_color),
                render.Text("D", font = "CG-pixel-4x5-mono", color = ltr_color),
                render.Text(str(hours), font = "CG-pixel-4x5-mono", color = num_color),
                render.Text("H", font = "CG-pixel-4x5-mono", color = ltr_color),
            ],
        )
    else:
        hours = total_secs // 3600
        minutes = (total_secs % 3600) // 60
        return render.Row(
            children = [
                render.Text(str(hours), font = "CG-pixel-4x5-mono", color = num_color),
                render.Text("H", font = "CG-pixel-4x5-mono", color = ltr_color),
                render.Text(str(minutes), font = "CG-pixel-4x5-mono", color = num_color),
                _m_glyph(ltr_color),
            ],
        )
