"""
Applet: Reading Challenge
Summary: Goodreads challenge tracker
Description: Displays progress towards your Goodreads yearly goal, navigate to your goodreads.com/user_challenges/{id} to get your challenge id from the URL.
Author: panderson54
"""

load("http.star", "http")
load("images/five_book_icon.png", FIVE_BOOK_ICON_ASSET = "file")
load("images/one_closed_book_icon.png", ONE_CLOSED_BOOK_ICON_ASSET = "file")
load("images/one_open_book_icon.png", ONE_OPEN_BOOK_ICON_ASSET = "file")
load("images/three_book_icon.png", THREE_BOOK_ICON_ASSET = "file")
load("re.star", "re")
load("render.star", "render")
load("schema.star", "schema")

FIVE_BOOK_ICON = FIVE_BOOK_ICON_ASSET.readall()
ONE_CLOSED_BOOK_ICON = ONE_CLOSED_BOOK_ICON_ASSET.readall()
ONE_OPEN_BOOK_ICON = ONE_OPEN_BOOK_ICON_ASSET.readall()
THREE_BOOK_ICON = THREE_BOOK_ICON_ASSET.readall()

GOODREADS_PROGRESS_URL = "https://www.goodreads.com/user_challenges/"

def gen_book_image(progress):
    if progress <= 0:
        images = render.Row(main_align = "center", cross_align = "end", expanded = True, children = [
            render.Image(src = ONE_OPEN_BOOK_ICON, height = 15, width = 25),
        ])
    elif progress == 1:
        images = render.Row(main_align = "start", cross_align = "end", expanded = True, children = [
            render.Image(src = ONE_CLOSED_BOOK_ICON, height = 15, width = 12),
        ])
    elif progress == 2:
        images = render.Row(main_align = "center", cross_align = "end", expanded = True, children = [
            render.Image(src = THREE_BOOK_ICON, height = 22, width = 20),
        ])
    elif progress == 3:
        images = render.Row(main_align = "center", cross_align = "end", expanded = True, children = [
            render.Image(src = THREE_BOOK_ICON, height = 13, width = 20),
        ])
    elif progress == 4:
        images = render.Row(main_align = "center", cross_align = "end", expanded = True, children = [
            render.Image(src = THREE_BOOK_ICON, height = 13, width = 20),
            render.Padding(child = render.Image(src = ONE_OPEN_BOOK_ICON, height = 15, width = 25), pad = (3, 0, 0, 0)),
        ])
    elif progress == 5:
        images = render.Row(main_align = "start", cross_align = "end", expanded = True, children = [
            render.Image(src = FIVE_BOOK_ICON, height = 15, width = 20),
        ])
    elif progress == 6:
        images = render.Row(main_align = "center", cross_align = "end", expanded = True, children = [
            render.Image(src = THREE_BOOK_ICON, height = 10, width = 15),
            render.Image(src = THREE_BOOK_ICON, height = 13, width = 20),
        ])
    elif progress == 7:
        images = render.Row(main_align = "center", cross_align = "end", expanded = True, children = [
            render.Image(src = FIVE_BOOK_ICON, height = 13, width = 20),
            render.Padding(child = render.Image(src = ONE_CLOSED_BOOK_ICON, height = 15, width = 10), pad = (3, 0, 0, 0)),
            render.Padding(child = render.Image(src = ONE_OPEN_BOOK_ICON, height = 15, width = 25), pad = (2, 0, 0, 0)),
        ])

    elif progress == 8:
        images = render.Row(main_align = "center", cross_align = "end", expanded = True, children = [
            render.Image(src = THREE_BOOK_ICON, height = 13, width = 20),
            render.Image(src = FIVE_BOOK_ICON, height = 15, width = 20),
        ])
    elif progress == 9:
        images = render.Row(main_align = "center", cross_align = "end", expanded = True, children = [
            render.Image(src = THREE_BOOK_ICON, height = 13, width = 20),
            render.Image(src = THREE_BOOK_ICON, height = 13, width = 20),
            render.Image(src = THREE_BOOK_ICON, height = 13, width = 20),
        ])
    elif progress == 10:
        images = render.Row(main_align = "center", cross_align = "end", expanded = True, children = [
            render.Image(src = FIVE_BOOK_ICON, height = 15, width = 20),
            render.Image(src = FIVE_BOOK_ICON, height = 15, width = 20),
        ])
    elif progress == 11:
        images = render.Row(main_align = "center", cross_align = "end", expanded = True, children = [
            render.Image(src = FIVE_BOOK_ICON, height = 15, width = 20),
            render.Image(src = FIVE_BOOK_ICON, height = 15, width = 20),
            render.Padding(child = render.Image(src = ONE_CLOSED_BOOK_ICON, height = 15, width = 12), pad = (1, 0, 0, 0)),
        ])

    elif progress == 12:
        images = render.Row(main_align = "center", cross_align = "end", expanded = True, children = [
            render.Image(src = FIVE_BOOK_ICON, height = 12, width = 18),
            render.Image(src = THREE_BOOK_ICON, height = 22, width = 20),
            render.Image(src = FIVE_BOOK_ICON, height = 16, width = 10),
        ])
    else:
        images = render.Row(main_align = "center", cross_align = "end", expanded = True, children = [
            render.Image(src = FIVE_BOOK_ICON, height = 15, width = 20),
            render.Image(src = FIVE_BOOK_ICON, height = 14, width = 20),
            render.Image(src = FIVE_BOOK_ICON, height = 12, width = 18),
            render.Image(src = FIVE_BOOK_ICON, height = 16, width = 10),
        ])

    return images

def main(config):
    CHALLENGE_ID = config.str("user_challenge_id", "38950148")

    challenge_page = http.get(GOODREADS_PROGRESS_URL + CHALLENGE_ID, ttl_seconds = 86400)

    if challenge_page.status_code != 200:
        fail("Request failed with status %d", challenge_page.status_code)

    body = challenge_page.body()
    progress_div = re.findall(r"<div class='progressText'>([\s\S]*?)</div>", body)

    if not progress_div:
        fail("No challenge found at {}".format(config.str("user_challenge_id", CHALLENGE_ID)))

    progress_nums = re.findall(r"\d+", progress_div[0])
    progress = progress_nums[0]
    goal = progress_nums[1]

    progress_text = " ".join(["Read:", str(progress), "books."])
    goal_text = " ".join(["Goal:", str(goal), "books."])

    images = gen_book_image(int(progress))

    lines = [
        render.Text(content = progress_text),
        render.Text(content = goal_text),
        render.Padding(child = images, pad = (0, 1, 0, 0)),
    ]

    return render.Root(
        child = render.Column(
            main_align = "space_around",
            children = lines,
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "user_challenge_id",
                name = "Challenge ID",
                desc = "Navigate goodreads.com/user_challenges and get this from the URL",
                icon = "key",
            ),
        ],
    )
