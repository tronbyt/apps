"""
Applet: WorldCapitals
Summary: Displays a world capital
Description: Displays a world capital each day for a specific country.
Author: Jake Manske
"""

load("flags/DEFAULT.png", DEFAULT_FLAG = "file")
load("flags.star", "FLAGS")
load("http.star", "http")
load("random.star", "random")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

COUNTRIES_REST_ENDPOINT_ALL = "https://restcountries.com/v3.1/all?fields=name,cca3,capital,translations,flags"
COUNTRIES_REST_ENDPOINT_REGION = "https://restcountries.com/v3.1/region/{0}?fields=name,cca3,capital,translations,flags"

# start on Jan 1 2023
REFERENCE_DATE = time.parse_time("2023-01-01T00:00:00Z")

# other config
HTTP_OK = 200
CACHE_TIMEOUT = 24 * 3600  #  24 hours

def main(config):
    """ gets the country based on the current configuration

    Args:
        config (dict): configuration for the app
    Returns:
        widget to display
    """

    scale = 2 if canvas.is2x() else 1
    font = "terminus-12" if scale == 2 else "tom-thumb"

    # get current country index
    # it will be the number of hours since the reference date
    frequency = int(config.get("frequency", "24"))
    country_index = int((time.now() - REFERENCE_DATE).hours // frequency) if frequency != 0 else -1

    # get the region selected
    region = config.get("region") or "all"

    # get the country for the current config
    country = get_country(region, country_index)

    # parse country information
    capital_city = country.get("capital")
    if capital_city:
        # capitals are an array, grab the first one
        capital_city = capital_city[0]
    else:
        capital_city = "No Capital City"

    # get the common name
    lang = config.get("language") or "eng"
    if lang == "eng":
        country_name = country.get("name")
    elif lang == "native":
        native_names = country.get("name").get("nativeName")

        # native names are in a dictionary, grab the first one
        country_name = native_names.values()[0]
    else:
        country_name = country.get("translations").get(lang)
    if not country_name:
        country_name = country.get("name")
    country_name = country_name.get("common")

    # look up the flag
    flag = get_flag(country)

    # render the widget
    return render.Root(
        child = render.Column(
            main_align = "center",
            cross_align = "center",
            expanded = True,
            children = [
                render.Marquee(
                    align = "center",
                    child = render.Text(
                        content = country_name,
                        font = font,
                    ),
                    width = canvas.width(),
                ),
                render.Image(
                    src = flag,
                    height = 19 * scale,
                ),
                render.Box(
                    height = 1 * scale,
                ),
                render.Marquee(
                    align = "center",
                    child = render.Text(
                        content = capital_city,
                        font = font,
                    ),
                    width = canvas.width(),
                ),
            ],
        ),
    )

def get_country(region, country_index):
    """ gets the country based on the current configuration

    Args:
        region (string): the region we are limited to
        country_index (int): the index of the country we are processing
    Returns:
        a dict "country" object
    """

    # get the URL based on region selected
    url = get_url(region)

    # ping it
    response = http.get(url, ttl_seconds = CACHE_TIMEOUT)

    # check status code
    if response.status_code != HTTP_OK:
        # if we are not OK, return the default country with information about the failure
        country = {
            "name": {
                "common": "HTTP ERROR",
            },
            "cca3": "N/A",
            "capital": ["ERROR CODE: " + str(response.status_code)],
        }
    else:
        # parse response object and sort it so we can get the right country in the loop
        countries = response.json()
        sorted_countries = sorted(countries, get_cca3)

        # count how many results we have
        num_countries = len(sorted_countries)

        # get the country based on index modulo how many countries there are for this region
        if country_index < 0:
            country_index = random.number(0, num_countries - 1)
        else:
            country_index = country_index % num_countries
        country = sorted_countries[country_index]

    return country

def get_schema():
    options = [
        schema.Option(
            display = "All",
            value = "all",
        ),
        schema.Option(
            display = "Africa",
            value = "africa",
        ),
        schema.Option(
            display = "Americas",
            value = "americas",
        ),
        schema.Option(
            display = "Asia",
            value = "asia",
        ),
        schema.Option(
            display = "Europe",
            value = "europe",
        ),
        schema.Option(
            display = "Oceania",
            value = "oceania",
        ),
    ]

    languages = [
        schema.Option(
            display = "English",
            value = "eng",
        ),
        schema.Option(
            display = "Native",
            value = "native",
        ),
        schema.Option(
            display = "German",
            value = "deu",
        ),
        schema.Option(
            display = "French",
            value = "fra",
        ),
        schema.Option(
            display = "Italian",
            value = "ita",
        ),
        schema.Option(
            display = "Japanese",
            value = "jpn",
        ),
        schema.Option(
            display = "Spanish",
            value = "spa",
        ),
    ]

    frequency = [
        schema.Option(
            display = "Daily",
            value = "24",
        ),
        schema.Option(
            display = "Hourly",
            value = "1",
        ),
        schema.Option(
            display = "Everytime",
            value = "0",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "region",
                name = "Region",
                desc = "Limit world capitals to this region.",
                icon = "globe",
                default = "all",  # use all as the default
                options = options,
            ),
            schema.Dropdown(
                id = "language",
                name = "Language",
                desc = "The language to use for the country name.",
                icon = "language",
                default = "eng",
                options = languages,
            ),
            schema.Dropdown(
                id = "frequency",
                name = "Frequency",
                desc = "How often to display a different country.",
                icon = "repeat",
                default = "24",
                options = frequency,
            ),
        ],
    )

def get_cca3(country):
    return country.get("cca3")

def get_url(region):
    if region == "all":
        return COUNTRIES_REST_ENDPOINT_ALL
    else:
        return COUNTRIES_REST_ENDPOINT_REGION.format(region)

def get_flag(country):
    """ gets the flag based on the country

    Args:
        country (string): the country whose flag we need
    Returns:
        a flag image as bytes
    """

    # try to get the flag from the URL first
    url = country.get("flags").get("png")
    if url:
        response = http.get(url, ttl_seconds = CACHE_TIMEOUT)
        if response.status_code == 200:
            return response.body()

    # fallback to built-in flags
    country_code = get_cca3(country)
    flag = FLAGS.get(country_code) or DEFAULT_FLAG
    return flag.readall()
