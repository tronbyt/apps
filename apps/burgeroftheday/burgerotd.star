"""
Applet: Burger of the Day
Summary: Shows Burger of the Day
Description: Display the set Burger of the Day, show a random burger every time, or enter your own custom burger. Burgers courtesy of Bob's Burgers. Use the Show logo and Scroll speed options to fit your Tidbyt.
Author: Kyle Stark @kaisle51
Thanks: @whyamihere @dinotash @inxi @J.R. @Milx
"""

load("encoding/json.star", "json")
load("images/bobs_logo.png", BOBS_LOGO_ASSET = "file")
load("images/burger_text.png", BURGER_TEXT_ASSET = "file")
load("math.star", "math")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

BOBS_LOGO = BOBS_LOGO_ASSET.readall()
BURGER_TEXT = BURGER_TEXT_ASSET.readall()

#64 x 19

#insert image base64 in empty line below
#64 x 21

BURGER_LIST = ['"New bacon-ings"', "Never Been Feta", "Foot Feta-ish Burger", "The Life of the Parsley Burger", "Sweet Chili O' Mine Burger", "Itsy Bitsy Teeny Weenie Yellow Polka-Dot Zucchini Burger", "Hit Me With Your Best Shallot Burger", "Focaccia red handed burger", "So Many Fennel So Little Thyme Burger", "THE FINDERS CAPERS BURGER", "Emergency Eggs-it Burger", "Sweet Home Avocado Burger", "The stayin' a chive burger", "Let's Give 'em Something Shiitake 'bout Burger", "Chile Relleno- You-Didn't Burger", "Pear Goes the Neighborhood", "Salvador Cauliflower Burger", "Fig Lebowski Burger", "Cole came, cole slaw, cole conquered Burger", "Breaking Radish Burger", "Captain Pepper Jack Marrow Burger", "Little Swiss Bunshine Burger", "Take A Leek Burger", "The ber-gouda triangle burger", "The little sprouts on the prairie burger", "She's a Super Leek Burger", "Use It Or Bleus It Burger", "THE HICKORY CHICORY GUAC BURGER", "Chorizo Your Own Adventure Burger", "Chard To A Crisp Burger", "THE SEALED WITH A SWISS BURGER", "Topless the Morning To You Burger", "50 Ways to Leave Your Guava Burger", "THE I LOVE YOU JUST THE WHEY YOU ARE BURGER", "The eggplant one on me burger", "Every Breath You Tikka Masala Burger", "Nothing Compares 2 Bleu (Cheese) Burger", "The Here I Am Broccoli Like a Hurricane Burger", "Better cauliflower saul burger", "Don't Go Brocking My Heart Burger", "I Heartichoke You Burger", "The Shut Up and Swiss Me Burger", "A Good Manchego is Hard to Find Burger", "MY BLOODY KALE-ENTINE BURGER", "Be My Valen-thyme Burger", "THE I HATE TO SEE YOU BRIE-VE BUT I LOVE TO WATCH YOU GO BURGER", "Step up 2: the beets burger", "Girls Just Wanna Have Fennel Burger", "Don't You Four Cheddar 'Bout Me Burger", "The Don't Get Creme Fraiche With Me Burger", "Curry On My Wayward Bun Burger", "Nice guys spinach last burger", "The marvelous mrs. basil burger", "Parme- jean-claude van hamburger", "Bruschetta Bout It Burger", "Tarragon in Sixty Seconds Burger", "Poutine on the Ritz Burger", "The Oh Con-Pear Burger", "Say It Ain't Cilantro Burger", "Chevre Which Way But Loose Burger", "THE TWO LEFT BEET BURGER", "The Older with More Eggs- perience Burger", "Eggers Can't Be Cheesers Burger", "Edamame Dearest Burger", "Pickle My Funny Bone Burger", "The I'm Getting Too Old For This Shishito Burger", "Burger A La Mode", "Open Sesame Burger", "THE FIGGY SMALLS BURGER", "A wrinkle in thyme burger", "Chipotle Off the Old Block Burger", "Don't Give Me No Chive Burger", "Frisee It, Don't Spray It Burger", "Turn the Other Leek Burger", "Where Have You Bean All My Life Burger", "The into thin heirloom burger", "The happy paint patty's day burger", "I Mint to Do That Burger", "Totally Radish Burger", "Mushroom With A View Burger", "It's Only Sourdough Burger", "Cajun Gracefully Burger", "The Hand That Rocks the Bagel Burger", "Olive And Let Die Burger", "Wasabi My Guest Burger", "THE COLBY BY YOUR NAME BURGER", "The creme fraiche prince of bell peppers burger", "The Garden of E-dumb Burger", "What's The Worce- stershire That Could Happen Burger", "To Err Is Cumin Burger", "The you can lead a horseradish to watercress burger", "Take Me Out To The Burger", "National Pass-Thyme Burger", "A Leek of Their Own Burger", "Put Me in Poached Burger", "Fig-eta Bout It Burger", "Pepper Don't Preach Burger", "Creminis and Misdemeanies Burger", "Poblano Picasso Burger", "Enoki Dokie Burger", "MediterrAin't Misbehavin' Burger", "Sharp Cheddar Dressed Man BURGER", "Barley Davidson Burger", "The green a little bean of me burger", "Sprouts! Sprouts! Sprouts It All Out! Burger", "Snipwrecked Burger", "THE DILL CRAZY AFTER ALL THESE GRUYERES BURGER", "The Choys are Bok in Town Burger", "Papaya Was A Rolling Stone Burger", "These Collards Don't Run Burger", "Do the Brussel Burger", "Onion Ring Around the Rosemary Burger", "The oaxaca waka waka burger", "Parma Parma Parma Chameleon Burger", "The mo, larry, and curry burger", "Curd-fect Strangers Burger", "Peas and Thank You Burger", "THE WHAT IF PEAPOD WAS ONE OF US BURGER", "Knife to Beet You Burger", "Is This Your Chard Burger", "The Glass Fromagerie Burger", "Citizen Kale Burger", "The should I sautee or should i mango burger", "Total Eclipse of the Havarti Burger", "Shoestring Around the Rosey Burger", "Mission A-Corn- Plished Burger", "Scent of a Cumin Burger", "Baby got bak choy burger", "The Grand Brie Burger", "Parm-pit Burger", "If You've Got It, Croissant It Burger", "Last of the Mo-Jicama Burger", "Endive Had the Time of My Life Burger", "Not If I Can Kelp It Burger", "The mama said there'd be glaze like this burger", "Sit and Spinach Burger", "All In A Glaze Work Burger", "Weekend at Bearnaise Burger", "I Know Why the Cajun Burger Sings", "The Stop or My Mom Will Shoots Burger", "Thank God It's Fried Egg Burger", "The Sun'll Come Out To-Marrow Burger", "If Looks Could Kale Burger", "If At First You Sesame Seed, Thai, Thai, Again Burger", "The Saffron Saff-off Burger", "Gourdon- Hamsey Burger", "Sympathy for the Deviled Egg Burger", "Onion-tended Consequences Burger", "The rye of the storm burger", "Who Wants To Be A Scallionaire Burger?", "The bustle and flow burger", "Bet it all on black garlic burger", "Teriyaki a New One Burger", "THE CHEVRE LITTLE THING SHE DOES IS MAGIC BURGER", "The twisted swiss-ster burger", "My Farro Lady Burger", "Woulda Coulda Gouda Burger", "You Gouda Be Kidding Me Burger", "As Gouda As It Gets Burger", "Gouda Gouda Gumdrops Burger", "A Few Gouda Men Burger", "Gouda Gouda Two Shoes Burger", "Gouda Day Sir Burger", "Parsnips- Vous Francais Burger", "Sweaty Palms Burger", "Tangled Up in Blueberry Burger", "The Gouda Wife Burger", "Take a bite out of lime burger", "This is what it sounds like when cloves fry burger", "Do Fry for Me Argentina Burger", "The fleetwood jack burger", "The deep blue brie burger", "Summer Thyme Burger", "I Know What You Did Last Summer Squash Burger", "The 500 Glaze of Summer Burger", "It's My Havarti and I'll Rye If I Want To burger", "Bleu is the Warmest Cheese Burger", "The Blanc Canvas Burger", "Blondes Have More Fun-gus Burger", "We're Here We're Gruyere, Get Used to It Burger", "Free To Brie You and Me Burger", "Chili Wonka Burger", "Glory Glory Jalapeno Burger", "Fingerling Brothers and Barnum and Bay Leaves Burger", "The for butter or for wurst burger", "View to a Kielbasa Dog", "The Heirloom Where it Happens Burger", "TURMERIC-A THE BEAUTIFUL BURGER", "Freedom of Choys Burger", "The Six Scallion Dollar Man Burger", "The if it's yellow let it portobello burger", "The Full Head of Heir-loom Tomato Burger", "We Bought a Zucchini Burger", "The Olive What She's Having Burger", "Son of a peach-er man burger", "You Won't Believe It's Not Butternut- squash Burger", "Bright leeks, big city burger", "It's chive o'clock some-pear burger", "The Paprika Smurf Burger", "THE ALL HOT AND COLLARD BURGER", "Edward James Olive-most Burger", "The Rosemary's Baby Spinach Burger", "Shishito Corleone Burger", "The you had me at hellokra burger", "Do the cremini, do the thyme burger", "Portobello the Belt Burger", "THE AROUND THE WORLD IN EIGHTY DATES BURGER", "Full nettle jacket burger", "Step Into the Okra-tagon Burger", "Medium Snare Burger", "I'd Be Cheddar Off Literally Anywhere But Here Burger!", "Beet-er Late Than Never", "Throw cardamom-ma from the train burger", "The fifty glaze to eat your burger", "To Thine Own Self be Bleu Burger", "Corned Identity Burger", "THE MUSH-AROOM ABOUT NOTHING BURGER", "It Takes Two to Mango burger", "THE DRAGONFRUIT ME TO HELL BURGER", "THE LAND OF THE SLAW-ST BURGER", "The throw your hands in the heirloom burger", "The pea-brie's big adventure burger", "Aw Nuts Burger", "When Harry Met Salami Burger", "Krauted House Burger", "Asiago for broke burger", "Top Bun Burger", "The Say Cheese Burger", "It Takes Bun to Know Bun Burger", "Heads Shoulders Knees and Tomatoes Burger", "I'm Picklish Burger", "Runny Out of Thyme Burger", "Chutney the Front Door Burger", "The fleetwood jack burger", "The straight and marrow burger", "The Gorgon-baby -gone burger", "The Final Kraut Down Burger", "THE THROW YOUR HANDS IN THE GRUYERE BURGER", "The One Yam Band Burger", "The 'shroom where it happens burger", "Walk This Waioli Burger", "The thin red pepper burger", "Ready or not here i plum burger", "THE JUDGE BRINE-HOLD BURGER", "She'll be Coming 'round the Plantain Burger", "The hawk and chickpeas burger", "Happy banana- versary burger", "The bleu collard burger", "The easy come, asiago burger", "The guac! or my mom will shoot burger", "The Don't Dream It's Okra Burger", "The rib long and prosper burger", "The Longest Chard Burger", "Smells Like Bean Spirit Burger", "The Troy Oinkman Burger", "The thousand chard stare burger", "Cloves encounters burger", "Kale Mary Burger", "The random jacks of chive-ness burger", "I'm Gonna Get You Succotash Burger", "The Frankie goes to hollandaise burger", "The ruth tomater ginsburger", "The Wasabi with You Burger", "Take a picture fig'll last longer", "Judy Garlic Burger", "The almond butters band burger", "The glazed and infused burger", "One Fish, Two Fish, Red Fish Hamburger", "THE COPS AND RABE-ERS BURGER", "Shake Your Honeymaker Burger", "Beets of Burden Burger", "I bean of greenie burger", "The unbreakable kimchi schmidt burger", "Avoca-don't you want me baby? burger", "The Jack-O-Lentil Burger", "THE HUNT FOR RED ONION-TOBER BURGER", "Onion Burger - Grilled...  To Death!", "Muenster Under the Bun Burger", "The pecorino on someone your own size burger", "Two Karat Burger", "The chimichurri up and wait burger", "Rest in Peas Burger", "Butterface Burger", "LITTLE CHOP OF HORSERADISH BURGER", "The 28 maize later burger", "The corn-juring two burger", "Texas Chainsaw Massa-curd Burger", "The if I \nhad a (pumper) nickel burger", "Kales From the Crypt Burger", "THE DEVIL'S AVOCADO-CATE BURGER", "It's fun to eat at the rYe MCA Burger", "The Human Polenta-pede Burger", "Riding in Cars with \nBok Choys", "Grandpa Muenster Burger", "Caper the Friendly Goat Cheese Burger", "Grin and carrot burger", "The chili-delphia story burger", "Paranormal Pepper Jack-tivity Burger", "The leek-y cauldron burger", "Shoot out at the Okra Corral Burger", "MURDER, KIMCHI WROTE BURGER", "I've Created a Muenster Burger", "The night-pear \non elm beet burger", "The Cauli- flower's Cumin from Inside the House Burger", "The what we dill in the shadows burger", "Corn This Way Burger", "Ruta-Bag-A Burger", "Livin' on a pear burger", "The Baby You Can Chive My Car Burger", "You Spinach Me Right Round Spinach Burger", "The chimi-churri you can't be serious burger", "The what's the matter-horn burger", "THE ABSENTEE SHALLOT BURGER", "Camembert-ly Legal Burger", "The groove is in the chard burger", "Burger she goat", "The goat tell it on the mountain burger", "Band On The Bun Burger", "House of 1000 pork-ses burger", "Sub- conscious Burger", "The lost in yam-slation burger", "The Mad Flax Curry Road burger", "In ricotta da vida burger", "ONE FLEW OKRA THE COUSCOUS NEST BURGER", "Only the Provolonely Burger", "Stilton crazy after all these gruyeres burger", "The Sound & The Curry Burger", "You're Kimchi the Best Burger", "Bohemian Radishy Burger", "The Catch Me If You Cran Burger", "I stilton haven't found what thyme looking for burger", "Graters of the sauced havart(i) burger", "The tikka look at me now burger", "Charbroil Fair Burger", "The Yam Ship Burger", "One Horse Open Slaw Burger", "Jingle bell peppers rock burger", "Let it snow peas Burger", "I Fought the Slaw Burger", "Walking in a Winter Comes-with- cran Burger", "It came upon a midnight gruyere burger", "Bleu by You Burger", "The What's Kala-mata with You Burger", "Santa Claus Is Cumin to Town Burger", "The hollandaise ro-o-oh-o-oh- o-oh-oh-oh- oll burger", "The Ebeneezer Bleu-ge Burger", "THE SMILLA'S SENSE OF SNOWPEAS BURGER", "Winter Muensterland Burger with Muenster cheese", "Passion of the Cress Burger", "You cheddar watch out, you cheddar on rye burger", "Jingle Bell Pepper Burger", "Away in a Mango Burger", "Home for the Challah-Days Burger", "You can't fight City Challa Burger", "Your cress is on my list burger", "The challah and the chive-y burger", "The Silentil Night Burger", "THE SANTA SLAWS IS COMING TO TOWN BURGER", "Twas the Nut Before Christmas Burger", "Cheeses is Born Burger", "The Pear Tree Burger", "The fried off into the sunset burger", "Good Night and Good Leek Burger", "Fifth Day of Christmas Burger", "Celery-brate good times, come on! burger", "Havarti Like It's 1999 Burger"]

BURGER_PAR_LIST = ["(comes with bacon)", "", "", "", "", "", "", "(on focaccia with beets)", "(comes with lots of fennel, no thyme)", "", "", "", "", "", "", "(comes with a side of pear salad)", "", "", "", "(comes with a slice of Radish)", "", "(Comes on a buttered bun)", "(Comes with sauteed leeks)", "", "", "(Comes with braised leeks)", "(Comes with Bleu Cheese)", "", "", "", "", "", "", "", "", "", "", "", "", "(with broccoli and artichoke hearts)", "", "", "", "", "", "", "", "", "(Comes with four kinds of cheddar)", "", "", "", "", "", "", "", "(Comes with poutine fries)", "", "(Doesn't come with cilantro. Because cilantro is terrible.)", "", "", "(aged burger with a fried egg on top)", "(with fried egg and cheese)", "(comes with edamame)", "", "", "(Comes with ice cream - Not on top)", "(Served open-faced on a sesame seed bun)", "", "", "", "(served with no chives)", "", "", "(Comes with Baked Beans)", "", "(whiskey brushed patty)", "(Comes with mint relish)", "(Comes with Radish)", "(Porcini on a double decker)", "(But I Like It)", "", "(comes with an everything bagel)", "", "", "", "", "(Served with Crapple)", "", "", "", "(Comes with Peanuts and Crackerjacks)", "", "", "(comes with a poached egg)", "", "", "(comes with cremini mushrooms)", "", "(Comes with enoki mushrooms)", "", "(Comes with sharp cheddar)", "(comes on a barley roll)", "", "", "(comes with parsnips)", "", "", "", "", "(Comes with brussel sprouts)", "", "(comes with oaxaca cheese)", "(with Parmesan crisp)", "", "(Comes with cheese curds)", "", "", "(with Thinly Sliced Beets)", "", "", "", "(comes with sauteed onions and mango salsa)", "", "", "(Comes with Corn Salsa)", "", "", "", "(Comes with Parmesan)", "", "(Comes with Jicama)", "", "", "(comes with a wor- cestershire glaze)", "", "(Served with Balsamic Glaze)", "", "", "(comes with pea shoots)", "", "(comes with bone marrow)", "", "", "", "(Comes with squash and ham)", "", "", "(served with a balsamic drizzle on a rye bun)", "", "(served with Brussel sprouts)", "", "", "", "", "", "", "", "", "", "", "(It comes with shoes)", "", "", "(Comes with hearts of palm)", "(comes with a blueberry compote)", "(comes with Mature Gouda)", "(with lime chutney)", "(with fried garlic cloves)", "", "(comes with sweet little fries pies, jack cheese)", "(comes with blue cheese and brie)", "", "", "(comes with Pomegranate Glaze)", "", "", "(comes with a fromage blanc)", "(Comes with mushrooms)", "", "", "", "", "", "(with butter pickles and sausage)", "", "", "", "(comes with bok choy)", "", "(with yellow peppers and portobello mushrooms)", "", "", "", "(comes with peach glaze)", "(served with zucchini)", "(comes with grilled leeks)", "", "(comes with blue potato fries)", "", "", "", "(comes with shishito peppers)", "", "", "", "", "(comes with sauteed nettles)", "", "", "(comes with aged cheddar)", "", "", "", "(served with bleu cheese)", "(comes with corned beef)", "", "", "", "(Comes with pickle slaw)", "", "(pea protein burger w/Brie)", "(comes with peanut butter)", "", "", "", "(comes on our best seven-grain bun)", "", "(comes on a fancy bun)", "", "(comes with pickles)", "(comes with a runny fried egg)", "(Comes with Mango Chutney)", "(comes with sweet little pies, jack cheese)", "(comes with marrow)", "(comes with gorgonzola cheese)", "(Comes with sauerkraut)", "", "(Comes with yams)", "", "(comes with wasabi aioli)", "", "", "", "", "", "(9 is divisible by 3)", "", "", "", "", "", "", "", "(Served with bacon)", "(comes with thousand island dressing and swiss chard)", "", "(served with kale)", "(with monterrey jack cheese and chives)", "", "", "(comes with heirloom tomatoes and pickled ginger)", "", "", "", "(comes with toasted almond butter)", "(bourbon glazed and infused with bacon)", "", "(Topped with Broccoli Rabes)", "(Comes with Honey Mustard)", "", "(comes with black bean parsley puree)", "", "", "", "", "", "", "(comes with pecorino crisps)", "(Comes with two carrots)", "", "", "(served with butter lettuce)", "", "(comes with corn salsa)", "(comes with even more corn salsa)", "", "", "", "", "(Comes on Rye w/ Mustard, Cheese & Avocado)", "", "", "(10% Senior Discount)", "(served with capers & feta)", "", "", "", "", "", "", "", "(comes with pear and beet relish)", "(Comes with cauliflower and cumin)", "", "", "", "", "", "", "", "(with swiss cheese crisps)", "(Comes with crispy shallots)", "", "", "(comes with goat cheese)", "(comes with goat cheese)", "(Comes with Wings)", "(topped with ham and bacon)", "(on a sub roll)", "", "", "", "", "(Comes with provolone)", "", "", "", "", "(served with cranberry sauce)", "", "", "", "(Comes with Parlsey, Sage, Rosemary, and Thyme)", "(comes with yams)", "(Comes with slaw, no horse)", "", "", "(And the Slaw Won)", "(comes with cranberry sauce)", "", "(with locally sourced bleu cheese)", "", "(with cumin)", "(comes with hollandaise sauce on a kaiser roll)", "", "", "(Side of snow peas)", "", "", "", "", "(Comes on a challah roll)", "(comes on a Challah roll)", "(comes with watercress)", "", "(Comes with lentils)", "", "(comes with walnut aioli)", "(Comes with baby swiss)", "(with sliced pears - partridge not included)", "(comes with a fried egg)", "", "(Comes with five golden rings of onion)", "", ""]

DEFAULT_BURGER_NAME = "New bacon-ings"
DEFAULT_BURGER_PAR = "(Comes with bacon)"
BURGER_NAME = ""
BURGER_PAR = ""
YEAR = time.now().year
DEFAULT_TIME_ZONE = "America/New_York"

#remove leap day burger from lists if its not a leap year
def checkIfNotLeapYear():
    if (YEAR % 4 != 0) or (YEAR % 100 == 0):
        BURGER_LIST.pop(59)
        BURGER_PAR_LIST.pop(59)

checkIfNotLeapYear()

def main(config):
    def showBobsLogo():
        if config.bool("show_logo", True):
            return render.Padding(
                render.Image(
                    src = BOBS_LOGO,
                    width = 62,
                    height = 20,
                ),
                pad = 1,
            )
        else:
            return None

    LOCATION = config.get("location")
    LOCATION = json.decode(LOCATION) if LOCATION else {}
    TIME_ZONE = LOCATION.get(
        "timezone",
        time.tz(),
    )
    TIME_NOW = time.now().in_location(TIME_ZONE)
    CURRENT_YEAR = int(TIME_NOW.year)
    FIRST_DAY = time.time(year = CURRENT_YEAR, month = 1, day = 1, location = TIME_ZONE)
    DAYS_SINCE_JAN1 = TIME_NOW - FIRST_DAY
    DAYS_NUMBER = math.floor(DAYS_SINCE_JAN1.hours / 24)
    RANDOM_NUMBER = random.number(0, 365)
    BURGER_SHOWN = config.get("burger_shown", "daily")
    SCROLL_SPEED = config.str("scroll_speed", "60")

    if BURGER_SHOWN == "random":
        BURGER_NAME = BURGER_LIST[RANDOM_NUMBER]
        BURGER_PAR = BURGER_PAR_LIST[RANDOM_NUMBER]
    elif BURGER_SHOWN == "daily":
        BURGER_NAME = BURGER_LIST[DAYS_NUMBER]
        BURGER_PAR = BURGER_PAR_LIST[DAYS_NUMBER]
    elif BURGER_SHOWN == "custom":
        BURGER_NAME = config.str("custom_name", DEFAULT_BURGER_NAME)
        BURGER_PAR = config.str("custom_ingredients", DEFAULT_BURGER_PAR)
    else:
        BURGER_NAME = DEFAULT_BURGER_NAME
        BURGER_PAR = DEFAULT_BURGER_PAR

    return render.Root(
        show_full_animation = True,
        delay = int(SCROLL_SPEED),
        child = render.Column(
            children = [
                render.Marquee(
                    offset_start = 32,
                    offset_end = 32,
                    width = 64,
                    height = 32,
                    scroll_direction = "vertical",
                    child =
                        render.Column(
                            children = [
                                showBobsLogo(),
                                render.Padding(
                                    render.Image(
                                        src = BURGER_TEXT,
                                        width = 64,
                                        height = 21,
                                    ),
                                    pad = (0, 3, 0, 0),
                                ),
                                render.Box(
                                    render.Row(
                                        expanded = True,
                                        main_align = "space_evenly",
                                        children = [
                                            render.Text(
                                                content = "OF THE DAY",
                                                color = "#fff",
                                            ),
                                        ],
                                    ),
                                    width = 64,
                                    height = 8,
                                ),
                                render.Box(
                                    color = "#000",
                                    child = render.Box(
                                        width = 38,
                                        height = 1,
                                        color = "#fff",
                                    ),
                                    width = 64,
                                    height = 3,
                                ),
                                render.Padding(
                                    render.WrappedText(
                                        content = BURGER_NAME.upper(),
                                        width = 60,
                                        color = "#fff",
                                    ),
                                    pad = (3, 6, 3, 1),
                                ),
                                render.Padding(
                                    render.WrappedText(
                                        content = BURGER_PAR.lower(),
                                        width = 60,
                                        color = "#fff",
                                    ),
                                    pad = (3, 0, 3, 2),
                                ),
                                render.Box(
                                    render.Row(
                                        expanded = True,
                                        main_align = "space_evenly",
                                        children = [
                                            render.Text(
                                                content = "$5.95",
                                                font = "6x13",
                                            ),
                                        ],
                                    ),
                                    width = 64,
                                    height = 13,
                                ),
                            ],
                        ),
                ),
            ],
        ),
    )

def get_schema():
    scroll_speed = [
        schema.Option(display = "Slow", value = "200"),
        schema.Option(display = "Normal", value = "100"),
        schema.Option(display = "Fast (Default)", value = "60"),
        schema.Option(display = "Faster", value = "30"),
    ]
    burger_shown = [
        schema.Option(display = "Daily", value = "daily"),
        schema.Option(display = "Random", value = "random"),
        schema.Option(display = "Custom", value = "custom"),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "So your daily burger changes each day",
                icon = "locationDot",
            ),
            schema.Toggle(
                id = "show_logo",
                name = "Show logo",
                desc = "Show or hide the Bob's Burgers show logo",
                icon = "signHanging",
                default = True,
            ),
            schema.Dropdown(
                id = "burger_shown",
                name = "Burger shown",
                desc = "Burgers to show",
                icon = "burger",
                default = burger_shown[0].value,
                options = burger_shown,
            ),
            schema.Text(
                id = "custom_name",
                name = "Custom burger",
                desc = "Custom burger",
                icon = "pencil",
                default = DEFAULT_BURGER_NAME,
            ),
            schema.Text(
                id = "custom_ingredients",
                name = "Custom ingredients",
                desc = "Custom ingredients",
                icon = "pencil",
                default = DEFAULT_BURGER_PAR,
            ),
            schema.Dropdown(
                id = "scroll_speed",
                name = "Scroll speed",
                desc = "Text scrolling speed",
                icon = "personRunning",
                default = scroll_speed[2].value,
                options = scroll_speed,
            ),
        ],
    )
