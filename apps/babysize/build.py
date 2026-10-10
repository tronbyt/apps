# Copyright 2026 cptntrps
# SPDX-License-Identifier: Apache-2.0

"""Build baby_size.star: sprites (sprites.py) + weekly sizes + random comparisons, embedded as base64 PNGs.

Run: python3 build.py   (writes baby_size.star next to this file), then pixlet format baby_size.star
"""
import os
import sprites
from pokemon import POKEMON

HERE = os.path.dirname(os.path.abspath(__file__))

# week: (length cm, weight g) - common weekly averages; crown-rump to week 19, crown-heel from week 20
SIZES = {
    4: (0.1, 0), 5: (0.2, 0), 6: (0.6, 0), 7: (1.3, 1), 8: (1.6, 1), 9: (2.3, 2), 10: (3.1, 4), 11: (4.1, 7),
    12: (5.4, 14), 13: (7.4, 23), 14: (8.7, 43), 15: (10.1, 70), 16: (11.6, 100), 17: (13.0, 140), 18: (14.2, 190),
    19: (15.3, 240), 20: (25.6, 300), 21: (26.7, 360), 22: (27.8, 430), 23: (28.9, 501), 24: (30.0, 600),
    25: (34.6, 660), 26: (35.6, 760), 27: (36.6, 875), 28: (37.6, 1005), 29: (38.6, 1153), 30: (39.9, 1319),
    31: (41.1, 1502), 32: (42.4, 1702), 33: (43.7, 1918), 34: (45.0, 2146), 35: (46.2, 2383), 36: (47.4, 2622),
    37: (48.6, 2859), 38: (49.8, 3083), 39: (50.7, 3288), 40: (51.2, 3462),
}

# week: comparisons of about the same size; the minute selects one on each render
CHOICES = {
    4: ["poppy"], 5: ["sesame"], 6: ["lentil"], 7: ["blueberry", "coffeebean", "pea"], 8: ["raspberry", "olive"],
    9: ["grape", "cherry", "olive"], 10: ["strawberry", "cherry", "walnut"], 11: ["fig", "walnut", "strawberry"],
    12: ["lime", "plum", "pingpong"], 13: ["lemon", "kiwi", "plum"], 14: ["peach", "lemon", "tennisball"],
    15: ["apple", "orange", "baseball"], 16: ["avocado", "pear", "teddy"], 17: ["pear", "avocado", "teddy"],
    18: ["mango", "tomato", "pear"], 19: ["mango", "teddy"], 20: ["banana", "carrot"], 21: ["carrot", "banana"],
    22: ["papaya", "zucchini"], 23: ["grapefruit", "papaya"], 24: ["corn", "zucchini"],
    25: ["cauliflower", "eggplant"], 26: ["lettuce", "eggplant"], 27: ["broccoli", "cauliflower", "cabbage"],
    28: ["eggplant", "butternut"], 29: ["butternut", "eggplant"], 30: ["cabbage", "coconut"],
    31: ["coconut", "pineapple"], 32: ["squash", "coconut"], 33: ["pineapple", "cantaloupe"],
    34: ["cantaloupe", "pineapple"], 35: ["honeydew", "cantaloupe"], 36: ["honeydew", "pumpkin"],
    37: ["pumpkin", "honeydew"], 38: ["pumpkin", "watermelon"], 39: ["watermelon", "pumpkin"],
    40: ["watermelon", "pumpkin"],
}

CHOICES.update({4: ['poppy', 'sesame', 'lentil'], 5: ['sesame', 'poppy', 'lentil'], 6: ['lentil', 'sesame', 'pea'], 8: ['raspberry', 'olive', 'blueberry'], 19: ['mango', 'teddy', 'pear'], 20: ['banana', 'carrot', 'zucchini'], 21: ['carrot', 'banana', 'zucchini'], 22: ['papaya', 'zucchini', 'corn'], 23: ['grapefruit', 'papaya', 'eggplant'], 24: ['corn', 'zucchini', 'papaya'], 25: ['cauliflower', 'eggplant', 'lettuce'], 26: ['lettuce', 'eggplant', 'cauliflower'], 28: ['eggplant', 'butternut', 'broccoli'], 29: ['butternut', 'eggplant', 'cabbage'], 30: ['cabbage', 'coconut', 'butternut'], 31: ['coconut', 'pineapple', 'cabbage'], 32: ['squash', 'coconut', 'pineapple'], 33: ['pineapple', 'cantaloupe', 'squash'], 34: ['cantaloupe', 'pineapple', 'honeydew'], 35: ['honeydew', 'cantaloupe', 'pineapple'], 36: ['honeydew', 'pumpkin', 'cantaloupe'], 37: ['pumpkin', 'honeydew', 'watermelon'], 38: ['pumpkin', 'watermelon', 'honeydew'], 39: ['watermelon', 'pumpkin', 'honeydew'], 40: ['watermelon', 'pumpkin', 'honeydew']})

# Everyday objects and pop-culture characters join the fruit comparisons.
for _w, _objs in {9: ['gummybear'], 10: ['lego', 'pollypocket'], 11: ['pollypocket', 'lego'], 12: ['tamagotchi'], 14: ['rubberduck'], 15: ['stuart', 'rubberduck'], 16: ['coxinha'], 17: ['tinkerbell'], 19: ['tinkerbell'], 20: ['smurf', 'kirby', 'havaianas'], 21: ['babygroot', 'havaianas', 'smurf'], 22: ['babygroot', 'kirby'], 24: ['shelfelf'], 25: ['shelfelf'], 26: ['leprechaun'], 27: ['leprechaun'], 28: ['gnome', 'bowlingpin', 'spool1'], 29: ['gnome', 'spool1'], 30: ['pikachu', 'grogu'], 31: ['pikachu', 'grogu', 'bowlingpin'], 32: ['chihuahua'], 33: ['spool2', 'chihuahua'], 34: ['minion', 'spool2'], 35: ['minion'], 36: ['chihuahua'], 37: ['spool3'], 38: ['spool3', 'cat'], 39: ['jigglypuff', 'cat'], 40: ['cat', 'jigglypuff']}.items():
    CHOICES[_w] = CHOICES[_w] + [o for o in _objs if o not in CHOICES[_w]]

# Gen 1 comparisons use official height only, never Pokemon weight. The live
# daily length further filters these candidates so a weekly boundary cannot
# display a Pokemon more than 10% larger/smaller than the baby estimate.
POKEMON_HEIGHTS = {obj: data[1] for obj, data in POKEMON.items()}
for _w, (_length, _) in SIZES.items():
    if _w < 20:  # compare standing height to the crown-heel measurement
        continue
    _end = _length + (SIZES.get(_w + 1, SIZES[_w])[0] - _length) * 6 / 7
    for _obj, _height in POKEMON_HEIGHTS.items():
        if _length <= _height * 1.1 and _end >= _height * 0.9 and _obj not in CHOICES[_w]:
            CHOICES[_w].append(_obj)

NAMES = {  # id: (english, portugues)
    "poppy": ("POPPY SEED", "SEMENTE"), "sesame": ("SESAME SEED", "GERGELIM"), "lentil": ("LENTIL", "LENTILHA"),
    "pea": ("PEA", "ERVILHA"), "coffeebean": ("COFFEE BEAN", "GRAO CAFE"), "blueberry": ("BLUEBERRY", "MIRTILO"),
    "raspberry": ("RASPBERRY", "FRAMBOESA"), "olive": ("OLIVE", "AZEITONA"), "grape": ("GRAPE", "UVA"),
    "cherry": ("CHERRY", "CEREJA"), "strawberry": ("STRAWBERRY", "MORANGO"), "walnut": ("WALNUT", "NOZ"),
    "fig": ("FIG", "FIGO"), "pingpong": ("PING PONG", "BOLA PINGUE"), "lime": ("LIME", "LIMAO"),
    "plum": ("PLUM", "AMEIXA"), "kiwi": ("KIWI", "KIWI"), "lemon": ("LEMON", "LIMAO"),
    "tennisball": ("TENNIS BALL", "BOLA TENIS"), "peach": ("PEACH", "PESSEGO"), "orange": ("ORANGE", "LARANJA"),
    "baseball": ("BASEBALL", "BEISEBOL"), "apple": ("APPLE", "MACA"), "avocado": ("AVOCADO", "ABACATE"),
    "teddy": ("TEDDY BEAR", "URSINHO"), "pear": ("PEAR", "PERA"), "tomato": ("TOMATO", "TOMATE"),
    "mango": ("MANGO", "MANGA"), "banana": ("BANANA", "BANANA"), "carrot": ("CARROT", "CENOURA"),
    "papaya": ("PAPAYA", "MAMAO"), "zucchini": ("ZUCCHINI", "ABOBRINHA"), "grapefruit": ("GRAPEFRUIT", "TORANJA"),
    "corn": ("CORN", "MILHO"), "cauliflower": ("CAULIFLOWER", "COUVE-FLOR"), "lettuce": ("LETTUCE", "ALFACE"),
    "broccoli": ("BROCCOLI", "BROCOLIS"), "eggplant": ("EGGPLANT", "BERINJELA"), "butternut": ("BUTTERNUT", "ABOBORA"),
    "cabbage": ("CABBAGE", "REPOLHO"), "coconut": ("COCONUT", "COCO"), "squash": ("SQUASH", "MORANGA"),
    "pineapple": ("PINEAPPLE", "ABACAXI"), "cantaloupe": ("CANTALOUPE", "MELAO"), "honeydew": ("HONEYDEW", "MELAO VERDE"),
    "pumpkin": ("PUMPKIN", "ABOBORA"), "watermelon": ("WATERMELON", "MELANCIA"),
}

NAMES.update({'gummybear': ('GUMMY BEAR', 'JUJUBA'), 'lego': ('LEGO BRICK', 'PECA LEGO'), 'pollypocket': ('POLLYPOCKET', 'POLLYPOCKET'), 'tamagotchi': ('TAMAGOTCHI', 'TAMAGOTCHI'), 'rubberduck': ('RUBBER DUCK', 'PATINHO'), 'stuart': ('STUART', 'STUART'), 'coxinha': ('COXINHA', 'COXINHA'), 'tinkerbell': ('TINKER BELL', 'SININHO'), 'smurf': ('SMURF', 'SMURF'), 'kirby': ('KIRBY', 'KIRBY'), 'havaianas': ('HAVAIANAS', 'HAVAIANAS'), 'babygroot': ('BABY GROOT', 'BABY GROOT'), 'shelfelf': ('SHELF ELF', 'DUENDE'), 'leprechaun': ('LEPRECHAUN', 'LEPRECHAUN'), 'gnome': ('LAWN GNOME', 'ANAO JARDIM'), 'bowlingpin': ('BOWLING PIN', 'PINO'), 'spool1': ('1KG SPOOL', '1KG BOBINA'), 'spool2': ('2 SPOOLS', '2 BOBINAS'), 'spool3': ('3 SPOOLS', '3 BOBINAS'), 'pikachu': ('PIKACHU', 'PIKACHU'), 'grogu': ('BABY YODA', 'BABY YODA'), 'chihuahua': ('CHIHUAHUA', 'CHIHUAHUA'), 'minion': ('MINION', 'MINION'), 'cat': ('HOUSE CAT', 'GATO'), 'jigglypuff': ('JIGGLYPUFF', 'JIGGLYPUFF')})

NAMES.update({obj: (data[2], data[2]) for obj, data in POKEMON.items()})

sprites.OBJECTS["tomato"] = sprites.OBJECTS.pop("bellpepper")
sprites.OBJECTS.pop("egg", None)

TEMPLATE = r'''# Copyright 2026 cptntrps
# SPDX-License-Identifier: Apache-2.0

"""
Applet: Baby Size
Summary: Baby growth in pixel art
Description: Follow pregnancy weeks with rotating pixel-art comparisons, estimated length and weight, and a countdown to the due date.
Author: cptntrps

Generated by build.py from sprites.py and pokemon.py; edit the sources, rebuild,
and run pixlet format before submitting.

Due date -> pregnancy week (due date minus 280 days = week 0). Sizes are common weekly averages:
crown-rump length to week 19, crown-heel from week 20. Every baby differs.
"""

load("encoding/base64.star", "base64")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_TZ = "UTC"
PINK = "#ff7eb6"
TRACK = "#262b31"
TICK = "#59606a"
MUTE = "#8a929b"

SIZES = __SIZES__
CHOICES = __CHOICES__
POKEMON_HEIGHTS = __POKEMON_HEIGHTS__
NAMES = __NAMES__
COLORS = __COLORS__
S1 = __S1__
S2 = __S2__

WORDS = {
    "en": {"week": "WEEK", "of": "OF 40", "size": ["AS BIG AS A", "CURRENTLY A", "SMUGGLING A", "BABY NOW:"], "left": "d", "early": "SOON", "here": "HELLO!", "demo": "DEMO"},
    "pt": {"week": "SEMANA", "of": "DE 40", "size": ["TAMANHO DE", "ESTA SEMANA:", "BEBE AGORA:", "PARECE:"], "left": "d", "early": "LOGO", "here": "OI BEBE!", "demo": "DEMO"},
}

def fmt_len(cm):
    if cm < 10:
        t = int(cm * 10 + 0.5)
        return "%d.%d" % (t // 10, t % 10), "cm"
    return "%d" % int(cm + 0.5), "cm"

def fmt_weight(g):
    if g < 1:
        return "<1g"
    if g < 1000:
        return "%dg" % int(g + 0.5)
    t = int(g / 100.0 + 0.5)
    return "%d.%dkg" % (t // 10, t % 10)

def bar(width, wk, day):
    fill = int(width * min(wk * 7 + day, 280) / 280.0)
    ticks = [int(width * 13 / 40.0), int(width * 27 / 40.0)]
    children = [render.Box(width = width, height = 2, color = TRACK)]
    children.append(render.Box(width = max(fill, 1), height = 2, color = PINK))
    for t in ticks:
        children.append(render.Padding(pad = (t, 0, 0, 0), child = render.Box(width = 1, height = 2, color = TICK if t > fill else "#ffd1e6")))
    return render.Stack(children = children)

def sprite(obj, big, bob):
    src = base64.decode(S2[obj] if big else S1[obj])
    size = 32 if big else 16
    return render.Padding(pad = (0, 1 if bob else 0, 0, 0 if bob else 1), child = render.Image(src = src, width = size, height = size))

def page_week(obj, wk, day, left, w, bob):
    num = [render.Text("%d" % wk, font = "6x13", color = "#ffffff")]
    if day:
        num.append(render.Padding(pad = (1, 0, 0, 0), child = render.Text("+%d" % day, font = "tom-thumb", color = PINK)))
    return render.Row(children = [
        render.Box(width = 32, height = 32, child = sprite(obj, True, bob)),
        render.Padding(pad = (2, 1, 0, 0), child = render.Column(
            expanded = True,
            main_align = "space_between",
            children = [
                render.Text(w["week"], font = "tom-thumb", color = MUTE),
                render.Row(cross_align = "end", children = num),
                render.Text(left, font = "tom-thumb", color = MUTE),
                bar(29, wk, day),
            ],
        )),
    ])

def page_size(obj, wk, day, length, weight, lang, bob, caption):
    name = NAMES[obj][1] if lang == "pt" else NAMES[obj][0]
    font = "tb-8" if len(name) * 5 <= 44 else "tom-thumb"  # build.py guarantees <= 11 characters
    num, unit = fmt_len(length)
    return render.Padding(pad = (1, 1, 1, 0), child = render.Column(
        expanded = True,
        main_align = "space_between",
        children = [
            render.Row(cross_align = "center", children = [
                render.Box(width = 16, height = 17, child = sprite(obj, False, bob)),
                render.Padding(pad = (1, 0, 0, 0), child = render.Column(children = [
                    render.Text(caption, font = "CG-pixel-3x5-mono", color = MUTE),
                    render.Box(width = 1, height = 2),
                    render.Text(name, font = font, color = COLORS[obj]),
                ])),
            ]),
            render.Row(expanded = True, main_align = "space_between", cross_align = "end", children = [
                render.Row(cross_align = "end", children = [
                    render.Text(num, font = "tb-8", color = "#ffffff"),
                    render.Text(unit, font = "tom-thumb", color = MUTE),
                ]),
                render.Text(fmt_weight(weight), font = "tb-8", color = "#ffffff"),
            ]),
            bar(62, wk, day),
        ],
    ))

def valid_date(value):
    if len(value) < 10 or value[4] != "-" or value[7] != "-":
        return False
    if len(value) > 10 and value[10] != "T":
        return False
    digits = value[:4] + value[5:7] + value[8:10]
    if any([digits[i] not in "0123456789" for i in range(len(digits))]):
        return False
    year, month, day = int(value[:4], 10), int(value[5:7], 10), int(value[8:10], 10)
    if year < 1 or month < 1 or month > 12:
        return False
    leap = year % 4 == 0 and (year % 100 != 0 or year % 400 == 0)
    month_days = [31, 29 if leap else 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    return day >= 1 and day <= month_days[month - 1]

def date_error(lang):
    title = "DEFINA DATA" if lang == "pt" else "SET DUE DATE"
    return render.Root(child = render.Column(
        main_align = "center",
        cross_align = "center",
        children = [
            render.Text(title, font = "CG-pixel-3x5-mono", color = PINK),
            render.Box(width = 1, height = 4),
            render.Text("YYYY-MM-DD", font = "CG-pixel-3x5-mono", color = MUTE),
        ],
    ))

def comparison_choices(wk, length):
    return [obj for obj in CHOICES["%d" % wk]
            if obj not in POKEMON_HEIGHTS or
            (wk >= 20 and length >= POKEMON_HEIGHTS[obj] * 0.9 and length <= POKEMON_HEIGHTS[obj] * 1.1)]

def main(config):
    tz = config.get("$tz", DEFAULT_TZ) or DEFAULT_TZ
    lang = config.str("lang", "en")
    w = WORDS.get(lang, WORDS["en"])
    now = time.now().in_location(tz)
    raw_due = (config.str("due_date", "") or "").strip()
    if raw_due and not valid_date(raw_due):
        return date_error(lang)
    # Compare calendar dates at UTC midnight so daylight-saving transitions do
    # not move the week/day boundary. The date picker's time component is ignored.
    date_format = "2006-01-02"
    due_text = raw_due[:10] if raw_due else now.format(date_format)
    due = time.parse_time(due_text, format = date_format, location = "UTC")
    today = time.parse_time(now.format(date_format), format = date_format, location = "UTC")
    days_left = int((due - today).hours / 24) if raw_due else 210
    gest = 280 - days_left
    wk, day = gest // 7, gest % 7
    if wk < 4:
        wk, day = 4, 0
    if days_left <= 0:
        wk, day = 40, 0
    wk = min(wk, 40)
    cur, nxt = SIZES["%d" % wk], SIZES.get("%d" % (wk + 1), SIZES["%d" % wk])
    f = 0.0 if wk in (19, 40) else day / 7.0  # no blend across the week-20 change of measure
    length = cur[0] + (nxt[0] - cur[0]) * f
    weight = cur[1] + (nxt[1] - cur[1]) * f
    picks = comparison_choices(wk, length)
    # a different object on every render: renders come 1-2 minutes apart (uinterval 1 min, ~80 s rotation),
    # and a step of 1 or 2 through >= 3 choices never lands on the same one (pixlet's random module repeated
    # the same pick on every render here)
    obj = picks[(now.unix // 60 + wk * 7) % len(picks)]
    caption = w["size"][(now.unix // 60 // 3) % len(w["size"])]
    left = w["demo"] if not raw_due else (w["here"] if days_left <= 0 else "%d%s" % (days_left, w["left"]))

    frames = []
    for i in range(70):  # ~7 s: the object large, the week
        frames.append(page_week(obj, wk, day, left, w, (i // 6) % 2 == 1))
    for i in range(80):  # ~8 s: what it is and how big
        frames.append(page_size(obj, wk, day, length, weight, lang, (i // 6) % 2 == 1, caption))
    return render.Root(delay = 100, show_full_animation = True, child = render.Animation(children = frames))

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.DateTime(id = "due_date", name = "Due date", desc = "Choose the due date (time is ignored). Leave empty for a week-10 demo.", icon = "calendar"),
            schema.Dropdown(
                id = "lang",
                name = "Language",
                desc = "Language on the panel",
                icon = "language",
                default = "en",
                options = [schema.Option(display = "English", value = "en"), schema.Option(display = "Portugues", value = "pt")],
            ),
        ],
    )
'''


def main():
    used = sorted({o for objs in CHOICES.values() for o in objs})
    missing = [o for o in used if o not in sprites.OBJECTS or o not in NAMES]
    short = [w for w, objs in CHOICES.items() if len(objs) < 3]  # >= 3 keeps consecutive renders different
    assert not short, f"weeks with fewer than 3 choices: {short}"
    too_long = [n for o in used for n in NAMES[o] if len(n) > 11]  # 11 x 4 px tom-thumb = the 44 px name column
    assert not too_long, f"names longer than 11 characters: {too_long}"
    assert not missing, f"objects without sprite or name: {missing}"
    s1 = {o: sprites.png_b64(o, 1) for o in used}
    s2 = {o: sprites.png_b64(o, 2) for o in used}
    def name_color(o):  # the sprite's most used colour that is not outline or a dark detail
        if o == "pollypocket":
            return "#ff68ad"  # keep Polly's name pink alongside her blonde hair
        from collections import Counter
        shape, pal = sprites.OBJECTS[o]
        counts = Counter(ch for row in sprites.SHAPES[shape] for ch in row if ch not in ".o")
        for ch, _ in counts.most_common():
            c = pal[ch].lstrip("#")
            if sum(int(c[i:i + 2], 16) for i in (0, 2, 4)) > 240:  # bright enough to read on black
                return pal[ch]
        return "#ffffff"
    colors = {o: name_color(o) for o in used}
    out = (TEMPLATE.replace("__SIZES__", repr({str(k): v for k, v in SIZES.items()}))
           .replace("__CHOICES__", repr({str(k): v for k, v in CHOICES.items()}))
           .replace("__POKEMON_HEIGHTS__", repr(POKEMON_HEIGHTS))
           .replace("__NAMES__", repr({o: NAMES[o] for o in used}))
           .replace("__COLORS__", repr(colors)).replace("__S1__", repr(s1)).replace("__S2__", repr(s2)))
    open(os.path.join(HERE, "baby_size.star"), "w").write(out)
    import subprocess
    subprocess.run([os.environ.get("PIXLET", "pixlet"), "format", os.path.join(HERE, "baby_size.star")], check=True)
    print(f"baby_size.star: {len(used)} objects, {len(out) // 1024} KB")


if __name__ == "__main__":
    main()
