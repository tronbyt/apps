"""
Applet: Olympic Medals
Summary: 2024 Paris Olympic medals
Description: Displays 2024 Paris Olympic gold, silver, and bronze medal count by country.
Author: James Woglom
"""

load("animation.star", "animation")
load("html.star", "html")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/flag_afghanistan.webp", FLAG_AFGHANISTAN = "file")
load("images/flag_albania.webp", FLAG_ALBANIA = "file")
load("images/flag_algeria.webp", FLAG_ALGERIA = "file")
load("images/flag_american_samoa.webp", FLAG_AMERICAN_SAMOA = "file")
load("images/flag_andorra.webp", FLAG_ANDORRA = "file")
load("images/flag_angola.webp", FLAG_ANGOLA = "file")
load("images/flag_antigua_and_barbuda.webp", FLAG_ANTIGUA_AND_BARBUDA = "file")
load("images/flag_argentina.webp", FLAG_ARGENTINA = "file")
load("images/flag_armenia.webp", FLAG_ARMENIA = "file")
load("images/flag_aruba.webp", FLAG_ARUBA = "file")
load("images/flag_australia.webp", FLAG_AUSTRALIA = "file")
load("images/flag_austria.webp", FLAG_AUSTRIA = "file")
load("images/flag_azerbaijan.webp", FLAG_AZERBAIJAN = "file")
load("images/flag_bahamas.webp", FLAG_BAHAMAS = "file")
load("images/flag_bahrain.webp", FLAG_BAHRAIN = "file")
load("images/flag_bangladesh.webp", FLAG_BANGLADESH = "file")
load("images/flag_barbados.webp", FLAG_BARBADOS = "file")
load("images/flag_belgium.webp", FLAG_BELGIUM = "file")
load("images/flag_belize.webp", FLAG_BELIZE = "file")
load("images/flag_benin.webp", FLAG_BENIN = "file")
load("images/flag_bermuda.webp", FLAG_BERMUDA = "file")
load("images/flag_bhutan.webp", FLAG_BHUTAN = "file")
load("images/flag_boc.webp", FLAG_BOC = "file")
load("images/flag_bolivia.webp", FLAG_BOLIVIA = "file")
load("images/flag_bosnia_and_herzegovina.webp", FLAG_BOSNIA_AND_HERZEGOVINA = "file")
load("images/flag_botswana.webp", FLAG_BOTSWANA = "file")
load("images/flag_brazil.webp", FLAG_BRAZIL = "file")
load("images/flag_brunei_darussalam.webp", FLAG_BRUNEI_DARUSSALAM = "file")
load("images/flag_bulgaria.webp", FLAG_BULGARIA = "file")
load("images/flag_burkina_faso.webp", FLAG_BURKINA_FASO = "file")
load("images/flag_burundi.webp", FLAG_BURUNDI = "file")
load("images/flag_cabo_verde.webp", FLAG_CABO_VERDE = "file")
load("images/flag_cambodia.webp", FLAG_CAMBODIA = "file")
load("images/flag_cameroon.webp", FLAG_CAMEROON = "file")
load("images/flag_canada.webp", FLAG_CANADA = "file")
load("images/flag_cayman_islands.webp", FLAG_CAYMAN_ISLANDS = "file")
load("images/flag_central_african_republic.webp", FLAG_CENTRAL_AFRICAN_REPUBLIC = "file")
load("images/flag_chad.webp", FLAG_CHAD = "file")
load("images/flag_chile.webp", FLAG_CHILE = "file")
load("images/flag_chinese_taipei.webp", FLAG_CHINESE_TAIPEI = "file")
load("images/flag_colombia.webp", FLAG_COLOMBIA = "file")
load("images/flag_comoros.webp", FLAG_COMOROS = "file")
load("images/flag_congo.webp", FLAG_CONGO = "file")
load("images/flag_cook_islands.webp", FLAG_COOK_ISLANDS = "file")
load("images/flag_costa_rica.webp", FLAG_COSTA_RICA = "file")
load("images/flag_croatia.webp", FLAG_CROATIA = "file")
load("images/flag_cuba.webp", FLAG_CUBA = "file")
load("images/flag_cyprus.webp", FLAG_CYPRUS = "file")
load("images/flag_czechia.webp", FLAG_CZECHIA = "file")
load("images/flag_democratic_people_s_republic_of_korea.webp", FLAG_DEMOCRATIC_PEOPLE_S_REPUBLIC_OF_KOREA = "file")
load("images/flag_democratic_republic_of_the_congo.webp", FLAG_DEMOCRATIC_REPUBLIC_OF_THE_CONGO = "file")
load("images/flag_denmark.webp", FLAG_DENMARK = "file")
load("images/flag_djibouti.webp", FLAG_DJIBOUTI = "file")
load("images/flag_dominica.webp", FLAG_DOMINICA = "file")
load("images/flag_dominican_republic.webp", FLAG_DOMINICAN_REPUBLIC = "file")
load("images/flag_ecuador.webp", FLAG_ECUADOR = "file")
load("images/flag_egypt.webp", FLAG_EGYPT = "file")
load("images/flag_el_salvador.webp", FLAG_EL_SALVADOR = "file")
load("images/flag_equatorial_guinea.webp", FLAG_EQUATORIAL_GUINEA = "file")
load("images/flag_eritrea.webp", FLAG_ERITREA = "file")
load("images/flag_estonia.webp", FLAG_ESTONIA = "file")
load("images/flag_eswatini.webp", FLAG_ESWATINI = "file")
load("images/flag_ethiopia.webp", FLAG_ETHIOPIA = "file")
load("images/flag_federated_states_of_micronesia.webp", FLAG_FEDERATED_STATES_OF_MICRONESIA = "file")
load("images/flag_fiji.webp", FLAG_FIJI = "file")
load("images/flag_finland.webp", FLAG_FINLAND = "file")
load("images/flag_france.webp", FLAG_FRANCE = "file")
load("images/flag_gabon.webp", FLAG_GABON = "file")
load("images/flag_gambia.webp", FLAG_GAMBIA = "file")
load("images/flag_georgia.webp", FLAG_GEORGIA = "file")
load("images/flag_germany.webp", FLAG_GERMANY = "file")
load("images/flag_ghana.webp", FLAG_GHANA = "file")
load("images/flag_great_britain.webp", FLAG_GREAT_BRITAIN = "file")
load("images/flag_greece.webp", FLAG_GREECE = "file")
load("images/flag_grenada.webp", FLAG_GRENADA = "file")
load("images/flag_guam.webp", FLAG_GUAM = "file")
load("images/flag_guatemala.webp", FLAG_GUATEMALA = "file")
load("images/flag_guinea.webp", FLAG_GUINEA = "file")
load("images/flag_guinea_bissau.webp", FLAG_GUINEA_BISSAU = "file")
load("images/flag_guyana.webp", FLAG_GUYANA = "file")
load("images/flag_haiti.webp", FLAG_HAITI = "file")
load("images/flag_honduras.webp", FLAG_HONDURAS = "file")
load("images/flag_hong_kong__china.webp", FLAG_HONG_KONG__CHINA = "file")
load("images/flag_hungary.webp", FLAG_HUNGARY = "file")
load("images/flag_iceland.webp", FLAG_ICELAND = "file")
load("images/flag_india.webp", FLAG_INDIA = "file")
load("images/flag_indonesia.webp", FLAG_INDONESIA = "file")
load("images/flag_iraq.webp", FLAG_IRAQ = "file")
load("images/flag_ireland.webp", FLAG_IRELAND = "file")
load("images/flag_islamic_republic_of_iran.webp", FLAG_ISLAMIC_REPUBLIC_OF_IRAN = "file")
load("images/flag_israel.webp", FLAG_ISRAEL = "file")
load("images/flag_italy.webp", FLAG_ITALY = "file")
load("images/flag_jamaica.webp", FLAG_JAMAICA = "file")
load("images/flag_japan.webp", FLAG_JAPAN = "file")
load("images/flag_jordan.webp", FLAG_JORDAN = "file")
load("images/flag_kazakhstan.webp", FLAG_KAZAKHSTAN = "file")
load("images/flag_kenya.webp", FLAG_KENYA = "file")
load("images/flag_kiribati.webp", FLAG_KIRIBATI = "file")
load("images/flag_kosovo.webp", FLAG_KOSOVO = "file")
load("images/flag_kuwait.webp", FLAG_KUWAIT = "file")
load("images/flag_kyrgyzstan.webp", FLAG_KYRGYZSTAN = "file")
load("images/flag_lao_people_s_democratic_republic.webp", FLAG_LAO_PEOPLE_S_DEMOCRATIC_REPUBLIC = "file")
load("images/flag_latvia.webp", FLAG_LATVIA = "file")
load("images/flag_lebanon.webp", FLAG_LEBANON = "file")
load("images/flag_lesotho.webp", FLAG_LESOTHO = "file")
load("images/flag_liberia.webp", FLAG_LIBERIA = "file")
load("images/flag_libya.webp", FLAG_LIBYA = "file")
load("images/flag_liechtenstein.webp", FLAG_LIECHTENSTEIN = "file")
load("images/flag_lithuania.webp", FLAG_LITHUANIA = "file")
load("images/flag_luxembourg.webp", FLAG_LUXEMBOURG = "file")
load("images/flag_madagascar.webp", FLAG_MADAGASCAR = "file")
load("images/flag_malawi.webp", FLAG_MALAWI = "file")
load("images/flag_malaysia.webp", FLAG_MALAYSIA = "file")
load("images/flag_maldives.webp", FLAG_MALDIVES = "file")
load("images/flag_mali.webp", FLAG_MALI = "file")
load("images/flag_malta.webp", FLAG_MALTA = "file")
load("images/flag_marshall_islands.webp", FLAG_MARSHALL_ISLANDS = "file")
load("images/flag_mauritania.webp", FLAG_MAURITANIA = "file")
load("images/flag_mauritius.webp", FLAG_MAURITIUS = "file")
load("images/flag_mexico.webp", FLAG_MEXICO = "file")
load("images/flag_monaco.webp", FLAG_MONACO = "file")
load("images/flag_mongolia.webp", FLAG_MONGOLIA = "file")
load("images/flag_montenegro.webp", FLAG_MONTENEGRO = "file")
load("images/flag_morocco.webp", FLAG_MOROCCO = "file")
load("images/flag_mozambique.webp", FLAG_MOZAMBIQUE = "file")
load("images/flag_myanmar.webp", FLAG_MYANMAR = "file")
load("images/flag_namibia.webp", FLAG_NAMIBIA = "file")
load("images/flag_nauru.webp", FLAG_NAURU = "file")
load("images/flag_nepal.webp", FLAG_NEPAL = "file")
load("images/flag_netherlands.webp", FLAG_NETHERLANDS = "file")
load("images/flag_new_zealand.webp", FLAG_NEW_ZEALAND = "file")
load("images/flag_nicaragua.webp", FLAG_NICARAGUA = "file")
load("images/flag_niger.webp", FLAG_NIGER = "file")
load("images/flag_nigeria.webp", FLAG_NIGERIA = "file")
load("images/flag_north_macedonia.webp", FLAG_NORTH_MACEDONIA = "file")
load("images/flag_norway.webp", FLAG_NORWAY = "file")
load("images/flag_oman.webp", FLAG_OMAN = "file")
load("images/flag_pakistan.webp", FLAG_PAKISTAN = "file")
load("images/flag_palau.webp", FLAG_PALAU = "file")
load("images/flag_palestine.webp", FLAG_PALESTINE = "file")
load("images/flag_panama.webp", FLAG_PANAMA = "file")
load("images/flag_papua_new_guinea.webp", FLAG_PAPUA_NEW_GUINEA = "file")
load("images/flag_paraguay.webp", FLAG_PARAGUAY = "file")
load("images/flag_people_s_republic_of_china.webp", FLAG_PEOPLE_S_REPUBLIC_OF_CHINA = "file")
load("images/flag_peru.webp", FLAG_PERU = "file")
load("images/flag_philippines.webp", FLAG_PHILIPPINES = "file")
load("images/flag_poland.webp", FLAG_POLAND = "file")
load("images/flag_portugal.webp", FLAG_PORTUGAL = "file")
load("images/flag_puerto_rico.webp", FLAG_PUERTO_RICO = "file")
load("images/flag_qatar.webp", FLAG_QATAR = "file")
load("images/flag_republic_of_korea.webp", FLAG_REPUBLIC_OF_KOREA = "file")
load("images/flag_republic_of_moldova.webp", FLAG_REPUBLIC_OF_MOLDOVA = "file")
load("images/flag_roc.webp", FLAG_ROC = "file")
load("images/flag_romania.webp", FLAG_ROMANIA = "file")
load("images/flag_rwanda.webp", FLAG_RWANDA = "file")
load("images/flag_saint_kitts_and_nevis.webp", FLAG_SAINT_KITTS_AND_NEVIS = "file")
load("images/flag_saint_lucia.webp", FLAG_SAINT_LUCIA = "file")
load("images/flag_samoa.webp", FLAG_SAMOA = "file")
load("images/flag_san_marino.webp", FLAG_SAN_MARINO = "file")
load("images/flag_sao_tome_and_principe.webp", FLAG_SAO_TOME_AND_PRINCIPE = "file")
load("images/flag_saudi_arabia.webp", FLAG_SAUDI_ARABIA = "file")
load("images/flag_senegal.webp", FLAG_SENEGAL = "file")
load("images/flag_serbia.webp", FLAG_SERBIA = "file")
load("images/flag_seychelles.webp", FLAG_SEYCHELLES = "file")
load("images/flag_sierra_leone.webp", FLAG_SIERRA_LEONE = "file")
load("images/flag_singapore.webp", FLAG_SINGAPORE = "file")
load("images/flag_slovakia.webp", FLAG_SLOVAKIA = "file")
load("images/flag_slovenia.webp", FLAG_SLOVENIA = "file")
load("images/flag_solomon_islands.webp", FLAG_SOLOMON_ISLANDS = "file")
load("images/flag_somalia.webp", FLAG_SOMALIA = "file")
load("images/flag_south_africa.webp", FLAG_SOUTH_AFRICA = "file")
load("images/flag_south_sudan.webp", FLAG_SOUTH_SUDAN = "file")
load("images/flag_spain.webp", FLAG_SPAIN = "file")
load("images/flag_sri_lanka.webp", FLAG_SRI_LANKA = "file")
load("images/flag_st_vincent_and_the_grenadines.webp", FLAG_ST_VINCENT_AND_THE_GRENADINES = "file")
load("images/flag_sudan.webp", FLAG_SUDAN = "file")
load("images/flag_suriname.webp", FLAG_SURINAME = "file")
load("images/flag_sweden.webp", FLAG_SWEDEN = "file")
load("images/flag_switzerland.webp", FLAG_SWITZERLAND = "file")
load("images/flag_syrian_arab_republic.webp", FLAG_SYRIAN_ARAB_REPUBLIC = "file")
load("images/flag_tajikistan.webp", FLAG_TAJIKISTAN = "file")
load("images/flag_thailand.webp", FLAG_THAILAND = "file")
load("images/flag_timor_leste.webp", FLAG_TIMOR_LESTE = "file")
load("images/flag_togo.webp", FLAG_TOGO = "file")
load("images/flag_tonga.webp", FLAG_TONGA = "file")
load("images/flag_trinidad_and_tobago.webp", FLAG_TRINIDAD_AND_TOBAGO = "file")
load("images/flag_tunisia.webp", FLAG_TUNISIA = "file")
load("images/flag_turkmenistan.webp", FLAG_TURKMENISTAN = "file")
load("images/flag_tuvalu.webp", FLAG_TUVALU = "file")
load("images/flag_uganda.webp", FLAG_UGANDA = "file")
load("images/flag_ukraine.webp", FLAG_UKRAINE = "file")
load("images/flag_united_arab_emirates.webp", FLAG_UNITED_ARAB_EMIRATES = "file")
load("images/flag_united_republic_of_tanzania.webp", FLAG_UNITED_REPUBLIC_OF_TANZANIA = "file")
load("images/flag_united_states_of_america.webp", FLAG_UNITED_STATES_OF_AMERICA = "file")
load("images/flag_uruguay.webp", FLAG_URUGUAY = "file")
load("images/flag_uzbekistan.webp", FLAG_UZBEKISTAN = "file")
load("images/flag_vanuatu.webp", FLAG_VANUATU = "file")
load("images/flag_venezuela.webp", FLAG_VENEZUELA = "file")
load("images/flag_vietnam.webp", FLAG_VIETNAM = "file")
load("images/flag_virgin_islands__us.webp", FLAG_VIRGIN_ISLANDS__US = "file")
load("images/flag_virgin_islands_british.webp", FLAG_VIRGIN_ISLANDS_BRITISH = "file")
load("images/flag_yemen.webp", FLAG_YEMEN = "file")
load("images/flag_zambia.webp", FLAG_ZAMBIA = "file")
load("images/flag_zimbabwe.webp", FLAG_ZIMBABWE = "file")
load("images/olympic_logo.png", OLYMPIC_LOGO_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

OLYMPIC_LOGO = OLYMPIC_LOGO_ASSET.readall()

URL = "https://olympics.com/en/paris-2024/medals"
USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"
DEFAULT_TEXT_COLOR = "#fff"
DEFAULT_BG_COLOR = "#000"

DEFAULT_SUMMARY = True
DEFAULT_DETAIL = True
DEFAULT_RINGS = True
DEFAULT_FULL_ANIMATION = True
DEFAULT_COUNT = "5"
DEFAULT_DELAY = "100"
DEFAULT_FRAMES = "50"

def fetch_data(config):
    count = int(config.str("count", DEFAULT_COUNT))

    res = http.get(URL, headers = {"User-Agent": USER_AGENT}, ttl_seconds = 3600)
    if res.status_code != 200:
        fail("GET %s failed with status %d: %s", URL, res.status_code, res.body())
    page = html(res.body())
    list = page.find("[data-testid='noc-row']")
    if not list:
        fail("could not find medal list table on %s: %s", URL, res.body())

    res = []
    for i in range(min(count, list.len())):
        row = list.eq(i)
        spans = row.find("span")

        scraped = [
            spans.eq(2).text(),  # Country name
            1 + i,  # Rank
            spans.eq(3).text(),  # Gold
            spans.eq(4).text(),  # Silver
            spans.eq(5).text(),  # Bronze
        ]
        res.append(scraped)

    return res

def display_for(duration, child):
    return render.Box(
        child = animation.Transformation(
            child = child,
            duration = duration,
            delay = 0,
            origin = animation.Origin(0, 0),
            direction = "normal",
            fill_mode = "forwards",
            keyframes = [
                animation.Keyframe(
                    percentage = 0.0,
                    transforms = [animation.Translate(0, 0)],
                ),
                animation.Keyframe(
                    percentage = 1.0,
                    transforms = [animation.Translate(0, 0)],
                ),
            ],
        ),
    )

def main(config):
    show_summary = config.bool("show_summary", DEFAULT_SUMMARY)
    show_detail = config.bool("show_detail", DEFAULT_DETAIL)
    show_rings = config.bool("show_rings", DEFAULT_RINGS)
    show_full_animation = config.bool("show_full_animation", DEFAULT_FULL_ANIMATION)
    delay = int(config.str("delay", DEFAULT_DELAY))
    frames = int(config.str("frames", DEFAULT_FRAMES))

    data = fetch_data(config)

    rendered = []

    if show_summary:
        summary = render_summary(data, show_rings)
        rendered.append(summary)

    if show_detail:
        for i in range(len(data)):
            r = render_country(*data[i])
            rendered.append(r)

    children = []
    for i in range(len(rendered)):
        children.append(display_for(frames, rendered[i]))

    return render.Root(
        render.Sequence(children = children),
        delay = delay,
        show_full_animation = show_full_animation,
    )

def text_or_marquee(name, text_color = DEFAULT_TEXT_COLOR):
    name_text = render.Text(
        content = name,
        color = text_color,
        font = "tom-thumb",
    )

    return render.Marquee(
        width = 48,
        child = name_text,
        offset_start = 0,
        offset_end = 48,
        align = "center",
    )

def big_text_or_marquee(name, text_color = DEFAULT_TEXT_COLOR):
    name_text = render.Text(
        content = name,
        color = text_color,
        font = "5x8",
    )

    return render.Marquee(
        width = 40,
        child = name_text,
        offset_start = 0,
        offset_end = 48,
        align = "center",
    )

def render_medal_row(left, gold, silver, bronze):
    return render.Row(
        main_align = "start",
        cross_align = "center",
        children = [
            render.Box(
                width = 16,
                height = 8,
                child = left,
            ),
            render.Stack(
                children = [
                    render.Box(width = 16, height = 8, color = "#FFD700"),
                    render.WrappedText(gold, width = 16, height = 8, color = "#000", align = "center"),
                ],
            ),
            render.Stack(
                children = [
                    render.Box(width = 16, height = 8, color = "#C0C0C0"),
                    render.WrappedText(silver, width = 16, height = 8, color = "#000", align = "center"),
                ],
            ),
            render.Stack(
                children = [
                    render.Box(width = 16, height = 8, color = "#CD7F32"),
                    render.WrappedText(bronze, width = 16, height = 8, color = "#000", align = "center"),
                ],
            ),
        ],
    )

def render_country(country, place, gold, silver, bronze):
    flag = FLAGS[country]
    country_name = SHORT_NAMES.get(country, country)

    # original flag image is 40 x 30
    rendered_image = render.Image(
        src = flag.readall(),
        width = 16,
        height = 12,
    )

    total_medals = int(gold) + int(silver) + int(bronze)

    box = render.Box(
        child = render.Column(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = [
                render_medal_row(
                    render.Text(
                        content = humanize.ordinal(place),
                    ),
                    gold,
                    silver,
                    bronze,
                ),
                render.Box(
                    width = 64,
                    height = 16,
                    child = render.Row(
                        cross_align = "center",
                        children = [
                            rendered_image,
                            render.Box(
                                width = 42,
                                height = 16,
                                child = render.Column(
                                    expanded = True,
                                    main_align = "center",
                                    cross_align = "center",
                                    children = [
                                        big_text_or_marquee(country_name),
                                        text_or_marquee(humanize.plural(total_medals, "medal")),
                                    ],
                                ),
                            ),
                        ],
                    ),
                ),
            ],
        ),
    )

    return box

def olympic_rings():
    return render.Box(
        child = render.Padding(
            child = render.Image(
                src = OLYMPIC_LOGO,
                width = 54,
                height = 24,
            ),
            pad = (0, 2, 0, 0),
        ),
        color = "#5f5f5f",
    )

def render_summary(data, show_rings):
    children = [
        render.Text(
            "Paris 2024",
            font = "5x8",
        ),
        render.Text(
            "Medal Count:",
            font = "5x8",
        ),
    ]
    for i in range(len(data)):
        children.append(render.Padding(
            child = render_summary_country(*data[i]),
            pad = (0, 2, 0, 2),
        ))

    stack = []
    if show_rings:
        stack.append(olympic_rings())

    return render.Stack(
        children = stack + [
            render.Marquee(
                scroll_direction = "vertical",
                height = 32,
                offset_start = 32,
                offset_end = 0,
                child = render.Column(
                    cross_align = "center",
                    expanded = True,
                    children = children,
                ),
            ),
        ],
    )

# keeping unused args in order to keep tuple format
# buildifier: disable=unused-variable
def render_summary_country(country, place, gold, silver, bronze):
    flag = FLAGS[country]

    # original flag image is 40 x 30
    rendered_image = render.Image(
        src = flag.readall(),
        width = 16,
        height = 12,
    )

    return render_medal_row(rendered_image, gold, silver, bronze)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "show_summary",
                name = "Show summary",
                desc = "Show a summary of the top rankings",
                icon = "gear",
                default = DEFAULT_SUMMARY,
            ),
            schema.Toggle(
                id = "show_detail",
                name = "Show detail",
                desc = "Show a per-country detail",
                icon = "gear",
                default = DEFAULT_DETAIL,
            ),
            schema.Toggle(
                id = "show_rings",
                name = "Show Olympic rings",
                desc = "Show the olympic rings logo",
                icon = "gear",
                default = DEFAULT_RINGS,
            ),
            schema.Toggle(
                id = "show_full_animation",
                name = "Show full animation",
                desc = "Show full animation regardless of app cycle settings",
                icon = "gear",
                default = DEFAULT_FULL_ANIMATION,
            ),
            schema.Text(
                id = "count",
                name = "Country count",
                desc = "Number of countries to display",
                icon = "gear",
                default = DEFAULT_COUNT,
            ),
            schema.Text(
                id = "delay",
                name = "Delay",
                desc = "Frame delay. Increase to slow down the display.",
                icon = "gear",
                default = DEFAULT_DELAY,
            ),
            schema.Text(
                id = "frames",
                name = "Frames",
                desc = "Frame count each country is displayed",
                icon = "gear",
                default = DEFAULT_FRAMES,
            ),
        ],
    )

SHORT_NAMES = {
    "United States of America": "United States",
    "People's Republic of China": "China",
}

FLAGS = {
    "Afghanistan": FLAG_AFGHANISTAN,
    "Albania": FLAG_ALBANIA,
    "Algeria": FLAG_ALGERIA,
    "American Samoa": FLAG_AMERICAN_SAMOA,
    "Andorra": FLAG_ANDORRA,
    "Angola": FLAG_ANGOLA,
    "Antigua and Barbuda": FLAG_ANTIGUA_AND_BARBUDA,
    "Argentina": FLAG_ARGENTINA,
    "Armenia": FLAG_ARMENIA,
    "Aruba": FLAG_ARUBA,
    "Australia": FLAG_AUSTRALIA,
    "Austria": FLAG_AUSTRIA,
    "Azerbaijan": FLAG_AZERBAIJAN,
    "Bahamas": FLAG_BAHAMAS,
    "Bahrain": FLAG_BAHRAIN,
    "Bangladesh": FLAG_BANGLADESH,
    "Barbados": FLAG_BARBADOS,
    "BOC": FLAG_BOC,
    "Belgium": FLAG_BELGIUM,
    "Belize": FLAG_BELIZE,
    "Benin": FLAG_BENIN,
    "Bermuda": FLAG_BERMUDA,
    "Bhutan": FLAG_BHUTAN,
    "Bolivia": FLAG_BOLIVIA,
    "Bosnia and Herzegovina": FLAG_BOSNIA_AND_HERZEGOVINA,
    "Botswana": FLAG_BOTSWANA,
    "Brazil": FLAG_BRAZIL,
    "Brunei Darussalam": FLAG_BRUNEI_DARUSSALAM,
    "Bulgaria": FLAG_BULGARIA,
    "Burkina Faso": FLAG_BURKINA_FASO,
    "Burundi": FLAG_BURUNDI,
    "Cabo Verde": FLAG_CABO_VERDE,
    "Cambodia": FLAG_CAMBODIA,
    "Cameroon": FLAG_CAMEROON,
    "Canada": FLAG_CANADA,
    "Cayman Islands": FLAG_CAYMAN_ISLANDS,
    "Central African Republic": FLAG_CENTRAL_AFRICAN_REPUBLIC,
    "Chad": FLAG_CHAD,
    "Chile": FLAG_CHILE,
    "People's Republic of China": FLAG_PEOPLE_S_REPUBLIC_OF_CHINA,
    "Chinese Taipei": FLAG_CHINESE_TAIPEI,
    "Colombia": FLAG_COLOMBIA,
    "Comoros": FLAG_COMOROS,
    "Congo": FLAG_CONGO,
    "Democratic Republic of the Congo": FLAG_DEMOCRATIC_REPUBLIC_OF_THE_CONGO,
    "Cook Islands": FLAG_COOK_ISLANDS,
    "Costa Rica": FLAG_COSTA_RICA,
    "Croatia": FLAG_CROATIA,
    "Cuba": FLAG_CUBA,
    "Cyprus": FLAG_CYPRUS,
    "Czechia": FLAG_CZECHIA,
    "Denmark": FLAG_DENMARK,
    "Djibouti": FLAG_DJIBOUTI,
    "Dominica": FLAG_DOMINICA,
    "Dominican Republic": FLAG_DOMINICAN_REPUBLIC,
    "Ecuador": FLAG_ECUADOR,
    "Egypt": FLAG_EGYPT,
    "El Salvador": FLAG_EL_SALVADOR,
    "Equatorial Guinea": FLAG_EQUATORIAL_GUINEA,
    "Eritrea": FLAG_ERITREA,
    "Estonia": FLAG_ESTONIA,
    "Eswatini": FLAG_ESWATINI,
    "Ethiopia": FLAG_ETHIOPIA,
    "Fiji": FLAG_FIJI,
    "Finland": FLAG_FINLAND,
    "France": FLAG_FRANCE,
    "Gabon": FLAG_GABON,
    "Gambia": FLAG_GAMBIA,
    "Georgia": FLAG_GEORGIA,
    "Germany": FLAG_GERMANY,
    "Ghana": FLAG_GHANA,
    "Greece": FLAG_GREECE,
    "Grenada": FLAG_GRENADA,
    "Guam": FLAG_GUAM,
    "Guatemala": FLAG_GUATEMALA,
    "Guinea": FLAG_GUINEA,
    "Guinea-Bissau": FLAG_GUINEA_BISSAU,
    "Guyana": FLAG_GUYANA,
    "Haiti": FLAG_HAITI,
    "Honduras": FLAG_HONDURAS,
    "Hong Kong, China": FLAG_HONG_KONG__CHINA,
    "Hungary": FLAG_HUNGARY,
    "Iceland": FLAG_ICELAND,
    "India": FLAG_INDIA,
    "Indonesia": FLAG_INDONESIA,
    "Islamic Republic of Iran": FLAG_ISLAMIC_REPUBLIC_OF_IRAN,
    "Iraq": FLAG_IRAQ,
    "Ireland": FLAG_IRELAND,
    "Israel": FLAG_ISRAEL,
    "Italy": FLAG_ITALY,
    "Jamaica": FLAG_JAMAICA,
    "Japan": FLAG_JAPAN,
    "Jordan": FLAG_JORDAN,
    "Kazakhstan": FLAG_KAZAKHSTAN,
    "Kenya": FLAG_KENYA,
    "Kiribati": FLAG_KIRIBATI,
    "Democratic People's Republic of Korea": FLAG_DEMOCRATIC_PEOPLE_S_REPUBLIC_OF_KOREA,
    "Republic of Korea": FLAG_REPUBLIC_OF_KOREA,
    "Kosovo": FLAG_KOSOVO,
    "Kuwait": FLAG_KUWAIT,
    "Kyrgyzstan": FLAG_KYRGYZSTAN,
    "Lao People's Democratic Republic": FLAG_LAO_PEOPLE_S_DEMOCRATIC_REPUBLIC,
    "Latvia": FLAG_LATVIA,
    "Lebanon": FLAG_LEBANON,
    "Lesotho": FLAG_LESOTHO,
    "Liberia": FLAG_LIBERIA,
    "Libya": FLAG_LIBYA,
    "Liechtenstein": FLAG_LIECHTENSTEIN,
    "Lithuania": FLAG_LITHUANIA,
    "Luxembourg": FLAG_LUXEMBOURG,
    "Madagascar": FLAG_MADAGASCAR,
    "Malawi": FLAG_MALAWI,
    "Malaysia": FLAG_MALAYSIA,
    "Maldives": FLAG_MALDIVES,
    "Mali": FLAG_MALI,
    "Malta": FLAG_MALTA,
    "Marshall Islands": FLAG_MARSHALL_ISLANDS,
    "Mauritania": FLAG_MAURITANIA,
    "Mauritius": FLAG_MAURITIUS,
    "Mexico": FLAG_MEXICO,
    "Federated States of Micronesia": FLAG_FEDERATED_STATES_OF_MICRONESIA,
    "Republic of Moldova": FLAG_REPUBLIC_OF_MOLDOVA,
    "Monaco": FLAG_MONACO,
    "Mongolia": FLAG_MONGOLIA,
    "Montenegro": FLAG_MONTENEGRO,
    "Morocco": FLAG_MOROCCO,
    "Mozambique": FLAG_MOZAMBIQUE,
    "Myanmar": FLAG_MYANMAR,
    "Namibia": FLAG_NAMIBIA,
    "Nauru": FLAG_NAURU,
    "Nepal": FLAG_NEPAL,
    "Netherlands": FLAG_NETHERLANDS,
    "New Zealand": FLAG_NEW_ZEALAND,
    "Nicaragua": FLAG_NICARAGUA,
    "Niger": FLAG_NIGER,
    "Nigeria": FLAG_NIGERIA,
    "North Macedonia": FLAG_NORTH_MACEDONIA,
    "Norway": FLAG_NORWAY,
    "Oman": FLAG_OMAN,
    "Pakistan": FLAG_PAKISTAN,
    "Palau": FLAG_PALAU,
    "Palestine": FLAG_PALESTINE,
    "Panama": FLAG_PANAMA,
    "Papua New Guinea": FLAG_PAPUA_NEW_GUINEA,
    "Paraguay": FLAG_PARAGUAY,
    "Peru": FLAG_PERU,
    "Philippines": FLAG_PHILIPPINES,
    "Poland": FLAG_POLAND,
    "Portugal": FLAG_PORTUGAL,
    "Puerto Rico": FLAG_PUERTO_RICO,
    "Qatar": FLAG_QATAR,
    "Romania": FLAG_ROMANIA,
    "ROC": FLAG_ROC,
    "Rwanda": FLAG_RWANDA,
    "Saint Kitts and Nevis": FLAG_SAINT_KITTS_AND_NEVIS,
    "Saint Lucia": FLAG_SAINT_LUCIA,
    "Samoa": FLAG_SAMOA,
    "San Marino": FLAG_SAN_MARINO,
    "Sao Tome and Principe": FLAG_SAO_TOME_AND_PRINCIPE,
    "Saudi Arabia": FLAG_SAUDI_ARABIA,
    "Senegal": FLAG_SENEGAL,
    "Serbia": FLAG_SERBIA,
    "Seychelles": FLAG_SEYCHELLES,
    "Sierra Leone": FLAG_SIERRA_LEONE,
    "Singapore": FLAG_SINGAPORE,
    "Slovakia": FLAG_SLOVAKIA,
    "Slovenia": FLAG_SLOVENIA,
    "Solomon Islands": FLAG_SOLOMON_ISLANDS,
    "Somalia": FLAG_SOMALIA,
    "South Africa": FLAG_SOUTH_AFRICA,
    "South Sudan": FLAG_SOUTH_SUDAN,
    "Spain": FLAG_SPAIN,
    "Sri Lanka": FLAG_SRI_LANKA,
    "St Vincent and the Grenadines": FLAG_ST_VINCENT_AND_THE_GRENADINES,
    "Sudan": FLAG_SUDAN,
    "Suriname": FLAG_SURINAME,
    "Sweden": FLAG_SWEDEN,
    "Switzerland": FLAG_SWITZERLAND,
    "Syrian Arab Republic": FLAG_SYRIAN_ARAB_REPUBLIC,
    "Tajikistan": FLAG_TAJIKISTAN,
    "United Republic of Tanzania": FLAG_UNITED_REPUBLIC_OF_TANZANIA,
    "Thailand": FLAG_THAILAND,
    "Timor-Leste": FLAG_TIMOR_LESTE,
    "Togo": FLAG_TOGO,
    "Tonga": FLAG_TONGA,
    "Trinidad and Tobago": FLAG_TRINIDAD_AND_TOBAGO,
    "Tunisia": FLAG_TUNISIA,
    "Turkmenistan": FLAG_TURKMENISTAN,
    "Tuvalu": FLAG_TUVALU,
    "Uganda": FLAG_UGANDA,
    "Ukraine": FLAG_UKRAINE,
    "United Arab Emirates": FLAG_UNITED_ARAB_EMIRATES,
    "Great Britain": FLAG_GREAT_BRITAIN,
    "United States of America": FLAG_UNITED_STATES_OF_AMERICA,
    "Uruguay": FLAG_URUGUAY,
    "Uzbekistan": FLAG_UZBEKISTAN,
    "Vanuatu": FLAG_VANUATU,
    "Venezuela": FLAG_VENEZUELA,
    "Vietnam": FLAG_VIETNAM,
    "Virgin Islands British": FLAG_VIRGIN_ISLANDS_BRITISH,
    "Virgin Islands, US": FLAG_VIRGIN_ISLANDS__US,
    "Yemen": FLAG_YEMEN,
    "Zambia": FLAG_ZAMBIA,
    "Zimbabwe": FLAG_ZIMBABWE,
}
