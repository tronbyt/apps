"""
Applet: Mastodon Follows
Summary: Mastodon Follower Count
Description: Display your follower count from a Mastodon instance.
Author: Nick Penree
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/mastodon_icon.png", MASTODON_ICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

MASTODON_ICON = MASTODON_ICON_ASSET.readall()

def main(config):
    username = config.get("username", "lisamelton")

    if username.startswith("@"):
        username = username[len("@"):]

    instance = json.decode(config.get("instance", "{\"display\":\"mastodon.social\",\"value\":\"mastodon.social\"}"))
    instance_name = instance["value"]
    message = "@%s@%s" % (username, instance_name)
    followers_count = get_followers_count(instance_name, username)

    if followers_count == None:
        formatted_followers_count = "Not Found"
        message = "Check your username. (%s)" % message
    else:
        formatted_followers_count = "%s %s" % (humanize.comma(followers_count), humanize.plural_word(followers_count, "follower"))

    username_child = render.Text(
        color = "#3c3c3c",
        content = message,
    )

    if len(message) > 12:
        username_child = render.Marquee(
            width = 64,
            child = username_child,
        )

    return render.Root(
        child = render.Box(
            render.Column(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Image(MASTODON_ICON),
                            render.WrappedText(formatted_followers_count),
                        ],
                    ),
                    username_child,
                ],
            ),
        ),
    )

def get_followers_count(instance, username):
    response = http.get(
        "https://%s/api/v1/accounts/lookup/?acct=%s" % (instance, username),
        headers = {
            "Content-Type": "application/json",
        },
        ttl_seconds = 240,
    )

    if response.status_code == 200:
        body = response.json()
        if body != None and len(body) > 0:
            return int(body["followers_count"])
    return None

def search_instances(pattern, config):
    matched_instances = []
    response = http.get(
        "https://instances.social/api/1.0/instances/search",
        params = {
            "name": "true",
            "q": pattern,
        },
        headers = {
            "Authorization": "Bearer %s" % config.get("instances_api_token"),
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
    )

    if response.status_code == 200:
        body = response.json()
        if body != None and len(body) > 0:
            if "instances" in body:
                instances = body["instances"]
                for instance in instances:
                    matched_instances.append(
                        schema.Option(
                            display = instance["name"],
                            value = instance["name"],
                        ),
                    )
    return matched_instances

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "instances_api_token",
                name = "Instances.social API Token",
                desc = "Your API token for instances.social. See https://instances.social/api/ for details.",
                icon = "key",
                secret = True,
            ),
            schema.Typeahead(
                id = "instance",
                name = "Instance",
                desc = "Mastodon instances from instances.social",
                icon = "gear",
                handler = search_instances,
            ),
            schema.Text(
                id = "username",
                name = "User Name",
                icon = "user",
                desc = "User name for which to display follower count",
            ),
        ],
    )
