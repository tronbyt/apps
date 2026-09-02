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
    "de-DE": {
        "0": [
            {"text": [], "h": 0, "o": 2, "military": True},
            {"text": [], "h": 0, "o": 2},
            {"text": ["Punkt"], "h": 0, "o": 1},
        ],
        "1": [
            {"text": ["eins"], "h": 0, "o": 2, "military": True},
            {"text": ["eins"], "h": 0, "o": 2},
            {"text": ["kurz", "nach"], "h": 0, "o": 1},
        ],
        "2": [
            {"text": ["zwei"], "h": 0, "o": 2, "military": True},
            {"text": ["zwei"], "h": 0, "o": 2},
        ],
        "3": [
            {"text": ["drei"], "h": 0, "o": 2, "military": True},
            {"text": ["drei"], "h": 0, "o": 2},
        ],
        "4": [
            {"text": ["vier"], "h": 0, "o": 2, "military": True},
            {"text": ["vier"], "h": 0, "o": 2},
        ],
        "5": [
            {"text": ["fünf"], "h": 0, "o": 2, "military": True},
            {"text": ["fünf"], "h": 0, "o": 2},
            {"text": ["fünf", "nach"], "h": 0, "o": 1},
        ],
        "6": [
            {"text": ["sechs"], "h": 0, "o": 2, "military": True},
            {"text": ["sechs"], "h": 0, "o": 2},
        ],
        "7": [
            {"text": ["sieben"], "h": 0, "o": 2, "military": True},
            {"text": ["sieben"], "h": 0, "o": 2},
        ],
        "8": [
            {"text": ["acht"], "h": 0, "o": 2, "military": True},
            {"text": ["acht"], "h": 0, "o": 2},
        ],
        "9": [
            {"text": ["neun"], "h": 0, "o": 2, "military": True},
            {"text": ["neun"], "h": 0, "o": 2},
        ],
        "10": [
            {"text": ["zehn"], "h": 0, "o": 2, "military": True},
            {"text": ["zehn", "nach"], "h": 0, "o": 1},
        ],
        "11": [
            {"text": ["elf"], "h": 0, "o": 2, "military": True},
        ],
        "12": [
            {"text": ["zwölf"], "h": 0, "o": 2, "military": True},
        ],
        "13": [
            {"text": ["dreizehn"], "h": 0, "o": 2, "military": True},
        ],
        "14": [
            {"text": ["vierzehn"], "h": 0, "o": 2, "military": True},
        ],
        "15": [
            {"text": ["fünfzehn"], "h": 0, "o": 2, "military": True},
            {"text": ["Viertel", "nach"], "h": 0, "o": 1},
        ],
        "16": [
            {"text": ["sechzehn"], "h": 0, "o": 2, "military": True},
        ],
        "17": [
            {"text": ["siebzehn"], "h": 0, "o": 2, "military": True},
        ],
        "18": [
            {"text": ["achtzehn"], "h": 0, "o": 2, "military": True},
        ],
        "19": [
            {"text": ["neunzehn"], "h": 0, "o": 2, "military": True},
        ],
        "20": [
            {"text": ["zwanzig"], "h": 0, "o": 2, "military": True},
            {"text": ["zwanzig", "nach"], "h": 0, "o": 1},
            {"text": ["zehn vor", "halb"], "h": 1, "o": 1},
        ],
        "21": [
            {"text": ["einund", "zwanzig"], "h": 0, "o": 2, "military": True},
        ],
        "22": [
            {"text": ["zweiund", "zwanzig"], "h": 0, "o": 2, "military": True},
        ],
        "23": [
            {"text": ["dreiund", "zwanzig"], "h": 0, "o": 2, "military": True},
        ],
        "24": [
            {"text": ["vierund", "zwanzig"], "h": 0, "o": 2, "military": True},
        ],
        "25": [
            {"text": ["fünfund", "zwanzig"], "h": 0, "o": 2, "military": True},
            {"text": ["fünf vor", "halb"], "h": 1, "o": 1},
        ],
        "26": [
            {"text": ["sechsund", "zwanzig"], "h": 0, "o": 2, "military": True},
        ],
        "27": [
            {"text": ["siebenund", "zwanzig"], "h": 0, "o": 2, "military": True},
        ],
        "28": [
            {"text": ["achtund", "zwanzig"], "h": 0, "o": 2, "military": True},
        ],
        "29": [
            {"text": ["neunund", "zwanzig"], "h": 0, "o": 2, "military": True},
        ],
        "30": [
            {"text": ["dreißig"], "h": 0, "o": 2, "military": True},
            {"text": ["halb"], "h": 1, "o": 1},
        ],
        "31": [
            {"text": ["einund", "dreißig"], "h": 0, "o": 2, "military": True},
        ],
        "32": [
            {"text": ["zweiund", "dreißig"], "h": 0, "o": 2, "military": True},
        ],
        "33": [
            {"text": ["dreiund", "dreißig"], "h": 0, "o": 2, "military": True},
        ],
        "34": [
            {"text": ["vierund", "dreißig"], "h": 0, "o": 2, "military": True},
        ],
        "35": [
            {"text": ["fünfund", "dreißig"], "h": 0, "o": 2, "military": True},
            {"text": ["fünf nach", "halb"], "h": 1, "o": 1},
        ],
        "36": [
            {"text": ["sechsund", "dreißig"], "h": 0, "o": 2, "military": True},
        ],
        "37": [
            {"text": ["siebenund", "dreißig"], "h": 0, "o": 2, "military": True},
        ],
        "38": [
            {"text": ["achtund", "dreißig"], "h": 0, "o": 2, "military": True},
        ],
        "39": [
            {"text": ["neunund", "dreißig"], "h": 0, "o": 2, "military": True},
        ],
        "40": [
            {"text": ["vierzig"], "h": 0, "o": 2, "military": True},
            {"text": ["zwanzig", "vor"], "h": 1, "o": 1},
            {"text": ["zehn nach", "halb"], "h": 1, "o": 1},
        ],
        "41": [
            {"text": ["einund", "vierzig"], "h": 0, "o": 2, "military": True},
        ],
        "42": [
            {"text": ["zweiund", "vierzig"], "h": 0, "o": 2, "military": True},
        ],
        "43": [
            {"text": ["dreiund", "vierzig"], "h": 0, "o": 2, "military": True},
        ],
        "44": [
            {"text": ["vierund", "vierzig"], "h": 0, "o": 2, "military": True},
        ],
        "45": [
            {"text": ["fünfund", "vierzig"], "h": 0, "o": 2, "military": True},
            {"text": ["Viertel", "vor"], "h": 1, "o": 1},
        ],
        "46": [
            {"text": ["sechsund", "vierzig"], "h": 0, "o": 2, "military": True},
        ],
        "47": [
            {"text": ["siebenund", "vierzig"], "h": 0, "o": 2, "military": True},
        ],
        "48": [
            {"text": ["achtund", "vierzig"], "h": 0, "o": 2, "military": True},
        ],
        "49": [
            {"text": ["neunund", "vierzig"], "h": 0, "o": 2, "military": True},
        ],
        "50": [
            {"text": ["fünfzig"], "h": 0, "o": 2, "military": True},
            {"text": ["zehn", "vor"], "h": 1, "o": 1},
        ],
        "51": [
            {"text": ["einund", "fünfzig"], "h": 0, "o": 2, "military": True},
        ],
        "52": [
            {"text": ["zweiund", "fünfzig"], "h": 0, "o": 2, "military": True},
        ],
        "53": [
            {"text": ["dreiund", "fünfzig"], "h": 0, "o": 2, "military": True},
        ],
        "54": [
            {"text": ["vierund", "fünfzig"], "h": 0, "o": 2, "military": True},
        ],
        "55": [
            {"text": ["fünfund", "fünfzig"], "h": 0, "o": 2, "military": True},
            {"text": ["fünf", "vor"], "h": 1, "o": 1},
        ],
        "56": [
            {"text": ["sechsund", "fünfzig"], "h": 0, "o": 2, "military": True},
        ],
        "57": [
            {"text": ["siebenund", "fünfzig"], "h": 0, "o": 2, "military": True},
        ],
        "58": [
            {"text": ["achtund", "fünfzig"], "h": 0, "o": 2, "military": True},
        ],
        "59": [
            {"text": ["neunund", "fünfzig"], "h": 0, "o": 2, "military": True},
            {"text": ["kurz", "vor"], "h": 1, "o": 1},
        ],
    },
    "es-ES": {
        "0": [
            {"text": [], "h": 0, "o": 2, "military": True},
            {"text": [], "h": 0, "o": 2},
            {"text": ["en punto"], "h": 0, "o": 2},
        ],
        "1": [
            {"text": ["uno"], "h": 0, "o": 2, "military": True},
            {"text": ["y un", "minuto"], "h": 0, "o": 2},
        ],
        "2": [
            {"text": ["dos"], "h": 0, "o": 2, "military": True},
            {"text": ["y dos"], "h": 0, "o": 2},
        ],
        "3": [
            {"text": ["tres"], "h": 0, "o": 2, "military": True},
            {"text": ["y tres"], "h": 0, "o": 2},
        ],
        "4": [
            {"text": ["cuatro"], "h": 0, "o": 2, "military": True},
            {"text": ["y cuatro"], "h": 0, "o": 2},
        ],
        "5": [
            {"text": ["cinco"], "h": 0, "o": 2, "military": True},
            {"text": ["y cinco"], "h": 0, "o": 2},
        ],
        "6": [
            {"text": ["seis"], "h": 0, "o": 2, "military": True},
            {"text": ["y seis"], "h": 0, "o": 2},
        ],
        "7": [
            {"text": ["siete"], "h": 0, "o": 2, "military": True},
            {"text": ["y siete"], "h": 0, "o": 2},
        ],
        "8": [
            {"text": ["ocho"], "h": 0, "o": 2, "military": True},
            {"text": ["y ocho"], "h": 0, "o": 2},
        ],
        "9": [
            {"text": ["nueve"], "h": 0, "o": 2, "military": True},
            {"text": ["y nueve"], "h": 0, "o": 2},
        ],
        "10": [
            {"text": ["diez"], "h": 0, "o": 2, "military": True},
            {"text": ["y diez"], "h": 0, "o": 2},
        ],
        "11": [
            {"text": ["once"], "h": 0, "o": 2, "military": True},
            {"text": ["y once"], "h": 0, "o": 2},
        ],
        "12": [
            {"text": ["doce"], "h": 0, "o": 2, "military": True},
            {"text": ["y doce"], "h": 0, "o": 2},
        ],
        "13": [
            {"text": ["trece"], "h": 0, "o": 2, "military": True},
            {"text": ["y trece"], "h": 0, "o": 2},
        ],
        "14": [
            {"text": ["catorce"], "h": 0, "o": 2, "military": True},
            {"text": ["y catorce"], "h": 0, "o": 2},
        ],
        "15": [
            {"text": ["quince"], "h": 0, "o": 2, "military": True},
            {"text": ["y cuarto"], "h": 0, "o": 2},
        ],
        "16": [
            {"text": ["dieciséis"], "h": 0, "o": 2, "military": True},
            {"text": ["y dieciséis"], "h": 0, "o": 2},
        ],
        "17": [
            {"text": ["diecisiete"], "h": 0, "o": 2, "military": True},
            {"text": ["y diecisiete"], "h": 0, "o": 2},
        ],
        "18": [
            {"text": ["dieciocho"], "h": 0, "o": 2, "military": True},
            {"text": ["y dieciocho"], "h": 0, "o": 2},
        ],
        "19": [
            {"text": ["diecinueve"], "h": 0, "o": 2, "military": True},
            {"text": ["y diecinueve"], "h": 0, "o": 2},
        ],
        "20": [
            {"text": ["veinte"], "h": 0, "o": 2, "military": True},
            {"text": ["y veinte"], "h": 0, "o": 2},
        ],
        "21": [
            {"text": ["veintiuno"], "h": 0, "o": 2, "military": True},
            {"text": ["y veintiuno"], "h": 0, "o": 2},
        ],
        "22": [
            {"text": ["veintidós"], "h": 0, "o": 2, "military": True},
            {"text": ["y veintidós"], "h": 0, "o": 2},
        ],
        "23": [
            {"text": ["veintitrés"], "h": 0, "o": 2, "military": True},
            {"text": ["y veintitrés"], "h": 0, "o": 2},
        ],
        "24": [
            {"text": ["veinti", "cuatro"], "h": 0, "o": 2, "military": True},
            {"text": ["y veinti", "cuatro"], "h": 0, "o": 2},
        ],
        "25": [
            {"text": ["veinticinco"], "h": 0, "o": 2, "military": True},
            {"text": ["y veinti", "cinco"], "h": 0, "o": 2},
        ],
        "26": [
            {"text": ["veintiséis"], "h": 0, "o": 2, "military": True},
            {"text": ["y veintiséis"], "h": 0, "o": 2},
        ],
        "27": [
            {"text": ["veintisiete"], "h": 0, "o": 2, "military": True},
            {"text": ["y veinti", "siete"], "h": 0, "o": 2},
        ],
        "28": [
            {"text": ["veintiocho"], "h": 0, "o": 2, "military": True},
            {"text": ["y veintiocho"], "h": 0, "o": 2},
        ],
        "29": [
            {"text": ["veintinueve"], "h": 0, "o": 2, "military": True},
            {"text": ["y veinti", "nueve"], "h": 0, "o": 2},
        ],
        "30": [
            {"text": ["treinta"], "h": 0, "o": 2, "military": True},
            {"text": ["y media"], "h": 0, "o": 2},
        ],
        "31": [
            {"text": ["treinta", "y uno"], "h": 0, "o": 2, "military": True},
            {"text": ["y treinta", "y uno"], "h": 0, "o": 2},
        ],
        "32": [
            {"text": ["treinta", "y dos"], "h": 0, "o": 2, "military": True},
            {"text": ["y treinta", "y dos"], "h": 0, "o": 2},
        ],
        "33": [
            {"text": ["treinta", "y tres"], "h": 0, "o": 2, "military": True},
            {"text": ["y treinta", "y tres"], "h": 0, "o": 2},
        ],
        "34": [
            {"text": ["treinta", "y cuatro"], "h": 0, "o": 2, "military": True},
            {"text": ["y treinta", "y cuatro"], "h": 0, "o": 2},
        ],
        "35": [
            {"text": ["treinta", "y cinco"], "h": 0, "o": 2, "military": True},
            {"text": ["y treinta", "y cinco"], "h": 0, "o": 2},
            {"text": ["menos veinti", "cinco"], "h": 1, "o": 2},
        ],
        "36": [
            {"text": ["treinta", "y seis"], "h": 0, "o": 2, "military": True},
            {"text": ["y treinta", "y seis"], "h": 0, "o": 2},
        ],
        "37": [
            {"text": ["treinta", "y siete"], "h": 0, "o": 2, "military": True},
            {"text": ["y treinta", "y siete"], "h": 0, "o": 2},
        ],
        "38": [
            {"text": ["treinta", "y ocho"], "h": 0, "o": 2, "military": True},
            {"text": ["y treinta", "y ocho"], "h": 0, "o": 2},
        ],
        "39": [
            {"text": ["treinta", "y nueve"], "h": 0, "o": 2, "military": True},
            {"text": ["y treinta", "y nueve"], "h": 0, "o": 2},
        ],
        "40": [
            {"text": ["cuarenta"], "h": 0, "o": 2, "military": True},
            {"text": ["y cuarenta"], "h": 0, "o": 2},
            {"text": ["menos veinte"], "h": 1, "o": 2},
        ],
        "41": [
            {"text": ["cuarenta", "y uno"], "h": 0, "o": 2, "military": True},
            {"text": ["y cuarenta", "y uno"], "h": 0, "o": 2},
        ],
        "42": [
            {"text": ["cuarenta", "y dos"], "h": 0, "o": 2, "military": True},
            {"text": ["y cuarenta", "y dos"], "h": 0, "o": 2},
        ],
        "43": [
            {"text": ["cuarenta", "y tres"], "h": 0, "o": 2, "military": True},
            {"text": ["y cuarenta", "y tres"], "h": 0, "o": 2},
        ],
        "44": [
            {"text": ["cuarenta", "y cuatro"], "h": 0, "o": 2, "military": True},
            {"text": ["y cuarenta", "y cuatro"], "h": 0, "o": 2},
        ],
        "45": [
            {"text": ["cuarenta", "y cinco"], "h": 0, "o": 2, "military": True},
            {"text": ["y cuarenta", "y cinco"], "h": 0, "o": 2},
            {"text": ["menos cuarto"], "h": 1, "o": 2},
        ],
        "46": [
            {"text": ["cuarenta", "y seis"], "h": 0, "o": 2, "military": True},
            {"text": ["y cuarenta", "y seis"], "h": 0, "o": 2},
        ],
        "47": [
            {"text": ["cuarenta", "y siete"], "h": 0, "o": 2, "military": True},
            {"text": ["y cuarenta", "y siete"], "h": 0, "o": 2},
        ],
        "48": [
            {"text": ["cuarenta", "y ocho"], "h": 0, "o": 2, "military": True},
            {"text": ["y cuarenta", "y ocho"], "h": 0, "o": 2},
        ],
        "49": [
            {"text": ["cuarenta", "y nueve"], "h": 0, "o": 2, "military": True},
            {"text": ["y cuarenta", "y nueve"], "h": 0, "o": 2},
        ],
        "50": [
            {"text": ["cincuenta"], "h": 0, "o": 2, "military": True},
            {"text": ["y cincuenta"], "h": 0, "o": 2},
            {"text": ["menos diez"], "h": 1, "o": 2},
        ],
        "51": [
            {"text": ["cincuenta", "y uno"], "h": 0, "o": 2, "military": True},
            {"text": ["y cincuenta", "y uno"], "h": 0, "o": 2},
            {"text": ["menos nueve"], "h": 1, "o": 2},
        ],
        "52": [
            {"text": ["cincuenta", "y dos"], "h": 0, "o": 2, "military": True},
            {"text": ["y cincuenta", "y dos"], "h": 0, "o": 2},
            {"text": ["menos ocho"], "h": 1, "o": 2},
        ],
        "53": [
            {"text": ["cincuenta", "y tres"], "h": 0, "o": 2, "military": True},
            {"text": ["y cincuenta", "y tres"], "h": 0, "o": 2},
            {"text": ["menos siete"], "h": 1, "o": 2},
        ],
        "54": [
            {"text": ["cincuenta", "y cuatro"], "h": 0, "o": 2, "military": True},
            {"text": ["y cincuenta", "y cuatro"], "h": 0, "o": 2},
            {"text": ["menos seis"], "h": 1, "o": 2},
        ],
        "55": [
            {"text": ["cincuenta", "y cinco"], "h": 0, "o": 2, "military": True},
            {"text": ["y cincuenta", "y cinco"], "h": 0, "o": 2},
            {"text": ["menos cinco"], "h": 1, "o": 2},
        ],
        "56": [
            {"text": ["cincuenta", "y seis"], "h": 0, "o": 2, "military": True},
            {"text": ["y cincuenta", "y seis"], "h": 0, "o": 2},
            {"text": ["menos cuatro"], "h": 1, "o": 2},
        ],
        "57": [
            {"text": ["cincuenta", "y siete"], "h": 0, "o": 2, "military": True},
            {"text": ["y cincuenta", "y siete"], "h": 0, "o": 2},
            {"text": ["menos tres"], "h": 1, "o": 2},
        ],
        "58": [
            {"text": ["cincuenta", "y ocho"], "h": 0, "o": 2, "military": True},
            {"text": ["y cincuenta", "y ocho"], "h": 0, "o": 2},
            {"text": ["menos dos"], "h": 1, "o": 2},
        ],
        "59": [
            {"text": ["cincuenta", "y nueve"], "h": 0, "o": 2, "military": True},
            {"text": ["y cincuenta", "y nueve"], "h": 0, "o": 2},
            {"text": ["menos un", "minuto"], "h": 1, "o": 2},
        ],
    },
    "pt-BR": {
        "0": [
            {"text": [], "h": 0, "o": 2, "military": True},
            {"text": [], "h": 0, "o": 2},
            {"text": ["em ponto"], "h": 0, "o": 2},
        ],
        "1": [
            {"text": ["e um"], "h": 0, "o": 2, "military": True},
            {"text": ["e um"], "h": 0, "o": 2},
        ],
        "2": [
            {"text": ["e dois"], "h": 0, "o": 2, "military": True},
            {"text": ["e dois"], "h": 0, "o": 2},
        ],
        "3": [
            {"text": ["e três"], "h": 0, "o": 2, "military": True},
            {"text": ["e três"], "h": 0, "o": 2},
        ],
        "4": [
            {"text": ["e quatro"], "h": 0, "o": 2, "military": True},
            {"text": ["e quatro"], "h": 0, "o": 2},
        ],
        "5": [
            {"text": ["e cinco"], "h": 0, "o": 2, "military": True},
            {"text": ["e cinco"], "h": 0, "o": 2},
        ],
        "6": [
            {"text": ["e seis"], "h": 0, "o": 2, "military": True},
            {"text": ["e seis"], "h": 0, "o": 2},
        ],
        "7": [
            {"text": ["e sete"], "h": 0, "o": 2, "military": True},
            {"text": ["e sete"], "h": 0, "o": 2},
        ],
        "8": [
            {"text": ["e oito"], "h": 0, "o": 2, "military": True},
            {"text": ["e oito"], "h": 0, "o": 2},
        ],
        "9": [
            {"text": ["e nove"], "h": 0, "o": 2, "military": True},
            {"text": ["e nove"], "h": 0, "o": 2},
        ],
        "10": [
            {"text": ["e dez"], "h": 0, "o": 2, "military": True},
        ],
        "11": [
            {"text": ["e onze"], "h": 0, "o": 2, "military": True},
        ],
        "12": [
            {"text": ["e doze"], "h": 0, "o": 2, "military": True},
        ],
        "13": [
            {"text": ["e treze"], "h": 0, "o": 2, "military": True},
        ],
        "14": [
            {"text": ["e quatorze"], "h": 0, "o": 2, "military": True},
        ],
        "15": [
            {"text": ["e quinze"], "h": 0, "o": 2, "military": True},
        ],
        "16": [
            {"text": ["e dezesseis"], "h": 0, "o": 2, "military": True},
        ],
        "17": [
            {"text": ["e dezessete"], "h": 0, "o": 2, "military": True},
        ],
        "18": [
            {"text": ["e dezoito"], "h": 0, "o": 2, "military": True},
        ],
        "19": [
            {"text": ["e dezenove"], "h": 0, "o": 2, "military": True},
        ],
        "20": [
            {"text": ["e vinte"], "h": 0, "o": 2, "military": True},
        ],
        "21": [
            {"text": ["e vinte e um"], "h": 0, "o": 2, "military": True},
        ],
        "22": [
            {"text": ["e vinte", "e dois"], "h": 0, "o": 2, "military": True},
        ],
        "23": [
            {"text": ["e vinte", "e três"], "h": 0, "o": 2, "military": True},
        ],
        "24": [
            {"text": ["e vinte", "e quatro"], "h": 0, "o": 2, "military": True},
        ],
        "25": [
            {"text": ["e vinte", "e cinco"], "h": 0, "o": 2, "military": True},
        ],
        "26": [
            {"text": ["e vinte", "e seis"], "h": 0, "o": 2, "military": True},
        ],
        "27": [
            {"text": ["e vinte", "e sete"], "h": 0, "o": 2, "military": True},
        ],
        "28": [
            {"text": ["e vinte", "e oito"], "h": 0, "o": 2, "military": True},
        ],
        "29": [
            {"text": ["e vinte", "e nove"], "h": 0, "o": 2, "military": True},
        ],
        "30": [
            {"text": ["e trinta"], "h": 0, "o": 2, "military": True},
            {"text": ["e trinta"], "h": 0, "o": 2},
            {"text": ["e meia"], "h": 0, "o": 2},
        ],
        "31": [
            {"text": ["e trinta", "e um"], "h": 0, "o": 2, "military": True},
        ],
        "32": [
            {"text": ["e trinta", "e dois"], "h": 0, "o": 2, "military": True},
        ],
        "33": [
            {"text": ["e trinta", "e três"], "h": 0, "o": 2, "military": True},
        ],
        "34": [
            {"text": ["e trinta", "e quatro"], "h": 0, "o": 2, "military": True},
        ],
        "35": [
            {"text": ["e trinta", "e cinco"], "h": 0, "o": 2, "military": True},
        ],
        "36": [
            {"text": ["e trinta", "e seis"], "h": 0, "o": 2, "military": True},
        ],
        "37": [
            {"text": ["e trinta", "e sete"], "h": 0, "o": 2, "military": True},
        ],
        "38": [
            {"text": ["e trinta", "e oito"], "h": 0, "o": 2, "military": True},
        ],
        "39": [
            {"text": ["e trinta", "e nove"], "h": 0, "o": 2, "military": True},
        ],
        "40": [
            {"text": ["e quarenta"], "h": 0, "o": 2, "military": True},
            {"text": ["vinte para", "as"], "h": 1, "o": 1},
        ],
        "41": [
            {"text": ["e quarenta", "e um"], "h": 0, "o": 2, "military": True},
        ],
        "42": [
            {"text": ["e quarenta", "e dois"], "h": 0, "o": 2, "military": True},
        ],
        "43": [
            {"text": ["e quarenta", "e três"], "h": 0, "o": 2, "military": True},
        ],
        "44": [
            {"text": ["e quarenta", "e quatro"], "h": 0, "o": 2, "military": True},
        ],
        "45": [
            {"text": ["e quarenta", "e cinco"], "h": 0, "o": 2, "military": True},
            {"text": ["quinze para", "as"], "h": 1, "o": 1},
        ],
        "46": [
            {"text": ["e quarenta", "e seis"], "h": 0, "o": 2, "military": True},
        ],
        "47": [
            {"text": ["e quarenta", "e sete"], "h": 0, "o": 2, "military": True},
        ],
        "48": [
            {"text": ["e quarenta", "e oito"], "h": 0, "o": 2, "military": True},
        ],
        "49": [
            {"text": ["e quarenta", "e nove"], "h": 0, "o": 2, "military": True},
        ],
        "50": [
            {"text": ["e cinquenta"], "h": 0, "o": 2, "military": True},
            {"text": ["dez para", "as"], "h": 1, "o": 1},
        ],
        "51": [
            {"text": ["e cinquenta", "e um"], "h": 0, "o": 2, "military": True},
        ],
        "52": [
            {"text": ["e cinquenta", "e dois"], "h": 0, "o": 2, "military": True},
        ],
        "53": [
            {"text": ["e cinquenta", "e três"], "h": 0, "o": 2, "military": True},
        ],
        "54": [
            {"text": ["e cinquenta", "e quatro"], "h": 0, "o": 2, "military": True},
        ],
        "55": [
            {"text": ["e cinquenta", "e cinco"], "h": 0, "o": 2, "military": True},
            {"text": ["cinco para", "as"], "h": 1, "o": 1},
        ],
        "56": [
            {"text": ["e cinquenta", "e seis"], "h": 0, "o": 2, "military": True},
        ],
        "57": [
            {"text": ["e cinquenta", "e sete"], "h": 0, "o": 2, "military": True},
        ],
        "58": [
            {"text": ["e cinquenta", "e oito"], "h": 0, "o": 2, "military": True},
        ],
        "59": [
            {"text": ["e cinquenta", "e nove"], "h": 0, "o": 2, "military": True},
        ],
    },
    "it-IT": {
        "0": [
            {"text": [], "h": 0, "o": 2, "military": True},
            {"text": [], "h": 0, "o": 2},
            {"text": ["in punto"], "h": 0, "o": 2},
        ],
        "1": [
            {"text": ["e un minuto"], "h": 0, "o": 2, "military": True},
            {"text": ["e un minuto"], "h": 0, "o": 2},
        ],
        "2": [
            {"text": ["e due"], "h": 0, "o": 2, "military": True},
            {"text": ["e due"], "h": 0, "o": 2},
        ],
        "3": [
            {"text": ["e tre"], "h": 0, "o": 2, "military": True},
            {"text": ["e tre"], "h": 0, "o": 2},
        ],
        "4": [
            {"text": ["e quattro"], "h": 0, "o": 2, "military": True},
            {"text": ["e quattro"], "h": 0, "o": 2},
        ],
        "5": [
            {"text": ["e cinque"], "h": 0, "o": 2, "military": True},
            {"text": ["e cinque"], "h": 0, "o": 2},
        ],
        "6": [
            {"text": ["e sei"], "h": 0, "o": 2, "military": True},
            {"text": ["e sei"], "h": 0, "o": 2},
        ],
        "7": [
            {"text": ["e sette"], "h": 0, "o": 2, "military": True},
            {"text": ["e sette"], "h": 0, "o": 2},
        ],
        "8": [
            {"text": ["e otto"], "h": 0, "o": 2, "military": True},
            {"text": ["e otto"], "h": 0, "o": 2},
        ],
        "9": [
            {"text": ["e nove"], "h": 0, "o": 2, "military": True},
            {"text": ["e nove"], "h": 0, "o": 2},
        ],
        "10": [
            {"text": ["e dieci"], "h": 0, "o": 2, "military": True},
        ],
        "11": [
            {"text": ["e undici"], "h": 0, "o": 2, "military": True},
        ],
        "12": [
            {"text": ["e dodici"], "h": 0, "o": 2, "military": True},
        ],
        "13": [
            {"text": ["e tredici"], "h": 0, "o": 2, "military": True},
        ],
        "14": [
            {"text": ["e", "quattordici"], "h": 0, "o": 2, "military": True},
        ],
        "15": [
            {"text": ["e quindici"], "h": 0, "o": 2, "military": True},
            {"text": ["e quindici"], "h": 0, "o": 2},
            {"text": ["e un quarto"], "h": 0, "o": 2},
        ],
        "16": [
            {"text": ["e sedici"], "h": 0, "o": 2, "military": True},
        ],
        "17": [
            {"text": ["e", "diciassette"], "h": 0, "o": 2, "military": True},
        ],
        "18": [
            {"text": ["e diciotto"], "h": 0, "o": 2, "military": True},
        ],
        "19": [
            {"text": ["e", "diciannove"], "h": 0, "o": 2, "military": True},
        ],
        "20": [
            {"text": ["e venti"], "h": 0, "o": 2, "military": True},
        ],
        "21": [
            {"text": ["e ventuno"], "h": 0, "o": 2, "military": True},
        ],
        "22": [
            {"text": ["e ventidue"], "h": 0, "o": 2, "military": True},
        ],
        "23": [
            {"text": ["e ventitré"], "h": 0, "o": 2, "military": True},
        ],
        "24": [
            {"text": ["e venti", "quattro"], "h": 0, "o": 2, "military": True},
        ],
        "25": [
            {"text": ["e venti", "cinque"], "h": 0, "o": 2, "military": True},
        ],
        "26": [
            {"text": ["e ventisei"], "h": 0, "o": 2, "military": True},
        ],
        "27": [
            {"text": ["e ventisette"], "h": 0, "o": 2, "military": True},
        ],
        "28": [
            {"text": ["e ventotto"], "h": 0, "o": 2, "military": True},
        ],
        "29": [
            {"text": ["e ventinove"], "h": 0, "o": 2, "military": True},
        ],
        "30": [
            {"text": ["e trenta"], "h": 0, "o": 2, "military": True},
            {"text": ["e trenta"], "h": 0, "o": 2},
            {"text": ["e mezza"], "h": 0, "o": 2},
        ],
        "31": [
            {"text": ["e trentuno"], "h": 0, "o": 2, "military": True},
        ],
        "32": [
            {"text": ["e trentadue"], "h": 0, "o": 2, "military": True},
        ],
        "33": [
            {"text": ["e trentatré"], "h": 0, "o": 2, "military": True},
        ],
        "34": [
            {"text": ["e trenta", "quattro"], "h": 0, "o": 2, "military": True},
        ],
        "35": [
            {"text": ["e trenta", "cinque"], "h": 0, "o": 2, "military": True},
            {"text": ["meno venti", "cinque"], "h": 1, "o": 2},
        ],
        "36": [
            {"text": ["e trentasei"], "h": 0, "o": 2, "military": True},
        ],
        "37": [
            {"text": ["e trenta", "sette"], "h": 0, "o": 2, "military": True},
        ],
        "38": [
            {"text": ["e trentotto"], "h": 0, "o": 2, "military": True},
        ],
        "39": [
            {"text": ["e trenta", "nove"], "h": 0, "o": 2, "military": True},
        ],
        "40": [
            {"text": ["e quaranta"], "h": 0, "o": 2, "military": True},
            {"text": ["meno venti"], "h": 1, "o": 2},
        ],
        "41": [
            {"text": ["e quaran", "tuno"], "h": 0, "o": 2, "military": True},
        ],
        "42": [
            {"text": ["e quaranta", "due"], "h": 0, "o": 2, "military": True},
        ],
        "43": [
            {"text": ["e quaranta", "tré"], "h": 0, "o": 2, "military": True},
        ],
        "44": [
            {"text": ["e quaranta", "quattro"], "h": 0, "o": 2, "military": True},
        ],
        "45": [
            {"text": ["e quaranta", "cinque"], "h": 0, "o": 2, "military": True},
            {"text": ["meno", "un quarto"], "h": 1, "o": 2},
        ],
        "46": [
            {"text": ["e quaranta", "sei"], "h": 0, "o": 2, "military": True},
        ],
        "47": [
            {"text": ["e quaranta", "sette"], "h": 0, "o": 2, "military": True},
        ],
        "48": [
            {"text": ["e quaran", "totto"], "h": 0, "o": 2, "military": True},
        ],
        "49": [
            {"text": ["e quaranta", "nove"], "h": 0, "o": 2, "military": True},
        ],
        "50": [
            {"text": ["e cinquanta"], "h": 0, "o": 2, "military": True},
            {"text": ["meno dieci"], "h": 1, "o": 2},
        ],
        "51": [
            {"text": ["e cinquan", "tuno"], "h": 0, "o": 2, "military": True},
        ],
        "52": [
            {"text": ["e cinquanta", "due"], "h": 0, "o": 2, "military": True},
        ],
        "53": [
            {"text": ["e cinquanta", "tré"], "h": 0, "o": 2, "military": True},
        ],
        "54": [
            {"text": ["e cinquanta", "quattro"], "h": 0, "o": 2, "military": True},
        ],
        "55": [
            {"text": ["e cinquanta", "cinque"], "h": 0, "o": 2, "military": True},
            {"text": ["meno cinque"], "h": 1, "o": 2},
        ],
        "56": [
            {"text": ["e cinquanta", "sei"], "h": 0, "o": 2, "military": True},
        ],
        "57": [
            {"text": ["e cinquanta", "sette"], "h": 0, "o": 2, "military": True},
        ],
        "58": [
            {"text": ["e cinquan", "totto"], "h": 0, "o": 2, "military": True},
        ],
        "59": [
            {"text": ["e cinquanta", "nove"], "h": 0, "o": 2, "military": True},
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
    "de-DE": [
        {"hourMin": 0, "hourMax": 5, "text": [["nachts"]]},
        {"hourMin": 5, "hourMax": 10, "text": [["morgens"]]},
        {"hourMin": 10, "hourMax": 12, "text": [["vormittags"]]},
        {"hourMin": 12, "hourMax": 13, "text": [["mittags"]]},
        {"hourMin": 13, "hourMax": 18, "text": [["nachmittags"]]},
        {"hourMin": 18, "hourMax": 23, "text": [["abends"]]},
        {"hourMin": 23, "hourMax": 24, "text": [["nachts"]]},
    ],
    "es-ES": [
        {"hourMin": 0, "hourMax": 1, "text": [["de la noche"], ["de la madrugada"]]},
        {"hourMin": 1, "hourMax": 6, "text": [["de la madrugada"]]},
        {"hourMin": 6, "hourMax": 12, "text": [["de la mañana"]]},
        {"hourMin": 12, "hourMax": 13, "text": [["del mediodía"]]},
        {"hourMin": 13, "hourMax": 21, "text": [["de la tarde"]]},
        {"hourMin": 21, "hourMax": 24, "text": [["de la noche"]]},
    ],
    "pt-BR": [
        {"hourMin": 0, "hourMax": 1, "text": [[]]},
        {"hourMin": 1, "hourMax": 6, "text": [["da madrugada"]]},
        {"hourMin": 6, "hourMax": 12, "text": [["da manhã"]]},
        {"hourMin": 12, "hourMax": 13, "text": [[]]},
        {"hourMin": 13, "hourMax": 18, "text": [["da tarde"]]},
        {"hourMin": 18, "hourMax": 24, "text": [["da noite"]]},
    ],
    "it-IT": [
        {"hourMin": 0, "hourMax": 1, "text": [[]]},
        {"hourMin": 1, "hourMax": 4, "text": [["di notte"], ["del mattino"]]},
        {"hourMin": 4, "hourMax": 5, "text": [["del mattino"], ["di notte"]]},
        {"hourMin": 5, "hourMax": 12, "text": [["del mattino"]]},
        {"hourMin": 12, "hourMax": 13, "text": [[]]},
        {"hourMin": 13, "hourMax": 18, "text": [["del pomeriggio"]]},
        {"hourMin": 18, "hourMax": 24, "text": [["di sera"]]},
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
    "de-DE": {
        "0": ["zwölf", "zwölf Uhr", "null Uhr"],
        "1": ["eins", "ein Uhr", "ein Uhr"],
        "2": ["zwei", "zwei Uhr", "zwei Uhr"],
        "3": ["drei", "drei Uhr", "drei Uhr"],
        "4": ["vier", "vier Uhr", "vier Uhr"],
        "5": ["fünf", "fünf Uhr", "fünf Uhr"],
        "6": ["sechs", "sechs Uhr", "sechs Uhr"],
        "7": ["sieben", "sieben Uhr", "sieben Uhr"],
        "8": ["acht", "acht Uhr", "acht Uhr"],
        "9": ["neun", "neun Uhr", "neun Uhr"],
        "10": ["zehn", "zehn Uhr", "zehn Uhr"],
        "11": ["elf", "elf Uhr", "elf Uhr"],
        "12": ["zwölf", "zwölf Uhr", "zwölf Uhr"],
        "13": ["eins", "ein Uhr", "dreizehn Uhr"],
        "14": ["zwei", "zwei Uhr", "vierzehn Uhr"],
        "15": ["drei", "drei Uhr", "fünfzehn Uhr"],
        "16": ["vier", "vier Uhr", "sechzehn Uhr"],
        "17": ["fünf", "fünf Uhr", "siebzehn Uhr"],
        "18": ["sechs", "sechs Uhr", "achtzehn Uhr"],
        "19": ["sieben", "sieben Uhr", "neunzehn Uhr"],
        "20": ["acht", "acht Uhr", "zwanzig Uhr"],
        "21": ["neun", "neun Uhr", "einund|zwanzig Uhr"],
        "22": ["zehn", "zehn Uhr", "zweiund|zwanzig Uhr"],
        "23": ["elf", "elf Uhr", "dreiund|zwanzig Uhr"],
    },
    "es-ES": {
        "0": ["las doce", "cero"],
        "1": ["la una", "una"],
        "2": ["las dos", "dos"],
        "3": ["las tres", "tres"],
        "4": ["las cuatro", "cuatro"],
        "5": ["las cinco", "cinco"],
        "6": ["las seis", "seis"],
        "7": ["las siete", "siete"],
        "8": ["las ocho", "ocho"],
        "9": ["las nueve", "nueve"],
        "10": ["las diez", "diez"],
        "11": ["las once", "once"],
        "12": ["las doce", "doce"],
        "13": ["la una", "trece"],
        "14": ["las dos", "catorce"],
        "15": ["las tres", "quince"],
        "16": ["las cuatro", "dieciséis"],
        "17": ["las cinco", "diecisiete"],
        "18": ["las seis", "dieciocho"],
        "19": ["las siete", "diecinueve"],
        "20": ["las ocho", "veinte"],
        "21": ["las nueve", "veintiuna"],
        "22": ["las diez", "veintidós"],
        "23": ["las once", "veintitrés"],
    },
    "pt-BR": {
        "0": ["meia-noite", "zero"],
        "1": ["uma", "uma"],
        "2": ["duas", "duas"],
        "3": ["três", "três"],
        "4": ["quatro", "quatro"],
        "5": ["cinco", "cinco"],
        "6": ["seis", "seis"],
        "7": ["sete", "sete"],
        "8": ["oito", "oito"],
        "9": ["nove", "nove"],
        "10": ["dez", "dez"],
        "11": ["onze", "onze"],
        "12": ["meio-dia", "doze"],
        "13": ["uma", "treze"],
        "14": ["duas", "quatorze"],
        "15": ["três", "quinze"],
        "16": ["quatro", "dezesseis"],
        "17": ["cinco", "dezessete"],
        "18": ["seis", "dezoito"],
        "19": ["sete", "dezenove"],
        "20": ["oito", "vinte"],
        "21": ["nove", "vinte e uma"],
        "22": ["dez", "vinte e duas"],
        "23": ["onze", "vinte e três"],
    },
    "it-IT": {
        "0": ["mezzanotte", "zero"],
        "1": ["l'una", "l'una"],
        "2": ["le due", "le due"],
        "3": ["le tre", "le tre"],
        "4": ["le quattro", "le quattro"],
        "5": ["le cinque", "le cinque"],
        "6": ["le sei", "le sei"],
        "7": ["le sette", "le sette"],
        "8": ["le otto", "le otto"],
        "9": ["le nove", "le nove"],
        "10": ["le dieci", "le dieci"],
        "11": ["le undici", "le undici"],
        "12": ["mezzogiorno", "le dodici"],
        "13": ["l'una", "le tredici"],
        "14": ["le due", "le quattordici"],
        "15": ["le tre", "le quindici"],
        "16": ["le quattro", "le sedici"],
        "17": ["le cinque", "le diciassette"],
        "18": ["le sei", "le diciotto"],
        "19": ["le sette", "le diciannove"],
        "20": ["le otto", "le venti"],
        "21": ["le nove", "le ventuno"],
        "22": ["le dieci", "le ventidue"],
        "23": ["le undici", "le ventitré"],
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
    "de-DE": {
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
    "es-ES": {
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
    "pt-BR": {
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
    "it-IT": {
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
    "de-DE": {
        "0:0": [["Mitternacht"], ["null Uhr"], ["zwölf Uhr"]],
        "12:0": [["zwölf Uhr"], ["Mittag"], ["Punkt", "zwölf"]],
    },
    "es-ES": {
        "0:0": [["las doce"], ["medianoche"], ["las doce", "en punto"]],
        "12:0": [["las doce"], ["mediodía"], ["las doce", "en punto"]],
    },
    "pt-BR": {
        "0:0": [["meia-noite"], ["meia-noite"], ["meia-noite", "em ponto"]],
        "0:40": [["meia-noite", "e quarenta"], ["vinte para", "a uma"]],
        "0:45": [["meia-noite", "e quarenta", "e cinco"], ["quinze para", "a uma"]],
        "0:50": [["meia-noite", "e cinquenta"], ["dez para", "a uma"]],
        "0:55": [["meia-noite", "e cinquenta", "e cinco"], ["cinco para", "a uma"]],
        "11:40": [["onze", "e quarenta"], ["vinte para", "o meio-dia"]],
        "11:45": [["onze", "e quarenta", "e cinco"], ["quinze para", "o meio-dia"]],
        "11:50": [["onze", "e cinquenta"], ["dez para", "o meio-dia"]],
        "11:55": [["onze", "e cinquenta", "e cinco"], ["cinco para", "o meio-dia"]],
        "12:0": [["meio-dia"], ["meio-dia"], ["meio-dia", "em ponto"]],
        "12:40": [["meio-dia", "e quarenta"], ["vinte para", "a uma"]],
        "12:45": [["meio-dia", "e quarenta", "e cinco"], ["quinze para", "a uma"]],
        "12:50": [["meio-dia", "e cinquenta"], ["dez para", "a uma"]],
        "12:55": [["meio-dia", "e cinquenta", "e cinco"], ["cinco para", "a uma"]],
        "23:40": [["onze", "e quarenta"], ["vinte para", "a meia-noite"]],
        "23:45": [["onze", "e quarenta", "e cinco"], ["quinze para", "a meia-noite"]],
        "23:50": [["onze", "e cinquenta"], ["dez para", "a meia-noite"]],
        "23:55": [["onze", "e cinquenta", "e cinco"], ["cinco para", "a meia-noite"]],
    },
    "it-IT": {
        "0:0": [["mezzanotte"], ["mezzanotte"], ["mezzanotte", "in punto"]],
        "12:0": [["mezzogiorno"], ["mezzogiorno"], ["mezzogiorno", "in punto"]],
        "12:30": [["mezzogiorno", "e mezzo"], ["mezzogiorno", "e trenta"]],
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
        "militarySingularHours": [],
        "ampm": ["AM", "PM"],
        "dayPartFollowsHourWord": False,
        "additiveHourIndex": 0,
        "upperFixups": [],
    },
    "fr-FR": {
        "subtitleFont": "tom-thumb",
        "subtitleHeight": 8,
        "subtitleCascade": False,
        "militaryPad": "",
        "militaryNoun": ["heure", "heures"],
        "militarySingularHours": [0, 1],
        "ampm": [],
        "dayPartFollowsHourWord": True,
        "additiveHourIndex": 0,
        "upperFixups": [],
    },
    "de-DE": {
        "subtitleFont": "tom-thumb",
        "subtitleHeight": 8,
        "subtitleCascade": False,
        "militaryPad": "",
        "militaryNoun": [],
        "militarySingularHours": [],
        "ampm": [],
        "dayPartFollowsHourWord": False,
        "additiveHourIndex": 1,
        "upperFixups": [["ß", "SS"]],
    },
    "es-ES": {
        "subtitleFont": "tom-thumb",
        "subtitleHeight": 8,
        "subtitleCascade": False,
        "militaryPad": "",
        "militaryNoun": ["hora", "horas"],
        "militarySingularHours": [1],
        "ampm": [],
        "dayPartFollowsHourWord": True,
        "additiveHourIndex": 0,
        "upperFixups": [],
    },
    "pt-BR": {
        "subtitleFont": "tom-thumb",
        "subtitleHeight": 8,
        "subtitleCascade": False,
        "militaryPad": "",
        "militaryNoun": ["hora", "horas"],
        "militarySingularHours": [1],
        "ampm": [],
        "dayPartFollowsHourWord": True,
        "additiveHourIndex": 0,
        "upperFixups": [],
    },
    "it-IT": {
        "subtitleFont": "tom-thumb",
        "subtitleHeight": 8,
        "subtitleCascade": False,
        "militaryPad": "",
        "militaryNoun": [],
        "militarySingularHours": [],
        "ampm": [],
        "dayPartFollowsHourWord": True,
        "additiveHourIndex": 0,
        "upperFixups": [],
    },
}

def military_time(hour, min, hours, minutes, rules):
    returnTime = []

    # add hour text
    hourText = ""
    if rules["militaryPad"] and hour < 10 and hour > 0:
        hourText += rules["militaryPad"]
    hourText += hours[str(hour)][-1]

    # "|" is an authored line break inside an hour word. German needs one --
    # "zweiundzwanzig Uhr" is 69px on a 63px line. Words without one stay one line.
    returnTime += hourText.split("|")

    if rules["militaryNoun"]:
        singular = hour in rules["militarySingularHours"]
        returnTime.append(rules["militaryNoun"][0] if singular else rules["militaryNoun"][1])

    # add minutes text
    returnTime += minutes[str(min)][0]["text"]

    return returnTime

def display_time(hour, min, hours, minutes, special, config, rules):
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
            nextHourIndex = 0 if hour == 23 else hour + 1

            # get a random entry of the minute (that isn't military time)
            minuteMinimum = 1 if min < 10 and len(minutes[str(min)]) > 1 else 0
            minuteMaximum = len(minutes[str(min)]) - 1
            minuteIndex = random.number(minuteMinimum, minuteMaximum)
            minuteObj = minutes[str(min)][minuteIndex]

            # a language can need a different hour word before its hour noun than
            # in a relative phrase -- German says "ein Uhr" but "halb eins"
            hourSlot = rules["additiveHourIndex"] if minuteObj["o"] == 2 else 0
            thisHourText = hours[str(hour)][hourSlot]
            nextHourText = hours[str(nextHourIndex)][hourSlot]

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
            returnTime.append(hours[str(hour)][rules["additiveHourIndex"]])

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

def to_caps(lines, rules):
    # .upper() leaves "ß" alone, so German would read "DREIßIG"; its uppercase is "SS"
    out = []
    for line in lines:
        for pair in rules["upperFixups"]:
            line = line.replace(pair[0], pair[1])
        out.append(line.upper())
    return out

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
        showTime, spokenHour = display_time(hour, min, hours, minutes, special, config, rules)
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
        showTime = to_caps(showTime, rules)
        subTime = to_caps(subTime, rules)

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
        schema.Option(
            display = "Deutsch (Deutschland)",
            value = "de-DE",
        ),
        schema.Option(
            display = "Español (España)",
            value = "es-ES",
        ),
        schema.Option(
            display = "Italiano (Italia)",
            value = "it-IT",
        ),
        schema.Option(
            display = "Português (Brasil)",
            value = "pt-BR",
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
