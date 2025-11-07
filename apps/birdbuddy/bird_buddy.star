"""
Applet: Bird Buddy
Summary: Whose visiting your feeder
Description: See your latest Bird Buddy feeder visitors.
Author: Brombomb
"""

load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# Bird Buddy GraphQL API URL
BIRD_BUDDY_GRAPHQL_URL = "https://graphql.app-api.prod.aws.mybirdbuddy.com/graphql"

# Cache TTL (5 minutes)
CACHE_TTL = 300

# Display constants
BIRD_ICON_SIZE = 32
TEXT_AREA_WIDTH = 32
MARQUEE_DELAY = 32

# Default values
DEFAULT_BIRD_NAME = "No recent visitors"

# Embedded House Finch icon (32px height, WebP format, 688 bytes)
DEFAULT_FINCH_ICON = base64.decode("UklGRqgCAABXRUJQVlA4WAoAAAAQAAAAHwAAHwAAQUxQSIcBAAABkHRrmyHJ0t+2bdurXtu27d7atnts27Zta2dz1XZnDCIicxARE4D/s6aTm6HsH1DOvPLl+9NOU8nkmybI70f0eWRleMKGCHXmdKwSza56x9p0HYbKAcL+FkbxeUYImd1nQpErGmNMHIjXAmBQ95pQB2UBaDYPEeYVLfxeNkbo75wAk22zhL0OVJ3g3QKFdCsYHiS8B+UpgMMb2viarQLXBRWG6hUaEQTCfVyRoXmbIXYZmDoPpZlNZSmfleaBMQvtkkzlgdP9kxTrVHlk6mfEHTMFt8VDMaNrTMFtsm7m+zDXaIEiuN3OCtc8Is+NcQirlbj8ns5utgA0fVe+fz5y8+S7Kw/Hh7PkOPw/jrWqA4Bqe3x1n4ZCwQLHxJfDFSqssOOJCoCcnEZTsfsCXeeSxjvXDl96OblIhyGjBMCpcu2RCyuuxqno29uap+xuiDk+t9ucRjXJ335s28PLC/J0AUBRHSZb587b8sgq2qctj9DWUZH77XetrocePADU5CFSQV9OxH8bAFZQOCD6AAAA0AUAnQEqIAAgAD6JOpdHpSOiITAYDACgEQlsAJ0y0HtK0GFK9GAHmNsmqw7vyW55QMqSzbigAAD9HA4d1FhaRU4gK+vJY77KIge08aCwuwMWmP/cU9qLFFE7Fb8//GyN9QFsL7m8JlAk19x3+tLtrMmjlgOS9oajz1/xngIk0b9doBcx3kFp9BHQ1ZYjkB7+EweYxkzW/EY7xW4BU/qvcmglxp+vweI7XdCXb/c2Q0A+Hz7BSdhXUs0Hp0qDgtDPZL0Kz3VzAmya2k0BbJU/QLLmtFEqEiXR+cmyeW1mGkg41CqWThGPKnG/1c5u/39e0ZiyyNblAHnAAA==")

# Relevant feed item types for bird sightings
VALID_BIRD_NODE_TYPES = [
    "FeedItemSpeciesSighting",
    "FeedItemSpeciesUnlocked",
    "FeedItemCollectedPostcard",
    "FeedItemNewPostcard",
    "FeedItemMysteryVisitorNotRecognized",
]

def main(config):
    username = config.str("username", "")
    password = config.str("password", "")

    # Clean up whitespace
    username = username.strip() if username else ""
    password = password.strip() if password else ""

    # Check if configuration is missing
    if not username or not password:
        return render_error("Bird Buddy Setup\nAdd credentials in\nPixlet app settings")

    # Get authentication token
    token = get_auth_token(username, password)
    if not token:
        return render_error("Authentication failed.\nCheck credentials")

    # Get feeder data
    feeders = get_feeders(token)
    if not feeders:
        return render_error("No feeders found")

    # Get the latest bird sighting
    latest_sighting = get_latest_sighting(token, feeders)

    return render_bird_display(latest_sighting)

def get_auth_token(username, password):
    """Authenticate with Bird Buddy API and get access token"""

    cache_key = "bb_token_{}".format(username)
    cached_token = cache.get(cache_key)

    if cached_token:
        print("Using cached token")
        return cached_token

    # GraphQL mutation for authentication based on PyBirdBuddy
    auth_mutation = {
        "query": """
            mutation emailSignIn($emailSignInInput: EmailSignInInput!) {
                authEmailSignIn(emailSignInInput: $emailSignInInput) {
                    ... on Auth {
                        accessToken
                        refreshToken
                        __typename
                    }
                    __typename
                }
            }
        """,
        "variables": {
            "emailSignInInput": {
                "email": username,
                "password": password,
            },
        },
    }

    headers = {
        "Content-Type": "application/json",
    }

    response = http.post(
        url = BIRD_BUDDY_GRAPHQL_URL,
        json_body = auth_mutation,
        headers = headers,
        ttl_seconds = 60,
    )

    if response.status_code != 200:
        print("Auth failed with status: {}".format(response.status_code))
        print("Response body: {}".format(response.body()))
        if response.status_code == 400:
            print("Invalid credentials - check username/password")
        elif response.status_code == 401:
            print("Unauthorized - check credentials")
        elif response.status_code == 403:
            print("Forbidden - account may be locked")
        return None

    auth_response = response.json()
    if not auth_response:
        print("Failed to parse auth JSON response")
        return None

    if "data" in auth_response:
        auth_data = auth_response.get("data", {}).get("authEmailSignIn")
        if auth_data:
            # Check if it's a successful Auth response
            if auth_data.get("__typename") == "Auth":
                token = auth_data.get("accessToken")
                if token:
                    # Cache token for 14 minutes (tokens usually last 15 min)
                    cache.set(cache_key, token, ttl_seconds = 840)
                    return token

                # Check if it's a different response type (Problem, etc.)
            else:
                response_type = auth_data.get("__typename", "Unknown")
                if response_type == "Problem":
                    print("Authentication failed - invalid email/password")
                else:
                    print("Auth failed with response type: {}".format(response_type))
                return None

    # Check for GraphQL errors
    if auth_response and "errors" in auth_response:
        errors = auth_response.get("errors", [])
        for error in errors:
            print("GraphQL Auth Error: {}".format(error.get("message", "Unknown error")))

    print("Failed to parse auth response")

    return None

def get_feeders(token):
    """Get list of feeders for the user using GraphQL"""

    # GraphQL query for feeders - based on PyBirdBuddy me query
    feeders_query = {
        "query": """
            query me {
                me {
                    feeders {
                        ... on FeederForOwner {
                            id
                            name
                            state
                            battery {
                                percentage
                                state
                            }
                            signal {
                                state
                                value
                            }
                            __typename
                        }
                        ... on FeederForMember {
                            id
                            name
                            state
                            battery {
                                percentage
                                state
                            }
                            signal {
                                state
                                value
                            }
                            __typename
                        }
                        __typename
                    }
                    __typename
                }
            }
        """,
    }

    headers = {
        "Authorization": "Bearer {}".format(token),
        "Content-Type": "application/json",
    }

    response = http.post(
        url = BIRD_BUDDY_GRAPHQL_URL,
        json_body = feeders_query,
        headers = headers,
        ttl_seconds = CACHE_TTL,
    )

    if response.status_code != 200:
        print("Feeders request failed: {}".format(response.status_code))
        print("Feeders response body: {}".format(response.body()))
        if response.status_code == 429:
            print("RATE LIMITED: Too many requests to Bird Buddy API")
        elif response.status_code == 500:
            print("SERVER ERROR: Bird Buddy API internal server error")
        elif response.status_code == 401:
            print("UNAUTHORIZED: Token may be expired")
        return None

    feeders_response = response.json()
    if not feeders_response:
        print("Failed to parse JSON response")
        return []

    if "data" in feeders_response:
        me_data = feeders_response.get("data", {}).get("me", {})
        if me_data:
            feeders_data = me_data.get("feeders", [])
            return feeders_data
        else:
            print("No 'me' data in response")
            return []
    else:
        print("Failed to parse feeders response")
        if feeders_response and "errors" in feeders_response:
            errors = feeders_response.get("errors", [])
            for error in errors:
                print("GraphQL Feeders Error: {}".format(error.get("message", "Unknown error")))
        else:
            print("No response data found")
        return []

def get_latest_sighting(token, feeders):
    """Get the most recent bird sighting from feed using GraphQL"""

    if not feeders:
        return create_default_sighting()

    # GraphQL query for recent feed items (based on PyBirdBuddy FEED query)
    feed_query = {
        "query": """
            query meFeed($first: Int) {
                me {
                    feed(first: $first) {
                        edges {
                            node {
                                ... on FeedItemSpeciesSighting {
                                    id
                                    createdAt
                                    collection {
                                        ... on CollectionBird {
                                            species {
                                                ... on SpeciesBird {
                                                    id
                                                    name
                                                }
                                            }
                                        }
                                    }
                                    __typename
                                }
                                ... on FeedItemSpeciesUnlocked {
                                    id
                                    createdAt
                                    collection {
                                        ... on CollectionBird {
                                            species {
                                                ... on SpeciesBird {
                                                    id
                                                    name
                                                }
                                            }
                                        }
                                    }
                                    __typename
                                }
                                ... on FeedItemNewPostcard {
                                    id
                                    createdAt
                                    __typename
                                }
                                ... on FeedItemMysteryVisitorNotRecognized {
                                    id
                                    createdAt
                                    __typename
                                }
                                ... on FeedItemCollectedPostcard {
                                    id
                                    createdAt
                                    hasNewSpecies
                                    hasMysteryVisitor
                                    species {
                                        ... on SpeciesBird {
                                            id
                                            name
                                            iconUrl
                                        }
                                    }
                                    __typename
                                }
                                ... on FeedItemFeederMemberJoined {
                                    id
                                    createdAt
                                    __typename
                                }
                                __typename
                            }
                        }
                        __typename
                    }
                    __typename
                }
            }
        """,
        "variables": {
            "first": 100,
        },
    }

    headers = {
        "Authorization": "Bearer {}".format(token),
        "Content-Type": "application/json",
    }

    response = http.post(
        url = BIRD_BUDDY_GRAPHQL_URL,
        json_body = feed_query,
        headers = headers,
        ttl_seconds = CACHE_TTL,
    )

    if response.status_code == 200:
        feed_response = response.json()
        if not feed_response:
            print("Failed to parse feed JSON response")
        elif "data" in feed_response:
            me_data = feed_response.get("data", {}).get("me", {})
            if me_data and "feed" in me_data:
                feed_edges = me_data.get("feed", {}).get("edges", [])
                if feed_edges:
                    # Look for the most recent BIRD-related feed item only
                    for edge in feed_edges:
                        node = edge.get("node", {})
                        node_type = node.get("__typename", "")

                        # Only include actual bird sighting items, not setup/admin items
                        if node_type in VALID_BIRD_NODE_TYPES:
                            parsed_result = parse_feed_item(node)
                            if parsed_result:  # Only return if we got actual data
                                # Check if this is a postcard that needs bird detail lookup
                                if "postcard_id" in parsed_result:
                                    postcard_id = parsed_result["postcard_id"]
                                    sighting_result = get_postcard_sighting(token, postcard_id)
                                    if sighting_result:
                                        # Use the postcard timestamp but bird name from sighting
                                        sighting_result["timestamp"] = parsed_result["timestamp"]
                                        return sighting_result
                                    else:
                                        # Fallback to generic postcard message
                                        parsed_result["bird_name"] = "Bird Visitor"
                                        return parsed_result
                                else:
                                    return parsed_result
                else:
                    print("No feed items in response")
            else:
                print("No feed data in me response")
        elif feed_response and "errors" in feed_response:
            errors = feed_response.get("errors", [])
            for error in errors:
                print("GraphQL Feed Error: {}".format(error.get("message", "Unknown error")))
        else:
            print("No data in feed response")
    else:
        print("Feed request failed: {}".format(response.status_code))
        print("Feed response body: {}".format(response.body()))
        if response.status_code == 429:
            print("RATE LIMITED: Too many feed requests to Bird Buddy API")
        elif response.status_code == 500:
            print("SERVER ERROR: Bird Buddy feed API internal server error")
        elif response.status_code == 401:
            print("UNAUTHORIZED: Feed access token may be expired")

    # Try the collections query if feed fails
    return get_from_collections(token)

def get_postcard_sighting(token, postcard_id):
    """Convert a postcard to sighting to get bird details using PyBirdBuddy approach"""

    # Based on POSTCARD_TO_SIGHTING mutation from PyBirdBuddy
    postcard_mutation = {
        "query": """
            mutation sightingCreateFromPostcard($sightingCreateFromPostcardInput: SightingCreateFromPostcardInput!) {
                sightingCreateFromPostcard(sightingCreateFromPostcardInput: $sightingCreateFromPostcardInput) {
                    ... on SightingCreateFromPostcardResult {
                        sightingReport {
                            sightings {
                                ... on SightingRecognizedBird {
                                    id
                                    color
                                    text
                                    count
                                    species {
                                        ... on SpeciesBird {
                                            id
                                            name
                                            iconUrl
                                        }
                                    }
                                    __typename
                                }
                                ... on SightingRecognizedBirdUnlocked {
                                    id
                                    color
                                    text
                                    species {
                                        ... on SpeciesBird {
                                            id
                                            name
                                            iconUrl
                                        }
                                    }
                                    __typename
                                }
                                ... on SightingRecognizedMysteryVisitor {
                                    id
                                    color
                                    text
                                    count
                                    __typename
                                }
                                __typename
                            }
                            __typename
                        }
                        __typename
                    }
                    __typename
                }
            }
        """,
        "variables": {
            "sightingCreateFromPostcardInput": {
                "feedItemId": postcard_id,
            },
        },
    }

    headers = {
        "Authorization": "Bearer {}".format(token),
        "Content-Type": "application/json",
    }

    response = http.post(
        url = BIRD_BUDDY_GRAPHQL_URL,
        json_body = postcard_mutation,
        headers = headers,
        ttl_seconds = 60,
    )

    if response.status_code == 200:
        sighting_response = response.json()
        if not sighting_response:
            print("Failed to parse sighting JSON response")
        elif "data" in sighting_response:
            data = sighting_response.get("data")
            if data and "sightingCreateFromPostcard" in data:
                create_data = data.get("sightingCreateFromPostcard")
                if create_data and "sightingReport" in create_data:
                    sighting_report = create_data.get("sightingReport")
                    if sighting_report and "sightings" in sighting_report:
                        sightings = sighting_report.get("sightings", [])

                        if sightings:
                            # Get the first sighting
                            sighting = sightings[0]
                            sighting_type = sighting.get("__typename", "")

                            if sighting_type in ["SightingRecognizedBird", "SightingRecognizedBirdUnlocked"]:
                                species = sighting.get("species", {})
                                if species:
                                    bird_name = species.get("name", "Unknown Bird")
                                    icon_url = species.get("iconUrl", "")
                                    return {
                                        "bird_name": bird_name,
                                        "timestamp": "",  # We'll use the postcard timestamp
                                        "icon_url": icon_url,
                                        "raw_data": sighting,
                                    }
                            elif sighting_type == "SightingRecognizedMysteryVisitor":
                                return {
                                    "bird_name": "Mystery Visitor",
                                    "timestamp": "",
                                    "icon_url": "",
                                    "raw_data": sighting,
                                }

        # Check for errors (might be already collected)
        if sighting_response and "errors" in sighting_response:
            errors = sighting_response.get("errors", [])
            for error in errors:
                print("Postcard sighting error: {}".format(error.get("message", "Unknown error")))
    else:
        print("Postcard sighting request failed: {}".format(response.status_code))
        print("Response body: {}".format(response.body()))
        if response.status_code == 429:
            print("RATE LIMITED: Too many postcard requests to Bird Buddy API")
        elif response.status_code == 500:
            print("SERVER ERROR: Bird Buddy postcard API internal server error")
        elif response.status_code == 401:
            print("UNAUTHORIZED: Postcard access token may be expired")

    return None

def get_from_collections(token):
    """Get bird data from collections using GraphQL"""

    # Use the collections query from PyBirdBuddy
    collections_query = {
        "query": """
            query meCollections {
                me {
                    collections {
                        ... on CollectionBird {
                            id
                            visitLastTime
                            visitsAllTime
                            species {
                                ... on SpeciesBird {
                                    id
                                    name
                                    iconUrl
                                }
                            }
                            __typename
                        }
                        ... on CollectionMysteryVisitor {
                            id
                            visitLastTime
                            visitsAllTime
                            __typename
                        }
                        __typename
                    }
                    __typename
                }
            }
        """,
    }

    headers = {
        "Authorization": "Bearer {}".format(token),
        "Content-Type": "application/json",
    }

    response = http.post(
        url = BIRD_BUDDY_GRAPHQL_URL,
        json_body = collections_query,
        headers = headers,
        ttl_seconds = CACHE_TTL,
    )

    if response.status_code == 200:
        collections_response = response.json()
        if not collections_response:
            print("Failed to parse collections JSON response")
        elif "data" in collections_response:
            me_data = collections_response.get("data", {}).get("me", {})
            if me_data and "collections" in me_data:
                collections = me_data.get("collections", [])

                if collections:
                    # Sort by most recent visit
                    bird_collections = []
                    for collection in collections:
                        if collection.get("__typename") == "CollectionBird":
                            bird_collections.append(collection)

                    if bird_collections:
                        # Sort by visitLastTime (most recent first)
                        def get_visit_time(collection):
                            return collection.get("visitLastTime", "1970-01-01T00:00:00Z")

                        bird_collections.sort(key = get_visit_time, reverse = True)

                        latest_collection = bird_collections[0]
                        species = latest_collection.get("species", {})
                        bird_name = species.get("name", "Unknown Bird")
                        visit_time = latest_collection.get("visitLastTime", "")
                        icon_url = species.get("iconUrl", "")

                        return {
                            "bird_name": bird_name,
                            "timestamp": visit_time,
                            "icon_url": icon_url,
                            "raw_data": latest_collection,
                        }
        elif collections_response and "errors" in collections_response:
            errors = collections_response.get("errors", [])
            for error in errors:
                print("GraphQL Collections Error: {}".format(error.get("message", "Unknown error")))
    else:
        print("Collections request failed: {}".format(response.status_code))
        print("Collections response body: {}".format(response.body()))

    return create_default_sighting()

def parse_feed_item(feed_node):
    """Parse a single feed item from GraphQL response"""

    if not feed_node:
        return create_default_sighting()

    node_type = feed_node.get("__typename", "")

    # Extract bird name based on feed item type
    bird_name = "Unknown Bird"
    icon_url = ""

    if node_type in ["FeedItemSpeciesSighting", "FeedItemSpeciesUnlocked"]:
        collection = feed_node.get("collection", {})
        if collection and "species" in collection:
            species = collection.get("species", {})
            if species:
                bird_name = species.get("name") or "Unknown Bird"
                icon_url = species.get("iconUrl", "")
    elif node_type == "FeedItemCollectedPostcard":
        # This should have actual bird species data
        species = feed_node.get("species", {})
        if species:
            bird_name = species.get("name", "Unknown Bird")
            icon_url = species.get("iconUrl", "")
        else:
            bird_name = "Collected Postcard"
            icon_url = ""
    elif node_type == "FeedItemNewPostcard":
        # Try to get bird details from the postcard using its ID
        postcard_id = feed_node.get("id")
        if postcard_id:
            # Note: This will be called from get_latest_sighting with token
            return {
                "bird_name": "Getting bird details...",
                "timestamp": feed_node.get("createdAt", ""),
                "icon_url": "",
                "raw_data": feed_node,
                "postcard_id": postcard_id,  # Pass the ID for later processing
            }
        else:
            bird_name = "Bird Visitor"
            icon_url = ""
    elif node_type == "FeedItemMysteryVisitorNotRecognized":
        bird_name = "Mystery Visitor"
    elif node_type == "FeedItemFeederMemberJoined":
        bird_name = "Feeder Setup"
    else:
        bird_name = "Recent Activity"

    # Extract timestamp
    timestamp_str = feed_node.get("createdAt", "")

    return {
        "bird_name": bird_name,
        "timestamp": timestamp_str,
        "icon_url": icon_url,
        "raw_data": feed_node,
    }

def create_default_sighting():
    """Create a default sighting when no data is available"""
    return {
        "bird_name": DEFAULT_BIRD_NAME,
        "timestamp": None,
        "icon_url": DEFAULT_FINCH_ICON,
        "raw_data": {},
    }

def clean_timestamp(timestamp_str):
    """Clean up timestamp string to handle ISO format variations"""
    if not timestamp_str:
        return None

    # Clean up the timestamp - handle both with and without milliseconds
    clean_timestamp = timestamp_str
    if "." in timestamp_str and "Z" in timestamp_str:
        # Remove milliseconds: 2025-10-08T14:45:34.497Z -> 2025-10-08T14:45:34Z
        parts = timestamp_str.split(".")
        clean_timestamp = parts[0] + "Z"
    elif not timestamp_str.endswith("Z"):
        clean_timestamp = timestamp_str + "Z"

    return clean_timestamp

def humanize_time_ago(timestamp_str):
    """Convert timestamp to human readable 'time ago' format using Pixlet's built-in time functions"""

    if not timestamp_str:
        return "Unknown time"

    # Clean up the timestamp using helper function
    clean_timestamp_result = clean_timestamp(timestamp_str)
    if not clean_timestamp_result:
        return "Recently"

    # Parse the timestamp - Pixlet uses Go's reference time format
    sighting_time = time.parse_time(clean_timestamp_result, format = "2006-01-02T15:04:05Z")
    if not sighting_time:
        return "Recently"

    current_time = time.now()

    # Calculate time difference in seconds
    diff_seconds = current_time.unix - sighting_time.unix

    if diff_seconds < 60:
        return "Just now"
    elif diff_seconds < 3600:  # Less than 1 hour
        minutes = int(diff_seconds / 60)
        if minutes == 1:
            return "1 minute ago"
        else:
            return "{} minutes ago".format(minutes)
    elif diff_seconds < 86400:  # Less than 1 day
        hours = int(diff_seconds / 3600)
        if hours == 1:
            return "1 hour ago"
        else:
            return "{} hours ago".format(hours)
    elif diff_seconds < 604800:  # Less than 1 week
        days = int(diff_seconds / 86400)
        if days == 1:
            return "Yesterday"
        else:
            return "{} days ago".format(days)
    else:
        # For older sightings, just show the date
        formatted = time.format_time(sighting_time, format = "Jan 2")
        if formatted:
            return formatted
        else:
            return "Long ago"

def get_timestamp_color(timestamp_str):
    """Calculate color based on how recent the sighting is - decays from green to gray"""

    if not timestamp_str:
        return "#CCCCCC"  # Gray for unknown time

    # Clean up the timestamp using helper function
    clean_timestamp_result = clean_timestamp(timestamp_str)
    if not clean_timestamp_result:
        return "#CCCCCC"  # Gray for invalid timestamp

    sighting_time = time.parse_time(clean_timestamp_result, format = "2006-01-02T15:04:05Z")
    if not sighting_time:
        return "#CCCCCC"  # Gray for unparseable time

    current_time = time.now()
    diff_seconds = current_time.unix - sighting_time.unix

    # Color decay over 24 hours (86400 seconds)
    # 0-15 minutes (900 seconds): Full green #00cc66
    # 15 minutes - 24 hours: Decay to gray #CCCCCC

    if diff_seconds <= 900:  # 15 minutes or less - full green
        return "#00CC66"
    elif diff_seconds >= 86400:  # 24 hours or more - full gray
        return "#CCCCCC"
    else:
        # Linear interpolation between green and gray
        # Green: R=0, G=204, B=102
        # Gray:  R=204, G=204, B=204

        # Calculate progress from 15 minutes to 24 hours
        progress = (diff_seconds - 900) / (86400 - 900)  # 0.0 to 1.0

        # Interpolate each color component
        red = int(0 + (204 * progress))  # Red goes from 0 to 204
        green = 204  # Green stays constant at 204
        blue = int(102 + (102 * progress))  # Blue goes from 102 to 204

        # Format as hex color (manual hex conversion for Starlark compatibility)
        hex_chars = "0123456789ABCDEF"
        red_hex = hex_chars[red // 16] + hex_chars[red % 16]
        green_hex = hex_chars[green // 16] + hex_chars[green % 16]
        blue_hex = hex_chars[blue // 16] + hex_chars[blue % 16]
        return "#" + red_hex + green_hex + blue_hex

def render_bird_display(sighting):
    """Render the main bird display"""

    bird_name = sighting["bird_name"]
    timestamp_str = sighting["timestamp"]
    icon_url = sighting.get("icon_url", "")

    # Format timestamp for display - use humanized time
    time_display = humanize_time_ago(timestamp_str)

    # Calculate timestamp color based on recency - decays from green to gray over 24 hours
    timestamp_color = get_timestamp_color(timestamp_str)

    # Create bird display with proper error handling for image fetching
    bird_image_data = None

    # Try to fetch the bird-specific icon first
    if icon_url:
        icon_response = http.get(icon_url)
        if icon_response.status_code == 200 and icon_response.body():
            bird_image_data = icon_response.body()

    # If primary icon failed, use the embedded finch icon (no HTTP request needed)
    if not bird_image_data:
        bird_image_data = DEFAULT_FINCH_ICON

    # Create bird display - use image if we got valid data, otherwise use text fallback
    if bird_image_data:
        bird_display = render.Image(
            src = bird_image_data,
            height = BIRD_ICON_SIZE,
        )
    else:
        # Final fallback to text if all image fetches fail
        bird_display = render.Text(
            content = "🐦",
            font = "6x13",
            color = "#FFFFFF",
        )

    # Create children list for the main row
    row_children = [
        # Bird icon/emoji column
        render.Column(
            children = [
                render.Box(
                    width = BIRD_ICON_SIZE,
                    height = BIRD_ICON_SIZE,
                    child = bird_display,
                ),
            ],
        ),
        # Text information column - use remaining space after bird icon
        render.Box(
            width = TEXT_AREA_WIDTH,  # Maximum remaining space (64 - 32 = 32)
            height = BIRD_ICON_SIZE,
            child = render.Column(
                main_align = "space_around",
                cross_align = "start",
                children = [
                    render.Marquee(
                        width = TEXT_AREA_WIDTH,
                        delay = MARQUEE_DELAY,  # 32 frame delay before scrolling starts
                        child = render.Text(
                            content = bird_name,
                            font = "tom-thumb",
                            color = "#FFFFFF",
                        ),
                    ),
                    render.Marquee(
                        width = TEXT_AREA_WIDTH,
                        delay = MARQUEE_DELAY,  # 32 frame delay before scrolling starts
                        child = render.Text(
                            content = time_display,
                            font = "tom-thumb",
                            color = timestamp_color,
                        ),
                    ),
                ],
            ),
        ),
    ]

    return render.Root(
        child = render.Stack(
            children = [
                # Main content
                render.Row(
                    main_align = "start",
                    children = row_children,
                ),
            ],
        ),
    )

def render_error(message):
    """Render an error message"""
    return render.Root(
        child = render.Column(
            main_align = "center",
            cross_align = "center",
            children = [
                render.Text(
                    content = "Bird Buddy",
                    font = "tom-thumb",
                    color = "#CCCCCC",
                ),
                render.Box(height = 2),
                render.WrappedText(
                    content = message,
                    font = "tom-thumb",
                    color = "#FF6666",
                    align = "center",
                    width = 64,
                ),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "username",
                name = "Bird Buddy Email",
                desc = "Enter your Bird Buddy account email address",
                icon = "user",
            ),
            schema.Text(
                id = "password",
                name = "Bird Buddy Password",
                desc = "Enter your Bird Buddy account password",
                icon = "lock",
                secret = True,
            ),
        ],
    )
