"""
Applet: Duolingo
Summary: Display Duolingo Progress
Description: Track your Duolingo study progress. The app has multiple views: Today, Week, Two Weeks. You can add multiple instances to display more than one. Note: The app will be hidden from the rotation if no lessons have been completed in the last week.
Author: Olly Stedall @saltedlolly
Thanks: @drudge @whyamIhere @AmillionAir
"""

load("cache.star", "cache")
load("http.star", "http")
load("images/crown_icon.png", CROWN_ICON_ASSET = "file")
load("images/duolingo_icon_angry.webp", DUOLINGO_ICON_ANGRY_ASSET = "file")
load("images/duolingo_icon_cry.webp", DUOLINGO_ICON_CRY_ASSET = "file")
load("images/duolingo_icon_dancing.webp", DUOLINGO_ICON_DANCING_ASSET = "file")
load("images/duolingo_icon_fly.webp", DUOLINGO_ICON_FLY_ASSET = "file")
load("images/duolingo_icon_sleeping.webp", DUOLINGO_ICON_SLEEPING_ASSET = "file")
load("images/duolingo_icon_standing.webp", DUOLINGO_ICON_STANDING_ASSET = "file")
load("images/duolingo_icon_standing_point_down.webp", DUOLINGO_ICON_STANDING_POINT_DOWN_ASSET = "file")
load("images/duolingo_icon_standing_point_left.webp", DUOLINGO_ICON_STANDING_POINT_LEFT_ASSET = "file")
load("images/duolingo_icon_standing_point_right.webp", DUOLINGO_ICON_STANDING_POINT_RIGHT_ASSET = "file")
load("images/duolingo_icon_standing_point_right_flap.webp", DUOLINGO_ICON_STANDING_POINT_RIGHT_FLAP_ASSET = "file")
load("images/progressbar_darkblue_arrows.webp", PROGRESSBAR_DARKBLUE_ARROWS_ASSET = "file")
load("images/progressbar_gold_arrows.webp", PROGRESSBAR_GOLD_ARROWS_ASSET = "file")
load("images/progressbar_orange_arrows.webp", PROGRESSBAR_ORANGE_ARROWS_ASSET = "file")
load("images/progressbar_purple_arrows.webp", PROGRESSBAR_PURPLE_ARROWS_ASSET = "file")
load("images/progressbar_turquoise_arrows.webp", PROGRESSBAR_TURQUOISE_ARROWS_ASSET = "file")
load("images/streak_icon_frozen.png", STREAK_ICON_FROZEN_ASSET = "file")
load("images/streak_icon_gold.png", STREAK_ICON_GOLD_ASSET = "file")
load("images/streak_icon_gold_animated.webp", STREAK_ICON_GOLD_ANIMATED_ASSET = "file")
load("images/streak_icon_gold_animated_old.webp", STREAK_ICON_GOLD_ANIMATED_OLD_ASSET = "file")
load("images/streak_icon_grey.png", STREAK_ICON_GREY_ASSET = "file")
load("images/xp_icon_gold.webp", XP_ICON_GOLD_ASSET = "file")
load("images/xp_icon_grey.png", XP_ICON_GREY_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

CROWN_ICON = CROWN_ICON_ASSET.readall()
DUOLINGO_ICON_ANGRY = DUOLINGO_ICON_ANGRY_ASSET.readall()
DUOLINGO_ICON_CRY = DUOLINGO_ICON_CRY_ASSET.readall()
DUOLINGO_ICON_DANCING = DUOLINGO_ICON_DANCING_ASSET.readall()
DUOLINGO_ICON_FLY = DUOLINGO_ICON_FLY_ASSET.readall()
DUOLINGO_ICON_SLEEPING = DUOLINGO_ICON_SLEEPING_ASSET.readall()
DUOLINGO_ICON_STANDING = DUOLINGO_ICON_STANDING_ASSET.readall()
DUOLINGO_ICON_STANDING_POINT_DOWN = DUOLINGO_ICON_STANDING_POINT_DOWN_ASSET.readall()
DUOLINGO_ICON_STANDING_POINT_LEFT = DUOLINGO_ICON_STANDING_POINT_LEFT_ASSET.readall()
DUOLINGO_ICON_STANDING_POINT_RIGHT = DUOLINGO_ICON_STANDING_POINT_RIGHT_ASSET.readall()
DUOLINGO_ICON_STANDING_POINT_RIGHT_FLAP = DUOLINGO_ICON_STANDING_POINT_RIGHT_FLAP_ASSET.readall()
PROGRESSBAR_DARKBLUE_ARROWS = PROGRESSBAR_DARKBLUE_ARROWS_ASSET.readall()
PROGRESSBAR_GOLD_ARROWS = PROGRESSBAR_GOLD_ARROWS_ASSET.readall()
PROGRESSBAR_ORANGE_ARROWS = PROGRESSBAR_ORANGE_ARROWS_ASSET.readall()
PROGRESSBAR_PURPLE_ARROWS = PROGRESSBAR_PURPLE_ARROWS_ASSET.readall()
PROGRESSBAR_TURQUOISE_ARROWS = PROGRESSBAR_TURQUOISE_ARROWS_ASSET.readall()
STREAK_ICON_FROZEN = STREAK_ICON_FROZEN_ASSET.readall()
STREAK_ICON_GOLD = STREAK_ICON_GOLD_ASSET.readall()
STREAK_ICON_GOLD_ANIMATED = STREAK_ICON_GOLD_ANIMATED_ASSET.readall()
STREAK_ICON_GOLD_ANIMATED_OLD = STREAK_ICON_GOLD_ANIMATED_OLD_ASSET.readall()
STREAK_ICON_GREY = STREAK_ICON_GREY_ASSET.readall()
XP_ICON_GOLD = XP_ICON_GOLD_ASSET.readall()
XP_ICON_GREY = XP_ICON_GREY_ASSET.readall()

print(" ---------------------------------------------------------------------------------------------------------------------")

# Set applet defaults
DEFAULT_USERNAME = "saltedlolly"
DEFAULT_DAILY_XP_TARGET = "100"  # Choose the desired daily XP goal. The XP goal set in the Duolingo app is ignored.
DEFAULT_TIMEZONE = "Europe/London"  # Affects when the daily XP counter resets.
DEFAULT_DISPLAY_VIEW = "week"  # can be 'today', 'week' or 'twoweeks'
DEFAULT_NICKNAME = ""  # Max five characters. Displays on screen to identify the Duolingo user.
DEFAULT_SHOW_EXTRA_STATS = "totalxp"  # Display currennt Streak and total XP score on the week chart. Can be 'none', 'todayxp', 'chartxp' or 'totalxp'

# 18 x 18 Standing Blinking, Flap

# 16 x 18 - Point Left, Look Right, Blink

# 16 x 18

# 16 x 18

# 16 x 18

# Duolingo Owl Flying 18 x 18

# Duolingo Owl Angry - Animated Stamping # 16 x 18

# Duolingo Owl Crying - Animated Tears # 16 x 18

# Duolingo Owl Sleeping - Animated Zzz # 16 x 18

# Duolingo Owl Dancing # 18 x 18

# Streak Flame Icon - Gold 6x7

# Streak Flame Icon - Gold Animated 6x7

# Streak Flame Icon - Gold Animated 5x7

# Streak Flame Icon - Greyscale 6x7

# Streak Flame Icon - Frozen 6x7

# XP Spark Icon - Gold Animated  6x7

# XP Spark Icon - Greyscale  6x7

# Crown Icon  9x7

# Progress Bar Complete - Gold Arrows 25x3

# Progress Bar Complete - Purple Arrows 25x3

# Progress Bar Complete - Turqoise Arrows 25x3

# Progress Bar Complete - Orange Arrows 25x3

# Progress Bar Complete - Dark Blue Arrows 25x3

DISPLAY_VIEW_LIST = {
    "Today": "today",
    "One Week": "week",
    "Two Weeks": "twoweeks",
}

DISPLAY_HEADER_LIST = {
    "None": "none",
    "Streak + Today XP": "todayxp",
    "Streak + Chart XP": "chartxp",
    "Streak + Total XP": "totalxp",
}

XP_TARGET_LIST = {
    "None": "0",
    "20xp": "20",
    "30xp": "30",
    "40xp": "40",
    "50xp": "50",
    "60xp": "60",
    "75xp": "75",
    "100xp": "100",
    "125xp": "125",
    "150xp": "150",
    "175xp": "175",
    "200xp": "200",
    "250xp": "250",
    "300xp": "300",
    "400xp": "400",
    "500xp": "500",
}

def get_schema():
    displayoptions = [
        schema.Option(display = displaykey, value = displayval)
        for displaykey, displayval in DISPLAY_VIEW_LIST.items()
    ]

    xptargetoptions = [
        schema.Option(display = xptargetkey, value = xptargetval)
        for xptargetkey, xptargetval in XP_TARGET_LIST.items()
    ]

    headeroptions = [
        schema.Option(display = headerkey, value = headerval)
        for headerkey, headerval in DISPLAY_HEADER_LIST.items()
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "duolingo_username",
                name = "Username",
                desc = "Enter a Duolingo username.",
                icon = "user",
                default = DEFAULT_USERNAME,
            ),
            schema.Dropdown(
                id = "xp_target",
                name = "Daily XP target",
                desc = "Enter a daily XP target. Resets at midnight.",
                icon = "trophy",
                default = xptargetoptions[6].value,
                options = xptargetoptions,
            ),
            schema.Dropdown(
                id = "display_view",
                name = "Display",
                desc = "Choose Today or Week view.",
                icon = "display",
                default = displayoptions[0].value,
                options = displayoptions,
            ),
            schema.Dropdown(
                id = "extra_week_stats",
                name = "Extra Chart Stats?",
                desc = "Optionally display the user's Streak and Total XP, Today's XP, or the XP for the current chart duration.",
                icon = "eye",
                default = headeroptions[0].value,
                options = headeroptions,
            ),
            schema.Text(
                id = "nickname",
                name = "Nickname",
                desc = "Display on Tidbyt to identify the user. Max 5 letters.",
                icon = "user",
                default = DEFAULT_NICKNAME,
            ),
        ],
    )

def main(config):
    # Defined potentially undefined variables.
    DUOLINGO_ICON = None
    PROGRESSBAR_ANI = None
    XP_ICON = None
    dayofweek = None
    display_error_msg = None
    display_frozen_lastweek = None
    display_frozen_thisweek = None
    display_missed_lastweek = None
    display_missed_thisweek = None
    display_output = None
    display_repaired_lastweek = None
    display_repaired_thisweek = None
    do_duolingo_main_query = None
    duolingo_main_json = None
    duolingo_main_query_url = None
    duolingo_streak = None
    duolingo_streak_daystart = None
    duolingo_streak_now = None
    duolingo_totalxp = None
    duolingo_totalxp_daystart = None
    duolingo_totalxp_now = None
    duolingo_userid = None
    duolingo_xpsummary_json = None
    duolingo_xptoday = None
    error_message_1 = None
    error_message_2 = None
    nickname_today_view = None
    oneweek_bar = None
    oneweek_todays_bar = None
    progressbar_col = None
    progressbar_perc = None
    show_chartbar = None
    streak_icon = None
    twoweek_todays_bar = None
    twoweeks_bar = None
    twoweeks_bar_lastweek_frozen = None
    twoweeks_bar_lastweek_missed = None
    twoweeks_bar_lastweek_normal = None
    twoweeks_bar_lastweek_repaired = None
    twoweeks_bar_thisweek_frozen = None
    twoweeks_bar_thisweek_missed = None
    twoweeks_bar_thisweek_normal = None
    twoweeks_bar_thisweek_repaired = None
    upper_chart_value = None
    vertbar_lastweek_col = None
    vertbar_lastweek_col_frozen = None
    vertbar_lastweek_col_header = None
    vertbar_lastweek_col_missed = None
    vertbar_lastweek_col_repaired = None
    week_xp_scores = None
    week_xp_scores_total = None
    xp_day_score_lastweek = None
    xp_query_time = None
    xp_score = None

    # Get Schema variables
    duolingo_username = config.get("duolingo_username", DEFAULT_USERNAME)
    display_view = config.str("display_view", DEFAULT_DISPLAY_VIEW)
    xp_target = int(config.str("xp_target", DEFAULT_DAILY_XP_TARGET))
    nickname = config.get("nickname", DEFAULT_NICKNAME)
    display_extra_stats = config.str("extra_week_stats", DEFAULT_SHOW_EXTRA_STATS)

    print("XP Target: " + str(xp_target))

    # Trim nickname to only display first five characters, and capitalize
    nickname = nickname[:5].upper()

    # Setup user cache keys
    duolingo_cache_key_username = "duolingo_%s" % duolingo_username

    duolingo_cache_key_saveddate = "%s_saveddate" % duolingo_cache_key_username
    duolingo_cache_key_totalxp_daystart = "%s_totalxp_daystart" % duolingo_cache_key_username
    duolingo_cache_key_streak_daystart = "%s_streak_daystart" % duolingo_cache_key_username

    # Get Cache variables
    duolingo_saveddate_cached = cache.get(duolingo_cache_key_saveddate)
    duolingo_totalxp_daystart_cached = cache.get(duolingo_cache_key_totalxp_daystart)
    duolingo_streak_daystart_cached = cache.get(duolingo_cache_key_streak_daystart)

    # Get time and location variables
    timezone = time.tz()
    print("Using timezone " + timezone)

    # DEBUG
    # print("DEBUG WARNING: Duolingo Username is set to saltedlolly manually.")
    # duolingo_username = "saltedlolly"

    #Setup main query url
    duolingo_main_query_url_prefix = "https://www.duolingo.com/2017-06-30/users?username="
    if duolingo_username != None:
        duolingo_main_query_url = duolingo_main_query_url_prefix + duolingo_username

    # IMPORTANT NOTE: There are two queries that need to be made to duolingo.com
    # The main query is made the first time the script runs each day (to update the daily xptotal)
    # The xpsummary query is made every 15 minutes (to get the running xp count, and live status)

    # FIRST LOOKUP CURRENT DUOLINGO USERID (OR RETRIEVE FROM CACHE)
    # If the userid for the provided username is not yet known, send a query to duolingo.com to retrieve it
    # Thereafter the userid for the associated username is cached for 7 days, and the timer is updated on each run
    # i.e. So as long as that username continues to be used in the app, the userid will remain cached

    # Check a username has been provided (i.e. field is not blank)
    if duolingo_username != None:
        do_duolingo_main_query = True

    # Lookup userId from supplied username (if not already found in cache)
    if do_duolingo_main_query == True:
        print("Querying duolingo.com for userId...")

        headers = {
            "authority": "www.duolingo.com",
            "accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
            "accept-language": "en-US,en;q=0.9",
            "dnt": "1",
            "sec-ch-ua": '"Google Chrome";v="111", "Not(A:Brand";v="8", "Chromium";v="111"',
            "sec-ch-ua-mobile": "?0",
            "sec-ch-ua-platform": '"macOS"',
            "sec-fetch-dest": "document",
            "sec-fetch-mode": "navigate",
            "sec-fetch-site": "none",
            "sec-fetch-user": "?1",
            "upgrade-insecure-requests": "1",
            "user-agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36",
        }

        duolingo_main_query = http.get(duolingo_main_query_url, headers = headers, ttl_seconds = 604800)

        if duolingo_main_query.status_code != 200:
            if duolingo_main_query.status_code == 422:
                print("Error! No Duolingo username provided.")
                display_error_msg = True
                error_message_1 = "username"
                error_message_2 = "is blank"
                duolingo_userid = None
            else:
                print("Duolingo query failed with status %d", duolingo_main_query.status_code)
                display_error_msg = True
                error_message_1 = "check"
                error_message_2 = "connection"
                duolingo_userid = None
        else:
            # display an error message if the username is unrecognised
            duolingo_main_json = duolingo_main_query.json()
            if duolingo_main_json["users"] == []:
                print("Error! Unrecognised username.")
                display_error_msg = True
                error_message_1 = "invalid"
                error_message_2 = "username"
                duolingo_userid = None
            else:
                duolingo_userid = int(duolingo_main_json["users"][0]["id"])
                if duolingo_userid != None:
                    print("Success! userId for username \"" + str(duolingo_username) + "\": " + str(duolingo_userid))
                    display_error_msg = False
                else:
                    # Show error if username not found
                    print("userId not found.")
                    display_error_msg = True
                    error_message_1 = "username"
                    error_message_2 = "not found"

    # Declare display variable
    hide_duolingo_in_rotation = False

    # If we know the userId then next we'll lookup the progress data for that user (either from duolingo or from cache)
    if duolingo_userid != None:
        # LOOKUP DUOLINGO XP SUMMARY JSON DATA
        # The XP summary is updated every 15 minutes

        # Example Query: https://www.duolingo.com/2017-06-30/users/6364229/xp_summaries?startDate=2022-02-24&endDate=2022-02-24&Europe/London

        # Setup xp summary query URL
        duolingo_xpsummary_query_1 = "https://www.duolingo.com/2017-06-30/users/"
        duolingo_xpsummary_query_2 = "/xp_summaries?startDate="
        duolingo_xpsummary_query_3 = "&endDate="
        duolingo_xpsummary_query_4 = "&timezone="

        # Get today's date
        now = time.now().in_location(timezone)
        date_now = now.format("2006-01-02").upper()
        hour_now = now.hour

        # Get the date 13 days ago
        thirteen_days_ago = now - time.parse_duration("312h")  # 312h /108
        startDate = thirteen_days_ago.format("2006-01-02").upper()

        # Set end date variable (today)
        endDate = date_now

        print("Start Date: " + str(startDate) + "   End Date: " + str(endDate))

        DUOLINGO_XP_QUERY_URL = duolingo_xpsummary_query_1 + str(duolingo_userid) + duolingo_xpsummary_query_2 + startDate + duolingo_xpsummary_query_3 + endDate + duolingo_xpsummary_query_4 + timezone

        print("Querying duolingo.com for XP summary data.")
        xpsummary_query = http.get(DUOLINGO_XP_QUERY_URL, ttl_seconds = 900)
        if xpsummary_query.status_code != 200:
            print("XP summary query failed with status %d", xpsummary_query.status_code)
            display_error_msg = True
            error_message_1 = "check"
            error_message_2 = "connection"
            live_xp_data = None
        else:
            display_error_msg = False
            duolingo_xpsummary_json = xpsummary_query.json()
            xp_query_time = now
            live_xp_data = True

            # Show error if username was not recognised
            print("XP summary data retrieved from duolingo.com")

        # Setup dummy data for use on days with no data available
        dummy_data = {"gainedXp": 0, "streakExtended": False, "frozen": False, "repaired": False, "dummyData": True}

        # If there is no data returned at all for the time frame then we can assume no lessons have been completed recently
        # In this case we need to insert dummy data for the entire time frame
        if duolingo_xpsummary_json["summaries"] == []:
            hide_duolingo_in_rotation = True
            print("WARNING: Duolingo returned no data suggesting no lessons have been completed for the last 14 days. App will be hidden.")
        else:
            # Lookup the date from the first 'date' value in JSON too see if it is today's data
            time_of_first_entry_unix_time = int(duolingo_xpsummary_json["summaries"][0]["date"])
            time_of_first_entry = time.from_timestamp(time_of_first_entry_unix_time).in_location("UTC")
            date_of_first_entry = time_of_first_entry.format("2006-01-02")

            # If the data is from yesterday, insert today's dummy data into JSON variable. (This will be replaced by the actual data once it becomes available.)
            if date_of_first_entry != date_now:
                duolingo_xpsummary_json["summaries"].insert(0, dummy_data)
                print("Date of the most recent XP data: " + str(date_of_first_entry) + "   (Dummy data has been inserted for today.)")
            else:
                print("Date of the most recent XP data: " + str(date_of_first_entry) + "   (No dummy data needed for today.)")

            # Work out how many days of data is available (this should be 14 unless the user has only just joined Duolingo witin the last 14 days)
            days_returned = len(duolingo_xpsummary_json["summaries"])
            if days_returned >= 14:
                print("Days with data: " + str(days_returned))
            else:
                print("Days with data: " + str(days_returned) + "   (Query returned less than 14 days of data. New Duolingo user?)")

                # insert historical dummy data if less than 14 days of data exists
                days_of_dummy_data_to_add = 14 - days_returned
                for daynum in range(0, days_of_dummy_data_to_add):
                    duolingo_xpsummary_json["summaries"].append(dummy_data)
                print("Total days after inserting dummy data:  " + str(len(duolingo_xpsummary_json["summaries"])))

            # if the user only has 7 or less days of data available, and the two week chart view is selected, only display the one week view
            if days_returned <= 7 and display_view == "twoweeks":
                display_view = "week"

            # Now we get today's daily XP count from the xpsummary_query_json variable (which updates with live data every 15 mins)
            # We'll need this below, to calculate the total XP earned
            duolingo_xptoday = duolingo_xpsummary_json["summaries"][0]["gainedXp"]

            # If the current XP score is null convert to integer zero
            if str(duolingo_xptoday) == "null":
                duolingo_xptoday = 0
            else:
                duolingo_xptoday = int(duolingo_xptoday)

            # Get current streak status
            is_streak_extended = bool(duolingo_xpsummary_json["summaries"][0]["streakExtended"])

            # Put the XP scores for the week into a list called week_xp_scores. The first entry will be  days 13 ago. The last entry will be today.
            week_xp_scores = []
            for daynum in range(0, 14):
                day_xp = duolingo_xpsummary_json["summaries"][daynum]["gainedXp"]
                if day_xp == None:
                    day_xp = int(0)
                else:
                    day_xp = int(day_xp)
                week_xp_scores.append(day_xp)

            print("Two Week's XP Scores: " + str(week_xp_scores))

            # Slice the current week's xp scores, if we are only displaying the last week of data
            if display_view == "week":
                week_xp_scores = (week_xp_scores[0:7])
                print("One Week's XP Scores: " + str(week_xp_scores))

            # Add up the XP score from every day to get the one week or two week total
            week_xp_scores_total = 0
            if display_view == "week" or display_view == "today":
                # Add up total xp score for the last week
                for i in range(0, 7):
                    week_xp_scores_total = week_xp_scores[i] + week_xp_scores_total
            if display_view == "twoweeks":
                # Add up total xp score for the last week
                for i in range(0, 14):
                    week_xp_scores_total = week_xp_scores[i] + week_xp_scores_total

            # If no XP score has been acheived in the last week then set the variable to hide the Duolingo app from displaying in the rotation
            # (if the twoweek view is being displayed, the XP score limit is two weeks before it is hidden from view)
            if week_xp_scores_total == 0:
                hide_duolingo_in_rotation = True
                if display_view == "twoweeks":
                    print("IMPORTANT: No Duolingo lessons have been completed in the last 14 days - Tidbyt display will be hidden.")
                else:
                    print("IMPORTANT: No Duolingo lessons have been completed in the last 7 days - Tidbyt display will be hidden.")
            else:
                hide_duolingo_in_rotation = False

            # LOOKUP DUOLINGO MAIN JSON DATA AT START OF DAY
            # The is run daily to calculate what the user's totalXP was at the start of the day
            # It runs whenever it detects that the date has changed from the previous time it was run
            # It also requires live XP data to be available (rather than cached data)

            # Run this if today's date has changed and live data has just been retried (or this is the first time running)
            if (duolingo_saveddate_cached != date_now) and (live_xp_data == True):
                print("New day detected!")

                # First we are going to get the totalXp score at the start of the day
                # (we will use this to calculate the running XP total throughout the day)
                if do_duolingo_main_query == True:
                    duolingo_totalxp = int(duolingo_main_json["users"][0]["totalXp"])
                    duolingo_streak = int(duolingo_main_json["users"][0]["streak"])
                else:
                    # Setup userid query URL
                    print("Querying duolingo.com for current totalXp...")
                    duolingo_main_query = http.get(duolingo_main_query_url)
                    if duolingo_main_query.status_code != 200:
                        print("Duolingo query failed with status %d", duolingo_main_query.status_code)
                        display_error_msg = True
                    else:
                        duolingo_main_json = duolingo_main_query.json()
                        duolingo_totalxp = int(duolingo_main_json["users"][0]["totalXp"])

                        # Show error if totalxp was not found
                        if duolingo_totalxp == "":
                            print("totalXp query failed with status %d", duolingo_main_query.status_code)
                            display_error_msg = True
                            error_message_1 = "totalXp"
                            error_message_2 = "not found"
                        else:
                            display_error_msg = False
                            print("Queried totalXp for username \"" + str(duolingo_username) + "\": " + str(duolingo_totalxp))

                        #                       cache.set(duolingo_cache_key_totalxp, str(duolingo_totalxp), ttl_seconds=86400)

                        # Get current streak
                        duolingo_streak = int(duolingo_main_json["users"][0]["streak"])

                        # Show error if totalxp was not found
                        if duolingo_streak == "":
                            print("Streak query failed with status %d", duolingo_main_query.status_code)
                            display_error_msg = True
                            error_message_1 = "streak"
                            error_message_2 = "not found"
                        else:
                            display_error_msg = False
                            print("Queried Streak for username \"" + str(duolingo_username) + "\": " + str(duolingo_totalxp))

                #                      cache.set(duolingo_cache_key_totalxp, str(duolingo_totalxp), ttl_seconds=86400)

                # Now we subtract the daily XP count from the total count to find out the XP count at the start of the day
                # (this is saved in the cache so we don't have to perform the main json query more than once per day - we can calculate the)
                # running live total by adding the XP at start of day to the current daily count from the XP Summary query.)
                duolingo_totalxp_daystart = int(duolingo_totalxp) - int(duolingo_xptoday)

                print("XP Count at Start of Day: " + str(duolingo_totalxp_daystart))

                # Store start-of-day XP count in cache (for 24hrs)
                cache.set(duolingo_cache_key_totalxp_daystart, str(duolingo_totalxp_daystart), ttl_seconds = 86400)

                # Now we cache the Streak at the start of the day, and store it in the cache
                if is_streak_extended == True:
                    duolingo_streak_daystart = int(duolingo_streak) - 1
                else:
                    duolingo_streak_daystart = int(duolingo_streak)

                print("Streak at Start of Day: " + str(duolingo_streak_daystart))

                # Store start-of-day XP count in cache (for 24hrs)
                cache.set(duolingo_cache_key_streak_daystart, str(duolingo_streak_daystart), ttl_seconds = 86400)

                # Finally update the cache with the new date so this won't run again until tomorrow (stored for 24 hours)
                cache.set(duolingo_cache_key_saveddate, str(date_now), ttl_seconds = 86400)

            # Set variables for current state
            if live_xp_data == True:
                print("---- CURRENT DATA: LIVE ----- ")
            elif live_xp_data == False:
                print("---- CURRENT DATA: CACHED ----- ")
            elif live_xp_data == None:
                print("---- CURRENT DATA: UNAVAILABLE ----- ")

            # Use cached value for Total XP at day start if live value is not available
            if duolingo_totalxp_daystart_cached != None:
                duolingo_totalxp_daystart = str(duolingo_totalxp_daystart_cached)

            # Calculate current total XP
            duolingo_totalxp_now = int(duolingo_totalxp_daystart) + int(duolingo_xptoday)
            print("Today's XP: " + str(duolingo_xptoday) + "  Total XP (at day start): " + str(duolingo_totalxp_daystart) + "   TOTAL XP: " + str(duolingo_totalxp_now))

            # Use cached value for Streak at day start if live value is not available
            if duolingo_streak_daystart_cached != None:
                duolingo_streak_daystart = str(duolingo_streak_daystart_cached)

            # Calculate current Streak, based on whther it has already been extended today
            if is_streak_extended == True:
                duolingo_streak_now = int(duolingo_streak_daystart) + 1
            else:
                duolingo_streak_now = int(duolingo_streak_daystart)

            print("Streak: " + str(duolingo_streak_now) + "   Streak Extended?: " + str(is_streak_extended))

            # Deduce what streak icon to display on Today view
            if is_streak_extended == False:
                streak_icon = STREAK_ICON_GREY
            elif is_streak_extended == True:
                streak_icon = STREAK_ICON_GOLD_ANIMATED

            # Deduce what XP icon to display on Today view
            if int(duolingo_xptoday) == 0:
                XP_ICON = XP_ICON_GREY
            else:
                XP_ICON = XP_ICON_GOLD

            # OWL PICKER !!

            # Calculate percentage achieved of progress bar
            xp_target = int(xp_target)
            if xp_target != 0:
                progressbar_perc = (int(duolingo_xptoday) / int(xp_target)) * 100
            else:
                progressbar_perc = 0
                print("Note: No daily XP target is selected.")

            # Decide which Duolingo icon should be displayed right now
            if int(duolingo_xptoday) == 0 and hour_now >= 20:
                DUOLINGO_ICON = DUOLINGO_ICON_CRY
                print("Owl: Crying")
            elif int(duolingo_xptoday) == 0 and hour_now >= 14 and display_view == "today":
                DUOLINGO_ICON = DUOLINGO_ICON_ANGRY
                print("Owl: Angry")
            elif int(duolingo_xptoday) == 0 and hour_now >= 10 and display_view == "today":
                DUOLINGO_ICON = DUOLINGO_ICON_STANDING_POINT_LEFT
                print("Owl: Pointing Left")
            elif int(duolingo_xptoday) == 0:
                DUOLINGO_ICON = DUOLINGO_ICON_SLEEPING
            elif int(progressbar_perc) > 0 and int(progressbar_perc) < 35 and int(xp_target) != 0 and display_view == "today":
                DUOLINGO_ICON = DUOLINGO_ICON_STANDING_POINT_LEFT
                print("Owl: Pointing Left")
            elif int(progressbar_perc) >= 35 and int(progressbar_perc) <= 60 and int(xp_target) != 0 and display_view == "today":
                DUOLINGO_ICON = DUOLINGO_ICON_STANDING_POINT_DOWN
                print("Owl: Pointing Down")
            elif int(progressbar_perc) > 60 and int(progressbar_perc) <= 80 and int(xp_target) != 0 and display_view == "today":
                DUOLINGO_ICON = DUOLINGO_ICON_STANDING_POINT_RIGHT
                print("Owl: Pointing Right")
            elif int(progressbar_perc) > 80 and int(progressbar_perc) < 100 and int(xp_target) != 0 and display_view == "today":
                DUOLINGO_ICON = DUOLINGO_ICON_STANDING_POINT_RIGHT_FLAP
                print("Owl: Pointing Right + Flap")
            elif int(duolingo_xptoday) >= (2 * int(xp_target)) and int(xp_target) != 0 and display_view == "today":
                DUOLINGO_ICON = DUOLINGO_ICON_DANCING
                print("Owl: Dancing")
            elif int(progressbar_perc) >= 100 and int(xp_target) != 0 and display_view == "today":
                DUOLINGO_ICON = DUOLINGO_ICON_FLY
                print("Owl: Flying")
            else:
                print("Error: Could not select specific Duolingo icon, so reverting to the default standing icon.")
                DUOLINGO_ICON = DUOLINGO_ICON_STANDING

            # OWL TESTING !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            #        DUOLINGO_ICON = DUOLINGO_ICON_DANCING

            # Setup nickname display, if needed
            if nickname != "":
                nickname_today_view = render.Column(
                    main_align = "space_between",
                    cross_align = "space_between",
                    expanded = False,
                    children = [
                        render.Row(
                            main_align = "space_between",
                            cross_align = "space_between",
                            expanded = False,
                            children = [
                                render.Text(str(nickname), font = "tom-thumb"),
                            ],
                        ),
                    ],
                )

            else:
                nickname_today_view = None

    # DISPLAY ERROR MESSAGES
    # If the data queries failed in any way, then show an error on the Tidbyt

    if display_error_msg == True:
        print("Displaying Error message on Tidbyt...")

        display_output = render.Box(
            render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "space_evenly",
                children = [
                    render.Image(src = DUOLINGO_ICON_CRY),

                    # Column to hold pricing text evenly distrubuted accross 1-3 rows
                    render.Column(
                        main_align = "space_evenly",
                        expanded = False,
                        children = [
                            render.Text("ERROR:", font = "CG-pixel-3x5-mono", color = "#FF0000"),
                            render.Box(width = 1, height = 1, color = "#000000"),
                            render.Text("%s" % error_message_1, font = "tom-thumb"),
                            render.Text("%s" % error_message_2, font = "tom-thumb"),
                        ],
                    ),
                ],
            ),
        )

    # DISPLAY TODAY VIEW
    # Setup dtoay view layout

    if display_error_msg == False and display_view == "today" and hide_duolingo_in_rotation == False:
        print("Displaying Day View on Tidbyt...")

        # Setup progress bar. Don't display if XP target in Schema is set to None.
        if xp_target == 0:
            progressbar = None
            multiplier_text = None
        else:
            # Setup progress bar dimensions
            progressbar_total_length = 25
            progressbar_total_height = 3

            # Choose completed animated progress bar color
            if int(duolingo_xptoday) >= int(xp_target):
                if int(duolingo_xptoday) >= (5 * int(xp_target)):
                    progressbar_col = "#28ff00"  # lime green
                    high_multiplier = int(duolingo_xptoday) / int(int(xp_target))
                    multiplier_text = str(int(high_multiplier)) + "x"
                    PROGRESSBAR_ANI = PROGRESSBAR_DARKBLUE_ARROWS
                elif int(duolingo_xptoday) >= (4 * int(xp_target)):
                    progressbar_col = "#ff5800"  # burnt orange
                    PROGRESSBAR_ANI = PROGRESSBAR_ORANGE_ARROWS
                    multiplier_text = "4x"
                elif int(duolingo_xptoday) >= (3 * int(xp_target)):
                    progressbar_col = "#00ffd7"  # turquoise
                    PROGRESSBAR_ANI = PROGRESSBAR_TURQUOISE_ARROWS
                    multiplier_text = "3x"
                elif int(duolingo_xptoday) >= (2 * int(xp_target)):
                    progressbar_col = "#d700ff"  # purple
                    PROGRESSBAR_ANI = PROGRESSBAR_PURPLE_ARROWS
                    multiplier_text = "2x"
                else:
                    progressbar_col = "#ffd700"  # gold
                    PROGRESSBAR_ANI = PROGRESSBAR_GOLD_ARROWS
                    multiplier_text = None
            else:
                progressbar_col = "#808080"
                multiplier_text = None

            #   Second, work out the current length the progress bar should be
            progressbar_current_length = int((progressbar_total_length / 100) * progressbar_perc)

            if progressbar_current_length < progressbar_total_length:
                fadeList = []  # This sets up the fading progress indicator

                for frame in range(28):
                    #Setup progress indicator fader colors - fades from black to grey and back again
                    if frame == 0 or frame == 1:
                        fading_indicator_col = "#000000"  # Black
                    elif frame == 2:
                        fading_indicator_col = "#0d0d0d"  # Step 1
                    elif frame == 3:
                        fading_indicator_col = "#1a1a1a"  # Step 2
                    elif frame == 4:
                        fading_indicator_col = "#272727"  # Step 3
                    elif frame == 5:
                        fading_indicator_col = "#333333"  # Step 4
                    elif frame == 6:
                        fading_indicator_col = "#404040"  # Step 5
                    elif frame == 7:
                        fading_indicator_col = "#4c4c4c"  # Step 6
                    elif frame == 8:
                        fading_indicator_col = "#595959"  # Step 7
                    elif frame == 9:
                        fading_indicator_col = "#666666"  # Step 8
                    elif frame == 10:
                        fading_indicator_col = "#737373"  # Step 9
                    elif frame >= 11 and frame <= 14:
                        fading_indicator_col = "#808080"  # Progress Bar Grey
                    elif frame == 15:
                        fading_indicator_col = "#737373"  # Step 9
                    elif frame == 16:
                        fading_indicator_col = "#666666"  # Step 8
                    elif frame == 17:
                        fading_indicator_col = "#595959"  # Step 7
                    elif frame == 18:
                        fading_indicator_col = "#4c4c4c"  # Step 6
                    elif frame == 19:
                        fading_indicator_col = "#404040"  # Step 5
                    elif frame == 20:
                        fading_indicator_col = "#333333"  # Step 4
                    elif frame == 21:
                        fading_indicator_col = "#272727"  # Step 3
                    elif frame == 22:
                        fading_indicator_col = "#1a1a1a"  # Step 2
                    elif frame == 23:
                        fading_indicator_col = "#0d0d0d"  # Step 1
                    else:
                        fading_indicator_col = "#000000"  # Black

                    if progressbar_current_length > 0:
                        display_progressbar_length = render.Box(
                            width = progressbar_current_length,
                            height = 3,
                            color = progressbar_col,
                        )
                    else:
                        display_progressbar_length = None

                    # Setup fading indicator for progress bar
                    progressbar_frame = render.Row(
                        main_align = "start",
                        cross_align = "center",  # Controls vertical alignment
                        expanded = False,
                        children = [
                            render.Box(
                                width = (progressbar_total_length + 2),
                                height = (progressbar_total_height + 2),
                                color = "#e1e0e0",
                                child = render.Box(
                                    width = progressbar_total_length,
                                    height = progressbar_total_height,
                                    color = "#000000",
                                    child = render.Padding(
                                        child = render.Row(
                                            main_align = "start",
                                            cross_align = "start",  # Controls vertical alignment
                                            expanded = True,
                                            children = [
                                                display_progressbar_length,
                                                render.Box(
                                                    width = 1,
                                                    height = 3,
                                                    color = fading_indicator_col,
                                                ),
                                            ],
                                        ),
                                        pad = (0, 0, (progressbar_total_length - 1 - progressbar_current_length), 0),
                                    ),
                                ),
                            ),
                        ],
                    )

                    fadeList.append(progressbar_frame)

                progressbar = render.Animation(
                    children = (
                        fadeList
                    ),
                )

            else:
                # Display the completed progress bar animation
                progressbar = render.Row(
                    main_align = "space_evenly",
                    cross_align = "center",  # Controls vertical alignment
                    expanded = False,
                    children = [
                        render.Box(
                            width = (progressbar_total_length + 2),
                            height = (progressbar_total_height + 2),
                            color = "#e1e0e0",
                            child = render.Image(src = PROGRESSBAR_ANI),
                        ),
                    ],
                )

        # Display multiplier text if needed!
        if multiplier_text != None:
            display_multiplier_spacer = render.Box(width = 1, height = 1, color = "#000000")
            display_multiplier_text = render.Text(str(multiplier_text), color = progressbar_col, font = "tom-thumb")
        else:
            display_multiplier_spacer = None
            display_multiplier_text = None

        display_output = render.Box(
            render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    render.Column(
                        main_align = "space_evenly",
                        cross_align = "left",
                        expanded = True,
                        children = [
                            nickname_today_view,
                            render.Row(
                                main_align = "space_evenly",
                                cross_align = "end",  # Controls vertical alignment
                                expanded = False,
                                children = [
                                    render.Image(src = streak_icon),
                                    render.Box(
                                        # spacer column
                                        width = 2,
                                        height = 2,
                                        color = "#000000",
                                    ),
                                    render.Text(str(duolingo_streak_now), font = "tom-thumb"),
                                ],
                            ),
                            render.Row(
                                main_align = "space_evenly",
                                cross_align = "end",  # Controls vertical alignment
                                expanded = False,
                                children = [
                                    render.Image(src = XP_ICON),
                                    render.Box(
                                        # spacer column
                                        width = 1,
                                        height = 2,
                                        color = "#000000",
                                    ),
                                    render.Text(str(duolingo_xptoday) + "xp", font = "tom-thumb"),
                                ],
                            ),
                        ],
                    ),

                    # Column to hold pricing text evenly distrubuted accross 1-3 rows
                    render.Column(
                        main_align = "center",
                        cross_align = "center",  # Controls vertical alignment
                        expanded = True,
                        children = [
                            render.Row(
                                main_align = "space_evenly",
                                cross_align = "end",  # Controls vertical alignment
                                expanded = False,
                                children = [
                                    render.Image(src = DUOLINGO_ICON),
                                ],
                            ),
                            progressbar,
                            display_multiplier_spacer,
                            display_multiplier_text,
                        ],
                    ),
                ],
            ),
        )

    # DISPLAY WEEK VIEW (OR TWO WEEK VIEW)
    # Setup week view layout

    if display_error_msg == False and hide_duolingo_in_rotation == False and (display_view == "week" or display_view == "twoweeks"):
        print("Displaying Week View on Tidbyt...")

        # Setup verticle bar dimensions
        vertbar_total_width = 5

        print("Display Extra Stats: " + str(display_extra_stats))

        if display_extra_stats != "None":
            vertbar_total_height = 17
        else:
            vertbar_total_height = 24

        # Get the highest value from the available daily scores. This is used to setup the upper_chart_value.
        week_xp_scores_sorted = sorted(week_xp_scores)
        week_xp_highest = int(week_xp_scores_sorted[-1])

        print("Week's Highest XP Score: " + str(week_xp_highest))

        # Set the upper chart value, based on the highest daily score from the last week
        xp_target = int(xp_target)
        if week_xp_highest <= xp_target and xp_target > 0:
            upper_chart_value = xp_target  # Set upper chart height to the xp_target if none if the last weeks scores have exceeded it
        elif week_xp_highest > xp_target:
            upper_chart_value = week_xp_highest  # Otherwise set the upper_chart_value to be the highest daily xp score from the last two weeks

        week_progress_chart = []
        vertbar_col = []

        # Setup chart display for the past week. Cycles though each day working backwards towards today.
        for daynum in range(6, -1, -1):
            xp_day_score = duolingo_xpsummary_json["summaries"][daynum]["gainedXp"]

            # Set this day's XP score to 0 if it is Null
            if xp_day_score == None:
                xp_day_score = 0

            # Setup vertbar display variables for this day
            if xp_day_score > 0:
                display_frozen_thisweek = False
                display_missed_thisweek = False
                display_repaired_thisweek = False
            else:
                is_frozen_thisweek = bool(duolingo_xpsummary_json["summaries"][daynum]["frozen"])
                is_repaired_thisweek = bool(duolingo_xpsummary_json["summaries"][daynum]["repaired"])
                is_streak_extended_thisweek = bool(duolingo_xpsummary_json["summaries"][daynum]["streakExtended"])
                if daynum != 0 and is_frozen_thisweek == True:
                    display_frozen_thisweek = True
                    display_missed_thisweek = False
                    display_repaired_thisweek = False
                elif daynum != 0 and is_frozen_thisweek == False and is_streak_extended_thisweek == False and is_repaired_thisweek == False:
                    display_frozen_thisweek = False
                    display_missed_thisweek = True
                    display_repaired_thisweek = False
                elif daynum != 0 and is_frozen_thisweek == False and is_streak_extended_thisweek == False and is_repaired_thisweek == True:
                    display_frozen_thisweek = False
                    display_missed_thisweek = False
                    display_repaired_thisweek = True

            # Display different shade of color bar if the XP score was not hit
            if int(xp_day_score) >= int(xp_target):
                vertbar_col = "#feea3a"
                vertbar_col_header = "#ea3afe"
            else:
                vertbar_col = "#9e9e9e"
                vertbar_col_header = "#e1e0e0"

            vertbar_thisweek_col_frozen = "#71d2ff"
            vertbar_thisweek_col_missed = "#ff0000"
            vertbar_thisweek_col_repaired = "#787878"

            if display_view == "twoweeks":
                xp_day_score_lastweek = duolingo_xpsummary_json["summaries"][daynum + 7]["gainedXp"]

                # Setup this day last week's XP score to 0 if it is Null
                if xp_day_score_lastweek == None:
                    xp_day_score_lastweek = 0

                # Setup vertbar display variables for this day last week
                if xp_day_score_lastweek > 0:
                    display_frozen_lastweek = False
                    display_missed_lastweek = False
                    display_repaired_lastweek = False
                else:
                    is_frozen_lastweek = bool(duolingo_xpsummary_json["summaries"][daynum + 7]["frozen"])
                    is_repaired_lastweek = bool(duolingo_xpsummary_json["summaries"][daynum + 7]["repaired"])
                    is_streak_extended_lastweek = bool(duolingo_xpsummary_json["summaries"][daynum + 7]["streakExtended"])
                    if daynum != 0 and is_frozen_lastweek == True:
                        display_frozen_lastweek = True
                        display_missed_lastweek = False
                        display_repaired_lastweek = False
                    elif daynum != 0 and is_frozen_lastweek == False and is_streak_extended_lastweek == False and is_repaired_lastweek == False:
                        display_frozen_lastweek = False
                        display_missed_lastweek = True
                        display_repaired_lastweek = False
                    elif daynum != 0 and is_frozen_lastweek == False and is_streak_extended_lastweek == False and is_repaired_lastweek == True:
                        display_frozen_lastweek = False
                        display_missed_lastweek = False
                        display_repaired_lastweek = True

                # Work out the diferent shades of color bar if the XP score was not hit
                #               if int(xp_day_score_lastweek) >= int(xp_target):
                #                   vertbar_lastweek_col = "#9e8e01"
                #                   vertbar_lastweek_col_header = "#770185"
                #               else:
                vertbar_lastweek_col = "#3a3a3a"
                vertbar_lastweek_col_header = "#616161"

                vertbar_lastweek_col_frozen = "#0093d8"
                vertbar_lastweek_col_missed = "#b30000"
                vertbar_lastweek_col_repaired = "#212121"

            # Calculate this week vertical bar height
            # First, work out percentage progress towards the upper_chart_value
            vertbar_current_perc = (int(xp_day_score) / int(upper_chart_value)) * 100

            # Second, work out the current height the vertical bar should be
            vertbar_current_height = int((vertbar_total_height / 100) * vertbar_current_perc)

            # Ensure the bar has at least one pixel height if a lesson has been completed (to prevent it showing as zero when other lessons have very high scores)
            if vertbar_current_height == 0 and int(xp_day_score) > 0:
                vertbar_current_height = 1

            # Calculate last weeks vertical bar length, if it is being displayed
            if display_view == "twoweeks":
                # First, work out percentage progress towards the upper_chart_value
                vertbar_lastweek_perc = (int(xp_day_score_lastweek) / int(upper_chart_value)) * 100

                # Second, work out the current height the vertical bar should be
                vertbar_lastweek_height = int((vertbar_total_height / 100) * vertbar_lastweek_perc)

                # Ensure the bar has at least one pixel height if a lesson has been completed (to prevent it showing as zero when other lessons have very high scores)
                if vertbar_lastweek_height == 0 and int(xp_day_score) > 0:
                    vertbar_lastweek_height = 1

            else:
                vertbar_lastweek_height = 0

            # Display normal one week proress bar
            oneweek_bar_normal = [

                # This week full size  bar
                render.Box(
                    width = vertbar_total_width,
                    height = vertbar_total_height,
                    color = "#000000",
                    child = render.Padding(
                        child = render.Box(
                            width = 5,
                            height = vertbar_current_height,
                            color = str(vertbar_col),
                            child = render.Padding(
                                child = render.Box(
                                    width = 5,
                                    height = 1,
                                    color = str(vertbar_col_header),
                                ),
                                pad = (0, 0, 0, vertbar_current_height - 1),
                            ),
                        ),
                        pad = (0, (vertbar_total_height - vertbar_current_height), 0, 0),
                    ),
                ),

                # Spacer bar
                render.Box(
                    # spacer column
                    width = 1,
                    height = (vertbar_total_height),
                    color = "#000000",
                ),
            ]

            # Setup normal one week progress bar, with animated indicator for today
            if daynum == 0:
                fadeList = []  # This sets up the fading progress indicator

                # If today's progress is at zero, set it to 1 so that the fading indicator displays
                if vertbar_current_height == 0:
                    vertbar_current_height = 1

                # If the daily XP target has been hit then we are using the gold/purple bars so setup the appropriate progress indicator fade
                if int(xp_day_score) >= int(xp_target):
                    # fades from black to purple
                    for frame in range(30):
                        if frame == 0 or frame == 1:
                            vertbar_col_header = "#000000"  # Black
                        elif frame == 2:
                            vertbar_col_header = "#140515"  # Step 1
                        elif frame == 3:
                            vertbar_col_header = "#270a2a"  # Step 2
                        elif frame == 4:
                            vertbar_col_header = "#3b0e3f"  # Step 3
                        elif frame == 5:
                            vertbar_col_header = "#4e1355"  # Step 4
                        elif frame == 6:
                            vertbar_col_header = "#61186a"  # Step 5
                        elif frame == 7:
                            vertbar_col_header = "#751d7f"  # Step 6
                        elif frame == 8:
                            vertbar_col_header = "#882294"  # Step 7
                        elif frame == 9:
                            vertbar_col_header = "#9c27a9"  # Step 8
                        elif frame == 10:
                            vertbar_col_header = "#b02bbe"  # Step 9
                        elif frame == 11:
                            vertbar_col_header = "#c330d4"  # Step 10
                        elif frame == 12:
                            vertbar_col_header = "#d735e9"  # Step 11
                        elif frame >= 13 and frame <= 16:
                            vertbar_col_header = "#ea3afe"  # Progress Bar Purple
                        elif frame == 17:
                            vertbar_col_header = "#d735e9"  # Step 11
                        elif frame == 18:
                            vertbar_col_header = "#c330d4"  # Step 10
                        elif frame == 19:
                            vertbar_col_header = "#b02bbe"  # Step 9
                        elif frame == 20:
                            vertbar_col_header = "#9c27a9"  # Step 8
                        elif frame == 21:
                            vertbar_col_header = "#882294"  # Step 7
                        elif frame == 22:
                            vertbar_col_header = "#751d7f"  # Step 6
                        elif frame == 23:
                            vertbar_col_header = "#61186a"  # Step 5
                        elif frame == 24:
                            vertbar_col_header = "#4e1355"  # Step 4
                        elif frame == 25:
                            vertbar_col_header = "#3b0e3f"  # Step 3
                        elif frame == 26:
                            vertbar_col_header = "#270a2a"  # Step 2
                        elif frame == 27:
                            vertbar_col_header = "#140515"  # Step 1
                        elif frame >= 28:
                            vertbar_col_header = "#000000"  # Black

                        if display_view == "week":
                            oneweek_bar_today_frame = render.Box(
                                width = vertbar_total_width,
                                height = vertbar_total_height,
                                color = "#000000",
                                child = render.Padding(
                                    child = render.Box(
                                        width = 5,
                                        height = vertbar_current_height,
                                        color = str(vertbar_col),
                                        child = render.Padding(
                                            child = render.Box(
                                                width = 5,
                                                height = 1,
                                                color = str(vertbar_col_header),
                                            ),
                                            pad = (0, 0, 0, vertbar_current_height - 1),
                                        ),
                                    ),
                                    pad = (0, (vertbar_total_height - vertbar_current_height), 0, 0),
                                ),
                            )

                            fadeList.append(oneweek_bar_today_frame)

                        if display_view == "twoweeks":
                            twoweeks_bar_today_frame = render.Box(
                                width = 3,
                                height = (vertbar_total_height),
                                color = "#e1e0e0",
                                child = render.Box(
                                    width = 3,
                                    height = vertbar_total_height,
                                    color = "#000000",
                                    child = render.Padding(
                                        child = render.Box(
                                            width = 3,
                                            height = vertbar_current_height,
                                            color = str(vertbar_col),
                                            child = render.Padding(
                                                child = render.Box(
                                                    width = 3,
                                                    height = 1,
                                                    color = str(vertbar_col_header),
                                                ),
                                                pad = (0, 0, 0, vertbar_current_height - 1),
                                            ),
                                        ),
                                        pad = (0, (vertbar_total_height - vertbar_current_height), 0, 0),
                                    ),
                                ),
                            )

                            fadeList.append(twoweeks_bar_today_frame)

                    # If the daily XP target has NOT been hit then we are using the grey bars so setup the appropriate progress indicator fade
                else:
                    # fades from black to light grey
                    for frame in range(30):
                        if frame == 0 or frame == 1:
                            vertbar_col_header = "#000000"  # Black
                        elif frame == 2:
                            vertbar_col_header = "#131313"  # Step 1
                        elif frame == 3:
                            vertbar_col_header = "#252525"  # Step 2
                        elif frame == 4:
                            vertbar_col_header = "#383838"  # Step 3
                        elif frame == 5:
                            vertbar_col_header = "#4b4b4b"  # Step 4
                        elif frame == 6:
                            vertbar_col_header = "#5e5d5d"  # Step 5
                        elif frame == 7:
                            vertbar_col_header = "#717070"  # Step 6
                        elif frame == 8:
                            vertbar_col_header = "#838383"  # Step 7
                        elif frame == 9:
                            vertbar_col_header = "#969595"  # Step 8
                        elif frame == 10:
                            vertbar_col_header = "#a9a8a8"  # Step 9
                        elif frame == 11:
                            vertbar_col_header = "#bbbbbb"  # Step 10
                        elif frame == 12:
                            vertbar_col_header = "#cecdcd"  # Step 11
                        elif frame >= 13 and frame <= 16:
                            vertbar_col_header = "#e1e0e0"  # Progress Bar Light Grey
                        elif frame == 17:
                            vertbar_col_header = "#cecdcd"  # Step 11
                        elif frame == 18:
                            vertbar_col_header = "#bbbbbb"  # Step 10
                        elif frame == 19:
                            vertbar_col_header = "#a9a8a8"  # Step 9
                        elif frame == 20:
                            vertbar_col_header = "#969595"  # Step 8
                        elif frame == 21:
                            vertbar_col_header = "#838383"  # Step 7
                        elif frame == 22:
                            vertbar_col_header = "#717070"  # Step 6
                        elif frame == 23:
                            vertbar_col_header = "#5e5d5d"  # Step 5
                        elif frame == 24:
                            vertbar_col_header = "#4b4b4b"  # Step 4
                        elif frame == 25:
                            vertbar_col_header = "#383838"  # Step 3
                        elif frame == 26:
                            vertbar_col_header = "#252525"  # Step 2
                        elif frame == 27:
                            vertbar_col_header = "#131313"  # Step 1
                        elif frame >= 28:
                            vertbar_col_header = "#000000"  # Black

                        if display_view == "week":
                            oneweek_bar_today_frame = render.Box(
                                width = vertbar_total_width,
                                height = vertbar_total_height,
                                color = "#000000",
                                child = render.Padding(
                                    child = render.Box(
                                        width = 5,
                                        height = vertbar_current_height,
                                        color = str(vertbar_col),
                                        child = render.Padding(
                                            child = render.Box(
                                                width = 5,
                                                height = 1,
                                                color = str(vertbar_col_header),
                                            ),
                                            pad = (0, 0, 0, vertbar_current_height - 1),
                                        ),
                                    ),
                                    pad = (0, (vertbar_total_height - vertbar_current_height), 0, 0),
                                ),
                            )

                            fadeList.append(oneweek_bar_today_frame)

                        if display_view == "twoweeks":
                            twoweeks_bar_today_frame = render.Box(
                                width = 3,
                                height = (vertbar_total_height),
                                color = "#e1e0e0",
                                child = render.Box(
                                    width = 3,
                                    height = vertbar_total_height,
                                    color = "#000000",
                                    child = render.Padding(
                                        child = render.Box(
                                            width = 3,
                                            height = vertbar_current_height,
                                            color = str(vertbar_col),
                                            child = render.Padding(
                                                child = render.Box(
                                                    width = 3,
                                                    height = 1,
                                                    color = str(vertbar_col_header),
                                                ),
                                                pad = (0, 0, 0, vertbar_current_height - 1),
                                            ),
                                        ),
                                        pad = (0, (vertbar_total_height - vertbar_current_height), 0, 0),
                                    ),
                                ),
                            )

                            fadeList.append(twoweeks_bar_today_frame)

                if display_view == "week":
                    oneweek_todays_bar = render.Animation(
                        children = (
                            fadeList
                        ),
                    )

                if display_view == "twoweeks":
                    twoweek_todays_bar = render.Animation(
                        children = (
                            fadeList
                        ),
                    )

            else:
                oneweek_todays_bar = render.Box(
                    width = vertbar_total_width,
                    height = vertbar_total_height,
                    color = "#000000",
                    child = render.Padding(
                        child = render.Box(
                            width = 5,
                            height = vertbar_current_height,
                            color = str(vertbar_col),
                            child = render.Padding(
                                child = render.Box(
                                    width = 5,
                                    height = 1,
                                    color = str(vertbar_col_header),
                                ),
                                pad = (0, 0, 0, vertbar_current_height - 1),
                            ),
                        ),
                        pad = (0, (vertbar_total_height - vertbar_current_height), 0, 0),
                    ),
                )

                # Set up two weeks today bars
                if display_view == "twoweeks":
                    twoweek_todays_bar = render.Box(
                        width = 3,
                        height = (vertbar_total_height),
                        color = "#e1e0e0",
                        child = render.Box(
                            width = 3,
                            height = vertbar_total_height,
                            color = "#000000",
                            child = render.Padding(
                                child = render.Box(
                                    width = 3,
                                    height = vertbar_current_height,
                                    color = str(vertbar_col),
                                    child = render.Padding(
                                        child = render.Box(
                                            width = 3,
                                            height = 1,
                                            color = str(vertbar_col_header),
                                        ),
                                        pad = (0, 0, 0, vertbar_current_height - 1),
                                    ),
                                ),
                                pad = (0, (vertbar_total_height - vertbar_current_height), 0, 0),
                            ),
                        ),
                    )

            # Display normal one week proress bar
            oneweek_bar_normal = [

                # This week full size  bar
                oneweek_todays_bar,

                # Spacer bar
                render.Box(
                    # spacer column
                    width = 1,
                    height = (vertbar_total_height),
                    color = "#000000",
                ),
            ]

            oneweek_bar_missed = [

                # This week full size  bar
                render.Box(
                    width = vertbar_total_width,
                    height = vertbar_total_height,
                    color = "#000000",
                    child = render.Padding(
                        child = render.Box(
                            width = 5,
                            height = 5,
                            color = "#000000",
                            child = render.Text("x", color = "#ff0000"),
                        ),
                        pad = (0, (vertbar_total_height - 6), 0, 0),
                    ),
                ),

                # Spacer bar
                render.Box(
                    # spacer column
                    width = 1,
                    height = (vertbar_total_height),
                    color = "#000000",
                ),
            ]

            oneweek_bar_frozen = [

                # This week full size  bar
                render.Box(
                    width = vertbar_total_width,
                    height = vertbar_total_height,
                    color = "#000000",
                    child = render.Padding(
                        child = render.Box(
                            width = 5,
                            height = 7,
                            color = "#000000",
                            child = render.Image(src = STREAK_ICON_FROZEN),
                        ),
                        pad = (0, (vertbar_total_height - 7), 0, 0),
                    ),
                ),

                # Spacer bar
                render.Box(
                    # spacer column
                    width = 1,
                    height = (vertbar_total_height),
                    color = "#000000",
                ),
            ]

            # Display normal one week proress bar
            oneweek_bar_repaired = [

                # This week full size  bar
                render.Box(
                    width = vertbar_total_width,
                    height = vertbar_total_height,
                    color = "#000000",
                    child = render.Padding(
                        child = render.Box(
                            width = 5,
                            height = 1,
                            color = str(vertbar_thisweek_col_repaired),
                        ),
                        pad = (0, (vertbar_total_height - 1), 0, 0),
                    ),
                ),

                # Spacer bar
                render.Box(
                    # spacer column
                    width = 1,
                    height = (vertbar_total_height),
                    color = "#000000",
                ),
            ]

            # Set up two weeks today bars
            if display_view == "twoweeks":
                twoweeks_bar_thisweek_normal = twoweek_todays_bar

                twoweeks_bar_lastweek_normal = render.Box(
                    width = 2,
                    height = (vertbar_total_height),
                    color = "#e1e0e0",
                    child = render.Box(
                        width = 2,
                        height = vertbar_total_height,
                        color = "#000000",
                        child = render.Padding(
                            child = render.Box(
                                width = 2,
                                height = vertbar_lastweek_height,
                                color = str(vertbar_lastweek_col),
                                child = render.Padding(
                                    child = render.Box(
                                        width = 2,
                                        height = 1,
                                        color = str(vertbar_lastweek_col_header),
                                    ),
                                    pad = (0, 0, 0, vertbar_lastweek_height - 1),
                                ),
                            ),
                            pad = (0, (vertbar_total_height - vertbar_lastweek_height), 0, 0),
                        ),
                    ),
                )

                # Display this week frozen on two week chart
                twoweeks_bar_thisweek_frozen = render.Box(
                    width = 3,
                    height = vertbar_total_height,
                    color = "#000000",
                    child = render.Padding(
                        child = render.Box(
                            width = 3,
                            height = 1,
                            color = vertbar_thisweek_col_frozen,
                        ),
                        pad = (0, (vertbar_total_height - 1), 0, 0),
                    ),
                )

                # Display last week frozen on two week chart
                twoweeks_bar_lastweek_frozen = render.Box(
                    width = 2,
                    height = vertbar_total_height,
                    color = "#000000",
                    child = render.Padding(
                        child = render.Box(
                            width = 2,
                            height = 1,
                            color = vertbar_lastweek_col_frozen,
                        ),
                        pad = (0, (vertbar_total_height - 1), 0, 0),
                    ),
                )

                # Display this week missed on two week chart
                twoweeks_bar_thisweek_missed = render.Box(
                    width = 3,
                    height = vertbar_total_height,
                    color = "#000000",
                    child = render.Padding(
                        child = render.Box(
                            width = 3,
                            height = 1,
                            color = vertbar_thisweek_col_missed,
                        ),
                        pad = (0, (vertbar_total_height - 1), 0, 0),
                    ),
                )

                # Display last week missed on two week chart
                twoweeks_bar_lastweek_missed = render.Box(
                    width = 2,
                    height = vertbar_total_height,
                    color = "#000000",
                    child = render.Padding(
                        child = render.Box(
                            width = 2,
                            height = 1,
                            color = vertbar_lastweek_col_missed,
                        ),
                        pad = (0, (vertbar_total_height - 1), 0, 0),
                    ),
                )

                # Display this week repaired on two week chart
                twoweeks_bar_thisweek_repaired = render.Box(
                    width = 3,
                    height = vertbar_total_height,
                    color = "#000000",
                    child = render.Padding(
                        child = render.Box(
                            width = 3,
                            height = 1,
                            color = vertbar_thisweek_col_repaired,
                        ),
                        pad = (0, (vertbar_total_height - 1), 0, 0),
                    ),
                )

                # Display last week repaired on two week chart
                twoweeks_bar_lastweek_repaired = render.Box(
                    width = 2,
                    height = vertbar_total_height,
                    color = "#000000",
                    child = render.Padding(
                        child = render.Box(
                            width = 2,
                            height = 1,
                            color = vertbar_lastweek_col_repaired,
                        ),
                        pad = (0, (vertbar_total_height - 1), 0, 0),
                    ),
                )

            # TESTING VARIABLES

            # Choose what to display - bar, frozen icon, missed, blank or flashing progress (used for today)
            if display_view == "week":
                if display_frozen_thisweek == True:
                    oneweek_bar = oneweek_bar_frozen  # display the frozen icon
                elif display_missed_thisweek == True:
                    oneweek_bar = oneweek_bar_missed  # display the missed day cross icon
                elif display_repaired_thisweek == True:
                    oneweek_bar = oneweek_bar_repaired  # display the band aid icon
                    #              elif daynum == 0 and xp_day_score == 0:
                    #                  oneweek_bar = oneweek_bar_today_flashing_start          # display the flashing progress indicator
                    #              elif daynum == 0 and xp_day_score > 0:
                    #                  oneweek_bar = oneweek_bar_today_flashing_progress       # display the flashing progress indicator
                    #              elif daynum != 0 and xp_day_score > 0:
                    #                  oneweek_bar = oneweek_bar_today_flashing_progress       # display the flashing progress indicator

                else:
                    oneweek_bar = oneweek_bar_normal  # display the normal progress indicator

            if display_view == "twoweeks":
                # last week
                if display_frozen_lastweek == True:
                    twoweeks_bar_lastweek = twoweeks_bar_lastweek_frozen  # display the frozen icon
                elif display_missed_lastweek == True:
                    twoweeks_bar_lastweek = twoweeks_bar_lastweek_missed  # display the missed day cross icon
                elif display_repaired_lastweek == True:
                    twoweeks_bar_lastweek = twoweeks_bar_lastweek_repaired  # display the band aid icon
                else:
                    twoweeks_bar_lastweek = twoweeks_bar_lastweek_normal  # display the normal progress indicator

                # this week
                if display_frozen_thisweek == True:
                    twoweeks_bar_thisweek = twoweeks_bar_thisweek_frozen  # display the frozen icon
                elif display_missed_thisweek == True:
                    twoweeks_bar_thisweek = twoweeks_bar_thisweek_missed  # display the missed day cross icon
                elif display_repaired_thisweek == True:
                    twoweeks_bar_thisweek = twoweeks_bar_thisweek_repaired  # display the band aid icon
                else:
                    twoweeks_bar_thisweek = twoweeks_bar_thisweek_normal  # display the normal progress indicator

                twoweeks_bar = [

                    # Last week narrow bar
                    twoweeks_bar_lastweek,

                    # This week wide bar
                    twoweeks_bar_thisweek,

                    # Spacer bar
                    render.Box(
                        # spacer column
                        width = 1,
                        height = (vertbar_total_height),
                        color = "#000000",
                    ),
                ]

            # Choose which display to show
            if display_view == "week":
                show_chartbar = oneweek_bar
            elif display_view == "twoweeks":
                show_chartbar = twoweeks_bar

            vertbar = render.Row(
                main_align = "space_evenly",
                cross_align = "center",  # Controls vertical alignment
                expanded = False,
                children = show_chartbar,
            )

            # Get day of week, based on when the xp summary data was last updated:
            if daynum == 0:  # TODAY
                dayofweek = xp_query_time
            elif daynum == 1:  # YESTERDAY
                dayofweek = xp_query_time - time.parse_duration("24h")
            elif daynum == 2:  # TWO DAYS AGO
                dayofweek = xp_query_time - time.parse_duration("48h")
            elif daynum == 3:  # THREE DAYS AGO
                dayofweek = xp_query_time - time.parse_duration("72h")
            elif daynum == 4:  # FOUR DAYS AGO
                dayofweek = xp_query_time - time.parse_duration("96h")
            elif daynum == 5:  # FIVE DAYS AGO
                dayofweek = xp_query_time - time.parse_duration("120h")
            elif daynum == 6:  # SIX DAYS AGO
                dayofweek = xp_query_time - time.parse_duration("144h")

            # Convert day of week to single lower case letter
            dayofweek_letter = dayofweek.format("Mon").lower()[0]

            if display_view == "week":
                print("Day of Week: " + str(dayofweek_letter) + "  XP Score: " + str(xp_day_score))
            elif display_view == "twoweeks":
                print("Day of Week: " + str(dayofweek_letter) + "  Last Week XP Score: " + str(xp_day_score_lastweek) + "   This Week XP Score: " + str(xp_day_score))

            day_progress_chart = render.Column(
                main_align = "end",
                cross_align = "center",  # Controls vertical alignment
                expanded = True,
                children = [
                    vertbar,
                    render.Row(
                        main_align = "space_evenly",
                        cross_align = "end",  # Controls vertical alignment
                        expanded = False,
                        children = [
                            render.Box(
                                width = 1,
                                height = 7,
                            ),
                            render.Text(str(dayofweek_letter), font = "tom-thumb"),
                            render.Box(
                                width = 1,
                                height = 7,
                            ),
                        ],
                    ),
                ],
            )

            week_progress_chart.append(day_progress_chart)

        if display_extra_stats != "none":
            # Choose which XP count to display
            if display_extra_stats == "todayxp":
                xp_score = str(duolingo_xptoday)
            if display_extra_stats == "chartxp":
                xp_score = str(week_xp_scores_total)
            if display_extra_stats == "totalxp":
                xp_score = str(duolingo_totalxp_now)

            display_stats_header = render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "end",
                children = [

                    # Display current Streak
                    render.Column(
                        main_align = "center",
                        cross_align = "center",  # Controls vertical alignment
                        expanded = False,
                        children = [
                            render.Row(
                                main_align = "space_evenly",
                                cross_align = "end",  # Controls vertical alignment
                                expanded = False,
                                children = [
                                    render.Image(src = streak_icon),
                                    render.Box(
                                        # spacer column
                                        width = 1,
                                        height = 1,
                                        color = "#000000",
                                    ),
                                    render.Text(str(duolingo_streak_now), font = "tom-thumb"),
                                ],
                            ),
                        ],
                    ),

                    # Display total XP
                    render.Column(
                        main_align = "end",
                        cross_align = "center",  # Controls vertical alignment
                        expanded = False,
                        children = [
                            render.Row(
                                main_align = "space_evenly",
                                cross_align = "end",  # Controls vertical alignment
                                expanded = False,
                                children = [
                                    render.Image(src = XP_ICON),
                                    render.Box(
                                        # spacer column
                                        width = 1,
                                        height = 1,
                                        color = "#000000",
                                    ),
                                    render.Text(str(xp_score), font = "tom-thumb"),
                                ],
                            ),
                        ],
                    ),
                ],
            )

        else:
            display_stats_header = None

        display_output = render.Box(
            render.Column(
                children = [
                    display_stats_header,
                    render.Row(
                        expanded = False,
                        main_align = "space_evenly",
                        cross_align = "center",
                        children = [

                            # Display Duolingo icon and username
                            render.Column(
                                main_align = "center",
                                cross_align = "center",  # Controls vertical alignment
                                expanded = True,
                                children = [
                                    render.Row(
                                        main_align = "space_evenly",
                                        cross_align = "space_evenly",  # Controls vertical alignment
                                        expanded = False,
                                        children = [
                                            render.Image(src = DUOLINGO_ICON),
                                        ],
                                    ),
                                    render.Box(
                                        width = 22,
                                        height = 1,
                                        color = "#000000",
                                    ),
                                    nickname_today_view,
                                ],
                            ),

                            # Display Progress Chart
                            render.Column(
                                main_align = "end",
                                cross_align = "center",  # Controls vertical alignment
                                expanded = True,
                                children = [

                                    # Display week progress chart
                                    render.Row(
                                        main_align = "end",
                                        cross_align = "end",
                                        expanded = True,
                                        children = week_progress_chart,
                                    ),
                                ],
                            ),
                        ],
                    ),
                ],
            ),
        )

    # Hide the applet in the rotation if there has been no lessons completed recently (e.g. in the last week)
    if hide_duolingo_in_rotation == True:
        print("--- APPLET HIDDEN FROM ROTATION ---")
        return []
    else:
        return render.Root(
            delay = 50,
            child = display_output,
        )
