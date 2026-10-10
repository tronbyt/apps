# Copyright 2026 cptntrps
# SPDX-License-Identifier: Apache-2.0

"""Practical pregnancy tips based on public guidance, checked 2026-10-10.

Week placement is editorial, not a treatment schedule or a claim that a food
causes that week's milestone. Food suggestions are for the pregnant parent.
No supplement doses, developmental guarantees, or flavor-training claims.
"""

DIET = "https://www.nhs.uk/pregnancy/keeping-well/have-a-healthy-diet/"
TIPS = {
    "variety": {
        "lines": (("VARY THE MENU", "FOR A MIX", "OF NUTRIENTS"),
                  ("VARIE O PRATO", "PARA COMBINAR", "NUTRIENTES")),
        "badge": "NHS",
        "reason": "A varied, balanced diet supplies nutrients needed during pregnancy and supports growth. This does not claim to improve taste buds or prevent picky eating.",
        "sources": (DIET,),
    },
    "calcium": {
        "lines": (("PASTEURIZED", "YOGURT FOR", "BONE CALCIUM"),
                  ("IOGURTE", "PASTEURIZADO:", "CALCIO P/ OSSOS")),
        "badge": "NIH",
        "reason": "Yogurt supplies calcium, which is needed for bones and teeth. Choose pasteurized yogurt; calcium-fortified dairy alternatives are another option. This is food guidance, not a recommendation to add a calcium supplement.",
        "sources": ("https://ods.od.nih.gov/factsheets/Calcium-Consumer/", DIET,
                    "https://www.nhs.uk/pregnancy/keeping-well/foods-to-avoid/"),
    },
    "iron": {
        "lines": (("BEANS + PEPPERS", "FOR BETTER", "IRON ABSORPTION"),
                  ("FEIJAO+PIMENTAO", "AJUDAM A", "ABSORVER FERRO")),
        "badge": "NIH",
        "reason": "Beans provide nonheme iron. Vitamin C in sweet peppers helps the body absorb plant iron; iron is used to make the blood proteins that carry oxygen. This pairing illustrates that established mechanism, not a trial of this exact meal or a treatment for anemia.",
        "sources": ("https://ods.od.nih.gov/factsheets/Iron-Consumer/",),
    },
    "choline": {
        "lines": (("COOKED EGGS", "ADD CHOLINE", "FOR BABY GROWTH"),
                  ("OVOS COZIDOS", "DAO COLINA", "PARA CRESCER")),
        "badge": "NIH",
        "reason": "Eggs supply choline, which is needed for fetal growth and central nervous-system development. Cook eggs until both whites and yolks are firm. This does not claim that extra choline boosts intelligence or prescribe supplements.",
        "sources": ("https://ods.od.nih.gov/factsheets/Pregnancy-HealthProfessional/",
                    "https://ods.od.nih.gov/factsheets/Choline-Consumer/", DIET),
    },
    "fibre": {
        "lines": (("OATS ADD", "FIBRE TO HELP", "KEEP YOU GOING"),
                  ("AVEIA DA FIBRAS", "PARA AJUDAR", "O INTESTINO")),
        "badge": "NHS",
        "reason": "Higher-fibre foods such as oats help digestion and can help prevent constipation. This tip benefits the pregnant parent's comfort; it does not claim a fetal developmental effect.",
        "sources": (DIET,),
    },
    "voice": {
        "lines": (("CHAT OR SING", "BABY CAN HEAR", "YOUR VOICE"),
                  ("CONVERSE, CANTE", "BEBE JA OUVE", "SUA VOZ")),
        "badge": "NHS",
        "reason": "The NHS describes hearing outside voices around week 21 and recognizing voices around week 31, and suggests talking or singing. This is a connection activity, not a proven intelligence or language boost. It needs no belly headphones or loud sound.",
        "sources": (
            "https://www.nhs.uk/best-start-in-life/pregnancy/week-by-week-guide-to-pregnancy/2nd-trimester/week-21/",
            "https://www.nhs.uk/best-start-in-life/pregnancy/week-by-week-guide-to-pregnancy/3rd-trimester/week-31/",
        ),
    },
    "prenatal": {
        "lines": (("BRING QUESTIONS", "TO YOUR NEXT", "PRENATAL VISIT"),
                  ("LEVE DUVIDAS", "PARA A PROXIMA", "CONSULTA")),
        "badge": "NIH",
        "reason": "Early, regular prenatal care helps identify concerns and tailor care. Visits include discussion of questions about the pregnancy. This remains useful at any stage.",
        "sources": ("https://www.nichd.nih.gov/health/topics/pregnancy/conditioninfo/prenatal-care",),
    },
    "folic": {
        "lines": (("CHECK FOLIC", "ACID IN YOUR", "PRENATAL PLAN"),
                  ("CONFIRA ACIDO", "FOLICO NO SEU", "PRE-NATAL")),
        "badge": "CDC",
        "reason": "Folic acid before and during early pregnancy helps prevent neural-tube defects. Do not wait for this card or a particular week to discuss it. Follow prenatal guidance from your clinician; the app does not set an individual dose or replace supplementation with food.",
        "sources": ("https://www.cdc.gov/folic-acid/about/index.html",),
    },
    "produce": {
        "lines": (("WASH FRUIT", "AND VEG WELL", "FOR FOOD SAFETY"),
                  ("LAVE BEM", "FRUTAS E", "VERDURAS")),
        "badge": "NHS",
        "reason": "Careful washing removes soil from produce and reduces exposure to foodborne hazards. This is food-safety advice, not a milestone-specific intervention.",
        "sources": (DIET,),
    },
}

WEEK_TIPS = {
    4: "folic", 5: "folic", 6: "choline", 7: "variety", 8: "iron",
    9: "variety", 10: "calcium", 11: "choline", 12: "calcium",
    13: "variety", 14: "fibre", 15: "choline", 16: "iron", 17: "variety",
    18: "iron", 19: "calcium", 20: "produce", 21: "voice", 22: "variety",
    23: "choline", 24: "iron", 25: "fibre", 26: "variety", 27: "iron",
    28: "iron", 29: "choline", 30: "variety", 31: "voice", 32: "variety",
    33: "calcium", 34: "fibre", 35: "iron", 36: "prenatal", 37: "voice",
    38: "produce", 39: "variety", 40: "prenatal",
}
