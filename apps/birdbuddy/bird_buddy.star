"""
Applet: Bird Buddy
Summary: Whose visiting your feeder
Description: See your latest Bird Buddy feeder visitors.
Author: Brombomb
"""

load("cache.star", "cache")
load("http.star", "http")
load("images/default_finch_icon.webp", DEFAULT_FINCH_ICON_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_FINCH_ICON = DEFAULT_FINCH_ICON_ASSET.readall()

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
    if feeders == None:
        print("Token expired or auth error. Re-authenticating...")
        token = get_auth_token(username, password, force_refresh = True)
        if not token:
            return render_error("Authentication failed.\nCheck credentials")
        feeders = get_feeders(token)

    if not feeders:
        return []

    # Get the latest bird sighting
    latest_sighting = get_latest_sighting(token, feeders)

    # Only render if there was a sighting
    timestamp = latest_sighting.get("timestamp")
    if not timestamp:
        return []

    clean_ts = clean_timestamp(timestamp)
    if not clean_ts:
        return []

    sighting_time = time.parse_time(clean_ts, format = "2006-01-02T15:04:05Z")
    if not sighting_time:
        return []

    now = time.now()
    diff_seconds = now.unix - sighting_time.unix
    if diff_seconds > 3600:  # older than 1 hour
        return []

    # Inject random bird icon for mystery visitors
    if latest_sighting.get("bird_name") == "Mystery Visitor" and not latest_sighting.get("icon_url"):
        print("Mystery visitor found! Fetching random avatar from the full Bird Buddy catalog...")
        random_species = get_random_collection_species(token)
        if random_species and random_species.get("iconUrl"):
            print("Selected random avatar: {}".format(random_species.get("name", "Unknown")))
            latest_sighting["icon_url"] = random_species["iconUrl"]

    return render_bird_display(latest_sighting)

def get_auth_token(username, password, force_refresh = False):
    """Authenticate with Bird Buddy API and get access token"""

    cache_key = "bb_token_{}".format(username)
    cached_token = None if force_refresh else cache.get(cache_key)

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

    # Check for GraphQL errors first
    is_auth_error = False
    if feeders_response and "errors" in feeders_response:
        errors = feeders_response.get("errors", [])
        for error in errors:
            err_msg = error.get("message", "")
            err_code = error.get("extensions", {}).get("code", "")
            print("GraphQL Feeders Error: {}".format(err_msg or err_code))
            if err_msg == "AUTH_TOKEN_EXPIRED_ERROR" or err_code == "AUTH_TOKEN_EXPIRED_ERROR" or "auth" in err_msg.lower() or "token" in err_msg.lower():
                is_auth_error = True

    if is_auth_error:
        return None

    if "data" in feeders_response:
        data = feeders_response.get("data") or {}
        me_data = data.get("me") or {}
        if me_data:
            feeders_data = me_data.get("feeders", [])
            return feeders_data
        else:
            print("No 'me' data in response. Response: {}".format(feeders_response))
            return []
    else:
        print("Failed to parse feeders response. Response: {}".format(feeders_response))
        return []

def get_latest_sighting(token, feeders, ttl_seconds = CACHE_TTL):
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
                                    inferenceExecutionMode
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
        ttl_seconds = ttl_seconds,
    )

    if response.status_code == 200:
        feed_response = response.json()
        if not feed_response:
            print("Failed to parse feed JSON response")
        elif "data" in feed_response:
            data = feed_response.get("data") or {}
            me_data = data.get("me") or {}
            if me_data and "feed" in me_data:
                feed = me_data.get("feed") or {}
                feed_edges = feed.get("edges") or []
                if feed_edges:
                    # Look for the most recent BIRD-related feed item only
                    for edge in feed_edges:
                        node = edge.get("node", {})
                        node_type = node.get("__typename", "")

                        # Only include actual bird sighting items, not setup/admin items
                        if node_type in VALID_BIRD_NODE_TYPES:
                            parsed_result = parse_feed_item(node)
                            print("Parsed feed item: type={}, bird={}, ts={}".format(node_type, parsed_result.get("bird_name"), parsed_result.get("timestamp")))
                            if parsed_result:  # Only return if we got actual data
                                # Check if this is a postcard that needs bird detail lookup
                                if "postcard_id" in parsed_result:
                                    postcard_id = parsed_result["postcard_id"]
                                    raw_data = parsed_result.get("raw_data", {})
                                    execution_mode = raw_data.get("inferenceExecutionMode", "")
                                    if execution_mode == "MANUAL_NOT_STARTED":
                                        print("Postcard execution mode is MANUAL_NOT_STARTED. Triggering AI reanalysis...")
                                        reanalyze_postcard(token, postcard_id)

                                    sighting_result = get_postcard_sighting(token, postcard_id)
                                    if sighting_result:
                                        # Use the postcard timestamp but bird name from sighting
                                        sighting_result["timestamp"] = parsed_result["timestamp"]
                                        print("Successfully claimed postcard: {}".format(sighting_result))
                                        return sighting_result
                                    elif ttl_seconds > 0:
                                        # If claiming the cached postcard failed, re-fetch feed with no cache
                                        print("Postcard claim failed (likely already collected). Re-fetching fresh feed...")
                                        return get_latest_sighting(token, feeders, ttl_seconds = 0)
                                    else:
                                        # Skip this failed postcard and try the next feed item
                                        print("Skipping failed postcard, trying next feed item...")
                                        continue
                                else:
                                    print("Returning valid sighting from feed: {}".format(parsed_result))
                                    return parsed_result
                        else:
                            print("Skipping non-bird feed item type: {}".format(node_type))
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
    print("Feed check complete, falling back to collections query...")
    return get_from_collections(token)

def reanalyze_postcard(token, postcard_id):
    """Trigger the AI identification (reanalysis) for a postcard"""

    reanalyze_mutation = {
        "query": """
            mutation ReanalyzePostcard($feedItemId: ID!) {
                inferenceExternalPostcardReanalyze(feedItemId: $feedItemId) {
                    updatedFeedItem {
                        __typename
                        ... on FeedItemNewPostcard {
                            id
                            inferenceExecutionMode
                        }
                    }
                }
            }
        """,
        "variables": {
            "feedItemId": postcard_id,
        },
    }

    headers = {
        "Authorization": "Bearer {}".format(token),
        "Content-Type": "application/json",
    }

    response = http.post(
        url = BIRD_BUDDY_GRAPHQL_URL,
        json_body = reanalyze_mutation,
        headers = headers,
        ttl_seconds = 0,
    )

    if response.status_code != 200:
        print("Postcard reanalyze request failed: {}".format(response.status_code))
        return False

    reanalyze_response = response.json()
    if not reanalyze_response:
        print("Failed to parse reanalyze JSON response")
        return False

    if "errors" in reanalyze_response:
        errors = reanalyze_response.get("errors", [])
        for error in errors:
            print("Postcard reanalyze error: {}".format(error.get("message", "Unknown error")))
        return False

    data = reanalyze_response.get("data")
    if not data or "inferenceExternalPostcardReanalyze" not in data:
        return False

    reanalyze_result = data.get("inferenceExternalPostcardReanalyze") or {}
    updated_item = reanalyze_result.get("updatedFeedItem") or {}
    new_mode = updated_item.get("inferenceExecutionMode")
    print("Postcard reanalyzed. New mode: {}".format(new_mode))

    return True

def get_postcard_sighting(token, postcard_id):
    """Convert a postcard to sighting, identify the visitor if needed, finish/collect the postcard, and return details"""

    # Based on POSTCARD_TO_SIGHTING mutation from PyBirdBuddy
    # Now retrieves reportToken, matchTokens, and suggestions for undecided sightings
    postcard_mutation = {
        "query": """
            mutation sightingCreateFromPostcard($sightingCreateFromPostcardInput: SightingCreateFromPostcardInput!) {
                sightingCreateFromPostcard(sightingCreateFromPostcardInput: $sightingCreateFromPostcardInput) {
                    ... on SightingCreateFromPostcardResult {
                        sightingReport {
                            reportToken
                            sightings {
                                ... on SightingRecognizedBird {
                                    id
                                    color
                                    text
                                    count
                                    matchTokens
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
                                    matchTokens
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
                                    matchTokens
                                    __typename
                                }
                                ... on SightingCantDecideWhichBird {
                                    id
                                    matchTokens
                                    suggestions {
                                        species {
                                            ... on SpeciesBird {
                                                id
                                                name
                                                iconUrl
                                            }
                                        }
                                        __typename
                                    }
                                    __typename
                                }
                                __typename
                            }
                            __typename
                        }
                        videoMedia {
                            id
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

    if response.status_code != 200:
        print("Postcard sighting request failed: {}".format(response.status_code))
        return None

    sighting_response = response.json()
    if not sighting_response:
        print("Failed to parse sighting JSON response")
        return None

    if "errors" in sighting_response:
        errors = sighting_response.get("errors", [])
        for error in errors:
            print("Postcard sighting error: {} (postcard may already be collected)".format(error.get("message", "Unknown error")))
        return None

    data = sighting_response.get("data") or {}
    if not data or "sightingCreateFromPostcard" not in data:
        return None

    create_data = data.get("sightingCreateFromPostcard")
    if not create_data or "sightingReport" not in create_data:
        return None

    sighting_report = create_data.get("sightingReport")
    if not sighting_report:
        return None

    sightings = sighting_report.get("sightings", [])
    report_token = sighting_report.get("reportToken", "")

    # Process each sighting to resolve identification if undecided
    updated_sightings = []
    final_report_token = report_token

    for sighting in sightings:
        sighting_type = sighting.get("__typename", "")
        if sighting_type == "SightingCantDecideWhichBird":
            suggestions = sighting.get("suggestions", [])
            chosen_species_id = None
            if suggestions:
                first_suggestion = suggestions[0]
                species = first_suggestion.get("species", {})
                chosen_species_id = species.get("id")

            if chosen_species_id:
                # Identify as best guess species
                print("Undecided visitor. Identifying as best guess species ID: {}".format(chosen_species_id))
                choose_mutation = {
                    "query": """
                        mutation sightingChooseSpecies($sightingChooseSpeciesInput: SightingChooseSpeciesInput!) {
                            sightingChooseSpecies(sightingChooseSpeciesInput: $sightingChooseSpeciesInput) {
                                reportToken
                                sightings {
                                    ... on SightingRecognizedBird {
                                        id
                                        color
                                        text
                                        count
                                        matchTokens
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
                                        matchTokens
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
                                        matchTokens
                                        __typename
                                    }
                                    __typename
                                }
                                __typename
                            }
                        }
                    """,
                    "variables": {
                        "sightingChooseSpeciesInput": {
                            "sightingId": sighting.get("id"),
                            "speciesId": chosen_species_id,
                            "reportToken": final_report_token,
                        },
                    },
                }
                choose_resp = http.post(
                    url = BIRD_BUDDY_GRAPHQL_URL,
                    json_body = choose_mutation,
                    headers = headers,
                    ttl_seconds = 60,
                )
                if choose_resp.status_code == 200:
                    choose_json = choose_resp.json()
                    if choose_json and "data" in choose_json:
                        choose_data = choose_json.get("data", {}).get("sightingChooseSpecies", {})
                        if choose_data:
                            final_report_token = choose_data.get("reportToken", final_report_token)
                            updated_sightings = choose_data.get("sightings", [])
                else:
                    print("sightingChooseSpecies mutation failed: {}".format(choose_resp.status_code))
            else:
                # Convert to mystery visitor
                print("Undecided visitor with no suggestions. Converting to Mystery Visitor.")
                mystery_mutation = {
                    "query": """
                        mutation sightingConvertToMysteryVisitor($sightingConvertToMysteryVisitorInput: SightingConvertToMysteryVisitorInput!) {
                            sightingConvertToMysteryVisitor(sightingConvertToMysteryVisitorInput: $sightingConvertToMysteryVisitorInput) {
                                reportToken
                                sightings {
                                    ... on SightingRecognizedMysteryVisitor {
                                        id
                                        color
                                        text
                                        count
                                        matchTokens
                                        __typename
                                    }
                                    __typename
                                }
                                __typename
                            }
                        }
                    """,
                    "variables": {
                        "sightingConvertToMysteryVisitorInput": {
                            "sightingId": sighting.get("id"),
                            "reportToken": final_report_token,
                        },
                    },
                }
                mystery_resp = http.post(
                    url = BIRD_BUDDY_GRAPHQL_URL,
                    json_body = mystery_mutation,
                    headers = headers,
                    ttl_seconds = 60,
                )
                if mystery_resp.status_code == 200:
                    mystery_json = mystery_resp.json()
                    if mystery_json and "data" in mystery_json:
                        mystery_data = mystery_json.get("data", {}).get("sightingConvertToMysteryVisitor", {})
                        if mystery_data:
                            final_report_token = mystery_data.get("reportToken", final_report_token)
                            updated_sightings = mystery_data.get("sightings", [])
                else:
                    print("sightingConvertToMysteryVisitor mutation failed: {}".format(mystery_resp.status_code))
        else:
            updated_sightings.append(sighting)

    if not updated_sightings:
        updated_sightings = sightings

    # Skipping sightingReportPostcardFinish to leave postcards uncollected in user's Bird Buddy app
    print("Skipping auto-collection of postcard {} as requested".format(postcard_id))

    # Return the first finalized sighting details
    if updated_sightings:
        sighting = updated_sightings[0]
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
            else:
                return None
        elif sighting_type == "SightingRecognizedMysteryVisitor":
            return {
                "bird_name": "Mystery Visitor",
                "timestamp": "",
                "icon_url": "",
                "raw_data": sighting,
            }
        else:
            return None
    else:
        return None

def fetch_bird_collections(token):
    """Fetch bird collections using GraphQL"""
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

    print("Fetching collections...")
    if response.status_code == 200:
        collections_response = response.json()
        if not collections_response:
            print("Failed to parse collections JSON response")
            return []

        if "data" in collections_response:
            data = collections_response.get("data") or {}
            me_data = data.get("me") or {}
            if me_data and "collections" in me_data:
                collections = me_data.get("collections") or []
                print("Found {} collections items".format(len(collections)))

                if collections:
                    bird_collections = []
                    for collection in collections:
                        if collection.get("__typename") == "CollectionBird":
                            bird_collections.append(collection)

                    print("Found {} bird collections".format(len(bird_collections)))
                    return bird_collections
            else:
                print("No me/collections in response data: {}".format(collections_response))
        elif collections_response and "errors" in collections_response:
            errors = collections_response.get("errors") or []
            for error in errors:
                print("GraphQL Collections Error: {}".format(error.get("message", "Unknown error")))
    else:
        print("Collections request failed: {}".format(response.status_code))
        print("Collections response body: {}".format(response.body()))

    return []

def get_from_collections(token):
    """Get latest bird data from collections"""
    bird_collections = fetch_bird_collections(token)

    if bird_collections:
        # Sort by visitLastTime (most recent first)
        def get_visit_time(collection):
            return collection.get("visitLastTime", "1970-01-01T00:00:00Z")

        bird_collections.sort(key = get_visit_time, reverse = True)

        latest_collection = bird_collections[0]
        species = latest_collection.get("species") or {}
        bird_name = species.get("name", "Unknown Bird")
        visit_time = latest_collection.get("visitLastTime", "")
        icon_url = species.get("iconUrl", "")

        result = {
            "bird_name": bird_name,
            "timestamp": visit_time,
            "icon_url": icon_url,
            "raw_data": latest_collection,
        }
        print("Returning collections sighting: {}".format(result))
        return result

    print("No valid collections found, returning default empty sighting")
    return create_default_sighting()

def get_random_collection_species(token):
    """Get a random bird species from the full Bird Buddy catalog"""
    bird_collections = fetch_bird_collections(token)

    if bird_collections:
        # Get pseudo-random index based on current nanosecond
        idx = time.now().unix % len(bird_collections)
        return bird_collections[idx].get("species") or {}
    return {}

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
        # This should have actual bird species data (which is a list in GraphQL)
        species_list = feed_node.get("species") or []
        if species_list:
            species = species_list[0]
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

    # Color decay over 1 hour (3600 seconds)
    if diff_seconds >= 3600:  # 1 hour or more - full gray
        return "#CCCCCC"
    else:
        # Linear interpolation between green and gray
        # Green: R=0, G=204, B=102
        # Gray:  R=204, G=204, B=204

        # Calculate progress from 0 minutes to 1 hour
        progress = (diff_seconds) / (3600)  # 0.0 to 1.0

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
