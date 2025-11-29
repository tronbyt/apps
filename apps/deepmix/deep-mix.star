"""
Deep Mix - A Tidbyt app showing the currently playing song from Deep Mix Online Radio
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")

# Deep Mix Logo
DM_LOGO = base64.decode("""
R0lGODlhZAAeAP8AAAAAAAAAMwAAZgAAmQAAzAAA/wAzAAAzMwAzZgAzmQAzzAAz/wBmAABmMwBmZgBmmQBmzABm/wCZAACZMwCZZgCZmQCZzACZ/wDMAADMMwDMZgDMmQDMzADM/wD/AAD/MwD/ZgD/mQD/zAD//zMAADMAMzMAZjMAmTMAzDMA/zMzADMzMzMzZjMzmTMzzDMz/zNmADNmMzNmZjNmmTNmzDNm/zOZADOZMzOZZjOZmTOZzDOZ/zPMADPMMzPMZjPMmTPMzDPM/zP/ADP/MzP/ZjP/mTP/zDP//2YAAGYAM2YAZmYAmWYAzGYA/2YzAGYzM2YzZmYzmWYzzGYz/2ZmAGZmM2ZmZmZmmWZmzGZm/2aZAGaZM2aZZmaZmWaZzGaZ/2bMAGbMM2bMZmbMmWbMzGbM/2b/AGb/M2b/Zmb/mWb/zGb//5kAAJkAM5kAZpkAmZkAzJkA/5kzAJkzM5kzZpkzmZkzzJkz/5lmAJlmM5lmZplmmZlmzJlm/5mZAJmZM5mZZpmZmZmZzJmZ/5nMAJnMM5nMZpnMmZnMzJnM/5n/AJn/M5n/Zpn/mZn/zJn//8wAAMwAM8wAZswAmcwAzMwA/8wzAMwzM8wzZswzmcwzzMwz/8xmAMxmM8xmZsxmmcxmzMxm/8yZAMyZM8yZZsyZmcyZzMyZ/8zMAMzMM8zMZszMmczMzMzM/8z/AMz/M8z/Zsz/mcz/zMz///8AAP8AM/8AZv8Amf8AzP8A//8zAP8zM/8zZv8zmf8zzP8z//9mAP9mM/9mZv9mmf9mzP9m//+ZAP+ZM/+ZZv+Zmf+ZzP+Z///MAP/MM//MZv/Mmf/MzP/M////AP//M///Zv//mf//zP///wAAABZV/xFV/xRO7Q1G6SBR7BVb/xNY/xxW+yRU7BVR8Q9V/BNX/xBX/xtR7CZN5iBS7RNa/xRX/xpS8yJU7RZS8BFV/QtY/xlS8T9f6x1Q6xFQ7hJT+RRU/xBT/xBV/xdP7U1Z2UNe5B1U9BNb/xVd/xtP7CNS7SwAAAAAZAAeAIcAAAAAADMAAGYAAJkAAMwAAP8AMwAAMzMAM2YAM5kAM8wAM/8AZgAAZjMAZmYAZpkAZswAZv8AmQAAmTMAmWYAmZkAmcwAmf8AzAAAzDMAzGYAzJkAzMwAzP8A/wAA/zMA/2YA/5kA/8wA//8zAAAzADMzAGYzAJkzAMwzAP8zMwAzMzMzM2YzM5kzM8wzM/8zZgAzZjMzZmYzZpkzZswzZv8zmQAzmTMzmWYzmZkzmcwzmf8zzAAzzDMzzGYzzJkzzMwzzP8z/wAz/zMz/2Yz/5kz/8wz//9mAABmADNmAGZmAJlmAMxmAP9mMwBmMzNmM2ZmM5lmM8xmM/9mZgBmZjNmZmZmZplmZsxmZv9mmQBmmTNmmWZmmZlmmcxmmf9mzABmzDNmzGZmzJlmzMxmzP9m/wBm/zNm/2Zm/5lm/8xm//+ZAACZADOZAGaZAJmZAMyZAP+ZMwCZMzOZM2aZM5mZM8yZM/+ZZgCZZjOZZmaZZpmZZsyZZv+ZmQCZmTOZmWaZmZmZmcyZmf+ZzACZzDOZzGaZzJmZzMyZzP+Z/wCZ/zOZ/2aZ/5mZ/8yZ///MAADMADPMAGbMAJnMAMzMAP/MMwDMMzPMM2bMM5nMM8zMM//MZgDMZjPMZmbMZpnMZszMZv/MmQDMmTPMmWbMmZnMmczMmf/MzADMzDPMzGbMzJnMzMzMzP/M/wDM/zPM/2bM/5nM/8zM////AAD/ADP/AGb/AJn/AMz/AP//MwD/MzP/M2b/M5n/M8z/M///ZgD/ZjP/Zmb/Zpn/Zsz/Zv//mQD/mTP/mWb/mZn/mcz/mf//zAD/zDP/zGb/zJn/zMz/zP///wD//zP//2b//5n//8z///8AAAAWVf8RVf8UTu0NRukgUewVW/8TWP8cVvskVOwVUfEPVfwTV/8QV/8bUewmTeYgUu0TWv8UV/8aUvMiVO0WUvARVf0LWP8ZUvE/X+sdUOsRUO4SU/kUVP8QU/8QVf8XT+1NWdlDXuQdVPQTW/8VXf8bT+wjUu0I/wCxCRxIsKDBgwgTKlzIsKHDhxAjSpxIsaLFixgN1njhYgHHBTQ8QngRIaNJhgoWeKwYYQGEBS1hyoR5subBFx4XVHQRgeSCGiBVhgRqs6hAmApqVPTpIqSCFzV4qoRgtOrFGgoiKCVIAytRgi+oKgx7s+tYGgRfFsyqkMYLs1yjJoxA10VBoHQH/mypda9ObC1r0P0pUyBJoHhJ9jTcc2TgwEllfsVWQ/ALwIgJIt6q0SXngTToXgYcIatguhAioKVcWitqrQJTZ6WLmibg1LQjvAyd+yXnl6oF6g5OmvhB3iXvoi4eAQto2sVrCMImaFBrgaeVQuiqOvlptF151/8I3bVGauzmk7POGzqpQq0QPmNPrd38Z/sl40P4MlDQaeHxaQbdbffR9xxxvK3GWnziLXRBBBfIt8ODF+iATYMDCXaBQBQOMtAXFwRIw4MWELQDBBeA9+BnFGr2YHIUqndhiBDKZ9CEKFrI1Q4WbHXBBT1aMJyQG+KY4g46pPcjZQ/qKJwFEWJzYoUmokhQBFCuNmKKLkagg4wI6fDjDjf+uKEOU5o54Y9oiSmmmXCiBSSVA61p4ZzqbUlmnVZyCGVBb9KpEI+C1glliWY6aVCiCc25p5RzcnjBo9jM6SSUkwq0JqWVWjAipwc5alAHUJJpaaN/hrmmiaViI2aqmmL/WieQe766oaE/wpoQqR0oKiUHF3QgEK8JWUBqEAlxcCxBOnRwAQdSdsABpc4KO5CxFwAhELba+tlrEMb6Cqi02VY4bRDASjuss0DoAIQFFgArEBAdHMuBsfHe2iy+FgSxr7OVKluiQPtCOxCveyKsqbIbpgsqQcDiy2u+6g5Lcb31IhutsulK20G3Hitbb7oG89otNh5TqyzBHg+rrI47cLDyrkF0ULPII5+MDc70fmytQBzbzEHNTgI7bdAyA50xxCMP1LPGT2PTs8EC1UxqQmRQlHUZCnHNddUtWyV2TVOPbXZGHut89toRefwz23A3BMQIHYwQ990NoRuE2nj3Cu3334AHLrhJAQEAOw==
""")

# Cache TTL for API responses
CACHE_TTL_SECONDS = 30  # Cache for 30 seconds (more frequent updates for live radio)

def main(config):
    """
    Main function that renders the Tidbyt display
    """

    # Get user-configured colors
    text_color = config.get("text_color", "#0ff1b2")

    # Fetch current playing track
    current_track = fetch_current_track()

    if current_track == None:
        # Fallback display if API is unavailable
        return render.Root(
            child = render.Box(
                render.Column(
                    expanded = True,
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        render.Image(
                            src = DM_LOGO,
                            # width = 128,
                            # height = 64,
                        ),
                        render.Marquee(
                            width = 64,
                            child = render.Text(
                                content = "Deep Mix Radio • Loading...",
                                font = "tb-8",
                                color = text_color,
                            ),
                            scroll_direction = "horizontal",
                        ),
                    ],
                ),
            ),
        )

    # Display current track info
    # artist = current_track.get("artist", "Unknown Artist")
    title = current_track.get("title", "Unknown Track")

    # Build the display children
    children = [
        render.Image(
            src = DM_LOGO,
            width = 32,
            height = 16,
        ),
    ]

    # Use centered text for short titles, marquee for long ones
    if len(title) < 14:
        children.append(
            render.Text(
                content = title,
                font = "tb-8",
                color = text_color,
            ),
        )
    else:
        children.append(
            render.Marquee(
                width = 64,
                child = render.Text(
                    content = title,
                    font = "tb-8",
                    color = text_color,
                ),
                scroll_direction = "horizontal",
            ),
        )

    return render.Root(
        child = render.Box(
            render.Column(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = children,
            ),
        ),
    )

def get_schema():
    """
    Configuration schema for the app
    """
    return schema.Schema(
        version = "1",
        fields = [
            schema.Color(
                id = "text_color",
                name = "Text Color",
                desc = "Color for track information text",
                icon = "palette",
                default = "#0ff1b2",
            ),
        ],
    )

def fetch_current_track():
    """
    Fetch current track from Deep Mix Radio by scraping HTML
    """
    url = "http://217.160.63.220:7620/played.html?sid=1"

    # Cache the response for 30 seconds
    cached = cache.get("current_track")
    if cached != None:
        return json.decode(cached)

    resp = http.get(url)

    if resp.status_code == 200:
        html = resp.body()

        # Find the row with "Current Song" marker
        current_song_marker = "<b>Current Song</b>"
        if current_song_marker in html:
            # Find the start of the row containing the current song
            marker_pos = html.find(current_song_marker)
            row_start = html.rfind("<tr>", 0, marker_pos)

            if row_start != -1:
                # Extract the row
                row_end = html.find("</tr>", row_start)
                row = html[row_start:row_end]

                # Extract the song title (second <td>)
                # Find all <td> tags in the row
                first_td_end = row.find("</td>")
                if first_td_end != -1:
                    # Find the second <td>
                    second_td_start = row.find("<td>", first_td_end)
                    second_td_end = row.find("</td>", second_td_start)

                    if second_td_start != -1 and second_td_end != -1:
                        # Extract the content between the tags
                        song_text = row[second_td_start + 4:second_td_end]

                        # Parse artist and title (format: "Artist - Title")
                        if " - " in song_text:
                            parts = song_text.split(" - ", 1)
                            artist = parts[0].strip()
                            title = parts[1].strip()
                        else:
                            # If no separator, use the whole text as title
                            artist = "Unknown Artist"
                            title = song_text.strip()

                        track_data = {
                            "artist": artist,
                            "title": title,
                        }
                        cache.set("current_track", json.encode(track_data), ttl_seconds = CACHE_TTL_SECONDS)
                        return track_data

        print("Could not parse current song from HTML")
        return None
    else:
        print("Failed to fetch from server:", resp.status_code)
        return None
