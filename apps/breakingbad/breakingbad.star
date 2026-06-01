"""
Applet: BreakingBad
Summary: Breaking Bad TV Credit
Description: Display credit in Breaking Bad TV show format.
Author: Robert Ison
"""

load("images/smoke.gif", SMOKE_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

SMOKE = SMOKE_ASSET.readall()

FONT = "6x10"
ELEMENT_GREEN = "#094b3f"
WHITE = "#FFF"

elements = {
    "H": "Hydrogen",
    "He": "Helium",
    "Li": "Lithium",
    "Be": "Beryllium",
    "B": "Boron",
    "C": "Carbon",
    "N": "Nitrogen",
    "O": "Oxygen",
    "F": "Fluorine",
    "Ne": "Neon",
    "Na": "Sodium",
    "Mg": "Magnesium",
    "Al": "Aluminum",
    "Si": "Silicon",
    "P": "Phosphorus",
    "S": "Sulfur",
    "Cl": "Chlorine",
    "Ar": "Argon",
    "K": "Potassium",
    "Ca": "Calcium",
    "Sc": "Scandium",
    "Ti": "Titanium",
    "V": "Vanadium",
    "Cr": "Chromium",
    "Mn": "Manganese",
    "Fe": "Iron",
    "Co": "Cobalt",
    "Ni": "Nickel",
    "Cu": "Copper",
    "Zn": "Zinc",
    "Ga": "Gallium",
    "Ge": "Germanium",
    "As": "Arsenic",
    "Se": "Selenium",
    "Br": "Bromine",
    "Kr": "Krypton",
    "Rb": "Rubidium",
    "Sr": "Strontium",
    "Y": "Yttrium",
    "Zr": "Zirconium",
    "Nb": "Niobium",
    "Mo": "Molybdenum",
    "Tc": "Technetium",
    "Ru": "Ruthenium",
    "Rh": "Rhodium",
    "Pd": "Palladium",
    "Ag": "Silver",
    "Cd": "Cadmium",
    "In": "Indium",
    "Sn": "Tin",
    "Sb": "Antimony",
    "Te": "Tellurium",
    "I": "Iodine",
    "Xe": "Xenon",
    "Cs": "Cesium",
    "Ba": "Barium",
    "La": "Lanthanum",
    "Ce": "Cerium",
    "Pr": "Praseodymium",
    "Nd": "Neodymium",
    "Pm": "Promethium",
    "Sm": "Samarium",
    "Eu": "Europium",
    "Gd": "Gadolinium",
    "Tb": "Terbium",
    "Dy": "Dysprosium",
    "Ho": "Holmium",
    "Er": "Erbium",
    "Tm": "Thulium",
    "Yb": "Ytterbium",
    "Lu": "Lutetium",
    "Hf": "Hafnium",
    "Ta": "Tantalum",
    "W": "Tungsten",
    "Re": "Rhenium",
    "Os": "Osmium",
    "Ir": "Iridium",
    "Pt": "Platinum",
    "Au": "Gold",
    "Hg": "Mercury",
    "Tl": "Thallium",
    "Pb": "Lead",
    "Bi": "Bismuth",
    "Po": "Polonium",
    "At": "Astatine",
    "Rn": "Radon",
    "Fr": "Francium",
    "Ra": "Radium",
    "Ac": "Actinium",
    "Th": "Thorium",
    "Pa": "Protactinium",
    "U": "Uranium",
    "Np": "Neptunium",
    "Pu": "Plutonium",
    "Am": "Americium",
    "Cm": "Curium",
    "Bk": "Berkelium",
    "Cf": "Californium",
    "Es": "Einsteinium",
    "Fm": "Fermium",
    "Md": "Mendelevium",
    "No": "Nobelium",
    "Lr": "Lawrencium",
    "Rf": "Rutherfordium",
    "Db": "Dubnium",
    "Sg": "Seaborgium",
    "Bh": "Bohrium",
    "Hs": "Hassium",
    "Mt": "Meitnerium",
    "Ds": "Darmstadtium",
    "Rg": "Roentgentium",
    "Cn": "Copernicum",
    "Nh": "Nihonium",
    "Fl": "Flerovium",
    "Mc": "Moscovium",
    "Lv": "Livermorium",
    "Ts": "Tennessine",
    "Og": "Oganesson",
}

def main(config):
    line1 = config.str("line1", "Breaking")
    line2 = config.str("line2", "  Bad")
    show_smoke = config.bool("show_image", True)

    return render.Root(
        child = render.Stack(
            children = [
                render.Image(src = SMOKE) if show_smoke else None,
                get_display_children_for_given_breakdown(1, find_element_symbol(line1)),
                get_display_children_for_given_breakdown(2, find_element_symbol(line2)),
            ],
        ),
        delay = 200,
    )

def get_display_children_for_given_breakdown(row, breakdown):
    items = []

    height_offset = 1 + 15 * (int(row) - 1)
    left_offset = 1 + 3 * (int(row) - 1)
    text_height_difference = 2

    prefix = breakdown[0]
    element = breakdown[1]
    suffix = breakdown[2]

    if (len(prefix) > 0):
        items.insert(len(items), add_padding_to_child_element(render.Text(prefix.strip(), font = FONT), left_offset, height_offset + text_height_difference))

    left_offset = left_offset + 6 * len(prefix)

    if (len(element) > 0):
        items.insert(len(items), add_padding_to_child_element(get_element_box_children(element), left_offset, height_offset))
        left_offset = left_offset + 14

    if (len(suffix) > 0):
        items.insert(len(items), add_padding_to_child_element(render.Text(suffix.strip(), font = FONT), left_offset, height_offset + text_height_difference))

    return render.Stack(items)

def get_element_box_children(element):
    return render.Box(width = 13, height = 14, color = WHITE, child = render.Box(width = 11, height = 12, color = ELEMENT_GREEN, child = add_padding_to_child_element(render.Text(element), 1)))

def find_element_symbol(name):
    for length in (2, 1):  # Check 2-letter symbols first, then 1-letter
        for i in range(len(name) - (length - 1)):
            if name[i:i + length].capitalize() in elements:
                return name[:i], name[i:i + length].capitalize(), name[i + length:]

    return name, "", ""

def add_padding_to_child_element(element, left = 0, top = 0, right = 0, bottom = 0):
    padded_element = render.Padding(
        pad = (left, top, right, bottom),
        child = element,
    )

    return padded_element

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "line1",
                name = "Line 1",
                desc = "First Name",
                icon = "pencil",
            ),
            schema.Text(
                id = "line2",
                name = "Line 2",
                desc = "Last Name",
                icon = "pencil",
            ),
            schema.Toggle(
                id = "show_image",
                name = "Show background image?",
                desc = "Display the smoking background?",
                icon = "fireFlameCurved",
            ),
        ],
    )
