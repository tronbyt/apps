"""
Applet: USDebtClock
Summary: Displays the US total debt
Description: Displays the total debt by the United States of America in dollars.
Author: PMK (@pmk)
"""

load("http.star", "http")
load("humanize.star", "humanize")
load("images/background_image.gif", BACKGROUND_IMAGE_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

BACKGROUND_IMAGE = BACKGROUND_IMAGE_ASSET.readall()

DEFAULT_IS_ANIMATING = True
DEFAULT_HAS_BACKGROUND_IMAGE = True

FRAMES_PER_SECOND = 30

NUMBER_SUFFIX = ["trillion", "billion", "million", "thousand", "dollar debt"]

def get_data(ttl_seconds = 60 * 60 * 6):
    url = "https://api.fiscaldata.treasury.gov/services/api/fiscal_service/v2/accounting/od/debt_to_penny?sort=-record_date&format=json&page%5Bnumber%5D=1&page%5Bsize%5D=2"
    response = http.get(url = url, ttl_seconds = ttl_seconds)
    if response.status_code != 200:
        fail("Treasury.gov request failed with status %d", response.status_code)
    return response.json()

def convert_to_chunks_by_thousands_separator(big_float_number):
    return humanize.comma(int(float(big_float_number))).split(",")

def convert_duration_to_seconds(duration):
    return int(duration / time.second)

def get_current_debt(raw_data, fr):
    latest_debt = int(float(raw_data[0]["tot_pub_debt_out_amt"]))
    previous_debt = int(float(raw_data[1]["tot_pub_debt_out_amt"]))

    latest_date = time.parse_time(raw_data[0]["record_date"] + "T00:00:00.00Z")
    previous_date = time.parse_time(raw_data[1]["record_date"] + "T00:00:00.00Z")

    diff_number_latest_previous = latest_debt - previous_debt
    diff_number_latest_previous_per_second = int(diff_number_latest_previous / convert_duration_to_seconds(latest_date - previous_date))
    diff_current_latest_in_seconds = convert_duration_to_seconds(time.now() - latest_date)

    return latest_debt + diff_number_latest_previous_per_second + ((diff_current_latest_in_seconds / FRAMES_PER_SECOND) * fr)

def render_content(raw_data, fr):
    total_debt = get_current_debt(raw_data, fr)
    total_debt_chunks = convert_to_chunks_by_thousands_separator(total_debt)

    rows = []
    for idx, c in enumerate(total_debt_chunks):
        rows.append(
            render.Row(
                expanded = True,
                children = [
                    render.Box(
                        width = 12,
                        height = 6,
                        child = render.Row(
                            expanded = True,
                            main_align = "end",
                            children = [
                                render.Text(
                                    content = "{}".format(int(c)),
                                    font = "tom-thumb",
                                ),
                            ],
                        ),
                    ),
                    render.Padding(
                        pad = (3, 0, 0, 0),
                        child = render.Row(
                            expanded = True,
                            main_align = "start",
                            children = [
                                render.Text(
                                    content = NUMBER_SUFFIX[idx],
                                    font = "tom-thumb",
                                ),
                            ],
                        ),
                    ),
                ],
            ),
        )
    return render.Column(
        children = rows,
    )

def render_animated_content(raw_data):
    return render.Animation(
        children = [
            render_content(raw_data, fr)
            for fr in range(1500)
        ],
    )

def main(config):
    is_animating = config.bool("is_animating", DEFAULT_IS_ANIMATING)
    has_background_image = config.bool("has_background_image", DEFAULT_HAS_BACKGROUND_IMAGE)

    raw_data = get_data()["data"]

    conditional_background_image_elements = []
    if has_background_image:
        conditional_background_image_elements.append(
            render.Stack(
                children = [
                    render.Padding(
                        pad = (-5, -9, 0, 0),
                        child = render.Image(
                            src = BACKGROUND_IMAGE,
                            width = 68,
                            height = 50,
                        ),
                    ),
                    render.Box(
                        width = 64,
                        height = 32,
                        color = "#000B",
                    ),
                ],
            ),
        )

    conditional_background_image_elements.append(
        render.Padding(
            pad = (3, 1, 0, 0),
            child = render_animated_content(raw_data) if is_animating else render_content(raw_data, 1),
        ),
    )

    return render.Root(
        delay = FRAMES_PER_SECOND,
        child = render.Stack(
            children = conditional_background_image_elements,
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "has_background_image",
                name = "Show background image?",
                desc = "Will show the animated background image.",
                default = True,
                icon = "user",
            ),
            schema.Toggle(
                id = "is_animating",
                name = "Show animation?",
                desc = "Will animate the numbers.",
                default = True,
                icon = "user",
            ),
        ],
    )
