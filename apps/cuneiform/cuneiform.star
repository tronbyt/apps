"""
Applet: Cuneiform
Summary: Random cuneiform signs
Description: Shows a cuneiform sign and its Sumerian transliterations.
Author: dinosaursrarr
"""

load("encoding/base64.star", "base64")
load("hash.star", "hash")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("images/img_008ee812.png", IMG_008ee812_ASSET = "file")
load("images/img_00d495a1.png", IMG_00d495a1_ASSET = "file")
load("images/img_00d7f0e7.png", IMG_00d7f0e7_ASSET = "file")
load("images/img_0131dfd1.png", IMG_0131dfd1_ASSET = "file")
load("images/img_017fad4d.png", IMG_017fad4d_ASSET = "file")
load("images/img_01a69d08.png", IMG_01a69d08_ASSET = "file")
load("images/img_01f62c5a.png", IMG_01f62c5a_ASSET = "file")
load("images/img_01f643f7.png", IMG_01f643f7_ASSET = "file")
load("images/img_039c993b.png", IMG_039c993b_ASSET = "file")
load("images/img_0456196d.png", IMG_0456196d_ASSET = "file")
load("images/img_05870392.png", IMG_05870392_ASSET = "file")
load("images/img_06375f4f.png", IMG_06375f4f_ASSET = "file")
load("images/img_0649f3d8.png", IMG_0649f3d8_ASSET = "file")
load("images/img_06e8fe9a.png", IMG_06e8fe9a_ASSET = "file")
load("images/img_07082229.png", IMG_07082229_ASSET = "file")
load("images/img_098ad690.png", IMG_098ad690_ASSET = "file")
load("images/img_0a638198.png", IMG_0a638198_ASSET = "file")
load("images/img_0b109a10.png", IMG_0b109a10_ASSET = "file")
load("images/img_0d03c6a4.png", IMG_0d03c6a4_ASSET = "file")
load("images/img_0d98e366.png", IMG_0d98e366_ASSET = "file")
load("images/img_0de0477b.png", IMG_0de0477b_ASSET = "file")
load("images/img_0e182320.png", IMG_0e182320_ASSET = "file")
load("images/img_10aede87.png", IMG_10aede87_ASSET = "file")
load("images/img_11d11e94.png", IMG_11d11e94_ASSET = "file")
load("images/img_12574514.png", IMG_12574514_ASSET = "file")
load("images/img_130f493c.png", IMG_130f493c_ASSET = "file")
load("images/img_1319d59a.png", IMG_1319d59a_ASSET = "file")
load("images/img_147c5f13.png", IMG_147c5f13_ASSET = "file")
load("images/img_15a590ea.png", IMG_15a590ea_ASSET = "file")
load("images/img_15ef3770.png", IMG_15ef3770_ASSET = "file")
load("images/img_166b035b.png", IMG_166b035b_ASSET = "file")
load("images/img_168e92b2.png", IMG_168e92b2_ASSET = "file")
load("images/img_17616339.png", IMG_17616339_ASSET = "file")
load("images/img_1765af05.png", IMG_1765af05_ASSET = "file")
load("images/img_183b22b1.png", IMG_183b22b1_ASSET = "file")
load("images/img_1903fc8c.png", IMG_1903fc8c_ASSET = "file")
load("images/img_19875dd5.png", IMG_19875dd5_ASSET = "file")
load("images/img_19c34ba3.png", IMG_19c34ba3_ASSET = "file")
load("images/img_19c7d5d9.png", IMG_19c7d5d9_ASSET = "file")
load("images/img_19dfb4f9.png", IMG_19dfb4f9_ASSET = "file")
load("images/img_1a52be18.png", IMG_1a52be18_ASSET = "file")
load("images/img_1be39411.png", IMG_1be39411_ASSET = "file")
load("images/img_1c47a7ae.png", IMG_1c47a7ae_ASSET = "file")
load("images/img_1d27c49d.png", IMG_1d27c49d_ASSET = "file")
load("images/img_1dde43e0.png", IMG_1dde43e0_ASSET = "file")
load("images/img_1ef1f750.png", IMG_1ef1f750_ASSET = "file")
load("images/img_1f3365eb.png", IMG_1f3365eb_ASSET = "file")
load("images/img_1f90a499.png", IMG_1f90a499_ASSET = "file")
load("images/img_1fa09832.png", IMG_1fa09832_ASSET = "file")
load("images/img_1ff4fb5a.png", IMG_1ff4fb5a_ASSET = "file")
load("images/img_201cb86e.png", IMG_201cb86e_ASSET = "file")
load("images/img_213172d4.png", IMG_213172d4_ASSET = "file")
load("images/img_21573837.png", IMG_21573837_ASSET = "file")
load("images/img_216891b8.png", IMG_216891b8_ASSET = "file")
load("images/img_219f1f7b.png", IMG_219f1f7b_ASSET = "file")
load("images/img_22b1a7e5.png", IMG_22b1a7e5_ASSET = "file")
load("images/img_22b9fa14.png", IMG_22b9fa14_ASSET = "file")
load("images/img_24903bdf.png", IMG_24903bdf_ASSET = "file")
load("images/img_24e507b6.png", IMG_24e507b6_ASSET = "file")
load("images/img_2510cef5.png", IMG_2510cef5_ASSET = "file")
load("images/img_261799a9.png", IMG_261799a9_ASSET = "file")
load("images/img_27fd535f.png", IMG_27fd535f_ASSET = "file")
load("images/img_28f09589.png", IMG_28f09589_ASSET = "file")
load("images/img_2a4ea728.png", IMG_2a4ea728_ASSET = "file")
load("images/img_2a89976b.png", IMG_2a89976b_ASSET = "file")
load("images/img_2f3856c8.png", IMG_2f3856c8_ASSET = "file")
load("images/img_2f52c2e6.png", IMG_2f52c2e6_ASSET = "file")
load("images/img_30c579bf.png", IMG_30c579bf_ASSET = "file")
load("images/img_324b402e.png", IMG_324b402e_ASSET = "file")
load("images/img_336672dc.png", IMG_336672dc_ASSET = "file")
load("images/img_34322a74.png", IMG_34322a74_ASSET = "file")
load("images/img_34de12ae.png", IMG_34de12ae_ASSET = "file")
load("images/img_357712cc.png", IMG_357712cc_ASSET = "file")
load("images/img_35a05541.png", IMG_35a05541_ASSET = "file")
load("images/img_3644238a.png", IMG_3644238a_ASSET = "file")
load("images/img_369e3814.png", IMG_369e3814_ASSET = "file")
load("images/img_36f18d71.png", IMG_36f18d71_ASSET = "file")
load("images/img_38b85b02.png", IMG_38b85b02_ASSET = "file")
load("images/img_39008c85.png", IMG_39008c85_ASSET = "file")
load("images/img_3949ba43.png", IMG_3949ba43_ASSET = "file")
load("images/img_395922a9.png", IMG_395922a9_ASSET = "file")
load("images/img_39ddfe5c.png", IMG_39ddfe5c_ASSET = "file")
load("images/img_3a0febf3.png", IMG_3a0febf3_ASSET = "file")
load("images/img_3acec7ac.png", IMG_3acec7ac_ASSET = "file")
load("images/img_3b8a00bf.png", IMG_3b8a00bf_ASSET = "file")
load("images/img_3c50fee1.png", IMG_3c50fee1_ASSET = "file")
load("images/img_3ccd1a65.png", IMG_3ccd1a65_ASSET = "file")
load("images/img_3cd429d6.png", IMG_3cd429d6_ASSET = "file")
load("images/img_3cfc046b.png", IMG_3cfc046b_ASSET = "file")
load("images/img_3d96b2d1.png", IMG_3d96b2d1_ASSET = "file")
load("images/img_3f1643eb.png", IMG_3f1643eb_ASSET = "file")
load("images/img_3f8cc66e.png", IMG_3f8cc66e_ASSET = "file")
load("images/img_3fececeb.png", IMG_3fececeb_ASSET = "file")
load("images/img_400db6b9.png", IMG_400db6b9_ASSET = "file")
load("images/img_409fd636.png", IMG_409fd636_ASSET = "file")
load("images/img_41d66b4c.png", IMG_41d66b4c_ASSET = "file")
load("images/img_421ba246.png", IMG_421ba246_ASSET = "file")
load("images/img_42369512.png", IMG_42369512_ASSET = "file")
load("images/img_4298405e.png", IMG_4298405e_ASSET = "file")
load("images/img_42aa34de.png", IMG_42aa34de_ASSET = "file")
load("images/img_442d2268.png", IMG_442d2268_ASSET = "file")
load("images/img_45215991.png", IMG_45215991_ASSET = "file")
load("images/img_46660b6f.png", IMG_46660b6f_ASSET = "file")
load("images/img_46a3eb00.png", IMG_46a3eb00_ASSET = "file")
load("images/img_482bc582.png", IMG_482bc582_ASSET = "file")
load("images/img_48510370.png", IMG_48510370_ASSET = "file")
load("images/img_48b22fa0.png", IMG_48b22fa0_ASSET = "file")
load("images/img_49a3a018.png", IMG_49a3a018_ASSET = "file")
load("images/img_49aa04bc.png", IMG_49aa04bc_ASSET = "file")
load("images/img_49cd5205.png", IMG_49cd5205_ASSET = "file")
load("images/img_4accea70.png", IMG_4accea70_ASSET = "file")
load("images/img_4af99cb6.png", IMG_4af99cb6_ASSET = "file")
load("images/img_4ba47beb.png", IMG_4ba47beb_ASSET = "file")
load("images/img_4c3c79a0.png", IMG_4c3c79a0_ASSET = "file")
load("images/img_4d69d36c.png", IMG_4d69d36c_ASSET = "file")
load("images/img_4db2562b.png", IMG_4db2562b_ASSET = "file")
load("images/img_4ded3cc4.png", IMG_4ded3cc4_ASSET = "file")
load("images/img_4df96571.png", IMG_4df96571_ASSET = "file")
load("images/img_4e372a11.png", IMG_4e372a11_ASSET = "file")
load("images/img_4e916360.png", IMG_4e916360_ASSET = "file")
load("images/img_4f62b877.png", IMG_4f62b877_ASSET = "file")
load("images/img_5059f42f.png", IMG_5059f42f_ASSET = "file")
load("images/img_5087f1ec.png", IMG_5087f1ec_ASSET = "file")
load("images/img_519c0499.png", IMG_519c0499_ASSET = "file")
load("images/img_5250a5c0.png", IMG_5250a5c0_ASSET = "file")
load("images/img_52674a31.png", IMG_52674a31_ASSET = "file")
load("images/img_5277f975.png", IMG_5277f975_ASSET = "file")
load("images/img_52e1e77a.png", IMG_52e1e77a_ASSET = "file")
load("images/img_52e5691f.png", IMG_52e5691f_ASSET = "file")
load("images/img_52fcb805.png", IMG_52fcb805_ASSET = "file")
load("images/img_5398aebe.png", IMG_5398aebe_ASSET = "file")
load("images/img_53a5ce08.png", IMG_53a5ce08_ASSET = "file")
load("images/img_53ca20e5.png", IMG_53ca20e5_ASSET = "file")
load("images/img_54b3cc09.png", IMG_54b3cc09_ASSET = "file")
load("images/img_55b83bcd.png", IMG_55b83bcd_ASSET = "file")
load("images/img_55d41d0d.png", IMG_55d41d0d_ASSET = "file")
load("images/img_55f52c48.png", IMG_55f52c48_ASSET = "file")
load("images/img_55f6713a.png", IMG_55f6713a_ASSET = "file")
load("images/img_56251961.png", IMG_56251961_ASSET = "file")
load("images/img_56b2b4dd.png", IMG_56b2b4dd_ASSET = "file")
load("images/img_57126452.png", IMG_57126452_ASSET = "file")
load("images/img_572b86d8.png", IMG_572b86d8_ASSET = "file")
load("images/img_57540126.png", IMG_57540126_ASSET = "file")
load("images/img_5779dd1c.png", IMG_5779dd1c_ASSET = "file")
load("images/img_57e6072f.png", IMG_57e6072f_ASSET = "file")
load("images/img_589cd2f8.png", IMG_589cd2f8_ASSET = "file")
load("images/img_58e7856a.png", IMG_58e7856a_ASSET = "file")
load("images/img_59253904.png", IMG_59253904_ASSET = "file")
load("images/img_594a4302.png", IMG_594a4302_ASSET = "file")
load("images/img_5a63e706.png", IMG_5a63e706_ASSET = "file")
load("images/img_5a8a402c.png", IMG_5a8a402c_ASSET = "file")
load("images/img_5afa5769.png", IMG_5afa5769_ASSET = "file")
load("images/img_5b77d506.png", IMG_5b77d506_ASSET = "file")
load("images/img_5ba0eabd.png", IMG_5ba0eabd_ASSET = "file")
load("images/img_5c2398c4.png", IMG_5c2398c4_ASSET = "file")
load("images/img_5c7622cd.png", IMG_5c7622cd_ASSET = "file")
load("images/img_5d3d9022.png", IMG_5d3d9022_ASSET = "file")
load("images/img_5d43ab0e.png", IMG_5d43ab0e_ASSET = "file")
load("images/img_5d9832e7.png", IMG_5d9832e7_ASSET = "file")
load("images/img_5f91f36a.png", IMG_5f91f36a_ASSET = "file")
load("images/img_6061eb46.png", IMG_6061eb46_ASSET = "file")
load("images/img_60719bb7.png", IMG_60719bb7_ASSET = "file")
load("images/img_6081aa9e.png", IMG_6081aa9e_ASSET = "file")
load("images/img_6127e76b.png", IMG_6127e76b_ASSET = "file")
load("images/img_614e9017.png", IMG_614e9017_ASSET = "file")
load("images/img_621dc3a3.png", IMG_621dc3a3_ASSET = "file")
load("images/img_6223134d.png", IMG_6223134d_ASSET = "file")
load("images/img_62a44deb.png", IMG_62a44deb_ASSET = "file")
load("images/img_62fb4c2e.png", IMG_62fb4c2e_ASSET = "file")
load("images/img_644cd76f.png", IMG_644cd76f_ASSET = "file")
load("images/img_64ac5ad3.png", IMG_64ac5ad3_ASSET = "file")
load("images/img_650e754e.png", IMG_650e754e_ASSET = "file")
load("images/img_65854956.png", IMG_65854956_ASSET = "file")
load("images/img_658ec908.png", IMG_658ec908_ASSET = "file")
load("images/img_65c7a63a.png", IMG_65c7a63a_ASSET = "file")
load("images/img_65f11b50.png", IMG_65f11b50_ASSET = "file")
load("images/img_660bf1ee.png", IMG_660bf1ee_ASSET = "file")
load("images/img_68113fc3.png", IMG_68113fc3_ASSET = "file")
load("images/img_681afd8f.png", IMG_681afd8f_ASSET = "file")
load("images/img_68d3ab36.png", IMG_68d3ab36_ASSET = "file")
load("images/img_69305354.png", IMG_69305354_ASSET = "file")
load("images/img_69e30ead.png", IMG_69e30ead_ASSET = "file")
load("images/img_6ae68e6c.png", IMG_6ae68e6c_ASSET = "file")
load("images/img_6b19b302.png", IMG_6b19b302_ASSET = "file")
load("images/img_6c055019.png", IMG_6c055019_ASSET = "file")
load("images/img_6c630f99.png", IMG_6c630f99_ASSET = "file")
load("images/img_6c666fa4.png", IMG_6c666fa4_ASSET = "file")
load("images/img_6c9e5e77.png", IMG_6c9e5e77_ASSET = "file")
load("images/img_6daeea1e.png", IMG_6daeea1e_ASSET = "file")
load("images/img_6e7b2f78.png", IMG_6e7b2f78_ASSET = "file")
load("images/img_6f7be716.png", IMG_6f7be716_ASSET = "file")
load("images/img_709680b5.png", IMG_709680b5_ASSET = "file")
load("images/img_70d31ab9.png", IMG_70d31ab9_ASSET = "file")
load("images/img_70ed3bc3.png", IMG_70ed3bc3_ASSET = "file")
load("images/img_728cd802.png", IMG_728cd802_ASSET = "file")
load("images/img_733a17b6.png", IMG_733a17b6_ASSET = "file")
load("images/img_7359b7b4.png", IMG_7359b7b4_ASSET = "file")
load("images/img_73b3847a.png", IMG_73b3847a_ASSET = "file")
load("images/img_741f8628.png", IMG_741f8628_ASSET = "file")
load("images/img_74239715.png", IMG_74239715_ASSET = "file")
load("images/img_7484f58b.png", IMG_7484f58b_ASSET = "file")
load("images/img_755a18bb.png", IMG_755a18bb_ASSET = "file")
load("images/img_7569ff61.png", IMG_7569ff61_ASSET = "file")
load("images/img_75a79c30.png", IMG_75a79c30_ASSET = "file")
load("images/img_760e9cbe.png", IMG_760e9cbe_ASSET = "file")
load("images/img_762f9145.png", IMG_762f9145_ASSET = "file")
load("images/img_770f2f40.png", IMG_770f2f40_ASSET = "file")
load("images/img_77103ac8.png", IMG_77103ac8_ASSET = "file")
load("images/img_772570ea.png", IMG_772570ea_ASSET = "file")
load("images/img_77859917.png", IMG_77859917_ASSET = "file")
load("images/img_779dd430.png", IMG_779dd430_ASSET = "file")
load("images/img_7884df31.png", IMG_7884df31_ASSET = "file")
load("images/img_7a148ef2.png", IMG_7a148ef2_ASSET = "file")
load("images/img_7a35d308.png", IMG_7a35d308_ASSET = "file")
load("images/img_7a6f0ae1.png", IMG_7a6f0ae1_ASSET = "file")
load("images/img_7adb53aa.png", IMG_7adb53aa_ASSET = "file")
load("images/img_7adcd5e6.png", IMG_7adcd5e6_ASSET = "file")
load("images/img_7b2bff65.png", IMG_7b2bff65_ASSET = "file")
load("images/img_7b72cad8.png", IMG_7b72cad8_ASSET = "file")
load("images/img_7d797889.png", IMG_7d797889_ASSET = "file")
load("images/img_7e680be9.png", IMG_7e680be9_ASSET = "file")
load("images/img_7eb6b209.png", IMG_7eb6b209_ASSET = "file")
load("images/img_7fcdf569.png", IMG_7fcdf569_ASSET = "file")
load("images/img_80a4fd96.png", IMG_80a4fd96_ASSET = "file")
load("images/img_80b66ea8.png", IMG_80b66ea8_ASSET = "file")
load("images/img_80c0607b.png", IMG_80c0607b_ASSET = "file")
load("images/img_82196ac6.png", IMG_82196ac6_ASSET = "file")
load("images/img_82459f39.png", IMG_82459f39_ASSET = "file")
load("images/img_82cb86aa.png", IMG_82cb86aa_ASSET = "file")
load("images/img_834f42c8.png", IMG_834f42c8_ASSET = "file")
load("images/img_837fe4bc.png", IMG_837fe4bc_ASSET = "file")
load("images/img_83955ebf.png", IMG_83955ebf_ASSET = "file")
load("images/img_83acac7e.png", IMG_83acac7e_ASSET = "file")
load("images/img_84954883.png", IMG_84954883_ASSET = "file")
load("images/img_84c76c14.png", IMG_84c76c14_ASSET = "file")
load("images/img_84f2944d.png", IMG_84f2944d_ASSET = "file")
load("images/img_84f3562f.png", IMG_84f3562f_ASSET = "file")
load("images/img_84f5669e.png", IMG_84f5669e_ASSET = "file")
load("images/img_8549eb8c.png", IMG_8549eb8c_ASSET = "file")
load("images/img_85ba258c.png", IMG_85ba258c_ASSET = "file")
load("images/img_85ec0a85.png", IMG_85ec0a85_ASSET = "file")
load("images/img_86066ece.png", IMG_86066ece_ASSET = "file")
load("images/img_871ba23d.png", IMG_871ba23d_ASSET = "file")
load("images/img_873f460b.png", IMG_873f460b_ASSET = "file")
load("images/img_87fcf3f0.png", IMG_87fcf3f0_ASSET = "file")
load("images/img_886e9eed.png", IMG_886e9eed_ASSET = "file")
load("images/img_892cc318.png", IMG_892cc318_ASSET = "file")
load("images/img_8aeb13ed.png", IMG_8aeb13ed_ASSET = "file")
load("images/img_8d7fbc38.png", IMG_8d7fbc38_ASSET = "file")
load("images/img_8ec02b2b.png", IMG_8ec02b2b_ASSET = "file")
load("images/img_8f03f64f.png", IMG_8f03f64f_ASSET = "file")
load("images/img_8f84b41a.png", IMG_8f84b41a_ASSET = "file")
load("images/img_8fad5a68.png", IMG_8fad5a68_ASSET = "file")
load("images/img_8fb0fda3.png", IMG_8fb0fda3_ASSET = "file")
load("images/img_8fbea2b3.png", IMG_8fbea2b3_ASSET = "file")
load("images/img_8fea62bf.png", IMG_8fea62bf_ASSET = "file")
load("images/img_90031e56.png", IMG_90031e56_ASSET = "file")
load("images/img_90bbff63.png", IMG_90bbff63_ASSET = "file")
load("images/img_919c3b3f.png", IMG_919c3b3f_ASSET = "file")
load("images/img_9260075b.png", IMG_9260075b_ASSET = "file")
load("images/img_9303789e.png", IMG_9303789e_ASSET = "file")
load("images/img_93b37396.png", IMG_93b37396_ASSET = "file")
load("images/img_93fbb7d6.png", IMG_93fbb7d6_ASSET = "file")
load("images/img_9414d838.png", IMG_9414d838_ASSET = "file")
load("images/img_944e9af2.png", IMG_944e9af2_ASSET = "file")
load("images/img_94754156.png", IMG_94754156_ASSET = "file")
load("images/img_94adeb55.png", IMG_94adeb55_ASSET = "file")
load("images/img_94bbe360.png", IMG_94bbe360_ASSET = "file")
load("images/img_9508396b.png", IMG_9508396b_ASSET = "file")
load("images/img_95b2230d.png", IMG_95b2230d_ASSET = "file")
load("images/img_95e9e634.png", IMG_95e9e634_ASSET = "file")
load("images/img_962f435d.png", IMG_962f435d_ASSET = "file")
load("images/img_97ec5cc5.png", IMG_97ec5cc5_ASSET = "file")
load("images/img_9891b743.png", IMG_9891b743_ASSET = "file")
load("images/img_98da46ed.png", IMG_98da46ed_ASSET = "file")
load("images/img_997fc62c.png", IMG_997fc62c_ASSET = "file")
load("images/img_99aeb864.png", IMG_99aeb864_ASSET = "file")
load("images/img_99b55fec.png", IMG_99b55fec_ASSET = "file")
load("images/img_99c16546.png", IMG_99c16546_ASSET = "file")
load("images/img_9a008f0d.png", IMG_9a008f0d_ASSET = "file")
load("images/img_9b2d1f64.png", IMG_9b2d1f64_ASSET = "file")
load("images/img_9b4f4586.png", IMG_9b4f4586_ASSET = "file")
load("images/img_9bd70ebe.png", IMG_9bd70ebe_ASSET = "file")
load("images/img_9c158536.png", IMG_9c158536_ASSET = "file")
load("images/img_9ca340e6.png", IMG_9ca340e6_ASSET = "file")
load("images/img_9dbdf155.png", IMG_9dbdf155_ASSET = "file")
load("images/img_9f4942c1.png", IMG_9f4942c1_ASSET = "file")
load("images/img_9f7409b9.png", IMG_9f7409b9_ASSET = "file")
load("images/img_a08593de.png", IMG_a08593de_ASSET = "file")
load("images/img_a1bfe563.png", IMG_a1bfe563_ASSET = "file")
load("images/img_a332da77.png", IMG_a332da77_ASSET = "file")
load("images/img_a334d27f.png", IMG_a334d27f_ASSET = "file")
load("images/img_a38724e4.png", IMG_a38724e4_ASSET = "file")
load("images/img_a3d2583d.png", IMG_a3d2583d_ASSET = "file")
load("images/img_a40b42d9.png", IMG_a40b42d9_ASSET = "file")
load("images/img_a41151c9.png", IMG_a41151c9_ASSET = "file")
load("images/img_a468ef2c.png", IMG_a468ef2c_ASSET = "file")
load("images/img_a4dcaafc.png", IMG_a4dcaafc_ASSET = "file")
load("images/img_a50fae24.png", IMG_a50fae24_ASSET = "file")
load("images/img_a5756217.png", IMG_a5756217_ASSET = "file")
load("images/img_a63bac6d.png", IMG_a63bac6d_ASSET = "file")
load("images/img_a6a16dcc.png", IMG_a6a16dcc_ASSET = "file")
load("images/img_a72167f5.png", IMG_a72167f5_ASSET = "file")
load("images/img_a9195573.png", IMG_a9195573_ASSET = "file")
load("images/img_a9be40f3.png", IMG_a9be40f3_ASSET = "file")
load("images/img_a9ed06f9.png", IMG_a9ed06f9_ASSET = "file")
load("images/img_aa38e834.png", IMG_aa38e834_ASSET = "file")
load("images/img_aa547625.png", IMG_aa547625_ASSET = "file")
load("images/img_aa9ab0f1.png", IMG_aa9ab0f1_ASSET = "file")
load("images/img_ac287bbd.png", IMG_ac287bbd_ASSET = "file")
load("images/img_ac2d6f91.png", IMG_ac2d6f91_ASSET = "file")
load("images/img_ac9ddc3d.png", IMG_ac9ddc3d_ASSET = "file")
load("images/img_acaff5e3.png", IMG_acaff5e3_ASSET = "file")
load("images/img_acf2c701.png", IMG_acf2c701_ASSET = "file")
load("images/img_ad0efefc.png", IMG_ad0efefc_ASSET = "file")
load("images/img_ad33b827.png", IMG_ad33b827_ASSET = "file")
load("images/img_ae085ff7.png", IMG_ae085ff7_ASSET = "file")
load("images/img_ae1685f3.png", IMG_ae1685f3_ASSET = "file")
load("images/img_af779bdd.png", IMG_af779bdd_ASSET = "file")
load("images/img_af8581f1.png", IMG_af8581f1_ASSET = "file")
load("images/img_b02d1b53.png", IMG_b02d1b53_ASSET = "file")
load("images/img_b0efb116.png", IMG_b0efb116_ASSET = "file")
load("images/img_b1b09805.png", IMG_b1b09805_ASSET = "file")
load("images/img_b367ef3e.png", IMG_b367ef3e_ASSET = "file")
load("images/img_b4672c43.png", IMG_b4672c43_ASSET = "file")
load("images/img_b5630b33.png", IMG_b5630b33_ASSET = "file")
load("images/img_b5815ca9.png", IMG_b5815ca9_ASSET = "file")
load("images/img_b60210ce.png", IMG_b60210ce_ASSET = "file")
load("images/img_b73acd73.png", IMG_b73acd73_ASSET = "file")
load("images/img_b75d3a97.png", IMG_b75d3a97_ASSET = "file")
load("images/img_b773ac0d.png", IMG_b773ac0d_ASSET = "file")
load("images/img_b8445b0e.png", IMG_b8445b0e_ASSET = "file")
load("images/img_b9bf2d66.png", IMG_b9bf2d66_ASSET = "file")
load("images/img_bb8eb91c.png", IMG_bb8eb91c_ASSET = "file")
load("images/img_bbbd1c2a.png", IMG_bbbd1c2a_ASSET = "file")
load("images/img_bc4844ce.png", IMG_bc4844ce_ASSET = "file")
load("images/img_bf1f9378.png", IMG_bf1f9378_ASSET = "file")
load("images/img_c0550c6f.png", IMG_c0550c6f_ASSET = "file")
load("images/img_c0c7d2d2.png", IMG_c0c7d2d2_ASSET = "file")
load("images/img_c19e9148.png", IMG_c19e9148_ASSET = "file")
load("images/img_c1d837c5.png", IMG_c1d837c5_ASSET = "file")
load("images/img_c1ff91e5.png", IMG_c1ff91e5_ASSET = "file")
load("images/img_c24ef6f2.png", IMG_c24ef6f2_ASSET = "file")
load("images/img_c280ec8a.png", IMG_c280ec8a_ASSET = "file")
load("images/img_c28e7e25.png", IMG_c28e7e25_ASSET = "file")
load("images/img_c30a4356.png", IMG_c30a4356_ASSET = "file")
load("images/img_c3de0859.png", IMG_c3de0859_ASSET = "file")
load("images/img_c4885de5.png", IMG_c4885de5_ASSET = "file")
load("images/img_c4ceac93.png", IMG_c4ceac93_ASSET = "file")
load("images/img_c635a67b.png", IMG_c635a67b_ASSET = "file")
load("images/img_c6a91091.png", IMG_c6a91091_ASSET = "file")
load("images/img_c72afcf4.png", IMG_c72afcf4_ASSET = "file")
load("images/img_c7a809d3.png", IMG_c7a809d3_ASSET = "file")
load("images/img_c7faff06.png", IMG_c7faff06_ASSET = "file")
load("images/img_c859f386.png", IMG_c859f386_ASSET = "file")
load("images/img_c8f92c2f.png", IMG_c8f92c2f_ASSET = "file")
load("images/img_ca00d185.png", IMG_ca00d185_ASSET = "file")
load("images/img_caaf4cdc.png", IMG_caaf4cdc_ASSET = "file")
load("images/img_cac15e22.png", IMG_cac15e22_ASSET = "file")
load("images/img_cb1ac8e0.png", IMG_cb1ac8e0_ASSET = "file")
load("images/img_cbb0d10f.png", IMG_cbb0d10f_ASSET = "file")
load("images/img_cbddfa47.png", IMG_cbddfa47_ASSET = "file")
load("images/img_cc688c54.png", IMG_cc688c54_ASSET = "file")
load("images/img_ccba99ed.png", IMG_ccba99ed_ASSET = "file")
load("images/img_cd936a99.png", IMG_cd936a99_ASSET = "file")
load("images/img_cdec54fd.png", IMG_cdec54fd_ASSET = "file")
load("images/img_ce3eda3d.png", IMG_ce3eda3d_ASSET = "file")
load("images/img_cecd3c30.png", IMG_cecd3c30_ASSET = "file")
load("images/img_cf74bcd5.png", IMG_cf74bcd5_ASSET = "file")
load("images/img_d0487696.png", IMG_d0487696_ASSET = "file")
load("images/img_d0cba88b.png", IMG_d0cba88b_ASSET = "file")
load("images/img_d0ea14ae.png", IMG_d0ea14ae_ASSET = "file")
load("images/img_d10849c0.png", IMG_d10849c0_ASSET = "file")
load("images/img_d2d91b19.png", IMG_d2d91b19_ASSET = "file")
load("images/img_d3d91f8b.png", IMG_d3d91f8b_ASSET = "file")
load("images/img_d3e50852.png", IMG_d3e50852_ASSET = "file")
load("images/img_d3e7d20b.png", IMG_d3e7d20b_ASSET = "file")
load("images/img_d411c558.png", IMG_d411c558_ASSET = "file")
load("images/img_d4672d8d.png", IMG_d4672d8d_ASSET = "file")
load("images/img_d6cc9b7a.png", IMG_d6cc9b7a_ASSET = "file")
load("images/img_d71a1626.png", IMG_d71a1626_ASSET = "file")
load("images/img_d829488b.png", IMG_d829488b_ASSET = "file")
load("images/img_d932d1cf.png", IMG_d932d1cf_ASSET = "file")
load("images/img_d9da378b.png", IMG_d9da378b_ASSET = "file")
load("images/img_dc19252b.png", IMG_dc19252b_ASSET = "file")
load("images/img_dc834b29.png", IMG_dc834b29_ASSET = "file")
load("images/img_dd0f97bd.png", IMG_dd0f97bd_ASSET = "file")
load("images/img_de89829b.png", IMG_de89829b_ASSET = "file")
load("images/img_dee95b1d.png", IMG_dee95b1d_ASSET = "file")
load("images/img_deeae69d.png", IMG_deeae69d_ASSET = "file")
load("images/img_e0b78ca5.png", IMG_e0b78ca5_ASSET = "file")
load("images/img_e0dca16d.png", IMG_e0dca16d_ASSET = "file")
load("images/img_e1a780bb.png", IMG_e1a780bb_ASSET = "file")
load("images/img_e1f53035.png", IMG_e1f53035_ASSET = "file")
load("images/img_e22dbfe2.png", IMG_e22dbfe2_ASSET = "file")
load("images/img_e27702cf.png", IMG_e27702cf_ASSET = "file")
load("images/img_e290115c.png", IMG_e290115c_ASSET = "file")
load("images/img_e3b77fc0.png", IMG_e3b77fc0_ASSET = "file")
load("images/img_e46c8d72.png", IMG_e46c8d72_ASSET = "file")
load("images/img_e4a8986c.png", IMG_e4a8986c_ASSET = "file")
load("images/img_e4c6c755.png", IMG_e4c6c755_ASSET = "file")
load("images/img_e53eba15.png", IMG_e53eba15_ASSET = "file")
load("images/img_e57153fa.png", IMG_e57153fa_ASSET = "file")
load("images/img_e5e81ac8.png", IMG_e5e81ac8_ASSET = "file")
load("images/img_e64d6931.png", IMG_e64d6931_ASSET = "file")
load("images/img_e6e001db.png", IMG_e6e001db_ASSET = "file")
load("images/img_e7259310.png", IMG_e7259310_ASSET = "file")
load("images/img_e86d1e5e.png", IMG_e86d1e5e_ASSET = "file")
load("images/img_e89a35c6.png", IMG_e89a35c6_ASSET = "file")
load("images/img_e98a3322.png", IMG_e98a3322_ASSET = "file")
load("images/img_ea2c77a3.png", IMG_ea2c77a3_ASSET = "file")
load("images/img_eac6eb28.png", IMG_eac6eb28_ASSET = "file")
load("images/img_eb2e632f.png", IMG_eb2e632f_ASSET = "file")
load("images/img_ed010819.png", IMG_ed010819_ASSET = "file")
load("images/img_ed62874d.png", IMG_ed62874d_ASSET = "file")
load("images/img_edc6afd6.png", IMG_edc6afd6_ASSET = "file")
load("images/img_edf35d8d.png", IMG_edf35d8d_ASSET = "file")
load("images/img_ee833173.png", IMG_ee833173_ASSET = "file")
load("images/img_eed94cf6.png", IMG_eed94cf6_ASSET = "file")
load("images/img_ef5ac2dc.png", IMG_ef5ac2dc_ASSET = "file")
load("images/img_f0c3fc78.png", IMG_f0c3fc78_ASSET = "file")
load("images/img_f299c389.png", IMG_f299c389_ASSET = "file")
load("images/img_f35454fc.png", IMG_f35454fc_ASSET = "file")
load("images/img_f495a98c.png", IMG_f495a98c_ASSET = "file")
load("images/img_f49f2a81.png", IMG_f49f2a81_ASSET = "file")
load("images/img_f5a6c4f6.png", IMG_f5a6c4f6_ASSET = "file")
load("images/img_f5d62d35.png", IMG_f5d62d35_ASSET = "file")
load("images/img_f63f042b.png", IMG_f63f042b_ASSET = "file")
load("images/img_f695f1c2.png", IMG_f695f1c2_ASSET = "file")
load("images/img_f7d5b90c.png", IMG_f7d5b90c_ASSET = "file")
load("images/img_f8045efc.png", IMG_f8045efc_ASSET = "file")
load("images/img_f937e911.png", IMG_f937e911_ASSET = "file")
load("images/img_f9b8f926.png", IMG_f9b8f926_ASSET = "file")
load("images/img_fa4fc2e2.png", IMG_fa4fc2e2_ASSET = "file")
load("images/img_fb0cf0fd.png", IMG_fb0cf0fd_ASSET = "file")
load("images/img_fb7fb9cb.png", IMG_fb7fb9cb_ASSET = "file")
load("images/img_fbfec33b.png", IMG_fbfec33b_ASSET = "file")
load("images/img_fc5585da.png", IMG_fc5585da_ASSET = "file")
load("images/img_fd260b30.png", IMG_fd260b30_ASSET = "file")
load("images/img_fe03dbda.png", IMG_fe03dbda_ASSET = "file")
load("images/img_fe40462c.png", IMG_fe40462c_ASSET = "file")
load("images/img_fe4fdc24.png", IMG_fe4fdc24_ASSET = "file")
load("images/img_fe9cf4cc.png", IMG_fe9cf4cc_ASSET = "file")
load("images/img_fff8cb94.png", IMG_fff8cb94_ASSET = "file")

FONT = "tb-8"

# To match the Maya Glyphs app
GOLD = "#e79223"
TEAL = "#56a0a0"

def printable(s):
    # These characters aren't in any of pixlet's fonts, so replace
    # with similar ones that are.
    return s.replace(r"ḫ", r"ħ").replace(r"ṣ", r"ş").replace(r"ṭ", r"ţ")

def printable_list(l):
    return [printable(s) for s in l]

def main():
    # Pick a new pseudorandom sign every 15 seconds
    timestamp = time.now().unix // 15
    h = hash.md5(str(timestamp))
    index = int(h, 16) % len(SIGNS)
    sign = SIGNS[index]

    img = render.Image(base64.decode(sign["src"]))
    width, _ = img.size()

    return render.Root(
        child = render.Padding(
            pad = (1, 1, 1, 1),
            child = render.Stack(
                children = [
                    render.Row(
                        main_align = "end",
                        cross_align = "center",
                        expanded = True,
                        children = [
                            render.Column(
                                main_align = "space_around",
                                cross_align = "center",
                                expanded = True,
                                children = [img],
                            ),
                        ],
                    ),
                    render.Column(
                        main_align = "space_between",
                        cross_align = "start",
                        expanded = True,
                        children = [
                            # Sign name (from unicode)
                            render.Text(
                                sign["name"],
                                font = FONT,
                                color = TEAL,
                            ),
                            # How to pronounce in Sumerian, one per line.
                            # Akkadian may be better understood but this is
                            # the source I took it from.
                            render.Marquee(
                                scroll_direction = "vertical",
                                width = max(30, 62 - width),
                                height = 22,
                                align = "end",
                                child = render.WrappedText(
                                    "\n".join(printable_list(sign["sumerian_transliterations"])),
                                    width = max(30, 62 - width),
                                    font = FONT,
                                    color = GOLD,
                                ),
                            ),
                        ],
                    ),
                ],
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [],
    )

# Many thanks to the Electronic Text Corpus of Sumerian Literature (ETCSL).
# https://etcsl.orinst.ox.ac.uk/edition2/signlist.php
# Black, J.A., Cunningham, G., Ebeling, J., Flückiger-Hawker, E., Robson, E., Taylor, J., and Zólyomi, G., The Electronic Text Corpus of Sumerian Literature (http://etcsl.orinst.ox.ac.uk/), Oxford 1998–2006
# The source page says that "the signs in this list were kindly supplied by Steve Tinney of the Pennsylvania Sumerian Dictionary Project (PSD)".
# The PSD's website states that "All materials will be made freely available".
SIGNS = [
    {
        "name": r"A",
        "sumerian_transliterations": [r"a", r"dur5", r"duru5"],
        "src": IMG_421ba246_ASSET.readall(),
    },
    {
        "name": r"A×HA",
        "sumerian_transliterations": [r"saḫ7"],
        "src": IMG_837fe4bc_ASSET.readall(),
    },
    {
        "name": r"A2",
        "sumerian_transliterations": [r"a2", r"ed", r"et", r"id", r"it", r"iṭ", r"te8"],
        "src": IMG_53a5ce08_ASSET.readall(),
    },
    {
        "name": r"AB",
        "sumerian_transliterations": [r"ab", r"aba", r"ap", r"eš3", r"iri12", r"is3"],
        "src": IMG_55d41d0d_ASSET.readall(),
    },
    {
        "name": r"ABgunu",
        "sumerian_transliterations": [r"ab4", r"aba4", r"gun4", r"iri11", r"unu", r"unug"],
        "src": IMG_5a63e706_ASSET.readall(),
    },
    {
        "name": r"AB×GAL",
        "sumerian_transliterations": [r"irigal"],
        "src": IMG_64ac5ad3_ASSET.readall(),
    },
    {
        "name": r"AB×HA",
        "sumerian_transliterations": [r"agarinx", r"nanše", r"niĝin6", r"sirara"],
        "src": IMG_8aeb13ed_ASSET.readall(),
    },
    {
        "name": r"AB2",
        "sumerian_transliterations": [r"ab2"],
        "src": IMG_99b55fec_ASSET.readall(),
    },
    {
        "name": r"AB2×GAN2tenu",
        "sumerian_transliterations": [r"šem5"],
        "src": IMG_5ba0eabd_ASSET.readall(),
    },
    {
        "name": r"AB2×ŠA3",
        "sumerian_transliterations": [r"lipiš", r"ub3", r"šem3"],
        "src": IMG_2a89976b_ASSET.readall(),
    },
    {
        "name": r"AD",
        "sumerian_transliterations": [r"ad", r"at"],
        "src": IMG_94bbe360_ASSET.readall(),
    },
    {
        "name": r"AK",
        "sumerian_transliterations": [r"ag", r"ak", r"ša5"],
        "src": IMG_73b3847a_ASSET.readall(),
    },
    {
        "name": r"AK×ERIN2",
        "sumerian_transliterations": [r"me3"],
        "src": IMG_482bc582_ASSET.readall(),
    },
    {
        "name": r"AL",
        "sumerian_transliterations": [r"al"],
        "src": IMG_85ba258c_ASSET.readall(),
    },
    {
        "name": r"ALAN",
        "sumerian_transliterations": [r"alan"],
        "src": IMG_eb2e632f_ASSET.readall(),
    },
    {
        "name": r"AMAR",
        "sumerian_transliterations": [r"amar", r"mar2", r"zur"],
        "src": IMG_a9195573_ASSET.readall(),
    },
    {
        "name": r"AMAR×ŠE",
        "sumerian_transliterations": [r"sizkur"],
        "src": IMG_59253904_ASSET.readall(),
    },
    {
        "name": r"AN",
        "sumerian_transliterations": [r"am6", r"an", r"diĝir", r"il3", r"naggax"],
        "src": IMG_c1d837c5_ASSET.readall(),
    },
    {
        "name": r"AN.AŠ.AN",
        "sumerian_transliterations": [r"tilla2"],
        "src": IMG_77103ac8_ASSET.readall(),
    },
    {
        "name": r"AN/AN",
        "sumerian_transliterations": [r"part of compound"],
        "src": IMG_00d7f0e7_ASSET.readall(),
    },
    {
        "name": r"AN+NAGA(inverted)AN+NAGA",
        "sumerian_transliterations": [r"dalḫamun5"],
        "src": IMG_8fad5a68_ASSET.readall(),
    },
    {
        "name": r"ANŠE",
        "sumerian_transliterations": [r"anše"],
        "src": IMG_19c34ba3_ASSET.readall(),
    },
    {
        "name": r"APIN",
        "sumerian_transliterations": [r"absin3", r"apin", r"engar", r"ur11", r"uš8"],
        "src": IMG_00d495a1_ASSET.readall(),
    },
    {
        "name": r"ARAD",
        "sumerian_transliterations": [r"arad", r"er3", r"nitaḫ2"],
        "src": IMG_3a0febf3_ASSET.readall(),
    },
    {
        "name": r"ARAD×KUR",
        "sumerian_transliterations": [r"arad2"],
        "src": IMG_709680b5_ASSET.readall(),
    },
    {
        "name": r"AŠ",
        "sumerian_transliterations": [r"aš", r"dil", r"dili", r"rum", r"til4"],
        "src": IMG_7eb6b209_ASSET.readall(),
    },
    {
        "name": r"AŠ2",
        "sumerian_transliterations": [r"aš2", r"ziz2"],
        "src": IMG_6f7be716_ASSET.readall(),
    },
    {
        "name": r"AŠGAB",
        "sumerian_transliterations": [r"ašgab"],
        "src": IMG_9c158536_ASSET.readall(),
    },
    {
        "name": r"BA",
        "sumerian_transliterations": [r"ba", r"be4"],
        "src": IMG_8fea62bf_ASSET.readall(),
    },
    {
        "name": r"BAD",
        "sumerian_transliterations": [r"ba9", r"bad", r"be"],
        "src": IMG_ae1685f3_ASSET.readall(),
    },
    {
        "name": r"BAHAR2",
        "sumerian_transliterations": [r"baḫar2"],
        "src": IMG_caaf4cdc_ASSET.readall(),
    },
    {
        "name": r"BAL",
        "sumerian_transliterations": [r"bal"],
        "src": IMG_80b66ea8_ASSET.readall(),
    },
    {
        "name": r"BALAG",
        "sumerian_transliterations": [r"balaĝ", r"buluĝ5"],
        "src": IMG_39ddfe5c_ASSET.readall(),
    },
    {
        "name": r"BAR",
        "sumerian_transliterations": [r"bar"],
        "src": IMG_58e7856a_ASSET.readall(),
    },
    {
        "name": r"BARA2",
        "sumerian_transliterations": [r"barag", r"šara"],
        "src": IMG_a38724e4_ASSET.readall(),
    },
    {
        "name": r"BI",
        "sumerian_transliterations": [r"be2", r"bi", r"biz", r"kaš", r"pe2", r"pi2"],
        "src": IMG_b367ef3e_ASSET.readall(),
    },
    {
        "name": r"BU",
        "sumerian_transliterations": [r"bu", r"bur12", r"dur7", r"gid2", r"kim3", r"pu", r"sir2", r"su13", r"sud4", r"tur8"],
        "src": IMG_7adb53aa_ASSET.readall(),
    },
    {
        "name": r"BU/BU.AB",
        "sumerian_transliterations": [r"sirsir"],
        "src": IMG_ad33b827_ASSET.readall(),
    },
    {
        "name": r"BULUG",
        "sumerian_transliterations": [r"bulug"],
        "src": IMG_a40b42d9_ASSET.readall(),
    },
    {
        "name": r"BUR",
        "sumerian_transliterations": [r"bur"],
        "src": IMG_49cd5205_ASSET.readall(),
    },
    {
        "name": r"BUR2",
        "sumerian_transliterations": [r"bu8", r"bur2", r"du9", r"dun5", r"sun5", r"ušum"],
        "src": IMG_3f1643eb_ASSET.readall(),
    },
    {
        "name": r"DA",
        "sumerian_transliterations": [r"da", r"ta2"],
        "src": IMG_edf35d8d_ASSET.readall(),
    },
    {
        "name": r"DAG",
        "sumerian_transliterations": [r"barag2", r"dag", r"par3", r"para3", r"tag2"],
        "src": IMG_213172d4_ASSET.readall(),
    },
    {
        "name": r"DAG.KISIM5×GA",
        "sumerian_transliterations": [r"akan", r"ubur"],
        "src": IMG_ce3eda3d_ASSET.readall(),
    },
    {
        "name": r"DAG.KISIM5×GIR2",
        "sumerian_transliterations": [r"kiši8"],
        "src": IMG_b1b09805_ASSET.readall(),
    },
    {
        "name": r"DAG.KISIM5×LU",
        "sumerian_transliterations": [r"ubur2"],
        "src": IMG_90bbff63_ASSET.readall(),
    },
    {
        "name": r"DAG.KISIM5×LU+MAŠ2",
        "sumerian_transliterations": [r"amaš", r"utua2"],
        "src": IMG_dee95b1d_ASSET.readall(),
    },
    {
        "name": r"DAG.KISIM5×SI",
        "sumerian_transliterations": [r"kisim2"],
        "src": IMG_22b9fa14_ASSET.readall(),
    },
    {
        "name": r"DAG.KISIM5×U2+GIR2",
        "sumerian_transliterations": [r"kisim", r"ḫarub"],
        "src": IMG_cb1ac8e0_ASSET.readall(),
    },
    {
        "name": r"DAM",
        "sumerian_transliterations": [r"dam"],
        "src": IMG_7b2bff65_ASSET.readall(),
    },
    {
        "name": r"DAR",
        "sumerian_transliterations": [r"dar", r"gun3", r"tar2"],
        "src": IMG_cd936a99_ASSET.readall(),
    },
    {
        "name": r"DARA3",
        "sumerian_transliterations": [r"dar3", r"dara3", r"taraḫ"],
        "src": IMG_400db6b9_ASSET.readall(),
    },
    {
        "name": r"DARA4",
        "sumerian_transliterations": [r"dara4"],
        "src": IMG_48510370_ASSET.readall(),
    },
    {
        "name": r"DI",
        "sumerian_transliterations": [r"de", r"di", r"sa2", r"silim"],
        "src": IMG_84f3562f_ASSET.readall(),
    },
    {
        "name": r"DIB",
        "sumerian_transliterations": [r"dab", r"dib"],
        "src": IMG_70d31ab9_ASSET.readall(),
    },
    {
        "name": r"DIM",
        "sumerian_transliterations": [r"dim"],
        "src": IMG_ad0efefc_ASSET.readall(),
    },
    {
        "name": r"DIM×ŠE",
        "sumerian_transliterations": [r"mun"],
        "src": IMG_4298405e_ASSET.readall(),
    },
    {
        "name": r"DIM2",
        "sumerian_transliterations": [r"dim2", r"ge18", r"gen7", r"gim", r"gin7", r"šidim"],
        "src": IMG_94adeb55_ASSET.readall(),
    },
    {
        "name": r"DIN",
        "sumerian_transliterations": [r"din", r"kurun2", r"tin"],
        "src": IMG_19c7d5d9_ASSET.readall(),
    },
    {
        "name": r"DIŠ",
        "sumerian_transliterations": [r"diš", r"eš4"],
        "src": IMG_68113fc3_ASSET.readall(),
    },
    {
        "name": r"DU",
        "sumerian_transliterations": [r"de6", r"du", r"gub", r"im4", r"kub", r"kurx", r"kux", r"laḫ6", r"ra2", r"re6", r"tu3", r"tum2", r"ĝen", r"ša4"],
        "src": IMG_52e5691f_ASSET.readall(),
    },
    {
        "name": r"DUgunu",
        "sumerian_transliterations": [r"suḫuš"],
        "src": IMG_6c630f99_ASSET.readall(),
    },
    {
        "name": r"DU/DU",
        "sumerian_transliterations": [r"laḫ4", r"re7", r"su8", r"sub2", r"sug2"],
        "src": IMG_168e92b2_ASSET.readall(),
    },
    {
        "name": r"DUšešig",
        "sumerian_transliterations": [r"gir5", r"im2", r"kaš4", r"rim4"],
        "src": IMG_0b109a10_ASSET.readall(),
    },
    {
        "name": r"DUB",
        "sumerian_transliterations": [r"dab4", r"dub", r"kišib3", r"zamug"],
        "src": IMG_0649f3d8_ASSET.readall(),
    },
    {
        "name": r"DUB2",
        "sumerian_transliterations": [r"dub2"],
        "src": IMG_621dc3a3_ASSET.readall(),
    },
    {
        "name": r"DUG",
        "sumerian_transliterations": [r"dug", r"epir", r"gurun7", r"kurin", r"kurun3"],
        "src": IMG_2a4ea728_ASSET.readall(),
    },
    {
        "name": r"DUGUD",
        "sumerian_transliterations": [r"dugud", r"ĝi25"],
        "src": IMG_49aa04bc_ASSET.readall(),
    },
    {
        "name": r"DUN",
        "sumerian_transliterations": [r"dun", r"dur9", r"sul", r"zu7", r"šaḫ2", r"šul"],
        "src": IMG_e46c8d72_ASSET.readall(),
    },
    {
        "name": r"DUN3",
        "sumerian_transliterations": [r"du5", r"tun3"],
        "src": IMG_728cd802_ASSET.readall(),
    },
    {
        "name": r"DUN3gunu",
        "sumerian_transliterations": [r"aga3", r"giĝ4"],
        "src": IMG_aa38e834_ASSET.readall(),
    },
    {
        "name": r"DUN3gunugunu",
        "sumerian_transliterations": [r"aga", r"mir", r"niĝir"],
        "src": IMG_eac6eb28_ASSET.readall(),
    },
    {
        "name": r"DUN3gunugunušešig",
        "sumerian_transliterations": [r"dul4", r"šudul4"],
        "src": IMG_681afd8f_ASSET.readall(),
    },
    {
        "name": r"E",
        "sumerian_transliterations": [r"e", r"eg2"],
        "src": IMG_83955ebf_ASSET.readall(),
    },
    {
        "name": r"E2",
        "sumerian_transliterations": [r"e2"],
        "src": IMG_d3d91f8b_ASSET.readall(),
    },
    {
        "name": r"EDIN",
        "sumerian_transliterations": [r"bir4", r"edimx", r"edin", r"ru6"],
        "src": IMG_a5756217_ASSET.readall(),
    },
    {
        "name": r"EGIR",
        "sumerian_transliterations": [r"eĝer"],
        "src": IMG_e64d6931_ASSET.readall(),
    },
    {
        "name": r"EL",
        "sumerian_transliterations": [r"el", r"il5", r"sikil"],
        "src": IMG_0d03c6a4_ASSET.readall(),
    },
    {
        "name": r"EN",
        "sumerian_transliterations": [r"en", r"in4", r"ru12", r"uru16"],
        "src": IMG_d3e50852_ASSET.readall(),
    },
    {
        "name": r"EN×GAN2tenu",
        "sumerian_transliterations": [r"buru14", r"enkar", r"ešgiri2"],
        "src": IMG_80a4fd96_ASSET.readall(),
    },
    {
        "name": r"EREN",
        "sumerian_transliterations": [r"erin", r"še22", r"šeš4"],
        "src": IMG_ea2c77a3_ASSET.readall(),
    },
    {
        "name": r"ERIN2",
        "sumerian_transliterations": [r"erim", r"erin2", r"pir2", r"rin2", r"zalag2"],
        "src": IMG_7fcdf569_ASSET.readall(),
    },
    {
        "name": r"EŠ2",
        "sumerian_transliterations": [r"egir2", r"eš2", r"eše2", r"gir15", r"sumunx", r"ub2", r"še3", r"ḫuĝ"],
        "src": IMG_008ee812_ASSET.readall(),
    },
    {
        "name": r"EZEN",
        "sumerian_transliterations": [r"asilx", r"ezem", r"ezen", r"gublagax", r"šer3", r"šir3"],
        "src": IMG_3acec7ac_ASSET.readall(),
    },
    {
        "name": r"EZEN×A",
        "sumerian_transliterations": [r"asil3", r"asila3"],
        "src": IMG_762f9145_ASSET.readall(),
    },
    {
        "name": r"EZEN×BAD",
        "sumerian_transliterations": [r"bad3", r"u9", r"ug5", r"un3"],
        "src": IMG_aa547625_ASSET.readall(),
    },
    {
        "name": r"EZEN×KASKAL",
        "sumerian_transliterations": [r"ubara", r"un4"],
        "src": IMG_944e9af2_ASSET.readall(),
    },
    {
        "name": r"EZEN×KU3",
        "sumerian_transliterations": [r"kisiga"],
        "src": IMG_6c666fa4_ASSET.readall(),
    },
    {
        "name": r"EZEN×LA",
        "sumerian_transliterations": [r"gublaga"],
        "src": IMG_fe40462c_ASSET.readall(),
    },
    {
        "name": r"EZEN×LAL×LAL",
        "sumerian_transliterations": [r"asil", r"asila"],
        "src": IMG_1319d59a_ASSET.readall(),
    },
    {
        "name": r"GA",
        "sumerian_transliterations": [r"ga", r"gur11", r"ka3", r"qa2"],
        "src": IMG_ee833173_ASSET.readall(),
    },
    {
        "name": r"GA2",
        "sumerian_transliterations": [r"ba4", r"ma3", r"pisaĝ", r"ĝa2", r"ĝe26"],
        "src": IMG_755a18bb_ASSET.readall(),
    },
    {
        "name": r"GA2×AN",
        "sumerian_transliterations": [r"ama", r"daĝal"],
        "src": IMG_5398aebe_ASSET.readall(),
    },
    {
        "name": r"GA2×GAN2tenu",
        "sumerian_transliterations": [r"dan4"],
        "src": IMG_c19e9148_ASSET.readall(),
    },
    {
        "name": r"GA2×GAR",
        "sumerian_transliterations": [r"ĝalga"],
        "src": IMG_ed010819_ASSET.readall(),
    },
    {
        "name": r"GA2×ME+EN",
        "sumerian_transliterations": [r"dan2", r"men"],
        "src": IMG_af8581f1_ASSET.readall(),
    },
    {
        "name": r"GA2×MI",
        "sumerian_transliterations": [r"itima"],
        "src": IMG_82cb86aa_ASSET.readall(),
    },
    {
        "name": r"GA2×NUN",
        "sumerian_transliterations": [r"ĝanun"],
        "src": IMG_3fececeb_ASSET.readall(),
    },
    {
        "name": r"GA2×NUN/NUN",
        "sumerian_transliterations": [r"ur3"],
        "src": IMG_6c9e5e77_ASSET.readall(),
    },
    {
        "name": r"GA2×PA",
        "sumerian_transliterations": [r"gazi", r"sila4"],
        "src": IMG_fe03dbda_ASSET.readall(),
    },
    {
        "name": r"GA2×SAL",
        "sumerian_transliterations": [r"ama5", r"arḫuš"],
        "src": IMG_7a148ef2_ASSET.readall(),
    },
    {
        "name": r"GA2×ŠE",
        "sumerian_transliterations": [r"esaĝ2"],
        "src": IMG_e7259310_ASSET.readall(),
    },
    {
        "name": r"GA2×TAK4",
        "sumerian_transliterations": [r"dan3"],
        "src": IMG_06e8fe9a_ASSET.readall(),
    },
    {
        "name": r"GABA",
        "sumerian_transliterations": [r"du8", r"duḫ", r"gab", r"gaba"],
        "src": IMG_4ded3cc4_ASSET.readall(),
    },
    {
        "name": r"GAD",
        "sumerian_transliterations": [r"gada"],
        "src": IMG_5c7622cd_ASSET.readall(),
    },
    {
        "name": r"GAD/GAD.GAR/GAR",
        "sumerian_transliterations": [r"garadinx", r"kinda"],
        "src": IMG_06375f4f_ASSET.readall(),
    },
    {
        "name": r"GAL",
        "sumerian_transliterations": [r"gal", r"kal2"],
        "src": IMG_e3b77fc0_ASSET.readall(),
    },
    {
        "name": r"GAL.GAD/GAD.GAR/GAR",
        "sumerian_transliterations": [r"kindagal"],
        "src": IMG_166b035b_ASSET.readall(),
    },
    {
        "name": r"GALAM",
        "sumerian_transliterations": [r"galam", r"sukud", r"sukux"],
        "src": IMG_ca00d185_ASSET.readall(),
    },
    {
        "name": r"GAM",
        "sumerian_transliterations": [r"gam", r"gur2", r"gurum"],
        "src": IMG_b73acd73_ASSET.readall(),
    },
    {
        "name": r"GAN",
        "sumerian_transliterations": [r"gam4", r"gan", r"gana", r"kan", r"ḫe2"],
        "src": IMG_bc4844ce_ASSET.readall(),
    },
    {
        "name": r"GAN2",
        "sumerian_transliterations": [r"ga3", r"gan2", r"gana2", r"iku", r"kan2"],
        "src": IMG_8549eb8c_ASSET.readall(),
    },
    {
        "name": r"GAN2%GAN2",
        "sumerian_transliterations": [r"ulul2"],
        "src": IMG_d9da378b_ASSET.readall(),
    },
    {
        "name": r"GAN2tenu",
        "sumerian_transliterations": [r"guru6", r"kar2"],
        "src": IMG_6daeea1e_ASSET.readall(),
    },
    {
        "name": r"GAR",
        "sumerian_transliterations": [r"ni3", r"ninda", r"nindan", r"niĝ2", r"ĝar", r"ša2"],
        "src": IMG_5d9832e7_ASSET.readall(),
    },
    {
        "name": r"GAR3",
        "sumerian_transliterations": [r"gar3", r"gara3", r"qar"],
        "src": IMG_c635a67b_ASSET.readall(),
    },
    {
        "name": r"GAgunu",
        "sumerian_transliterations": [r"gara2"],
        "src": IMG_55b83bcd_ASSET.readall(),
    },
    {
        "name": r"GEŠTIN",
        "sumerian_transliterations": [r"ĝeštin"],
        "src": IMG_52e1e77a_ASSET.readall(),
    },
    {
        "name": r"GI",
        "sumerian_transliterations": [r"ge", r"gen6", r"gi", r"ke2", r"ki2", r"sig17"],
        "src": IMG_ac287bbd_ASSET.readall(),
    },
    {
        "name": r"GI4",
        "sumerian_transliterations": [r"ge4", r"gi4", r"qi4"],
        "src": IMG_eed94cf6_ASSET.readall(),
    },
    {
        "name": r"GIDIM",
        "sumerian_transliterations": [r"gidim"],
        "src": IMG_589cd2f8_ASSET.readall(),
    },
    {
        "name": r"GIG",
        "sumerian_transliterations": [r"gi17", r"gig", r"simx"],
        "src": IMG_46a3eb00_ASSET.readall(),
    },
    {
        "name": r"GIR2",
        "sumerian_transliterations": [r"ĝir2", r"ĝiri2"],
        "src": IMG_a3d2583d_ASSET.readall(),
    },
    {
        "name": r"GIR2gunu",
        "sumerian_transliterations": [r"kiši17", r"tab2", r"ul4"],
        "src": IMG_cac15e22_ASSET.readall(),
    },
    {
        "name": r"GIR3",
        "sumerian_transliterations": [r"er9", r"gir3", r"ĝir3", r"ĝiri3", r"šakkan2"],
        "src": IMG_b02d1b53_ASSET.readall(),
    },
    {
        "name": r"GIR3×A+IGI",
        "sumerian_transliterations": [r"alim"],
        "src": IMG_6ae68e6c_ASSET.readall(),
    },
    {
        "name": r"GIR3×GAN2tenu",
        "sumerian_transliterations": [r"gir16", r"giri16", r"girid2"],
        "src": IMG_d3e7d20b_ASSET.readall(),
    },
    {
        "name": r"GIR3×LU+IGI",
        "sumerian_transliterations": [r"lulim"],
        "src": IMG_65854956_ASSET.readall(),
    },
    {
        "name": r"GISAL",
        "sumerian_transliterations": [r"ĝisal"],
        "src": IMG_b8445b0e_ASSET.readall(),
    },
    {
        "name": r"GIŠ",
        "sumerian_transliterations": [r"is", r"iz", r"iš6", r"ĝiš"],
        "src": IMG_1765af05_ASSET.readall(),
    },
    {
        "name": r"GIŠ%GIŠ",
        "sumerian_transliterations": [r"lirum3", r"ul3", r"šennur", r"ḫul3"],
        "src": IMG_f7d5b90c_ASSET.readall(),
    },
    {
        "name": r"GI%GI",
        "sumerian_transliterations": [r"gel", r"gi16", r"gib", r"gil", r"gilim"],
        "src": IMG_5b77d506_ASSET.readall(),
    },
    {
        "name": r"GU",
        "sumerian_transliterations": [r"gu"],
        "src": IMG_a9be40f3_ASSET.readall(),
    },
    {
        "name": r"GU%GU",
        "sumerian_transliterations": [r"saḫ4", r"suḫ3"],
        "src": IMG_30c579bf_ASSET.readall(),
    },
    {
        "name": r"GU2",
        "sumerian_transliterations": [r"gu2", r"gun2"],
        "src": IMG_e86d1e5e_ASSET.readall(),
    },
    {
        "name": r"GU2×KAK",
        "sumerian_transliterations": [r"dur", r"usanx"],
        "src": IMG_24e507b6_ASSET.readall(),
    },
    {
        "name": r"GU2×NUN",
        "sumerian_transliterations": [r"sub3", r"usan"],
        "src": IMG_c8f92c2f_ASSET.readall(),
    },
    {
        "name": r"GUD",
        "sumerian_transliterations": [r"eštub", r"gu4", r"gud"],
        "src": IMG_6c055019_ASSET.readall(),
    },
    {
        "name": r"GUD×A+KUR",
        "sumerian_transliterations": [r"ildag2"],
        "src": IMG_82196ac6_ASSET.readall(),
    },
    {
        "name": r"GUD×KUR",
        "sumerian_transliterations": [r"am", r"ildag3"],
        "src": IMG_9414d838_ASSET.readall(),
    },
    {
        "name": r"GUL",
        "sumerian_transliterations": [r"gul", r"isimu2", r"kul2", r"si23", r"sumun2"],
        "src": IMG_74239715_ASSET.readall(),
    },
    {
        "name": r"GUM",
        "sumerian_transliterations": [r"gum", r"kum", r"naĝa4", r"qum"],
        "src": IMG_1a52be18_ASSET.readall(),
    },
    {
        "name": r"GUM×ŠE",
        "sumerian_transliterations": [r"gaz", r"naĝa3"],
        "src": IMG_6223134d_ASSET.readall(),
    },
    {
        "name": r"GUR",
        "sumerian_transliterations": [r"gur"],
        "src": IMG_5d43ab0e_ASSET.readall(),
    },
    {
        "name": r"GUR7",
        "sumerian_transliterations": [r"guru7"],
        "src": IMG_4db2562b_ASSET.readall(),
    },
    {
        "name": r"GURUN",
        "sumerian_transliterations": [r"gamx", r"gurun"],
        "src": IMG_56b2b4dd_ASSET.readall(),
    },
    {
        "name": r"HA",
        "sumerian_transliterations": [r"ku6", r"peš11", r"ḫa"],
        "src": IMG_69305354_ASSET.readall(),
    },
    {
        "name": r"HAgunu",
        "sumerian_transliterations": [r"biš", r"gir", r"peš"],
        "src": IMG_324b402e_ASSET.readall(),
    },
    {
        "name": r"HAL",
        "sumerian_transliterations": [r"ḫal"],
        "src": IMG_c4ceac93_ASSET.readall(),
    },
    {
        "name": r"HI",
        "sumerian_transliterations": [r"da10", r"du10", r"dub3", r"dug3", r"šar2", r"ḫe", r"ḫi"],
        "src": IMG_d829488b_ASSET.readall(),
    },
    {
        "name": r"HI×AŠ",
        "sumerian_transliterations": [r"sur3"],
        "src": IMG_8d7fbc38_ASSET.readall(),
    },
    {
        "name": r"HI×AŠ2",
        "sumerian_transliterations": [r"ar3", r"kin2", r"kinkin", r"mar6", r"mur", r"ur5", r"ḫar", r"ḫur"],
        "src": IMG_b60210ce_ASSET.readall(),
    },
    {
        "name": r"HI×BAD",
        "sumerian_transliterations": [r"kam", r"tu7", r"utul2"],
        "src": IMG_1f90a499_ASSET.readall(),
    },
    {
        "name": r"HI×NUN",
        "sumerian_transliterations": [r"aḫ", r"a’", r"eḫ", r"iḫ", r"umun3", r"uḫ"],
        "src": IMG_c4885de5_ASSET.readall(),
    },
    {
        "name": r"HI×ŠE",
        "sumerian_transliterations": [r"bir", r"dubur", r"giriš"],
        "src": IMG_fe4fdc24_ASSET.readall(),
    },
    {
        "name": r"HU",
        "sumerian_transliterations": [r"mušen", r"pag", r"u11", r"ḫu"],
        "src": IMG_a1bfe563_ASSET.readall(),
    },
    {
        "name": r"HUB2",
        "sumerian_transliterations": [r"tu11", r"ḫub2"],
        "src": IMG_f8045efc_ASSET.readall(),
    },
    {
        "name": r"HUB2×UD",
        "sumerian_transliterations": [r"tu10"],
        "src": IMG_c0c7d2d2_ASSET.readall(),
    },
    {
        "name": r"HUL2",
        "sumerian_transliterations": [r"bibra", r"gukkal", r"kuš8", r"ukuš2", r"ḫul2"],
        "src": IMG_fc5585da_ASSET.readall(),
    },
    {
        "name": r"I",
        "sumerian_transliterations": [r"i"],
        "src": IMG_c6a91091_ASSET.readall(),
    },
    {
        "name": r"I.A",
        "sumerian_transliterations": [r"ia"],
        "src": IMG_a6a16dcc_ASSET.readall(),
    },
    {
        "name": r"IB",
        "sumerian_transliterations": [r"dara2", r"eb", r"ib", r"ip", r"uraš", r"urta"],
        "src": IMG_9bd70ebe_ASSET.readall(),
    },
    {
        "name": r"IDIM",
        "sumerian_transliterations": [r"idim"],
        "src": IMG_83acac7e_ASSET.readall(),
    },
    {
        "name": r"IG",
        "sumerian_transliterations": [r"eg", r"ek", r"ig", r"ik", r"iq", r"ĝal2"],
        "src": IMG_dc19252b_ASSET.readall(),
    },
    {
        "name": r"IGI",
        "sumerian_transliterations": [r"ge8", r"gi8", r"igi", r"lib4", r"lim", r"ši"],
        "src": IMG_8fbea2b3_ASSET.readall(),
    },
    {
        "name": r"IGIgunu",
        "sumerian_transliterations": [r"imma3", r"se12", r"sig7", r"ugur2", r"šex"],
        "src": IMG_7adcd5e6_ASSET.readall(),
    },
    {
        "name": r"IL",
        "sumerian_transliterations": [r"il"],
        "src": IMG_5c2398c4_ASSET.readall(),
    },
    {
        "name": r"IL2",
        "sumerian_transliterations": [r"dusu", r"ga6", r"gur3", r"guru3", r"il2"],
        "src": IMG_e5e81ac8_ASSET.readall(),
    },
    {
        "name": r"IM",
        "sumerian_transliterations": [r"did", r"em", r"enegir", r"im", r"iškur", r"karkara", r"ni2", r"tum9"],
        "src": IMG_1903fc8c_ASSET.readall(),
    },
    {
        "name": r"IM×TAK4",
        "sumerian_transliterations": [r"kid7"],
        "src": IMG_9ca340e6_ASSET.readall(),
    },
    {
        "name": r"IMIN",
        "sumerian_transliterations": [r"imin"],
        "src": IMG_772570ea_ASSET.readall(),
    },
    {
        "name": r"IN",
        "sumerian_transliterations": [r"en6", r"in", r"isin2"],
        "src": IMG_19dfb4f9_ASSET.readall(),
    },
    {
        "name": r"IR",
        "sumerian_transliterations": [r"er", r"ir"],
        "src": IMG_834f42c8_ASSET.readall(),
    },
    {
        "name": r"IŠ",
        "sumerian_transliterations": [r"isiš", r"iš", r"iši", r"kukkuš", r"kuš7", r"saḫar"],
        "src": IMG_87fcf3f0_ASSET.readall(),
    },
    {
        "name": r"KA",
        "sumerian_transliterations": [r"du11", r"dug4", r"ga14", r"giri17", r"gu3", r"inim", r"ka", r"kir4", r"pi4", r"su11", r"zu2", r"zuḫ", r"šudx"],
        "src": IMG_15ef3770_ASSET.readall(),
    },
    {
        "name": r"KA×A",
        "sumerian_transliterations": [r"enmen2", r"kab2", r"na8", r"naĝ"],
        "src": IMG_216891b8_ASSET.readall(),
    },
    {
        "name": r"KA×BAD",
        "sumerian_transliterations": [r"uš11"],
        "src": IMG_f9b8f926_ASSET.readall(),
    },
    {
        "name": r"KA×BALAG",
        "sumerian_transliterations": [r"šeg11"],
        "src": IMG_2f52c2e6_ASSET.readall(),
    },
    {
        "name": r"KA×EŠ2",
        "sumerian_transliterations": [r"ma5"],
        "src": IMG_1c47a7ae_ASSET.readall(),
    },
    {
        "name": r"KA×GA",
        "sumerian_transliterations": [r"sub"],
        "src": IMG_55f6713a_ASSET.readall(),
    },
    {
        "name": r"KA×GAN2tenu",
        "sumerian_transliterations": [r"bu3", r"kana6", r"puzur5"],
        "src": IMG_a08593de_ASSET.readall(),
    },
    {
        "name": r"KA×GAR",
        "sumerian_transliterations": [r"gu7", r"šaĝar"],
        "src": IMG_3cd429d6_ASSET.readall(),
    },
    {
        "name": r"KA×IM",
        "sumerian_transliterations": [r"bun2"],
        "src": IMG_572b86d8_ASSET.readall(),
    },
    {
        "name": r"KA×LI",
        "sumerian_transliterations": [r"mu7", r"tu6", r"uš7", r"zug4", r"ĝili3", r"šegx"],
        "src": IMG_a334d27f_ASSET.readall(),
    },
    {
        "name": r"KA×ME",
        "sumerian_transliterations": [r"eme"],
        "src": IMG_10aede87_ASSET.readall(),
    },
    {
        "name": r"KA×MI",
        "sumerian_transliterations": [r"kana5"],
        "src": IMG_05870392_ASSET.readall(),
    },
    {
        "name": r"KA×NE",
        "sumerian_transliterations": [r"urgu2"],
        "src": IMG_b4672c43_ASSET.readall(),
    },
    {
        "name": r"KA×NUN",
        "sumerian_transliterations": [r"nundum"],
        "src": IMG_fff8cb94_ASSET.readall(),
    },
    {
        "name": r"KA×SA",
        "sumerian_transliterations": [r"sun4"],
        "src": IMG_97ec5cc5_ASSET.readall(),
    },
    {
        "name": r"KA×SAR",
        "sumerian_transliterations": [r"ma8"],
        "src": IMG_e98a3322_ASSET.readall(),
    },
    {
        "name": r"KA×ŠE",
        "sumerian_transliterations": [r"tukur2"],
        "src": IMG_84f2944d_ASSET.readall(),
    },
    {
        "name": r"KA×ŠID",
        "sumerian_transliterations": [r"sigx", r"šeg10"],
        "src": IMG_fa4fc2e2_ASSET.readall(),
    },
    {
        "name": r"KA×ŠU",
        "sumerian_transliterations": [r"šudu3"],
        "src": IMG_65c7a63a_ASSET.readall(),
    },
    {
        "name": r"KA×UD",
        "sumerian_transliterations": [r"enmen", r"si19"],
        "src": IMG_130f493c_ASSET.readall(),
    },
    {
        "name": r"KA2",
        "sumerian_transliterations": [r"kan4"],
        "src": IMG_7484f58b_ASSET.readall(),
    },
    {
        "name": r"KAB",
        "sumerian_transliterations": [r"gab2", r"gabu2", r"kab"],
        "src": IMG_b773ac0d_ASSET.readall(),
    },
    {
        "name": r"KAD3",
        "sumerian_transliterations": [r"sedx"],
        "src": IMG_38b85b02_ASSET.readall(),
    },
    {
        "name": r"KAD4",
        "sumerian_transliterations": [r"kad4", r"kam3", r"peš5"],
        "src": IMG_70ed3bc3_ASSET.readall(),
    },
    {
        "name": r"KAD5",
        "sumerian_transliterations": [r"kad5", r"peš6"],
        "src": IMG_a41151c9_ASSET.readall(),
    },
    {
        "name": r"KAK",
        "sumerian_transliterations": [r"da3", r"du3", r"gag", r"ru2", r"ḫenbur"],
        "src": IMG_9a008f0d_ASSET.readall(),
    },
    {
        "name": r"KAL",
        "sumerian_transliterations": [r"alad2", r"esi", r"kal", r"kalag", r"lamma", r"rib", r"sun7", r"zi8", r"ĝuruš"],
        "src": IMG_3c50fee1_ASSET.readall(),
    },
    {
        "name": r"KAL×BAD",
        "sumerian_transliterations": [r"alad"],
        "src": IMG_d411c558_ASSET.readall(),
    },
    {
        "name": r"KASKAL",
        "sumerian_transliterations": [r"eš8", r"ir7", r"kaskal", r"raš"],
        "src": IMG_6b19b302_ASSET.readall(),
    },
    {
        "name": r"KASKAL.LAGAB×U/LAGAB×U",
        "sumerian_transliterations": [r"šubtum6"],
        "src": IMG_cdec54fd_ASSET.readall(),
    },
    {
        "name": r"KEŠ2",
        "sumerian_transliterations": [r"gir11", r"keše2", r"kirid", r"ḫir"],
        "src": IMG_4df96571_ASSET.readall(),
    },
    {
        "name": r"KI",
        "sumerian_transliterations": [r"ge5", r"gi5", r"ke", r"ki", r"qi2"],
        "src": IMG_f495a98c_ASSET.readall(),
    },
    {
        "name": r"KI×U",
        "sumerian_transliterations": [r"ḫabrud"],
        "src": IMG_cbb0d10f_ASSET.readall(),
    },
    {
        "name": r"KID",
        "sumerian_transliterations": [r"ge2", r"gi2", r"ke4", r"kid", r"lil2"],
        "src": IMG_fbfec33b_ASSET.readall(),
    },
    {
        "name": r"KIN",
        "sumerian_transliterations": [r"gur10", r"kin", r"kiĝ2", r"saga11"],
        "src": IMG_ac2d6f91_ASSET.readall(),
    },
    {
        "name": r"KISAL",
        "sumerian_transliterations": [r"kisal", r"par4"],
        "src": IMG_ae085ff7_ASSET.readall(),
    },
    {
        "name": r"KIŠ",
        "sumerian_transliterations": [r"kiš"],
        "src": IMG_cf74bcd5_ASSET.readall(),
    },
    {
        "name": r"KU",
        "sumerian_transliterations": [r"bid3", r"bu7", r"dab5", r"dib2", r"dur2", r"duru2", r"durun", r"gu5", r"ku", r"nu10", r"suḫ5", r"tukul", r"tuš", r"ugu4", r"še10"],
        "src": IMG_5d3d9022_ASSET.readall(),
    },
    {
        "name": r"KU3",
        "sumerian_transliterations": [r"ku3", r"kug"],
        "src": IMG_4d69d36c_ASSET.readall(),
    },
    {
        "name": r"KU4",
        "sumerian_transliterations": [r"ku4", r"kur9"],
        "src": IMG_760e9cbe_ASSET.readall(),
    },
    {
        "name": r"KU7",
        "sumerian_transliterations": [r"gurušta", r"ku7"],
        "src": IMG_21573837_ASSET.readall(),
    },
    {
        "name": r"KUL",
        "sumerian_transliterations": [r"kul", r"numun"],
        "src": IMG_c28e7e25_ASSET.readall(),
    },
    {
        "name": r"KUN",
        "sumerian_transliterations": [r"kun"],
        "src": IMG_bb8eb91c_ASSET.readall(),
    },
    {
        "name": r"KUR",
        "sumerian_transliterations": [r"gin3", r"kur"],
        "src": IMG_4c3c79a0_ASSET.readall(),
    },
    {
        "name": r"KUŠU2",
        "sumerian_transliterations": [r"kušu2", r"uḫ3"],
        "src": IMG_12574514_ASSET.readall(),
    },
    {
        "name": r"LA",
        "sumerian_transliterations": [r"la", r"šika"],
        "src": IMG_e57153fa_ASSET.readall(),
    },
    {
        "name": r"LAGAB",
        "sumerian_transliterations": [r"ellag", r"girin", r"gur4", r"kilib", r"kir3", r"lagab", r"lugud2", r"ni10", r"niĝin2", r"rin", r"ḫab"],
        "src": IMG_7b72cad8_ASSET.readall(),
    },
    {
        "name": r"LAGAB×A",
        "sumerian_transliterations": [r"ambar", r"as4", r"buniĝ", r"sug"],
        "src": IMG_b5630b33_ASSET.readall(),
    },
    {
        "name": r"LAGAB×BAD",
        "sumerian_transliterations": [r"gigir"],
        "src": IMG_5afa5769_ASSET.readall(),
    },
    {
        "name": r"LAGAB×GAR",
        "sumerian_transliterations": [r"buniĝ2"],
        "src": IMG_1ff4fb5a_ASSET.readall(),
    },
    {
        "name": r"LAGAB×GUD",
        "sumerian_transliterations": [r"šurum3"],
        "src": IMG_0456196d_ASSET.readall(),
    },
    {
        "name": r"LAGAB×GUD+GUD",
        "sumerian_transliterations": [r"ganam4", r"u8", r"šurum"],
        "src": IMG_c3de0859_ASSET.readall(),
    },
    {
        "name": r"LAGAB×HAL",
        "sumerian_transliterations": [r"engur", r"namma"],
        "src": IMG_1d27c49d_ASSET.readall(),
    },
    {
        "name": r"LAGAB×IGIgunu",
        "sumerian_transliterations": [r"immax", r"šara2"],
        "src": IMG_357712cc_ASSET.readall(),
    },
    {
        "name": r"LAGAB×KUL",
        "sumerian_transliterations": [r"esir2"],
        "src": IMG_fe9cf4cc_ASSET.readall(),
    },
    {
        "name": r"LAGAB×SUM",
        "sumerian_transliterations": [r"zar"],
        "src": IMG_d10849c0_ASSET.readall(),
    },
    {
        "name": r"LAGAB×U",
        "sumerian_transliterations": [r"bu4", r"dul2", r"gigir2", r"pu2", r"tul2", r"ub4", r"ḫab2"],
        "src": IMG_7a35d308_ASSET.readall(),
    },
    {
        "name": r"LAGAB×U+A",
        "sumerian_transliterations": [r"umaḫ"],
        "src": IMG_409fd636_ASSET.readall(),
    },
    {
        "name": r"LAGAB×U+U+U",
        "sumerian_transliterations": [r"bul", r"bur10", r"ninna2", r"tuku4"],
        "src": IMG_34322a74_ASSET.readall(),
    },
    {
        "name": r"LAGAR",
        "sumerian_transliterations": [r"lagar"],
        "src": IMG_35a05541_ASSET.readall(),
    },
    {
        "name": r"LAGARgunu",
        "sumerian_transliterations": [r"du6"],
        "src": IMG_c72afcf4_ASSET.readall(),
    },
    {
        "name": r"LAGARgunu/LAGARgunu.ŠE",
        "sumerian_transliterations": [r"part of compound"],
        "src": IMG_4ba47beb_ASSET.readall(),
    },
    {
        "name": r"LAGAR×ŠE",
        "sumerian_transliterations": [r"sur12"],
        "src": IMG_01a69d08_ASSET.readall(),
    },
    {
        "name": r"LAL",
        "sumerian_transliterations": [r"la2", r"lal", r"suru5"],
        "src": IMG_75a79c30_ASSET.readall(),
    },
    {
        "name": r"LAL×LAL",
        "sumerian_transliterations": [r"part of compound"],
        "src": IMG_acf2c701_ASSET.readall(),
    },
    {
        "name": r"LAM",
        "sumerian_transliterations": [r"ešx", r"lam"],
        "src": IMG_7569ff61_ASSET.readall(),
    },
    {
        "name": r"LI",
        "sumerian_transliterations": [r"en3", r"gub2", r"le", r"li"],
        "src": IMG_46660b6f_ASSET.readall(),
    },
    {
        "name": r"LIL",
        "sumerian_transliterations": [r"lil", r"sukux"],
        "src": IMG_28f09589_ASSET.readall(),
    },
    {
        "name": r"LIMMU2",
        "sumerian_transliterations": [r"limmu2"],
        "src": IMG_c0550c6f_ASSET.readall(),
    },
    {
        "name": r"LIŠ",
        "sumerian_transliterations": [r"dilim2"],
        "src": IMG_9891b743_ASSET.readall(),
    },
    {
        "name": r"LU",
        "sumerian_transliterations": [r"lu", r"lug", r"nu12", r"udu"],
        "src": IMG_f5a6c4f6_ASSET.readall(),
    },
    {
        "name": r"LU×BAD",
        "sumerian_transliterations": [r"ad3"],
        "src": IMG_1be39411_ASSET.readall(),
    },
    {
        "name": r"LU2",
        "sumerian_transliterations": [r"lu2"],
        "src": IMG_3949ba43_ASSET.readall(),
    },
    {
        "name": r"LU2(inverted)LU2",
        "sumerian_transliterations": [r"inbir"],
        "src": IMG_6081aa9e_ASSET.readall(),
    },
    {
        "name": r"LU2šešig",
        "sumerian_transliterations": [r"ri9"],
        "src": IMG_5059f42f_ASSET.readall(),
    },
    {
        "name": r"LU2×BAD",
        "sumerian_transliterations": [r"ad6"],
        "src": IMG_9260075b_ASSET.readall(),
    },
    {
        "name": r"LU2×GAN2tenu",
        "sumerian_transliterations": [r"šaĝa", r"še29"],
        "src": IMG_27fd535f_ASSET.readall(),
    },
    {
        "name": r"LU2×NE",
        "sumerian_transliterations": [r"du14"],
        "src": IMG_4f62b877_ASSET.readall(),
    },
    {
        "name": r"LU3",
        "sumerian_transliterations": [r"gar5", r"gug2", r"lu3"],
        "src": IMG_7e680be9_ASSET.readall(),
    },
    {
        "name": r"LUGAL",
        "sumerian_transliterations": [r"lillan", r"lugal", r"rab3", r"šarrum"],
        "src": IMG_962f435d_ASSET.readall(),
    },
    {
        "name": r"LUGALšešig",
        "sumerian_transliterations": [r"dim3"],
        "src": IMG_90031e56_ASSET.readall(),
    },
    {
        "name": r"LUH",
        "sumerian_transliterations": [r"luḫ", r"sukkal", r"ḫuluḫ"],
        "src": IMG_6127e76b_ASSET.readall(),
    },
    {
        "name": r"LUL",
        "sumerian_transliterations": [r"ka5", r"lib", r"lu5", r"lub", r"lul", r"nar", r"paḫ", r"šatam"],
        "src": IMG_45215991_ASSET.readall(),
    },
    {
        "name": r"LUM",
        "sumerian_transliterations": [r"gum2", r"gun5", r"guz", r"lum", r"num2", r"ḫum", r"ḫuz"],
        "src": IMG_d0cba88b_ASSET.readall(),
    },
    {
        "name": r"MA",
        "sumerian_transliterations": [r"ma", r"peš3"],
        "src": IMG_e53eba15_ASSET.readall(),
    },
    {
        "name": r"MAgunu",
        "sumerian_transliterations": [r"ḫašḫur"],
        "src": IMG_d4672d8d_ASSET.readall(),
    },
    {
        "name": r"MA2",
        "sumerian_transliterations": [r"ma2"],
        "src": IMG_deeae69d_ASSET.readall(),
    },
    {
        "name": r"MAH",
        "sumerian_transliterations": [r"maḫ", r"šutur"],
        "src": IMG_d2d91b19_ASSET.readall(),
    },
    {
        "name": r"MAR",
        "sumerian_transliterations": [r"mar"],
        "src": IMG_93b37396_ASSET.readall(),
    },
    {
        "name": r"MAŠ",
        "sumerian_transliterations": [r"mas", r"maš", r"sa9"],
        "src": IMG_c280ec8a_ASSET.readall(),
    },
    {
        "name": r"MAŠ2",
        "sumerian_transliterations": [r"maš2"],
        "src": IMG_a9ed06f9_ASSET.readall(),
    },
    {
        "name": r"ME",
        "sumerian_transliterations": [r"ba13", r"išib", r"me", r"men2"],
        "src": IMG_de89829b_ASSET.readall(),
    },
    {
        "name": r"MES",
        "sumerian_transliterations": [r"kišib", r"meš3"],
        "src": IMG_741f8628_ASSET.readall(),
    },
    {
        "name": r"MI",
        "sumerian_transliterations": [r"gig2", r"ku10", r"me2", r"mi", r"ĝi6"],
        "src": IMG_93fbb7d6_ASSET.readall(),
    },
    {
        "name": r"MIN",
        "sumerian_transliterations": [r"min"],
        "src": IMG_98da46ed_ASSET.readall(),
    },
    {
        "name": r"MU",
        "sumerian_transliterations": [r"mu", r"muḫaldim", r"ĝu10"],
        "src": IMG_519c0499_ASSET.readall(),
    },
    {
        "name": r"MU/MU",
        "sumerian_transliterations": [r"daḫ", r"taḫ"],
        "src": IMG_84954883_ASSET.readall(),
    },
    {
        "name": r"MUG",
        "sumerian_transliterations": [r"mug"],
        "src": IMG_e0b78ca5_ASSET.readall(),
    },
    {
        "name": r"MUNSUB",
        "sumerian_transliterations": [r"sumur3"],
        "src": IMG_5277f975_ASSET.readall(),
    },
    {
        "name": r"MURGU2",
        "sumerian_transliterations": [r"murgu2"],
        "src": IMG_ef5ac2dc_ASSET.readall(),
    },
    {
        "name": r"MUŠ",
        "sumerian_transliterations": [r"muš", r"niraḫ", r"suḫx", r"šubax"],
        "src": IMG_5779dd1c_ASSET.readall(),
    },
    {
        "name": r"MUŠ/MUŠ",
        "sumerian_transliterations": [r"ri8"],
        "src": IMG_b0efb116_ASSET.readall(),
    },
    {
        "name": r"MUŠ/MUŠ×A+NA",
        "sumerian_transliterations": [r"erina8"],
        "src": IMG_fd260b30_ASSET.readall(),
    },
    {
        "name": r"MUŠ3",
        "sumerian_transliterations": [r"inana", r"muš3", r"sed6", r"suḫ10", r"šuba4"],
        "src": IMG_55f52c48_ASSET.readall(),
    },
    {
        "name": r"MUŠ3gunu",
        "sumerian_transliterations": [r"muš2", r"susbu2", r"suḫ"],
        "src": IMG_41d66b4c_ASSET.readall(),
    },
    {
        "name": r"MUŠ3×A",
        "sumerian_transliterations": [r"part of compound"],
        "src": IMG_84c76c14_ASSET.readall(),
    },
    {
        "name": r"MUŠ3×A+DI",
        "sumerian_transliterations": [r"sed"],
        "src": IMG_9303789e_ASSET.readall(),
    },
    {
        "name": r"NA",
        "sumerian_transliterations": [r"na"],
        "src": IMG_53ca20e5_ASSET.readall(),
    },
    {
        "name": r"NA2",
        "sumerian_transliterations": [r"na2", r"nu2"],
        "src": IMG_9f4942c1_ASSET.readall(),
    },
    {
        "name": r"NAGA",
        "sumerian_transliterations": [r"ereš2", r"naĝa", r"nisaba2"],
        "src": IMG_017fad4d_ASSET.readall(),
    },
    {
        "name": r"NAGA(inverted)",
        "sumerian_transliterations": [r"teme"],
        "src": IMG_8fb0fda3_ASSET.readall(),
    },
    {
        "name": r"NAGAR",
        "sumerian_transliterations": [r"nagar"],
        "src": IMG_336672dc_ASSET.readall(),
    },
    {
        "name": r"NAM",
        "sumerian_transliterations": [r"bir5", r"nam", r"sim", r"sin2"],
        "src": IMG_650e754e_ASSET.readall(),
    },
    {
        "name": r"NE",
        "sumerian_transliterations": [r"bar7", r"be7", r"bi2", r"bil", r"de3", r"du17", r"gibil4", r"izi", r"kum2", r"lam2", r"lem4", r"li9", r"ne", r"ni5", r"pel", r"pil", r"saḫarx", r"šeĝ6"],
        "src": IMG_d71a1626_ASSET.readall(),
    },
    {
        "name": r"NEšešig",
        "sumerian_transliterations": [r"bil2", r"gibil", r"pel2"],
        "src": IMG_c859f386_ASSET.readall(),
    },
    {
        "name": r"NI",
        "sumerian_transliterations": [r"be3", r"dig", r"i3", r"ia3", r"le2", r"li2", r"lid2", r"ne2", r"ni", r"suš2", r"zal", r"zar2"],
        "src": IMG_9b2d1f64_ASSET.readall(),
    },
    {
        "name": r"NIM",
        "sumerian_transliterations": [r"deḫi3", r"elam", r"nim", r"tum4"],
        "src": IMG_442d2268_ASSET.readall(),
    },
    {
        "name": r"NIM×GAN2tenu",
        "sumerian_transliterations": [r"tum3"],
        "src": IMG_3f8cc66e_ASSET.readall(),
    },
    {
        "name": r"NINDA2",
        "sumerian_transliterations": [r"inda", r"ninda2"],
        "src": IMG_e0dca16d_ASSET.readall(),
    },
    {
        "name": r"NINDA2×GUD",
        "sumerian_transliterations": [r"indagara"],
        "src": IMG_9508396b_ASSET.readall(),
    },
    {
        "name": r"NINDA2×NE",
        "sumerian_transliterations": [r"aĝ2", r"em3", r"eĝ3", r"iĝ3"],
        "src": IMG_997fc62c_ASSET.readall(),
    },
    {
        "name": r"NINDA2×ŠE",
        "sumerian_transliterations": [r"sa10", r"sam2"],
        "src": IMG_99c16546_ASSET.readall(),
    },
    {
        "name": r"NISAG",
        "sumerian_transliterations": [r"nesaĝ"],
        "src": IMG_0d98e366_ASSET.readall(),
    },
    {
        "name": r"NU",
        "sumerian_transliterations": [r"nu", r"sir5"],
        "src": IMG_e89a35c6_ASSET.readall(),
    },
    {
        "name": r"NU11",
        "sumerian_transliterations": [r"nu11"],
        "src": IMG_82459f39_ASSET.readall(),
    },
    {
        "name": r"NUN",
        "sumerian_transliterations": [r"eridug", r"nun", r"sil2", r"zil"],
        "src": IMG_07082229_ASSET.readall(),
    },
    {
        "name": r"NUNUZ",
        "sumerian_transliterations": [r"nida", r"nunuz", r"nus"],
        "src": IMG_49a3a018_ASSET.readall(),
    },
    {
        "name": r"NUNUZ.AB2×AŠGAB",
        "sumerian_transliterations": [r"usan3"],
        "src": IMG_54b3cc09_ASSET.readall(),
    },
    {
        "name": r"NUNUZ.AB2×LA",
        "sumerian_transliterations": [r"laḫtan"],
        "src": IMG_e6e001db_ASSET.readall(),
    },
    {
        "name": r"NUN.LAGAR×MAŠ",
        "sumerian_transliterations": [r"immal"],
        "src": IMG_19875dd5_ASSET.readall(),
    },
    {
        "name": r"NUN.LAGAR×SAL",
        "sumerian_transliterations": [r"arḫuš2", r"immal2", r"šilam"],
        "src": IMG_5a8a402c_ASSET.readall(),
    },
    {
        "name": r"NUN/NUN",
        "sumerian_transliterations": [r"nir", r"ri5", r"tirx", r"šer7"],
        "src": IMG_e4c6c755_ASSET.readall(),
    },
    {
        "name": r"NUNtenu",
        "sumerian_transliterations": [r"agargara", r"garx"],
        "src": IMG_fb7fb9cb_ASSET.readall(),
    },
    {
        "name": r"PA",
        "sumerian_transliterations": [r"kumx", r"kun2", r"mu6", r"mudru", r"pa", r"sag3", r"sig3", r"ugula", r"ux", r"ĝidru", r"ḫendur"],
        "src": IMG_bf1f9378_ASSET.readall(),
    },
    {
        "name": r"PAD",
        "sumerian_transliterations": [r"kurum6", r"pad", r"pax", r"šukur2", r"šutug"],
        "src": IMG_8f84b41a_ASSET.readall(),
    },
    {
        "name": r"PAN",
        "sumerian_transliterations": [r"pan"],
        "src": IMG_f695f1c2_ASSET.readall(),
    },
    {
        "name": r"PAP",
        "sumerian_transliterations": [r"kur2", r"pa4", r"pap"],
        "src": IMG_a63bac6d_ASSET.readall(),
    },
    {
        "name": r"PEŠ2",
        "sumerian_transliterations": [r"kilim", r"peš2"],
        "src": IMG_c7faff06_ASSET.readall(),
    },
    {
        "name": r"PI",
        "sumerian_transliterations": [r"be6", r"bi3", r"me8", r"pa12", r"pe", r"pi", r"tal2", r"wa", r"we", r"wi", r"ĝeštug"],
        "src": IMG_95e9e634_ASSET.readall(),
    },
    {
        "name": r"PIRIG",
        "sumerian_transliterations": [r"ne3", r"niskum", r"piriĝ"],
        "src": IMG_147c5f13_ASSET.readall(),
    },
    {
        "name": r"PIRIG(inverted)PIRIG",
        "sumerian_transliterations": [r"tidnim", r"tidnum"],
        "src": IMG_039c993b_ASSET.readall(),
    },
    {
        "name": r"PIRIG×UD",
        "sumerian_transliterations": [r"piriĝ3", r"ug", r"uk", r"uq"],
        "src": IMG_6e7b2f78_ASSET.readall(),
    },
    {
        "name": r"PIRIG×ZA",
        "sumerian_transliterations": [r"az"],
        "src": IMG_7a6f0ae1_ASSET.readall(),
    },
    {
        "name": r"RA",
        "sumerian_transliterations": [r"ra"],
        "src": IMG_e4a8986c_ASSET.readall(),
    },
    {
        "name": r"RI",
        "sumerian_transliterations": [r"dal", r"de5", r"re", r"ri", r"rig5"],
        "src": IMG_bbbd1c2a_ASSET.readall(),
    },
    {
        "name": r"RU",
        "sumerian_transliterations": [r"ilar", r"ru", r"šub"],
        "src": IMG_42aa34de_ASSET.readall(),
    },
    {
        "name": r"SA",
        "sumerian_transliterations": [r"sa"],
        "src": IMG_36f18d71_ASSET.readall(),
    },
    {
        "name": r"SAG",
        "sumerian_transliterations": [r"dul7", r"sa12", r"saĝ", r"šak"],
        "src": IMG_660bf1ee_ASSET.readall(),
    },
    {
        "name": r"SAGgunu",
        "sumerian_transliterations": [r"dul3", r"kuš2", r"kušu4", r"sumur", r"sur2"],
        "src": IMG_7884df31_ASSET.readall(),
    },
    {
        "name": r"SAG×ŠID",
        "sumerian_transliterations": [r"dilib3"],
        "src": IMG_39008c85_ASSET.readall(),
    },
    {
        "name": r"SAG×U2",
        "sumerian_transliterations": [r"uzug3"],
        "src": IMG_69e30ead_ASSET.readall(),
    },
    {
        "name": r"SAL",
        "sumerian_transliterations": [r"gal4", r"mi2", r"munus", r"sal"],
        "src": IMG_098ad690_ASSET.readall(),
    },
    {
        "name": r"SAR",
        "sumerian_transliterations": [r"kiri6", r"mu2", r"nisig", r"sakar", r"sar", r"saḫar2", r"sigx", r"šar"],
        "src": IMG_4accea70_ASSET.readall(),
    },
    {
        "name": r"SI",
        "sumerian_transliterations": [r"si", r"sig9"],
        "src": IMG_52fcb805_ASSET.readall(),
    },
    {
        "name": r"SIgunu",
        "sumerian_transliterations": [r"sa11", r"su4"],
        "src": IMG_9b4f4586_ASSET.readall(),
    },
    {
        "name": r"SIG",
        "sumerian_transliterations": [r"si11", r"sig", r"sik", r"šex"],
        "src": IMG_873f460b_ASSET.readall(),
    },
    {
        "name": r"SIG4",
        "sumerian_transliterations": [r"kulla", r"murgu", r"ĝar8", r"šeg12"],
        "src": IMG_658ec908_ASSET.readall(),
    },
    {
        "name": r"SIK2",
        "sumerian_transliterations": [r"siki"],
        "src": IMG_0e182320_ASSET.readall(),
    },
    {
        "name": r"SILA3",
        "sumerian_transliterations": [r"qa", r"sal4", r"sila3"],
        "src": IMG_f0c3fc78_ASSET.readall(),
    },
    {
        "name": r"SU",
        "sumerian_transliterations": [r"kuš", r"su", r"sug6"],
        "src": IMG_7d797889_ASSET.readall(),
    },
    {
        "name": r"SUD",
        "sumerian_transliterations": [r"su3", r"sud", r"sug4"],
        "src": IMG_f299c389_ASSET.readall(),
    },
    {
        "name": r"SUD2",
        "sumerian_transliterations": [r"sud2", r"šita3"],
        "src": IMG_614e9017_ASSET.readall(),
    },
    {
        "name": r"SUHUR",
        "sumerian_transliterations": [r"sumur2", r"suḫur"],
        "src": IMG_395922a9_ASSET.readall(),
    },
    {
        "name": r"SUM",
        "sumerian_transliterations": [r"si3", r"sig10", r"sum", r"šum2"],
        "src": IMG_594a4302_ASSET.readall(),
    },
    {
        "name": r"SUR",
        "sumerian_transliterations": [r"sur"],
        "src": IMG_86066ece_ASSET.readall(),
    },
    {
        "name": r"ŠA",
        "sumerian_transliterations": [r"en8", r"ša"],
        "src": IMG_d932d1cf_ASSET.readall(),
    },
    {
        "name": r"ŠA3",
        "sumerian_transliterations": [r"pešx", r"ša3", r"šag4"],
        "src": IMG_d6cc9b7a_ASSET.readall(),
    },
    {
        "name": r"ŠA3×A",
        "sumerian_transliterations": [r"bir7", r"iškila", r"peš4"],
        "src": IMG_c24ef6f2_ASSET.readall(),
    },
    {
        "name": r"ŠA3×NE",
        "sumerian_transliterations": [r"ninim"],
        "src": IMG_644cd76f_ASSET.readall(),
    },
    {
        "name": r"ŠA3×TUR",
        "sumerian_transliterations": [r"peš13"],
        "src": IMG_8ec02b2b_ASSET.readall(),
    },
    {
        "name": r"ŠA6",
        "sumerian_transliterations": [r"sa6", r"sag9", r"ĝišnimbar"],
        "src": IMG_3cfc046b_ASSET.readall(),
    },
    {
        "name": r"ŠE",
        "sumerian_transliterations": [r"niga", r"še"],
        "src": IMG_183b22b1_ASSET.readall(),
    },
    {
        "name": r"ŠE/ŠE.TAB/TAB.GAR/GAR",
        "sumerian_transliterations": [r"garadin3"],
        "src": IMG_65f11b50_ASSET.readall(),
    },
    {
        "name": r"ŠEG9",
        "sumerian_transliterations": [r"kiši6", r"šeg9"],
        "src": IMG_1fa09832_ASSET.readall(),
    },
    {
        "name": r"ŠEN",
        "sumerian_transliterations": [r"dur10", r"šen"],
        "src": IMG_68d3ab36_ASSET.readall(),
    },
    {
        "name": r"ŠEŠ",
        "sumerian_transliterations": [r"mun4", r"muš5", r"sis", r"šeš"],
        "src": IMG_e27702cf_ASSET.readall(),
    },
    {
        "name": r"ŠEŠ2",
        "sumerian_transliterations": [r"še8", r"šeš2"],
        "src": IMG_c1ff91e5_ASSET.readall(),
    },
    {
        "name": r"ŠID",
        "sumerian_transliterations": [r"kas7", r"kiri8", r"lag", r"nesaĝ2", r"pisaĝ2", r"saĝ5", r"saĝĝa", r"silaĝ", r"šid", r"šub6", r"šudum"],
        "src": IMG_c30a4356_ASSET.readall(),
    },
    {
        "name": r"ŠID×A",
        "sumerian_transliterations": [r"alal", r"pisaĝ3"],
        "src": IMG_f63f042b_ASSET.readall(),
    },
    {
        "name": r"ŠIM",
        "sumerian_transliterations": [r"bappir2", r"lunga", r"mud5", r"šem", r"šembi2", r"šembizid", r"šim"],
        "src": IMG_af779bdd_ASSET.readall(),
    },
    {
        "name": r"ŠIM×GAR",
        "sumerian_transliterations": [r"bappir", r"lunga3"],
        "src": IMG_0a638198_ASSET.readall(),
    },
    {
        "name": r"ŠIM×IGIgunu",
        "sumerian_transliterations": [r"šembi"],
        "src": IMG_d0ea14ae_ASSET.readall(),
    },
    {
        "name": r"ŠIM×KUŠU2",
        "sumerian_transliterations": [r"šembulugx"],
        "src": IMG_3b8a00bf_ASSET.readall(),
    },
    {
        "name": r"ŠINIG",
        "sumerian_transliterations": [r"šinig"],
        "src": IMG_f5d62d35_ASSET.readall(),
    },
    {
        "name": r"ŠIR",
        "sumerian_transliterations": [r"aš7", r"šir"],
        "src": IMG_15a590ea_ASSET.readall(),
    },
    {
        "name": r"ŠITA",
        "sumerian_transliterations": [r"šita"],
        "src": IMG_cbddfa47_ASSET.readall(),
    },
    {
        "name": r"ŠU",
        "sumerian_transliterations": [r"šu"],
        "src": IMG_369e3814_ASSET.readall(),
    },
    {
        "name": r"ŠU2",
        "sumerian_transliterations": [r"šu2", r"šuš2"],
        "src": IMG_2510cef5_ASSET.readall(),
    },
    {
        "name": r"ŠUBUR",
        "sumerian_transliterations": [r"šaḫ", r"šubur"],
        "src": IMG_01f62c5a_ASSET.readall(),
    },
    {
        "name": r"TA",
        "sumerian_transliterations": [r"da2", r"ta"],
        "src": IMG_62fb4c2e_ASSET.readall(),
    },
    {
        "name": r"TA×HI",
        "sumerian_transliterations": [r"alamuš", r"lal3"],
        "src": IMG_219f1f7b_ASSET.readall(),
    },
    {
        "name": r"TAB",
        "sumerian_transliterations": [r"dab2", r"tab", r"tap"],
        "src": IMG_dc834b29_ASSET.readall(),
    },
    {
        "name": r"TAG",
        "sumerian_transliterations": [r"sub6", r"tag", r"tibir", r"tuku5", r"zil2", r"šum"],
        "src": IMG_3ccd1a65_ASSET.readall(),
    },
    {
        "name": r"TAG×ŠU",
        "sumerian_transliterations": [r"tibir2"],
        "src": IMG_261799a9_ASSET.readall(),
    },
    {
        "name": r"TAG×TUG2",
        "sumerian_transliterations": [r"uttu"],
        "src": IMG_95b2230d_ASSET.readall(),
    },
    {
        "name": r"TAK4",
        "sumerian_transliterations": [r"da13", r"kid2", r"tak4", r"taka4"],
        "src": IMG_e1f53035_ASSET.readall(),
    },
    {
        "name": r"TAR",
        "sumerian_transliterations": [r"ku5", r"kud", r"kur5", r"sila", r"tar", r"ḫaš"],
        "src": IMG_733a17b6_ASSET.readall(),
    },
    {
        "name": r"TE",
        "sumerian_transliterations": [r"gal5", r"te", r"temen", r"ten", r"teĝ3"],
        "src": IMG_871ba23d_ASSET.readall(),
    },
    {
        "name": r"TEgunu",
        "sumerian_transliterations": [r"gur8", r"tenx", r"uru5"],
        "src": IMG_8f03f64f_ASSET.readall(),
    },
    {
        "name": r"TI",
        "sumerian_transliterations": [r"de9", r"di3", r"ti", r"til3", r"tiĝ4"],
        "src": IMG_60719bb7_ASSET.readall(),
    },
    {
        "name": r"TIL",
        "sumerian_transliterations": [r"sumun", r"til", r"šumun"],
        "src": IMG_3644238a_ASSET.readall(),
    },
    {
        "name": r"TIR",
        "sumerian_transliterations": [r"ezina3", r"ter", r"tir"],
        "src": IMG_56251961_ASSET.readall(),
    },
    {
        "name": r"TU",
        "sumerian_transliterations": [r"du2", r"tu", r"tud", r"tum12", r"tur5"],
        "src": IMG_b5815ca9_ASSET.readall(),
    },
    {
        "name": r"TUG2",
        "sumerian_transliterations": [r"azlag2", r"dul5", r"mu4", r"mur10", r"nam2", r"taškarin", r"tubax", r"tug2", r"tuku2", r"umuš"],
        "src": IMG_dd0f97bd_ASSET.readall(),
    },
    {
        "name": r"TUK",
        "sumerian_transliterations": [r"du12", r"tuk", r"tuku"],
        "src": IMG_7359b7b4_ASSET.readall(),
    },
    {
        "name": r"TUM",
        "sumerian_transliterations": [r"dum", r"eb2", r"ib2", r"tum"],
        "src": IMG_d0487696_ASSET.readall(),
    },
    {
        "name": r"TUR",
        "sumerian_transliterations": [r"ban3", r"banda3", r"di4", r"dumu", r"tur"],
        "src": IMG_fb0cf0fd_ASSET.readall(),
    },
    {
        "name": r"U",
        "sumerian_transliterations": [r"bur3", r"buru3", r"u", r"šu4"],
        "src": IMG_01f643f7_ASSET.readall(),
    },
    {
        "name": r"U.GUD",
        "sumerian_transliterations": [r"du7", r"ul"],
        "src": IMG_42369512_ASSET.readall(),
    },
    {
        "name": r"U.U.U",
        "sumerian_transliterations": [r"es2", r"eš"],
        "src": IMG_a468ef2c_ASSET.readall(),
    },
    {
        "name": r"U/U.PA/PA.GAR/GAR",
        "sumerian_transliterations": [r"garadin10"],
        "src": IMG_5087f1ec_ASSET.readall(),
    },
    {
        "name": r"U/U.SUR/SUR",
        "sumerian_transliterations": [r"garadin9"],
        "src": IMG_edc6afd6_ASSET.readall(),
    },
    {
        "name": r"U2",
        "sumerian_transliterations": [r"kuš3", r"u2"],
        "src": IMG_2f3856c8_ASSET.readall(),
    },
    {
        "name": r"UB",
        "sumerian_transliterations": [r"ar2", r"ub", r"up"],
        "src": IMG_22b1a7e5_ASSET.readall(),
    },
    {
        "name": r"UD",
        "sumerian_transliterations": [r"a12", r"babbar", r"bir2", r"dag2", r"tam", r"u4", r"ud", r"ut", r"utu", r"zalag", r"šamaš", r"ḫad2"],
        "src": IMG_52674a31_ASSET.readall(),
    },
    {
        "name": r"UD.KUŠU2",
        "sumerian_transliterations": [r"akšak", r"aḫ6", r"uḫ2"],
        "src": IMG_f49f2a81_ASSET.readall(),
    },
    {
        "name": r"UD×U+U+U",
        "sumerian_transliterations": [r"itid"],
        "src": IMG_0131dfd1_ASSET.readall(),
    },
    {
        "name": r"UD×U+U+Ugunu",
        "sumerian_transliterations": [r"murub4"],
        "src": IMG_c7a809d3_ASSET.readall(),
    },
    {
        "name": r"UDUG",
        "sumerian_transliterations": [r"udug"],
        "src": IMG_6061eb46_ASSET.readall(),
    },
    {
        "name": r"UM",
        "sumerian_transliterations": [r"deḫi2", r"um"],
        "src": IMG_62a44deb_ASSET.readall(),
    },
    {
        "name": r"UMUM",
        "sumerian_transliterations": [r"simug", r"umum", r"umun2"],
        "src": IMG_34de12ae_ASSET.readall(),
    },
    {
        "name": r"UMUM×KASKAL",
        "sumerian_transliterations": [r"abzux", r"de2"],
        "src": IMG_4e372a11_ASSET.readall(),
    },
    {
        "name": r"UN",
        "sumerian_transliterations": [r"kalam", r"un", r"uĝ3"],
        "src": IMG_779dd430_ASSET.readall(),
    },
    {
        "name": r"UR",
        "sumerian_transliterations": [r"teš2", r"ur"],
        "src": IMG_886e9eed_ASSET.readall(),
    },
    {
        "name": r"URšešig",
        "sumerian_transliterations": [r"dul9"],
        "src": IMG_9dbdf155_ASSET.readall(),
    },
    {
        "name": r"UR2",
        "sumerian_transliterations": [r"ur2"],
        "src": IMG_a332da77_ASSET.readall(),
    },
    {
        "name": r"UR2×NUN",
        "sumerian_transliterations": [r"ušbar"],
        "src": IMG_cecd3c30_ASSET.readall(),
    },
    {
        "name": r"UR2×U2",
        "sumerian_transliterations": [r"ušbar7"],
        "src": IMG_9f7409b9_ASSET.readall(),
    },
    {
        "name": r"UR2×U2+AŠ",
        "sumerian_transliterations": [r"ušbar3"],
        "src": IMG_5250a5c0_ASSET.readall(),
    },
    {
        "name": r"UR4",
        "sumerian_transliterations": [r"ur4"],
        "src": IMG_4af99cb6_ASSET.readall(),
    },
    {
        "name": r"URI",
        "sumerian_transliterations": [r"uri"],
        "src": IMG_e290115c_ASSET.readall(),
    },
    {
        "name": r"URI3",
        "sumerian_transliterations": [r"urin", r"uru3"],
        "src": IMG_ac9ddc3d_ASSET.readall(),
    },
    {
        "name": r"URU",
        "sumerian_transliterations": [r"eri", r"iri", r"re2", r"ri2", r"u19", r"uru"],
        "src": IMG_f937e911_ASSET.readall(),
    },
    {
        "name": r"URU×A",
        "sumerian_transliterations": [r"uru18"],
        "src": IMG_85ec0a85_ASSET.readall(),
    },
    {
        "name": r"URU×BAR",
        "sumerian_transliterations": [r"unken"],
        "src": IMG_ccba99ed_ASSET.readall(),
    },
    {
        "name": r"URU×GA",
        "sumerian_transliterations": [r"šakir3"],
        "src": IMG_11d11e94_ASSET.readall(),
    },
    {
        "name": r"URU×GAR",
        "sumerian_transliterations": [r"erim3"],
        "src": IMG_201cb86e_ASSET.readall(),
    },
    {
        "name": r"URU×GU",
        "sumerian_transliterations": [r"gur5", r"guru5", r"guruš3", r"šakir", r"šegx"],
        "src": IMG_cc688c54_ASSET.readall(),
    },
    {
        "name": r"URU×IGI",
        "sumerian_transliterations": [r"asal", r"asar", r"asari", r"silig"],
        "src": IMG_1f3365eb_ASSET.readall(),
    },
    {
        "name": r"URU×MIN",
        "sumerian_transliterations": [r"u18", r"ulu3", r"uru17", r"ĝišgal"],
        "src": IMG_a4dcaafc_ASSET.readall(),
    },
    {
        "name": r"URU×TU",
        "sumerian_transliterations": [r"šeg5"],
        "src": IMG_f35454fc_ASSET.readall(),
    },
    {
        "name": r"URU×UD",
        "sumerian_transliterations": [r"erim6", r"uru2"],
        "src": IMG_3d96b2d1_ASSET.readall(),
    },
    {
        "name": r"URU×URUDA",
        "sumerian_transliterations": [r"banšur", r"silig5", r"urux"],
        "src": IMG_57126452_ASSET.readall(),
    },
    {
        "name": r"URUDA",
        "sumerian_transliterations": [r"dab6", r"urud"],
        "src": IMG_17616339_ASSET.readall(),
    },
    {
        "name": r"UŠ",
        "sumerian_transliterations": [r"nitaḫ", r"us2", r"uš", r"ĝiš3"],
        "src": IMG_acaff5e3_ASSET.readall(),
    },
    {
        "name": r"UŠ2",
        "sumerian_transliterations": [r"ug7", r"uš2"],
        "src": IMG_57540126_ASSET.readall(),
    },
    {
        "name": r"UŠ×A",
        "sumerian_transliterations": [r"kaš3"],
        "src": IMG_aa9ab0f1_ASSET.readall(),
    },
    {
        "name": r"UŠ×TAK4",
        "sumerian_transliterations": [r"dan6"],
        "src": IMG_892cc318_ASSET.readall(),
    },
    {
        "name": r"UZ3",
        "sumerian_transliterations": [r"ud5", r"uz3"],
        "src": IMG_5f91f36a_ASSET.readall(),
    },
    {
        "name": r"UZU",
        "sumerian_transliterations": [r"uzu"],
        "src": IMG_a72167f5_ASSET.readall(),
    },
    {
        "name": r"ZA",
        "sumerian_transliterations": [r"sa3", r"za"],
        "src": IMG_0de0477b_ASSET.readall(),
    },
    {
        "name": r"ZAtenu",
        "sumerian_transliterations": [r"ad4"],
        "src": IMG_919c3b3f_ASSET.readall(),
    },
    {
        "name": r"ZADIM",
        "sumerian_transliterations": [r"zadim"],
        "src": IMG_94754156_ASSET.readall(),
    },
    {
        "name": r"ZAG",
        "sumerian_transliterations": [r"za3", r"zag", r"zak"],
        "src": IMG_80c0607b_ASSET.readall(),
    },
    {
        "name": r"ZE2",
        "sumerian_transliterations": [r"ze2", r"zi2"],
        "src": IMG_e22dbfe2_ASSET.readall(),
    },
    {
        "name": r"ZI",
        "sumerian_transliterations": [r"se2", r"si2", r"ze", r"zi", r"zid", r"zig3", r"ṣi2"],
        "src": IMG_4e916360_ASSET.readall(),
    },
    {
        "name": r"ZI/ZI",
        "sumerian_transliterations": [r"part of compound"],
        "src": IMG_770f2f40_ASSET.readall(),
    },
    {
        "name": r"ZI3",
        "sumerian_transliterations": [r"zid2"],
        "src": IMG_77859917_ASSET.readall(),
    },
    {
        "name": r"ZIG",
        "sumerian_transliterations": [r"zib2", r"ḫaš2"],
        "src": IMG_b75d3a97_ASSET.readall(),
    },
    {
        "name": r"ZU",
        "sumerian_transliterations": [r"su2", r"zu"],
        "src": IMG_84f5669e_ASSET.readall(),
    },
    {
        "name": r"ZUM",
        "sumerian_transliterations": [r"rig2", r"sum2", r"zum", r"ḫaš4"],
        "src": IMG_ed62874d_ASSET.readall(),
    },
    {
        "name": r"TWO.AŠ",
        "sumerian_transliterations": [r"min5"],
        "src": IMG_b9bf2d66_ASSET.readall(),
    },
    {
        "name": r"ONE.BURU",
        "sumerian_transliterations": [r"BUR3gunu"],
        "src": IMG_a50fae24_ASSET.readall(),
    },
    {
        "name": r"THREE.DIŠ",
        "sumerian_transliterations": [r"eš5"],
        "src": IMG_57e6072f_ASSET.readall(),
    },
    {
        "name": r"FOUR.DIŠ",
        "sumerian_transliterations": [r"limmu5"],
        "src": IMG_1dde43e0_ASSET.readall(),
    },
    {
        "name": r"FOUR.DIŠ.VAR",
        "sumerian_transliterations": [r"limmu"],
        "src": IMG_48b22fa0_ASSET.readall(),
    },
    {
        "name": r"FIVE.DIŠ",
        "sumerian_transliterations": [r"ia2"],
        "src": IMG_99aeb864_ASSET.readall(),
    },
    {
        "name": r"EIGHT.DIŠ",
        "sumerian_transliterations": [r"ussu"],
        "src": IMG_1ef1f750_ASSET.readall(),
    },
    {
        "name": r"ONE.EŠE3",
        "sumerian_transliterations": [r"eše3"],
        "src": IMG_57540126_ASSET.readall(),
    },
    {
        "name": r"TWO.EŠE3",
        "sumerian_transliterations": [r"eše3/eše3"],
        "src": IMG_24903bdf_ASSET.readall(),
    },
    {
        "name": r"FIVE.U",
        "sumerian_transliterations": [r"ninnu"],
        "src": IMG_e1a780bb_ASSET.readall(),
    },
]
