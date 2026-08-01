"""
Applet: Critical Chicken
Summary: Gaming news
Description: Shows the latest post from CriticalChicken.com.
Author: Critical Chicken
"""

load("animation.star", "animation")
load("http.star", "http")
load("images/aceattorney.png", IMGBGACEATTORNEY_ASSET = "file", IMGTAGACEATTORNEY_ASSET = "file")
load("images/branding.png", IMGBRANDING_ASSET = "file")
load("images/breakingnews.png", IMGTAGBREAKINGNEWS_ASSET = "file")
load("images/dungeonsanddragons.png", IMGBGDUNGEONSANDDRAGONS_ASSET = "file", IMGTAGDUNGEONSANDDRAGONS_ASSET = "file")
load("images/e3.png", IMGBGE3_ASSET = "file")
load("images/e3sfuture.png", IMGTAGE3SFUTURE_ASSET = "file")
load("images/error.png", IMGBGERROR_ASSET = "file", IMGTAGERROR_ASSET = "file")
load("images/exclusive.png", IMGBGEXCLUSIVE_ASSET = "file", IMGTAGEXCLUSIVE_ASSET = "file")
load("images/feature.png", IMGBGFEATURE_ASSET = "file", IMGTAGFEATURE_ASSET = "file")
load("images/firstimpressions.png", IMGTAGFIRSTIMPRESSIONS_ASSET = "file")
load("images/forthegaymers.png", IMGBGFORTHEGAYMERS_ASSET = "file", IMGTAGFORTHEGAYMERS_ASSET = "file")
load("images/guestblog.png", IMGTAGGUESTBLOG_ASSET = "file")
load("images/guide.png", IMGTAGGUIDE_ASSET = "file")
load("images/handson.png", IMGTAGHANDSON_ASSET = "file")
load("images/interview.png", IMGTAGINTERVIEW_ASSET = "file")
load("images/latest.png", IMGBGLATEST_ASSET = "file", IMGTAGLATEST_ASSET = "file")
load("images/link.png", IMGTAGLINK_ASSET = "file")
load("images/live.gif", IMGBGLIVE_ASSET = "file", IMGTAGLIVE_ASSET = "file")
load("images/liveupdates.png", IMGTAGLIVEUPDATES_ASSET = "file")
load("images/news.png", IMGBGNEWS_ASSET = "file", IMGTAGNEWS_ASSET = "file")
load("images/newsalert.png", IMGTAGNEWSALERT_ASSET = "file")
load("images/nintendodirect.png", IMGBGNINTENDODIRECT_ASSET = "file", IMGTAGNINTENDODIRECT_ASSET = "file")
load("images/none.png", IMGTAGNONE_ASSET = "file")
load("images/opinion.png", IMGTAGOPINION_ASSET = "file")
load("images/persona.png", IMGBGPERSONA_ASSET = "file", IMGTAGPERSONA_ASSET = "file")
load("images/pokemon.png", IMGBGPOKEMON_ASSET = "file", IMGTAGPOKEMON_ASSET = "file")
load("images/pokemonpresents.png", IMGTAGPOKEMONPRESENTS_ASSET = "file")
load("images/preview.png", IMGTAGPREVIEW_ASSET = "file")
load("images/review.png", IMGBGREVIEW_ASSET = "file", IMGTAGREVIEW_ASSET = "file")
load("images/rumour.png", IMGTAGRUMOUR_ASSET = "file")
load("images/secondlook.png", IMGTAGSECONDLOOK_ASSET = "file")
load("images/siteupdate.png", IMGTAGSITEUPDATE_ASSET = "file")
load("images/stateofplay.png", IMGBGSTATEOFPLAY_ASSET = "file", IMGTAGSTATEOFPLAY_ASSET = "file")
load("images/summergamefest.png", IMGBGSUMMERGAMEFEST_ASSET = "file")
load("images/summergamefest24.png", IMGTAGSUMMERGAMEFEST24_ASSET = "file")
load("images/switch2.png", IMGBGSWITCH2_ASSET = "file", IMGTAGSWITCH2_ASSET = "file")
load("images/update.png", IMGTAGUPDATE_ASSET = "file")
load("images/updated.png", IMGTAGUPDATED_ASSET = "file")
load("images/video.png", IMGTAGVIDEO_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

# IMAGES

# TITLETAGS

# Ace Attorney
IMGTAGACEATTORNEY = IMGTAGACEATTORNEY_ASSET.readall()

# Breaking news
IMGTAGBREAKINGNEWS = IMGTAGBREAKINGNEWS_ASSET.readall()

# Dungeons + Dragons
IMGTAGDUNGEONSANDDRAGONS = IMGTAGDUNGEONSANDDRAGONS_ASSET.readall()

# E3's future
IMGTAGE3SFUTURE = IMGTAGE3SFUTURE_ASSET.readall()

# Error
IMGTAGERROR = IMGTAGERROR_ASSET.readall()

# Exclusive
IMGTAGEXCLUSIVE = IMGTAGEXCLUSIVE_ASSET.readall()

# Feature
IMGTAGFEATURE = IMGTAGFEATURE_ASSET.readall()

# First impressions
IMGTAGFIRSTIMPRESSIONS = IMGTAGFIRSTIMPRESSIONS_ASSET.readall()

# #ForTheGaymers
IMGTAGFORTHEGAYMERS = IMGTAGFORTHEGAYMERS_ASSET.readall()

# Guest blog
IMGTAGGUESTBLOG = IMGTAGGUESTBLOG_ASSET.readall()

# Guide
IMGTAGGUIDE = IMGTAGGUIDE_ASSET.readall()

# Hands on
IMGTAGHANDSON = IMGTAGHANDSON_ASSET.readall()

# Interview
IMGTAGINTERVIEW = IMGTAGINTERVIEW_ASSET.readall()

# Latest (placeholder)
IMGTAGLATEST = IMGTAGLATEST_ASSET.readall()

# Link
IMGTAGLINK = IMGTAGLINK_ASSET.readall()

# Live
IMGTAGLIVE = IMGTAGLIVE_ASSET.readall()

# Live updates
IMGTAGLIVEUPDATES = IMGTAGLIVEUPDATES_ASSET.readall()

# News
IMGTAGNEWS = IMGTAGNEWS_ASSET.readall()

# News alert
IMGTAGNEWSALERT = IMGTAGNEWSALERT_ASSET.readall()

# Nintendo Direct
IMGTAGNINTENDODIRECT = IMGTAGNINTENDODIRECT_ASSET.readall()

# None (transparent)
IMGTAGNONE = IMGTAGNONE_ASSET.readall()

# Opinion
IMGTAGOPINION = IMGTAGOPINION_ASSET.readall()

# Persona
IMGTAGPERSONA = IMGTAGPERSONA_ASSET.readall()

# Pokémon
IMGTAGPOKEMON = IMGTAGPOKEMON_ASSET.readall()

# Pokémon Presents
IMGTAGPOKEMONPRESENTS = IMGTAGPOKEMONPRESENTS_ASSET.readall()

# Preview
IMGTAGPREVIEW = IMGTAGPREVIEW_ASSET.readall()

# Review
IMGTAGREVIEW = IMGTAGREVIEW_ASSET.readall()

# Rumour
IMGTAGRUMOUR = IMGTAGRUMOUR_ASSET.readall()

# Second look
IMGTAGSECONDLOOK = IMGTAGSECONDLOOK_ASSET.readall()

# Site update
IMGTAGSITEUPDATE = IMGTAGSITEUPDATE_ASSET.readall()

# State of Play
IMGTAGSTATEOFPLAY = IMGTAGSTATEOFPLAY_ASSET.readall()

# Summer Game Fest 24
IMGTAGSUMMERGAMEFEST24 = IMGTAGSUMMERGAMEFEST24_ASSET.readall()

# Switch 2
IMGTAGSWITCH2 = IMGTAGSWITCH2_ASSET.readall()

# Update
IMGTAGUPDATE = IMGTAGUPDATE_ASSET.readall()

# Updated (News | Updated)
IMGTAGUPDATED = IMGTAGUPDATED_ASSET.readall()

# Video
IMGTAGVIDEO = IMGTAGVIDEO_ASSET.readall()

# BACKDROPS

# Ace Attorney
IMGBGACEATTORNEY = IMGBGACEATTORNEY_ASSET.readall()

# Dungeons and Dragons
IMGBGDUNGEONSANDDRAGONS = IMGBGDUNGEONSANDDRAGONS_ASSET.readall()

# E3
IMGBGE3 = IMGBGE3_ASSET.readall()

# Error
IMGBGERROR = IMGBGERROR_ASSET.readall()

# Exclusive
IMGBGEXCLUSIVE = IMGBGEXCLUSIVE_ASSET.readall()

# Feature
IMGBGFEATURE = IMGBGFEATURE_ASSET.readall()

# #ForTheGaymers
IMGBGFORTHEGAYMERS = IMGBGFORTHEGAYMERS_ASSET.readall()

# Latest (fallback)
IMGBGLATEST = IMGBGLATEST_ASSET.readall()

# Live (animated)
IMGBGLIVE = IMGBGLIVE_ASSET.readall()

# News
IMGBGNEWS = IMGBGNEWS_ASSET.readall()

# Nintendo Direct
IMGBGNINTENDODIRECT = IMGBGNINTENDODIRECT_ASSET.readall()

# Persona
IMGBGPERSONA = IMGBGPERSONA_ASSET.readall()

# Pokémon
IMGBGPOKEMON = IMGBGPOKEMON_ASSET.readall()

# Review
IMGBGREVIEW = IMGBGREVIEW_ASSET.readall()

# State of Play
IMGBGSTATEOFPLAY = IMGBGSTATEOFPLAY_ASSET.readall()

# Summer Game Fest
IMGBGSUMMERGAMEFEST = IMGBGSUMMERGAMEFEST_ASSET.readall()

# Switch 2
IMGBGSWITCH2 = IMGBGSWITCH2_ASSET.readall()

# BRANDING

# CriticalChicken.com
IMGBRANDING = IMGBRANDING_ASSET.readall()

# MAIN

def main():
    # For linting
    excerpt_strip_bold_op = ""
    excerpt_strip_bold_ed = ""
    excerpt_strip_strong_op = ""
    excerpt_strip_strong_ed = ""
    excerpt_strip_italic_op = ""
    excerpt_strip_italic_ed = ""
    excerpt_strip_em_op = ""
    excerpt_strip_em_ed = ""
    finalheadline = ""
    finalcategory = ""
    finalexcerpt = ""

    get_feeds = http.get("https://www.criticalchicken.com/wp-json/wp/v2/posts?_fields=title,categories,excerpt&per_page=1", ttl_seconds = 900)
    if get_feeds.status_code != 200:
        return connectionError()
    get_headline = get_feeds.json()[0]["title"]["rendered"]
    get_category = get_feeds.json()[0]["categories"]
    get_excerpt = get_feeds.json()[0]["excerpt"]["rendered"]

    # Strip out HTML tags that might appear in the excerpts
    excerpt_strip_bold_op = get_excerpt.replace("<b>", "")
    excerpt_strip_bold_ed = excerpt_strip_bold_op.replace("</b>", "")
    excerpt_strip_strong_op = excerpt_strip_bold_ed.replace("<strong>", "")
    excerpt_strip_strong_ed = excerpt_strip_strong_op.replace("</strong>", "")
    excerpt_strip_italic_op = excerpt_strip_strong_ed.replace("<i>", "")
    excerpt_strip_italic_ed = excerpt_strip_italic_op.replace("</i>", "")
    excerpt_strip_em_op = excerpt_strip_italic_ed.replace("<em>", "")
    excerpt_strip_em_ed = excerpt_strip_em_op.replace("</em>", "")

    finalheadline = str(get_headline)
    finalcategory = str(get_category)
    finalexcerpt = str(excerpt_strip_em_ed)

    # Colour palette
    red = "#d20202"
    blue = "#1564dc"
    orange = "#f47614"
    yellow = "#ffdc17"

    # Decide which titleTag and backdrop to show

    # Set fallbacks
    txColour = red
    ttleTag1 = IMGTAGLATEST
    ttleTag2 = IMGTAGNONE
    backdrop = IMGBGLATEST

    # News
    if "[2.0" in finalcategory or " 2.0" in finalcategory:
        ttleTag1 = IMGTAGNEWS
        backdrop = IMGBGNEWS

        # Video
        if "[31.0" in finalcategory or " 31.0" in finalcategory:
            ttleTag1 = IMGTAGVIDEO

        # Update
        if "[29.0" in finalcategory or " 29.0" in finalcategory:
            ttleTag1 = IMGTAGUPDATE

        # Site update
        if "[27.0" in finalcategory or " 27.0" in finalcategory:
            ttleTag1 = IMGTAGSITEUPDATE

        # Rumour
        if "[25.0" in finalcategory or " 25.0" in finalcategory:
            ttleTag1 = IMGTAGRUMOUR

        # Live updates
        if "[18.0" in finalcategory or " 18.0" in finalcategory:
            ttleTag1 = IMGTAGLIVEUPDATES

        # Link
        if "[16.0" in finalcategory or " 16.0" in finalcategory:
            ttleTag1 = IMGTAGLINK

        # Updated (News | Updated)
        if "[30.0" in finalcategory or " 30.0" in finalcategory:
            ttleTag1 = IMGTAGUPDATED

    # Feature
    if "[10.0" in finalcategory or " 10.0" in finalcategory:
        txColour = blue
        ttleTag1 = IMGTAGFEATURE
        backdrop = IMGBGFEATURE

        # Opinion
        if "[21.0" in finalcategory or " 21.0" in finalcategory:
            ttleTag1 = IMGTAGOPINION

        # Interview
        if "[15.0" in finalcategory or " 15.0" in finalcategory:
            ttleTag1 = IMGTAGINTERVIEW

        # Guide
        if "[12.0" in finalcategory or " 12.0" in finalcategory:
            ttleTag1 = IMGTAGGUIDE

        # Guest blog
        if "[11.0" in finalcategory or " 11.0" in finalcategory:
            ttleTag1 = IMGTAGGUESTBLOG

    # Review
    if "[13.0" in finalcategory or " 13.0" in finalcategory:
        txColour = orange
        ttleTag1 = IMGTAGREVIEW
        backdrop = IMGBGREVIEW

        # Second look
        if "[26.0" in finalcategory or " 26.0" in finalcategory:
            ttleTag1 = IMGTAGSECONDLOOK

        # Preview
        if "[23.0" in finalcategory or " 23.0" in finalcategory:
            ttleTag1 = IMGTAGPREVIEW

        # Hands on
        if "[14.0" in finalcategory or " 14.0" in finalcategory:
            ttleTag1 = IMGTAGHANDSON

        # First impressions
        if "[24.0" in finalcategory or " 24.0" in finalcategory:
            ttleTag1 = IMGTAGFIRSTIMPRESSIONS

    # #ForTheGaymers
    if "[34.0" in finalcategory or " 34.0" in finalcategory:
        ttleTag2 = IMGTAGFORTHEGAYMERS
        backdrop = IMGBGFORTHEGAYMERS

    # Switch 2
    if "[497.0" in finalcategory or " 497.0" in finalcategory:
        ttleTag2 = IMGTAGSWITCH2
        backdrop = IMGBGSWITCH2

    # Dungeons & Dragons
    if "[452.0" in finalcategory or " 452.0" in finalcategory:
        ttleTag2 = IMGTAGDUNGEONSANDDRAGONS
        backdrop = IMGBGDUNGEONSANDDRAGONS

    # Ace Attorney
    if "[4.0" in finalcategory or " 4.0" in finalcategory:
        ttleTag2 = IMGTAGACEATTORNEY
        backdrop = IMGBGACEATTORNEY

    # Persona
    if "[504.0" in finalcategory or " 504.0" in finalcategory:
        ttleTag2 = IMGTAGPERSONA
        backdrop = IMGBGPERSONA

    # State of Play
    if "[28.0" in finalcategory or " 28.0" in finalcategory:
        ttleTag2 = IMGTAGSTATEOFPLAY
        backdrop = IMGBGSTATEOFPLAY

    # Pokémon
    if "[448.0" in finalcategory or " 448.0" in finalcategory:
        ttleTag2 = IMGTAGPOKEMON
        backdrop = IMGBGPOKEMON

    # Pokémon Presents
    if "[22.0" in finalcategory or " 22.0" in finalcategory:
        ttleTag2 = IMGTAGPOKEMONPRESENTS
        backdrop = IMGBGPOKEMON

    # Nintendo Direct
    if "[20.0" in finalcategory or " 20.0" in finalcategory:
        ttleTag2 = IMGTAGNINTENDODIRECT
        backdrop = IMGBGNINTENDODIRECT

    # Summer Game Fest 24
    if "[33.0" in finalcategory or " 33.0" in finalcategory:
        ttleTag2 = IMGTAGSUMMERGAMEFEST24
        backdrop = IMGBGSUMMERGAMEFEST

    # E3's future
    if "[8.0" in finalcategory or " 8.0" in finalcategory:
        ttleTag2 = IMGTAGE3SFUTURE
        backdrop = IMGBGE3

    # News alert
    if "[19.0" in finalcategory or " 19.0" in finalcategory:
        txColour = yellow
        ttleTag1 = IMGTAGNEWSALERT

    # Breaking news
    if "[5.0" in finalcategory or " 5.0" in finalcategory:
        txColour = yellow
        ttleTag1 = IMGTAGBREAKINGNEWS

    # Live
    if "[17.0" in finalcategory or " 17.0" in finalcategory:
        txColour = yellow
        ttleTag1 = IMGTAGLIVE
        backdrop = IMGBGLIVE

    # Exclusive
    if "[9.0" in finalcategory or " 9.0" in finalcategory:
        txColour = yellow
        ttleTag1 = IMGTAGEXCLUSIVE
        backdrop = IMGBGEXCLUSIVE

    return render.Root(
        show_full_animation = True,
        delay = 50,
        child = render.Stack(
            children = [
                animation.Transformation(
                    child = render.Box(width = 64, height = 9, color = txColour),
                    duration = 9,
                    delay = 5,
                    origin = animation.Origin(1, 1),
                    keyframes = [
                        animation.Keyframe(
                            percentage = 0.0,
                            transforms = [animation.Translate(0, 32)],
                        ),
                        animation.Keyframe(
                            percentage = 1.0,
                            transforms = [animation.Translate(0, 24)],
                        ),
                    ],
                ),
                animation.Transformation(
                    child = render.Image(width = 64, height = 9, src = ttleTag1),
                    duration = 9,
                    delay = 5,
                    origin = animation.Origin(1, 1),
                    keyframes = [
                        animation.Keyframe(
                            percentage = 0.0,
                            transforms = [animation.Translate(0, 32)],
                        ),
                        animation.Keyframe(
                            percentage = 1.0,
                            transforms = [animation.Translate(0, 24)],
                        ),
                    ],
                ),
                animation.Transformation(
                    child = render.Image(width = 64, height = 13, src = IMGBRANDING),
                    duration = 14,
                    delay = 0,
                    origin = animation.Origin(1, 1),
                    keyframes = [
                        animation.Keyframe(
                            percentage = 0.0,
                            transforms = [animation.Translate(0, -13)],
                        ),
                        animation.Keyframe(
                            percentage = 1.0,
                            transforms = [animation.Translate(0, 0)],
                        ),
                    ],
                ),
                animation.Transformation(
                    child = render.Box(width = 64, height = 32, color = "#000000"),
                    duration = 25,
                    delay = 50,
                    origin = animation.Origin(1, 1),
                    keyframes = [
                        animation.Keyframe(
                            percentage = 0.0,
                            transforms = [animation.Translate(0, 32)],
                        ),
                        animation.Keyframe(
                            percentage = 0.00000001,
                            transforms = [animation.Translate(0, 24)],
                            curve = "ease_in_out",
                        ),
                        animation.Keyframe(
                            percentage = 1.0,
                            transforms = [animation.Translate(0, 0)],
                        ),
                    ],
                ),
                animation.Transformation(
                    child = render.Image(width = 64, height = 32, src = backdrop),
                    duration = 25,
                    delay = 50,
                    origin = animation.Origin(1, 1),
                    keyframes = [
                        animation.Keyframe(
                            percentage = 0.0,
                            transforms = [animation.Translate(64, 0)],
                            curve = "ease_in_out",
                        ),
                        animation.Keyframe(
                            percentage = 1.0,
                            transforms = [animation.Translate(0, 0)],
                        ),
                    ],
                ),
                render.Box(
                    child = render.Marquee(
                        child = render.Column(
                            children = [
                                render.Box(
                                    width = 64,
                                    height = 1,
                                ),
                                render.WrappedText(
                                    content = finalheadline,
                                    font = "tb-8",
                                    align = "left",
                                    width = 64,
                                    color = "#000000",
                                    linespacing = 1,
                                ),
                                render.Box(
                                    width = 64,
                                    height = 2,
                                ),
                                render.WrappedText(
                                    content = finalexcerpt,
                                    font = "tb-8",
                                    align = "left",
                                    width = 64,
                                    color = "#000000",
                                    linespacing = 1,
                                ),
                            ],
                        ),
                        height = 32,
                        offset_start = 105,
                        offset_end = 32,
                        scroll_direction = "vertical",
                    ),
                ),
                render.Box(
                    child = render.Marquee(
                        child = render.Column(
                            children = [
                                render.WrappedText(
                                    content = finalheadline,
                                    font = "tb-8",
                                    align = "left",
                                    width = 64,
                                    color = txColour,
                                    linespacing = 1,
                                ),
                                render.Box(
                                    width = 64,
                                    height = 2,
                                ),
                                render.WrappedText(
                                    content = finalexcerpt,
                                    font = "tb-8",
                                    align = "left",
                                    width = 64,
                                    color = "#ffffff",
                                    linespacing = 1,
                                ),
                            ],
                        ),
                        height = 32,
                        offset_start = 105,
                        offset_end = 32,
                        scroll_direction = "vertical",
                    ),
                ),
                animation.Transformation(
                    child = render.Box(width = 64, height = 9, color = txColour),
                    duration = 25,
                    delay = 50,
                    origin = animation.Origin(1, 1),
                    keyframes = [
                        animation.Keyframe(
                            percentage = 0.0,
                            transforms = [animation.Translate(0, 32)],
                        ),
                        animation.Keyframe(
                            percentage = 0.00000001,
                            transforms = [animation.Translate(0, 24)],
                            curve = "ease_in_out",
                        ),
                        animation.Keyframe(
                            percentage = 1.0,
                            transforms = [animation.Translate(0, 0)],
                        ),
                    ],
                ),
                animation.Transformation(
                    child = render.Image(width = 64, height = 9, src = ttleTag1),
                    duration = 25,
                    delay = 50,
                    origin = animation.Origin(1, 1),
                    keyframes = [
                        animation.Keyframe(
                            percentage = 0.0,
                            transforms = [animation.Translate(0, 32)],
                        ),
                        animation.Keyframe(
                            percentage = 0.00000001,
                            transforms = [animation.Translate(0, 24)],
                            curve = "ease_in_out",
                        ),
                        animation.Keyframe(
                            percentage = 1.0,
                            transforms = [animation.Translate(0, 0)],
                        ),
                    ],
                ),
                animation.Transformation(
                    child = render.Image(width = 64, height = 9, src = ttleTag2),
                    duration = 10,
                    delay = 96,
                    origin = animation.Origin(1, 1),
                    keyframes = [
                        animation.Keyframe(
                            percentage = 0.0,
                            transforms = [animation.Translate(0, -9)],
                        ),
                        animation.Keyframe(
                            percentage = 1.0,
                            transforms = [animation.Translate(0, 0)],
                        ),
                    ],
                ),
            ],
        ),
    )

# ERROR MESSAGE

def connectionError():
    return render.Root(
        show_full_animation = True,
        delay = 50,
        child = render.Stack(
            children = [
                animation.Transformation(
                    child = render.Box(width = 64, height = 9, color = "#717070"),
                    duration = 9,
                    delay = 5,
                    origin = animation.Origin(1, 1),
                    keyframes = [
                        animation.Keyframe(
                            percentage = 0.0,
                            transforms = [animation.Translate(0, 32)],
                        ),
                        animation.Keyframe(
                            percentage = 1.0,
                            transforms = [animation.Translate(0, 24)],
                        ),
                    ],
                ),
                animation.Transformation(
                    child = render.Image(width = 64, height = 9, src = IMGTAGERROR),
                    duration = 9,
                    delay = 5,
                    origin = animation.Origin(1, 1),
                    keyframes = [
                        animation.Keyframe(
                            percentage = 0.0,
                            transforms = [animation.Translate(0, 32)],
                        ),
                        animation.Keyframe(
                            percentage = 1.0,
                            transforms = [animation.Translate(0, 24)],
                        ),
                    ],
                ),
                animation.Transformation(
                    child = render.Image(width = 64, height = 13, src = IMGBRANDING),
                    duration = 14,
                    delay = 0,
                    origin = animation.Origin(1, 1),
                    keyframes = [
                        animation.Keyframe(
                            percentage = 0.0,
                            transforms = [animation.Translate(0, -13)],
                        ),
                        animation.Keyframe(
                            percentage = 1.0,
                            transforms = [animation.Translate(0, 0)],
                        ),
                    ],
                ),
                animation.Transformation(
                    child = render.Box(width = 64, height = 32, color = "#000000"),
                    duration = 25,
                    delay = 50,
                    origin = animation.Origin(1, 1),
                    keyframes = [
                        animation.Keyframe(
                            percentage = 0.0,
                            transforms = [animation.Translate(0, 32)],
                        ),
                        animation.Keyframe(
                            percentage = 0.00000001,
                            transforms = [animation.Translate(0, 24)],
                            curve = "ease_in_out",
                        ),
                        animation.Keyframe(
                            percentage = 1.0,
                            transforms = [animation.Translate(0, 0)],
                        ),
                    ],
                ),
                animation.Transformation(
                    child = render.Image(width = 64, height = 32, src = IMGBGERROR),
                    duration = 25,
                    delay = 50,
                    origin = animation.Origin(1, 1),
                    keyframes = [
                        animation.Keyframe(
                            percentage = 0.0,
                            transforms = [animation.Translate(64, 0)],
                            curve = "ease_in_out",
                        ),
                        animation.Keyframe(
                            percentage = 1.0,
                            transforms = [animation.Translate(0, 0)],
                        ),
                    ],
                ),
                render.Box(
                    child = render.Marquee(
                        child = render.Column(
                            children = [
                                render.Box(
                                    width = 64,
                                    height = 1,
                                ),
                                render.WrappedText(
                                    content = "We couldn't get the latest post.",
                                    font = "tb-8",
                                    align = "left",
                                    width = 64,
                                    color = "#000000",
                                    linespacing = 1,
                                ),
                                render.Box(
                                    width = 64,
                                    height = 2,
                                ),
                                render.WrappedText(
                                    content = "We'll try again in a few minutes.",
                                    font = "tb-8",
                                    align = "left",
                                    width = 64,
                                    color = "#000000",
                                    linespacing = 1,
                                ),
                            ],
                        ),
                        height = 32,
                        offset_start = 105,
                        offset_end = 32,
                        scroll_direction = "vertical",
                    ),
                ),
                render.Box(
                    child = render.Marquee(
                        child = render.Column(
                            children = [
                                render.WrappedText(
                                    content = "We couldn't get the latest post.",
                                    font = "tb-8",
                                    align = "left",
                                    width = 64,
                                    color = "#ffffff",
                                    linespacing = 1,
                                ),
                                render.Box(
                                    width = 64,
                                    height = 2,
                                ),
                                render.WrappedText(
                                    content = "We'll try again in a few minutes.",
                                    font = "tb-8",
                                    align = "left",
                                    width = 64,
                                    color = "#ffffff",
                                    linespacing = 1,
                                ),
                            ],
                        ),
                        height = 32,
                        offset_start = 105,
                        offset_end = 32,
                        scroll_direction = "vertical",
                    ),
                ),
                animation.Transformation(
                    child = render.Box(width = 64, height = 9, color = "#717070"),
                    duration = 25,
                    delay = 50,
                    origin = animation.Origin(1, 1),
                    keyframes = [
                        animation.Keyframe(
                            percentage = 0.0,
                            transforms = [animation.Translate(0, 32)],
                        ),
                        animation.Keyframe(
                            percentage = 0.00000001,
                            transforms = [animation.Translate(0, 24)],
                            curve = "ease_in_out",
                        ),
                        animation.Keyframe(
                            percentage = 1.0,
                            transforms = [animation.Translate(0, 0)],
                        ),
                    ],
                ),
                animation.Transformation(
                    child = render.Image(width = 64, height = 9, src = IMGTAGERROR),
                    duration = 25,
                    delay = 50,
                    origin = animation.Origin(1, 1),
                    keyframes = [
                        animation.Keyframe(
                            percentage = 0.0,
                            transforms = [animation.Translate(0, 32)],
                        ),
                        animation.Keyframe(
                            percentage = 0.00000001,
                            transforms = [animation.Translate(0, 24)],
                            curve = "ease_in_out",
                        ),
                        animation.Keyframe(
                            percentage = 1.0,
                            transforms = [animation.Translate(0, 0)],
                        ),
                    ],
                ),
                animation.Transformation(
                    child = render.Image(width = 64, height = 9, src = IMGTAGNONE),
                    duration = 10,
                    delay = 96,
                    origin = animation.Origin(1, 1),
                    keyframes = [
                        animation.Keyframe(
                            percentage = 0.0,
                            transforms = [animation.Translate(0, -9)],
                        ),
                        animation.Keyframe(
                            percentage = 1.0,
                            transforms = [animation.Translate(0, 0)],
                        ),
                    ],
                ),
            ],
        ),
    )

# SCHEMA

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
        ],
    )
