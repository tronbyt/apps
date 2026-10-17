"""
Applet: PixelGreet
Summary: Customized Guest Greetings
Description: PixelGreet is an app that allows hosts to craft customized messages and images for each guest. Start scheduling greetings at pixelgreet.com. Elevate your hosting, nurture lasting connections, and boost guest satisfaction with this versatile tool.
Author: Justin Gerber
"""

load("encoding/base64.star", "base64")
load("http.star", "http")
load("images/default_pixel_greet_image.png", DEFAULT_PIXEL_GREET_IMAGE_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

DEFAULT_PIXEL_GREET_IMAGE = DEFAULT_PIXEL_GREET_IMAGE_ASSET.readall()

DEFAULT_MESSAGE = "Welcome! Schedule guest greetings at Pixelgreet.com"
INVALID_API_KEY_MESSAGE = "An invalid API key has been provided."

BASE_URL = "https://api.app.pixelgreet.com/Messages"
DEFAULT_CACHE_DURATION = 40
INVALID_KEY_ERROR_NUMBER = 60062

def main(config):
    print("The application is starting...")
    api_key = config.get("key")

    #api_key = "INSERT_KEY_HERE"
    image, message = get_image_and_message(api_key)

    # Setup the image and marquee
    image = render.Image(
        width = 24,
        height = 24,
        src = image,
    )
    text = render.Text(
        message,
        font = "tb-8",
    )
    marquee_horizontal = render.Marquee(
        width = 36,
        offset_start = 18,
        offset_end = 18,
        child = text,
        align = "center",
    )
    contents = render.Row(
        expanded = True,
        main_align = "space_evenly",
        cross_align = "center",
        children = [
            image,
            marquee_horizontal,
        ],
    )
    return render.Root(
        show_full_animation = True,
        child = render.Box(
            contents,
        ),
    )

# This function retrieves the image and message based on the provided API key and its validity.
# It checks the format of the provided API key.
# If the API key format is invalid, default values for the image and message are used.
# If the API key format is valid and the key is not cached, the image and message are retrieved from the API and then are later cached.
#
# Args:
#   api_key (str): The API key to be used for the lookup and API call.
#
# Returns:
#   tuple: A tuple containing the image and message (both strings).

def get_image_and_message(api_key):
    if is_api_key_blank(api_key):
        image = DEFAULT_PIXEL_GREET_IMAGE
        message = DEFAULT_MESSAGE
    elif not is_valid_api_key_format(api_key):
        print(INVALID_API_KEY_MESSAGE)
        image = DEFAULT_PIXEL_GREET_IMAGE
        message = INVALID_API_KEY_MESSAGE
    else:
        print("The API key could be valid.")
        image, message = get_decoded_data_from_api(api_key)

    return image, message

# This function retrieves the decoded data from the API using the provided API key.
# It sends an HTTP GET request to the API and checks the response for success. The http.get is cached.
#
# If the response is successful, the image and message are extracted from the response. If the response is unsuccessful, an error message
# is generated using the handle_api_error function.
#
# Args:
#   api_key (str): The API key to be used in the API call.
#
# Returns:
#   tuple: A tuple containing the decoded image and message (both strings).
def get_decoded_data_from_api(api_key):
    response = http.get(BASE_URL, headers = {"x-api-key": api_key}, ttl_seconds = DEFAULT_CACHE_DURATION)

    if response.status_code != 200:
        fail("Failed to get a success response from the Pixel Greet API.", response.status_code)

    if response.json()["success"]:
        print("The API call was successful.")
        image = base64.decode(response.json()["base64Image"])
        message = response.json()["message"]
    else:
        error_message = handle_api_error(response)
        image = DEFAULT_PIXEL_GREET_IMAGE
        message = error_message

    return image, message

# This function handles API errors based on the error number in the response.
# It is called when the API response is unsuccessful. The function extracts the error number
# from the response and prints an appropriate message based on the error number.
#
# Note: The returned error message string can be used by the calling function to handle the error further.
#
# Args:
#   response (object): The HTTP response object from the API call.
#
# Returns:
#   str: A string containing the error message based on the error number.
def handle_api_error(response):
    print("The API call was unsuccessful.")
    error_number = response.json()["error"]["errorNumber"]

    if error_number == INVALID_KEY_ERROR_NUMBER:
        print(INVALID_API_KEY_MESSAGE)
        return INVALID_API_KEY_MESSAGE
    else:
        print("An unknown error has occurred.")
        return "An unknown error has occurred."

# This function checks if the provided API key has a valid format.
# A valid API key format must:
#   1. Not be an empty string or None.
#   2. Contain exactly 2 hyphens.
#
# Note: This function does not guarantee that the API key is valid, but it ensures
#       that the API key has the potential to be right based on the format.
#
# Args:
#   api_key (string): The API key to be validated.
#
# Returns:
#   bool: True if the API key has a valid format, False otherwise.
def is_valid_api_key_format(api_key):
    return api_key and api_key.count("-") == 2

# This function checks if the provided API key is blank.
#
# Args:
#   api_key (string): The API key to be validated.
#
# Returns:
#   bool: True if the API is blank, otherwise false
def is_api_key_blank(api_key):
    return api_key in (None, "")

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "key",
                name = "Key",
                desc = "Pixel Greet API Key",
                icon = "key",
                secret = True,
            ),
        ],
    )
