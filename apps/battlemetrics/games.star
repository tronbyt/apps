load("render.star", "render")
load("time.star", "time")
load("utils.star", "parse_ts")
load("widgets.star", "render_duration_widget")

def render_middle_rust(server):
    details = server["details"]
    now_unix = time.now().unix
    elapsed_secs = 0
    remaining_secs = 0

    if details.get("rust_born") != None:
        elapsed_secs = now_unix - parse_ts(details["rust_born"]).unix
    if details.get("rust_next_wipe") != None:
        remaining_secs = parse_ts(details["rust_next_wipe"]).unix - now_unix
    if remaining_secs < 0:
        remaining_secs = 0

    return render.Row(
        expanded = True,
        children = [
            render.Column(
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "space_between",
                        children = [
                            render_duration_widget(elapsed_secs, "#888888", "#555555"),
                            render_duration_widget(remaining_secs, "#f5a623", "#8a5a00"),
                        ],
                    ),
                    render.Box(height = 1),
                    render.Row(
                        expanded = True,
                        main_align = "space_between",
                        children = [
                            render.Text("old", font = "CG-pixel-3x5-mono", color = "#555555"),
                            render.Text("left", font = "CG-pixel-3x5-mono", color = "#8a5a00"),
                        ],
                    ),
                ],
            ),
        ],
    )

GAME_MIDDLE_RENDERERS = {
    "rust": render_middle_rust,
}

GAME_ICONS = {
    "7dtd": "https://cdn.battlemetrics.com/app/assets/7dtd.2df6d.png",
    "83": "https://cdn.battlemetrics.com/app/assets/83.814e2.png",
    "arksa": "https://cdn.battlemetrics.com/app/assets/arksa.d91c2.png",
    "ark": "https://cdn.battlemetrics.com/app/assets/ark.55fdf.png",
    "arma2": "https://cdn.battlemetrics.com/app/assets/arma2.22622.png",
    "arma3": "https://cdn.battlemetrics.com/app/assets/arma3.aea2b.png",
    "reforger": "https://cdn.battlemetrics.com/app/assets/reforger.3d3fa.png",
    "atlas": "https://cdn.battlemetrics.com/app/assets/atlas.e58b3.png",
    "battalion1944": "https://cdn.battlemetrics.com/app/assets/battalion1944.42c2e.png",
    "battlebit": "https://cdn.battlemetrics.com/app/assets/battlebit.bebc0.png",
    "btw": "https://cdn.battlemetrics.com/app/assets/btw.f79f8.png",
    "conanexiles": "https://cdn.battlemetrics.com/app/assets/conanexiles.d30c8.png",
    "cs": "https://cdn.battlemetrics.com/app/assets/cs.188f3.png",
    "css": "https://cdn.battlemetrics.com/app/assets/css.f2a36.png",
    "dnl": "https://cdn.battlemetrics.com/app/assets/dnl.5b306.png",
    "dayz": "https://cdn.battlemetrics.com/app/assets/dayz.932f9.png",
    "enshrouded": "https://cdn.battlemetrics.com/app/assets/enshrouded.fc88b.png",
    "gmod": "https://cdn.battlemetrics.com/app/assets/gmod.70e3e.png",
    "hll": "https://cdn.battlemetrics.com/app/assets/hll.a94d9.png",
    "insurgency": "https://cdn.battlemetrics.com/app/assets/insurgency.d46f2.png",
    "sandstorm": "https://cdn.battlemetrics.com/app/assets/sandstorm.3b7d6.png",
    "minecraft": "https://cdn.battlemetrics.com/app/assets/minecraft.19839.png",
    "mordhau": "https://cdn.battlemetrics.com/app/assets/mordhau.47bec.png",
    "moe": "https://cdn.battlemetrics.com/app/assets/moe.797fc.png",
    "palworld": "https://cdn.battlemetrics.com/app/assets/palworld.56b1c.png",
    "pixark": "https://cdn.battlemetrics.com/app/assets/pixark.2df7d.png",
    "zomboid": "https://cdn.battlemetrics.com/app/assets/zomboid.47aa8.png",
    "rend": "https://cdn.battlemetrics.com/app/assets/rend.a52a2.png",
    "renown": "https://cdn.battlemetrics.com/app/assets/renown.1fe10.png",
    "rs2vietnam": "https://cdn.battlemetrics.com/app/assets/rs2vietnam.f28f9.png",
    "rust": "https://cdn.battlemetrics.com/app/assets/rust.47f25.png",
    "scum": "https://cdn.battlemetrics.com/app/assets/scum.38d39.png",
    "soulmask": "https://cdn.battlemetrics.com/app/assets/soulmask.377a8.png",
    "squad": "https://cdn.battlemetrics.com/app/assets/squad.3642a.png",
    "postscriptum": "https://cdn.battlemetrics.com/app/assets/postscriptum.288d8.png",
    "tf2": "https://cdn.battlemetrics.com/app/assets/tf2.26e3e.png",
    "thefront": "https://cdn.battlemetrics.com/app/assets/thefront.f32fd.png",
    "unturned": "https://cdn.battlemetrics.com/app/assets/unturned.2daec.png",
    "vrising": "https://cdn.battlemetrics.com/app/assets/vrising.6d2a3.png",
    "valheim": "https://cdn.battlemetrics.com/app/assets/valheim.b8dfc.png",
}
