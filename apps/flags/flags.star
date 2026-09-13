"""
Applet: Flags
Summary: Displays a country flag
Description: Displays a random or specific country flag.
Author: btjones
"""

# Copyright 2022 Brandon Jones

# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

load("images/ad_flag.webp", AD_FLAG = "file")
load("images/ae_flag.webp", AE_FLAG = "file")
load("images/af_flag.webp", AF_FLAG = "file")
load("images/ag_flag.webp", AG_FLAG = "file")
load("images/ai_flag.webp", AI_FLAG = "file")
load("images/al_flag.webp", AL_FLAG = "file")
load("images/am_flag.webp", AM_FLAG = "file")
load("images/ao_flag.webp", AO_FLAG = "file")
load("images/aq_flag.webp", AQ_FLAG = "file")
load("images/ar_flag.webp", AR_FLAG = "file")
load("images/as_flag.webp", AS_FLAG = "file")
load("images/at_flag.webp", AT_FLAG = "file")
load("images/au_flag.webp", AU_FLAG = "file")
load("images/aw_flag.webp", AW_FLAG = "file")
load("images/ax_flag.webp", AX_FLAG = "file")
load("images/az_flag.webp", AZ_FLAG = "file")
load("images/ba_flag.webp", BA_FLAG = "file")
load("images/bb_flag.webp", BB_FLAG = "file")
load("images/bd_flag.webp", BD_FLAG = "file")
load("images/be_flag.webp", BE_FLAG = "file")
load("images/bf_flag.webp", BF_FLAG = "file")
load("images/bg_flag.webp", BG_FLAG = "file")
load("images/bh_flag.webp", BH_FLAG = "file")
load("images/bi_flag.webp", BI_FLAG = "file")
load("images/bj_flag.webp", BJ_FLAG = "file")
load("images/bl_flag.webp", BL_FLAG = "file")
load("images/bm_flag.webp", BM_FLAG = "file")
load("images/bn_flag.webp", BN_FLAG = "file")
load("images/bo_flag.webp", BO_FLAG = "file")
load("images/bq_flag.webp", BQ_FLAG = "file")
load("images/br_flag.webp", BR_FLAG = "file")
load("images/bs_flag.webp", BS_FLAG = "file")
load("images/bt_flag.webp", BT_FLAG = "file")
load("images/bv_flag.webp", BV_FLAG = "file")
load("images/bw_flag.webp", BW_FLAG = "file")
load("images/by_flag.webp", BY_FLAG = "file")
load("images/bz_flag.webp", BZ_FLAG = "file")
load("images/ca_flag.webp", CA_FLAG = "file")
load("images/cc_flag.webp", CC_FLAG = "file")
load("images/cd_flag.webp", CD_FLAG = "file")
load("images/cf_flag.webp", CF_FLAG = "file")
load("images/cg_flag.webp", CG_FLAG = "file")
load("images/ch_flag.webp", CH_FLAG = "file")
load("images/ci_flag.webp", CI_FLAG = "file")
load("images/ck_flag.webp", CK_FLAG = "file")
load("images/cl_flag.webp", CL_FLAG = "file")
load("images/cm_flag.webp", CM_FLAG = "file")
load("images/cn_flag.webp", CN_FLAG = "file")
load("images/co_flag.webp", CO_FLAG = "file")
load("images/cr_flag.webp", CR_FLAG = "file")
load("images/cu_flag.webp", CU_FLAG = "file")
load("images/cv_flag.webp", CV_FLAG = "file")
load("images/cw_flag.webp", CW_FLAG = "file")
load("images/cx_flag.webp", CX_FLAG = "file")
load("images/cy_flag.webp", CY_FLAG = "file")
load("images/cz_flag.webp", CZ_FLAG = "file")
load("images/de_flag.webp", DE_FLAG = "file")
load("images/dj_flag.webp", DJ_FLAG = "file")
load("images/dk_flag.webp", DK_FLAG = "file")
load("images/dm_flag.webp", DM_FLAG = "file")
load("images/do_flag.webp", DO_FLAG = "file")
load("images/dz_flag.webp", DZ_FLAG = "file")
load("images/ec_flag.webp", EC_FLAG = "file")
load("images/ee_flag.webp", EE_FLAG = "file")
load("images/eg_flag.webp", EG_FLAG = "file")
load("images/eh_flag.webp", EH_FLAG = "file")
load("images/er_flag.webp", ER_FLAG = "file")
load("images/es_flag.webp", ES_FLAG = "file")
load("images/et_flag.webp", ET_FLAG = "file")
load("images/fi_flag.webp", FI_FLAG = "file")
load("images/fj_flag.webp", FJ_FLAG = "file")
load("images/fk_flag.webp", FK_FLAG = "file")
load("images/fm_flag.webp", FM_FLAG = "file")
load("images/fo_flag.webp", FO_FLAG = "file")
load("images/fr_flag.webp", FR_FLAG = "file")
load("images/ga_flag.webp", GA_FLAG = "file")
load("images/gb_flag.webp", GB_FLAG = "file")
load("images/gd_flag.webp", GD_FLAG = "file")
load("images/ge_flag.webp", GE_FLAG = "file")
load("images/gf_flag.webp", GF_FLAG = "file")
load("images/gg_flag.webp", GG_FLAG = "file")
load("images/gh_flag.webp", GH_FLAG = "file")
load("images/gi_flag.webp", GI_FLAG = "file")
load("images/gl_flag.webp", GL_FLAG = "file")
load("images/gm_flag.webp", GM_FLAG = "file")
load("images/gn_flag.webp", GN_FLAG = "file")
load("images/gp_flag.webp", GP_FLAG = "file")
load("images/gq_flag.webp", GQ_FLAG = "file")
load("images/gr_flag.webp", GR_FLAG = "file")
load("images/gs_flag.webp", GS_FLAG = "file")
load("images/gt_flag.webp", GT_FLAG = "file")
load("images/gu_flag.webp", GU_FLAG = "file")
load("images/gw_flag.webp", GW_FLAG = "file")
load("images/gy_flag.webp", GY_FLAG = "file")
load("images/hk_flag.webp", HK_FLAG = "file")
load("images/hm_flag.webp", HM_FLAG = "file")
load("images/hn_flag.webp", HN_FLAG = "file")
load("images/hr_flag.webp", HR_FLAG = "file")
load("images/ht_flag.webp", HT_FLAG = "file")
load("images/hu_flag.webp", HU_FLAG = "file")
load("images/id_flag.webp", ID_FLAG = "file")
load("images/ie_flag.webp", IE_FLAG = "file")
load("images/il_flag.webp", IL_FLAG = "file")
load("images/im_flag.webp", IM_FLAG = "file")
load("images/in_flag.webp", IN_FLAG = "file")
load("images/io_flag.webp", IO_FLAG = "file")
load("images/iq_flag.webp", IQ_FLAG = "file")
load("images/ir_flag.webp", IR_FLAG = "file")
load("images/is_flag.webp", IS_FLAG = "file")
load("images/it_flag.webp", IT_FLAG = "file")
load("images/je_flag.webp", JE_FLAG = "file")
load("images/jm_flag.webp", JM_FLAG = "file")
load("images/jo_flag.webp", JO_FLAG = "file")
load("images/jp_flag.webp", JP_FLAG = "file")
load("images/ke_flag.webp", KE_FLAG = "file")
load("images/kg_flag.webp", KG_FLAG = "file")
load("images/kh_flag.webp", KH_FLAG = "file")
load("images/ki_flag.webp", KI_FLAG = "file")
load("images/km_flag.webp", KM_FLAG = "file")
load("images/kn_flag.webp", KN_FLAG = "file")
load("images/kp_flag.webp", KP_FLAG = "file")
load("images/kr_flag.webp", KR_FLAG = "file")
load("images/kw_flag.webp", KW_FLAG = "file")
load("images/ky_flag.webp", KY_FLAG = "file")
load("images/kz_flag.webp", KZ_FLAG = "file")
load("images/la_flag.webp", LA_FLAG = "file")
load("images/lb_flag.webp", LB_FLAG = "file")
load("images/lc_flag.webp", LC_FLAG = "file")
load("images/li_flag.webp", LI_FLAG = "file")
load("images/lk_flag.webp", LK_FLAG = "file")
load("images/lr_flag.webp", LR_FLAG = "file")
load("images/ls_flag.webp", LS_FLAG = "file")
load("images/lt_flag.webp", LT_FLAG = "file")
load("images/lu_flag.webp", LU_FLAG = "file")
load("images/lv_flag.webp", LV_FLAG = "file")
load("images/ly_flag.webp", LY_FLAG = "file")
load("images/ma_flag.webp", MA_FLAG = "file")
load("images/mc_flag.webp", MC_FLAG = "file")
load("images/md_flag.webp", MD_FLAG = "file")
load("images/me_flag.webp", ME_FLAG = "file")
load("images/mf_flag.webp", MF_FLAG = "file")
load("images/mg_flag.webp", MG_FLAG = "file")
load("images/mh_flag.webp", MH_FLAG = "file")
load("images/mk_flag.webp", MK_FLAG = "file")
load("images/ml_flag.webp", ML_FLAG = "file")
load("images/mm_flag.webp", MM_FLAG = "file")
load("images/mn_flag.webp", MN_FLAG = "file")
load("images/mo_flag.webp", MO_FLAG = "file")
load("images/mp_flag.webp", MP_FLAG = "file")
load("images/mq_flag.webp", MQ_FLAG = "file")
load("images/mr_flag.webp", MR_FLAG = "file")
load("images/ms_flag.webp", MS_FLAG = "file")
load("images/mt_flag.webp", MT_FLAG = "file")
load("images/mu_flag.webp", MU_FLAG = "file")
load("images/mv_flag.webp", MV_FLAG = "file")
load("images/mw_flag.webp", MW_FLAG = "file")
load("images/mx_flag.webp", MX_FLAG = "file")
load("images/my_flag.webp", MY_FLAG = "file")
load("images/mz_flag.webp", MZ_FLAG = "file")
load("images/na_flag.webp", NA_FLAG = "file")
load("images/nc_flag.webp", NC_FLAG = "file")
load("images/ne_flag.webp", NE_FLAG = "file")
load("images/nf_flag.webp", NF_FLAG = "file")
load("images/ng_flag.webp", NG_FLAG = "file")
load("images/ni_flag.webp", NI_FLAG = "file")
load("images/nl_flag.webp", NL_FLAG = "file")
load("images/no_flag.webp", NO_FLAG = "file")
load("images/np_flag.webp", NP_FLAG = "file")
load("images/nr_flag.webp", NR_FLAG = "file")
load("images/nu_flag.webp", NU_FLAG = "file")
load("images/nz_flag.webp", NZ_FLAG = "file")
load("images/om_flag.webp", OM_FLAG = "file")
load("images/pa_flag.webp", PA_FLAG = "file")
load("images/pe_flag.webp", PE_FLAG = "file")
load("images/pf_flag.webp", PF_FLAG = "file")
load("images/pg_flag.webp", PG_FLAG = "file")
load("images/ph_flag.webp", PH_FLAG = "file")
load("images/pk_flag.webp", PK_FLAG = "file")
load("images/pl_flag.webp", PL_FLAG = "file")
load("images/pm_flag.webp", PM_FLAG = "file")
load("images/pn_flag.webp", PN_FLAG = "file")
load("images/pr_flag.webp", PR_FLAG = "file")
load("images/ps_flag.webp", PS_FLAG = "file")
load("images/pt_flag.webp", PT_FLAG = "file")
load("images/pw_flag.webp", PW_FLAG = "file")
load("images/py_flag.webp", PY_FLAG = "file")
load("images/qa_flag.webp", QA_FLAG = "file")
load("images/re_flag.webp", RE_FLAG = "file")
load("images/ro_flag.webp", RO_FLAG = "file")
load("images/rs_flag.webp", RS_FLAG = "file")
load("images/ru_flag.webp", RU_FLAG = "file")
load("images/rw_flag.webp", RW_FLAG = "file")
load("images/sa_flag.webp", SA_FLAG = "file")
load("images/sb_flag.webp", SB_FLAG = "file")
load("images/sc_flag.webp", SC_FLAG = "file")
load("images/sd_flag.webp", SD_FLAG = "file")
load("images/se_flag.webp", SE_FLAG = "file")
load("images/sg_flag.webp", SG_FLAG = "file")
load("images/sh_flag.webp", SH_FLAG = "file")
load("images/si_flag.webp", SI_FLAG = "file")
load("images/sj_flag.webp", SJ_FLAG = "file")
load("images/sk_flag.webp", SK_FLAG = "file")
load("images/sl_flag.webp", SL_FLAG = "file")
load("images/sm_flag.webp", SM_FLAG = "file")
load("images/sn_flag.webp", SN_FLAG = "file")
load("images/so_flag.webp", SO_FLAG = "file")
load("images/sr_flag.webp", SR_FLAG = "file")
load("images/ss_flag.webp", SS_FLAG = "file")
load("images/st_flag.webp", ST_FLAG = "file")
load("images/sv_flag.webp", SV_FLAG = "file")
load("images/sx_flag.webp", SX_FLAG = "file")
load("images/sy_flag.webp", SY_FLAG = "file")
load("images/sz_flag.webp", SZ_FLAG = "file")
load("images/tc_flag.webp", TC_FLAG = "file")
load("images/td_flag.webp", TD_FLAG = "file")
load("images/tf_flag.webp", TF_FLAG = "file")
load("images/tg_flag.webp", TG_FLAG = "file")
load("images/th_flag.webp", TH_FLAG = "file")
load("images/tj_flag.webp", TJ_FLAG = "file")
load("images/tk_flag.webp", TK_FLAG = "file")
load("images/tl_flag.webp", TL_FLAG = "file")
load("images/tm_flag.webp", TM_FLAG = "file")
load("images/tn_flag.webp", TN_FLAG = "file")
load("images/to_flag.webp", TO_FLAG = "file")
load("images/tr_flag.webp", TR_FLAG = "file")
load("images/tt_flag.webp", TT_FLAG = "file")
load("images/tv_flag.webp", TV_FLAG = "file")
load("images/tw_flag.webp", TW_FLAG = "file")
load("images/tz_flag.webp", TZ_FLAG = "file")
load("images/ua_flag.webp", UA_FLAG = "file")
load("images/ug_flag.webp", UG_FLAG = "file")
load("images/um_flag.webp", UM_FLAG = "file")
load("images/us_flag.webp", US_FLAG = "file")
load("images/uy_flag.webp", UY_FLAG = "file")
load("images/uz_flag.webp", UZ_FLAG = "file")
load("images/va_flag.webp", VA_FLAG = "file")
load("images/vc_flag.webp", VC_FLAG = "file")
load("images/ve_flag.webp", VE_FLAG = "file")
load("images/vg_flag.webp", VG_FLAG = "file")
load("images/vi_flag.webp", VI_FLAG = "file")
load("images/vn_flag.webp", VN_FLAG = "file")
load("images/vu_flag.webp", VU_FLAG = "file")
load("images/wf_flag.webp", WF_FLAG = "file")
load("images/ws_flag.webp", WS_FLAG = "file")
load("images/xk_flag.webp", XK_FLAG = "file")
load("images/ye_flag.webp", YE_FLAG = "file")
load("images/yt_flag.webp", YT_FLAG = "file")
load("images/za_flag.webp", ZA_FLAG = "file")
load("images/zm_flag.webp", ZM_FLAG = "file")
load("images/zw_flag.webp", ZW_FLAG = "file")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

COUNTRY_CODE_SCHEMA_ID = "country_code"
TEXT_COLOR_SCHEMA_ID = "text_color"
BG_COLOR_SCHEMA_ID = "bg_color"
SHOW_NAME_SCHEMA_ID = "show_name"
DEFAULT_COUNTRY_CODE = "random"
DEFAULT_TEXT_COLOR = "#fff"
DEFAULT_BG_COLOR = "#000"
COUNTRIES = {
    DEFAULT_COUNTRY_CODE: {
        "name": "Random",
        "flag": "",
    },
    "af": {
        "name": "Afghanistan",
        "flag": AF_FLAG.readall(),
    },
    "ax": {
        "name": "Åland Islands",
        "flag": AX_FLAG.readall(),
    },
    "al": {
        "name": "Albania",
        "flag": AL_FLAG.readall(),
    },
    "dz": {
        "name": "Algeria",
        "flag": DZ_FLAG.readall(),
    },
    "as": {
        "name": "American Samoa",
        "flag": AS_FLAG.readall(),
    },
    "ad": {
        "name": "Andorra",
        "flag": AD_FLAG.readall(),
    },
    "ao": {
        "name": "Angola",
        "flag": AO_FLAG.readall(),
    },
    "ai": {
        "name": "Anguilla",
        "flag": AI_FLAG.readall(),
    },
    "aq": {
        "name": "Antarctica",
        "flag": AQ_FLAG.readall(),
    },
    "ag": {
        "name": "Antigua and Barbuda",
        "flag": AG_FLAG.readall(),
    },
    "ar": {
        "name": "Argentina",
        "flag": AR_FLAG.readall(),
    },
    "am": {
        "name": "Armenia",
        "flag": AM_FLAG.readall(),
    },
    "aw": {
        "name": "Aruba",
        "flag": AW_FLAG.readall(),
    },
    "au": {
        "name": "Australia",
        "flag": AU_FLAG.readall(),
    },
    "at": {
        "name": "Austria",
        "flag": AT_FLAG.readall(),
    },
    "az": {
        "name": "Azerbaijan",
        "flag": AZ_FLAG.readall(),
    },
    "bs": {
        "name": "Bahamas",
        "flag": BS_FLAG.readall(),
    },
    "bh": {
        "name": "Bahrain",
        "flag": BH_FLAG.readall(),
    },
    "bd": {
        "name": "Bangladesh",
        "flag": BD_FLAG.readall(),
    },
    "bb": {
        "name": "Barbados",
        "flag": BB_FLAG.readall(),
    },
    "by": {
        "name": "Belarus",
        "flag": BY_FLAG.readall(),
    },
    "be": {
        "name": "Belgium",
        "flag": BE_FLAG.readall(),
    },
    "bz": {
        "name": "Belize",
        "flag": BZ_FLAG.readall(),
    },
    "bj": {
        "name": "Benin",
        "flag": BJ_FLAG.readall(),
    },
    "bm": {
        "name": "Bermuda",
        "flag": BM_FLAG.readall(),
    },
    "bt": {
        "name": "Bhutan",
        "flag": BT_FLAG.readall(),
    },
    "bo": {
        "name": "Bolivia (Plurinational State of)",
        "flag": BO_FLAG.readall(),
    },
    "bq": {
        "name": "Bonaire, Sint Eustatius and Saba",
        "flag": BQ_FLAG.readall(),
    },
    "ba": {
        "name": "Bosnia and Herzegovina",
        "flag": BA_FLAG.readall(),
    },
    "bw": {
        "name": "Botswana",
        "flag": BW_FLAG.readall(),
    },
    "bv": {
        "name": "Bouvet Island",
        "flag": BV_FLAG.readall(),
    },
    "br": {
        "name": "Brazil",
        "flag": BR_FLAG.readall(),
    },
    "io": {
        "name": "British Indian Ocean Territory",
        "flag": IO_FLAG.readall(),
    },
    "bn": {
        "name": "Brunei Darussalam",
        "flag": BN_FLAG.readall(),
    },
    "bg": {
        "name": "Bulgaria",
        "flag": BG_FLAG.readall(),
    },
    "bf": {
        "name": "Burkina Faso",
        "flag": BF_FLAG.readall(),
    },
    "bi": {
        "name": "Burundi",
        "flag": BI_FLAG.readall(),
    },
    "cv": {
        "name": "Cabo Verde",
        "flag": CV_FLAG.readall(),
    },
    "kh": {
        "name": "Cambodia",
        "flag": KH_FLAG.readall(),
    },
    "cm": {
        "name": "Cameroon",
        "flag": CM_FLAG.readall(),
    },
    "ca": {
        "name": "Canada",
        "flag": CA_FLAG.readall(),
    },
    "ky": {
        "name": "Cayman Islands",
        "flag": KY_FLAG.readall(),
    },
    "cf": {
        "name": "Central African Republic",
        "flag": CF_FLAG.readall(),
    },
    "td": {
        "name": "Chad",
        "flag": TD_FLAG.readall(),
    },
    "cl": {
        "name": "Chile",
        "flag": CL_FLAG.readall(),
    },
    "cn": {
        "name": "China",
        "flag": CN_FLAG.readall(),
    },
    "cx": {
        "name": "Christmas Island",
        "flag": CX_FLAG.readall(),
    },
    "cc": {
        "name": "Cocos (Keeling) Islands",
        "flag": CC_FLAG.readall(),
    },
    "co": {
        "name": "Colombia",
        "flag": CO_FLAG.readall(),
    },
    "km": {
        "name": "Comoros",
        "flag": KM_FLAG.readall(),
    },
    "cg": {
        "name": "Congo",
        "flag": CG_FLAG.readall(),
    },
    "cd": {
        "name": "Congo, Democratic Republic of the",
        "flag": CD_FLAG.readall(),
    },
    "ck": {
        "name": "Cook Islands",
        "flag": CK_FLAG.readall(),
    },
    "cr": {
        "name": "Costa Rica",
        "flag": CR_FLAG.readall(),
    },
    "ci": {
        "name": "Côte d'Ivoire",
        "flag": CI_FLAG.readall(),
    },
    "hr": {
        "name": "Croatia",
        "flag": HR_FLAG.readall(),
    },
    "cu": {
        "name": "Cuba",
        "flag": CU_FLAG.readall(),
    },
    "cw": {
        "name": "Curaçao",
        "flag": CW_FLAG.readall(),
    },
    "cy": {
        "name": "Cyprus",
        "flag": CY_FLAG.readall(),
    },
    "cz": {
        "name": "Czechia",
        "flag": CZ_FLAG.readall(),
    },
    "dk": {
        "name": "Denmark",
        "flag": DK_FLAG.readall(),
    },
    "dj": {
        "name": "Djibouti",
        "flag": DJ_FLAG.readall(),
    },
    "dm": {
        "name": "Dominica",
        "flag": DM_FLAG.readall(),
    },
    "do": {
        "name": "Dominican Republic",
        "flag": DO_FLAG.readall(),
    },
    "ec": {
        "name": "Ecuador",
        "flag": EC_FLAG.readall(),
    },
    "eg": {
        "name": "Egypt",
        "flag": EG_FLAG.readall(),
    },
    "sv": {
        "name": "El Salvador",
        "flag": SV_FLAG.readall(),
    },
    "gb-eng": {
        "name": "England",
        "flag": SV_FLAG.readall(),
    },
    "gq": {
        "name": "Equatorial Guinea",
        "flag": GQ_FLAG.readall(),
    },
    "er": {
        "name": "Eritrea",
        "flag": ER_FLAG.readall(),
    },
    "ee": {
        "name": "Estonia",
        "flag": EE_FLAG.readall(),
    },
    "sz": {
        "name": "Eswatini",
        "flag": SZ_FLAG.readall(),
    },
    "et": {
        "name": "Ethiopia",
        "flag": ET_FLAG.readall(),
    },
    "fk": {
        "name": "Falkland Islands (Malvinas)",
        "flag": FK_FLAG.readall(),
    },
    "fo": {
        "name": "Faroe Islands",
        "flag": FO_FLAG.readall(),
    },
    "fj": {
        "name": "Fiji",
        "flag": FJ_FLAG.readall(),
    },
    "fi": {
        "name": "Finland",
        "flag": FI_FLAG.readall(),
    },
    "fr": {
        "name": "France",
        "flag": FR_FLAG.readall(),
    },
    "gf": {
        "name": "French Guiana",
        "flag": GF_FLAG.readall(),
    },
    "pf": {
        "name": "French Polynesia",
        "flag": PF_FLAG.readall(),
    },
    "tf": {
        "name": "French Southern Territories",
        "flag": TF_FLAG.readall(),
    },
    "ga": {
        "name": "Gabon",
        "flag": GA_FLAG.readall(),
    },
    "gm": {
        "name": "Gambia",
        "flag": GM_FLAG.readall(),
    },
    "ge": {
        "name": "Georgia",
        "flag": GE_FLAG.readall(),
    },
    "de": {
        "name": "Germany",
        "flag": DE_FLAG.readall(),
    },
    "gh": {
        "name": "Ghana",
        "flag": GH_FLAG.readall(),
    },
    "gi": {
        "name": "Gibraltar",
        "flag": GI_FLAG.readall(),
    },
    "gr": {
        "name": "Greece",
        "flag": GR_FLAG.readall(),
    },
    "gl": {
        "name": "Greenland",
        "flag": GL_FLAG.readall(),
    },
    "gd": {
        "name": "Grenada",
        "flag": GD_FLAG.readall(),
    },
    "gp": {
        "name": "Guadeloupe",
        "flag": GP_FLAG.readall(),
    },
    "gu": {
        "name": "Guam",
        "flag": GU_FLAG.readall(),
    },
    "gt": {
        "name": "Guatemala",
        "flag": GT_FLAG.readall(),
    },
    "gg": {
        "name": "Guernsey",
        "flag": GG_FLAG.readall(),
    },
    "gn": {
        "name": "Guinea",
        "flag": GN_FLAG.readall(),
    },
    "gw": {
        "name": "Guinea-Bissau",
        "flag": GW_FLAG.readall(),
    },
    "gy": {
        "name": "Guyana",
        "flag": GY_FLAG.readall(),
    },
    "ht": {
        "name": "Haiti",
        "flag": HT_FLAG.readall(),
    },
    "hm": {
        "name": "Heard Island and McDonald Islands",
        "flag": HM_FLAG.readall(),
    },
    "va": {
        "name": "Holy See",
        "flag": VA_FLAG.readall(),
    },
    "hn": {
        "name": "Honduras",
        "flag": HN_FLAG.readall(),
    },
    "hk": {
        "name": "Hong Kong",
        "flag": HK_FLAG.readall(),
    },
    "hu": {
        "name": "Hungary",
        "flag": HU_FLAG.readall(),
    },
    "is": {
        "name": "Iceland",
        "flag": IS_FLAG.readall(),
    },
    "in": {
        "name": "India",
        "flag": IN_FLAG.readall(),
    },
    "id": {
        "name": "Indonesia",
        "flag": ID_FLAG.readall(),
    },
    "ir": {
        "name": "Iran (Islamic Republic of)",
        "flag": IR_FLAG.readall(),
    },
    "iq": {
        "name": "Iraq",
        "flag": IQ_FLAG.readall(),
    },
    "ie": {
        "name": "Ireland",
        "flag": IE_FLAG.readall(),
    },
    "im": {
        "name": "Isle of Man",
        "flag": IM_FLAG.readall(),
    },
    "il": {
        "name": "Israel",
        "flag": IL_FLAG.readall(),
    },
    "it": {
        "name": "Italy",
        "flag": IT_FLAG.readall(),
    },
    "jm": {
        "name": "Jamaica",
        "flag": JM_FLAG.readall(),
    },
    "jp": {
        "name": "Japan",
        "flag": JP_FLAG.readall(),
    },
    "je": {
        "name": "Jersey",
        "flag": JE_FLAG.readall(),
    },
    "jo": {
        "name": "Jordan",
        "flag": JO_FLAG.readall(),
    },
    "kz": {
        "name": "Kazakhstan",
        "flag": KZ_FLAG.readall(),
    },
    "ke": {
        "name": "Kenya",
        "flag": KE_FLAG.readall(),
    },
    "ki": {
        "name": "Kiribati",
        "flag": KI_FLAG.readall(),
    },
    "kp": {
        "name": "Korea (Democratic People's Republic of)",
        "flag": KP_FLAG.readall(),
    },
    "kr": {
        "name": "Korea, Republic of",
        "flag": KR_FLAG.readall(),
    },
    "xk": {
        "name": "Kosovo",
        "flag": XK_FLAG.readall(),
    },
    "kw": {
        "name": "Kuwait",
        "flag": KW_FLAG.readall(),
    },
    "kg": {
        "name": "Kyrgyzstan",
        "flag": KG_FLAG.readall(),
    },
    "la": {
        "name": "Lao People's Democratic Republic",
        "flag": LA_FLAG.readall(),
    },
    "lv": {
        "name": "Latvia",
        "flag": LV_FLAG.readall(),
    },
    "lb": {
        "name": "Lebanon",
        "flag": LB_FLAG.readall(),
    },
    "ls": {
        "name": "Lesotho",
        "flag": LS_FLAG.readall(),
    },
    "lr": {
        "name": "Liberia",
        "flag": LR_FLAG.readall(),
    },
    "ly": {
        "name": "Libya",
        "flag": LY_FLAG.readall(),
    },
    "li": {
        "name": "Liechtenstein",
        "flag": LI_FLAG.readall(),
    },
    "lt": {
        "name": "Lithuania",
        "flag": LT_FLAG.readall(),
    },
    "lu": {
        "name": "Luxembourg",
        "flag": LU_FLAG.readall(),
    },
    "mo": {
        "name": "Macao",
        "flag": MO_FLAG.readall(),
    },
    "mg": {
        "name": "Madagascar",
        "flag": MG_FLAG.readall(),
    },
    "mw": {
        "name": "Malawi",
        "flag": MW_FLAG.readall(),
    },
    "my": {
        "name": "Malaysia",
        "flag": MY_FLAG.readall(),
    },
    "mv": {
        "name": "Maldives",
        "flag": MV_FLAG.readall(),
    },
    "ml": {
        "name": "Mali",
        "flag": ML_FLAG.readall(),
    },
    "mt": {
        "name": "Malta",
        "flag": MT_FLAG.readall(),
    },
    "mh": {
        "name": "Marshall Islands",
        "flag": MH_FLAG.readall(),
    },
    "mq": {
        "name": "Martinique",
        "flag": MQ_FLAG.readall(),
    },
    "mr": {
        "name": "Mauritania",
        "flag": MR_FLAG.readall(),
    },
    "mu": {
        "name": "Mauritius",
        "flag": MU_FLAG.readall(),
    },
    "yt": {
        "name": "Mayotte",
        "flag": YT_FLAG.readall(),
    },
    "mx": {
        "name": "Mexico",
        "flag": MX_FLAG.readall(),
    },
    "fm": {
        "name": "Micronesia (Federated States of)",
        "flag": FM_FLAG.readall(),
    },
    "md": {
        "name": "Moldova, Republic of",
        "flag": MD_FLAG.readall(),
    },
    "mc": {
        "name": "Monaco",
        "flag": MC_FLAG.readall(),
    },
    "mn": {
        "name": "Mongolia",
        "flag": MN_FLAG.readall(),
    },
    "me": {
        "name": "Montenegro",
        "flag": ME_FLAG.readall(),
    },
    "ms": {
        "name": "Montserrat",
        "flag": MS_FLAG.readall(),
    },
    "ma": {
        "name": "Morocco",
        "flag": MA_FLAG.readall(),
    },
    "mz": {
        "name": "Mozambique",
        "flag": MZ_FLAG.readall(),
    },
    "mm": {
        "name": "Myanmar",
        "flag": MM_FLAG.readall(),
    },
    "na": {
        "name": "Namibia",
        "flag": NA_FLAG.readall(),
    },
    "nr": {
        "name": "Nauru",
        "flag": NR_FLAG.readall(),
    },
    "np": {
        "name": "Nepal",
        "flag": NP_FLAG.readall(),
    },
    "nl": {
        "name": "Netherlands",
        "flag": NL_FLAG.readall(),
    },
    "nc": {
        "name": "New Caledonia",
        "flag": NC_FLAG.readall(),
    },
    "nz": {
        "name": "New Zealand",
        "flag": NZ_FLAG.readall(),
    },
    "ni": {
        "name": "Nicaragua",
        "flag": NI_FLAG.readall(),
    },
    "ne": {
        "name": "Niger",
        "flag": NE_FLAG.readall(),
    },
    "ng": {
        "name": "Nigeria",
        "flag": NG_FLAG.readall(),
    },
    "nu": {
        "name": "Niue",
        "flag": NU_FLAG.readall(),
    },
    "nf": {
        "name": "Norfolk Island",
        "flag": NF_FLAG.readall(),
    },
    "mk": {
        "name": "North Macedonia",
        "flag": MK_FLAG.readall(),
    },
    "gb-nir": {
        "name": "Northern Ireland",
        "flag": MK_FLAG.readall(),
    },
    "mp": {
        "name": "Northern Mariana Islands",
        "flag": MP_FLAG.readall(),
    },
    "no": {
        "name": "Norway",
        "flag": NO_FLAG.readall(),
    },
    "om": {
        "name": "Oman",
        "flag": OM_FLAG.readall(),
    },
    "pk": {
        "name": "Pakistan",
        "flag": PK_FLAG.readall(),
    },
    "pw": {
        "name": "Palau",
        "flag": PW_FLAG.readall(),
    },
    "ps": {
        "name": "Palestine, State of",
        "flag": PS_FLAG.readall(),
    },
    "pa": {
        "name": "Panama",
        "flag": PA_FLAG.readall(),
    },
    "pg": {
        "name": "Papua New Guinea",
        "flag": PG_FLAG.readall(),
    },
    "py": {
        "name": "Paraguay",
        "flag": PY_FLAG.readall(),
    },
    "pe": {
        "name": "Peru",
        "flag": PE_FLAG.readall(),
    },
    "ph": {
        "name": "Philippines",
        "flag": PH_FLAG.readall(),
    },
    "pn": {
        "name": "Pitcairn",
        "flag": PN_FLAG.readall(),
    },
    "pl": {
        "name": "Poland",
        "flag": PL_FLAG.readall(),
    },
    "pt": {
        "name": "Portugal",
        "flag": PT_FLAG.readall(),
    },
    "pr": {
        "name": "Puerto Rico",
        "flag": PR_FLAG.readall(),
    },
    "qa": {
        "name": "Qatar",
        "flag": QA_FLAG.readall(),
    },
    "re": {
        "name": "Réunion",
        "flag": RE_FLAG.readall(),
    },
    "ro": {
        "name": "Romania",
        "flag": RO_FLAG.readall(),
    },
    "ru": {
        "name": "Russian Federation",
        "flag": RU_FLAG.readall(),
    },
    "rw": {
        "name": "Rwanda",
        "flag": RW_FLAG.readall(),
    },
    "bl": {
        "name": "Saint Barthélemy",
        "flag": BL_FLAG.readall(),
    },
    "sh": {
        "name": "Saint Helena, Ascension and Tristan da Cunha",
        "flag": SH_FLAG.readall(),
    },
    "kn": {
        "name": "Saint Kitts and Nevis",
        "flag": KN_FLAG.readall(),
    },
    "lc": {
        "name": "Saint Lucia",
        "flag": LC_FLAG.readall(),
    },
    "mf": {
        "name": "Saint Martin (French part)",
        "flag": MF_FLAG.readall(),
    },
    "pm": {
        "name": "Saint Pierre and Miquelon",
        "flag": PM_FLAG.readall(),
    },
    "vc": {
        "name": "Saint Vincent and the Grenadines",
        "flag": VC_FLAG.readall(),
    },
    "ws": {
        "name": "Samoa",
        "flag": WS_FLAG.readall(),
    },
    "sm": {
        "name": "San Marino",
        "flag": SM_FLAG.readall(),
    },
    "st": {
        "name": "Sao Tome and Principe",
        "flag": ST_FLAG.readall(),
    },
    "sa": {
        "name": "Saudi Arabia",
        "flag": SA_FLAG.readall(),
    },
    "gb-sct": {
        "name": "Scotland",
        "flag": SA_FLAG.readall(),
    },
    "sn": {
        "name": "Senegal",
        "flag": SN_FLAG.readall(),
    },
    "rs": {
        "name": "Serbia",
        "flag": RS_FLAG.readall(),
    },
    "sc": {
        "name": "Seychelles",
        "flag": SC_FLAG.readall(),
    },
    "sl": {
        "name": "Sierra Leone",
        "flag": SL_FLAG.readall(),
    },
    "sg": {
        "name": "Singapore",
        "flag": SG_FLAG.readall(),
    },
    "sx": {
        "name": "Sint Maarten (Dutch part)",
        "flag": SX_FLAG.readall(),
    },
    "sk": {
        "name": "Slovakia",
        "flag": SK_FLAG.readall(),
    },
    "si": {
        "name": "Slovenia",
        "flag": SI_FLAG.readall(),
    },
    "sb": {
        "name": "Solomon Islands",
        "flag": SB_FLAG.readall(),
    },
    "so": {
        "name": "Somalia",
        "flag": SO_FLAG.readall(),
    },
    "za": {
        "name": "South Africa",
        "flag": ZA_FLAG.readall(),
    },
    "gs": {
        "name": "South Georgia and the South Sandwich Islands",
        "flag": GS_FLAG.readall(),
    },
    "ss": {
        "name": "South Sudan",
        "flag": SS_FLAG.readall(),
    },
    "es": {
        "name": "Spain",
        "flag": ES_FLAG.readall(),
    },
    "lk": {
        "name": "Sri Lanka",
        "flag": LK_FLAG.readall(),
    },
    "sd": {
        "name": "Sudan",
        "flag": SD_FLAG.readall(),
    },
    "sr": {
        "name": "Suriname",
        "flag": SR_FLAG.readall(),
    },
    "sj": {
        "name": "Svalbard and Jan Mayen",
        "flag": SJ_FLAG.readall(),
    },
    "se": {
        "name": "Sweden",
        "flag": SE_FLAG.readall(),
    },
    "ch": {
        "name": "Switzerland",
        "flag": CH_FLAG.readall(),
    },
    "sy": {
        "name": "Syrian Arab Republic",
        "flag": SY_FLAG.readall(),
    },
    "tw": {
        "name": "Taiwan, Province of China",
        "flag": TW_FLAG.readall(),
    },
    "tj": {
        "name": "Tajikistan",
        "flag": TJ_FLAG.readall(),
    },
    "tz": {
        "name": "Tanzania, United Republic of",
        "flag": TZ_FLAG.readall(),
    },
    "th": {
        "name": "Thailand",
        "flag": TH_FLAG.readall(),
    },
    "tl": {
        "name": "Timor-Leste",
        "flag": TL_FLAG.readall(),
    },
    "tg": {
        "name": "Togo",
        "flag": TG_FLAG.readall(),
    },
    "tk": {
        "name": "Tokelau",
        "flag": TK_FLAG.readall(),
    },
    "to": {
        "name": "Tonga",
        "flag": TO_FLAG.readall(),
    },
    "tt": {
        "name": "Trinidad and Tobago",
        "flag": TT_FLAG.readall(),
    },
    "tn": {
        "name": "Tunisia",
        "flag": TN_FLAG.readall(),
    },
    "tr": {
        "name": "Turkey",
        "flag": TR_FLAG.readall(),
    },
    "tm": {
        "name": "Turkmenistan",
        "flag": TM_FLAG.readall(),
    },
    "tc": {
        "name": "Turks and Caicos Islands",
        "flag": TC_FLAG.readall(),
    },
    "tv": {
        "name": "Tuvalu",
        "flag": TV_FLAG.readall(),
    },
    "ug": {
        "name": "Uganda",
        "flag": UG_FLAG.readall(),
    },
    "ua": {
        "name": "Ukraine",
        "flag": UA_FLAG.readall(),
    },
    "ae": {
        "name": "United Arab Emirates",
        "flag": AE_FLAG.readall(),
    },
    "gb": {
        "name": "United Kingdom of Great Britain and Northern Ireland",
        "flag": GB_FLAG.readall(),
    },
    "um": {
        "name": "United States Minor Outlying Islands",
        "flag": UM_FLAG.readall(),
    },
    "us": {
        "name": "United States of America",
        "flag": US_FLAG.readall(),
    },
    "uy": {
        "name": "Uruguay",
        "flag": UY_FLAG.readall(),
    },
    "uz": {
        "name": "Uzbekistan",
        "flag": UZ_FLAG.readall(),
    },
    "vu": {
        "name": "Vanuatu",
        "flag": VU_FLAG.readall(),
    },
    "ve": {
        "name": "Venezuela (Bolivarian Republic of)",
        "flag": VE_FLAG.readall(),
    },
    "vn": {
        "name": "Viet Nam",
        "flag": VN_FLAG.readall(),
    },
    "vg": {
        "name": "Virgin Islands (British)",
        "flag": VG_FLAG.readall(),
    },
    "vi": {
        "name": "Virgin Islands (U.S.)",
        "flag": VI_FLAG.readall(),
    },
    "gb-wls": {
        "name": "Wales",
        "flag": VI_FLAG.readall(),
    },
    "wf": {
        "name": "Wallis and Futuna",
        "flag": WF_FLAG.readall(),
    },
    "eh": {
        "name": "Western Sahara",
        "flag": EH_FLAG.readall(),
    },
    "ye": {
        "name": "Yemen",
        "flag": YE_FLAG.readall(),
    },
    "zm": {
        "name": "Zambia",
        "flag": ZM_FLAG.readall(),
    },
    "zw": {
        "name": "Zimbabwe",
        "flag": ZW_FLAG.readall(),
    },
}

def main(config):
    country_code = config.get(COUNTRY_CODE_SCHEMA_ID, DEFAULT_COUNTRY_CODE)
    text_color = config.get(TEXT_COLOR_SCHEMA_ID, DEFAULT_TEXT_COLOR)
    bg_color = config.get(BG_COLOR_SCHEMA_ID, DEFAULT_BG_COLOR)
    show_name = config.bool(SHOW_NAME_SCHEMA_ID, False)
    country = get_random_country() if country_code == "random" else get_country(country_code)

    if show_name:
        return render_with_name(country, bg_color, text_color)

    return render_without_name(country, bg_color)

# renders both the flag and the country name
def render_with_name(country, bg_color, text_color):
    flag = country["flag"]
    name = country["name"]

    # render the flag with a scaled down image
    # original flag image is 40 x 30
    rendered_image = render.Image(
        src = flag,
        width = 32,
        height = 24,
    )

    # render the country name text
    name_text = render.Text(
        content = name,
        color = text_color,
        font = "tom-thumb",
    )

    # if the country name won't fit by itself, put it in a marquee
    rendered_text = name_text if len(name) <= 16 else render.Marquee(
        width = 64,
        child = name_text,
    )

    return render.Root(
        render.Box(
            child = render.Column(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = [
                    rendered_image,
                    rendered_text,
                ],
            ),
            color = bg_color,
        ),
        delay = 100,
    )

# renders only a country flag
def render_without_name(country, bg_color):
    flag = country["flag"]

    return render.Root(
        render.Box(
            child = render.Image(
                src = flag,
            ),
            color = bg_color,
        ),
    )

# retrieves a random country the list of countries
def get_random_country():
    return COUNTRIES.values()[random.number(1, len(COUNTRIES) - 1)]

# retrieves a specific country the list of countries
def get_country(country_code):
    return COUNTRIES[country_code]

# generates schema options for each country code
def get_country_schema_options():
    options = []
    for code in COUNTRIES:
        options.append(
            schema.Option(
                display = COUNTRIES[code]["name"],
                value = code,
            ),
        )
    return options

# returns the schema text color options
def get_text_color_schema_options():
    return [
        schema.Option(
            display = "White",
            value = DEFAULT_TEXT_COLOR,
        ),
        schema.Option(
            display = "Light Gray",
            value = "#ccc",
        ),
        schema.Option(
            display = "Medium Gray",
            value = "#999",
        ),
        schema.Option(
            display = "Dark Gray",
            value = "#666",
        ),
    ]

# returns the schema background color options
def get_bg_color_schema_options():
    return [
        schema.Option(
            display = "Black",
            value = DEFAULT_BG_COLOR,
        ),
        schema.Option(
            display = "Dark Gray",
            value = "#111",
        ),
        schema.Option(
            display = "Medium Gray",
            value = "#222",
        ),
        schema.Option(
            display = "Light Gray",
            value = "#333",
        ),
    ]

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = COUNTRY_CODE_SCHEMA_ID,
                name = "Flag Country",
                desc = "The country of the flag to be displayed.",
                icon = "flag",
                default = DEFAULT_COUNTRY_CODE,
                options = get_country_schema_options(),
            ),
            schema.Toggle(
                id = SHOW_NAME_SCHEMA_ID,
                name = "Show Country Name",
                desc = "Display the country name along with its flag.",
                icon = "font",
                default = False,
            ),
            schema.Dropdown(
                id = TEXT_COLOR_SCHEMA_ID,
                name = "Text Color",
                desc = "The color of the country name text.",
                icon = "paintbrush",
                default = DEFAULT_TEXT_COLOR,
                options = get_text_color_schema_options(),
            ),
            schema.Dropdown(
                id = BG_COLOR_SCHEMA_ID,
                name = "Background Color",
                desc = "The color to display behind the flag.",
                icon = "fillDrip",
                default = DEFAULT_BG_COLOR,
                options = get_bg_color_schema_options(),
            ),
        ],
    )
