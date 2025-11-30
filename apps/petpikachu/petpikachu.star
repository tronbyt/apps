"""
Applet: Pet Pikachu
Summary: Virtual pet Pikachu
Description: Based on the Pokémon Pikachu virtual pet from the 90s
Author: Kyle Stark @kaisle51
Thanks: Code usage: Steve Otteson. Sprite source: https://www.youtube.com/watch?v=RCL1iwIU57k
"""

load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("images/backflip_1_a83ad8d8.png", BACKFLIP_1_a83ad8d8_ASSET = "file")
load("images/backflip_2_d49d16e9.png", BACKFLIP_2_d49d16e9_ASSET = "file")
load("images/backflip_3_e66be6d2.png", BACKFLIP_3_e66be6d2_ASSET = "file")
load("images/backflip_4_84ec8814.png", BACKFLIP_4_84ec8814_ASSET = "file")
load("images/bathe_1_e18e4650.png", BATHE_1_e18e4650_ASSET = "file")
load("images/bathe_2_8d7e1a3d.png", BATHE_2_8d7e1a3d_ASSET = "file")
load("images/bathe_3_dd22c92b.png", BATHE_3_dd22c92b_ASSET = "file")
load("images/bathe_4_aee7e390.png", BATHE_4_aee7e390_ASSET = "file")
load("images/bike_1_0ba2a639.png", BIKE_1_0ba2a639_ASSET = "file")
load("images/bike_2_6e8609df.png", BIKE_2_6e8609df_ASSET = "file")
load("images/bike_3_d0527603.png", BIKE_3_d0527603_ASSET = "file")
load("images/bike_4_cfd13b67.png", BIKE_4_cfd13b67_ASSET = "file")
load("images/brush_1_26e6ed9e.png", BRUSH_1_26e6ed9e_ASSET = "file")
load("images/brush_2_217507e3.png", BRUSH_2_217507e3_ASSET = "file")
load("images/build_1_f0ffb00d.png", BUILD_1_f0ffb00d_ASSET = "file")
load("images/build_2_b72e8f51.png", BUILD_2_b72e8f51_ASSET = "file")
load("images/build_3_434d6c86.png", BUILD_3_434d6c86_ASSET = "file")
load("images/build_4_59413faa.png", BUILD_4_59413faa_ASSET = "file")
load("images/build_5_ed028d81.png", BUILD_5_ed028d81_ASSET = "file")
load("images/cheer_1_4847d673.png", CHEER_1_4847d673_ASSET = "file")
load("images/cheer_2_bf2931db.png", CHEER_2_bf2931db_ASSET = "file")
load("images/cheer_3_456cb381.png", CHEER_3_456cb381_ASSET = "file")
load("images/chillmag_10_5139930c.png", CHILLMAG_10_5139930c_ASSET = "file")
load("images/chillmag_11_b6d879ea.png", CHILLMAG_11_b6d879ea_ASSET = "file")
load("images/chillmag_12_7e0d932c.png", CHILLMAG_12_7e0d932c_ASSET = "file")
load("images/chillmag_13_4c309533.png", CHILLMAG_13_4c309533_ASSET = "file")
load("images/chillmag_1_d742faf5.png", CHILLMAG_1_d742faf5_ASSET = "file")
load("images/chillmag_2_1285d76c.png", CHILLMAG_2_1285d76c_ASSET = "file")
load("images/chillmag_3_6b041bdf.png", CHILLMAG_3_6b041bdf_ASSET = "file")
load("images/chillmag_4_697c5ad3.png", CHILLMAG_4_697c5ad3_ASSET = "file")
load("images/chillmag_5_84cd4b16.png", CHILLMAG_5_84cd4b16_ASSET = "file")
load("images/chillmag_6_48d94a0f.png", CHILLMAG_6_48d94a0f_ASSET = "file")
load("images/chillmag_7_a9c539ff.png", CHILLMAG_7_a9c539ff_ASSET = "file")
load("images/chillmag_8_e5db64a0.png", CHILLMAG_8_e5db64a0_ASSET = "file")
load("images/chillmag_9_6adfb211.png", CHILLMAG_9_6adfb211_ASSET = "file")
load("images/compute_1_d72afb6d.png", COMPUTE_1_d72afb6d_ASSET = "file")
load("images/compute_2_879e2a2e.png", COMPUTE_2_879e2a2e_ASSET = "file")
load("images/compute_3_5e3c9b0a.png", COMPUTE_3_5e3c9b0a_ASSET = "file")
load("images/desksleep_1_628444ec.png", DESKSLEEP_1_628444ec_ASSET = "file")
load("images/desksleep_2_d4c520ca.png", DESKSLEEP_2_d4c520ca_ASSET = "file")
load("images/desksleep_3_e768b8ec.png", DESKSLEEP_3_e768b8ec_ASSET = "file")
load("images/drive_10_22696a79.png", DRIVE_10_22696a79_ASSET = "file")
load("images/drive_11_6b2a4895.png", DRIVE_11_6b2a4895_ASSET = "file")
load("images/drive_12_66a06e5e.png", DRIVE_12_66a06e5e_ASSET = "file")
load("images/drive_13_21c93ffd.png", DRIVE_13_21c93ffd_ASSET = "file")
load("images/drive_14_87c314fa.png", DRIVE_14_87c314fa_ASSET = "file")
load("images/drive_1_2e74f7a9.png", DRIVE_1_2e74f7a9_ASSET = "file")
load("images/drive_2_9b42a4a2.png", DRIVE_2_9b42a4a2_ASSET = "file")
load("images/drive_3_abc38ce7.png", DRIVE_3_abc38ce7_ASSET = "file")
load("images/drive_4_3806ef35.png", DRIVE_4_3806ef35_ASSET = "file")
load("images/drive_5_0cd7d9dd.png", DRIVE_5_0cd7d9dd_ASSET = "file")
load("images/drive_6_6fec488c.png", DRIVE_6_6fec488c_ASSET = "file")
load("images/drive_7_5bf95f8d.png", DRIVE_7_5bf95f8d_ASSET = "file")
load("images/drive_8_51d1b44e.png", DRIVE_8_51d1b44e_ASSET = "file")
load("images/drive_9_0501b976.png", DRIVE_9_0501b976_ASSET = "file")
load("images/eat_1_d68098a4.png", EAT_1_d68098a4_ASSET = "file")
load("images/eat_2_34260630.png", EAT_2_34260630_ASSET = "file")
load("images/eat_3_e299f69d.png", EAT_3_e299f69d_ASSET = "file")
load("images/eatdonut_1_0969f3c9.png", EATDONUT_1_0969f3c9_ASSET = "file")
load("images/eatdonut_2_2b22949c.png", EATDONUT_2_2b22949c_ASSET = "file")
load("images/eatdonut_3_3d052f56.png", EATDONUT_3_3d052f56_ASSET = "file")
load("images/eatrice_1_db9a81db.png", EATRICE_1_db9a81db_ASSET = "file")
load("images/eatrice_2_853f1268.png", EATRICE_2_853f1268_ASSET = "file")
load("images/eatrice_3_c9e8bcea.png", EATRICE_3_c9e8bcea_ASSET = "file")
load("images/glide_10_197a0f49.png", GLIDE_10_197a0f49_ASSET = "file")
load("images/glide_11_3dc6969b.png", GLIDE_11_3dc6969b_ASSET = "file")
load("images/glide_12_63014efe.png", GLIDE_12_63014efe_ASSET = "file")
load("images/glide_13_5308fca7.png", GLIDE_13_5308fca7_ASSET = "file")
load("images/glide_14_67d51803.png", GLIDE_14_67d51803_ASSET = "file")
load("images/glide_15_4cd08c3a.png", GLIDE_15_4cd08c3a_ASSET = "file")
load("images/glide_16_4c079a34.png", GLIDE_16_4c079a34_ASSET = "file")
load("images/glide_17_1a4d4275.png", GLIDE_17_1a4d4275_ASSET = "file")
load("images/glide_18_9139ed1c.png", GLIDE_18_9139ed1c_ASSET = "file")
load("images/glide_19_0b725825.png", GLIDE_19_0b725825_ASSET = "file")
load("images/glide_20_c9ea392d.png", GLIDE_20_c9ea392d_ASSET = "file")
load("images/glide_21_837ced02.png", GLIDE_21_837ced02_ASSET = "file")
load("images/glide_22_a1be338b.png", GLIDE_22_a1be338b_ASSET = "file")
load("images/glide_2_94180ca2.png", GLIDE_2_94180ca2_ASSET = "file")
load("images/glide_3_975472de.png", GLIDE_3_975472de_ASSET = "file")
load("images/glide_4_ed824933.png", GLIDE_4_ed824933_ASSET = "file")
load("images/glide_5_fdb66079.png", GLIDE_5_fdb66079_ASSET = "file")
load("images/glide_6_dc5d7190.png", GLIDE_6_dc5d7190_ASSET = "file")
load("images/glide_7_f6e9f9db.png", GLIDE_7_f6e9f9db_ASSET = "file")
load("images/glide_8_0640e25d.png", GLIDE_8_0640e25d_ASSET = "file")
load("images/glide_9_1d95cbe0.png", GLIDE_9_1d95cbe0_ASSET = "file")
load("images/kite_10_2253ecd3.png", KITE_10_2253ecd3_ASSET = "file")
load("images/kite_11_2e74e6a2.png", KITE_11_2e74e6a2_ASSET = "file")
load("images/kite_12_d5e60b3e.png", KITE_12_d5e60b3e_ASSET = "file")
load("images/kite_13_8fca9358.png", KITE_13_8fca9358_ASSET = "file")
load("images/kite_14_0b8c8e9e.png", KITE_14_0b8c8e9e_ASSET = "file")
load("images/kite_15_b0359f6b.png", KITE_15_b0359f6b_ASSET = "file")
load("images/kite_16_2cef3f61.png", KITE_16_2cef3f61_ASSET = "file")
load("images/kite_1_545dfbca.png", KITE_1_545dfbca_ASSET = "file")
load("images/kite_2_64cec44d.png", KITE_2_64cec44d_ASSET = "file")
load("images/kite_3_16ae3347.png", KITE_3_16ae3347_ASSET = "file")
load("images/kite_4_f8370e13.png", KITE_4_f8370e13_ASSET = "file")
load("images/kite_5_0e722f39.png", KITE_5_0e722f39_ASSET = "file")
load("images/kite_6_74100d0c.png", KITE_6_74100d0c_ASSET = "file")
load("images/kite_7_1d12828b.png", KITE_7_1d12828b_ASSET = "file")
load("images/kite_8_e5999463.png", KITE_8_e5999463_ASSET = "file")
load("images/kite_9_cb036e63.png", KITE_9_cb036e63_ASSET = "file")
load("images/learn_1_cb22fc9e.png", LEARN_1_cb22fc9e_ASSET = "file")
load("images/learn_2_59728f0b.png", LEARN_2_59728f0b_ASSET = "file")
load("images/learn_3_e7c9a221.png", LEARN_3_e7c9a221_ASSET = "file")
load("images/learn_4_a5e46d7a.png", LEARN_4_a5e46d7a_ASSET = "file")
load("images/learn_5_6d4f3c1c.png", LEARN_5_6d4f3c1c_ASSET = "file")
load("images/learngeo_1_65a01508.png", LEARNGEO_1_65a01508_ASSET = "file")
load("images/learngeo_2_8c6246c9.png", LEARNGEO_2_8c6246c9_ASSET = "file")
load("images/learnwooper_1_ab1a573b.png", LEARNWOOPER_1_ab1a573b_ASSET = "file")
load("images/learnwooper_2_e1bc89f3.png", LEARNWOOPER_2_e1bc89f3_ASSET = "file")
load("images/learnwooper_3_5f1963c2.png", LEARNWOOPER_3_5f1963c2_ASSET = "file")
load("images/learnwooper_4_b0260b65.png", LEARNWOOPER_4_b0260b65_ASSET = "file")
load("images/learnwooper_5_b314f7c5.png", LEARNWOOPER_5_b314f7c5_ASSET = "file")
load("images/learnwooper_6_9ae22117.png", LEARNWOOPER_6_9ae22117_ASSET = "file")
load("images/lick_1_6b02209f.png", LICK_1_6b02209f_ASSET = "file")
load("images/lick_2_bf4d8b60.png", LICK_2_bf4d8b60_ASSET = "file")
load("images/lick_3_dc705eca.png", LICK_3_dc705eca_ASSET = "file")
load("images/love_1_61a9c1bc.png", LOVE_1_61a9c1bc_ASSET = "file")
load("images/love_2_d0017249.png", LOVE_2_d0017249_ASSET = "file")
load("images/love_3_589984b9.png", LOVE_3_589984b9_ASSET = "file")
load("images/piano_1_50d28994.png", PIANO_1_50d28994_ASSET = "file")
load("images/piano_2_f146ebee.png", PIANO_2_f146ebee_ASSET = "file")
load("images/read_1_69f1c5e7.png", READ_1_69f1c5e7_ASSET = "file")
load("images/read_2_e98c036f.png", READ_2_e98c036f_ASSET = "file")
load("images/read_3_7db2a4d2.png", READ_3_7db2a4d2_ASSET = "file")
load("images/shovel_1_693d5fcc.png", SHOVEL_1_693d5fcc_ASSET = "file")
load("images/shovel_2_f9bde391.png", SHOVEL_2_f9bde391_ASSET = "file")
load("images/shower_1_d55988e9.png", SHOWER_1_d55988e9_ASSET = "file")
load("images/shower_2_0b515e26.png", SHOWER_2_0b515e26_ASSET = "file")
load("images/shower_3_9baeec6e.png", SHOWER_3_9baeec6e_ASSET = "file")
load("images/shower_4_c000eb8e.png", SHOWER_4_c000eb8e_ASSET = "file")
load("images/skate_10_2e99102c.png", SKATE_10_2e99102c_ASSET = "file")
load("images/skate_11_ab9bab92.png", SKATE_11_ab9bab92_ASSET = "file")
load("images/skate_12_4c14bc69.png", SKATE_12_4c14bc69_ASSET = "file")
load("images/skate_13_f438fd47.png", SKATE_13_f438fd47_ASSET = "file")
load("images/skate_14_adf5d185.png", SKATE_14_adf5d185_ASSET = "file")
load("images/skate_15_3c7eff51.png", SKATE_15_3c7eff51_ASSET = "file")
load("images/skate_1_02303c20.png", SKATE_1_02303c20_ASSET = "file")
load("images/skate_2_3111a93c.png", SKATE_2_3111a93c_ASSET = "file")
load("images/skate_3_f18d650b.png", SKATE_3_f18d650b_ASSET = "file")
load("images/skate_4_32e49b3b.png", SKATE_4_32e49b3b_ASSET = "file")
load("images/skate_5_bd802635.png", SKATE_5_bd802635_ASSET = "file")
load("images/skate_6_12ac19d8.png", SKATE_6_12ac19d8_ASSET = "file")
load("images/skate_7_6e178182.png", SKATE_7_6e178182_ASSET = "file")
load("images/skate_8_7ef0de4d.png", SKATE_8_7ef0de4d_ASSET = "file")
load("images/skate_9_95672823.png", SKATE_9_95672823_ASSET = "file")
load("images/sleep_1_5a1aff77.png", SLEEP_1_5a1aff77_ASSET = "file")
load("images/sleep_2_ffb9db63.png", SLEEP_2_ffb9db63_ASSET = "file")
load("images/sleep_3_6cef0af5.png", SLEEP_3_6cef0af5_ASSET = "file")
load("images/sleep_4_a30f3e70.png", SLEEP_4_a30f3e70_ASSET = "file")
load("images/sleep_5_0e742a59.png", SLEEP_5_0e742a59_ASSET = "file")
load("images/suck_1_732d27e5.png", SUCK_1_732d27e5_ASSET = "file")
load("images/suck_2_9665fe9f.png", SUCK_2_9665fe9f_ASSET = "file")
load("images/suck_3_ce026312.png", SUCK_3_ce026312_ASSET = "file")
load("images/swim_1_3f2d5589.png", SWIM_1_3f2d5589_ASSET = "file")
load("images/swim_2_823e59f2.png", SWIM_2_823e59f2_ASSET = "file")
load("images/swim_3_21adcc31.png", SWIM_3_21adcc31_ASSET = "file")
load("images/swim_4_d6a0c76c.png", SWIM_4_d6a0c76c_ASSET = "file")
load("images/swim_5_51e8401f.png", SWIM_5_51e8401f_ASSET = "file")
load("images/swim_6_0f205d75.png", SWIM_6_0f205d75_ASSET = "file")
load("images/swim_7_a5945162.png", SWIM_7_a5945162_ASSET = "file")
load("images/swim_8_783b64e6.png", SWIM_8_783b64e6_ASSET = "file")
load("images/swim_9_3b8e7f84.png", SWIM_9_3b8e7f84_ASSET = "file")
load("images/tease_1_de1d5618.png", TEASE_1_de1d5618_ASSET = "file")
load("images/tease_2_62896fc3.png", TEASE_2_62896fc3_ASSET = "file")
load("images/tease_3_12fa3191.png", TEASE_3_12fa3191_ASSET = "file")
load("images/tease_4_20e720a1.png", TEASE_4_20e720a1_ASSET = "file")
load("images/toot_10_3f28ccb1.png", TOOT_10_3f28ccb1_ASSET = "file")
load("images/toot_11_5a898064.png", TOOT_11_5a898064_ASSET = "file")
load("images/toot_12_13a014c8.png", TOOT_12_13a014c8_ASSET = "file")
load("images/toot_13_470ee3ce.png", TOOT_13_470ee3ce_ASSET = "file")
load("images/toot_14_718326bc.png", TOOT_14_718326bc_ASSET = "file")
load("images/toot_15_0689e4b7.png", TOOT_15_0689e4b7_ASSET = "file")
load("images/toot_16_af6776f9.png", TOOT_16_af6776f9_ASSET = "file")
load("images/toot_1_485f7325.png", TOOT_1_485f7325_ASSET = "file")
load("images/toot_2_fa4944a6.png", TOOT_2_fa4944a6_ASSET = "file")
load("images/toot_3_aa6b0825.png", TOOT_3_aa6b0825_ASSET = "file")
load("images/toot_4_7460228b.png", TOOT_4_7460228b_ASSET = "file")
load("images/toot_5_179944a3.png", TOOT_5_179944a3_ASSET = "file")
load("images/toot_6_1e8b0a2f.png", TOOT_6_1e8b0a2f_ASSET = "file")
load("images/toot_7_62eb7620.png", TOOT_7_62eb7620_ASSET = "file")
load("images/toot_8_c37fdf1b.png", TOOT_8_c37fdf1b_ASSET = "file")
load("images/toot_9_d8f3ccac.png", TOOT_9_d8f3ccac_ASSET = "file")
load("images/unicycle_1_cddfa574.png", UNICYCLE_1_cddfa574_ASSET = "file")
load("images/unicycle_2_49b601dd.png", UNICYCLE_2_49b601dd_ASSET = "file")
load("images/unicycle_3_bb667ad8.png", UNICYCLE_3_bb667ad8_ASSET = "file")
load("images/unicycle_4_614ef2b5.png", UNICYCLE_4_614ef2b5_ASSET = "file")
load("images/unicycle_5_7b6efca8.png", UNICYCLE_5_7b6efca8_ASSET = "file")
load("images/wail_1_549133a3.png", WAIL_1_549133a3_ASSET = "file")
load("images/wail_2_dba63f5a.png", WAIL_2_dba63f5a_ASSET = "file")
load("images/wail_3_841adb16.png", WAIL_3_841adb16_ASSET = "file")
load("images/wail_4_a6978c71.png", WAIL_4_a6978c71_ASSET = "file")
load("images/walk_1_2d42d3fb.png", WALK_1_2d42d3fb_ASSET = "file")
load("images/walk_2_b68c206b.png", WALK_2_b68c206b_ASSET = "file")
load("images/walk_3_53a7e3a1.png", WALK_3_53a7e3a1_ASSET = "file")
load("images/walk_4_11b35138.png", WALK_4_11b35138_ASSET = "file")
load("images/walk_5_a11c2c2b.png", WALK_5_a11c2c2b_ASSET = "file")
load("images/walk_6_83479de9.png", WALK_6_83479de9_ASSET = "file")
load("images/walk_7_6a4b58ff.png", WALK_7_6a4b58ff_ASSET = "file")
load("images/walkditto_10_79c5a705.png", WALKDITTO_10_79c5a705_ASSET = "file")
load("images/walkditto_11_aa769517.png", WALKDITTO_11_aa769517_ASSET = "file")
load("images/walkditto_12_aeadbbf8.png", WALKDITTO_12_aeadbbf8_ASSET = "file")
load("images/walkditto_13_a89b093d.png", WALKDITTO_13_a89b093d_ASSET = "file")
load("images/walkditto_14_3b6c408d.png", WALKDITTO_14_3b6c408d_ASSET = "file")
load("images/walkditto_1_4a7a2c12.png", WALKDITTO_1_4a7a2c12_ASSET = "file")
load("images/walkditto_2_d705a369.png", WALKDITTO_2_d705a369_ASSET = "file")
load("images/walkditto_3_612a65a7.png", WALKDITTO_3_612a65a7_ASSET = "file")
load("images/walkditto_4_5b096996.png", WALKDITTO_4_5b096996_ASSET = "file")
load("images/walkditto_5_973d5d76.png", WALKDITTO_5_973d5d76_ASSET = "file")
load("images/walkditto_6_017ecd46.png", WALKDITTO_6_017ecd46_ASSET = "file")
load("images/walkditto_7_5dcae422.png", WALKDITTO_7_5dcae422_ASSET = "file")
load("images/walkditto_8_441bae5a.png", WALKDITTO_8_441bae5a_ASSET = "file")
load("images/walkditto_9_55594840.png", WALKDITTO_9_55594840_ASSET = "file")
load("images/watch_1_b3b9087e.png", WATCH_1_b3b9087e_ASSET = "file")
load("images/watch_2_358043c9.png", WATCH_2_358043c9_ASSET = "file")
load("images/watch_3_2d4dcabc.png", WATCH_3_2d4dcabc_ASSET = "file")
load("images/wave_1_5acf57be.png", WAVE_1_5acf57be_ASSET = "file")
load("images/wave_2_091aaeb6.png", WAVE_2_091aaeb6_ASSET = "file")
load("images/wave_3_bf75b2d6.png", WAVE_3_bf75b2d6_ASSET = "file")
load("images/wave_4_850c44b3.png", WAVE_4_850c44b3_ASSET = "file")
load("images/wave_5_0f2477e0.png", WAVE_5_0f2477e0_ASSET = "file")
load("images/wave_6_30773687.png", WAVE_6_30773687_ASSET = "file")
load("images/write_1_93138a53.png", WRITE_1_93138a53_ASSET = "file")
load("images/write_2_7d82958a.png", WRITE_2_7d82958a_ASSET = "file")
load("images/write_3_bf4ac1e4.png", WRITE_3_bf4ac1e4_ASSET = "file")
load("images/yoyo_1_ed5bb6aa.png", YOYO_1_ed5bb6aa_ASSET = "file")
load("images/yoyo_2_8c35d430.png", YOYO_2_8c35d430_ASSET = "file")
load("images/yoyo_3_5ac56af7.png", YOYO_3_5ac56af7_ASSET = "file")
load("images/yoyo_4_10f38652.png", YOYO_4_10f38652_ASSET = "file")
load("images/yoyo_5_dfbedb91.png", YOYO_5_dfbedb91_ASSET = "file")
load("images/yoyo_6_42c21c11.png", YOYO_6_42c21c11_ASSET = "file")

DEFAULT_TIME_ZONE = "America/Phoenix"
BG_COLOR = "#95a87e"

def main(config):
    def getFrames(animationName):
        FRAMES = []
        for i in range(0, len(animationName[0])):
            FRAMES.extend([
                render.Column(
                    children = [
                        render.Box(
                            width = animationName[1],
                            height = animationName[2],
                            child = render.Image(base64.decode(animationName[0][i]), width = animationName[1], height = animationName[2]),
                        ),
                    ],
                ),
            ])
        return FRAMES

    def getPikachu(animationName):
        setDelay(animationName)
        return render.Padding(
            pad = (animationName[3], animationName[4], 0, 0),
            child = render.Animation(
                getFrames(animationName),
            ),
        )

    def setDelay(animationName):
        FRAME_DELAY = animationName[5]
        return FRAME_DELAY

    LOCATION = config.get("location")
    LOCATION = json.decode(LOCATION) if LOCATION else {}
    TIME_ZONE = LOCATION.get(
        "timezone",
        time.tz(),
    )
    TIME_NOW = time.now().in_location(TIME_ZONE)
    HOUR = int(TIME_NOW.format("15"))
    MINUTE = int(TIME_NOW.format("4"))
    DATE = int(TIME_NOW.format("2"))
    DAY = TIME_NOW.format("Mon")
    RANDOM_NUMBER = random.number(0, 100)

    # available actions (37):
    # DESKSLEEP, DRIVE, EAT, EATDONUT, EATRICE, GLIDE, KITE,
    # LEARNWOOPER, LEARNGEO, LICK, LOVE, PIANO, READ, SHOVEL, SHOWER,
    # SKATE, SLEEP, SLEEPTHRU, SUCK, SWIM, TEASE, TOOT, UNICYCLE,
    # BACKFLIP, BATHE, BIKE, BRUSH, BUILD, CHEER, CHILLMAG, COMPUTE,
    # WAIL, WALK, WALKDITTO, WAVE, WATCH, WRITE, YOYO

    def action():
        if HOUR < 6:
            return SLEEPTHRU
        elif HOUR == 6:
            if MINUTE <= 30:
                return READ
            else:
                return SHOWER
        elif HOUR == 7:
            if RANDOM_NUMBER > 5:
                if DAY == "Sun" or DAY == "Sat":
                    return COMPUTE
                elif RANDOM_NUMBER > 20:
                    return WALKDITTO
                else:
                    return WALK
            else:
                return TOOT
        elif HOUR == 8:
            if MINUTE <= 30:
                if DATE == 7:
                    return LICK
                else:
                    return EATDONUT
            else:
                return BRUSH
        elif HOUR == 9:
            if DATE % 2 == 0:  # even days
                return YOYO
            else:  # odd days
                return PIANO
        elif HOUR == 10:
            if RANDOM_NUMBER > 20:
                return LOVE
            elif RANDOM_NUMBER > 10 and RANDOM_NUMBER <= 20:
                return CHEER
            else:
                return WAIL
        elif HOUR == 11:
            if DATE <= 15:
                if MINUTE <= 5:
                    return GLIDE
                else:
                    return BUILD
            else:
                return SHOVEL
        elif HOUR == 12:
            return EAT
        elif HOUR == 13:
            if DAY == "Mon" or DAY == "Tue" or DAY == "Wed" or DAY == "Thu" or DAY == "Fri":
                if DATE % 2 != 0:  # odd days
                    return LEARNWOOPER
                elif DATE % 2 == 0 and DATE % 10 != 0:  # even days not divisible by 10
                    return LEARNGEO
                else:  # 10th, 20th, 30th
                    return DESKSLEEP
            else:  # weekend
                return KITE
        elif HOUR == 14 or HOUR == 15:
            if DAY == "Sun" or DAY == "Thu":
                return BIKE
            elif DAY == "Mon" or DAY == "Fri":
                return SWIM
            elif DAY == "Tue" or DAY == "Sat":
                return SKATE
            else:
                return YOYO
        elif HOUR == 16:
            if MINUTE <= 25:
                return UNICYCLE
            elif MINUTE > 25 and MINUTE <= 30:
                if RANDOM_NUMBER > 95:
                    return GLIDE
                else:
                    return BACKFLIP
            else:
                return DRIVE
        elif HOUR == 17:
            if DAY == "Mon" or DAY == "Tue" or DAY == "Wed" or DAY == "Thu" or DAY == "Sun":
                if MINUTE > 40:
                    if DATE % 2 == 0:  # even days
                        return LICK
                    else:  # odd days
                        return SUCK
                else:
                    return EATRICE
            else:
                return DRIVE
        elif HOUR == 18:
            if DAY == "Fri" or DAY == "Sat":
                if MINUTE <= 40:
                    return EATRICE
                else:
                    return TOOT
            else:
                return WATCH
        elif HOUR == 19:
            if DAY == "Fri" or DAY == "Sat":
                if MINUTE <= 30:
                    return COMPUTE
                else:
                    return CHILLMAG
            elif DAY == "Mon" or DAY == "Tue" or DAY == "Wed" or DAY == "Thu":
                if MINUTE <= 30:
                    return WRITE
                else:
                    return CHILLMAG
            else:
                return BATHE
        elif HOUR == 20:
            if RANDOM_NUMBER > 50:
                return WAVE
            else:
                return TEASE
        elif HOUR == 21:
            if MINUTE <= 30:
                return READ
            else:
                return BRUSH
        elif HOUR >= 22:
            return SLEEP
        else:  # default animation
            return BUILD

    return render.Root(
        delay = setDelay(action()),
        child = render.Stack(
            children = [
                render.Box(
                    width = 64,
                    height = 32,
                    color = BG_COLOR,
                ),
                getPikachu(action()),
            ],
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Location(
                id = "location",
                name = "Location",
                desc = "So Pikachu's activities match the time of day",
                icon = "locationDot",
            ),
        ],
    )

# Animation frames:
# READ
READ_1 = READ_1_69f1c5e7_ASSET.readall()
READ_2 = READ_2_e98c036f_ASSET.readall()
READ_3 = READ_3_7db2a4d2_ASSET.readall()

# BUILD
BUILD_1 = BUILD_1_f0ffb00d_ASSET.readall()
BUILD_2 = BUILD_2_b72e8f51_ASSET.readall()
BUILD_3 = BUILD_3_434d6c86_ASSET.readall()
BUILD_4 = BUILD_4_59413faa_ASSET.readall()
BUILD_5 = BUILD_5_ed028d81_ASSET.readall()

# GLIDE
GLIDE_1 = """iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAAAXNSR0IArs4c6QAAAB5JREFUaIHtwQENAAAAwqD3T20PBxQAAAAAAAAA8G4gIAABOwRMqQAAAABJRU5ErkJggg==
"""
GLIDE_2 = GLIDE_2_94180ca2_ASSET.readall()
GLIDE_3 = GLIDE_3_975472de_ASSET.readall()
GLIDE_4 = GLIDE_4_ed824933_ASSET.readall()
GLIDE_5 = GLIDE_5_fdb66079_ASSET.readall()
GLIDE_6 = GLIDE_6_dc5d7190_ASSET.readall()
GLIDE_7 = GLIDE_7_f6e9f9db_ASSET.readall()
GLIDE_8 = GLIDE_8_0640e25d_ASSET.readall()
GLIDE_9 = GLIDE_9_1d95cbe0_ASSET.readall()
GLIDE_10 = GLIDE_10_197a0f49_ASSET.readall()
GLIDE_11 = GLIDE_11_3dc6969b_ASSET.readall()
GLIDE_12 = GLIDE_12_63014efe_ASSET.readall()
GLIDE_13 = GLIDE_13_5308fca7_ASSET.readall()
GLIDE_14 = GLIDE_14_67d51803_ASSET.readall()
GLIDE_15 = GLIDE_15_4cd08c3a_ASSET.readall()
GLIDE_16 = GLIDE_16_4c079a34_ASSET.readall()
GLIDE_17 = GLIDE_17_1a4d4275_ASSET.readall()
GLIDE_18 = GLIDE_18_9139ed1c_ASSET.readall()
GLIDE_19 = GLIDE_19_0b725825_ASSET.readall()
GLIDE_20 = GLIDE_20_c9ea392d_ASSET.readall()
GLIDE_21 = GLIDE_21_837ced02_ASSET.readall()
GLIDE_22 = GLIDE_22_a1be338b_ASSET.readall()

# WAVE
WAVE_1 = WAVE_1_5acf57be_ASSET.readall()
WAVE_2 = WAVE_2_091aaeb6_ASSET.readall()
WAVE_3 = WAVE_3_bf75b2d6_ASSET.readall()
WAVE_4 = WAVE_4_850c44b3_ASSET.readall()
WAVE_5 = WAVE_5_0f2477e0_ASSET.readall()
WAVE_6 = WAVE_6_30773687_ASSET.readall()

# WRITE
WRITE_1 = WRITE_1_93138a53_ASSET.readall()
WRITE_2 = WRITE_2_7d82958a_ASSET.readall()
WRITE_3 = WRITE_3_bf4ac1e4_ASSET.readall()

# CHEER
CHEER_1 = CHEER_1_4847d673_ASSET.readall()
CHEER_2 = CHEER_2_bf2931db_ASSET.readall()
CHEER_3 = CHEER_3_456cb381_ASSET.readall()

# TEASE
TEASE_1 = TEASE_1_de1d5618_ASSET.readall()
TEASE_2 = TEASE_2_62896fc3_ASSET.readall()
TEASE_3 = TEASE_3_12fa3191_ASSET.readall()
TEASE_4 = TEASE_4_20e720a1_ASSET.readall()

# SWIM
SWIM_1 = SWIM_1_3f2d5589_ASSET.readall()
SWIM_2 = SWIM_2_823e59f2_ASSET.readall()
SWIM_3 = SWIM_3_21adcc31_ASSET.readall()
SWIM_4 = SWIM_4_d6a0c76c_ASSET.readall()
SWIM_5 = SWIM_5_51e8401f_ASSET.readall()
SWIM_6 = SWIM_6_0f205d75_ASSET.readall()
SWIM_7 = SWIM_7_a5945162_ASSET.readall()
SWIM_8 = SWIM_8_783b64e6_ASSET.readall()
SWIM_9 = SWIM_9_3b8e7f84_ASSET.readall()

# YOYO
YOYO_1 = YOYO_1_ed5bb6aa_ASSET.readall()
YOYO_2 = YOYO_2_8c35d430_ASSET.readall()
YOYO_3 = YOYO_3_5ac56af7_ASSET.readall()
YOYO_4 = YOYO_4_10f38652_ASSET.readall()
YOYO_5 = YOYO_5_dfbedb91_ASSET.readall()
YOYO_6 = YOYO_6_42c21c11_ASSET.readall()

# SLEEP
SLEEP_1 = SLEEP_1_5a1aff77_ASSET.readall()
SLEEP_2 = SLEEP_2_ffb9db63_ASSET.readall()
SLEEP_3 = SLEEP_3_6cef0af5_ASSET.readall()
SLEEP_4 = SLEEP_4_a30f3e70_ASSET.readall()
SLEEP_5 = SLEEP_5_0e742a59_ASSET.readall()

# PIANO
PIANO_1 = PIANO_1_50d28994_ASSET.readall()
PIANO_2 = PIANO_2_f146ebee_ASSET.readall()

# BATHE
BATHE_1 = BATHE_1_e18e4650_ASSET.readall()
BATHE_2 = BATHE_2_8d7e1a3d_ASSET.readall()
BATHE_3 = BATHE_3_dd22c92b_ASSET.readall()
BATHE_4 = BATHE_4_aee7e390_ASSET.readall()

# LICK
LICK_1 = LICK_1_6b02209f_ASSET.readall()
LICK_2 = LICK_2_bf4d8b60_ASSET.readall()
LICK_3 = LICK_3_dc705eca_ASSET.readall()

# WATCH
WATCH_1 = WATCH_1_b3b9087e_ASSET.readall()
WATCH_2 = WATCH_2_358043c9_ASSET.readall()
WATCH_3 = WATCH_3_2d4dcabc_ASSET.readall()

# EAT
EAT_1 = EAT_1_d68098a4_ASSET.readall()
EAT_2 = EAT_2_34260630_ASSET.readall()
EAT_3 = EAT_3_e299f69d_ASSET.readall()

# EATRICE
EATRICE_1 = EATRICE_1_db9a81db_ASSET.readall()
EATRICE_2 = EATRICE_2_853f1268_ASSET.readall()
EATRICE_3 = EATRICE_3_c9e8bcea_ASSET.readall()

# SHOVEL
SHOVEL_1 = SHOVEL_1_693d5fcc_ASSET.readall()
SHOVEL_2 = SHOVEL_2_f9bde391_ASSET.readall()

# SUCK
SUCK_1 = SUCK_1_732d27e5_ASSET.readall()
SUCK_2 = SUCK_2_9665fe9f_ASSET.readall()
SUCK_3 = SUCK_3_ce026312_ASSET.readall()

# WAIL
WAIL_1 = WAIL_1_549133a3_ASSET.readall()
WAIL_2 = WAIL_2_dba63f5a_ASSET.readall()
WAIL_3 = WAIL_3_841adb16_ASSET.readall()
WAIL_4 = WAIL_4_a6978c71_ASSET.readall()

# BACKFLIP
BACKFLIP_1 = BACKFLIP_1_a83ad8d8_ASSET.readall()
BACKFLIP_2 = BACKFLIP_2_d49d16e9_ASSET.readall()
BACKFLIP_3 = BACKFLIP_3_e66be6d2_ASSET.readall()
BACKFLIP_4 = BACKFLIP_4_84ec8814_ASSET.readall()

# LOVE
LOVE_1 = LOVE_1_61a9c1bc_ASSET.readall()
LOVE_2 = LOVE_2_d0017249_ASSET.readall()
LOVE_3 = LOVE_3_589984b9_ASSET.readall()

# COMPUTE
COMPUTE_1 = COMPUTE_1_d72afb6d_ASSET.readall()
COMPUTE_2 = COMPUTE_2_879e2a2e_ASSET.readall()
COMPUTE_3 = COMPUTE_3_5e3c9b0a_ASSET.readall()

# DRIVE
DRIVE_1 = DRIVE_1_2e74f7a9_ASSET.readall()
DRIVE_2 = DRIVE_2_9b42a4a2_ASSET.readall()
DRIVE_3 = DRIVE_3_abc38ce7_ASSET.readall()
DRIVE_4 = DRIVE_4_3806ef35_ASSET.readall()
DRIVE_5 = DRIVE_5_0cd7d9dd_ASSET.readall()
DRIVE_6 = DRIVE_6_6fec488c_ASSET.readall()
DRIVE_7 = DRIVE_7_5bf95f8d_ASSET.readall()
DRIVE_8 = DRIVE_8_51d1b44e_ASSET.readall()
DRIVE_9 = DRIVE_9_0501b976_ASSET.readall()
DRIVE_10 = DRIVE_10_22696a79_ASSET.readall()
DRIVE_11 = DRIVE_11_6b2a4895_ASSET.readall()
DRIVE_12 = DRIVE_12_66a06e5e_ASSET.readall()
DRIVE_13 = DRIVE_13_21c93ffd_ASSET.readall()
DRIVE_14 = DRIVE_14_87c314fa_ASSET.readall()

# BRUSH
BRUSH_1 = BRUSH_1_26e6ed9e_ASSET.readall()
BRUSH_2 = BRUSH_2_217507e3_ASSET.readall()

# SHOWER
SHOWER_1 = SHOWER_1_d55988e9_ASSET.readall()
SHOWER_2 = SHOWER_2_0b515e26_ASSET.readall()
SHOWER_3 = SHOWER_3_9baeec6e_ASSET.readall()
SHOWER_4 = SHOWER_4_c000eb8e_ASSET.readall()

# LEARN
LEARN_1 = LEARN_1_cb22fc9e_ASSET.readall()
LEARN_2 = LEARN_2_59728f0b_ASSET.readall()
LEARN_3 = LEARN_3_e7c9a221_ASSET.readall()
LEARN_4 = LEARN_4_a5e46d7a_ASSET.readall()
LEARN_5 = LEARN_5_6d4f3c1c_ASSET.readall()

# LEARNWOOPER
LEARNWOOPER_1 = LEARNWOOPER_1_ab1a573b_ASSET.readall()
LEARNWOOPER_2 = LEARNWOOPER_2_e1bc89f3_ASSET.readall()
LEARNWOOPER_3 = LEARNWOOPER_3_5f1963c2_ASSET.readall()
LEARNWOOPER_4 = LEARNWOOPER_4_b0260b65_ASSET.readall()
LEARNWOOPER_5 = LEARNWOOPER_5_b314f7c5_ASSET.readall()
LEARNWOOPER_6 = LEARNWOOPER_6_9ae22117_ASSET.readall()

# DESKSLEEP
DESKSLEEP_1 = DESKSLEEP_1_628444ec_ASSET.readall()
DESKSLEEP_2 = DESKSLEEP_2_d4c520ca_ASSET.readall()
DESKSLEEP_3 = DESKSLEEP_3_e768b8ec_ASSET.readall()

# LEARNGEO
LEARNGEO_1 = LEARNGEO_1_65a01508_ASSET.readall()
LEARNGEO_2 = LEARNGEO_2_8c6246c9_ASSET.readall()

# BIKE
BIKE_1 = BIKE_1_0ba2a639_ASSET.readall()
BIKE_2 = BIKE_2_6e8609df_ASSET.readall()
BIKE_3 = BIKE_3_d0527603_ASSET.readall()
BIKE_4 = BIKE_4_cfd13b67_ASSET.readall()

# TOOT
TOOT_1 = TOOT_1_485f7325_ASSET.readall()
TOOT_2 = TOOT_2_fa4944a6_ASSET.readall()
TOOT_3 = TOOT_3_aa6b0825_ASSET.readall()
TOOT_4 = TOOT_4_7460228b_ASSET.readall()
TOOT_5 = TOOT_5_179944a3_ASSET.readall()
TOOT_6 = TOOT_6_1e8b0a2f_ASSET.readall()
TOOT_7 = TOOT_7_62eb7620_ASSET.readall()
TOOT_8 = TOOT_8_c37fdf1b_ASSET.readall()
TOOT_9 = TOOT_9_d8f3ccac_ASSET.readall()
TOOT_10 = TOOT_10_3f28ccb1_ASSET.readall()
TOOT_11 = TOOT_11_5a898064_ASSET.readall()
TOOT_12 = TOOT_12_13a014c8_ASSET.readall()
TOOT_13 = TOOT_13_470ee3ce_ASSET.readall()
TOOT_14 = TOOT_14_718326bc_ASSET.readall()
TOOT_15 = TOOT_15_0689e4b7_ASSET.readall()
TOOT_16 = TOOT_16_af6776f9_ASSET.readall()

# EATDONUT
EATDONUT_1 = EATDONUT_1_0969f3c9_ASSET.readall()
EATDONUT_2 = EATDONUT_2_2b22949c_ASSET.readall()
EATDONUT_3 = EATDONUT_3_3d052f56_ASSET.readall()

# WALK
WALK_1 = WALK_1_2d42d3fb_ASSET.readall()
WALK_2 = WALK_2_b68c206b_ASSET.readall()
WALK_3 = WALK_3_53a7e3a1_ASSET.readall()
WALK_4 = WALK_4_11b35138_ASSET.readall()
WALK_5 = WALK_5_a11c2c2b_ASSET.readall()
WALK_6 = WALK_6_83479de9_ASSET.readall()
WALK_7 = WALK_7_6a4b58ff_ASSET.readall()

# WALKDITTO
WALKDITTO_1 = WALKDITTO_1_4a7a2c12_ASSET.readall()
WALKDITTO_2 = WALKDITTO_2_d705a369_ASSET.readall()
WALKDITTO_3 = WALKDITTO_3_612a65a7_ASSET.readall()
WALKDITTO_4 = WALKDITTO_4_5b096996_ASSET.readall()
WALKDITTO_5 = WALKDITTO_5_973d5d76_ASSET.readall()
WALKDITTO_6 = WALKDITTO_6_017ecd46_ASSET.readall()
WALKDITTO_7 = WALKDITTO_7_5dcae422_ASSET.readall()
WALKDITTO_8 = WALKDITTO_8_441bae5a_ASSET.readall()
WALKDITTO_9 = WALKDITTO_9_55594840_ASSET.readall()
WALKDITTO_10 = WALKDITTO_10_79c5a705_ASSET.readall()
WALKDITTO_11 = WALKDITTO_11_aa769517_ASSET.readall()
WALKDITTO_12 = WALKDITTO_12_aeadbbf8_ASSET.readall()
WALKDITTO_13 = WALKDITTO_13_a89b093d_ASSET.readall()
WALKDITTO_14 = WALKDITTO_14_3b6c408d_ASSET.readall()

# UNICYCLE
UNICYCLE_1 = UNICYCLE_1_cddfa574_ASSET.readall()
UNICYCLE_2 = UNICYCLE_2_49b601dd_ASSET.readall()
UNICYCLE_3 = UNICYCLE_3_bb667ad8_ASSET.readall()
UNICYCLE_4 = UNICYCLE_4_614ef2b5_ASSET.readall()
UNICYCLE_5 = UNICYCLE_5_7b6efca8_ASSET.readall()

# KITE
KITE_1 = KITE_1_545dfbca_ASSET.readall()
KITE_2 = KITE_2_64cec44d_ASSET.readall()
KITE_3 = KITE_3_16ae3347_ASSET.readall()
KITE_4 = KITE_4_f8370e13_ASSET.readall()
KITE_5 = KITE_5_0e722f39_ASSET.readall()
KITE_6 = KITE_6_74100d0c_ASSET.readall()
KITE_7 = KITE_7_1d12828b_ASSET.readall()
KITE_8 = KITE_8_e5999463_ASSET.readall()
KITE_9 = KITE_9_cb036e63_ASSET.readall()
KITE_10 = KITE_10_2253ecd3_ASSET.readall()
KITE_11 = KITE_11_2e74e6a2_ASSET.readall()
KITE_12 = KITE_12_d5e60b3e_ASSET.readall()
KITE_13 = KITE_13_8fca9358_ASSET.readall()
KITE_14 = KITE_14_0b8c8e9e_ASSET.readall()
KITE_15 = KITE_15_b0359f6b_ASSET.readall()
KITE_16 = KITE_16_2cef3f61_ASSET.readall()

# SKATE
SKATE_1 = SKATE_1_02303c20_ASSET.readall()
SKATE_2 = SKATE_2_3111a93c_ASSET.readall()
SKATE_3 = SKATE_3_f18d650b_ASSET.readall()
SKATE_4 = SKATE_4_32e49b3b_ASSET.readall()
SKATE_5 = SKATE_5_bd802635_ASSET.readall()
SKATE_6 = SKATE_6_12ac19d8_ASSET.readall()
SKATE_7 = SKATE_7_6e178182_ASSET.readall()
SKATE_8 = SKATE_8_7ef0de4d_ASSET.readall()
SKATE_9 = SKATE_9_95672823_ASSET.readall()
SKATE_10 = SKATE_10_2e99102c_ASSET.readall()
SKATE_11 = SKATE_11_ab9bab92_ASSET.readall()
SKATE_12 = SKATE_12_4c14bc69_ASSET.readall()
SKATE_13 = SKATE_13_f438fd47_ASSET.readall()
SKATE_14 = SKATE_14_adf5d185_ASSET.readall()
SKATE_15 = SKATE_15_3c7eff51_ASSET.readall()

# CHILLMAG
CHILLMAG_1 = CHILLMAG_1_d742faf5_ASSET.readall()
CHILLMAG_2 = CHILLMAG_2_1285d76c_ASSET.readall()
CHILLMAG_3 = CHILLMAG_3_6b041bdf_ASSET.readall()
CHILLMAG_4 = CHILLMAG_4_697c5ad3_ASSET.readall()
CHILLMAG_5 = CHILLMAG_5_84cd4b16_ASSET.readall()
CHILLMAG_6 = CHILLMAG_6_48d94a0f_ASSET.readall()
CHILLMAG_7 = CHILLMAG_7_a9c539ff_ASSET.readall()
CHILLMAG_8 = CHILLMAG_8_e5db64a0_ASSET.readall()
CHILLMAG_9 = CHILLMAG_9_6adfb211_ASSET.readall()
CHILLMAG_10 = CHILLMAG_10_5139930c_ASSET.readall()
CHILLMAG_11 = CHILLMAG_11_b6d879ea_ASSET.readall()
CHILLMAG_12 = CHILLMAG_12_7e0d932c_ASSET.readall()
CHILLMAG_13 = CHILLMAG_13_4c309533_ASSET.readall()

# Animations list: [[frames], width, height, xPosition, yPosition, frameMilliseconds]
READ = [
    [READ_1, READ_2, READ_1, READ_2, READ_1, READ_2, READ_1, READ_2, READ_1, READ_2, READ_3, READ_3, READ_3],
    32,
    15,
    5,
    12,
    750,
]
BUILD = [
    [BUILD_1, BUILD_1, BUILD_1, BUILD_2, BUILD_2, BUILD_2, BUILD_3, BUILD_4, BUILD_3, BUILD_4, BUILD_3, BUILD_4, BUILD_3, BUILD_4, BUILD_1, BUILD_1, BUILD_1, BUILD_2, BUILD_2, BUILD_2, BUILD_3, BUILD_4, BUILD_3, BUILD_4, BUILD_3, BUILD_4, BUILD_3, BUILD_4, BUILD_5, BUILD_5, BUILD_5, BUILD_5],
    32,
    22,
    8,
    8,
    250,
]
GLIDE = [
    [GLIDE_1, GLIDE_1, GLIDE_2, GLIDE_3, GLIDE_4, GLIDE_5, GLIDE_6, GLIDE_7, GLIDE_8, GLIDE_9, GLIDE_10, GLIDE_11, GLIDE_12, GLIDE_13, GLIDE_1, GLIDE_1, GLIDE_1, GLIDE_14, GLIDE_15, GLIDE_16, GLIDE_17, GLIDE_18, GLIDE_19, GLIDE_20, GLIDE_21, GLIDE_22, GLIDE_1, GLIDE_1, GLIDE_1],
    64,
    32,
    0,
    0,
    300,
]
WAVE = [
    [WAVE_1, WAVE_2, WAVE_3, WAVE_4, WAVE_3, WAVE_5, WAVE_6, WAVE_5, WAVE_6],
    36,
    32,
    14,
    0,
    750,
]
WRITE = [
    [WRITE_1, WRITE_2, WRITE_1, WRITE_2, WRITE_1, WRITE_2, WRITE_1, WRITE_2, WRITE_1, WRITE_2, WRITE_1, WRITE_2, WRITE_3, WRITE_3, WRITE_3, WRITE_3, WRITE_3],
    34,
    32,
    14,
    0,
    500,
]
CHEER = [
    [CHEER_1, CHEER_2, CHEER_1, CHEER_3],
    30,
    26,
    19,
    4,
    750,
]
TEASE = [
    [TEASE_1, TEASE_1, TEASE_1, TEASE_1, TEASE_1, TEASE_2, TEASE_3, TEASE_3, TEASE_4, TEASE_4, TEASE_3, TEASE_3, TEASE_4, TEASE_4, TEASE_3, TEASE_3, TEASE_4, TEASE_4, TEASE_3, TEASE_3],
    32,
    26,
    16,
    4,
    250,
]
SWIM = [
    [SWIM_1, SWIM_2, SWIM_3, SWIM_4, SWIM_5, SWIM_6, SWIM_7, SWIM_8, SWIM_9],
    64,
    32,
    0,
    0,
    400,
]
YOYO = [
    [YOYO_2, YOYO_3, YOYO_1, YOYO_2, YOYO_2, YOYO_3, YOYO_1, YOYO_2, YOYO_2, YOYO_3, YOYO_1, YOYO_2, YOYO_2, YOYO_4, YOYO_5, YOYO_6],
    38,
    25,
    26,
    7,
    500,
]
SLEEP = [
    [SLEEP_1, SLEEP_2, SLEEP_3, SLEEP_3, SLEEP_3, SLEEP_4, SLEEP_4, SLEEP_4, SLEEP_5, SLEEP_5, SLEEP_5, SLEEP_4, SLEEP_4, SLEEP_4, SLEEP_5, SLEEP_5, SLEEP_5, SLEEP_3, SLEEP_3, SLEEP_3, SLEEP_5, SLEEP_5, SLEEP_5, SLEEP_3, SLEEP_3, SLEEP_3, SLEEP_2, SLEEP_2, SLEEP_1],
    34,
    26,
    14,
    4,
    750,
]
SLEEPTHRU = [
    [SLEEP_5, SLEEP_3, SLEEP_4, SLEEP_5, SLEEP_4, SLEEP_3],
    34,
    26,
    14,
    4,
    3000,
]
PIANO = [
    [PIANO_1, PIANO_2],
    34,
    24,
    14,
    4,
    750,
]
BATHE = [
    [BATHE_1, BATHE_2, BATHE_1, BATHE_2, BATHE_1, BATHE_2, BATHE_1, BATHE_2, BATHE_3, BATHE_4, BATHE_3, BATHE_4],
    34,
    24,
    14,
    5,
    750,
]
LICK = [
    [LICK_1, LICK_2, LICK_1, LICK_2, LICK_1, LICK_2, LICK_1, LICK_2, LICK_3, LICK_3, LICK_3],
    35,
    22,
    15,
    5,
    750,
]
WATCH = [
    [WATCH_1, WATCH_2, WATCH_1, WATCH_2, WATCH_1, WATCH_2, WATCH_1, WATCH_2, WATCH_1, WATCH_2, WATCH_1, WATCH_2, WATCH_3, WATCH_3],
    44,
    25,
    0,
    5,
    500,
]
EAT = [
    [EAT_1, EAT_2, EAT_3, EAT_2, EAT_3, EAT_2, EAT_3, EAT_2, EAT_3, EAT_2, EAT_3, EAT_2],
    36,
    32,
    14,
    0,
    400,
]
EATRICE = [
    [EATRICE_1, EATRICE_2, EATRICE_3, EATRICE_2, EATRICE_3, EATRICE_2, EATRICE_3, EATRICE_2],
    36,
    32,
    14,
    0,
    400,
]
SHOVEL = [
    [SHOVEL_1, SHOVEL_2],
    38,
    17,
    10,
    12,
    600,
]
SUCK = [
    [SUCK_1, SUCK_2, SUCK_1, SUCK_2, SUCK_1, SUCK_2, SUCK_1, SUCK_2, SUCK_3, SUCK_3, SUCK_3],
    35,
    25,
    23,
    4,
    750,
]
WAIL = [
    [WAIL_1, WAIL_2, WAIL_3, WAIL_4, WAIL_3, WAIL_4, WAIL_3, WAIL_4, WAIL_2, WAIL_1, WAIL_1],
    30,
    26,
    17,
    3,
    500,
]
BACKFLIP = [
    [WAIL_1, BACKFLIP_1, BACKFLIP_2, BACKFLIP_3, BACKFLIP_4, BACKFLIP_1, WAIL_1, WAIL_1, WAIL_1],
    33,
    32,
    15,
    0,
    500,
]
LOVE = [
    [LOVE_1, LOVE_2, LOVE_1, LOVE_3],
    38,
    28,
    13,
    2,
    750,
]
COMPUTE = [
    [COMPUTE_1, COMPUTE_1, COMPUTE_1, COMPUTE_2, COMPUTE_2, COMPUTE_2, COMPUTE_3, COMPUTE_2, COMPUTE_3, COMPUTE_2, COMPUTE_3, COMPUTE_2, COMPUTE_3, COMPUTE_2],
    36,
    25,
    0,
    7,
    300,
]
DRIVE = [
    [DRIVE_14, DRIVE_1, DRIVE_2, DRIVE_3, DRIVE_4, DRIVE_5, DRIVE_6, DRIVE_7, DRIVE_8, DRIVE_9, DRIVE_10, DRIVE_11, DRIVE_12, DRIVE_13, DRIVE_14, DRIVE_14],
    64,
    24,
    0,
    4,
    400,
]
BRUSH = [
    [BRUSH_1, BRUSH_2],
    64,
    27,
    0,
    5,
    500,
]
SHOWER = [
    [SHOWER_1, SHOWER_2, SHOWER_1, SHOWER_2, SHOWER_1, SHOWER_2, SHOWER_3, SHOWER_4, SHOWER_3, SHOWER_4, SHOWER_3, SHOWER_4],
    36,
    29,
    0,
    2,
    500,
]
LEARNWOOPER = [
    [LEARNWOOPER_1, LEARNWOOPER_2, LEARNWOOPER_3, LEARNWOOPER_4, LEARNWOOPER_1, LEARNWOOPER_2, LEARNWOOPER_5, LEARNWOOPER_6, LEARNWOOPER_1, LEARNWOOPER_2],
    64,
    32,
    0,
    0,
    500,
]
DESKSLEEP = [
    [DESKSLEEP_1, DESKSLEEP_2, DESKSLEEP_1, DESKSLEEP_2, DESKSLEEP_1, DESKSLEEP_2, DESKSLEEP_3, DESKSLEEP_3],
    30,
    24,
    10,
    8,
    1000,
]
LEARNGEO = [
    [LEARN_1, LEARNGEO_1, LEARN_1, LEARNGEO_2],
    40,
    32,
    0,
    0,
    1500,
]
BIKE = [
    [BIKE_4, BIKE_4, BIKE_4, BIKE_1, BIKE_2, BIKE_1, BIKE_2, BIKE_1, BIKE_2, BIKE_1, BIKE_2, BIKE_1, BIKE_2, BIKE_1, BIKE_2, BIKE_1],
    35,
    21,
    13,
    6,
    300,
]
TOOT = [
    [TOOT_1, TOOT_2, TOOT_3, TOOT_4, TOOT_5, TOOT_6, TOOT_7, TOOT_8, TOOT_9, TOOT_10, TOOT_11, TOOT_12, TOOT_13, TOOT_14, TOOT_15, TOOT_16, TOOT_16, TOOT_16],
    64,
    21,
    0,
    8,
    500,
]
EATDONUT = [
    [EATDONUT_1, EATDONUT_2, EATDONUT_3, EATDONUT_2, EATDONUT_3, EATDONUT_2, EATDONUT_3, EATDONUT_2],
    36,
    32,
    14,
    0,
    400,
]
WALK = [
    [WALK_1, WALK_2, WALK_3, WALK_4, WALK_5, WALK_6, WALK_6, WALK_7, WALK_6, WALK_6, WALK_7, WALK_6, WALK_6, WALK_7, WALK_6, WALK_6, WALK_7, WALK_6, WALK_6, WALK_7, WALK_6, WALK_6, WALK_7],
    41,
    24,
    20,
    4,
    750,
]
WALKDITTO = [
    [WALKDITTO_1, WALKDITTO_2, WALKDITTO_3, WALKDITTO_4, WALKDITTO_5, WALKDITTO_6, WALKDITTO_7, WALKDITTO_8, WALKDITTO_9, WALKDITTO_11, WALKDITTO_12, WALKDITTO_13, WALKDITTO_14, WALKDITTO_14, WALKDITTO_14, WALKDITTO_14, WALKDITTO_14, WALKDITTO_14, WALKDITTO_14, WALKDITTO_14, WALKDITTO_14, WALKDITTO_14, WALKDITTO_14, WALKDITTO_14, WALKDITTO_14],
    64,
    32,
    0,
    0,
    300,
]
UNICYCLE = [
    [UNICYCLE_5, UNICYCLE_5, UNICYCLE_4, UNICYCLE_2, UNICYCLE_1, UNICYCLE_3, UNICYCLE_1, UNICYCLE_3, UNICYCLE_1, UNICYCLE_3, UNICYCLE_4, UNICYCLE_2, UNICYCLE_4, UNICYCLE_2, UNICYCLE_4, UNICYCLE_3, UNICYCLE_4, UNICYCLE_1, UNICYCLE_3, UNICYCLE_1, UNICYCLE_3, UNICYCLE_4, UNICYCLE_2, UNICYCLE_4, UNICYCLE_2, UNICYCLE_4, UNICYCLE_3, UNICYCLE_4, UNICYCLE_1, UNICYCLE_3, UNICYCLE_1, UNICYCLE_3, UNICYCLE_4, UNICYCLE_2, UNICYCLE_4, UNICYCLE_2, UNICYCLE_4, UNICYCLE_3, UNICYCLE_4],
    51,
    23,
    10,
    6,
    600,
]
KITE = [
    [KITE_1, KITE_2, KITE_3, KITE_4, KITE_5, KITE_6, KITE_7, KITE_8, KITE_9, KITE_10, KITE_11, KITE_12, KITE_13, KITE_14, KITE_15, KITE_16, KITE_16, KITE_16, KITE_16],
    64,
    30,
    0,
    1,
    250,
]
SKATE = [
    [SKATE_1, SKATE_2, SKATE_3, SKATE_4, SKATE_5, SKATE_6, SKATE_6, SKATE_6, SKATE_6, SKATE_6, SKATE_7, SKATE_8, SKATE_9, SKATE_10, SKATE_11, SKATE_12, SKATE_13, SKATE_14, SKATE_15, SKATE_15, SKATE_15, SKATE_15, SKATE_15],
    64,
    16,
    0,
    12,
    350,
]
CHILLMAG = [
    [CHILLMAG_1, CHILLMAG_2, CHILLMAG_1, CHILLMAG_3, CHILLMAG_4, CHILLMAG_5, CHILLMAG_1, CHILLMAG_6, CHILLMAG_1, CHILLMAG_7, CHILLMAG_8, CHILLMAG_9, CHILLMAG_10, CHILLMAG_11, CHILLMAG_12, CHILLMAG_11, CHILLMAG_10, CHILLMAG_13],
    64,
    32,
    0,
    0,
    250,
]
