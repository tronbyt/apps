"""
Applet: Random Dogs
Summary: Shows pictures of dogs
Description: Shows random pictures of dogs from dog.ceo.
Author: mattmcquinn
"""

load("http.star", "http")
load("images/default_image.jpg", DEFAULT_IMAGE_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

DEFAULT_IMAGE = DEFAULT_IMAGE_ASSET.readall()

def main(config):
    image = DEFAULT_IMAGE
    breed = config.get("breed")
    random = config.bool("random", True)
    if random:
        url = "https://dog.ceo/api/breeds/image/random"
    else:
        url = "https://dog.ceo/api/breed/" + breed + "/images/random"

    # cache the request for a new image for four minutes
    rep = http.get(url, ttl_seconds = 4 * 60)
    if rep.headers.get("Tidbyt-Cache-Status") == "HIT":
        print("Hit! Not fetching new image url.")
    else:
        print("Miss! Fetching new image url.")
    if rep.status_code == 200:
        response = rep.json()
        image_url = response["message"]
        print(image_url)

        # cache the actual image response for 24 hours
        # image data should not change frequently (if ever) so this TTL can be very long
        image_rep = http.get(image_url, ttl_seconds = 60 * 60 * 24)
        if image_rep.headers.get("Tidbyt-Cache-Status") == "HIT":
            print("Hit! Fetching image from cache.")
        else:
            print("Miss! Fetching image data.")
        if image_rep.status_code == 200:
            image = image_rep.body()

    return render.Root(
        child = render.Image(src = image, width = 64, height = 32),
    )

def get_schema():
    options = [
        schema.Option(display = "Affenpinscher", value = "affenpinscher"),
        schema.Option(display = "African", value = "african"),
        schema.Option(display = "Airedale", value = "airedale"),
        schema.Option(display = "Akita", value = "akita"),
        schema.Option(display = "Appenzeller", value = "appenzeller"),
        schema.Option(display = "Shepherd Australian", value = "australian/shepherd"),
        schema.Option(display = "Basenji", value = "basenji"),
        schema.Option(display = "Beagle", value = "beagle"),
        schema.Option(display = "Bluetick", value = "bluetick"),
        schema.Option(display = "Borzoi", value = "borzoi"),
        schema.Option(display = "Bouvier", value = "bouvier"),
        schema.Option(display = "Boxer", value = "boxer"),
        schema.Option(display = "Brabancon", value = "brabancon"),
        schema.Option(display = "Briard", value = "briard"),
        schema.Option(display = "Norwegian Buhund", value = "buhund/norwegian"),
        schema.Option(display = "Boston Bulldog", value = "bulldog/boston"),
        schema.Option(display = "English Bulldog", value = "bulldog/english"),
        schema.Option(display = "French Bulldog", value = "bulldog/french"),
        schema.Option(display = "Staffordshire Bullterrier", value = "bullterrier/staffordshire"),
        schema.Option(display = "Australian Cattledog", value = "cattledog/australian"),
        schema.Option(display = "Cavapoo", value = "cavapoo"),
        schema.Option(display = "Chihuahua", value = "chihuahua"),
        schema.Option(display = "Chow", value = "chow"),
        schema.Option(display = "Clumber", value = "clumber"),
        schema.Option(display = "Cockapoo", value = "cockapoo"),
        schema.Option(display = "Border Collie", value = "collie/border"),
        schema.Option(display = "Coonhound", value = "coonhound"),
        schema.Option(display = "Cardigan Corgi", value = "corgi/cardigan"),
        schema.Option(display = "Cotondetulear", value = "cotondetulear"),
        schema.Option(display = "Dachshund", value = "dachshund"),
        schema.Option(display = "Dalmatian", value = "dalmatian"),
        schema.Option(display = "Great Dane", value = "dane/great"),
        schema.Option(display = "Scottish Deerhound", value = "deerhound/scottish"),
        schema.Option(display = "Dhole", value = "dhole"),
        schema.Option(display = "Dingo", value = "dingo"),
        schema.Option(display = "Doberman", value = "doberman"),
        schema.Option(display = "Norwegian Elkhound", value = "elkhound/norwegian"),
        schema.Option(display = "Entlebucher", value = "entlebucher"),
        schema.Option(display = "Eskimo", value = "eskimo"),
        schema.Option(display = "Lapphund Finnish", value = "finnish/lapphund"),
        schema.Option(display = "Bichon Frise", value = "frise/bichon"),
        schema.Option(display = "Germanshepherd", value = "germanshepherd"),
        schema.Option(display = "Italian Greyhound", value = "greyhound/italian"),
        schema.Option(display = "Groenendael", value = "groenendael"),
        schema.Option(display = "Havanese", value = "havanese"),
        schema.Option(display = "Afghan Hound", value = "hound/afghan"),
        schema.Option(display = "Basset Hound", value = "hound/basset"),
        schema.Option(display = "Blood Hound", value = "hound/blood"),
        schema.Option(display = "English Hound", value = "hound/english"),
        schema.Option(display = "Ibizan Hound", value = "hound/ibizan"),
        schema.Option(display = "Plott Hound", value = "hound/plott"),
        schema.Option(display = "Walker Hound", value = "hound/walker"),
        schema.Option(display = "Husky", value = "husky"),
        schema.Option(display = "Keeshond", value = "keeshond"),
        schema.Option(display = "Kelpie", value = "kelpie"),
        schema.Option(display = "Komondor", value = "komondor"),
        schema.Option(display = "Kuvasz", value = "kuvasz"),
        schema.Option(display = "Labradoodle", value = "labradoodle"),
        schema.Option(display = "Labrador", value = "labrador"),
        schema.Option(display = "Leonberg", value = "leonberg"),
        schema.Option(display = "Lhasa", value = "lhasa"),
        schema.Option(display = "Malamute", value = "malamute"),
        schema.Option(display = "Malinois", value = "malinois"),
        schema.Option(display = "Maltese", value = "maltese"),
        schema.Option(display = "Bull Mastiff", value = "mastiff/bull"),
        schema.Option(display = "English Mastiff", value = "mastiff/english"),
        schema.Option(display = "Tibetan Mastiff", value = "mastiff/tibetan"),
        schema.Option(display = "Mexicanhairless", value = "mexicanhairless"),
        schema.Option(display = "Mix", value = "mix"),
        schema.Option(display = "Bernese Mountain", value = "mountain/bernese"),
        schema.Option(display = "Swiss Mountain", value = "mountain/swiss"),
        schema.Option(display = "Newfoundland", value = "newfoundland"),
        schema.Option(display = "Otterhound", value = "otterhound"),
        schema.Option(display = "Caucasian Ovcharka", value = "ovcharka/caucasian"),
        schema.Option(display = "Papillon", value = "papillon"),
        schema.Option(display = "Pekinese", value = "pekinese"),
        schema.Option(display = "Pembroke", value = "pembroke"),
        schema.Option(display = "Miniature Pinscher", value = "pinscher/miniature"),
        schema.Option(display = "Pitbull", value = "pitbull"),
        schema.Option(display = "German Pointer", value = "pointer/german"),
        schema.Option(display = "Germanlonghair Pointer", value = "pointer/germanlonghair"),
        schema.Option(display = "Pomeranian", value = "pomeranian"),
        schema.Option(display = "Medium Poodle", value = "poodle/medium"),
        schema.Option(display = "Miniature Poodle", value = "poodle/miniature"),
        schema.Option(display = "Standard Poodle", value = "poodle/standard"),
        schema.Option(display = "Toy Poodle", value = "poodle/toy"),
        schema.Option(display = "Pug", value = "pug"),
        schema.Option(display = "Puggle", value = "puggle"),
        schema.Option(display = "Pyrenees", value = "pyrenees"),
        schema.Option(display = "Redbone", value = "redbone"),
        schema.Option(display = "Chesapeake Retriever", value = "retriever/chesapeake"),
        schema.Option(display = "Curly Retriever", value = "retriever/curly"),
        schema.Option(display = "Flatcoated Retriever", value = "retriever/flatcoated"),
        schema.Option(display = "Golden Retriever", value = "retriever/golden"),
        schema.Option(display = "Rhodesian Ridgeback", value = "ridgeback/rhodesian"),
        schema.Option(display = "Rottweiler", value = "rottweiler"),
        schema.Option(display = "Saluki", value = "saluki"),
        schema.Option(display = "Samoyed", value = "samoyed"),
        schema.Option(display = "Schipperke", value = "schipperke"),
        schema.Option(display = "Giant Schnauzer", value = "schnauzer/giant"),
        schema.Option(display = "Miniature Schnauzer", value = "schnauzer/miniature"),
        schema.Option(display = "Italian Segugio", value = "segugio/italian"),
        schema.Option(display = "English Setter", value = "setter/english"),
        schema.Option(display = "Gordon Setter", value = "setter/gordon"),
        schema.Option(display = "Irish Setter", value = "setter/irish"),
        schema.Option(display = "Sharpei", value = "sharpei"),
        schema.Option(display = "English Sheepdog", value = "sheepdog/english"),
        schema.Option(display = "Shetland Sheepdog", value = "sheepdog/shetland"),
        schema.Option(display = "Shiba", value = "shiba"),
        schema.Option(display = "Shihtzu", value = "shihtzu"),
        schema.Option(display = "Blenheim Spaniel", value = "spaniel/blenheim"),
        schema.Option(display = "Brittany Spaniel", value = "spaniel/brittany"),
        schema.Option(display = "Cocker Spaniel", value = "spaniel/cocker"),
        schema.Option(display = "Irish Spaniel", value = "spaniel/irish"),
        schema.Option(display = "Japanese Spaniel", value = "spaniel/japanese"),
        schema.Option(display = "Sussex Spaniel", value = "spaniel/sussex"),
        schema.Option(display = "Welsh Spaniel", value = "spaniel/welsh"),
        schema.Option(display = "Japanese Spitz", value = "spitz/japanese"),
        schema.Option(display = "English Springer", value = "springer/english"),
        schema.Option(display = "Stbernard", value = "stbernard"),
        schema.Option(display = "American Terrier", value = "terrier/american"),
        schema.Option(display = "Australian Terrier", value = "terrier/australian"),
        schema.Option(display = "Bedlington Terrier", value = "terrier/bedlington"),
        schema.Option(display = "Border Terrier", value = "terrier/border"),
        schema.Option(display = "Cairn Terrier", value = "terrier/cairn"),
        schema.Option(display = "Dandie Terrier", value = "terrier/dandie"),
        schema.Option(display = "Fox Terrier", value = "terrier/fox"),
        schema.Option(display = "Irish Terrier", value = "terrier/irish"),
        schema.Option(display = "Kerryblue Terrier", value = "terrier/kerryblue"),
        schema.Option(display = "Lakeland Terrier", value = "terrier/lakeland"),
        schema.Option(display = "Norfolk Terrier", value = "terrier/norfolk"),
        schema.Option(display = "Norwich Terrier", value = "terrier/norwich"),
        schema.Option(display = "Patterdale Terrier", value = "terrier/patterdale"),
        schema.Option(display = "Russell Terrier", value = "terrier/russell"),
        schema.Option(display = "Scottish Terrier", value = "terrier/scottish"),
        schema.Option(display = "Sealyham Terrier", value = "terrier/sealyham"),
        schema.Option(display = "Silky Terrier", value = "terrier/silky"),
        schema.Option(display = "Tibetan Terrier", value = "terrier/tibetan"),
        schema.Option(display = "Toy Terrier", value = "terrier/toy"),
        schema.Option(display = "Welsh Terrier", value = "terrier/welsh"),
        schema.Option(display = "Westhighland Terrier", value = "terrier/westhighland"),
        schema.Option(display = "Wheaten Terrier", value = "terrier/wheaten"),
        schema.Option(display = "Yorkshire Terrier", value = "terrier/yorkshire"),
        schema.Option(display = "Tervuren", value = "tervuren"),
        schema.Option(display = "Vizsla", value = "vizsla"),
        schema.Option(display = "Spanish Waterdog", value = "waterdog/spanish"),
        schema.Option(display = "Weimaraner", value = "weimaraner"),
        schema.Option(display = "Whippet", value = "whippet"),
        schema.Option(display = "Irish Wolfhound", value = "wolfhound/irish"),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "random",
                name = "Random Breed",
                desc = "Show any random breed",
                icon = "shuffle",
                default = True,
            ),
            schema.Dropdown(
                id = "breed",
                name = "Specific Breed",
                desc = "A specific breed to show (turn random off)",
                icon = "dog",
                options = options,
                default = "dachshund",  # fits the dimensions of the Tidbyt well ;-)
            ),
        ],
    )
