"""
Applet: Wiki Feat. Image
Summary: Wikipedia's featured image
Description: Displays Wikipedia's featured image of the day.
Author: sch0lars
"""

load("http.star", "http")
load("render.star", "render")
load("time.star", "time")

CACHE_DURATION = 14400

def main():
    TODAY = time.now().format("2006/01/02")
    YESTERDAY = (time.now() - time.parse_duration("24h")).format("2006/01/02")
    image = ""
    error_message = None

    # Call the API for today's image
    json_dict_today = call_api(TODAY)

    if "error" in json_dict_today:
        error_message = json_dict_today["error"]
    else:
        # Check that the API response contains the image information
        if has_image_information(json_dict_today):
            image = retrieve_image(json_dict_today)
        else:
            # If today's image cannot be retrieved, try to retrieve yesterday's image instead
            json_dict_yesterday = call_api(YESTERDAY)
            if "error" in json_dict_yesterday:
                error_message = json_dict_yesterday["error"]
            else:
                # Check that the API response contains the image information
                if has_image_information(json_dict_yesterday):
                    image = retrieve_image(json_dict_yesterday)
                else:
                    error_message = "Featured image is currently unavailable"

    # If there's an error message, display it
    if error_message:
        return render.Root(
            child = render.Box(
                child = render.WrappedText(
                    content = error_message,
                    width = 64,
                    align = "center",
                    color = "#f66",
                ),
            ),
        )

    # Otherwise, display the image
    return render.Root(
        # Render the image to fit the Tidbyt's 64x32 resolution
        child = render.Image(
            src = image,
            width = 64,
            height = 32,
        ),
    )

def call_api(date):
    """
    Calls the API to retrieve the image information for the given `date`

    :param date: a string representation of a date in YYYY/MM/DD format
    :returns: a JSON dictionary containing information from the API response
    """
    api_url = "https://api.wikimedia.org/feed/v1/wikipedia/en/featured/%s" % date

    # Call the API and cache the results for 4 hours
    resp = http.get(api_url, ttl_seconds = CACHE_DURATION, headers = {"User-Agent": "TidbytApp/1.0"})

    # Ensure we get a 200 status response
    if resp.status_code != 200:
        return {"error": "Wikipedia API request failed with status %d" % resp.status_code}

    return resp.json()

def has_image_information(json_dict):
    """
    Checks for the image information within the API response's JSON dictionary

    :param json_dict: a JSON dictionary containing information from the API response
    :returns: a Boolean value denoting whether required keys are present within the JSON dictionary
    """
    return "image" in json_dict.keys() and "thumbnail" in json_dict["image"].keys()

def retrieve_image(json_dict):
    """
    Parses the image source information from the JSON dictionary and retrieves the image

    :param json_dict: a JSON dictionary containing information from the API response
    :returns: the raw image data
    """

    # Get the image URL from the response
    image_url = json_dict["image"]["thumbnail"]["source"]

    # Retrieve the actual image data from the source URL and cache the results for 4 hours
    image = http.get(image_url, ttl_seconds = CACHE_DURATION).body()

    return image
