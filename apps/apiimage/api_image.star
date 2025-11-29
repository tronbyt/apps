"""
Applet: API image
Summary: API image display
Description: Display an image from an API endpoint.
Author: Michael Yagi
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("images/bg_image.jpg", BG_IMAGE_ASSET = "file")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("xpath.star", "xpath")

BG_IMAGE = BG_IMAGE_ASSET.readall()

def main(config):
    random.seed(time.now().unix)

    api_url = config.str("api_url", "")
    response_path = config.get("response_path", "")
    request_headers = config.get("request_headers", "")
    debug_output = config.bool("debug_output", False)
    base_url = config.str("base_url", "")
    fit_screen = config.bool("fit_screen", False)
    ttl_seconds = config.get("ttl_seconds", 20)
    ttl_seconds = int(ttl_seconds)

    if debug_output:
        print("------------------------------")
        print("CONFIG - api_url: " + api_url)
        print("CONFIG - base_url: " + base_url)
        print("CONFIG - response_path: " + response_path)
        print("CONFIG - request_headers: " + request_headers)
        print("CONFIG - debug_output: " + str(debug_output))
        print("CONFIG - fit_screen: " + str(fit_screen))
        print("CONFIG - ttl_seconds: " + str(ttl_seconds))

    return get_image(api_url, base_url, response_path, request_headers, debug_output, fit_screen, ttl_seconds)

def get_image(api_url, base_url, response_path, request_headers, debug_output, fit_screen, ttl_seconds):
    failure = False
    message = ""
    row = render.Row(children = [])

    if debug_output == False:
        message = "API IMAGE"

        row = render.Stack([
            render.Image(src = BG_IMAGE),
            render.Box(
                render.Row(
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        render.Box(
                            width = 44,
                            height = 12,
                            color = "#FFFFFF",
                        ),
                    ],
                ),
            ),
            render.Box(
                render.Row(
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        render.Box(
                            width = 42,
                            height = 10,
                            color = "#000000",
                        ),
                    ],
                ),
            ),
            render.Box(
                render.Row(
                    main_align = "space_evenly",
                    cross_align = "center",
                    children = [
                        render.Text(content = message, font = "tom-thumb", color = "#FFFFFF"),
                    ],
                ),
            ),
        ])

    if api_url == "":
        failure = True
        message = "API URL must not be blank"

        if debug_output:
            print(message)

    else:
        headerMap = {}
        if request_headers != "" or request_headers != {}:
            request_headers_array = request_headers.split(",")

            for app_header in request_headers_array:
                headerKeyValueArray = app_header.split(":")
                if len(headerKeyValueArray) > 1:
                    headerMap[headerKeyValueArray[0].strip()] = headerKeyValueArray[1].strip()

        output_map = get_data(api_url, debug_output, headerMap, ttl_seconds)
        output_body = output_map["data"]
        output_type = output_map["type"]

        if output_body != None and type(output_body) == "string":
            output = json.decode(output_body, None)

            if output_body != "":
                img = None

                if debug_output:
                    outputStr = str(output)
                    outputLen = len(outputStr)
                    if outputLen >= 200:
                        outputLen = 200

                    if output_type == "json":
                        outputStr = outputStr[0:outputLen]
                        if outputLen >= 200:
                            outputStr = outputStr + "..."
                            print("Decoded JSON truncated: " + outputStr)
                        else:
                            print("Decoded JSON: " + outputStr)

                if failure == False:
                    if output_type == "json":
                        failure = True

                        # Parse response path for JSON
                        output_map = parse_response_path(output, response_path, debug_output)
                        output = output_map["output"]
                        message = output_map["message"]
                        failure = output_map["failure"]

                        if debug_output:
                            print("Response content type JSON")

                        if type(output) == "string" and output.startswith("http") == False and (base_url == "" or base_url.startswith("http") == False):
                            failure = True
                            message = "Base URL required"
                            if debug_output:
                                print("Invalid URL. Requires a base_url")
                        elif type(output) == "string":
                            failure = False
                            if output.startswith("http") == False and base_url != "":
                                if output.startswith("/"):
                                    url = base_url + output
                                else:
                                    url = base_url + "/" + output
                            else:
                                url = output

                            output_map = get_data(url, debug_output, headerMap, ttl_seconds)
                            img = output_map["data"]

                            if debug_output:
                                print("Image URL: " + url)
                        else:
                            if message == "":
                                message = "Bad response path for JSON. Must point to an image URL."
                            if debug_output:
                                print(message)
                            failure = True
                    elif output_type == "xml":
                        failure = False

                        output = xpath.loads(output_body)

                        output_map = parse_response_path(output, response_path, debug_output, True)
                        output = output_map["output"]
                        message = output_map["message"]
                        failure = output_map["failure"]

                        if failure == False and type(output) == "string":
                            if output.startswith("http") == False and base_url != "":
                                if output.startswith("/"):
                                    url = base_url + output
                                else:
                                    url = base_url + "/" + output
                            else:
                                url = output

                            output_map = get_data(url, debug_output, headerMap, ttl_seconds)
                            img = output_map["data"]

                            if debug_output:
                                print("Image URL: " + url)
                        elif response_path == "":
                            message = "Missing response path for XML"
                            if debug_output:
                                print(message)
                            failure = True
                    elif output_type == "image":
                        if debug_output:
                            print("Response content type image")
                        img = output_body
                    else:
                        failure = True
                        message = "Invalid type: " + output_type
                        if debug_output:
                            print(message)

                if img != None:
                    imgRender = render.Image(
                        src = img,
                        height = 32,
                    )

                    if fit_screen == True:
                        imgRender = render.Image(
                            src = img,
                            width = 64,
                        )

                    return render.Root(
                        child = render.Box(
                            render.Row(
                                expanded = True,
                                main_align = "space_evenly",
                                cross_align = "center",
                                children = [imgRender],
                            ),
                        ),
                    )

            else:
                message = "Invalid image URL"
                if debug_output:
                    print(message)
                    print(output)
                failure = True
                # return get_image(base_url, api_url, response_path, request_headers, debug_output)

        else:
            message = "Oops! Check URL and header values. URL " + api_url + " must return JSON or text."
            if debug_output:
                print(message)
            failure = True

    if message == "":
        message = "Could not get image"

    message = "API Image - " + message

    if debug_output == True:
        row = render.Marquee(
            offset_start = 32,
            offset_end = 32,
            height = 32,
            scroll_direction = "vertical",
            width = 64,
            child = render.WrappedText(content = message, font = "tom-thumb", color = "#FF0000"),
        )

    return render.Root(
        child = render.Box(
            row,
        ),
    )

def parse_response_path(output, responsePathStr, debug_output, is_xml = False):
    message = ""
    failure = False

    if (len(responsePathStr) > 0):
        responsePathArray = responsePathStr.split(",")

        if is_xml:
            path_str = ""

            # last_item = ""
            for item in responsePathArray:
                item = item.strip()

                # test_output = None
                # if len(path_str) > 0:
                #     test_output = output.query_all(path_str)
                #     if type(test_output) == "list" and len(test_output) == 0:
                #         failure = True
                #         message = "Response path has empty list for " + last_item + "."
                #         if debug_output:
                #             print("responsePathArray for " + last_item + " invalid. Response path has empty list.")
                #         break

                index = -1
                valid_rand = False
                if item == "[rand]":
                    valid_rand = True

                if valid_rand:
                    test_output = output.query_all(path_str)
                    if type(test_output) == "list" and len(test_output) > 0:
                        index = random.number(0, len(test_output) - 1)
                    else:
                        failure = True
                        message = "Response path has empty list for " + item + "."
                        if debug_output:
                            print("responsePathArray for " + item + " invalid. Response path has empty list.")
                        break

                    if debug_output:
                        print("Random index chosen " + str(index))

                if type(item) != "int" and item.isdigit():
                    index = int(item)

                if index > -1:
                    path_str = path_str + "[" + str(index) + "]"
                else:
                    path_str = path_str + "/" + item

                # last_item = item

                if debug_output:
                    print("Appended path: " + path_str)

            if failure == False:
                output = output.query_all(path_str)
                if type(output) == "list" and len(output) > 0:
                    output = output[0]

                if type(output) != "string":
                    failure = True
                    message = "Response path result not a string, found " + type(output) + " instead reading path " + path_str + "."
                    if debug_output:
                        print(message)
            else:
                output = None

        else:
            for item in responsePathArray:
                item = item.strip()

                valid_rand = False
                if item == "[rand]":
                    valid_rand = True

                if valid_rand:
                    if type(output) == "list":
                        if len(output) > 0 and item == "[rand]":
                            item = random.number(0, len(output) - 1)
                        else:
                            failure = True
                            message = "Response path has empty list for " + item + "."
                            if debug_output:
                                print("responsePathArray for " + item + " invalid. Response path has empty list.")
                            break

                        if debug_output:
                            print("Random index chosen " + str(item))
                    else:
                        failure = True
                        message = "Response path invalid for " + item + ". Use of [rand] only allowable in lists."
                        if debug_output:
                            print("responsePathArray for " + item + " invalid. Use of [rand] only allowable in lists.")
                        break

                if type(item) != "int" and item.isdigit():
                    item = int(item)

                if debug_output:
                    print("path array item: " + str(item) + " - type " + str(type(output)))

                if output != None and type(output) == "dict" and type(item) == "string":
                    valid_keys = []
                    if output != None and type(output) == "dict":
                        valid_keys = output.keys()

                    has_item = False
                    for valid_key in valid_keys:
                        if valid_key == item:
                            has_item = True
                            break

                    if has_item:
                        output = output[item]
                    else:
                        failure = True
                        message = "Response path invalid. " + str(item) + " does not exist"
                        if debug_output:
                            print("responsePathArray invalid. " + str(item) + " does not exist")
                        output = None
                        break
                elif output != None and type(output) == "list" and type(item) == "int" and item <= len(output) - 1:
                    output = output[item]
                else:
                    failure = True
                    message = "Response path invalid. " + str(item) + " does not exist"
                    if debug_output:
                        print("responsePathArray invalid. " + str(item) + " does not exist")
                    output = None
                    break
    else:
        output = None

    return {"output": output, "failure": failure, "message": message}

def get_data(url, debug_output, headerMap = {}, ttl_seconds = 20):
    if headerMap == {}:
        res = http.get(url, ttl_seconds = ttl_seconds)
    else:
        res = http.get(url, headers = headerMap, ttl_seconds = ttl_seconds)

    if url.endswith("webp"):
        return {"data": res.body(), "type": "image"}

    headers = res.headers
    isValidContentType = False

    headersStr = str(headers)
    headersStr = headersStr.lower()
    headers = json.decode(headersStr, None)
    contentType = ""
    if headers != None and headers.get("content-type") != None:
        contentType = headers.get("content-type")

        if contentType.find("json") != -1 or contentType.find("image") != -1 or contentType.find("xml") != -1 or "webp" in url:
            if contentType.find("json") != -1:
                contentType = "json"
            elif contentType.find("image") != -1 or "webp" in url:
                contentType = "image"
            else:
                contentType = "xml"
            isValidContentType = True

    if debug_output:
        print("isValidContentType for " + url + " content type " + contentType + ": " + str(isValidContentType))

    if res.status_code != 200 or isValidContentType == False:
        if debug_output:
            print("status: " + str(res.status_code))
            print("Requested url: " + str(url))
    else:
        data = res.body()

        return {"data": data, "type": contentType}

    return {"data": None, "type": contentType}

def get_schema():
    ttl_options = [
        schema.Option(
            display = "5 sec",
            value = "5",
        ),
        schema.Option(
            display = "20 sec",
            value = "20",
        ),
        schema.Option(
            display = "1 min",
            value = "60",
        ),
        schema.Option(
            display = "15 min",
            value = "900",
        ),
        schema.Option(
            display = "1 hour",
            value = "3600",
        ),
        schema.Option(
            display = "24 hours",
            value = "86400",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "api_url",
                name = "API URL",
                desc = "The API URL. Supports JSON, XML or image types.",
                icon = "globe",
                default = "",
            ),
            schema.Text(
                id = "response_path",
                name = "JSON response path",
                desc = "A comma separated path to the image URL in the response JSON or XML. Use `[rand]` to choose a random index. eg. `json_key_1, 0, [rand], json_key_to_image_url`",
                icon = "code",
                default = "",
                # default = "message",
            ),
            schema.Text(
                id = "request_headers",
                name = "Request headers",
                desc = "Comma separated key:value pairs to build the request headers. eg, `x-api-key:abc123,content-type:application/json`",
                icon = "code",
                default = "",
            ),
            schema.Dropdown(
                id = "ttl_seconds",
                name = "Refresh rate",
                desc = "Refresh data at the specified interval. Useful for when an endpoint serves random images.",
                icon = "clock",
                default = ttl_options[1].value,
                options = ttl_options,
            ),
            schema.Text(
                id = "base_url",
                name = "Base URL",
                desc = "The base URL if needed",
                icon = "globe",
                default = "",
            ),
            schema.Toggle(
                id = "fit_screen",
                name = "Fit screen",
                desc = "Fit image on screen.",
                icon = "arrowsLeftRightToLine",
                default = False,
            ),
            schema.Toggle(
                id = "debug_output",
                name = "Toggle debug messages",
                desc = "Toggle debug messages. Will display the messages on the display if enabled.",
                icon = "bug",
                default = False,
            ),
        ],
    )
