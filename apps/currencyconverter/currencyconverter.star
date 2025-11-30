"""
Applet: CurrencyConverter
Summary: Displays Currency Exchange
Description: Displays current currency exchange rates.
Author: Robert Ison
"""

load("cache.star", "cache")
load("encoding/json.star", "json")
load("http.star", "http")
load("humanize.star", "humanize")
load("images/aed_flag.webp", AED_FLAG = "file")
load("images/all_flag.webp", ALL_FLAG = "file")
load("images/amd_flag.webp", AMD_FLAG = "file")
load("images/aoa_flag.webp", AOA_FLAG = "file")
load("images/ars_flag.webp", ARS_FLAG = "file")
load("images/aud_flag.webp", AUD_FLAG = "file")
load("images/awg_flag.webp", AWG_FLAG = "file")
load("images/azn_flag.webp", AZN_FLAG = "file")
load("images/bam_flag.webp", BAM_FLAG = "file")
load("images/bbd_flag.webp", BBD_FLAG = "file")
load("images/bdt_flag.webp", BDT_FLAG = "file")
load("images/bgn_flag.webp", BGN_FLAG = "file")
load("images/bhd_flag.webp", BHD_FLAG = "file")
load("images/bif_flag.webp", BIF_FLAG = "file")
load("images/bmd_flag.webp", BMD_FLAG = "file")
load("images/bnd_flag.webp", BND_FLAG = "file")
load("images/bob_flag.webp", BOB_FLAG = "file")
load("images/brl_flag.webp", BRL_FLAG = "file")
load("images/bsd_flag.webp", BSD_FLAG = "file")
load("images/btn_flag.webp", BTN_FLAG = "file")
load("images/bwp_flag.webp", BWP_FLAG = "file")
load("images/byn_flag.webp", BYN_FLAG = "file")
load("images/bzd_flag.webp", BZD_FLAG = "file")
load("images/cad_flag.webp", CAD_FLAG = "file")
load("images/cdf_flag.webp", CDF_FLAG = "file")
load("images/chf_flag.webp", CHF_FLAG = "file")
load("images/clp_flag.webp", CLP_FLAG = "file")
load("images/cny_flag.webp", CNY_FLAG = "file")
load("images/cop_flag.webp", COP_FLAG = "file")
load("images/crc_flag.webp", CRC_FLAG = "file")
load("images/cup_flag.webp", CUP_FLAG = "file")
load("images/djf_flag.webp", DJF_FLAG = "file")
load("images/dkk_flag.webp", DKK_FLAG = "file")
load("images/dop_flag.webp", DOP_FLAG = "file")
load("images/egp_flag.webp", EGP_FLAG = "file")
load("images/ern_flag.webp", ERN_FLAG = "file")
load("images/etb_flag.webp", ETB_FLAG = "file")
load("images/euro_flag.png", EURO_FLAG_ASSET = "file")
load("images/fjd_flag.webp", FJD_FLAG = "file")
load("images/fkp_flag.webp", FKP_FLAG = "file")
load("images/fok_flag.webp", FOK_FLAG = "file")
load("images/gbp_flag.webp", GBP_FLAG = "file")
load("images/gel_flag.webp", GEL_FLAG = "file")
load("images/ghs_flag.webp", GHS_FLAG = "file")
load("images/gip_flag.webp", GIP_FLAG = "file")
load("images/gnf_flag.webp", GNF_FLAG = "file")
load("images/gtq_flag.webp", GTQ_FLAG = "file")
load("images/gyd_flag.webp", GYD_FLAG = "file")
load("images/hkd_flag.webp", HKD_FLAG = "file")
load("images/hnl_flag.webp", HNL_FLAG = "file")
load("images/hrk_flag.webp", HRK_FLAG = "file")
load("images/htg_flag.webp", HTG_FLAG = "file")
load("images/huf_flag.webp", HUF_FLAG = "file")
load("images/idr_flag.webp", IDR_FLAG = "file")
load("images/ils_flag.webp", ILS_FLAG = "file")
load("images/imp_flag.webp", IMP_FLAG = "file")
load("images/inr_flag.webp", INR_FLAG = "file")
load("images/iqd_flag.webp", IQD_FLAG = "file")
load("images/irr_flag.webp", IRR_FLAG = "file")
load("images/isk_flag.webp", ISK_FLAG = "file")
load("images/jep_flag.webp", JEP_FLAG = "file")
load("images/jmd_flag.webp", JMD_FLAG = "file")
load("images/jod_flag.webp", JOD_FLAG = "file")
load("images/jpy_flag.webp", JPY_FLAG = "file")
load("images/kes_flag.webp", KES_FLAG = "file")
load("images/kgs_flag.webp", KGS_FLAG = "file")
load("images/khr_flag.webp", KHR_FLAG = "file")
load("images/kid_flag.webp", KID_FLAG = "file")
load("images/kmf_flag.webp", KMF_FLAG = "file")
load("images/krw_flag.webp", KRW_FLAG = "file")
load("images/kwd_flag.webp", KWD_FLAG = "file")
load("images/kyd_flag.webp", KYD_FLAG = "file")
load("images/kzt_flag.webp", KZT_FLAG = "file")
load("images/lak_flag.webp", LAK_FLAG = "file")
load("images/lbp_flag.webp", LBP_FLAG = "file")
load("images/lkr_flag.webp", LKR_FLAG = "file")
load("images/lrd_flag.webp", LRD_FLAG = "file")
load("images/lsl_flag.webp", LSL_FLAG = "file")
load("images/lyd_flag.webp", LYD_FLAG = "file")
load("images/mad_flag.webp", MAD_FLAG = "file")
load("images/mdl_flag.webp", MDL_FLAG = "file")
load("images/mga_flag.webp", MGA_FLAG = "file")
load("images/mkd_flag.webp", MKD_FLAG = "file")
load("images/mmk_flag.webp", MMK_FLAG = "file")
load("images/mnt_flag.webp", MNT_FLAG = "file")
load("images/mop_flag.webp", MOP_FLAG = "file")
load("images/mru_flag.webp", MRU_FLAG = "file")
load("images/mur_flag.webp", MUR_FLAG = "file")
load("images/mvr_flag.webp", MVR_FLAG = "file")
load("images/mwk_flag.webp", MWK_FLAG = "file")
load("images/mxn_flag.webp", MXN_FLAG = "file")
load("images/myr_flag.webp", MYR_FLAG = "file")
load("images/mzn_flag.webp", MZN_FLAG = "file")
load("images/nad_flag.webp", NAD_FLAG = "file")
load("images/ngn_flag.webp", NGN_FLAG = "file")
load("images/nio_flag.webp", NIO_FLAG = "file")
load("images/nok_flag.webp", NOK_FLAG = "file")
load("images/npr_flag.webp", NPR_FLAG = "file")
load("images/nzd_flag.webp", NZD_FLAG = "file")
load("images/omr_flag.webp", OMR_FLAG = "file")
load("images/pab_flag.webp", PAB_FLAG = "file")
load("images/pen_flag.webp", PEN_FLAG = "file")
load("images/pgk_flag.webp", PGK_FLAG = "file")
load("images/php_flag.webp", PHP_FLAG = "file")
load("images/pkr_flag.webp", PKR_FLAG = "file")
load("images/pln_flag.webp", PLN_FLAG = "file")
load("images/pyg_flag.webp", PYG_FLAG = "file")
load("images/qar_flag.webp", QAR_FLAG = "file")
load("images/ron_flag.webp", RON_FLAG = "file")
load("images/rub_flag.webp", RUB_FLAG = "file")
load("images/rwf_flag.webp", RWF_FLAG = "file")
load("images/sar_flag.webp", SAR_FLAG = "file")
load("images/sbd_flag.webp", SBD_FLAG = "file")
load("images/scr_flag.webp", SCR_FLAG = "file")
load("images/sdg_flag.webp", SDG_FLAG = "file")
load("images/sek_flag.webp", SEK_FLAG = "file")
load("images/sgd_flag.webp", SGD_FLAG = "file")
load("images/shp_flag.webp", SHP_FLAG = "file")
load("images/sle_flag.webp", SLE_FLAG = "file")
load("images/sos_flag.webp", SOS_FLAG = "file")
load("images/srd_flag.webp", SRD_FLAG = "file")
load("images/ssp_flag.webp", SSP_FLAG = "file")
load("images/stn_flag.webp", STN_FLAG = "file")
load("images/syp_flag.webp", SYP_FLAG = "file")
load("images/szl_flag.webp", SZL_FLAG = "file")
load("images/thb_flag.webp", THB_FLAG = "file")
load("images/tjs_flag.webp", TJS_FLAG = "file")
load("images/tmt_flag.webp", TMT_FLAG = "file")
load("images/tnd_flag.webp", TND_FLAG = "file")
load("images/top_flag.webp", TOP_FLAG = "file")
load("images/try_flag.webp", TRY_FLAG = "file")
load("images/ttd_flag.webp", TTD_FLAG = "file")
load("images/tvd_flag.webp", TVD_FLAG = "file")
load("images/twd_flag.webp", TWD_FLAG = "file")
load("images/tzs_flag.webp", TZS_FLAG = "file")
load("images/uah_flag.webp", UAH_FLAG = "file")
load("images/ugx_flag.webp", UGX_FLAG = "file")
load("images/usd_flag.webp", USD_FLAG = "file")
load("images/uyu_flag.webp", UYU_FLAG = "file")
load("images/uzs_flag.webp", UZS_FLAG = "file")
load("images/ves_flag.webp", VES_FLAG = "file")
load("images/vuv_flag.webp", VUV_FLAG = "file")
load("images/wst_flag.webp", WST_FLAG = "file")
load("images/xaf_flag.webp", XAF_FLAG = "file")
load("images/zar_flag.webp", ZAR_FLAG = "file")
load("images/zmw_flag.webp", ZMW_FLAG = "file")
load("images/zwl_flag.webp", ZWL_FLAG = "file")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# Exchangerate-API.com Info

currencies = {
    "eur": {
        "name": "Euro",
        "flag": EURO_FLAG_ASSET.readall(),
    },
    "aed": {
        "name": "United Arab Emirates",
        "flag": AED_FLAG.readall(),
    },
    "all": {
        "name": "Albania",
        "flag": ALL_FLAG.readall(),
    },
    "amd": {
        "name": "Armenia",
        "flag": AMD_FLAG.readall(),
    },
    "aoa": {
        "name": "Angola",
        "flag": AOA_FLAG.readall(),
    },
    "ars": {
        "name": "Argentina",
        "flag": ARS_FLAG.readall(),
    },
    "aud": {
        "name": "Australia",
        "flag": AUD_FLAG.readall(),
    },
    "awg": {
        "name": "Aruba",
        "flag": AWG_FLAG.readall(),
    },
    "azn": {
        "name": "Azerbaijan",
        "flag": AZN_FLAG.readall(),
    },
    "bam": {
        "name": "Bosnia and Herzegovina",
        "flag": BAM_FLAG.readall(),
    },
    "bbd": {
        "name": "Barbados",
        "flag": BBD_FLAG.readall(),
    },
    "bdt": {
        "name": "Bangladesh",
        "flag": BDT_FLAG.readall(),
    },
    "bhd": {
        "name": "Bahrain",
        "flag": BHD_FLAG.readall(),
    },
    "bif": {
        "name": "Burundi",
        "flag": BIF_FLAG.readall(),
    },
    "bmd": {
        "name": "Bermuda",
        "flag": BMD_FLAG.readall(),
    },
    "bnd": {
        "name": "Brunei Darussalam",
        "flag": BND_FLAG.readall(),
    },
    "bob": {
        "name": "Bolivia",
        "flag": BOB_FLAG.readall(),
    },
    "brl": {
        "name": "Brazil",
        "flag": BRL_FLAG.readall(),
    },
    "bsd": {
        "name": "Bahamas",
        "flag": BSD_FLAG.readall(),
    },
    "btn": {
        "name": "Bhutan",
        "flag": BTN_FLAG.readall(),
    },
    "bzd": {
        "name": "Belize",
        "flag": BZD_FLAG.readall(),
    },
    "byn": {
        "name": "Belarus",
        "flag": BYN_FLAG.readall(),
    },
    "bwp": {
        "name": "Botswana",
        "flag": BWP_FLAG.readall(),
    },
    "bgn": {
        "name": "Bulgaria",
        "flag": BGN_FLAG.readall(),
    },
    "khr": {
        "name": "Cambodia",
        "flag": KHR_FLAG.readall(),
    },
    "cad": {
        "name": "Canada",
        "flag": CAD_FLAG.readall(),
    },
    "kyd": {
        "name": "Cayman Islands",
        "flag": KYD_FLAG.readall(),
    },
    "xaf": {
        "name": "Central African Republic",
        "flag": XAF_FLAG.readall(),
    },
    "clp": {
        "name": "Chile",
        "flag": CLP_FLAG.readall(),
    },
    "cny": {
        "name": "China",
        "flag": CNY_FLAG.readall(),
    },
    "cop": {
        "name": "Colombia",
        "flag": COP_FLAG.readall(),
    },
    "kmf": {
        "name": "Comoros",
        "flag": KMF_FLAG.readall(),
    },
    "crc": {
        "name": "Costa Rica",
        "flag": CRC_FLAG.readall(),
    },
    "hrk": {
        "name": "Croatia",
        "flag": HRK_FLAG.readall(),
    },
    "cup": {
        "name": "Cuba",
        "flag": CUP_FLAG.readall(),
    },
    "cdf": {
        "name": "Congo",
        "flag": CDF_FLAG.readall(),
    },
    "dkk": {
        "name": "Denmark",
        "flag": DKK_FLAG.readall(),
    },
    "djf": {
        "name": "Djibouti",
        "flag": DJF_FLAG.readall(),
    },
    "dop": {
        "name": "Dominican Republic",
        "flag": DOP_FLAG.readall(),
    },
    "egp": {
        "name": "Egypt",
        "flag": EGP_FLAG.readall(),
    },
    "ern": {
        "name": "Eritrea",
        "flag": ERN_FLAG.readall(),
    },
    "szl": {
        "name": "Eswatini",
        "flag": SZL_FLAG.readall(),
    },
    "etb": {
        "name": "Ethiopia",
        "flag": ETB_FLAG.readall(),
    },
    "fkp": {
        "name": "Falkland Islands",
        "flag": FKP_FLAG.readall(),
    },
    "fok": {
        "name": "Faroe Islands",
        "flag": FOK_FLAG.readall(),
    },
    "fjd": {
        "name": "Fiji",
        "flag": FJD_FLAG.readall(),
    },
    "gel": {
        "name": "Georgia",
        "flag": GEL_FLAG.readall(),
    },
    "ghs": {
        "name": "Ghana",
        "flag": GHS_FLAG.readall(),
    },
    "gip": {
        "name": "Gibraltar",
        "flag": GIP_FLAG.readall(),
    },
    "gtq": {
        "name": "Guatemala",
        "flag": GTQ_FLAG.readall(),
    },
    "gnf": {
        "name": "Guinea",
        "flag": GNF_FLAG.readall(),
    },
    "gyd": {
        "name": "Guyana",
        "flag": GYD_FLAG.readall(),
    },
    "htg": {
        "name": "Haiti",
        "flag": HTG_FLAG.readall(),
    },
    "hnl": {
        "name": "Honduras",
        "flag": HNL_FLAG.readall(),
    },
    "hkd": {
        "name": "Hong Kong",
        "flag": HKD_FLAG.readall(),
    },
    "huf": {
        "name": "Hungary",
        "flag": HUF_FLAG.readall(),
    },
    "isk": {
        "name": "Iceland",
        "flag": ISK_FLAG.readall(),
    },
    "inr": {
        "name": "India",
        "flag": INR_FLAG.readall(),
    },
    "idr": {
        "name": "Indonesia",
        "flag": IDR_FLAG.readall(),
    },
    "irr": {
        "name": "Iran",
        "flag": IRR_FLAG.readall(),
    },
    "iqd": {
        "name": "Iraq",
        "flag": IQD_FLAG.readall(),
    },
    "imp": {
        "name": "Isle of Man",
        "flag": IMP_FLAG.readall(),
    },
    "ils": {
        "name": "Israel",
        "flag": ILS_FLAG.readall(),
    },
    "jmd": {
        "name": "Jamaica",
        "flag": JMD_FLAG.readall(),
    },
    "jpy": {
        "name": "Japan",
        "flag": JPY_FLAG.readall(),
    },
    "jep": {
        "name": "Jersey",
        "flag": JEP_FLAG.readall(),
    },
    "jod": {
        "name": "Jordan",
        "flag": JOD_FLAG.readall(),
    },
    "kzt": {
        "name": "Kazakhstan",
        "flag": KZT_FLAG.readall(),
    },
    "kes": {
        "name": "Kenya",
        "flag": KES_FLAG.readall(),
    },
    "kid": {
        "name": "Kiribati",
        "flag": KID_FLAG.readall(),
    },
    "kwd": {
        "name": "Kuwait",
        "flag": KWD_FLAG.readall(),
    },
    "kgs": {
        "name": "Kyrgyzstan",
        "flag": KGS_FLAG.readall(),
    },
    "lak": {
        "name": "Laos",
        "flag": LAK_FLAG.readall(),
    },
    "lbp": {
        "name": "Lebanon",
        "flag": LBP_FLAG.readall(),
    },
    "lsl": {
        "name": "Lesotho",
        "flag": LSL_FLAG.readall(),
    },
    "lrd": {
        "name": "Liberia",
        "flag": LRD_FLAG.readall(),
    },
    "lyd": {
        "name": "Libya",
        "flag": LYD_FLAG.readall(),
    },
    "mop": {
        "name": "Macao",
        "flag": MOP_FLAG.readall(),
    },
    "mga": {
        "name": "Madagascar",
        "flag": MGA_FLAG.readall(),
    },
    "mwk": {
        "name": "Malawi",
        "flag": MWK_FLAG.readall(),
    },
    "myr": {
        "name": "Malaysia",
        "flag": MYR_FLAG.readall(),
    },
    "mvr": {
        "name": "Maldives",
        "flag": MVR_FLAG.readall(),
    },
    "mru": {
        "name": "Mauritania",
        "flag": MRU_FLAG.readall(),
    },
    "mur": {
        "name": "Mauritius",
        "flag": MUR_FLAG.readall(),
    },
    "mxn": {
        "name": "Mexico",
        "flag": MXN_FLAG.readall(),
    },
    "mdl": {
        "name": "Moldova, Republic of",
        "flag": MDL_FLAG.readall(),
    },
    "mnt": {
        "name": "Mongolia",
        "flag": MNT_FLAG.readall(),
    },
    "mad": {
        "name": "Morocco",
        "flag": MAD_FLAG.readall(),
    },
    "mzn": {
        "name": "Mozambique",
        "flag": MZN_FLAG.readall(),
    },
    "mmk": {
        "name": "Myanmar",
        "flag": MMK_FLAG.readall(),
    },
    "nad": {
        "name": "Namibia",
        "flag": NAD_FLAG.readall(),
    },
    "npr": {
        "name": "Nepal",
        "flag": NPR_FLAG.readall(),
    },
    "nzd": {
        "name": "New Zealand",
        "flag": NZD_FLAG.readall(),
    },
    "nio": {
        "name": "Nicaragua",
        "flag": NIO_FLAG.readall(),
    },
    "ngn": {
        "name": "Nigeria",
        "flag": NGN_FLAG.readall(),
    },
    "mkd": {
        "name": "North Macedonia",
        "flag": MKD_FLAG.readall(),
    },
    "nok": {
        "name": "Norway",
        "flag": NOK_FLAG.readall(),
    },
    "omr": {
        "name": "Oman",
        "flag": OMR_FLAG.readall(),
    },
    "pkr": {
        "name": "Pakistan",
        "flag": PKR_FLAG.readall(),
    },
    "pab": {
        "name": "Panama",
        "flag": PAB_FLAG.readall(),
    },
    "pgk": {
        "name": "Papua New Guinea",
        "flag": PGK_FLAG.readall(),
    },
    "pyg": {
        "name": "Paraguay",
        "flag": PYG_FLAG.readall(),
    },
    "pen": {
        "name": "Peru",
        "flag": PEN_FLAG.readall(),
    },
    "php": {
        "name": "Philippines",
        "flag": PHP_FLAG.readall(),
    },
    "pln": {
        "name": "Poland",
        "flag": PLN_FLAG.readall(),
    },
    "qar": {
        "name": "Qatar",
        "flag": QAR_FLAG.readall(),
    },
    "ron": {
        "name": "Romania",
        "flag": RON_FLAG.readall(),
    },
    "rub": {
        "name": "Russia",
        "flag": RUB_FLAG.readall(),
    },
    "rwf": {
        "name": "Rwanda",
        "flag": RWF_FLAG.readall(),
    },
    "shp": {
        "name": "Saint Helena",
        "flag": SHP_FLAG.readall(),
    },
    "wst": {
        "name": "Samoa",
        "flag": WST_FLAG.readall(),
    },
    "stn": {
        "name": "Sao Tome and Principe",
        "flag": STN_FLAG.readall(),
    },
    "sar": {
        "name": "Saudi Arabia",
        "flag": SAR_FLAG.readall(),
    },
    "scr": {
        "name": "Seychelles",
        "flag": SCR_FLAG.readall(),
    },
    "sle": {
        "name": "Sierra Leone",
        "flag": SLE_FLAG.readall(),
    },
    "sgd": {
        "name": "Singapore",
        "flag": SGD_FLAG.readall(),
    },
    "sbd": {
        "name": "Solomon Islands",
        "flag": SBD_FLAG.readall(),
    },
    "sos": {
        "name": "Somalia",
        "flag": SOS_FLAG.readall(),
    },
    "zar": {
        "name": "South Africa",
        "flag": ZAR_FLAG.readall(),
    },
    "ssp": {
        "name": "South Sudan",
        "flag": SSP_FLAG.readall(),
    },
    "lkr": {
        "name": "Sri Lanka",
        "flag": LKR_FLAG.readall(),
    },
    "sdg": {
        "name": "Sudan",
        "flag": SDG_FLAG.readall(),
    },
    "srd": {
        "name": "Suriname",
        "flag": SRD_FLAG.readall(),
    },
    "sek": {
        "name": "Sweden",
        "flag": SEK_FLAG.readall(),
    },
    "chf": {
        "name": "Switzerland",
        "flag": CHF_FLAG.readall(),
    },
    "syp": {
        "name": "Syrian Arab Republic",
        "flag": SYP_FLAG.readall(),
    },
    "twd": {
        "name": "Taiwan",
        "flag": TWD_FLAG.readall(),
    },
    "tjs": {
        "name": "Tajikistan",
        "flag": TJS_FLAG.readall(),
    },
    "tzs": {
        "name": "Tanzania",
        "flag": TZS_FLAG.readall(),
    },
    "thb": {
        "name": "Thailand",
        "flag": THB_FLAG.readall(),
    },
    "top": {
        "name": "Tonga",
        "flag": TOP_FLAG.readall(),
    },
    "ttd": {
        "name": "Trinidad and Tobago",
        "flag": TTD_FLAG.readall(),
    },
    "tnd": {
        "name": "Tunisia",
        "flag": TND_FLAG.readall(),
    },
    "try": {
        "name": "Turkey",
        "flag": TRY_FLAG.readall(),
    },
    "tmt": {
        "name": "Turkmenistan",
        "flag": TMT_FLAG.readall(),
    },
    "tvd": {
        "name": "Tuvalu",
        "flag": TVD_FLAG.readall(),
    },
    "ugx": {
        "name": "Uganda",
        "flag": UGX_FLAG.readall(),
    },
    "uah": {
        "name": "Ukraine",
        "flag": UAH_FLAG.readall(),
    },
    "gbp": {
        "name": "United Kingdom",
        "flag": GBP_FLAG.readall(),
    },
    "usd": {
        "name": "USA",
        "flag": USD_FLAG.readall(),
    },
    "uyu": {
        "name": "Uruguay",
        "flag": UYU_FLAG.readall(),
    },
    "uzs": {
        "name": "Uzbekistan",
        "flag": UZS_FLAG.readall(),
    },
    "vuv": {
        "name": "Vanuatu",
        "flag": VUV_FLAG.readall(),
    },
    "ves": {
        "name": "Venezuela",
        "flag": VES_FLAG.readall(),
    },
    "zmw": {
        "name": "Zambia",
        "flag": ZMW_FLAG.readall(),
    },
    "zwl": {
        "name": "Zimbabwe",
        "flag": ZWL_FLAG.readall(),
    },
    "krw": {
        "name": "South Korea",
        "flag": KRW_FLAG.readall(),
    },
}

# retrieves a specific country the list of countries
def get_currency(currency_code):
    return currencies[currency_code]

def get_currency_information(currency_url):
    res = http.get(
        url = currency_url,
    )

    if res.status_code == 200:
        return res.json()
    else:
        return None

def get_appropriate_humanize_display(number):
    """ Gets the appropriate make with the right number of decimals

        When two currencies are fairly close in value, 3 decimals makes sense
        However, if one currency is 1,000 time the other, 2 decimals makes sense for the more valuable currency and 6 decimals are
        needed, just to display enough significant digits.
        This algorithm figures the most appropriate mask.

    Args:
        number: the number we need to figure how many decimals are needed
    Returns:
        Humanize mask for this particular number
    """
    if (number > 1000):
        mask = "#.##"
    elif (number > 10):
        mask = "#.####"
    elif (number > 0.1):
        mask = "#.###"
    elif (number > 0.0001):
        mask = "#.####"
    else:
        mask = "#.######"
    return mask

def main(config):
    """ Main

    Args:
        config: The past in configuration which includes selected countries
    Returns:
        Display to Tidbyt
    """
    local_currency = config.get("local") or "usd"
    foreign_currency = config.get("foreign") or "cad"

    key = config.get("api_key")
    exchange_rate_url = "https://v6.exchangerate-api.com/v6/%s/latest/%s" % (key, local_currency.lower())

    exchange_data_encoded_json = cache.get(exchange_rate_url)
    if exchange_data_encoded_json == None:
        exchange_data_decoded_json = get_currency_information(exchange_rate_url)

        # calculate 5 minutes past the stated next update date to make sure it it'll be updated next time we call
        cache_time = int(exchange_data_decoded_json["time_next_update_unix"]) - int(time.now().in_location("UTC").unix) + 300

        # TODO: Determine if this cache call can be converted to the new HTTP cache.
        cache.set(exchange_rate_url, json.encode(exchange_data_decoded_json), ttl_seconds = cache_time)
    else:
        exchange_data_decoded_json = json.decode(exchange_data_encoded_json)

    foreign_currency_cost_in_local = float(exchange_data_decoded_json["conversion_rates"][foreign_currency.upper()])
    local_currency_cost_in_foreign = float(math.pow(foreign_currency_cost_in_local, -1))

    return render.Root(
        render.Row(
            children = [
                render.Column(
                    children = [
                        render.Image(
                            src = get_currency(local_currency.lower())["flag"],
                            width = 16,
                            height = 15,
                        ),
                        render.Box(width = 16, height = 2),
                        render.Image(
                            src = get_currency(foreign_currency.lower())["flag"],
                            width = 16,
                            height = 15,
                        ),
                    ],
                ),
                render.Column(
                    cross_align = "left",
                    children = [
                        render.Box(
                            width = 48,
                            height = 15,
                            child = render.WrappedText(
                                content = humanize.float(get_appropriate_humanize_display(foreign_currency_cost_in_local), foreign_currency_cost_in_local),
                                width = 48,
                                align = "right",
                                font = "tb-8",
                            ),
                        ),
                        render.Box(width = 48, height = 2),
                        render.Box(
                            width = 48,
                            height = 15,
                            child = render.WrappedText(
                                content = humanize.float(get_appropriate_humanize_display(local_currency_cost_in_foreign), local_currency_cost_in_foreign),
                                width = 48,
                                align = "right",
                                font = "tb-8",
                            ),
                        ),
                    ],
                ),
            ],
        ),
    )

def get_schema():
    currency_options = [
        schema.Option(value = "CAD", display = "Canada"),
        schema.Option(value = "GBP", display = "United Kingdom"),
        schema.Option(value = "USD", display = "United States"),
        schema.Option(value = "ALL", display = "Albania"),
        schema.Option(value = "AOA", display = "Angola"),
        schema.Option(value = "ARS", display = "Argentina"),
        schema.Option(value = "AMD", display = "Armenia"),
        schema.Option(value = "AWG", display = "Aruba"),
        schema.Option(value = "AUD", display = "Australia"),
        schema.Option(value = "AZN", display = "Azerbaijan"),
        schema.Option(value = "BSD", display = "Bahamas"),
        schema.Option(value = "BHD", display = "Bahrain"),
        schema.Option(value = "BDT", display = "Bangladesh"),
        schema.Option(value = "BBD", display = "Barbados"),
        schema.Option(value = "BYN", display = "Belarus"),
        schema.Option(value = "BZD", display = "Belize"),
        schema.Option(value = "BMD", display = "Bermuda"),
        schema.Option(value = "BTN", display = "Bhutan"),
        schema.Option(value = "BOB", display = "Bolivia"),
        schema.Option(value = "BAM", display = "Bosnia and Herzegovina"),
        schema.Option(value = "BWP", display = "Botswana"),
        schema.Option(value = "BRL", display = "Brazil"),
        schema.Option(value = "BND", display = "Brunei"),
        schema.Option(value = "BGN", display = "Bulgaria"),
        schema.Option(value = "BIF", display = "Burundi"),
        schema.Option(value = "KHR", display = "Cambodia"),
        schema.Option(value = "CAD", display = "Canada"),
        schema.Option(value = "KYD", display = "Cayman Islands"),
        schema.Option(value = "XAF", display = "CEMAC"),
        schema.Option(value = "CLP", display = "Chile"),
        schema.Option(value = "CNY", display = "China"),
        schema.Option(value = "COP", display = "Colombia"),
        schema.Option(value = "KMF", display = "Comoros"),
        schema.Option(value = "CRC", display = "Costa Rica"),
        schema.Option(value = "HRK", display = "Croatia"),
        schema.Option(value = "CUP", display = "Cuba"),
        schema.Option(value = "CDF", display = "Democratic Republic of the Congo"),
        schema.Option(value = "DKK", display = "Denmark"),
        schema.Option(value = "DJF", display = "Djibouti"),
        schema.Option(value = "DOP", display = "Dominican Republic"),
        schema.Option(value = "EGP", display = "Egypt"),
        schema.Option(value = "ERN", display = "Eritrea"),
        schema.Option(value = "SZL", display = "Eswatini"),
        schema.Option(value = "ETB", display = "Ethiopia"),
        schema.Option(value = "EUR", display = "European Union Euro"),
        schema.Option(value = "FKP", display = "Falkland Islands"),
        schema.Option(value = "FOK", display = "Faroe Islands"),
        schema.Option(value = "FJD", display = "Fiji"),
        schema.Option(value = "GEL", display = "Georgia"),
        schema.Option(value = "GHS", display = "Ghana"),
        schema.Option(value = "GIP", display = "Gibraltar"),
        schema.Option(value = "GTQ", display = "Guatemala"),
        schema.Option(value = "GNF", display = "Guinea"),
        schema.Option(value = "GYD", display = "Guyana"),
        schema.Option(value = "HTG", display = "Haiti"),
        schema.Option(value = "HNL", display = "Honduras"),
        schema.Option(value = "HKD", display = "Hong Kong"),
        schema.Option(value = "HUF", display = "Hungary"),
        schema.Option(value = "ISK", display = "Iceland"),
        schema.Option(value = "INR", display = "India"),
        schema.Option(value = "IDR", display = "Indonesia"),
        schema.Option(value = "IRR", display = "Iran"),
        schema.Option(value = "IQD", display = "Iraq"),
        schema.Option(value = "IMP", display = "Isle of Man"),
        schema.Option(value = "ILS", display = "Israel"),
        schema.Option(value = "JMD", display = "Jamaica"),
        schema.Option(value = "JPY", display = "Japan"),
        schema.Option(value = "JEP", display = "Jersey"),
        schema.Option(value = "JOD", display = "Jordan"),
        schema.Option(value = "KZT", display = "Kazakhstan"),
        schema.Option(value = "KES", display = "Kenya"),
        schema.Option(value = "KID", display = "Kiribati"),
        schema.Option(value = "KWD", display = "Kuwait"),
        schema.Option(value = "KGS", display = "Kyrgyzstan"),
        schema.Option(value = "LAK", display = "Laos"),
        schema.Option(value = "LBP", display = "Lebanon"),
        schema.Option(value = "LSL", display = "Lesotho"),
        schema.Option(value = "LRD", display = "Liberia"),
        schema.Option(value = "LYD", display = "Libya"),
        schema.Option(value = "MOP", display = "Macau"),
        schema.Option(value = "MGA", display = "Madagascar"),
        schema.Option(value = "MWK", display = "Malawi"),
        schema.Option(value = "MYR", display = "Malaysia"),
        schema.Option(value = "MVR", display = "Maldives"),
        schema.Option(value = "MRU", display = "Mauritania"),
        schema.Option(value = "MUR", display = "Mauritius"),
        schema.Option(value = "MXN", display = "Mexico"),
        schema.Option(value = "MDL", display = "Moldova"),
        schema.Option(value = "MNT", display = "Mongolia"),
        schema.Option(value = "MAD", display = "Morocco"),
        schema.Option(value = "MZN", display = "Mozambique"),
        schema.Option(value = "MMK", display = "Myanmar"),
        schema.Option(value = "NAD", display = "Namibia"),
        schema.Option(value = "NPR", display = "Nepal"),
        schema.Option(value = "NZD", display = "New Zealand"),
        schema.Option(value = "NIO", display = "Nicaragua"),
        schema.Option(value = "NGN", display = "Nigeria"),
        schema.Option(value = "MKD", display = "North Macedonia"),
        schema.Option(value = "NOK", display = "Norway"),
        schema.Option(value = "OMR", display = "Oman"),
        schema.Option(value = "PKR", display = "Pakistan"),
        schema.Option(value = "PAB", display = "Panama"),
        schema.Option(value = "PGK", display = "Papua New Guinea"),
        schema.Option(value = "PYG", display = "Paraguay"),
        schema.Option(value = "PEN", display = "Peru"),
        schema.Option(value = "PHP", display = "Philippines"),
        schema.Option(value = "PLN", display = "Poland"),
        schema.Option(value = "QAR", display = "Qatar"),
        schema.Option(value = "RON", display = "Romania"),
        schema.Option(value = "RUB", display = "Russia"),
        schema.Option(value = "RWF", display = "Rwanda"),
        schema.Option(value = "SHP", display = "Saint Helena"),
        schema.Option(value = "WST", display = "Samoa"),
        schema.Option(value = "STN", display = "São Tomé and Príncipe"),
        schema.Option(value = "SAR", display = "Saudi Arabia"),
        schema.Option(value = "SCR", display = "Seychelles"),
        schema.Option(value = "SLE", display = "Sierra Leone"),
        schema.Option(value = "SGD", display = "Singapore"),
        schema.Option(value = "SBD", display = "Solomon Islands"),
        schema.Option(value = "SOS", display = "Somalia"),
        schema.Option(value = "ZAR", display = "South Africa"),
        schema.Option(value = "KRW", display = "South Korea"),
        schema.Option(value = "SSP", display = "South Sudan"),
        schema.Option(value = "LKR", display = "Sri Lanka"),
        schema.Option(value = "SDG", display = "Sudan"),
        schema.Option(value = "SEK", display = "Sweden"),
        schema.Option(value = "CHF", display = "Switzerland"),
        schema.Option(value = "SYP", display = "Syria"),
        schema.Option(value = "TWD", display = "Taiwan"),
        schema.Option(value = "TJS", display = "Tajikistan"),
        schema.Option(value = "TZS", display = "Tanzania"),
        schema.Option(value = "TOP", display = "Tonga"),
        schema.Option(value = "TTD", display = "Trinidad and Tobago"),
        schema.Option(value = "TND", display = "Tunisia"),
        schema.Option(value = "TRY", display = "Turkey"),
        schema.Option(value = "TMT", display = "Turkmenistan"),
        schema.Option(value = "TVD", display = "Tuvalu"),
        schema.Option(value = "UGX", display = "Uganda"),
        schema.Option(value = "UAH", display = "Ukraine"),
        schema.Option(value = "AED", display = "United Arab Emirates"),
        schema.Option(value = "GBP", display = "United Kingdom"),
        schema.Option(value = "USD", display = "United States"),
        schema.Option(value = "UYU", display = "Uruguay"),
        schema.Option(value = "UZS", display = "Uzbekistan"),
        schema.Option(value = "VUV", display = "Vanuatu"),
        schema.Option(value = "VES", display = "Venezuela"),
        schema.Option(value = "ZMW", display = "Zambia"),
        schema.Option(value = "ZWL", display = "Zimbabwe"),
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "local",
                name = "Local",
                desc = "Your local currency",
                icon = "locationDot",
                options = currency_options,
                default = currency_options[0].value,
            ),
            schema.Dropdown(
                id = "foreign",
                name = "Foreign",
                desc = "Foreign currency",
                icon = "globe",
                options = currency_options,
                default = currency_options[24].value,
            ),
            schema.Text(
                id = "api_key",
                name = "Exchangerate-API Key",
                desc = "Your Exchangerate-API.com API Key.",
                icon = "key",
                secret = True,
            ),
        ],
    )
