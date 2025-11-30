"""
Applet: Military Ranks
Summary: Display military ranks
Description: Displays military ranks.
Author: Robert Ison
"""

load("encoding/base64.star", "base64")  #to encode/decode json data going to and from cache
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("images/img_02c25812.png", IMG_02c25812_ASSET = "file")
load("images/img_07929664.png", IMG_07929664_ASSET = "file")
load("images/img_07d6ce0e.png", IMG_07d6ce0e_ASSET = "file")
load("images/img_08fac660.png", IMG_08fac660_ASSET = "file")
load("images/img_161b696f.png", IMG_161b696f_ASSET = "file")
load("images/img_1631440a.png", IMG_1631440a_ASSET = "file")
load("images/img_16657da3.png", IMG_16657da3_ASSET = "file")
load("images/img_184ea5e6.png", IMG_184ea5e6_ASSET = "file")
load("images/img_1d460cfb.png", IMG_1d460cfb_ASSET = "file")
load("images/img_1d61f874.png", IMG_1d61f874_ASSET = "file")
load("images/img_1d70d2d6.png", IMG_1d70d2d6_ASSET = "file")
load("images/img_1ebc1a1a.png", IMG_1ebc1a1a_ASSET = "file")
load("images/img_28b6aaac.png", IMG_28b6aaac_ASSET = "file")
load("images/img_2abc6ca6.png", IMG_2abc6ca6_ASSET = "file")
load("images/img_2b91e2bb.png", IMG_2b91e2bb_ASSET = "file")
load("images/img_2e12e35e.png", IMG_2e12e35e_ASSET = "file")
load("images/img_3014f7e9.png", IMG_3014f7e9_ASSET = "file")
load("images/img_305ca1e6.png", IMG_305ca1e6_ASSET = "file")
load("images/img_38178f32.png", IMG_38178f32_ASSET = "file")
load("images/img_3dd9f45c.png", IMG_3dd9f45c_ASSET = "file")
load("images/img_3e3b5a4f.png", IMG_3e3b5a4f_ASSET = "file")
load("images/img_401bce0f.png", IMG_401bce0f_ASSET = "file")
load("images/img_44df9841.png", IMG_44df9841_ASSET = "file")
load("images/img_46472bbd.png", IMG_46472bbd_ASSET = "file")
load("images/img_466f8400.png", IMG_466f8400_ASSET = "file")
load("images/img_493deaa7.png", IMG_493deaa7_ASSET = "file")
load("images/img_4bb72bde.png", IMG_4bb72bde_ASSET = "file")
load("images/img_4ff92c3c.png", IMG_4ff92c3c_ASSET = "file")
load("images/img_6080019f.png", IMG_6080019f_ASSET = "file")
load("images/img_6480b1c6.png", IMG_6480b1c6_ASSET = "file")
load("images/img_667ee38b.png", IMG_667ee38b_ASSET = "file")
load("images/img_676ffa48.png", IMG_676ffa48_ASSET = "file")
load("images/img_67ab6470.png", IMG_67ab6470_ASSET = "file")
load("images/img_693bad85.png", IMG_693bad85_ASSET = "file")
load("images/img_6a8af36c.png", IMG_6a8af36c_ASSET = "file")
load("images/img_6c2e5753.png", IMG_6c2e5753_ASSET = "file")
load("images/img_6e474513.png", IMG_6e474513_ASSET = "file")
load("images/img_6e9e39ce.png", IMG_6e9e39ce_ASSET = "file")
load("images/img_70206d77.png", IMG_70206d77_ASSET = "file")
load("images/img_710d2efe.png", IMG_710d2efe_ASSET = "file")
load("images/img_7614353a.png", IMG_7614353a_ASSET = "file")
load("images/img_76271569.png", IMG_76271569_ASSET = "file")
load("images/img_79b0bac8.png", IMG_79b0bac8_ASSET = "file")
load("images/img_7a69691f.png", IMG_7a69691f_ASSET = "file")
load("images/img_7b3fce33.png", IMG_7b3fce33_ASSET = "file")
load("images/img_7b8cffbd.png", IMG_7b8cffbd_ASSET = "file")
load("images/img_7ea6ea3f.png", IMG_7ea6ea3f_ASSET = "file")
load("images/img_7fcd8c1b.png", IMG_7fcd8c1b_ASSET = "file")
load("images/img_81e3cbfa.png", IMG_81e3cbfa_ASSET = "file")
load("images/img_8a45a180.png", IMG_8a45a180_ASSET = "file")
load("images/img_8d28c58e.png", IMG_8d28c58e_ASSET = "file")
load("images/img_8ea99e9c.png", IMG_8ea99e9c_ASSET = "file")
load("images/img_8fcff451.png", IMG_8fcff451_ASSET = "file")
load("images/img_928bc0a7.png", IMG_928bc0a7_ASSET = "file")
load("images/img_96a79438.png", IMG_96a79438_ASSET = "file")
load("images/img_96d36788.png", IMG_96d36788_ASSET = "file")
load("images/img_99378ed6.png", IMG_99378ed6_ASSET = "file")
load("images/img_9f553e28.png", IMG_9f553e28_ASSET = "file")
load("images/img_a762344e.png", IMG_a762344e_ASSET = "file")
load("images/img_ac526e83.png", IMG_ac526e83_ASSET = "file")
load("images/img_ad58a696.png", IMG_ad58a696_ASSET = "file")
load("images/img_af03af72.png", IMG_af03af72_ASSET = "file")
load("images/img_b64ee582.png", IMG_b64ee582_ASSET = "file")
load("images/img_b8e1b7bb.png", IMG_b8e1b7bb_ASSET = "file")
load("images/img_b9996b9c.png", IMG_b9996b9c_ASSET = "file")
load("images/img_b9ff52a5.png", IMG_b9ff52a5_ASSET = "file")
load("images/img_ba22b234.png", IMG_ba22b234_ASSET = "file")
load("images/img_bbe283f5.png", IMG_bbe283f5_ASSET = "file")
load("images/img_bdfb956c.png", IMG_bdfb956c_ASSET = "file")
load("images/img_c3b2294f.png", IMG_c3b2294f_ASSET = "file")
load("images/img_c3c1a8e5.png", IMG_c3c1a8e5_ASSET = "file")
load("images/img_c40c862c.png", IMG_c40c862c_ASSET = "file")
load("images/img_c5fd58f3.png", IMG_c5fd58f3_ASSET = "file")
load("images/img_c8873bf3.png", IMG_c8873bf3_ASSET = "file")
load("images/img_cbd6769b.png", IMG_cbd6769b_ASSET = "file")
load("images/img_cfd50317.png", IMG_cfd50317_ASSET = "file")
load("images/img_d0d68b13.png", IMG_d0d68b13_ASSET = "file")
load("images/img_d21babe8.png", IMG_d21babe8_ASSET = "file")
load("images/img_d32b5aa5.png", IMG_d32b5aa5_ASSET = "file")
load("images/img_d482e1be.png", IMG_d482e1be_ASSET = "file")
load("images/img_d7b732f8.png", IMG_d7b732f8_ASSET = "file")
load("images/img_db58db18.png", IMG_db58db18_ASSET = "file")
load("images/img_dcf373d2.png", IMG_dcf373d2_ASSET = "file")
load("images/img_e934d8af.png", IMG_e934d8af_ASSET = "file")
load("images/img_eac1de65.png", IMG_eac1de65_ASSET = "file")
load("images/img_ec2759ed.png", IMG_ec2759ed_ASSET = "file")
load("images/img_ee5b9afe.png", IMG_ee5b9afe_ASSET = "file")
load("images/img_efbf80ae.png", IMG_efbf80ae_ASSET = "file")
load("images/img_f4260de5.png", IMG_f4260de5_ASSET = "file")
load("images/img_f746f5c3.png", IMG_f746f5c3_ASSET = "file")
load("images/img_fec39401.png", IMG_fec39401_ASSET = "file")

BRANCH_OPTIONS = [
    schema.Option(display = "Display A Random Rank Each Time", value = "random"),
    schema.Option(value = "Air Force", display = "Air Force"),
    schema.Option(value = "Army", display = "Army"),
    schema.Option(value = "Coast Guard", display = "Coast Guard"),
    schema.Option(value = "Marines", display = "Marines"),
    schema.Option(value = "Navy", display = "Navy"),
    schema.Option(value = "Space Force", display = "Space Force"),
]

ARMY_RANKS = [
    schema.Option(display = "Private", value = "Army|E1|Private"),
    schema.Option(display = "Private Second Class", value = "Army|E2|Private Second Class"),
    schema.Option(display = "Private First Class", value = "Army|E3|Private First Class"),
    schema.Option(display = "Specialist", value = "Army|E4|Specialist"),
    schema.Option(display = "Corporal", value = "Army|E4B|Corporal"),
    schema.Option(display = "Sergeant", value = "Army|E5|Sergeant"),
    schema.Option(display = "Staff Sergeant", value = "Army|E6|Staff Sergeant"),
    schema.Option(display = "Sergeant First Class", value = "Army|E7|Sergeant First Class"),
    schema.Option(display = "Master Sergeant", value = "Army|E8|Master Sergeant"),
    schema.Option(display = "First Sergeant", value = "Army|E8B|First Sergeant"),
    schema.Option(display = "Sergeant Major", value = "Army|E9|Sergeant Major"),
    schema.Option(display = "Command Sergeant Major", value = "Army|E9B|Command Sergeant Major"),
    schema.Option(display = "Sergeant Major of the Army", value = "Army|E9C|Sergeant Major of the Army"),
    schema.Option(display = "Warrant Officer 1", value = "Army|W1|Warrant Officer 1"),
    schema.Option(display = "Chief Warrant Officer 2", value = "Army|W2|Chief Warrant Officer 2"),
    schema.Option(display = "Chief Warrant Officer 3", value = "Army|W3|Chief Warrant Officer 3"),
    schema.Option(display = "Chief Warrant Officer 4", value = "Army|W4|Chief Warrant Officer 4"),
    schema.Option(display = "Chief Warrant Officer 5", value = "Army|W5|Chief Warrant Officer 5"),
    schema.Option(display = "Second Lieutenant", value = "Army|O1|Second Lieutenant"),
    schema.Option(display = "First Lieutenant", value = "Army|O2|First Lieutenant"),
    schema.Option(display = "Captain", value = "Army|O3|Captain"),
    schema.Option(display = "Major", value = "Army|O4|Major"),
    schema.Option(display = "Lieutenant Colonel", value = "Army|O5|Lieutenant Colonel"),
    schema.Option(display = "Colonel", value = "Army|O6|Colonel"),
    schema.Option(display = "Brigadier General", value = "Army|O7|Brigadier General"),
    schema.Option(display = "Major General", value = "Army|O8|Major General"),
    schema.Option(display = "Lieutenant General", value = "Army|O9|Lieutenant General"),
    schema.Option(display = "General", value = "Army|O10|General"),
    schema.Option(display = "General of the Army", value = "Army|O10B|General of the Army"),
]

AIR_FORCE_RANKS = [
    schema.Option(display = "Airman Basic", value = "Air Force|E1|Airman Basic"),
    schema.Option(display = "Airman", value = "Air Force|E2|Airman"),
    schema.Option(display = "Airman First Class", value = "Air Force|E3|Airman First Class"),
    schema.Option(display = "Senior Airman", value = "Air Force|E4|Senior Airman"),
    schema.Option(display = "Staff Sergeant", value = "Air Force|E5|Staff Sergeant"),
    schema.Option(display = "Technical Sergeant", value = "Air Force|E6|Technical Sergeant"),
    schema.Option(display = "Master Sergeant", value = "Air Force|E7|Master Sergeant"),
    schema.Option(display = "Senior Master Sergeant", value = "Air Force|E8|Senior Master Sergeant"),
    schema.Option(display = "Chief Master Sergeant", value = "Air Force|E9|Chief Master Sergeant"),
    schema.Option(display = "Command Chief Master Sergeant", value = "Air Force|E9B|Command Chief Master Sergeant"),
    schema.Option(display = "Chief Master Sergeant of the Air Force", value = "Air Force|E9C|Chief Master Sergeant of the Air Force"),
    schema.Option(display = "Second Lieutenant", value = "Air Force|O1|Second Lieutenant"),
    schema.Option(display = "First Lieutenant", value = "Air Force|O2|First Lieutenant"),
    schema.Option(display = "Captain", value = "Air Force|O3|Captain"),
    schema.Option(display = "Major", value = "Air Force|O4|Major"),
    schema.Option(display = "Lieutenant Colonel", value = "Air Force|O5|Lieutenant Colonel"),
    schema.Option(display = "Colonel", value = "Air Force|O6|Colonel"),
    schema.Option(display = "Brigadier General", value = "Air Force|O7|Brigadier General"),
    schema.Option(display = "Major General", value = "Air Force|O8|Major General"),
    schema.Option(display = "Lieutenant General", value = "Air Force|O9|Lieutenant General"),
    schema.Option(display = "General", value = "Air Force|O10|General"),
    schema.Option(display = "General of the Air Force", value = "Air Force|O10B|General of the Air Force"),
]

SPACE_FORCE_RANKS = [
    schema.Option(display = "Specialist 1", value = "Space Force|E1|Specialist 1"),
    schema.Option(display = "Specialist 2", value = "Space Force|E2|Specialist 2"),
    schema.Option(display = "Specialist 3", value = "Space Force|E3|Specialist 3"),
    schema.Option(display = "Specialist 4", value = "Space Force|E4|Specialist 4"),
    schema.Option(display = "Staff Sergeant", value = "Space Force|E5|Staff Sergeant"),
    schema.Option(display = "Technical Sergeant", value = "Space Force|E6|Technical Sergeant"),
    schema.Option(display = "Master Sergeant", value = "Space Force|E7|Master Sergeant"),
    schema.Option(display = "Senior Master Sergeant", value = "Space Force|E8|Senior Master Sergeant"),
    schema.Option(display = "Chief Master Sergeant", value = "Space Force|E9|Chief Master Sergeant"),
    schema.Option(display = "Command Chief Master Sergeant", value = "Space Force|E9B|Command Chief Master Sergeant"),
    schema.Option(display = "Chief Master Sergeant of the Space Force", value = "Space Force|E9C|Chief Master Sergeant of the Space Force"),
    schema.Option(display = "Second Lieutenant", value = "Space Force|O1|Second Lieutenant"),
    schema.Option(display = "First Lieutenant", value = "Space Force|O2|First Lieutenant"),
    schema.Option(display = "Captain", value = "Space Force|O3|Captain"),
    schema.Option(display = "Major", value = "Space Force|O4|Major"),
    schema.Option(display = "Lieutenant Colonel", value = "Space Force|O5|Lieutenant Colonel"),
    schema.Option(display = "Colonel", value = "Space Force|O6|Colonel"),
    schema.Option(display = "Brigadier General", value = "Space Force|O7|Brigadier General"),
    schema.Option(display = "Major General", value = "Space Force|O8|Major General"),
    schema.Option(display = "Lieutenant General", value = "Space Force|O9|Lieutenant General"),
    schema.Option(display = "General", value = "Space Force|O10|General"),
    schema.Option(display = "General of the Air Force", value = "Space Force|O10B|General of the Space Force"),
]
MARINE_RANKS = [
    schema.Option(display = "Private", value = "Marines|E1|Private"),
    schema.Option(display = "Private First Class", value = "Marines|E2|Private First Class"),
    schema.Option(display = "Lance Corporal", value = "Marines|E3|Lance Corporal"),
    schema.Option(display = "Corporal", value = "Marines|E4|Corporal"),
    schema.Option(display = "Sergeant", value = "Marines|E5|Sergeant"),
    schema.Option(display = "Staff Sergeant", value = "Marines|E6|Staff Sergeant"),
    schema.Option(display = "Gunnery Sergeant", value = "Marines|E7|Gunnery Sergeant"),
    schema.Option(display = "Master Sergeant", value = "Marines|E8|Master Sergeant"),
    schema.Option(display = "First Sergeant", value = "Marines|E8B|First Sergeant"),
    schema.Option(display = "Master Gunnery Sergeant", value = "Marines|E9|Master Gunnery Sergeant"),
    schema.Option(display = "Sergeant Major", value = "Marines|E9B|Sergeant Major"),
    schema.Option(display = "Sergeant Major of the Marine Corps", value = "Marines|E9C|Sergeant Major of the Marine Corps"),
    schema.Option(display = "Warrant Officer 1", value = "Marines|W1|Warrant Officer 1"),
    schema.Option(display = "Chief Warrant Officer 2", value = "Marines|W2|Chief Warrant Officer 2"),
    schema.Option(display = "Chief Warrant Officer 3", value = "Marines|W3|Chief Warrant Officer 3"),
    schema.Option(display = "Chief Warrant Officer 4", value = "Marines|W4|Chief Warrant Officer 4"),
    schema.Option(display = "Chief Warrant Officer 5", value = "Marines|W5|Chief Warrant Officer 5"),
    schema.Option(display = "Second Lieutenant", value = "Marines|O1|Second Lieutenant"),
    schema.Option(display = "First Lieutenant", value = "Marines|O2|First Lieutenant"),
    schema.Option(display = "Captain", value = "Marines|O3|Captain"),
    schema.Option(display = "Major", value = "Marines|O4|Major"),
    schema.Option(display = "Lieutenant Colonel", value = "Marines|O5|Lieutenant Colonel"),
    schema.Option(display = "Colonel", value = "Marines|O6|Colonel"),
    schema.Option(display = "Brigadier General", value = "Marines|O7|Brigadier General"),
    schema.Option(display = "Major General", value = "Marines|O8|Major General"),
    schema.Option(display = "Lieutenant General", value = "Marines|O9|Lieutenant General"),
    schema.Option(display = "General", value = "Marines|O10|General"),
]

NAVY_RANKS = [
    schema.Option(display = "Seaman Recruit", value = "Navy|E1|Seaman Recruit"),
    schema.Option(display = "Seaman Apprentice", value = "Navy|E2|Seaman Apprentice"),
    schema.Option(display = "Seaman", value = "Navy|E3|Seaman"),
    schema.Option(display = "Petty Officer Third Class", value = "Navy|E4|Petty Officer Third Class"),
    schema.Option(display = "Petty Officer Second Class", value = "Navy|E5|Petty Officer Second Class"),
    schema.Option(display = "Petty Officer First Class", value = "Navy|E6|Petty Officer First Class"),
    schema.Option(display = "Chief Petty Officer", value = "Navy|E7|Chief Petty Officer"),
    schema.Option(display = "Senior Chief Petty Officer", value = "Navy|E8|Senior Chief Petty Officer"),
    schema.Option(display = "Master Chief Petty Officer", value = "Navy|E9|Master Chief Petty Officer"),
    schema.Option(display = "Command Master Chief Petty Officer", value = "Navy|E9B|Command Master Chief Petty Officer"),
    schema.Option(display = "Master Chief Petty Officer of the Navy", value = "Navy|E9C|Master Chief Petty Officer of the Navy"),
    schema.Option(display = "Chief Warrant Officer 2", value = "Navy|W2|Chief Warrant Officer 2"),
    schema.Option(display = "Chief Warrant Officer 3", value = "Navy|W3|Chief Warrant Officer 3"),
    schema.Option(display = "Chief Warrant Officer 4", value = "Navy|W4|Chief Warrant Officer 4"),
    schema.Option(display = "Chief Warrant Officer 5", value = "Navy|W5|Chief Warrant Officer 5"),
    schema.Option(display = "Ensign", value = "Navy|O1|Ensign"),
    schema.Option(display = "Lieutenant Junior Grade", value = "Navy|O2|Lieutenant Junior Grade"),
    schema.Option(display = "Lieutenant", value = "Navy|O3|Lieutenant"),
    schema.Option(display = "Lieutenant Commander", value = "Navy|O4|Lieutenant Commander"),
    schema.Option(display = "Commander", value = "Navy|O5|Commander"),
    schema.Option(display = "Captain", value = "Navy|O6|Captain"),
    schema.Option(display = "Rear Admiral Lower Half", value = "Navy|O7|Rear Admiral Lower Half"),
    schema.Option(display = "Rear Admiral", value = "Navy|O8|Rear Admiral"),
    schema.Option(display = "Vice Admiral", value = "Navy|O9|Vice Admiral"),
    schema.Option(display = "Admiral", value = "Navy|O10|Admiral"),
    schema.Option(display = "Fleet Admiral", value = "Navy|O11|Fleet Admiral"),
]

COAST_GUARD_RANKS = [
    schema.Option(display = "Seaman Recruit", value = "Coast Guard|E1|Seaman Recruit"),
    schema.Option(display = "Seaman Apprentice", value = "Coast Guard|E2|Seaman Apprentice"),
    schema.Option(display = "Seaman", value = "Coast Guard|E3|Seaman"),
    schema.Option(display = "Petty Officer Third Class", value = "Coast Guard|E4|Petty Officer Third Class"),
    schema.Option(display = "Petty Officer Second Class", value = "Coast Guard|E5|Petty Officer Second Class"),
    schema.Option(display = "Petty Officer First Class", value = "Coast Guard|E6|Petty Officer First Class"),
    schema.Option(display = "Chief Petty Officer", value = "Coast Guard|E7|Chief Petty Officer"),
    schema.Option(display = "Senior Chief Petty Officer", value = "Coast Guard|E8|Senior Chief Petty Officer"),
    schema.Option(display = "Master Chief Petty Officer", value = "Coast Guard|E9|Master Chief Petty Officer"),
    schema.Option(display = "Command Master Chief Petty Officer", value = "Coast Guard|E9B|Command Master Chief Petty Officer"),
    schema.Option(display = "Master Chief Petty Officer of the Navy", value = "Coast Guard|E9C|Master Chief Petty Officer of the Navy"),
    schema.Option(display = "Chief Warrant Officer 2", value = "Coast Guard|W2|Chief Warrant Officer 2"),
    schema.Option(display = "Chief Warrant Officer 3", value = "Coast Guard|W3|Chief Warrant Officer 3"),
    schema.Option(display = "Chief Warrant Officer 4", value = "Coast Guard|W4|Chief Warrant Officer 4"),
    schema.Option(display = "Chief Warrant Officer 5", value = "Coast Guard|W5|Chief Warrant Officer 5"),
    schema.Option(display = "Ensign", value = "Coast Guard|O1|Ensign"),
    schema.Option(display = "Lieutenant Junior Grade", value = "Coast Guard|O2|Lieutenant Junior Grade"),
    schema.Option(display = "Lieutenant", value = "Coast Guard|O3|Lieutenant"),
    schema.Option(display = "Lieutenant Commander", value = "Coast Guard|O4|Lieutenant Commander"),
    schema.Option(display = "Commander", value = "Coast Guard|O5|Commander"),
    schema.Option(display = "Captain", value = "Coast Guard|O6|Captain"),
    schema.Option(display = "Rear Admiral Lower Half", value = "Coast Guard|O7|Rear Admiral Lower Half"),
    schema.Option(display = "Rear Admiral", value = "Coast Guard|O8|Rear Admiral"),
    schema.Option(display = "Vice Admiral", value = "Coast Guard|O9|Vice Admiral"),
    schema.Option(display = "Admiral", value = "Coast Guard|O10|Admiral"),
]

ranks = {
    "Army": {
        "E1": {
            "name": "Private",
            "height": "0",
            "width": "0",
            "image": IMG_4ff92c3c_ASSET.readall(),
        },
        "E2": {
            "name": "Private Second Class",
            "height": "28",
            "width": "30",
            "image": IMG_ee5b9afe_ASSET.readall(),
        },
        "E3": {
            "name": "Pfc.",
            "height": "28",
            "width": "23",
            "image": IMG_6a8af36c_ASSET.readall(),
        },
        "E4": {
            "name": "Spc.",
            "height": "28",
            "width": "23",
            "image": IMG_6e9e39ce_ASSET.readall(),
        },
        "E4B": {
            "name": "Cpl.",
            "height": "28",
            "width": "023",
            "image": IMG_cfd50317_ASSET.readall(),
        },
        "E5": {
            "name": "Sgt.",
            "height": "28",
            "width": "23",
            "image": IMG_1631440a_ASSET.readall(),
        },
        "E6": {
            "name": "Staff Sergeant",
            "height": "32",
            "width": "23",
            "image": IMG_38178f32_ASSET.readall(),
        },
        "E7": {
            "name": "Sergeant First Class",
            "height": "32",
            "width": "19",
            "image": IMG_466f8400_ASSET.readall(),
        },
        "E8": {
            "name": "Master Sergeant",
            "height": "32",
            "width": "18",
            "image": IMG_ad58a696_ASSET.readall(),
        },
        "E8B": {
            "name": "1st Sgt.",
            "height": "32",
            "width": "18",
            "image": IMG_76271569_ASSET.readall(),
        },
        "E9": {
            "name": "Sgt.Maj.",
            "height": "32",
            "width": "18",
            "image": IMG_d0d68b13_ASSET.readall(),
        },
        "E9B": {
            "name": "Command Sergeant Major",
            "height": "32",
            "width": "18",
            "image": IMG_02c25812_ASSET.readall(),
        },
        "E9C": {
            "name": "Sergeant Major of the Army",
            "height": "32",
            "width": "18",
            "image": IMG_7a69691f_ASSET.readall(),
        },
        "W1": {
            "name": "Warrant Officer 1",
            "height": "32",
            "width": "10",
            "image": IMG_2abc6ca6_ASSET.readall(),
        },
        "W2": {
            "name": "Chief Warrant Officer 2",
            "height": "32",
            "width": "10",
            "image": IMG_e934d8af_ASSET.readall(),
        },
        "W3": {
            "name": "Chief Warrant Officer 3",
            "height": "32",
            "width": "10",
            "image": IMG_07d6ce0e_ASSET.readall(),
        },
        "W4": {
            "name": "Chief Warrant Officer 4",
            "height": "32",
            "width": "10",
            "image": IMG_c5fd58f3_ASSET.readall(),
        },
        "W5": {
            "name": "Chief Warrant Officer 5",
            "height": "32",
            "width": "10",
            "image": IMG_ec2759ed_ASSET.readall(),
        },
        "O1": {
            "name": "2nd Lt.",
            "height": "32",
            "width": "13",
            "image": IMG_7b8cffbd_ASSET.readall(),
        },
        "O2": {
            "name": "1st Lt.",
            "height": "32",
            "width": "013",
            "image": IMG_d21babe8_ASSET.readall(),
        },
        "O3": {
            "name": "Captain",
            "height": "22",
            "width": "24",
            "image": IMG_7b3fce33_ASSET.readall(),
        },
        "O4": {
            "name": "Major",
            "height": "18",
            "width": "18",
            "image": IMG_3e3b5a4f_ASSET.readall(),
        },
        "O5": {
            "name": "Lt.Col.",
            "height": "18",
            "width": "18",
            "image": IMG_fec39401_ASSET.readall(),
        },
        "O6": {
            "name": "Col.",
            "height": "16",
            "width": "32",
            "image": IMG_1d70d2d6_ASSET.readall(),
        },
        "O7": {
            "name": "Brig.Gen.",
            "height": "16",
            "width": "18",
            "image": IMG_2e12e35e_ASSET.readall(),
        },
        "O8": {
            "name": "Maj.Gen.",
            "height": "16",
            "width": "18",
            "image": IMG_d7b732f8_ASSET.readall(),
        },
        "O9": {
            "name": "Lt.Gen.",
            "height": "16",
            "width": "18",
            "image": IMG_b64ee582_ASSET.readall(),
        },
        "O10": {
            "name": "General",
            "height": "8",
            "width": "18",
            "image": IMG_dcf373d2_ASSET.readall(),
        },
        "O10B": {
            "name": "General of the Army",
            "height": "16",
            "width": "18",
            "image": IMG_401bce0f_ASSET.readall(),
        },
    },
    "Air Force": {
        "E1": {
            "name": "Airman Basic",
            "height": "0",
            "width": "0",
            "image": IMG_4ff92c3c_ASSET.readall(),
        },
        "E2": {
            "name": "Airman",
            "height": "15",
            "width": "32",
            "image": IMG_305ca1e6_ASSET.readall(),
        },
        "E3": {
            "name": "Airman 1st Class",
            "height": "20",
            "width": "32",
            "image": IMG_79b0bac8_ASSET.readall(),
        },
        "E4": {
            "name": "Senior Airman",
            "height": "20",
            "width": "32",
            "image": IMG_c3c1a8e5_ASSET.readall(),
        },
        "E5": {
            "name": "Staff Sgt.",
            "height": "20",
            "width": "32",
            "image": IMG_af03af72_ASSET.readall(),
        },
        "E6": {
            "name": "Technical Sergeant",
            "height": "28",
            "width": "32",
            "image": IMG_f4260de5_ASSET.readall(),
        },
        "E7": {
            "name": "Master Sergeant",
            "height": "32",
            "width": "24",
            "image": IMG_7fcd8c1b_ASSET.readall(),
        },
        "E8": {
            "name": "Senior Master Sergeant",
            "height": "32",
            "width": "22",
            "image": IMG_b8e1b7bb_ASSET.readall(),
        },
        "E9": {
            "name": "Chief Master Sergeant",
            "height": "32",
            "width": "22",
            "image": IMG_b9996b9c_ASSET.readall(),
        },
        "E9B": {
            "name": "Command Chief Master Sergeant",
            "height": "32",
            "width": "22",
            "image": IMG_ba22b234_ASSET.readall(),
        },
        "E9C": {
            "name": "Chief Master Sergeant of the Air Force",
            "height": "32",
            "width": "22",
            "image": IMG_8fcff451_ASSET.readall(),
        },
        "O1": {
            "name": "2nd Lt.",
            "height": "32",
            "width": "13",
            "image": IMG_7b8cffbd_ASSET.readall(),
        },
        "O2": {
            "name": "1st Lt.",
            "height": "32",
            "width": "13",
            "image": IMG_d21babe8_ASSET.readall(),
        },
        "O3": {
            "name": "Captain",
            "height": "16",
            "width": "18",
            "image": IMG_7b3fce33_ASSET.readall(),
        },
        "O4": {
            "name": "Major",
            "height": "16",
            "width": "18",
            "image": IMG_3e3b5a4f_ASSET.readall(),
        },
        "O5": {
            "name": "Lt. Col.",
            "height": "16",
            "width": "18",
            "image": IMG_fec39401_ASSET.readall(),
        },
        "O6": {
            "name": "Col.",
            "height": "16",
            "width": "32",
            "image": IMG_1d70d2d6_ASSET.readall(),
        },
        "O7": {
            "name": "Brig.Gen.",
            "height": "16",
            "width": "18",
            "image": IMG_2e12e35e_ASSET.readall(),
        },
        "O8": {
            "name": "Maj.Gen.",
            "height": "8",
            "width": "18",
            "image": IMG_d7b732f8_ASSET.readall(),
        },
        "O9": {
            "name": "Lt. Gen.",
            "height": "8",
            "width": "18",
            "image": IMG_b64ee582_ASSET.readall(),
        },
        "O10": {
            "name": "General",
            "height": "8",
            "width": "22",
            "image": IMG_dcf373d2_ASSET.readall(),
        },
        "O10B": {
            "name": "General of the Air Force",
            "height": "20",
            "width": "22",
            "image": IMG_401bce0f_ASSET.readall(),
        },
    },
    "Space Force": {
        "E0": {
            "name": "Specialist Trainee",
            "height": "32",
            "width": "18",
            "image": IMG_4ff92c3c_ASSET.readall(),
        },
        "E1": {
            "name": "Spc.",
            "height": "20",
            "width": "18",
            "image": IMG_cbd6769b_ASSET.readall(),
        },
        "E2": {
            "name": "Spc.2",
            "height": "20",
            "width": "18",
            "image": IMG_08fac660_ASSET.readall(),
        },
        "E3": {
            "name": "Spc.3",
            "height": "20",
            "width": "18",
            "image": IMG_d32b5aa5_ASSET.readall(),
        },
        "E4": {
            "name": "Spc.4",
            "height": "20",
            "width": "18",
            "image": IMG_bdfb956c_ASSET.readall(),
        },
        "E5": {
            "name": "Sgt.",
            "height": "22",
            "width": "18",
            "image": IMG_4bb72bde_ASSET.readall(),
        },
        "E6": {
            "name": "Technical Sergeant",
            "height": "28",
            "width": "18",
            "image": IMG_44df9841_ASSET.readall(),
        },
        "E7": {
            "name": "Master Sergeant",
            "height": "28",
            "width": "18",
            "image": IMG_ac526e83_ASSET.readall(),
        },
        "E8": {
            "name": "Senior Master Sergeant",
            "height": "30",
            "width": "18",
            "image": IMG_6480b1c6_ASSET.readall(),
        },
        "E9": {
            "name": "Chief Master Sergeant",
            "height": "30",
            "width": "18",
            "image": IMG_70206d77_ASSET.readall(),
        },
        "E9B": {
            "name": "Command Chief Master Sergeant",
            "height": "30",
            "width": "18",
            "image": IMG_1d61f874_ASSET.readall(),
        },
        "E9C": {
            "name": "Chief Master Sergeant of the Space Force",
            "height": "30",
            "width": "18",
            "image": IMG_161b696f_ASSET.readall(),
        },
        "O1": {
            "name": "2nd.Lt.",
            "height": "32",
            "width": "13",
            "image": IMG_7b8cffbd_ASSET.readall(),
        },
        "O2": {
            "name": "1st.Lt.",
            "height": "32",
            "width": "13",
            "image": IMG_d21babe8_ASSET.readall(),
        },
        "O3": {
            "name": "Captain",
            "height": "16",
            "width": "18",
            "image": IMG_7b3fce33_ASSET.readall(),
        },
        "O4": {
            "name": "Major",
            "height": "16",
            "width": "18",
            "image": IMG_3e3b5a4f_ASSET.readall(),
        },
        "O5": {
            "name": "Lt.Col.",
            "height": "16",
            "width": "18",
            "image": IMG_fec39401_ASSET.readall(),
        },
        "O6": {
            "name": "Col.",
            "height": "16",
            "width": "32",
            "image": IMG_1d70d2d6_ASSET.readall(),
        },
        "O7": {
            "name": "Brig.Gen.",
            "height": "16",
            "width": "18",
            "image": IMG_2e12e35e_ASSET.readall(),
        },
        "O8": {
            "name": "Maj.Gen.",
            "height": "10",
            "width": "18",
            "image": IMG_d7b732f8_ASSET.readall(),
        },
        "O9": {
            "name": "Lt.Gen.",
            "height": "10",
            "width": "18",
            "image": IMG_b64ee582_ASSET.readall(),
        },
        "O10": {
            "name": "General",
            "height": "10",
            "width": "22",
            "image": IMG_dcf373d2_ASSET.readall(),
        },
        "O10B": {
            "name": "General of the Air Force",
            "height": "20",
            "width": "22",
            "image": IMG_401bce0f_ASSET.readall(),
        },
    },
    "Marines": {
        "E1": {
            "name": "Pvt.",
            "height": "1",
            "width": "1",
            "image": IMG_4ff92c3c_ASSET.readall(),
        },
        "E2": {
            "name": "Pfc.",
            "height": "21",
            "width": "32",
            "image": IMG_28b6aaac_ASSET.readall(),
        },
        "E3": {
            "name": "Lance Cpl.",
            "height": "20",
            "width": "32",
            "image": IMG_7ea6ea3f_ASSET.readall(),
        },
        "E4": {
            "name": "Cpl.",
            "height": "32",
            "width": "28",
            "image": IMG_96a79438_ASSET.readall(),
        },
        "E5": {
            "name": "Sgt.",
            "height": "32",
            "width": "28",
            "image": IMG_6080019f_ASSET.readall(),
        },
        "E6": {
            "name": "Staff Sergeant",
            "height": "32",
            "width": "18",
            "image": IMG_f746f5c3_ASSET.readall(),
        },
        "E7": {
            "name": "Gunnery Sergeant",
            "height": "32",
            "width": "18",
            "image": IMG_eac1de65_ASSET.readall(),
        },
        "E8": {
            "name": "Master Sergeant",
            "height": "32",
            "width": "18",
            "image": IMG_b9ff52a5_ASSET.readall(),
        },
        "E8B": {
            "name": "1st.Sgt.",
            "height": "32",
            "width": "18",
            "image": IMG_96d36788_ASSET.readall(),
        },
        "E9": {
            "name": "Master Gunnery Sergeant",
            "height": "32",
            "width": "18",
            "image": IMG_8d28c58e_ASSET.readall(),
        },
        "E9B": {
            "name": "Sgt.Maj.",
            "height": "32",
            "width": "18",
            "image": IMG_a762344e_ASSET.readall(),
        },
        "E9C": {
            "name": "Sergeant Major of the Marine Corps",
            "height": "32",
            "width": "18",
            "image": IMG_d482e1be_ASSET.readall(),
        },
        "W1": {
            "name": "Warrant Officer 1",
            "height": "32",
            "width": "10",
            "image": IMG_c8873bf3_ASSET.readall(),
        },
        "W2": {
            "name": "Chief Warrant Officer 2",
            "height": "32",
            "width": "10",
            "image": IMG_c3b2294f_ASSET.readall(),
        },
        "W3": {
            "name": "Chief Warrant Officer 3",
            "height": "32",
            "width": "10",
            "image": IMG_8ea99e9c_ASSET.readall(),
        },
        "W4": {
            "name": "Chief Warrant Officer 4",
            "height": "32",
            "width": "10",
            "image": IMG_6e474513_ASSET.readall(),
        },
        "W5": {
            "name": "Chief Warrant Officer 5",
            "height": "32",
            "width": "10",
            "image": IMG_667ee38b_ASSET.readall(),
        },
        "O1": {
            "name": "2nd.Lt.",
            "height": "32",
            "width": "10",
            "image": IMG_7b8cffbd_ASSET.readall(),
        },
        "O2": {
            "name": "1st.Lt.",
            "height": "32",
            "width": "10",
            "image": IMG_d21babe8_ASSET.readall(),
        },
        "O3": {
            "name": "Captain",
            "height": "22",
            "width": "24",
            "image": IMG_7b3fce33_ASSET.readall(),
        },
        "O4": {
            "name": "Major",
            "height": "18",
            "width": "18",
            "image": IMG_3e3b5a4f_ASSET.readall(),
        },
        "O5": {
            "name": "Lt.Col.",
            "height": "18",
            "width": "18",
            "image": IMG_fec39401_ASSET.readall(),
        },
        "O6": {
            "name": "Col.",
            "height": "16",
            "width": "32",
            "image": IMG_1d70d2d6_ASSET.readall(),
        },
        "O7": {
            "name": "Brigadier General",
            "height": "22",
            "width": "24",
            "image": IMG_2e12e35e_ASSET.readall(),
        },
        "O8": {
            "name": "Maj.Gen",
            "height": "10",
            "width": "24",
            "image": IMG_d7b732f8_ASSET.readall(),
        },
        "O9": {
            "name": "Lt.Gen",
            "height": "8",
            "width": "24",
            "image": IMG_b64ee582_ASSET.readall(),
        },
        "O10": {
            "name": "General",
            "height": "8",
            "width": "24",
            "image": IMG_dcf373d2_ASSET.readall(),
        },
    },
    "Navy": {
        "E1": {
            "name": "Seaman Recruit",
            "height": "1",
            "width": "1",
            "image": IMG_4ff92c3c_ASSET.readall(),
        },
        "E2": {
            "name": "Seaman Apprentice",
            "height": "32",
            "width": "30",
            "image": IMG_67ab6470_ASSET.readall(),
        },
        "E3": {
            "name": "Seaman",
            "height": "32",
            "width": "30",
            "image": IMG_693bad85_ASSET.readall(),
        },
        "E4": {
            "name": "Petty Officer Third Class",
            "height": "32",
            "width": "30",
            "image": IMG_6c2e5753_ASSET.readall(),
        },
        "E5": {
            "name": "Petty Officer Second Class",
            "height": "32",
            "width": "24",
            "image": IMG_184ea5e6_ASSET.readall(),
        },
        "E6": {
            "name": "Petty Officer First Class",
            "height": "32",
            "width": "20",
            "image": IMG_493deaa7_ASSET.readall(),
        },
        "E7": {
            "name": "Chief Petty Officer",
            "height": "32",
            "width": "20",
            "image": IMG_7614353a_ASSET.readall(),
        },
        "E8": {
            "name": "Senior Chief Petty Officer",
            "height": "32",
            "width": "20",
            "image": IMG_3dd9f45c_ASSET.readall(),
        },
        "E9": {
            "name": "Master Chief Petty Officer",
            "height": "32",
            "width": "18",
            "image": IMG_bbe283f5_ASSET.readall(),
        },
        "E9B": {
            "name": "Command Master Chief Petty Officer",
            "height": "32",
            "width": "18",
            "image": IMG_99378ed6_ASSET.readall(),
        },
        "E9C": {
            "name": "Master Chief Petty Officer of the Navy",
            "height": "32",
            "width": "18",
            "image": IMG_db58db18_ASSET.readall(),
        },
        "W2": {
            "name": "Chief Warrant Officer 2",
            "height": "32",
            "width": "18",
            "image": IMG_07929664_ASSET.readall(),
        },
        "W3": {
            "name": "Chief Warrant Officer 3",
            "height": "32",
            "width": "18",
            "image": IMG_8a45a180_ASSET.readall(),
        },
        "W4": {
            "name": "Chief Warrant Officer 4",
            "height": "32",
            "width": "18",
            "image": IMG_3014f7e9_ASSET.readall(),
        },
        "W5": {
            "name": "Chief Warrant Officer 5",
            "height": "32",
            "width": "18",
            "image": IMG_710d2efe_ASSET.readall(),
        },
        "O1": {
            "name": "Ensign",
            "height": "32",
            "width": "20",
            "image": IMG_1d460cfb_ASSET.readall(),
        },
        "O2": {
            "name": "Lt. j.g.",
            "height": "32",
            "width": "20",
            "image": IMG_c40c862c_ASSET.readall(),
        },
        "O3": {
            "name": "Lt.",
            "height": "32",
            "width": "20",
            "image": IMG_9f553e28_ASSET.readall(),
        },
        "O4": {
            "name": "Lt.Cmdr.",
            "height": "32",
            "width": "20",
            "image": IMG_efbf80ae_ASSET.readall(),
        },
        "O5": {
            "name": "Cmdr.",
            "height": "32",
            "width": "20",
            "image": IMG_46472bbd_ASSET.readall(),
        },
        "O6": {
            "name": "Captain",
            "height": "32",
            "width": "20",
            "image": IMG_2b91e2bb_ASSET.readall(),
        },
        "O7": {
            "name": "Rear Adm.",
            "height": "32",
            "width": "20",
            "image": IMG_16657da3_ASSET.readall(),
        },
        "O8": {
            "name": "Rear Adm.",
            "height": "32",
            "width": "20",
            "image": IMG_1ebc1a1a_ASSET.readall(),
        },
        "O9": {
            "name": "Vice Adm",
            "height": "32",
            "width": "20",
            "image": IMG_81e3cbfa_ASSET.readall(),
        },
        "O10": {
            "name": "Admiral",
            "height": "32",
            "width": "20",
            "image": IMG_928bc0a7_ASSET.readall(),
        },
        "O11": {
            "name": "Fleet Admiral",
            "height": "32",
            "width": "20",
            "image": IMG_676ffa48_ASSET.readall(),
        },
    },
    "Coast Guard": {
        "E1": {
            "name": "Seaman Recruit",
            "height": "1",
            "width": "1",
            "image": IMG_4ff92c3c_ASSET.readall(),
        },
        "E2": {
            "name": "Seaman Apprentice",
            "height": "32",
            "width": "30",
            "image": IMG_67ab6470_ASSET.readall(),
        },
        "E3": {
            "name": "Seaman",
            "height": "32",
            "width": "30",
            "image": IMG_693bad85_ASSET.readall(),
        },
        "E4": {
            "name": "Petty Officer Third Class",
            "height": "32",
            "width": "30",
            "image": IMG_6c2e5753_ASSET.readall(),
        },
        "E5": {
            "name": "Petty Officer Second Class",
            "height": "32",
            "width": "30",
            "image": IMG_184ea5e6_ASSET.readall(),
        },
        "E6": {
            "name": "Petty Officer First Class",
            "height": "32",
            "width": "30",
            "image": IMG_493deaa7_ASSET.readall(),
        },
        "E7": {
            "name": "Chief Petty Officer",
            "height": "32",
            "width": "20",
            "image": IMG_7614353a_ASSET.readall(),
        },
        "E8": {
            "name": "Senior Chief Petty Officer",
            "height": "32",
            "width": "20",
            "image": IMG_3dd9f45c_ASSET.readall(),
        },
        "E9": {
            "name": "Master Chief Petty Officer",
            "height": "32",
            "width": "20",
            "image": IMG_bbe283f5_ASSET.readall(),
        },
        "E9B": {
            "name": "Command Master Chief Petty Officer",
            "height": "32",
            "width": "20",
            "image": IMG_99378ed6_ASSET.readall(),
        },
        "E9C": {
            "name": "Master Chief Petty Officer of the Navy",
            "height": "32",
            "width": "20",
            "image": IMG_db58db18_ASSET.readall(),
        },
        "W2": {
            "name": "Chief Warrant Officer 2",
            "height": "32",
            "width": "18",
            "image": IMG_07929664_ASSET.readall(),
        },
        "W3": {
            "name": "Chief Warrant Officer 3",
            "height": "32",
            "width": "18",
            "image": IMG_8a45a180_ASSET.readall(),
        },
        "W4": {
            "name": "Chief Warrant Officer 4",
            "height": "32",
            "width": "18",
            "image": IMG_3014f7e9_ASSET.readall(),
        },
        "W5": {
            "name": "Chief Warrant Officer 5",
            "height": "32",
            "width": "18",
            "image": IMG_710d2efe_ASSET.readall(),
        },
        "O1": {
            "name": "Ensign",
            "height": "32",
            "width": "20",
            "image": IMG_1d460cfb_ASSET.readall(),
        },
        "O2": {
            "name": "Lt. j.g.",
            "height": "32",
            "width": "20",
            "image": IMG_c40c862c_ASSET.readall(),
        },
        "O3": {
            "name": "Lt.",
            "height": "32",
            "width": "20",
            "image": IMG_9f553e28_ASSET.readall(),
        },
        "O4": {
            "name": "Lt.Cmdr.",
            "height": "32",
            "width": "20",
            "image": IMG_efbf80ae_ASSET.readall(),
        },
        "O5": {
            "name": "Cmdr.",
            "height": "32",
            "width": "20",
            "image": IMG_46472bbd_ASSET.readall(),
        },
        "O6": {
            "name": "Captain",
            "height": "32",
            "width": "20",
            "image": IMG_2b91e2bb_ASSET.readall(),
        },
        "O7": {
            "name": "Rear Adm.",
            "height": "32",
            "width": "20",
            "image": IMG_16657da3_ASSET.readall(),
        },
        "O8": {
            "name": "Rear Adm.",
            "height": "32",
            "width": "20",
            "image": IMG_1ebc1a1a_ASSET.readall(),
        },
        "O9": {
            "name": "Vice Adm.",
            "height": "32",
            "width": "20",
            "image": IMG_81e3cbfa_ASSET.readall(),
        },
        "O10": {
            "name": "Admiral",
            "height": "32",
            "width": "20",
            "image": IMG_928bc0a7_ASSET.readall(),
        },
    },
}

def get_random_rank(random_branch):
    random_rank_options = AIR_FORCE_RANKS

    if random_branch == "AirForce":
        random_rank_options = AIR_FORCE_RANKS
    elif random_branch == "Army":
        random_rank_options = ARMY_RANKS
    elif random_branch == "Navy":
        random_rank_options = NAVY_RANKS
    elif random_branch == "Marines":
        random_rank_options = MARINE_RANKS
    elif random_branch == "Coast Guard":
        random_rank_options = COAST_GUARD_RANKS
    elif random_branch == "Space Force":
        random_rank_options = SPACE_FORCE_RANKS
    else:
        random_rank_options = AIR_FORCE_RANKS

    return random_rank_options[random.number(0, len(random_rank_options) - 1)].value

def main(config):
    myBranch = config.get("branch", "Army")

    if (myBranch == "random"):
        random.seed(time.now().unix)
        myBranch = BRANCH_OPTIONS[random.number(1, 6)].value
        rankInfo = get_random_rank(myBranch).split("|")
    else:
        myRank = config.get("myrank", ARMY_RANKS[10].value)
        rankInfo = myRank.split("|")

    branch = str(rankInfo[0])
    selectedRank = ranks[branch][rankInfo[1]]
    selectedImage = base64.decode(selectedRank["image"])
    imageHeight = int(selectedRank["height"])
    imageWidth = int(selectedRank["width"])
    textWidth = 64 - 1 - imageWidth

    if imageWidth == 0:
        textWidth = 64

    children = []

    #Add rank insignia if it exists
    if imageWidth > 0:
        children.append(render.Image(selectedImage, height = imageHeight, width = imageWidth))

    #Add Rank text display
    children.append(
        add_padding_to_child_element(
            render.Marquee(
                width = textWidth,
                child = render.Text(selectedRank["name"], font = "CG-pixel-4x5-mono"),
            ),
            64 - textWidth,
        ),
    )

    #Add Name

    #default move it to the left as far as possible
    name_left_offset = 64 - textWidth if imageHeight > 10 else 1
    children.append(
        add_padding_to_child_element(
            render.Marquee(
                width = textWidth if imageHeight > 10 else 64,
                child = render.Text((config.str("myName", "")), font = "6x13"),
                offset_start = len(selectedRank["name"]) * 5,
            ),
            name_left_offset,
            6,
        ),
    )

    #Add Service

    #default move it to the left as far as possible
    service_left_offset = 64 - textWidth if imageHeight > 20 else 1

    #but if the service name is short enough to not scroll, let's put it under the name and rank
    if len(branch) * 5 < 32 - service_left_offset:
        service_left_offset = 64 - textWidth

    children.append(
        add_padding_to_child_element(
            render.Marquee(
                width = textWidth if imageHeight > 20 else 64,
                child = render.Text(branch, font = "CG-pixel-4x5-mono"),
                offset_start = (len(selectedRank["name"]) + len(config.str("myName", ""))) * 5,
            ),
            service_left_offset,
            32 - 5,
        ),
    )

    return render.Root(
        child = render.Stack(
            children = children,
        ),
        show_full_animation = True,
        delay = int(config.get("scroll", 45)),
    )

def add_padding_to_child_element(element, left = 0, top = 0, right = 0, bottom = 0):
    padded_element = render.Padding(
        pad = (left, top, right, bottom),
        child = element,
    )

    return padded_element

def get_ranks(branch):
    rank_options = ARMY_RANKS
    icon = "gun"

    if branch == "Air Force":
        rank_options = AIR_FORCE_RANKS
        icon = "jetFighter"
    elif branch == "Army":
        rank_options = ARMY_RANKS
        icon = "personMilitaryRifle"
    elif branch == "Navy":
        rank_options = NAVY_RANKS
        icon = "ship"
    elif branch == "Coast Guard":
        rank_options = COAST_GUARD_RANKS
        icon = "helicopter"
    elif branch == "Marines":
        rank_options = MARINE_RANKS
        icon = "personMilitaryRifle"
    elif branch == "Space Force":
        rank_options = SPACE_FORCE_RANKS
        icon = "satellite"
    else:
        rank_options = ARMY_RANKS
        icon = "gun"

    return [
        schema.Dropdown(
            id = "myrank",
            name = "%s Rank" % branch,
            desc = "Choose your rank",
            icon = icon,
            options = rank_options,
            default = rank_options[5].value,
        ),
    ]

def get_schema():
    scroll_speed_options = [
        schema.Option(
            display = "Slow Scroll",
            value = "60",
        ),
        schema.Option(
            display = "Medium Scroll",
            value = "45",
        ),
        schema.Option(
            display = "Fast Scroll",
            value = "30",
        ),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "myName",
                name = "Name",
                desc = "Enter your Name or leave blank",
                icon = "person",
                default = "",
            ),
            schema.Dropdown(
                id = "scroll",
                name = "Scroll",
                desc = "Scroll Speed",
                icon = "stopwatch",
                options = scroll_speed_options,
                default = scroll_speed_options[0].value,
            ),
            schema.Dropdown(
                id = "branch",
                name = "Branch",
                desc = "Military Branch",
                icon = "globe",
                options = BRANCH_OPTIONS,
                default = BRANCH_OPTIONS[0].value,
            ),
            schema.Generated(
                id = "rank",
                source = "branch",
                handler = get_ranks,
            ),
        ],
    )
