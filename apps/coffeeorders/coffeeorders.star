"""
Applet: Coffee
Summary: Displays Coffee Orders
Description: Displays Coffee Orders with explanations.
Author: Robert Ison
"""

load("http.star", "http")
load("images/coffee_cup_image.png", COFFEE_CUP_IMAGE_ASSET = "file")
load("images/default_coffee_image.jpg", DEFAULT_COFFEE_IMAGE_ASSET = "file")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

COFFEE_CUP_IMAGE = COFFEE_CUP_IMAGE_ASSET.readall()
DEFAULT_COFFEE_IMAGE = DEFAULT_COFFEE_IMAGE_ASSET.readall()

COFFEE_IMAGE_CACHE_TIME = 600  #10 Minutes
COFFEE_IMAGE_URL = "https://coffee.alexflipnote.dev/random.json"
COFFEE_DATA = [
    {
        "Coffee Drink": "Espresso",
        "Description": "A strong, concentrated coffee",
        "Ingredients": "Single or double shot of espresso",
        "Proportions": "1 shot (single) or 2 shots (double) espresso",
    },
    {
        "Coffee Drink": "Cappuccino",
        "Description": "Creamy and frothy, strong coffee flavor",
        "Ingredients": "1/3 espresso, 1/3 steamed milk, 1/3 milk foam",
        "Proportions": "1 shot espresso, equal parts steamed milk and milk foam",
    },
    {
        "Coffee Drink": "Flat White",
        "Description": "Smooth and velvety",
        "Ingredients": "Espresso, steamed milk (with little foam)",
        "Proportions": "1 shot espresso, 2/3 steamed milk, little foam",
    },
    {
        "Coffee Drink": "Latte",
        "Description": "Mild and creamy",
        "Ingredients": "Espresso, steamed milk, light milk foam",
        "Proportions": "1 shot espresso, 2/3 steamed milk, light milk foam",
    },
    {
        "Coffee Drink": "Americano",
        "Description": "Diluted espresso",
        "Ingredients": "Espresso, hot water",
        "Proportions": "1 shot espresso, 2/3 hot water",
    },
    {
        "Coffee Drink": "Macchiato",
        "Description": "Espresso with a dash of milk foam",
        "Ingredients": "Espresso, small amount of milk foam",
        "Proportions": "1 shot espresso, a dash of milk foam",
    },
    {
        "Coffee Drink": "Mocha",
        "Description": "Chocolate-flavored coffee",
        "Ingredients": "Espresso, steamed milk, chocolate syrup, whipped cream (optional)",
        "Proportions": "1 shot espresso, 2/3 steamed milk, 1-2 tablespoons chocolate syrup",
    },
    {
        "Coffee Drink": "Affogato",
        "Description": "Dessert-like coffee treat",
        "Ingredients": "Espresso, ice cream",
        "Proportions": "1 shot espresso, 1 scoop of ice cream",
    },
    {
        "Coffee Drink": "Café au Lait",
        "Description": "Classic French coffee drink",
        "Ingredients": "Brewed coffee, steamed milk",
        "Proportions": "1/2 brewed coffee, 1/2 steamed milk",
    },
    {
        "Coffee Drink": "Café Con Leche",
        "Description": "Spanish coffee with milk",
        "Ingredients": "Strong coffee or espresso, steamed milk",
        "Proportions": "1 shot espresso or strong coffee, 1/2 steamed milk",
    },
    {
        "Coffee Drink": "Coffee Nudge",
        "Description": "A warm coffee cocktail",
        "Ingredients": "Coffee, dark crème de cacao, brandy, whipped cream",
        "Proportions": "1 cup coffee, 1 oz dark crème de cacao, 1 oz brandy, whipped cream on top",
    },
    {
        "Coffee Drink": "Mochaccino",
        "Description": "A blend of cappuccino and mocha",
        "Ingredients": "Espresso, steamed milk, chocolate syrup, milk foam",
        "Proportions": "1 shot espresso, 1/2 steamed milk, 1-2 tablespoons chocolate syrup, milk foam on top",
    },
    {
        "Coffee Drink": "Cortado",
        "Description": "Espresso cut with a small amount of warm milk",
        "Ingredients": "Espresso, warm milk",
        "Proportions": "1 shot espresso, 1 shot warm milk",
    },
    {
        "Coffee Drink": "Breve",
        "Description": "Rich and creamy, made with half-and-half",
        "Ingredients": "Espresso, steamed half-and-half",
        "Proportions": "1 shot espresso, equal parts steamed half-and-half",
    },
    {
        "Coffee Drink": "Mocha Breve",
        "Description": "A rich mocha made with half-and-half",
        "Ingredients": "Espresso, steamed half-and-half, chocolate syrup",
        "Proportions": "1 shot espresso, 2/3 steamed half-and-half, 1-2 tablespoons chocolate syrup",
    },
    {
        "Coffee Drink": "Café Noisette",
        "Description": "French espresso with a hint of milk",
        "Ingredients": "Espresso, a dash of hot milk",
        "Proportions": "1 shot espresso, a dash of hot milk",
    },
    {
        "Coffee Drink": "Lungo",
        "Description": "A 'long' espresso with more water",
        "Ingredients": "Espresso, more water",
        "Proportions": "1 shot espresso, double the amount of water",
    },
    {
        "Coffee Drink": "Viennois",
        "Description": "Espresso topped with whipped cream",
        "Ingredients": "Espresso, whipped cream",
        "Proportions": "1 shot espresso, topped with whipped cream",
    },
    {
        "Coffee Drink": "Con Panna",
        "Description": "Espresso with whipped cream",
        "Ingredients": "Espresso, whipped cream",
        "Proportions": "1 shot espresso, a dollop of whipped cream",
    },
]

COFFEE_PALETTE = {"Espresso": "#4B2E22", "Coffee Bean": "#6F4E37", "Latte": "#D3B499", "Cream": "#FFF5E1", "Mocha": "#3B2F2F", "Caramel": "#C68E51", "Warm Cinnamon": "#D2691E", "Foam White": "#FFFFF0"}
COFFEE_FONT = "tb-8"

def main(config):
    # this contains the display elements
    children = []

    # either display a random image, or a coffee recipe
    if config.get("display_type") == "image":
        children.append(get_coffee_image())
    else:
        # get the coffees they selected in the pick list
        selected_coffees = get_selected_coffees(config)

        # if they didn't pick anything, we'll pick from the full list
        if (len(selected_coffees) == 0):
            selected_coffees = COFFEE_DATA

        #Recipe Display
        random_coffee_id = random.number(0, len(selected_coffees) - 1)
        children.append(add_padding_to_child_element(render.Image(src = COFFEE_CUP_IMAGE, width = 20), -3))
        children.append(add_padding_to_child_element(render.Marquee(width = 44, child = render.Text(content = selected_coffees[random_coffee_id]["Coffee Drink"], color = COFFEE_PALETTE["Cream"], font = COFFEE_FONT)), 16))
        children.append(add_padding_to_child_element(render.Marquee(width = 64, child = render.Text(content = selected_coffees[random_coffee_id]["Description"], color = COFFEE_PALETTE["Warm Cinnamon"], font = COFFEE_FONT)), 0, 14))
        children.append(add_padding_to_child_element(render.Marquee(width = 64, offset_end = 64, offset_start = (4 * (len(selected_coffees[random_coffee_id]["Description"]))), child = render.Text(content = selected_coffees[random_coffee_id]["Proportions"], color = COFFEE_PALETTE["Caramel"], font = COFFEE_FONT)), 0, 23))

    return render.Root(
        render.Stack(
            children = children,
        ),
        show_full_animation = True,
        delay = int(config.get("scroll", 45)),
    )

def get_selected_coffees(config):
    selected_coffees = []

    for coffee in COFFEE_DATA:
        if (config.bool(coffee["Coffee Drink"]) == True):
            selected_coffees.append(coffee)

    return selected_coffees

def get_coffee_image():
    rep = http.get(
        COFFEE_IMAGE_URL,
        headers = {"User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.6 Safari/605.1.1", "Accept": "text/html,application/xhtml+xml,application/xml"},
    )

    if rep.status_code == 200 and rep.json():
        artwork = http.get(rep.json()["file"], ttl_seconds = COFFEE_IMAGE_CACHE_TIME).body()
        artwork_image = render.Image(src = artwork, width = 64, height = 32)
    else:
        artwork_image = render.Image(src = DEFAULT_COFFEE_IMAGE, width = 64, height = 32)

    return artwork_image

def add_padding_to_child_element(element, left = 0, top = 0, right = 0, bottom = 0):
    padded_element = render.Padding(
        pad = (left, top, right, bottom),
        child = element,
    )

    return padded_element

def get_schema():
    scroll_speed_options = [
        schema.Option(
            display = "Slow Scroll",
            value = "60",
        ),
        schema.Option(
            display = "Medium Scroll",
            value = "45",
        ),
        schema.Option(
            display = "Fast Scroll",
            value = "30",
        ),
    ]

    display_type = [
        schema.Option(display = "Display Random Coffee Image", value = "image"),
        schema.Option(display = "Display Random Coffee Order", value = "order"),
    ]

    def get_coffees(type):
        # default
        items = sorted(COFFEE_DATA, key = lambda x: x["Coffee Drink"])
        icon = "mugHot"

        if type == "order":
            return [
                schema.Toggle(id = item["Coffee Drink"], name = item["Coffee Drink"], desc = item["Description"], icon = icon, default = False)
                for item in items
            ]
        else:
            return []

    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "scroll",
                name = "Scroll",
                desc = "Scroll Speed",
                icon = "scroll",
                options = scroll_speed_options,
                default = scroll_speed_options[0].value,
            ),
            schema.Dropdown(
                id = "display_type",
                icon = "tv",
                name = "What to display",
                desc = "What do you want this to display?",
                options = display_type,
                default = display_type[1].value,
            ),
            schema.Generated(
                id = "coffee_types",
                source = "display_type",
                handler = get_coffees,
            ),
        ],
    )
