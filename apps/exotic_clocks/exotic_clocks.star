"""
Applet: Exotic Clocks
Summary: Weird Clocks
Description: Weird but stylish way to tell the time.
Author: vzsky
"""

load("encoding/json.star", "json")
load("images/blank.png", BLANK_ASSET = "file")
load("images/colon.png", COLON_ASSET = "file")
load("images/kw_1.png", KW_1_ASSET = "file")
load("images/kw_2.png", KW_2_ASSET = "file")
load("images/kw_3.png", KW_3_ASSET = "file")
load("images/kw_4.png", KW_4_ASSET = "file")
load("images/kw_5.png", KW_5_ASSET = "file")
load("images/kw_6.png", KW_6_ASSET = "file")
load("images/kw_7.png", KW_7_ASSET = "file")
load("images/kw_8.png", KW_8_ASSET = "file")
load("images/kw_9.png", KW_9_ASSET = "file")
load("images/kw_a.png", KW_A_ASSET = "file")
load("images/kw_b.png", KW_B_ASSET = "file")
load("images/kw_c.png", KW_C_ASSET = "file")
load("images/kw_hour.png", KW_HOUR_ASSET = "file")
load("images/kw_min.png", KW_MIN_ASSET = "file")
load("images/kw_s1.png", KW_S1_ASSET = "file")
load("images/kw_s2.png", KW_S2_ASSET = "file")
load("images/kw_s3.png", KW_S3_ASSET = "file")
load("images/kw_s4.png", KW_S4_ASSET = "file")
load("images/kw_s5.png", KW_S5_ASSET = "file")
load("images/kw_s6.png", KW_S6_ASSET = "file")
load("images/kw_s7.png", KW_S7_ASSET = "file")
load("images/kw_s8.png", KW_S8_ASSET = "file")
load("images/kw_s9.png", KW_S9_ASSET = "file")
load("images/kw_sa.png", KW_SA_ASSET = "file")
load("images/td_egt.png", TD_EGT_ASSET = "file")
load("images/td_fiv.png", TD_FIV_ASSET = "file")
load("images/td_fou.png", TD_FOU_ASSET = "file")
load("images/td_nne.png", TD_NNE_ASSET = "file")
load("images/td_one.png", TD_ONE_ASSET = "file")
load("images/td_sev.png", TD_SEV_ASSET = "file")
load("images/td_six.png", TD_SIX_ASSET = "file")
load("images/td_thr.png", TD_THR_ASSET = "file")
load("images/td_two.png", TD_TWO_ASSET = "file")
load("images/td_zro.png", TD_ZRO_ASSET = "file")
load("images/tw_1.png", TW_1_ASSET = "file")
load("images/tw_2.png", TW_2_ASSET = "file")
load("images/tw_3.png", TW_3_ASSET = "file")
load("images/tw_4.png", TW_4_ASSET = "file")
load("images/tw_5.png", TW_5_ASSET = "file")
load("images/tw_6.png", TW_6_ASSET = "file")
load("images/tw_7.png", TW_7_ASSET = "file")
load("images/tw_8.png", TW_8_ASSET = "file")
load("images/tw_9.png", TW_9_ASSET = "file")
load("images/tw_a0.png", TW_A0_ASSET = "file")
load("images/tw_a1.png", TW_A1_ASSET = "file")
load("images/tw_a2.png", TW_A2_ASSET = "file")
load("images/tw_a3.png", TW_A3_ASSET = "file")
load("images/tw_a4.png", TW_A4_ASSET = "file")
load("images/tw_a5.png", TW_A5_ASSET = "file")
load("images/tw_a6.png", TW_A6_ASSET = "file")
load("images/tw_a7.png", TW_A7_ASSET = "file")
load("images/tw_a8.png", TW_A8_ASSET = "file")
load("images/tw_a9.png", TW_A9_ASSET = "file")
load("images/tw_aa.png", TW_AA_ASSET = "file")
load("images/tw_ab.png", TW_AB_ASSET = "file")
load("images/tw_half.png", TW_HALF_ASSET = "file")
load("images/tw_natee.png", TW_NATEE_ASSET = "file")
load("images/tw_neung.png", TW_NEUNG_ASSET = "file")
load("images/tw_p0.png", TW_P0_ASSET = "file")
load("images/tw_p1.png", TW_P1_ASSET = "file")
load("images/tw_p2.png", TW_P2_ASSET = "file")
load("images/tw_p3.png", TW_P3_ASSET = "file")
load("images/tw_p4.png", TW_P4_ASSET = "file")
load("images/tw_p5.png", TW_P5_ASSET = "file")
load("images/tw_p6.png", TW_P6_ASSET = "file")
load("images/tw_p7.png", TW_P7_ASSET = "file")
load("images/tw_p8.png", TW_P8_ASSET = "file")
load("images/tw_p9.png", TW_P9_ASSET = "file")
load("images/tw_pa.png", TW_PA_ASSET = "file")
load("images/tw_pb.png", TW_PB_ASSET = "file")
load("images/tw_sib.png", TW_SIB_ASSET = "file")
load("images/tw_yee.png", TW_YEE_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

BLANK = BLANK_ASSET.readall()
COLON = COLON_ASSET.readall()
KW_1 = KW_1_ASSET.readall()
KW_2 = KW_2_ASSET.readall()
KW_3 = KW_3_ASSET.readall()
KW_4 = KW_4_ASSET.readall()
KW_5 = KW_5_ASSET.readall()
KW_6 = KW_6_ASSET.readall()
KW_7 = KW_7_ASSET.readall()
KW_8 = KW_8_ASSET.readall()
KW_9 = KW_9_ASSET.readall()
KW_A = KW_A_ASSET.readall()
KW_B = KW_B_ASSET.readall()
KW_C = KW_C_ASSET.readall()
KW_HOUR = KW_HOUR_ASSET.readall()
KW_MIN = KW_MIN_ASSET.readall()
KW_S1 = KW_S1_ASSET.readall()
KW_S2 = KW_S2_ASSET.readall()
KW_S3 = KW_S3_ASSET.readall()
KW_S4 = KW_S4_ASSET.readall()
KW_S5 = KW_S5_ASSET.readall()
KW_S6 = KW_S6_ASSET.readall()
KW_S7 = KW_S7_ASSET.readall()
KW_S8 = KW_S8_ASSET.readall()
KW_S9 = KW_S9_ASSET.readall()
KW_SA = KW_SA_ASSET.readall()
TD_EGT = TD_EGT_ASSET.readall()
TD_FIV = TD_FIV_ASSET.readall()
TD_FOU = TD_FOU_ASSET.readall()
TD_NNE = TD_NNE_ASSET.readall()
TD_ONE = TD_ONE_ASSET.readall()
TD_SEV = TD_SEV_ASSET.readall()
TD_SIX = TD_SIX_ASSET.readall()
TD_THR = TD_THR_ASSET.readall()
TD_TWO = TD_TWO_ASSET.readall()
TD_ZRO = TD_ZRO_ASSET.readall()
TW_1 = TW_1_ASSET.readall()
TW_2 = TW_2_ASSET.readall()
TW_3 = TW_3_ASSET.readall()
TW_4 = TW_4_ASSET.readall()
TW_5 = TW_5_ASSET.readall()
TW_6 = TW_6_ASSET.readall()
TW_7 = TW_7_ASSET.readall()
TW_8 = TW_8_ASSET.readall()
TW_9 = TW_9_ASSET.readall()
TW_A0 = TW_A0_ASSET.readall()
TW_A1 = TW_A1_ASSET.readall()
TW_A2 = TW_A2_ASSET.readall()
TW_A3 = TW_A3_ASSET.readall()
TW_A4 = TW_A4_ASSET.readall()
TW_A5 = TW_A5_ASSET.readall()
TW_A6 = TW_A6_ASSET.readall()
TW_A7 = TW_A7_ASSET.readall()
TW_A8 = TW_A8_ASSET.readall()
TW_A9 = TW_A9_ASSET.readall()
TW_AA = TW_AA_ASSET.readall()
TW_AB = TW_AB_ASSET.readall()
TW_HALF = TW_HALF_ASSET.readall()
TW_NATEE = TW_NATEE_ASSET.readall()
TW_NEUNG = TW_NEUNG_ASSET.readall()
TW_P0 = TW_P0_ASSET.readall()
TW_P1 = TW_P1_ASSET.readall()
TW_P2 = TW_P2_ASSET.readall()
TW_P3 = TW_P3_ASSET.readall()
TW_P4 = TW_P4_ASSET.readall()
TW_P5 = TW_P5_ASSET.readall()
TW_P6 = TW_P6_ASSET.readall()
TW_P7 = TW_P7_ASSET.readall()
TW_P8 = TW_P8_ASSET.readall()
TW_P9 = TW_P9_ASSET.readall()
TW_PA = TW_PA_ASSET.readall()
TW_PB = TW_PB_ASSET.readall()
TW_SIB = TW_SIB_ASSET.readall()
TW_YEE = TW_YEE_ASSET.readall()

#############################
# THAI NUMBERS

TD_DIGITS = [TD_ZRO, TD_ONE, TD_TWO, TD_THR, TD_FOU, TD_FIV, TD_SIX, TD_SEV, TD_EGT, TD_NNE]

#############################
# THAI WORDS

TW_HOURS = [TW_A0, TW_A1, TW_A2, TW_A3, TW_A4, TW_A5, TW_A6, TW_A7, TW_A8, TW_A9, TW_AA, TW_AB, TW_P0, TW_P1, TW_P2, TW_P3, TW_P4, TW_P5, TW_P6, TW_P7, TW_P8, TW_P9, TW_PA, TW_PB]

TW_DIGITS = [TW_NEUNG, TW_1, TW_2, TW_3, TW_4, TW_5, TW_6, TW_7, TW_8, TW_9, TW_SIB]
#############################
# KOREAN WORDS

# S for Sino Korean

KW_HOURS = [KW_1, KW_2, KW_3, KW_4, KW_5, KW_6, KW_7, KW_8, KW_9, KW_A, KW_B, KW_C]
KW_MINUTES = [KW_S1, KW_S2, KW_S3, KW_S4, KW_S5, KW_S6, KW_S7, KW_S8, KW_S9, KW_SA]
#############################

DEFAULT_LOCATION = {
    "lat": 13.7563,
    "lng": 100.5018,
    "locality": "Bangkok",
}
DEFAULT_TIMEZONE = "Asia/Bangkok"

def main(config):
    location = config.get("location")
    loc = json.decode(location) if location else DEFAULT_LOCATION
    timezone = loc.get("timezone", time.tz())

    current_time = time.now().in_location(timezone)

    clock = render_thai_clock(current_time)
    if config.get("clocktype") == "roman":
        clock = render_roman_clock(current_time)
    if config.get("clocktype") == "thaiwords":
        clock = render_thaiwords_clock(current_time)
    if config.get("clocktype") == "koreanwords":
        clock = render_korean_clock(current_time)

    return render.Root(
        delay = 500,
        child = clock,
    )

def centered_row(images):
    return render.Row(
        expanded = True,
        main_align = "center",
        cross_align = "center",
        children = [render.Image(img) for img in images],
    )

def render_thai_time(hh, mm, separator):
    return render.Box(
        child = render.Row(
            expanded = True,
            main_align = "center",
            cross_align = "center",
            children = [
                render.Image(TD_DIGITS[int(hh[0])]),
                render.Image(TD_DIGITS[int(hh[1])]),
                render.Image(src = separator),
                render.Image(TD_DIGITS[int(mm[0])]),
                render.Image(TD_DIGITS[int(mm[1])]),
            ],
        ),
    )

def render_thai_clock(current_time):
    hh = current_time.format("15")
    mm = current_time.format("04")
    return render.Animation(
        children = [
            render_thai_time(hh, mm, COLON),
            render_thai_time(hh, mm, BLANK),
        ],
    )

def img_of_koreanwords_minutes(minutes):
    if minutes == 0:
        return []
    ten = minutes // 10
    unit = minutes % 10
    img_ten = KW_MINUTES[ten - 1]
    img_unit = KW_MINUTES[unit - 1]
    if unit == 0:
        return [img_ten, KW_MINUTES[9], KW_MIN]
    if ten == 0:
        return [img_unit, KW_MIN]
    if ten == 1:
        return [KW_MINUTES[9], img_unit, KW_MIN]
    return [img_ten, KW_MINUTES[9], img_unit, KW_MIN]

def render_koreanwords_time(hours, minutes):
    if minutes == 0:
        return [centered_row([KW_HOURS[hours - 1], KW_HOUR])]
    return [centered_row([KW_HOURS[hours - 1], KW_HOUR]), centered_row(img_of_koreanwords_minutes(minutes))]

def render_korean_clock(current_time):
    hh = current_time.format("03")
    mm = current_time.format("04")
    return render.Animation(
        children = [
            render.Box(
                render.Column(
                    cross_align = "center",
                    children = render_koreanwords_time(int(hh), int(mm)),
                ),
            ),
        ],
    )

def img_of_thaiwords_minutes(minutes):
    if minutes == 0:
        return [BLANK]
    if minutes == 1:
        return [TW_DIGITS[0], TW_NATEE]
    if minutes <= 10:
        return [TW_DIGITS[minutes], TW_NATEE]
    if minutes < 20:
        return [TW_SIB, TW_DIGITS[minutes - 10]]
    if minutes == 20:
        return [TW_YEE, TW_SIB]
    if minutes < 30:
        return [TW_YEE, TW_SIB, TW_DIGITS[minutes - 20]]
    if minutes == 30:
        return [TW_HALF]
    if minutes % 10 == 0:
        return [TW_DIGITS[minutes // 10], TW_SIB]
    return [TW_DIGITS[minutes // 10], TW_SIB, TW_DIGITS[minutes % 10]]

def render_thaiwords_time(hours, minutes):
    if hours == 0 and minutes == 15:
        return [centered_row([TW_HOURS[0]]), centered_row(img_of_thaiwords_minutes(15) + [TW_NATEE])]

    onerow = (minutes == 0) or (minutes == 30 and hours != 11) or (hours == 12 and minutes <= 10)
    if onerow:
        return [centered_row([TW_HOURS[hours]] + img_of_thaiwords_minutes(minutes))]
    return [centered_row([TW_HOURS[hours]]), centered_row(img_of_thaiwords_minutes(minutes))]

def render_thaiwords_clock(current_time):
    hh = current_time.format("15")
    mm = current_time.format("04")
    return render.Animation(
        children = [
            render.Box(
                render.Column(
                    cross_align = "center",
                    children = render_thaiwords_time(int(hh), int(mm)),
                ),
            ),
        ],
    )

def roman_numeral(num):
    numbers = [(50, "L"), (40, "XL"), (10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I")]
    result = ""
    for val, str in numbers:
        for _ in range(10):
            if num >= val:
                result += str
                num -= val
    return result

def render_roman_clock(current_time):
    hh = int(current_time.format("15"))
    mm = int(current_time.format("04"))
    texts = [render.Text("H " + roman_numeral(hh), font = "6x13")]
    if mm != 0:
        texts.append(render.Text("M " + roman_numeral(mm), font = "6x13"))
    return render.Box(child = render.Column(children = texts))

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "Location for which to display the time",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "clocktype",
                name = "Clock Type",
                desc = "Type of the clock to display",
                icon = "language",
                default = "thai",
                options = [
                    schema.Option(
                        display = "Thai",
                        value = "thai",
                    ),
                    schema.Option(
                        display = "Roman",
                        value = "roman",
                    ),
                    schema.Option(
                        display = "Thai Words",
                        value = "thaiwords",
                    ),
                    schema.Option(
                        display = "Korean Words",
                        value = "koreanwords",
                    ),
                ],
            ),
        ],
    )
