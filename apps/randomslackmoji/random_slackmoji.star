"""
Applet: Random Slackmoji
Summary: Displays a random Slackmoji
Description: Displays a random image from slackmojis.com!
Author: btjones
"""

# Copyright 2022 Brandon Jones

# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

load("cache.star", "cache")
load("encoding/json.star", "json")
load("html.star", "html")
load("http.star", "http")
load("images/fail_image.png", FAIL_IMAGE_ASSET = "file")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

FAIL_IMAGE = FAIL_IMAGE_ASSET.readall()

SLACKMOJI_PAGE_COUNT = 112
SLACKMOJI_IMAGES_PER_PAGE = 499
SLACKMOJIS_URL_RANDOM = "https://slackmojis.com/emojis.json?page="
SLACKMOJIS_URL_QUERY = "https://slackmojis.com/emojis/search?query="

USE_CACHE = True
CACHE_SECONDS_URL = 60  # 60 seconds
CACHE_SECONDS_IMAGE = 60 * 60 * 24 * 30  # 30 days
SCHEMA_QUERY_ID = "query"

# fetches a random slackmoji url from all slackmojis
def get_random_url():
    page_url = SLACKMOJIS_URL_RANDOM + str(random.number(0, SLACKMOJI_PAGE_COUNT))
    response = http.get(page_url)
    if response.status_code == 200:
        body = response.body()
        data = json.decode(body) if body else None
        if data:
            slackmoji = data[random.number(0, SLACKMOJI_IMAGES_PER_PAGE)]
            if slackmoji and slackmoji["image_url"]:
                return slackmoji["image_url"]

    # something went wrong, no image url to return
    return None

# fetches a random slackmoji url from the query results
def get_query_url(query):
    page_url = SLACKMOJIS_URL_QUERY + query
    response = http.get(page_url)
    if response.status_code == 200:
        html_body = html(response.body())
        images = html_body.find("img")
        image_count = images.len()
        if image_count > 0:
            random_index = random.number(0, image_count - 1)
            return images.eq(random_index).attr("src")

    # something went wrong, no image url to return
    return None

# fetches a random slackmoji image url
def get_slackmoji_url(query):
    cache_name = "slackmoji_url_" + query

    # return cached url if available
    if USE_CACHE:
        cached_url = cache.get(cache_name)
        if cached_url != None:
            return cached_url

    # no cache, fetch new url
    url = get_query_url(query) if len(query) > 0 else get_random_url()

    # set cached url
    if USE_CACHE and url != None:
        cache.set(cache_name, url, ttl_seconds = CACHE_SECONDS_URL)

    return url

# downloads an image from the provided url
def get_image(url):
    if url:
        # no cache, fetch new image
        response = http.get(url, ttl_seconds = CACHE_SECONDS_IMAGE)
        if response and response.status_code == 200:
            return response.body()

    # something went wrong, return the fail image
    return FAIL_IMAGE

def main(config):
    # get the slackmoji image url
    query = config.get(SCHEMA_QUERY_ID, "")
    url = get_slackmoji_url(query)

    # if no image url was returned and we have a query, show error message
    if (url == None and len(query) > 0):
        return render.Root(
            render.Box(
                child = render.WrappedText(
                    content = "No results for: " + query,
                ),
            ),
        )

    # download the image
    image = get_image(url)

    return render.Root(
        render.Box(
            child = render.Image(
                src = image,
                height = 32,
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = SCHEMA_QUERY_ID,
                name = "Search Query",
                desc = "Optional search to narrow down the image results.",
                icon = "magnifyingGlass",
                default = "",
            ),
        ],
    )
