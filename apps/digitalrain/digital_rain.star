"""
Applet: Digital Rain
Summary: Digital Rain à la Matrix
Description: Generates an animation loop of falling code similar to that from the Matrix movie. A new sequence every 30 minutes.
Author: Henry So, Jr.
"""

# Digital Rain à la The Matrix
# Version 1.1.0
#
# Copyright (c) 2022 Henry So, Jr.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Via the configuration below, this app will show a different sequence every
# 30 minutes (see SEED_GRANULARITY)

load("images/char_01f442de.png", CHAR_01f442de_ASSET = "file")
load("images/char_022cd37f.png", CHAR_022cd37f_ASSET = "file")
load("images/char_03167e55.png", CHAR_03167e55_ASSET = "file")
load("images/char_036ccf92.png", CHAR_036ccf92_ASSET = "file")
load("images/char_038ce057.png", CHAR_038ce057_ASSET = "file")
load("images/char_03902fce.png", CHAR_03902fce_ASSET = "file")
load("images/char_03d9fd1d.png", CHAR_03d9fd1d_ASSET = "file")
load("images/char_04250f76.png", CHAR_04250f76_ASSET = "file")
load("images/char_045e53e8.png", CHAR_045e53e8_ASSET = "file")
load("images/char_0555d134.png", CHAR_0555d134_ASSET = "file")
load("images/char_06db63dd.png", CHAR_06db63dd_ASSET = "file")
load("images/char_074546a3.png", CHAR_074546a3_ASSET = "file")
load("images/char_08ca6efa.png", CHAR_08ca6efa_ASSET = "file")
load("images/char_09e0fcb6.png", CHAR_09e0fcb6_ASSET = "file")
load("images/char_0a8e49d4.png", CHAR_0a8e49d4_ASSET = "file")
load("images/char_0b338198.png", CHAR_0b338198_ASSET = "file")
load("images/char_0b44cf0f.png", CHAR_0b44cf0f_ASSET = "file")
load("images/char_0c5d905d.png", CHAR_0c5d905d_ASSET = "file")
load("images/char_0d67b97b.png", CHAR_0d67b97b_ASSET = "file")
load("images/char_0fc703e5.png", CHAR_0fc703e5_ASSET = "file")
load("images/char_106a1633.png", CHAR_106a1633_ASSET = "file")
load("images/char_1392e2ef.png", CHAR_1392e2ef_ASSET = "file")
load("images/char_1521608a.png", CHAR_1521608a_ASSET = "file")
load("images/char_1d548473.png", CHAR_1d548473_ASSET = "file")
load("images/char_1dfbc367.png", CHAR_1dfbc367_ASSET = "file")
load("images/char_1ebc835e.png", CHAR_1ebc835e_ASSET = "file")
load("images/char_20ed36bf.png", CHAR_20ed36bf_ASSET = "file")
load("images/char_21c2200b.png", CHAR_21c2200b_ASSET = "file")
load("images/char_22282c66.png", CHAR_22282c66_ASSET = "file")
load("images/char_23ae116f.png", CHAR_23ae116f_ASSET = "file")
load("images/char_23b7fcdb.png", CHAR_23b7fcdb_ASSET = "file")
load("images/char_2810d5dc.png", CHAR_2810d5dc_ASSET = "file")
load("images/char_28dc2da4.png", CHAR_28dc2da4_ASSET = "file")
load("images/char_29af0b75.png", CHAR_29af0b75_ASSET = "file")
load("images/char_2a30da5c.png", CHAR_2a30da5c_ASSET = "file")
load("images/char_2f61c8b0.png", CHAR_2f61c8b0_ASSET = "file")
load("images/char_2f979f41.png", CHAR_2f979f41_ASSET = "file")
load("images/char_30cc3bc8.png", CHAR_30cc3bc8_ASSET = "file")
load("images/char_312a8932.png", CHAR_312a8932_ASSET = "file")
load("images/char_32358c27.png", CHAR_32358c27_ASSET = "file")
load("images/char_3285b566.png", CHAR_3285b566_ASSET = "file")
load("images/char_32a782a7.png", CHAR_32a782a7_ASSET = "file")
load("images/char_32b4e375.png", CHAR_32b4e375_ASSET = "file")
load("images/char_32c22bac.png", CHAR_32c22bac_ASSET = "file")
load("images/char_3394126b.png", CHAR_3394126b_ASSET = "file")
load("images/char_33fb1957.png", CHAR_33fb1957_ASSET = "file")
load("images/char_349c8b35.png", CHAR_349c8b35_ASSET = "file")
load("images/char_35ad536f.png", CHAR_35ad536f_ASSET = "file")
load("images/char_37ab1fef.png", CHAR_37ab1fef_ASSET = "file")
load("images/char_37d66382.png", CHAR_37d66382_ASSET = "file")
load("images/char_37fd3c86.png", CHAR_37fd3c86_ASSET = "file")
load("images/char_3823fee7.png", CHAR_3823fee7_ASSET = "file")
load("images/char_3a9fb0fb.png", CHAR_3a9fb0fb_ASSET = "file")
load("images/char_3d2be8b8.png", CHAR_3d2be8b8_ASSET = "file")
load("images/char_3d79d0bc.png", CHAR_3d79d0bc_ASSET = "file")
load("images/char_3e800265.png", CHAR_3e800265_ASSET = "file")
load("images/char_3ee3a4e2.png", CHAR_3ee3a4e2_ASSET = "file")
load("images/char_40c009f5.png", CHAR_40c009f5_ASSET = "file")
load("images/char_413a236c.png", CHAR_413a236c_ASSET = "file")
load("images/char_418df98f.png", CHAR_418df98f_ASSET = "file")
load("images/char_42b06694.png", CHAR_42b06694_ASSET = "file")
load("images/char_44d56a10.png", CHAR_44d56a10_ASSET = "file")
load("images/char_452e24fd.png", CHAR_452e24fd_ASSET = "file")
load("images/char_454bc795.png", CHAR_454bc795_ASSET = "file")
load("images/char_4739ee65.png", CHAR_4739ee65_ASSET = "file")
load("images/char_478f89cf.png", CHAR_478f89cf_ASSET = "file")
load("images/char_492a5b99.png", CHAR_492a5b99_ASSET = "file")
load("images/char_4b5babbb.png", CHAR_4b5babbb_ASSET = "file")
load("images/char_4d018752.png", CHAR_4d018752_ASSET = "file")
load("images/char_4df7d8e3.png", CHAR_4df7d8e3_ASSET = "file")
load("images/char_4f40da66.png", CHAR_4f40da66_ASSET = "file")
load("images/char_4f63afa3.png", CHAR_4f63afa3_ASSET = "file")
load("images/char_500ec7e0.png", CHAR_500ec7e0_ASSET = "file")
load("images/char_5011b9da.png", CHAR_5011b9da_ASSET = "file")
load("images/char_50b56be7.png", CHAR_50b56be7_ASSET = "file")
load("images/char_50be5b5b.png", CHAR_50be5b5b_ASSET = "file")
load("images/char_51dc39e2.png", CHAR_51dc39e2_ASSET = "file")
load("images/char_51e2aeb0.png", CHAR_51e2aeb0_ASSET = "file")
load("images/char_52d596a8.png", CHAR_52d596a8_ASSET = "file")
load("images/char_5323749d.png", CHAR_5323749d_ASSET = "file")
load("images/char_54145a3a.png", CHAR_54145a3a_ASSET = "file")
load("images/char_54dfc2f8.png", CHAR_54dfc2f8_ASSET = "file")
load("images/char_5668b369.png", CHAR_5668b369_ASSET = "file")
load("images/char_568c3af8.png", CHAR_568c3af8_ASSET = "file")
load("images/char_575b59de.png", CHAR_575b59de_ASSET = "file")
load("images/char_5a4c37e7.png", CHAR_5a4c37e7_ASSET = "file")
load("images/char_5aea1855.png", CHAR_5aea1855_ASSET = "file")
load("images/char_5ce03429.png", CHAR_5ce03429_ASSET = "file")
load("images/char_5e813b06.png", CHAR_5e813b06_ASSET = "file")
load("images/char_5e9379b9.png", CHAR_5e9379b9_ASSET = "file")
load("images/char_5eaffcd5.png", CHAR_5eaffcd5_ASSET = "file")
load("images/char_5f14efbd.png", CHAR_5f14efbd_ASSET = "file")
load("images/char_5f760275.png", CHAR_5f760275_ASSET = "file")
load("images/char_60cf0d96.png", CHAR_60cf0d96_ASSET = "file")
load("images/char_63629f5f.png", CHAR_63629f5f_ASSET = "file")
load("images/char_64002965.png", CHAR_64002965_ASSET = "file")
load("images/char_66e4d95d.png", CHAR_66e4d95d_ASSET = "file")
load("images/char_6711d7c8.png", CHAR_6711d7c8_ASSET = "file")
load("images/char_673b3015.png", CHAR_673b3015_ASSET = "file")
load("images/char_6787e471.png", CHAR_6787e471_ASSET = "file")
load("images/char_68b69ce8.png", CHAR_68b69ce8_ASSET = "file")
load("images/char_6a1a7a11.png", CHAR_6a1a7a11_ASSET = "file")
load("images/char_6ae806b1.png", CHAR_6ae806b1_ASSET = "file")
load("images/char_6b58cfd9.png", CHAR_6b58cfd9_ASSET = "file")
load("images/char_6cad31b0.png", CHAR_6cad31b0_ASSET = "file")
load("images/char_6d51ac83.png", CHAR_6d51ac83_ASSET = "file")
load("images/char_6db8d2a0.png", CHAR_6db8d2a0_ASSET = "file")
load("images/char_6e16f4ef.png", CHAR_6e16f4ef_ASSET = "file")
load("images/char_6f13ebc1.png", CHAR_6f13ebc1_ASSET = "file")
load("images/char_6f4d4fad.png", CHAR_6f4d4fad_ASSET = "file")
load("images/char_6fc64aea.png", CHAR_6fc64aea_ASSET = "file")
load("images/char_70ff248c.png", CHAR_70ff248c_ASSET = "file")
load("images/char_71bd0d26.png", CHAR_71bd0d26_ASSET = "file")
load("images/char_71d251c0.png", CHAR_71d251c0_ASSET = "file")
load("images/char_7301e392.png", CHAR_7301e392_ASSET = "file")
load("images/char_74805967.png", CHAR_74805967_ASSET = "file")
load("images/char_76643f1f.png", CHAR_76643f1f_ASSET = "file")
load("images/char_78cd1f4a.png", CHAR_78cd1f4a_ASSET = "file")
load("images/char_79286ba9.png", CHAR_79286ba9_ASSET = "file")
load("images/char_7ba77cd8.png", CHAR_7ba77cd8_ASSET = "file")
load("images/char_7bd66cb3.png", CHAR_7bd66cb3_ASSET = "file")
load("images/char_7c018d41.png", CHAR_7c018d41_ASSET = "file")
load("images/char_7cd0d8d9.png", CHAR_7cd0d8d9_ASSET = "file")
load("images/char_7d253c1b.png", CHAR_7d253c1b_ASSET = "file")
load("images/char_7d5d5285.png", CHAR_7d5d5285_ASSET = "file")
load("images/char_801cbd9d.png", CHAR_801cbd9d_ASSET = "file")
load("images/char_857b8f75.png", CHAR_857b8f75_ASSET = "file")
load("images/char_86cc311d.png", CHAR_86cc311d_ASSET = "file")
load("images/char_8b660bd1.png", CHAR_8b660bd1_ASSET = "file")
load("images/char_8b72aa67.png", CHAR_8b72aa67_ASSET = "file")
load("images/char_8cd40a88.png", CHAR_8cd40a88_ASSET = "file")
load("images/char_8d3aed50.png", CHAR_8d3aed50_ASSET = "file")
load("images/char_8e8972a2.png", CHAR_8e8972a2_ASSET = "file")
load("images/char_8ec4315d.png", CHAR_8ec4315d_ASSET = "file")
load("images/char_8f9d9bc0.png", CHAR_8f9d9bc0_ASSET = "file")
load("images/char_8fae5c65.png", CHAR_8fae5c65_ASSET = "file")
load("images/char_9033661e.png", CHAR_9033661e_ASSET = "file")
load("images/char_91620f66.png", CHAR_91620f66_ASSET = "file")
load("images/char_9301a936.png", CHAR_9301a936_ASSET = "file")
load("images/char_934192ec.png", CHAR_934192ec_ASSET = "file")
load("images/char_937a1459.png", CHAR_937a1459_ASSET = "file")
load("images/char_93fcc9b7.png", CHAR_93fcc9b7_ASSET = "file")
load("images/char_943d6da0.png", CHAR_943d6da0_ASSET = "file")
load("images/char_949c61a0.png", CHAR_949c61a0_ASSET = "file")
load("images/char_97f59b19.png", CHAR_97f59b19_ASSET = "file")
load("images/char_984fb220.png", CHAR_984fb220_ASSET = "file")
load("images/char_988d6626.png", CHAR_988d6626_ASSET = "file")
load("images/char_988db185.png", CHAR_988db185_ASSET = "file")
load("images/char_98d2ac46.png", CHAR_98d2ac46_ASSET = "file")
load("images/char_993269e6.png", CHAR_993269e6_ASSET = "file")
load("images/char_99a2b78b.png", CHAR_99a2b78b_ASSET = "file")
load("images/char_9c21bf6e.png", CHAR_9c21bf6e_ASSET = "file")
load("images/char_9c7e5ae3.png", CHAR_9c7e5ae3_ASSET = "file")
load("images/char_9e738f92.png", CHAR_9e738f92_ASSET = "file")
load("images/char_9ed2b9e1.png", CHAR_9ed2b9e1_ASSET = "file")
load("images/char_9f43cfaa.png", CHAR_9f43cfaa_ASSET = "file")
load("images/char_9fe60305.png", CHAR_9fe60305_ASSET = "file")
load("images/char_a10a23c1.png", CHAR_a10a23c1_ASSET = "file")
load("images/char_a1757092.png", CHAR_a1757092_ASSET = "file")
load("images/char_a1d306be.png", CHAR_a1d306be_ASSET = "file")
load("images/char_a21cf6f5.png", CHAR_a21cf6f5_ASSET = "file")
load("images/char_a3c2198b.png", CHAR_a3c2198b_ASSET = "file")
load("images/char_a3eeac0b.png", CHAR_a3eeac0b_ASSET = "file")
load("images/char_a404b03d.png", CHAR_a404b03d_ASSET = "file")
load("images/char_a40880dc.png", CHAR_a40880dc_ASSET = "file")
load("images/char_a6c4b1f7.png", CHAR_a6c4b1f7_ASSET = "file")
load("images/char_a7508537.png", CHAR_a7508537_ASSET = "file")
load("images/char_a7a4792f.png", CHAR_a7a4792f_ASSET = "file")
load("images/char_a93511dc.png", CHAR_a93511dc_ASSET = "file")
load("images/char_a9e06c6f.png", CHAR_a9e06c6f_ASSET = "file")
load("images/char_ab7836cd.png", CHAR_ab7836cd_ASSET = "file")
load("images/char_ac46011b.png", CHAR_ac46011b_ASSET = "file")
load("images/char_ac492008.png", CHAR_ac492008_ASSET = "file")
load("images/char_aec9bd5e.png", CHAR_aec9bd5e_ASSET = "file")
load("images/char_af0e0d3c.png", CHAR_af0e0d3c_ASSET = "file")
load("images/char_b13e6975.png", CHAR_b13e6975_ASSET = "file")
load("images/char_b43a335b.png", CHAR_b43a335b_ASSET = "file")
load("images/char_b7b090f1.png", CHAR_b7b090f1_ASSET = "file")
load("images/char_b86c1ca1.png", CHAR_b86c1ca1_ASSET = "file")
load("images/char_ba6ab80a.png", CHAR_ba6ab80a_ASSET = "file")
load("images/char_bc50cded.png", CHAR_bc50cded_ASSET = "file")
load("images/char_bd7f1d7d.png", CHAR_bd7f1d7d_ASSET = "file")
load("images/char_bdec1020.png", CHAR_bdec1020_ASSET = "file")
load("images/char_c13f2c6a.png", CHAR_c13f2c6a_ASSET = "file")
load("images/char_c1b67ee8.png", CHAR_c1b67ee8_ASSET = "file")
load("images/char_c3cea04d.png", CHAR_c3cea04d_ASSET = "file")
load("images/char_c4cc7d9a.png", CHAR_c4cc7d9a_ASSET = "file")
load("images/char_c50aae66.png", CHAR_c50aae66_ASSET = "file")
load("images/char_c5c9d414.png", CHAR_c5c9d414_ASSET = "file")
load("images/char_c5d31eb0.png", CHAR_c5d31eb0_ASSET = "file")
load("images/char_c62ae6aa.png", CHAR_c62ae6aa_ASSET = "file")
load("images/char_c65877e3.png", CHAR_c65877e3_ASSET = "file")
load("images/char_c6e60f10.png", CHAR_c6e60f10_ASSET = "file")
load("images/char_c8b723c6.png", CHAR_c8b723c6_ASSET = "file")
load("images/char_ca670842.png", CHAR_ca670842_ASSET = "file")
load("images/char_cae2cffc.png", CHAR_cae2cffc_ASSET = "file")
load("images/char_ccd7f1a4.png", CHAR_ccd7f1a4_ASSET = "file")
load("images/char_ce4b8496.png", CHAR_ce4b8496_ASSET = "file")
load("images/char_ce9bcb0a.png", CHAR_ce9bcb0a_ASSET = "file")
load("images/char_ceb81a1e.png", CHAR_ceb81a1e_ASSET = "file")
load("images/char_cf0d5596.png", CHAR_cf0d5596_ASSET = "file")
load("images/char_d09407de.png", CHAR_d09407de_ASSET = "file")
load("images/char_d107a1f6.png", CHAR_d107a1f6_ASSET = "file")
load("images/char_d278ec10.png", CHAR_d278ec10_ASSET = "file")
load("images/char_d4a7385f.png", CHAR_d4a7385f_ASSET = "file")
load("images/char_d4fe02c9.png", CHAR_d4fe02c9_ASSET = "file")
load("images/char_d670146f.png", CHAR_d670146f_ASSET = "file")
load("images/char_d738a896.png", CHAR_d738a896_ASSET = "file")
load("images/char_d8048408.png", CHAR_d8048408_ASSET = "file")
load("images/char_d82040ef.png", CHAR_d82040ef_ASSET = "file")
load("images/char_d93b911e.png", CHAR_d93b911e_ASSET = "file")
load("images/char_da61033e.png", CHAR_da61033e_ASSET = "file")
load("images/char_da631d57.png", CHAR_da631d57_ASSET = "file")
load("images/char_db316804.png", CHAR_db316804_ASSET = "file")
load("images/char_dcc525e7.png", CHAR_dcc525e7_ASSET = "file")
load("images/char_df355bcf.png", CHAR_df355bcf_ASSET = "file")
load("images/char_df6513fb.png", CHAR_df6513fb_ASSET = "file")
load("images/char_e2117148.png", CHAR_e2117148_ASSET = "file")
load("images/char_e33c6c4f.png", CHAR_e33c6c4f_ASSET = "file")
load("images/char_e3988955.png", CHAR_e3988955_ASSET = "file")
load("images/char_e3fa62d9.png", CHAR_e3fa62d9_ASSET = "file")
load("images/char_e4228e5a.png", CHAR_e4228e5a_ASSET = "file")
load("images/char_e49df898.png", CHAR_e49df898_ASSET = "file")
load("images/char_e64268f1.png", CHAR_e64268f1_ASSET = "file")
load("images/char_e6fa7917.png", CHAR_e6fa7917_ASSET = "file")
load("images/char_e8143f13.png", CHAR_e8143f13_ASSET = "file")
load("images/char_e85914ac.png", CHAR_e85914ac_ASSET = "file")
load("images/char_e8b0e14d.png", CHAR_e8b0e14d_ASSET = "file")
load("images/char_e97d35e8.png", CHAR_e97d35e8_ASSET = "file")
load("images/char_e989599a.png", CHAR_e989599a_ASSET = "file")
load("images/char_e9930359.png", CHAR_e9930359_ASSET = "file")
load("images/char_ec1ddf83.png", CHAR_ec1ddf83_ASSET = "file")
load("images/char_f0bb085d.png", CHAR_f0bb085d_ASSET = "file")
load("images/char_f1822bd6.png", CHAR_f1822bd6_ASSET = "file")
load("images/char_f2062591.png", CHAR_f2062591_ASSET = "file")
load("images/char_f249a245.png", CHAR_f249a245_ASSET = "file")
load("images/char_f2be6c8f.png", CHAR_f2be6c8f_ASSET = "file")
load("images/char_f3126e05.png", CHAR_f3126e05_ASSET = "file")
load("images/char_f5c6f364.png", CHAR_f5c6f364_ASSET = "file")
load("images/char_f61e967f.png", CHAR_f61e967f_ASSET = "file")
load("images/char_f64eb6d1.png", CHAR_f64eb6d1_ASSET = "file")
load("images/char_f696c053.png", CHAR_f696c053_ASSET = "file")
load("images/char_f9627db2.png", CHAR_f9627db2_ASSET = "file")
load("images/char_fb54771d.png", CHAR_fb54771d_ASSET = "file")
load("images/char_fbdf5393.png", CHAR_fbdf5393_ASSET = "file")
load("images/char_fecbbfb6.png", CHAR_fecbbfb6_ASSET = "file")
load("images/char_ffc4a49a.png", CHAR_ffc4a49a_ASSET = "file")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

# for column styles:
# 'speed' is the number of frames before the drop moves, so a lower number
# moves the drop faster
# 'drop_min' is the minimum size of a drop and its trail
# 'drop_variance' is the amount by which the drop's trail can be longer

FAST_COLUMN = {
    "speed": 1,
    "drop_min": 9,
    "drop_variance": 9,
}
NORMAL_COLUMN = {
    "speed": 2,
    "drop_min": 9,
    "drop_variance": 9,
}
SLOW_COLUMN = {
    "speed": 3,
    "drop_min": 7,
    "drop_variance": 5,
}

# this sets the relative frequency of different column types
COLUMN_STYLES = [
    FAST_COLUMN,
    FAST_COLUMN,
    FAST_COLUMN,
    NORMAL_COLUMN,
    NORMAL_COLUMN,
    NORMAL_COLUMN,
    NORMAL_COLUMN,
    NORMAL_COLUMN,
    SLOW_COLUMN,
    SLOW_COLUMN,
]
COLUMN_STYLE_COUNT = len(COLUMN_STYLES)

# this is variance in the position of the second drop in a given column
# relative to both drops being equidistant
SECOND_DROP_VARIANCE = 8

WIDTH = 64
HEIGHT = 32

FRAMES = 72

# the amount of time before a new sequence is generated
SEED_GRANULARITY = 60 * 30  # 30 minutes

# in addition to the parameters in the schema, config can accept 'seed' for
# debugging issues with specific seeds
def main(config):
    # seed the pseudo-random number generator
    seed = config.get("seed")
    if seed:
        seed = int(seed)
    else:
        seed = int(time.now().unix) // SEED_GRANULARITY

    #print("seed = %d" % seed)

    random.seed(seed)

    # get the color; do it this way so that setting the color from the
    # config doesn't spoil the pseudo-random number sequence
    color_options = (
        [i for i in range(COLOR_COUNT)] +
        [random.number(0, COLOR_COUNT) - 1, random.number(0, COLOR_COUNT - 1)]
    )
    color_number = COLOR_NAMES.get(config.get("color"), COLOR_NAMES["random"])
    if color_number >= 0:
        color_number = color_options[color_number]

    char_size = CHAR_SIZES.get(config.get("char_size")) or CHAR_SIZES["normal"]

    # initialize the columns
    columns = [
        generate_column(char_size, color_number)
        for i in range(char_size["columns"])
    ]

    # occasionally blow a column away
    if random.number(0, 24) == 0 and char_size["columns"] > 2:
        columns[random.number(0, char_size["columns"] - 3) + 1] = None

    # vary the x-offset and y-offset for more interesting variety
    xoffset = -random.number(0, max(char_size["w"], 2) - 1)
    yoffset = -random.number(0, max(char_size["h"], 2) - 1)
    #print("offset = %d, %d" % (xoffset, yoffset))

    # create the widget for the app
    return render.Root(
        delay = 30,
        child = render.Box(
            width = WIDTH,
            height = HEIGHT,
            child = render.Padding(
                pad = (xoffset, yoffset, 0, 0),
                child = render.Animation([
                    generate_frame(char_size, columns, f)
                    for f in range(72)
                ]),
            ),
        ),
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "color",
                name = "Color",
                icon = "brush",
                desc = "The color to use for the rain.",
                options = [
                    schema.Option(display = color, value = color)
                    for color in COLOR_NAMES
                ],
                default = "green",
            ),
            schema.Dropdown(
                id = "char_size",
                name = "Character Size",
                icon = "textHeight",
                desc = "The character size for the rain.",
                options = [
                    schema.Option(display = char_size, value = char_size)
                    for char_size in CHAR_SIZES
                ],
                default = "normal",
            ),
        ],
    )

# Generates the initial state of a column
# char_size - the character size structure
# color_number - the color number
def generate_column(char_size, color_number):
    style = COLUMN_STYLES[random.number(0, COLUMN_STYLE_COUNT - 1)]
    speed = style["speed"]
    drop_size = style["drop_min"] + random.number(0, style["drop_variance"] - 1)
    size = FRAMES // speed
    offset = random.number(0, size - 1)
    colors = colors_of(color_number)

    second_drop = {
        "chars": [random.number(0, CHAR_COUNT - 1) for i in range(char_size["rows"])],
        "mutations": [0 for i in range(char_size["rows"])],
        "offset": offset + ((size - SECOND_DROP_VARIANCE) // 2) +
                  random.number(0, SECOND_DROP_VARIANCE - 1),
        "drop_size": style["drop_min"] + random.number(0, style["drop_variance"] - 1),
        "colors": colors_of(color_number),
    } if speed == 1 and random.number(0, 6) < 2 else None

    return {
        "speed": speed,
        "frame_offset": random.number(0, speed - 1),
        "size": size,
        "chars": [random.number(0, CHAR_COUNT - 1) for i in range(char_size["rows"])],
        "mutations": [0 for i in range(char_size["rows"])],
        "offset": offset,
        "drop_size": drop_size,
        "colors": colors,
        "second_drop": second_drop,
    }

# Returns the colors structure to use for the given the color_number
# color_number - the color_number
def colors_of(color_number):
    color = random.number(0, COLOR_COUNT - 1)
    if color_number >= 0:
        color = color_number
    return COLORS[color]

# Generates a given frame of the animation
# char_size - the character size structure
# columns - the list of column structures
# f - the frame number
def generate_frame(char_size, columns, f):
    frame_chars = [
        [None for c in range(char_size["columns"])]
        for r in range(char_size["rows"])
    ]
    frame_colors = [
        ["#000" for c in range(char_size["columns"])]
        for r in range(char_size["rows"])
    ]
    for c in range(char_size["columns"]):
        for column in compute_column(char_size, columns[c], f):
            chars = column["chars"]
            drop_size = column["drop_size"]
            colors = column["colors"]
            for i in range(char_size["rows"]):
                if chars[i]:
                    r = char_size["rows"] - i - 1
                    frame_chars[r][c] = chars[i][0]
                    loc = chars[i][1]
                    if loc == 0:
                        frame_colors[r][c] = "#fff"
                    else:
                        frame_colors[r][c] = colors[min(drop_size - loc, 5)]
    return render.Column([
        render.Row([
            render.Box(
                width = char_size["w"] + 1,
                height = char_size["h"] + 1,
                child = render_char(
                    char_size,
                    frame_chars[r][c],
                    frame_colors[r][c],
                ),
            )
            for c in range(char_size["columns"])
        ])
        for r in range(char_size["rows"])
    ])

# Computes a particular column (some columns have two drops)
# char_size - the character size structure
# column - the column structure
# f - the frame number
def compute_column(char_size, column, f):
    if column:
        speed = column["speed"]
        f += column["frame_offset"]
        size = column["size"]
        do_mutate = (f % speed) == 0

        first_drop_column = compute_drop(
            char_size,
            speed,
            size,
            column,
            f,
            do_mutate,
        )

        second_drop = column["second_drop"]
        if second_drop:
            second_drop_column = compute_drop(
                char_size,
                speed,
                size,
                second_drop,
                f,
                do_mutate,
            )
            return [first_drop_column, second_drop_column]
        else:
            return [first_drop_column]
    else:
        return []

# Computes a particular "drop" of a given column
# char_size - the character size structure
# speed - the speed of the column
# size - the size of the column
# drop - the drop structure
# f - the frame number
# do_mutate - whether to perform a mutation
def compute_drop(char_size, speed, size, drop, f, do_mutate):
    drop_size = drop["drop_size"]
    chars = drop["chars"]
    mutations = drop["mutations"]
    offset = drop["offset"]
    pos = (f // speed) + offset

    # prevent mutate when offset <= drop_size to prevent
    # flip-flops of visible characters when the animation loops

    if do_mutate and offset > drop_size:
        mutate_chars(char_size, chars, mutations, pos, size, drop_size)

    return {
        "chars": chars_of(char_size, chars, pos, size, drop_size),
        "size": size,
        "drop_size": drop_size,
        "colors": drop["colors"],
    }

# Mutates the visible characters randomly
# char_size - the character size structure
# chars - the character array of the drop
# mutations - the mutation tracking array of the drop
# pos - the virtual position of the drop
# size - the size of the column
# drop_size - the size of the drop
def mutate_chars(char_size, chars, mutations, pos, size, drop_size):
    for i in range(1, 6):
        mutate_char(
            char_size,
            chars,
            mutations,
            -pos,
            size,
            drop_size - i,
            6 - i,
            30,
        )
    for n in range(1, drop_size - 5):
        mutate_char(char_size, chars, mutations, -pos, size, n, 1, 50)

# Mutates a single character
# char_size - the character size structure
# chars - the character array of the drop
# mutations - the mutation tracking array of the drop
# pos - the virtual position of the drop
# size - the size of the column
# n - the index of the character within the drop
# numerator - the chance of mutation numerator
# denominator - the chance of mutation denominator
def mutate_char(
        char_size,
        chars,
        mutations,
        pos,
        size,
        n,
        numerator,
        denominator):
    index = (pos + n) % size
    if (index < char_size["rows"] and
        random.number(0, denominator - 1) < (numerator - mutations[index])):
        chars[index] = random.number(0, CHAR_COUNT - 1)
        mutations[index] += 1

# Returns the on-screen characters
# char_size - the character size structure
# chars - the character array of the drop
# pos - the virtual position of the drop
# size - the size of the column
# drop_size - the size of the drop
def chars_of(char_size, chars, pos, size, drop_size):
    result = [None for i in range(char_size["rows"])]
    for i in range(drop_size):
        index = (-pos + i) % size
        if index < char_size["rows"]:
            result[index] = (chars[index], i)
    return result

# Returns the widget for a character
# char_size - the character size structure
# index - the character index
# color - the character color
def render_char(char_size, index, color):
    if index == None:
        return render.Box(
            width = char_size["w"],
            height = char_size["h"],
        )
    else:
        return render.Box(
            color = color,
            width = char_size["w"],
            height = char_size["h"],
            child = render.Image(char_size["chars"][index]),
        )

COLORS = [
    [p.replace("X", v) for v in ("2", "5", "8", "b", "d", "f")]
    for p in ("#00X", "#0X0", "#0XX", "#X00", "#X0X", "#XX0")
]
COLOR_COUNT = len(COLORS)
COLOR_NAMES = {
    "random": 6,
    "random-mono": 7,
    "blue": 0,
    "green": 1,
    "cyan": 2,
    "red": 3,
    "magenta": 4,
    "yellow": 5,
    "multicolor": -1,
}

CHAR_SIZES = {
    t[0]: {
        "w": t[1],
        "h": t[2],
        "columns": (WIDTH // (t[1] + 1)) + 1,
        "rows": (HEIGHT // (t[2] + 1)) + 1,
        "chars": t[3],
    }
    for t in [
        ("normal", 5, 7, [
            CHAR_418df98f_ASSET.readall(),
            CHAR_7cd0d8d9_ASSET.readall(),
            CHAR_c5c9d414_ASSET.readall(),
            CHAR_bc50cded_ASSET.readall(),
            CHAR_5011b9da_ASSET.readall(),
            CHAR_312a8932_ASSET.readall(),
            CHAR_fecbbfb6_ASSET.readall(),
            CHAR_d738a896_ASSET.readall(),
            CHAR_5f760275_ASSET.readall(),
            CHAR_f249a245_ASSET.readall(),
            CHAR_a6c4b1f7_ASSET.readall(),
            CHAR_6e16f4ef_ASSET.readall(),
            CHAR_32b4e375_ASSET.readall(),
            CHAR_943d6da0_ASSET.readall(),
            CHAR_a9e06c6f_ASSET.readall(),
            CHAR_8e8972a2_ASSET.readall(),
            CHAR_50b56be7_ASSET.readall(),
            CHAR_ceb81a1e_ASSET.readall(),
            CHAR_8d3aed50_ASSET.readall(),
            CHAR_23b7fcdb_ASSET.readall(),
            CHAR_500ec7e0_ASSET.readall(),
            CHAR_32c22bac_ASSET.readall(),
            CHAR_f1822bd6_ASSET.readall(),
            CHAR_c3cea04d_ASSET.readall(),
            CHAR_349c8b35_ASSET.readall(),
            CHAR_988db185_ASSET.readall(),
            CHAR_6b58cfd9_ASSET.readall(),
            CHAR_64002965_ASSET.readall(),
            CHAR_f2be6c8f_ASSET.readall(),
            CHAR_29af0b75_ASSET.readall(),
            CHAR_35ad536f_ASSET.readall(),
            CHAR_c62ae6aa_ASSET.readall(),
            CHAR_d107a1f6_ASSET.readall(),
            CHAR_ca670842_ASSET.readall(),
            CHAR_5e9379b9_ASSET.readall(),
            CHAR_54dfc2f8_ASSET.readall(),
            CHAR_fbdf5393_ASSET.readall(),
            CHAR_5f14efbd_ASSET.readall(),
            CHAR_4b5babbb_ASSET.readall(),
            CHAR_37ab1fef_ASSET.readall(),
            CHAR_949c61a0_ASSET.readall(),
            CHAR_b86c1ca1_ASSET.readall(),
            CHAR_28dc2da4_ASSET.readall(),
            CHAR_1d548473_ASSET.readall(),
            CHAR_6cad31b0_ASSET.readall(),
            CHAR_01f442de_ASSET.readall(),
            CHAR_6fc64aea_ASSET.readall(),
            CHAR_d4a7385f_ASSET.readall(),
            CHAR_4d018752_ASSET.readall(),
            CHAR_af0e0d3c_ASSET.readall(),
        ]),
        ("small", 4, 6, [
            CHAR_71d251c0_ASSET.readall(),
            CHAR_a40880dc_ASSET.readall(),
            CHAR_da61033e_ASSET.readall(),
            CHAR_22282c66_ASSET.readall(),
            CHAR_6f13ebc1_ASSET.readall(),
            CHAR_106a1633_ASSET.readall(),
            CHAR_3e800265_ASSET.readall(),
            CHAR_70ff248c_ASSET.readall(),
            CHAR_93fcc9b7_ASSET.readall(),
            CHAR_ac492008_ASSET.readall(),
            CHAR_f696c053_ASSET.readall(),
            CHAR_e4228e5a_ASSET.readall(),
            CHAR_23ae116f_ASSET.readall(),
            CHAR_988d6626_ASSET.readall(),
            CHAR_5668b369_ASSET.readall(),
            CHAR_c6e60f10_ASSET.readall(),
            CHAR_6d51ac83_ASSET.readall(),
            CHAR_c8b723c6_ASSET.readall(),
            CHAR_df6513fb_ASSET.readall(),
            CHAR_b43a335b_ASSET.readall(),
            CHAR_50be5b5b_ASSET.readall(),
            CHAR_ab7836cd_ASSET.readall(),
            CHAR_8ec4315d_ASSET.readall(),
            CHAR_0d67b97b_ASSET.readall(),
            CHAR_e64268f1_ASSET.readall(),
            CHAR_ffc4a49a_ASSET.readall(),
            CHAR_37fd3c86_ASSET.readall(),
            CHAR_51e2aeb0_ASSET.readall(),
            CHAR_dcc525e7_ASSET.readall(),
            CHAR_08ca6efa_ASSET.readall(),
            CHAR_9fe60305_ASSET.readall(),
            CHAR_cf0d5596_ASSET.readall(),
            CHAR_d278ec10_ASSET.readall(),
            CHAR_492a5b99_ASSET.readall(),
            CHAR_03902fce_ASSET.readall(),
            CHAR_6787e471_ASSET.readall(),
            CHAR_0fc703e5_ASSET.readall(),
            CHAR_51dc39e2_ASSET.readall(),
            CHAR_60cf0d96_ASSET.readall(),
            CHAR_7c018d41_ASSET.readall(),
            CHAR_66e4d95d_ASSET.readall(),
            CHAR_97f59b19_ASSET.readall(),
            CHAR_a7508537_ASSET.readall(),
            CHAR_9301a936_ASSET.readall(),
            CHAR_d670146f_ASSET.readall(),
            CHAR_d93b911e_ASSET.readall(),
            CHAR_8f9d9bc0_ASSET.readall(),
            CHAR_7ba77cd8_ASSET.readall(),
            CHAR_3394126b_ASSET.readall(),
            CHAR_a1d306be_ASSET.readall(),
        ]),
        ("smaller", 3, 5, [
            CHAR_e85914ac_ASSET.readall(),
            CHAR_d4fe02c9_ASSET.readall(),
            CHAR_e8b0e14d_ASSET.readall(),
            CHAR_bd7f1d7d_ASSET.readall(),
            CHAR_6db8d2a0_ASSET.readall(),
            CHAR_413a236c_ASSET.readall(),
            CHAR_8fae5c65_ASSET.readall(),
            CHAR_bdec1020_ASSET.readall(),
            CHAR_33fb1957_ASSET.readall(),
            CHAR_e2117148_ASSET.readall(),
            CHAR_9033661e_ASSET.readall(),
            CHAR_1dfbc367_ASSET.readall(),
            CHAR_993269e6_ASSET.readall(),
            CHAR_6f4d4fad_ASSET.readall(),
            CHAR_32358c27_ASSET.readall(),
            CHAR_d8048408_ASSET.readall(),
            CHAR_3a9fb0fb_ASSET.readall(),
            CHAR_ccd7f1a4_ASSET.readall(),
            CHAR_74805967_ASSET.readall(),
            CHAR_a10a23c1_ASSET.readall(),
            CHAR_f61e967f_ASSET.readall(),
            CHAR_a1757092_ASSET.readall(),
            CHAR_454bc795_ASSET.readall(),
            CHAR_da631d57_ASSET.readall(),
            CHAR_2a30da5c_ASSET.readall(),
            CHAR_b13e6975_ASSET.readall(),
            CHAR_86cc311d_ASSET.readall(),
            CHAR_2f979f41_ASSET.readall(),
            CHAR_e989599a_ASSET.readall(),
            CHAR_6a1a7a11_ASSET.readall(),
            CHAR_cae2cffc_ASSET.readall(),
            CHAR_5a4c37e7_ASSET.readall(),
            CHAR_ba6ab80a_ASSET.readall(),
            CHAR_c65877e3_ASSET.readall(),
            CHAR_7301e392_ASSET.readall(),
            CHAR_9e738f92_ASSET.readall(),
            CHAR_04250f76_ASSET.readall(),
            CHAR_68b69ce8_ASSET.readall(),
            CHAR_3823fee7_ASSET.readall(),
            CHAR_32a782a7_ASSET.readall(),
            CHAR_e3988955_ASSET.readall(),
            CHAR_06db63dd_ASSET.readall(),
            CHAR_a7a4792f_ASSET.readall(),
            CHAR_78cd1f4a_ASSET.readall(),
            CHAR_aec9bd5e_ASSET.readall(),
            CHAR_3285b566_ASSET.readall(),
            CHAR_ce4b8496_ASSET.readall(),
            CHAR_045e53e8_ASSET.readall(),
            CHAR_f0bb085d_ASSET.readall(),
            CHAR_4f40da66_ASSET.readall(),
        ]),
        ("tiny", 2, 3, [
            CHAR_e6fa7917_ASSET.readall(),
            CHAR_e9930359_ASSET.readall(),
            CHAR_df355bcf_ASSET.readall(),
            CHAR_a21cf6f5_ASSET.readall(),
            CHAR_0a8e49d4_ASSET.readall(),
            CHAR_8cd40a88_ASSET.readall(),
            CHAR_c4cc7d9a_ASSET.readall(),
            CHAR_074546a3_ASSET.readall(),
            CHAR_3d79d0bc_ASSET.readall(),
            CHAR_c5d31eb0_ASSET.readall(),
            CHAR_7d5d5285_ASSET.readall(),
            CHAR_8b72aa67_ASSET.readall(),
            CHAR_1392e2ef_ASSET.readall(),
            CHAR_37d66382_ASSET.readall(),
            CHAR_8b660bd1_ASSET.readall(),
            CHAR_a3eeac0b_ASSET.readall(),
            CHAR_52d596a8_ASSET.readall(),
            CHAR_1521608a_ASSET.readall(),
            CHAR_e97d35e8_ASSET.readall(),
            CHAR_d82040ef_ASSET.readall(),
            CHAR_0b44cf0f_ASSET.readall(),
            CHAR_e3fa62d9_ASSET.readall(),
            CHAR_c13f2c6a_ASSET.readall(),
            CHAR_1ebc835e_ASSET.readall(),
            CHAR_79286ba9_ASSET.readall(),
            CHAR_e8143f13_ASSET.readall(),
            CHAR_0c5d905d_ASSET.readall(),
            CHAR_478f89cf_ASSET.readall(),
            CHAR_452e24fd_ASSET.readall(),
            CHAR_3ee3a4e2_ASSET.readall(),
            CHAR_5ce03429_ASSET.readall(),
            CHAR_4739ee65_ASSET.readall(),
            CHAR_21c2200b_ASSET.readall(),
            CHAR_03d9fd1d_ASSET.readall(),
            CHAR_76643f1f_ASSET.readall(),
            CHAR_934192ec_ASSET.readall(),
            CHAR_5323749d_ASSET.readall(),
            CHAR_0b338198_ASSET.readall(),
            CHAR_f9627db2_ASSET.readall(),
            CHAR_44d56a10_ASSET.readall(),
            CHAR_f64eb6d1_ASSET.readall(),
            CHAR_ce9bcb0a_ASSET.readall(),
            CHAR_5e813b06_ASSET.readall(),
            CHAR_6ae806b1_ASSET.readall(),
            CHAR_a93511dc_ASSET.readall(),
            CHAR_54145a3a_ASSET.readall(),
            CHAR_c50aae66_ASSET.readall(),
            CHAR_30cc3bc8_ASSET.readall(),
            CHAR_2810d5dc_ASSET.readall(),
            CHAR_4f63afa3_ASSET.readall(),
        ]),
        ("tinier", 1, 2, [
            CHAR_3d2be8b8_ASSET.readall(),
            CHAR_42b06694_ASSET.readall(),
            CHAR_f2062591_ASSET.readall(),
            CHAR_575b59de_ASSET.readall(),
            CHAR_9f43cfaa_ASSET.readall(),
            CHAR_9f43cfaa_ASSET.readall(),
            CHAR_7bd66cb3_ASSET.readall(),
            CHAR_ac46011b_ASSET.readall(),
            CHAR_40c009f5_ASSET.readall(),
            CHAR_e33c6c4f_ASSET.readall(),
            CHAR_a3c2198b_ASSET.readall(),
            CHAR_f3126e05_ASSET.readall(),
            CHAR_f3126e05_ASSET.readall(),
            CHAR_09e0fcb6_ASSET.readall(),
            CHAR_3d2be8b8_ASSET.readall(),
            CHAR_2f61c8b0_ASSET.readall(),
            CHAR_98d2ac46_ASSET.readall(),
            CHAR_9c21bf6e_ASSET.readall(),
            CHAR_568c3af8_ASSET.readall(),
            CHAR_a404b03d_ASSET.readall(),
            CHAR_6711d7c8_ASSET.readall(),
            CHAR_fb54771d_ASSET.readall(),
            CHAR_b7b090f1_ASSET.readall(),
            CHAR_022cd37f_ASSET.readall(),
            CHAR_7d253c1b_ASSET.readall(),
            CHAR_ec1ddf83_ASSET.readall(),
            CHAR_673b3015_ASSET.readall(),
            CHAR_63629f5f_ASSET.readall(),
            CHAR_db316804_ASSET.readall(),
            CHAR_984fb220_ASSET.readall(),
            CHAR_9ed2b9e1_ASSET.readall(),
            CHAR_857b8f75_ASSET.readall(),
            CHAR_03167e55_ASSET.readall(),
            CHAR_f5c6f364_ASSET.readall(),
            CHAR_71bd0d26_ASSET.readall(),
            CHAR_0555d134_ASSET.readall(),
            CHAR_20ed36bf_ASSET.readall(),
            CHAR_c1b67ee8_ASSET.readall(),
            CHAR_5eaffcd5_ASSET.readall(),
            CHAR_036ccf92_ASSET.readall(),
            CHAR_801cbd9d_ASSET.readall(),
            CHAR_99a2b78b_ASSET.readall(),
            CHAR_038ce057_ASSET.readall(),
            CHAR_e49df898_ASSET.readall(),
            CHAR_9c7e5ae3_ASSET.readall(),
            CHAR_937a1459_ASSET.readall(),
            CHAR_5aea1855_ASSET.readall(),
            CHAR_91620f66_ASSET.readall(),
            CHAR_4df7d8e3_ASSET.readall(),
            CHAR_d09407de_ASSET.readall(),
        ]),
    ]
}
CHAR_COUNT = len(CHAR_SIZES["normal"]["chars"])
