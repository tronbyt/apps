"""
Applet: GitHub Repo
Summary: Display GitHub repo stats
Description: Display various statistics of a public GitHub repo.
Author: rs7q5
"""

#github_repo.star
#Created 20221223 RIS
#Last Modified 20230607 RIS

load("http.star", "http")
load("humanize.star", "humanize")
load("images/fork_icon.png", FORK_ICON_ASSET = "file")
load("images/github_failed_icon.png", GITHUB_FAILED_ICON_ASSET = "file")
load("images/github_fault_icon.png", GITHUB_FAULT_ICON_ASSET = "file")
load("images/github_loading_icon.png", GITHUB_LOADING_ICON_ASSET = "file")
load("images/github_neutral_icon.png", GITHUB_NEUTRAL_ICON_ASSET = "file")
load("images/github_success_icon.png", GITHUB_SUCCESS_ICON_ASSET = "file")
load("images/issue_icon.png", ISSUE_ICON_ASSET = "file")
load("images/pr_icon.png", PR_ICON_ASSET = "file")
load("images/star_icon.png", STAR_ICON_ASSET = "file")
load("images/tag_icon.png", TAG_ICON_ASSET = "file")
load("images/watch_icon.png", WATCH_ICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

FORK_ICON = FORK_ICON_ASSET.readall()
GITHUB_FAILED_ICON = GITHUB_FAILED_ICON_ASSET.readall()
GITHUB_FAULT_ICON = GITHUB_FAULT_ICON_ASSET.readall()
GITHUB_LOADING_ICON = GITHUB_LOADING_ICON_ASSET.readall()
GITHUB_NEUTRAL_ICON = GITHUB_NEUTRAL_ICON_ASSET.readall()
GITHUB_SUCCESS_ICON = GITHUB_SUCCESS_ICON_ASSET.readall()
ISSUE_ICON = ISSUE_ICON_ASSET.readall()
PR_ICON = PR_ICON_ASSET.readall()
STAR_ICON = STAR_ICON_ASSET.readall()
TAG_ICON = TAG_ICON_ASSET.readall()
WATCH_ICON = WATCH_ICON_ASSET.readall()

############
FONT = "tom-thumb"  #set font
BASE_URL = "https://api.github.com/graphql"

############
#stuff for open issues/prs
ISSUE_PR_COLOR = "#57ab5a"
STAT_COLOR = "#768390"
STAR_COLOR = "#daaa3f"
PENDING_COLOR = "#966600"
FAIL_COLOR = "#e5534b"

#images of icons

#format for using these icons are from github_badge.star by Cavallando (changed colors to match GitHub dark dimmed theme)

############
#other settings

DEFAULT_AUTH_TOKEN = "1234"  #can get this by creating a personal token (classic) in GitHub and having the scope be public_repo
DEFAULT_OWNER = "tidbyt"
DEFAULT_REPO = "community"
DEFAULT_BRANCH = "main"

############
def main(config):
    #get data
    data = get_repository(config)  #get data

    #create main header of text
    header_txt = config.str("organization", DEFAULT_OWNER) + "/" + config.str("repository", DEFAULT_REPO) + ":" + config.str("branch", DEFAULT_BRANCH)
    header_all = render.Text(header_txt, font = FONT)

    #format display data
    if data == None:
        #error getting data
        line1 = render.WrappedText("Error getting data!!!!", font = FONT)
        line2 = None
        line3 = None
    elif type(data) == "string":
        #error getting repository data
        line1 = render.Marquee(
            height = 26,
            scroll_direction = "vertical",
            offset_start = 32,
            offset_end = 32,
            child = render.WrappedText(data, font = FONT),
        )
        line2 = None
        line3 = None
    else:
        #information on the repository exists
        if data["latestRelease"] != None:
            header_all = render.Row(
                children = [
                    render.Text(header_txt, font = FONT),
                    render.Padding(render.Image(src = TAG_ICON, height = 6, width = 6), pad = (2, 0, 2, 0)),
                    render.Text(data["latestRelease"]["name"], font = FONT),
                ],
            )
        else:
            header_all = render.Text(header_txt, font = FONT)
            #header_txt += "(%s)" % data["latestRelease"]["name"]

        line1 = repository_stats(data)
        line2 = issues_pullrequests(data)
        line3 = latest_commit(data)

    #create the final frame
    frame_final = render.Column(
        main_align = "space_between",
        children = [
            render.Marquee(header_all, width = 64, offset_start = 64, offset_end = 64),
            line1,  #watchers, forks, stargazers
            line2,  #issues/pull requests
            line3,  #latest commit and version
        ],
    )

    return render.Root(
        delay = 100,  #speed up scroll text
        show_full_animation = True,
        child = frame_final,
    )

def get_schema():
    return [
        schema.Text(
            id = "organization",
            name = "User/Organization",
            desc = "User/organization of the repository.",
            icon = "user",
            default = DEFAULT_OWNER,
        ),
        schema.Text(
            id = "repository",
            name = "Repository",
            desc = "Name of the repository.",
            icon = "user",
            default = DEFAULT_REPO,
        ),
        schema.Text(
            id = "branch",
            name = "Branch",
            desc = "Default branch",
            icon = "user",
            default = DEFAULT_BRANCH,
        ),
        schema.Text(
            id = "auth_token",
            name = "GitHub Auth Token",
            desc = "GitHub personal access token (classic) with public_repo scope.",
            icon = "key",
            secret = True,
        ),
    ]

######################################################
#functions for getting data
def get_repository(config):
    #get repo statistics
    owner = config.str("organization", DEFAULT_OWNER)
    repo = config.str("repository", DEFAULT_REPO)
    branch = config.str("branch", DEFAULT_BRANCH)
    nameWithOwner = owner + "/" + repo
    dataQuery = {
        "query": """query {
                    repository(name: "%s", owner: "%s") {
                        id
                        nameWithOwner
                        watchers {
                        totalCount
                        }
                        stargazers {
                        totalCount
                        }
                        issues(states: OPEN) {
                        totalCount
                        }
                        forks {
                        totalCount
                        }
                        pullRequests(states: OPEN) {
                        totalCount
                        }
                        latestRelease {
                        id
                        name
                        publishedAt
                        updatedAt
                        createdAt
                        }
                        ref(qualifiedName: "%s") {
                        id
                        name
                        target {
                            ... on Commit {
                            id
                            abbreviatedOid
                            messageHeadline
                            committedDate
                            statusCheckRollup {
                                state
                            }
                            }
                        }
                        }
                    }
                    }
                """ % (repo, owner, branch),
    }

    #get data
    auth_key = config.get("auth_token") or DEFAULT_AUTH_TOKEN
    rep = http.post(
        BASE_URL,
        headers = {
            "Authorization": "Bearer " + auth_key,
        },
        json_body = dataQuery,
        ttl_seconds = 1800,  #cache for 30 seconds
    )

    #print(rep.json()["errors"])
    if rep.status_code != 200:
        print("%s Error, could not get data for %s!!!!" % (rep.status_code, nameWithOwner))
        return None
    elif rep.json().get("errors", None) != None:
        #error message
        return rep.json()["errors"][0]["message"]  #gets only the first error
    else:
        data = rep.json()["data"]["repository"]

    return data

######################################################
#functions to create displayed information
def repository_stats(data):
    #get stats like watchers, forks, and stargazers
    #get data
    watchers = int(data["watchers"]["totalCount"])
    forks = int(data["forks"]["totalCount"])
    stargazers = int(data["stargazers"]["totalCount"])

    ##############
    #create images
    watch_img = render.Image(src = WATCH_ICON, width = 8, height = 8)
    fork_img = render.Image(src = FORK_ICON, width = 8, height = 8)
    star_img = render.Image(src = STAR_ICON, width = 8, height = 8)

    #final text
    final_text = render.Row(
        #expanded=True,
        children = [
            #watchers
            render.Padding(child = watch_img, pad = (0, 0, 1, 0)),
            render.Text(content = str(watchers), height = 9, offset = 1, font = FONT),
            ######
            #forks
            render.Padding(child = fork_img, pad = (4, 0, 1, 0)),
            render.Text(content = str(forks), height = 9, offset = 1, font = FONT),
            ######
            #stargazers
            #followers • following
            render.Padding(child = star_img, pad = (4, 0, 1, 0)),
            render.Text(content = str(stargazers), height = 9, offset = 1, font = FONT),
        ],
    )
    return render.Marquee(width = 64, child = final_text, offset_start = 64, offset_end = 64, align = "start")

def issues_pullrequests(data):
    #get stats like issues/pull requests
    #get data
    issues = int(data["issues"]["totalCount"])
    pulls = int(data["pullRequests"]["totalCount"])

    ##############
    #create images
    # issue_img = render.Circle(
    #     color = ISSUE_PR_COLOR,
    #     diameter = 8,
    #     child = render.Circle(
    #         color = "#000000",
    #         diameter = 6,
    #         child = render.Circle(color = ISSUE_PR_COLOR, diameter = 2),
    #     ),
    # )
    issue_img = render.Image(src = ISSUE_ICON, width = 8, height = 8)
    pr_img = render.Image(src = PR_ICON, width = 8, height = 8)

    #final text
    final_text = render.Row(
        #expanded=True,
        children = [
            ######
            #issues open
            render.Padding(child = issue_img, pad = (0, 0, 1, 0)),
            render.Text(content = str(issues), height = 9, offset = 1, font = FONT),
            ######
            #pulls open
            render.Padding(child = pr_img, pad = (4, 0, 1, 0)),
            render.Text(content = str(pulls), height = 9, offset = 1, font = FONT),
        ],
    )
    return render.Marquee(width = 64, child = final_text, offset_start = 64, offset_end = 64, align = "start")

def get_status_icon(status):
    #get the right commit status icon - from github_badge.star by Cavallando
    if status == "completed" or status == "success":
        return GITHUB_SUCCESS_ICON
    elif status == "failed" or status == "timed_out":
        return GITHUB_FAILED_ICON
    elif status == "cancelled" or status == "skipped" or status == "stale" or status == "neutral":
        return GITHUB_NEUTRAL_ICON
    elif status == "action_required":
        return GITHUB_FAULT_ICON
    else:
        return GITHUB_LOADING_ICON

def latest_commit(data):
    commit_data = data["ref"]
    if commit_data == None:
        final_text = render.Text("Cannot get latest commit for specified branch!!!")
    else:
        oid_short = commit_data["target"]["abbreviatedOid"]  #shortened commit id

        #get status id icon
        commit_status = commit_data["target"]["statusCheckRollup"]["state"].lower()
        status_icon = get_status_icon(commit_status)
        status_img = render.Image(src = status_icon, width = 8, height = 8)

        commit_time = time.parse_time(commit_data["target"]["committedDate"], "2006-01-02T15:04:05Z", "Zulu")

        #time_info = [render.Padding(render.Text(content=x,height=9,offset=1,font=FONT),pad=(2,0,0,0)) for x in humanize.time(commit_time).split(" ")] #condense spacing between relative time
        time_info = []
        for x in humanize.time(commit_time).split(" "):
            shift = 4 if time_info == [] else 2
            time_info.append(render.Padding(render.Text(content = x, height = 9, offset = 1, font = FONT), pad = (shift, 0, 0, 0)))

        final_frame_vec = [
            render.Text("Latest", height = 9, offset = 1, font = FONT),
            render.Padding(child = render.Text("commit:", height = 9, offset = 1, font = FONT), pad = (2, 0, 0, 0)),
            #render.Padding(child = render.Text(oid_short, height = 9, offset = 1, font = FONT), pad = (2, 0, 0, 0)),
            ######
            #commit info
            render.Padding(child = status_img, pad = (4, 0, 1, 0)),
            render.Text(content = oid_short, height = 9, offset = 1, font = FONT),
            ######
            #time info
            #render.Padding(child=render.Text(content = humanize.time(commit_time), height = 9, offset = 1, font = FONT),pad=(2,0,0,0)),
        ]

        final_frame_vec.extend(time_info)  #add time info

        #final text
        final_text = render.Row(
            children = final_frame_vec,
        )
    return render.Marquee(width = 64, child = final_text, offset_start = 64, offset_end = 64, align = "start")
