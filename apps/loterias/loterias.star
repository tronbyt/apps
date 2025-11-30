"""
Applet: Loterias
Summary: Loterias do Brasil
Description: Veja os premios das principais modalidades da loteria.
Author: Daniel Sitnik
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("images/img_09887a13.png", IMG_09887a13_ASSET = "file")
load("images/img_17a26da4.png", IMG_17a26da4_ASSET = "file")
load("images/img_18e27725.png", IMG_18e27725_ASSET = "file")
load("images/img_2dc029ba.png", IMG_2dc029ba_ASSET = "file")
load("images/img_54dbf868.png", IMG_54dbf868_ASSET = "file")
load("images/img_65621ebc.png", IMG_65621ebc_ASSET = "file")
load("images/img_80d3e641.png", IMG_80d3e641_ASSET = "file")
load("images/img_9065715b.png", IMG_9065715b_ASSET = "file")
load("images/img_fb4c57f4.png", IMG_fb4c57f4_ASSET = "file")

# default values
DEFAULT_MODALITY = "megasena"
DEFAULT_PRIZE = "estimated"
DEFAULT_LOCATION = json.encode({
    "lat": "-23.6139915",
    "lng": "-46.7066243",
    "description": "São Paulo, SP, Brasil",
    "locality": "São Paulo",
    "place_id": "ChIJ0WGkg4FEzpQRrlsz_whLqZs",
    "timezone": "America/Sao_Paulo",
})

CACHE_TTL = 3600

# modalities configuration
MODALITIES = {
    "megasena": {
        "name": "MEGASENA",
        "color": "#4b966d",
        "icon": IMG_2dc029ba_ASSET.readall(),
    },
    "diaDeSorte": {
        "name": "DIA DE SORTE",
        "color": "#c1893f",
        "font": "CG-pixel-3x5-mono",
        "icon": IMG_54dbf868_ASSET.readall(),
    },
    "duplasena": {
        "name": "DUPLA SENA",
        "color": "#98262a",
        "icon": IMG_09887a13_ASSET.readall(),
    },
    "maisMilionaria": {
        "name": "MILIONÁRIA",
        "color": "#1c3176",
        "icon": IMG_80d3e641_ASSET.readall(),
    },
    "lotofacil": {
        "name": "LOTOFÁCIL",
        "color": "#871985",
        "icon": IMG_65621ebc_ASSET.readall(),
    },
    "lotomania": {
        "name": "LOTOMANIA",
        "color": "#e88732",
        "icon": IMG_18e27725_ASSET.readall(),
    },
    "timemania": {
        "name": "TIMEMANIA",
        "color": "#75fb4c",
        "icon": IMG_9065715b_ASSET.readall(),
    },
    "superSete": {
        "name": "SUPER SETE",
        "color": "#b1ce5b",
        "icon": IMG_17a26da4_ASSET.readall(),
    },
    "quina": {
        "name": "QUINA",
        "color": "#21027f",
        "icon": IMG_fb4c57f4_ASSET.readall(),
    },
}

def main(config):
    # get config options
    modality = config.str("modality", DEFAULT_MODALITY)
    prize = config.str("prize", DEFAULT_PRIZE)
    location_cfg = config.str("location", DEFAULT_LOCATION)
    location = json.decode(location_cfg)
    timezone = location["timezone"]

    # call loterias API
    res = http.get("https://tidbyt-loterias.vercel.app/api/%s" % modality, ttl_seconds = CACHE_TTL)

    # handle API error
    if res.status_code != 200:
        print("API error %d: %s" % (res.status_code, res.body()))
        return render_error(res.status_code)

    # get API data
    data = res.json()

    # calculate remaining time to the draw date considering the user's timezone
    draw_date = time.parse_time(("%s 20:00") % data["dataProximoConcurso"], "2/1/2006 15:04", "America/Sao_Paulo")
    draw_date_in_tz = draw_date.in_location(timezone)

    # humanize the draw date
    draw_date_human = ""

    # check if date is in the past
    current_time = time.now().in_location(timezone)
    if (current_time.unix < draw_date.unix):
        draw_date_human = "em " + humanize.time(draw_date_in_tz).replace("from now", "")
        draw_date_human = draw_date_human.replace("week", "semana")
        draw_date_human = draw_date_human.replace("weeks", "semanas")
        draw_date_human = draw_date_human.replace("days", "dias")
        draw_date_human = draw_date_human.replace("day", "dia")
        draw_date_human = draw_date_human.replace("hours", "horas")
        draw_date_human = draw_date_human.replace("hour", "hora")
        draw_date_human = draw_date_human.replace("minutes", "minutos")
        draw_date_human = draw_date_human.replace("minute", "minuto")
        draw_date_human = draw_date_human.replace("seconds", "segundos")
        draw_date_human = draw_date_human.replace("second", "segundo")
    else:
        draw_date_human = "encerrado!"

    # obtain the estimated/accumulated prize value
    prize_value = "R$ "
    if prize == DEFAULT_PRIZE:
        # estimated: what the lottery estimates the prize will be until the closing time
        prize_value = prize_value + humanize.float("#.###,", data["valorEstimadoProximoConcurso"])
    else:
        # accumulated: the true current accumulated prize value based on people's bets
        prize_value = prize_value + humanize.float("#.###,", data["valorAcumuladoProximoConcurso"])

    # grab the modality display configuration
    modality_name = MODALITIES.get(modality)["name"]
    modality_color = MODALITIES.get(modality)["color"]
    modality_icon = MODALITIES.get(modality)["icon"]
    modality_font = MODALITIES.get(modality).get("font", "tb-8")

    # render the final display
    return render.Root(
        render.Box(
            render.Column(
                expanded = True,
                main_align = "space_around",
                cross_align = "center",
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "space_around",
                        cross_align = "center",
                        children = [
                            render.Image(src = base64.decode(modality_icon), height = 10),
                            render.Text(modality_name, color = modality_color, font = modality_font),
                        ],
                    ),
                    render.Box(width = 64, height = 1, color = modality_color),
                    render.Text(prize_value),
                    render.Text(draw_date_human),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Localização",
                desc = "Localização para cálculo do tempo até o encerramento das apostas",
                icon = "locationDot",
            ),
            schema.Dropdown(
                id = "modality",
                name = "Modalidade",
                desc = "Modalidade (tipo de jogo)",
                icon = "clover",
                default = DEFAULT_MODALITY,
                options = [
                    schema.Option(
                        display = "Megasena",
                        value = "megasena",
                    ),
                    schema.Option(
                        display = "Dia de Sorte",
                        value = "diaDeSorte",
                    ),
                    schema.Option(
                        display = "Dupla Sena",
                        value = "duplasena",
                    ),
                    schema.Option(
                        display = "Mais Milionária",
                        value = "maisMilionaria",
                    ),
                    schema.Option(
                        display = "Lotofácil",
                        value = "lotofacil",
                    ),
                    schema.Option(
                        display = "Lotomania",
                        value = "lotomania",
                    ),
                    schema.Option(
                        display = "Timemanina",
                        value = "timemania",
                    ),
                    schema.Option(
                        display = "Super Sete",
                        value = "superSete",
                    ),
                    schema.Option(
                        display = "Quina",
                        value = "quina",
                    ),
                ],
            ),
            schema.Dropdown(
                id = "prize",
                name = "Prêmio",
                desc = "Exibir prêmio total estimado ou o valor real acumulado",
                icon = "sackDollar",
                default = DEFAULT_PRIZE,
                options = [
                    schema.Option(
                        display = "Estimado",
                        value = "estimated",
                    ),
                    schema.Option(
                        display = "Acumulado",
                        value = "accumulated",
                    ),
                ],
            ),
        ],
    )

def render_error(status_code):
    return render.Root(
        render.Box(
            render.Column(
                expanded = True,
                main_align = "space_around",
                cross_align = "center",
                children = [
                    render.Row(
                        main_align = "center",
                        cross_align = "center",
                        children = [
                            render.Image(src = base64.decode(MODALITIES["megasena"]["icon"]), height = 10),
                            render.Text("  LOTERIAS", color = "#4b966d"),
                        ],
                    ),
                    render.Text("API ERROR", color = "#ff0"),
                    render.Text("code " + str(status_code), color = "#f00"),
                ],
            ),
        ),
    )
