"""
Applet: Trenitalia
Summary: Partenze treni italiani
Description: Mostra i prossimi treni in partenza da una stazione Trenitalia. Perfetto per pendolari: filtra per destinazione o numero treno.
Author: Mattia Colombo
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# API Base URL
VIAGGIATRENO_BASE = "http://www.viaggiatreno.it/infomobilita/resteasy/viaggiatreno"

# Colori
COLOR_RED = "#FF0000"
COLOR_GREEN = "#00FF00"
COLOR_YELLOW = "#FFFF00"
COLOR_WHITE = "#FFFFFF"
COLOR_GRAY = "#888888"
COLOR_ORANGE = "#FFA500"
COLOR_FRECCIAROSSA = "#C8102E"
COLOR_FRECCIARGENTO = "#A8A8A8"
COLOR_INTERCITY = "#0066B3"
COLOR_REGIONALE = "#00A651"

# Colori per categoria
CATEGORY_COLORS = {
    "FR": COLOR_FRECCIAROSSA,
    "FA": COLOR_FRECCIARGENTO,
    "FB": COLOR_WHITE,
    "IC": COLOR_INTERCITY,
    "ICN": COLOR_INTERCITY,
    "EC": COLOR_INTERCITY,
    "EN": COLOR_INTERCITY,
    "REG": COLOR_REGIONALE,
    "RV": COLOR_REGIONALE,
}

# Stazioni comuni predefinite
DEFAULT_STATIONS = [
    ("Milano Centrale", "S01700"),
    ("Milano Porta Garibaldi", "S01645"),
    ("Milano Cadorna", "S01637"),
    ("Roma Termini", "S08409"),
    ("Roma Tiburtina", "S08217"),
    ("Napoli Centrale", "S09218"),
    ("Torino Porta Nuova", "S00219"),
    ("Firenze S.M.N.", "S06004"),
    ("Bologna Centrale", "S05043"),
    ("Venezia S. Lucia", "S02593"),
    ("Genova Piazza Principe", "S01700"),
    ("Verona Porta Nuova", "S02430"),
]

def main(config):
    """Funzione principale dell'app."""

    # Gestisci station_id che può essere stringa o oggetto JSON da pixlet serve
    station_id_raw = config.get("station_id", "S01700")
    if type(station_id_raw) == "dict":
        station_id = station_id_raw.get("value", "S01700")
    elif station_id_raw.startswith("{"):
        # E' una stringa JSON, prova a parsarla
        station_id = "S01700"  # fallback
        if "S0" in station_id_raw:
            # Estrai il codice stazione dalla stringa
            import_idx = station_id_raw.find("S0")
            if import_idx >= 0:
                station_id = station_id_raw[import_idx:import_idx + 6]
    else:
        station_id = station_id_raw

    station_name = config.get("station_name", "Milano Centrale")
    destination_filter = config.get("destination_filter", "").upper().strip()
    train_number_filter = config.get("train_number", "").strip()
    num_trains = min(int(config.get("num_trains", "3")), 9)  # max 9 treni
    page_duration = int(config.get("page_duration", "3"))

    # Ottieni le partenze
    departures = get_departures(station_id)

    if departures == None:
        return render_error("Errore API")

    if len(departures) == 0:
        return render_error("Nessun treno")

    # Filtra treni già passati (considerando il ritardo + 5 min di margine)
    now = time.now()
    now_ts = now.unix * 1000  # timestamp in millisecondi
    margin_ms = 5 * 60 * 1000  # 5 minuti di margine
    filtered_departures = []
    for d in departures:
        orario_ms = d.get("orarioPartenza", 0)
        ritardo = d.get("ritardo", 0) or 0

        # Orario effettivo = orario previsto + ritardo + margine
        orario_effettivo_ms = orario_ms + (ritardo * 60 * 1000) + margin_ms
        if orario_effettivo_ms > now_ts:
            filtered_departures.append(d)
    departures = filtered_departures

    # Filtra per destinazione se specificato (supporta filtri multipli separati da virgola)
    if destination_filter:
        filters = [f.strip() for f in destination_filter.split(",")]
        filtered = []
        for d in departures:
            dest = d.get("destinazione", "").upper()
            for f in filters:
                if f in dest:
                    filtered.append(d)
                    break
        departures = filtered

    # Filtra per numero treno se specificato
    if train_number_filter:
        departures = [
            d
            for d in departures
            if str(d.get("numeroTreno", "")) == train_number_filter
        ]

    if len(departures) == 0:
        filter_text = destination_filter or train_number_filter
        return render_error("Nessun " + filter_text[:8])

    # Prendi i treni richiesti
    trains_to_show = departures[:num_trains]

    # TEST: Simula primo treno cancellato e secondo con ritardo (RIMUOVERE DOPO TEST)
    # if len(trains_to_show) > 0:
    #     trains_to_show[0]["provvedimento"] = 1  # CANCELLATO
    # if len(trains_to_show) > 1:
    #     trains_to_show[1]["ritardo"] = 25  # 25 min ritardo

    # Costruisci la UI
    train_rows = []
    for train in trains_to_show:
        train_rows.append(render_train_row(train))

    # Se più di 3 treni, crea animazione che mostra gruppi di 3
    if num_trains > 3:
        pages = []

        # Crea frame per ogni "pagina" di 3 treni
        for start in range(0, len(train_rows), 3):
            page_rows = train_rows[start:start + 3]

            # Aggiungi righe vuote se necessario per riempire
            for _ in range(3 - len(page_rows)):
                page_rows.append(render.Box(width = 64, height = 8))
            pages.append(render.Column(children = page_rows))

        # Crea frame ripetuti per ogni pagina (20 frame = ~1 sec)
        frames_per_page = page_duration * 20
        frames = []
        for page in pages:
            for _ in range(frames_per_page):
                frames.append(page)

        train_list = render.Animation(children = frames)
    else:
        train_list = render.Column(
            expanded = True,
            children = train_rows,
        )

    return render.Root(
        max_age = 60,
        child = render.Column(
            expanded = True,
            main_align = "start",
            children = [
                # Header con nome stazione
                render.Box(
                    width = 64,
                    height = 8,
                    color = "#1a1a2e",
                    child = render.Padding(
                        pad = (1, 1, 1, 0),
                        child = render.Marquee(
                            width = 62,
                            child = render.Text(
                                station_name.upper(),
                                font = "tom-thumb",
                                color = COLOR_WHITE,
                            ),
                        ),
                    ),
                ),
                # Lista treni (con scroll se > 3)
                train_list,
            ],
        ),
    )

def render_error(message):
    """Renderizza un messaggio di errore."""
    return render.Root(
        child = render.Box(
            render.Column(
                expanded = True,
                main_align = "center",
                cross_align = "center",
                children = [
                    render.Text("TRENITALIA", font = "tom-thumb", color = COLOR_RED),
                    render.Box(width = 64, height = 3),
                    render.Text(message, font = "tom-thumb", color = COLOR_GRAY),
                ],
            ),
        ),
    )

def render_train_row(train):
    """Renderizza una riga per un treno."""
    categoria = train.get("categoria", "")
    destinazione = train.get("destinazione", "---")
    orario_ms = train.get("orarioPartenza", 0)
    ritardo = train.get("ritardo", 0)
    provvedimento = train.get("provvedimento", 0)

    # Colore categoria
    cat_color = CATEGORY_COLORS.get(categoria.upper(), COLOR_GRAY)

    # Converti timestamp in orario
    if orario_ms and orario_ms > 0:
        orario = time.from_timestamp(int(orario_ms / 1000))
        orario_str = orario.format("15:04")
    else:
        orario_str = "--:--"

    # Determina stato e colore ritardo
    is_cancelled = provvedimento == 1

    if is_cancelled:
        ritardo_text = "CANC"
        ritardo_color = COLOR_RED
    elif ritardo and ritardo > 0:
        ritardo_text = "+%d'" % ritardo
        if ritardo >= 30:
            ritardo_color = COLOR_RED
        elif ritardo >= 10:
            ritardo_color = COLOR_ORANGE
        else:
            ritardo_color = COLOR_YELLOW
    elif ritardo and ritardo < 0:
        ritardo_text = "%d'" % ritardo  # anticipo
        ritardo_color = COLOR_GREEN
    else:
        ritardo_text = "OK"
        ritardo_color = COLOR_GREEN

    # Colore testo principale
    text_color = COLOR_GRAY if is_cancelled else COLOR_WHITE

    # Layout: ● 17:24 TREVIGLIO  +25'
    return render.Box(
        width = 64,
        height = 8,
        child = render.Row(
            expanded = True,
            main_align = "space_between",
            cross_align = "center",
            children = [
                # Sinistra: pallino + orario + destinazione (con scroll)
                render.Row(
                    cross_align = "center",
                    children = [
                        render.Box(width = 1, height = 1),
                        render.Box(width = 3, height = 3, color = cat_color),
                        render.Box(width = 2, height = 1),
                        render.Text(orario_str, font = "tom-thumb", color = text_color),
                        render.Box(width = 2, height = 1),
                        render.Marquee(
                            width = 24,
                            child = render.Text(abbreviate_station(destinazione), font = "tom-thumb", color = text_color),
                        ),
                    ],
                ),
                # Destra: ritardo
                render.Padding(
                    pad = (0, 0, 1, 0),
                    child = render.Text(ritardo_text, font = "tom-thumb", color = ritardo_color),
                ),
            ],
        ),
    )

def get_departures(station_id):
    """Ottiene le partenze da una stazione."""

    # Controlla cache
    cache_key = "departures_%s" % station_id
    cached = cache.get(cache_key)
    if cached:
        return json.decode(cached)

    # Giorni e mesi in inglese per il formato API
    days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

    now = time.now()

    weekday_str = now.format("Monday")
    day_idx = {"Sunday": 0, "Monday": 1, "Tuesday": 2, "Wednesday": 3, "Thursday": 4, "Friday": 5, "Saturday": 6}.get(weekday_str, 0)
    day_name = days[day_idx]

    month_str = now.format("January")
    month_idx = {"January": 0, "February": 1, "March": 2, "April": 3, "May": 4, "June": 5, "July": 6, "August": 7, "September": 8, "October": 9, "November": 10, "December": 11}.get(month_str, 0)
    month_name = months[month_idx]

    # Una sola chiamata API per velocità
    date_str = "%s %s %s %s %s GMT+0100" % (
        day_name,
        month_name,
        now.format("02"),
        now.format("2006"),
        now.format("15:04:05"),
    )

    url = "%s/partenze/%s/%s" % (VIAGGIATRENO_BASE, station_id, date_str)
    resp = http.get(url, ttl_seconds = 30)

    departures = []
    if resp.status_code == 200:
        body = resp.body()
        if body and body != "":
            trains = resp.json()
            if trains:
                departures = trains

    # Ordina per orario di partenza
    departures = sorted(departures, key = lambda x: x.get("orarioPartenza", 0))

    if departures and len(departures) > 0:
        cache.set(cache_key, json.encode(departures), ttl_seconds = 30)

    return departures if departures else []

def abbreviate_station(name):
    """Abbrevia il nome della stazione per adattarlo al display."""
    if not name:
        return "---"

    result = name.upper()

    # Abbreviazioni comuni - ordine importante (prima le più lunghe)
    abbreviations = {
        "MILANO PORTA GARIBALDI": "MI P.GAR",
        "MILANO CENTRALE": "MI C.LE",
        "MILANO CADORNA": "MI CAD",
        "ROMA TERMINI": "ROMA T.",
        "ROMA TIBURTINA": "ROMA TIB",
        "TORINO PORTA NUOVA": "TO P.N.",
        "FIRENZE S.M.N.": "FI SMN",
        "FIRENZE SANTA MARIA NOVELLA": "FI SMN",
        "VENEZIA S. LUCIA": "VE S.L.",
        "VENEZIA SANTA LUCIA": "VE S.L.",
        "NAPOLI CENTRALE": "NA C.LE",
        "BOLOGNA CENTRALE": "BO C.LE",
        "GENOVA PIAZZA PRINCIPE": "GE P.PR",
        "CENTRALE": "C.LE",
        "PORTA NUOVA": "P.N.",
        "PORTA GARIBALDI": "P.GAR",
        "PIAZZA PRINCIPE": "P.PR",
        " NORD": " N",
        " SUD": " S",
    }

    for full, abbr in abbreviations.items():
        result = result.replace(full, abbr)

    return result

def search_stations(pattern):
    """Cerca stazioni per nome."""
    if not pattern or len(pattern) < 2:
        return [
            schema.Option(display = station[0], value = station[1])
            for station in DEFAULT_STATIONS
        ]

    url = "%s/autocompletaStazione/%s" % (VIAGGIATRENO_BASE, pattern.upper())
    resp = http.get(url, ttl_seconds = 300)

    if resp.status_code != 200:
        return [
            schema.Option(display = station[0], value = station[1])
            for station in DEFAULT_STATIONS
        ]

    body = resp.body()
    if not body:
        return []

    lines = body.split("\n")
    options = []

    for line in lines:
        if "|" in line:
            parts = line.split("|")
            if len(parts) >= 2:
                name = parts[0].strip()
                code = parts[1].strip()
                if name and code:
                    options.append(schema.Option(display = name, value = code))

    return options[:15]

def get_schema():
    """Define configuration schema."""
    return schema.Schema(
        version = "1",
        fields = [
            schema.Typeahead(
                id = "station_id",
                name = "Departure Station",
                desc = "Search and select station",
                icon = "trainSubway",
                handler = search_stations,
            ),
            schema.Text(
                id = "station_name",
                name = "Station Name",
                desc = "Name shown in header",
                icon = "tag",
                default = "Milano Centrale",
            ),
            schema.Text(
                id = "destination_filter",
                name = "Destination Filter",
                desc = "Filter by destinations (comma separated)",
                icon = "locationArrow",
                default = "",
            ),
            schema.Text(
                id = "train_number",
                name = "Train Number",
                desc = "Show only this specific train",
                icon = "hashtag",
                default = "",
            ),
            schema.Text(
                id = "num_trains",
                name = "Number of Trains",
                desc = "How many trains to show (max 9)",
                icon = "list",
                default = "3",
            ),
            schema.Text(
                id = "page_duration",
                name = "Page Duration (sec)",
                desc = "Seconds per page if >3 trains",
                icon = "clock",
                default = "3",
            ),
        ],
    )
