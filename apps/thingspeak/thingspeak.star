load("http.star", "http")
load("images/thingspeak_icon.png", THINGSPEAK_ICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

THINGSPEAK_ICON = THINGSPEAK_ICON_ASSET.readall()

# Load Thingspeak icon from base64 encoded data

# Learn more about error codes
# https://www.mathworks.com/help/thingspeak/error-codes.html
def renderErrorHelp(config, resp):
    errorMsg = "Something went wrong, check your settings."
    errorDetails = resp.data
    if errorDetails == -1:
        errorMsg = "Is your channel private? Did you provide an API key?"
    if config.str("channelId", None) == None:
        errorMsg = "Add a channelId to get started :)"

    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "space_around",
            cross_align = "center",
            children = [
                render.Marquee(
                    width = 64,
                    height = 32,
                    align = "start",
                    child = render.Text(errorMsg),
                ),
            ],
        ),
    )

# get data or used cached value for desired render
def getData(config):
    # get settings from user config
    config_channel_id = config.str("channelId", None)
    field_id = config.str("fieldId", "1")
    get_last = "" if config.bool("renderPlotView") else "/last"

    # set up params for api call
    # see also: https://www.mathworks.com/help/thingspeak/rest-api.html
    THINGSPEAK_CHANNEL_URL_ENDPOINT = "https://api.thingspeak.com/channels/{}/fields/{}{}.json".format(config_channel_id, field_id, get_last)
    headers = {
        "Content-Type": "application/json",
        "User-Agent": "Tidbyt App: Thingspeak channel data",
    }

    params = {
        "api_key": config.str("apiKey", ""),
        "results": "6000",  # increases odds you will get some results if there's infrequent data in a field
        # some fields may only get data once a day. TODO consider exposing settings for api filters?
    }

    resp = http.get(THINGSPEAK_CHANNEL_URL_ENDPOINT, params = params, headers = headers, ttl_seconds = 60)

    return struct(status_code = resp.status_code, data = resp.json())

def renderBottomContent(config, resp):
    # get fieldKey for configured from config eg: field1
    fieldKey = "field{}".format(config.str("fieldId", "1"))

    if config.bool("renderPlotView", False):
        validResultValues = []

        # filter out null values that may exist in response
        for result in resp.data.get("feeds"):
            resultValue = result.get(fieldKey)
            if resultValue != None:
                validResultValues.append(float(resultValue))
                if len(validResultValues) > 64:
                    break  # bail 64 is enough of data for 64 px

        return render.Plot(
            data = enumerate(validResultValues),
            width = 64,
            height = 16,
            color = "#3584B2",  # thingspeak hex color 💬
            x_lim = (0, len(validResultValues) - 1),
            y_lim = (min(validResultValues), max(validResultValues)),
            fill = True,
        )

    return render.Marquee(
        width = 64,
        height = 16,
        align = "start",
        child = render.Text("{prepend} {value}".format(prepend = config.str("prepend"), value = resp.data.get(fieldKey))),
    )

def main(config):
    print("Running Thingspeak app")
    resp = getData(config)
    if resp.status_code != 200:
        print("Thingspeak API request failed with status", resp.status_code)
        return renderErrorHelp(config, resp)

    return render.Root(
        child = render.Column(
            expanded = True,
            main_align = "space_around",
            cross_align = "center",
            children = [
                render.Row(
                    children = [
                        render.Image(src = THINGSPEAK_ICON),
                        render.Marquee(
                            width = 48,
                            height = 16,
                            align = "start",
                            child = render.Text(config.str("title", "No value given")),
                        ),
                    ],
                    cross_align = "center",
                ),
                renderBottomContent(config = config, resp = resp),
            ],
        ),
    )

def get_schema():
    fieldOptions = [
        schema.Option(
            display = "Field 1",
            value = "1",
        ),
        schema.Option(
            display = "Field 2",
            value = "2",
        ),
        schema.Option(
            display = "Field 3",
            value = "3",
        ),
        schema.Option(
            display = "Field 4",
            value = "4",
        ),
        schema.Option(
            display = "Field 5",
            value = "5",
        ),
        schema.Option(
            display = "Field 6",
            value = "6",
        ),
        schema.Option(
            display = "Field 7",
            value = "7",
        ),
        schema.Option(
            display = "Field 8",
            value = "8",
        ),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "channelId",
                name = "Thingspeak Channel Id",
                desc = "The id of the thingspeak channel.",
                icon = "rss",
                default = "2203073",
            ),
            schema.Text(
                id = "apiKey",
                name = "Read API Key",
                desc = "A read API key if the channel is private.",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "title",
                name = "Title",
                desc = "Title text next to the Thingspeak logo",
                default = "Thingspeak",
                icon = "tag",
            ),
            schema.Toggle(
                id = "renderPlotView",
                name = "Render as a plot view",
                desc = "Should the app render as a plot view",
                icon = "chartLine",
                default = True,
            ),
            schema.Text(
                id = "prepend",
                name = "Text to add before the value",
                desc = "Text to add before the value",
                icon = "tag",
                default = "Your selected field value is",
            ),
            schema.Dropdown(
                id = "fieldId",
                name = "field",
                desc = "The field from your selected channel",
                icon = "tableCellsLarge",
                default = fieldOptions[0].value,
                options = fieldOptions,
            ),
        ],
    )
