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
load("images/cve_flag.webp", CVE_FLAG = "file")
load("images/czk_flag.webp", CZK_FLAG = "file")
load("images/djf_flag.webp", DJF_FLAG = "file")
load("images/dkk_flag.webp", DKK_FLAG = "file")
load("images/dop_flag.webp", DOP_FLAG = "file")
load("images/dzd_flag.webp", DZD_FLAG = "file")
load("images/egp_flag.webp", EGP_FLAG = "file")
load("images/ern_flag.webp", ERN_FLAG = "file")
load("images/etb_flag.webp", ETB_FLAG = "file")
load("images/euro_flag.png", EURO_FLAG_ASSET = "file")
load("images/fjd_flag.webp", FJD_FLAG = "file")
load("images/fkp_flag.webp", FKP_FLAG = "file")
load("images/fok_flag.webp", FOK_FLAG = "file")
load("images/gbp_flag.webp", GBP_FLAG = "file")
load("images/gel_flag.webp", GEL_FLAG = "file")
load("images/ggp_flag.webp", GGP_FLAG = "file")
load("images/ghs_flag.webp", GHS_FLAG = "file")
load("images/gip_flag.webp", GIP_FLAG = "file")
load("images/gmd_flag.webp", GMD_FLAG = "file")
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
load("images/rsd_flag.webp", RSD_FLAG = "file")
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
load("images/vnd_flag.webp", VND_FLAG = "file")
load("images/vuv_flag.webp", VUV_FLAG = "file")
load("images/wst_flag.webp", WST_FLAG = "file")
load("images/xaf_flag.webp", XAF_FLAG = "file")
load("images/yer_flag.webp", YER_FLAG = "file")
load("images/zar_flag.webp", ZAR_FLAG = "file")
load("images/zmw_flag.webp", ZMW_FLAG = "file")
load("images/zwl_flag.webp", ZWL_FLAG = "file")
load("render.star", "canvas", "render")
load("schema.star", "schema")
load("time.star", "time")

def is_square():
    """True on a 64x64 panel.

    Panels are told apart by SHAPE, never by size: the 128x64 wide panel is
    also 64 tall.
    """
    w, h = canvas.size()
    return h == w

def center_on_square(child, width = None, height = None):
    """Centre `child` on the square (64x64); other panels get it unchanged.

    A scene hand-laid for 64x32 passes its size so the Box that centres it
    has the scene's bounds rather than the panel's.
    """
    if not is_square():
        return child
    if width != None and height != None:
        child = render.Box(width = width, height = height, child = child)
    return render.Box(width = canvas.width(), height = canvas.height(), child = child)

# Currency metadata and existing bundled flag assets.
currencies = {
    "aed": {"name": "United Arab Emirates", "flag": AED_FLAG.readall()},
    "all": {"name": "Albania", "flag": ALL_FLAG.readall()},
    "amd": {"name": "Armenia", "flag": AMD_FLAG.readall()},
    "aoa": {"name": "Angola", "flag": AOA_FLAG.readall()},
    "ars": {"name": "Argentina", "flag": ARS_FLAG.readall()},
    "aud": {"name": "Australia", "flag": AUD_FLAG.readall()},
    "awg": {"name": "Aruba", "flag": AWG_FLAG.readall()},
    "azn": {"name": "Azerbaijan", "flag": AZN_FLAG.readall()},
    "bam": {"name": "Bosnia and Herzegovina", "flag": BAM_FLAG.readall()},
    "bbd": {"name": "Barbados", "flag": BBD_FLAG.readall()},
    "bdt": {"name": "Bangladesh", "flag": BDT_FLAG.readall()},
    "bgn": {"name": "Bulgaria", "flag": BGN_FLAG.readall()},
    "bhd": {"name": "Bahrain", "flag": BHD_FLAG.readall()},
    "bif": {"name": "Burundi", "flag": BIF_FLAG.readall()},
    "bmd": {"name": "Bermuda", "flag": BMD_FLAG.readall()},
    "bnd": {"name": "Brunei Darussalam", "flag": BND_FLAG.readall()},
    "bob": {"name": "Bolivia", "flag": BOB_FLAG.readall()},
    "brl": {"name": "Brazil", "flag": BRL_FLAG.readall()},
    "bsd": {"name": "Bahamas", "flag": BSD_FLAG.readall()},
    "btn": {"name": "Bhutan", "flag": BTN_FLAG.readall()},
    "bwp": {"name": "Botswana", "flag": BWP_FLAG.readall()},
    "byn": {"name": "Belarus", "flag": BYN_FLAG.readall()},
    "bzd": {"name": "Belize", "flag": BZD_FLAG.readall()},
    "cad": {"name": "Canada", "flag": CAD_FLAG.readall()},
    "cdf": {"name": "Congo", "flag": CDF_FLAG.readall()},
    "chf": {"name": "Switzerland", "flag": CHF_FLAG.readall()},
    "clf": {"name": "Chile (Unidad de Fomento)", "flag": CLP_FLAG.readall()},
    "clp": {"name": "Chile", "flag": CLP_FLAG.readall()},
    "cnh": {"name": "China (Offshore Renminbi)", "flag": CNY_FLAG.readall()},
    "cny": {"name": "China", "flag": CNY_FLAG.readall()},
    "cop": {"name": "Colombia", "flag": COP_FLAG.readall()},
    "crc": {"name": "Costa Rica", "flag": CRC_FLAG.readall()},
    "cup": {"name": "Cuba", "flag": CUP_FLAG.readall()},
    "cve": {"name": "Cape Verde", "flag": CVE_FLAG.readall()},
    "czk": {"name": "Czech Republic", "flag": CZK_FLAG.readall()},
    "djf": {"name": "Djibouti", "flag": DJF_FLAG.readall()},
    "dkk": {"name": "Denmark", "flag": DKK_FLAG.readall()},
    "dop": {"name": "Dominican Republic", "flag": DOP_FLAG.readall()},
    "dzd": {"name": "Algeria", "flag": DZD_FLAG.readall()},
    "egp": {"name": "Egypt", "flag": EGP_FLAG.readall()},
    "ern": {"name": "Eritrea", "flag": ERN_FLAG.readall()},
    "etb": {"name": "Ethiopia", "flag": ETB_FLAG.readall()},
    "eur": {"name": "Euro", "flag": EURO_FLAG_ASSET.readall()},
    "fjd": {"name": "Fiji", "flag": FJD_FLAG.readall()},
    "fkp": {"name": "Falkland Islands", "flag": FKP_FLAG.readall()},
    "fok": {"name": "Faroe Islands", "flag": FOK_FLAG.readall()},
    "gbp": {"name": "United Kingdom", "flag": GBP_FLAG.readall()},
    "gel": {"name": "Georgia", "flag": GEL_FLAG.readall()},
    "ggp": {"name": "Guernsey", "flag": GGP_FLAG.readall()},
    "ghs": {"name": "Ghana", "flag": GHS_FLAG.readall()},
    "gip": {"name": "Gibraltar", "flag": GIP_FLAG.readall()},
    "gmd": {"name": "The Gambia", "flag": GMD_FLAG.readall()},
    "gnf": {"name": "Guinea", "flag": GNF_FLAG.readall()},
    "gtq": {"name": "Guatemala", "flag": GTQ_FLAG.readall()},
    "gyd": {"name": "Guyana", "flag": GYD_FLAG.readall()},
    "hkd": {"name": "Hong Kong", "flag": HKD_FLAG.readall()},
    "hnl": {"name": "Honduras", "flag": HNL_FLAG.readall()},
    "hrk": {"name": "Croatia", "flag": HRK_FLAG.readall()},
    "htg": {"name": "Haiti", "flag": HTG_FLAG.readall()},
    "huf": {"name": "Hungary", "flag": HUF_FLAG.readall()},
    "idr": {"name": "Indonesia", "flag": IDR_FLAG.readall()},
    "ils": {"name": "Israel", "flag": ILS_FLAG.readall()},
    "imp": {"name": "Isle of Man", "flag": IMP_FLAG.readall()},
    "inr": {"name": "India", "flag": INR_FLAG.readall()},
    "iqd": {"name": "Iraq", "flag": IQD_FLAG.readall()},
    "irr": {"name": "Iran", "flag": IRR_FLAG.readall()},
    "isk": {"name": "Iceland", "flag": ISK_FLAG.readall()},
    "jep": {"name": "Jersey", "flag": JEP_FLAG.readall()},
    "jmd": {"name": "Jamaica", "flag": JMD_FLAG.readall()},
    "jod": {"name": "Jordan", "flag": JOD_FLAG.readall()},
    "jpy": {"name": "Japan", "flag": JPY_FLAG.readall()},
    "kes": {"name": "Kenya", "flag": KES_FLAG.readall()},
    "kgs": {"name": "Kyrgyzstan", "flag": KGS_FLAG.readall()},
    "khr": {"name": "Cambodia", "flag": KHR_FLAG.readall()},
    "kid": {"name": "Kiribati", "flag": KID_FLAG.readall()},
    "kmf": {"name": "Comoros", "flag": KMF_FLAG.readall()},
    "krw": {"name": "South Korea", "flag": KRW_FLAG.readall()},
    "kwd": {"name": "Kuwait", "flag": KWD_FLAG.readall()},
    "kyd": {"name": "Cayman Islands", "flag": KYD_FLAG.readall()},
    "kzt": {"name": "Kazakhstan", "flag": KZT_FLAG.readall()},
    "lak": {"name": "Laos", "flag": LAK_FLAG.readall()},
    "lbp": {"name": "Lebanon", "flag": LBP_FLAG.readall()},
    "lkr": {"name": "Sri Lanka", "flag": LKR_FLAG.readall()},
    "lrd": {"name": "Liberia", "flag": LRD_FLAG.readall()},
    "lsl": {"name": "Lesotho", "flag": LSL_FLAG.readall()},
    "lyd": {"name": "Libya", "flag": LYD_FLAG.readall()},
    "mad": {"name": "Morocco", "flag": MAD_FLAG.readall()},
    "mdl": {"name": "Moldova, Republic of", "flag": MDL_FLAG.readall()},
    "mga": {"name": "Madagascar", "flag": MGA_FLAG.readall()},
    "mkd": {"name": "North Macedonia", "flag": MKD_FLAG.readall()},
    "mmk": {"name": "Myanmar", "flag": MMK_FLAG.readall()},
    "mnt": {"name": "Mongolia", "flag": MNT_FLAG.readall()},
    "mop": {"name": "Macao", "flag": MOP_FLAG.readall()},
    "mru": {"name": "Mauritania", "flag": MRU_FLAG.readall()},
    "mur": {"name": "Mauritius", "flag": MUR_FLAG.readall()},
    "mvr": {"name": "Maldives", "flag": MVR_FLAG.readall()},
    "mwk": {"name": "Malawi", "flag": MWK_FLAG.readall()},
    "mxn": {"name": "Mexico", "flag": MXN_FLAG.readall()},
    "myr": {"name": "Malaysia", "flag": MYR_FLAG.readall()},
    "mzn": {"name": "Mozambique", "flag": MZN_FLAG.readall()},
    "nad": {"name": "Namibia", "flag": NAD_FLAG.readall()},
    "ngn": {"name": "Nigeria", "flag": NGN_FLAG.readall()},
    "nio": {"name": "Nicaragua", "flag": NIO_FLAG.readall()},
    "nok": {"name": "Norway", "flag": NOK_FLAG.readall()},
    "npr": {"name": "Nepal", "flag": NPR_FLAG.readall()},
    "nzd": {"name": "New Zealand", "flag": NZD_FLAG.readall()},
    "omr": {"name": "Oman", "flag": OMR_FLAG.readall()},
    "pab": {"name": "Panama", "flag": PAB_FLAG.readall()},
    "pen": {"name": "Peru", "flag": PEN_FLAG.readall()},
    "pgk": {"name": "Papua New Guinea", "flag": PGK_FLAG.readall()},
    "php": {"name": "Philippines", "flag": PHP_FLAG.readall()},
    "pkr": {"name": "Pakistan", "flag": PKR_FLAG.readall()},
    "pln": {"name": "Poland", "flag": PLN_FLAG.readall()},
    "pyg": {"name": "Paraguay", "flag": PYG_FLAG.readall()},
    "qar": {"name": "Qatar", "flag": QAR_FLAG.readall()},
    "ron": {"name": "Romania", "flag": RON_FLAG.readall()},
    "rsd": {"name": "Serbia", "flag": RSD_FLAG.readall()},
    "rub": {"name": "Russia", "flag": RUB_FLAG.readall()},
    "rwf": {"name": "Rwanda", "flag": RWF_FLAG.readall()},
    "sar": {"name": "Saudi Arabia", "flag": SAR_FLAG.readall()},
    "sbd": {"name": "Solomon Islands", "flag": SBD_FLAG.readall()},
    "scr": {"name": "Seychelles", "flag": SCR_FLAG.readall()},
    "sdg": {"name": "Sudan", "flag": SDG_FLAG.readall()},
    "sek": {"name": "Sweden", "flag": SEK_FLAG.readall()},
    "sgd": {"name": "Singapore", "flag": SGD_FLAG.readall()},
    "shp": {"name": "Saint Helena", "flag": SHP_FLAG.readall()},
    "sle": {"name": "Sierra Leone", "flag": SLE_FLAG.readall()},
    "sos": {"name": "Somalia", "flag": SOS_FLAG.readall()},
    "srd": {"name": "Suriname", "flag": SRD_FLAG.readall()},
    "ssp": {"name": "South Sudan", "flag": SSP_FLAG.readall()},
    "stn": {"name": "Sao Tome and Principe", "flag": STN_FLAG.readall()},
    "syp": {"name": "Syrian Arab Republic", "flag": SYP_FLAG.readall()},
    "szl": {"name": "Eswatini", "flag": SZL_FLAG.readall()},
    "thb": {"name": "Thailand", "flag": THB_FLAG.readall()},
    "tjs": {"name": "Tajikistan", "flag": TJS_FLAG.readall()},
    "tmt": {"name": "Turkmenistan", "flag": TMT_FLAG.readall()},
    "tnd": {"name": "Tunisia", "flag": TND_FLAG.readall()},
    "top": {"name": "Tonga", "flag": TOP_FLAG.readall()},
    "try": {"name": "Turkey", "flag": TRY_FLAG.readall()},
    "ttd": {"name": "Trinidad and Tobago", "flag": TTD_FLAG.readall()},
    "tvd": {"name": "Tuvalu", "flag": TVD_FLAG.readall()},
    "twd": {"name": "Taiwan", "flag": TWD_FLAG.readall()},
    "tzs": {"name": "Tanzania", "flag": TZS_FLAG.readall()},
    "uah": {"name": "Ukraine", "flag": UAH_FLAG.readall()},
    "ugx": {"name": "Uganda", "flag": UGX_FLAG.readall()},
    "usd": {"name": "USA", "flag": USD_FLAG.readall()},
    "uyu": {"name": "Uruguay", "flag": UYU_FLAG.readall()},
    "uzs": {"name": "Uzbekistan", "flag": UZS_FLAG.readall()},
    "ves": {"name": "Venezuela", "flag": VES_FLAG.readall()},
    "vnd": {"name": "Vietnam", "flag": VND_FLAG.readall()},
    "vuv": {"name": "Vanuatu", "flag": VUV_FLAG.readall()},
    "wst": {"name": "Samoa", "flag": WST_FLAG.readall()},
    "xaf": {"name": "Central African Republic", "flag": XAF_FLAG.readall()},
    "yer": {"name": "Yemen", "flag": YER_FLAG.readall()},
    "zar": {"name": "South Africa", "flag": ZAR_FLAG.readall()},
    "zmw": {"name": "Zambia", "flag": ZMW_FLAG.readall()},
    "zwl": {"name": "Zimbabwe", "flag": ZWL_FLAG.readall()},
}

# The API returns units of the foreign currency per ONE local currency.
# The display intentionally puts the home/local currency on the TOP row:
#
#   TOP:    local flag   -> 1 local buys this many foreign currency units.
#   BOTTOM: foreign flag -> 1 foreign buys this many local currency units.
#
# Example only: if 1 USD = 1.36 CAD, the display is:
#   USA flag       1.36
#   Canada flag    0.735  (approximately; actual text uses the masks below)
#
# The flag identifies the currency being SPENT, not the units of the number.
# Keep this established convention: do not swap the two displayed rates.

DEFAULT_LOCAL = "USD"
DEFAULT_FOREIGN = "CAD"
HTTP_CACHE_SECONDS = 60
MIN_CACHE_SECONDS = 300
MAX_CACHE_SECONDS = 86400

def get_currency(currency_code):
    return currencies.get(currency_code.lower())

def error_display(message):
    return render.Root(
        child = render.Box(
            child = render.WrappedText(
                content = message,
                width = 64,
                align = "center",
                color = "#ff0000",
            ),
        ),
    )

def api_error_message(data):
    messages = {
        "invalid-key": "Check API Key",
        "inactive-account": "Activate API Account",
        "quota-reached": "API Quota Reached",
        "unsupported-code": "Currency Unsupported",
        "unknown-code": "Currency Unsupported",
        "malformed-request": "API Request Error",
    }
    return messages.get(data.get("error-type"), "Exchange API Error")

def is_positive_number(value):
    # JSON rates must be positive numbers, not strings, booleans or null.
    if type(value) not in ["int", "float"]:
        return False

    # Reject NaN and infinity as well as zero and negative numbers.
    return value > 0 and value < float("inf")

def validate_exchange_data(data, local_currency):
    if type(data) != "dict":
        return "Invalid API Response"
    if data.get("result") != "success":
        return api_error_message(data)
    if data.get("base_code") != local_currency:
        return "Wrong Base Currency"
    if type(data.get("conversion_rates")) != "dict":
        return "Rates Unavailable"
    return None

def get_currency_information(currency_url):
    # Keep HTTP caching short because cache.star below handles the longer,
    # API-timestamp-based lifetime. Do not print the URL: it contains the key.
    res = http.get(url = currency_url, ttl_seconds = HTTP_CACHE_SECONDS)
    if res.status_code != 200:
        if res.status_code == 429:
            return None, "API Rate Limit"
        if res.status_code in [401, 403]:
            return None, "API Access Denied"
        return None, "API HTTP %s" % res.status_code
    return res.json(), None

def get_cache_time(data):
    # Refresh five minutes after the API's advertised next update.
    # Missing, invalid or stale timestamps get a safe short fallback TTL.
    next_update = data.get("time_next_update_unix")
    if not is_positive_number(next_update):
        return MIN_CACHE_SECONDS
    seconds = int(next_update) - int(time.now().unix) + 300
    return max(MIN_CACHE_SECONDS, min(MAX_CACHE_SECONDS, seconds))

def get_appropriate_humanize_display(number):
    """Keep the original masks, tuned for visual balance on a small display.

    This is a glanceable, ballpark comparison, not an executable exchange
    quote. Visual appeal takes priority over uniform decimal precision.
    The different thresholds are intentional and remain unchanged.
    """
    if number > 1000:
        return "#.##"
    elif number > 10:
        return "#.####"
    elif number > 0.1:
        return "#.###"
    elif number > 0.0001:
        return "#.####"
    return "#.######"

def show_instructions_screen():
    messages = [
        "Currency Converter",
        "Choose your home and foreign currencies in settings. Enter your ExchangeRate-API key.",
        "Top: one home currency unit buys the shown amount of foreign currency. Bottom: one foreign unit buys the shown amount of home currency. The flag shows which currency you spend.",
        "Rates are approximate, not a live exchange quote. Turn off Show Instructions in settings to return to rates.",
    ]

    children = []
    offset = 15

    for index in range(len(messages)):
        message = messages[index]
        children.append(
            render.Marquee(
                width = 64,
                offset_start = offset,
                child = render.Text(
                    message,
                    font = "tb-8",
                    color = "#65D0E6" if index == 0 else "#F4A306",
                ),
            ),
        )
        offset += len(message) * 5

    return render.Root(
        child = center_on_square(render.Column(children = children)),
        show_full_animation = True,
    )

def main(config):
    if config.bool("show_instructions", False):
        return show_instructions_screen(config)

    local_currency = (config.get("local") or DEFAULT_LOCAL).strip().upper()
    foreign_currency = (config.get("foreign") or DEFAULT_FOREIGN).strip().upper()
    local_info = get_currency(local_currency)
    foreign_info = get_currency(foreign_currency)
    if local_info == None or foreign_info == None:
        return error_display("Invalid Currency")

    key = (config.get("api_key") or "").strip()
    if not key:
        return error_display("Enter API Key")

    exchange_rate_url = "https://v6.exchangerate-api.com/v6/%s/latest/%s" % (key, local_currency)

    # Cache is shared per app. Include the API key and base currency to keep
    # different accounts and base-currency datasets separate. Version the
    # key so responses cached by the older implementation are not reused.
    cache_key = "currency-converter-v2:" + exchange_rate_url
    encoded_data = cache.get(cache_key)
    data = None
    if encoded_data != None:
        data = json.decode(encoded_data)

        # Ignore a structurally invalid cached response and fetch again.
        if validate_exchange_data(data, local_currency) != None:
            data = None

    if data == None:
        data, error = get_currency_information(exchange_rate_url)
        if error != None:
            return error_display(error)
        error = validate_exchange_data(data, local_currency)
        if error != None:
            return error_display(error)

        # Cache only successful responses with the expected base and rates.
        cache.set(cache_key, json.encode(data), ttl_seconds = get_cache_time(data))

    rate = data["conversion_rates"].get(foreign_currency)
    if rate == None:
        return error_display("Rate Unavailable")
    if not is_positive_number(rate):
        return error_display("Invalid Rate")

    # TOP: one unit of home/local currency buys this many foreign units.
    foreign_per_local = float(rate)

    # BOTTOM: one unit of foreign currency buys this many home/local units.
    local_per_foreign = 1.0 / foreign_per_local
    if not is_positive_number(local_per_foreign):
        return error_display("Invalid Rate")

    return render.Root(
        child = center_on_square(render.Row(
            children = [
                render.Column(
                    children = [
                        render.Image(src = local_info["flag"], width = 16, height = 15),
                        render.Box(width = 16, height = 2),
                        render.Image(src = foreign_info["flag"], width = 16, height = 15),
                    ],
                ),
                render.Column(
                    cross_align = "left",
                    children = [
                        render.Box(
                            width = 48,
                            height = 15,
                            child = render.WrappedText(
                                content = humanize.float(get_appropriate_humanize_display(foreign_per_local), foreign_per_local),
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
                                content = humanize.float(get_appropriate_humanize_display(local_per_foreign), local_per_foreign),
                                width = 48,
                                align = "right",
                                font = "tb-8",
                            ),
                        ),
                    ],
                ),
            ],
        )),
    )

def get_schema():
    # Build options from the same currency dictionary used for flags, so
    # supported entries cannot be accidentally omitted or duplicated.
    # Keep CAD, GBP and USD pinned first, as in the original menu.
    preferred = ["cad", "gbp", "usd"]
    labels = {
        "usd": "United States",
        "eur": "European Union Euro",
        "bnd": "Brunei",
        "cdf": "Democratic Republic of the Congo",
        "xaf": "CEMAC",
        "syp": "Syria",
        "stn": "Sao Tome and Principe",
    }

    # Sorting these display-name/code pairs gives the remaining entries
    # alphabetical country-name order without requiring a lambda function.
    remaining = sorted([
        (labels.get(code, currencies[code]["name"]), code)
        for code in currencies
        if code not in preferred
    ])
    ordered_codes = preferred + [entry[1] for entry in remaining]
    currency_options = [
        schema.Option(
            value = code.upper(),
            display = labels.get(code, currencies[code]["name"]),
        )
        for code in ordered_codes
    ]
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(
                id = "show_instructions",
                name = "Show Instructions",
                desc = "Show scrolling help instead of exchange rates",
                icon = "circleInfo",
                default = False,
            ),
            schema.Dropdown(
                id = "local",
                name = "Local",
                desc = "Your home currency (top row)",
                icon = "locationDot",
                options = currency_options,
                default = DEFAULT_LOCAL,
            ),
            schema.Dropdown(
                id = "foreign",
                name = "Foreign",
                desc = "Foreign currency (bottom row)",
                icon = "globe",
                options = currency_options,
                default = DEFAULT_FOREIGN,
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
