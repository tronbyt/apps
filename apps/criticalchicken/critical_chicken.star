"""
Applet: Critical Chicken
Summary: Gaming news
Description: Shows the latest post from CriticalChicken.com.
Author: Critical Chicken
"""

load("animation.star", "animation")
load("http.star", "http")
load("images/e3.png", E3_ASSET = "file")
load("images/img_2.png", IMG_2_ASSET = "file")
load("images/img_24.png", IMG_24_ASSET = "file")
load("images/imgbgaceattorney.png", IMGBGACEATTORNEY_ASSET = "file")
load("images/imgbgdungeonsanddragons.png", IMGBGDUNGEONSANDDRAGONS_ASSET = "file")
load("images/imgbge3.png", IMGBGE3_ASSET = "file")
load("images/imgbgerror.png", IMGBGERROR_ASSET = "file")
load("images/imgbgexclusive.png", IMGBGEXCLUSIVE_ASSET = "file")
load("images/imgbgfeature.png", IMGBGFEATURE_ASSET = "file")
load("images/imgbgforthegaymers.png", IMGBGFORTHEGAYMERS_ASSET = "file")
load("images/imgbglatest.png", IMGBGLATEST_ASSET = "file")
load("images/imgbglive.gif", IMGBGLIVE_ASSET = "file")
load("images/imgbgnews.png", IMGBGNEWS_ASSET = "file")
load("images/imgbgnintendodirect.png", IMGBGNINTENDODIRECT_ASSET = "file")
load("images/imgbgpersona.png", IMGBGPERSONA_ASSET = "file")
load("images/imgbgpokemon.png", IMGBGPOKEMON_ASSET = "file")
load("images/imgbgreview.png", IMGBGREVIEW_ASSET = "file")
load("images/imgbgstateofplay.png", IMGBGSTATEOFPLAY_ASSET = "file")
load("images/imgbgsummergamefest.png", IMGBGSUMMERGAMEFEST_ASSET = "file")
load("images/imgbgswitch2.png", IMGBGSWITCH2_ASSET = "file")
load("images/imgbranding.png", IMGBRANDING_ASSET = "file")
load("images/imgtagaceattorney.png", IMGTAGACEATTORNEY_ASSET = "file")
load("images/imgtagbreakingnews.png", IMGTAGBREAKINGNEWS_ASSET = "file")
load("images/imgtagdungeonsanddragons.png", IMGTAGDUNGEONSANDDRAGONS_ASSET = "file")
load("images/imgtage3sfuture.png", IMGTAGE3SFUTURE_ASSET = "file")
load("images/imgtagerror.png", IMGTAGERROR_ASSET = "file")
load("images/imgtagexclusive.png", IMGTAGEXCLUSIVE_ASSET = "file")
load("images/imgtagfeature.png", IMGTAGFEATURE_ASSET = "file")
load("images/imgtagfirstimpressions.png", IMGTAGFIRSTIMPRESSIONS_ASSET = "file")
load("images/imgtagforthegaymers.png", IMGTAGFORTHEGAYMERS_ASSET = "file")
load("images/imgtagguestblog.png", IMGTAGGUESTBLOG_ASSET = "file")
load("images/imgtagguide.png", IMGTAGGUIDE_ASSET = "file")
load("images/imgtaghandson.png", IMGTAGHANDSON_ASSET = "file")
load("images/imgtaginterview.png", IMGTAGINTERVIEW_ASSET = "file")
load("images/imgtaglatest.png", IMGTAGLATEST_ASSET = "file")
load("images/imgtaglink.png", IMGTAGLINK_ASSET = "file")
load("images/imgtaglive.png", IMGTAGLIVE_ASSET = "file")
load("images/imgtagliveupdates.png", IMGTAGLIVEUPDATES_ASSET = "file")
load("images/imgtagnews.png", IMGTAGNEWS_ASSET = "file")
load("images/imgtagnewsalert.png", IMGTAGNEWSALERT_ASSET = "file")
load("images/imgtagnintendodirect.png", IMGTAGNINTENDODIRECT_ASSET = "file")
load("images/imgtagnone.png", IMGTAGNONE_ASSET = "file")
load("images/imgtagopinion.png", IMGTAGOPINION_ASSET = "file")
load("images/imgtagpersona.png", IMGTAGPERSONA_ASSET = "file")
load("images/imgtagpokemon.png", IMGTAGPOKEMON_ASSET = "file")
load("images/imgtagpokemonpresents.png", IMGTAGPOKEMONPRESENTS_ASSET = "file")
load("images/imgtagpreview.png", IMGTAGPREVIEW_ASSET = "file")
load("images/imgtagreview.png", IMGTAGREVIEW_ASSET = "file")
load("images/imgtagrumour.png", IMGTAGRUMOUR_ASSET = "file")
load("images/imgtagsecondlook.png", IMGTAGSECONDLOOK_ASSET = "file")
load("images/imgtagsiteupdate.png", IMGTAGSITEUPDATE_ASSET = "file")
load("images/imgtagstateofplay.png", IMGTAGSTATEOFPLAY_ASSET = "file")
load("images/imgtagsummergamefest24.png", IMGTAGSUMMERGAMEFEST24_ASSET = "file")
load("images/imgtagswitch2.png", IMGTAGSWITCH2_ASSET = "file")
load("images/imgtagupdate.png", IMGTAGUPDATE_ASSET = "file")
load("images/imgtagupdated.png", IMGTAGUPDATED_ASSET = "file")
load("images/imgtagvideo.png", IMGTAGVIDEO_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

IMGBGACEATTORNEY = IMGBGACEATTORNEY_ASSET.readall()
IMGBGDUNGEONSANDDRAGONS = IMGBGDUNGEONSANDDRAGONS_ASSET.readall()
IMGBGE3 = IMGBGE3_ASSET.readall()
IMGBGERROR = IMGBGERROR_ASSET.readall()
IMGBGEXCLUSIVE = IMGBGEXCLUSIVE_ASSET.readall()
IMGBGFEATURE = IMGBGFEATURE_ASSET.readall()
IMGBGFORTHEGAYMERS = IMGBGFORTHEGAYMERS_ASSET.readall()
IMGBGLATEST = IMGBGLATEST_ASSET.readall()
IMGBGLIVE = IMGBGLIVE_ASSET.readall()
IMGBGNEWS = IMGBGNEWS_ASSET.readall()
IMGBGNINTENDODIRECT = IMGBGNINTENDODIRECT_ASSET.readall()
IMGBGPERSONA = IMGBGPERSONA_ASSET.readall()
IMGBGPOKEMON = IMGBGPOKEMON_ASSET.readall()
IMGBGREVIEW = IMGBGREVIEW_ASSET.readall()
IMGBGSTATEOFPLAY = IMGBGSTATEOFPLAY_ASSET.readall()
IMGBGSUMMERGAMEFEST = IMGBGSUMMERGAMEFEST_ASSET.readall()
IMGBGSWITCH2 = IMGBGSWITCH2_ASSET.readall()
IMGBRANDING = IMGBRANDING_ASSET.readall()
IMGTAGACEATTORNEY = IMGTAGACEATTORNEY_ASSET.readall()
IMGTAGBREAKINGNEWS = IMGTAGBREAKINGNEWS_ASSET.readall()
IMGTAGDUNGEONSANDDRAGONS = IMGTAGDUNGEONSANDDRAGONS_ASSET.readall()
IMGTAGE3SFUTURE = IMGTAGE3SFUTURE_ASSET.readall()
IMGTAGERROR = IMGTAGERROR_ASSET.readall()
IMGTAGEXCLUSIVE = IMGTAGEXCLUSIVE_ASSET.readall()
IMGTAGFEATURE = IMGTAGFEATURE_ASSET.readall()
IMGTAGFIRSTIMPRESSIONS = IMGTAGFIRSTIMPRESSIONS_ASSET.readall()
IMGTAGFORTHEGAYMERS = IMGTAGFORTHEGAYMERS_ASSET.readall()
IMGTAGGUESTBLOG = IMGTAGGUESTBLOG_ASSET.readall()
IMGTAGGUIDE = IMGTAGGUIDE_ASSET.readall()
IMGTAGHANDSON = IMGTAGHANDSON_ASSET.readall()
IMGTAGINTERVIEW = IMGTAGINTERVIEW_ASSET.readall()
IMGTAGLATEST = IMGTAGLATEST_ASSET.readall()
IMGTAGLINK = IMGTAGLINK_ASSET.readall()
IMGTAGLIVE = IMGTAGLIVE_ASSET.readall()
IMGTAGLIVEUPDATES = IMGTAGLIVEUPDATES_ASSET.readall()
IMGTAGNEWS = IMGTAGNEWS_ASSET.readall()
IMGTAGNEWSALERT = IMGTAGNEWSALERT_ASSET.readall()
IMGTAGNINTENDODIRECT = IMGTAGNINTENDODIRECT_ASSET.readall()
IMGTAGNONE = IMGTAGNONE_ASSET.readall()
IMGTAGOPINION = IMGTAGOPINION_ASSET.readall()
IMGTAGPERSONA = IMGTAGPERSONA_ASSET.readall()
IMGTAGPOKEMON = IMGTAGPOKEMON_ASSET.readall()
IMGTAGPOKEMONPRESENTS = IMGTAGPOKEMONPRESENTS_ASSET.readall()
IMGTAGPREVIEW = IMGTAGPREVIEW_ASSET.readall()
IMGTAGREVIEW = IMGTAGREVIEW_ASSET.readall()
IMGTAGRUMOUR = IMGTAGRUMOUR_ASSET.readall()
IMGTAGSECONDLOOK = IMGTAGSECONDLOOK_ASSET.readall()
IMGTAGSITEUPDATE = IMGTAGSITEUPDATE_ASSET.readall()
IMGTAGSTATEOFPLAY = IMGTAGSTATEOFPLAY_ASSET.readall()
IMGTAGSUMMERGAMEFEST24 = IMGTAGSUMMERGAMEFEST24_ASSET.readall()
IMGTAGSWITCH2 = IMGTAGSWITCH2_ASSET.readall()
IMGTAGUPDATE = IMGTAGUPDATE_ASSET.readall()
IMGTAGUPDATED = IMGTAGUPDATED_ASSET.readall()
IMGTAGVIDEO = IMGTAGVIDEO_ASSET.readall()

E3 = E3_ASSET.readall()
IMG_2 = IMG_2_ASSET.readall()
IMG_24 = IMG_24_ASSET.readall()

# IMAGES

# TITLETAGS

# Ace Attorney

# Breaking news

# Dungeons + Dragons

# E3's future

# Error

# Exclusive

# Feature

# First impressions

# #ForTheGaymers

# Guest blog

# Guide

# Hands on

# Interview

# Latest (placeholder)

# Link

# Live

# Live updates

# News

# News alert

# Nintendo Direct

# None (transparent)

# Opinion

# Persona

# Pokémon

# Pokémon Presents

# Preview

# Review

# Rumour

# Second look

# Site update

# State of Play

# Summer Game Fest IMG_24

# Switch IMG_2

# Update

# Updated (News | Updated)

# Video

# BACKDROPS

# Ace Attorney

# Dungeons and Dragons

# E3

# Error

# Exclusive

# Feature

# #ForTheGaymers

# Latest (fallback)

# Live (animated)

# News

# Nintendo Direct

# Persona

# Pokémon

# Review

# State of Play

# Summer Game Fest

# Switch IMG_2

# BRANDING

# CriticalChicken.com

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
    if "[IMG_2.0" in finalcategory or " IMG_2.0" in finalcategory:
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
        if "[IMG_24.0" in finalcategory or " IMG_24.0" in finalcategory:
            ttleTag1 = IMGTAGFIRSTIMPRESSIONS

    # #ForTheGaymers
    if "[34.0" in finalcategory or " 34.0" in finalcategory:
        ttleTag2 = IMGTAGFORTHEGAYMERS
        backdrop = IMGBGFORTHEGAYMERS

    # Switch IMG_2
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

    # Summer Game Fest IMG_24
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
                            transforms = [animation.Translate(0, IMG_24)],
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
                            transforms = [animation.Translate(0, IMG_24)],
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
                            transforms = [animation.Translate(0, IMG_24)],
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
                                    height = IMG_2,
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
                                    height = IMG_2,
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
                            transforms = [animation.Translate(0, IMG_24)],
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
                            transforms = [animation.Translate(0, IMG_24)],
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
                            transforms = [animation.Translate(0, IMG_24)],
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
                            transforms = [animation.Translate(0, IMG_24)],
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
                            transforms = [animation.Translate(0, IMG_24)],
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
                                    height = IMG_2,
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
                                    height = IMG_2,
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
                            transforms = [animation.Translate(0, IMG_24)],
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
                            transforms = [animation.Translate(0, IMG_24)],
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
