"""
Applet: States Visited
Summary: Show states you've visited
Description: Select the states you have been to and show them off on your Tidbyt!
Author: sloanesturz
"""

load("encoding/base64.star", "base64")
load("render.star", "render")
load("schema.star", "schema")
load("images/img_02c77957.png", IMG_02c77957_ASSET = "file")
load("images/img_0b707932.png", IMG_0b707932_ASSET = "file")
load("images/img_0dbdb44d.png", IMG_0dbdb44d_ASSET = "file")
load("images/img_12cd72c7.png", IMG_12cd72c7_ASSET = "file")
load("images/img_1a163134.png", IMG_1a163134_ASSET = "file")
load("images/img_1dd42802.png", IMG_1dd42802_ASSET = "file")
load("images/img_1f2db57d.png", IMG_1f2db57d_ASSET = "file")
load("images/img_250ab2c0.png", IMG_250ab2c0_ASSET = "file")
load("images/img_253d2b29.png", IMG_253d2b29_ASSET = "file")
load("images/img_29759483.png", IMG_29759483_ASSET = "file")
load("images/img_29be94a1.png", IMG_29be94a1_ASSET = "file")
load("images/img_2b8675b0.png", IMG_2b8675b0_ASSET = "file")
load("images/img_3059b1a9.png", IMG_3059b1a9_ASSET = "file")
load("images/img_328461c8.png", IMG_328461c8_ASSET = "file")
load("images/img_330fe414.png", IMG_330fe414_ASSET = "file")
load("images/img_38620887.png", IMG_38620887_ASSET = "file")
load("images/img_41f6c9da.png", IMG_41f6c9da_ASSET = "file")
load("images/img_42c5fcf8.png", IMG_42c5fcf8_ASSET = "file")
load("images/img_4641518d.png", IMG_4641518d_ASSET = "file")
load("images/img_4aba1569.png", IMG_4aba1569_ASSET = "file")
load("images/img_4df45c58.png", IMG_4df45c58_ASSET = "file")
load("images/img_53c9f9c5.png", IMG_53c9f9c5_ASSET = "file")
load("images/img_55f7a9dc.png", IMG_55f7a9dc_ASSET = "file")
load("images/img_70c9c804.png", IMG_70c9c804_ASSET = "file")
load("images/img_70e5d3cc.png", IMG_70e5d3cc_ASSET = "file")
load("images/img_77c21843.png", IMG_77c21843_ASSET = "file")
load("images/img_7e5f0fe2.png", IMG_7e5f0fe2_ASSET = "file")
load("images/img_82d4657b.png", IMG_82d4657b_ASSET = "file")
load("images/img_85319811.png", IMG_85319811_ASSET = "file")
load("images/img_8cb9146e.png", IMG_8cb9146e_ASSET = "file")
load("images/img_913a0a03.png", IMG_913a0a03_ASSET = "file")
load("images/img_91d682a5.png", IMG_91d682a5_ASSET = "file")
load("images/img_9e0cc860.png", IMG_9e0cc860_ASSET = "file")
load("images/img_a0954fe5.png", IMG_a0954fe5_ASSET = "file")
load("images/img_a1a7848d.png", IMG_a1a7848d_ASSET = "file")
load("images/img_a1cc444c.png", IMG_a1cc444c_ASSET = "file")
load("images/img_a2374ab4.png", IMG_a2374ab4_ASSET = "file")
load("images/img_a2e88e85.png", IMG_a2e88e85_ASSET = "file")
load("images/img_b54112c5.png", IMG_b54112c5_ASSET = "file")
load("images/img_bd8e36bc.png", IMG_bd8e36bc_ASSET = "file")
load("images/img_c07bc2f0.png", IMG_c07bc2f0_ASSET = "file")
load("images/img_d1c68ff8.png", IMG_d1c68ff8_ASSET = "file")
load("images/img_d6421684.png", IMG_d6421684_ASSET = "file")
load("images/img_d76c634a.png", IMG_d76c634a_ASSET = "file")
load("images/img_e3b51f17.png", IMG_e3b51f17_ASSET = "file")
load("images/img_ed2cb528.png", IMG_ed2cb528_ASSET = "file")
load("images/img_f4a83903.png", IMG_f4a83903_ASSET = "file")
load("images/img_f6a8827b.png", IMG_f6a8827b_ASSET = "file")

STATES = {
    "AL": IMG_0b707932_ASSET.readall(),
    "AR": IMG_a1cc444c_ASSET.readall(),
    "AZ": IMG_330fe414_ASSET.readall(),
    "CA": IMG_f4a83903_ASSET.readall(),
    "CO": IMG_55f7a9dc_ASSET.readall(),
    "CT": IMG_53c9f9c5_ASSET.readall(),
    "DE": IMG_d76c634a_ASSET.readall(),
    "FL": IMG_253d2b29_ASSET.readall(),
    "GA": IMG_ed2cb528_ASSET.readall(),
    "IA": IMG_a1a7848d_ASSET.readall(),
    "ID": IMG_d1c68ff8_ASSET.readall(),
    "IL": IMG_2b8675b0_ASSET.readall(),
    "IN": IMG_02c77957_ASSET.readall(),
    "KS": IMG_70c9c804_ASSET.readall(),
    "KY": IMG_328461c8_ASSET.readall(),
    "LA": IMG_250ab2c0_ASSET.readall(),
    "MA": IMG_70e5d3cc_ASSET.readall(),
    "MD": IMG_8cb9146e_ASSET.readall(),
    "ME": IMG_29759483_ASSET.readall(),
    "MI": IMG_d6421684_ASSET.readall(),
    "MN": IMG_a0954fe5_ASSET.readall(),
    "MO": IMG_7e5f0fe2_ASSET.readall(),
    "MS": IMG_3059b1a9_ASSET.readall(),
    "MT": IMG_1f2db57d_ASSET.readall(),
    "NC": IMG_9e0cc860_ASSET.readall(),
    "ND": IMG_29be94a1_ASSET.readall(),
    "NE": IMG_f6a8827b_ASSET.readall(),
    "NH": IMG_c07bc2f0_ASSET.readall(),
    "NJ": IMG_913a0a03_ASSET.readall(),
    "NM": IMG_a2374ab4_ASSET.readall(),
    "NV": IMG_1a163134_ASSET.readall(),
    "NY": IMG_42c5fcf8_ASSET.readall(),
    "OH": IMG_0dbdb44d_ASSET.readall(),
    "OK": IMG_4df45c58_ASSET.readall(),
    "OR": IMG_91d682a5_ASSET.readall(),
    "PA": IMG_b54112c5_ASSET.readall(),
    "RI": IMG_4aba1569_ASSET.readall(),
    "SC": IMG_1dd42802_ASSET.readall(),
    "SD": IMG_82d4657b_ASSET.readall(),
    "TN": IMG_85319811_ASSET.readall(),
    "TX": IMG_41f6c9da_ASSET.readall(),
    "UT": IMG_4641518d_ASSET.readall(),
    "VA": IMG_77c21843_ASSET.readall(),
    "VT": IMG_12cd72c7_ASSET.readall(),
    "WA": IMG_bd8e36bc_ASSET.readall(),
    "WI": IMG_a2e88e85_ASSET.readall(),
    "WV": IMG_e3b51f17_ASSET.readall(),
    "WY": IMG_38620887_ASSET.readall(),
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
                render.Image(base64.decode(STATES[state]), 64)
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
