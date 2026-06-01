"""
Applet: GitHub Stargazers
Summary: Display GitHub repo stars
Description: Display the GitHub stargazer count for a repo.
Author: fulghum
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/github_image.png", GITHUB_IMAGE_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

GITHUB_IMAGE = GITHUB_IMAGE_ASSET.readall()

GITHUB_REPO_SEARCH_URL = "https://api.github.com/search/repositories?q=%s"

def get_stargazers_count(org_name, repo_name, config):
    query_params = "repo:%s/%s" % (org_name, repo_name)
    res_json = send_github_request(GITHUB_REPO_SEARCH_URL, query_params, config)
    stargazers_count = res_json["items"][0]["stargazers_count"]
    print("stargazers_count: %s " % stargazers_count)
    return stargazers_count

def send_github_request(url, query_params, config):
    api_key = config.get("github_api_key")

    headers = {}
    if api_key == None:
        print("warning: no api_key available; sending request without authentication")
    else:
        headers = {
            "Authorization": "token %s" % api_key,
        }

    res = http.get(
        url = url % humanize.url_encode(query_params),
        headers = headers,
        ttl_seconds = 300,
    )
    if res.status_code != 200:
        print("GitHub API request failed: %s - %s " % (res.status_code, res.body()))
        return None

    return json.decode(res.body())

def main(config):
    org_name = config.get("org_name", "tronbyt")
    repo_name = config.get("repo_name", "apps")

    print("Fetching GitHub stargazer count...")
    stargazers_count = get_stargazers_count(org_name, repo_name, config)

    image_size = 16
    msg = "%s stars" % humanize.comma(stargazers_count)

    display_name = "%s/%s" % (org_name, repo_name)
    username_child = render.Text(
        color = "#6cc644",
        content = display_name,
    )

    if len(display_name) > 12:
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
                        main_align = "space_evenly" if len(msg) > 5 else "center",
                        cross_align = "center",
                        children = [
                            render.Padding(
                                pad = (1, 1, 1, 1),
                                child = render.Image(GITHUB_IMAGE, height = image_size),
                            ),
                            render.WrappedText(msg, font = "tb-8" if len(msg) > 7 else "6x13"),
                        ],
                    ),
                    username_child,
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "org_name",
                name = "Org Name",
                icon = "user",
                desc = "Name of the organization, or account, containing the GitHub repository",
            ),
            schema.Text(
                id = "repo_name",
                name = "Repo Name",
                icon = "user",
                desc = "Name of the GitHub repository for which to display stargazer count",
            ),
            schema.Text(
                id = "github_api_key",
                name = "GitHub API Key",
                icon = "key",
                desc = "A GitHub API key to increase rate limits.",
                secret = True,
            ),
        ],
    )
