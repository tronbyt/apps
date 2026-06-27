"""
Applet: States Visited
Summary: Show states you've visited
Description: Select the states you have been to and show them off on your Tidbyt!
Author: sloanesturz
"""

load("images/map_al.png", MAP_AL_ASSET = "file")
load("images/map_ar.png", MAP_AR_ASSET = "file")
load("images/map_az.png", MAP_AZ_ASSET = "file")
load("images/map_ca.png", MAP_CA_ASSET = "file")
load("images/map_co.png", MAP_CO_ASSET = "file")
load("images/map_ct.png", MAP_CT_ASSET = "file")
load("images/map_de.png", MAP_DE_ASSET = "file")
load("images/map_fl.png", MAP_FL_ASSET = "file")
load("images/map_ga.png", MAP_GA_ASSET = "file")
load("images/map_ia.png", MAP_IA_ASSET = "file")
load("images/map_id.png", MAP_ID_ASSET = "file")
load("images/map_il.png", MAP_IL_ASSET = "file")
load("images/map_in.png", MAP_IN_ASSET = "file")
load("images/map_ks.png", MAP_KS_ASSET = "file")
load("images/map_ky.png", MAP_KY_ASSET = "file")
load("images/map_la.png", MAP_LA_ASSET = "file")
load("images/map_ma.png", MAP_MA_ASSET = "file")
load("images/map_md.png", MAP_MD_ASSET = "file")
load("images/map_me.png", MAP_ME_ASSET = "file")
load("images/map_mi.png", MAP_MI_ASSET = "file")
load("images/map_mn.png", MAP_MN_ASSET = "file")
load("images/map_mo.png", MAP_MO_ASSET = "file")
load("images/map_ms.png", MAP_MS_ASSET = "file")
load("images/map_mt.png", MAP_MT_ASSET = "file")
load("images/map_nc.png", MAP_NC_ASSET = "file")
load("images/map_nd.png", MAP_ND_ASSET = "file")
load("images/map_ne.png", MAP_NE_ASSET = "file")
load("images/map_nh.png", MAP_NH_ASSET = "file")
load("images/map_nj.png", MAP_NJ_ASSET = "file")
load("images/map_nm.png", MAP_NM_ASSET = "file")
load("images/map_nv.png", MAP_NV_ASSET = "file")
load("images/map_ny.png", MAP_NY_ASSET = "file")
load("images/map_oh.png", MAP_OH_ASSET = "file")
load("images/map_ok.png", MAP_OK_ASSET = "file")
load("images/map_or.png", MAP_OR_ASSET = "file")
load("images/map_pa.png", MAP_PA_ASSET = "file")
load("images/map_ri.png", MAP_RI_ASSET = "file")
load("images/map_sc.png", MAP_SC_ASSET = "file")
load("images/map_sd.png", MAP_SD_ASSET = "file")
load("images/map_tn.png", MAP_TN_ASSET = "file")
load("images/map_tx.png", MAP_TX_ASSET = "file")
load("images/map_ut.png", MAP_UT_ASSET = "file")
load("images/map_va.png", MAP_VA_ASSET = "file")
load("images/map_vt.png", MAP_VT_ASSET = "file")
load("images/map_wa.png", MAP_WA_ASSET = "file")
load("images/map_wi.png", MAP_WI_ASSET = "file")
load("images/map_wv.png", MAP_WV_ASSET = "file")
load("images/map_wy.png", MAP_WY_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")

STATES = {
    "AL": MAP_AL_ASSET.readall(),
    "AR": MAP_AR_ASSET.readall(),
    "AZ": MAP_AZ_ASSET.readall(),
    "CA": MAP_CA_ASSET.readall(),
    "CO": MAP_CO_ASSET.readall(),
    "CT": MAP_CT_ASSET.readall(),
    "DE": MAP_DE_ASSET.readall(),
    "FL": MAP_FL_ASSET.readall(),
    "GA": MAP_GA_ASSET.readall(),
    "IA": MAP_IA_ASSET.readall(),
    "ID": MAP_ID_ASSET.readall(),
    "IL": MAP_IL_ASSET.readall(),
    "IN": MAP_IN_ASSET.readall(),
    "KS": MAP_KS_ASSET.readall(),
    "KY": MAP_KY_ASSET.readall(),
    "LA": MAP_LA_ASSET.readall(),
    "MA": MAP_MA_ASSET.readall(),
    "MD": MAP_MD_ASSET.readall(),
    "ME": MAP_ME_ASSET.readall(),
    "MI": MAP_MI_ASSET.readall(),
    "MN": MAP_MN_ASSET.readall(),
    "MO": MAP_MO_ASSET.readall(),
    "MS": MAP_MS_ASSET.readall(),
    "MT": MAP_MT_ASSET.readall(),
    "NC": MAP_NC_ASSET.readall(),
    "ND": MAP_ND_ASSET.readall(),
    "NE": MAP_NE_ASSET.readall(),
    "NH": MAP_NH_ASSET.readall(),
    "NJ": MAP_NJ_ASSET.readall(),
    "NM": MAP_NM_ASSET.readall(),
    "NV": MAP_NV_ASSET.readall(),
    "NY": MAP_NY_ASSET.readall(),
    "OH": MAP_OH_ASSET.readall(),
    "OK": MAP_OK_ASSET.readall(),
    "OR": MAP_OR_ASSET.readall(),
    "PA": MAP_PA_ASSET.readall(),
    "RI": MAP_RI_ASSET.readall(),
    "SC": MAP_SC_ASSET.readall(),
    "SD": MAP_SD_ASSET.readall(),
    "TN": MAP_TN_ASSET.readall(),
    "TX": MAP_TX_ASSET.readall(),
    "UT": MAP_UT_ASSET.readall(),
    "VA": MAP_VA_ASSET.readall(),
    "VT": MAP_VT_ASSET.readall(),
    "WA": MAP_WA_ASSET.readall(),
    "WI": MAP_WI_ASSET.readall(),
    "WV": MAP_WV_ASSET.readall(),
    "WY": MAP_WY_ASSET.readall(),
}

STATE_NAMES = {
    "AL": "Alabama",
    "AK": "Alaska",
    "AZ": "Arizona",
    "AR": "Arkansas",
    "CA": "California",
    "CO": "Colorado",
    "CT": "Connecticut",
    "DE": "Delaware",
    "FL": "Florida",
    "GA": "Georgia",
    "HI": "Hawaii",
    "ID": "Idaho",
    "IL": "Illinois",
    "IN": "Indiana",
    "IA": "Iowa",
    "KS": "Kansas",
    "KY": "Kentucky",
    "LA": "Louisiana",
    "ME": "Maine",
    "MD": "Maryland",
    "MA": "Massachusetts",
    "MI": "Michigan",
    "MN": "Minnesota",
    "MS": "Mississippi",
    "MO": "Missouri",
    "MT": "Montana",
    "NE": "Nebraska",
    "NV": "Nevada",
    "NH": "New Hampshire",
    "NJ": "New Jersey",
    "NM": "New Mexico",
    "NY": "New York",
    "NC": "North Carolina",
    "ND": "North Dakota",
    "OH": "Ohio",
    "OK": "Oklahoma",
    "OR": "Oregon",
    "PA": "Pennsylvania",
    "RI": "Rhode Island",
    "SC": "South Carolina",
    "SD": "South Dakota",
    "TN": "Tennessee",
    "TX": "Texas",
    "UT": "Utah",
    "VT": "Vermont",
    "VA": "Virginia",
    "WA": "Washington",
    "WV": "West Virginia",
    "WI": "Wisconsin",
    "WY": "Wyoming",
}

def main(config):
    return render.Root(
        render.Stack(
            [
                render.Image(STATES[state], 64)
                for state in STATES
                if config.get(state) and config.get(state) != "false"
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Toggle(id = state, name = state, desc = STATE_NAMES[state], icon = "landmarkFlag")
            for state in STATES
        ],
    )
