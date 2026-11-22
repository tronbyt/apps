"""
Applet: Holiday Countdown
Summary: Countdown to upcoming holidays
Description: Shows the next upcoming holiday, cycles holidays occurring within the next 7 days,
             or celebrates the current holiday on the day of. Supports disabling individual
             holidays, pinning a single holiday, and enabling optional cultural and Canadian
             holidays. Supports 1x (64x32) and 2x (128x64) displays via canvas.is2x().
"""

load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

FRAME_DELAY_MS = 350
SUBFRAMES_PER_HOLIDAY = 12  # LCM of 4 and 6 frames (4.2 seconds per holiday when cycling)

# Rata Die (days since 0001-01-01 = 1) of Unix epoch (1970-01-01)
UNIX_EPOCH_RD = 719163

# Verified astronomical lunisolar holiday dates (2025-2040)
CHINESE_NEW_YEAR_DATES = {
    2025: (1, 29),
    2026: (2, 17),
    2027: (2, 6),
    2028: (1, 26),
    2029: (2, 13),
    2030: (2, 3),
    2031: (1, 23),
    2032: (2, 11),
    2033: (1, 31),
    2034: (2, 19),
    2035: (2, 8),
    2036: (1, 28),
    2037: (2, 15),
    2038: (2, 4),
    2039: (1, 24),
    2040: (2, 12),
}

DIWALI_DATES = {
    2025: (10, 21),
    2026: (11, 8),
    2027: (10, 29),
    2028: (10, 17),
    2029: (11, 5),
    2030: (10, 26),
    2031: (11, 14),
    2032: (11, 2),
    2033: (10, 22),
    2034: (11, 10),
    2035: (10, 30),
    2036: (10, 19),
    2037: (11, 7),
    2038: (10, 27),
    2039: (10, 17),
    2040: (11, 4),
}

HOLI_DATES = {
    2025: (3, 14),
    2026: (3, 4),
    2027: (3, 22),
    2028: (3, 11),
    2029: (3, 1),
    2030: (3, 20),
    2031: (3, 9),
    2032: (3, 27),
    2033: (3, 16),
    2034: (3, 5),
    2035: (3, 24),
    2036: (3, 12),
    2037: (3, 2),
    2038: (3, 21),
    2039: (3, 11),
    2040: (3, 29),
}

MOON_FESTIVAL_DATES = {
    2025: (10, 6),
    2026: (9, 25),
    2027: (9, 15),
    2028: (10, 3),
    2029: (9, 22),
    2030: (9, 12),
    2031: (10, 1),
    2032: (9, 19),
    2033: (9, 8),
    2034: (9, 27),
    2035: (9, 16),
    2036: (10, 4),
    2037: (9, 24),
    2038: (9, 13),
    2039: (10, 2),
    2040: (9, 20),
}

# ==============================================================================
# Date Calculation Engines (Fixed, Computus, Weekday, Hebrew, Hijri, Lunisolar)
# ==============================================================================

def gregorian_to_rd(year, month, day):
    """Return Rata Die (1 = 0001-01-01) for a Gregorian calendar date."""
    t = time.time(year = year, month = month, day = day, location = "UTC")
    return UNIX_EPOCH_RD + int(t.unix // 86400)

def get_easter(year):
    """Anonymous Gregorian Computus (Meeus/Jones/Butcher algorithm)."""
    a = year % 19
    b = year // 100
    c = year % 100
    d = b // 4
    e = b % 4
    f = (b + 8) // 25
    g = (b - f + 1) // 3
    h = (19 * a + b - d - g + 15) % 30
    i = c // 4
    k = c % 4
    l = (32 + 2 * e + 2 * i - h - k) % 7
    m = (a + 11 * h + 22 * l) // 451
    month = (h + l - 7 * m + 114) // 31
    day = ((h + l - 7 * m + 114) % 31) + 1
    return month, day

def get_weekday(year, month, day):
    """Return day of week where 0 = Sunday, 1 = Monday, ..., 6 = Saturday."""
    t = time.time(year = year, month = month, day = day, location = "UTC")
    days = t.unix // 86400
    return int((days + 4) % 7)

def get_nth_weekday(year, month, target_weekday, n):
    """Return (month, day) for the nth occurrence of target_weekday (0 = Sun .. 6 = Sat)."""
    w1 = get_weekday(year, month, 1)
    offset = (target_weekday - w1 + 7) % 7
    return month, 1 + offset + (n - 1) * 7

def get_last_weekday(year, month, target_weekday, last_day_of_month):
    """Return (month, day) for the last occurrence of target_weekday (0 = Sun .. 6 = Sat)."""
    wl = get_weekday(year, month, last_day_of_month)
    offset = (wl - target_weekday + 7) % 7
    return month, last_day_of_month - offset

def hebrew_elapsed_days(hyear):
    """Days elapsed from Hebrew epoch to 1 Tishrei before postponement rules."""
    months = (235 * hyear - 234) // 19
    parts = 12084 + 13753 * months
    day = months * 29 + parts // 25920
    if (3 * (day + 1)) % 7 < 3:
        day += 1
    return day

def hebrew_year_delay(hyear):
    """Postponement adjustment for Hebrew year length constraints."""
    ny0 = hebrew_elapsed_days(hyear - 1)
    ny1 = hebrew_elapsed_days(hyear)
    ny2 = hebrew_elapsed_days(hyear + 1)
    if ny2 - ny1 == 356:
        return 2
    if ny1 - ny0 == 382:
        return 1
    return 0

def hebrew_new_year_rd(hyear):
    """Return Rata Die of 1 Tishrei (Rosh Hashanah) for Hebrew year hyear."""
    return -1373427 + hebrew_elapsed_days(hyear) + hebrew_year_delay(hyear)

def hijri_to_rd(hyear, hmonth, hday):
    """Tabular Islamic (civil Hijri) calendar to Rata Die (within +/-1 day of sighting)."""
    return hday + 29 * (hmonth - 1) + (6 * hmonth - 1) // 11 + (hyear - 1) * 354 + (3 + 11 * hyear) // 30 + 227014

def get_holiday_candidate_rds(holiday_id, year):
    """Return list of (start_rd, target_year) candidates around Gregorian year."""
    if holiday_id == "new_years_day":
        return [(gregorian_to_rd(year, 1, 1), year)]
    elif holiday_id == "valentines_day":
        return [(gregorian_to_rd(year, 2, 14), year)]
    elif holiday_id == "st_patricks_day":
        return [(gregorian_to_rd(year, 3, 17), year)]
    elif holiday_id == "easter":
        m, d = get_easter(year)
        return [(gregorian_to_rd(year, m, d), year)]
    elif holiday_id == "mothers_day":
        m, d = get_nth_weekday(year, 5, 0, 2)  # 2nd Sunday of May
        return [(gregorian_to_rd(year, m, d), year)]
    elif holiday_id == "memorial_day":
        m, d = get_last_weekday(year, 5, 1, 31)  # Last Monday of May
        return [(gregorian_to_rd(year, m, d), year)]
    elif holiday_id == "fathers_day":
        m, d = get_nth_weekday(year, 6, 0, 3)  # 3rd Sunday of June
        return [(gregorian_to_rd(year, m, d), year)]
    elif holiday_id == "fourth_of_july":
        return [(gregorian_to_rd(year, 7, 4), year)]
    elif holiday_id == "labor_day" or holiday_id == "canadian_labour_day":
        m, d = get_nth_weekday(year, 9, 1, 1)  # 1st Monday of September
        return [(gregorian_to_rd(year, m, d), year)]
    elif holiday_id == "canadian_thanksgiving":
        m, d = get_nth_weekday(year, 10, 1, 2)  # 2nd Monday of October
        return [(gregorian_to_rd(year, m, d), year)]
    elif holiday_id == "halloween":
        return [(gregorian_to_rd(year, 10, 31), year)]
    elif holiday_id == "veterans_day":
        return [(gregorian_to_rd(year, 11, 11), year)]
    elif holiday_id == "thanksgiving":
        m, d = get_nth_weekday(year, 11, 4, 4)  # 4th Thursday of November
        return [(gregorian_to_rd(year, m, d), year)]
    elif holiday_id == "christmas":
        return [(gregorian_to_rd(year, 12, 25), year)]
    elif holiday_id == "kwanzaa":
        return [(gregorian_to_rd(year, 12, 26), year)]
    elif holiday_id == "new_years_eve":
        return [(gregorian_to_rd(year, 12, 31), year)]
    elif holiday_id == "rosh_hashanah":
        hyear = year + 3761
        return [(hebrew_new_year_rd(hyear), year)]
    elif holiday_id == "yom_kippur":
        hyear = year + 3761
        return [(hebrew_new_year_rd(hyear) + 9, year)]  # 10 Tishrei
    elif holiday_id == "hanukkah":
        hyear = year + 3761
        rh_rd = hebrew_new_year_rd(hyear)
        ydays = hebrew_new_year_rd(hyear + 1) - rh_rd
        cheshvan_days = 30 if (ydays % 10 == 5) else 29
        return [(rh_rd + 30 + cheshvan_days + 24, year)]  # 25 Kislev (Day 1)
    elif holiday_id == "eid_al_fitr" or holiday_id == "eid_al_adha":
        # Check neighboring Hijri years to handle 2 occurrences in one Gregorian year
        hmonth, hday = (10, 1) if holiday_id == "eid_al_fitr" else (12, 10)
        approx_hy = int(((year - 622) * 33) // 32)
        return [(hijri_to_rd(hy, hmonth, hday), year) for hy in range(approx_hy - 1, approx_hy + 3)]
    elif holiday_id == "chinese_new_year":
        md = CHINESE_NEW_YEAR_DATES.get(year)
        return [(gregorian_to_rd(year, md[0], md[1]), year)] if md else []
    elif holiday_id == "diwali":
        md = DIWALI_DATES.get(year)
        return [(gregorian_to_rd(year, md[0], md[1]), year)] if md else []
    elif holiday_id == "holi":
        md = HOLI_DATES.get(year)
        return [(gregorian_to_rd(year, md[0], md[1]), year)] if md else []
    elif holiday_id == "moon_festival":
        md = MOON_FESTIVAL_DATES.get(year)
        return [(gregorian_to_rd(year, md[0], md[1]), year)] if md else []
    return []

def calculate_holiday(holiday_def, now):
    """Compute days until next occurrence (or active day index for multi-day celebrations).

    Uses UTC Rata Die calendar math so DST transitions never cause off-by-one drift.
    For multi-day holidays (Hanukkah: 8 days, Kwanzaa: 7 days), checks previous and
    current year starts so celebrations crossing New Year's Day work accurately, and
    only counts down to Day 1 (never showing future days of the celebration).
    """
    today_rd = gregorian_to_rd(now.year, now.month, now.day)
    duration = holiday_def.get("duration_days", 1)

    candidates = []
    for y in (now.year - 1, now.year, now.year + 1):
        for rd, target_year in get_holiday_candidate_rds(holiday_def["id"], y):
            candidates.append((rd, target_year))

    # Check if today falls inside an active celebration window [start_rd, start_rd + duration - 1]
    for start_rd, target_year in candidates:
        if today_rd >= start_rd and today_rd < start_rd + duration:
            return {
                "id": holiday_def["id"],
                "line1": holiday_def["line1"],
                "line2": holiday_def["line2"],
                "line1_1x": holiday_def.get("line1_1x", holiday_def["line1"]),
                "line2_1x": holiday_def.get("line2_1x", holiday_def["line2"]),
                "color": holiday_def["color"],
                "sprite": holiday_def.get("sprite", holiday_def["id"]),
                "palette": holiday_def["palette"],
                "frames": holiday_def["frames"],
                "duration_days": duration,
                "celebration_day": (today_rd - start_rd) + 1,
                "days": 0,
                "year": target_year,
            }

    # Otherwise pick the nearest upcoming Day 1
    best_days = None
    best_year = now.year
    for start_rd, target_year in candidates:
        diff = start_rd - today_rd
        if diff > 0 and (best_days == None or diff < best_days):
            best_days = diff
            best_year = target_year

    if best_days == None:
        return None

    return {
        "id": holiday_def["id"],
        "line1": holiday_def["line1"],
        "line2": holiday_def["line2"],
        "line1_1x": holiday_def.get("line1_1x", holiday_def["line1"]),
        "line2_1x": holiday_def.get("line2_1x", holiday_def["line2"]),
        "color": holiday_def["color"],
        "sprite": holiday_def.get("sprite", holiday_def["id"]),
        "palette": holiday_def["palette"],
        "frames": holiday_def["frames"],
        "duration_days": duration,
        "celebration_day": 0,
        "days": best_days,
        "year": best_year,
    }

ALL_HOLIDAYS = [
    # Default US holidays (enabled by default)
    {"id": "new_years_day", "name": "New Year's Day", "line1": "New Year's", "line2": "Day", "color": "#ffd700", "palette": None, "frames": 4, "default_enabled": True, "icon": "champagneGlasses"},
    {"id": "valentines_day", "name": "Valentine's Day", "line1": "Valentine's", "line2": "Day", "line1_1x": "Valen-", "line2_1x": "tine's", "color": "#ff4d6d", "palette": "val", "frames": 4, "default_enabled": True, "icon": "heart"},
    {"id": "st_patricks_day", "name": "St. Patrick's Day", "line1": "St. Pat-", "line2": "rick's Day", "color": "#38b000", "palette": "stp", "frames": 4, "default_enabled": True, "icon": "clover"},
    {"id": "easter", "name": "Easter", "line1": "Easter", "line2": "Sunday", "color": "#f3c68f", "palette": "eas", "frames": 4, "default_enabled": True, "icon": "egg"},
    {"id": "mothers_day", "name": "Mother's Day", "line1": "Mother's", "line2": "Day", "color": "#ff70a6", "palette": "mom", "frames": 4, "default_enabled": True, "icon": "heart"},
    {"id": "memorial_day", "name": "Memorial Day", "line1": "Memorial", "line2": "Day", "color": "#4cc9f0", "palette": "usa", "frames": 4, "default_enabled": True, "icon": "flagUsa"},
    {"id": "fathers_day", "name": "Father's Day", "line1": "Father's", "line2": "Day", "color": "#4895ef", "palette": "dad", "frames": 4, "default_enabled": True, "icon": "heart"},
    {"id": "fourth_of_july", "name": "4th of July", "line1": "4th of", "line2": "July", "color": "#ef233c", "palette": "usa", "frames": 4, "default_enabled": True, "icon": "flagUsa"},
    {"id": "labor_day", "name": "Labor Day (US)", "line1": "Labor", "line2": "Day", "color": "#ffb703", "palette": "lab", "frames": 4, "default_enabled": True, "icon": "hammer"},
    {"id": "halloween", "name": "Halloween", "line1": "Happy", "line2": "Halloween", "color": "#fb8500", "palette": "hal", "frames": 4, "default_enabled": True, "icon": "ghost"},
    {"id": "veterans_day", "name": "Veterans Day", "line1": "Veterans", "line2": "Day", "color": "#ffbe0b", "palette": "vet", "frames": 4, "default_enabled": True, "icon": "flagUsa"},
    {"id": "thanksgiving", "name": "Thanksgiving (US)", "line1": "Thanks-", "line2": "giving", "color": "#d97706", "palette": "thx", "frames": 4, "default_enabled": True, "icon": "calendar"},
    {"id": "christmas", "name": "Christmas", "line1": "Merry", "line2": "Christmas", "color": "#2ec4b6", "palette": "xma", "frames": 6, "default_enabled": True, "icon": "gift"},
    {"id": "new_years_eve", "name": "New Year's Eve", "line1": "New Year's", "line2": "Eve", "color": "#f72585", "palette": "nye", "frames": 6, "default_enabled": True, "icon": "champagneGlasses"},
    # Optional cultural & Canadian holidays (disabled by default)
    {"id": "kwanzaa", "name": "Kwanzaa", "line1": "Kwanzaa", "line2": "", "color": "#2dc653", "palette": "kwa", "frames": 4, "duration_days": 7, "default_enabled": False, "icon": "fireFlameCurved"},
    {"id": "hanukkah", "name": "Hanukkah", "line1": "Hanukkah", "line2": "", "color": "#3a86ff", "palette": "han", "frames": 4, "duration_days": 8, "default_enabled": False, "icon": "hanukiah"},
    {"id": "canadian_thanksgiving", "name": "Thanksgiving (Canada)", "line1": "Thanks-", "line2": "giving", "color": "#d97706", "sprite": "thanksgiving", "palette": "thx", "frames": 4, "default_enabled": False, "icon": "calendar"},
    {"id": "canadian_labour_day", "name": "Labour Day (Canada)", "line1": "Labour", "line2": "Day", "color": "#ffb703", "sprite": "labor_day", "palette": "lab", "frames": 4, "default_enabled": False, "icon": "hammer"},
    {"id": "chinese_new_year", "name": "Chinese New Year", "line1": "Chinese", "line2": "New Year", "color": "#ff4d6d", "palette": "cny", "frames": 4, "default_enabled": False, "icon": "dragon"},
    {"id": "moon_festival", "name": "Moon Festival (Mid-Autumn)", "line1": "Moon", "line2": "Festival", "color": "#ffd166", "palette": "moo", "frames": 4, "default_enabled": False, "icon": "moon"},
    {"id": "eid_al_fitr", "name": "Eid al-Fitr", "line1": "Eid", "line2": "al-Fitr", "color": "#06d6a0", "palette": "efr", "frames": 4, "default_enabled": False, "icon": "calendar"},
    {"id": "eid_al_adha", "name": "Eid al-Adha", "line1": "Eid", "line2": "al-Adha", "color": "#06d6a0", "palette": "ead", "frames": 4, "default_enabled": False, "icon": "calendar"},
    {"id": "diwali", "name": "Diwali", "line1": "Diwali", "line2": "", "color": "#ff9e00", "palette": "diw", "frames": 4, "default_enabled": False, "icon": "fireFlameCurved"},
    {"id": "holi", "name": "Holi", "line1": "Holi", "line2": "", "color": "#ff006e", "palette": "hol", "frames": 4, "default_enabled": False, "icon": "calendar"},
    {"id": "rosh_hashanah", "name": "Rosh Hashanah", "line1": "Rosh", "line2": "Hashanah", "color": "#ffd166", "palette": "rsh", "frames": 4, "default_enabled": False, "icon": "appleWhole"},
    {"id": "yom_kippur", "name": "Yom Kippur", "line1": "Yom", "line2": "Kippur", "color": "#90e0ef", "palette": "ykp", "frames": 4, "default_enabled": False, "icon": "calendar"},
]

# ==============================================================================
# Palettes & 24x24 Pixel Art Sprites
# ==============================================================================

PALETTES = {
    "val": {"r": "#e63946", "d": "#9b111e", "p": "#ff758f", "s": "#ffb3c6", "w": "#ffffff"},
    "stp": {"g": "#1b4332", "m": "#2d6a4f", "l": "#52b788", "b": "#95d5b2", "w": "#ffffff", "y": "#ffd700"},
    "eas": {"w": "#ffffff", "s": "#e9ecef", "p": "#ff8fab", "b": "#00b4d8", "y": "#ffd166", "g": "#06d6a0", "k": "#212529", "r": "#ff4d6d", "v": "#c77dff"},
    "mom": {"p": "#f72585", "l": "#ff758f", "s": "#ffb3c6", "w": "#ffffff", "y": "#ffd166"},
    "usa": {"r": "#e63946", "w": "#ffffff", "b": "#003566", "c": "#4cc9f0", "y": "#ffd60a", "g": "#adb5bd"},
    "dad": {"r": "#d90429", "d": "#8d0801", "p": "#ef233c", "b": "#0077b6", "c": "#00b4d8", "n": "#023e8a", "w": "#ffffff", "k": "#03045e"},
    "lab": {"y": "#ffd000", "o": "#f48c06", "s": "#ffcca8", "b": "#0077b6", "n": "#023e8a", "g": "#dee2e6", "d": "#8d99ae", "h": "#8d5524", "w": "#ffffff", "k": "#212529", "r": "#ffba08"},
    "hal": {"o": "#ff6d00", "d": "#d04a00", "a": "#ff9e00", "y": "#ffea00", "w": "#ffffff", "g": "#2d6a4f", "l": "#52b788", "k": "#1a0a00"},
    "vet": {"w": "#ffffff", "s": "#dee2e6", "k": "#111111", "y": "#ffb703", "o": "#fb8500", "b": "#6f4518", "d": "#432818", "r": "#e63946", "c": "#4895ef"},
    "thx": {"b": "#8d5524", "d": "#582f0e", "l": "#b07d4f", "r": "#d62828", "o": "#f77f00", "y": "#fcbf49", "k": "#1b1b1b", "w": "#ffffff"},
    "xma": {"g": "#1b4332", "m": "#2d6a4f", "l": "#40916c", "y": "#ffea00", "o": "#ffb703", "r": "#ff1744", "b": "#00e5ff", "p": "#f72585", "w": "#ffffff", "t": "#6f4518", "s": "#cce3ff"},
    "nye": {"y": "#ffd166", "w": "#ffffff", "c": "#00f5d4", "p": "#f72585", "g": "#8d99ae", "d": "#495057", "r": "#ff0054"},
    "han": {"b": "#3a86ff", "d": "#1d3557", "c": "#90e0ef", "g": "#ffd166", "o": "#fca311", "w": "#ffffff", "y": "#ffea00"},
    "kwa": {"r": "#e63946", "g": "#2dc653", "k": "#495057", "s": "#8d99ae", "b": "#8d5524", "d": "#582f0e", "y": "#ffea00", "o": "#fb8500", "w": "#ffffff"},
    "cny": {"r": "#d90429", "d": "#8d0801", "y": "#ffd700", "o": "#fca311", "w": "#ffffff"},
    "efr": {"y": "#ffd166", "o": "#fca311", "w": "#ffffff", "g": "#06d6a0", "t": "#118ab2", "c": "#90e0ef"},
    "ead": {"g": "#06d6a0", "t": "#0a9396", "d": "#005f73", "y": "#ffd166", "o": "#ee9b00", "w": "#ffffff", "s": "#e9d8a6"},
    "diw": {"t": "#c85a17", "d": "#8d3b0b", "y": "#ffea00", "o": "#ff8800", "w": "#ffffff", "p": "#ff006e", "c": "#00f5d4", "g": "#ffd166"},
    "hol": {"p": "#ff006e", "c": "#00f5d4", "y": "#ffbe0b", "g": "#38b000", "o": "#fb5607", "v": "#9b5de5", "w": "#ffffff"},
    "rsh": {"r": "#e63946", "d": "#9b111e", "g": "#38b000", "b": "#7f4f24", "y": "#ffd166", "o": "#f77f00", "a": "#c87d1a", "w": "#ffffff"},
    "ykp": {"y": "#ffd166", "o": "#e09f3e", "d": "#9e6b24", "w": "#ffffff", "b": "#3a86ff", "c": "#90e0ef"},
    "moo": {"y": "#ffd166", "o": "#f4a261", "w": "#fff8d6", "b": "#3a506b", "c": "#5bc0be", "r": "#e63946"},
}

SPRITES = {
    # --------------------------------------------------------------------------
    # Valentine's Day: Beating ruby heart + rising mini-hearts (4 frames)
    # --------------------------------------------------------------------------
    "valentines_day_0": [
        "........................",
        "........................",
        "........................",
        "........................",
        "........................",
        ".....rrr....rrr.........",
        "....rpppr..rrrrr........",
        "...rpwppprrrrrddr.......",
        "...rppprrrrrrrrrd.......",
        "...rrrrrrrrrrrrdd.......",
        "....rrrrrrrrrrdd........",
        ".....rrrrrrrrdd.........",
        "......rrrrrrdd..........",
        ".......rrrrdd...........",
        "........rrdd.......p.p..",
        ".........dd........ppp..",
        "....................p...",
        "........................",
        "........................",
        "........................",
        ".s.s....................",
        ".sss....................",
        "..s.....................",
        "........................",
    ],
    "valentines_day_1": [
        "........................",
        "..................s.s...",
        "...................w....",
        "........................",
        "....pppp....pppp........",
        "...ppwwpp..ppprrp.......",
        "..ppwwppppppprrrrp......",
        "..ppppppppprrrrrrd......",
        "..ppprrrrrrrrrrrdd......",
        "..rrrrrrrrrrrrrrdd......",
        "...rrrrrrrrrrrrdd.......",
        "....rrrrrrrrrrdd...s.s..",
        ".....rrrrrrrrdd....sss..",
        "......rrrrrrdd......s...",
        ".......rrrrdd...........",
        "........rrdd............",
        ".........dd.............",
        "........................",
        "........................",
        "........................",
        ".s.s....................",
        ".sss....................",
        "..s.....................",
        "........................",
    ],
    "valentines_day_2": [
        "........................",
        "........................",
        "........................",
        "........................",
        "........................",
        ".....rrr....rrr.........",
        "....rpppr..rrrrr........",
        "...rpwppprrrrrddr.......",
        "...rppprrrrrrrrrd..p.p..",
        "...rrrrrrrrrrrrdd..ppp..",
        "....rrrrrrrrrrdd....p...",
        ".....rrrrrrrrdd.........",
        "......rrrrrrdd..........",
        ".......rrrrdd...........",
        "........rrdd............",
        ".........dd.............",
        "........................",
        "........................",
        "........................",
        ".s.s....................",
        ".sss....................",
        "..s.....................",
        "........................",
        "........................",
    ],
    "valentines_day_3": [
        "........................",
        "..................s.s...",
        "...................w....",
        "........................",
        "........................",
        ".....rrr....rrr....s.s..",
        "....wwppr..rrrrr...sss..",
        "...rpwppprrrrrddr...s...",
        "...rppprrrrrrrrrd.......",
        "...rrrrrrrrrrrrdd.......",
        "....rrrrrrrrrrdd........",
        ".....rrrrrrrrdd.........",
        "......rrrrrrdd..........",
        ".......rrrrdd...........",
        "........rrdd............",
        ".........dd.............",
        ".s.s....................",
        ".sss....................",
        "..s.....................",
        "........................",
        "........................",
        "........................",
        "........................",
        "........................",
    ],

    # --------------------------------------------------------------------------
    # St. Patrick's Day: 4-leaf clover with clockwise shimmer + gold sparkles (4 frames)
    # --------------------------------------------------------------------------
    "st_patricks_day_0": [
        "........................",
        "..y.....................",
        ".ywy..ggg......ggg......",
        "..y.ggmllg....gllmgg....",
        "...gmmwwblg..glbblmmg...",
        "...gmlwbblg..glbbllmg...",
        "...gmmllllg..gllllmmg...",
        "....ggmmllggggllmmgg....",
        "......ggggmggmgggg......",
        "....ggmmllggggllmmgg....",
        "...gmmllllg..gllllmmg...",
        "...gmllbblg..glbbllmg...",
        "...gmmlbblg..glbblmmg...",
        "....ggmllg.gg.gllmgg....",
        "......ggg..gg..ggg......",
        "...........gg...........",
        "............gg.......y..",
        "............mgg.........",
        ".............mgg........",
        "...y..........gg........",
        "........................",
        "........................",
        "........................",
        "........................",
    ],
    "st_patricks_day_1": [
        "........................",
        "........................",
        "......ggg......ggg...y..",
        "....ggmllg....gllmggywy.",
        "...gmmlbblg..glwwlmmgy..",
        "...gmllbblg..glbwllmg...",
        "...gmmllllg..gllllmmg...",
        "....ggmmllggggllmmgg....",
        "......ggggmggmgggg......",
        "....ggmmllggggllmmgg....",
        "...gmmllllg..gllllmmg...",
        "...gmllbblg..glbbllmg...",
        "...gmmlbblg..glbblmmg...",
        "....ggmllg.gg.gllmgg....",
        "......ggg..gg..ggg......",
        "...........gg...........",
        "............gg..........",
        "..y.........mgg.........",
        ".............mgg........",
        "..............gg........",
        "...................y....",
        "........................",
        "........................",
        "........................",
    ],
    "st_patricks_day_2": [
        "...................y....",
        "..................ywy...",
        "......ggg......ggg.y....",
        "....ggmllg....gllmgg....",
        "...gmmlbblg..glbblmmg...",
        "...gmllbblg..glbbllmg...",
        "...gmmllllg..gllllmmg...",
        "....ggmmllggggllmmgg....",
        "......ggggmggmgggg......",
        "....ggmmllggggllmmgg....",
        "...gmmllllg..gllllmmg...",
        "...gmllbblg..glwwllmg...",
        "...gmmlbblg..glbwlmmg.y.",
        "....ggmllg.gg.gllmgg....",
        "......ggg..gg..ggg......",
        "...........gg...........",
        "............gg..........",
        "............mgg.........",
        "....y........mgg........",
        "..............gg........",
        "........................",
        "........................",
        "........................",
        "........................",
    ],
    "st_patricks_day_3": [
        "........................",
        "...........y............",
        "......ggg......ggg......",
        "....ggmllg....gllmgg....",
        "...gmmlbblg..glbblmmg...",
        "...gmllbblg..glbbllmg...",
        "...gmmllllg..gllllmmg...",
        "....ggmmllggggllmmgg....",
        "......ggggmggmgggg......",
        ".y..ggmmllggggllmmgg....",
        "ywygmmllllg..gllllmmg...",
        ".y.gmlwwblg..glbbllmg...",
        "...gmmwbblg..glbblmmg...",
        "....ggmllg.gg.gllmgg....",
        "......ggg..gg..ggg......",
        "...........gg...........",
        "............gg..........",
        "............mgg.........",
        ".............mgg.....y..",
        "..............gg........",
        "........................",
        "........................",
        "........................",
        "........................",
    ],

    # --------------------------------------------------------------------------
    # Easter: Hopping bunny with ear twitch + sparkling pastel egg (4 frames)
    # --------------------------------------------------------------------------
    "easter_0": [
        "........................",
        "........................",
        "........................",
        "........................",
        "........................",
        "........................",
        "................w.......",
        "................y.......",
        "........................",
        "..ww...ww...............",
        "..wpw.wpw...............",
        "..wpw.wpw.......bbbb....",
        "..wpw.wpw......bwwwwb...",
        "..www.www.....bbppppbb..",
        "...wwwww......bbyyyybb..",
        "..wwwwwww....bbvrvrvrbb.",
        "..wkwwwkw....bbyyyyyybb.",
        ".wpwwpwwpw...bbggggggbb.",
        "..wwwwwww....bbppwwppbb.",
        "...wwwww......bbggggbb..",
        "..wwswwsw.....bbvvvvbb..",
        "...wwwww.g..g..bbbbbbg..",
        ".gggggggggggggggggggggg.",
        "........................",
    ],
    "easter_1": [
        "........................",
        "........................",
        "........................",
        "........................",
        "........................",
        "........................",
        ".ww....ww...............",
        "..wpw.wpw...............",
        "..wpw.wpw.............w.",
        "...ww.wpw.............y.",
        "..www.www...............",
        "...wwwww........bbbb....",
        "..wwwwwww......bwwwwb...",
        "..wkwwwkw.....bbvvvvbb..",
        ".wpwwpwwpw....bbyyyybb..",
        "..wwwwwww....bbrvrvrvbb.",
        "...wwwww.....bbyyyyyybb.",
        "..wwswwsw....bbggggggbb.",
        "...wwwww.....bbppwwppbb.",
        "..............bbggggbb..",
        "..............bbppppbb..",
        "...g..g..g..g..bbbbbbg..",
        ".gggggggggggggggggggggg.",
        "........................",
    ],
    "easter_2": [
        "........................",
        "........................",
        "........................",
        "........................",
        ".ww....ww...............",
        "..wpw.wpw....w..........",
        "..wpw.wpw....y..........",
        "...ww.wpw...............",
        "..www.www...............",
        "...wwwww................",
        "..wwwwwww.......bbbb....",
        "..wkwwwkw......bwwwwb...",
        ".wpwwpwwpw....bbppppbb..",
        "..wwwwwww.....bbyyyybb..",
        "...wwwww.....bbvrvrvrbb.",
        "..wwswwsw....bbyyyyyybb.",
        "...wwwww.....bbggggggbb.",
        ".............bbppwwppbb.",
        "..............bbggggbb..",
        "..............bbvvvvbb..",
        "...............bbbbbb...",
        "...g..g..g..g..g..g..g..",
        ".gggggggggggggggggggggg.",
        "........................",
    ],
    "easter_3": [
        "........................",
        "........................",
        "........................",
        "........................",
        ".....................w..",
        ".....................y..",
        "........................",
        "..ww...ww...............",
        "..wpw.wpw...............",
        "..wpw.wpw...............",
        "..wpw.wpw...............",
        "..www.www.......bbbb....",
        "...wwwww.......bwwwwb...",
        "..wwwwwww.....bbvvvvbb..",
        "..wkwwwkw.....bbyyyybb..",
        ".wpwwpwwpw...bbrvrvrvbb.",
        "..wwwwwww....bbyyyyyybb.",
        "...wwwww.....bbggggggbb.",
        "..wwswwsw....bbppwwppbb.",
        "...wwwww......bbggggbb..",
        "..............bbppppbb..",
        "...g..g..g..g..bbbbbbg..",
        ".gggggggggggggggggggggg.",
        "........................",
    ],

    # --------------------------------------------------------------------------
    # Mother's Day: Centered MOM with alternating pulsing hearts + sparkles (4 frames)
    # --------------------------------------------------------------------------
    "mothers_day_0": [
        "........................",
        "...pp.pp................",
        "..psssspp..y.....l.l....",
        "..psssssp.......lwwsl...",
        "...psssp.........lsl....",
        "....psp...........l.....",
        ".....p..................",
        "........................",
        "........................",
        "...w...w..www..w...w....",
        "...ww.ww.w...w.ww.ww....",
        ".w.w.w.w.w...w.w.w.w....",
        "...w...w.w...w.w...w....",
        "...w...w.w...w.w...w....",
        "...w...w..www..w...w....",
        "........................",
        "........................",
        "................pp.pp...",
        "....l.l........psssspp..",
        "...lwwsl.......psssssp..",
        "....lsl.........psssp...",
        ".....l...........psp....",
        "..................p.....",
        "........................",
    ],
    "mothers_day_1": [
        "........................",
        "................pp.pp...",
        "....p.p........psssspp..",
        "...psssp.......psssssp..",
        "....psp.........psssp...",
        ".....p...........psp....",
        "..................p.....",
        "........................",
        "........................",
        "...w...w..www..w...w....",
        "...ww.ww.w...w.ww.ww....",
        "...w.w.w.w...w.w.w.w....",
        "...w...w.w...w.w...w..w.",
        "...w...w.w...w.w...w....",
        "...w...w..www..w...w....",
        "........................",
        "........................",
        "...pp.pp................",
        "..psssspp........p.p....",
        "..psssssp.......psssp...",
        "...psssp....y....psp....",
        "....psp...........p.....",
        ".....p..................",
        "........................",
    ],
    "mothers_day_2": [
        "........................",
        "...pp.pp................",
        "..psssspp..w.....l.l....",
        "..psssssp.......lwwsl...",
        "...psssp.........lsl....",
        "....psp...........l.....",
        ".....p..................",
        "........................",
        "........................",
        "...w...w..www..w...w....",
        "...ww.ww.w...w.ww.ww....",
        ".y.w.w.w.w...w.w.w.w....",
        "...w...w.w...w.w...w....",
        "...w...w.w...w.w...w....",
        "...w...w..www..w...w....",
        "........................",
        "........................",
        "................pp.pp...",
        "....l.l........psssspp..",
        "...lwwsl.......psssssp..",
        "....lsl.........psssp...",
        ".....l...........psp....",
        "..................p.....",
        "........................",
    ],
    "mothers_day_3": [
        "........................",
        "................pp.pp...",
        "....p.p........psssspp..",
        "...psssp.......psssssp..",
        "....psp.........psssp...",
        ".....p...........psp....",
        "..................p.....",
        "........................",
        "........................",
        "...w...w..www..w...w....",
        "...ww.ww.w...w.ww.ww....",
        "...w.w.w.w...w.w.w.w....",
        "...w...w.w...w.w...w..y.",
        "...w...w.w...w.w...w....",
        "...w...w..www..w...w....",
        "........................",
        "........................",
        "...pp.pp................",
        "..psssspp........p.p....",
        "..psssssp.......psssp...",
        "...psssp....w....psp....",
        "....psp...........p.....",
        ".....p..................",
        "........................",
    ],

    # --------------------------------------------------------------------------
    # Memorial Day: Sine-waving US flag on flagpole + gleaming gold ribbon (4 frames)
    # --------------------------------------------------------------------------
    "memorial_day_0": [
        ".y......................",
        ".g.......brr.......rrr..",
        ".gbbb..bbwwwrr...rrwwwr.",
        ".gbwbbbwbbrrwwrrrwwrrrw.",
        ".gbbwwbbwwwwrrwwwrrwwwr.",
        ".gbwbbwwbbrrwwrrrwwrrrw.",
        ".gbbbwbbbwwwrrwwwrrwwwr.",
        ".gwwwbbwwrrrwwrrrwwrrrw.",
        ".grrrwwrrwwwrrwwwrrwwwr.",
        ".gwwwrrwwrrrwwrrrwwrrrw.",
        ".grrrwwrr...rrwwwrr...r.",
        ".g...rr.......rrr.......",
        ".g......................",
        ".g......................",
        "..........wwyy..........",
        ".........yyyyyy.........",
        "........yy....yy........",
        "........yy....yy........",
        ".........yyyyyy.........",
        "..........yyyy..........",
        ".........yy..yy.........",
        "........yy....yy........",
        ".......yy......yy.......",
        "........................",
    ],
    "memorial_day_1": [
        ".y......................",
        ".g....bbb.......rrr.....",
        ".gbbbbbwbbr...rrwwwrrr..",
        ".gbwbwwbwwwrrrwwrrrwwwr.",
        ".gbbwbbwbbrwwwrrwwwrrrw.",
        ".gbwbwbbbwwrrrwwrrrwwwr.",
        ".gbbbbwwwbrwwwrrwwwrrrw.",
        ".gwwwwrrrwwrrrwwrrrwwwr.",
        ".grrrrwwwrrwwwrrwwwrrrw.",
        ".gwwwwrrrwwrrrwwrrrwwwr.",
        ".grrrr...rrwwwrr...rrrw.",
        ".g.........rrr........r.",
        ".g......................",
        ".g......................",
        "..........yyyy..........",
        ".........yyyywy.........",
        "........yy....wy........",
        "........yy....yy........",
        ".........yyyyyy.........",
        "..........yyyy..........",
        ".........yy..yy.........",
        "........yy....yy........",
        ".......yy......yy.......",
        "........................",
    ],
    "memorial_day_2": [
        ".y......................",
        ".g...b.......rrr........",
        ".gbbbwbb...rrwwwrrr...r.",
        ".gbwbbbwbbrwwrrrwwwrrrw.",
        ".gbbwwwbbwwrrwwwrrrwwwr.",
        ".gbwbbbwwbrwwrrrwwwrrrw.",
        ".gbbbwbbbwwrrwwwrrrwwwr.",
        ".gwwwrwwbbrwwrrrwwwrrrw.",
        ".grrrwrrwwwrrwwwrrrwwwr.",
        ".gwwwrwwrrrwwrrrwwwrrrw.",
        ".grrr.rrwwwrr...rrrwwwr.",
        ".g......rrr........rrr..",
        ".g......................",
        ".g......................",
        "..........yyyy..........",
        ".........yyyyyy.........",
        "........yy....yy........",
        "........yy....yy........",
        ".........yywwyy.........",
        "..........yyyy..........",
        ".........yy..yy.........",
        "........yy....yy........",
        ".......yy......yy.......",
        "........................",
    ],
    "memorial_day_3": [
        ".y......................",
        ".g........rrr........rr.",
        ".gbbb...bbwwwrrr...rrww.",
        ".gbwbbbbbwrrrwwwrrrwwrr.",
        ".gbbwwbwwbwwwrrrwwwrrww.",
        ".gbwbbwbbwrrrwwwrrrwwrr.",
        ".gbbbwbwbbwwwrrrwwwrrww.",
        ".gwwwbbbwwrrrwwwrrrwwrr.",
        ".grrrwwwrrwwwrrrwwwrrww.",
        ".gwwwrrrwwrrrwwwrrrwwrr.",
        ".grrrwwwrr...rrrwwwrr...",
        ".g...rrr........rrr.....",
        ".g......................",
        ".g......................",
        "..........yyyy..........",
        ".........yyyyyy.........",
        "........yw....yy........",
        "........yw....yy........",
        ".........yyyyyy.........",
        "..........yyyy..........",
        ".........yy..yy.........",
        "........yy....yy........",
        ".......yy......yy.......",
        "........................",
    ],

    # --------------------------------------------------------------------------
    # Father's Day: Symmetrical heart + pointed necktie with scrolling diagonal stripes (4 frames)
    # --------------------------------------------------------------------------
    "fathers_day_0": [
        "........................",
        "........................",
        "......rrrr....rrrr......",
        "....rrppppr..rrdddrr....",
        "...rrppprrrrrrrddddrr...",
        "...rppprrwbcnnwrddddr...",
        "...rrrrrrrnnnnrrddddr...",
        "...rrrrrrrrnnrrrddddr...",
        "....rrrrrkbbcckddddr....",
        ".....rrrrkbccbkdddr.....",
        "......rrrkccbbkddr......",
        ".......rrkcbbckdr.......",
        "........rkbbcckr........",
        "........kbbccbbk........",
        "........kbccbbck........",
        "........kccbbcck........",
        "........kcbbccbk........",
        "........kbbccbbk........",
        ".........kccbbk.........",
        ".........kcbbck.........",
        "..........kbck..........",
        "...........kk...........",
        "........................",
        "........................",
    ],
    "fathers_day_1": [
        "........................",
        "........................",
        "......rrrr....rrrr......",
        "....rrppppr..rrdddrr....",
        "...rrppprrrrrrrddddrr...",
        "...rppprrwbcnnwrddddr...",
        "...rrrrrrrnnnnrrddddr...",
        "...rrrrrrrrnnrrrddddr...",
        "....rrrrrkcbbckddddr....",
        ".....rrrrkbbcckdddr.....",
        "......rrrkbccbkddr......",
        ".......rrkccbbkdr.......",
        "........rkcbbckr........",
        "........kcbbccbk........",
        "........kbbccbbk........",
        "........kbwcbbck........",
        "........kccbbcck........",
        "........kcbbccbk........",
        ".........kbccbk.........",
        ".........kccbbk.........",
        "..........kbbk..........",
        "...........kk...........",
        "........................",
        "........................",
    ],
    "fathers_day_2": [
        "........................",
        "........................",
        "......rrrr....rrrr......",
        "....rrppppr..rrdddrr....",
        "...rrppprrrrrrrddddrr...",
        "...rppprrwbcnnwrddddr...",
        "...rrrrrrrnnnnrrddddr...",
        "...rrrrrrrrnnrrrddddr...",
        "....rrrrrkccbbkddddr....",
        ".....rrrrkcbbckdddr.....",
        "......rrrkbbcckddr......",
        ".......rrkbwcbkdr.......",
        "........rkccbbkr........",
        "........kccbbcck........",
        "........kcbbccbk........",
        "........kbbccbbk........",
        "........kbccbbck........",
        "........kccbbcck........",
        ".........kbbcck.........",
        ".........kbccbk.........",
        "..........kcbk..........",
        "...........kk...........",
        "........................",
        "........................",
    ],
    "fathers_day_3": [
        "........................",
        "........................",
        "......rrrr....rrrr......",
        "....rrppppr..rrdddrr....",
        "...rrppprrrrrrrddddrr...",
        "...rppprrwbcnnwrddddr...",
        "...rrrrrrrnnnnrrddddr...",
        "...rrrrrrrrnnrrrddddr...",
        "....rrrrrkbccbkddddr....",
        ".....rrrrkccbbkdddr.....",
        "......rrrkcbbckddr......",
        ".......rrkbbcckdr.......",
        "........rkbccbkr........",
        "........kbccbbck........",
        "........kccbbcck........",
        "........kcbbccbk........",
        "........kbbccbbk........",
        "........kbccbbck........",
        ".........kcbbck.........",
        ".........kbbcck.........",
        "..........kcck..........",
        "...........kk...........",
        "........................",
        "........................",
    ],

    # --------------------------------------------------------------------------
    # 4th of July: Staggered expanding radial starburst fireworks (4 frames)
    # --------------------------------------------------------------------------
    "fourth_of_july_0": [
        "........................",
        "........................",
        "........................",
        "..................y.....",
        ".................www....",
        "................ywwwy...",
        ".................www....",
        ".......w..........y.....",
        ".......y................",
        ".......r................",
        "........................",
        "................b.......",
        ".............b...w.b....",
        ".....c........c.c.c.....",
        ".............w..........",
        ".c.......c..b.c.w.c.b...",
        "....y..............w....",
        ".......y......c.c.c.....",
        ".............b.w...b....",
        "c..y......c.....b.......",
        "........................",
        "......y.................",
        ".c.......c..............",
        ".....c..................",
    ],
    "fourth_of_july_1": [
        "........................",
        "..................r.....",
        "...............r...w.r..",
        "................y.y.y...",
        "...............w........",
        ".......r......r.y.w.y.r.",
        "......yyy............w..",
        ".....rywyr......y.y.y...",
        "......yyy......r.w...r..",
        ".......r..........r.....",
        "................b.......",
        "........................",
        "............b.......b...",
        "...............y........",
        "..................y.....",
        "........................",
        "...........b..y......b..",
        "........................",
        ".....w...........y......",
        ".....w......b.......b...",
        ".....b..........b.......",
        "........................",
        "........................",
        "........................",
    ],
    "fourth_of_july_2": [
        "..................r.....",
        "........................",
        "..............r.......r.",
        ".......r.........y......",
        "....r...w.r.........y...",
        ".....r.r.r..............",
        "....w........r..y......r",
        "...r.r.y.r.r............",
        "..........w........y....",
        ".....r.r.r....r.......r.",
        "....r.w...r.......r.....",
        ".......r................",
        "........................",
        "........................",
        "........................",
        "................w.......",
        ".....b..........w.......",
        "....www.........c.......",
        "...bwwwb................",
        "....www.................",
        ".....b..................",
        "........................",
        "........................",
        "........................",
    ],
    "fourth_of_july_3": [
        "........................",
        "........................",
        ".......r................",
        "........................",
        "...r.......r............",
        "......y...........w.....",
        ".........y........w.....",
        "..................y.....",
        "..r..y......r...........",
        "........................",
        "........y...............",
        "...r.......r............",
        ".......r................",
        "................c.......",
        ".....c.........www......",
        "..c...w.c.....cwwwc.....",
        "...b.b.b.......www......",
        "..w.............c.......",
        ".c.b.w.b.c..............",
        "........w...............",
        "...b.b.b................",
        "..c.w...c...............",
        ".....c..................",
        "........................",
    ],

    # --------------------------------------------------------------------------
    # Labor Day / Labour Day: Hard-hat worker swinging hammer with strike sparks (4 frames)
    # --------------------------------------------------------------------------
    "labor_day_0": [
        "........................",
        "........................",
        "........................",
        "................ggggg...",
        ".....yyyyyy.....ggddg...",
        "....yyyyyyyy.....ggg....",
        "...yyyyyyyyyy.....h.....",
        "..yyyyyyyyyyyy....h.....",
        "..oooooooooooo....h.....",
        "....ssssssss......h.....",
        "....skssssks......h.....",
        "....ssssssss......h.....",
        ".....sskkss.......h.....",
        "...nbbbbbbbbn.....h.....",
        "..nbbbbbbbbbbn....h.....",
        ".nbbbbbbbbbbbbn.........",
        ".nbbwbbbbbbwbbn.........",
        ".nbbybbbbbbybbn.........",
        ".nbbbbbbbbbbbbn.........",
        "..nbbbbbbbbbbn..........",
        "...nbbbbbbbbn...........",
        "........................",
        "........................",
        "........................",
    ],
    "labor_day_1": [
        "........................",
        "........................",
        "........................",
        "........................",
        ".....yyyyyy.............",
        "....yyyyyyyy.......ggg..",
        "...yyyyyyyyyy.....ggggg.",
        "..yyyyyyyyyyyy....ggddg.",
        "..oooooooooooo......h...",
        "....ssssssss.......h....",
        "....skssssks.......h....",
        "....ssssssss......h.....",
        ".....sskkss.......h.....",
        "...nbbbbbbbbn....h......",
        "..nbbbbbbbbbbn...h......",
        ".nbbbbbbbbbbbbn.........",
        ".nbbwbbbbbbwbbn.........",
        ".nbbybbbbbbybbn.........",
        ".nbbbbbbbbbbbbn.........",
        "..nbbbbbbbbbbn..........",
        "...nbbbbbbbbn...........",
        "........................",
        "........................",
        "........................",
    ],
    "labor_day_2": [
        "........................",
        "........................",
        "........................",
        "........................",
        ".....yyyyyy.............",
        "....yyyyyyyy............",
        "...yyyyyyyyyy...........",
        "..yyyyyyyyyyyy..........",
        "..oooooooooooo..........",
        "....ssssssss............",
        "....skssssks............",
        "....ssssssss............",
        ".....sskkss........gg...",
        "...nbbbbbbbbn......gg...",
        "..nbbbbbbbbbbn.hhhhdd...",
        ".nbbbbbbbbbbbbn....gg...",
        ".nbbwbbbbbbwbbn....gg...",
        ".nbbybbbbbbybbn.....y.y.",
        ".nbbbbbbbbbbbbn......w..",
        "..nbbbbbbbbbbn.....r...r",
        "...nbbbbbbbbn........y..",
        "........................",
        "........................",
        "........................",
    ],
    "labor_day_3": [
        "........................",
        "........................",
        "........................",
        "........................",
        ".....yyyyyy.............",
        "....yyyyyyyy....ggggg...",
        "...yyyyyyyyyy...ggddg...",
        "..yyyyyyyyyyyy...ggg....",
        "..oooooooooooo....h.....",
        "....ssssssss......h.....",
        "....skssssks......h.....",
        "....ssssssss......h.....",
        ".....sskkss.......h.....",
        "...nbbbbbbbbn....h......",
        "..nbbbbbbbbbbn...h......",
        ".nbbbbbbbbbbbbn.........",
        ".nbbwbbbbbbwbbn.........",
        ".nbbybbbbbbybbn.........",
        ".nbbbbbbbbbbbbn.........",
        "..nbbbbbbbbbbn..........",
        "...nbbbbbbbbn...........",
        "........................",
        "........................",
        "........................",
    ],

    # --------------------------------------------------------------------------
    # Halloween: 3D ribbed pumpkin with flickering candlelight + floating ghost (4 frames)
    # --------------------------------------------------------------------------
    "halloween_0": [
        "........................",
        ".................wwww...",
        "................wwwwww..",
        "..y.............wkwwkw..",
        "................wwwwww..",
        "................wwwwww..",
        "................w.ww.w..",
        "........................",
        "........................",
        "........................",
        "........lg..............",
        ".......lgg..............",
        "....ddooooooood.........",
        "...ddooooooooood........",
        "..doodoooooodood........",
        "..dookoooookdood........",
        "..dokkkoookkkood........",
        "..doodookooodood........",
        "..dokdokookokood........",
        "..dookkokkokdood........",
        "...ddooooooooood........",
        "....ddooooooood.........",
        "........................",
        "........................",
    ],
    "halloween_1": [
        "........................",
        "........................",
        "................wwww....",
        "...............wwwwww...",
        "...............wkwwkw...",
        "...............wwwwww...",
        "...............wwwwww...",
        "................w..ww...",
        "........................",
        "........................",
        "........lg..............",
        ".......lgg..............",
        "....ddooooooood.........",
        "...ddooooooooood........",
        "..doodoooooodood........",
        "..dooyoooooydood........",
        "..doyyyoooyyyood........",
        "..doodooaooodood........",
        "..doadoaooaoaood........",
        "..dooaaoaaoadood........",
        "...ddooooooooood........",
        "....ddooooooood.........",
        "........................",
        "........................",
    ],
    "halloween_2": [
        "........................",
        "...............wwww.....",
        "..............wwwwww....",
        "..y...........wkwwkw....",
        "..............wwwwww....",
        "..............wwwwww....",
        "..............w.ww.w....",
        "........................",
        "........................",
        "........................",
        "........lg..............",
        ".......lgg..............",
        "....ddooooooood.........",
        "...ddooooooooood........",
        "..doodoooooodood........",
        "..doowooooowdood........",
        "..dowwwooowwwood........",
        "..doodooyooodood........",
        "..doydoyooyoyood........",
        "..dooyyoyyoydood........",
        "...ddooooooooood........",
        "....ddooooooood.........",
        "........................",
        "........................",
    ],
    "halloween_3": [
        "................wwww....",
        "...............wwwwww...",
        "...............wkwwkw...",
        "...............wwwwww...",
        "...............wwwwww...",
        "................w..ww...",
        "........................",
        "........................",
        "........................",
        "........................",
        "........lg..............",
        ".......lgg..............",
        "....ddooooooood.........",
        "...ddooooooooood........",
        "..doodoooooodood........",
        "..dooyoooooydood........",
        "..doyyyoooyyyood........",
        "..doodoowooodood........",
        "..dowdowoowowood........",
        "..doowwowwowdood........",
        "...ddooooooooood........",
        "....ddooooooood.........",
        "........................",
        "........................",
    ],

    # --------------------------------------------------------------------------
    # Veterans Day: Bald eagle with wing ruffle, eye glint + honor stars (4 frames)
    # --------------------------------------------------------------------------
    "veterans_day_0": [
        "........................",
        "........................",
        "...c...............y....",
        "..................yyy...",
        "........wwww.......y....",
        ".......wwwwww...........",
        "......wwwwwwww..........",
        ".....wwwwswwwww.........",
        "....wwkwwswwwwww........",
        "...wwkkywwwwwwww.....r..",
        "..yyyyyywwwwwwsw........",
        "..oyyyywwwwwwwsw........",
        "...oo.wwwwwwwwsw........",
        "......wwwwwwwwww........",
        ".......wwwwwwww.........",
        ".......bbbbbbbb.........",
        "......bbddddbbdb........",
        ".....bbddbbbddbbb.......",
        "....bbddbbbbddbbbb......",
        "....bbddbbbbddbbbb......",
        ".....bbddddddbbbbb......",
        "......bbbbbbbbbbb.......",
        "........................",
        "........................",
    ],
    "veterans_day_1": [
        "........................",
        "........................",
        "........................",
        "..r.................s...",
        "........wwww.......sws..",
        ".......wwwwww.......s...",
        "......wwwwwwww..........",
        ".....wwwwswwwww.........",
        "....wwkwwswwwwww......c.",
        "...wwkkywwwwwwww........",
        "..yyyyyywwwwwwsw........",
        "..oyyyywwwwwwwsw........",
        "...oo.wwwwwwwwsw........",
        "......wwwwwwwwww........",
        ".......wwwwwwww.........",
        ".......bbbbbbbb.........",
        "......bbddddbbdb........",
        ".....bbdbbbbddbbbb......",
        "....bbddbbbbddbbbb......",
        "....bbdddddddbbbbb......",
        ".....bbbbbbbbbbbb.......",
        "......bbbbbbbbbb........",
        "........................",
        "........................",
    ],
    "veterans_day_2": [
        "........................",
        "...s....................",
        "..sws...................",
        "...s...............r....",
        "........wwww............",
        ".......wwwwww...........",
        "......wwwwwwww..........",
        ".....wwwwswwwww.........",
        "....wwkwwswwwwww.....y..",
        "...wwkkywwwwwwww....yyy.",
        "..yyyyyywwwwwwsw.....y..",
        "..oyyyywwwwwwwsw........",
        "...oo.wwwwwwwwsw........",
        "......wwwwwwwwww........",
        ".......wwwwwwww.........",
        ".......bbbbbbbb.........",
        "......bbddddbbdb........",
        ".....bbddbbbddbbb.......",
        "....bbddbbbbddbbbb......",
        "....bbddbbbbddbbbb......",
        ".....bbddddddbbbbb......",
        "......bbbbbbbbbbb.......",
        "........................",
        "........................",
    ],
    "veterans_day_3": [
        "........................",
        "........................",
        "..y.....................",
        ".yyy....................",
        "..y.....wwww........c...",
        ".......wwwwww...........",
        "......wwwwwwww..........",
        ".....wwwwswwwww.......s.",
        "....wwkwwswwwwww.....sws",
        "...wwkkywwwwwwww......s.",
        "..yyyyyywwwwwwsw........",
        "..oyyyywwwwwwwsw........",
        "...oo.wwwwwwwwsw........",
        "......wwwwwwwwww........",
        ".......wwwwwwww.........",
        ".......bbbbbbbb.........",
        "......bbddddbbdb........",
        ".....bbdbbbbddbbbb......",
        "....bbddbbbbddbbbb......",
        "....bbdddddddbbbbb......",
        ".....bbbbbbbbbbbb.......",
        "......bbbbbbbbbb........",
        "........................",
        "........................",
    ],

    # --------------------------------------------------------------------------
    # Thanksgiving (US & Canada): Turkey with fluttering wings + shimmering autumn fan tail (4 frames)
    # --------------------------------------------------------------------------
    "thanksgiving_0": [
        "........................",
        "........................",
        "........................",
        "........rrrrrrrr........",
        "......rrrroooorrrr......",
        "....rrroooyyyyoooorr....",
        "...rrooyyddddddyyoorr...",
        "..rrooybbddddddbbbyorr..",
        "..rroybbbddddddbbbyorr..",
        "..rroybbbdbbbbdbbbyorr..",
        "...r.bbbbbbbbbbbbbb.r...",
        "........bwkbbkwb........",
        "........bbbyybbb........",
        "........bbbyybbb........",
        ".........bbrrbb.........",
        "........lbbllbbl........",
        ".......llbbbbbbll.......",
        ".......llbbbbbbll.......",
        "........lbbddbbl........",
        ".........dddddd.........",
        "..........o..o..........",
        ".........oo..oo.........",
        "........................",
        "........................",
    ],
    "thanksgiving_1": [
        "........................",
        "........................",
        "........oooooooo........",
        "......ooooyyyyoooo......",
        "....oooyyyrrrryyyyoo....",
        "...ooyyrrddddddrryyoo...",
        "..ooyyrbbddddddbbbryoo..",
        "..ooyrbbbddddddbbbryoo..",
        "..ooyrbbbddddddbbbryoo..",
        "...o.bbbbdbbbbdbbbb.o...",
        ".........bbbbbb.........",
        "........bwkbbkwb........",
        "........bbbyybbb........",
        "........bbbyybbb........",
        ".........bbrrbb.........",
        "......l.lbbllbbl.l......",
        ".....b.llbbbbbbll.b.....",
        ".......llbbbbbbll.......",
        "........lbbddbbl........",
        ".........dddddd.........",
        "..........o..o..........",
        ".........oo..oo.........",
        "........................",
        "........................",
    ],
    "thanksgiving_2": [
        "........................",
        "........................",
        "........................",
        "........rrrrrrrr........",
        "......rrrryyyyrrrr......",
        "....rrryyyooooyyyyrr....",
        "...rryyooddddddooyyrr...",
        "..rryyobbddddddbbboyrr..",
        "..rryobbbddddddbbboyrr..",
        "..rryobbbdbbbbdbbboyrr..",
        "...r.bbbbbbbbbbbbbb.r...",
        "........bwkbbkwb........",
        "........bbbyybbb........",
        "........bbbyybbb........",
        ".........bbrrbb.........",
        "........lbbllbbl........",
        ".......llbbbbbbll.......",
        ".......llbbbbbbll.......",
        "........lbbddbbl........",
        ".........dddddd.........",
        "..........o..o..........",
        ".........oo..oo.........",
        "........................",
        "........................",
    ],
    "thanksgiving_3": [
        "........................",
        "........................",
        "........oooooooo........",
        "......oooorrrroooo......",
        "....ooorrryyyyrrrroo....",
        "...oorryyddddddyyrroo...",
        "..oorrybbddddddbbbyroo..",
        "..oorybbbddddddbbbyroo..",
        "..oorybbbddddddbbbyroo..",
        "...o.bbbbdbbbbdbbbb.o...",
        ".........bbbbbb.........",
        "........bwkbbkwb........",
        "........bbbyybbb........",
        "........bbbyybbb........",
        ".........bbrrbb.........",
        "......l.lbbllbbl.l......",
        ".....b.llbbbbbbll.b.....",
        ".......llbbbbbbll.......",
        "........lbbddbbl........",
        ".........dddddd.........",
        "..........o..o..........",
        ".........oo..oo.........",
        "........................",
        "........................",
    ],

    # --------------------------------------------------------------------------
    # Christmas: Sparkling tree with twinkling star, falling snow + presents (6 frames)
    # --------------------------------------------------------------------------
    "christmas_0": [
        "........................",
        "...s......yyy...........",
        "..........ywy...........",
        "..........yyy.......w...",
        "...........g............",
        "..........gmg...........",
        ".........gmrmg..........",
        "........gmmmmmg.........",
        ".....s.gmmmmmymg........",
        "........glmmmlg.........",
        ".......gmmbmmmmg........",
        "......gmmmmmmmpmg.....w.",
        ".....gmmmmmmmmmmmg......",
        "......glmwmmommlg.......",
        ".....gmmmmmmmmmrmg......",
        "..s.gmmmmmmmmmmmmmg.....",
        "...gmmmymmmbmmpmmmmg....",
        "..gmmommmmmmmmmmmwmmgw..",
        ".ggggggggggggggggggggg..",
        "....ryr...ttt...bpb.....",
        "....yyy...ttt...ppp.....",
        "....ryr...ttt...bpb.....",
        "........................",
        "........................",
    ],
    "christmas_1": [
        "........................",
        "...........o............",
        "..........oyo...........",
        "...........o............",
        "..s........g............",
        "..........gmg...........",
        ".........gmymg.......w..",
        "........gmmmmmg.........",
        ".......gmmmmmbmg........",
        "........glmmmlg.........",
        ".......gmmpmmmmg........",
        "....s.gmmmmmmmwmg.......",
        ".....gmmmmmmmmmmmg......",
        "......glmommrmmlg.......",
        ".....gmmmmmmmmmymg.....w",
        "....gmmmmmmmmmmmmmg.....",
        "...gmmmbmmmpmmwmmmmg....",
        "..gmmrmmmmmmmmmmmommg...",
        ".ggggggggggggggggggggg..",
        "....ryr...ttt...bpb.....",
        "....yyy...ttt...ppp...w.",
        "....ryr...ttt...bpb.....",
        "........................",
        "........................",
    ],
    "christmas_2": [
        "..s.....................",
        "...........y............",
        "..........ywy........w..",
        "...........y............",
        "...........g............",
        "..........gmg...........",
        ".........gmbmg..........",
        "...s....gmmmmmg.........",
        ".......gmmmmmpmg........",
        "........glmmmlg.....w...",
        ".......gmmwmmmmg........",
        "......gmmmmmmmomg.......",
        ".....gmmmmmmmmmmmg......",
        "......glmrmmymmlg.......",
        ".....gmmmmmmmmmbmg......",
        "....gmmmmmmmmmmmmmg.....",
        "...gmmmpmmmwmmommmmg....",
        "..gmmymmmmmmmmmmmrmmg.w.",
        ".ggggggggggggggggggggg..",
        "....ryr...ttt...bpb.....",
        "....yyy...ttt...ppp.....",
        "....ryr...ttt...bpb.....",
        "........................",
        "........................",
    ],
    "christmas_3": [
        "........................",
        "..........yoy...........",
        "..........oyo...........",
        ".s........yoy...........",
        "...........g............",
        "..........gmg.........w.",
        ".........gmpmg..........",
        "........gmmmmmg.........",
        ".......gmmmmmwmg........",
        "........glmmmlg.........",
        "..s....gmmommmmg........",
        "......gmmmmmmmrmg.......",
        ".....gmmmmmmmmmmmg...w..",
        "......glmymmbmmlg.......",
        ".....gmmmmmmmmmpmg......",
        "....gmmmmmmmmmmmmmg.....",
        "...gmmmwmmmommrmmmmg....",
        "..gmmbmmmmmmmmmmmymmg...",
        ".ggggggggggggggggggggg..",
        "....ryr...ttt...bpb.....",
        "....yyy...ttt...ppp....w",
        "....ryr...ttt...bpb.....",
        "........................",
        "........................",
    ],
    "christmas_4": [
        "........................",
        "...........y............",
        "..........ywy.........w.",
        "...........y............",
        "...........g............",
        "..........gmg...........",
        "..s......gmwmg..........",
        "........gmmmmmg.........",
        ".......gmmmmmomg.....w..",
        "........glmmmlg.........",
        ".......gmmrmmmmg........",
        "......gmmmmmmmymg.......",
        ".....gmmmmmmmmmmmg......",
        "...s..glmbmmpmmlg.......",
        ".....gmmmmmmmmmwmg......",
        "....gmmmmmmmmmmmmmg.w...",
        "...gmmmommmrmmymmmmg....",
        "..gmmpmmmmmmmmmmmbmmg...",
        ".ggggggggggggggggggggg..",
        "....ryr...ttt...bpb.....",
        "....yyy...ttt...ppp.....",
        "....ryr...ttt...bpb.....",
        "........................",
        "........................",
    ],
    "christmas_5": [
        "........................",
        "...........o............",
        "....s.....oyo...........",
        "...........o............",
        "...........g............",
        "..........gmg..........w",
        ".........gmomg..........",
        "........gmmmmmg.........",
        ".......gmmmmmrmg........",
        ".s......glmmmlg.........",
        ".......gmmymmmmg........",
        "......gmmmmmmmbmg.....w.",
        ".....gmmmmmmmmmmmg......",
        "......glmpmmwmmlg.......",
        ".....gmmmmmmmmmomg......",
        "....gmmmmmmmmmmmmmg.....",
        "..sgmmmrmmmymmbmmmmg....",
        "..gmmwmmmmmmmmmmmpmmg...",
        ".ggggggggggggggggggggg..",
        "....ryr...ttt...bpb.....",
        "....yyy...ttt...ppp.....",
        "....ryr...ttt...bpb.....",
        "........................",
        "........................",
    ],

    # --------------------------------------------------------------------------
    # New Year's Eve: Times Square ball drop to rooftop + midnight fireworks finale (6 frames)
    # --------------------------------------------------------------------------
    "new_years_eve_0": [
        "........................",
        "..........wwww..........",
        ".........wywyww.........",
        "....r....wwywyw.........",
        "...rwr....wwww..........",
        "....r......gd...........",
        "...........gd...........",
        "...........gd......c....",
        "...........gd.....cwc...",
        "...........gd......c....",
        "...........gd...........",
        "...........gd...........",
        "...........gd...........",
        "...........gd...........",
        "...........gd...........",
        "...........gd...........",
        "...........gd...........",
        "...........gd...........",
        "...........gd...........",
        ".....gggggggggggggg.....",
        "......dddddddddddd......",
        "......ddyydwwdyydd......",
        "......dddddddddddd......",
        "......dddddddddddd......",
    ],
    "new_years_eve_1": [
        "........................",
        "...........gd...........",
        "...........gd...........",
        "...........gd......y....",
        "..........wwww....ywy...",
        ".........wcycyw....y....",
        ".........wycycw.........",
        "..........wwww..........",
        "...........gd...........",
        "...........gd...........",
        "....p......gd...........",
        "...pwp.....gd...........",
        "....p......gd...........",
        "...........gd...........",
        "...........gd...........",
        "...........gd...........",
        "...........gd...........",
        "...........gd...........",
        "...........gd...........",
        ".....gggggggggggggg.....",
        "......dddddddddddd......",
        "......ddwwdyydwwdd......",
        "......dddddddddddd......",
        "......dddddddddddd......",
    ],
    "new_years_eve_2": [
        "........................",
        "...........gd...........",
        "...........gd...........",
        "...........gd...........",
        "......y....gd...........",
        "...y.c.....gd...........",
        "....cwc....gd...........",
        ".....c.y..wwww..........",
        "....y....wpwpww.........",
        ".........wwpwpw.........",
        "..........wwww.....y....",
        "...........gd...y.r.....",
        "...........gd....rwr....",
        "...........gd.....r.y...",
        "...........gd....y......",
        "...........gd...........",
        "...........gd...........",
        "...........gd...........",
        "...........gd...........",
        ".....gggggggggggggg.....",
        "......dddddddddddd......",
        "......ddyydwwdyydd......",
        "......dddddddddddd......",
        "......dddddddddddd......",
    ],
    "new_years_eve_3": [
        "........................",
        "...........gd...........",
        "...........gd...........",
        "...........gd...........",
        "...........gd.....p.....",
        "...........gd....pwp....",
        "...........gd.....p.....",
        "...........gd...........",
        "....y......gd...........",
        "...ywy.....gd...........",
        "....y.....wwww..........",
        ".........wypypw.........",
        ".........wpypyw.........",
        "..........wwww..........",
        "...........gd...........",
        "...........gd...........",
        "...........gd...........",
        "...........gd...........",
        "...........gd...........",
        ".....gggggggggggggg.....",
        "......dddddddddddd......",
        "......ddwwdyydwwdd......",
        "......dddddddddddd......",
        "......dddddddddddd......",
    ],
    "new_years_eve_4": [
        "........................",
        "...........gd...........",
        "......y....gd...........",
        "...y.w.....gd...........",
        "....www....gd.......y...",
        ".....w.y...gd....y.c....",
        "....y......gd.....cwc...",
        "...........gd......c.y..",
        "...........gd.....y.....",
        "...........gd...........",
        "...........gd...........",
        ".....y.....gd...........",
        "..y.r......gd...........",
        "...rwr....wwww..........",
        "....r.y..wcwcww.........",
        "...y.....wwcwcw.........",
        "..........wwww..........",
        "...........gd...........",
        "...........gd...........",
        ".....gggggggggggggg.....",
        "......dddddddddddd......",
        "......ddyydwwdyydd......",
        "......dddddddddddd......",
        "......dddddddddddd......",
    ],
    "new_years_eve_5": [
        "...........r............",
        ".........y.gdy..........",
        ".....w.....yd.....w.....",
        "...p...pr.ywy.r.c...c...",
        ".....p.....yd.....c.....",
        "..w.pwp.wy.gdy.w.cwc.w..",
        ".....p.....rd.....c.....",
        "...p...p...gd...c...c...",
        ".....w.....gd.....w.....",
        "...........gd...........",
        "..c........gd........p..",
        "...........gd...........",
        "...........gd...........",
        "...y.......gd.......r...",
        "...........gd...........",
        "..........wwww..........",
        ".........wwywyw.........",
        ".........wywyww.........",
        "..........wwww..........",
        ".....gggggggggggggg.....",
        "......dddddddddddd......",
        "......ddwwdyydwwdd......",
        "......dddddddddddd......",
        "......dddddddddddd......",
    ],

    # --------------------------------------------------------------------------
    # Chinese New Year: Red & gold lantern with swaying tassel + sparkles (4 frames)
    # --------------------------------------------------------------------------
    "chinese_new_year_0": [
        "........................",
        "...........yy...........",
        "...........oo...........",
        "........................",
        "...y......yyyy..........",
        "........ddyyyydd....y...",
        ".......drrryyrrrd..ywy..",
        "......drrryrryrrrd..y...",
        "......drrryrryrrrd......",
        "......drryyyyyyrrd......",
        "......drrryrryrrrd......",
        "......drrryrryrrrd......",
        ".......drrryyrrrd.......",
        "........ddyyyydd........",
        "..........yyyy..........",
        ".........oooooo.........",
        "...........y............",
        "....o......o............",
        "..........yr........y...",
        "..........ry............",
        "..........o.............",
        "........................",
        "........................",
        "........................",
    ],
    "chinese_new_year_1": [
        "........................",
        "...........yy...........",
        "...........oo...........",
        "........................",
        "..........yyyy.......y..",
        "........ddyyyydd........",
        ".......drrryyrrrd.......",
        "..y...drrryrryrrrd......",
        ".ywy..drrryyyyrrrd......",
        "..y...drryywwyyrrd......",
        "......drrryyyyrrrd......",
        "......drrryrryrrrd......",
        ".......drrryyrrrd.......",
        "........ddyyyydd........",
        "..........yyyy.....y....",
        ".........oooooo...ywy...",
        "...........y.......y....",
        "...........o............",
        "...........yr...........",
        "...y.......ry...........",
        "...........o............",
        "........................",
        "........................",
        "........................",
    ],
    "chinese_new_year_2": [
        "........................",
        "...........yy...........",
        "...........oo...........",
        "....o...................",
        "..........yyyy..........",
        "........ddyyyydd........",
        ".......drrryyrrrd.......",
        "......drrryrryrrrd......",
        "......drrryyyyrrrd......",
        "......drryywwyyrrd...y..",
        "......drrryyyyrrrd..ywy.",
        "......drrryrryrrrd...y..",
        ".......drrryyrrrd.......",
        "........ddyyyydd........",
        "..........yyyy..........",
        "..y......oooooo.........",
        "............y...........",
        "............o...........",
        "............yr..........",
        "............ry..........",
        ".............o......o...",
        "........................",
        "........................",
        "........................",
    ],
    "chinese_new_year_3": [
        "........................",
        "...........yy...........",
        "...........oo......y....",
        "..................ywy...",
        "..........yyyy.....y....",
        "........ddyyyydd........",
        ".......drrryyrrrd.......",
        "......drrryrryrrrd......",
        "......drrryrryrrrd......",
        "......drryyyyyyrrd......",
        "......drrryrryrrrd......",
        "......drrryrryrrrd......",
        "...y...drrryyrrrd.......",
        "........ddyyyydd........",
        "..........yyyy..........",
        ".........oooooo.........",
        "...........y.........y..",
        "...........o............",
        "...........yr...........",
        ".....y.....ry...........",
        "....ywy.....o...........",
        ".....y..................",
        "........................",
        "........................",
    ],

    # --------------------------------------------------------------------------
    # Eid al-Fitr: Golden crescent moon, twinkling stars + hanging fanoos lantern (4 frames)
    # --------------------------------------------------------------------------
    "eid_al_fitr_0": [
        "........................",
        "..................o.....",
        "..................o.....",
        ".................yo.....",
        "......yyy..y......o.....",
        "....yyooy.ywy.....o.....",
        "...ywoo....y......o.....",
        "..ywoo............o.....",
        "..yyo.............o.....",
        "..yyo.............o.....",
        "..yyo.............y.....",
        "..yyoo...........ygy....",
        "...yyoo.........ygtgy...",
        "....yyooy.......yyyty...",
        "......yyy.......ytwyy...",
        "................ygtgy...",
        ".................ygy....",
        "...........y......y.....",
        "........................",
        ".....c..................",
        "........................",
        "........................",
        "........................",
        "........................",
    ],
    "eid_al_fitr_1": [
        "........................",
        "..................o.....",
        ".................yo.....",
        "................ywo.....",
        "......yyy........yo.....",
        "....yyooy..y......o.....",
        "...yyoo...........o.....",
        "..yyoo............o.....",
        "..yyo.............o.....",
        "..yyo.............o.....",
        "..yyo...................",
        "..yyoo............y.....",
        "...yyoo..........ygy....",
        "....yyooy.......ygtgy...",
        "......yyy.......ytwty...",
        "................ytwty...",
        "................ygtgy...",
        "...........c.....ygy....",
        ".....c............y.....",
        "....cwc.................",
        ".....c..................",
        "........................",
        "........................",
        "........................",
    ],
    "eid_al_fitr_2": [
        "........................",
        "..................o.....",
        "..................o.....",
        ".................yo.....",
        "......yyy.........o.....",
        "....yyooy..c......o.....",
        "...ywoo...........o.....",
        "..ywoo............o.....",
        "..yyo.............o.....",
        "..yyo.............o.....",
        "..yyo...................",
        "..yyoo............y.....",
        "...yyoo..........ygy....",
        "....yyooy.......ygtgy...",
        "......yyy.......yyyty...",
        "................ytwyy...",
        "...........y....ygtgy...",
        "..........ywy....ygy....",
        "...........y......y.....",
        ".....y..................",
        "........................",
        "........................",
        "........................",
        "........................",
    ],
    "eid_al_fitr_3": [
        "........................",
        "..................o.....",
        "..................o.....",
        ".................co.....",
        "......yyy..y......o.....",
        "....yyooy.ywy.....o.....",
        "...yyoo....y......o.....",
        "..yyoo............o.....",
        "..yyo.............o.....",
        "..yyo.............o.....",
        "..yyo.............y.....",
        "..yyoo...........ygy....",
        "...yyoo.........ygtgy...",
        "....yyooy.......ytwty...",
        "......yyy.......ytwty...",
        "................ygtgy...",
        ".................ygy....",
        "...........y......y.....",
        "........................",
        ".....y..................",
        "........................",
        "........................",
        "........................",
        "........................",
    ],

    # --------------------------------------------------------------------------
    # Eid al-Adha: Emerald & gold mosque dome, minarets + glowing doorway (4 frames)
    # --------------------------------------------------------------------------
    "eid_al_adha_0": [
        "........................",
        "........................",
        "...ywy..................",
        "...................y....",
        "........................",
        ".......y...wy...........",
        "..........yo............",
        "...........yy...........",
        "...........oo...........",
        "..........gggg..........",
        ".........ggttgg.........",
        "........ggttttgg........",
        "...y...ggttttttgg...y...",
        "..ggg..gttttttttg..ggg..",
        "...s...ggddddddgg...s...",
        "...s..ssssssssssss..s...",
        "...s..ssddyyyyddss..s...",
        "...s..ssdgywwygdss..s...",
        "...s..ssdgywwygdss..s...",
        "...s..ssdgywwygdss..s...",
        "..sss.ssdgyyyygdss.sss..",
        "..ssssssssssssssssssss..",
        "........................",
        "........................",
    ],
    "eid_al_adha_1": [
        "........................",
        "........................",
        "....y...................",
        "..................ywy...",
        "........................",
        "...........yy..ywy......",
        "..........yo............",
        "...........yy...........",
        "...........oo...........",
        "..........gggg..........",
        ".........ggttgg.........",
        "........ggttttgg........",
        "...y...ggttttttgg...y...",
        "..ggg..gttttttttg..ggg..",
        "...s...ggddddddgg...s...",
        "...s..ssssssssssss..s...",
        "...s..ssddyyyyddss..s...",
        "...s..ssdgyoyygdss..s...",
        "...s..ssdgyoyygdss..s...",
        "...s..ssdgyoyygdss..s...",
        "..sss.ssdgyyyygdss.sss..",
        "..ssssssssssssssssssss..",
        "........................",
        "........................",
    ],
    "eid_al_adha_2": [
        "........................",
        "........................",
        "...ywy..................",
        "...................y....",
        "........................",
        "...........wy...y.......",
        "..........yo............",
        "...........yy...........",
        "...........oo...........",
        "..........gggg..........",
        ".........ggttgg.........",
        "........ggttttgg........",
        "...y...ggttttttgg...y...",
        "..ggg..gttttttttg..ggg..",
        "...s...ggddddddgg...s...",
        "...s..ssssssssssss..s...",
        "...s..ssddyyyyddss..s...",
        "...s..ssdgywwygdss..s...",
        "...s..ssdgywwygdss..s...",
        "...s..ssdgywwygdss..s...",
        "..sss.ssdgyyyygdss.sss..",
        "..ssssssssssssssssssss..",
        "........................",
        "........................",
    ],
    "eid_al_adha_3": [
        "........................",
        "........................",
        "....y...................",
        "..................ywy...",
        "........................",
        "......ywy..yy...........",
        "..........yo............",
        "...........yy...........",
        "...........oo...........",
        "..........gggg..........",
        ".........ggttgg.........",
        "........ggttttgg........",
        "...y...ggttttttgg...y...",
        "..ggg..gttttttttg..ggg..",
        "...s...ggddddddgg...s...",
        "...s..ssssssssssss..s...",
        "...s..ssddyyyyddss..s...",
        "...s..ssdgyoyygdss..s...",
        "...s..ssdgyoyygdss..s...",
        "...s..ssdgyoyygdss..s...",
        "..sss.ssdgyyyygdss.sss..",
        "..ssssssssssssssssssss..",
        "........................",
        "........................",
    ],

    # --------------------------------------------------------------------------
    # Diwali: Decorated clay diya lamp with dancing flame + warm sparkles (4 frames)
    # --------------------------------------------------------------------------
    "diwali_0": [
        "........................",
        "........................",
        "........................",
        "......y.................",
        "........................",
        "........................",
        "....g...................",
        "...................w....",
        "........................",
        "...........o............",
        "..........oyo...........",
        "..........oyyo..........",
        ".........oywyo....p.....",
        ".........oywyo..........",
        "..........oyo...........",
        "....gggggggwwggggggg....",
        "...ttptctptctptctpttt...",
        "....tttttttttttttttt....",
        ".....ttddddddddddtt.....",
        "......tddddddddddt......",
        "........dddddddd........",
        "........................",
        "........................",
        "........................",
    ],
    "diwali_1": [
        "........................",
        "........................",
        "........................",
        ".................y......",
        "........................",
        "....................g...",
        "........................",
        "........................",
        "........................",
        "...w........o...........",
        "...........oyo..........",
        "..........oyyo..........",
        ".....c...oywyo..........",
        ".........oywyo..........",
        "..........oyo...........",
        "....gggggggggggggggg....",
        "...ttptctptctptctpttt...",
        "....tttttttttttttttt....",
        ".....ttddddddddddtt.....",
        "......tddddddddddt......",
        "........dddddddd........",
        "........................",
        "........................",
        "........................",
    ],
    "diwali_2": [
        "........................",
        "........................",
        "............w...........",
        "........................",
        "........................",
        ".....y..................",
        "........................",
        "........................",
        "........................",
        "...........w.......g....",
        "..........oyo...........",
        ".........oywyo..........",
        ".........oywyo......y...",
        ".........oyyyo..........",
        "..........oyo...........",
        "....gggggggwwggggggg....",
        "...ttptctptctptctpttt...",
        "....tttttttttttttttt....",
        ".....ttddddddddddtt.....",
        "......tddddddddddt......",
        "........dddddddd........",
        "........................",
        "........................",
        "........................",
    ],
    "diwali_3": [
        "........................",
        "........................",
        "........................",
        "........................",
        ".......p..........w.....",
        "........................",
        "........................",
        "........................",
        "........................",
        "..........o.............",
        ".........oyo............",
        "....g....oyyo......c....",
        ".........oywyo..........",
        ".........oywyo..........",
        "..........oyo...........",
        "....gggggggggggggggg....",
        "...ttptctptctptctpttt...",
        "....tttttttttttttttt....",
        ".....ttddddddddddtt.....",
        "......tddddddddddt......",
        "........dddddddd........",
        "........................",
        "........................",
        "........................",
    ],

    # --------------------------------------------------------------------------
    # Holi: Swirling multicolor gulal powder bursts (4 frames)
    # --------------------------------------------------------------------------
    "holi_0": [
        "........................",
        "........................",
        "............g...........",
        "........................",
        "..y.....................",
        ".....oopoo...........p..",
        ".....opppo......g.......",
        ".....ppppp.....gcg......",
        ".....opppo....gcccg.....",
        ".....oopoo.....gcg......",
        "..........yywyy.g.......",
        "..........ywwwy.........",
        "..........wwwww.p.......",
        "..........ywwwypvpp.....",
        "......ooyoyywyyvvvvp....",
        "......oyyyo..pvvvvvp....",
        "......yyyyy.pvvvvvvvp...",
        "......oyyyo..pvvvvvp....",
        "......ooyoo..pvvvvvp....",
        "..............ppvpp..g..",
        "...c............p.......",
        "............p...........",
        "........................",
        "........................",
    ],
    "holi_1": [
        "........................",
        "........................",
        "........................",
        "...c...o...w............",
        ".....oopoo..........y...",
        "....opppppo.............",
        "....opppppo...ggcgg.....",
        "...opppppppo..gcccg.....",
        "....opppppo...ccccc.....",
        "....opppppo...gcccg.....",
        ".....oopoo..c.ggcgg.....",
        ".......o...cyc..........",
        "..........cyyyc.........",
        "...........cyc..........",
        "........o...c.ppvpp.....",
        ".......oyo....pvvvp.....",
        "......oyyyo...vvvvv.....",
        ".......oyo....pvvvp.....",
        "..v.....o.....ppvpp.....",
        "........................",
        "........................",
        ".............c......o...",
        "........................",
        "........................",
    ],
    "holi_2": [
        "........................",
        "........................",
        "............o...........",
        "........................",
        "................g.......",
        ".....oopoo....ggcgg.....",
        ".....opppo...gcccccg....",
        ".....ppppp...gcccccg....",
        ".....opppo..gcccccccg...",
        "..g..oopoo...gcccccg....",
        "..........yywyyccccg....",
        "..........ywwwygcgg...y.",
        "..........wwwww.g.......",
        "..........ywwwy.........",
        "......ooyoyywyy.p.......",
        "......oyyyo....pvp......",
        "......yyyyy...pvvvp.....",
        "......oyyyo....pvp......",
        "......ooyoo.....p.......",
        "........................",
        "...................c....",
        ".....p..................",
        "............y...........",
        "........................",
    ],
    "holi_3": [
        "........................",
        "........................",
        "....o........c..........",
        "........................",
        "........................",
        ".......o................",
        "......opo.....ggcgg.....",
        ".....opppo....gcccg.....",
        "......opo.....ccccc..v..",
        ".......o......gcccg.....",
        "............c.ggcgg.....",
        "...........cyc..........",
        "........o.cyyyc.........",
        "......ooyoocyc..........",
        "..y..oyyyyyoc.ppvpp.....",
        ".....oyyyyyo..pvvvp.....",
        "....oyyyyyyyo.vvvvv..p..",
        ".....oyyyyyo..pvvvp.....",
        ".....oyyyyyo..ppvpp.....",
        "......ooyoo.............",
        "........o...............",
        "...........g............",
        "........................",
        "........................",
    ],

    # --------------------------------------------------------------------------
    # Rosh Hashanah: Red apple + golden honey pot with dripping honey (4 frames)
    # --------------------------------------------------------------------------
    "rosh_hashanah_0": [
        "........................",
        "........................",
        "........................",
        "........................",
        "..........w........b....",
        "..........y.......b.....",
        ".................b......",
        "................yo......",
        "................oy......",
        ".....bgg........y.......",
        ".....bg.........o.......",
        "...rr.rr................",
        "..rwwrrrr...............",
        ".rwwrrrrrd.....yyyyy....",
        ".rwrrrrrrd....yaaaaay...",
        ".rrrrrrrrd...yaoyyyoay..",
        ".rrrrrrrrd...yaoyyyoay..",
        "..rrrrrrdd...yaoooooay..",
        "...rrr.dd.....yaaaaay...",
        "...............aaaaa....",
        "........................",
        "........................",
        "........................",
        "........................",
    ],
    "rosh_hashanah_1": [
        "........................",
        "........................",
        "........................",
        "........................",
        "...................b....",
        "..................b.....",
        "....y............b......",
        "................yo......",
        "................oy......",
        ".....bgg..............w.",
        ".....bg.........y.......",
        "...rr.rr........o.......",
        "..rwwrrrr...............",
        ".rwwrrrrrd.....yyyyy....",
        ".rwrrrrrrd....yaaaaay...",
        ".rrrrrrrrd...yaoyyyoay..",
        ".rrrrrrrrd...yaoyyyoay..",
        "..rrrrrrdd...yaoooooay..",
        "...rrr.dd.....yaaaaay...",
        "...............aaaaa....",
        "........................",
        "........................",
        "........................",
        "........................",
    ],
    "rosh_hashanah_2": [
        "........................",
        "........................",
        "........................",
        "........................",
        "..........w........b....",
        "..........y.......b.....",
        ".................b......",
        "................yo......",
        "................oy......",
        ".....bgg................",
        ".....bg.................",
        "...rr.rr........y.......",
        "..rwwrrrr.......o.......",
        ".rwwrrrrrd.....yyyyy....",
        ".rwrrrrrrd....yaaaaay...",
        ".rrrrrrrrd...yaoyyyoay..",
        ".rrrrrrrrd...yaoyyyoay..",
        "..rrrrrrdd...yaoooooay..",
        "...rrr.dd.....yaaaaay...",
        "...............aaaaa....",
        "........................",
        "........................",
        "........................",
        "........................",
    ],
    "rosh_hashanah_3": [
        "........................",
        "........................",
        "........................",
        "........................",
        "...................b....",
        "..................b.....",
        "....y............b......",
        "................yo......",
        "................oy......",
        ".....bgg..............w.",
        ".....bg.................",
        "...rr.rr................",
        "..rwwrrrr.......y.......",
        ".rwwrrrrrd.....wywyy....",
        ".rwrrrrrrd....yaaaaay...",
        ".rrrrrrrrd...yaoyyyoay..",
        ".rrrrrrrrd...yaoyyyoay..",
        "..rrrrrrdd...yaoooooay..",
        "...rrr.dd.....yaaaaay...",
        "...............aaaaa....",
        "........................",
        "........................",
        "........................",
        "........................",
    ],

    # --------------------------------------------------------------------------
    # Yom Kippur: Golden shofar with radiating sound waves + Star of David (4 frames)
    # --------------------------------------------------------------------------
    "yom_kippur_0": [
        "........................",
        "........................",
        ".....b..................",
        "...bbbbb................",
        "....bwb.................",
        "...bbbbb................",
        ".....b..................",
        "........................",
        "........................",
        "........................",
        "........................",
        ".................w......",
        "............yoo...w.....",
        "...........yyoo...w.....",
        "..........yyood..w......",
        ".........yyood..........",
        ".......yyyood...........",
        ".....yyyyood............",
        "...yyyyyood.............",
        "..yddyyood..............",
        ".ydd..ddd...............",
        "........................",
        "........................",
        "........................",
    ],
    "yom_kippur_1": [
        "........................",
        "........................",
        ".....b..................",
        "...bbbbb................",
        "....bcb.................",
        "...bbbbb................",
        ".....b..................",
        "........................",
        "........................",
        "...................w....",
        "....................w...",
        ".................y..w...",
        "............yoo...y.w...",
        "...........yyoo...y.w...",
        "..........yyood..y......",
        ".........yyood.....w....",
        ".......yyyood...........",
        ".....yyyyood............",
        "...yyyyyood.............",
        "..yddyyood..............",
        ".ydd..ddd...............",
        "........................",
        "........................",
        "........................",
    ],
    "yom_kippur_2": [
        "........................",
        "........................",
        ".....b..................",
        "...bbbbb................",
        "....bwb.................",
        "...bbbbb................",
        ".....b..................",
        ".....................y..",
        "......................y.",
        "...................c..y.",
        "....................c.y.",
        ".................y..c.y.",
        "............yoo...y.c.y.",
        "...........yyoo...y.c.y.",
        "..........yyood..y....y.",
        ".........yyood.....c....",
        ".......yyyood........y..",
        ".....yyyyood............",
        "...yyyyyood.............",
        "..yddyyood..............",
        ".ydd..ddd...............",
        "........................",
        "........................",
        "........................",
    ],
    "yom_kippur_3": [
        "........................",
        "........................",
        ".....b..................",
        "...bbbbb................",
        "....bcb.................",
        "...bbbbb................",
        ".....b..................",
        ".....................b..",
        "......................b.",
        "...................c..b.",
        "....................c.b.",
        "....................c.b.",
        "............yoo.....c.b.",
        "...........yyoo.....c.b.",
        "..........yyood.......b.",
        ".........yyood.....c....",
        ".......yyyood........b..",
        ".....yyyyood............",
        "...yyyyyood.............",
        "..yddyyood..............",
        ".ydd..ddd...............",
        "........................",
        "........................",
        "........................",
    ],

    # --------------------------------------------------------------------------
    # Moon Festival (Mid-Autumn): Full harvest moon, drifting clouds + sky lanterns (4 frames)
    # --------------------------------------------------------------------------
    "moon_festival_0": [
        "........................",
        "........................",
        "..y..................y..",
        ".ywy.......o............",
        "..y.....ooyyyoo.........",
        ".......oyyyyyyyo........",
        "......oyyyywyoyyo.......",
        "......oyywwwyyoyo.......",
        "......yyywwwyoyyy.......",
        ".....oyywwwwoooyyo......",
        "......yyyyyyyooyy.......",
        "......oyyyyyyyoooccc....",
        "......oyyyyyyyoocbbbc...",
        "...ccccoyyyyyyobbbbbbb..",
        "..ccbbbbcoyyyoo.........",
        ".bbbbbbbbb.o............",
        "....................c...",
        "...................cwc..",
        "...c...............yc...",
        ".....ry...........ryr...",
        ".....y............rwr...",
        "..................ryr...",
        "...................y....",
        "........................",
    ],
    "moon_festival_1": [
        "........................",
        ".....................y..",
        "....................ywy.",
        "..y........o.........y..",
        "........ooyyyoo.........",
        ".......oyyyyyyyo........",
        "......oyyyyyyoyyo.......",
        "......oyyyyyyyoyo.......",
        "......yyyyyyyoyyy.......",
        ".....oyyyyyyoooyyo......",
        "......yyyyyyyooyy.......",
        "......oyyyyyyyooccc.....",
        "......oyyyyyyyocbbbc....",
        "....ccccyyyyyybbbbbbb...",
        "...ccbbbbcyyyoo.........",
        "..bbbbbbbbbo............",
        "........................",
        "...c...............yy...",
        "..cwcrr...........ryr...",
        "...c.y............rwr...",
        "..................ryr...",
        "...................y....",
        "........................",
        "........................",
    ],
    "moon_festival_2": [
        "........................",
        "........................",
        ".....................y..",
        "..c........o............",
        "........ooyyyoo.........",
        ".......oyyyyyyyo........",
        "......oyyyywyoyyo.......",
        "......oyywwwyyoyo.......",
        "......yyywwwyoyyy.......",
        ".....oyywwwwoooyyo......",
        "......yyyyyyyooyy.......",
        "......oyyyyyyyoccc......",
        "......oyyyyyyycbbbc.....",
        ".....ccccyyyybbbbbbb....",
        "....ccbbbbcyyoo.........",
        "...bbbbbbbbb............",
        "...................y....",
        "..................ryr...",
        "...y..............rwr...",
        ".....ry...........ryr...",
        ".....y.............y....",
        "........................",
        "........................",
        "........................",
    ],
    "moon_festival_3": [
        "........................",
        "........................",
        "..y..................c..",
        ".ywy.......o............",
        "..y.....ooyyyoo.........",
        ".......oyyyyyyyo........",
        "......oyyyyyyoyyo.......",
        "......oyyyyyyyoyo.......",
        "......yyyyyyyoyyy.......",
        ".....oyyyyyyoooyyo......",
        "......yyyyyyyooyy.......",
        "......oyyyyyyyooccc.....",
        "......oyyyyyyyocbbbc....",
        "....ccccyyyyyybbbbbbb...",
        "...ccbbbbcyyyoo.........",
        "..bbbbbbbbbo............",
        "....................c...",
        "...................ywc..",
        "...y..............ryr...",
        "..................rwr...",
        ".....rr...........ryr...",
        ".....y.............y....",
        "........................",
        "........................",
    ],
}

def build_hanukkah_grid(frame_idx, lit_candles):
    """Build a 24x24 9-branch Hanukkiah lighting the shamash + lit_candles (1..8) right-to-left."""
    grid = [["." for _ in range(24)] for _ in range(24)]
    f = frame_idx % 4

    # Pedestal base & central stem
    for x in range(8, 16):
        grid[21][x] = "g"
    for x in range(10, 14):
        grid[20][x] = "o"
    for y in range(12, 20):
        grid[y][11] = "g"
        grid[y][12] = "o"

    # Curved golden branches for 4 left (x=4,6,8,10) and 4 right (x=14,16,18,20) candles
    branch_defs = [
        (4, 18),
        (6, 17),
        (8, 16),
        (10, 15),
        (14, 15),
        (16, 16),
        (18, 17),
        (20, 18),
    ]
    for bx, bend_y in branch_defs:
        for y in range(13, bend_y + 1):
            grid[y][bx] = "g"
        x0, x1 = (bx, 11) if bx < 12 else (12, bx)
        for x in range(x0, x1 + 1):
            grid[bend_y][x] = "o"

    # Candle holders & wax candles (shamash at x=12 is taller)
    for y in range(7, 12):
        grid[y][12] = "c"
    grid[12][12] = "g"
    for bx, _ in branch_defs:
        for y in range(9, 13):
            grid[y][bx] = "b"
        grid[13][bx] = "g"

    # Light shamash + lit_candles in traditional right-to-left order
    light_order = [20, 18, 16, 14, 10, 8, 6, 4]
    active_xs = [12] + light_order[:lit_candles]
    for idx, cx in enumerate(active_xs):
        base_y = 6 if cx == 12 else 8
        flicker = (f + idx) % 4
        grid[base_y][cx] = "w" if flicker in (0, 2) else "y"
        grid[base_y - 1][cx] = "y" if flicker in (0, 1) else "o"
        if flicker in (0, 2) and base_y - 2 >= 0:
            grid[base_y - 2][cx] = "o"

    # Subtle blue/white sparkles in upper sky
    sparks = [(2, 3), (21, 4), (3, 7), (22, 2)]
    sx, sy = sparks[f]
    grid[sy][sx] = "w" if f % 2 == 0 else "c"
    return ["".join(row) for row in grid]

def build_kwanzaa_grid(frame_idx, lit_candles):
    """Build a 24x24 7-candle Kinara (3 red, 1 black, 3 green) lighting lit_candles (1..7)."""
    grid = [["." for _ in range(24)] for _ in range(24)]
    f = frame_idx % 4

    # Woven mkeka mat strip (red / dark / green)
    for x in range(2, 22):
        grid[22][x] = "r" if x % 3 == 0 else ("g" if x % 3 == 1 else "k")

    # Carved wooden Kinara bar & pedestal
    for x in range(2, 22):
        grid[16][x] = "b"
        grid[17][x] = "d"
    for x in range(10, 14):
        grid[18][x] = "b"
        grid[19][x] = "d"
    for x in range(7, 17):
        grid[20][x] = "b"
        grid[21][x] = "d"

    # 7 candles: 3 red (left), 1 black (center, taller), 3 green (right)
    candles = [
        (3, "r", 10),
        (6, "r", 10),
        (9, "r", 10),
        (12, "k", 8),
        (15, "g", 10),
        (18, "g", 10),
        (21, "g", 10),
    ]
    for cx, col, top_y in candles:
        for y in range(top_y, 16):
            grid[y][cx] = col
            if cx == 12 and y in (9, 12, 14):
                grid[y][cx] = "s"  # Subtle highlight on black Umoja candle

    # Traditional lighting order: center black first, then alternating left-to-right
    light_order = [12, 9, 15, 6, 18, 3, 21]
    active_xs = light_order[:lit_candles]
    for idx, cx in enumerate(active_xs):
        base_y = 7 if cx == 12 else 9
        flicker = (f + idx) % 4
        grid[base_y][cx] = "w" if flicker in (0, 2) else "y"
        grid[base_y - 1][cx] = "y" if flicker in (0, 1) else "o"
        if flicker in (0, 2) and base_y - 2 >= 0:
            grid[base_y - 2][cx] = "o"

    # Subtle festive sparkle
    sparks = [(2, 4), (21, 4), (5, 3), (18, 3)]
    sx, sy = sparks[f]
    grid[sy][sx] = "y" if f % 2 == 0 else "w"
    return ["".join(row) for row in grid]

def render_sprite(grid, palette, pixel_size = 1):
    """Render a 24x24 ASCII pixel grid using horizontal run-length encoding."""
    rows = []
    for line in grid:
        boxes = []
        cur_c = None
        count = 0
        for i in range(len(line)):
            col = palette.get(line[i], None)
            if col == cur_c:
                count += 1
            else:
                if count > 0:
                    boxes.append(render.Box(width = count * pixel_size, height = pixel_size, color = cur_c or "#00000000"))
                cur_c = col
                count = 1
        if count > 0:
            boxes.append(render.Box(width = count * pixel_size, height = pixel_size, color = cur_c or "#00000000"))
        rows.append(render.Row(children = boxes))
    return render.Column(children = rows)

def render_compact_text(content, color, font, compact_spaces = False):
    """Render text, optionally tightening spaces to 2px in 1x tom-thumb to prevent clipping."""
    if not compact_spaces or " " not in content:
        return render.Text(content = content, color = color, font = font)
    parts = content.split(" ")
    children = []
    for i, part in enumerate(parts):
        if i > 0:
            children.append(render.Box(width = 1, height = 1))
        if part != "":
            children.append(render.Text(content = part, color = color, font = font))
    return render.Row(cross_align = "center", children = children)

def render_holiday_icon(holiday, frame_idx, is_2x):
    pixel_size = 2 if is_2x else 1
    holiday_id = holiday["id"]

    # New Year's Day: dynamic target year with 4-frame shimmering confetti
    if holiday_id == "new_years_day":
        year_str = str(holiday["year"])
        f = frame_idx % 4
        spark_rows_top = ["* + *", "+ * +", "* . *", ". + ."]
        spark_rows_bot = ["+ * +", "* . *", ". + .", "* + *"]
        top_cols = ["#ffd700", "#00f5d4", "#f72585", "#ffffff"]
        bot_cols = ["#00f5d4", "#f72585", "#ffd700", "#00f5d4"]
        year_cols = ["#ffffff", "#fff3b0", "#ffffff", "#ffd700"]

        year_font = "10x20" if is_2x else "tb-8"
        spark_font = "5x8" if is_2x else "CG-pixel-3x5-mono"
        icon_width = 48 if is_2x else 24
        icon_height = 64 if is_2x else 32

        return render.Box(
            width = icon_width,
            height = icon_height,
            child = render.Column(
                main_align = "space_evenly",
                cross_align = "center",
                expanded = True,
                children = [
                    render.Text(spark_rows_top[f], color = top_cols[f], font = spark_font),
                    render.Box(
                        width = icon_width,
                        height = 22 if is_2x else 11,
                        color = "#2a1f00" if f % 2 == 0 else "#1a1400",
                        child = render.Text(year_str, color = year_cols[f], font = year_font),
                    ),
                    render.Text(spark_rows_bot[f], color = bot_cols[f], font = spark_font),
                ],
            ),
        )

    # Dynamic multi-day candle animations (Hanukkah & Kwanzaa)
    if holiday_id == "hanukkah":
        lit = holiday["celebration_day"] if holiday["days"] == 0 and holiday["celebration_day"] > 0 else 8
        return render_sprite(build_hanukkah_grid(frame_idx, lit), PALETTES["han"], pixel_size)

    if holiday_id == "kwanzaa":
        lit = holiday["celebration_day"] if holiday["days"] == 0 and holiday["celebration_day"] > 0 else 7
        return render_sprite(build_kwanzaa_grid(frame_idx, lit), PALETTES["kwa"], pixel_size)

    sprite_key = "%s_%d" % (holiday["sprite"], frame_idx % holiday["frames"])
    return render_sprite(SPRITES[sprite_key], PALETTES[holiday["palette"]], pixel_size)

# ==============================================================================
# UI Card Renderer
# ==============================================================================

def render_holiday_card_frame(holiday, frame_idx, is_2x):
    days = holiday["days"]
    line1 = holiday["line1"] if is_2x else holiday["line1_1x"]
    line2 = holiday["line2"] if is_2x else holiday["line2_1x"]
    title_color = holiday["color"]
    duration = holiday.get("duration_days", 1)
    celeb_day = holiday.get("celebration_day", 0)

    if days == 0:
        if duration > 1 and celeb_day > 0:
            greeting_lines = ["Happy", line1, "Day %d of %d" % (celeb_day, duration)]
        elif line1 in ("Happy", "Merry"):
            greeting_lines = [line1, line2] if line2 != "" else [line1]
        else:
            greeting_lines = ["Happy"]
            if line1 != "":
                greeting_lines.append(line1)
            if line2 != "":
                greeting_lines.append(line2)
        badge_color = "#ffffff"
        badge_bg = "#d90429"
    elif days == 1:
        greeting_lines = ["TOMORROW"]
        badge_color = "#ffb703"
        badge_bg = "#3a2500"
    else:
        greeting_lines = ["in %d days" % days if is_2x else "%d days" % days]
        badge_color = "#00f5d4"
        badge_bg = "#003530"

    title_font = "6x13" if is_2x else "tom-thumb"
    if days == 0:
        badge_font = "6x13" if is_2x else "tom-thumb"
    else:
        badge_font = "5x8" if is_2x else "CG-pixel-3x5-mono"

    content_width = 76 if is_2x else 38
    card_width = 128 if is_2x else 64
    card_height = 64 if is_2x else 32
    icon_pad = (2, 0, 2, 0) if is_2x else (1, 0, 1, 0)

    title_elements = []
    if days != 0:
        title_elements = [
            render_compact_text(line1, title_color, title_font, compact_spaces = (not is_2x and len(line1) > 9)),
        ]
        if line2 != "":
            title_elements.append(
                render_compact_text(line2, title_color, title_font, compact_spaces = (not is_2x and len(line2) > 9)),
            )

    content_children = []
    if title_elements:
        content_children.append(render.Column(children = title_elements))
        content_children.append(render.Box(width = content_width, height = 4 if is_2x else 2))

    badge_rows = []
    for i, greeting_line in enumerate(greeting_lines):
        if i > 0:
            badge_rows.append(render.Box(width = 1, height = 2 if is_2x else 1))
        badge_rows.append(
            render_compact_text(
                greeting_line,
                badge_color,
                badge_font,
                compact_spaces = (not is_2x and days == 0 and len(greeting_line) > 8),
            ),
        )

    badge_child = render.Column(
        main_align = "center",
        cross_align = "start",
        children = badge_rows,
    )
    content_children.append(render.Box(
        color = badge_bg,
        padding = 2 if is_2x else 1,
        child = badge_child,
    ))

    return render.Box(
        width = card_width,
        height = card_height,
        child = render.Row(
            expanded = True,
            main_align = "start",
            cross_align = "center",
            children = [
                render.Padding(
                    pad = icon_pad,
                    child = render_holiday_icon(holiday, frame_idx, is_2x),
                ),
                render.Column(
                    main_align = "center",
                    cross_align = "start",
                    children = content_children,
                ),
            ],
        ),
    )

# ==============================================================================
# Main Entry Point
# ==============================================================================

def main(config):
    timezone = time.tz()
    is_2x = canvas.is2x()
    now = time.now().in_location(timezone)

    display_holiday = config.get("display_holiday")
    if display_holiday and display_holiday != "auto":
        # Pinning/previewing works even for holidays that are currently toggled off
        selected = [h for h in ALL_HOLIDAYS if h["id"] == display_holiday]
        if len(selected) > 0:
            calc = calculate_holiday(selected[0], now)
            if calc != None:
                display_list = [calc]
            else:
                return []
        else:
            return []
    else:
        enabled_defs = [
            h
            for h in ALL_HOLIDAYS
            if config.bool("enable_" + h["id"], h["default_enabled"])
        ]
        if len(enabled_defs) == 0:
            return []

        computed = []
        for h in enabled_defs:
            calc = calculate_holiday(h, now)
            if calc != None:
                computed.append(calc)
        if len(computed) == 0:
            return []

        computed = sorted(computed, key = lambda x: x["days"])

        todays_holidays = [h for h in computed if h["days"] == 0]
        if len(todays_holidays) > 0:
            display_list = todays_holidays
        else:
            next_7_days = [h for h in computed if h["days"] > 0 and h["days"] <= 7]
            if len(next_7_days) > 0:
                display_list = next_7_days
            else:
                display_list = [computed[0]]

    frames = []
    if len(display_list) == 1:
        h = display_list[0]
        for f in range(h["frames"]):
            frames.append(render_holiday_card_frame(h, f, is_2x))
    else:
        for h in display_list:
            for f in range(SUBFRAMES_PER_HOLIDAY):
                frames.append(render_holiday_card_frame(h, f, is_2x))

    return render.Root(
        delay = FRAME_DELAY_MS,
        child = render.Animation(children = frames),
    )

def get_schema():
    holiday_options = [schema.Option(display = "Auto (Next Upcoming)", value = "auto")]
    toggle_fields = []
    for h in ALL_HOLIDAYS:
        holiday_options.append(schema.Option(display = h["name"], value = h["id"]))
        toggle_fields.append(
            schema.Toggle(
                id = "enable_" + h["id"],
                name = h["name"],
                desc = "Include %s in the holiday countdown" % h["name"],
                icon = h["icon"],
                default = h["default_enabled"],
            ),
        )

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "display_holiday",
                name = "Display Holiday",
                desc = "Cycle upcoming holidays automatically, or pin/preview a single holiday",
                icon = "thumbtack",
                default = "auto",
                options = holiday_options,
            ),
        ] + toggle_fields,
    )
