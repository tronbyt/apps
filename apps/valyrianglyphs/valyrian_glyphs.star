"""
Applet: Valyrian Glyphs
Summary: Random High Valyrian glyphs
Description: Display a random glyph and translations from the High Valyrian language, as featured in HBO's Game of Thrones and House of the Dragon.
Author: frame-shift and David J. Peterson
"""

load("animation.star", "animation")
load("encoding/base64.star", "base64")
load("random.star", "random")
load("render.star", "render")
load("images/img_000895e8.png", IMG_000895e8_ASSET = "file")
load("images/img_0046cde2.png", IMG_0046cde2_ASSET = "file")
load("images/img_00de1706.png", IMG_00de1706_ASSET = "file")
load("images/img_0170f3a6.png", IMG_0170f3a6_ASSET = "file")
load("images/img_01715500.png", IMG_01715500_ASSET = "file")
load("images/img_0173a662.png", IMG_0173a662_ASSET = "file")
load("images/img_028f08d5.png", IMG_028f08d5_ASSET = "file")
load("images/img_02ecf4d9.png", IMG_02ecf4d9_ASSET = "file")
load("images/img_0332728e.png", IMG_0332728e_ASSET = "file")
load("images/img_03df1022.png", IMG_03df1022_ASSET = "file")
load("images/img_042a14e8.png", IMG_042a14e8_ASSET = "file")
load("images/img_0562f401.png", IMG_0562f401_ASSET = "file")
load("images/img_05bf35c9.png", IMG_05bf35c9_ASSET = "file")
load("images/img_0642f8c6.png", IMG_0642f8c6_ASSET = "file")
load("images/img_06566dad.png", IMG_06566dad_ASSET = "file")
load("images/img_0657582f.png", IMG_0657582f_ASSET = "file")
load("images/img_08282460.png", IMG_08282460_ASSET = "file")
load("images/img_0a6966dc.png", IMG_0a6966dc_ASSET = "file")
load("images/img_0af07890.png", IMG_0af07890_ASSET = "file")
load("images/img_0be1a635.png", IMG_0be1a635_ASSET = "file")
load("images/img_0c43cc24.png", IMG_0c43cc24_ASSET = "file")
load("images/img_0d56a3e3.png", IMG_0d56a3e3_ASSET = "file")
load("images/img_0e3a66db.png", IMG_0e3a66db_ASSET = "file")
load("images/img_0ea82d76.png", IMG_0ea82d76_ASSET = "file")
load("images/img_0eb5b914.png", IMG_0eb5b914_ASSET = "file")
load("images/img_0f5f59e9.png", IMG_0f5f59e9_ASSET = "file")
load("images/img_101b3ea6.png", IMG_101b3ea6_ASSET = "file")
load("images/img_102270a1.png", IMG_102270a1_ASSET = "file")
load("images/img_102e8b5f.png", IMG_102e8b5f_ASSET = "file")
load("images/img_11d33d71.png", IMG_11d33d71_ASSET = "file")
load("images/img_125fedab.png", IMG_125fedab_ASSET = "file")
load("images/img_129c2e2f.png", IMG_129c2e2f_ASSET = "file")
load("images/img_12e239eb.png", IMG_12e239eb_ASSET = "file")
load("images/img_132289fe.png", IMG_132289fe_ASSET = "file")
load("images/img_1360a5b4.png", IMG_1360a5b4_ASSET = "file")
load("images/img_13b9d9c8.png", IMG_13b9d9c8_ASSET = "file")
load("images/img_148947fd.png", IMG_148947fd_ASSET = "file")
load("images/img_1496d30d.png", IMG_1496d30d_ASSET = "file")
load("images/img_14ee66b8.png", IMG_14ee66b8_ASSET = "file")
load("images/img_1538813b.png", IMG_1538813b_ASSET = "file")
load("images/img_15a85268.png", IMG_15a85268_ASSET = "file")
load("images/img_15cb6988.png", IMG_15cb6988_ASSET = "file")
load("images/img_16c32784.png", IMG_16c32784_ASSET = "file")
load("images/img_16d94002.png", IMG_16d94002_ASSET = "file")
load("images/img_17018e13.png", IMG_17018e13_ASSET = "file")
load("images/img_1766844d.png", IMG_1766844d_ASSET = "file")
load("images/img_1996a3ee.png", IMG_1996a3ee_ASSET = "file")
load("images/img_199cb10f.png", IMG_199cb10f_ASSET = "file")
load("images/img_1b3b0fe1.png", IMG_1b3b0fe1_ASSET = "file")
load("images/img_1b5670b8.png", IMG_1b5670b8_ASSET = "file")
load("images/img_1c5839b3.png", IMG_1c5839b3_ASSET = "file")
load("images/img_1d23f50d.png", IMG_1d23f50d_ASSET = "file")
load("images/img_1d664423.png", IMG_1d664423_ASSET = "file")
load("images/img_1eb62354.png", IMG_1eb62354_ASSET = "file")
load("images/img_1ff1bd74.png", IMG_1ff1bd74_ASSET = "file")
load("images/img_1ff7438c.png", IMG_1ff7438c_ASSET = "file")
load("images/img_223b29a2.png", IMG_223b29a2_ASSET = "file")
load("images/img_23c591e3.png", IMG_23c591e3_ASSET = "file")
load("images/img_24123ab8.png", IMG_24123ab8_ASSET = "file")
load("images/img_24b88d0e.png", IMG_24b88d0e_ASSET = "file")
load("images/img_24f547f4.png", IMG_24f547f4_ASSET = "file")
load("images/img_25126822.png", IMG_25126822_ASSET = "file")
load("images/img_25aae965.png", IMG_25aae965_ASSET = "file")
load("images/img_261e1d4b.png", IMG_261e1d4b_ASSET = "file")
load("images/img_26353c5a.png", IMG_26353c5a_ASSET = "file")
load("images/img_2638e74e.png", IMG_2638e74e_ASSET = "file")
load("images/img_2714c1d7.png", IMG_2714c1d7_ASSET = "file")
load("images/img_2772a852.png", IMG_2772a852_ASSET = "file")
load("images/img_27de4edf.png", IMG_27de4edf_ASSET = "file")
load("images/img_293ef48a.png", IMG_293ef48a_ASSET = "file")
load("images/img_2a130ed2.png", IMG_2a130ed2_ASSET = "file")
load("images/img_2a1e2785.png", IMG_2a1e2785_ASSET = "file")
load("images/img_2a490f73.png", IMG_2a490f73_ASSET = "file")
load("images/img_2a781cf7.png", IMG_2a781cf7_ASSET = "file")
load("images/img_2b1ff3f8.png", IMG_2b1ff3f8_ASSET = "file")
load("images/img_2b4e5523.png", IMG_2b4e5523_ASSET = "file")
load("images/img_2b81c1e2.png", IMG_2b81c1e2_ASSET = "file")
load("images/img_2ca15f7c.png", IMG_2ca15f7c_ASSET = "file")
load("images/img_2cd705ce.png", IMG_2cd705ce_ASSET = "file")
load("images/img_2d52cd35.png", IMG_2d52cd35_ASSET = "file")
load("images/img_2dd6c75e.png", IMG_2dd6c75e_ASSET = "file")
load("images/img_2de4eb6b.png", IMG_2de4eb6b_ASSET = "file")
load("images/img_31943655.png", IMG_31943655_ASSET = "file")
load("images/img_32565d0c.png", IMG_32565d0c_ASSET = "file")
load("images/img_328f7e3a.png", IMG_328f7e3a_ASSET = "file")
load("images/img_32c93a2e.png", IMG_32c93a2e_ASSET = "file")
load("images/img_32d8a2d5.png", IMG_32d8a2d5_ASSET = "file")
load("images/img_3306f5d7.png", IMG_3306f5d7_ASSET = "file")
load("images/img_33a78435.png", IMG_33a78435_ASSET = "file")
load("images/img_33b8d4e5.png", IMG_33b8d4e5_ASSET = "file")
load("images/img_33d742d8.png", IMG_33d742d8_ASSET = "file")
load("images/img_343463ad.png", IMG_343463ad_ASSET = "file")
load("images/img_343b1fec.png", IMG_343b1fec_ASSET = "file")
load("images/img_350945ee.png", IMG_350945ee_ASSET = "file")
load("images/img_3535ded2.png", IMG_3535ded2_ASSET = "file")
load("images/img_357b0697.png", IMG_357b0697_ASSET = "file")
load("images/img_364287e1.png", IMG_364287e1_ASSET = "file")
load("images/img_367fbb29.png", IMG_367fbb29_ASSET = "file")
load("images/img_370d572d.png", IMG_370d572d_ASSET = "file")
load("images/img_373b9e95.png", IMG_373b9e95_ASSET = "file")
load("images/img_37b8e9b2.png", IMG_37b8e9b2_ASSET = "file")
load("images/img_37d77da0.png", IMG_37d77da0_ASSET = "file")
load("images/img_3953c4ba.png", IMG_3953c4ba_ASSET = "file")
load("images/img_3aa06f79.png", IMG_3aa06f79_ASSET = "file")
load("images/img_3e248790.png", IMG_3e248790_ASSET = "file")
load("images/img_3ea955cc.png", IMG_3ea955cc_ASSET = "file")
load("images/img_3f1768fa.png", IMG_3f1768fa_ASSET = "file")
load("images/img_3fbe769c.png", IMG_3fbe769c_ASSET = "file")
load("images/img_3fd96b2f.png", IMG_3fd96b2f_ASSET = "file")
load("images/img_41225b8a.png", IMG_41225b8a_ASSET = "file")
load("images/img_41732d45.png", IMG_41732d45_ASSET = "file")
load("images/img_43379e54.png", IMG_43379e54_ASSET = "file")
load("images/img_434556cd.png", IMG_434556cd_ASSET = "file")
load("images/img_43d3a952.png", IMG_43d3a952_ASSET = "file")
load("images/img_440722e7.png", IMG_440722e7_ASSET = "file")
load("images/img_44190441.png", IMG_44190441_ASSET = "file")
load("images/img_44aa0861.png", IMG_44aa0861_ASSET = "file")
load("images/img_451b5ade.png", IMG_451b5ade_ASSET = "file")
load("images/img_4528d6f5.png", IMG_4528d6f5_ASSET = "file")
load("images/img_45391861.png", IMG_45391861_ASSET = "file")
load("images/img_454aeb79.png", IMG_454aeb79_ASSET = "file")
load("images/img_45730155.png", IMG_45730155_ASSET = "file")
load("images/img_45f3bfd5.png", IMG_45f3bfd5_ASSET = "file")
load("images/img_47f66c07.png", IMG_47f66c07_ASSET = "file")
load("images/img_482c85e7.png", IMG_482c85e7_ASSET = "file")
load("images/img_48898bce.png", IMG_48898bce_ASSET = "file")
load("images/img_489e5875.png", IMG_489e5875_ASSET = "file")
load("images/img_4988c657.png", IMG_4988c657_ASSET = "file")
load("images/img_4a7c673c.png", IMG_4a7c673c_ASSET = "file")
load("images/img_4aaaf365.png", IMG_4aaaf365_ASSET = "file")
load("images/img_4aaafaea.png", IMG_4aaafaea_ASSET = "file")
load("images/img_4ab39d0c.png", IMG_4ab39d0c_ASSET = "file")
load("images/img_4b5cb580.png", IMG_4b5cb580_ASSET = "file")
load("images/img_4bb59a72.png", IMG_4bb59a72_ASSET = "file")
load("images/img_4bc7f232.png", IMG_4bc7f232_ASSET = "file")
load("images/img_4c0f45f3.png", IMG_4c0f45f3_ASSET = "file")
load("images/img_4d4c8728.png", IMG_4d4c8728_ASSET = "file")
load("images/img_4d4ec311.png", IMG_4d4ec311_ASSET = "file")
load("images/img_4d6f7fe4.png", IMG_4d6f7fe4_ASSET = "file")
load("images/img_4e42c77b.png", IMG_4e42c77b_ASSET = "file")
load("images/img_4e6932b6.png", IMG_4e6932b6_ASSET = "file")
load("images/img_4e7f4cee.png", IMG_4e7f4cee_ASSET = "file")
load("images/img_4ef52a21.png", IMG_4ef52a21_ASSET = "file")
load("images/img_4ef97216.png", IMG_4ef97216_ASSET = "file")
load("images/img_5007b979.png", IMG_5007b979_ASSET = "file")
load("images/img_51101e9e.png", IMG_51101e9e_ASSET = "file")
load("images/img_515844f2.png", IMG_515844f2_ASSET = "file")
load("images/img_515a3efd.png", IMG_515a3efd_ASSET = "file")
load("images/img_51855cc8.png", IMG_51855cc8_ASSET = "file")
load("images/img_51cace8b.png", IMG_51cace8b_ASSET = "file")
load("images/img_521a31c6.png", IMG_521a31c6_ASSET = "file")
load("images/img_52330bf0.png", IMG_52330bf0_ASSET = "file")
load("images/img_528870df.png", IMG_528870df_ASSET = "file")
load("images/img_52acdbf8.png", IMG_52acdbf8_ASSET = "file")
load("images/img_52f7cfd2.png", IMG_52f7cfd2_ASSET = "file")
load("images/img_534760bf.png", IMG_534760bf_ASSET = "file")
load("images/img_55840d36.png", IMG_55840d36_ASSET = "file")
load("images/img_57ba32b4.png", IMG_57ba32b4_ASSET = "file")
load("images/img_584da881.png", IMG_584da881_ASSET = "file")
load("images/img_58992dee.png", IMG_58992dee_ASSET = "file")
load("images/img_58bf3f03.png", IMG_58bf3f03_ASSET = "file")
load("images/img_594a9325.png", IMG_594a9325_ASSET = "file")
load("images/img_59d0f054.png", IMG_59d0f054_ASSET = "file")
load("images/img_5b9ba9bb.png", IMG_5b9ba9bb_ASSET = "file")
load("images/img_5c23a564.png", IMG_5c23a564_ASSET = "file")
load("images/img_5caafb10.png", IMG_5caafb10_ASSET = "file")
load("images/img_5dd1e297.png", IMG_5dd1e297_ASSET = "file")
load("images/img_5e199dfe.png", IMG_5e199dfe_ASSET = "file")
load("images/img_5f19fc72.png", IMG_5f19fc72_ASSET = "file")
load("images/img_5f62d838.png", IMG_5f62d838_ASSET = "file")
load("images/img_5f833f86.png", IMG_5f833f86_ASSET = "file")
load("images/img_5f9a7766.png", IMG_5f9a7766_ASSET = "file")
load("images/img_60be0f88.png", IMG_60be0f88_ASSET = "file")
load("images/img_6124ffc7.png", IMG_6124ffc7_ASSET = "file")
load("images/img_613c6e2a.png", IMG_613c6e2a_ASSET = "file")
load("images/img_61c00db0.png", IMG_61c00db0_ASSET = "file")
load("images/img_61dda01c.png", IMG_61dda01c_ASSET = "file")
load("images/img_62998aec.png", IMG_62998aec_ASSET = "file")
load("images/img_62b16948.png", IMG_62b16948_ASSET = "file")
load("images/img_642dd209.png", IMG_642dd209_ASSET = "file")
load("images/img_646b75c3.png", IMG_646b75c3_ASSET = "file")
load("images/img_6492bfd1.png", IMG_6492bfd1_ASSET = "file")
load("images/img_65523acb.png", IMG_65523acb_ASSET = "file")
load("images/img_655d9ef3.png", IMG_655d9ef3_ASSET = "file")
load("images/img_657e3596.png", IMG_657e3596_ASSET = "file")
load("images/img_658926ff.png", IMG_658926ff_ASSET = "file")
load("images/img_6597a4cb.png", IMG_6597a4cb_ASSET = "file")
load("images/img_65c2833d.png", IMG_65c2833d_ASSET = "file")
load("images/img_65c37fb8.png", IMG_65c37fb8_ASSET = "file")
load("images/img_65cdae9f.png", IMG_65cdae9f_ASSET = "file")
load("images/img_6603993a.png", IMG_6603993a_ASSET = "file")
load("images/img_660a7c41.png", IMG_660a7c41_ASSET = "file")
load("images/img_66680117.png", IMG_66680117_ASSET = "file")
load("images/img_67144415.png", IMG_67144415_ASSET = "file")
load("images/img_67152b06.png", IMG_67152b06_ASSET = "file")
load("images/img_676293f7.png", IMG_676293f7_ASSET = "file")
load("images/img_676a8565.png", IMG_676a8565_ASSET = "file")
load("images/img_681721a6.png", IMG_681721a6_ASSET = "file")
load("images/img_697bc9b8.png", IMG_697bc9b8_ASSET = "file")
load("images/img_698a261e.png", IMG_698a261e_ASSET = "file")
load("images/img_698ebb7d.png", IMG_698ebb7d_ASSET = "file")
load("images/img_6998830a.png", IMG_6998830a_ASSET = "file")
load("images/img_6a0f296a.png", IMG_6a0f296a_ASSET = "file")
load("images/img_6ace12ff.png", IMG_6ace12ff_ASSET = "file")
load("images/img_6ad8f103.png", IMG_6ad8f103_ASSET = "file")
load("images/img_6b1e1dfb.png", IMG_6b1e1dfb_ASSET = "file")
load("images/img_6d057349.png", IMG_6d057349_ASSET = "file")
load("images/img_6d6fddfc.png", IMG_6d6fddfc_ASSET = "file")
load("images/img_6da77693.png", IMG_6da77693_ASSET = "file")
load("images/img_6dc5b73e.png", IMG_6dc5b73e_ASSET = "file")
load("images/img_6def6c83.png", IMG_6def6c83_ASSET = "file")
load("images/img_6dfd3924.png", IMG_6dfd3924_ASSET = "file")
load("images/img_6f2391b6.png", IMG_6f2391b6_ASSET = "file")
load("images/img_6f6e0c3e.png", IMG_6f6e0c3e_ASSET = "file")
load("images/img_7048bad6.png", IMG_7048bad6_ASSET = "file")
load("images/img_7177f42d.png", IMG_7177f42d_ASSET = "file")
load("images/img_7179ac10.png", IMG_7179ac10_ASSET = "file")
load("images/img_71be53bf.png", IMG_71be53bf_ASSET = "file")
load("images/img_732f703c.png", IMG_732f703c_ASSET = "file")
load("images/img_73799785.png", IMG_73799785_ASSET = "file")
load("images/img_73829cac.png", IMG_73829cac_ASSET = "file")
load("images/img_73ac00ff.png", IMG_73ac00ff_ASSET = "file")
load("images/img_73c3aea3.png", IMG_73c3aea3_ASSET = "file")
load("images/img_73f84085.png", IMG_73f84085_ASSET = "file")
load("images/img_7495d6d6.png", IMG_7495d6d6_ASSET = "file")
load("images/img_757ac791.png", IMG_757ac791_ASSET = "file")
load("images/img_75fce320.png", IMG_75fce320_ASSET = "file")
load("images/img_76cebc01.png", IMG_76cebc01_ASSET = "file")
load("images/img_7800371e.png", IMG_7800371e_ASSET = "file")
load("images/img_788fea83.png", IMG_788fea83_ASSET = "file")
load("images/img_78fd2646.png", IMG_78fd2646_ASSET = "file")
load("images/img_791666e7.png", IMG_791666e7_ASSET = "file")
load("images/img_7a213967.png", IMG_7a213967_ASSET = "file")
load("images/img_7b378372.png", IMG_7b378372_ASSET = "file")
load("images/img_7b4a8bb3.png", IMG_7b4a8bb3_ASSET = "file")
load("images/img_7b91d8b1.png", IMG_7b91d8b1_ASSET = "file")
load("images/img_7b9cea26.png", IMG_7b9cea26_ASSET = "file")
load("images/img_7beca465.png", IMG_7beca465_ASSET = "file")
load("images/img_7c79b70a.png", IMG_7c79b70a_ASSET = "file")
load("images/img_7cc07c4f.png", IMG_7cc07c4f_ASSET = "file")
load("images/img_7d16c8ac.png", IMG_7d16c8ac_ASSET = "file")
load("images/img_7d6b1bb8.png", IMG_7d6b1bb8_ASSET = "file")
load("images/img_7d786d9d.png", IMG_7d786d9d_ASSET = "file")
load("images/img_7e719373.png", IMG_7e719373_ASSET = "file")
load("images/img_7fc5baa6.png", IMG_7fc5baa6_ASSET = "file")
load("images/img_80b06068.png", IMG_80b06068_ASSET = "file")
load("images/img_80df8a2d.png", IMG_80df8a2d_ASSET = "file")
load("images/img_8168175a.png", IMG_8168175a_ASSET = "file")
load("images/img_8264bdbd.png", IMG_8264bdbd_ASSET = "file")
load("images/img_82de5f87.png", IMG_82de5f87_ASSET = "file")
load("images/img_83142870.png", IMG_83142870_ASSET = "file")
load("images/img_84d0f068.png", IMG_84d0f068_ASSET = "file")
load("images/img_8509b544.png", IMG_8509b544_ASSET = "file")
load("images/img_85daa81c.png", IMG_85daa81c_ASSET = "file")
load("images/img_88399df2.png", IMG_88399df2_ASSET = "file")
load("images/img_883b369c.png", IMG_883b369c_ASSET = "file")
load("images/img_898be070.png", IMG_898be070_ASSET = "file")
load("images/img_89a25482.png", IMG_89a25482_ASSET = "file")
load("images/img_8a03b04c.png", IMG_8a03b04c_ASSET = "file")
load("images/img_8a3e81d6.png", IMG_8a3e81d6_ASSET = "file")
load("images/img_8acb20fb.png", IMG_8acb20fb_ASSET = "file")
load("images/img_8b11911e.png", IMG_8b11911e_ASSET = "file")
load("images/img_8b34be00.png", IMG_8b34be00_ASSET = "file")
load("images/img_8bb2be89.png", IMG_8bb2be89_ASSET = "file")
load("images/img_8bb505c8.png", IMG_8bb505c8_ASSET = "file")
load("images/img_8bbe124c.png", IMG_8bbe124c_ASSET = "file")
load("images/img_8bdde982.png", IMG_8bdde982_ASSET = "file")
load("images/img_8bde1fe3.png", IMG_8bde1fe3_ASSET = "file")
load("images/img_8c54e932.png", IMG_8c54e932_ASSET = "file")
load("images/img_8c56925d.png", IMG_8c56925d_ASSET = "file")
load("images/img_8c6a096a.png", IMG_8c6a096a_ASSET = "file")
load("images/img_8cc9bdad.png", IMG_8cc9bdad_ASSET = "file")
load("images/img_8ce4e1d2.png", IMG_8ce4e1d2_ASSET = "file")
load("images/img_8fc2c9a7.png", IMG_8fc2c9a7_ASSET = "file")
load("images/img_8feaf675.png", IMG_8feaf675_ASSET = "file")
load("images/img_8ff0f1ca.png", IMG_8ff0f1ca_ASSET = "file")
load("images/img_9070668c.png", IMG_9070668c_ASSET = "file")
load("images/img_91ee487d.png", IMG_91ee487d_ASSET = "file")
load("images/img_921f19cf.png", IMG_921f19cf_ASSET = "file")
load("images/img_92405d1a.png", IMG_92405d1a_ASSET = "file")
load("images/img_93b94d70.png", IMG_93b94d70_ASSET = "file")
load("images/img_943275e3.png", IMG_943275e3_ASSET = "file")
load("images/img_95cfdb18.png", IMG_95cfdb18_ASSET = "file")
load("images/img_9676518d.png", IMG_9676518d_ASSET = "file")
load("images/img_96a52ab3.png", IMG_96a52ab3_ASSET = "file")
load("images/img_97351477.png", IMG_97351477_ASSET = "file")
load("images/img_97a0aab6.png", IMG_97a0aab6_ASSET = "file")
load("images/img_99ddbcf7.png", IMG_99ddbcf7_ASSET = "file")
load("images/img_9a1bf3e0.png", IMG_9a1bf3e0_ASSET = "file")
load("images/img_9a378c5b.png", IMG_9a378c5b_ASSET = "file")
load("images/img_9abb1767.png", IMG_9abb1767_ASSET = "file")
load("images/img_9ad214b6.png", IMG_9ad214b6_ASSET = "file")
load("images/img_9af675c9.png", IMG_9af675c9_ASSET = "file")
load("images/img_9b0b947c.png", IMG_9b0b947c_ASSET = "file")
load("images/img_9d7512db.png", IMG_9d7512db_ASSET = "file")
load("images/img_9e54b83f.png", IMG_9e54b83f_ASSET = "file")
load("images/img_9eeb917e.png", IMG_9eeb917e_ASSET = "file")
load("images/img_9f4899f0.png", IMG_9f4899f0_ASSET = "file")
load("images/img_9fbf19f5.png", IMG_9fbf19f5_ASSET = "file")
load("images/img_9fe6f5b9.png", IMG_9fe6f5b9_ASSET = "file")
load("images/img_a1146f3c.png", IMG_a1146f3c_ASSET = "file")
load("images/img_a1a1c53d.png", IMG_a1a1c53d_ASSET = "file")
load("images/img_a1caadf6.png", IMG_a1caadf6_ASSET = "file")
load("images/img_a1f0cad4.png", IMG_a1f0cad4_ASSET = "file")
load("images/img_a329cbbf.png", IMG_a329cbbf_ASSET = "file")
load("images/img_a32c14d9.png", IMG_a32c14d9_ASSET = "file")
load("images/img_a393c0fb.png", IMG_a393c0fb_ASSET = "file")
load("images/img_a3e544c0.png", IMG_a3e544c0_ASSET = "file")
load("images/img_a45516f6.png", IMG_a45516f6_ASSET = "file")
load("images/img_a456babe.png", IMG_a456babe_ASSET = "file")
load("images/img_a518fef0.png", IMG_a518fef0_ASSET = "file")
load("images/img_a56fa996.png", IMG_a56fa996_ASSET = "file")
load("images/img_a648a491.png", IMG_a648a491_ASSET = "file")
load("images/img_a669e1ca.png", IMG_a669e1ca_ASSET = "file")
load("images/img_a7bb9c07.png", IMG_a7bb9c07_ASSET = "file")
load("images/img_a8b016dd.png", IMG_a8b016dd_ASSET = "file")
load("images/img_a9f24bd5.png", IMG_a9f24bd5_ASSET = "file")
load("images/img_aad4b90e.png", IMG_aad4b90e_ASSET = "file")
load("images/img_ad910c1d.png", IMG_ad910c1d_ASSET = "file")
load("images/img_ae25e30a.png", IMG_ae25e30a_ASSET = "file")
load("images/img_ae6fbbe8.png", IMG_ae6fbbe8_ASSET = "file")
load("images/img_aea47e56.png", IMG_aea47e56_ASSET = "file")
load("images/img_aeb17303.png", IMG_aeb17303_ASSET = "file")
load("images/img_aedf19d4.png", IMG_aedf19d4_ASSET = "file")
load("images/img_af01bb72.png", IMG_af01bb72_ASSET = "file")
load("images/img_afd68cdd.png", IMG_afd68cdd_ASSET = "file")
load("images/img_b043bbd8.png", IMG_b043bbd8_ASSET = "file")
load("images/img_b09b6a2c.png", IMG_b09b6a2c_ASSET = "file")
load("images/img_b0bb2ddb.png", IMG_b0bb2ddb_ASSET = "file")
load("images/img_b0caa942.png", IMG_b0caa942_ASSET = "file")
load("images/img_b0f1487f.png", IMG_b0f1487f_ASSET = "file")
load("images/img_b115ed02.png", IMG_b115ed02_ASSET = "file")
load("images/img_b124fca6.png", IMG_b124fca6_ASSET = "file")
load("images/img_b17e1219.png", IMG_b17e1219_ASSET = "file")
load("images/img_b3462530.png", IMG_b3462530_ASSET = "file")
load("images/img_b3a4e1ea.png", IMG_b3a4e1ea_ASSET = "file")
load("images/img_b46a7943.png", IMG_b46a7943_ASSET = "file")
load("images/img_b536e582.png", IMG_b536e582_ASSET = "file")
load("images/img_b5aec4f3.png", IMG_b5aec4f3_ASSET = "file")
load("images/img_b5e6635d.png", IMG_b5e6635d_ASSET = "file")
load("images/img_b6025a94.png", IMG_b6025a94_ASSET = "file")
load("images/img_b6a1798e.png", IMG_b6a1798e_ASSET = "file")
load("images/img_b6db5b4c.png", IMG_b6db5b4c_ASSET = "file")
load("images/img_b7b3d9f5.png", IMG_b7b3d9f5_ASSET = "file")
load("images/img_b881b4bf.png", IMG_b881b4bf_ASSET = "file")
load("images/img_b8d899ea.png", IMG_b8d899ea_ASSET = "file")
load("images/img_b936c178.png", IMG_b936c178_ASSET = "file")
load("images/img_b9bc0652.png", IMG_b9bc0652_ASSET = "file")
load("images/img_ba2c6d96.png", IMG_ba2c6d96_ASSET = "file")
load("images/img_ba840454.png", IMG_ba840454_ASSET = "file")
load("images/img_ba8d9d6b.png", IMG_ba8d9d6b_ASSET = "file")
load("images/img_baa19a11.png", IMG_baa19a11_ASSET = "file")
load("images/img_bba517ec.png", IMG_bba517ec_ASSET = "file")
load("images/img_bbfa4dd8.png", IMG_bbfa4dd8_ASSET = "file")
load("images/img_bd421031.png", IMG_bd421031_ASSET = "file")
load("images/img_be0c85cd.png", IMG_be0c85cd_ASSET = "file")
load("images/img_be727a48.png", IMG_be727a48_ASSET = "file")
load("images/img_becc34a0.png", IMG_becc34a0_ASSET = "file")
load("images/img_bedc975a.png", IMG_bedc975a_ASSET = "file")
load("images/img_bfbe7b80.png", IMG_bfbe7b80_ASSET = "file")
load("images/img_bfdfd33c.png", IMG_bfdfd33c_ASSET = "file")
load("images/img_c0a8b968.png", IMG_c0a8b968_ASSET = "file")
load("images/img_c0bb9938.png", IMG_c0bb9938_ASSET = "file")
load("images/img_c1cd6731.png", IMG_c1cd6731_ASSET = "file")
load("images/img_c1d7f5aa.png", IMG_c1d7f5aa_ASSET = "file")
load("images/img_c1f013c2.png", IMG_c1f013c2_ASSET = "file")
load("images/img_c27baa64.png", IMG_c27baa64_ASSET = "file")
load("images/img_c2943145.png", IMG_c2943145_ASSET = "file")
load("images/img_c37e6d72.png", IMG_c37e6d72_ASSET = "file")
load("images/img_c528d50c.png", IMG_c528d50c_ASSET = "file")
load("images/img_c5bfbb4d.png", IMG_c5bfbb4d_ASSET = "file")
load("images/img_c68adb54.png", IMG_c68adb54_ASSET = "file")
load("images/img_c6d3bb20.png", IMG_c6d3bb20_ASSET = "file")
load("images/img_c7d6cdfc.png", IMG_c7d6cdfc_ASSET = "file")
load("images/img_c80ad1be.png", IMG_c80ad1be_ASSET = "file")
load("images/img_c8253fc8.png", IMG_c8253fc8_ASSET = "file")
load("images/img_c99f70eb.png", IMG_c99f70eb_ASSET = "file")
load("images/img_c9a82150.png", IMG_c9a82150_ASSET = "file")
load("images/img_ca0b237a.png", IMG_ca0b237a_ASSET = "file")
load("images/img_ca811654.png", IMG_ca811654_ASSET = "file")
load("images/img_caabb991.png", IMG_caabb991_ASSET = "file")
load("images/img_ccabb773.png", IMG_ccabb773_ASSET = "file")
load("images/img_ccbf354a.png", IMG_ccbf354a_ASSET = "file")
load("images/img_cd0aa873.png", IMG_cd0aa873_ASSET = "file")
load("images/img_cd9a5743.png", IMG_cd9a5743_ASSET = "file")
load("images/img_ce12b4d4.png", IMG_ce12b4d4_ASSET = "file")
load("images/img_ce652728.png", IMG_ce652728_ASSET = "file")
load("images/img_ceab5bc4.png", IMG_ceab5bc4_ASSET = "file")
load("images/img_cef700cc.png", IMG_cef700cc_ASSET = "file")
load("images/img_cf5a277e.png", IMG_cf5a277e_ASSET = "file")
load("images/img_d051ed2f.png", IMG_d051ed2f_ASSET = "file")
load("images/img_d0ba34e8.png", IMG_d0ba34e8_ASSET = "file")
load("images/img_d0cb6059.png", IMG_d0cb6059_ASSET = "file")
load("images/img_d2700eee.png", IMG_d2700eee_ASSET = "file")
load("images/img_d48108c0.png", IMG_d48108c0_ASSET = "file")
load("images/img_d4f62d6c.png", IMG_d4f62d6c_ASSET = "file")
load("images/img_d4f6a9bc.png", IMG_d4f6a9bc_ASSET = "file")
load("images/img_d5312729.png", IMG_d5312729_ASSET = "file")
load("images/img_d65fbf1d.png", IMG_d65fbf1d_ASSET = "file")
load("images/img_d66d6dd8.png", IMG_d66d6dd8_ASSET = "file")
load("images/img_d6c38ec3.png", IMG_d6c38ec3_ASSET = "file")
load("images/img_d90621cf.png", IMG_d90621cf_ASSET = "file")
load("images/img_d9256392.png", IMG_d9256392_ASSET = "file")
load("images/img_d9aff129.png", IMG_d9aff129_ASSET = "file")
load("images/img_da12145c.png", IMG_da12145c_ASSET = "file")
load("images/img_da28b346.png", IMG_da28b346_ASSET = "file")
load("images/img_dab7257d.png", IMG_dab7257d_ASSET = "file")
load("images/img_daf4928d.png", IMG_daf4928d_ASSET = "file")
load("images/img_db3467bc.png", IMG_db3467bc_ASSET = "file")
load("images/img_dbd35ead.png", IMG_dbd35ead_ASSET = "file")
load("images/img_dbeda978.png", IMG_dbeda978_ASSET = "file")
load("images/img_dbf03acd.png", IMG_dbf03acd_ASSET = "file")
load("images/img_dc7c6dae.png", IMG_dc7c6dae_ASSET = "file")
load("images/img_dcc262f9.png", IMG_dcc262f9_ASSET = "file")
load("images/img_dce53603.png", IMG_dce53603_ASSET = "file")
load("images/img_dcf2b7e9.png", IMG_dcf2b7e9_ASSET = "file")
load("images/img_df9d4dcd.png", IMG_df9d4dcd_ASSET = "file")
load("images/img_dfa588f4.png", IMG_dfa588f4_ASSET = "file")
load("images/img_e05df4d0.png", IMG_e05df4d0_ASSET = "file")
load("images/img_e0a6898d.png", IMG_e0a6898d_ASSET = "file")
load("images/img_e157efd1.png", IMG_e157efd1_ASSET = "file")
load("images/img_e1bc7095.png", IMG_e1bc7095_ASSET = "file")
load("images/img_e20a300f.png", IMG_e20a300f_ASSET = "file")
load("images/img_e2211141.png", IMG_e2211141_ASSET = "file")
load("images/img_e26d2c33.png", IMG_e26d2c33_ASSET = "file")
load("images/img_e2787cf6.png", IMG_e2787cf6_ASSET = "file")
load("images/img_e2e264ba.png", IMG_e2e264ba_ASSET = "file")
load("images/img_e2ff6a77.png", IMG_e2ff6a77_ASSET = "file")
load("images/img_e37b7101.png", IMG_e37b7101_ASSET = "file")
load("images/img_e4135835.png", IMG_e4135835_ASSET = "file")
load("images/img_e467b2d1.png", IMG_e467b2d1_ASSET = "file")
load("images/img_e541d809.png", IMG_e541d809_ASSET = "file")
load("images/img_e57eb69d.png", IMG_e57eb69d_ASSET = "file")
load("images/img_e5aca4c2.png", IMG_e5aca4c2_ASSET = "file")
load("images/img_e5d66bec.png", IMG_e5d66bec_ASSET = "file")
load("images/img_e68e0595.png", IMG_e68e0595_ASSET = "file")
load("images/img_e6ff54df.png", IMG_e6ff54df_ASSET = "file")
load("images/img_e7630448.png", IMG_e7630448_ASSET = "file")
load("images/img_e8d91197.png", IMG_e8d91197_ASSET = "file")
load("images/img_e97e40b3.png", IMG_e97e40b3_ASSET = "file")
load("images/img_e9a6eeb9.png", IMG_e9a6eeb9_ASSET = "file")
load("images/img_ea41a9ab.png", IMG_ea41a9ab_ASSET = "file")
load("images/img_ea9f2bc1.png", IMG_ea9f2bc1_ASSET = "file")
load("images/img_eac81a2b.png", IMG_eac81a2b_ASSET = "file")
load("images/img_ebbbff33.png", IMG_ebbbff33_ASSET = "file")
load("images/img_ebf4d673.png", IMG_ebf4d673_ASSET = "file")
load("images/img_ebfb8247.png", IMG_ebfb8247_ASSET = "file")
load("images/img_ec6582a0.png", IMG_ec6582a0_ASSET = "file")
load("images/img_ec6cca6c.png", IMG_ec6cca6c_ASSET = "file")
load("images/img_eca6dc7a.png", IMG_eca6dc7a_ASSET = "file")
load("images/img_eca7c1d5.png", IMG_eca7c1d5_ASSET = "file")
load("images/img_edd22972.png", IMG_edd22972_ASSET = "file")
load("images/img_ede8987f.png", IMG_ede8987f_ASSET = "file")
load("images/img_ef2959e9.png", IMG_ef2959e9_ASSET = "file")
load("images/img_ef5598e9.png", IMG_ef5598e9_ASSET = "file")
load("images/img_efd089f7.png", IMG_efd089f7_ASSET = "file")
load("images/img_f0881c75.png", IMG_f0881c75_ASSET = "file")
load("images/img_f0be8093.png", IMG_f0be8093_ASSET = "file")
load("images/img_f0d5bdbd.png", IMG_f0d5bdbd_ASSET = "file")
load("images/img_f1bf08a8.png", IMG_f1bf08a8_ASSET = "file")
load("images/img_f286c8f8.png", IMG_f286c8f8_ASSET = "file")
load("images/img_f3373dd0.png", IMG_f3373dd0_ASSET = "file")
load("images/img_f358007d.png", IMG_f358007d_ASSET = "file")
load("images/img_f36ddfc8.png", IMG_f36ddfc8_ASSET = "file")
load("images/img_f37fa009.png", IMG_f37fa009_ASSET = "file")
load("images/img_f417042b.png", IMG_f417042b_ASSET = "file")
load("images/img_f429a718.png", IMG_f429a718_ASSET = "file")
load("images/img_f44b0f57.png", IMG_f44b0f57_ASSET = "file")
load("images/img_f4f00986.png", IMG_f4f00986_ASSET = "file")
load("images/img_f56bf033.png", IMG_f56bf033_ASSET = "file")
load("images/img_f671efb3.png", IMG_f671efb3_ASSET = "file")
load("images/img_f695c54c.png", IMG_f695c54c_ASSET = "file")
load("images/img_f791860b.png", IMG_f791860b_ASSET = "file")
load("images/img_f93b16d4.png", IMG_f93b16d4_ASSET = "file")
load("images/img_f9501866.png", IMG_f9501866_ASSET = "file")
load("images/img_f9c32675.png", IMG_f9c32675_ASSET = "file")
load("images/img_fa5f36c4.png", IMG_fa5f36c4_ASSET = "file")
load("images/img_fb8f6141.png", IMG_fb8f6141_ASSET = "file")
load("images/img_fc10ee06.png", IMG_fc10ee06_ASSET = "file")
load("images/img_fc132309.png", IMG_fc132309_ASSET = "file")
load("images/img_fc801cc8.png", IMG_fc801cc8_ASSET = "file")
load("images/img_fcf61125.png", IMG_fcf61125_ASSET = "file")
load("images/img_ff81cbb4.png", IMG_ff81cbb4_ASSET = "file")
load("images/img_ff88cf18.png", IMG_ff88cf18_ASSET = "file")
load("images/img_ffc4d578.png", IMG_ffc4d578_ASSET = "file")
load("images/img_fff2997d.png", IMG_fff2997d_ASSET = "file")

# Animation values
FPS = 16
ANI_FRAMES = (0, (3 * FPS) / 240, (5 * FPS) / 240, (10 * FPS) / 240, (12 * FPS) / 240, 1)  # Start, hold 3s, slide 2s, hold 5s, slide 2s, hold 3s

# Lexicon: Each row is single glyph; each glyph has indices of:
# [0] GLYPH; [1] VALYRIAN; [2:5] ENGLISH; [5] BASE64
# UNICODE:
# a bar - \u0101
# e bar - \u0113
# i bar - \u012B
# o bar - \u014D
# u bar - \u016B
# y 'bar' - \u0177
# n tilde - \u00F1
# New entry template:    ["fileName", "valyrian", "english1", "english2", "english3", "base64"],
LEXICON = [
    ["a", "\u0101", "glyph for long a", "", "", IMG_e05df4d0_ASSET.readall()],
    ["air", "paghar", "air", "breath", "", IMG_343b1fec_ASSET.readall()],
    ["air2", "paghagon", "to breathe", "to inhale", "", IMG_343b1fec_ASSET.readall()],
    ["amaranth", "olzon", "amaranth", "", "", IMG_d4f6a9bc_ASSET.readall()],
    ["and", "selagon", "to agree", "to head for", "to make for", IMG_8c54e932_ASSET.readall()],
    ["and2", "se", "and", "", "", IMG_8c54e932_ASSET.readall()],
    ["apple", "pr\u016Bbres", "apple", "", "", IMG_5c23a564_ASSET.readall()],
    ["arakh", "arakhi", "arakh", "(Dothraki", "borrowing)", IMG_2de4eb6b_ASSET.readall()],
    ["area", "\u0101lion", "area", "place", "location", IMG_cd0aa873_ASSET.readall()],
    ["arm", "\u00F1\u014Dghe", "arm", "", "", IMG_52acdbf8_ASSET.readall()],
    ["arrange", "verdagon", "to arrange", "to order", "to deal in", IMG_7d6b1bb8_ASSET.readall()],
    ["arrow", "p\u0113je", "arrow", "", "", IMG_60be0f88_ASSET.readall()],
    ["art", "\u0177s", "art", "", "", IMG_364287e1_ASSET.readall()],
    ["ash", "\u00F1uqir", "ash", "ashes", "", IMG_1c5839b3_ASSET.readall()],
    ["ask", "epagon", "to ask", "to inquire", "to query", IMG_37b8e9b2_ASSET.readall()],
    ["avoid", "kulogon", "to avoid", "to dodge", "to go around", IMG_a669e1ca_ASSET.readall()],
    ["awake", "kiragon", "to be awake", "to be up", "", IMG_454aeb79_ASSET.readall()],
    ["b", "b", "glyph for b", "", "", IMG_b936c178_ASSET.readall()],
    ["back", "inkon", "back", "back side", "", IMG_9b0b947c_ASSET.readall()],
    ["back2", "ampa", "ten (10)", "", "", IMG_9b0b947c_ASSET.readall()],
    ["barley", "\u0101ro", "barley", "", "", IMG_caabb991_ASSET.readall()],
    ["basket", "g\u016Bron", "basket", "", "", IMG_f0be8093_ASSET.readall()],
    ["bat", "massa", "bat", "", "", IMG_0af07890_ASSET.readall()],
    ["bean", "l\u0101gho", "bean", "", "", IMG_6d057349_ASSET.readall()],
    ["beans", "l\u0101ghor", "beans", "", "", IMG_b8d899ea_ASSET.readall()],
    ["bear", "gryves", "bear", "", "", IMG_e2211141_ASSET.readall()],
    ["beard", "rhotton", "beard", "", "", IMG_898be070_ASSET.readall()],
    ["beautiful", "gevie", "beautiful", "", "", IMG_e6ff54df_ASSET.readall()],
    ["bed", "ilvos", "bed", "", "", IMG_b881b4bf_ASSET.readall()],
    ["bee", "\u0113s", "bee", "", "", IMG_11d33d71_ASSET.readall()],
    ["beet", "kr\u0113go", "beet", "", "", IMG_bedc975a_ASSET.readall()],
    ["beetle", "heltar", "beetle", "", "", IMG_698a261e_ASSET.readall()],
    ["big", "r\u014Dva", "big", "large", "", IMG_dce53603_ASSET.readall()],
    ["bigbrother", "l\u0113kia", "older", "brother", "", IMG_6b1e1dfb_ASSET.readall()],
    ["bigsister", "mandia", "older", "sister", "", IMG_3fbe769c_ASSET.readall()],
    ["bird", "ao", "you (singular)", "", "", IMG_5e199dfe_ASSET.readall()],
    ["bird2", "hontes", "bird", "", "", IMG_5e199dfe_ASSET.readall()],
    ["bite", "angogon", "to bite", "", "", IMG_aad4b90e_ASSET.readall()],
    ["bitter", "geba", "bitter", "acrid", "", IMG_80df8a2d_ASSET.readall()],
    ["blackberry", "vusko", "blackberry", "", "", IMG_6ace12ff_ASSET.readall()],
    ["blood", "\u0101nogar", "blood", "", "", IMG_489e5875_ASSET.readall()],
    ["boar", "qryldes", "boar", "pig (m)", "", IMG_44190441_ASSET.readall()],
    ["boar2", "beqes", "pig (f)", "", "", IMG_44190441_ASSET.readall()],
    ["boat", "l\u014Dgor", "boat", "ship", "", IMG_ccbf354a_ASSET.readall()],
    ["body", "m\u0113ny", "body", "", "", IMG_9fbf19f5_ASSET.readall()],
    ["bone", "\u012Bby", "bone", "", "", IMG_37d77da0_ASSET.readall()],
    ["boot", "landis", "shoe", "boot", "", IMG_66680117_ASSET.readall()],
    ["bound", "pyghagon", "to jump", "to leap", "to bounce", IMG_8c56925d_ASSET.readall()],
    ["boy", "taoba", "boy", "", "", IMG_f93b16d4_ASSET.readall()],
    ["boy2", "tr\u0113sy", "son", "parallel nephew", "", IMG_f93b16d4_ASSET.readall()],
    ["brace", "aena", "supportive", "reliable", "", IMG_d4f62d6c_ASSET.readall()],
    ["brain", "\u00F1aka", "brain", "", "", IMG_e8d91197_ASSET.readall()],
    ["bread", "havon", "bread", "", "", IMG_2b4e5523_ASSET.readall()],
    ["break", "pryjagon", "to destroy", "to ruin", "to break", IMG_102270a1_ASSET.readall()],
    ["breeze", "pisti", "breeze", "", "", IMG_4a7c673c_ASSET.readall()],
    ["bring", "maghagon", "to bring", "to carry", "", IMG_85daa81c_ASSET.readall()],
    ["bull", "vandis", "bull", "cow (m)", "", IMG_e7630448_ASSET.readall()],
    ["bull2", "nuspes", "cow (f)", "", "", IMG_e7630448_ASSET.readall()],
    ["burn", "z\u0101lagon", "to burn", "", "", IMG_d2700eee_ASSET.readall()],
    ["burst", "biragon", "to burst", "to explode", "to break", IMG_c1f013c2_ASSET.readall()],
    ["bury", "tojagon", "to bury", "", "", IMG_95cfdb18_ASSET.readall()],
    ["butcher", "heghagon", "to slaughter", "", "", IMG_eca7c1d5_ASSET.readall()],
    ["buy", "sindigon", "to buy", "to purchase", "", IMG_6dc5b73e_ASSET.readall()],
    ["canyon", "rios", "valley", "canyon", "", IMG_aedf19d4_ASSET.readall()],
    ["carrot", "onjapos", "carrot", "", "", IMG_ce652728_ASSET.readall()],
    ["case", "pragron", "case", "shell", "husk", IMG_1ff1bd74_ASSET.readall()],
    ["cat", "k\u0113li", "cat", "kitty", "", IMG_ccabb773_ASSET.readall()],
    ["cedar", "uela", "cedar", "", "", IMG_373b9e95_ASSET.readall()],
    ["celery", "n\u014Dro", "celery", "celery stalk", "", IMG_2d52cd35_ASSET.readall()],
    ["certain", "s\u012Blie", "certain", "absolute", "definite", IMG_8feaf675_ASSET.readall()],
    ["chain", "belmon", "chain", "", "", IMG_657e3596_ASSET.readall()],
    ["charge", "gaemagon", "to charge", "to rush", "", IMG_7c79b70a_ASSET.readall()],
    ["chase", "daenagon", "to pursue", "to chase", "", IMG_7177f42d_ASSET.readall()],
    ["cherry", "jerde", "cherry", "", "", IMG_02ecf4d9_ASSET.readall()],
    ["chest", "naejos", "chest", "pectorals", "breast", IMG_aeb17303_ASSET.readall()],
    ["chop", "jukagon", "to cleave", "to chop", "", IMG_41225b8a_ASSET.readall()],
    ["city", "oktion", "city", "", "", IMG_3535ded2_ASSET.readall()],
    ["clay", "indor", "clay", "", "", IMG_15a85268_ASSET.readall()],
    ["climb", "hepagon", "to climb", "to ascend", "", IMG_da12145c_ASSET.readall()],
    ["closingstrike", ")", "equivalent", "to a closed", "parenthesis", IMG_13b9d9c8_ASSET.readall()],
    ["cloud", "sambar", "cloud", "", "", IMG_b115ed02_ASSET.readall()],
    ["cold", "iosre", "cold", "(to the touch)", "", IMG_b17e1219_ASSET.readall()],
    ["come", "m\u0101zigon", "to come", "to arrive", "", IMG_132289fe_ASSET.readall()],
    ["control", "visagon", "to control", "to manage", "to handle", IMG_ca0b237a_ASSET.readall()],
    ["cool", "qapa", "cold", "(internally)", "", IMG_0173a662_ASSET.readall()],
    ["copper", "br\u0101edy", "bell", "", "", IMG_d90621cf_ASSET.readall()],
    ["core", "ripo", "core", "pit", "", IMG_05bf35c9_ASSET.readall()],
    ["crawl", "tyvagon", "to crawl", "to creep", "", IMG_ae6fbbe8_ASSET.readall()],
    ["crooked", "onga", "crooked", "gnarled", "wrinkled", IMG_367fbb29_ASSET.readall()],
    ["cross", "\u012Bligon", "to cross", "to retread", "", IMG_1d664423_ASSET.readall()],
    ["crystal", "z\u0101eres", "crystal", "gem", "", IMG_0eb5b914_ASSET.readall()],
    ["curve", "oba", "curved", "arched", "convex", IMG_f9c32675_ASSET.readall()],
    ["curve2", "obagon", "to curve", "to bow", "to bend", IMG_f9c32675_ASSET.readall()],
    ["cyclic", "are", "cyclic", "rhythmic", "repetitive", IMG_148947fd_ASSET.readall()],
    ["d", "d", "glyph for d", "", "", IMG_e20a300f_ASSET.readall()],
    ["dadsbigsister", "velma", "father's", "older", "sister", IMG_8a3e81d6_ASSET.readall()],
    ["dadslittlesister", "\u00F1\u0101mar", "father's", "younger", "sister", IMG_65cdae9f_ASSET.readall()],
    ["dance", "lilagon", "to dance", "", "", IMG_0ea82d76_ASSET.readall()],
    ["dark", "zomir", "darkness", "", "", IMG_ba840454_ASSET.readall()],
    ["dawn", "\u014Dz", "dawn", "", "", IMG_dab7257d_ASSET.readall()],
    ["day", "tubis", "day", "", "", IMG_b6db5b4c_ASSET.readall()],
    ["death", "morghon", "death", "", "", IMG_660a7c41_ASSET.readall()],
    ["deer", "myrdys", "doe", "deer (f)", "", IMG_db3467bc_ASSET.readall()],
    ["deer2", "velkrys", "stag", "deer (m)", "", IMG_db3467bc_ASSET.readall()],
    ["defeat", "\u0113rinagon", "to defeat", "to conquer", "to vanquish", IMG_dbeda978_ASSET.readall()],
    ["dig", "rudigon", "to dig", "", "", IMG_9ad214b6_ASSET.readall()],
    ["digit", "t\u0101emis", "digit", "finger", "toe", IMG_9070668c_ASSET.readall()],
    ["dip", "iovagon", "to dip", "to dunk", "to submerge", IMG_f1bf08a8_ASSET.readall()],
    ["do", "gaomagon", "to do", "to act", "to perform", IMG_6da77693_ASSET.readall()],
    ["dog", "jaos", "dog", "", "", IMG_becc34a0_ASSET.readall()],
    ["dole", "tyragon", "to distribute", "to share", "to dole out", IMG_92405d1a_ASSET.readall()],
    ["doom", "v\u0113jes", "doom", "fate", "", IMG_dfa588f4_ASSET.readall()],
    ["door", "nerny", "door", "mouth of a cave", "", IMG_78fd2646_ASSET.readall()],
    ["doubledot", ":", "punctuation", "used to separate", "clauses", IMG_44aa0861_ASSET.readall()],
    ["drag", "ql\u0101dugon", "to drag", "", "", IMG_efd089f7_ASSET.readall()],
    ["dragon", "zaldr\u012Bzes", "dragon", "", "", IMG_58bf3f03_ASSET.readall()],
    ["dragonfly", "r\u0177z", "dragonfly", "", "", IMG_1496d30d_ASSET.readall()],
    ["drain", "qeragon", "to drain", "to empty", "to dissolve", IMG_99ddbcf7_ASSET.readall()],
    ["drakarys", "drakarys", "dragonfire", "", "", IMG_eca6dc7a_ASSET.readall()],
    ["drill", "l\u014Dry", "drill", "hand drill", "", IMG_d9aff129_ASSET.readall()],
    ["drill2", "l\u014Dragon", "to drill", "to bore", "", IMG_d9aff129_ASSET.readall()],
    ["drink", "m\u014Dzugon", "to drink", "", "", IMG_788fea83_ASSET.readall()],
    ["drop", "rughagon", "to drop", "", "", IMG_102e8b5f_ASSET.readall()],
    ["drum", "meme", "drum", "", "", IMG_06566dad_ASSET.readall()],
    ["dry", "tista", "dry", "", "", IMG_c27baa64_ASSET.readall()],
    ["duck", "ezar", "duck", "", "", IMG_4e42c77b_ASSET.readall()],
    ["dull", "ruaka", "dull", "ineffective", "", IMG_9d7512db_ASSET.readall()],
    ["dust", "jeson", "dust", "powder", "", IMG_b5aec4f3_ASSET.readall()],
    ["e", "\u0113", "glyph for long e", "", "", IMG_5f19fc72_ASSET.readall()],
    ["eagle", "z\u0113res", "eagle", "", "", IMG_a329cbbf_ASSET.readall()],
    ["ear", "eleks", "ear", "", "", IMG_6f2391b6_ASSET.readall()],
    ["earth", "tegon", "ground", "earth", "soil", IMG_943275e3_ASSET.readall()],
    ["eat", "kis-", "used with", "words for", "eating", IMG_f671efb3_ASSET.readall()],
    ["eel", "ubles", "eel", "", "", IMG_2b81c1e2_ASSET.readall()],
    ["egg", "dr\u014Dmon", "egg", "", "", IMG_41732d45_ASSET.readall()],
    ["eight", "j\u0113nqa", "eight (8)", "", "", IMG_e2e264ba_ASSET.readall()],
    ["ember", "jehys", "ember", "glowing coal", "", IMG_25126822_ASSET.readall()],
    ["enye", "\u00F1", "glyph for \u00F1", "", "", IMG_223b29a2_ASSET.readall()],
    ["equal", "g\u012Bda", "equal", "steady", "stable", IMG_f37fa009_ASSET.readall()],
    ["evil", "k\u014Dz", "bad", "evil", "wicked", IMG_0642f8c6_ASSET.readall()],
    ["eye", "laes", "eye", "", "", IMG_7a213967_ASSET.readall()],
    ["fall", "ropagon", "to fall", "", "", IMG_c2943145_ASSET.readall()],
    ["father", "kepa", "father", "dad", "paternal uncle", IMG_7d786d9d_ASSET.readall()],
    ["fear", "z\u016Bgagon", "to fear", "to be afraid", "", IMG_0170f3a6_ASSET.readall()],
    ["feather", "t\u012Bkos", "feather", "", "", IMG_1b3b0fe1_ASSET.readall()],
    ["fig", "r\u014Dbir", "fig", "", "", IMG_9fe6f5b9_ASSET.readall()],
    ["fight", "azandy", "short sword", "", "", IMG_ffc4d578_ASSET.readall()],
    ["fill", "leghagon", "to fill", "", "", IMG_f417042b_ASSET.readall()],
    ["finish", "tatagon", "to finish", "", "", IMG_ef2959e9_ASSET.readall()],
    ["fire", "perzys", "fire", "", "", IMG_4528d6f5_ASSET.readall()],
    ["firstperson", "nyke", "I (pronoun)", "", "", IMG_62b16948_ASSET.readall()],
    ["fish", "klios", "fish", "", "", IMG_7048bad6_ASSET.readall()],
    ["fish2", "adere", "quick", "smooth", "slippery", IMG_7048bad6_ASSET.readall()],
    ["five", "t\u014Dma", "five (5)", "", "", IMG_6597a4cb_ASSET.readall()],
    ["flap", "lytagon", "to flap", "", "", IMG_e467b2d1_ASSET.readall()],
    ["flesh", "\u00F1elly", "skin", "flesh", "", IMG_cef700cc_ASSET.readall()],
    ["flow", "i\u0101ragon", "to flow", "to run", "to go", IMG_73799785_ASSET.readall()],
    ["flower", "r\u016Bklon", "flower", "", "", IMG_028f08d5_ASSET.readall()],
    ["fly", "s\u014Dvion", "butterfly", "", "", IMG_b043bbd8_ASSET.readall()],
    ["fold", "lurugon", "to fold", "", "", IMG_2638e74e_ASSET.readall()],
    ["follow", "pikagon", "to follow", "", "", IMG_9f4899f0_ASSET.readall()],
    ["food", "havor", "food", "sustenance", "", IMG_d5312729_ASSET.readall()],
    ["foot", "deks", "foot", "step", "", IMG_129c2e2f_ASSET.readall()],
    ["forest", "gu\u0113sin", "forest", "woods", "", IMG_ebbbff33_ASSET.readall()],
    ["four", "arlie", "new", "", "", IMG_03df1022_ASSET.readall()],
    ["four2", "izula", "four (4)", "", "", IMG_03df1022_ASSET.readall()],
    ["fox", "lanty", "fox", "", "", IMG_45391861_ASSET.readall()],
    ["free", "d\u0101ez", "free", "", "", IMG_80b06068_ASSET.readall()],
    ["frog", "reks", "frog", "", "", IMG_8bb2be89_ASSET.readall()],
    ["fruit", "gerpa", "fruit", "", "", IMG_7b9cea26_ASSET.readall()],
    ["furrow", "grozagon", "to plow", "", "", IMG_dcf2b7e9_ASSET.readall()],
    ["g", "g", "glyph for g", "", "", IMG_8c6a096a_ASSET.readall()],
    ["garlic", "zubon", "garlic", "", "", IMG_aea47e56_ASSET.readall()],
    ["gate", "remio", "gate", "city gate", "", IMG_af01bb72_ASSET.readall()],
    ["giant", "labar", "giant", "", "", IMG_4bc7f232_ASSET.readall()],
    ["girl", "ri\u00F1a", "girl", "child", "", IMG_0657582f_ASSET.readall()],
    ["girl2", "tala", "daughter", "parallel niece", "", IMG_0657582f_ASSET.readall()],
    ["give", "tepagon", "to give", "", "", IMG_edd22972_ASSET.readall()],
    ["glass", "jenys", "glass", "", "", IMG_65c2833d_ASSET.readall()],
    ["go", "jagon", "to go", "", "", IMG_a393c0fb_ASSET.readall()],
    ["goat", "hobres", "goat (m)", "jerk", "", IMG_8509b544_ASSET.readall()],
    ["goat2", "epses", "goat (f)", "", "", IMG_8509b544_ASSET.readall()],
    ["god", "jaes", "god", "deity", "", IMG_bfdfd33c_ASSET.readall()],
    ["gold", "\u0101eksion", "gold", "", "", IMG_7b378372_ASSET.readall()],
    ["good", "s\u0177z", "good", "", "", IMG_ba8d9d6b_ASSET.readall()],
    ["grape", "avero", "grape", "", "", IMG_ebf4d673_ASSET.readall()],
    ["grapes", "averun", "bunch", "of", "grapes", IMG_59d0f054_ASSET.readall()],
    ["grass", "parmon", "grass", "", "", IMG_9eeb917e_ASSET.readall()],
    ["great", "kara", "great", "magnificent", "excellent", IMG_7179ac10_ASSET.readall()],
    ["grind", "\u00F1uragon", "to grind", "to mash", "", IMG_9af675c9_ASSET.readall()],
    ["guard", "m\u012Bsagon", "to guard", "to defend", "to clothe", IMG_b09b6a2c_ASSET.readall()],
    ["guess", "ot\u0101pagon", "to guess", "to opine", "to think", IMG_4ef97216_ASSET.readall()],
    ["guest", "zentys", "guest", "", "", IMG_350945ee_ASSET.readall()],
    ["gull", "bratsi", "gull", "seagull", "", IMG_e5d66bec_ASSET.readall()],
    ["h", "h", "glyph for h", "", "", IMG_4aaaf365_ASSET.readall()],
    ["hack", "rhupagon", "to hack", "to chip", "to split", IMG_6492bfd1_ASSET.readall()],
    ["half", "ez\u012Bmi", "half", "", "", IMG_370d572d_ASSET.readall()],
    ["hammer", "galry", "hammer", "mallet", "", IMG_32565d0c_ASSET.readall()],
    ["hand", "ondos", "hand", "agency", "", IMG_ceab5bc4_ASSET.readall()],
    ["hand2", "pakton", "right", "right side", "right hand", IMG_ceab5bc4_ASSET.readall()],
    ["hang", "b\u0113rigon", "to hang", "", "", IMG_4e7f4cee_ASSET.readall()],
    ["have", "emagon", "to have", "", "", IMG_ff88cf18_ASSET.readall()],
    ["hazel", "rhaegor", "hazel tree", "", "", IMG_8b11911e_ASSET.readall()],
    ["head", "bartos", "head", "", "", IMG_8cc9bdad_ASSET.readall()],
    ["healthy", "rytsa", "healthy", "well", "hale", IMG_4ef52a21_ASSET.readall()],
    ["heart", "pr\u016Bmia", "heart", "", "", IMG_4d4ec311_ASSET.readall()],
    ["heavy", "kempa", "heavy", "weighty", "impressive", IMG_bbfa4dd8_ASSET.readall()],
    ["heft", "osragon", "to pick up", "to lift", "to heft", IMG_8b34be00_ASSET.readall()],
    ["helm", "gelte", "helmet", "helm", "", IMG_732f703c_ASSET.readall()],
    ["help", "baelagon", "to help", "to assist", "to aid", IMG_31943655_ASSET.readall()],
    ["hide", "ruaragon", "to hide", "to conceal", "", IMG_b6025a94_ASSET.readall()],
    ["high", "eglie", "high", "superior", "late", IMG_e68e0595_ASSET.readall()],
    ["hit", "h\u012Blagon", "to punch", "to hit", "to strike", IMG_daf4928d_ASSET.readall()],
    ["hold", "pilogon", "to hold", "onto", "", IMG_7800371e_ASSET.readall()],
    ["hole", "nopon", "hole", "pit", "", IMG_ce12b4d4_ASSET.readall()],
    ["honey", "elilla", "honey", "", "", IMG_fa5f36c4_ASSET.readall()],
    ["hook", "\u016Bly", "hook", "", "", IMG_3f1768fa_ASSET.readall()],
    ["horse", "anne", "horse", "", "", IMG_000895e8_ASSET.readall()],
    ["hot", "b\u0101ne", "hot", "(to the touch)", "", IMG_e9a6eeb9_ASSET.readall()],
    ["house", "lenton", "house", "home", "", IMG_e5aca4c2_ASSET.readall()],
    ["hunger", "merbugon", "to be hungry", "to hunger", "", IMG_17018e13_ASSET.readall()],
    ["hunt", "arghugon", "to hunt", "", "", IMG_515844f2_ASSET.readall()],
    ["i", "\u012B", "glyph for long i", "", "", IMG_9e54b83f_ASSET.readall()],
    ["ignite", "pradagon", "to activate", "to start", "to ignite", IMG_681721a6_ASSET.readall()],
    ["ice", "suvion", "ice", "", "", IMG_f9501866_ASSET.readall()],
    ["imprint", "k\u012Bvo", "imprint", "footprint", "stamp", IMG_e1bc7095_ASSET.readall()],
    ["infant", "r\u016Bs", "infant", "baby", "child", IMG_0e3a66db_ASSET.readall()],
    ["iron", "\u0101egion", "iron", "", "", IMG_2a490f73_ASSET.readall()],
    ["island", "\u0101jon", "island", "", "", IMG_55840d36_ASSET.readall()],
    ["it", "\u016Bja", "she, he, it", "(terrestrial and", "aquatic nouns)", IMG_2dd6c75e_ASSET.readall()],
    ["ivy", "joro", "ivy", "", "", IMG_58992dee_ASSET.readall()],
    ["j", "j", "glyph for j", "", "", IMG_33d742d8_ASSET.readall()],
    ["jasmine", "ovo\u00F1o", "jasmine", "", "", IMG_8168175a_ASSET.readall()],
    ["joyful", "jessie", "joyful", "exultant", "", IMG_0be1a635_ASSET.readall()],
    ["k", "k", "glyph for k", "", "", IMG_b5e6635d_ASSET.readall()],
    ["kae", "kae-", "used with", "words for", "salvation", IMG_75fce320_ASSET.readall()],
    ["keep", "r\u0101elagon", "to keep", "to maintain", "to retain", IMG_fcf61125_ASSET.readall()],
    ["kidney", "rhemo", "kidney", "", "", IMG_4bb59a72_ASSET.readall()],
    ["kill", "s\u0113nagon", "to kill", "", "", IMG_1766844d_ASSET.readall()],
    ["kiln", "peri", "kiln", "", "", IMG_f695c54c_ASSET.readall()],
    ["king", "d\u0101rys", "king", "monarch", "", IMG_7495d6d6_ASSET.readall()],
    ["king2", "d\u0101ria", "queen", "", "", IMG_7495d6d6_ASSET.readall()],
    ["l", "l", "glyph for l", "", "", IMG_8ce4e1d2_ASSET.readall()],
    ["lake", "n\u0101var", "lake", "", "", IMG_52330bf0_ASSET.readall()],
    ["laugh", "s\u014Dpagon", "to laugh", "", "", IMG_48898bce_ASSET.readall()],
    ["lava", "runar", "lava", "", "", IMG_a518fef0_ASSET.readall()],
    ["lead", "jemagon", "to lead", "to guide", "", IMG_97351477_ASSET.readall()],
    ["leaf", "temby", "leaf", "palm frond", "page", IMG_ea9f2bc1_ASSET.readall()],
    ["leak", "nehugon", "to leak", "to seep", "to ooze", IMG_6ad8f103_ASSET.readall()],
    ["lean", "resagon", "to lean", "to list", "", IMG_5007b979_ASSET.readall()],
    ["leather", "rongon", "leather", "hide", "animal skin", IMG_c5bfbb4d_ASSET.readall()],
    ["left", "gepton", "left", "left side", "left hand", IMG_84d0f068_ASSET.readall()],
    ["leg", "kris", "leg", "", "", IMG_3e248790_ASSET.readall()],
    ["lie", "ilagon", "to lie", "to be straight", "to be at", IMG_f429a718_ASSET.readall()],
    ["lilac", "saere", "lilac", "", "", IMG_a7bb9c07_ASSET.readall()],
    ["lime", "g\u0177s", "lime", "", "", IMG_cd9a5743_ASSET.readall()],
    ["line", "qogron", "row", "line", "rank", IMG_d0cb6059_ASSET.readall()],
    ["little", "byka", "small", "little", "", IMG_6a0f296a_ASSET.readall()],
    ["littlebrother", "valonqar", "younger", "brother", "", IMG_c528d50c_ASSET.readall()],
    ["littlesister", "h\u0101edar", "younger", "sister", "", IMG_c99f70eb_ASSET.readall()],
    ["lizard", "r\u012Bza", "lizard", "reptile", "", IMG_676a8565_ASSET.readall()],
    ["ll", "ll", "ligature for", "double l", "", IMG_3953c4ba_ASSET.readall()],
    ["like", "raqagon", "to like", "to love", "to appreciate", IMG_61dda01c_ASSET.readall()],
    ["long", "b\u014Dsa", "long", "tall", "", IMG_83142870_ASSET.readall()],
    ["low", "quba", "low", "inferior", "previous", IMG_0046cde2_ASSET.readall()],
    ["luck", "biare", "fortunate", "lucky", "happy", IMG_26353c5a_ASSET.readall()],
    ["lung", "m\u014Ds", "lung", "", "", IMG_ec6582a0_ASSET.readall()],
    ["lungwort", "odinge", "lungwort", "", "", IMG_a456babe_ASSET.readall()],
    ["m", "m", "glyph for m", "", "", IMG_3306f5d7_ASSET.readall()],
    ["maegi", "maegi", "soothsayer", "fortune teller", "", IMG_a648a491_ASSET.readall()],
    ["man", "vala", "man", "", "", IMG_33b8d4e5_ASSET.readall()],
    ["manage", "r\u012Bnagon", "to manage", "to handle", "to oversee", IMG_82de5f87_ASSET.readall()],
    ["many", "naena", "many", "multitude", "horde", IMG_0d56a3e3_ASSET.readall()],
    ["marry", "d\u012Bnagon", "to put", "to place", "to marry", IMG_883b369c_ASSET.readall()],
    ["match", "z\u0177ragon", "to match", "to fit", "to go with", IMG_528870df_ASSET.readall()],
    ["meat", "parklon", "meat", "", "", IMG_9abb1767_ASSET.readall()],
    ["meet", "rhaenagon", "to meet", "to discover", "to begin", IMG_43379e54_ASSET.readall()],
    ["melt", "hivagon", "to melt", "", "", IMG_642dd209_ASSET.readall()],
    ["memory", "r\u016Bnagon", "to remember", "to recall", "", IMG_45f3bfd5_ASSET.readall()],
    ["middot", "\u00B7", "punctuation", "used to separate", "words", IMG_a3e544c0_ASSET.readall()],
    ["midnight", "bant\u0101zma", "midnight", "", "", IMG_33a78435_ASSET.readall()],
    ["milk", "j\u016Blor", "milk", "", "", IMG_c1d7f5aa_ASSET.readall()],
    ["mint", "z\u0101kon", "mint", "", "", IMG_2a781cf7_ASSET.readall()],
    ["momsbigbrother", "i\u0101pa", "mother's", "older", "brother", IMG_c0bb9938_ASSET.readall()],
    ["momslittlebrother", "q\u0177bor", "mother's", "younger", "brother", IMG_51855cc8_ASSET.readall()],
    ["monkey", "gaba", "monkey", "", "", IMG_534760bf_ASSET.readall()],
    ["moon", "h\u016Bra", "moon", "", "", IMG_51101e9e_ASSET.readall()],
    ["mother", "mu\u00F1a", "mother", "mom", "maternal aunt", IMG_a45516f6_ASSET.readall()],
    ["mountain", "bl\u0113non", "mountain", "", "", IMG_7b4a8bb3_ASSET.readall()],
    ["mountainrange", "bl\u0113nun", "mountain", "range", "", IMG_88399df2_ASSET.readall()],
    ["mouth", "relgos", "mouth (human)", "", "", IMG_b0f1487f_ASSET.readall()],
    ["move", "aeragon", "to move", "to go", "", IMG_e57eb69d_ASSET.readall()],
    ["much", "olvie", "much", "a lot", "many", IMG_434556cd_ASSET.readall()],
    ["mud", "vaogar", "mud", "filth", "", IMG_6dfd3924_ASSET.readall()],
    ["mushroom", "nollon", "mushroom", "", "", IMG_c37e6d72_ASSET.readall()],
    ["n", "n", "glyph for n", "", "", IMG_5f9a7766_ASSET.readall()],
    ["nadir", "gaos", "belly (animal)", "nadir", "underside", IMG_24b88d0e_ASSET.readall()],
    ["name", "br\u014Dzagon", "to name", "", "", IMG_1d23f50d_ASSET.readall()],
    ["narrow", "\u0177rda", "narrow", "", "", IMG_a1f0cad4_ASSET.readall()],
    ["neck", "yrgos", "neck", "throat", "", IMG_4c0f45f3_ASSET.readall()],
    ["night", "bantis", "night", "", "", IMG_a1a1c53d_ASSET.readall()],
    ["nightsky", "\u0113brion", "night sky", "", "", IMG_3ea955cc_ASSET.readall()],
    ["nine", "v\u014Dre", "nine (9)", "", "", IMG_2772a852_ASSET.readall()],
    ["nn", "nn", "ligature for", "double n", "", IMG_7beca465_ASSET.readall()],
    ["nose", "pungos", "nose", "", "", IMG_73c3aea3_ASSET.readall()],
    ["not", "daor", "no", "not", "", IMG_1b5670b8_ASSET.readall()],
    ["o", "\u014D", "glyph for long o", "", "", IMG_e2ff6a77_ASSET.readall()],
    ["obsolete", "n\u016Bda", "gray", "antiquated", "obsolete", IMG_8bdde982_ASSET.readall()],
    ["ocean", "embar", "sea", "ocean", "", IMG_24123ab8_ASSET.readall()],
    ["old", "u\u0113pa", "old", "elderly", "", IMG_9676518d_ASSET.readall()],
    ["oldeat", "kis-", "older version", "of the kis-", "glyph", IMG_4988c657_ASSET.readall()],
    ["oleander", "helaenor", "oleander", "oleander bush", "", IMG_baa19a11_ASSET.readall()],
    ["olive", "p\u0113ko", "olive", "", "", IMG_dc7c6dae_ASSET.readall()],
    ["one", "m\u0113re", "one (1)", "only", "sole", IMG_646b75c3_ASSET.readall()],
    ["openingstrike", "(", "equivalent", "to an opening", "parenthesis", IMG_65523acb_ASSET.readall()],
    ["orchid", "votre", "orchid", "", "", IMG_eac81a2b_ASSET.readall()],
    ["other", "tolie", "other", "higher", "next", IMG_ba2c6d96_ASSET.readall()],
    ["owl", "atroksia", "owl", "", "", IMG_0f5f59e9_ASSET.readall()],
    ["p", "p", "glyph for p", "", "", IMG_482c85e7_ASSET.readall()],
    ["palm", "nine", "palm of the hand", "", "", IMG_4b5cb580_ASSET.readall()],
    ["path", "geron", "path", "walkway", "", IMG_ebfb8247_ASSET.readall()],
    ["peel", "dyragon", "to peel", "", "", IMG_1ff7438c_ASSET.readall()],
    ["pelican", "manengi", "pelican", "", "", IMG_3aa06f79_ASSET.readall()],
    ["pelican2", "manengagon", "to scoop", "to ladle", "", IMG_3aa06f79_ASSET.readall()],
    ["pile", "k\u0101ro", "heap", "pile", "", IMG_1eb62354_ASSET.readall()],
    ["pillar", "q\u012Bzy", "pillar", "support", "post", IMG_2cd705ce_ASSET.readall()],
    ["plan", "k\u0177vagon", "to plan", "to strategize", "to conceive", IMG_71be53bf_ASSET.readall()],
    ["planet", "v\u0177s", "planet", "world", "", IMG_1538813b_ASSET.readall()],
    ["play", "tymagon", "to play", "to frolic", "to gambol", IMG_25aae965_ASSET.readall()],
    ["pluck", "deragon", "to pluck", "to pick", "", IMG_e97e40b3_ASSET.readall()],
    ["poke", "t\u0113magon", "to poke", "to prod", "to prick", IMG_91ee487d_ASSET.readall()],
    ["pomegranate", "n\u0113\u00F1o", "pomegranate", "", "", IMG_4ab39d0c_ASSET.readall()],
    ["poppy", "j\u014Dz", "poppy", "", "", IMG_6603993a_ASSET.readall()],
    ["pot", "\u00F1uton", "pot", "cooking pot", "", IMG_757ac791_ASSET.readall()],
    ["pot2", "keragon", "to cook", "", "", IMG_757ac791_ASSET.readall()],
    ["pound", "qepagon", "to pound", "to flatten", "to tamp", IMG_357b0697_ASSET.readall()],
    ["pour", "hulagon", "to pour", "", "", IMG_7fc5baa6_ASSET.readall()],
    ["power", "kostagon", "to be able", "can (aux)", "", IMG_655d9ef3_ASSET.readall()],
    ["praise", "rijagon", "to praise", "to laud", "", IMG_e157efd1_ASSET.readall()],
    ["press", "p\u0177nagon", "to press", "to squeeze", "to compress", IMG_6f6e0c3e_ASSET.readall()],
    ["pretty", "litse", "pretty", "cute", "fair", IMG_9a1bf3e0_ASSET.readall()],
    ["priest", "voktys", "priest", "priestess", "", IMG_613c6e2a_ASSET.readall()],
    ["prop", "t\u0101ragon", "to pitch", "to prop up", "", IMG_4e6932b6_ASSET.readall()],
    ["protrude", "hyngagon", "to protrude", "to stick out", "to extend", IMG_6998830a_ASSET.readall()],
    ["pull", "hakogon", "to pull", "to bother", "to annoy", IMG_594a9325_ASSET.readall()],
    ["pure", "v\u014Dka", "pure", "", "", IMG_00de1706_ASSET.readall()],
    ["push", "indigon", "to push", "to intend", "to mean to do", IMG_d051ed2f_ASSET.readall()],
    ["put", "hannagon", "to put in place", "", "", IMG_dcc262f9_ASSET.readall()],
    ["q", "q", "glyph for q", "", "", IMG_293ef48a_ASSET.readall()],
    ["r", "r", "glyph for r", "", "", IMG_bfbe7b80_ASSET.readall()],
    ["rabbit", "hunes", "rabbit", "bunny", "hare", IMG_d66d6dd8_ASSET.readall()],
    ["rain", "daomio", "rain", "", "", IMG_e37b7101_ASSET.readall()],
    ["ram", "\u014Dtor", "ram", "sheep (m)", "", IMG_8a03b04c_ASSET.readall()],
    ["raven", "v\u014Dljes", "raven", "", "", IMG_5caafb10_ASSET.readall()],
    ["rh", "rh", "glyph for rh", "", "", IMG_f791860b_ASSET.readall()],
    ["rice", "m\u0101lor", "rice", "", "", IMG_52f7cfd2_ASSET.readall()],
    ["ride", "kipagon", "to ride", "", "", IMG_c80ad1be_ASSET.readall()],
    ["rip", "tessagon", "to rip", "to tear", "", IMG_0a6966dc_ASSET.readall()],
    ["rise", "s\u012Bmagon", "to rise", "to float up", "", IMG_b6a1798e_ASSET.readall()],
    ["river", "qelbar", "river", "", "", IMG_b46a7943_ASSET.readall()],
    ["roll", "s\u014Dlugon", "to roll", "to tumble", "", IMG_ef5598e9_ASSET.readall()],
    ["rooster", "\u00F1oves", "rooster", "chicken (m)", "", IMG_73829cac_ASSET.readall()],
    ["rooster2", "qulbes", "hen", "chicken (f)", "", IMG_73829cac_ASSET.readall()],
    ["rope", "hubon", "rope", "cord", "", IMG_8264bdbd_ASSET.readall()],
    ["rose", "r\u0113ko", "rose", "", "", IMG_ad910c1d_ASSET.readall()],
    ["rot", "puatagon", "to rot", "to shrivel", "to go bad", IMG_e4135835_ASSET.readall()],
    ["rough", "rhinka", "rough", "coarse", "unpleasant", IMG_8bde1fe3_ASSET.readall()],
    ["rr", "rr", "ligature", "for", "double r", IMG_08282460_ASSET.readall()],
    ["rub", "pamagon", "to rub", "to pet", "", IMG_96a52ab3_ASSET.readall()],
    ["run", "dakogon", "to run", "", "", IMG_328f7e3a_ASSET.readall()],
    ["s", "s", "glyph for s", "", "", IMG_5b9ba9bb_ASSET.readall()],
    ["safe", "\u0177gha", "safe", "secure", "", IMG_0332728e_ASSET.readall()],
    ["salt", "lopon", "salt", "", "", IMG_5dd1e297_ASSET.readall()],
    ["sambucus", "t\u014Dmo", "elderflower", "sambucus", "", IMG_199cb10f_ASSET.readall()],
    ["same", "h\u0113nka", "same", "similar", "", IMG_fb8f6141_ASSET.readall()],
    ["sand", "rizmon", "sand", "", "", IMG_b124fca6_ASSET.readall()],
    ["scalp", "ziksos", "neck", "scalp", "", IMG_15cb6988_ASSET.readall()],
    ["scorpion", "raedes", "scorpion", "", "", IMG_584da881_ASSET.readall()],
    ["scrape", "gisagon", "to scrape", "", "", IMG_4aaafaea_ASSET.readall()],
    ["scratch", "purtagon", "to scratch", "to scour", "to score", IMG_32c93a2e_ASSET.readall()],
    ["scream", "h\u012Bghagon", "to scream", "to wail", "to cry out", IMG_8bb505c8_ASSET.readall()],
    ["screech", "jitsagon", "to screech", "to yelp", "to yowl", IMG_a32c14d9_ASSET.readall()],
    ["seed", "n\u016Bmo", "pod", "seed", "nut", IMG_b0bb2ddb_ASSET.readall()],
    ["sell", "lioragon", "to sell", "", "", IMG_73ac00ff_ASSET.readall()],
    ["sense", "hylagon", "to feel", "to sense", "", IMG_1996a3ee_ASSET.readall()],
    ["separate", "viragon", "to separate", "to thresh out", "to pull apart", IMG_93b94d70_ASSET.readall()],
    ["serve", "dohaeragon", "to serve", "", "", IMG_fc801cc8_ASSET.readall()],
    ["seven", "s\u012Bkuda", "seven (7)", "", "", IMG_2b1ff3f8_ASSET.readall()],
    ["seven2", "sagon", "to be (copula)", "", "", IMG_2b1ff3f8_ASSET.readall()],
    ["sew", "\u00F1epegon", "to sew", "", "", IMG_ea41a9ab_ASSET.readall()],
    ["sharp", "qana", "sharp", "effective", "", IMG_0c43cc24_ASSET.readall()],
    ["she", "ziry", "she, he, it", "(lunar and", "solar nouns)", IMG_14ee66b8_ASSET.readall()],
    ["sheep", "bianor", "sheep (f)", "", "", IMG_9a378c5b_ASSET.readall()],
    ["shield", "somby", "shield", "", "", IMG_7cc07c4f_ASSET.readall()],
    ["short", "m\u012Bba", "short", "", "", IMG_51cace8b_ASSET.readall()],
    ["shoulder", "q\u012Bbi", "shoulder", "back of the neck", "shoulder area", IMG_125fedab_ASSET.readall()],
    ["shove", "v\u0101degon", "to position", "to put in place", "", IMG_5f62d838_ASSET.readall()],
    ["show", "arrigon", "to show", "to display", "", IMG_d6c38ec3_ASSET.readall()],
    ["sibling", "dubys", "sibling", "parallel cousin", "", IMG_73f84085_ASSET.readall()],
    ["silk", "kyno", "silkworm", "", "", IMG_cf5a277e_ASSET.readall()],
    ["silver", "g\u0113lion", "silver", "", "", IMG_a1146f3c_ASSET.readall()],
    ["sing", "v\u0101edagon", "to sing", "", "", IMG_01715500_ASSET.readall()],
    ["sit", "d\u0113magon", "to sit", "to sit down", "", IMG_fc10ee06_ASSET.readall()],
    ["six", "b\u0177re", "six (6)", "", "", IMG_f0881c75_ASSET.readall()],
    ["sleep", "\u0113drugon", "to sleep", "", "", IMG_b0caa942_ASSET.readall()],
    ["slow", "paez", "slow", "sluggish", "", IMG_67152b06_ASSET.readall()],
    ["smile", "l\u012Brigon", "to smile", "", "", IMG_c6d3bb20_ASSET.readall()],
    ["smoke", "\u014Drbar", "smoke", "", "", IMG_921f19cf_ASSET.readall()],
    ["snout", "\u0101psos", "snout", "muzzle", "mouth", IMG_afd68cdd_ASSET.readall()],
    ["snow", "s\u014Dna", "snow", "", "", IMG_a8b016dd_ASSET.readall()],
    ["soil", "balon", "soil", "", "", IMG_da28b346_ASSET.readall()],
    ["solid", "l\u014Dta", "solid", "hard", "durable", IMG_27de4edf_ASSET.readall()],
    ["sour", "v\u012Bga", "sour", "", "", IMG_89a25482_ASSET.readall()],
    ["sparrow", "urghes", "sparrow", "", "", IMG_c0a8b968_ASSET.readall()],
    ["speak", "\u0177dragon", "to speak", "to talk", "", IMG_f36ddfc8_ASSET.readall()],
    ["spider", "vaokses", "spider", "", "", IMG_45730155_ASSET.readall()],
    ["spring", "ki\u014Ds", "spring (season)", "", "", IMG_f358007d_ASSET.readall()],
    ["squid", "u\u0113s", "squid", "", "", IMG_62998aec_ASSET.readall()],
    ["squirrel", "rola", "squirrel", "", "", IMG_be0c85cd_ASSET.readall()],
    ["ss", "ss", "ligature for", "double s", "", IMG_d9256392_ASSET.readall()],
    ["stand", "i\u014Dragon", "to stand", "to be in a state", "", IMG_521a31c6_ASSET.readall()],
    ["star", "q\u0113los", "star", "", "", IMG_5f833f86_ASSET.readall()],
    ["steer", "soljagon", "to guide", "to steer", "to pilot", IMG_698ebb7d_ASSET.readall()],
    ["stomach", "iemny", "stomach", "belly (human)", "", IMG_ae25e30a_ASSET.readall()],
    ["stone", "d\u014Dron", "stone", "rock", "", IMG_0562f401_ASSET.readall()],
    ["stone2", "qighagon", "to pile", "to stack", "", IMG_0562f401_ASSET.readall()],
    ["storm", "jelm\u0101zma", "storm", "violent winds", "", IMG_dbf03acd_ASSET.readall()],
    ["strawberry", "z\u014Dro", "strawberry", "", "", IMG_97a0aab6_ASSET.readall()],
    ["stretch", "korzigon", "to stretch", "to extend", "to last", IMG_8fc2c9a7_ASSET.readall()],
    ["struggle", "ambigon", "to struggle", "", "", IMG_bd421031_ASSET.readall()],
    ["stuck", "suez", "stuck", "jammed", "wedged", IMG_65c37fb8_ASSET.readall()],
    ["suckle", "b\u012Bbagon", "to suckle", "", "", IMG_b3a4e1ea_ASSET.readall()],
    ["summer", "jaedos", "summer", "", "", IMG_c9a82150_ASSET.readall()],
    ["sun", "v\u0113zos", "sun", "", "", IMG_61c00db0_ASSET.readall()],
    ["sunrise", "\u00F1\u0101qien", "sunrise", "", "", IMG_b7b3d9f5_ASSET.readall()],
    ["sunrise2", "dr\u016Br", "tomorrow", "", "", IMG_b7b3d9f5_ASSET.readall()],
    ["sunset", "endien", "sunset", "", "", IMG_b9bc0652_ASSET.readall()],
    ["sunset2", "z\u0101n", "yesterday", "", "", IMG_b9bc0652_ASSET.readall()],
    ["swap", "milagon", "to swap", "to switch", "", IMG_76cebc01_ASSET.readall()],
    ["sweet", "d\u014Dna", "sweet", "pleasant", "", IMG_d65fbf1d_ASSET.readall()],
    ["swell", "h\u014Dzigon", "to swell", "", "", IMG_67144415_ASSET.readall()],
    ["swim", "bughegon", "to swim", "", "", IMG_f4f00986_ASSET.readall()],
    ["t", "t", "glyph for t", "", "", IMG_4d4c8728_ASSET.readall()],
    ["table", "qurdon", "table", "", "", IMG_3fd96b2f_ASSET.readall()],
    ["tail", "bode", "tail", "", "", IMG_43d3a952_ASSET.readall()],
    ["targaryen", "Targ\u0101rien", "Targaryen", "", "", IMG_8bbe124c_ASSET.readall()],
    ["tea", "s\u016Bmo", "tea leaf", "", "", IMG_4d6f7fe4_ASSET.readall()],
    ["tear", "q\u016Bvy", "tear", "teardrop", "", IMG_ca811654_ASSET.readall()],
    ["tear2", "limagon", "to cry", "to weep", "", IMG_ca811654_ASSET.readall()],
    ["they", "p\u014Dnta", "they", "", "", IMG_a56fa996_ASSET.readall()],
    ["thick", "qumblie", "thick", "", "", IMG_515a3efd_ASSET.readall()],
    ["thigh", "pore", "thigh", "", "", IMG_451b5ade_ASSET.readall()],
    ["thin", "vasrie", "thin", "", "", IMG_be727a48_ASSET.readall()],
    ["thing", "non", "thing", "", "", IMG_a9f24bd5_ASSET.readall()],
    ["three", "h\u0101re", "three (3)", "", "", IMG_32d8a2d5_ASSET.readall()],
    ["through", "r\u0113bagon", "to pass through", "to go through", "to undergo", IMG_8acb20fb_ASSET.readall()],
    ["throw", "ilzigon", "to throw", "to sow", "to bore", IMG_c8253fc8_ASSET.readall()],
    ["toil", "botagon", "to work", "to endure", "to suffer", IMG_a1caadf6_ASSET.readall()],
    ["tongue", "\u0113ngos", "tongue", "language", "dialect", IMG_6d6fddfc_ASSET.readall()],
    ["tooth", "\u0101tsio", "tooth", "", "", IMG_791666e7_ASSET.readall()],
    ["top", "baes", "top", "summit", "tip", IMG_7e719373_ASSET.readall()],
    ["touch", "renigon", "to touch", "", "", IMG_ede8987f_ASSET.readall()],
    ["tree", "gu\u0113se", "tree", "", "", IMG_12e239eb_ASSET.readall()],
    ["trout", "b\u0113gor", "trout", "", "", IMG_042a14e8_ASSET.readall()],
    ["true", "dr\u0113je", "true", "right", "correct", IMG_2ca15f7c_ASSET.readall()],
    ["ts", "ts", "ligature", "for", "ts", IMG_ec6cca6c_ASSET.readall()],
    ["tt", "tt", "ligature", "for", "double t", IMG_8ff0f1ca_ASSET.readall()],
    ["turn", "p\u0101legon", "to twist", "to turn", "to rotate", IMG_ff81cbb4_ASSET.readall()],
    ["turtle", "qintir", "turtle", "", "", IMG_fc132309_ASSET.readall()],
    ["two", "lanta", "two (2)", "", "", IMG_343463ad_ASSET.readall()],
    ["type", "l\u016Bs", "type", "kind", "", IMG_7d16c8ac_ASSET.readall()],
    ["tyrant", "qr\u012Bnio", "tyrant", "dictator", "", IMG_f286c8f8_ASSET.readall()],
    ["tys", "tys", "ligature for tys", "", "", IMG_c7d6cdfc_ASSET.readall()],
    ["u", "\u016B", "glyph for long u", "", "", IMG_23c591e3_ASSET.readall()],
    ["uproot", "terragon", "to uproot", "to unearth", "to dig up", IMG_c68adb54_ASSET.readall()],
    ["v", "v", "glyph for v", "", "", IMG_6def6c83_ASSET.readall()],
    ["valyria", "Valyria", "Valyria", "", "", IMG_b536e582_ASSET.readall()],
    ["vapor", "konor", "vapor", "steam", "", IMG_b3462530_ASSET.readall()],
    ["veil", "laodi", "veil", "", "", IMG_2a130ed2_ASSET.readall()],
    ["veil2", "laodigon", "to abduct", "to steal", "to cover", IMG_2a130ed2_ASSET.readall()],
    ["velaryon", "velagon", "to oscillate", "to bob", "", IMG_2714c1d7_ASSET.readall()],
    ["violet", "daema", "violet (flower)", "", "", IMG_16d94002_ASSET.readall()],
    ["warm", "dija", "hot", "(internally)", "", IMG_f56bf033_ASSET.readall()],
    ["warn", "vermagon", "to warn", "to alert", "", IMG_697bc9b8_ASSET.readall()],
    ["water", "i\u0113dar", "water", "", "", IMG_261e1d4b_ASSET.readall()],
    ["waterowl", "-ria", "glyph used as a", "determinative", "for some nouns", IMG_440722e7_ASSET.readall()],
    ["wave", "pelar", "wave", "", "", IMG_dbd35ead_ASSET.readall()],
    ["we", "\u012Blon", "we", "", "", IMG_e0a6898d_ASSET.readall()],
    ["wet", "l\u014Dz", "wet", "damp", "moist", IMG_d0ba34e8_ASSET.readall()],
    ["whale", "qaedar", "whale", "", "", IMG_f0d5bdbd_ASSET.readall()],
    ["what", "skoros", "what", "", "", IMG_bba517ec_ASSET.readall()],
    ["wheel", "grevy", "wheel", "", "", IMG_101b3ea6_ASSET.readall()],
    ["whip", "qil\u014Dny", "whip", "", "", IMG_e541d809_ASSET.readall()],
    ["whip2", "qil\u014Dnagon", "to whip", "to chastise", "to punish", IMG_e541d809_ASSET.readall()],
    ["whirl", "s\u016Bsagon", "to whirl", "to twirl", "to spin", IMG_e2787cf6_ASSET.readall()],
    ["whole", "giez", "whole", "complete", "together", IMG_f44b0f57_ASSET.readall()],
    ["wide", "dr\u0101\u00F1e", "wide", "", "", IMG_676293f7_ASSET.readall()],
    ["wilt", "gosagon", "to wilt", "to wither", "", IMG_57ba32b4_ASSET.readall()],
    ["wind", "jelmio", "wind", "", "", IMG_d48108c0_ASSET.readall()],
    ["wipe", "r\u0101enagon", "to wipe", "to brush", "", IMG_7b91d8b1_ASSET.readall()],
    ["wolf", "zokla", "wolf", "", "", IMG_df9d4dcd_ASSET.readall()],
    ["woman", "\u0101bra", "woman", "", "", IMG_f3373dd0_ASSET.readall()],
    ["wood", "tijon", "wood", "", "", IMG_47f66c07_ASSET.readall()],
    ["word", "udir", "word", "", "", IMG_658926ff_ASSET.readall()],
    ["worm", "turgon", "worm", "", "", IMG_c1cd6731_ASSET.readall()],
    ["write", "bardugon", "to write", "", "", IMG_fff2997d_ASSET.readall()],
    ["x", "ks", "ligature for ks", "", "", IMG_e26d2c33_ASSET.readall()],
    ["y", "\u0177", "glyph for long y", "", "", IMG_6124ffc7_ASSET.readall()],
    ["y2", "g\u0101r", "hundred (100)", "", "", IMG_6124ffc7_ASSET.readall()],
    ["young", "suene", "young", "youthful", "", IMG_2a1e2785_ASSET.readall()],
    ["z", "z", "glyph for z", "", "", IMG_1360a5b4_ASSET.readall()],
    ["zero", "daorun", "zero (0)", "nothing", "null", IMG_24f547f4_ASSET.readall()],
    ["zr", "zr", "ligature for", "zr or sr", "", IMG_16c32784_ASSET.readall()],
]

def main():
    # Render for display
    g = random.number(0, len(LEXICON))  # Min and max of range is inclusive
    # print("INDEX: " + str(g) + "; GLYPH: " + LEXICON[g][0])

    glyph = LEXICON[g][5]
    name = LEXICON[g][1]
    words = LEXICON[g][2:5]

    if g >= 0:
        return render_full(glyph, name, words)
    else:
        return render.Root(
            child = render.Box(color = "#000"),
        )

def render_full(glyph, name, words):
    # Render and return root with animation
    glyph = base64.decode(glyph)
    glyph_bg = "#000000"  # Color of glyph background
    name_bg = "#632b26"  # Color of name box background
    name_color = "#ffffff"  # Color of name text
    word_color = "#ffffff"  # Color of words text
    word_bg = "#000000"  # Color of words background
    alpha = "DD"  # Opacity setting for overlay (00 = transparent; FF = opaque)
    name_font = "tb-8"  # Do not change font (must maintain diacritics); max 10 characters
    word_font = "tom-thumb"  # tom-thumb: 16 max chars
    height = 32  # Height of Tidbyt
    height_name = 11  # Height of name box
    height_space = 1  # Height of space between name box and words

    # Render for display
    return render.Root(
        show_full_animation = True,
        child = render.Stack(
            children = [
                # Glyph
                render.Box(
                    child = render.Image(src = glyph),
                    color = glyph_bg,
                    width = 64,
                    height = 32,
                ),
                # Text overlay
                animation.Transformation(
                    child = render.Column(
                        expanded = True,
                        children = [
                            # Name
                            render.Box(
                                width = 64,
                                height = height_name,
                                color = name_bg + alpha,
                                child = render.WrappedText(
                                    content = name,
                                    align = "center",
                                    color = name_color,
                                    font = name_font,
                                    linespacing = 0,
                                ),
                            ),
                            # Spacer
                            render.Box(
                                width = 64,
                                height = height_space,
                                color = word_bg + alpha,
                            ),
                            # Words
                            render.Box(
                                width = 64,
                                height = height - height_name - height_space,
                                color = word_bg + alpha,
                                child = render.WrappedText(
                                    content = "\n".join(words),
                                    align = "center",
                                    color = word_color,
                                    font = word_font,
                                    width = 64,
                                    linespacing = 1,
                                ),
                            ),
                        ],
                    ),
                    duration = 15 * FPS,
                    delay = 0,
                    keyframes = [
                        animation.Keyframe(
                            percentage = ANI_FRAMES[0],  # Start
                            transforms = [animation.Translate(0, 33)],
                        ),
                        animation.Keyframe(
                            percentage = ANI_FRAMES[1],
                            transforms = [animation.Translate(0, 33)],
                            curve = "ease_in_out",
                        ),
                        animation.Keyframe(
                            percentage = ANI_FRAMES[2],  # Slide overlay in
                            transforms = [animation.Translate(0, 0)],
                        ),
                        animation.Keyframe(
                            percentage = ANI_FRAMES[3],
                            transforms = [animation.Translate(0, 0)],
                            curve = "ease_in_out",
                        ),
                        animation.Keyframe(
                            percentage = ANI_FRAMES[4],  # Slide overlay out
                            transforms = [animation.Translate(0, 33)],
                        ),
                        animation.Keyframe(
                            percentage = ANI_FRAMES[5],
                            transforms = [animation.Translate(0, 33)],
                        ),
                    ],
                ),
            ],
        ),
    )
