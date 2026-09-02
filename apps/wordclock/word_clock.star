"""
Applet: Word Clock
Author: Jeffrey Lancaster
Summary: Accurate human readable time
Description: Display the accurate time in a human-readable way. Inspired by Max Timkovich's Fuzzy Clock.
"""

load("encoding/json.star", "json")
load("math.star", "math")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

DEFAULT_LOCATION = {
    "lat": 40.7,
    "lng": -74.0,
    "locality": "Brooklyn",
}
DEFAULT_TIMEZONE = "US/Eastern"

# h is whether to use the subsequent hour word
# o is whether the text comes before (1) or after (2) the hour word

minutesObj = {
    "en-US": {
        "0": [
            {"text": ["hundred"], "h": 0, "o": 2, "military": True},
            {"text": ["o'clock"], "h": 0, "o": 2},
            {"text": [], "h": 0, "o": 1},
        ],
        "1": [
            {"text": ["zero one"], "h": 0, "o": 2, "military": True},
            {"text": ["oh one"], "h": 0, "o": 2},
            {"text": ["one", "past"], "h": 0, "o": 1},
            {"text": ["one", "after"], "h": 0, "o": 1},
        ],
        "2": [
            {"text": ["zero two"], "h": 0, "o": 2, "military": True},
            {"text": ["oh two"], "h": 0, "o": 2},
            {"text": ["two", "past"], "h": 0, "o": 1},
            {"text": ["two", "after"], "h": 0, "o": 1},
        ],
        "3": [
            {"text": ["zero three"], "h": 0, "o": 2, "military": True},
            {"text": ["oh three"], "h": 0, "o": 2},
            {"text": ["three", "past"], "h": 0, "o": 1},
            {"text": ["three", "after"], "h": 0, "o": 1},
        ],
        "4": [
            {"text": ["zero four"], "h": 0, "o": 2, "military": True},
            {"text": ["oh four"], "h": 0, "o": 2},
            {"text": ["four", "past"], "h": 0, "o": 1},
            {"text": ["four", "after"], "h": 0, "o": 1},
        ],
        "5": [
            {"text": ["zero five"], "h": 0, "o": 2, "military": True},
            {"text": ["oh five"], "h": 0, "o": 2},
            {"text": ["five", "past"], "h": 0, "o": 1},
            {"text": ["five", "after"], "h": 0, "o": 1},
        ],
        "6": [
            {"text": ["zero six"], "h": 0, "o": 2, "military": True},
            {"text": ["oh six"], "h": 0, "o": 2},
            {"text": ["six", "past"], "h": 0, "o": 1},
            {"text": ["six", "after"], "h": 0, "o": 1},
        ],
        "7": [
            {"text": ["zero seven"], "h": 0, "o": 2, "military": True},
            {"text": ["oh seven"], "h": 0, "o": 2},
            {"text": ["seven", "past"], "h": 0, "o": 1},
            {"text": ["seven", "after"], "h": 0, "o": 1},
        ],
        "8": [
            {"text": ["zero eight"], "h": 0, "o": 2, "military": True},
            {"text": ["oh eight"], "h": 0, "o": 2},
            {"text": ["eight", "past"], "h": 0, "o": 1},
            {"text": ["eight", "after"], "h": 0, "o": 1},
        ],
        "9": [
            {"text": ["zero nine"], "h": 0, "o": 2, "military": True},
            {"text": ["oh nine"], "h": 0, "o": 2},
            {"text": ["nine", "past"], "h": 0, "o": 1},
            {"text": ["nine", "after"], "h": 0, "o": 1},
        ],
        "10": [
            {"text": ["ten"], "h": 0, "o": 2},
            {"text": ["ten", "past"], "h": 0, "o": 1},
            {"text": ["ten", "after"], "h": 0, "o": 1},
        ],
        "11": [{"text": ["eleven"], "h": 0, "o": 2}],
        "12": [{"text": ["twelve"], "h": 0, "o": 2}],
        "13": [{"text": ["thirteen"], "h": 0, "o": 2}],
        "14": [{"text": ["fourteen"], "h": 0, "o": 2}],
        "15": [
            {"text": ["fifteen"], "h": 0, "o": 2},
            {"text": ["quarter", "past"], "h": 0, "o": 1},
            {"text": ["quarter", "after"], "h": 0, "o": 1},
        ],
        "16": [{"text": ["sixteen"], "h": 0, "o": 2}],
        "17": [{"text": ["seventeen"], "h": 0, "o": 2}],
        "18": [{"text": ["eighteen"], "h": 0, "o": 2}],
        "19": [{"text": ["nineteen"], "h": 0, "o": 2}],
        "20": [{"text": ["twenty"], "h": 0, "o": 2}],
        "21": [{"text": ["twenty-one"], "h": 0, "o": 2}],
        "22": [{"text": ["twenty-two"], "h": 0, "o": 2}],
        "23": [{"text": ["twenty-three"], "h": 0, "o": 2}],
        "24": [{"text": ["twenty-four"], "h": 0, "o": 2}],
        "25": [{"text": ["twenty-five"], "h": 0, "o": 2}],
        "26": [{"text": ["twenty-six"], "h": 0, "o": 2}],
        "27": [{"text": ["twenty-seven"], "h": 0, "o": 2}],
        "28": [{"text": ["twenty-eight"], "h": 0, "o": 2}],
        "29": [{"text": ["twenty-nine"], "h": 0, "o": 2}],
        "30": [
            {"text": ["thirty"], "h": 0, "o": 2},
            {"text": ["half", "past"], "h": 0, "o": 1},
            {"text": ["half"], "h": 0, "o": 1},
        ],
        "31": [{"text": ["thirty-one"], "h": 0, "o": 2}],
        "32": [{"text": ["thirty-two"], "h": 0, "o": 2}],
        "33": [{"text": ["thirty-three"], "h": 0, "o": 2}],
        "34": [{"text": ["thirty-four"], "h": 0, "o": 2}],
        "35": [{"text": ["thirty-five"], "h": 0, "o": 2}],
        "36": [{"text": ["thirty-six"], "h": 0, "o": 2}],
        "37": [{"text": ["thirty-seven"], "h": 0, "o": 2}],
        "38": [{"text": ["thirty-eight"], "h": 0, "o": 2}],
        "39": [{"text": ["thirty-nine"], "h": 0, "o": 2}],
        "40": [
            {"text": ["forty"], "h": 0, "o": 2},
            {"text": ["twenty", "til"], "h": 1, "o": 1},
            {"text": ["twenty", "to"], "h": 1, "o": 1},
        ],
        "41": [{"text": ["forty-one"], "h": 0, "o": 2}],
        "42": [{"text": ["forty-two"], "h": 0, "o": 2}],
        "43": [{"text": ["forty-three"], "h": 0, "o": 2}],
        "44": [{"text": ["forty-four"], "h": 0, "o": 2}],
        "45": [
            {"text": ["forty-five"], "h": 0, "o": 2},
            {"text": ["quarter", "til"], "h": 1, "o": 1},
            {"text": ["quarter", "to"], "h": 1, "o": 1},
        ],
        "46": [{"text": ["forty-six"], "h": 0, "o": 2}],
        "47": [{"text": ["forty-seven"], "h": 0, "o": 2}],
        "48": [{"text": ["forty-eight"], "h": 0, "o": 2}],
        "49": [{"text": ["forty-nine"], "h": 0, "o": 2}],
        "50": [
            {"text": ["fifty"], "h": 0, "o": 2},
            {"text": ["ten", "til"], "h": 1, "o": 1},
            {"text": ["ten", "to"], "h": 1, "o": 1},
        ],
        "51": [
            {"text": ["fifty-one"], "h": 0, "o": 2},
            {"text": ["nine", "til"], "h": 1, "o": 1},
            {"text": ["nine", "to"], "h": 1, "o": 1},
        ],
        "52": [
            {"text": ["fifty-two"], "h": 0, "o": 2},
            {"text": ["eight", "til"], "h": 1, "o": 1},
            {"text": ["eight", "to"], "h": 1, "o": 1},
        ],
        "53": [
            {"text": ["fifty-three"], "h": 0, "o": 2},
            {"text": ["seven", "til"], "h": 1, "o": 1},
            {"text": ["seven", "to"], "h": 1, "o": 1},
        ],
        "54": [
            {"text": ["fifty-four"], "h": 0, "o": 2},
            {"text": ["six", "til"], "h": 1, "o": 1},
            {"text": ["six", "to"], "h": 1, "o": 1},
        ],
        "55": [
            {"text": ["fifty-five"], "h": 0, "o": 2},
            {"text": ["five", "til"], "h": 1, "o": 1},
            {"text": ["five", "to"], "h": 1, "o": 1},
        ],
        "56": [
            {"text": ["fifty-six"], "h": 0, "o": 2},
            {"text": ["four", "til"], "h": 1, "o": 1},
            {"text": ["four", "to"], "h": 1, "o": 1},
        ],
        "57": [
            {"text": ["fifty-seven"], "h": 0, "o": 2},
            {"text": ["three", "til"], "h": 1, "o": 1},
            {"text": ["three", "to"], "h": 1, "o": 1},
        ],
        "58": [
            {"text": ["fifty-eight"], "h": 0, "o": 2},
            {"text": ["two", "til"], "h": 1, "o": 1},
            {"text": ["two", "to"], "h": 1, "o": 1},
        ],
        "59": [
            {"text": ["fifty-nine"], "h": 0, "o": 2},
            {"text": ["one", "til"], "h": 1, "o": 1},
            {"text": ["one", "to"], "h": 1, "o": 1},
        ],
    },
    "fr-FR": {
        "0": [
            {"text": [], "h": 0, "o": 2, "military": True},
            {"text": [], "h": 0, "o": 2},
            {"text": ["pile"], "h": 0, "o": 2},
        ],
        "1": [
            {"text": ["une"], "h": 0, "o": 2, "military": True},
            {"text": ["une"], "h": 0, "o": 2},
        ],
        "2": [
            {"text": ["deux"], "h": 0, "o": 2, "military": True},
            {"text": ["deux"], "h": 0, "o": 2},
        ],
        "3": [
            {"text": ["trois"], "h": 0, "o": 2, "military": True},
            {"text": ["trois"], "h": 0, "o": 2},
        ],
        "4": [
            {"text": ["quatre"], "h": 0, "o": 2, "military": True},
            {"text": ["quatre"], "h": 0, "o": 2},
        ],
        "5": [
            {"text": ["cinq"], "h": 0, "o": 2, "military": True},
            {"text": ["cinq"], "h": 0, "o": 2},
        ],
        "6": [
            {"text": ["six"], "h": 0, "o": 2, "military": True},
            {"text": ["six"], "h": 0, "o": 2},
        ],
        "7": [
            {"text": ["sept"], "h": 0, "o": 2, "military": True},
            {"text": ["sept"], "h": 0, "o": 2},
        ],
        "8": [
            {"text": ["huit"], "h": 0, "o": 2, "military": True},
            {"text": ["huit"], "h": 0, "o": 2},
        ],
        "9": [
            {"text": ["neuf"], "h": 0, "o": 2, "military": True},
            {"text": ["neuf"], "h": 0, "o": 2},
        ],
        "10": [
            {"text": ["dix"], "h": 0, "o": 2, "military": True},
        ],
        "11": [
            {"text": ["onze"], "h": 0, "o": 2, "military": True},
        ],
        "12": [
            {"text": ["douze"], "h": 0, "o": 2, "military": True},
        ],
        "13": [
            {"text": ["treize"], "h": 0, "o": 2, "military": True},
        ],
        "14": [
            {"text": ["quatorze"], "h": 0, "o": 2, "military": True},
        ],
        "15": [
            {"text": ["quinze"], "h": 0, "o": 2, "military": True},
            {"text": ["et quart"], "h": 0, "o": 2},
        ],
        "16": [
            {"text": ["seize"], "h": 0, "o": 2, "military": True},
        ],
        "17": [
            {"text": ["dix-sept"], "h": 0, "o": 2, "military": True},
        ],
        "18": [
            {"text": ["dix-huit"], "h": 0, "o": 2, "military": True},
        ],
        "19": [
            {"text": ["dix-neuf"], "h": 0, "o": 2, "military": True},
        ],
        "20": [
            {"text": ["vingt"], "h": 0, "o": 2, "military": True},
        ],
        "21": [
            {"text": ["vingt", "et-une"], "h": 0, "o": 2, "military": True},
        ],
        "22": [
            {"text": ["vingt-deux"], "h": 0, "o": 2, "military": True},
        ],
        "23": [
            {"text": ["vingt-trois"], "h": 0, "o": 2, "military": True},
        ],
        "24": [
            {"text": ["vingt", "quatre"], "h": 0, "o": 2, "military": True},
        ],
        "25": [
            {"text": ["vingt-cinq"], "h": 0, "o": 2, "military": True},
        ],
        "26": [
            {"text": ["vingt-six"], "h": 0, "o": 2, "military": True},
        ],
        "27": [
            {"text": ["vingt-sept"], "h": 0, "o": 2, "military": True},
        ],
        "28": [
            {"text": ["vingt-huit"], "h": 0, "o": 2, "military": True},
        ],
        "29": [
            {"text": ["vingt-neuf"], "h": 0, "o": 2, "military": True},
        ],
        "30": [
            {"text": ["trente"], "h": 0, "o": 2, "military": True},
            {"text": ["et demie"], "h": 0, "o": 2},
        ],
        "31": [
            {"text": ["trente", "et-une"], "h": 0, "o": 2, "military": True},
        ],
        "32": [
            {"text": ["trente-deux"], "h": 0, "o": 2, "military": True},
        ],
        "33": [
            {"text": ["trente-trois"], "h": 0, "o": 2, "military": True},
        ],
        "34": [
            {"text": ["trente", "quatre"], "h": 0, "o": 2, "military": True},
        ],
        "35": [
            {"text": ["trente-cinq"], "h": 0, "o": 2, "military": True},
            {"text": ["moins", "vingt-cinq"], "h": 1, "o": 2},
        ],
        "36": [
            {"text": ["trente-six"], "h": 0, "o": 2, "military": True},
        ],
        "37": [
            {"text": ["trente-sept"], "h": 0, "o": 2, "military": True},
        ],
        "38": [
            {"text": ["trente-huit"], "h": 0, "o": 2, "military": True},
        ],
        "39": [
            {"text": ["trente-neuf"], "h": 0, "o": 2, "military": True},
        ],
        "40": [
            {"text": ["quarante"], "h": 0, "o": 2, "military": True},
            {"text": ["moins", "vingt"], "h": 1, "o": 2},
        ],
        "41": [
            {"text": ["quarante", "et-une"], "h": 0, "o": 2, "military": True},
        ],
        "42": [
            {"text": ["quarante", "deux"], "h": 0, "o": 2, "military": True},
        ],
        "43": [
            {"text": ["quarante", "trois"], "h": 0, "o": 2, "military": True},
        ],
        "44": [
            {"text": ["quarante", "quatre"], "h": 0, "o": 2, "military": True},
        ],
        "45": [
            {"text": ["quarante", "cinq"], "h": 0, "o": 2, "military": True},
            {"text": ["moins", "le quart"], "h": 1, "o": 2},
        ],
        "46": [
            {"text": ["quarante", "six"], "h": 0, "o": 2, "military": True},
        ],
        "47": [
            {"text": ["quarante", "sept"], "h": 0, "o": 2, "military": True},
        ],
        "48": [
            {"text": ["quarante", "huit"], "h": 0, "o": 2, "military": True},
        ],
        "49": [
            {"text": ["quarante", "neuf"], "h": 0, "o": 2, "military": True},
        ],
        "50": [
            {"text": ["cinquante"], "h": 0, "o": 2, "military": True},
            {"text": ["moins", "dix"], "h": 1, "o": 2},
        ],
        "51": [
            {"text": ["cinquante", "et-une"], "h": 0, "o": 2, "military": True},
            {"text": ["moins", "neuf"], "h": 1, "o": 2},
        ],
        "52": [
            {"text": ["cinquante", "deux"], "h": 0, "o": 2, "military": True},
            {"text": ["moins", "huit"], "h": 1, "o": 2},
        ],
        "53": [
            {"text": ["cinquante", "trois"], "h": 0, "o": 2, "military": True},
            {"text": ["moins", "sept"], "h": 1, "o": 2},
        ],
        "54": [
            {"text": ["cinquante", "quatre"], "h": 0, "o": 2, "military": True},
            {"text": ["moins", "six"], "h": 1, "o": 2},
        ],
        "55": [
            {"text": ["cinquante", "cinq"], "h": 0, "o": 2, "military": True},
            {"text": ["moins", "cinq"], "h": 1, "o": 2},
        ],
        "56": [
            {"text": ["cinquante", "six"], "h": 0, "o": 2, "military": True},
            {"text": ["moins", "quatre"], "h": 1, "o": 2},
        ],
        "57": [
            {"text": ["cinquante", "sept"], "h": 0, "o": 2, "military": True},
            {"text": ["moins", "trois"], "h": 1, "o": 2},
        ],
        "58": [
            {"text": ["cinquante", "huit"], "h": 0, "o": 2, "military": True},
            {"text": ["moins", "deux"], "h": 1, "o": 2},
        ],
        "59": [
            {"text": ["cinquante", "neuf"], "h": 0, "o": 2, "military": True},
            {"text": ["moins", "une"], "h": 1, "o": 2},
        ],
    },
}

timeOfDayObj = {
    "en-US": [
        {"hourMin": 0, "hourMax": 12, "text": [["in the", "morning"], ["AM"]]},
        {"hourMin": 12, "hourMax": 17, "text": [["in the", "afternoon"], ["PM"]]},
        {"hourMin": 17, "hourMax": 21, "text": [["in the", "evening"], ["PM"]]},
        {"hourMin": 21, "hourMax": 24, "text": [["at night"], ["PM"]]},
    ],
    # French ranges are not the English ones: 21:00-23:59 is "du soir", never
    # "de la nuit", and midi/minuit take no complement at all. Ranges must stay
    # disjoint -- time_of_day() concatenates every match rather than picking one.
    "fr-FR": [
        {"hourMin": 0, "hourMax": 1, "text": [[]]},
        {"hourMin": 1, "hourMax": 5, "text": [["du matin"], ["de la nuit"]]},
        {"hourMin": 5, "hourMax": 12, "text": [["du matin"]]},
        {"hourMin": 12, "hourMax": 13, "text": [[]]},
        {"hourMin": 13, "hourMax": 18, "text": [["de l'après-midi"]]},
        {"hourMin": 18, "hourMax": 24, "text": [["du soir"]]},
    ],
}

hoursObj = {
    "en-US": {
        "0": ["twelve", "zero"],
        "1": ["one"],
        "2": ["two"],
        "3": ["three"],
        "4": ["four"],
        "5": ["five"],
        "6": ["six"],
        "7": ["seven"],
        "8": ["eight"],
        "9": ["nine"],
        "10": ["ten"],
        "11": ["eleven"],
        "12": ["twelve"],
        "13": ["one", "thirteen"],
        "14": ["two", "fourteen"],
        "15": ["three", "fifteen"],
        "16": ["four", "sixteen"],
        "17": ["five", "seventeen"],
        "18": ["six", "eighteen"],
        "19": ["seven", "nineteen"],
        "20": ["eight", "twenty"],
        "21": ["nine", "twenty-one"],
        "22": ["ten", "twenty-two"],
        "23": ["eleven", "twenty-three"],
    },
    # Index 0 is the 12-hour word and carries the hour noun, because agreement
    # depends on the hour ("une heure" vs "deux heures"). Index -1 is the bare
    # 24-hour numeral: "dix-sept heures" is 70px on a 63px line, so military_time()
    # renders the noun as its own line instead.
    "fr-FR": {
        "0": ["minuit", "zéro"],
        "1": ["une heure", "une"],
        "2": ["deux heures", "deux"],
        "3": ["trois heures", "trois"],
        "4": ["quatre heures", "quatre"],
        "5": ["cinq heures", "cinq"],
        "6": ["six heures", "six"],
        "7": ["sept heures", "sept"],
        "8": ["huit heures", "huit"],
        "9": ["neuf heures", "neuf"],
        "10": ["dix heures", "dix"],
        "11": ["onze heures", "onze"],
        "12": ["midi", "douze"],
        "13": ["une heure", "treize"],
        "14": ["deux heures", "quatorze"],
        "15": ["trois heures", "quinze"],
        "16": ["quatre heures", "seize"],
        "17": ["cinq heures", "dix-sept"],
        "18": ["six heures", "dix-huit"],
        "19": ["sept heures", "dix-neuf"],
        "20": ["huit heures", "vingt"],
        "21": ["neuf heures", "vingt-et-une"],
        "22": ["dix heures", "vingt-deux"],
        "23": ["onze heures", "vingt-trois"],
    },
}

gameOfThronesObj = {
    "en-US": {
        "stem": "hour of the ",
        "0": "owl",
        "1": "owl",
        "2": "wolf",
        "3": "wolf",
        "4": "nightengale",
        "5": "nightengale",
        "6": "",
        "7": "",
        "8": "",
        "9": "",
        "10": "",
        "11": "",
        "12": "",
        "13": "",
        "14": "",
        "15": "",
        "16": "",
        "17": "",
        "18": "bat",
        "19": "bat",
        "20": "eel",
        "21": "eel",
        "22": "ghosts",
        "23": "ghosts",
    },
    # Not translated: the hour names belong to an English-language franchise and
    # game_of_thrones() is gated to en-US. The key still has to exist, because
    # main() indexes this table for whatever dialect is selected.
    "fr-FR": {
        "stem": "",
        "0": "",
        "1": "",
        "2": "",
        "3": "",
        "4": "",
        "5": "",
        "6": "",
        "7": "",
        "8": "",
        "9": "",
        "10": "",
        "11": "",
        "12": "",
        "13": "",
        "14": "",
        "15": "",
        "16": "",
        "17": "",
        "18": "",
        "19": "",
        "20": "",
        "21": "",
        "22": "",
        "23": "",
    },
}

specialObj = {
    "en-US": {
        "0:0": [["midnight"], ["twelve"], ["twelve", "o'clock"]],
        "12:0": [["noon"], ["twelve"], ["twelve", "o'clock"]],
    },
    # The :30 entries carry the one agreement the minute table cannot express:
    # postposed "demi" agrees with the noun before it, so it is "huit heures et
    # demie" but "midi et demi". A minute entry cannot know which hour it landed on.
    "fr-FR": {
        "0:0": [["minuit"], ["minuit", "pile"]],
        "0:30": [["minuit", "et demi"], ["minuit", "trente"]],
        "12:0": [["midi"], ["midi", "pile"]],
        "12:30": [["midi", "et demi"], ["midi", "trente"]],
    },
}

# Everything about a dialect that is behaviour rather than vocabulary.
#
# subtitleFont     CG-pixel-3x5-mono has no accented glyphs at all -- they render
#                  zero-width, so "l'après-midi" would come out "l'aprs-midi".
#                  tom-thumb is the same size class and does carry them.
# subtitleHeight   the glyph box plus the 1px padding above and below each line.
# subtitleCascade  whether the subtitle keeps stepping right under the time.
#                  French complements are long ("de l'après-midi" is 59px of a
#                  63px line), so they start at the margin instead.
# militaryPad      English pads a 24-hour hour ("zero eight hundred"). French
#                  speaks no leading zero: 07:05 is "sept heures cinq".
# militaryNoun     dialects that say an hour noun get it as its own line, so a
#                  long hour word ("dix-sept heures") never outgrows the panel.
#                  Singular first: "zéro heure", "une heure", "vingt-et-une heures".
# ampm             empty for dialects that have no such convention. French has
#                  none, and "AM" is actively misleading -- it reads as "après-midi".
# dayPartFollowsHourWord
#                  which hour the part-of-day complement describes. In French it
#                  belongs to the hour that was spoken, so "moins" times take the
#                  complement of the hour they count back from -- 17:50 is "six
#                  heures moins dix du soir", and 11:45 is "midi moins le quart"
#                  with none at all. English says "quarter til twelve in the
#                  morning", where the complement still describes 11:45.
dialectObj = {
    "en-US": {
        "subtitleFont": "CG-pixel-3x5-mono",
        "subtitleHeight": 7,
        "subtitleCascade": True,
        "militaryPad": "zero ",
        "militaryNoun": [],
        "ampm": ["AM", "PM"],
        "dayPartFollowsHourWord": False,
    },
    "fr-FR": {
        "subtitleFont": "tom-thumb",
        "subtitleHeight": 8,
        "subtitleCascade": False,
        "militaryPad": "",
        "militaryNoun": ["heure", "heures"],
        "ampm": [],
        "dayPartFollowsHourWord": True,
    },
}

def military_time(hour, min, hours, minutes, rules):
    returnTime = []

    # add hour text
    hourText = ""
    if rules["militaryPad"] and hour < 10 and hour > 0:
        hourText += rules["militaryPad"]
    hourText += hours[str(hour)][-1]
    returnTime.append(hourText)

    if rules["militaryNoun"]:
        returnTime.append(rules["militaryNoun"][0] if hour <= 1 else rules["militaryNoun"][1])

    # add minutes text
    returnTime += minutes[str(min)][0]["text"]

    return returnTime

def display_time(hour, min, hours, minutes, special, config):
    returnTime = []

    # a time the dialect words specially (noon, midnight, "midi et demi")
    specialKey = (":").join([str(hour), str(min)])

    if config.get("display", "random") == "random":
        if specialKey in special:
            specialIndex = random.number(0, len(special[specialKey]) - 1)
            for i in special[specialKey][specialIndex]:
                returnTime.append(i)
            return returnTime, hour
        else:
            # handle all other times
            # get hour text options
            thisHourText = hours[str(hour)][0]
            nextHourIndex = 0 if hour == 23 else hour + 1
            nextHourText = hours[str(nextHourIndex)][0]

            # get a random entry of the minute (that isn't military time)
            minuteMinimum = 1 if min < 10 and len(minutes[str(min)]) > 1 else 0
            minuteMaximum = len(minutes[str(min)]) - 1
            minuteIndex = random.number(minuteMinimum, minuteMaximum)
            minuteObj = minutes[str(min)][minuteIndex]

            # format the minuteObj according to its internal rules:
            # h is whether to use the subsequent hour word
            # o is whether the text comes before (1) or after (2) the hour word
            hourWord = thisHourText if minuteObj["h"] == 0 else nextHourText
            spokenHour = hour if minuteObj["h"] == 0 else nextHourIndex
            minuteWord = minuteObj["text"]
            if minuteObj["o"] == 1:
                if len(minuteWord) > 1:
                    minuteWord = [minuteWord[0], " ".join([minuteWord[1], hourWord])]
                    return minuteWord, spokenHour
                else:
                    returnTime = minuteWord + [hourWord] if minuteObj["text"] != "" else [hourWord]
                    return returnTime, spokenHour
            else:  # minuteObj["o"] == 2
                returnTime = [hourWord] + minuteWord if minuteObj["text"] != "" else [hourWord]
                return returnTime, spokenHour

    else:
        # account for noon/midnight
        if specialKey in special:
            returnTime += special[specialKey][0]

        else:
            # add hour text
            returnTime.append(hours[str(hour)][0])

            # add minutes text
            minIndex = 1 if min < 10 and len(minutes[str(min)]) > 1 else 0  # avoid military times
            minutesTime = minutes[str(min)][minIndex]["text"]
            returnTime += minutesTime

        return returnTime, hour

def game_of_thrones(hour, gameOfThrones, dialect):
    returnTime = []
    if dialect != "en-US":
        return returnTime
    if len(gameOfThrones[str(hour)]) > 0:
        returnTime = [gameOfThrones["stem"], gameOfThrones[str(hour)]]
    return returnTime

def time_of_day(hour, timeOfDay, config, rules):
    returnTime = []
    basic = config.get("display", False) == "basic"

    if config.bool("military", False):  # don't show anything
        return returnTime
    elif basic and rules["ampm"]:  # just show AM/PM
        return [rules["ampm"][0]] if hour < 12 else [rules["ampm"][1]]
    else:  # a dialect without AM/PM says the part of day instead
        for timeRange in timeOfDay:
            if hour >= timeRange["hourMin"] and hour < timeRange["hourMax"]:
                rangeIndex = 0 if basic else random.number(0, len(timeRange["text"]) - 1)
                returnTime += timeRange["text"][rangeIndex]
        return returnTime

def calculate_top_margin(showTime, subTime, littleH):
    fullHeight = 32
    bigH = 8

    topMargin = int(math.ceil((fullHeight - (bigH * len(showTime)) - (littleH * len(subTime))) / 2))

    # a negative margin silently slices the top off the first line
    return topMargin if topMargin > 0 else 0

def main(config):
    location = config.get("location")
    loc = json.decode(location) if location else DEFAULT_LOCATION
    timezone = loc.get("timezone", DEFAULT_TIMEZONE)
    now = time.now().in_location(timezone)

    # get the current time
    hour = now.hour
    min = now.minute

    # set the dialect globally; an unknown value would abort the render
    dialect = config.get("dialect", "en-US")
    if dialect not in hoursObj:
        dialect = "en-US"
    minutes = minutesObj[dialect]
    timeOfDay = timeOfDayObj[dialect]
    hours = hoursObj[dialect]
    gameOfThrones = gameOfThronesObj[dialect]
    special = specialObj[dialect]
    rules = dialectObj[dialect]

    # apply the config rules
    showTime = []
    subTime = []
    dayPartHour = hour
    if config.bool("military", False):  # use Military Time
        showTime = military_time(hour, min, hours, minutes, rules)
    else:  # basic vs. surprise me
        showTime, spokenHour = display_time(hour, min, hours, minutes, special, config)
        if rules["dayPartFollowsHourWord"]:
            dayPartHour = spokenHour

    # add GoT description or add time of day
    if config.bool("game_of_thrones"):
        subTime = game_of_thrones(hour, gameOfThrones, dialect)
    if config.bool("time_of_day") and subTime == []:
        subTime = time_of_day(dayPartHour, timeOfDay, config, rules)

    # the panel is 32px tall; drop the subtitle rather than clip the time
    if (8 * len(showTime)) + (rules["subtitleHeight"] * len(subTime)) > 32:
        subTime = []

    # apply lettercase styling
    if config.get("caps", "caps") == "caps":
        showTime = [i.upper() for i in showTime]
        subTime = [i.upper() for i in subTime]

    # render the words
    textTime = [render.Text(" " * i + s) for i, s in enumerate(showTime)]

    subIndent = len(showTime) if rules["subtitleCascade"] else 0

    textTime += [render.Padding(
        pad = (0, 1, 0, 1),
        child = render.Text(" " * subIndent + " " * i + s, font = rules["subtitleFont"]),
    ) for i, s in enumerate(subTime)]

    # center the text vertically
    topMargin = calculate_top_margin(showTime, subTime, rules["subtitleHeight"])

    # once the column already fills the panel, a bottom pad costs it a row --
    # and that row is where the descenders of the last line live
    bottomPad = 1 if topMargin > 0 else 0

    return render.Root(
        child = render.Padding(
            pad = (1, topMargin, 0, bottomPad),
            child = render.Column(
                children = textTime,
            ),
        ),
    )

def get_schema():
    dialectOptions = [
        schema.Option(
            display = "American English",
            value = "en-US",
        ),
        schema.Option(
            display = "Français (France)",
            value = "fr-FR",
        ),
    ]

    displayOptions = [
        schema.Option(
            display = "Basic",
            value = "basic",
        ),
        schema.Option(
            display = "Random",
            value = "random",
        ),
    ]

    capsOptions = [
        schema.Option(
            display = "CAPS",
            value = "caps",
        ),
        schema.Option(
            display = "lowercase",
            value = "lower",
        ),
    ]

    # icons from: https://fontawesome.com/
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                icon = "locationDot",
                desc = "Location for which to display time",
            ),
            schema.Dropdown(
                id = "dialect",
                name = "Language",
                icon = "language",
                desc = "Language in which to display time",
                default = dialectOptions[0].value,
                options = dialectOptions,
            ),
            schema.Dropdown(
                id = "caps",
                name = "Text Case",
                icon = "font",
                desc = "CAPS vs. lowercase",
                default = capsOptions[0].value,
                options = capsOptions,
            ),
            schema.Dropdown(
                id = "display",
                name = "Display",
                icon = "shuffle",
                desc = "Basic times vs. surprise me",
                default = displayOptions[1].value,
                options = displayOptions,
            ),
            schema.Toggle(
                id = "time_of_day",
                name = "Time of Day",
                desc = "Indication of AM/PM",
                icon = "moon",
                default = False,
            ),
            schema.Toggle(
                id = "game_of_thrones",
                name = "Game of Thrones",
                desc = "Nighttime hour descriptions",
                icon = "chessRook",
                default = False,
            ),
            schema.Toggle(
                id = "military",
                name = "Military Time",
                desc = "24-hour times",
                icon = "jetFighter",
                default = False,
            ),
        ],
    )
