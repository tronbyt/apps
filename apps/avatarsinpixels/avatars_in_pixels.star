"""
Applet: Avatars In Pixels
Summary: Show a pixel art character
Description: Displays a random pixel art character from https://www.avatarsinpixels.com/.
Author: Daniel Sitnik
"""

load("animation.star", "animation")
load("cache.star", "cache")
load("http.star", "http")
load("images/error_icon.png", ERROR_ICON_ASSET = "file")
load("render.star", "render")

ERROR_ICON = ERROR_ICON_ASSET.readall()

CACHE_TTL = 3600

def main():
    img = get_avatar()

    if type(img) == "dict" and img["error"] != None:
        return render_error(img["error"])
    else:
        return render_animation(img)

def get_avatar():
    # check if we have a cached image
    cached_img = cache.get("minipix")

    if cached_img != None:
        return cached_img

    # first request, returns the URL of the generated avatar
    res = http.post("https://www.avatarsinpixels.com/minipix/Update", headers = {
        "accept": "application/json, text/javascript, */*; q=0.01",
        "content-type": "application/x-www-form-urlencoded; charset=UTF-8",
        "referer": "https://www.avatarsinpixels.com/minipix/clothing/Body",
        "user-agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36",
    }, form_body = {
        "action": "actions",
        "Actions": "randomizeColors randomizeLayers",
    })

    if res.status_code != 200:
        print("Generate API error (%d): %s" % (res.status_code, res.body()))
        return {
            "error": res.status_code,
        }

    # extract the PHP session cookie to be used on the next request
    # format: PHPSESSID=6ofhdor04vlqm6b0m6fq0dh995; path=/
    res_headers = res.headers
    php_cookie = res_headers["Set-Cookie"].replace("; path=/", "")

    # retrieve the path to avatar image
    data = res.json()

    # remove the escaped slashes from the path
    src = data["src"].replace("\\", "")

    # request the avatar image
    res = http.get("https://www.avatarsinpixels.com" + src, headers = {
        "accept": "image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8",
        "referer": "https://www.avatarsinpixels.com/minipix/clothing/Body",
        "user-agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36",
        "cookie": php_cookie,
    })

    if res.status_code != 200:
        print("Image API error (%d): %s" % (res.status_code, res.body()))
        return {
            "error": res.status_code,
        }

    img = res.body()

    # cache the image for 1 hour
    cache.set("minipix", img, ttl_seconds = CACHE_TTL)

    return img

def render_animation(img):
    anim = animation.Transformation(
        child = render.Image(src = img, width = 64),
        duration = 120,
        delay = 10,
        direction = "alternate",
        fill_mode = "forwards",
        keyframes = [
            animation.Keyframe(
                percentage = 0.0,
                transforms = [animation.Translate(0, 0)],
                curve = "ease_in_out",
            ),
            animation.Keyframe(
                percentage = 1.0,
                transforms = [animation.Translate(0, -32)],
            ),
        ],
    )

    return render.Root(anim)

def render_error(error):
    return render.Root(
        render.Box(
            render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Image(ERROR_ICON, width = 28),
                    render.Column(
                        cross_align = "center",
                        children = [
                            render.Text("API", color = "#ff0"),
                            render.Text("ERROR", color = "#ff0"),
                            render.Text(str(error), color = "#f00"),
                        ],
                    ),
                ],
            ),
        ),
    )
