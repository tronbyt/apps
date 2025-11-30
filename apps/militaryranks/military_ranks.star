"""
Applet: Military Ranks
Summary: Display military ranks
Description: Displays military ranks.
Author: Robert Ison
"""

load("images/rank_air_force_e2_airman.png", RANK_AIR_FORCE_E2_AIRMAN_ASSET = "file")
load("images/rank_air_force_e3_airman_1st_class.png", RANK_AIR_FORCE_E3_AIRMAN_1ST_CLASS_ASSET = "file")
load("images/rank_air_force_e4_senior_airman.png", RANK_AIR_FORCE_E4_SENIOR_AIRMAN_ASSET = "file")
load("images/rank_air_force_e5_staff_sgt.png", RANK_AIR_FORCE_E5_STAFF_SGT_ASSET = "file")
load("images/rank_air_force_e6_technical_sergeant.png", RANK_AIR_FORCE_E6_TECHNICAL_SERGEANT_ASSET = "file")
load("images/rank_air_force_e7_master_sergeant.png", RANK_AIR_FORCE_E7_MASTER_SERGEANT_ASSET = "file")
load("images/rank_air_force_e8_senior_master_sergeant.png", RANK_AIR_FORCE_E8_SENIOR_MASTER_SERGEANT_ASSET = "file")
load("images/rank_air_force_e9_chief_master_sergeant.png", RANK_AIR_FORCE_E9_CHIEF_MASTER_SERGEANT_ASSET = "file")
load("images/rank_air_force_e9b_command_chief_master_sergeant.png", RANK_AIR_FORCE_E9B_COMMAND_CHIEF_MASTER_SERGEANT_ASSET = "file")
load("images/rank_air_force_e9c_chief_master_sergeant_of_the_air_force.png", RANK_AIR_FORCE_E9C_CHIEF_MASTER_SERGEANT_OF_THE_AIR_FORCE_ASSET = "file")
load("images/rank_army_e2_private_second_class.png", RANK_ARMY_E2_PRIVATE_SECOND_CLASS_ASSET = "file")
load("images/rank_army_e3_pfc.png", RANK_ARMY_E3_PFC_ASSET = "file")
load("images/rank_army_e4_spc.png", RANK_ARMY_E4_SPC_ASSET = "file")
load("images/rank_army_e4b_cpl.png", RANK_ARMY_E4B_CPL_ASSET = "file")
load("images/rank_army_e5_sgt.png", RANK_ARMY_E5_SGT_ASSET = "file")
load("images/rank_army_e6_staff_sergeant.png", RANK_ARMY_E6_STAFF_SERGEANT_ASSET = "file")
load("images/rank_army_e7_sergeant_first_class.png", RANK_ARMY_E7_SERGEANT_FIRST_CLASS_ASSET = "file")
load("images/rank_army_e8_master_sergeant.png", RANK_ARMY_E8_MASTER_SERGEANT_ASSET = "file")
load("images/rank_army_e8b_1st_sgt.png", RANK_ARMY_E8B_1ST_SGT_ASSET = "file")
load("images/rank_army_e9_sgt_maj.png", RANK_ARMY_E9_SGT_MAJ_ASSET = "file")
load("images/rank_army_e9b_command_sergeant_major.png", RANK_ARMY_E9B_COMMAND_SERGEANT_MAJOR_ASSET = "file")
load("images/rank_army_e9c_sergeant_major_of_the_army.png", RANK_ARMY_E9C_SERGEANT_MAJOR_OF_THE_ARMY_ASSET = "file")
load("images/rank_army_o10_general.png", RANK_ARMY_O10_GENERAL_ASSET = "file")
load("images/rank_army_o10b_general_of_the_army.png", RANK_ARMY_O10B_GENERAL_OF_THE_ARMY_ASSET = "file")
load("images/rank_army_o1_2nd_lt.png", RANK_ARMY_O1_2ND_LT_ASSET = "file")
load("images/rank_army_o2_1st_lt.png", RANK_ARMY_O2_1ST_LT_ASSET = "file")
load("images/rank_army_o3_captain.png", RANK_ARMY_O3_CAPTAIN_ASSET = "file")
load("images/rank_army_o4_major.png", RANK_ARMY_O4_MAJOR_ASSET = "file")
load("images/rank_army_o5_lt_col.png", RANK_ARMY_O5_LT_COL_ASSET = "file")
load("images/rank_army_o6_col.png", RANK_ARMY_O6_COL_ASSET = "file")
load("images/rank_army_o7_brig_gen.png", RANK_ARMY_O7_BRIG_GEN_ASSET = "file")
load("images/rank_army_o8_maj_gen.png", RANK_ARMY_O8_MAJ_GEN_ASSET = "file")
load("images/rank_army_o9_lt_gen.png", RANK_ARMY_O9_LT_GEN_ASSET = "file")
load("images/rank_army_w1_warrant_officer_1.png", RANK_ARMY_W1_WARRANT_OFFICER_1_ASSET = "file")
load("images/rank_army_w2_chief_warrant_officer_2.png", RANK_ARMY_W2_CHIEF_WARRANT_OFFICER_2_ASSET = "file")
load("images/rank_army_w3_chief_warrant_officer_3.png", RANK_ARMY_W3_CHIEF_WARRANT_OFFICER_3_ASSET = "file")
load("images/rank_army_w4_chief_warrant_officer_4.png", RANK_ARMY_W4_CHIEF_WARRANT_OFFICER_4_ASSET = "file")
load("images/rank_army_w5_chief_warrant_officer_5.png", RANK_ARMY_W5_CHIEF_WARRANT_OFFICER_5_ASSET = "file")
load("images/rank_generic_lowest_rank.png", RANK_GENERIC_LOWEST_RANK_ASSET = "file")
load("images/rank_marines_e2_pfc.png", RANK_MARINES_E2_PFC_ASSET = "file")
load("images/rank_marines_e3_lance_cpl.png", RANK_MARINES_E3_LANCE_CPL_ASSET = "file")
load("images/rank_marines_e4_cpl.png", RANK_MARINES_E4_CPL_ASSET = "file")
load("images/rank_marines_e5_sgt.png", RANK_MARINES_E5_SGT_ASSET = "file")
load("images/rank_marines_e6_staff_sergeant.png", RANK_MARINES_E6_STAFF_SERGEANT_ASSET = "file")
load("images/rank_marines_e7_gunnery_sergeant.png", RANK_MARINES_E7_GUNNERY_SERGEANT_ASSET = "file")
load("images/rank_marines_e8_master_sergeant.png", RANK_MARINES_E8_MASTER_SERGEANT_ASSET = "file")
load("images/rank_marines_e8b_1st_sgt.png", RANK_MARINES_E8B_1ST_SGT_ASSET = "file")
load("images/rank_marines_e9_master_gunnery_sergeant.png", RANK_MARINES_E9_MASTER_GUNNERY_SERGEANT_ASSET = "file")
load("images/rank_marines_e9b_sgt_maj.png", RANK_MARINES_E9B_SGT_MAJ_ASSET = "file")
load("images/rank_marines_e9c_sergeant_major_of_the_marine_corps.png", RANK_MARINES_E9C_SERGEANT_MAJOR_OF_THE_MARINE_CORPS_ASSET = "file")
load("images/rank_marines_w1_warrant_officer_1.png", RANK_MARINES_W1_WARRANT_OFFICER_1_ASSET = "file")
load("images/rank_marines_w2_chief_warrant_officer_2.png", RANK_MARINES_W2_CHIEF_WARRANT_OFFICER_2_ASSET = "file")
load("images/rank_marines_w3_chief_warrant_officer_3.png", RANK_MARINES_W3_CHIEF_WARRANT_OFFICER_3_ASSET = "file")
load("images/rank_marines_w4_chief_warrant_officer_4.png", RANK_MARINES_W4_CHIEF_WARRANT_OFFICER_4_ASSET = "file")
load("images/rank_marines_w5_chief_warrant_officer_5.png", RANK_MARINES_W5_CHIEF_WARRANT_OFFICER_5_ASSET = "file")
load("images/rank_navy_e2_seaman_apprentice.png", RANK_NAVY_E2_SEAMAN_APPRENTICE_ASSET = "file")
load("images/rank_navy_e3_seaman.png", RANK_NAVY_E3_SEAMAN_ASSET = "file")
load("images/rank_navy_e4_petty_officer_third_class.png", RANK_NAVY_E4_PETTY_OFFICER_THIRD_CLASS_ASSET = "file")
load("images/rank_navy_e5_petty_officer_second_class.png", RANK_NAVY_E5_PETTY_OFFICER_SECOND_CLASS_ASSET = "file")
load("images/rank_navy_e6_petty_officer_first_class.png", RANK_NAVY_E6_PETTY_OFFICER_FIRST_CLASS_ASSET = "file")
load("images/rank_navy_e7_chief_petty_officer.png", RANK_NAVY_E7_CHIEF_PETTY_OFFICER_ASSET = "file")
load("images/rank_navy_e8_senior_chief_petty_officer.png", RANK_NAVY_E8_SENIOR_CHIEF_PETTY_OFFICER_ASSET = "file")
load("images/rank_navy_e9_master_chief_petty_officer.png", RANK_NAVY_E9_MASTER_CHIEF_PETTY_OFFICER_ASSET = "file")
load("images/rank_navy_e9b_command_master_chief_petty_officer.png", RANK_NAVY_E9B_COMMAND_MASTER_CHIEF_PETTY_OFFICER_ASSET = "file")
load("images/rank_navy_e9c_master_chief_petty_officer_of_the_navy.png", RANK_NAVY_E9C_MASTER_CHIEF_PETTY_OFFICER_OF_THE_NAVY_ASSET = "file")
load("images/rank_navy_o10_admiral.png", RANK_NAVY_O10_ADMIRAL_ASSET = "file")
load("images/rank_navy_o11_fleet_admiral.png", RANK_NAVY_O11_FLEET_ADMIRAL_ASSET = "file")
load("images/rank_navy_o1_ensign.png", RANK_NAVY_O1_ENSIGN_ASSET = "file")
load("images/rank_navy_o2_lt__j_g.png", RANK_NAVY_O2_LT_J_G_ASSET = "file")
load("images/rank_navy_o3_lt.png", RANK_NAVY_O3_LT_ASSET = "file")
load("images/rank_navy_o4_lt_cmdr.png", RANK_NAVY_O4_LT_CMDR_ASSET = "file")
load("images/rank_navy_o5_cmdr.png", RANK_NAVY_O5_CMDR_ASSET = "file")
load("images/rank_navy_o6_captain.png", RANK_NAVY_O6_CAPTAIN_ASSET = "file")
load("images/rank_navy_o7_rear_adm.png", RANK_NAVY_O7_REAR_ADM_ASSET = "file")
load("images/rank_navy_o8_rear_adm.png", RANK_NAVY_O8_REAR_ADM_ASSET = "file")
load("images/rank_navy_o9_vice_adm.png", RANK_NAVY_O9_VICE_ADM_ASSET = "file")
load("images/rank_navy_w2_chief_warrant_officer_2.png", RANK_NAVY_W2_CHIEF_WARRANT_OFFICER_2_ASSET = "file")
load("images/rank_navy_w3_chief_warrant_officer_3.png", RANK_NAVY_W3_CHIEF_WARRANT_OFFICER_3_ASSET = "file")
load("images/rank_navy_w4_chief_warrant_officer_4.png", RANK_NAVY_W4_CHIEF_WARRANT_OFFICER_4_ASSET = "file")
load("images/rank_navy_w5_chief_warrant_officer_5.png", RANK_NAVY_W5_CHIEF_WARRANT_OFFICER_5_ASSET = "file")
load("images/rank_space_force_e1_spc.png", RANK_SPACE_FORCE_E1_SPC_ASSET = "file")
load("images/rank_space_force_e2_spc_2.png", RANK_SPACE_FORCE_E2_SPC_2_ASSET = "file")
load("images/rank_space_force_e3_spc_3.png", RANK_SPACE_FORCE_E3_SPC_3_ASSET = "file")
load("images/rank_space_force_e4_spc_4.png", RANK_SPACE_FORCE_E4_SPC_4_ASSET = "file")
load("images/rank_space_force_e5_sgt.png", RANK_SPACE_FORCE_E5_SGT_ASSET = "file")
load("images/rank_space_force_e6_technical_sergeant.png", RANK_SPACE_FORCE_E6_TECHNICAL_SERGEANT_ASSET = "file")
load("images/rank_space_force_e7_master_sergeant.png", RANK_SPACE_FORCE_E7_MASTER_SERGEANT_ASSET = "file")
load("images/rank_space_force_e8_senior_master_sergeant.png", RANK_SPACE_FORCE_E8_SENIOR_MASTER_SERGEANT_ASSET = "file")
load("images/rank_space_force_e9_chief_master_sergeant.png", RANK_SPACE_FORCE_E9_CHIEF_MASTER_SERGEANT_ASSET = "file")
load("images/rank_space_force_e9b_command_chief_master_sergeant.png", RANK_SPACE_FORCE_E9B_COMMAND_CHIEF_MASTER_SERGEANT_ASSET = "file")
load("images/rank_space_force_e9c_chief_master_sergeant_of_the_space_force.png", RANK_SPACE_FORCE_E9C_CHIEF_MASTER_SERGEANT_OF_THE_SPACE_FORCE_ASSET = "file")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

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
            "image": RANK_GENERIC_LOWEST_RANK_ASSET.readall(),
        },
        "E2": {
            "name": "Private Second Class",
            "height": "28",
            "width": "30",
            "image": RANK_ARMY_E2_PRIVATE_SECOND_CLASS_ASSET.readall(),
        },
        "E3": {
            "name": "Pfc.",
            "height": "28",
            "width": "23",
            "image": RANK_ARMY_E3_PFC_ASSET.readall(),
        },
        "E4": {
            "name": "Spc.",
            "height": "28",
            "width": "23",
            "image": RANK_ARMY_E4_SPC_ASSET.readall(),
        },
        "E4B": {
            "name": "Cpl.",
            "height": "28",
            "width": "023",
            "image": RANK_ARMY_E4B_CPL_ASSET.readall(),
        },
        "E5": {
            "name": "Sgt.",
            "height": "28",
            "width": "23",
            "image": RANK_ARMY_E5_SGT_ASSET.readall(),
        },
        "E6": {
            "name": "Staff Sergeant",
            "height": "32",
            "width": "23",
            "image": RANK_ARMY_E6_STAFF_SERGEANT_ASSET.readall(),
        },
        "E7": {
            "name": "Sergeant First Class",
            "height": "32",
            "width": "19",
            "image": RANK_ARMY_E7_SERGEANT_FIRST_CLASS_ASSET.readall(),
        },
        "E8": {
            "name": "Master Sergeant",
            "height": "32",
            "width": "18",
            "image": RANK_ARMY_E8_MASTER_SERGEANT_ASSET.readall(),
        },
        "E8B": {
            "name": "1st Sgt.",
            "height": "32",
            "width": "18",
            "image": RANK_ARMY_E8B_1ST_SGT_ASSET.readall(),
        },
        "E9": {
            "name": "Sgt.Maj.",
            "height": "32",
            "width": "18",
            "image": RANK_ARMY_E9_SGT_MAJ_ASSET.readall(),
        },
        "E9B": {
            "name": "Command Sergeant Major",
            "height": "32",
            "width": "18",
            "image": RANK_ARMY_E9B_COMMAND_SERGEANT_MAJOR_ASSET.readall(),
        },
        "E9C": {
            "name": "Sergeant Major of the Army",
            "height": "32",
            "width": "18",
            "image": RANK_ARMY_E9C_SERGEANT_MAJOR_OF_THE_ARMY_ASSET.readall(),
        },
        "W1": {
            "name": "Warrant Officer 1",
            "height": "32",
            "width": "10",
            "image": RANK_ARMY_W1_WARRANT_OFFICER_1_ASSET.readall(),
        },
        "W2": {
            "name": "Chief Warrant Officer 2",
            "height": "32",
            "width": "10",
            "image": RANK_ARMY_W2_CHIEF_WARRANT_OFFICER_2_ASSET.readall(),
        },
        "W3": {
            "name": "Chief Warrant Officer 3",
            "height": "32",
            "width": "10",
            "image": RANK_ARMY_W3_CHIEF_WARRANT_OFFICER_3_ASSET.readall(),
        },
        "W4": {
            "name": "Chief Warrant Officer 4",
            "height": "32",
            "width": "10",
            "image": RANK_ARMY_W4_CHIEF_WARRANT_OFFICER_4_ASSET.readall(),
        },
        "W5": {
            "name": "Chief Warrant Officer 5",
            "height": "32",
            "width": "10",
            "image": RANK_ARMY_W5_CHIEF_WARRANT_OFFICER_5_ASSET.readall(),
        },
        "O1": {
            "name": "2nd Lt.",
            "height": "32",
            "width": "13",
            "image": RANK_ARMY_O1_2ND_LT_ASSET.readall(),
        },
        "O2": {
            "name": "1st Lt.",
            "height": "32",
            "width": "013",
            "image": RANK_ARMY_O2_1ST_LT_ASSET.readall(),
        },
        "O3": {
            "name": "Captain",
            "height": "22",
            "width": "24",
            "image": RANK_ARMY_O3_CAPTAIN_ASSET.readall(),
        },
        "O4": {
            "name": "Major",
            "height": "18",
            "width": "18",
            "image": RANK_ARMY_O4_MAJOR_ASSET.readall(),
        },
        "O5": {
            "name": "Lt.Col.",
            "height": "18",
            "width": "18",
            "image": RANK_ARMY_O5_LT_COL_ASSET.readall(),
        },
        "O6": {
            "name": "Col.",
            "height": "16",
            "width": "32",
            "image": RANK_ARMY_O6_COL_ASSET.readall(),
        },
        "O7": {
            "name": "Brig.Gen.",
            "height": "16",
            "width": "18",
            "image": RANK_ARMY_O7_BRIG_GEN_ASSET.readall(),
        },
        "O8": {
            "name": "Maj.Gen.",
            "height": "16",
            "width": "18",
            "image": RANK_ARMY_O8_MAJ_GEN_ASSET.readall(),
        },
        "O9": {
            "name": "Lt.Gen.",
            "height": "16",
            "width": "18",
            "image": RANK_ARMY_O9_LT_GEN_ASSET.readall(),
        },
        "O10": {
            "name": "General",
            "height": "8",
            "width": "18",
            "image": RANK_ARMY_O10_GENERAL_ASSET.readall(),
        },
        "O10B": {
            "name": "General of the Army",
            "height": "16",
            "width": "18",
            "image": RANK_ARMY_O10B_GENERAL_OF_THE_ARMY_ASSET.readall(),
        },
    },
    "Air Force": {
        "E1": {
            "name": "Airman Basic",
            "height": "0",
            "width": "0",
            "image": RANK_GENERIC_LOWEST_RANK_ASSET.readall(),
        },
        "E2": {
            "name": "Airman",
            "height": "15",
            "width": "32",
            "image": RANK_AIR_FORCE_E2_AIRMAN_ASSET.readall(),
        },
        "E3": {
            "name": "Airman 1st Class",
            "height": "20",
            "width": "32",
            "image": RANK_AIR_FORCE_E3_AIRMAN_1ST_CLASS_ASSET.readall(),
        },
        "E4": {
            "name": "Senior Airman",
            "height": "20",
            "width": "32",
            "image": RANK_AIR_FORCE_E4_SENIOR_AIRMAN_ASSET.readall(),
        },
        "E5": {
            "name": "Staff Sgt.",
            "height": "20",
            "width": "32",
            "image": RANK_AIR_FORCE_E5_STAFF_SGT_ASSET.readall(),
        },
        "E6": {
            "name": "Technical Sergeant",
            "height": "28",
            "width": "32",
            "image": RANK_AIR_FORCE_E6_TECHNICAL_SERGEANT_ASSET.readall(),
        },
        "E7": {
            "name": "Master Sergeant",
            "height": "32",
            "width": "24",
            "image": RANK_AIR_FORCE_E7_MASTER_SERGEANT_ASSET.readall(),
        },
        "E8": {
            "name": "Senior Master Sergeant",
            "height": "32",
            "width": "22",
            "image": RANK_AIR_FORCE_E8_SENIOR_MASTER_SERGEANT_ASSET.readall(),
        },
        "E9": {
            "name": "Chief Master Sergeant",
            "height": "32",
            "width": "22",
            "image": RANK_AIR_FORCE_E9_CHIEF_MASTER_SERGEANT_ASSET.readall(),
        },
        "E9B": {
            "name": "Command Chief Master Sergeant",
            "height": "32",
            "width": "22",
            "image": RANK_AIR_FORCE_E9B_COMMAND_CHIEF_MASTER_SERGEANT_ASSET.readall(),
        },
        "E9C": {
            "name": "Chief Master Sergeant of the Air Force",
            "height": "32",
            "width": "22",
            "image": RANK_AIR_FORCE_E9C_CHIEF_MASTER_SERGEANT_OF_THE_AIR_FORCE_ASSET.readall(),
        },
        "O1": {
            "name": "2nd Lt.",
            "height": "32",
            "width": "13",
            "image": RANK_ARMY_O1_2ND_LT_ASSET.readall(),
        },
        "O2": {
            "name": "1st Lt.",
            "height": "32",
            "width": "13",
            "image": RANK_ARMY_O2_1ST_LT_ASSET.readall(),
        },
        "O3": {
            "name": "Captain",
            "height": "16",
            "width": "18",
            "image": RANK_ARMY_O3_CAPTAIN_ASSET.readall(),
        },
        "O4": {
            "name": "Major",
            "height": "16",
            "width": "18",
            "image": RANK_ARMY_O4_MAJOR_ASSET.readall(),
        },
        "O5": {
            "name": "Lt. Col.",
            "height": "16",
            "width": "18",
            "image": RANK_ARMY_O5_LT_COL_ASSET.readall(),
        },
        "O6": {
            "name": "Col.",
            "height": "16",
            "width": "32",
            "image": RANK_ARMY_O6_COL_ASSET.readall(),
        },
        "O7": {
            "name": "Brig.Gen.",
            "height": "16",
            "width": "18",
            "image": RANK_ARMY_O7_BRIG_GEN_ASSET.readall(),
        },
        "O8": {
            "name": "Maj.Gen.",
            "height": "8",
            "width": "18",
            "image": RANK_ARMY_O8_MAJ_GEN_ASSET.readall(),
        },
        "O9": {
            "name": "Lt. Gen.",
            "height": "8",
            "width": "18",
            "image": RANK_ARMY_O9_LT_GEN_ASSET.readall(),
        },
        "O10": {
            "name": "General",
            "height": "8",
            "width": "22",
            "image": RANK_ARMY_O10_GENERAL_ASSET.readall(),
        },
        "O10B": {
            "name": "General of the Air Force",
            "height": "20",
            "width": "22",
            "image": RANK_ARMY_O10B_GENERAL_OF_THE_ARMY_ASSET.readall(),
        },
    },
    "Space Force": {
        "E0": {
            "name": "Specialist Trainee",
            "height": "32",
            "width": "18",
            "image": RANK_GENERIC_LOWEST_RANK_ASSET.readall(),
        },
        "E1": {
            "name": "Spc.",
            "height": "20",
            "width": "18",
            "image": RANK_SPACE_FORCE_E1_SPC_ASSET.readall(),
        },
        "E2": {
            "name": "Spc.2",
            "height": "20",
            "width": "18",
            "image": RANK_SPACE_FORCE_E2_SPC_2_ASSET.readall(),
        },
        "E3": {
            "name": "Spc.3",
            "height": "20",
            "width": "18",
            "image": RANK_SPACE_FORCE_E3_SPC_3_ASSET.readall(),
        },
        "E4": {
            "name": "Spc.4",
            "height": "20",
            "width": "18",
            "image": RANK_SPACE_FORCE_E4_SPC_4_ASSET.readall(),
        },
        "E5": {
            "name": "Sgt.",
            "height": "22",
            "width": "18",
            "image": RANK_SPACE_FORCE_E5_SGT_ASSET.readall(),
        },
        "E6": {
            "name": "Technical Sergeant",
            "height": "28",
            "width": "18",
            "image": RANK_SPACE_FORCE_E6_TECHNICAL_SERGEANT_ASSET.readall(),
        },
        "E7": {
            "name": "Master Sergeant",
            "height": "28",
            "width": "18",
            "image": RANK_SPACE_FORCE_E7_MASTER_SERGEANT_ASSET.readall(),
        },
        "E8": {
            "name": "Senior Master Sergeant",
            "height": "30",
            "width": "18",
            "image": RANK_SPACE_FORCE_E8_SENIOR_MASTER_SERGEANT_ASSET.readall(),
        },
        "E9": {
            "name": "Chief Master Sergeant",
            "height": "30",
            "width": "18",
            "image": RANK_SPACE_FORCE_E9_CHIEF_MASTER_SERGEANT_ASSET.readall(),
        },
        "E9B": {
            "name": "Command Chief Master Sergeant",
            "height": "30",
            "width": "18",
            "image": RANK_SPACE_FORCE_E9B_COMMAND_CHIEF_MASTER_SERGEANT_ASSET.readall(),
        },
        "E9C": {
            "name": "Chief Master Sergeant of the Space Force",
            "height": "30",
            "width": "18",
            "image": RANK_SPACE_FORCE_E9C_CHIEF_MASTER_SERGEANT_OF_THE_SPACE_FORCE_ASSET.readall(),
        },
        "O1": {
            "name": "2nd.Lt.",
            "height": "32",
            "width": "13",
            "image": RANK_ARMY_O1_2ND_LT_ASSET.readall(),
        },
        "O2": {
            "name": "1st.Lt.",
            "height": "32",
            "width": "13",
            "image": RANK_ARMY_O2_1ST_LT_ASSET.readall(),
        },
        "O3": {
            "name": "Captain",
            "height": "16",
            "width": "18",
            "image": RANK_ARMY_O3_CAPTAIN_ASSET.readall(),
        },
        "O4": {
            "name": "Major",
            "height": "16",
            "width": "18",
            "image": RANK_ARMY_O4_MAJOR_ASSET.readall(),
        },
        "O5": {
            "name": "Lt.Col.",
            "height": "16",
            "width": "18",
            "image": RANK_ARMY_O5_LT_COL_ASSET.readall(),
        },
        "O6": {
            "name": "Col.",
            "height": "16",
            "width": "32",
            "image": RANK_ARMY_O6_COL_ASSET.readall(),
        },
        "O7": {
            "name": "Brig.Gen.",
            "height": "16",
            "width": "18",
            "image": RANK_ARMY_O7_BRIG_GEN_ASSET.readall(),
        },
        "O8": {
            "name": "Maj.Gen.",
            "height": "10",
            "width": "18",
            "image": RANK_ARMY_O8_MAJ_GEN_ASSET.readall(),
        },
        "O9": {
            "name": "Lt.Gen.",
            "height": "10",
            "width": "18",
            "image": RANK_ARMY_O9_LT_GEN_ASSET.readall(),
        },
        "O10": {
            "name": "General",
            "height": "10",
            "width": "22",
            "image": RANK_ARMY_O10_GENERAL_ASSET.readall(),
        },
        "O10B": {
            "name": "General of the Air Force",
            "height": "20",
            "width": "22",
            "image": RANK_ARMY_O10B_GENERAL_OF_THE_ARMY_ASSET.readall(),
        },
    },
    "Marines": {
        "E1": {
            "name": "Pvt.",
            "height": "1",
            "width": "1",
            "image": RANK_GENERIC_LOWEST_RANK_ASSET.readall(),
        },
        "E2": {
            "name": "Pfc.",
            "height": "21",
            "width": "32",
            "image": RANK_MARINES_E2_PFC_ASSET.readall(),
        },
        "E3": {
            "name": "Lance Cpl.",
            "height": "20",
            "width": "32",
            "image": RANK_MARINES_E3_LANCE_CPL_ASSET.readall(),
        },
        "E4": {
            "name": "Cpl.",
            "height": "32",
            "width": "28",
            "image": RANK_MARINES_E4_CPL_ASSET.readall(),
        },
        "E5": {
            "name": "Sgt.",
            "height": "32",
            "width": "28",
            "image": RANK_MARINES_E5_SGT_ASSET.readall(),
        },
        "E6": {
            "name": "Staff Sergeant",
            "height": "32",
            "width": "18",
            "image": RANK_MARINES_E6_STAFF_SERGEANT_ASSET.readall(),
        },
        "E7": {
            "name": "Gunnery Sergeant",
            "height": "32",
            "width": "18",
            "image": RANK_MARINES_E7_GUNNERY_SERGEANT_ASSET.readall(),
        },
        "E8": {
            "name": "Master Sergeant",
            "height": "32",
            "width": "18",
            "image": RANK_MARINES_E8_MASTER_SERGEANT_ASSET.readall(),
        },
        "E8B": {
            "name": "1st.Sgt.",
            "height": "32",
            "width": "18",
            "image": RANK_MARINES_E8B_1ST_SGT_ASSET.readall(),
        },
        "E9": {
            "name": "Master Gunnery Sergeant",
            "height": "32",
            "width": "18",
            "image": RANK_MARINES_E9_MASTER_GUNNERY_SERGEANT_ASSET.readall(),
        },
        "E9B": {
            "name": "Sgt.Maj.",
            "height": "32",
            "width": "18",
            "image": RANK_MARINES_E9B_SGT_MAJ_ASSET.readall(),
        },
        "E9C": {
            "name": "Sergeant Major of the Marine Corps",
            "height": "32",
            "width": "18",
            "image": RANK_MARINES_E9C_SERGEANT_MAJOR_OF_THE_MARINE_CORPS_ASSET.readall(),
        },
        "W1": {
            "name": "Warrant Officer 1",
            "height": "32",
            "width": "10",
            "image": RANK_MARINES_W1_WARRANT_OFFICER_1_ASSET.readall(),
        },
        "W2": {
            "name": "Chief Warrant Officer 2",
            "height": "32",
            "width": "10",
            "image": RANK_MARINES_W2_CHIEF_WARRANT_OFFICER_2_ASSET.readall(),
        },
        "W3": {
            "name": "Chief Warrant Officer 3",
            "height": "32",
            "width": "10",
            "image": RANK_MARINES_W3_CHIEF_WARRANT_OFFICER_3_ASSET.readall(),
        },
        "W4": {
            "name": "Chief Warrant Officer 4",
            "height": "32",
            "width": "10",
            "image": RANK_MARINES_W4_CHIEF_WARRANT_OFFICER_4_ASSET.readall(),
        },
        "W5": {
            "name": "Chief Warrant Officer 5",
            "height": "32",
            "width": "10",
            "image": RANK_MARINES_W5_CHIEF_WARRANT_OFFICER_5_ASSET.readall(),
        },
        "O1": {
            "name": "2nd.Lt.",
            "height": "32",
            "width": "10",
            "image": RANK_ARMY_O1_2ND_LT_ASSET.readall(),
        },
        "O2": {
            "name": "1st.Lt.",
            "height": "32",
            "width": "10",
            "image": RANK_ARMY_O2_1ST_LT_ASSET.readall(),
        },
        "O3": {
            "name": "Captain",
            "height": "22",
            "width": "24",
            "image": RANK_ARMY_O3_CAPTAIN_ASSET.readall(),
        },
        "O4": {
            "name": "Major",
            "height": "18",
            "width": "18",
            "image": RANK_ARMY_O4_MAJOR_ASSET.readall(),
        },
        "O5": {
            "name": "Lt.Col.",
            "height": "18",
            "width": "18",
            "image": RANK_ARMY_O5_LT_COL_ASSET.readall(),
        },
        "O6": {
            "name": "Col.",
            "height": "16",
            "width": "32",
            "image": RANK_ARMY_O6_COL_ASSET.readall(),
        },
        "O7": {
            "name": "Brigadier General",
            "height": "22",
            "width": "24",
            "image": RANK_ARMY_O7_BRIG_GEN_ASSET.readall(),
        },
        "O8": {
            "name": "Maj.Gen",
            "height": "10",
            "width": "24",
            "image": RANK_ARMY_O8_MAJ_GEN_ASSET.readall(),
        },
        "O9": {
            "name": "Lt.Gen",
            "height": "8",
            "width": "24",
            "image": RANK_ARMY_O9_LT_GEN_ASSET.readall(),
        },
        "O10": {
            "name": "General",
            "height": "8",
            "width": "24",
            "image": RANK_ARMY_O10_GENERAL_ASSET.readall(),
        },
    },
    "Navy": {
        "E1": {
            "name": "Seaman Recruit",
            "height": "1",
            "width": "1",
            "image": RANK_GENERIC_LOWEST_RANK_ASSET.readall(),
        },
        "E2": {
            "name": "Seaman Apprentice",
            "height": "32",
            "width": "30",
            "image": RANK_NAVY_E2_SEAMAN_APPRENTICE_ASSET.readall(),
        },
        "E3": {
            "name": "Seaman",
            "height": "32",
            "width": "30",
            "image": RANK_NAVY_E3_SEAMAN_ASSET.readall(),
        },
        "E4": {
            "name": "Petty Officer Third Class",
            "height": "32",
            "width": "30",
            "image": RANK_NAVY_E4_PETTY_OFFICER_THIRD_CLASS_ASSET.readall(),
        },
        "E5": {
            "name": "Petty Officer Second Class",
            "height": "32",
            "width": "24",
            "image": RANK_NAVY_E5_PETTY_OFFICER_SECOND_CLASS_ASSET.readall(),
        },
        "E6": {
            "name": "Petty Officer First Class",
            "height": "32",
            "width": "20",
            "image": RANK_NAVY_E6_PETTY_OFFICER_FIRST_CLASS_ASSET.readall(),
        },
        "E7": {
            "name": "Chief Petty Officer",
            "height": "32",
            "width": "20",
            "image": RANK_NAVY_E7_CHIEF_PETTY_OFFICER_ASSET.readall(),
        },
        "E8": {
            "name": "Senior Chief Petty Officer",
            "height": "32",
            "width": "20",
            "image": RANK_NAVY_E8_SENIOR_CHIEF_PETTY_OFFICER_ASSET.readall(),
        },
        "E9": {
            "name": "Master Chief Petty Officer",
            "height": "32",
            "width": "18",
            "image": RANK_NAVY_E9_MASTER_CHIEF_PETTY_OFFICER_ASSET.readall(),
        },
        "E9B": {
            "name": "Command Master Chief Petty Officer",
            "height": "32",
            "width": "18",
            "image": RANK_NAVY_E9B_COMMAND_MASTER_CHIEF_PETTY_OFFICER_ASSET.readall(),
        },
        "E9C": {
            "name": "Master Chief Petty Officer of the Navy",
            "height": "32",
            "width": "18",
            "image": RANK_NAVY_E9C_MASTER_CHIEF_PETTY_OFFICER_OF_THE_NAVY_ASSET.readall(),
        },
        "W2": {
            "name": "Chief Warrant Officer 2",
            "height": "32",
            "width": "18",
            "image": RANK_NAVY_W2_CHIEF_WARRANT_OFFICER_2_ASSET.readall(),
        },
        "W3": {
            "name": "Chief Warrant Officer 3",
            "height": "32",
            "width": "18",
            "image": RANK_NAVY_W3_CHIEF_WARRANT_OFFICER_3_ASSET.readall(),
        },
        "W4": {
            "name": "Chief Warrant Officer 4",
            "height": "32",
            "width": "18",
            "image": RANK_NAVY_W4_CHIEF_WARRANT_OFFICER_4_ASSET.readall(),
        },
        "W5": {
            "name": "Chief Warrant Officer 5",
            "height": "32",
            "width": "18",
            "image": RANK_NAVY_W5_CHIEF_WARRANT_OFFICER_5_ASSET.readall(),
        },
        "O1": {
            "name": "Ensign",
            "height": "32",
            "width": "20",
            "image": RANK_NAVY_O1_ENSIGN_ASSET.readall(),
        },
        "O2": {
            "name": "Lt. j.g.",
            "height": "32",
            "width": "20",
            "image": RANK_NAVY_O2_LT_J_G_ASSET.readall(),
        },
        "O3": {
            "name": "Lt.",
            "height": "32",
            "width": "20",
            "image": RANK_NAVY_O3_LT_ASSET.readall(),
        },
        "O4": {
            "name": "Lt.Cmdr.",
            "height": "32",
            "width": "20",
            "image": RANK_NAVY_O4_LT_CMDR_ASSET.readall(),
        },
        "O5": {
            "name": "Cmdr.",
            "height": "32",
            "width": "20",
            "image": RANK_NAVY_O5_CMDR_ASSET.readall(),
        },
        "O6": {
            "name": "Captain",
            "height": "32",
            "width": "20",
            "image": RANK_NAVY_O6_CAPTAIN_ASSET.readall(),
        },
        "O7": {
            "name": "Rear Adm.",
            "height": "32",
            "width": "20",
            "image": RANK_NAVY_O7_REAR_ADM_ASSET.readall(),
        },
        "O8": {
            "name": "Rear Adm.",
            "height": "32",
            "width": "20",
            "image": RANK_NAVY_O8_REAR_ADM_ASSET.readall(),
        },
        "O9": {
            "name": "Vice Adm",
            "height": "32",
            "width": "20",
            "image": RANK_NAVY_O9_VICE_ADM_ASSET.readall(),
        },
        "O10": {
            "name": "Admiral",
            "height": "32",
            "width": "20",
            "image": RANK_NAVY_O10_ADMIRAL_ASSET.readall(),
        },
        "O11": {
            "name": "Fleet Admiral",
            "height": "32",
            "width": "20",
            "image": RANK_NAVY_O11_FLEET_ADMIRAL_ASSET.readall(),
        },
    },
    "Coast Guard": {
        "E1": {
            "name": "Seaman Recruit",
            "height": "1",
            "width": "1",
            "image": RANK_GENERIC_LOWEST_RANK_ASSET.readall(),
        },
        "E2": {
            "name": "Seaman Apprentice",
            "height": "32",
            "width": "30",
            "image": RANK_NAVY_E2_SEAMAN_APPRENTICE_ASSET.readall(),
        },
        "E3": {
            "name": "Seaman",
            "height": "32",
            "width": "30",
            "image": RANK_NAVY_E3_SEAMAN_ASSET.readall(),
        },
        "E4": {
            "name": "Petty Officer Third Class",
            "height": "32",
            "width": "30",
            "image": RANK_NAVY_E4_PETTY_OFFICER_THIRD_CLASS_ASSET.readall(),
        },
        "E5": {
            "name": "Petty Officer Second Class",
            "height": "32",
            "width": "30",
            "image": RANK_NAVY_E5_PETTY_OFFICER_SECOND_CLASS_ASSET.readall(),
        },
        "E6": {
            "name": "Petty Officer First Class",
            "height": "32",
            "width": "30",
            "image": RANK_NAVY_E6_PETTY_OFFICER_FIRST_CLASS_ASSET.readall(),
        },
        "E7": {
            "name": "Chief Petty Officer",
            "height": "32",
            "width": "20",
            "image": RANK_NAVY_E7_CHIEF_PETTY_OFFICER_ASSET.readall(),
        },
        "E8": {
            "name": "Senior Chief Petty Officer",
            "height": "32",
            "width": "20",
            "image": RANK_NAVY_E8_SENIOR_CHIEF_PETTY_OFFICER_ASSET.readall(),
        },
        "E9": {
            "name": "Master Chief Petty Officer",
            "height": "32",
            "width": "20",
            "image": RANK_NAVY_E9_MASTER_CHIEF_PETTY_OFFICER_ASSET.readall(),
        },
        "E9B": {
            "name": "Command Master Chief Petty Officer",
            "height": "32",
            "width": "20",
            "image": RANK_NAVY_E9B_COMMAND_MASTER_CHIEF_PETTY_OFFICER_ASSET.readall(),
        },
        "E9C": {
            "name": "Master Chief Petty Officer of the Navy",
            "height": "32",
            "width": "20",
            "image": RANK_NAVY_E9C_MASTER_CHIEF_PETTY_OFFICER_OF_THE_NAVY_ASSET.readall(),
        },
        "W2": {
            "name": "Chief Warrant Officer 2",
            "height": "32",
            "width": "18",
            "image": RANK_NAVY_W2_CHIEF_WARRANT_OFFICER_2_ASSET.readall(),
        },
        "W3": {
            "name": "Chief Warrant Officer 3",
            "height": "32",
            "width": "18",
            "image": RANK_NAVY_W3_CHIEF_WARRANT_OFFICER_3_ASSET.readall(),
        },
        "W4": {
            "name": "Chief Warrant Officer 4",
            "height": "32",
            "width": "18",
            "image": RANK_NAVY_W4_CHIEF_WARRANT_OFFICER_4_ASSET.readall(),
        },
        "W5": {
            "name": "Chief Warrant Officer 5",
            "height": "32",
            "width": "18",
            "image": RANK_NAVY_W5_CHIEF_WARRANT_OFFICER_5_ASSET.readall(),
        },
        "O1": {
            "name": "Ensign",
            "height": "32",
            "width": "20",
            "image": RANK_NAVY_O1_ENSIGN_ASSET.readall(),
        },
        "O2": {
            "name": "Lt. j.g.",
            "height": "32",
            "width": "20",
            "image": RANK_NAVY_O2_LT_J_G_ASSET.readall(),
        },
        "O3": {
            "name": "Lt.",
            "height": "32",
            "width": "20",
            "image": RANK_NAVY_O3_LT_ASSET.readall(),
        },
        "O4": {
            "name": "Lt.Cmdr.",
            "height": "32",
            "width": "20",
            "image": RANK_NAVY_O4_LT_CMDR_ASSET.readall(),
        },
        "O5": {
            "name": "Cmdr.",
            "height": "32",
            "width": "20",
            "image": RANK_NAVY_O5_CMDR_ASSET.readall(),
        },
        "O6": {
            "name": "Captain",
            "height": "32",
            "width": "20",
            "image": RANK_NAVY_O6_CAPTAIN_ASSET.readall(),
        },
        "O7": {
            "name": "Rear Adm.",
            "height": "32",
            "width": "20",
            "image": RANK_NAVY_O7_REAR_ADM_ASSET.readall(),
        },
        "O8": {
            "name": "Rear Adm.",
            "height": "32",
            "width": "20",
            "image": RANK_NAVY_O8_REAR_ADM_ASSET.readall(),
        },
        "O9": {
            "name": "Vice Adm.",
            "height": "32",
            "width": "20",
            "image": RANK_NAVY_O9_VICE_ADM_ASSET.readall(),
        },
        "O10": {
            "name": "Admiral",
            "height": "32",
            "width": "20",
            "image": RANK_NAVY_O10_ADMIRAL_ASSET.readall(),
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
    selectedImage = selectedRank["image"]
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
