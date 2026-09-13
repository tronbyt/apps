"""
Applet: Movie Challenge
Summary: Letterboxd watch progress
Description: This app shows your Letterboxd movie watching progress. It gets your Letterboxd list of watched movies, shows a counter of how many movies you've watched out of your goal (e.g., "42/100"), and displays a randomly selected movie from your list with its rating.
Author: caropinzonsilva
"""

load("html.star", "html")
load("http.star", "http")
load("images/film_icon.png", FILM_ICON_ASSET = "file")
load("images/half_star_icon.png", HALF_STAR_ICON_ASSET = "file")
load("images/movie_icon.png", MOVIE_ICON_ASSET = "file")
load("images/star_icon.png", STAR_ICON_ASSET = "file")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

FILM_ICON = FILM_ICON_ASSET.readall()
HALF_STAR_ICON = HALF_STAR_ICON_ASSET.readall()
MOVIE_ICON = MOVIE_ICON_ASSET.readall()
STAR_ICON = STAR_ICON_ASSET.readall()

# Schema definition for the app's configuration
def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            # Username field for Letterboxd account
            schema.Text(
                id = "letterboxd_username",
                name = "Letterboxd Username",
                desc = "Your Letterboxd username",
                icon = "user",
                default = "flanaganfilm",
            ),
            # List name field - extracted from the Letterboxd list URL
            schema.Text(
                id = "letterboxd_list_name",
                name = "Letterboxd list name",
                desc = "The list name taken from the URL of your Letterboxd list",
                icon = "link",
                default = "flanagans-best-of-2025",
            ),
            # Goal field for number of movies to watch
            schema.Text(
                id = "movie_goal",
                name = "Movie Goal",
                desc = "Your target number of movies to watch",
                icon = "film",
                default = "50",
            ),
        ],
    )

def main(config):
    # Get configuration values with defaults
    letterboxd_username = config.get("letterboxd_username", "flanaganfilm")
    letterboxd_list_name = config.get("letterboxd_list_name", "flanagans-best-of-2025")
    letterboxd_url = "https://letterboxd.com/%s/list/%s/detail/by/reverse/" % (letterboxd_username, letterboxd_list_name)
    movie_goal = int(config.get("movie_goal", "50"))

    # Fetch and parse the Letterboxd list page
    htmlstr = http.get(letterboxd_url).body()
    doc = html(htmlstr)
    watchedMovies = doc.find(".list-detailed-entry")

    # Display error message if no movies are found
    if watchedMovies.len() == 0:
        return render.Root(
            child = render.Box(
                color = "#709AD1",
                child = render.Column(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [
                        render.Marquee(
                            width = 64,
                            child = render.Text(
                                content = "No movies found - Check list URL and username",
                                color = "#ffffff",
                            ),
                        ),
                    ],
                ),
            ),
        )

    # Select a random movie from the list
    random_index = random.number(0, watchedMovies.len() - 1)
    movieDetails = watchedMovies.eq(random_index)
    movieName = movieDetails.find(".name").text()

    # Extract and process the movie's rating (if it exists)
    starImages = []
    ratingClass = movieDetails.find(".rating").attr("class")
    if ratingClass != None:
        ratingOverTen = int(ratingClass.split("rated-")[1])
        fullStars = int(ratingOverTen / 2)
        halfStars = ratingOverTen % 2

        # Add separator between movie name and rating
        starImages.append(render.Text(
            content = " - ",
            color = "#ffffff",
            font = "5x8",
        ))

        # Create list of star images based on rating
        for _i in range(fullStars):
            starImages.append(render.Image(src = STAR_ICON))
        if halfStars == 1:
            starImages.append(render.Image(src = HALF_STAR_ICON))

    # Calculate progress percentage for the progress bar
    percentage = watchedMovies.len() / movie_goal
    leftPadding = int((1 - percentage) * 128)

    # Render the main display
    return render.Root(
        child = render.Box(
            color = "#709AD1",
            child = render.Column(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    # Top row with movie counter and selected movie
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            # Movie icon
                            render.Image(src = MOVIE_ICON),
                            # Counter and movie details
                            render.Column(
                                children = [
                                    # Movies watched counter
                                    render.Text(
                                        content = "%d/%d" % (watchedMovies.len(), movie_goal),
                                        color = "#ffffff",
                                    ),
                                    # Scrolling movie name and rating
                                    render.Marquee(
                                        width = 40,
                                        child = render.Row(
                                            children = [
                                                render.Text(
                                                    content = "%s" % movieName,
                                                    color = "#ffffff",
                                                    font = "5x8",
                                                ),
                                            ] + starImages,  # Add rating stars if they exist
                                        ),
                                    ),
                                ],
                            ),
                        ],
                    ),
                    # Bottom progress bar
                    render.Padding(
                        pad = (0, 0, leftPadding, 0),  # (left, top, right, bottom)
                        child = render.Image(src = FILM_ICON),
                    ),
                ],
            ),
        ),
    )
