# Copyright 2026 cptntrps
# SPDX-License-Identifier: Apache-2.0

"""Everyday pregnancy tips based on public guidance, checked 2026-10-10.

Owner preference: broad, practical habits such as varied meals, hydration, rest,
and talking with the baby. Week placement is editorial, not a treatment schedule
or a claim that a habit causes a developmental milestone.
"""

DIET = "https://www.nhs.uk/pregnancy/keeping-well/have-a-healthy-diet/"
SLEEP = "https://www.nhs.uk/pregnancy/common-symptoms/tiredness/"
TIPS = {
    "variety": {
        "lines": (("VARY THE MENU", "FOR A MIX", "OF NUTRIENTS"),
                  ("VARIE O PRATO", "PARA COMBINAR", "NUTRIENTES")),
        "badge": "NHS",
        "reason": "A varied, balanced diet helps supply the nutrients needed during pregnancy. Variety matters across meals and days; no particular food needs to be eaten for a weekly milestone.",
        "sources": (DIET,),
    },
    "water": {
        "lines": (("SIP WATER", "DEHYDRATION CAN", "CAUSE HEADACHES"),
                  ("POUCA AGUA", "PODE CAUSAR", "DOR DE CABECA")),
        "badge": "NHS",
        "reason": "Drinking fluids helps prevent dehydration, which can contribute to headaches. Water is not a treatment for every headache. A severe headache, vision changes, pain under the ribs, or sudden swelling in pregnancy needs prompt maternity or medical advice; do not delay care to try hydration.",
        "sources": ("https://www.nhs.uk/pregnancy/common-symptoms/headaches/",
                    "https://www.nhs.uk/symptoms/headaches/"),
    },
    "rest": {
        "lines": (("FEELING TIRED?", "TIME TO PUT", "YOUR FEET UP"),
                  ("BATEU CANSACO?", "TIRE UM TEMPO", "PARA DESCANSAR")),
        "badge": "NHS",
        "reason": "Tiredness is common in pregnancy. Making time for rest and adequate sleep can make everyday life more manageable.",
        "sources": (SLEEP,),
    },
    "walk": {
        "lines": (("A SHORT WALK", "AT YOUR OWN", "EASY PACE"),
                  ("UMA CAMINHADA", "CURTA NO SEU", "PROPRIO RITMO")),
        "badge": "NHS",
        "reason": "Gentle activity such as walking can support fitness, sleep, and mood. Start gradually, stay comfortable, and follow any activity restrictions from your maternity team. Stop if you feel unwell or uncomfortable.",
        "sources": ("https://www.nhs.uk/pregnancy/keeping-well/exercise/",),
    },
    "meals": {
        "lines": (("FEELING SICK?", "SMALLER MEALS", "MAY HELP"),
                  ("COM ENJOO?", "PORCOES MENORES", "MAIS VEZES")),
        "badge": "NHS",
        "reason": "Small, frequent meals may help with pregnancy nausea. Persistent or severe vomiting, inability to keep fluids down, or signs of dehydration need medical advice.",
        "sources": ("https://www.nhs.uk/pregnancy/common-symptoms/vomiting-and-morning-sickness/",),
    },
    "wind_down": {
        "lines": (("BEFORE BED", "MAKE TIME TO", "WIND DOWN"),
                  ("ANTES DE DORMIR", "TIRE UM TEMPO", "PARA RELAXAR")),
        "badge": "NHS",
        "reason": "Taking time to relax before bed may help with sleep. It is a practical comfort suggestion, not a guarantee of better sleep or fetal development.",
        "sources": (SLEEP,),
    },
    "support": {
        "lines": (("SHARE CHORES", "MAKE A LITTLE", "ROOM FOR REST"),
                  ("DIVIDA TAREFAS", "ABRA ESPACO", "PARA DESCANSAR")),
        "badge": "NHS",
        "reason": "Accepting help from family or others can create time for rest. Sharing chores is a practical way for a partner or support person to help.",
        "sources": (SLEEP,),
    },
    "voice": {
        "lines": (("CHAT OR SING", "BABY CAN HEAR", "YOUR VOICE"),
                  ("CONVERSE, CANTE", "BEBE JA OUVE", "SUA VOZ")),
        "badge": "NHS",
        "reason": "The NHS describes hearing outside voices around week 21 and recognizing voices around week 31, and suggests talking or singing. This is a connection activity without a claim of improved intelligence. Normal conversation needs no belly headphones or loud sound.",
        "sources": (
            "https://www.nhs.uk/best-start-in-life/pregnancy/week-by-week-guide-to-pregnancy/2nd-trimester/week-21/",
            "https://www.nhs.uk/best-start-in-life/pregnancy/week-by-week-guide-to-pregnancy/3rd-trimester/week-31/",
        ),
    },
    "prenatal": {
        "lines": (("BRING QUESTIONS", "TO YOUR NEXT", "PRENATAL VISIT"),
                  ("LEVE DUVIDAS", "PARA A PROXIMA", "CONSULTA")),
        "badge": "NIH",
        "reason": "Prenatal visits include time to discuss pregnancy questions and tailor care. Keeping questions ready can help you make use of that conversation.",
        "sources": ("https://www.nichd.nih.gov/health/topics/pregnancy/conditioninfo/prenatal-care",),
    },
}

WEEK_TIPS = {
    4: "prenatal", 5: "rest", 6: "meals", 7: "water", 8: "rest",
    9: "variety", 10: "water", 11: "walk", 12: "variety",
    13: "walk", 14: "rest", 15: "wind_down", 16: "water", 17: "variety",
    18: "support", 19: "walk", 20: "water", 21: "voice", 22: "variety",
    23: "rest", 24: "support", 25: "walk", 26: "wind_down", 27: "water",
    28: "support", 29: "variety", 30: "walk", 31: "voice", 32: "rest",
    33: "water", 34: "wind_down", 35: "support", 36: "prenatal", 37: "voice",
    38: "rest", 39: "support", 40: "prenatal",
}
