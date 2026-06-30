"""
Applet: GitHub Unread
Summary: GitHub notifications count
Description: Displays the count of unread GitHub notifications.
Author: ElliottAYoung
"""

load("http.star", "http")
load("images/github_image.png", GITHUB_IMAGE_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

GITHUB_IMAGE = GITHUB_IMAGE_ASSET.readall()

def fetch_notifications(access_token):
    return http.get(
        "https://api.github.com/notifications",
        headers = {"Accept": "application/vnd.github+json", "Authorization": "Bearer {}".format(access_token), "X-GitHub-Api-Version": "2022-11-28"},
        ttl_seconds = 60,
    )

def get_count(response):
    count = 0
    for obj in response:
        if (obj["unread"] == True):
            count += 1

    return count

def render_notifications(count):
    if count == 1:
        notification_word = "Notification"
    else:
        notification_word = "Notifications"

    return render.Root(
        child = render.Stack(
            children = [
                render.Padding(
                    pad = (0, 2, 0, 0),
                    child = render.Row(
                        expanded = True,
                        main_align = "space_around",
                        cross_align = "center",
                        children = [
                            render.Padding(
                                pad = (1, 1, 1, 1),
                                child = render.Image(GITHUB_IMAGE, height = 14),
                            ),
                            render.Text(str(count) + " Unread"),
                        ],
                    ),
                ),
                render.Row(
                    expanded = True,
                    main_align = "space_around",
                    cross_align = "center",
                    children = [
                        render.Padding(
                            pad = (0, 20, 0, 0),
                            child = render.Text(notification_word),
                        ),
                    ],
                ),
            ],
        ),
    )

def render_error(err):
    return render.Root(
        child = render.Stack(
            children = [
                render.Padding(
                    pad = (0, 2, 0, 0),
                    child = render.Row(
                        expanded = True,
                        main_align = "space_around",
                        cross_align = "center",
                        children = [
                            render.Padding(
                                pad = (1, 1, 1, 1),
                                child = render.Image(GITHUB_IMAGE, height = 14),
                            ),
                            render.WrappedText(str(err)),
                        ],
                    ),
                ),
            ],
        ),
    )

def main(config):
    """Main render function for the App
    Args:
        config: The schema config from TidByt
    Returns:
        A Root view to render to the app
    """
    access_token = config.get("access_token") or None

    if access_token:
        response = fetch_notifications(access_token)

        if response.status_code != 200:
            return render_error("Error with Access Token.")

        count = get_count(response.json())

        return render_notifications(count)
    else:
        return render_error("No Access Token.")

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "access_token",
                name = "Github Personal Access Token",
                desc = "Personal Access token",
                icon = "lock",
                secret = True,
            ),
        ],
    )
