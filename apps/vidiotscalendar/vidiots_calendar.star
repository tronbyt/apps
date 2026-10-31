"""
Applet: Vidiots Calendar
Summary: Showtimes for Vidiots (LA)
Description: Movie showtimes for Vidiots theater in Los Angeles, CA.
Author: Buzz Andersen
"""

load("html.star", "html")
load("http.star", "http")
load("images/vidiots_logo.png", VIDIOTS_LOGO_ASSET = "file")
load("math.star", "math")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

VIDIOTS_LOGO = VIDIOTS_LOGO_ASSET.readall()

VIDIOTS_URL = "https://vidiotsfoundation.org/coming-soon/"
ANIMATION_DELAY = 50
SEVEN_DAY_DURATION = "168h"
THIRTY_DAY_DURATION = "720h"
MOVIE_PAGE_SIZE = 5
TITLE_CHARACTER_LIMIT = 32

def main(config):
    response = http.get(VIDIOTS_URL, ttl_seconds = 240)

    if response.status_code != 200:
        fail("Vidiots request failed with status %d", response.status_code)

    date_limit_config = config.str(DATE_LIMIT_CONFIG_KEY, SEVEN_DAYS_CONFIG_KEY)
    if date_limit_config == THIRTY_DAYS_CONFIG_KEY:
        date_limit_duration = THIRTY_DAY_DURATION
    else:
        date_limit_duration = SEVEN_DAY_DURATION

    movies = parse_movie_html(response.body(), date_limit_duration)
    movie_count = len(movies)

    pages = []
    if movie_count >= MOVIE_PAGE_SIZE and config.bool(RANDOM_PAGINATION_CONFIG_KEY, False):
        page_count = math.floor(movie_count / MOVIE_PAGE_SIZE)

        for i in range(math.floor(page_count)):
            index = MOVIE_PAGE_SIZE * i
            pages.append(range(index, index + MOVIE_PAGE_SIZE))

        last_segment_index = movie_count - MOVIE_PAGE_SIZE
        pages.append(range(last_segment_index, last_segment_index + MOVIE_PAGE_SIZE))
    else:
        pages.append(range(0, movie_count))

    page_selection = pages[random.number(0, len(pages) - 1)]

    selected_movies = []
    for i in page_selection:
        selected_movies.append(movies[i])

    return render_animation_for_movies(selected_movies, config.bool(FULL_ANIMATION_CONFIG_KEY, False))

def parse_movie_html(html_body, date_limit_duration):
    movie_list = html(html_body).find("#upcoming-films").children_filtered(".show-list").children_filtered(".show-details")

    date_now = time.now()
    date_limit = date_now + time.parse_duration(date_limit_duration)

    movies = []

    for i in range(movie_list.len()):
        details = movie_list.eq(i)
        title = details.find(".title").text()
        dates = details.find(".single-show-showtimes").children_filtered(".showtimes-container").children_filtered(".showtimes").children_filtered("li")

        valid_dates = {}

        for i in range(dates.len()):
            date_info = dates.eq(i)

            epoch = int(date_info.attr("data-date"))
            date = time.from_timestamp(epoch)

            showtime = date_info.children_filtered(".showtime")

            showtime_extra_text = showtime.children_filtered(".extra").text().strip()
            showtime_text = showtime.text().replace("\n", "").replace("\t", "").replace(showtime_extra_text, "").strip()

            is_past = date.unix < date_now.unix
            is_beyond_limit = date.unix > date_limit.unix

            if is_past == False and is_beyond_limit == False:
                if valid_dates.get(epoch) == None:
                    valid_dates[epoch] = []
                valid_dates[epoch].append(struct(date = date.format("Mon, Jan 2") + " - " + showtime_text, extra = showtime_extra_text.replace("*", "")))

        if len(valid_dates) > 0:
            current_movie = struct(title = title, dates = valid_dates)
            movies.append(current_movie)

    return movies

def render_animation_for_movies(movies, full_animation):
    movie_count = len(movies)

    movie_nodes = []

    for i in range(movie_count):
        current_movie = movies[i]

        time_nodes = []

        dates_count = len(current_movie.dates)
        for j in range(len(current_movie.dates)):
            current_date = current_movie.dates.items()[j]
            showtimes = current_date[1]
            first_time = showtimes[0]
            additional_count = len(showtimes) - 1

            time_string = first_time.date
            if additional_count > 0:
                time_string = time_string + " + " + str(additional_count) + " more"

            showtime_extra_text = ""
            if len(first_time.extra) > 0:
                showtime_extra_text = " (" + first_time.extra + ")"

            time_child_nodes = [
                render.Column(
                    children = [
                        render.Text(time_string),
                    ],
                ),
                render.Column(
                    children = [
                        render.Text(showtime_extra_text, color = "#ed1c24"),
                    ],
                ),
            ]

            if j < (dates_count - 1):
                time_child_nodes.append(
                    render.Text(" • "),
                )

            time_nodes.append(
                render.Row(
                    children = time_child_nodes,
                ),
            )

        current_title = current_movie.title
        if len(current_movie.title) > TITLE_CHARACTER_LIMIT:
            current_title = current_movie.title[:TITLE_CHARACTER_LIMIT] + "..."

        movie_nodes.append(
            render.Column(
                main_align = "center",
                children = [
                    render.Row(
                        children = [
                            render.Text(current_title, color = "#67bdee"),
                        ],
                    ),
                    render.Row(
                        children = time_nodes,
                    ),
                ],
            ),
        )

        if i < (movie_count - 1):
            movie_nodes.append(
                render.Padding(
                    pad = (4, 0, 4, 0),
                    child = render.Box(
                        width = 1,
                        height = 16,
                        color = "#ee7db8",
                    ),
                ),
            )

    return render.Root(
        delay = ANIMATION_DELAY,
        show_full_animation = full_animation,
        child = render.Padding(
            pad = (0, 0, 0, 2),
            child = render.Column(
                main_align = "start",
                cross_align = "start",
                children = [
                    render.Box(
                        height = 14,
                        child = render.Row(
                            children = [
                                render.Box(
                                    width = 14,
                                    child = render.Image(src = VIDIOTS_LOGO, width = 14, height = 14),
                                ),
                                render.Box(
                                    height = 14,
                                    child = render.Text("Vidiots", height = 10),
                                ),
                            ],
                        ),
                    ),
                    render.Marquee(
                        offset_start = 64,
                        offset_end = 64,
                        width = 64,
                        child = render.Row(
                            children = movie_nodes,
                        ),
                    ),
                ],
            ),
        ),
    )

def get_schema():
    date_limit_options = [
        schema.Option(
            display = "7 Days",
            value = SEVEN_DAYS_CONFIG_KEY,
        ),
        schema.Option(
            display = "30 Days",
            value = THIRTY_DAYS_CONFIG_KEY,
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = DATE_LIMIT_CONFIG_KEY,
                name = "Date Limit",
                desc = "Include showtimes within the next...",
                icon = "calendar",
                default = date_limit_options[0].value,
                options = date_limit_options,
            ),
            schema.Toggle(
                id = FULL_ANIMATION_CONFIG_KEY,
                name = "Show Full List",
                desc = "Request that Tidbyt show the full movie list rather than being limited to the normal app cycle time.",
                icon = "clock",
                default = False,
            ),
            schema.Toggle(
                id = RANDOM_PAGINATION_CONFIG_KEY,
                name = "Random Pagination",
                desc = "Split the entire movie list into pages and show a random page each time.",
                icon = "shuffle",
                default = False,
            ),
        ],
    )

DATE_LIMIT_CONFIG_KEY = "date_limit"
SEVEN_DAYS_CONFIG_KEY = "7_days"
THIRTY_DAYS_CONFIG_KEY = "30_days"
FULL_ANIMATION_CONFIG_KEY = "full_animation"
RANDOM_PAGINATION_CONFIG_KEY = "random_pagination"
