"""
Applet: Microseasons
Summary: 72 Japanese microseasons
Description: Displays today's Japanese microseason (Shichijuni-ko) in English or Japanese Romaji on its daily Iro-goyomi traditional color background, with optional daily phrase and color note screens.
Author: Brombomb
"""

load("math.star", "math")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("seasons_data.star", "SEASONS", "SEKKI_STARTS")
load("time.star", "time")

MONTH_ABBR = [
    "",
    "JAN",
    "FEB",
    "MAR",
    "APR",
    "MAY",
    "JUN",
    "JUL",
    "AUG",
    "SEP",
    "OCT",
    "NOV",
    "DEC",
]

FRAME_DELAY_MS = 100
FRAMES_PER_SCREEN = 45

def resolve_timezone(config):
    return config.get("$tz") or time.tz() or "Asia/Tokyo"

def parse_override_date(date_str):
    if not date_str:
        return None
    parts = date_str.strip().split("-")
    if len(parts) == 2 and parts[0].isdigit() and parts[1].isdigit():
        m = int(parts[0])
        d = int(parts[1])
        if m >= 1 and m <= 12 and d >= 1 and d <= 31:
            return (2026, m, d)
    if len(parts) == 3 and parts[0].isdigit() and parts[1].isdigit() and parts[2].isdigit():
        y = int(parts[0])
        m = int(parts[1])
        d = int(parts[2])
        if m >= 1 and m <= 12 and d >= 1 and d <= 31:
            return (y, m, d)
    return None

def resolve_microseason(year, month, day):
    target_unix = time.time(year = year, month = month, day = day, location = "UTC").unix

    # Build sorted list of (unix_ts, sekki_index) across year-1, year, year+1
    # so December/January wrap-around is exact.
    candidates = []
    for y in [year - 1, year, year + 1]:
        for idx, (m, d) in enumerate(SEKKI_STARTS):
            ts = time.time(year = y, month = m, day = d, location = "UTC").unix
            candidates.append((ts, idx))

    candidates = sorted(candidates, key = lambda item: item[0])

    current_start = candidates[0]
    next_start = candidates[1]
    for item in candidates:
        if item[0] <= target_unix:
            current_start = item
        else:
            next_start = item
            break

    days_in_sekki = (next_start[0] - current_start[0]) // 86400
    day_offset = (target_unix - current_start[0]) // 86400

    if day_offset < 5:
        sub = 0
        day_in_ko = day_offset
        ko_len = 5
    elif day_offset < 10:
        sub = 1
        day_in_ko = day_offset - 5
        ko_len = 5
    else:
        sub = 2
        day_in_ko = day_offset - 10
        ko_len = days_in_sekki - 10

    ko_index = current_start[1] * 3 + sub
    ko_num = ko_index + 1
    season_en, season_romaji, colors = SEASONS[ko_index]

    color_idx = day_in_ko if day_in_ko < len(colors) else len(colors) - 1
    color_name, color_hex, phrase, color_note = colors[color_idx]

    return {
        "ko_num": ko_num,
        "en": season_en,
        "romaji": season_romaji,
        "day_in_ko": day_in_ko + 1,
        "ko_len": ko_len,
        "color_name": color_name,
        "color_hex": color_hex,
        "phrase": phrase,
        "color_note": color_note,
        "colors": colors,
    }

def hex_to_rgb(hex_color):
    h = hex_color.lstrip("#")
    return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)

def rgb_to_hex(r, g, b):
    digits = "0123456789ABCDEF"
    out = "#"
    for val in [r, g, b]:
        clamped = max(0, min(255, int(val)))
        out += digits[clamped // 16] + digits[clamped % 16]
    return out

def blend_hex(hex_a, hex_b, t):
    ra, ga, ba = hex_to_rgb(hex_a)
    rb, gb, bb = hex_to_rgb(hex_b)
    return rgb_to_hex(
        ra + (rb - ra) * t,
        ga + (gb - ga) * t,
        ba + (bb - ba) * t,
    )

def linearize_channel(c):
    s = c / 255.0
    if s <= 0.03928:
        return s / 12.92
    return math.pow((s + 0.055) / 1.055, 2.4)

def relative_luminance(hex_color):
    r, g, b = hex_to_rgb(hex_color)
    return 0.2126 * linearize_channel(r) + 0.7152 * linearize_channel(g) + 0.0722 * linearize_channel(b)

def contrast_ratio(hex_a, hex_b):
    la = relative_luminance(hex_a)
    lb = relative_luminance(hex_b)
    hi = la if la >= lb else lb
    lo = lb if la >= lb else la
    return (hi + 0.05) / (lo + 0.05)

def blend_to_contrast(bg_hex, fg_hex, target_ratio):
    lo = 0.0
    hi = 0.45
    for _ in range(10):
        mid = (lo + hi) / 2.0
        cand = blend_hex(bg_hex, fg_hex, mid)
        if contrast_ratio(bg_hex, cand) < target_ratio:
            lo = mid
        else:
            hi = mid
    return blend_hex(bg_hex, fg_hex, hi)

def contrast_palette(bg_hex):
    lum = relative_luminance(bg_hex)

    # WCAG contrast ratios against white (#FFFFFF) and black (#000000)
    contrast_white = 1.05 / (lum + 0.05)
    contrast_black = (lum + 0.05) / 0.05
    if contrast_black >= contrast_white:
        fg = "#000000"
    else:
        fg = "#FFFFFF"
    sub_fg = blend_hex(bg_hex, fg, 0.80)
    rule = blend_to_contrast(bg_hex, fg, 2.2)
    return fg, sub_fg, rule

def tb8_word_width(word):
    w = 0
    for i in range(len(word)):
        ch = word[i]
        if ch in ["i", "l", ".", ",", "'", "!"]:
            w += 3
        elif ch in ["f", "j", "r", "t", "I"]:
            w += 4
        elif ch in ["m", "w", "M", "W"]:
            w += 6
        else:
            w += 5
    return w

def fits_tb8_two_lines(text, max_px):
    words = text.split(" ")
    lines = 1
    cur = 0
    for word in words:
        ww = tb8_word_width(word)
        if cur == 0:
            cur = ww
        elif cur + 4 + ww <= max_px:
            cur += 4 + ww
        else:
            lines += 1
            cur = ww
    return lines <= 2

def fits_tom_thumb_lines(text, max_px, max_lines):
    words = text.split(" ")
    lines = 1
    cur = 0
    for word in words:
        ww = len(word) * 4
        if cur == 0:
            cur = ww
        elif cur + 4 + ww <= max_px:
            cur += 4 + ww
        else:
            lines += 1
            cur = ww
    return lines <= max_lines

WAGARA_TILES = {
    "ichimatsu": [
        "####....",
        "####....",
        "####....",
        "####....",
        "....####",
        "....####",
        "....####",
        "....####",
    ],
    "shippo": [
        "...##...",
        "..#..#..",
        ".#....#.",
        "#......#",
        "#......#",
        ".#....#.",
        "..#..#..",
        "...##...",
    ],
    "seigaiha": [
        "..####..",
        ".#....#.",
        "#..##..#",
        "#.#..#.#",
        ".#....#.",
        "##....##",
    ],
    "yagasuri": [
        "#..##..#",
        ".#.##.#.",
        "..####..",
        "...##...",
        "#..##..#",
        ".#.##.#.",
        "..####..",
        "...##...",
    ],
}

def resolve_wagara(pattern, ko_num):
    if pattern == "auto":
        if ko_num <= 18:
            return "shippo"
        elif ko_num <= 36:
            return "seigaiha"
        elif ko_num <= 54:
            return "yagasuri"
        return "ichimatsu"
    if pattern in WAGARA_TILES:
        return pattern
    return None

def build_wagara_tile(tile_rows, color):
    rows = []
    for row_str in tile_rows:
        cells = []
        run_ch = ""
        run_len = 0
        for idx in range(len(row_str)):
            ch = row_str[idx]
            if ch == run_ch:
                run_len += 1
            else:
                if run_len > 0:
                    if run_ch == "#":
                        cells.append(render.Box(width = run_len, height = 1, color = color))
                    else:
                        cells.append(render.Box(width = run_len, height = 1))
                run_ch = ch
                run_len = 1
        if run_len > 0:
            if run_ch == "#":
                cells.append(render.Box(width = run_len, height = 1, color = color))
            else:
                cells.append(render.Box(width = run_len, height = 1))
        rows.append(render.Row(children = cells))
    return render.Column(children = rows)

def build_background(width, height, bg, fg, pattern_name):
    base = render.Box(width = width, height = height, color = bg)
    if not pattern_name or pattern_name not in WAGARA_TILES:
        return base
    tile_rows = WAGARA_TILES[pattern_name]
    tile_w = len(tile_rows[0])
    tile_h = len(tile_rows)
    pat_color = blend_to_contrast(bg, fg, 1.55)
    tile = build_wagara_tile(tile_rows, pat_color)
    cols = (width + tile_w - 1) // tile_w
    rows = (height + tile_h - 1) // tile_h
    grid_row = render.Row(children = [tile] * cols)
    grid = render.Column(children = [grid_row] * rows)
    return render.Stack(
        children = [
            base,
            render.Box(width = width, height = height, child = grid),
        ],
    )

def wrap_screen(width, height, bg, fg, pattern_name, content):
    return render.Stack(
        children = [
            build_background(width, height, bg, fg, pattern_name),
            render.Box(width = width, height = height, child = content),
        ],
    )

def render_day_dots(day_in_ko, ko_len, colors, fg, rule, dot_size, gap):
    dots = []
    outer_size = dot_size + 2
    for i in range(1, ko_len + 1):
        c_idx = i - 1 if i - 1 < len(colors) else len(colors) - 1
        swatch_hex = colors[c_idx][1]
        border_color = fg if i == day_in_ko else rule
        dots.append(
            render.Box(
                width = outer_size,
                height = outer_size,
                color = border_color,
                child = render.Box(
                    width = dot_size,
                    height = dot_size,
                    color = swatch_hex,
                ),
            ),
        )
        if i < ko_len:
            dots.append(render.Box(width = gap, height = outer_size))
    return render.Row(
        cross_align = "center",
        main_align = "center",
        children = dots,
    )

def build_season_screen(width, height, is_2x, is_square, info, season_text, ko_label, date_label, show_header, footer, bg, fg, sub_fg, rule, pattern_name):
    color_label = info["color_name"]

    if is_2x:
        pad_x = 4
        pad_y = 3
        content_w = width - pad_x * 2

        header_widget = None
        if show_header:
            header_widget = render.Column(
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "space_between",
                        cross_align = "center",
                        children = [
                            render.Text(content = ko_label, font = "tb-8", color = sub_fg),
                            render.Text(content = date_label, font = "tb-8", color = sub_fg),
                        ],
                    ),
                    render.Padding(
                        pad = (0, 2, 0, 0),
                        child = render.Box(width = content_w, height = 1, color = rule),
                    ),
                ],
            )

        title_font = "terminus-14" if len(season_text) <= 24 else "terminus-12"
        body_widget = render.WrappedText(
            content = season_text,
            width = content_w,
            font = title_font,
            color = fg,
            align = "center",
        )

        footer_widget = None
        footer_h_2x = 0
        if footer == "both":
            footer_h_2x = 15
            footer_widget = render.Column(
                cross_align = "center",
                children = [
                    render.Text(content = color_label, font = "tb-8", color = sub_fg),
                    render.Padding(
                        pad = (0, 2, 0, 0),
                        child = render_day_dots(info["day_in_ko"], info["ko_len"], info["colors"], fg, rule, 2, 3),
                    ),
                ],
            )
        elif footer == "color":
            footer_h_2x = 9
            footer_widget = render.Text(content = color_label, font = "tb-8", color = sub_fg)
        elif footer == "dots":
            footer_h_2x = 6
            footer_widget = render_day_dots(info["day_in_ko"], info["ko_len"], info["colors"], fg, rule, 2, 3)

        children = []
        if header_widget:
            children.append(header_widget)
        children.append(
            render.Box(
                width = content_w,
                height = height - pad_y * 2 - (12 if show_header else 0) - footer_h_2x,
                child = render.Column(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [body_widget],
                ),
            ),
        )
        if footer_widget:
            children.append(footer_widget)

        return wrap_screen(
            width,
            height,
            bg,
            fg,
            pattern_name,
            render.Padding(
                pad = (pad_x, pad_y, pad_x, pad_y),
                child = render.Column(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "center",
                    children = children,
                ),
            ),
        )

    if is_square:
        pad_x = 3
        pad_y = 2
        content_w = width - pad_x * 2

        children = []
        if show_header:
            children.append(
                render.Column(
                    children = [
                        render.Row(
                            expanded = True,
                            main_align = "space_between",
                            cross_align = "center",
                            children = [
                                render.Text(content = ko_label, font = "tom-thumb", color = sub_fg),
                                render.Text(content = date_label, font = "tom-thumb", color = sub_fg),
                            ],
                        ),
                        render.Padding(
                            pad = (0, 2, 0, 0),
                            child = render.Box(width = content_w, height = 1, color = rule),
                        ),
                    ],
                ),
            )

        footer_h_sq = 18 if footer == "both" else (11 if footer == "color" else (7 if footer == "dots" else 0))
        body_h = height - pad_y * 2 - (9 if show_header else 0) - footer_h_sq
        children.append(
            render.Box(
                width = content_w,
                height = body_h,
                child = render.Column(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.WrappedText(
                            content = season_text,
                            width = content_w,
                            font = "tb-8",
                            color = fg,
                            align = "center",
                        ),
                    ],
                ),
            ),
        )

        if footer == "both":
            color_font = "tom-thumb" if len(color_label) <= 14 else "CG-pixel-3x5-mono"
            children.append(
                render.Column(
                    cross_align = "center",
                    children = [
                        render.Box(width = content_w, height = 1, color = rule),
                        render.Padding(
                            pad = (0, 2, 0, 0),
                            child = render.Text(content = color_label, font = color_font, color = sub_fg),
                        ),
                        render.Padding(
                            pad = (0, 2, 0, 0),
                            child = render_day_dots(info["day_in_ko"], info["ko_len"], info["colors"], fg, rule, 2, 2),
                        ),
                    ],
                ),
            )
        elif footer == "color":
            color_font = "tom-thumb" if len(color_label) <= 14 else "CG-pixel-3x5-mono"
            children.append(
                render.Column(
                    cross_align = "center",
                    children = [
                        render.Box(width = content_w, height = 1, color = rule),
                        render.Padding(
                            pad = (0, 2, 0, 0),
                            child = render.Text(content = color_label, font = color_font, color = sub_fg),
                        ),
                    ],
                ),
            )
        elif footer == "dots":
            children.append(render_day_dots(info["day_in_ko"], info["ko_len"], info["colors"], fg, rule, 2, 2))

        return wrap_screen(
            width,
            height,
            bg,
            fg,
            pattern_name,
            render.Padding(
                pad = (pad_x, pad_y, pad_x, pad_y),
                child = render.Column(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "center",
                    children = children,
                ),
            ),
        )

    # 64x32 classic 1x layout
    pad_x = 2
    content_w = width - pad_x * 2

    children = []
    header_h = 0
    if show_header:
        header_h = 7
        children.append(
            render.Padding(
                pad = (pad_x, 0, pad_x, 0),
                child = render.Column(
                    children = [
                        render.Row(
                            expanded = True,
                            main_align = "space_between",
                            cross_align = "center",
                            children = [
                                render.Text(content = ko_label, font = "tom-thumb", color = sub_fg),
                                render.Text(content = date_label, font = "tom-thumb", color = sub_fg),
                            ],
                        ),
                        render.Box(width = content_w, height = 1, color = rule),
                    ],
                ),
            ),
        )

    footer_1x = "color" if footer == "both" else footer
    footer_h = 6 if footer_1x in ["color", "dots"] else 0
    body_h = height - 1 - header_h - footer_h

    # Use tb-8 only when text fits cleanly in 2 lines; otherwise tom-thumb for crisp 2-3 lines
    if not show_header and footer_1x == "none":
        body_font = "tb-8"
    elif fits_tb8_two_lines(season_text, content_w):
        body_font = "tb-8"
    else:
        body_font = "tom-thumb"

    children.append(
        render.Box(
            width = width,
            height = body_h,
            child = render.Padding(
                pad = (pad_x, 0, pad_x, 0),
                child = render.Column(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.WrappedText(
                            content = season_text,
                            width = content_w,
                            font = body_font,
                            color = fg,
                            align = "center",
                        ),
                    ],
                ),
            ),
        ),
    )

    if footer_1x == "color":
        children.append(
            render.Padding(
                pad = (0, 1, 0, 0),
                child = render.Text(content = color_label, font = "CG-pixel-3x5-mono", color = sub_fg),
            ),
        )
    elif footer_1x == "dots":
        children.append(
            render.Padding(
                pad = (0, 1, 0, 1),
                child = render_day_dots(info["day_in_ko"], info["ko_len"], info["colors"], fg, rule, 2, 2),
            ),
        )

    return wrap_screen(
        width,
        height,
        bg,
        fg,
        pattern_name,
        render.Padding(
            pad = (0, 1, 0, 0),
            child = render.Column(
                expanded = True,
                main_align = "space_between",
                cross_align = "center",
                children = children,
            ),
        ),
    )

def build_phrase_screen(width, height, is_2x, is_square, info, ko_label, date_label, show_header, bg, fg, sub_fg, rule, pattern_name):
    phrase = info["phrase"]

    if is_2x:
        pad_x = 5
        pad_y = 3
        content_w = width - pad_x * 2
        header_h = 12 if show_header else 0
        children = []
        if show_header:
            children.append(
                render.Column(
                    children = [
                        render.Row(
                            expanded = True,
                            main_align = "space_between",
                            cross_align = "center",
                            children = [
                                render.Text(content = ko_label, font = "tb-8", color = sub_fg),
                                render.Text(content = date_label, font = "tb-8", color = sub_fg),
                            ],
                        ),
                        render.Padding(
                            pad = (0, 2, 0, 0),
                            child = render.Box(width = content_w, height = 1, color = rule),
                        ),
                    ],
                ),
            )
        phrase_font = "terminus-12" if len(phrase) <= 36 else "tb-8"
        children.append(
            render.Box(
                width = content_w,
                height = height - pad_y * 2 - header_h,
                child = render.Column(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.WrappedText(
                            content = phrase,
                            width = content_w,
                            font = phrase_font,
                            color = fg,
                            align = "center",
                        ),
                    ],
                ),
            ),
        )
        return wrap_screen(
            width,
            height,
            bg,
            fg,
            pattern_name,
            render.Padding(
                pad = (pad_x, pad_y, pad_x, pad_y),
                child = render.Column(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "center",
                    children = children,
                ),
            ),
        )

    if is_square:
        pad_x = 3
        pad_y = 2
        content_w = width - pad_x * 2
        header_h = 9 if show_header else 0
        children = []
        if show_header:
            children.append(
                render.Column(
                    children = [
                        render.Row(
                            expanded = True,
                            main_align = "space_between",
                            cross_align = "center",
                            children = [
                                render.Text(content = ko_label, font = "tom-thumb", color = sub_fg),
                                render.Text(content = date_label, font = "tom-thumb", color = sub_fg),
                            ],
                        ),
                        render.Padding(
                            pad = (0, 2, 0, 0),
                            child = render.Box(width = content_w, height = 1, color = rule),
                        ),
                    ],
                ),
            )
        phrase_font = "tb-8" if len(phrase) <= 32 else "tom-thumb"
        children.append(
            render.Box(
                width = content_w,
                height = height - pad_y * 2 - header_h,
                child = render.Column(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.WrappedText(
                            content = phrase,
                            width = content_w,
                            font = phrase_font,
                            color = fg,
                            align = "center",
                        ),
                    ],
                ),
            ),
        )
        return wrap_screen(
            width,
            height,
            bg,
            fg,
            pattern_name,
            render.Padding(
                pad = (pad_x, pad_y, pad_x, pad_y),
                child = render.Column(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "center",
                    children = children,
                ),
            ),
        )

    # 64x32 classic 1x layout
    pad_x = 1
    content_w = width - pad_x * 2
    header_h = 7 if show_header else 0
    body_h = height - 1 - header_h
    children = []
    if show_header:
        children.append(
            render.Padding(
                pad = (1, 0, 1, 0),
                child = render.Column(
                    children = [
                        render.Row(
                            expanded = True,
                            main_align = "space_between",
                            cross_align = "center",
                            children = [
                                render.Text(content = ko_label, font = "tom-thumb", color = sub_fg),
                                render.Text(content = date_label, font = "tom-thumb", color = sub_fg),
                            ],
                        ),
                        render.Box(width = width - 4, height = 1, color = rule),
                    ],
                ),
            ),
        )
    phrase_widget = render.WrappedText(
        content = phrase,
        width = content_w,
        font = "tom-thumb",
        color = fg,
        align = "center",
    )
    if fits_tom_thumb_lines(phrase, content_w, body_h // 6):
        body_child = render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [phrase_widget],
        )
    else:
        body_child = render.Marquee(
            height = body_h,
            scroll_direction = "vertical",
            offset_start = 4,
            offset_end = 4,
            child = phrase_widget,
        )
    children.append(
        render.Box(
            width = content_w,
            height = body_h,
            child = body_child,
        ),
    )
    return wrap_screen(
        width,
        height,
        bg,
        fg,
        pattern_name,
        render.Padding(
            pad = (pad_x, 1, pad_x, 0),
            child = render.Column(
                expanded = True,
                main_align = "space_between",
                cross_align = "center",
                children = children,
            ),
        ),
    )

def build_color_note_screen(width, height, is_2x, is_square, info, bg, fg, sub_fg, rule, pattern_name):
    color_label = info["color_name"]
    color_hex = info["color_hex"]
    note = info["color_note"]

    if is_2x:
        pad_x = 5
        pad_y = 3
        content_w = width - pad_x * 2
        header_h = 12
        note_font = "terminus-12" if len(note) <= 36 else "tb-8"
        return wrap_screen(
            width,
            height,
            bg,
            fg,
            pattern_name,
            render.Padding(
                pad = (pad_x, pad_y, pad_x, pad_y),
                child = render.Column(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "center",
                    children = [
                        render.Column(
                            children = [
                                render.Row(
                                    expanded = True,
                                    main_align = "space_between",
                                    cross_align = "center",
                                    children = [
                                        render.Text(content = color_label, font = "tb-8", color = sub_fg),
                                        render.Text(content = color_hex, font = "tom-thumb", color = sub_fg),
                                    ],
                                ),
                                render.Padding(
                                    pad = (0, 2, 0, 0),
                                    child = render.Box(width = content_w, height = 1, color = rule),
                                ),
                            ],
                        ),
                        render.Box(
                            width = content_w,
                            height = height - pad_y * 2 - header_h,
                            child = render.Column(
                                expanded = True,
                                main_align = "center",
                                cross_align = "center",
                                children = [
                                    render.WrappedText(
                                        content = note,
                                        width = content_w,
                                        font = note_font,
                                        color = fg,
                                        align = "center",
                                    ),
                                ],
                            ),
                        ),
                    ],
                ),
            ),
        )

    if is_square:
        pad_x = 3
        pad_y = 2
        content_w = width - pad_x * 2
        header_font = "tom-thumb" if len(color_label) <= 14 else "CG-pixel-3x5-mono"
        header_h = 9
        note_font = "tb-8" if len(note) <= 30 else "tom-thumb"
        return wrap_screen(
            width,
            height,
            bg,
            fg,
            pattern_name,
            render.Padding(
                pad = (pad_x, pad_y, pad_x, pad_y),
                child = render.Column(
                    expanded = True,
                    main_align = "space_between",
                    cross_align = "center",
                    children = [
                        render.Column(
                            cross_align = "center",
                            children = [
                                render.Text(content = color_label, font = header_font, color = sub_fg),
                                render.Padding(
                                    pad = (0, 2, 0, 0),
                                    child = render.Box(width = content_w, height = 1, color = rule),
                                ),
                            ],
                        ),
                        render.Box(
                            width = content_w,
                            height = height - pad_y * 2 - header_h,
                            child = render.Column(
                                expanded = True,
                                main_align = "center",
                                cross_align = "center",
                                children = [
                                    render.WrappedText(
                                        content = note,
                                        width = content_w,
                                        font = note_font,
                                        color = fg,
                                        align = "center",
                                    ),
                                ],
                            ),
                        ),
                    ],
                ),
            ),
        )

    # 64x32 classic 1x layout
    header_h = 7
    body_w = width - 2
    body_h = height - 1 - header_h
    note_widget = render.WrappedText(
        content = note,
        width = body_w,
        font = "tom-thumb",
        color = fg,
        align = "center",
    )
    if fits_tom_thumb_lines(note, body_w, body_h // 6):
        note_body = render.Column(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [note_widget],
        )
    else:
        note_body = render.Marquee(
            height = body_h,
            scroll_direction = "vertical",
            offset_start = 4,
            offset_end = 4,
            child = note_widget,
        )
    return wrap_screen(
        width,
        height,
        bg,
        fg,
        pattern_name,
        render.Padding(
            pad = (0, 1, 0, 0),
            child = render.Column(
                expanded = True,
                main_align = "space_between",
                cross_align = "center",
                children = [
                    render.Column(
                        cross_align = "center",
                        children = [
                            render.Text(content = color_label, font = "CG-pixel-3x5-mono", color = sub_fg),
                            render.Padding(
                                pad = (0, 1, 0, 0),
                                child = render.Box(width = width - 4, height = 1, color = rule),
                            ),
                        ],
                    ),
                    render.Box(
                        width = body_w,
                        height = body_h,
                        child = note_body,
                    ),
                ],
            ),
        ),
    )

def main(config):
    width, height = canvas.size()
    is_2x = canvas.is2x()
    is_square = height == width

    override = parse_override_date(config.get("date"))
    if override:
        year, month, day = override
    else:
        tz = resolve_timezone(config)
        now = time.now().in_location(tz)
        year, month, day = now.year, now.month, now.day

    info = resolve_microseason(year, month, day)

    language = config.get("language", "en")
    show_header = config.bool("show_header", True)
    footer = config.get("footer", "both")
    show_phrase = config.bool("show_phrase", True)
    show_color_note = config.bool("show_color_note", True)
    pattern_name = resolve_wagara(config.get("pattern", "none"), info["ko_num"]) if is_2x else None

    season_text = info["romaji"] if language == "romaji" else info["en"]
    bg = info["color_hex"]
    fg, sub_fg, rule = contrast_palette(bg)

    ko_num = info["ko_num"]
    ko_label = ("%s%d/72" % ("0" if ko_num < 10 else "", ko_num))
    date_label = "%s %d" % (MONTH_ABBR[month], day)

    screens = [
        (build_season_screen(width, height, is_2x, is_square, info, season_text, ko_label, date_label, show_header, footer, bg, fg, sub_fg, rule, pattern_name), False),
    ]
    if show_phrase and info["phrase"]:
        phrase_scrolls = (not is_2x and not is_square) and not fits_tom_thumb_lines(info["phrase"], width - 2, (height - 1 - (7 if show_header else 0)) // 6)
        screens.append(
            (build_phrase_screen(width, height, is_2x, is_square, info, ko_label, date_label, show_header, bg, fg, sub_fg, rule, pattern_name), phrase_scrolls),
        )
    if show_color_note and info["color_note"]:
        note_scrolls = (not is_2x and not is_square) and not fits_tom_thumb_lines(info["color_note"], width - 2, (height - 8) // 6)
        screens.append(
            (build_color_note_screen(width, height, is_2x, is_square, info, bg, fg, sub_fg, rule, pattern_name), note_scrolls),
        )

    screen_override = config.get("screen")
    if screen_override and screen_override.isdigit():
        idx = int(screen_override) - 1
        if idx >= 0 and idx < len(screens):
            return render.Root(delay = FRAME_DELAY_MS, child = screens[idx][0])

    if len(screens) == 1:
        return render.Root(child = screens[0][0])

    seq_children = []
    for screen_widget, is_marquee in screens:
        if is_marquee:
            seq_children.append(screen_widget)
        else:
            seq_children.append(render.Animation(children = [screen_widget] * FRAMES_PER_SCREEN))

    return render.Root(
        delay = FRAME_DELAY_MS,
        child = render.Sequence(children = seq_children),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "language",
                name = "Language",
                desc = "Display microseason name in English or Japanese Romaji.",
                icon = "language",
                default = "en",
                options = [
                    schema.Option(display = "English", value = "en"),
                    schema.Option(display = "Japanese (Romaji)", value = "romaji"),
                ],
            ),
            schema.Dropdown(
                id = "footer",
                name = "Footer",
                desc = "Display color name, day color dots, both (2x/64x64), or nothing.",
                icon = "palette",
                default = "both",
                options = [
                    schema.Option(display = "Color + Day Dots (2x/64x64)", value = "both"),
                    schema.Option(display = "Color of the Day", value = "color"),
                    schema.Option(display = "Day Color Dots", value = "dots"),
                    schema.Option(display = "None", value = "none"),
                ],
            ),
            schema.Dropdown(
                id = "pattern",
                name = "Background Pattern (2x Only)",
                desc = "Overlay a subtle traditional Japanese wagara pattern on 2x displays.",
                icon = "borderAll",
                default = "none",
                options = [
                    schema.Option(display = "None (Solid Color)", value = "none"),
                    schema.Option(display = "Seasonal (Auto)", value = "auto"),
                    schema.Option(display = "Ichimatsu (Checkered)", value = "ichimatsu"),
                    schema.Option(display = "Shippo (Seven Treasures)", value = "shippo"),
                    schema.Option(display = "Seigaiha (Ocean Waves)", value = "seigaiha"),
                    schema.Option(display = "Yagasuri (Arrow Fletching)", value = "yagasuri"),
                ],
            ),
            schema.Toggle(
                id = "show_header",
                name = "Show Header",
                desc = "Display the microseason number (1-72) and date.",
                icon = "calendar",
                default = True,
            ),
            schema.Toggle(
                id = "show_phrase",
                name = "Show Daily Phrase",
                desc = "Cycle to a second screen showing today's seasonal phrase.",
                icon = "quoteLeft",
                default = True,
            ),
            schema.Toggle(
                id = "show_color_note",
                name = "Show Color Note",
                desc = "Cycle to a third screen describing today's Iro-goyomi color.",
                icon = "droplet",
                default = True,
            ),
        ],
    )
