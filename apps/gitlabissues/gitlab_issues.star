load("cache.star", "cache")
load("http.star", "http")
load("images/icon.png", ICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

ICON = ICON_ASSET.readall()

# Load GitLab icon from base64 encoded data

def main(config):
    token = config.get("api-token")
    domain = config.get("custom-domain")

    icon = render.Image(src = ICON)
    text = render.WrappedText(get_issues(token, domain))
    return render.Root(
        child = render.Row(
            expanded = True,
            cross_align = "top",
            children =
                [icon, text],
        ),
    )

def get_issues(accesstoken, domain):
    if accesstoken == None:
        return "You have 3 open issues!"

    # Set the GitLab API endpoint and access token
    api_endpoint = domain + "api/v4"

    url = api_endpoint + "/user?access_token=" + accesstoken
    user_data = http.get(url)
    if user_data.status_code != 200:
        return "API call fail!"
    user_data = user_data.json()
    user_id = user_data["id"]

    #Get the number of open issues for the current user
    issues_url = api_endpoint + "/issues?state=opened&assignee_id=%s" % str(user_id) + "&access_token=" + accesstoken
    open_issues = http.get(issues_url).json()
    open_issues = len(open_issues)

    cache_name = "%s_cache_data" % str(user_id)
    cached_data = cache.get(cache_name)
    if cached_data != None:
        print("Cached Data has been found!")
        set_cache(cache_name, str(open_issues))
        if open_issues == 0:
            return "You have no open issues!"
        elif int(cached_data) >= open_issues:
            if int(cached_data) - open_issues == 1:
                return "You have 1 open issue!"
            return "You have %d open issues!" % int(cached_data)
        else:
            number_of_new_issues = open_issues - int(cached_data)
            if number_of_new_issues == 1:
                return "You have 1 new issue!"
            return "You have %d new issues!" % number_of_new_issues
    else:
        print("No cached Data has been found!")

        set_cache(cache_name, str(open_issues))

        if open_issues == 0:
            return "You have no open issues!"
        elif open_issues == 1:
            return "You have 1 open issue!"

        return "You have %d open issues!" % open_issues

def set_cache(name, open_issues):
    # TODO: Determine if this cache call can be converted to the new HTTP cache.
    cache.set(name, open_issues, ttl_seconds = 3600)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api-token",
                name = "Your Gitlab access token",
                desc = "Your Gitlab access token",
                icon = "key",
                default = "",
                secret = True,
            ),
            schema.Text(
                id = "custom-domain",
                name = "Custom domain for hosted Gitlab",
                desc = "If applicable, a custom domain for your hosted Gitlab instance",
                icon = "cube",
                default = "https://gitlab.com/",
            ),
        ],
    )
