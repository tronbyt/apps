"""
Applet: Hieroglyphs
Summary: Random Egyptian Hieroglyphs
Description: Displays Egyptian Hieroglyphs from Gardiner's Sign List plus details of pronunciation and use.
Author: dinosaursrarr
"""

load("encoding/base64.star", "base64")
load("hash.star", "hash")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("images/img_011f15dc.png", IMG_011f15dc_ASSET = "file")
load("images/img_0134f045.png", IMG_0134f045_ASSET = "file")
load("images/img_019c936a.png", IMG_019c936a_ASSET = "file")
load("images/img_0223330d.png", IMG_0223330d_ASSET = "file")
load("images/img_0242894d.png", IMG_0242894d_ASSET = "file")
load("images/img_03149054.png", IMG_03149054_ASSET = "file")
load("images/img_03483cda.png", IMG_03483cda_ASSET = "file")
load("images/img_034b174f.png", IMG_034b174f_ASSET = "file")
load("images/img_038805d0.png", IMG_038805d0_ASSET = "file")
load("images/img_0396571f.png", IMG_0396571f_ASSET = "file")
load("images/img_03c241e6.png", IMG_03c241e6_ASSET = "file")
load("images/img_0422274e.png", IMG_0422274e_ASSET = "file")
load("images/img_04434350.png", IMG_04434350_ASSET = "file")
load("images/img_0452f938.png", IMG_0452f938_ASSET = "file")
load("images/img_04c0e157.png", IMG_04c0e157_ASSET = "file")
load("images/img_0538b5c7.png", IMG_0538b5c7_ASSET = "file")
load("images/img_057d06d0.png", IMG_057d06d0_ASSET = "file")
load("images/img_05ff0b26.png", IMG_05ff0b26_ASSET = "file")
load("images/img_064ed1ae.png", IMG_064ed1ae_ASSET = "file")
load("images/img_06bb469f.png", IMG_06bb469f_ASSET = "file")
load("images/img_06bffb4a.png", IMG_06bffb4a_ASSET = "file")
load("images/img_0727f80e.png", IMG_0727f80e_ASSET = "file")
load("images/img_074a4edd.png", IMG_074a4edd_ASSET = "file")
load("images/img_074d26a8.png", IMG_074d26a8_ASSET = "file")
load("images/img_07b5eed3.png", IMG_07b5eed3_ASSET = "file")
load("images/img_07bdf90d.png", IMG_07bdf90d_ASSET = "file")
load("images/img_07cb5549.png", IMG_07cb5549_ASSET = "file")
load("images/img_07d01d90.png", IMG_07d01d90_ASSET = "file")
load("images/img_07ffbdf4.png", IMG_07ffbdf4_ASSET = "file")
load("images/img_083f5351.png", IMG_083f5351_ASSET = "file")
load("images/img_08c1c849.png", IMG_08c1c849_ASSET = "file")
load("images/img_08f9fab8.png", IMG_08f9fab8_ASSET = "file")
load("images/img_09013a1c.png", IMG_09013a1c_ASSET = "file")
load("images/img_0961c734.png", IMG_0961c734_ASSET = "file")
load("images/img_09cbe74b.png", IMG_09cbe74b_ASSET = "file")
load("images/img_0a0e7869.png", IMG_0a0e7869_ASSET = "file")
load("images/img_0a30600c.png", IMG_0a30600c_ASSET = "file")
load("images/img_0a48a832.png", IMG_0a48a832_ASSET = "file")
load("images/img_0a5e366b.png", IMG_0a5e366b_ASSET = "file")
load("images/img_0a908084.png", IMG_0a908084_ASSET = "file")
load("images/img_0ab8b389.png", IMG_0ab8b389_ASSET = "file")
load("images/img_0b8c2497.png", IMG_0b8c2497_ASSET = "file")
load("images/img_0b962aec.png", IMG_0b962aec_ASSET = "file")
load("images/img_0be16370.png", IMG_0be16370_ASSET = "file")
load("images/img_0becc3f2.png", IMG_0becc3f2_ASSET = "file")
load("images/img_0d742789.png", IMG_0d742789_ASSET = "file")
load("images/img_0d97cfe0.png", IMG_0d97cfe0_ASSET = "file")
load("images/img_0d982481.png", IMG_0d982481_ASSET = "file")
load("images/img_0e1df356.png", IMG_0e1df356_ASSET = "file")
load("images/img_0ef19470.png", IMG_0ef19470_ASSET = "file")
load("images/img_0f30f8e4.png", IMG_0f30f8e4_ASSET = "file")
load("images/img_0f36a809.png", IMG_0f36a809_ASSET = "file")
load("images/img_0f442725.png", IMG_0f442725_ASSET = "file")
load("images/img_0f7a00f7.png", IMG_0f7a00f7_ASSET = "file")
load("images/img_1056d782.png", IMG_1056d782_ASSET = "file")
load("images/img_109eea05.png", IMG_109eea05_ASSET = "file")
load("images/img_10d2a078.png", IMG_10d2a078_ASSET = "file")
load("images/img_110fba65.png", IMG_110fba65_ASSET = "file")
load("images/img_1163726e.png", IMG_1163726e_ASSET = "file")
load("images/img_11c138da.png", IMG_11c138da_ASSET = "file")
load("images/img_11df83fb.png", IMG_11df83fb_ASSET = "file")
load("images/img_12e89e37.png", IMG_12e89e37_ASSET = "file")
load("images/img_132c5f8c.png", IMG_132c5f8c_ASSET = "file")
load("images/img_13dc43f6.png", IMG_13dc43f6_ASSET = "file")
load("images/img_14094e2e.png", IMG_14094e2e_ASSET = "file")
load("images/img_140cc880.png", IMG_140cc880_ASSET = "file")
load("images/img_15cf424a.png", IMG_15cf424a_ASSET = "file")
load("images/img_15d67858.png", IMG_15d67858_ASSET = "file")
load("images/img_16d53a37.png", IMG_16d53a37_ASSET = "file")
load("images/img_171bd5b9.png", IMG_171bd5b9_ASSET = "file")
load("images/img_172d7960.png", IMG_172d7960_ASSET = "file")
load("images/img_174d040c.png", IMG_174d040c_ASSET = "file")
load("images/img_17c54231.png", IMG_17c54231_ASSET = "file")
load("images/img_180e1ca9.png", IMG_180e1ca9_ASSET = "file")
load("images/img_18f1b417.png", IMG_18f1b417_ASSET = "file")
load("images/img_1952c542.png", IMG_1952c542_ASSET = "file")
load("images/img_19a5c741.png", IMG_19a5c741_ASSET = "file")
load("images/img_19ba119e.png", IMG_19ba119e_ASSET = "file")
load("images/img_19d7560a.png", IMG_19d7560a_ASSET = "file")
load("images/img_19df7447.png", IMG_19df7447_ASSET = "file")
load("images/img_1a344bc3.png", IMG_1a344bc3_ASSET = "file")
load("images/img_1a35d267.png", IMG_1a35d267_ASSET = "file")
load("images/img_1a35df33.png", IMG_1a35df33_ASSET = "file")
load("images/img_1ad35e66.png", IMG_1ad35e66_ASSET = "file")
load("images/img_1afe81ec.png", IMG_1afe81ec_ASSET = "file")
load("images/img_1b3199cb.png", IMG_1b3199cb_ASSET = "file")
load("images/img_1c96365c.png", IMG_1c96365c_ASSET = "file")
load("images/img_1dab1231.png", IMG_1dab1231_ASSET = "file")
load("images/img_1e4192f4.png", IMG_1e4192f4_ASSET = "file")
load("images/img_1e557a50.png", IMG_1e557a50_ASSET = "file")
load("images/img_1e9f4a4d.png", IMG_1e9f4a4d_ASSET = "file")
load("images/img_1f229b02.png", IMG_1f229b02_ASSET = "file")
load("images/img_1f57ad12.png", IMG_1f57ad12_ASSET = "file")
load("images/img_1ff45156.png", IMG_1ff45156_ASSET = "file")
load("images/img_2128119d.png", IMG_2128119d_ASSET = "file")
load("images/img_215e98e7.png", IMG_215e98e7_ASSET = "file")
load("images/img_21c3ac07.png", IMG_21c3ac07_ASSET = "file")
load("images/img_227023d7.png", IMG_227023d7_ASSET = "file")
load("images/img_232f67c2.png", IMG_232f67c2_ASSET = "file")
load("images/img_23340edd.png", IMG_23340edd_ASSET = "file")
load("images/img_23fa531a.png", IMG_23fa531a_ASSET = "file")
load("images/img_246a30b5.png", IMG_246a30b5_ASSET = "file")
load("images/img_2478bc8f.png", IMG_2478bc8f_ASSET = "file")
load("images/img_24898055.png", IMG_24898055_ASSET = "file")
load("images/img_24b11911.png", IMG_24b11911_ASSET = "file")
load("images/img_24c7b233.png", IMG_24c7b233_ASSET = "file")
load("images/img_2515bb9d.png", IMG_2515bb9d_ASSET = "file")
load("images/img_251b322b.png", IMG_251b322b_ASSET = "file")
load("images/img_252cd65e.png", IMG_252cd65e_ASSET = "file")
load("images/img_25be8d83.png", IMG_25be8d83_ASSET = "file")
load("images/img_25df1d69.png", IMG_25df1d69_ASSET = "file")
load("images/img_26c8444d.png", IMG_26c8444d_ASSET = "file")
load("images/img_282a2392.png", IMG_282a2392_ASSET = "file")
load("images/img_28481765.png", IMG_28481765_ASSET = "file")
load("images/img_28d72df8.png", IMG_28d72df8_ASSET = "file")
load("images/img_2902de7a.png", IMG_2902de7a_ASSET = "file")
load("images/img_29396c5b.png", IMG_29396c5b_ASSET = "file")
load("images/img_297c2776.png", IMG_297c2776_ASSET = "file")
load("images/img_29aac353.png", IMG_29aac353_ASSET = "file")
load("images/img_29ba85a5.png", IMG_29ba85a5_ASSET = "file")
load("images/img_2a85852e.png", IMG_2a85852e_ASSET = "file")
load("images/img_2ab5b6c2.png", IMG_2ab5b6c2_ASSET = "file")
load("images/img_2b297f3b.png", IMG_2b297f3b_ASSET = "file")
load("images/img_2bc1838b.png", IMG_2bc1838b_ASSET = "file")
load("images/img_2c39d23c.png", IMG_2c39d23c_ASSET = "file")
load("images/img_2c5df5a1.png", IMG_2c5df5a1_ASSET = "file")
load("images/img_2d2d2f98.png", IMG_2d2d2f98_ASSET = "file")
load("images/img_2d7f80e1.png", IMG_2d7f80e1_ASSET = "file")
load("images/img_2d8fd1b1.png", IMG_2d8fd1b1_ASSET = "file")
load("images/img_2e3d13b3.png", IMG_2e3d13b3_ASSET = "file")
load("images/img_2e94c0e3.png", IMG_2e94c0e3_ASSET = "file")
load("images/img_2ef5ac7a.png", IMG_2ef5ac7a_ASSET = "file")
load("images/img_2f7b3390.png", IMG_2f7b3390_ASSET = "file")
load("images/img_3080dd88.png", IMG_3080dd88_ASSET = "file")
load("images/img_309b59ea.png", IMG_309b59ea_ASSET = "file")
load("images/img_310ca371.png", IMG_310ca371_ASSET = "file")
load("images/img_31a3af82.png", IMG_31a3af82_ASSET = "file")
load("images/img_31afc721.png", IMG_31afc721_ASSET = "file")
load("images/img_3249722a.png", IMG_3249722a_ASSET = "file")
load("images/img_32541540.png", IMG_32541540_ASSET = "file")
load("images/img_32861038.png", IMG_32861038_ASSET = "file")
load("images/img_33446bb9.png", IMG_33446bb9_ASSET = "file")
load("images/img_33ddb4d3.png", IMG_33ddb4d3_ASSET = "file")
load("images/img_340aafc2.png", IMG_340aafc2_ASSET = "file")
load("images/img_34cfda0f.png", IMG_34cfda0f_ASSET = "file")
load("images/img_34d6db98.png", IMG_34d6db98_ASSET = "file")
load("images/img_34da11dd.png", IMG_34da11dd_ASSET = "file")
load("images/img_350a40f8.png", IMG_350a40f8_ASSET = "file")
load("images/img_3519ae3e.png", IMG_3519ae3e_ASSET = "file")
load("images/img_3689b2b1.png", IMG_3689b2b1_ASSET = "file")
load("images/img_36a7d2e9.png", IMG_36a7d2e9_ASSET = "file")
load("images/img_36b788fd.png", IMG_36b788fd_ASSET = "file")
load("images/img_36d3c835.png", IMG_36d3c835_ASSET = "file")
load("images/img_370f2434.png", IMG_370f2434_ASSET = "file")
load("images/img_378c1e9e.png", IMG_378c1e9e_ASSET = "file")
load("images/img_379f3d23.png", IMG_379f3d23_ASSET = "file")
load("images/img_3816ccd0.png", IMG_3816ccd0_ASSET = "file")
load("images/img_388c2020.png", IMG_388c2020_ASSET = "file")
load("images/img_38f63128.png", IMG_38f63128_ASSET = "file")
load("images/img_39254ede.png", IMG_39254ede_ASSET = "file")
load("images/img_3ab57c8c.png", IMG_3ab57c8c_ASSET = "file")
load("images/img_3af39e89.png", IMG_3af39e89_ASSET = "file")
load("images/img_3b322496.png", IMG_3b322496_ASSET = "file")
load("images/img_3b357730.png", IMG_3b357730_ASSET = "file")
load("images/img_3b55acac.png", IMG_3b55acac_ASSET = "file")
load("images/img_3bc61315.png", IMG_3bc61315_ASSET = "file")
load("images/img_3be58edf.png", IMG_3be58edf_ASSET = "file")
load("images/img_3c17f2a9.png", IMG_3c17f2a9_ASSET = "file")
load("images/img_3f1a3fbb.png", IMG_3f1a3fbb_ASSET = "file")
load("images/img_40de1f4f.png", IMG_40de1f4f_ASSET = "file")
load("images/img_428f42c9.png", IMG_428f42c9_ASSET = "file")
load("images/img_42a08925.png", IMG_42a08925_ASSET = "file")
load("images/img_42f94e16.png", IMG_42f94e16_ASSET = "file")
load("images/img_430c93ee.png", IMG_430c93ee_ASSET = "file")
load("images/img_43125459.png", IMG_43125459_ASSET = "file")
load("images/img_432083ff.png", IMG_432083ff_ASSET = "file")
load("images/img_4395a225.png", IMG_4395a225_ASSET = "file")
load("images/img_43e7143e.png", IMG_43e7143e_ASSET = "file")
load("images/img_44681079.png", IMG_44681079_ASSET = "file")
load("images/img_44d9c85b.png", IMG_44d9c85b_ASSET = "file")
load("images/img_452bd08b.png", IMG_452bd08b_ASSET = "file")
load("images/img_458199f8.png", IMG_458199f8_ASSET = "file")
load("images/img_45a6b69f.png", IMG_45a6b69f_ASSET = "file")
load("images/img_45ad9a25.png", IMG_45ad9a25_ASSET = "file")
load("images/img_45aff79b.png", IMG_45aff79b_ASSET = "file")
load("images/img_45cf3ab3.png", IMG_45cf3ab3_ASSET = "file")
load("images/img_4643f695.png", IMG_4643f695_ASSET = "file")
load("images/img_46711faf.png", IMG_46711faf_ASSET = "file")
load("images/img_4684cb0c.png", IMG_4684cb0c_ASSET = "file")
load("images/img_46f2987e.png", IMG_46f2987e_ASSET = "file")
load("images/img_471b6c2b.png", IMG_471b6c2b_ASSET = "file")
load("images/img_47282ffb.png", IMG_47282ffb_ASSET = "file")
load("images/img_4774c84b.png", IMG_4774c84b_ASSET = "file")
load("images/img_47dd5f2c.png", IMG_47dd5f2c_ASSET = "file")
load("images/img_48061a86.png", IMG_48061a86_ASSET = "file")
load("images/img_480b959a.png", IMG_480b959a_ASSET = "file")
load("images/img_48a1a9cd.png", IMG_48a1a9cd_ASSET = "file")
load("images/img_48cdbcde.png", IMG_48cdbcde_ASSET = "file")
load("images/img_494e671e.png", IMG_494e671e_ASSET = "file")
load("images/img_498e0f8c.png", IMG_498e0f8c_ASSET = "file")
load("images/img_49de40ec.png", IMG_49de40ec_ASSET = "file")
load("images/img_49f7a694.png", IMG_49f7a694_ASSET = "file")
load("images/img_4a0b0880.png", IMG_4a0b0880_ASSET = "file")
load("images/img_4a355a5a.png", IMG_4a355a5a_ASSET = "file")
load("images/img_4a47f1f1.png", IMG_4a47f1f1_ASSET = "file")
load("images/img_4a8f022c.png", IMG_4a8f022c_ASSET = "file")
load("images/img_4aa4411f.png", IMG_4aa4411f_ASSET = "file")
load("images/img_4aa75eca.png", IMG_4aa75eca_ASSET = "file")
load("images/img_4aaff14f.png", IMG_4aaff14f_ASSET = "file")
load("images/img_4ab8e2e9.png", IMG_4ab8e2e9_ASSET = "file")
load("images/img_4b20e344.png", IMG_4b20e344_ASSET = "file")
load("images/img_4b250737.png", IMG_4b250737_ASSET = "file")
load("images/img_4b8925e9.png", IMG_4b8925e9_ASSET = "file")
load("images/img_4b963bf1.png", IMG_4b963bf1_ASSET = "file")
load("images/img_4ba07cac.png", IMG_4ba07cac_ASSET = "file")
load("images/img_4bf9b138.png", IMG_4bf9b138_ASSET = "file")
load("images/img_4c58f050.png", IMG_4c58f050_ASSET = "file")
load("images/img_4c89bccc.png", IMG_4c89bccc_ASSET = "file")
load("images/img_4cdc9896.png", IMG_4cdc9896_ASSET = "file")
load("images/img_4cddfb5b.png", IMG_4cddfb5b_ASSET = "file")
load("images/img_4d307700.png", IMG_4d307700_ASSET = "file")
load("images/img_4db4da7a.png", IMG_4db4da7a_ASSET = "file")
load("images/img_4e0f1694.png", IMG_4e0f1694_ASSET = "file")
load("images/img_4e157a03.png", IMG_4e157a03_ASSET = "file")
load("images/img_4e302060.png", IMG_4e302060_ASSET = "file")
load("images/img_4e820fa8.png", IMG_4e820fa8_ASSET = "file")
load("images/img_4ea6d4ed.png", IMG_4ea6d4ed_ASSET = "file")
load("images/img_4ec8fc3e.png", IMG_4ec8fc3e_ASSET = "file")
load("images/img_4ed18d4a.png", IMG_4ed18d4a_ASSET = "file")
load("images/img_4f069ea4.png", IMG_4f069ea4_ASSET = "file")
load("images/img_4f7a1d73.png", IMG_4f7a1d73_ASSET = "file")
load("images/img_4f94b158.png", IMG_4f94b158_ASSET = "file")
load("images/img_507dadd7.png", IMG_507dadd7_ASSET = "file")
load("images/img_507ec9aa.png", IMG_507ec9aa_ASSET = "file")
load("images/img_50a573a5.png", IMG_50a573a5_ASSET = "file")
load("images/img_5150d223.png", IMG_5150d223_ASSET = "file")
load("images/img_516fd65f.png", IMG_516fd65f_ASSET = "file")
load("images/img_51a68752.png", IMG_51a68752_ASSET = "file")
load("images/img_51c84636.png", IMG_51c84636_ASSET = "file")
load("images/img_52084135.png", IMG_52084135_ASSET = "file")
load("images/img_520bcdde.png", IMG_520bcdde_ASSET = "file")
load("images/img_5266b180.png", IMG_5266b180_ASSET = "file")
load("images/img_52679821.png", IMG_52679821_ASSET = "file")
load("images/img_52e3df03.png", IMG_52e3df03_ASSET = "file")
load("images/img_52e8ed02.png", IMG_52e8ed02_ASSET = "file")
load("images/img_52f27717.png", IMG_52f27717_ASSET = "file")
load("images/img_5366c94b.png", IMG_5366c94b_ASSET = "file")
load("images/img_54f41c28.png", IMG_54f41c28_ASSET = "file")
load("images/img_5506d1fe.png", IMG_5506d1fe_ASSET = "file")
load("images/img_550f3326.png", IMG_550f3326_ASSET = "file")
load("images/img_55622e70.png", IMG_55622e70_ASSET = "file")
load("images/img_55b1d35a.png", IMG_55b1d35a_ASSET = "file")
load("images/img_55ed187b.png", IMG_55ed187b_ASSET = "file")
load("images/img_56834d4a.png", IMG_56834d4a_ASSET = "file")
load("images/img_569cd199.png", IMG_569cd199_ASSET = "file")
load("images/img_56b70cc9.png", IMG_56b70cc9_ASSET = "file")
load("images/img_5781da1e.png", IMG_5781da1e_ASSET = "file")
load("images/img_579f989f.png", IMG_579f989f_ASSET = "file")
load("images/img_5841c0c5.png", IMG_5841c0c5_ASSET = "file")
load("images/img_58d36b2c.png", IMG_58d36b2c_ASSET = "file")
load("images/img_58dea276.png", IMG_58dea276_ASSET = "file")
load("images/img_591dded2.png", IMG_591dded2_ASSET = "file")
load("images/img_599a57cf.png", IMG_599a57cf_ASSET = "file")
load("images/img_599f6e96.png", IMG_599f6e96_ASSET = "file")
load("images/img_5a3a077a.png", IMG_5a3a077a_ASSET = "file")
load("images/img_5a664392.png", IMG_5a664392_ASSET = "file")
load("images/img_5b0ce33a.png", IMG_5b0ce33a_ASSET = "file")
load("images/img_5b140f45.png", IMG_5b140f45_ASSET = "file")
load("images/img_5bd81fff.png", IMG_5bd81fff_ASSET = "file")
load("images/img_5bdff873.png", IMG_5bdff873_ASSET = "file")
load("images/img_5c51e7fd.png", IMG_5c51e7fd_ASSET = "file")
load("images/img_5c6a451e.png", IMG_5c6a451e_ASSET = "file")
load("images/img_5cc234b0.png", IMG_5cc234b0_ASSET = "file")
load("images/img_5e2ce9d2.png", IMG_5e2ce9d2_ASSET = "file")
load("images/img_5e8b0847.png", IMG_5e8b0847_ASSET = "file")
load("images/img_5fca5056.png", IMG_5fca5056_ASSET = "file")
load("images/img_5fe113c6.png", IMG_5fe113c6_ASSET = "file")
load("images/img_5ffabaca.png", IMG_5ffabaca_ASSET = "file")
load("images/img_6035af7a.png", IMG_6035af7a_ASSET = "file")
load("images/img_604b3dd9.png", IMG_604b3dd9_ASSET = "file")
load("images/img_6058c50b.png", IMG_6058c50b_ASSET = "file")
load("images/img_6069b53e.png", IMG_6069b53e_ASSET = "file")
load("images/img_60911c99.png", IMG_60911c99_ASSET = "file")
load("images/img_611bdd26.png", IMG_611bdd26_ASSET = "file")
load("images/img_617e3376.png", IMG_617e3376_ASSET = "file")
load("images/img_61eab265.png", IMG_61eab265_ASSET = "file")
load("images/img_61ff189b.png", IMG_61ff189b_ASSET = "file")
load("images/img_61fff579.png", IMG_61fff579_ASSET = "file")
load("images/img_62fd6143.png", IMG_62fd6143_ASSET = "file")
load("images/img_63346f63.png", IMG_63346f63_ASSET = "file")
load("images/img_63438e6c.png", IMG_63438e6c_ASSET = "file")
load("images/img_63714c7c.png", IMG_63714c7c_ASSET = "file")
load("images/img_64131565.png", IMG_64131565_ASSET = "file")
load("images/img_64406e60.png", IMG_64406e60_ASSET = "file")
load("images/img_6526a9b4.png", IMG_6526a9b4_ASSET = "file")
load("images/img_65f98131.png", IMG_65f98131_ASSET = "file")
load("images/img_665ac7a5.png", IMG_665ac7a5_ASSET = "file")
load("images/img_66e50cfc.png", IMG_66e50cfc_ASSET = "file")
load("images/img_66f0b5d7.png", IMG_66f0b5d7_ASSET = "file")
load("images/img_66f4eb94.png", IMG_66f4eb94_ASSET = "file")
load("images/img_66fc2935.png", IMG_66fc2935_ASSET = "file")
load("images/img_6720c7ca.png", IMG_6720c7ca_ASSET = "file")
load("images/img_675dce10.png", IMG_675dce10_ASSET = "file")
load("images/img_67e0a673.png", IMG_67e0a673_ASSET = "file")
load("images/img_67edffe0.png", IMG_67edffe0_ASSET = "file")
load("images/img_68020e2a.png", IMG_68020e2a_ASSET = "file")
load("images/img_687861d1.png", IMG_687861d1_ASSET = "file")
load("images/img_687c4c3a.png", IMG_687c4c3a_ASSET = "file")
load("images/img_689dae67.png", IMG_689dae67_ASSET = "file")
load("images/img_68a98eea.png", IMG_68a98eea_ASSET = "file")
load("images/img_692080a9.png", IMG_692080a9_ASSET = "file")
load("images/img_6920e471.png", IMG_6920e471_ASSET = "file")
load("images/img_69996ec4.png", IMG_69996ec4_ASSET = "file")
load("images/img_69f9f2c0.png", IMG_69f9f2c0_ASSET = "file")
load("images/img_6a26c76e.png", IMG_6a26c76e_ASSET = "file")
load("images/img_6a30b5e7.png", IMG_6a30b5e7_ASSET = "file")
load("images/img_6a3df4c6.png", IMG_6a3df4c6_ASSET = "file")
load("images/img_6abb445b.png", IMG_6abb445b_ASSET = "file")
load("images/img_6ad91cc8.png", IMG_6ad91cc8_ASSET = "file")
load("images/img_6b2a7f4f.png", IMG_6b2a7f4f_ASSET = "file")
load("images/img_6b2b50f1.png", IMG_6b2b50f1_ASSET = "file")
load("images/img_6b4c6145.png", IMG_6b4c6145_ASSET = "file")
load("images/img_6b9a6992.png", IMG_6b9a6992_ASSET = "file")
load("images/img_6c24ca9f.png", IMG_6c24ca9f_ASSET = "file")
load("images/img_6c7fb50c.png", IMG_6c7fb50c_ASSET = "file")
load("images/img_6ce98993.png", IMG_6ce98993_ASSET = "file")
load("images/img_6d36027e.png", IMG_6d36027e_ASSET = "file")
load("images/img_6eec4ee8.png", IMG_6eec4ee8_ASSET = "file")
load("images/img_6f21b6b9.png", IMG_6f21b6b9_ASSET = "file")
load("images/img_6fb6ab7e.png", IMG_6fb6ab7e_ASSET = "file")
load("images/img_6fd38523.png", IMG_6fd38523_ASSET = "file")
load("images/img_7028c206.png", IMG_7028c206_ASSET = "file")
load("images/img_703100e1.png", IMG_703100e1_ASSET = "file")
load("images/img_703768a3.png", IMG_703768a3_ASSET = "file")
load("images/img_70a5bedb.png", IMG_70a5bedb_ASSET = "file")
load("images/img_70aad8a0.png", IMG_70aad8a0_ASSET = "file")
load("images/img_70b5f256.png", IMG_70b5f256_ASSET = "file")
load("images/img_70fa944c.png", IMG_70fa944c_ASSET = "file")
load("images/img_710f120f.png", IMG_710f120f_ASSET = "file")
load("images/img_71378d17.png", IMG_71378d17_ASSET = "file")
load("images/img_715e3b67.png", IMG_715e3b67_ASSET = "file")
load("images/img_722c2eb8.png", IMG_722c2eb8_ASSET = "file")
load("images/img_727760ce.png", IMG_727760ce_ASSET = "file")
load("images/img_72d62d91.png", IMG_72d62d91_ASSET = "file")
load("images/img_73456c10.png", IMG_73456c10_ASSET = "file")
load("images/img_73f8d956.png", IMG_73f8d956_ASSET = "file")
load("images/img_74caf14a.png", IMG_74caf14a_ASSET = "file")
load("images/img_74e076dd.png", IMG_74e076dd_ASSET = "file")
load("images/img_74f7baff.png", IMG_74f7baff_ASSET = "file")
load("images/img_7531b15d.png", IMG_7531b15d_ASSET = "file")
load("images/img_75355232.png", IMG_75355232_ASSET = "file")
load("images/img_75ab6d52.png", IMG_75ab6d52_ASSET = "file")
load("images/img_760bad1e.png", IMG_760bad1e_ASSET = "file")
load("images/img_761d0c3d.png", IMG_761d0c3d_ASSET = "file")
load("images/img_762de6e4.png", IMG_762de6e4_ASSET = "file")
load("images/img_76f2c910.png", IMG_76f2c910_ASSET = "file")
load("images/img_77884021.png", IMG_77884021_ASSET = "file")
load("images/img_7808f1a7.png", IMG_7808f1a7_ASSET = "file")
load("images/img_78dfda53.png", IMG_78dfda53_ASSET = "file")
load("images/img_79253bd6.png", IMG_79253bd6_ASSET = "file")
load("images/img_793254cc.png", IMG_793254cc_ASSET = "file")
load("images/img_79b34ed9.png", IMG_79b34ed9_ASSET = "file")
load("images/img_7a1f303f.png", IMG_7a1f303f_ASSET = "file")
load("images/img_7ad65f89.png", IMG_7ad65f89_ASSET = "file")
load("images/img_7b12ddea.png", IMG_7b12ddea_ASSET = "file")
load("images/img_7b7c536a.png", IMG_7b7c536a_ASSET = "file")
load("images/img_7b96e86f.png", IMG_7b96e86f_ASSET = "file")
load("images/img_7c2dd155.png", IMG_7c2dd155_ASSET = "file")
load("images/img_7c556398.png", IMG_7c556398_ASSET = "file")
load("images/img_7d06db15.png", IMG_7d06db15_ASSET = "file")
load("images/img_7d085f78.png", IMG_7d085f78_ASSET = "file")
load("images/img_7d209502.png", IMG_7d209502_ASSET = "file")
load("images/img_7dcd4688.png", IMG_7dcd4688_ASSET = "file")
load("images/img_7e60be43.png", IMG_7e60be43_ASSET = "file")
load("images/img_7efa1414.png", IMG_7efa1414_ASSET = "file")
load("images/img_7f68c86c.png", IMG_7f68c86c_ASSET = "file")
load("images/img_803fc2bb.png", IMG_803fc2bb_ASSET = "file")
load("images/img_80aa7ecb.png", IMG_80aa7ecb_ASSET = "file")
load("images/img_812883fb.png", IMG_812883fb_ASSET = "file")
load("images/img_81765d2e.png", IMG_81765d2e_ASSET = "file")
load("images/img_817f79e0.png", IMG_817f79e0_ASSET = "file")
load("images/img_823cfd69.png", IMG_823cfd69_ASSET = "file")
load("images/img_823ff7c5.png", IMG_823ff7c5_ASSET = "file")
load("images/img_8256649d.png", IMG_8256649d_ASSET = "file")
load("images/img_82599031.png", IMG_82599031_ASSET = "file")
load("images/img_827688aa.png", IMG_827688aa_ASSET = "file")
load("images/img_82a21c1e.png", IMG_82a21c1e_ASSET = "file")
load("images/img_8372bbe9.png", IMG_8372bbe9_ASSET = "file")
load("images/img_8394f2b3.png", IMG_8394f2b3_ASSET = "file")
load("images/img_83f54f9e.png", IMG_83f54f9e_ASSET = "file")
load("images/img_8434790d.png", IMG_8434790d_ASSET = "file")
load("images/img_846328d6.png", IMG_846328d6_ASSET = "file")
load("images/img_84dc606f.png", IMG_84dc606f_ASSET = "file")
load("images/img_8570da19.png", IMG_8570da19_ASSET = "file")
load("images/img_85ecd114.png", IMG_85ecd114_ASSET = "file")
load("images/img_8681794f.png", IMG_8681794f_ASSET = "file")
load("images/img_869d2359.png", IMG_869d2359_ASSET = "file")
load("images/img_86be7891.png", IMG_86be7891_ASSET = "file")
load("images/img_86d17050.png", IMG_86d17050_ASSET = "file")
load("images/img_882a8107.png", IMG_882a8107_ASSET = "file")
load("images/img_8886d1e4.png", IMG_8886d1e4_ASSET = "file")
load("images/img_889cac3d.png", IMG_889cac3d_ASSET = "file")
load("images/img_890eff42.png", IMG_890eff42_ASSET = "file")
load("images/img_891bf9eb.png", IMG_891bf9eb_ASSET = "file")
load("images/img_895d96f7.png", IMG_895d96f7_ASSET = "file")
load("images/img_89a50395.png", IMG_89a50395_ASSET = "file")
load("images/img_89d2690b.png", IMG_89d2690b_ASSET = "file")
load("images/img_8a54c849.png", IMG_8a54c849_ASSET = "file")
load("images/img_8ab13b3f.png", IMG_8ab13b3f_ASSET = "file")
load("images/img_8ae09cef.png", IMG_8ae09cef_ASSET = "file")
load("images/img_8b21b696.png", IMG_8b21b696_ASSET = "file")
load("images/img_8b2af50a.png", IMG_8b2af50a_ASSET = "file")
load("images/img_8b3a201c.png", IMG_8b3a201c_ASSET = "file")
load("images/img_8b91532e.png", IMG_8b91532e_ASSET = "file")
load("images/img_8c101f49.png", IMG_8c101f49_ASSET = "file")
load("images/img_8c66c200.png", IMG_8c66c200_ASSET = "file")
load("images/img_8d0eb6e0.png", IMG_8d0eb6e0_ASSET = "file")
load("images/img_8d175f42.png", IMG_8d175f42_ASSET = "file")
load("images/img_8e07ec97.png", IMG_8e07ec97_ASSET = "file")
load("images/img_8ee2558a.png", IMG_8ee2558a_ASSET = "file")
load("images/img_8f562a2b.png", IMG_8f562a2b_ASSET = "file")
load("images/img_8f647f9a.png", IMG_8f647f9a_ASSET = "file")
load("images/img_9033a8f0.png", IMG_9033a8f0_ASSET = "file")
load("images/img_91147810.png", IMG_91147810_ASSET = "file")
load("images/img_91912432.png", IMG_91912432_ASSET = "file")
load("images/img_91de130d.png", IMG_91de130d_ASSET = "file")
load("images/img_92967819.png", IMG_92967819_ASSET = "file")
load("images/img_93722909.png", IMG_93722909_ASSET = "file")
load("images/img_93729b9c.png", IMG_93729b9c_ASSET = "file")
load("images/img_938cf6a6.png", IMG_938cf6a6_ASSET = "file")
load("images/img_93b36254.png", IMG_93b36254_ASSET = "file")
load("images/img_95e740a7.png", IMG_95e740a7_ASSET = "file")
load("images/img_95f89119.png", IMG_95f89119_ASSET = "file")
load("images/img_961631f2.png", IMG_961631f2_ASSET = "file")
load("images/img_962b308c.png", IMG_962b308c_ASSET = "file")
load("images/img_966ee5ef.png", IMG_966ee5ef_ASSET = "file")
load("images/img_97427986.png", IMG_97427986_ASSET = "file")
load("images/img_974c47fd.png", IMG_974c47fd_ASSET = "file")
load("images/img_9774162e.png", IMG_9774162e_ASSET = "file")
load("images/img_97d4feb8.png", IMG_97d4feb8_ASSET = "file")
load("images/img_97e32c30.png", IMG_97e32c30_ASSET = "file")
load("images/img_9858f545.png", IMG_9858f545_ASSET = "file")
load("images/img_9862881a.png", IMG_9862881a_ASSET = "file")
load("images/img_9881cc52.png", IMG_9881cc52_ASSET = "file")
load("images/img_98dbadd8.png", IMG_98dbadd8_ASSET = "file")
load("images/img_99218c04.png", IMG_99218c04_ASSET = "file")
load("images/img_996147db.png", IMG_996147db_ASSET = "file")
load("images/img_9990eebc.png", IMG_9990eebc_ASSET = "file")
load("images/img_9a058359.png", IMG_9a058359_ASSET = "file")
load("images/img_9a5defbe.png", IMG_9a5defbe_ASSET = "file")
load("images/img_9ad004d3.png", IMG_9ad004d3_ASSET = "file")
load("images/img_9b5d0657.png", IMG_9b5d0657_ASSET = "file")
load("images/img_9be91478.png", IMG_9be91478_ASSET = "file")
load("images/img_9c800b41.png", IMG_9c800b41_ASSET = "file")
load("images/img_9cb34b95.png", IMG_9cb34b95_ASSET = "file")
load("images/img_9cbabf42.png", IMG_9cbabf42_ASSET = "file")
load("images/img_9ccc8fe3.png", IMG_9ccc8fe3_ASSET = "file")
load("images/img_9cf3fbc8.png", IMG_9cf3fbc8_ASSET = "file")
load("images/img_9d0a6144.png", IMG_9d0a6144_ASSET = "file")
load("images/img_9d0cb6e6.png", IMG_9d0cb6e6_ASSET = "file")
load("images/img_9d957189.png", IMG_9d957189_ASSET = "file")
load("images/img_9dfb4b7a.png", IMG_9dfb4b7a_ASSET = "file")
load("images/img_9ef2a01f.png", IMG_9ef2a01f_ASSET = "file")
load("images/img_9f123a17.png", IMG_9f123a17_ASSET = "file")
load("images/img_9f50f7cb.png", IMG_9f50f7cb_ASSET = "file")
load("images/img_9fa69b18.png", IMG_9fa69b18_ASSET = "file")
load("images/img_a0048e11.png", IMG_a0048e11_ASSET = "file")
load("images/img_a0633063.png", IMG_a0633063_ASSET = "file")
load("images/img_a16c663b.png", IMG_a16c663b_ASSET = "file")
load("images/img_a1d890c1.png", IMG_a1d890c1_ASSET = "file")
load("images/img_a1ea5bbd.png", IMG_a1ea5bbd_ASSET = "file")
load("images/img_a287cc73.png", IMG_a287cc73_ASSET = "file")
load("images/img_a2bcc986.png", IMG_a2bcc986_ASSET = "file")
load("images/img_a2f88b9a.png", IMG_a2f88b9a_ASSET = "file")
load("images/img_a3524f51.png", IMG_a3524f51_ASSET = "file")
load("images/img_a3f9ab2c.png", IMG_a3f9ab2c_ASSET = "file")
load("images/img_a41e8fe2.png", IMG_a41e8fe2_ASSET = "file")
load("images/img_a4a3de76.png", IMG_a4a3de76_ASSET = "file")
load("images/img_a4d433df.png", IMG_a4d433df_ASSET = "file")
load("images/img_a4da2361.png", IMG_a4da2361_ASSET = "file")
load("images/img_a50e9dee.png", IMG_a50e9dee_ASSET = "file")
load("images/img_a53abc58.png", IMG_a53abc58_ASSET = "file")
load("images/img_a5e69189.png", IMG_a5e69189_ASSET = "file")
load("images/img_a5ef8a55.png", IMG_a5ef8a55_ASSET = "file")
load("images/img_a67491cd.png", IMG_a67491cd_ASSET = "file")
load("images/img_a67b9607.png", IMG_a67b9607_ASSET = "file")
load("images/img_a69b645e.png", IMG_a69b645e_ASSET = "file")
load("images/img_a706f3d9.png", IMG_a706f3d9_ASSET = "file")
load("images/img_a7310142.png", IMG_a7310142_ASSET = "file")
load("images/img_a769fe21.png", IMG_a769fe21_ASSET = "file")
load("images/img_a81418e9.png", IMG_a81418e9_ASSET = "file")
load("images/img_a81ccff0.png", IMG_a81ccff0_ASSET = "file")
load("images/img_a81d466c.png", IMG_a81d466c_ASSET = "file")
load("images/img_a84e0dea.png", IMG_a84e0dea_ASSET = "file")
load("images/img_a9645e45.png", IMG_a9645e45_ASSET = "file")
load("images/img_a96b151f.png", IMG_a96b151f_ASSET = "file")
load("images/img_a96d4d58.png", IMG_a96d4d58_ASSET = "file")
load("images/img_a97c3f20.png", IMG_a97c3f20_ASSET = "file")
load("images/img_a9cb49e3.png", IMG_a9cb49e3_ASSET = "file")
load("images/img_a9ec4905.png", IMG_a9ec4905_ASSET = "file")
load("images/img_a9f519e8.png", IMG_a9f519e8_ASSET = "file")
load("images/img_aa3e577c.png", IMG_aa3e577c_ASSET = "file")
load("images/img_aa895591.png", IMG_aa895591_ASSET = "file")
load("images/img_aaf58365.png", IMG_aaf58365_ASSET = "file")
load("images/img_ab3e0b95.png", IMG_ab3e0b95_ASSET = "file")
load("images/img_ab9206da.png", IMG_ab9206da_ASSET = "file")
load("images/img_abc7d3ad.png", IMG_abc7d3ad_ASSET = "file")
load("images/img_abd29292.png", IMG_abd29292_ASSET = "file")
load("images/img_acb4ed21.png", IMG_acb4ed21_ASSET = "file")
load("images/img_adb6d241.png", IMG_adb6d241_ASSET = "file")
load("images/img_ae1176dc.png", IMG_ae1176dc_ASSET = "file")
load("images/img_ae72a9a1.png", IMG_ae72a9a1_ASSET = "file")
load("images/img_aeada940.png", IMG_aeada940_ASSET = "file")
load("images/img_aecff2d5.png", IMG_aecff2d5_ASSET = "file")
load("images/img_aee23005.png", IMG_aee23005_ASSET = "file")
load("images/img_aefa6fb0.png", IMG_aefa6fb0_ASSET = "file")
load("images/img_af5b008f.png", IMG_af5b008f_ASSET = "file")
load("images/img_afa2060c.png", IMG_afa2060c_ASSET = "file")
load("images/img_afa595a0.png", IMG_afa595a0_ASSET = "file")
load("images/img_b0007393.png", IMG_b0007393_ASSET = "file")
load("images/img_b0356bdf.png", IMG_b0356bdf_ASSET = "file")
load("images/img_b073d97f.png", IMG_b073d97f_ASSET = "file")
load("images/img_b0dabd3f.png", IMG_b0dabd3f_ASSET = "file")
load("images/img_b15394b8.png", IMG_b15394b8_ASSET = "file")
load("images/img_b15ca726.png", IMG_b15ca726_ASSET = "file")
load("images/img_b1f96d00.png", IMG_b1f96d00_ASSET = "file")
load("images/img_b2997d46.png", IMG_b2997d46_ASSET = "file")
load("images/img_b2cfb097.png", IMG_b2cfb097_ASSET = "file")
load("images/img_b34a3964.png", IMG_b34a3964_ASSET = "file")
load("images/img_b39d1af5.png", IMG_b39d1af5_ASSET = "file")
load("images/img_b44c7ab1.png", IMG_b44c7ab1_ASSET = "file")
load("images/img_b45d7da2.png", IMG_b45d7da2_ASSET = "file")
load("images/img_b4852408.png", IMG_b4852408_ASSET = "file")
load("images/img_b4d48c11.png", IMG_b4d48c11_ASSET = "file")
load("images/img_b4f809bd.png", IMG_b4f809bd_ASSET = "file")
load("images/img_b55565d9.png", IMG_b55565d9_ASSET = "file")
load("images/img_b5afa141.png", IMG_b5afa141_ASSET = "file")
load("images/img_b5cd8a7e.png", IMG_b5cd8a7e_ASSET = "file")
load("images/img_b66c2764.png", IMG_b66c2764_ASSET = "file")
load("images/img_b6da2c76.png", IMG_b6da2c76_ASSET = "file")
load("images/img_b7a4784c.png", IMG_b7a4784c_ASSET = "file")
load("images/img_b7c84210.png", IMG_b7c84210_ASSET = "file")
load("images/img_b7e7afb9.png", IMG_b7e7afb9_ASSET = "file")
load("images/img_b87993b0.png", IMG_b87993b0_ASSET = "file")
load("images/img_b88dfca0.png", IMG_b88dfca0_ASSET = "file")
load("images/img_b9206066.png", IMG_b9206066_ASSET = "file")
load("images/img_b95cb370.png", IMG_b95cb370_ASSET = "file")
load("images/img_b9608d96.png", IMG_b9608d96_ASSET = "file")
load("images/img_b9c7e385.png", IMG_b9c7e385_ASSET = "file")
load("images/img_b9f103ff.png", IMG_b9f103ff_ASSET = "file")
load("images/img_ba47cd2d.png", IMG_ba47cd2d_ASSET = "file")
load("images/img_ba8eea94.png", IMG_ba8eea94_ASSET = "file")
load("images/img_ba97a6f5.png", IMG_ba97a6f5_ASSET = "file")
load("images/img_bab6af08.png", IMG_bab6af08_ASSET = "file")
load("images/img_bad08ff1.png", IMG_bad08ff1_ASSET = "file")
load("images/img_badc7377.png", IMG_badc7377_ASSET = "file")
load("images/img_baebf6f6.png", IMG_baebf6f6_ASSET = "file")
load("images/img_bb9f9b2d.png", IMG_bb9f9b2d_ASSET = "file")
load("images/img_bc730909.png", IMG_bc730909_ASSET = "file")
load("images/img_bcf6fc27.png", IMG_bcf6fc27_ASSET = "file")
load("images/img_bd13383b.png", IMG_bd13383b_ASSET = "file")
load("images/img_be10853e.png", IMG_be10853e_ASSET = "file")
load("images/img_be1c6ba9.png", IMG_be1c6ba9_ASSET = "file")
load("images/img_be9c1f7f.png", IMG_be9c1f7f_ASSET = "file")
load("images/img_bee51347.png", IMG_bee51347_ASSET = "file")
load("images/img_bef7758f.png", IMG_bef7758f_ASSET = "file")
load("images/img_bf19dd78.png", IMG_bf19dd78_ASSET = "file")
load("images/img_bf21e3d5.png", IMG_bf21e3d5_ASSET = "file")
load("images/img_bf47aac7.png", IMG_bf47aac7_ASSET = "file")
load("images/img_bfaf920e.png", IMG_bfaf920e_ASSET = "file")
load("images/img_c001eec0.png", IMG_c001eec0_ASSET = "file")
load("images/img_c00cdd06.png", IMG_c00cdd06_ASSET = "file")
load("images/img_c045c193.png", IMG_c045c193_ASSET = "file")
load("images/img_c04c2db7.png", IMG_c04c2db7_ASSET = "file")
load("images/img_c09ee311.png", IMG_c09ee311_ASSET = "file")
load("images/img_c0add213.png", IMG_c0add213_ASSET = "file")
load("images/img_c107c209.png", IMG_c107c209_ASSET = "file")
load("images/img_c160d134.png", IMG_c160d134_ASSET = "file")
load("images/img_c19b0a90.png", IMG_c19b0a90_ASSET = "file")
load("images/img_c19fbfdd.png", IMG_c19fbfdd_ASSET = "file")
load("images/img_c1ccf719.png", IMG_c1ccf719_ASSET = "file")
load("images/img_c20e5c1b.png", IMG_c20e5c1b_ASSET = "file")
load("images/img_c20fc55f.png", IMG_c20fc55f_ASSET = "file")
load("images/img_c30b1055.png", IMG_c30b1055_ASSET = "file")
load("images/img_c36816d3.png", IMG_c36816d3_ASSET = "file")
load("images/img_c3c13e2b.png", IMG_c3c13e2b_ASSET = "file")
load("images/img_c3e477eb.png", IMG_c3e477eb_ASSET = "file")
load("images/img_c4b127ff.png", IMG_c4b127ff_ASSET = "file")
load("images/img_c570bed4.png", IMG_c570bed4_ASSET = "file")
load("images/img_c625bdbd.png", IMG_c625bdbd_ASSET = "file")
load("images/img_c732b82d.png", IMG_c732b82d_ASSET = "file")
load("images/img_c7539a0b.png", IMG_c7539a0b_ASSET = "file")
load("images/img_c786ad76.png", IMG_c786ad76_ASSET = "file")
load("images/img_c7b19548.png", IMG_c7b19548_ASSET = "file")
load("images/img_c7ee90b1.png", IMG_c7ee90b1_ASSET = "file")
load("images/img_c80d53eb.png", IMG_c80d53eb_ASSET = "file")
load("images/img_c83495d7.png", IMG_c83495d7_ASSET = "file")
load("images/img_c89bb336.png", IMG_c89bb336_ASSET = "file")
load("images/img_c89bcfc8.png", IMG_c89bcfc8_ASSET = "file")
load("images/img_c8f1bed5.png", IMG_c8f1bed5_ASSET = "file")
load("images/img_c97e37a6.png", IMG_c97e37a6_ASSET = "file")
load("images/img_c9ba4ae3.png", IMG_c9ba4ae3_ASSET = "file")
load("images/img_c9cc8c39.png", IMG_c9cc8c39_ASSET = "file")
load("images/img_ca11937f.png", IMG_ca11937f_ASSET = "file")
load("images/img_ca2d9496.png", IMG_ca2d9496_ASSET = "file")
load("images/img_ca526a67.png", IMG_ca526a67_ASSET = "file")
load("images/img_ca9aa90e.png", IMG_ca9aa90e_ASSET = "file")
load("images/img_cb479ad9.png", IMG_cb479ad9_ASSET = "file")
load("images/img_cb481684.png", IMG_cb481684_ASSET = "file")
load("images/img_cb8f48b1.png", IMG_cb8f48b1_ASSET = "file")
load("images/img_ccd3f8ed.png", IMG_ccd3f8ed_ASSET = "file")
load("images/img_ccdc47ff.png", IMG_ccdc47ff_ASSET = "file")
load("images/img_cd26963c.png", IMG_cd26963c_ASSET = "file")
load("images/img_cd7d449b.png", IMG_cd7d449b_ASSET = "file")
load("images/img_cdd2f8cc.png", IMG_cdd2f8cc_ASSET = "file")
load("images/img_ce20ae85.png", IMG_ce20ae85_ASSET = "file")
load("images/img_ce827360.png", IMG_ce827360_ASSET = "file")
load("images/img_cebec140.png", IMG_cebec140_ASSET = "file")
load("images/img_ceff0bc5.png", IMG_ceff0bc5_ASSET = "file")
load("images/img_cf357682.png", IMG_cf357682_ASSET = "file")
load("images/img_cf608b11.png", IMG_cf608b11_ASSET = "file")
load("images/img_cf975423.png", IMG_cf975423_ASSET = "file")
load("images/img_d0218ed3.png", IMG_d0218ed3_ASSET = "file")
load("images/img_d05e2f69.png", IMG_d05e2f69_ASSET = "file")
load("images/img_d0b9619a.png", IMG_d0b9619a_ASSET = "file")
load("images/img_d0e0e290.png", IMG_d0e0e290_ASSET = "file")
load("images/img_d20691d6.png", IMG_d20691d6_ASSET = "file")
load("images/img_d23e7478.png", IMG_d23e7478_ASSET = "file")
load("images/img_d23ea096.png", IMG_d23ea096_ASSET = "file")
load("images/img_d251d4ec.png", IMG_d251d4ec_ASSET = "file")
load("images/img_d2b4d450.png", IMG_d2b4d450_ASSET = "file")
load("images/img_d2b5af47.png", IMG_d2b5af47_ASSET = "file")
load("images/img_d2ec2161.png", IMG_d2ec2161_ASSET = "file")
load("images/img_d2f7410e.png", IMG_d2f7410e_ASSET = "file")
load("images/img_d4676a68.png", IMG_d4676a68_ASSET = "file")
load("images/img_d4f35356.png", IMG_d4f35356_ASSET = "file")
load("images/img_d524b173.png", IMG_d524b173_ASSET = "file")
load("images/img_d65b5c68.png", IMG_d65b5c68_ASSET = "file")
load("images/img_d6934f36.png", IMG_d6934f36_ASSET = "file")
load("images/img_d6ad6f13.png", IMG_d6ad6f13_ASSET = "file")
load("images/img_d708d3ef.png", IMG_d708d3ef_ASSET = "file")
load("images/img_d72f27ba.png", IMG_d72f27ba_ASSET = "file")
load("images/img_d780ad72.png", IMG_d780ad72_ASSET = "file")
load("images/img_d79dc3da.png", IMG_d79dc3da_ASSET = "file")
load("images/img_d7b750bf.png", IMG_d7b750bf_ASSET = "file")
load("images/img_d7e49fbf.png", IMG_d7e49fbf_ASSET = "file")
load("images/img_d7f039a9.png", IMG_d7f039a9_ASSET = "file")
load("images/img_d80c534c.png", IMG_d80c534c_ASSET = "file")
load("images/img_d8188c6a.png", IMG_d8188c6a_ASSET = "file")
load("images/img_d8386be2.png", IMG_d8386be2_ASSET = "file")
load("images/img_d8694a44.png", IMG_d8694a44_ASSET = "file")
load("images/img_d8e80f25.png", IMG_d8e80f25_ASSET = "file")
load("images/img_d8ec7fbc.png", IMG_d8ec7fbc_ASSET = "file")
load("images/img_d9091970.png", IMG_d9091970_ASSET = "file")
load("images/img_d90f64b8.png", IMG_d90f64b8_ASSET = "file")
load("images/img_d915c1cd.png", IMG_d915c1cd_ASSET = "file")
load("images/img_d9522c21.png", IMG_d9522c21_ASSET = "file")
load("images/img_d9990236.png", IMG_d9990236_ASSET = "file")
load("images/img_d9ebda65.png", IMG_d9ebda65_ASSET = "file")
load("images/img_da284ecd.png", IMG_da284ecd_ASSET = "file")
load("images/img_dac7a178.png", IMG_dac7a178_ASSET = "file")
load("images/img_db5ce17e.png", IMG_db5ce17e_ASSET = "file")
load("images/img_dc398827.png", IMG_dc398827_ASSET = "file")
load("images/img_dcffd3c8.png", IMG_dcffd3c8_ASSET = "file")
load("images/img_dd08c850.png", IMG_dd08c850_ASSET = "file")
load("images/img_ddadf4c3.png", IMG_ddadf4c3_ASSET = "file")
load("images/img_de280549.png", IMG_de280549_ASSET = "file")
load("images/img_dfdb77d3.png", IMG_dfdb77d3_ASSET = "file")
load("images/img_e09d8705.png", IMG_e09d8705_ASSET = "file")
load("images/img_e1119e21.png", IMG_e1119e21_ASSET = "file")
load("images/img_e1b90338.png", IMG_e1b90338_ASSET = "file")
load("images/img_e38ca376.png", IMG_e38ca376_ASSET = "file")
load("images/img_e413ee45.png", IMG_e413ee45_ASSET = "file")
load("images/img_e442dd3e.png", IMG_e442dd3e_ASSET = "file")
load("images/img_e45e30f6.png", IMG_e45e30f6_ASSET = "file")
load("images/img_e493acad.png", IMG_e493acad_ASSET = "file")
load("images/img_e56e8ce7.png", IMG_e56e8ce7_ASSET = "file")
load("images/img_e5a08972.png", IMG_e5a08972_ASSET = "file")
load("images/img_e6c2ff8b.png", IMG_e6c2ff8b_ASSET = "file")
load("images/img_e70e87df.png", IMG_e70e87df_ASSET = "file")
load("images/img_e766f860.png", IMG_e766f860_ASSET = "file")
load("images/img_e7e387b0.png", IMG_e7e387b0_ASSET = "file")
load("images/img_e7e7298e.png", IMG_e7e7298e_ASSET = "file")
load("images/img_e7eb032f.png", IMG_e7eb032f_ASSET = "file")
load("images/img_e7f5209d.png", IMG_e7f5209d_ASSET = "file")
load("images/img_e8476ec5.png", IMG_e8476ec5_ASSET = "file")
load("images/img_e889b829.png", IMG_e889b829_ASSET = "file")
load("images/img_e88beb50.png", IMG_e88beb50_ASSET = "file")
load("images/img_e8e5104d.png", IMG_e8e5104d_ASSET = "file")
load("images/img_ea5b5176.png", IMG_ea5b5176_ASSET = "file")
load("images/img_ea8274cc.png", IMG_ea8274cc_ASSET = "file")
load("images/img_eac3b474.png", IMG_eac3b474_ASSET = "file")
load("images/img_eb0c6d6c.png", IMG_eb0c6d6c_ASSET = "file")
load("images/img_eb36dbae.png", IMG_eb36dbae_ASSET = "file")
load("images/img_eb7fa0d8.png", IMG_eb7fa0d8_ASSET = "file")
load("images/img_eba4f7af.png", IMG_eba4f7af_ASSET = "file")
load("images/img_ebde41a9.png", IMG_ebde41a9_ASSET = "file")
load("images/img_ecc1c3f4.png", IMG_ecc1c3f4_ASSET = "file")
load("images/img_ece96e91.png", IMG_ece96e91_ASSET = "file")
load("images/img_ed09d0f3.png", IMG_ed09d0f3_ASSET = "file")
load("images/img_ee648d1a.png", IMG_ee648d1a_ASSET = "file")
load("images/img_eeb970d2.png", IMG_eeb970d2_ASSET = "file")
load("images/img_ef43b180.png", IMG_ef43b180_ASSET = "file")
load("images/img_ef44195a.png", IMG_ef44195a_ASSET = "file")
load("images/img_ef6b167a.png", IMG_ef6b167a_ASSET = "file")
load("images/img_efd9af83.png", IMG_efd9af83_ASSET = "file")
load("images/img_f051302d.png", IMG_f051302d_ASSET = "file")
load("images/img_f06eb9f0.png", IMG_f06eb9f0_ASSET = "file")
load("images/img_f0b050d3.png", IMG_f0b050d3_ASSET = "file")
load("images/img_f178ab41.png", IMG_f178ab41_ASSET = "file")
load("images/img_f17b885e.png", IMG_f17b885e_ASSET = "file")
load("images/img_f17d8ea9.png", IMG_f17d8ea9_ASSET = "file")
load("images/img_f1dfb854.png", IMG_f1dfb854_ASSET = "file")
load("images/img_f2247be5.png", IMG_f2247be5_ASSET = "file")
load("images/img_f263066c.png", IMG_f263066c_ASSET = "file")
load("images/img_f277f5e3.png", IMG_f277f5e3_ASSET = "file")
load("images/img_f280d3bb.png", IMG_f280d3bb_ASSET = "file")
load("images/img_f2acacc2.png", IMG_f2acacc2_ASSET = "file")
load("images/img_f30833b1.png", IMG_f30833b1_ASSET = "file")
load("images/img_f35d2c15.png", IMG_f35d2c15_ASSET = "file")
load("images/img_f3f157e7.png", IMG_f3f157e7_ASSET = "file")
load("images/img_f48bbf75.png", IMG_f48bbf75_ASSET = "file")
load("images/img_f4ba06dc.png", IMG_f4ba06dc_ASSET = "file")
load("images/img_f4fa8605.png", IMG_f4fa8605_ASSET = "file")
load("images/img_f5d8cdab.png", IMG_f5d8cdab_ASSET = "file")
load("images/img_f60bad51.png", IMG_f60bad51_ASSET = "file")
load("images/img_f6a03fb4.png", IMG_f6a03fb4_ASSET = "file")
load("images/img_f6b385a8.png", IMG_f6b385a8_ASSET = "file")
load("images/img_f6d69597.png", IMG_f6d69597_ASSET = "file")
load("images/img_f6e7a5fc.png", IMG_f6e7a5fc_ASSET = "file")
load("images/img_f6f30aa4.png", IMG_f6f30aa4_ASSET = "file")
load("images/img_f7866f1f.png", IMG_f7866f1f_ASSET = "file")
load("images/img_f7ddb85d.png", IMG_f7ddb85d_ASSET = "file")
load("images/img_f80c8052.png", IMG_f80c8052_ASSET = "file")
load("images/img_f89c6d4a.png", IMG_f89c6d4a_ASSET = "file")
load("images/img_f8e870f0.png", IMG_f8e870f0_ASSET = "file")
load("images/img_f9b0147b.png", IMG_f9b0147b_ASSET = "file")
load("images/img_f9d74573.png", IMG_f9d74573_ASSET = "file")
load("images/img_f9f56699.png", IMG_f9f56699_ASSET = "file")
load("images/img_fa25b45a.png", IMG_fa25b45a_ASSET = "file")
load("images/img_fa590a9b.png", IMG_fa590a9b_ASSET = "file")
load("images/img_fa8ef2ca.png", IMG_fa8ef2ca_ASSET = "file")
load("images/img_fab6d7ed.png", IMG_fab6d7ed_ASSET = "file")
load("images/img_fb3b5855.png", IMG_fb3b5855_ASSET = "file")
load("images/img_fb45261c.png", IMG_fb45261c_ASSET = "file")
load("images/img_fbffda36.png", IMG_fbffda36_ASSET = "file")
load("images/img_fc08e88a.png", IMG_fc08e88a_ASSET = "file")
load("images/img_fc1f8780.png", IMG_fc1f8780_ASSET = "file")
load("images/img_fc6b5e9c.png", IMG_fc6b5e9c_ASSET = "file")
load("images/img_fd36449e.png", IMG_fd36449e_ASSET = "file")
load("images/img_fdf6d3a2.png", IMG_fdf6d3a2_ASSET = "file")
load("images/img_fe321946.png", IMG_fe321946_ASSET = "file")
load("images/img_feec6ca3.png", IMG_feec6ca3_ASSET = "file")
load("images/img_ff0883c2.png", IMG_ff0883c2_ASSET = "file")
load("images/img_ff41804c.png", IMG_ff41804c_ASSET = "file")
load("images/img_ff58e14c.png", IMG_ff58e14c_ASSET = "file")
load("images/img_fff7eadd.png", IMG_fff7eadd_ASSET = "file")

FONT = "tom-thumb"

DESCRIPTION = "description"
PRONUNCIATION = "pronunciation"

# To match the Maya Glyphs app
GOLD = "#e79223"
TEAL = "#56a0a0"

def main():
    # Pick a new pseudorandom glyph every 15 seconds
    timestamp = time.now().unix // 15
    h = hash.md5(str(timestamp))
    index = int(h, 16) % len(GLYPHS)
    key = sorted(GLYPHS.keys())[index]

    glyph = GLYPHS[key]

    texts = [
        # Glyph ID from Gardiner's sign list
        render.Text(
            key,
            font = FONT,
            color = TEAL,
        ),
    ]

    if PRONUNCIATION in glyph:
        # How to pronounce, in Manuel de Codage convention
        # https://en.wikipedia.org/wiki/Manuel_de_Codage
        texts.append(
            render.Text(
                glyph[PRONUNCIATION],
                font = FONT,
            ),
        )

    if DESCRIPTION in glyph:
        used_height = 6
        for t in texts:
            used_height += t.size()[1]
        texts.append(
            render.Padding(
                pad = (0, 30 - used_height, 0, 0),
                child = render.Marquee(
                    scroll_direction = "horizontal",
                    width = 62,
                    child = render.Text(
                        glyph[DESCRIPTION],
                        font = FONT,
                        color = GOLD,
                    ),
                ),
            ),
        )

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
                                children = [
                                    render.Image(base64.decode(glyph["src"])),
                                ],
                            ),
                        ],
                    ),
                    render.Column(
                        main_align = "start",
                        cross_align = "start",
                        expanded = True,
                        children = texts,
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

# Many thanks to the WikiHiero project https://www.mediawiki.org/wiki/Extension:WikiHiero
# Sources are released under the GNU Public License and images under the GNU Free Documentation Licence.
GLYPHS = {
    "O6": {
        "description": "enclosure",
        "pronunciation": "Hwt",
        "src": IMG_9ad004d3_ASSET.readall(),
    },
    "T23": {
        "description": "arrowhead",
        "src": IMG_a9cb49e3_ASSET.readall(),
    },
    "Aa22": {
        "src": IMG_c83495d7_ASSET.readall(),
    },
    "W10": {
        "description": "cup",
        "pronunciation": "iab",
        "src": IMG_66e50cfc_ASSET.readall(),
    },
    "S18": {
        "description": "menatnecklaceandcounterpoise",
        "pronunciation": "mnit",
        "src": IMG_4643f695_ASSET.readall(),
    },
    "B5": {
        "description": "woman suckling child",
        "src": IMG_c19b0a90_ASSET.readall(),
    },
    "W2": {
        "description": "oil-jar without ties",
        "pronunciation": "bAs",
        "src": IMG_171bd5b9_ASSET.readall(),
    },
    "Q4": {
        "description": "headrest",
        "src": IMG_43e7143e_ASSET.readall(),
    },
    "Y7": {
        "description": "harp",
        "src": IMG_d72f27ba_ASSET.readall(),
    },
    "R16": {
        "description": "sceptre with feathers and string",
        "pronunciation": "wx",
        "src": IMG_86d17050_ASSET.readall(),
    },
    "S43": {
        "description": "walking stick",
        "pronunciation": "md",
        "src": IMG_793254cc_ASSET.readall(),
    },
    "O16": {
        "description": "gateway with serpents",
        "src": IMG_4774c84b_ASSET.readall(),
    },
    "M17": {
        "description": "reed",
        "pronunciation": "i",
        "src": IMG_a9645e45_ASSET.readall(),
    },
    "U18": {
        "src": IMG_4b963bf1_ASSET.readall(),
    },
    "R2": {
        "description": "table with slices of bread",
        "src": IMG_f6d69597_ASSET.readall(),
    },
    "R20": {
        "description": "flower with horns",
        "src": IMG_64131565_ASSET.readall(),
    },
    "V27": {
        "src": IMG_b0007393_ASSET.readall(),
    },
    "Z94": {
        "src": IMG_3f1a3fbb_ASSET.readall(),
    },
    "B8": {
        "description": "woman holding lotus flower",
        "src": IMG_feec6ca3_ASSET.readall(),
    },
    "E18": {
        "description": "wolf on standard",
        "src": IMG_86be7891_ASSET.readall(),
    },
    "S20": {
        "description": "necklace with seal",
        "pronunciation": "xtm",
        "src": IMG_73456c10_ASSET.readall(),
    },
    "T18": {
        "description": "crook with package attached",
        "pronunciation": "Sms",
        "src": IMG_f8e870f0_ASSET.readall(),
    },
    "M37": {
        "description": "bundle of flax",
        "src": IMG_4db4da7a_ASSET.readall(),
    },
    "V19": {
        "pronunciation": "mDt",
        "src": IMG_d23ea096_ASSET.readall(),
    },
    "A5": {
        "description": "crouching man hiding behind wall",
        "src": IMG_a81418e9_ASSET.readall(),
    },
    "W16": {
        "description": "water jar with rack",
        "src": IMG_d2f7410e_ASSET.readall(),
    },
    "G7": {
        "description": "falcon on standard",
        "src": IMG_064ed1ae_ASSET.readall(),
    },
    "A23": {
        "description": "king with staff and mace with round head",
        "src": IMG_d05e2f69_ASSET.readall(),
    },
    "S44": {
        "description": "walking stick with flagellum",
        "pronunciation": "Ams",
        "src": IMG_06bb469f_ASSET.readall(),
    },
    "G11": {
        "description": "image of falcon",
        "src": IMG_a53abc58_ASSET.readall(),
    },
    "A49": {
        "description": "seated syrian holding stick",
        "src": IMG_0ef19470_ASSET.readall(),
    },
    "Aa25": {
        "src": IMG_388c2020_ASSET.readall(),
    },
    "E10": {
        "description": "ram",
        "src": IMG_8b91532e_ASSET.readall(),
    },
    "R9": {
        "description": "combination of cloth on pole and bag",
        "pronunciation": "bd",
        "src": IMG_4b8925e9_ASSET.readall(),
    },
    "E13": {
        "description": "cat",
        "src": IMG_b9f103ff_ASSET.readall(),
    },
    "O42": {
        "description": "fence",
        "pronunciation": "Szp",
        "src": IMG_6a30b5e7_ASSET.readall(),
    },
    "V18": {
        "src": IMG_3249722a_ASSET.readall(),
    },
    "N31": {
        "description": "road with shrubs",
        "src": IMG_92967819_ASSET.readall(),
    },
    "R11": {
        "description": "reed column",
        "pronunciation": "dd",
        "src": IMG_97e32c30_ASSET.readall(),
    },
    "V12": {
        "pronunciation": "arq",
        "src": IMG_e7e7298e_ASSET.readall(),
    },
    "V39": {
        "description": "?stylized ankh(for isis)(?)",
        "src": IMG_c89bcfc8_ASSET.readall(),
    },
    "Aa1": {
        "description": "placenta or sieve",
        "pronunciation": "x",
        "src": IMG_4a355a5a_ASSET.readall(),
    },
    "A35": {
        "description": "man building wall",
        "src": IMG_f6f30aa4_ASSET.readall(),
    },
    "T27": {
        "description": "trap",
        "src": IMG_692080a9_ASSET.readall(),
    },
    "F21": {
        "description": "ear of bovine",
        "pronunciation": "sDm",
        "src": IMG_51c84636_ASSET.readall(),
    },
    "O29": {
        "description": "horizontal wooden column",
        "pronunciation": "aA",
        "src": IMG_4ba07cac_ASSET.readall(),
    },
    "M25": {
        "description": "combination of flowering sedge and mouth",
        "src": IMG_4cdc9896_ASSET.readall(),
    },
    "W17": {
        "description": "water jar with rack",
        "pronunciation": "xnt",
        "src": IMG_ece96e91_ASSET.readall(),
    },
    "T13": {
        "description": "joined pieces of wood",
        "pronunciation": "rs",
        "src": IMG_9cb34b95_ASSET.readall(),
    },
    "O14": {
        "description": "part of battlemented enclosure",
        "src": IMG_0be16370_ASSET.readall(),
    },
    "G9": {
        "description": "falcon with sun on head",
        "src": IMG_69f9f2c0_ASSET.readall(),
    },
    "S1": {
        "description": "white crown",
        "pronunciation": "HDt",
        "src": IMG_08f9fab8_ASSET.readall(),
    },
    "M19": {
        "description": "heaped conical cakes between reed and club",
        "src": IMG_51a68752_ASSET.readall(),
    },
    "G23": {
        "description": "lapwing",
        "pronunciation": "rxyt",
        "src": IMG_cb8f48b1_ASSET.readall(),
    },
    "Q1": {
        "description": "seatthrone",
        "pronunciation": "st",
        "src": IMG_4aa4411f_ASSET.readall(),
    },
    "S41": {
        "description": "sceptre",
        "pronunciation": "Dam",
        "src": IMG_afa2060c_ASSET.readall(),
    },
    "N36": {
        "description": "canal",
        "src": IMG_66fc2935_ASSET.readall(),
    },
    "M29": {
        "description": "seed-pod",
        "pronunciation": "nDm",
        "src": IMG_340aafc2_ASSET.readall(),
    },
    "O47": {
        "description": "enclosed mound",
        "pronunciation": "nxn",
        "src": IMG_47dd5f2c_ASSET.readall(),
    },
    "T12": {
        "description": "bowstring",
        "pronunciation": "rwd",
        "src": IMG_1a35df33_ASSET.readall(),
    },
    "O39": {
        "description": "stone",
        "src": IMG_ff0883c2_ASSET.readall(),
    },
    "N17": {
        "description": "land",
        "src": IMG_58d36b2c_ASSET.readall(),
    },
    "G48": {
        "description": "three ducklings in nest",
        "src": IMG_428f42c9_ASSET.readall(),
    },
    "D1": {
        "description": "head",
        "pronunciation": "tp",
        "src": IMG_39254ede_ASSET.readall(),
    },
    "I5": {
        "description": "crocodile with curved tail",
        "pronunciation": "sAq",
        "src": IMG_9b5d0657_ASSET.readall(),
    },
    "L7": {
        "description": "scorpion",
        "pronunciation": "srqt",
        "src": IMG_45aff79b_ASSET.readall(),
    },
    "V23": {
        "src": IMG_23340edd_ASSET.readall(),
    },
    "C19": {
        "description": "mummy-shaped god",
        "src": IMG_a5e69189_ASSET.readall(),
    },
    "O11": {
        "description": "palace",
        "pronunciation": "aH",
        "src": IMG_550f3326_ASSET.readall(),
    },
    "D2": {
        "description": "face",
        "pronunciation": "Hr",
        "src": IMG_227023d7_ASSET.readall(),
    },
    "R12": {
        "description": "standard",
        "src": IMG_f7866f1f_ASSET.readall(),
    },
    "V7": {
        "description": "rope-(shape)",
        "pronunciation": "Sn",
        "src": IMG_b1f96d00_ASSET.readall(),
    },
    "G45": {
        "description": "combination of quail chick and forearm",
        "src": IMG_c160d134_ASSET.readall(),
    },
    "P10": {
        "description": "rudder",
        "src": IMG_74f7baff_ASSET.readall(),
    },
    "T29": {
        "description": "butcher's block with knife",
        "pronunciation": "nmt",
        "src": IMG_1f57ad12_ASSET.readall(),
    },
    "M33": {
        "description": "3 grains horizontally",
        "src": IMG_0727f80e_ASSET.readall(),
    },
    "M44": {
        "description": "thorn",
        "src": IMG_0f442725_ASSET.readall(),
    },
    "S45": {
        "description": "flagellum",
        "pronunciation": "nxxw",
        "src": IMG_ba47cd2d_ASSET.readall(),
    },
    "R15": {
        "description": "spear, emblem of the east",
        "pronunciation": "iAb",
        "src": IMG_55622e70_ASSET.readall(),
    },
    "O41": {
        "description": "double stairway",
        "src": IMG_5266b180_ASSET.readall(),
    },
    "Z92": {
        "src": IMG_09013a1c_ASSET.readall(),
    },
    "S35": {
        "description": "sunshade",
        "pronunciation": "Swt",
        "src": IMG_e09d8705_ASSET.readall(),
    },
    "L5": {
        "description": "centipede",
        "src": IMG_882a8107_ASSET.readall(),
    },
    "O38": {
        "description": "corner of wall",
        "src": IMG_4b20e344_ASSET.readall(),
    },
    "Aa41": {
        "src": IMG_a769fe21_ASSET.readall(),
    },
    "M18": {
        "description": "combination of reed and legs walking",
        "pronunciation": "ii",
        "src": IMG_d708d3ef_ASSET.readall(),
    },
    "G22": {
        "description": "hoopoe",
        "pronunciation": "Db",
        "src": IMG_665ac7a5_ASSET.readall(),
    },
    "O28": {
        "description": "column",
        "pronunciation": "iwn",
        "src": IMG_34da11dd_ASSET.readall(),
    },
    "O8": {
        "description": "combination of enclosure, flat loaf and wooden column",
        "src": IMG_66f4eb94_ASSET.readall(),
    },
    "M28": {
        "description": "combination of flowering sedge and hobble",
        "src": IMG_85ecd114_ASSET.readall(),
    },
    "S34": {
        "description": "lifeankh, possibly representing a sandal-strap",
        "pronunciation": "anx",
        "src": IMG_3519ae3e_ASSET.readall(),
    },
    "F30": {
        "description": "water-skin",
        "pronunciation": "Sd",
        "src": IMG_79b34ed9_ASSET.readall(),
    },
    "M6": {
        "description": "combination of palm branch and mouth",
        "pronunciation": "tr",
        "src": IMG_494e671e_ASSET.readall(),
    },
    "S9": {
        "description": "shutitwo-featheradornment",
        "pronunciation": "Swty",
        "src": IMG_ca2d9496_ASSET.readall(),
    },
    "I9": {
        "description": "horned viper",
        "pronunciation": "f",
        "src": IMG_7dcd4688_ASSET.readall(),
    },
    "D10": {
        "description": "eye of horus",
        "pronunciation": "wDAt",
        "src": IMG_5bd81fff_ASSET.readall(),
    },
    "B6": {
        "description": "woman on chair with child on lap",
        "src": IMG_f280d3bb_ASSET.readall(),
    },
    "F29": {
        "description": "cow's skin pierced by arrow",
        "pronunciation": "sti",
        "src": IMG_b95cb370_ASSET.readall(),
    },
    "V29": {
        "description": "(fiber)swab(straw broom)",
        "pronunciation": "wAH",
        "src": IMG_29aac353_ASSET.readall(),
    },
    "G49": {
        "description": "three ducklings in pool",
        "src": IMG_fd36449e_ASSET.readall(),
    },
    "Y2": {
        "src": IMG_4e820fa8_ASSET.readall(),
    },
    "Aa28": {
        "pronunciation": "qd",
        "src": IMG_710f120f_ASSET.readall(),
    },
    "S19": {
        "description": "sealwith necklace",
        "pronunciation": "sDAw",
        "src": IMG_b45d7da2_ASSET.readall(),
    },
    "A28": {
        "description": "man with hands raised on either side",
        "src": IMG_251b322b_ASSET.readall(),
    },
    "N3": {
        "description": "sky with sceptre",
        "src": IMG_2515bb9d_ASSET.readall(),
    },
    "R7": {
        "description": "bowl with smoke",
        "pronunciation": "snTr",
        "src": IMG_c3c13e2b_ASSET.readall(),
    },
    "Z4": {
        "description": "dual stroke",
        "pronunciation": "y",
        "src": IMG_432083ff_ASSET.readall(),
    },
    "G31": {
        "description": "heron",
        "src": IMG_0e1df356_ASSET.readall(),
    },
    "N28": {
        "description": "rays of sun over hill",
        "pronunciation": "xa",
        "src": IMG_5a3a077a_ASSET.readall(),
    },
    "D43": {
        "description": "forearm with flail",
        "src": IMG_a97c3f20_ASSET.readall(),
    },
    "F7": {
        "description": "ram head",
        "src": IMG_29ba85a5_ASSET.readall(),
    },
    "N30": {
        "description": "mound of earth",
        "pronunciation": "iAt",
        "src": IMG_18f1b417_ASSET.readall(),
    },
    "L2": {
        "description": "bee",
        "pronunciation": "bit",
        "src": IMG_bcf6fc27_ASSET.readall(),
    },
    "C10": {
        "description": "goddess with feather",
        "pronunciation": "mAat",
        "src": IMG_0f36a809_ASSET.readall(),
    },
    "U21": {
        "description": "adze-on-block",
        "pronunciation": "stp",
        "src": IMG_eb0c6d6c_ASSET.readall(),
    },
    "F33": {
        "description": "tail",
        "pronunciation": "sd",
        "src": IMG_ce827360_ASSET.readall(),
    },
    "Aa30": {
        "pronunciation": "Xkr",
        "src": IMG_1ad35e66_ASSET.readall(),
    },
    "N12": {
        "description": "crescent moon",
        "src": IMG_c20fc55f_ASSET.readall(),
    },
    "F32": {
        "description": "animal's belly",
        "pronunciation": "X",
        "src": IMG_6b9a6992_ASSET.readall(),
    },
    "M40": {
        "description": "bundle of reeds",
        "pronunciation": "iz",
        "src": IMG_9cf3fbc8_ASSET.readall(),
    },
    "U22": {
        "description": "clapper-(of-bell)tool/instrumentforked-staff, etc.",
        "pronunciation": "mnx",
        "src": IMG_a7310142_ASSET.readall(),
    },
    "D7": {
        "description": "eye with painted lower lid",
        "src": IMG_1f229b02_ASSET.readall(),
    },
    "G10": {
        "description": "falcon in sokar barque",
        "src": IMG_e70e87df_ASSET.readall(),
    },
    "S12": {
        "description": "collar of beads",
        "pronunciation": "nbw",
        "src": IMG_fc6b5e9c_ASSET.readall(),
    },
    "X5": {
        "src": IMG_ecc1c3f4_ASSET.readall(),
    },
    "G21": {
        "description": "guineafowl",
        "pronunciation": "nH",
        "src": IMG_42f94e16_ASSET.readall(),
    },
    "T17": {
        "description": "chariot",
        "pronunciation": "wrrt",
        "src": IMG_e45e30f6_ASSET.readall(),
    },
    "F18": {
        "description": "tusk",
        "pronunciation": "bH",
        "src": IMG_3ab57c8c_ASSET.readall(),
    },
    "Q3": {
        "description": "stool",
        "pronunciation": "p",
        "src": IMG_eb7fa0d8_ASSET.readall(),
    },
    "F52": {
        "description": "excrement",
        "src": IMG_fa8ef2ca_ASSET.readall(),
    },
    "E22": {
        "description": "lion",
        "pronunciation": "mAi",
        "src": IMG_63346f63_ASSET.readall(),
    },
    "N39": {
        "description": "pool with water",
        "src": IMG_9cbabf42_ASSET.readall(),
    },
    "N41": {
        "description": "well with ripple of water",
        "pronunciation": "id",
        "src": IMG_3af39e89_ASSET.readall(),
    },
    "T5": {
        "description": "combination of mace with round head and cobra",
        "src": IMG_b34a3964_ASSET.readall(),
    },
    "A10": {
        "description": "seated man holding oar",
        "src": IMG_057d06d0_ASSET.readall(),
    },
    "D53": {
        "description": "phallus with emission",
        "src": IMG_33ddb4d3_ASSET.readall(),
    },
    "K4": {
        "description": "elephant-snout fish",
        "pronunciation": "XA",
        "src": IMG_55ed187b_ASSET.readall(),
    },
    "S31": {
        "description": "combination of folded cloth and sickle",
        "src": IMG_efd9af83_ASSET.readall(),
    },
    "K6": {
        "description": "fish scale",
        "pronunciation": "nSmt",
        "src": IMG_eeb970d2_ASSET.readall(),
    },
    "E25": {
        "description": "hippopotamus",
        "src": IMG_038805d0_ASSET.readall(),
    },
    "B3": {
        "description": "woman giving birth",
        "pronunciation": "msi",
        "src": IMG_36b788fd_ASSET.readall(),
    },
    "T24": {
        "description": "fishingnet",
        "pronunciation": "iH",
        "src": IMG_ab9206da_ASSET.readall(),
    },
    "Aa3": {
        "description": "pustule with liquid issuing from it",
        "src": IMG_3816ccd0_ASSET.readall(),
    },
    "T32": {
        "description": "combination of knife-sharpener and legs",
        "src": IMG_3b55acac_ASSET.readall(),
    },
    "V13": {
        "description": "tethering rope",
        "pronunciation": "T",
        "src": IMG_fdf6d3a2_ASSET.readall(),
    },
    "E30": {
        "description": "ibex",
        "src": IMG_aefa6fb0_ASSET.readall(),
    },
    "F50": {
        "description": "combination of f46 and s29",
        "src": IMG_891bf9eb_ASSET.readall(),
    },
    "Z8": {
        "description": "oval",
        "src": IMG_310ca371_ASSET.readall(),
    },
    "O50": {
        "description": "threshing floor",
        "pronunciation": "zp",
        "src": IMG_6c24ca9f_ASSET.readall(),
    },
    "D45": {
        "description": "arm with wand",
        "pronunciation": "Dsr",
        "src": IMG_19a5c741_ASSET.readall(),
    },
    "A33": {
        "description": "man with stick and bundle on shoulder",
        "pronunciation": "mniw",
        "src": IMG_a96b151f_ASSET.readall(),
    },
    "V14": {
        "src": IMG_ccdc47ff_ASSET.readall(),
    },
    "U30": {
        "description": "kiln",
        "src": IMG_2e94c0e3_ASSET.readall(),
    },
    "A29": {
        "description": "man upside down",
        "src": IMG_1056d782_ASSET.readall(),
    },
    "P13": {
        "src": IMG_5366c94b_ASSET.readall(),
    },
    "S5": {
        "description": "pschent crown",
        "src": IMG_d23e7478_ASSET.readall(),
    },
    "U32": {
        "pronunciation": "zmn",
        "src": IMG_60911c99_ASSET.readall(),
    },
    "G42": {
        "description": "widgeon",
        "pronunciation": "wSA",
        "src": IMG_25df1d69_ASSET.readall(),
    },
    "T4": {
        "description": "mace with strap",
        "src": IMG_aeada940_ASSET.readall(),
    },
    "Aa32": {
        "src": IMG_7531b15d_ASSET.readall(),
    },
    "F47": {
        "description": "intestine",
        "src": IMG_afa595a0_ASSET.readall(),
    },
    "U9": {
        "src": IMG_abc7d3ad_ASSET.readall(),
    },
    "G8": {
        "description": "falcon on collar of beads",
        "src": IMG_d524b173_ASSET.readall(),
    },
    "D15": {
        "description": "diagonal marking of eye of horus",
        "src": IMG_5b0ce33a_ASSET.readall(),
    },
    "O1": {
        "description": "house",
        "pronunciation": "pr",
        "src": IMG_8a54c849_ASSET.readall(),
    },
    "A18": {
        "description": "child wearing red crown",
        "src": IMG_15d67858_ASSET.readall(),
    },
    "F2": {
        "description": "charging ox head",
        "src": IMG_c732b82d_ASSET.readall(),
    },
    "E11": {
        "description": "ram",
        "src": IMG_50a573a5_ASSET.readall(),
    },
    "D27": {
        "description": "small breast",
        "pronunciation": "mnD",
        "src": IMG_c786ad76_ASSET.readall(),
    },
    "R13": {
        "description": "falcon and feather on standard",
        "src": IMG_4f7a1d73_ASSET.readall(),
    },
    "T31": {
        "description": "knife-sharpener",
        "pronunciation": "sSm",
        "src": IMG_34cfda0f_ASSET.readall(),
    },
    "X6": {
        "description": "loaf-with-decoration",
        "src": IMG_07cb5549_ASSET.readall(),
    },
    "G20": {
        "description": "combination of owl and forearm",
        "src": IMG_75ab6d52_ASSET.readall(),
    },
    "K5": {
        "description": "petrocephalus bane",
        "pronunciation": "bz",
        "src": IMG_817f79e0_ASSET.readall(),
    },
    "G39": {
        "description": "pintail",
        "pronunciation": "zA",
        "src": IMG_e56e8ce7_ASSET.readall(),
    },
    "V2": {
        "pronunciation": "sTA",
        "src": IMG_40de1f4f_ASSET.readall(),
    },
    "T7": {
        "description": "axe",
        "src": IMG_a81d466c_ASSET.readall(),
    },
    "W18": {
        "description": "water jar with rack",
        "src": IMG_4a0b0880_ASSET.readall(),
    },
    "A59": {
        "description": "man threatening with stick",
        "src": IMG_f0b050d3_ASSET.readall(),
    },
    "C4": {
        "description": "god with ram head",
        "pronunciation": "Xnmw",
        "src": IMG_d2ec2161_ASSET.readall(),
    },
    "Z1": {
        "description": "single stroke",
        "src": IMG_109eea05_ASSET.readall(),
    },
    "U28": {
        "description": "fire-drill",
        "pronunciation": "DA",
        "src": IMG_d6934f36_ASSET.readall(),
    },
    "F26": {
        "description": "skin of goat",
        "pronunciation": "Xn",
        "src": IMG_d80c534c_ASSET.readall(),
    },
    "R10": {
        "description": "combination of cloth on pole, butcher's block and slope of hill",
        "src": IMG_722c2eb8_ASSET.readall(),
    },
    "O23": {
        "description": "double platform",
        "src": IMG_da284ecd_ASSET.readall(),
    },
    "T22": {
        "description": "arrowhead",
        "pronunciation": "sn",
        "src": IMG_b073d97f_ASSET.readall(),
    },
    "R17": {
        "description": "wig on pole",
        "src": IMG_45a6b69f_ASSET.readall(),
    },
    "F40": {
        "description": "backbone and spinal cords",
        "pronunciation": "Aw",
        "src": IMG_8c101f49_ASSET.readall(),
    },
    "E26": {
        "description": "elephant",
        "src": IMG_6d36027e_ASSET.readall(),
    },
    "G30": {
        "description": "three saddle-billed storks",
        "src": IMG_974c47fd_ASSET.readall(),
    },
    "A16": {
        "description": "man bowing down",
        "src": IMG_5a664392_ASSET.readall(),
    },
    "S30": {
        "description": "combination of folded cloth and horned viper",
        "pronunciation": "sf",
        "src": IMG_962b308c_ASSET.readall(),
    },
    "F6": {
        "description": "forepart of hartebeest",
        "src": IMG_0b8c2497_ASSET.readall(),
    },
    "D14": {
        "description": "right part of eye of horus",
        "src": IMG_c04c2db7_ASSET.readall(),
    },
    "I11": {
        "description": "two cobras",
        "pronunciation": "DD",
        "src": IMG_bee51347_ASSET.readall(),
    },
    "A27": {
        "description": "hastening man",
        "src": IMG_ef6b167a_ASSET.readall(),
    },
    "Z9": {
        "description": "crossed diagonal sticks",
        "src": IMG_7e60be43_ASSET.readall(),
    },
    "T20": {
        "description": "harpoon head",
        "src": IMG_03149054_ASSET.readall(),
    },
    "M16": {
        "description": "clump of papyrus",
        "pronunciation": "HA",
        "src": IMG_25be8d83_ASSET.readall(),
    },
    "Aa11": {
        "pronunciation": "mAa",
        "src": IMG_2e3d13b3_ASSET.readall(),
    },
    "S17": {
        "description": "pectoral",
        "src": IMG_a0048e11_ASSET.readall(),
    },
    "D19": {
        "description": "nose, eye and cheek",
        "pronunciation": "fnD",
        "src": IMG_78dfda53_ASSET.readall(),
    },
    "D42": {
        "description": "forearm with palm down and straight upper arm",
        "src": IMG_33446bb9_ASSET.readall(),
    },
    "C9": {
        "description": "goddess with horned sun-disk",
        "src": IMG_4ea6d4ed_ASSET.readall(),
    },
    "M30": {
        "description": "root",
        "pronunciation": "bnr",
        "src": IMG_ca9aa90e_ASSET.readall(),
    },
    "A50": {
        "description": "noble on chair",
        "pronunciation": "Sps",
        "src": IMG_6058c50b_ASSET.readall(),
    },
    "Y6": {
        "description": "game piece",
        "pronunciation": "ibA",
        "src": IMG_a4da2361_ASSET.readall(),
    },
    "Aa21": {
        "pronunciation": "wDa",
        "src": IMG_b5cd8a7e_ASSET.readall(),
    },
    "I14": {
        "description": "snake",
        "src": IMG_c19fbfdd_ASSET.readall(),
    },
    "L3": {
        "description": "fly",
        "src": IMG_9a5defbe_ASSET.readall(),
    },
    "A9": {
        "description": "man steadying basket on head",
        "src": IMG_49f7a694_ASSET.readall(),
    },
    "O32": {
        "description": "gateway",
        "src": IMG_c7ee90b1_ASSET.readall(),
    },
    "W11": {
        "description": "jar stand",
        "pronunciation": "nzt",
        "src": IMG_ab3e0b95_ASSET.readall(),
    },
    "U15": {
        "description": "sled(sledge)",
        "pronunciation": "tm",
        "src": IMG_fff7eadd_ASSET.readall(),
    },
    "O31": {
        "description": "door",
        "src": IMG_083f5351_ASSET.readall(),
    },
    "D62": {
        "description": "three toes oriented rightward",
        "src": IMG_52e3df03_ASSET.readall(),
    },
    "E15": {
        "description": "lying canine",
        "src": IMG_19df7447_ASSET.readall(),
    },
    "U27": {
        "src": IMG_d2b4d450_ASSET.readall(),
    },
    "M22": {
        "description": "rush",
        "src": IMG_61eab265_ASSET.readall(),
    },
    "P3": {
        "description": "sacred barque",
        "src": IMG_c9ba4ae3_ASSET.readall(),
    },
    "D29": {
        "description": "combination of hieroglyphs d28 and r12",
        "src": IMG_961631f2_ASSET.readall(),
    },
    "V16": {
        "description": "cattlehobble(bil.)",
        "src": IMG_4c89bccc_ASSET.readall(),
    },
    "D17": {
        "description": "diagonal and vertical markings of eye of horus",
        "src": IMG_f6e7a5fc_ASSET.readall(),
    },
    "U1": {
        "description": "sickle",
        "pronunciation": "mA",
        "src": IMG_4e302060_ASSET.readall(),
    },
    "F20": {
        "description": "tongue",
        "pronunciation": "ns",
        "src": IMG_17c54231_ASSET.readall(),
    },
    "G33": {
        "description": "cattle egret",
        "src": IMG_4f94b158_ASSET.readall(),
    },
    "E1": {
        "description": "bull",
        "src": IMG_d2b5af47_ASSET.readall(),
    },
    "H1": {
        "description": "head of pintail",
        "src": IMG_3b357730_ASSET.readall(),
    },
    "O18": {
        "description": "shrine in profile",
        "pronunciation": "kAr",
        "src": IMG_54f41c28_ASSET.readall(),
    },
    "E14": {
        "description": "dog",
        "src": IMG_9033a8f0_ASSET.readall(),
    },
    "M12": {
        "description": "one lotus plant",
        "pronunciation": "1000",
        "src": IMG_4cddfb5b_ASSET.readall(),
    },
    "D48": {
        "description": "hand without thumb",
        "src": IMG_f4ba06dc_ASSET.readall(),
    },
    "O46": {
        "description": "domed building",
        "src": IMG_f263066c_ASSET.readall(),
    },
    "Aa4": {
        "src": IMG_2bc1838b_ASSET.readall(),
    },
    "Y8": {
        "description": "sistrum",
        "pronunciation": "zSSt",
        "src": IMG_ed09d0f3_ASSET.readall(),
    },
    "D57": {
        "description": "leg with knife",
        "src": IMG_0a30600c_ASSET.readall(),
    },
    "U7": {
        "description": "hoe",
        "src": IMG_f6b385a8_ASSET.readall(),
    },
    "Z3": {
        "description": "plural strokes (vertical)",
        "src": IMG_0452f938_ASSET.readall(),
    },
    "D38": {
        "description": "forearm with rounded loaf",
        "src": IMG_d90f64b8_ASSET.readall(),
    },
    "R14": {
        "description": "emblemof the west",
        "pronunciation": "imnt",
        "src": IMG_d8188c6a_ASSET.readall(),
    },
    "W22": {
        "description": "beer jug",
        "pronunciation": "Hnqt",
        "src": IMG_9990eebc_ASSET.readall(),
    },
    "A34": {
        "description": "man pounding in a mortar",
        "src": IMG_812883fb_ASSET.readall(),
    },
    "V25": {
        "description": "command staff",
        "src": IMG_4395a225_ASSET.readall(),
    },
    "M31": {
        "description": "rhizome",
        "src": IMG_98dbadd8_ASSET.readall(),
    },
    "V9": {
        "description": "shenring",
        "src": IMG_8ee2558a_ASSET.readall(),
    },
    "B11": {
        "src": IMG_2d7f80e1_ASSET.readall(),
    },
    "G6": {
        "description": "combination of falcon and flaggellum",
        "src": IMG_019c936a_ASSET.readall(),
    },
    "M39": {
        "description": "basket of fruit or grain",
        "src": IMG_91de130d_ASSET.readall(),
    },
    "N27": {
        "description": "sun over mountain",
        "pronunciation": "Axt",
        "src": IMG_7a1f303f_ASSET.readall(),
    },
    "N32": {
        "description": "lump of clay",
        "src": IMG_aa895591_ASSET.readall(),
    },
    "D35": {
        "description": "arms in gesture of negation",
        "src": IMG_9ccc8fe3_ASSET.readall(),
    },
    "W14": {
        "description": "water jar",
        "pronunciation": "Hz",
        "src": IMG_b9c7e385_ASSET.readall(),
    },
    "A31": {
        "description": "man with hands raised behind him",
        "src": IMG_8570da19_ASSET.readall(),
    },
    "D13": {
        "description": "eyebrow",
        "src": IMG_69996ec4_ASSET.readall(),
    },
    "G12": {
        "description": "combination of image of falcon and flagellum",
        "src": IMG_ef44195a_ASSET.readall(),
    },
    "V6": {
        "description": "rope-(shape)",
        "pronunciation": "sS",
        "src": IMG_a1d890c1_ASSET.readall(),
    },
    "A43": {
        "description": "king wearing white crown",
        "src": IMG_d7e49fbf_ASSET.readall(),
    },
    "T34": {
        "description": "butcher's knife",
        "pronunciation": "nm",
        "src": IMG_4ab8e2e9_ASSET.readall(),
    },
    "G29": {
        "description": "saddle-billed stork",
        "pronunciation": "bA",
        "src": IMG_1ff45156_ASSET.readall(),
    },
    "E21": {
        "description": "lying set-animal",
        "src": IMG_5841c0c5_ASSET.readall(),
    },
    "F25": {
        "description": "leg ofox",
        "pronunciation": "wHm",
        "src": IMG_31afc721_ASSET.readall(),
    },
    "O19": {
        "description": "shrine with fence",
        "src": IMG_3080dd88_ASSET.readall(),
    },
    "G40": {
        "description": "pintail flying",
        "pronunciation": "pA",
        "src": IMG_b2997d46_ASSET.readall(),
    },
    "U16": {
        "description": "sled with jackal head",
        "pronunciation": "biA",
        "src": IMG_b2cfb097_ASSET.readall(),
    },
    "A36": {
        "description": "man kneading into vessel",
        "src": IMG_47282ffb_ASSET.readall(),
    },
    "A4": {
        "description": "seated man with hands raised",
        "src": IMG_1952c542_ASSET.readall(),
    },
    "D21": {
        "description": "mouth",
        "pronunciation": "rA",
        "src": IMG_77884021_ASSET.readall(),
    },
    "A6": {
        "description": "seated man under vase from which water flows",
        "src": IMG_bb9f9b2d_ASSET.readall(),
    },
    "M21": {
        "description": "reeds with root",
        "pronunciation": "sm",
        "src": IMG_ceff0bc5_ASSET.readall(),
    },
    "S15": {
        "description": "pectoral",
        "pronunciation": "tHn",
        "src": IMG_011f15dc_ASSET.readall(),
    },
    "D32": {
        "description": "arms embracing",
        "src": IMG_d8ec7fbc_ASSET.readall(),
    },
    "N37": {
        "description": "pool",
        "pronunciation": "S",
        "src": IMG_0d97cfe0_ASSET.readall(),
    },
    "T26": {
        "description": "birdtrap",
        "src": IMG_889cac3d_ASSET.readall(),
    },
    "W1": {
        "description": "oil jar",
        "src": IMG_b9206066_ASSET.readall(),
    },
    "S16": {
        "description": "pectoral",
        "src": IMG_bef7758f_ASSET.readall(),
    },
    "U2": {
        "description": "sickle",
        "src": IMG_2d8fd1b1_ASSET.readall(),
    },
    "D16": {
        "description": "vertical marking of eye of horus",
        "src": IMG_e88beb50_ASSET.readall(),
    },
    "D47": {
        "description": "hand with palm up",
        "src": IMG_63438e6c_ASSET.readall(),
    },
    "I6": {
        "description": "crocodile scales",
        "pronunciation": "km",
        "src": IMG_4ed18d4a_ASSET.readall(),
    },
    "H6": {
        "description": "feather",
        "pronunciation": "Sw",
        "src": IMG_180e1ca9_ASSET.readall(),
    },
    "S11": {
        "description": "broad collar",
        "pronunciation": "wsx",
        "src": IMG_4bf9b138_ASSET.readall(),
    },
    "E33": {
        "description": "monkey",
        "src": IMG_abd29292_ASSET.readall(),
    },
    "Q7": {
        "description": "brazier",
        "src": IMG_b87993b0_ASSET.readall(),
    },
    "D12": {
        "description": "pupil",
        "src": IMG_7808f1a7_ASSET.readall(),
    },
    "N4": {
        "description": "sky with rain",
        "pronunciation": "idt",
        "src": IMG_8394f2b3_ASSET.readall(),
    },
    "L6": {
        "description": "shell",
        "src": IMG_8c66c200_ASSET.readall(),
    },
    "D58": {
        "description": "foot",
        "pronunciation": "b",
        "src": IMG_b44c7ab1_ASSET.readall(),
    },
    "F17": {
        "description": "horn and vase from which water flows",
        "src": IMG_611bdd26_ASSET.readall(),
    },
    "E7": {
        "description": "donkey",
        "src": IMG_2c5df5a1_ASSET.readall(),
    },
    "F45": {
        "description": "uterus",
        "src": IMG_8d175f42_ASSET.readall(),
    },
    "A11": {
        "description": "seated man holding scepter of authority and shepherd's crook",
        "src": IMG_890eff42_ASSET.readall(),
    },
    "Y5": {
        "description": "senet board",
        "pronunciation": "mn",
        "src": IMG_82599031_ASSET.readall(),
    },
    "L1": {
        "description": "dung beetle",
        "pronunciation": "xpr",
        "src": IMG_be9c1f7f_ASSET.readall(),
    },
    "V35": {
        "src": IMG_a287cc73_ASSET.readall(),
    },
    "A22": {
        "description": "statue of man with staff and scepter of authority",
        "src": IMG_f9d74573_ASSET.readall(),
    },
    "Z95": {
        "src": IMG_32861038_ASSET.readall(),
    },
    "U11": {
        "pronunciation": "HqAt",
        "src": IMG_f4fa8605_ASSET.readall(),
    },
    "A30": {
        "description": "man with hands raised in front",
        "src": IMG_34d6db98_ASSET.readall(),
    },
    "T33": {
        "description": "knife-sharpener of butcher",
        "src": IMG_ee648d1a_ASSET.readall(),
    },
    "U10": {
        "description": "grain measure (with plural, for grain particles)",
        "pronunciation": "it",
        "src": IMG_215e98e7_ASSET.readall(),
    },
    "F16": {
        "description": "horn",
        "pronunciation": "db",
        "src": IMG_45ad9a25_ASSET.readall(),
    },
    "M3": {
        "description": "branch",
        "pronunciation": "xt",
        "src": IMG_1afe81ec_ASSET.readall(),
    },
    "O35": {
        "description": "combination of bolt and legs",
        "pronunciation": "zb",
        "src": IMG_0422274e_ASSET.readall(),
    },
    "O27": {
        "description": "hall of columns",
        "src": IMG_0a908084_ASSET.readall(),
    },
    "D9": {
        "description": "eye with flowing tears",
        "pronunciation": "rmi",
        "src": IMG_ff41804c_ASSET.readall(),
    },
    "T16": {
        "description": "scimitar",
        "src": IMG_05ff0b26_ASSET.readall(),
    },
    "V20": {
        "description": "cattle hobble",
        "pronunciation": "mD",
        "src": IMG_8434790d_ASSET.readall(),
    },
    "B4": {
        "description": "combination of woman giving birth and three skins tied together",
        "src": IMG_8886d1e4_ASSET.readall(),
    },
    "Aa40": {
        "src": IMG_5fe113c6_ASSET.readall(),
    },
    "P11": {
        "description": "mooringpost",
        "src": IMG_e1119e21_ASSET.readall(),
    },
    "M35": {
        "description": "stack(of grain)",
        "src": IMG_61ff189b_ASSET.readall(),
    },
    "Aa16": {
        "src": IMG_1a344bc3_ASSET.readall(),
    },
    "M9": {
        "description": "lotus flower",
        "pronunciation": "zSn",
        "src": IMG_4a47f1f1_ASSET.readall(),
    },
    "G46": {
        "description": "combination of quail chick and sickle",
        "pronunciation": "mAw",
        "src": IMG_d6ad6f13_ASSET.readall(),
    },
    "F44": {
        "description": "bone with meat",
        "pronunciation": "iwa",
        "src": IMG_52f27717_ASSET.readall(),
    },
    "V31": {
        "description": "basket-with-handle(hieroglyph)",
        "pronunciation": "k",
        "src": IMG_36d3c835_ASSET.readall(),
    },
    "T8": {
        "description": "dagger",
        "src": IMG_516fd65f_ASSET.readall(),
    },
    "E5": {
        "description": "cow suckling calf",
        "src": IMG_846328d6_ASSET.readall(),
    },
    "C17": {
        "description": "god with falcon head and two plumes",
        "src": IMG_24c7b233_ASSET.readall(),
    },
    "M43": {
        "description": "vine on trellis",
        "src": IMG_acb4ed21_ASSET.readall(),
    },
    "Z91": {
        "src": IMG_c30b1055_ASSET.readall(),
    },
    "V22": {
        "description": "whip",
        "pronunciation": "mH",
        "src": IMG_48a1a9cd_ASSET.readall(),
    },
    "D51": {
        "description": "one finger (horizontal)",
        "src": IMG_1a35d267_ASSET.readall(),
    },
    "G19": {
        "description": "combination of owl and forearm with conical loaf",
        "src": IMG_ebde41a9_ASSET.readall(),
    },
    "T2": {
        "description": "mace with round head",
        "src": IMG_c570bed4_ASSET.readall(),
    },
    "W20": {
        "description": "milk jug with cover",
        "src": IMG_d4f35356_ASSET.readall(),
    },
    "F27": {
        "description": "skin of cow with bent tail",
        "src": IMG_4f069ea4_ASSET.readall(),
    },
    "G35": {
        "description": "cormorant",
        "pronunciation": "aq",
        "src": IMG_ca526a67_ASSET.readall(),
    },
    "S38": {
        "description": "crook",
        "pronunciation": "HqA",
        "src": IMG_d0218ed3_ASSET.readall(),
    },
    "O51": {
        "description": "pile of grain",
        "pronunciation": "Snwt",
        "src": IMG_93b36254_ASSET.readall(),
    },
    "D44": {
        "description": "arm with sekhem scepter",
        "src": IMG_a67491cd_ASSET.readall(),
    },
    "M11": {
        "description": "flower on long twisted stalk",
        "pronunciation": "wdn",
        "src": IMG_b55565d9_ASSET.readall(),
    },
    "F34": {
        "description": "heart",
        "pronunciation": "ib",
        "src": IMG_f3f157e7_ASSET.readall(),
    },
    "S42": {
        "description": "sekhemscepter",
        "pronunciation": "xrp",
        "src": IMG_761d0c3d_ASSET.readall(),
    },
    "S3": {
        "description": "red crown",
        "pronunciation": "dSrt",
        "src": IMG_7f68c86c_ASSET.readall(),
    },
    "T15": {
        "description": "throw stick slanted",
        "src": IMG_c001eec0_ASSET.readall(),
    },
    "F24": {
        "description": "f23 reversed",
        "src": IMG_e493acad_ASSET.readall(),
    },
    "Aa27": {
        "pronunciation": "nD",
        "src": IMG_4ec8fc3e_ASSET.readall(),
    },
    "N34": {
        "description": "ingot of metal",
        "src": IMG_c00cdd06_ASSET.readall(),
    },
    "G27": {
        "description": "flamingo",
        "pronunciation": "dSr",
        "src": IMG_b7c84210_ASSET.readall(),
    },
    "A42": {
        "description": "king with uraeus and flagellum",
        "src": IMG_2c39d23c_ASSET.readall(),
    },
    "N9": {
        "description": "moon with lower half obscured",
        "pronunciation": "pzD",
        "src": IMG_d9990236_ASSET.readall(),
    },
    "M26": {
        "description": "floweringsedge",
        "pronunciation": "Sma",
        "src": IMG_0538b5c7_ASSET.readall(),
    },
    "F3": {
        "description": "hippopotamus head",
        "src": IMG_703100e1_ASSET.readall(),
    },
    "F8": {
        "description": "forepart of ram",
        "src": IMG_a0633063_ASSET.readall(),
    },
    "Aa12": {
        "src": IMG_1e4192f4_ASSET.readall(),
    },
    "O33": {
        "description": "façade of palace",
        "src": IMG_4e157a03_ASSET.readall(),
    },
    "O48": {
        "description": "enclosed mound",
        "src": IMG_687c4c3a_ASSET.readall(),
    },
    "S28": {
        "description": "cloth with fringe on top and folded cloth",
        "src": IMG_252cd65e_ASSET.readall(),
    },
    "N8": {
        "description": "sunshine",
        "pronunciation": "Hnmmt",
        "src": IMG_f89c6d4a_ASSET.readall(),
    },
    "F11": {
        "description": "head and neck of animal",
        "src": IMG_b66c2764_ASSET.readall(),
    },
    "P5": {
        "description": "sail",
        "pronunciation": "nfw",
        "src": IMG_dcffd3c8_ASSET.readall(),
    },
    "G2": {
        "description": "two egyptian vultures",
        "pronunciation": "AA",
        "src": IMG_e8476ec5_ASSET.readall(),
    },
    "O44": {
        "description": "emblem of min",
        "src": IMG_ca11937f_ASSET.readall(),
    },
    "O2": {
        "description": "combination of house and mace with round head",
        "src": IMG_1b3199cb_ASSET.readall(),
    },
    "B9": {
        "description": "woman holding sistrum",
        "src": IMG_895d96f7_ASSET.readall(),
    },
    "I4": {
        "description": "crocodileon shrine",
        "pronunciation": "sbk",
        "src": IMG_569cd199_ASSET.readall(),
    },
    "S4": {
        "description": "combination of red crown and basket",
        "src": IMG_07bdf90d_ASSET.readall(),
    },
    "Q6": {
        "description": "sarcophagus",
        "pronunciation": "qrsw",
        "src": IMG_4e0f1694_ASSET.readall(),
    },
    "O43": {
        "description": "low fence",
        "src": IMG_a9f519e8_ASSET.readall(),
    },
    "M34": {
        "description": "ear of emmer",
        "pronunciation": "bdt",
        "src": IMG_d79dc3da_ASSET.readall(),
    },
    "M24": {
        "description": "combination of sedge and mouth",
        "pronunciation": "rsw",
        "src": IMG_f2247be5_ASSET.readall(),
    },
    "O20": {
        "description": "shrine",
        "src": IMG_97d4feb8_ASSET.readall(),
    },
    "G4": {
        "description": "buzzard",
        "pronunciation": "tyw",
        "src": IMG_f9b0147b_ASSET.readall(),
    },
    "Aa2": {
        "description": "pustule",
        "src": IMG_31a3af82_ASSET.readall(),
    },
    "U35": {
        "src": IMG_0becc3f2_ASSET.readall(),
    },
    "N10": {
        "description": "moon with lower section obscured",
        "src": IMG_b39d1af5_ASSET.readall(),
    },
    "U26": {
        "pronunciation": "wbA",
        "src": IMG_727760ce_ASSET.readall(),
    },
    "F10": {
        "description": "head and neck of animal",
        "src": IMG_ccd3f8ed_ASSET.readall(),
    },
    "N24": {
        "description": "irrigation canal system",
        "pronunciation": "spAt",
        "src": IMG_246a30b5_ASSET.readall(),
    },
    "N6": {
        "description": "sun with uraeus",
        "src": IMG_1163726e_ASSET.readall(),
    },
    "O25": {
        "description": "obelisk",
        "pronunciation": "txn",
        "src": IMG_4684cb0c_ASSET.readall(),
    },
    "Aa26": {
        "src": IMG_fbffda36_ASSET.readall(),
    },
    "E17": {
        "description": "jackal",
        "pronunciation": "zAb",
        "src": IMG_715e3b67_ASSET.readall(),
    },
    "N35": {
        "description": "ripple of water",
        "pronunciation": "n",
        "src": IMG_823cfd69_ASSET.readall(),
    },
    "E24": {
        "description": "panther",
        "pronunciation": "Aby",
        "src": IMG_7c2dd155_ASSET.readall(),
    },
    "S14": {
        "description": "combination of collar of beads and mace with round head",
        "src": IMG_68020e2a_ASSET.readall(),
    },
    "Aa31": {
        "src": IMG_be1c6ba9_ASSET.readall(),
    },
    "A25": {
        "description": "man striking, with left arm hanging behind back",
        "src": IMG_6a3df4c6_ASSET.readall(),
    },
    "W13": {
        "description": "pot",
        "src": IMG_5c51e7fd_ASSET.readall(),
    },
    "N2": {
        "description": "sky with sceptre",
        "src": IMG_869d2359_ASSET.readall(),
    },
    "A41": {
        "description": "king with uraeus",
        "src": IMG_f06eb9f0_ASSET.readall(),
    },
    "A8": {
        "description": "man performing hnw-rite",
        "src": IMG_d8694a44_ASSET.readall(),
    },
    "S29": {
        "description": "folded cloth",
        "pronunciation": "s",
        "src": IMG_a706f3d9_ASSET.readall(),
    },
    "G54": {
        "description": "plucked bird",
        "pronunciation": "snD",
        "src": IMG_c1ccf719_ASSET.readall(),
    },
    "X4": {
        "src": IMG_6fb6ab7e_ASSET.readall(),
    },
    "N22": {
        "description": "broad tongue of land",
        "src": IMG_28d72df8_ASSET.readall(),
    },
    "G37": {
        "description": "sparrow",
        "pronunciation": "nDs",
        "src": IMG_480b959a_ASSET.readall(),
    },
    "D20": {
        "description": "nose, eye and cheek (cursive)",
        "src": IMG_f60bad51_ASSET.readall(),
    },
    "Aa6": {
        "src": IMG_15cf424a_ASSET.readall(),
    },
    "H3": {
        "description": "head of spoonbill",
        "pronunciation": "pAq",
        "src": IMG_14094e2e_ASSET.readall(),
    },
    "A26": {
        "description": "man with one arm pointing forward",
        "src": IMG_b7a4784c_ASSET.readall(),
    },
    "P4": {
        "description": "boat with net",
        "pronunciation": "wHa",
        "src": IMG_07d01d90_ASSET.readall(),
    },
    "P8": {
        "description": "oar",
        "pronunciation": "xrw",
        "src": IMG_99218c04_ASSET.readall(),
    },
    "T19": {
        "description": "harpoon head",
        "pronunciation": "qs",
        "src": IMG_938cf6a6_ASSET.readall(),
    },
    "N29": {
        "description": "slope of hill",
        "pronunciation": "q",
        "src": IMG_b9608d96_ASSET.readall(),
    },
    "G13": {
        "description": "image of falcon with two plumes",
        "src": IMG_f1dfb854_ASSET.readall(),
    },
    "Aa24": {
        "src": IMG_eac3b474_ASSET.readall(),
    },
    "M32": {
        "description": "rhizome",
        "src": IMG_06bffb4a_ASSET.readall(),
    },
    "T14": {
        "description": "throw stick vertically",
        "pronunciation": "qmA",
        "src": IMG_2ef5ac7a_ASSET.readall(),
    },
    "F42": {
        "description": "rib",
        "pronunciation": "spr",
        "src": IMG_a1ea5bbd_ASSET.readall(),
    },
    "M14": {
        "description": "combination of papyrus and cobra",
        "src": IMG_5150d223_ASSET.readall(),
    },
    "Z10": {
        "description": "crossed diagonal sticks",
        "src": IMG_48061a86_ASSET.readall(),
    },
    "V1": {
        "pronunciation": "100",
        "src": IMG_a69b645e_ASSET.readall(),
    },
    "R24": {
        "description": "two bows tied horizontally",
        "src": IMG_7efa1414_ASSET.readall(),
    },
    "D3": {
        "description": "hair",
        "pronunciation": "Sny",
        "src": IMG_2ab5b6c2_ASSET.readall(),
    },
    "M38": {
        "description": "wide bundle of flax",
        "src": IMG_de280549_ASSET.readall(),
    },
    "T6": {
        "description": "combination of mace with round head and two cobras",
        "pronunciation": "HDD",
        "src": IMG_aa3e577c_ASSET.readall(),
    },
    "E20": {
        "description": "set-animal",
        "src": IMG_61fff579_ASSET.readall(),
    },
    "F9": {
        "description": "leopardhead",
        "src": IMG_8681794f_ASSET.readall(),
    },
    "U37": {
        "src": IMG_ba97a6f5_ASSET.readall(),
    },
    "O45": {
        "description": "domed building",
        "pronunciation": "ipt",
        "src": IMG_c97e37a6_ASSET.readall(),
    },
    "C8": {
        "description": "ithyphallic god with two plumes, uplifted arm and flagellum",
        "pronunciation": "mnw",
        "src": IMG_ea8274cc_ASSET.readall(),
    },
    "M20": {
        "description": "field of reeds",
        "pronunciation": "sxt",
        "src": IMG_bd13383b_ASSET.readall(),
    },
    "X7": {
        "src": IMG_b88dfca0_ASSET.readall(),
    },
    "M5": {
        "description": "combination of palm branch and flat loaf",
        "src": IMG_6920e471_ASSET.readall(),
    },
    "G24": {
        "description": "lapwing with twisted wings",
        "src": IMG_79253bd6_ASSET.readall(),
    },
    "R22": {
        "description": "two narrow belemnites",
        "pronunciation": "xm",
        "src": IMG_45cf3ab3_ASSET.readall(),
    },
    "S7": {
        "description": "blue crown",
        "pronunciation": "xprS",
        "src": IMG_c045c193_ASSET.readall(),
    },
    "N25": {
        "description": "three hills",
        "pronunciation": "xAst",
        "src": IMG_703768a3_ASSET.readall(),
    },
    "S8": {
        "description": "atefcrown",
        "pronunciation": "Atf",
        "src": IMG_0ab8b389_ASSET.readall(),
    },
    "G47": {
        "description": "duckling",
        "pronunciation": "TA",
        "src": IMG_ae72a9a1_ASSET.readall(),
    },
    "I1": {
        "description": "gecko",
        "pronunciation": "aSA",
        "src": IMG_370f2434_ASSET.readall(),
    },
    "I12": {
        "description": "erect cobra",
        "src": IMG_70fa944c_ASSET.readall(),
    },
    "D24": {
        "description": "upper lip with teeth",
        "pronunciation": "spt",
        "src": IMG_687861d1_ASSET.readall(),
    },
    "G52": {
        "description": "goose picking up grain",
        "src": IMG_e442dd3e_ASSET.readall(),
    },
    "F1": {
        "description": "ox head",
        "src": IMG_d9091970_ASSET.readall(),
    },
    "N23": {
        "description": "irrigation canal",
        "src": IMG_e38ca376_ASSET.readall(),
    },
    "G14": {
        "description": "vulture",
        "pronunciation": "mwt",
        "src": IMG_8d0eb6e0_ASSET.readall(),
    },
    "A53": {
        "description": "standing mummy",
        "src": IMG_f30833b1_ASSET.readall(),
    },
    "D60": {
        "description": "foot under vase from which water flows",
        "pronunciation": "wab",
        "src": IMG_309b59ea_ASSET.readall(),
    },
    "M42": {
        "description": "flower",
        "src": IMG_9881cc52_ASSET.readall(),
    },
    "D46": {
        "description": "hand",
        "pronunciation": "d",
        "src": IMG_74e076dd_ASSET.readall(),
    },
    "A54": {
        "description": "lying mummy",
        "src": IMG_64406e60_ASSET.readall(),
    },
    "E6": {
        "description": "horse",
        "pronunciation": "zzmt",
        "src": IMG_7ad65f89_ASSET.readall(),
    },
    "O26": {
        "description": "stela",
        "src": IMG_823ff7c5_ASSET.readall(),
    },
    "D40": {
        "description": "forearm with stick",
        "src": IMG_91147810_ASSET.readall(),
    },
    "M36": {
        "description": "bundle of flax",
        "pronunciation": "Dr",
        "src": IMG_452bd08b_ASSET.readall(),
    },
    "Y3": {
        "description": "scribe's equipment",
        "pronunciation": "zS",
        "src": IMG_a3524f51_ASSET.readall(),
    },
    "D54": {
        "description": "legs walking",
        "src": IMG_3689b2b1_ASSET.readall(),
    },
    "N21": {
        "description": "short tongue of land",
        "src": IMG_cd26963c_ASSET.readall(),
    },
    "S25": {
        "description": "garment with ties",
        "src": IMG_689dae67_ASSET.readall(),
    },
    "Aa18": {
        "src": IMG_d0b9619a_ASSET.readall(),
    },
    "P1": {
        "description": "boat",
        "src": IMG_c89bb336_ASSET.readall(),
    },
    "N11": {
        "description": "crescent moon",
        "pronunciation": "iaH",
        "src": IMG_6035af7a_ASSET.readall(),
    },
    "H8": {
        "description": "egg",
        "src": IMG_e7eb032f_ASSET.readall(),
    },
    "Aa17": {
        "pronunciation": "sA",
        "src": IMG_3be58edf_ASSET.readall(),
    },
    "I3": {
        "description": "crocodile",
        "pronunciation": "mzH",
        "src": IMG_ef43b180_ASSET.readall(),
    },
    "N15": {
        "description": "star in circle",
        "pronunciation": "dwAt",
        "src": IMG_b4f809bd_ASSET.readall(),
    },
    "D56": {
        "description": "leg",
        "pronunciation": "sbq",
        "src": IMG_a5ef8a55_ASSET.readall(),
    },
    "A32": {
        "description": "man dancing with arms to the back",
        "src": IMG_e6c2ff8b_ASSET.readall(),
    },
    "S2": {
        "description": "combination of white crown and basket",
        "src": IMG_617e3376_ASSET.readall(),
    },
    "X8": {
        "description": "cone-shapedbread",
        "pronunciation": "rdi",
        "src": IMG_966ee5ef_ASSET.readall(),
    },
    "S32": {
        "description": "cloth with fringe on the side",
        "pronunciation": "siA",
        "src": IMG_1e9f4a4d_ASSET.readall(),
    },
    "V26": {
        "pronunciation": "aD",
        "src": IMG_b15394b8_ASSET.readall(),
    },
    "G44": {
        "description": "two quail chicks",
        "pronunciation": "ww",
        "src": IMG_172d7960_ASSET.readall(),
    },
    "F48": {
        "description": "intestine",
        "src": IMG_f7ddb85d_ASSET.readall(),
    },
    "S6": {
        "description": "combination of pschent crown and basket",
        "pronunciation": "sxmty",
        "src": IMG_110fba65_ASSET.readall(),
    },
    "O15": {
        "description": "enclosure with cup and flat loaf",
        "pronunciation": "wsxt",
        "src": IMG_8b2af50a_ASSET.readall(),
    },
    "O34": {
        "description": "door bolt",
        "pronunciation": "z",
        "src": IMG_dfdb77d3_ASSET.readall(),
    },
    "A19": {
        "description": "bent man leaning on staff",
        "src": IMG_aee23005_ASSET.readall(),
    },
    "U4": {
        "src": IMG_762de6e4_ASSET.readall(),
    },
    "Z6": {
        "description": "substitute for various human figures",
        "src": IMG_0b962aec_ASSET.readall(),
    },
    "G51": {
        "description": "bird pecking at fish",
        "src": IMG_24898055_ASSET.readall(),
    },
    "V32": {
        "pronunciation": "msn",
        "src": IMG_e413ee45_ASSET.readall(),
    },
    "F31": {
        "description": "three skins tied together",
        "pronunciation": "ms",
        "src": IMG_8ae09cef_ASSET.readall(),
    },
    "O49": {
        "description": "village",
        "pronunciation": "niwt",
        "src": IMG_827688aa_ASSET.readall(),
    },
    "M7": {
        "description": "combination of palm branch and stool",
        "src": IMG_9c800b41_ASSET.readall(),
    },
    "B7": {
        "description": "queen wearing diadem and holding flower",
        "src": IMG_fa25b45a_ASSET.readall(),
    },
    "N1": {
        "description": "sky",
        "pronunciation": "pt",
        "src": IMG_13dc43f6_ASSET.readall(),
    },
    "A17": {
        "description": "child sitting with hand to mouth",
        "pronunciation": "Xrd",
        "src": IMG_07ffbdf4_ASSET.readall(),
    },
    "F12": {
        "description": "head and neck of animal",
        "pronunciation": "wsr",
        "src": IMG_89d2690b_ASSET.readall(),
    },
    "C7": {
        "description": "god with seth-animal head",
        "pronunciation": "stX",
        "src": IMG_04434350_ASSET.readall(),
    },
    "V11": {
        "description": "cartouche-(divided)",
        "src": IMG_3c17f2a9_ASSET.readall(),
    },
    "E34": {
        "description": "hare",
        "pronunciation": "wn",
        "src": IMG_11c138da_ASSET.readall(),
    },
    "N13": {
        "description": "combination of crescent moon and star",
        "src": IMG_c4b127ff_ASSET.readall(),
    },
    "G50": {
        "description": "two plovers",
        "src": IMG_bf19dd78_ASSET.readall(),
    },
    "F35": {
        "description": "heart andwindpipe",
        "pronunciation": "nfr",
        "src": IMG_5b140f45_ASSET.readall(),
    },
    "G28": {
        "description": "glossy ibis",
        "pronunciation": "gm",
        "src": IMG_297c2776_ASSET.readall(),
    },
    "H4": {
        "description": "head of vulture",
        "pronunciation": "nr",
        "src": IMG_cb481684_ASSET.readall(),
    },
    "A44": {
        "description": "king wearing white crown with flagellum",
        "src": IMG_6b2a7f4f_ASSET.readall(),
    },
    "F22": {
        "description": "hind-quarters of lion",
        "pronunciation": "pH",
        "src": IMG_70a5bedb_ASSET.readall(),
    },
    "U29": {
        "src": IMG_8f562a2b_ASSET.readall(),
    },
    "H2": {
        "description": "head of crested bird",
        "pronunciation": "wSm",
        "src": IMG_d915c1cd_ASSET.readall(),
    },
    "K1": {
        "description": "tilapia",
        "pronunciation": "in",
        "src": IMG_4c58f050_ASSET.readall(),
    },
    "O12": {
        "description": "combination of palace and forearm",
        "src": IMG_dac7a178_ASSET.readall(),
    },
    "U14": {
        "src": IMG_84dc606f_ASSET.readall(),
    },
    "Aa15": {
        "pronunciation": "M",
        "src": IMG_b4852408_ASSET.readall(),
    },
    "O9": {
        "description": "combination of enclosure, flat loaf and basket",
        "src": IMG_7d085f78_ASSET.readall(),
    },
    "D4": {
        "description": "eye",
        "pronunciation": "ir",
        "src": IMG_a3f9ab2c_ASSET.readall(),
    },
    "O17": {
        "description": "open gateway with serpents",
        "src": IMG_52679821_ASSET.readall(),
    },
    "G3": {
        "description": "combination of egyptian vulture and sickle",
        "src": IMG_71378d17_ASSET.readall(),
    },
    "I15": {
        "description": "snake",
        "src": IMG_e1b90338_ASSET.readall(),
    },
    "V28": {
        "description": "a twisted wick",
        "pronunciation": "H",
        "src": IMG_be10853e_ASSET.readall(),
    },
    "A2": {
        "description": "man with hand to mouth",
        "src": IMG_46f2987e_ASSET.readall(),
    },
    "U24": {
        "description": "handdrill(hieroglyph)",
        "pronunciation": "Hmt",
        "src": IMG_a50e9dee_ASSET.readall(),
    },
    "U38": {
        "description": "scale",
        "pronunciation": "mxAt",
        "src": IMG_0a48a832_ASSET.readall(),
    },
    "X1": {
        "description": "loaf of bread",
        "pronunciation": "t",
        "src": IMG_599f6e96_ASSET.readall(),
    },
    "R23": {
        "description": "two broad belemnites",
        "src": IMG_a4a3de76_ASSET.readall(),
    },
    "F19": {
        "description": "lower jaw-bone of ox",
        "src": IMG_72d62d91_ASSET.readall(),
    },
    "W6": {
        "description": "metal vessel",
        "src": IMG_0d982481_ASSET.readall(),
    },
    "D36": {
        "description": "forearm (palm upwards)",
        "pronunciation": "a",
        "src": IMG_c0add213_ASSET.readall(),
    },
    "Aa29": {
        "src": IMG_adb6d241_ASSET.readall(),
    },
    "U8": {
        "src": IMG_49de40ec_ASSET.readall(),
    },
    "T28": {
        "description": "butcher's block",
        "pronunciation": "Xr",
        "src": IMG_498e0f8c_ASSET.readall(),
    },
    "F49": {
        "description": "intestine",
        "src": IMG_52084135_ASSET.readall(),
    },
    "U31": {
        "pronunciation": "rtH",
        "src": IMG_5cc234b0_ASSET.readall(),
    },
    "V33": {
        "pronunciation": "sSr",
        "src": IMG_6b2b50f1_ASSET.readall(),
    },
    "W5": {
        "src": IMG_b4d48c11_ASSET.readall(),
    },
    "E4": {
        "description": "sacred cow",
        "src": IMG_6a26c76e_ASSET.readall(),
    },
    "Z5": {
        "description": "diagonal stroke (from hieratic)",
        "src": IMG_f17d8ea9_ASSET.readall(),
    },
    "Aa13": {
        "pronunciation": "im",
        "src": IMG_66f0b5d7_ASSET.readall(),
    },
    "O36": {
        "description": "wall",
        "pronunciation": "inb",
        "src": IMG_07b5eed3_ASSET.readall(),
    },
    "R6": {
        "description": "broad censer",
        "src": IMG_fc08e88a_ASSET.readall(),
    },
    "E23": {
        "description": "lying lion",
        "pronunciation": "rw",
        "src": IMG_e7f5209d_ASSET.readall(),
    },
    "E27": {
        "description": "giraffe",
        "src": IMG_471b6c2b_ASSET.readall(),
    },
    "E19": {
        "description": "wolf on standard with mace",
        "src": IMG_174d040c_ASSET.readall(),
    },
    "G5": {
        "description": "falcon",
        "src": IMG_67edffe0_ASSET.readall(),
    },
    "S24": {
        "description": "girdle knot",
        "pronunciation": "Tz",
        "src": IMG_a2f88b9a_ASSET.readall(),
    },
    "W19": {
        "description": "milk jug with handle",
        "pronunciation": "mi",
        "src": IMG_9dfb4b7a_ASSET.readall(),
    },
    "T30": {
        "description": "knife",
        "src": IMG_c625bdbd_ASSET.readall(),
    },
    "W24": {
        "description": "pot",
        "pronunciation": "nw",
        "src": IMG_7b7c536a_ASSET.readall(),
    },
    "D52": {
        "description": "phallus",
        "pronunciation": "mt",
        "src": IMG_9ef2a01f_ASSET.readall(),
    },
    "O4": {
        "description": "shelter",
        "pronunciation": "h",
        "src": IMG_cf975423_ASSET.readall(),
    },
    "D31": {
        "description": "arms embracing club",
        "src": IMG_d0e0e290_ASSET.readall(),
    },
    "H5": {
        "description": "wing",
        "src": IMG_c20e5c1b_ASSET.readall(),
    },
    "E28": {
        "description": "oryx",
        "src": IMG_5e8b0847_ASSET.readall(),
    },
    "S13": {
        "description": "combination of collar of beads and foot",
        "src": IMG_9f50f7cb_ASSET.readall(),
    },
    "A1": {
        "description": "seated man",
        "src": IMG_760bad1e_ASSET.readall(),
    },
    "C5": {
        "description": "god with ram head holding ankh",
        "src": IMG_52e8ed02_ASSET.readall(),
    },
    "D55": {
        "description": "legs walking backwards",
        "src": IMG_e889b829_ASSET.readall(),
    },
    "M23": {
        "description": "sedge",
        "pronunciation": "sw",
        "src": IMG_2d2d2f98_ASSET.readall(),
    },
    "A56": {
        "description": "seated man holding stick",
        "src": IMG_f2acacc2_ASSET.readall(),
    },
    "R18": {
        "description": "combination of wig on pole and irrigation canal system",
        "src": IMG_0134f045_ASSET.readall(),
    },
    "R1": {
        "description": "high table with offerings",
        "pronunciation": "xAwt",
        "src": IMG_c3e477eb_ASSET.readall(),
    },
    "C12": {
        "description": "god with two plumes and scepter",
        "src": IMG_97427986_ASSET.readall(),
    },
    "T35": {
        "description": "butcher's knife",
        "src": IMG_a81ccff0_ASSET.readall(),
    },
    "S21": {
        "description": "ring",
        "src": IMG_b7e7afb9_ASSET.readall(),
    },
    "E3": {
        "description": "calf",
        "src": IMG_aecff2d5_ASSET.readall(),
    },
    "R3": {
        "description": "low table with offerings",
        "src": IMG_fe321946_ASSET.readall(),
    },
    "Y4": {
        "description": "scribe's equipment",
        "src": IMG_62fd6143_ASSET.readall(),
    },
    "R5": {
        "description": "narrow censer",
        "pronunciation": "kp",
        "src": IMG_29396c5b_ASSET.readall(),
    },
    "M15": {
        "description": "clump of papyrus with buds",
        "src": IMG_6c7fb50c_ASSET.readall(),
    },
    "A15": {
        "description": "man falling",
        "pronunciation": "xr",
        "src": IMG_996147db_ASSET.readall(),
    },
    "Aa9": {
        "src": IMG_ba8eea94_ASSET.readall(),
    },
    "E2": {
        "description": "bull charging",
        "src": IMG_aaf58365_ASSET.readall(),
    },
    "U41": {
        "description": "plummet",
        "src": IMG_d65b5c68_ASSET.readall(),
    },
    "A37": {
        "description": "man in vessel",
        "src": IMG_8b3a201c_ASSET.readall(),
    },
    "M2": {
        "description": "plant",
        "pronunciation": "Hn",
        "src": IMG_95e740a7_ASSET.readall(),
    },
    "D61": {
        "description": "three toes oriented leftward",
        "pronunciation": "sAH",
        "src": IMG_75355232_ASSET.readall(),
    },
    "G43": {
        "description": "quail chick",
        "pronunciation": "w",
        "src": IMG_ae1176dc_ASSET.readall(),
    },
    "A39": {
        "description": "man on two giraffes",
        "src": IMG_0d742789_ASSET.readall(),
    },
    "X3": {
        "src": IMG_83f54f9e_ASSET.readall(),
    },
    "U12": {
        "src": IMG_8ab13b3f_ASSET.readall(),
    },
    "R21": {
        "description": "flower with horns",
        "src": IMG_f48bbf75_ASSET.readall(),
    },
    "D59": {
        "description": "foot and forearm",
        "pronunciation": "ab",
        "src": IMG_c36816d3_ASSET.readall(),
    },
    "V38": {
        "src": IMG_b6da2c76_ASSET.readall(),
    },
    "N20": {
        "description": "tongue of land",
        "pronunciation": "wDb",
        "src": IMG_282a2392_ASSET.readall(),
    },
    "U36": {
        "description": "fuller's-club",
        "pronunciation": "Hm",
        "src": IMG_91912432_ASSET.readall(),
    },
    "E32": {
        "description": "baboon",
        "src": IMG_c09ee311_ASSET.readall(),
    },
    "G1": {
        "description": "egyptian vulture",
        "pronunciation": "A",
        "src": IMG_232f67c2_ASSET.readall(),
    },
    "U3": {
        "src": IMG_68a98eea_ASSET.readall(),
    },
    "U33": {
        "description": "'pestle'-(curved top)",
        "pronunciation": "ti",
        "src": IMG_fa590a9b_ASSET.readall(),
    },
    "V30": {
        "description": "basket(hieroglyph)",
        "pronunciation": "nb",
        "src": IMG_cebec140_ASSET.readall(),
    },
    "F36": {
        "description": "lung and windpipe",
        "pronunciation": "zmA",
        "src": IMG_5781da1e_ASSET.readall(),
    },
    "I7": {
        "description": "frog",
        "src": IMG_dc398827_ASSET.readall(),
    },
    "Aa14": {
        "src": IMG_0223330d_ASSET.readall(),
    },
    "S37": {
        "description": "fan",
        "pronunciation": "xw",
        "src": IMG_a2bcc986_ASSET.readall(),
    },
    "S26": {
        "description": "apron",
        "pronunciation": "Sndyt",
        "src": IMG_c7539a0b_ASSET.readall(),
    },
    "S36": {
        "description": "sunshade",
        "src": IMG_81765d2e_ASSET.readall(),
    },
    "F13": {
        "description": "horns",
        "pronunciation": "wp",
        "src": IMG_1e557a50_ASSET.readall(),
    },
    "O40": {
        "description": "stair single",
        "src": IMG_89a50395_ASSET.readall(),
    },
    "U13": {
        "pronunciation": "hb",
        "src": IMG_f277f5e3_ASSET.readall(),
    },
    "F5": {
        "description": "hartebeest head",
        "pronunciation": "SsA",
        "src": IMG_c7b19548_ASSET.readall(),
    },
    "K2": {
        "description": "barbel",
        "src": IMG_f17b885e_ASSET.readall(),
    },
    "B12": {
        "src": IMG_b0356bdf_ASSET.readall(),
    },
    "F23": {
        "description": "forelegof ox",
        "pronunciation": "xpS",
        "src": IMG_d9522c21_ASSET.readall(),
    },
    "Aa20": {
        "pronunciation": "apr",
        "src": IMG_fb3b5855_ASSET.readall(),
    },
    "A45": {
        "description": "king wearing red crown",
        "src": IMG_73f8d956_ASSET.readall(),
    },
    "F37": {
        "description": "backbone and ribs and spinal cord",
        "src": IMG_db5ce17e_ASSET.readall(),
    },
    "A13": {
        "description": "man with arms tied behind his back",
        "src": IMG_76f2c910_ASSET.readall(),
    },
    "N7": {
        "description": "combination of sun and butcher's block",
        "src": IMG_d9ebda65_ASSET.readall(),
    },
    "W15": {
        "description": "water jar with rack",
        "src": IMG_6720c7ca_ASSET.readall(),
    },
    "D18": {
        "description": "ear",
        "src": IMG_0961c734_ASSET.readall(),
    },
    "B10": {
        "src": IMG_6abb445b_ASSET.readall(),
    },
    "D26": {
        "description": "liquid issuing from lips",
        "src": IMG_65f98131_ASSET.readall(),
    },
    "V15": {
        "description": "tethering rope w/ walking legs",
        "pronunciation": "iTi",
        "src": IMG_675dce10_ASSET.readall(),
    },
    "C6": {
        "description": "god with jackal head",
        "pronunciation": "inpw",
        "src": IMG_38f63128_ASSET.readall(),
    },
    "D30": {
        "description": "two arms upraised with tail",
        "src": IMG_badc7377_ASSET.readall(),
    },
    "Aa5": {
        "description": "part of steering gear of a ship",
        "pronunciation": "Hp",
        "src": IMG_0f30f8e4_ASSET.readall(),
    },
    "G41": {
        "description": "pintail alighting",
        "pronunciation": "xn",
        "src": IMG_48cdbcde_ASSET.readall(),
    },
    "V34": {
        "src": IMG_034b174f_ASSET.readall(),
    },
    "T11": {
        "description": "arrow",
        "pronunciation": "zwn",
        "src": IMG_5c6a451e_ASSET.readall(),
    },
    "A21": {
        "description": "man holding staff with handkerchief",
        "pronunciation": "sr",
        "src": IMG_fc1f8780_ASSET.readall(),
    },
    "D22": {
        "description": "mouth with two strokes",
        "src": IMG_93729b9c_ASSET.readall(),
    },
    "U6": {
        "pronunciation": "mr",
        "src": IMG_cf357682_ASSET.readall(),
    },
    "P2": {
        "description": "ship under sail",
        "src": IMG_d7f039a9_ASSET.readall(),
    },
    "L4": {
        "description": "locust",
        "src": IMG_8b21b696_ASSET.readall(),
    },
    "D34": {
        "description": "armswith shieldand battle axe",
        "pronunciation": "aHA",
        "src": IMG_6ce98993_ASSET.readall(),
    },
    "P7": {
        "description": "combination of mast and forearm",
        "src": IMG_8f647f9a_ASSET.readall(),
    },
    "G36": {
        "description": "swallow",
        "pronunciation": "wr",
        "src": IMG_2128119d_ASSET.readall(),
    },
    "N16": {
        "description": "land with grains",
        "pronunciation": "tA",
        "src": IMG_c80d53eb_ASSET.readall(),
    },
    "O21": {
        "description": "façade of shrine",
        "src": IMG_ea5b5176_ASSET.readall(),
    },
    "Aa10": {
        "src": IMG_f051302d_ASSET.readall(),
    },
    "M8": {
        "description": "pool with lotus flowers",
        "pronunciation": "SA",
        "src": IMG_32541540_ASSET.readall(),
    },
    "A46": {
        "description": "king wearing red crown with flagellum",
        "src": IMG_2478bc8f_ASSET.readall(),
    },
    "C3": {
        "description": "god with ibis head",
        "pronunciation": "DHwty",
        "src": IMG_2902de7a_ASSET.readall(),
    },
    "G26": {
        "description": "sacred ibis on standard",
        "src": IMG_fb45261c_ASSET.readall(),
    },
    "B1": {
        "description": "seated woman",
        "src": IMG_19d7560a_ASSET.readall(),
    },
    "S23": {
        "description": "two whipswith shen ring",
        "pronunciation": "dmD",
        "src": IMG_e766f860_ASSET.readall(),
    },
    "B2": {
        "description": "pregnant woman",
        "src": IMG_6eec4ee8_ASSET.readall(),
    },
    "A12": {
        "description": "soldier with bow and quiver",
        "pronunciation": "mSa",
        "src": IMG_7c556398_ASSET.readall(),
    },
    "G34": {
        "description": "ostrich",
        "src": IMG_a41e8fe2_ASSET.readall(),
    },
    "C2": {
        "description": "god with falcon head and sun-disk holding ankh",
        "src": IMG_074a4edd_ASSET.readall(),
    },
    "N14": {
        "description": "star",
        "pronunciation": "sbA",
        "src": IMG_458199f8_ASSET.readall(),
    },
    "F51": {
        "description": "piece of flesh",
        "src": IMG_6069b53e_ASSET.readall(),
    },
    "D6": {
        "description": "eye with painted upper lid",
        "src": IMG_08c1c849_ASSET.readall(),
    },
    "F14": {
        "description": "horns with palm branch",
        "src": IMG_28481765_ASSET.readall(),
    },
    "Aa23": {
        "src": IMG_7b12ddea_ASSET.readall(),
    },
    "C18": {
        "description": "squatting god",
        "src": IMG_a67b9607_ASSET.readall(),
    },
    "V5": {
        "pronunciation": "snT",
        "src": IMG_56b70cc9_ASSET.readall(),
    },
    "P6": {
        "description": "mast",
        "pronunciation": "aHa",
        "src": IMG_74caf14a_ASSET.readall(),
    },
    "G15": {
        "description": "combination of vulture and flagellum",
        "src": IMG_56834d4a_ASSET.readall(),
    },
    "A40": {
        "description": "seated god",
        "src": IMG_c8f1bed5_ASSET.readall(),
    },
    "F41": {
        "description": "vertebrae",
        "src": IMG_132c5f8c_ASSET.readall(),
    },
    "V8": {
        "src": IMG_5fca5056_ASSET.readall(),
    },
    "A20": {
        "description": "man leaning on forked staff",
        "src": IMG_4a8f022c_ASSET.readall(),
    },
    "E16": {
        "description": "lying canine on shrine",
        "src": IMG_2a85852e_ASSET.readall(),
    },
    "G16": {
        "description": "vulture and cobra each on a basket",
        "pronunciation": "nbty",
        "src": IMG_bf21e3d5_ASSET.readall(),
    },
    "A24": {
        "description": "man striking with both hands",
        "src": IMG_1c96365c_ASSET.readall(),
    },
    "E12": {
        "description": "pig",
        "src": IMG_c9cc8c39_ASSET.readall(),
    },
    "Z93": {
        "src": IMG_d780ad72_ASSET.readall(),
    },
    "T10": {
        "description": "composite bow",
        "pronunciation": "pD",
        "src": IMG_11df83fb_ASSET.readall(),
    },
    "D41": {
        "description": "forearm with palm down and bent upper arm",
        "src": IMG_f6a03fb4_ASSET.readall(),
    },
    "V21": {
        "description": "fetter + cobra",
        "src": IMG_b5afa141_ASSET.readall(),
    },
    "U23": {
        "description": "chisel",
        "pronunciation": "Ab",
        "src": IMG_baebf6f6_ASSET.readall(),
    },
    "N42": {
        "description": "well with line of water",
        "src": IMG_9f123a17_ASSET.readall(),
    },
    "I8": {
        "description": "tadpole",
        "pronunciation": "Hfn",
        "src": IMG_a4d433df_ASSET.readall(),
    },
    "C20": {
        "description": "mummy-shaped god in shrine",
        "src": IMG_9fa69b18_ASSET.readall(),
    },
    "D8": {
        "description": "eye enclosed in sandy tract",
        "src": IMG_0396571f_ASSET.readall(),
    },
    "A14": {
        "description": "falling man with blood streaming from his head",
        "src": IMG_430c93ee_ASSET.readall(),
    },
    "S33": {
        "description": "sandal",
        "pronunciation": "Tb",
        "src": IMG_1dab1231_ASSET.readall(),
    },
    "S10": {
        "description": "headband",
        "pronunciation": "mDH",
        "src": IMG_dd08c850_ASSET.readall(),
    },
    "M13": {
        "description": "papyrusstem",
        "pronunciation": "wAD",
        "src": IMG_f5d8cdab_ASSET.readall(),
    },
    "A7": {
        "description": "fatigued man",
        "src": IMG_93722909_ASSET.readall(),
    },
    "W9": {
        "description": "stone jug",
        "pronunciation": "Xnm",
        "src": IMG_67e0a673_ASSET.readall(),
    },
    "D39": {
        "description": "forearm with bowl",
        "src": IMG_4b250737_ASSET.readall(),
    },
    "A48": {
        "description": "beardless man seated and holding knife",
        "src": IMG_70b5f256_ASSET.readall(),
    },
    "U25": {
        "src": IMG_03c241e6_ASSET.readall(),
    },
    "D63": {
        "description": "two toes oriented leftward",
        "src": IMG_3b322496_ASSET.readall(),
    },
    "D5": {
        "description": "eye touched up with paint",
        "src": IMG_36a7d2e9_ASSET.readall(),
    },
    "G38": {
        "description": "white-fronted goose",
        "pronunciation": "gb",
        "src": IMG_ff58e14c_ASSET.readall(),
    },
    "O10": {
        "description": "combination of enclosure and falcon",
        "src": IMG_a9ec4905_ASSET.readall(),
    },
    "U5": {
        "src": IMG_2b297f3b_ASSET.readall(),
    },
    "N38": {
        "description": "deep pool",
        "src": IMG_9d0cb6e6_ASSET.readall(),
    },
    "W23": {
        "description": "beer jug",
        "src": IMG_140cc880_ASSET.readall(),
    },
    "U40": {
        "description": "a support-(to lift)",
        "src": IMG_bad08ff1_ASSET.readall(),
    },
    "C1": {
        "description": "god with sun-disk and uraeus",
        "src": IMG_c107c209_ASSET.readall(),
    },
    "H7": {
        "description": "claw",
        "src": IMG_cf608b11_ASSET.readall(),
    },
    "V10": {
        "description": "cartouche",
        "src": IMG_16d53a37_ASSET.readall(),
    },
    "V3": {
        "pronunciation": "sTAw",
        "src": IMG_074d26a8_ASSET.readall(),
    },
    "F38": {
        "description": "backbone and ribs",
        "src": IMG_cb479ad9_ASSET.readall(),
    },
    "O30": {
        "description": "support",
        "pronunciation": "zxnt",
        "src": IMG_f9f56699_ASSET.readall(),
    },
    "A3": {
        "description": "man sitting on heel",
        "src": IMG_350a40f8_ASSET.readall(),
    },
    "S39": {
        "description": "shepherd's crook",
        "pronunciation": "awt",
        "src": IMG_5506d1fe_ASSET.readall(),
    },
    "F28": {
        "description": "skin of cow with straight tail",
        "src": IMG_6ad91cc8_ASSET.readall(),
    },
    "N18": {
        "description": "sandy tract",
        "pronunciation": "iw",
        "src": IMG_bc730909_ASSET.readall(),
    },
    "S27": {
        "description": "cloth with two strands",
        "pronunciation": "mnxt",
        "src": IMG_b15ca726_ASSET.readall(),
    },
    "T9": {
        "description": "bow",
        "pronunciation": "pd",
        "src": IMG_e5a08972_ASSET.readall(),
    },
    "R4": {
        "description": "loaf on mat",
        "pronunciation": "Htp",
        "src": IMG_63714c7c_ASSET.readall(),
    },
    "W4": {
        "description": "festival chamber, (the tail is also vertical 'great': ꜥꜣ)",
        "src": IMG_7b96e86f_ASSET.readall(),
    },
    "V37": {
        "pronunciation": "idr",
        "src": IMG_379f3d23_ASSET.readall(),
    },
    "U34": {
        "pronunciation": "xsf",
        "src": IMG_0f7a00f7_ASSET.readall(),
    },
    "V36": {
        "description": "doubled container(or-added-glyphs)many spellings",
        "src": IMG_bab6af08_ASSET.readall(),
    },
    "O22": {
        "description": "booth with pole",
        "pronunciation": "zH",
        "src": IMG_f178ab41_ASSET.readall(),
    },
    "A52": {
        "description": "noble squatting with flagellum",
        "src": IMG_0a5e366b_ASSET.readall(),
    },
    "T1": {
        "description": "mace with flat head",
        "src": IMG_09cbe74b_ASSET.readall(),
    },
    "A38": {
        "description": "man holding necks of two emblematic animals with panther heads",
        "pronunciation": "qiz",
        "src": IMG_579f989f_ASSET.readall(),
    },
    "F39": {
        "description": "backbone and spinal cord",
        "pronunciation": "imAx",
        "src": IMG_ce20ae85_ASSET.readall(),
    },
    "N26": {
        "description": "two hills",
        "pronunciation": "Dw",
        "src": IMG_803fc2bb_ASSET.readall(),
    },
    "U39": {
        "src": IMG_b0dabd3f_ASSET.readall(),
    },
    "G18": {
        "description": "two owls",
        "pronunciation": "mm",
        "src": IMG_d4676a68_ASSET.readall(),
    },
    "G25": {
        "description": "northern bald ibis",
        "pronunciation": "Ax",
        "src": IMG_10d2a078_ASSET.readall(),
    },
    "M10": {
        "description": "lotus bud with straight stem",
        "src": IMG_9be91478_ASSET.readall(),
    },
    "O37": {
        "description": "falling wall",
        "src": IMG_7d209502_ASSET.readall(),
    },
    "U17": {
        "description": "pick, opening earth",
        "pronunciation": "grg",
        "src": IMG_04c0e157_ASSET.readall(),
    },
    "F4": {
        "description": "forepart of lion",
        "pronunciation": "HAt",
        "src": IMG_e8e5104d_ASSET.readall(),
    },
    "S40": {
        "description": "wꜣssceptre(uꜣs)",
        "pronunciation": "wAs",
        "src": IMG_d7b750bf_ASSET.readall(),
    },
    "S22": {
        "description": "shoulder-knot",
        "pronunciation": "sT",
        "src": IMG_5ffabaca_ASSET.readall(),
    },
    "Aa8": {
        "description": "irrigation tunnels",
        "pronunciation": "qn",
        "src": IMG_26c8444d_ASSET.readall(),
    },
    "E9": {
        "description": "newborn hartebeest",
        "src": IMG_d20691d6_ASSET.readall(),
    },
    "T21": {
        "description": "harpoon",
        "pronunciation": "wa",
        "src": IMG_82a21c1e_ASSET.readall(),
    },
    "Aa19": {
        "src": IMG_507dadd7_ASSET.readall(),
    },
    "A55": {
        "description": "mummy on bed",
        "src": IMG_7028c206_ASSET.readall(),
    },
    "G32": {
        "description": "heron on perch",
        "pronunciation": "baHi",
        "src": IMG_a96d4d58_ASSET.readall(),
    },
    "Q2": {
        "description": "carryingchair",
        "pronunciation": "wz",
        "src": IMG_a84e0dea_ASSET.readall(),
    },
    "I2": {
        "description": "turtle",
        "pronunciation": "Styw",
        "src": IMG_eb36dbae_ASSET.readall(),
    },
    "Z2": {
        "description": "plural stroke (horizontal)",
        "src": IMG_fab6d7ed_ASSET.readall(),
    },
    "M1": {
        "description": "tree",
        "pronunciation": "iAm",
        "src": IMG_70aad8a0_ASSET.readall(),
    },
    "V17": {
        "description": "lifesaver",
        "src": IMG_599a57cf_ASSET.readall(),
    },
    "N33": {
        "description": "grain",
        "src": IMG_43125459_ASSET.readall(),
    },
    "W3": {
        "description": "alabasterbasin",
        "pronunciation": "Hb",
        "src": IMG_6f21b6b9_ASSET.readall(),
    },
    "I10": {
        "description": "cobra",
        "pronunciation": "D",
        "src": IMG_0a0e7869_ASSET.readall(),
    },
    "I13": {
        "description": "erect cobra on basket",
        "src": IMG_19ba119e_ASSET.readall(),
    },
    "D49": {
        "description": "fist",
        "src": IMG_591dded2_ASSET.readall(),
    },
    "O24": {
        "description": "pyramid",
        "src": IMG_d8e80f25_ASSET.readall(),
    },
    "W7": {
        "description": "granite bowl",
        "src": IMG_03483cda_ASSET.readall(),
    },
    "O3": {
        "description": "combination of house, oar, tall loaf and beer jug",
        "src": IMG_42a08925_ASSET.readall(),
    },
    "D28": {
        "description": "two arms upraised",
        "pronunciation": "kA",
        "src": IMG_3bc61315_ASSET.readall(),
    },
    "M27": {
        "description": "combination of flowering sedge and forearm",
        "src": IMG_d8386be2_ASSET.readall(),
    },
    "K3": {
        "description": "mullet",
        "pronunciation": "ad",
        "src": IMG_4d307700_ASSET.readall(),
    },
    "R8": {
        "description": "cloth on pole",
        "pronunciation": "nTr",
        "src": IMG_9862881a_ASSET.readall(),
    },
    "V24": {
        "pronunciation": "wD",
        "src": IMG_bfaf920e_ASSET.readall(),
    },
    "T3": {
        "description": "mace with round head",
        "pronunciation": "HD",
        "src": IMG_8372bbe9_ASSET.readall(),
    },
    "E31": {
        "description": "goat with collar",
        "src": IMG_a16c663b_ASSET.readall(),
    },
    "R25": {
        "description": "two bows tied vertically",
        "src": IMG_d251d4ec_ASSET.readall(),
    },
    "D33": {
        "description": "arms rowing",
        "src": IMG_44681079_ASSET.readall(),
    },
    "U19": {
        "src": IMG_23fa531a_ASSET.readall(),
    },
    "V4": {
        "description": "lasso",
        "pronunciation": "wA",
        "src": IMG_80aa7ecb_ASSET.readall(),
    },
    "D11": {
        "description": "left part of the eye of horus",
        "src": IMG_eba4f7af_ASSET.readall(),
    },
    "W12": {
        "description": "jar stand",
        "src": IMG_9a058359_ASSET.readall(),
    },
    "F46": {
        "description": "intestine",
        "pronunciation": "qAb",
        "src": IMG_e7e387b0_ASSET.readall(),
    },
    "F15": {
        "description": "horns with palm branch and sun",
        "src": IMG_604b3dd9_ASSET.readall(),
    },
    "A47": {
        "description": "shepherd seated and wrapped in mantle, holding stick",
        "pronunciation": "iry",
        "src": IMG_6526a9b4_ASSET.readall(),
    },
    "G17": {
        "description": "owl",
        "pronunciation": "m",
        "src": IMG_9858f545_ASSET.readall(),
    },
    "X2": {
        "src": IMG_95f89119_ASSET.readall(),
    },
    "O5": {
        "description": "winding wall from upper-left corner",
        "src": IMG_cd7d449b_ASSET.readall(),
    },
    "D23": {
        "description": "mouth with three strokes",
        "src": IMG_4aaff14f_ASSET.readall(),
    },
    "D50": {
        "description": "one finger",
        "pronunciation": "Dba",
        "src": IMG_4aa75eca_ASSET.readall(),
    },
    "D25": {
        "description": "lips",
        "pronunciation": "spty",
        "src": IMG_f80c8052_ASSET.readall(),
    },
    "E29": {
        "description": "gazelle",
        "src": IMG_7d06db15_ASSET.readall(),
    },
    "G53": {
        "description": "human-headed bird with bowl with smoke",
        "src": IMG_520bcdde_ASSET.readall(),
    },
    "U20": {
        "src": IMG_9d957189_ASSET.readall(),
    },
    "N40": {
        "description": "poolwith legs",
        "pronunciation": "Sm",
        "src": IMG_378c1e9e_ASSET.readall(),
    },
    "K7": {
        "description": "puffer",
        "src": IMG_bf47aac7_ASSET.readall(),
    },
    "F43": {
        "description": "ribs",
        "src": IMG_21c3ac07_ASSET.readall(),
    },
    "N19": {
        "description": "two sandy tracts",
        "src": IMG_af5b008f_ASSET.readall(),
    },
    "Z7": {
        "description": "coil(hieratic equivalent)",
        "pronunciation": "W",
        "src": IMG_5bdff873_ASSET.readall(),
    },
    "E8": {
        "description": "kid",
        "src": IMG_cdd2f8cc_ASSET.readall(),
    },
    "D37": {
        "description": "forearm with bread cone",
        "src": IMG_507ec9aa_ASSET.readall(),
    },
    "W21": {
        "description": "wine jars",
        "src": IMG_12e89e37_ASSET.readall(),
    },
    "Aa7": {
        "description": "a smiting-blade",
        "src": IMG_5e2ce9d2_ASSET.readall(),
    },
    "P9": {
        "description": "combination of oar and horned viper",
        "src": IMG_f35d2c15_ASSET.readall(),
    },
    "W25": {
        "description": "pot with legs",
        "pronunciation": "ini",
        "src": IMG_6fd38523_ASSET.readall(),
    },
    "C11": {
        "description": "god with arms supporting the sky and palm branch on head",
        "pronunciation": "HH",
        "src": IMG_9d0a6144_ASSET.readall(),
    },
    "R19": {
        "description": "scepter with feather",
        "src": IMG_24b11911_ASSET.readall(),
    },
    "N5": {
        "description": "sun",
        "pronunciation": "zw",
        "src": IMG_55b1d35a_ASSET.readall(),
    },
    "O13": {
        "description": "battlemented enclosure",
        "src": IMG_0242894d_ASSET.readall(),
    },
    "W8": {
        "description": "granite bowl",
        "src": IMG_44d9c85b_ASSET.readall(),
    },
    "M4": {
        "description": "palm branch",
        "pronunciation": "rnp",
        "src": IMG_ddadf4c3_ASSET.readall(),
    },
    "A51": {
        "description": "noble on chair with flagellum",
        "pronunciation": "Spsi",
        "src": IMG_8256649d_ASSET.readall(),
    },
    "Y1": {
        "description": "papyrusroll",
        "pronunciation": "mDAt",
        "src": IMG_58dea276_ASSET.readall(),
    },
    "M41": {
        "description": "piece of wood",
        "src": IMG_46711faf_ASSET.readall(),
    },
    "O7": {
        "description": "combination of enclosure and flat loaf",
        "src": IMG_8e07ec97_ASSET.readall(),
    },
    "T25": {
        "description": "float",
        "pronunciation": "DbA",
        "src": IMG_9774162e_ASSET.readall(),
    },
    "Z11": {
        "description": "two planks crossed and joined",
        "pronunciation": "imi",
        "src": IMG_2f7b3390_ASSET.readall(),
    },
    "Q5": {
        "description": "chest",
        "src": IMG_6b4c6145_ASSET.readall(),
    },
}
