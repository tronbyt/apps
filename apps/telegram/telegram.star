"""
Applet: Telegram
Summary: Group member count
Description: View your group/chat member count. Add @tidbytbot to your group/chat to get the Chat ID.
Author: Daniel Sitnik
"""

load("http.star", "http")
load("humanize.star", "humanize")
load("images/tg_logo.png", TG_LOGO_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

TG_LOGO = TG_LOGO_ASSET.readall()

# telegram logo

# telegram api url
TG_URL = "https://api.telegram.org/bot%s/getChatMemberCount"

def main(config):
    # get configs
    chat_id = config.str("chat_id", None)
    group_name = config.str("group_name", "Your Channel")
    dot_separator = config.bool("dot_separator", False)

    # decrypt bot token or use dev value
    bot_token = config.get("telegram_bot_token")

    # validate if token was provided
    if bot_token in (None, ""):
        return render_demo("Please provide a BOT TOKEN!", dot_separator)

    if chat_id == None:
        return render_demo("Tidbyt", dot_separator)

    # fetch member count
    res = http.get(TG_URL % bot_token, ttl_seconds = 3600, params = {
        "chat_id": chat_id,
    })

    # handle api errors
    if res.status_code != 200:
        print("API error %d: %s" % (res.status_code, res.body()))
        return render_error(res.json())

    # check returned data
    data = res.json()

    if data["ok"] != True:
        return render_error(data)

    member_count = humanize.comma(data["result"])

    # change thousands separator if necessary
    if (dot_separator):
        member_count = member_count.replace(",", ".")

    # render result
    return render.Root(
        child = render.Box(
            render.Column(
                cross_align = "center",
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Image(src = TG_LOGO),
                            render.Column(
                                children = [
                                    render.Text(member_count),
                                    render.Text("members"),
                                ],
                            ),
                        ],
                    ),
                    render.Marquee(
                        width = 64,
                        align = "center",
                        child = render.Text(content = group_name, color = "#777"),
                    ),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "telegram_bot_token",
                name = "Telegram Bot Token",
                desc = "Your Telegram Bot Token. See https://core.telegram.org/bots/api#authorizing-your-bot for details.",
                icon = "key",
                secret = True,
            ),
            schema.Text(
                id = "chat_id",
                name = "Chat ID",
                desc = "Chat ID given by the Tidbyt bot.",
                icon = "telegram",
            ),
            schema.Text(
                id = "group_name",
                name = "Group/chat name",
                desc = "Name of the group/chat.",
                icon = "signature",
                default = "Your Group",
            ),
            schema.Toggle(
                id = "dot_separator",
                name = "Use dot separator",
                desc = "Use dots for thousands separator.",
                icon = "toggleOn",
                default = False,
            ),
        ],
    )

def render_demo(group_name, dot_separator):
    member_count = "5,678"

    if dot_separator:
        member_count = member_count.replace(",", ".")

    return render.Root(
        child = render.Box(
            render.Column(
                cross_align = "center",
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Image(src = TG_LOGO),
                            render.Column(
                                children = [
                                    render.Text(member_count),
                                    render.Text("members"),
                                ],
                            ),
                        ],
                    ),
                    render.Marquee(
                        width = 64,
                        align = "center",
                        child = render.Text(content = group_name, color = "#777"),
                    ),
                ],
            ),
        ),
    )

def render_error(error):
    error_code = int(error.get("error_code", "000"))
    error_desc = error.get("description", "No description :(")

    return render.Root(
        child = render.Box(
            render.Column(
                cross_align = "center",
                children = [
                    render.Row(
                        expanded = True,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [
                            render.Image(src = TG_LOGO),
                            render.Column(
                                children = [
                                    render.Text(content = "API Error"),
                                    render.Text(content = str(error_code), color = "#f00"),
                                ],
                            ),
                        ],
                    ),
                    render.Marquee(
                        width = 64,
                        align = "center",
                        child = render.Text(content = error_desc, color = "#ff0"),
                    ),
                ],
            ),
        ),
    )
