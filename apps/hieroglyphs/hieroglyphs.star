"""
Applet: Hieroglyphs
Summary: Random Egyptian Hieroglyphs
Description: Displays Egyptian Hieroglyphs from Gardiner's Sign List plus details of pronunciation and use.
Author: dinosaursrarr
"""

load("hash.star", "hash")
load("images/glyph_A1.png", GLYPH_A1_ASSET = "file")
load("images/glyph_A10.png", GLYPH_A10_ASSET = "file")
load("images/glyph_A11.png", GLYPH_A11_ASSET = "file")
load("images/glyph_A12.png", GLYPH_A12_ASSET = "file")
load("images/glyph_A13.png", GLYPH_A13_ASSET = "file")
load("images/glyph_A14.png", GLYPH_A14_ASSET = "file")
load("images/glyph_A15.png", GLYPH_A15_ASSET = "file")
load("images/glyph_A16.png", GLYPH_A16_ASSET = "file")
load("images/glyph_A17.png", GLYPH_A17_ASSET = "file")
load("images/glyph_A18.png", GLYPH_A18_ASSET = "file")
load("images/glyph_A19.png", GLYPH_A19_ASSET = "file")
load("images/glyph_A2.png", GLYPH_A2_ASSET = "file")
load("images/glyph_A20.png", GLYPH_A20_ASSET = "file")
load("images/glyph_A21.png", GLYPH_A21_ASSET = "file")
load("images/glyph_A22.png", GLYPH_A22_ASSET = "file")
load("images/glyph_A23.png", GLYPH_A23_ASSET = "file")
load("images/glyph_A24.png", GLYPH_A24_ASSET = "file")
load("images/glyph_A25.png", GLYPH_A25_ASSET = "file")
load("images/glyph_A26.png", GLYPH_A26_ASSET = "file")
load("images/glyph_A27.png", GLYPH_A27_ASSET = "file")
load("images/glyph_A28.png", GLYPH_A28_ASSET = "file")
load("images/glyph_A29.png", GLYPH_A29_ASSET = "file")
load("images/glyph_A3.png", GLYPH_A3_ASSET = "file")
load("images/glyph_A30.png", GLYPH_A30_ASSET = "file")
load("images/glyph_A31.png", GLYPH_A31_ASSET = "file")
load("images/glyph_A32.png", GLYPH_A32_ASSET = "file")
load("images/glyph_A33.png", GLYPH_A33_ASSET = "file")
load("images/glyph_A34.png", GLYPH_A34_ASSET = "file")
load("images/glyph_A35.png", GLYPH_A35_ASSET = "file")
load("images/glyph_A36.png", GLYPH_A36_ASSET = "file")
load("images/glyph_A37.png", GLYPH_A37_ASSET = "file")
load("images/glyph_A38.png", GLYPH_A38_ASSET = "file")
load("images/glyph_A39.png", GLYPH_A39_ASSET = "file")
load("images/glyph_A4.png", GLYPH_A4_ASSET = "file")
load("images/glyph_A40.png", GLYPH_A40_ASSET = "file")
load("images/glyph_A41.png", GLYPH_A41_ASSET = "file")
load("images/glyph_A42.png", GLYPH_A42_ASSET = "file")
load("images/glyph_A43.png", GLYPH_A43_ASSET = "file")
load("images/glyph_A44.png", GLYPH_A44_ASSET = "file")
load("images/glyph_A45.png", GLYPH_A45_ASSET = "file")
load("images/glyph_A46.png", GLYPH_A46_ASSET = "file")
load("images/glyph_A47.png", GLYPH_A47_ASSET = "file")
load("images/glyph_A48.png", GLYPH_A48_ASSET = "file")
load("images/glyph_A49.png", GLYPH_A49_ASSET = "file")
load("images/glyph_A5.png", GLYPH_A5_ASSET = "file")
load("images/glyph_A50.png", GLYPH_A50_ASSET = "file")
load("images/glyph_A51.png", GLYPH_A51_ASSET = "file")
load("images/glyph_A52.png", GLYPH_A52_ASSET = "file")
load("images/glyph_A53.png", GLYPH_A53_ASSET = "file")
load("images/glyph_A54.png", GLYPH_A54_ASSET = "file")
load("images/glyph_A55.png", GLYPH_A55_ASSET = "file")
load("images/glyph_A56.png", GLYPH_A56_ASSET = "file")
load("images/glyph_A59.png", GLYPH_A59_ASSET = "file")
load("images/glyph_A6.png", GLYPH_A6_ASSET = "file")
load("images/glyph_A7.png", GLYPH_A7_ASSET = "file")
load("images/glyph_A8.png", GLYPH_A8_ASSET = "file")
load("images/glyph_A9.png", GLYPH_A9_ASSET = "file")
load("images/glyph_Aa1.png", GLYPH_AA1_ASSET = "file")
load("images/glyph_Aa10.png", GLYPH_AA10_ASSET = "file")
load("images/glyph_Aa11.png", GLYPH_AA11_ASSET = "file")
load("images/glyph_Aa12.png", GLYPH_AA12_ASSET = "file")
load("images/glyph_Aa13.png", GLYPH_AA13_ASSET = "file")
load("images/glyph_Aa14.png", GLYPH_AA14_ASSET = "file")
load("images/glyph_Aa15.png", GLYPH_AA15_ASSET = "file")
load("images/glyph_Aa16.png", GLYPH_AA16_ASSET = "file")
load("images/glyph_Aa17.png", GLYPH_AA17_ASSET = "file")
load("images/glyph_Aa18.png", GLYPH_AA18_ASSET = "file")
load("images/glyph_Aa19.png", GLYPH_AA19_ASSET = "file")
load("images/glyph_Aa2.png", GLYPH_AA2_ASSET = "file")
load("images/glyph_Aa20.png", GLYPH_AA20_ASSET = "file")
load("images/glyph_Aa21.png", GLYPH_AA21_ASSET = "file")
load("images/glyph_Aa22.png", GLYPH_AA22_ASSET = "file")
load("images/glyph_Aa23.png", GLYPH_AA23_ASSET = "file")
load("images/glyph_Aa24.png", GLYPH_AA24_ASSET = "file")
load("images/glyph_Aa25.png", GLYPH_AA25_ASSET = "file")
load("images/glyph_Aa26.png", GLYPH_AA26_ASSET = "file")
load("images/glyph_Aa27.png", GLYPH_AA27_ASSET = "file")
load("images/glyph_Aa28.png", GLYPH_AA28_ASSET = "file")
load("images/glyph_Aa29.png", GLYPH_AA29_ASSET = "file")
load("images/glyph_Aa3.png", GLYPH_AA3_ASSET = "file")
load("images/glyph_Aa30.png", GLYPH_AA30_ASSET = "file")
load("images/glyph_Aa31.png", GLYPH_AA31_ASSET = "file")
load("images/glyph_Aa32.png", GLYPH_AA32_ASSET = "file")
load("images/glyph_Aa4.png", GLYPH_AA4_ASSET = "file")
load("images/glyph_Aa40.png", GLYPH_AA40_ASSET = "file")
load("images/glyph_Aa41.png", GLYPH_AA41_ASSET = "file")
load("images/glyph_Aa5.png", GLYPH_AA5_ASSET = "file")
load("images/glyph_Aa6.png", GLYPH_AA6_ASSET = "file")
load("images/glyph_Aa7.png", GLYPH_AA7_ASSET = "file")
load("images/glyph_Aa8.png", GLYPH_AA8_ASSET = "file")
load("images/glyph_Aa9.png", GLYPH_AA9_ASSET = "file")
load("images/glyph_B1.png", GLYPH_B1_ASSET = "file")
load("images/glyph_B10.png", GLYPH_B10_ASSET = "file")
load("images/glyph_B11.png", GLYPH_B11_ASSET = "file")
load("images/glyph_B12.png", GLYPH_B12_ASSET = "file")
load("images/glyph_B2.png", GLYPH_B2_ASSET = "file")
load("images/glyph_B3.png", GLYPH_B3_ASSET = "file")
load("images/glyph_B4.png", GLYPH_B4_ASSET = "file")
load("images/glyph_B5.png", GLYPH_B5_ASSET = "file")
load("images/glyph_B6.png", GLYPH_B6_ASSET = "file")
load("images/glyph_B7.png", GLYPH_B7_ASSET = "file")
load("images/glyph_B8.png", GLYPH_B8_ASSET = "file")
load("images/glyph_B9.png", GLYPH_B9_ASSET = "file")
load("images/glyph_C1.png", GLYPH_C1_ASSET = "file")
load("images/glyph_C10.png", GLYPH_C10_ASSET = "file")
load("images/glyph_C11.png", GLYPH_C11_ASSET = "file")
load("images/glyph_C12.png", GLYPH_C12_ASSET = "file")
load("images/glyph_C17.png", GLYPH_C17_ASSET = "file")
load("images/glyph_C18.png", GLYPH_C18_ASSET = "file")
load("images/glyph_C19.png", GLYPH_C19_ASSET = "file")
load("images/glyph_C2.png", GLYPH_C2_ASSET = "file")
load("images/glyph_C20.png", GLYPH_C20_ASSET = "file")
load("images/glyph_C3.png", GLYPH_C3_ASSET = "file")
load("images/glyph_C4.png", GLYPH_C4_ASSET = "file")
load("images/glyph_C5.png", GLYPH_C5_ASSET = "file")
load("images/glyph_C6.png", GLYPH_C6_ASSET = "file")
load("images/glyph_C7.png", GLYPH_C7_ASSET = "file")
load("images/glyph_C8.png", GLYPH_C8_ASSET = "file")
load("images/glyph_C9.png", GLYPH_C9_ASSET = "file")
load("images/glyph_D1.png", GLYPH_D1_ASSET = "file")
load("images/glyph_D10.png", GLYPH_D10_ASSET = "file")
load("images/glyph_D11.png", GLYPH_D11_ASSET = "file")
load("images/glyph_D12.png", GLYPH_D12_ASSET = "file")
load("images/glyph_D13.png", GLYPH_D13_ASSET = "file")
load("images/glyph_D14.png", GLYPH_D14_ASSET = "file")
load("images/glyph_D15.png", GLYPH_D15_ASSET = "file")
load("images/glyph_D16.png", GLYPH_D16_ASSET = "file")
load("images/glyph_D17.png", GLYPH_D17_ASSET = "file")
load("images/glyph_D18.png", GLYPH_D18_ASSET = "file")
load("images/glyph_D19.png", GLYPH_D19_ASSET = "file")
load("images/glyph_D2.png", GLYPH_D2_ASSET = "file")
load("images/glyph_D20.png", GLYPH_D20_ASSET = "file")
load("images/glyph_D21.png", GLYPH_D21_ASSET = "file")
load("images/glyph_D22.png", GLYPH_D22_ASSET = "file")
load("images/glyph_D23.png", GLYPH_D23_ASSET = "file")
load("images/glyph_D24.png", GLYPH_D24_ASSET = "file")
load("images/glyph_D25.png", GLYPH_D25_ASSET = "file")
load("images/glyph_D26.png", GLYPH_D26_ASSET = "file")
load("images/glyph_D27.png", GLYPH_D27_ASSET = "file")
load("images/glyph_D28.png", GLYPH_D28_ASSET = "file")
load("images/glyph_D29.png", GLYPH_D29_ASSET = "file")
load("images/glyph_D3.png", GLYPH_D3_ASSET = "file")
load("images/glyph_D30.png", GLYPH_D30_ASSET = "file")
load("images/glyph_D31.png", GLYPH_D31_ASSET = "file")
load("images/glyph_D32.png", GLYPH_D32_ASSET = "file")
load("images/glyph_D33.png", GLYPH_D33_ASSET = "file")
load("images/glyph_D34.png", GLYPH_D34_ASSET = "file")
load("images/glyph_D35.png", GLYPH_D35_ASSET = "file")
load("images/glyph_D36.png", GLYPH_D36_ASSET = "file")
load("images/glyph_D37.png", GLYPH_D37_ASSET = "file")
load("images/glyph_D38.png", GLYPH_D38_ASSET = "file")
load("images/glyph_D39.png", GLYPH_D39_ASSET = "file")
load("images/glyph_D4.png", GLYPH_D4_ASSET = "file")
load("images/glyph_D40.png", GLYPH_D40_ASSET = "file")
load("images/glyph_D41.png", GLYPH_D41_ASSET = "file")
load("images/glyph_D42.png", GLYPH_D42_ASSET = "file")
load("images/glyph_D43.png", GLYPH_D43_ASSET = "file")
load("images/glyph_D44.png", GLYPH_D44_ASSET = "file")
load("images/glyph_D45.png", GLYPH_D45_ASSET = "file")
load("images/glyph_D46.png", GLYPH_D46_ASSET = "file")
load("images/glyph_D47.png", GLYPH_D47_ASSET = "file")
load("images/glyph_D48.png", GLYPH_D48_ASSET = "file")
load("images/glyph_D49.png", GLYPH_D49_ASSET = "file")
load("images/glyph_D5.png", GLYPH_D5_ASSET = "file")
load("images/glyph_D50.png", GLYPH_D50_ASSET = "file")
load("images/glyph_D51.png", GLYPH_D51_ASSET = "file")
load("images/glyph_D52.png", GLYPH_D52_ASSET = "file")
load("images/glyph_D53.png", GLYPH_D53_ASSET = "file")
load("images/glyph_D54.png", GLYPH_D54_ASSET = "file")
load("images/glyph_D55.png", GLYPH_D55_ASSET = "file")
load("images/glyph_D56.png", GLYPH_D56_ASSET = "file")
load("images/glyph_D57.png", GLYPH_D57_ASSET = "file")
load("images/glyph_D58.png", GLYPH_D58_ASSET = "file")
load("images/glyph_D59.png", GLYPH_D59_ASSET = "file")
load("images/glyph_D6.png", GLYPH_D6_ASSET = "file")
load("images/glyph_D60.png", GLYPH_D60_ASSET = "file")
load("images/glyph_D61.png", GLYPH_D61_ASSET = "file")
load("images/glyph_D62.png", GLYPH_D62_ASSET = "file")
load("images/glyph_D63.png", GLYPH_D63_ASSET = "file")
load("images/glyph_D7.png", GLYPH_D7_ASSET = "file")
load("images/glyph_D8.png", GLYPH_D8_ASSET = "file")
load("images/glyph_D9.png", GLYPH_D9_ASSET = "file")
load("images/glyph_E1.png", GLYPH_E1_ASSET = "file")
load("images/glyph_E10.png", GLYPH_E10_ASSET = "file")
load("images/glyph_E11.png", GLYPH_E11_ASSET = "file")
load("images/glyph_E12.png", GLYPH_E12_ASSET = "file")
load("images/glyph_E13.png", GLYPH_E13_ASSET = "file")
load("images/glyph_E14.png", GLYPH_E14_ASSET = "file")
load("images/glyph_E15.png", GLYPH_E15_ASSET = "file")
load("images/glyph_E16.png", GLYPH_E16_ASSET = "file")
load("images/glyph_E17.png", GLYPH_E17_ASSET = "file")
load("images/glyph_E18.png", GLYPH_E18_ASSET = "file")
load("images/glyph_E19.png", GLYPH_E19_ASSET = "file")
load("images/glyph_E2.png", GLYPH_E2_ASSET = "file")
load("images/glyph_E20.png", GLYPH_E20_ASSET = "file")
load("images/glyph_E21.png", GLYPH_E21_ASSET = "file")
load("images/glyph_E22.png", GLYPH_E22_ASSET = "file")
load("images/glyph_E23.png", GLYPH_E23_ASSET = "file")
load("images/glyph_E24.png", GLYPH_E24_ASSET = "file")
load("images/glyph_E25.png", GLYPH_E25_ASSET = "file")
load("images/glyph_E26.png", GLYPH_E26_ASSET = "file")
load("images/glyph_E27.png", GLYPH_E27_ASSET = "file")
load("images/glyph_E28.png", GLYPH_E28_ASSET = "file")
load("images/glyph_E29.png", GLYPH_E29_ASSET = "file")
load("images/glyph_E3.png", GLYPH_E3_ASSET = "file")
load("images/glyph_E30.png", GLYPH_E30_ASSET = "file")
load("images/glyph_E31.png", GLYPH_E31_ASSET = "file")
load("images/glyph_E32.png", GLYPH_E32_ASSET = "file")
load("images/glyph_E33.png", GLYPH_E33_ASSET = "file")
load("images/glyph_E34.png", GLYPH_E34_ASSET = "file")
load("images/glyph_E4.png", GLYPH_E4_ASSET = "file")
load("images/glyph_E5.png", GLYPH_E5_ASSET = "file")
load("images/glyph_E6.png", GLYPH_E6_ASSET = "file")
load("images/glyph_E7.png", GLYPH_E7_ASSET = "file")
load("images/glyph_E8.png", GLYPH_E8_ASSET = "file")
load("images/glyph_E9.png", GLYPH_E9_ASSET = "file")
load("images/glyph_F1.png", GLYPH_F1_ASSET = "file")
load("images/glyph_F10.png", GLYPH_F10_ASSET = "file")
load("images/glyph_F11.png", GLYPH_F11_ASSET = "file")
load("images/glyph_F12.png", GLYPH_F12_ASSET = "file")
load("images/glyph_F13.png", GLYPH_F13_ASSET = "file")
load("images/glyph_F14.png", GLYPH_F14_ASSET = "file")
load("images/glyph_F15.png", GLYPH_F15_ASSET = "file")
load("images/glyph_F16.png", GLYPH_F16_ASSET = "file")
load("images/glyph_F17.png", GLYPH_F17_ASSET = "file")
load("images/glyph_F18.png", GLYPH_F18_ASSET = "file")
load("images/glyph_F19.png", GLYPH_F19_ASSET = "file")
load("images/glyph_F2.png", GLYPH_F2_ASSET = "file")
load("images/glyph_F20.png", GLYPH_F20_ASSET = "file")
load("images/glyph_F21.png", GLYPH_F21_ASSET = "file")
load("images/glyph_F22.png", GLYPH_F22_ASSET = "file")
load("images/glyph_F23.png", GLYPH_F23_ASSET = "file")
load("images/glyph_F24.png", GLYPH_F24_ASSET = "file")
load("images/glyph_F25.png", GLYPH_F25_ASSET = "file")
load("images/glyph_F26.png", GLYPH_F26_ASSET = "file")
load("images/glyph_F27.png", GLYPH_F27_ASSET = "file")
load("images/glyph_F28.png", GLYPH_F28_ASSET = "file")
load("images/glyph_F29.png", GLYPH_F29_ASSET = "file")
load("images/glyph_F3.png", GLYPH_F3_ASSET = "file")
load("images/glyph_F30.png", GLYPH_F30_ASSET = "file")
load("images/glyph_F31.png", GLYPH_F31_ASSET = "file")
load("images/glyph_F32.png", GLYPH_F32_ASSET = "file")
load("images/glyph_F33.png", GLYPH_F33_ASSET = "file")
load("images/glyph_F34.png", GLYPH_F34_ASSET = "file")
load("images/glyph_F35.png", GLYPH_F35_ASSET = "file")
load("images/glyph_F36.png", GLYPH_F36_ASSET = "file")
load("images/glyph_F37.png", GLYPH_F37_ASSET = "file")
load("images/glyph_F38.png", GLYPH_F38_ASSET = "file")
load("images/glyph_F39.png", GLYPH_F39_ASSET = "file")
load("images/glyph_F4.png", GLYPH_F4_ASSET = "file")
load("images/glyph_F40.png", GLYPH_F40_ASSET = "file")
load("images/glyph_F41.png", GLYPH_F41_ASSET = "file")
load("images/glyph_F42.png", GLYPH_F42_ASSET = "file")
load("images/glyph_F43.png", GLYPH_F43_ASSET = "file")
load("images/glyph_F44.png", GLYPH_F44_ASSET = "file")
load("images/glyph_F45.png", GLYPH_F45_ASSET = "file")
load("images/glyph_F46.png", GLYPH_F46_ASSET = "file")
load("images/glyph_F47.png", GLYPH_F47_ASSET = "file")
load("images/glyph_F48.png", GLYPH_F48_ASSET = "file")
load("images/glyph_F49.png", GLYPH_F49_ASSET = "file")
load("images/glyph_F5.png", GLYPH_F5_ASSET = "file")
load("images/glyph_F50.png", GLYPH_F50_ASSET = "file")
load("images/glyph_F51.png", GLYPH_F51_ASSET = "file")
load("images/glyph_F52.png", GLYPH_F52_ASSET = "file")
load("images/glyph_F6.png", GLYPH_F6_ASSET = "file")
load("images/glyph_F7.png", GLYPH_F7_ASSET = "file")
load("images/glyph_F8.png", GLYPH_F8_ASSET = "file")
load("images/glyph_F9.png", GLYPH_F9_ASSET = "file")
load("images/glyph_G1.png", GLYPH_G1_ASSET = "file")
load("images/glyph_G10.png", GLYPH_G10_ASSET = "file")
load("images/glyph_G11.png", GLYPH_G11_ASSET = "file")
load("images/glyph_G12.png", GLYPH_G12_ASSET = "file")
load("images/glyph_G13.png", GLYPH_G13_ASSET = "file")
load("images/glyph_G14.png", GLYPH_G14_ASSET = "file")
load("images/glyph_G15.png", GLYPH_G15_ASSET = "file")
load("images/glyph_G16.png", GLYPH_G16_ASSET = "file")
load("images/glyph_G17.png", GLYPH_G17_ASSET = "file")
load("images/glyph_G18.png", GLYPH_G18_ASSET = "file")
load("images/glyph_G19.png", GLYPH_G19_ASSET = "file")
load("images/glyph_G2.png", GLYPH_G2_ASSET = "file")
load("images/glyph_G20.png", GLYPH_G20_ASSET = "file")
load("images/glyph_G21.png", GLYPH_G21_ASSET = "file")
load("images/glyph_G22.png", GLYPH_G22_ASSET = "file")
load("images/glyph_G23.png", GLYPH_G23_ASSET = "file")
load("images/glyph_G24.png", GLYPH_G24_ASSET = "file")
load("images/glyph_G25.png", GLYPH_G25_ASSET = "file")
load("images/glyph_G26.png", GLYPH_G26_ASSET = "file")
load("images/glyph_G27.png", GLYPH_G27_ASSET = "file")
load("images/glyph_G28.png", GLYPH_G28_ASSET = "file")
load("images/glyph_G29.png", GLYPH_G29_ASSET = "file")
load("images/glyph_G3.png", GLYPH_G3_ASSET = "file")
load("images/glyph_G30.png", GLYPH_G30_ASSET = "file")
load("images/glyph_G31.png", GLYPH_G31_ASSET = "file")
load("images/glyph_G32.png", GLYPH_G32_ASSET = "file")
load("images/glyph_G33.png", GLYPH_G33_ASSET = "file")
load("images/glyph_G34.png", GLYPH_G34_ASSET = "file")
load("images/glyph_G35.png", GLYPH_G35_ASSET = "file")
load("images/glyph_G36.png", GLYPH_G36_ASSET = "file")
load("images/glyph_G37.png", GLYPH_G37_ASSET = "file")
load("images/glyph_G38.png", GLYPH_G38_ASSET = "file")
load("images/glyph_G39.png", GLYPH_G39_ASSET = "file")
load("images/glyph_G4.png", GLYPH_G4_ASSET = "file")
load("images/glyph_G40.png", GLYPH_G40_ASSET = "file")
load("images/glyph_G41.png", GLYPH_G41_ASSET = "file")
load("images/glyph_G42.png", GLYPH_G42_ASSET = "file")
load("images/glyph_G43.png", GLYPH_G43_ASSET = "file")
load("images/glyph_G44.png", GLYPH_G44_ASSET = "file")
load("images/glyph_G45.png", GLYPH_G45_ASSET = "file")
load("images/glyph_G46.png", GLYPH_G46_ASSET = "file")
load("images/glyph_G47.png", GLYPH_G47_ASSET = "file")
load("images/glyph_G48.png", GLYPH_G48_ASSET = "file")
load("images/glyph_G49.png", GLYPH_G49_ASSET = "file")
load("images/glyph_G5.png", GLYPH_G5_ASSET = "file")
load("images/glyph_G50.png", GLYPH_G50_ASSET = "file")
load("images/glyph_G51.png", GLYPH_G51_ASSET = "file")
load("images/glyph_G52.png", GLYPH_G52_ASSET = "file")
load("images/glyph_G53.png", GLYPH_G53_ASSET = "file")
load("images/glyph_G54.png", GLYPH_G54_ASSET = "file")
load("images/glyph_G6.png", GLYPH_G6_ASSET = "file")
load("images/glyph_G7.png", GLYPH_G7_ASSET = "file")
load("images/glyph_G8.png", GLYPH_G8_ASSET = "file")
load("images/glyph_G9.png", GLYPH_G9_ASSET = "file")
load("images/glyph_H1.png", GLYPH_H1_ASSET = "file")
load("images/glyph_H2.png", GLYPH_H2_ASSET = "file")
load("images/glyph_H3.png", GLYPH_H3_ASSET = "file")
load("images/glyph_H4.png", GLYPH_H4_ASSET = "file")
load("images/glyph_H5.png", GLYPH_H5_ASSET = "file")
load("images/glyph_H6.png", GLYPH_H6_ASSET = "file")
load("images/glyph_H7.png", GLYPH_H7_ASSET = "file")
load("images/glyph_H8.png", GLYPH_H8_ASSET = "file")
load("images/glyph_I1.png", GLYPH_I1_ASSET = "file")
load("images/glyph_I10.png", GLYPH_I10_ASSET = "file")
load("images/glyph_I11.png", GLYPH_I11_ASSET = "file")
load("images/glyph_I12.png", GLYPH_I12_ASSET = "file")
load("images/glyph_I13.png", GLYPH_I13_ASSET = "file")
load("images/glyph_I14.png", GLYPH_I14_ASSET = "file")
load("images/glyph_I15.png", GLYPH_I15_ASSET = "file")
load("images/glyph_I2.png", GLYPH_I2_ASSET = "file")
load("images/glyph_I3.png", GLYPH_I3_ASSET = "file")
load("images/glyph_I4.png", GLYPH_I4_ASSET = "file")
load("images/glyph_I5.png", GLYPH_I5_ASSET = "file")
load("images/glyph_I6.png", GLYPH_I6_ASSET = "file")
load("images/glyph_I7.png", GLYPH_I7_ASSET = "file")
load("images/glyph_I8.png", GLYPH_I8_ASSET = "file")
load("images/glyph_I9.png", GLYPH_I9_ASSET = "file")
load("images/glyph_K1.png", GLYPH_K1_ASSET = "file")
load("images/glyph_K2.png", GLYPH_K2_ASSET = "file")
load("images/glyph_K3.png", GLYPH_K3_ASSET = "file")
load("images/glyph_K4.png", GLYPH_K4_ASSET = "file")
load("images/glyph_K5.png", GLYPH_K5_ASSET = "file")
load("images/glyph_K6.png", GLYPH_K6_ASSET = "file")
load("images/glyph_K7.png", GLYPH_K7_ASSET = "file")
load("images/glyph_L1.png", GLYPH_L1_ASSET = "file")
load("images/glyph_L2.png", GLYPH_L2_ASSET = "file")
load("images/glyph_L3.png", GLYPH_L3_ASSET = "file")
load("images/glyph_L4.png", GLYPH_L4_ASSET = "file")
load("images/glyph_L5.png", GLYPH_L5_ASSET = "file")
load("images/glyph_L6.png", GLYPH_L6_ASSET = "file")
load("images/glyph_L7.png", GLYPH_L7_ASSET = "file")
load("images/glyph_M1.png", GLYPH_M1_ASSET = "file")
load("images/glyph_M10.png", GLYPH_M10_ASSET = "file")
load("images/glyph_M11.png", GLYPH_M11_ASSET = "file")
load("images/glyph_M12.png", GLYPH_M12_ASSET = "file")
load("images/glyph_M13.png", GLYPH_M13_ASSET = "file")
load("images/glyph_M14.png", GLYPH_M14_ASSET = "file")
load("images/glyph_M15.png", GLYPH_M15_ASSET = "file")
load("images/glyph_M16.png", GLYPH_M16_ASSET = "file")
load("images/glyph_M17.png", GLYPH_M17_ASSET = "file")
load("images/glyph_M18.png", GLYPH_M18_ASSET = "file")
load("images/glyph_M19.png", GLYPH_M19_ASSET = "file")
load("images/glyph_M2.png", GLYPH_M2_ASSET = "file")
load("images/glyph_M20.png", GLYPH_M20_ASSET = "file")
load("images/glyph_M21.png", GLYPH_M21_ASSET = "file")
load("images/glyph_M22.png", GLYPH_M22_ASSET = "file")
load("images/glyph_M23.png", GLYPH_M23_ASSET = "file")
load("images/glyph_M24.png", GLYPH_M24_ASSET = "file")
load("images/glyph_M25.png", GLYPH_M25_ASSET = "file")
load("images/glyph_M26.png", GLYPH_M26_ASSET = "file")
load("images/glyph_M27.png", GLYPH_M27_ASSET = "file")
load("images/glyph_M28.png", GLYPH_M28_ASSET = "file")
load("images/glyph_M29.png", GLYPH_M29_ASSET = "file")
load("images/glyph_M3.png", GLYPH_M3_ASSET = "file")
load("images/glyph_M30.png", GLYPH_M30_ASSET = "file")
load("images/glyph_M31.png", GLYPH_M31_ASSET = "file")
load("images/glyph_M32.png", GLYPH_M32_ASSET = "file")
load("images/glyph_M33.png", GLYPH_M33_ASSET = "file")
load("images/glyph_M34.png", GLYPH_M34_ASSET = "file")
load("images/glyph_M35.png", GLYPH_M35_ASSET = "file")
load("images/glyph_M36.png", GLYPH_M36_ASSET = "file")
load("images/glyph_M37.png", GLYPH_M37_ASSET = "file")
load("images/glyph_M38.png", GLYPH_M38_ASSET = "file")
load("images/glyph_M39.png", GLYPH_M39_ASSET = "file")
load("images/glyph_M4.png", GLYPH_M4_ASSET = "file")
load("images/glyph_M40.png", GLYPH_M40_ASSET = "file")
load("images/glyph_M41.png", GLYPH_M41_ASSET = "file")
load("images/glyph_M42.png", GLYPH_M42_ASSET = "file")
load("images/glyph_M43.png", GLYPH_M43_ASSET = "file")
load("images/glyph_M44.png", GLYPH_M44_ASSET = "file")
load("images/glyph_M5.png", GLYPH_M5_ASSET = "file")
load("images/glyph_M6.png", GLYPH_M6_ASSET = "file")
load("images/glyph_M7.png", GLYPH_M7_ASSET = "file")
load("images/glyph_M8.png", GLYPH_M8_ASSET = "file")
load("images/glyph_M9.png", GLYPH_M9_ASSET = "file")
load("images/glyph_N1.png", GLYPH_N1_ASSET = "file")
load("images/glyph_N10.png", GLYPH_N10_ASSET = "file")
load("images/glyph_N11.png", GLYPH_N11_ASSET = "file")
load("images/glyph_N12.png", GLYPH_N12_ASSET = "file")
load("images/glyph_N13.png", GLYPH_N13_ASSET = "file")
load("images/glyph_N14.png", GLYPH_N14_ASSET = "file")
load("images/glyph_N15.png", GLYPH_N15_ASSET = "file")
load("images/glyph_N16.png", GLYPH_N16_ASSET = "file")
load("images/glyph_N17.png", GLYPH_N17_ASSET = "file")
load("images/glyph_N18.png", GLYPH_N18_ASSET = "file")
load("images/glyph_N19.png", GLYPH_N19_ASSET = "file")
load("images/glyph_N2.png", GLYPH_N2_ASSET = "file")
load("images/glyph_N20.png", GLYPH_N20_ASSET = "file")
load("images/glyph_N21.png", GLYPH_N21_ASSET = "file")
load("images/glyph_N22.png", GLYPH_N22_ASSET = "file")
load("images/glyph_N23.png", GLYPH_N23_ASSET = "file")
load("images/glyph_N24.png", GLYPH_N24_ASSET = "file")
load("images/glyph_N25.png", GLYPH_N25_ASSET = "file")
load("images/glyph_N26.png", GLYPH_N26_ASSET = "file")
load("images/glyph_N27.png", GLYPH_N27_ASSET = "file")
load("images/glyph_N28.png", GLYPH_N28_ASSET = "file")
load("images/glyph_N29.png", GLYPH_N29_ASSET = "file")
load("images/glyph_N3.png", GLYPH_N3_ASSET = "file")
load("images/glyph_N30.png", GLYPH_N30_ASSET = "file")
load("images/glyph_N31.png", GLYPH_N31_ASSET = "file")
load("images/glyph_N32.png", GLYPH_N32_ASSET = "file")
load("images/glyph_N33.png", GLYPH_N33_ASSET = "file")
load("images/glyph_N34.png", GLYPH_N34_ASSET = "file")
load("images/glyph_N35.png", GLYPH_N35_ASSET = "file")
load("images/glyph_N36.png", GLYPH_N36_ASSET = "file")
load("images/glyph_N37.png", GLYPH_N37_ASSET = "file")
load("images/glyph_N38.png", GLYPH_N38_ASSET = "file")
load("images/glyph_N39.png", GLYPH_N39_ASSET = "file")
load("images/glyph_N4.png", GLYPH_N4_ASSET = "file")
load("images/glyph_N40.png", GLYPH_N40_ASSET = "file")
load("images/glyph_N41.png", GLYPH_N41_ASSET = "file")
load("images/glyph_N42.png", GLYPH_N42_ASSET = "file")
load("images/glyph_N5.png", GLYPH_N5_ASSET = "file")
load("images/glyph_N6.png", GLYPH_N6_ASSET = "file")
load("images/glyph_N7.png", GLYPH_N7_ASSET = "file")
load("images/glyph_N8.png", GLYPH_N8_ASSET = "file")
load("images/glyph_N9.png", GLYPH_N9_ASSET = "file")
load("images/glyph_O1.png", GLYPH_O1_ASSET = "file")
load("images/glyph_O10.png", GLYPH_O10_ASSET = "file")
load("images/glyph_O11.png", GLYPH_O11_ASSET = "file")
load("images/glyph_O12.png", GLYPH_O12_ASSET = "file")
load("images/glyph_O13.png", GLYPH_O13_ASSET = "file")
load("images/glyph_O14.png", GLYPH_O14_ASSET = "file")
load("images/glyph_O15.png", GLYPH_O15_ASSET = "file")
load("images/glyph_O16.png", GLYPH_O16_ASSET = "file")
load("images/glyph_O17.png", GLYPH_O17_ASSET = "file")
load("images/glyph_O18.png", GLYPH_O18_ASSET = "file")
load("images/glyph_O19.png", GLYPH_O19_ASSET = "file")
load("images/glyph_O2.png", GLYPH_O2_ASSET = "file")
load("images/glyph_O20.png", GLYPH_O20_ASSET = "file")
load("images/glyph_O21.png", GLYPH_O21_ASSET = "file")
load("images/glyph_O22.png", GLYPH_O22_ASSET = "file")
load("images/glyph_O23.png", GLYPH_O23_ASSET = "file")
load("images/glyph_O24.png", GLYPH_O24_ASSET = "file")
load("images/glyph_O25.png", GLYPH_O25_ASSET = "file")
load("images/glyph_O26.png", GLYPH_O26_ASSET = "file")
load("images/glyph_O27.png", GLYPH_O27_ASSET = "file")
load("images/glyph_O28.png", GLYPH_O28_ASSET = "file")
load("images/glyph_O29.png", GLYPH_O29_ASSET = "file")
load("images/glyph_O3.png", GLYPH_O3_ASSET = "file")
load("images/glyph_O30.png", GLYPH_O30_ASSET = "file")
load("images/glyph_O31.png", GLYPH_O31_ASSET = "file")
load("images/glyph_O32.png", GLYPH_O32_ASSET = "file")
load("images/glyph_O33.png", GLYPH_O33_ASSET = "file")
load("images/glyph_O34.png", GLYPH_O34_ASSET = "file")
load("images/glyph_O35.png", GLYPH_O35_ASSET = "file")
load("images/glyph_O36.png", GLYPH_O36_ASSET = "file")
load("images/glyph_O37.png", GLYPH_O37_ASSET = "file")
load("images/glyph_O38.png", GLYPH_O38_ASSET = "file")
load("images/glyph_O39.png", GLYPH_O39_ASSET = "file")
load("images/glyph_O4.png", GLYPH_O4_ASSET = "file")
load("images/glyph_O40.png", GLYPH_O40_ASSET = "file")
load("images/glyph_O41.png", GLYPH_O41_ASSET = "file")
load("images/glyph_O42.png", GLYPH_O42_ASSET = "file")
load("images/glyph_O43.png", GLYPH_O43_ASSET = "file")
load("images/glyph_O44.png", GLYPH_O44_ASSET = "file")
load("images/glyph_O45.png", GLYPH_O45_ASSET = "file")
load("images/glyph_O46.png", GLYPH_O46_ASSET = "file")
load("images/glyph_O47.png", GLYPH_O47_ASSET = "file")
load("images/glyph_O48.png", GLYPH_O48_ASSET = "file")
load("images/glyph_O49.png", GLYPH_O49_ASSET = "file")
load("images/glyph_O5.png", GLYPH_O5_ASSET = "file")
load("images/glyph_O50.png", GLYPH_O50_ASSET = "file")
load("images/glyph_O51.png", GLYPH_O51_ASSET = "file")
load("images/glyph_O6.png", GLYPH_O6_ASSET = "file")
load("images/glyph_O7.png", GLYPH_O7_ASSET = "file")
load("images/glyph_O8.png", GLYPH_O8_ASSET = "file")
load("images/glyph_O9.png", GLYPH_O9_ASSET = "file")
load("images/glyph_P1.png", GLYPH_P1_ASSET = "file")
load("images/glyph_P10.png", GLYPH_P10_ASSET = "file")
load("images/glyph_P11.png", GLYPH_P11_ASSET = "file")
load("images/glyph_P13.png", GLYPH_P13_ASSET = "file")
load("images/glyph_P2.png", GLYPH_P2_ASSET = "file")
load("images/glyph_P3.png", GLYPH_P3_ASSET = "file")
load("images/glyph_P4.png", GLYPH_P4_ASSET = "file")
load("images/glyph_P5.png", GLYPH_P5_ASSET = "file")
load("images/glyph_P6.png", GLYPH_P6_ASSET = "file")
load("images/glyph_P7.png", GLYPH_P7_ASSET = "file")
load("images/glyph_P8.png", GLYPH_P8_ASSET = "file")
load("images/glyph_P9.png", GLYPH_P9_ASSET = "file")
load("images/glyph_Q1.png", GLYPH_Q1_ASSET = "file")
load("images/glyph_Q2.png", GLYPH_Q2_ASSET = "file")
load("images/glyph_Q3.png", GLYPH_Q3_ASSET = "file")
load("images/glyph_Q4.png", GLYPH_Q4_ASSET = "file")
load("images/glyph_Q5.png", GLYPH_Q5_ASSET = "file")
load("images/glyph_Q6.png", GLYPH_Q6_ASSET = "file")
load("images/glyph_Q7.png", GLYPH_Q7_ASSET = "file")
load("images/glyph_R1.png", GLYPH_R1_ASSET = "file")
load("images/glyph_R10.png", GLYPH_R10_ASSET = "file")
load("images/glyph_R11.png", GLYPH_R11_ASSET = "file")
load("images/glyph_R12.png", GLYPH_R12_ASSET = "file")
load("images/glyph_R13.png", GLYPH_R13_ASSET = "file")
load("images/glyph_R14.png", GLYPH_R14_ASSET = "file")
load("images/glyph_R15.png", GLYPH_R15_ASSET = "file")
load("images/glyph_R16.png", GLYPH_R16_ASSET = "file")
load("images/glyph_R17.png", GLYPH_R17_ASSET = "file")
load("images/glyph_R18.png", GLYPH_R18_ASSET = "file")
load("images/glyph_R19.png", GLYPH_R19_ASSET = "file")
load("images/glyph_R2.png", GLYPH_R2_ASSET = "file")
load("images/glyph_R20.png", GLYPH_R20_ASSET = "file")
load("images/glyph_R21.png", GLYPH_R21_ASSET = "file")
load("images/glyph_R22.png", GLYPH_R22_ASSET = "file")
load("images/glyph_R23.png", GLYPH_R23_ASSET = "file")
load("images/glyph_R24.png", GLYPH_R24_ASSET = "file")
load("images/glyph_R25.png", GLYPH_R25_ASSET = "file")
load("images/glyph_R3.png", GLYPH_R3_ASSET = "file")
load("images/glyph_R4.png", GLYPH_R4_ASSET = "file")
load("images/glyph_R5.png", GLYPH_R5_ASSET = "file")
load("images/glyph_R6.png", GLYPH_R6_ASSET = "file")
load("images/glyph_R7.png", GLYPH_R7_ASSET = "file")
load("images/glyph_R8.png", GLYPH_R8_ASSET = "file")
load("images/glyph_R9.png", GLYPH_R9_ASSET = "file")
load("images/glyph_S1.png", GLYPH_S1_ASSET = "file")
load("images/glyph_S10.png", GLYPH_S10_ASSET = "file")
load("images/glyph_S11.png", GLYPH_S11_ASSET = "file")
load("images/glyph_S12.png", GLYPH_S12_ASSET = "file")
load("images/glyph_S13.png", GLYPH_S13_ASSET = "file")
load("images/glyph_S14.png", GLYPH_S14_ASSET = "file")
load("images/glyph_S15.png", GLYPH_S15_ASSET = "file")
load("images/glyph_S16.png", GLYPH_S16_ASSET = "file")
load("images/glyph_S17.png", GLYPH_S17_ASSET = "file")
load("images/glyph_S18.png", GLYPH_S18_ASSET = "file")
load("images/glyph_S19.png", GLYPH_S19_ASSET = "file")
load("images/glyph_S2.png", GLYPH_S2_ASSET = "file")
load("images/glyph_S20.png", GLYPH_S20_ASSET = "file")
load("images/glyph_S21.png", GLYPH_S21_ASSET = "file")
load("images/glyph_S22.png", GLYPH_S22_ASSET = "file")
load("images/glyph_S23.png", GLYPH_S23_ASSET = "file")
load("images/glyph_S24.png", GLYPH_S24_ASSET = "file")
load("images/glyph_S25.png", GLYPH_S25_ASSET = "file")
load("images/glyph_S26.png", GLYPH_S26_ASSET = "file")
load("images/glyph_S27.png", GLYPH_S27_ASSET = "file")
load("images/glyph_S28.png", GLYPH_S28_ASSET = "file")
load("images/glyph_S29.png", GLYPH_S29_ASSET = "file")
load("images/glyph_S3.png", GLYPH_S3_ASSET = "file")
load("images/glyph_S30.png", GLYPH_S30_ASSET = "file")
load("images/glyph_S31.png", GLYPH_S31_ASSET = "file")
load("images/glyph_S32.png", GLYPH_S32_ASSET = "file")
load("images/glyph_S33.png", GLYPH_S33_ASSET = "file")
load("images/glyph_S34.png", GLYPH_S34_ASSET = "file")
load("images/glyph_S35.png", GLYPH_S35_ASSET = "file")
load("images/glyph_S36.png", GLYPH_S36_ASSET = "file")
load("images/glyph_S37.png", GLYPH_S37_ASSET = "file")
load("images/glyph_S38.png", GLYPH_S38_ASSET = "file")
load("images/glyph_S39.png", GLYPH_S39_ASSET = "file")
load("images/glyph_S4.png", GLYPH_S4_ASSET = "file")
load("images/glyph_S40.png", GLYPH_S40_ASSET = "file")
load("images/glyph_S41.png", GLYPH_S41_ASSET = "file")
load("images/glyph_S42.png", GLYPH_S42_ASSET = "file")
load("images/glyph_S43.png", GLYPH_S43_ASSET = "file")
load("images/glyph_S44.png", GLYPH_S44_ASSET = "file")
load("images/glyph_S45.png", GLYPH_S45_ASSET = "file")
load("images/glyph_S5.png", GLYPH_S5_ASSET = "file")
load("images/glyph_S6.png", GLYPH_S6_ASSET = "file")
load("images/glyph_S7.png", GLYPH_S7_ASSET = "file")
load("images/glyph_S8.png", GLYPH_S8_ASSET = "file")
load("images/glyph_S9.png", GLYPH_S9_ASSET = "file")
load("images/glyph_T1.png", GLYPH_T1_ASSET = "file")
load("images/glyph_T10.png", GLYPH_T10_ASSET = "file")
load("images/glyph_T11.png", GLYPH_T11_ASSET = "file")
load("images/glyph_T12.png", GLYPH_T12_ASSET = "file")
load("images/glyph_T13.png", GLYPH_T13_ASSET = "file")
load("images/glyph_T14.png", GLYPH_T14_ASSET = "file")
load("images/glyph_T15.png", GLYPH_T15_ASSET = "file")
load("images/glyph_T16.png", GLYPH_T16_ASSET = "file")
load("images/glyph_T17.png", GLYPH_T17_ASSET = "file")
load("images/glyph_T18.png", GLYPH_T18_ASSET = "file")
load("images/glyph_T19.png", GLYPH_T19_ASSET = "file")
load("images/glyph_T2.png", GLYPH_T2_ASSET = "file")
load("images/glyph_T20.png", GLYPH_T20_ASSET = "file")
load("images/glyph_T21.png", GLYPH_T21_ASSET = "file")
load("images/glyph_T22.png", GLYPH_T22_ASSET = "file")
load("images/glyph_T23.png", GLYPH_T23_ASSET = "file")
load("images/glyph_T24.png", GLYPH_T24_ASSET = "file")
load("images/glyph_T25.png", GLYPH_T25_ASSET = "file")
load("images/glyph_T26.png", GLYPH_T26_ASSET = "file")
load("images/glyph_T27.png", GLYPH_T27_ASSET = "file")
load("images/glyph_T28.png", GLYPH_T28_ASSET = "file")
load("images/glyph_T29.png", GLYPH_T29_ASSET = "file")
load("images/glyph_T3.png", GLYPH_T3_ASSET = "file")
load("images/glyph_T30.png", GLYPH_T30_ASSET = "file")
load("images/glyph_T31.png", GLYPH_T31_ASSET = "file")
load("images/glyph_T32.png", GLYPH_T32_ASSET = "file")
load("images/glyph_T33.png", GLYPH_T33_ASSET = "file")
load("images/glyph_T34.png", GLYPH_T34_ASSET = "file")
load("images/glyph_T35.png", GLYPH_T35_ASSET = "file")
load("images/glyph_T4.png", GLYPH_T4_ASSET = "file")
load("images/glyph_T5.png", GLYPH_T5_ASSET = "file")
load("images/glyph_T6.png", GLYPH_T6_ASSET = "file")
load("images/glyph_T7.png", GLYPH_T7_ASSET = "file")
load("images/glyph_T8.png", GLYPH_T8_ASSET = "file")
load("images/glyph_T9.png", GLYPH_T9_ASSET = "file")
load("images/glyph_U1.png", GLYPH_U1_ASSET = "file")
load("images/glyph_U10.png", GLYPH_U10_ASSET = "file")
load("images/glyph_U11.png", GLYPH_U11_ASSET = "file")
load("images/glyph_U12.png", GLYPH_U12_ASSET = "file")
load("images/glyph_U13.png", GLYPH_U13_ASSET = "file")
load("images/glyph_U14.png", GLYPH_U14_ASSET = "file")
load("images/glyph_U15.png", GLYPH_U15_ASSET = "file")
load("images/glyph_U16.png", GLYPH_U16_ASSET = "file")
load("images/glyph_U17.png", GLYPH_U17_ASSET = "file")
load("images/glyph_U18.png", GLYPH_U18_ASSET = "file")
load("images/glyph_U19.png", GLYPH_U19_ASSET = "file")
load("images/glyph_U2.png", GLYPH_U2_ASSET = "file")
load("images/glyph_U20.png", GLYPH_U20_ASSET = "file")
load("images/glyph_U21.png", GLYPH_U21_ASSET = "file")
load("images/glyph_U22.png", GLYPH_U22_ASSET = "file")
load("images/glyph_U23.png", GLYPH_U23_ASSET = "file")
load("images/glyph_U24.png", GLYPH_U24_ASSET = "file")
load("images/glyph_U25.png", GLYPH_U25_ASSET = "file")
load("images/glyph_U26.png", GLYPH_U26_ASSET = "file")
load("images/glyph_U27.png", GLYPH_U27_ASSET = "file")
load("images/glyph_U28.png", GLYPH_U28_ASSET = "file")
load("images/glyph_U29.png", GLYPH_U29_ASSET = "file")
load("images/glyph_U3.png", GLYPH_U3_ASSET = "file")
load("images/glyph_U30.png", GLYPH_U30_ASSET = "file")
load("images/glyph_U31.png", GLYPH_U31_ASSET = "file")
load("images/glyph_U32.png", GLYPH_U32_ASSET = "file")
load("images/glyph_U33.png", GLYPH_U33_ASSET = "file")
load("images/glyph_U34.png", GLYPH_U34_ASSET = "file")
load("images/glyph_U35.png", GLYPH_U35_ASSET = "file")
load("images/glyph_U36.png", GLYPH_U36_ASSET = "file")
load("images/glyph_U37.png", GLYPH_U37_ASSET = "file")
load("images/glyph_U38.png", GLYPH_U38_ASSET = "file")
load("images/glyph_U39.png", GLYPH_U39_ASSET = "file")
load("images/glyph_U4.png", GLYPH_U4_ASSET = "file")
load("images/glyph_U40.png", GLYPH_U40_ASSET = "file")
load("images/glyph_U41.png", GLYPH_U41_ASSET = "file")
load("images/glyph_U5.png", GLYPH_U5_ASSET = "file")
load("images/glyph_U6.png", GLYPH_U6_ASSET = "file")
load("images/glyph_U7.png", GLYPH_U7_ASSET = "file")
load("images/glyph_U8.png", GLYPH_U8_ASSET = "file")
load("images/glyph_U9.png", GLYPH_U9_ASSET = "file")
load("images/glyph_V1.png", GLYPH_V1_ASSET = "file")
load("images/glyph_V10.png", GLYPH_V10_ASSET = "file")
load("images/glyph_V11.png", GLYPH_V11_ASSET = "file")
load("images/glyph_V12.png", GLYPH_V12_ASSET = "file")
load("images/glyph_V13.png", GLYPH_V13_ASSET = "file")
load("images/glyph_V14.png", GLYPH_V14_ASSET = "file")
load("images/glyph_V15.png", GLYPH_V15_ASSET = "file")
load("images/glyph_V16.png", GLYPH_V16_ASSET = "file")
load("images/glyph_V17.png", GLYPH_V17_ASSET = "file")
load("images/glyph_V18.png", GLYPH_V18_ASSET = "file")
load("images/glyph_V19.png", GLYPH_V19_ASSET = "file")
load("images/glyph_V2.png", GLYPH_V2_ASSET = "file")
load("images/glyph_V20.png", GLYPH_V20_ASSET = "file")
load("images/glyph_V21.png", GLYPH_V21_ASSET = "file")
load("images/glyph_V22.png", GLYPH_V22_ASSET = "file")
load("images/glyph_V23.png", GLYPH_V23_ASSET = "file")
load("images/glyph_V24.png", GLYPH_V24_ASSET = "file")
load("images/glyph_V25.png", GLYPH_V25_ASSET = "file")
load("images/glyph_V26.png", GLYPH_V26_ASSET = "file")
load("images/glyph_V27.png", GLYPH_V27_ASSET = "file")
load("images/glyph_V28.png", GLYPH_V28_ASSET = "file")
load("images/glyph_V29.png", GLYPH_V29_ASSET = "file")
load("images/glyph_V3.png", GLYPH_V3_ASSET = "file")
load("images/glyph_V30.png", GLYPH_V30_ASSET = "file")
load("images/glyph_V31.png", GLYPH_V31_ASSET = "file")
load("images/glyph_V32.png", GLYPH_V32_ASSET = "file")
load("images/glyph_V33.png", GLYPH_V33_ASSET = "file")
load("images/glyph_V34.png", GLYPH_V34_ASSET = "file")
load("images/glyph_V35.png", GLYPH_V35_ASSET = "file")
load("images/glyph_V36.png", GLYPH_V36_ASSET = "file")
load("images/glyph_V37.png", GLYPH_V37_ASSET = "file")
load("images/glyph_V38.png", GLYPH_V38_ASSET = "file")
load("images/glyph_V39.png", GLYPH_V39_ASSET = "file")
load("images/glyph_V4.png", GLYPH_V4_ASSET = "file")
load("images/glyph_V5.png", GLYPH_V5_ASSET = "file")
load("images/glyph_V6.png", GLYPH_V6_ASSET = "file")
load("images/glyph_V7.png", GLYPH_V7_ASSET = "file")
load("images/glyph_V8.png", GLYPH_V8_ASSET = "file")
load("images/glyph_V9.png", GLYPH_V9_ASSET = "file")
load("images/glyph_W1.png", GLYPH_W1_ASSET = "file")
load("images/glyph_W10.png", GLYPH_W10_ASSET = "file")
load("images/glyph_W11.png", GLYPH_W11_ASSET = "file")
load("images/glyph_W12.png", GLYPH_W12_ASSET = "file")
load("images/glyph_W13.png", GLYPH_W13_ASSET = "file")
load("images/glyph_W14.png", GLYPH_W14_ASSET = "file")
load("images/glyph_W15.png", GLYPH_W15_ASSET = "file")
load("images/glyph_W16.png", GLYPH_W16_ASSET = "file")
load("images/glyph_W17.png", GLYPH_W17_ASSET = "file")
load("images/glyph_W18.png", GLYPH_W18_ASSET = "file")
load("images/glyph_W19.png", GLYPH_W19_ASSET = "file")
load("images/glyph_W2.png", GLYPH_W2_ASSET = "file")
load("images/glyph_W20.png", GLYPH_W20_ASSET = "file")
load("images/glyph_W21.png", GLYPH_W21_ASSET = "file")
load("images/glyph_W22.png", GLYPH_W22_ASSET = "file")
load("images/glyph_W23.png", GLYPH_W23_ASSET = "file")
load("images/glyph_W24.png", GLYPH_W24_ASSET = "file")
load("images/glyph_W25.png", GLYPH_W25_ASSET = "file")
load("images/glyph_W3.png", GLYPH_W3_ASSET = "file")
load("images/glyph_W4.png", GLYPH_W4_ASSET = "file")
load("images/glyph_W5.png", GLYPH_W5_ASSET = "file")
load("images/glyph_W6.png", GLYPH_W6_ASSET = "file")
load("images/glyph_W7.png", GLYPH_W7_ASSET = "file")
load("images/glyph_W8.png", GLYPH_W8_ASSET = "file")
load("images/glyph_W9.png", GLYPH_W9_ASSET = "file")
load("images/glyph_X1.png", GLYPH_X1_ASSET = "file")
load("images/glyph_X2.png", GLYPH_X2_ASSET = "file")
load("images/glyph_X3.png", GLYPH_X3_ASSET = "file")
load("images/glyph_X4.png", GLYPH_X4_ASSET = "file")
load("images/glyph_X5.png", GLYPH_X5_ASSET = "file")
load("images/glyph_X6.png", GLYPH_X6_ASSET = "file")
load("images/glyph_X7.png", GLYPH_X7_ASSET = "file")
load("images/glyph_X8.png", GLYPH_X8_ASSET = "file")
load("images/glyph_Y1.png", GLYPH_Y1_ASSET = "file")
load("images/glyph_Y2.png", GLYPH_Y2_ASSET = "file")
load("images/glyph_Y3.png", GLYPH_Y3_ASSET = "file")
load("images/glyph_Y4.png", GLYPH_Y4_ASSET = "file")
load("images/glyph_Y5.png", GLYPH_Y5_ASSET = "file")
load("images/glyph_Y6.png", GLYPH_Y6_ASSET = "file")
load("images/glyph_Y7.png", GLYPH_Y7_ASSET = "file")
load("images/glyph_Y8.png", GLYPH_Y8_ASSET = "file")
load("images/glyph_Z1.png", GLYPH_Z1_ASSET = "file")
load("images/glyph_Z10.png", GLYPH_Z10_ASSET = "file")
load("images/glyph_Z11.png", GLYPH_Z11_ASSET = "file")
load("images/glyph_Z2.png", GLYPH_Z2_ASSET = "file")
load("images/glyph_Z3.png", GLYPH_Z3_ASSET = "file")
load("images/glyph_Z4.png", GLYPH_Z4_ASSET = "file")
load("images/glyph_Z5.png", GLYPH_Z5_ASSET = "file")
load("images/glyph_Z6.png", GLYPH_Z6_ASSET = "file")
load("images/glyph_Z7.png", GLYPH_Z7_ASSET = "file")
load("images/glyph_Z8.png", GLYPH_Z8_ASSET = "file")
load("images/glyph_Z9.png", GLYPH_Z9_ASSET = "file")
load("images/glyph_Z91.png", GLYPH_Z91_ASSET = "file")
load("images/glyph_Z92.png", GLYPH_Z92_ASSET = "file")
load("images/glyph_Z93.png", GLYPH_Z93_ASSET = "file")
load("images/glyph_Z94.png", GLYPH_Z94_ASSET = "file")
load("images/glyph_Z95.png", GLYPH_Z95_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

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
                                    render.Image(glyph["src"]),
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
        "src": GLYPH_O6_ASSET.readall(),
    },
    "T23": {
        "description": "arrowhead",
        "src": GLYPH_T23_ASSET.readall(),
    },
    "Aa22": {
        "src": GLYPH_AA22_ASSET.readall(),
    },
    "W10": {
        "description": "cup",
        "pronunciation": "iab",
        "src": GLYPH_W10_ASSET.readall(),
    },
    "S18": {
        "description": "menatnecklaceandcounterpoise",
        "pronunciation": "mnit",
        "src": GLYPH_S18_ASSET.readall(),
    },
    "B5": {
        "description": "woman suckling child",
        "src": GLYPH_B5_ASSET.readall(),
    },
    "W2": {
        "description": "oil-jar without ties",
        "pronunciation": "bAs",
        "src": GLYPH_W2_ASSET.readall(),
    },
    "Q4": {
        "description": "headrest",
        "src": GLYPH_Q4_ASSET.readall(),
    },
    "Y7": {
        "description": "harp",
        "src": GLYPH_Y7_ASSET.readall(),
    },
    "R16": {
        "description": "sceptre with feathers and string",
        "pronunciation": "wx",
        "src": GLYPH_R16_ASSET.readall(),
    },
    "S43": {
        "description": "walking stick",
        "pronunciation": "md",
        "src": GLYPH_S43_ASSET.readall(),
    },
    "O16": {
        "description": "gateway with serpents",
        "src": GLYPH_O16_ASSET.readall(),
    },
    "M17": {
        "description": "reed",
        "pronunciation": "i",
        "src": GLYPH_M17_ASSET.readall(),
    },
    "U18": {
        "src": GLYPH_U18_ASSET.readall(),
    },
    "R2": {
        "description": "table with slices of bread",
        "src": GLYPH_R2_ASSET.readall(),
    },
    "R20": {
        "description": "flower with horns",
        "src": GLYPH_R20_ASSET.readall(),
    },
    "V27": {
        "src": GLYPH_V27_ASSET.readall(),
    },
    "Z94": {
        "src": GLYPH_Z94_ASSET.readall(),
    },
    "B8": {
        "description": "woman holding lotus flower",
        "src": GLYPH_B8_ASSET.readall(),
    },
    "E18": {
        "description": "wolf on standard",
        "src": GLYPH_E18_ASSET.readall(),
    },
    "S20": {
        "description": "necklace with seal",
        "pronunciation": "xtm",
        "src": GLYPH_S20_ASSET.readall(),
    },
    "T18": {
        "description": "crook with package attached",
        "pronunciation": "Sms",
        "src": GLYPH_T18_ASSET.readall(),
    },
    "M37": {
        "description": "bundle of flax",
        "src": GLYPH_M37_ASSET.readall(),
    },
    "V19": {
        "pronunciation": "mDt",
        "src": GLYPH_V19_ASSET.readall(),
    },
    "A5": {
        "description": "crouching man hiding behind wall",
        "src": GLYPH_A5_ASSET.readall(),
    },
    "W16": {
        "description": "water jar with rack",
        "src": GLYPH_W16_ASSET.readall(),
    },
    "G7": {
        "description": "falcon on standard",
        "src": GLYPH_G7_ASSET.readall(),
    },
    "A23": {
        "description": "king with staff and mace with round head",
        "src": GLYPH_A23_ASSET.readall(),
    },
    "S44": {
        "description": "walking stick with flagellum",
        "pronunciation": "Ams",
        "src": GLYPH_S44_ASSET.readall(),
    },
    "G11": {
        "description": "image of falcon",
        "src": GLYPH_G11_ASSET.readall(),
    },
    "A49": {
        "description": "seated syrian holding stick",
        "src": GLYPH_A49_ASSET.readall(),
    },
    "Aa25": {
        "src": GLYPH_AA25_ASSET.readall(),
    },
    "E10": {
        "description": "ram",
        "src": GLYPH_E10_ASSET.readall(),
    },
    "R9": {
        "description": "combination of cloth on pole and bag",
        "pronunciation": "bd",
        "src": GLYPH_R9_ASSET.readall(),
    },
    "E13": {
        "description": "cat",
        "src": GLYPH_E13_ASSET.readall(),
    },
    "O42": {
        "description": "fence",
        "pronunciation": "Szp",
        "src": GLYPH_O42_ASSET.readall(),
    },
    "V18": {
        "src": GLYPH_V18_ASSET.readall(),
    },
    "N31": {
        "description": "road with shrubs",
        "src": GLYPH_N31_ASSET.readall(),
    },
    "R11": {
        "description": "reed column",
        "pronunciation": "dd",
        "src": GLYPH_R11_ASSET.readall(),
    },
    "V12": {
        "pronunciation": "arq",
        "src": GLYPH_V12_ASSET.readall(),
    },
    "V39": {
        "description": "?stylized ankh(for isis)(?)",
        "src": GLYPH_V39_ASSET.readall(),
    },
    "Aa1": {
        "description": "placenta or sieve",
        "pronunciation": "x",
        "src": GLYPH_AA1_ASSET.readall(),
    },
    "A35": {
        "description": "man building wall",
        "src": GLYPH_A35_ASSET.readall(),
    },
    "T27": {
        "description": "trap",
        "src": GLYPH_T27_ASSET.readall(),
    },
    "F21": {
        "description": "ear of bovine",
        "pronunciation": "sDm",
        "src": GLYPH_F21_ASSET.readall(),
    },
    "O29": {
        "description": "horizontal wooden column",
        "pronunciation": "aA",
        "src": GLYPH_O29_ASSET.readall(),
    },
    "M25": {
        "description": "combination of flowering sedge and mouth",
        "src": GLYPH_M25_ASSET.readall(),
    },
    "W17": {
        "description": "water jar with rack",
        "pronunciation": "xnt",
        "src": GLYPH_W17_ASSET.readall(),
    },
    "T13": {
        "description": "joined pieces of wood",
        "pronunciation": "rs",
        "src": GLYPH_T13_ASSET.readall(),
    },
    "O14": {
        "description": "part of battlemented enclosure",
        "src": GLYPH_O14_ASSET.readall(),
    },
    "G9": {
        "description": "falcon with sun on head",
        "src": GLYPH_G9_ASSET.readall(),
    },
    "S1": {
        "description": "white crown",
        "pronunciation": "HDt",
        "src": GLYPH_S1_ASSET.readall(),
    },
    "M19": {
        "description": "heaped conical cakes between reed and club",
        "src": GLYPH_M19_ASSET.readall(),
    },
    "G23": {
        "description": "lapwing",
        "pronunciation": "rxyt",
        "src": GLYPH_G23_ASSET.readall(),
    },
    "Q1": {
        "description": "seatthrone",
        "pronunciation": "st",
        "src": GLYPH_Q1_ASSET.readall(),
    },
    "S41": {
        "description": "sceptre",
        "pronunciation": "Dam",
        "src": GLYPH_S41_ASSET.readall(),
    },
    "N36": {
        "description": "canal",
        "src": GLYPH_N36_ASSET.readall(),
    },
    "M29": {
        "description": "seed-pod",
        "pronunciation": "nDm",
        "src": GLYPH_M29_ASSET.readall(),
    },
    "O47": {
        "description": "enclosed mound",
        "pronunciation": "nxn",
        "src": GLYPH_O47_ASSET.readall(),
    },
    "T12": {
        "description": "bowstring",
        "pronunciation": "rwd",
        "src": GLYPH_T12_ASSET.readall(),
    },
    "O39": {
        "description": "stone",
        "src": GLYPH_O39_ASSET.readall(),
    },
    "N17": {
        "description": "land",
        "src": GLYPH_N17_ASSET.readall(),
    },
    "G48": {
        "description": "three ducklings in nest",
        "src": GLYPH_G48_ASSET.readall(),
    },
    "D1": {
        "description": "head",
        "pronunciation": "tp",
        "src": GLYPH_D1_ASSET.readall(),
    },
    "I5": {
        "description": "crocodile with curved tail",
        "pronunciation": "sAq",
        "src": GLYPH_I5_ASSET.readall(),
    },
    "L7": {
        "description": "scorpion",
        "pronunciation": "srqt",
        "src": GLYPH_L7_ASSET.readall(),
    },
    "V23": {
        "src": GLYPH_V23_ASSET.readall(),
    },
    "C19": {
        "description": "mummy-shaped god",
        "src": GLYPH_C19_ASSET.readall(),
    },
    "O11": {
        "description": "palace",
        "pronunciation": "aH",
        "src": GLYPH_O11_ASSET.readall(),
    },
    "D2": {
        "description": "face",
        "pronunciation": "Hr",
        "src": GLYPH_D2_ASSET.readall(),
    },
    "R12": {
        "description": "standard",
        "src": GLYPH_R12_ASSET.readall(),
    },
    "V7": {
        "description": "rope-(shape)",
        "pronunciation": "Sn",
        "src": GLYPH_V7_ASSET.readall(),
    },
    "G45": {
        "description": "combination of quail chick and forearm",
        "src": GLYPH_G45_ASSET.readall(),
    },
    "P10": {
        "description": "rudder",
        "src": GLYPH_P10_ASSET.readall(),
    },
    "T29": {
        "description": "butcher's block with knife",
        "pronunciation": "nmt",
        "src": GLYPH_T29_ASSET.readall(),
    },
    "M33": {
        "description": "3 grains horizontally",
        "src": GLYPH_M33_ASSET.readall(),
    },
    "M44": {
        "description": "thorn",
        "src": GLYPH_M44_ASSET.readall(),
    },
    "S45": {
        "description": "flagellum",
        "pronunciation": "nxxw",
        "src": GLYPH_S45_ASSET.readall(),
    },
    "R15": {
        "description": "spear, emblem of the east",
        "pronunciation": "iAb",
        "src": GLYPH_R15_ASSET.readall(),
    },
    "O41": {
        "description": "double stairway",
        "src": GLYPH_O41_ASSET.readall(),
    },
    "Z92": {
        "src": GLYPH_Z92_ASSET.readall(),
    },
    "S35": {
        "description": "sunshade",
        "pronunciation": "Swt",
        "src": GLYPH_S35_ASSET.readall(),
    },
    "L5": {
        "description": "centipede",
        "src": GLYPH_L5_ASSET.readall(),
    },
    "O38": {
        "description": "corner of wall",
        "src": GLYPH_O38_ASSET.readall(),
    },
    "Aa41": {
        "src": GLYPH_AA41_ASSET.readall(),
    },
    "M18": {
        "description": "combination of reed and legs walking",
        "pronunciation": "ii",
        "src": GLYPH_M18_ASSET.readall(),
    },
    "G22": {
        "description": "hoopoe",
        "pronunciation": "Db",
        "src": GLYPH_G22_ASSET.readall(),
    },
    "O28": {
        "description": "column",
        "pronunciation": "iwn",
        "src": GLYPH_O28_ASSET.readall(),
    },
    "O8": {
        "description": "combination of enclosure, flat loaf and wooden column",
        "src": GLYPH_O8_ASSET.readall(),
    },
    "M28": {
        "description": "combination of flowering sedge and hobble",
        "src": GLYPH_M28_ASSET.readall(),
    },
    "S34": {
        "description": "lifeankh, possibly representing a sandal-strap",
        "pronunciation": "anx",
        "src": GLYPH_S34_ASSET.readall(),
    },
    "F30": {
        "description": "water-skin",
        "pronunciation": "Sd",
        "src": GLYPH_F30_ASSET.readall(),
    },
    "M6": {
        "description": "combination of palm branch and mouth",
        "pronunciation": "tr",
        "src": GLYPH_M6_ASSET.readall(),
    },
    "S9": {
        "description": "shutitwo-featheradornment",
        "pronunciation": "Swty",
        "src": GLYPH_S9_ASSET.readall(),
    },
    "I9": {
        "description": "horned viper",
        "pronunciation": "f",
        "src": GLYPH_I9_ASSET.readall(),
    },
    "D10": {
        "description": "eye of horus",
        "pronunciation": "wDAt",
        "src": GLYPH_D10_ASSET.readall(),
    },
    "B6": {
        "description": "woman on chair with child on lap",
        "src": GLYPH_B6_ASSET.readall(),
    },
    "F29": {
        "description": "cow's skin pierced by arrow",
        "pronunciation": "sti",
        "src": GLYPH_F29_ASSET.readall(),
    },
    "V29": {
        "description": "(fiber)swab(straw broom)",
        "pronunciation": "wAH",
        "src": GLYPH_V29_ASSET.readall(),
    },
    "G49": {
        "description": "three ducklings in pool",
        "src": GLYPH_G49_ASSET.readall(),
    },
    "Y2": {
        "src": GLYPH_Y2_ASSET.readall(),
    },
    "Aa28": {
        "pronunciation": "qd",
        "src": GLYPH_AA28_ASSET.readall(),
    },
    "S19": {
        "description": "sealwith necklace",
        "pronunciation": "sDAw",
        "src": GLYPH_S19_ASSET.readall(),
    },
    "A28": {
        "description": "man with hands raised on either side",
        "src": GLYPH_A28_ASSET.readall(),
    },
    "N3": {
        "description": "sky with sceptre",
        "src": GLYPH_N3_ASSET.readall(),
    },
    "R7": {
        "description": "bowl with smoke",
        "pronunciation": "snTr",
        "src": GLYPH_R7_ASSET.readall(),
    },
    "Z4": {
        "description": "dual stroke",
        "pronunciation": "y",
        "src": GLYPH_Z4_ASSET.readall(),
    },
    "G31": {
        "description": "heron",
        "src": GLYPH_G31_ASSET.readall(),
    },
    "N28": {
        "description": "rays of sun over hill",
        "pronunciation": "xa",
        "src": GLYPH_N28_ASSET.readall(),
    },
    "D43": {
        "description": "forearm with flail",
        "src": GLYPH_D43_ASSET.readall(),
    },
    "F7": {
        "description": "ram head",
        "src": GLYPH_F7_ASSET.readall(),
    },
    "N30": {
        "description": "mound of earth",
        "pronunciation": "iAt",
        "src": GLYPH_N30_ASSET.readall(),
    },
    "L2": {
        "description": "bee",
        "pronunciation": "bit",
        "src": GLYPH_L2_ASSET.readall(),
    },
    "C10": {
        "description": "goddess with feather",
        "pronunciation": "mAat",
        "src": GLYPH_C10_ASSET.readall(),
    },
    "U21": {
        "description": "adze-on-block",
        "pronunciation": "stp",
        "src": GLYPH_U21_ASSET.readall(),
    },
    "F33": {
        "description": "tail",
        "pronunciation": "sd",
        "src": GLYPH_F33_ASSET.readall(),
    },
    "Aa30": {
        "pronunciation": "Xkr",
        "src": GLYPH_AA30_ASSET.readall(),
    },
    "N12": {
        "description": "crescent moon",
        "src": GLYPH_N12_ASSET.readall(),
    },
    "F32": {
        "description": "animal's belly",
        "pronunciation": "X",
        "src": GLYPH_F32_ASSET.readall(),
    },
    "M40": {
        "description": "bundle of reeds",
        "pronunciation": "iz",
        "src": GLYPH_M40_ASSET.readall(),
    },
    "U22": {
        "description": "clapper-(of-bell)tool/instrumentforked-staff, etc.",
        "pronunciation": "mnx",
        "src": GLYPH_U22_ASSET.readall(),
    },
    "D7": {
        "description": "eye with painted lower lid",
        "src": GLYPH_D7_ASSET.readall(),
    },
    "G10": {
        "description": "falcon in sokar barque",
        "src": GLYPH_G10_ASSET.readall(),
    },
    "S12": {
        "description": "collar of beads",
        "pronunciation": "nbw",
        "src": GLYPH_S12_ASSET.readall(),
    },
    "X5": {
        "src": GLYPH_X5_ASSET.readall(),
    },
    "G21": {
        "description": "guineafowl",
        "pronunciation": "nH",
        "src": GLYPH_G21_ASSET.readall(),
    },
    "T17": {
        "description": "chariot",
        "pronunciation": "wrrt",
        "src": GLYPH_T17_ASSET.readall(),
    },
    "F18": {
        "description": "tusk",
        "pronunciation": "bH",
        "src": GLYPH_F18_ASSET.readall(),
    },
    "Q3": {
        "description": "stool",
        "pronunciation": "p",
        "src": GLYPH_Q3_ASSET.readall(),
    },
    "F52": {
        "description": "excrement",
        "src": GLYPH_F52_ASSET.readall(),
    },
    "E22": {
        "description": "lion",
        "pronunciation": "mAi",
        "src": GLYPH_E22_ASSET.readall(),
    },
    "N39": {
        "description": "pool with water",
        "src": GLYPH_N39_ASSET.readall(),
    },
    "N41": {
        "description": "well with ripple of water",
        "pronunciation": "id",
        "src": GLYPH_N41_ASSET.readall(),
    },
    "T5": {
        "description": "combination of mace with round head and cobra",
        "src": GLYPH_T5_ASSET.readall(),
    },
    "A10": {
        "description": "seated man holding oar",
        "src": GLYPH_A10_ASSET.readall(),
    },
    "D53": {
        "description": "phallus with emission",
        "src": GLYPH_D53_ASSET.readall(),
    },
    "K4": {
        "description": "elephant-snout fish",
        "pronunciation": "XA",
        "src": GLYPH_K4_ASSET.readall(),
    },
    "S31": {
        "description": "combination of folded cloth and sickle",
        "src": GLYPH_S31_ASSET.readall(),
    },
    "K6": {
        "description": "fish scale",
        "pronunciation": "nSmt",
        "src": GLYPH_K6_ASSET.readall(),
    },
    "E25": {
        "description": "hippopotamus",
        "src": GLYPH_E25_ASSET.readall(),
    },
    "B3": {
        "description": "woman giving birth",
        "pronunciation": "msi",
        "src": GLYPH_B3_ASSET.readall(),
    },
    "T24": {
        "description": "fishingnet",
        "pronunciation": "iH",
        "src": GLYPH_T24_ASSET.readall(),
    },
    "Aa3": {
        "description": "pustule with liquid issuing from it",
        "src": GLYPH_AA3_ASSET.readall(),
    },
    "T32": {
        "description": "combination of knife-sharpener and legs",
        "src": GLYPH_T32_ASSET.readall(),
    },
    "V13": {
        "description": "tethering rope",
        "pronunciation": "T",
        "src": GLYPH_V13_ASSET.readall(),
    },
    "E30": {
        "description": "ibex",
        "src": GLYPH_E30_ASSET.readall(),
    },
    "F50": {
        "description": "combination of f46 and s29",
        "src": GLYPH_F50_ASSET.readall(),
    },
    "Z8": {
        "description": "oval",
        "src": GLYPH_Z8_ASSET.readall(),
    },
    "O50": {
        "description": "threshing floor",
        "pronunciation": "zp",
        "src": GLYPH_O50_ASSET.readall(),
    },
    "D45": {
        "description": "arm with wand",
        "pronunciation": "Dsr",
        "src": GLYPH_D45_ASSET.readall(),
    },
    "A33": {
        "description": "man with stick and bundle on shoulder",
        "pronunciation": "mniw",
        "src": GLYPH_A33_ASSET.readall(),
    },
    "V14": {
        "src": GLYPH_V14_ASSET.readall(),
    },
    "U30": {
        "description": "kiln",
        "src": GLYPH_U30_ASSET.readall(),
    },
    "A29": {
        "description": "man upside down",
        "src": GLYPH_A29_ASSET.readall(),
    },
    "P13": {
        "src": GLYPH_P13_ASSET.readall(),
    },
    "S5": {
        "description": "pschent crown",
        "src": GLYPH_S5_ASSET.readall(),
    },
    "U32": {
        "pronunciation": "zmn",
        "src": GLYPH_U32_ASSET.readall(),
    },
    "G42": {
        "description": "widgeon",
        "pronunciation": "wSA",
        "src": GLYPH_G42_ASSET.readall(),
    },
    "T4": {
        "description": "mace with strap",
        "src": GLYPH_T4_ASSET.readall(),
    },
    "Aa32": {
        "src": GLYPH_AA32_ASSET.readall(),
    },
    "F47": {
        "description": "intestine",
        "src": GLYPH_F47_ASSET.readall(),
    },
    "U9": {
        "src": GLYPH_U9_ASSET.readall(),
    },
    "G8": {
        "description": "falcon on collar of beads",
        "src": GLYPH_G8_ASSET.readall(),
    },
    "D15": {
        "description": "diagonal marking of eye of horus",
        "src": GLYPH_D15_ASSET.readall(),
    },
    "O1": {
        "description": "house",
        "pronunciation": "pr",
        "src": GLYPH_O1_ASSET.readall(),
    },
    "A18": {
        "description": "child wearing red crown",
        "src": GLYPH_A18_ASSET.readall(),
    },
    "F2": {
        "description": "charging ox head",
        "src": GLYPH_F2_ASSET.readall(),
    },
    "E11": {
        "description": "ram",
        "src": GLYPH_E11_ASSET.readall(),
    },
    "D27": {
        "description": "small breast",
        "pronunciation": "mnD",
        "src": GLYPH_D27_ASSET.readall(),
    },
    "R13": {
        "description": "falcon and feather on standard",
        "src": GLYPH_R13_ASSET.readall(),
    },
    "T31": {
        "description": "knife-sharpener",
        "pronunciation": "sSm",
        "src": GLYPH_T31_ASSET.readall(),
    },
    "X6": {
        "description": "loaf-with-decoration",
        "src": GLYPH_X6_ASSET.readall(),
    },
    "G20": {
        "description": "combination of owl and forearm",
        "src": GLYPH_G20_ASSET.readall(),
    },
    "K5": {
        "description": "petrocephalus bane",
        "pronunciation": "bz",
        "src": GLYPH_K5_ASSET.readall(),
    },
    "G39": {
        "description": "pintail",
        "pronunciation": "zA",
        "src": GLYPH_G39_ASSET.readall(),
    },
    "V2": {
        "pronunciation": "sTA",
        "src": GLYPH_V2_ASSET.readall(),
    },
    "T7": {
        "description": "axe",
        "src": GLYPH_T7_ASSET.readall(),
    },
    "W18": {
        "description": "water jar with rack",
        "src": GLYPH_W18_ASSET.readall(),
    },
    "A59": {
        "description": "man threatening with stick",
        "src": GLYPH_A59_ASSET.readall(),
    },
    "C4": {
        "description": "god with ram head",
        "pronunciation": "Xnmw",
        "src": GLYPH_C4_ASSET.readall(),
    },
    "Z1": {
        "description": "single stroke",
        "src": GLYPH_Z1_ASSET.readall(),
    },
    "U28": {
        "description": "fire-drill",
        "pronunciation": "DA",
        "src": GLYPH_U28_ASSET.readall(),
    },
    "F26": {
        "description": "skin of goat",
        "pronunciation": "Xn",
        "src": GLYPH_F26_ASSET.readall(),
    },
    "R10": {
        "description": "combination of cloth on pole, butcher's block and slope of hill",
        "src": GLYPH_R10_ASSET.readall(),
    },
    "O23": {
        "description": "double platform",
        "src": GLYPH_O23_ASSET.readall(),
    },
    "T22": {
        "description": "arrowhead",
        "pronunciation": "sn",
        "src": GLYPH_T22_ASSET.readall(),
    },
    "R17": {
        "description": "wig on pole",
        "src": GLYPH_R17_ASSET.readall(),
    },
    "F40": {
        "description": "backbone and spinal cords",
        "pronunciation": "Aw",
        "src": GLYPH_F40_ASSET.readall(),
    },
    "E26": {
        "description": "elephant",
        "src": GLYPH_E26_ASSET.readall(),
    },
    "G30": {
        "description": "three saddle-billed storks",
        "src": GLYPH_G30_ASSET.readall(),
    },
    "A16": {
        "description": "man bowing down",
        "src": GLYPH_A16_ASSET.readall(),
    },
    "S30": {
        "description": "combination of folded cloth and horned viper",
        "pronunciation": "sf",
        "src": GLYPH_S30_ASSET.readall(),
    },
    "F6": {
        "description": "forepart of hartebeest",
        "src": GLYPH_F6_ASSET.readall(),
    },
    "D14": {
        "description": "right part of eye of horus",
        "src": GLYPH_D14_ASSET.readall(),
    },
    "I11": {
        "description": "two cobras",
        "pronunciation": "DD",
        "src": GLYPH_I11_ASSET.readall(),
    },
    "A27": {
        "description": "hastening man",
        "src": GLYPH_A27_ASSET.readall(),
    },
    "Z9": {
        "description": "crossed diagonal sticks",
        "src": GLYPH_Z9_ASSET.readall(),
    },
    "T20": {
        "description": "harpoon head",
        "src": GLYPH_T20_ASSET.readall(),
    },
    "M16": {
        "description": "clump of papyrus",
        "pronunciation": "HA",
        "src": GLYPH_M16_ASSET.readall(),
    },
    "Aa11": {
        "pronunciation": "mAa",
        "src": GLYPH_AA11_ASSET.readall(),
    },
    "S17": {
        "description": "pectoral",
        "src": GLYPH_S17_ASSET.readall(),
    },
    "D19": {
        "description": "nose, eye and cheek",
        "pronunciation": "fnD",
        "src": GLYPH_D19_ASSET.readall(),
    },
    "D42": {
        "description": "forearm with palm down and straight upper arm",
        "src": GLYPH_D42_ASSET.readall(),
    },
    "C9": {
        "description": "goddess with horned sun-disk",
        "src": GLYPH_C9_ASSET.readall(),
    },
    "M30": {
        "description": "root",
        "pronunciation": "bnr",
        "src": GLYPH_M30_ASSET.readall(),
    },
    "A50": {
        "description": "noble on chair",
        "pronunciation": "Sps",
        "src": GLYPH_A50_ASSET.readall(),
    },
    "Y6": {
        "description": "game piece",
        "pronunciation": "ibA",
        "src": GLYPH_Y6_ASSET.readall(),
    },
    "Aa21": {
        "pronunciation": "wDa",
        "src": GLYPH_AA21_ASSET.readall(),
    },
    "I14": {
        "description": "snake",
        "src": GLYPH_I14_ASSET.readall(),
    },
    "L3": {
        "description": "fly",
        "src": GLYPH_L3_ASSET.readall(),
    },
    "A9": {
        "description": "man steadying basket on head",
        "src": GLYPH_A9_ASSET.readall(),
    },
    "O32": {
        "description": "gateway",
        "src": GLYPH_O32_ASSET.readall(),
    },
    "W11": {
        "description": "jar stand",
        "pronunciation": "nzt",
        "src": GLYPH_W11_ASSET.readall(),
    },
    "U15": {
        "description": "sled(sledge)",
        "pronunciation": "tm",
        "src": GLYPH_U15_ASSET.readall(),
    },
    "O31": {
        "description": "door",
        "src": GLYPH_O31_ASSET.readall(),
    },
    "D62": {
        "description": "three toes oriented rightward",
        "src": GLYPH_D62_ASSET.readall(),
    },
    "E15": {
        "description": "lying canine",
        "src": GLYPH_E15_ASSET.readall(),
    },
    "U27": {
        "src": GLYPH_U27_ASSET.readall(),
    },
    "M22": {
        "description": "rush",
        "src": GLYPH_M22_ASSET.readall(),
    },
    "P3": {
        "description": "sacred barque",
        "src": GLYPH_P3_ASSET.readall(),
    },
    "D29": {
        "description": "combination of hieroglyphs d28 and r12",
        "src": GLYPH_D29_ASSET.readall(),
    },
    "V16": {
        "description": "cattlehobble(bil.)",
        "src": GLYPH_V16_ASSET.readall(),
    },
    "D17": {
        "description": "diagonal and vertical markings of eye of horus",
        "src": GLYPH_D17_ASSET.readall(),
    },
    "U1": {
        "description": "sickle",
        "pronunciation": "mA",
        "src": GLYPH_U1_ASSET.readall(),
    },
    "F20": {
        "description": "tongue",
        "pronunciation": "ns",
        "src": GLYPH_F20_ASSET.readall(),
    },
    "G33": {
        "description": "cattle egret",
        "src": GLYPH_G33_ASSET.readall(),
    },
    "E1": {
        "description": "bull",
        "src": GLYPH_E1_ASSET.readall(),
    },
    "H1": {
        "description": "head of pintail",
        "src": GLYPH_H1_ASSET.readall(),
    },
    "O18": {
        "description": "shrine in profile",
        "pronunciation": "kAr",
        "src": GLYPH_O18_ASSET.readall(),
    },
    "E14": {
        "description": "dog",
        "src": GLYPH_E14_ASSET.readall(),
    },
    "M12": {
        "description": "one lotus plant",
        "pronunciation": "1000",
        "src": GLYPH_M12_ASSET.readall(),
    },
    "D48": {
        "description": "hand without thumb",
        "src": GLYPH_D48_ASSET.readall(),
    },
    "O46": {
        "description": "domed building",
        "src": GLYPH_O46_ASSET.readall(),
    },
    "Aa4": {
        "src": GLYPH_AA4_ASSET.readall(),
    },
    "Y8": {
        "description": "sistrum",
        "pronunciation": "zSSt",
        "src": GLYPH_Y8_ASSET.readall(),
    },
    "D57": {
        "description": "leg with knife",
        "src": GLYPH_D57_ASSET.readall(),
    },
    "U7": {
        "description": "hoe",
        "src": GLYPH_U7_ASSET.readall(),
    },
    "Z3": {
        "description": "plural strokes (vertical)",
        "src": GLYPH_Z3_ASSET.readall(),
    },
    "D38": {
        "description": "forearm with rounded loaf",
        "src": GLYPH_D38_ASSET.readall(),
    },
    "R14": {
        "description": "emblemof the west",
        "pronunciation": "imnt",
        "src": GLYPH_R14_ASSET.readall(),
    },
    "W22": {
        "description": "beer jug",
        "pronunciation": "Hnqt",
        "src": GLYPH_W22_ASSET.readall(),
    },
    "A34": {
        "description": "man pounding in a mortar",
        "src": GLYPH_A34_ASSET.readall(),
    },
    "V25": {
        "description": "command staff",
        "src": GLYPH_V25_ASSET.readall(),
    },
    "M31": {
        "description": "rhizome",
        "src": GLYPH_M31_ASSET.readall(),
    },
    "V9": {
        "description": "shenring",
        "src": GLYPH_V9_ASSET.readall(),
    },
    "B11": {
        "src": GLYPH_B11_ASSET.readall(),
    },
    "G6": {
        "description": "combination of falcon and flaggellum",
        "src": GLYPH_G6_ASSET.readall(),
    },
    "M39": {
        "description": "basket of fruit or grain",
        "src": GLYPH_M39_ASSET.readall(),
    },
    "N27": {
        "description": "sun over mountain",
        "pronunciation": "Axt",
        "src": GLYPH_N27_ASSET.readall(),
    },
    "N32": {
        "description": "lump of clay",
        "src": GLYPH_N32_ASSET.readall(),
    },
    "D35": {
        "description": "arms in gesture of negation",
        "src": GLYPH_D35_ASSET.readall(),
    },
    "W14": {
        "description": "water jar",
        "pronunciation": "Hz",
        "src": GLYPH_W14_ASSET.readall(),
    },
    "A31": {
        "description": "man with hands raised behind him",
        "src": GLYPH_A31_ASSET.readall(),
    },
    "D13": {
        "description": "eyebrow",
        "src": GLYPH_D13_ASSET.readall(),
    },
    "G12": {
        "description": "combination of image of falcon and flagellum",
        "src": GLYPH_G12_ASSET.readall(),
    },
    "V6": {
        "description": "rope-(shape)",
        "pronunciation": "sS",
        "src": GLYPH_V6_ASSET.readall(),
    },
    "A43": {
        "description": "king wearing white crown",
        "src": GLYPH_A43_ASSET.readall(),
    },
    "T34": {
        "description": "butcher's knife",
        "pronunciation": "nm",
        "src": GLYPH_T34_ASSET.readall(),
    },
    "G29": {
        "description": "saddle-billed stork",
        "pronunciation": "bA",
        "src": GLYPH_G29_ASSET.readall(),
    },
    "E21": {
        "description": "lying set-animal",
        "src": GLYPH_E21_ASSET.readall(),
    },
    "F25": {
        "description": "leg ofox",
        "pronunciation": "wHm",
        "src": GLYPH_F25_ASSET.readall(),
    },
    "O19": {
        "description": "shrine with fence",
        "src": GLYPH_O19_ASSET.readall(),
    },
    "G40": {
        "description": "pintail flying",
        "pronunciation": "pA",
        "src": GLYPH_G40_ASSET.readall(),
    },
    "U16": {
        "description": "sled with jackal head",
        "pronunciation": "biA",
        "src": GLYPH_U16_ASSET.readall(),
    },
    "A36": {
        "description": "man kneading into vessel",
        "src": GLYPH_A36_ASSET.readall(),
    },
    "A4": {
        "description": "seated man with hands raised",
        "src": GLYPH_A4_ASSET.readall(),
    },
    "D21": {
        "description": "mouth",
        "pronunciation": "rA",
        "src": GLYPH_D21_ASSET.readall(),
    },
    "A6": {
        "description": "seated man under vase from which water flows",
        "src": GLYPH_A6_ASSET.readall(),
    },
    "M21": {
        "description": "reeds with root",
        "pronunciation": "sm",
        "src": GLYPH_M21_ASSET.readall(),
    },
    "S15": {
        "description": "pectoral",
        "pronunciation": "tHn",
        "src": GLYPH_S15_ASSET.readall(),
    },
    "D32": {
        "description": "arms embracing",
        "src": GLYPH_D32_ASSET.readall(),
    },
    "N37": {
        "description": "pool",
        "pronunciation": "S",
        "src": GLYPH_N37_ASSET.readall(),
    },
    "T26": {
        "description": "birdtrap",
        "src": GLYPH_T26_ASSET.readall(),
    },
    "W1": {
        "description": "oil jar",
        "src": GLYPH_W1_ASSET.readall(),
    },
    "S16": {
        "description": "pectoral",
        "src": GLYPH_S16_ASSET.readall(),
    },
    "U2": {
        "description": "sickle",
        "src": GLYPH_U2_ASSET.readall(),
    },
    "D16": {
        "description": "vertical marking of eye of horus",
        "src": GLYPH_D16_ASSET.readall(),
    },
    "D47": {
        "description": "hand with palm up",
        "src": GLYPH_D47_ASSET.readall(),
    },
    "I6": {
        "description": "crocodile scales",
        "pronunciation": "km",
        "src": GLYPH_I6_ASSET.readall(),
    },
    "H6": {
        "description": "feather",
        "pronunciation": "Sw",
        "src": GLYPH_H6_ASSET.readall(),
    },
    "S11": {
        "description": "broad collar",
        "pronunciation": "wsx",
        "src": GLYPH_S11_ASSET.readall(),
    },
    "E33": {
        "description": "monkey",
        "src": GLYPH_E33_ASSET.readall(),
    },
    "Q7": {
        "description": "brazier",
        "src": GLYPH_Q7_ASSET.readall(),
    },
    "D12": {
        "description": "pupil",
        "src": GLYPH_D12_ASSET.readall(),
    },
    "N4": {
        "description": "sky with rain",
        "pronunciation": "idt",
        "src": GLYPH_N4_ASSET.readall(),
    },
    "L6": {
        "description": "shell",
        "src": GLYPH_L6_ASSET.readall(),
    },
    "D58": {
        "description": "foot",
        "pronunciation": "b",
        "src": GLYPH_D58_ASSET.readall(),
    },
    "F17": {
        "description": "horn and vase from which water flows",
        "src": GLYPH_F17_ASSET.readall(),
    },
    "E7": {
        "description": "donkey",
        "src": GLYPH_E7_ASSET.readall(),
    },
    "F45": {
        "description": "uterus",
        "src": GLYPH_F45_ASSET.readall(),
    },
    "A11": {
        "description": "seated man holding scepter of authority and shepherd's crook",
        "src": GLYPH_A11_ASSET.readall(),
    },
    "Y5": {
        "description": "senet board",
        "pronunciation": "mn",
        "src": GLYPH_Y5_ASSET.readall(),
    },
    "L1": {
        "description": "dung beetle",
        "pronunciation": "xpr",
        "src": GLYPH_L1_ASSET.readall(),
    },
    "V35": {
        "src": GLYPH_V35_ASSET.readall(),
    },
    "A22": {
        "description": "statue of man with staff and scepter of authority",
        "src": GLYPH_A22_ASSET.readall(),
    },
    "Z95": {
        "src": GLYPH_Z95_ASSET.readall(),
    },
    "U11": {
        "pronunciation": "HqAt",
        "src": GLYPH_U11_ASSET.readall(),
    },
    "A30": {
        "description": "man with hands raised in front",
        "src": GLYPH_A30_ASSET.readall(),
    },
    "T33": {
        "description": "knife-sharpener of butcher",
        "src": GLYPH_T33_ASSET.readall(),
    },
    "U10": {
        "description": "grain measure (with plural, for grain particles)",
        "pronunciation": "it",
        "src": GLYPH_U10_ASSET.readall(),
    },
    "F16": {
        "description": "horn",
        "pronunciation": "db",
        "src": GLYPH_F16_ASSET.readall(),
    },
    "M3": {
        "description": "branch",
        "pronunciation": "xt",
        "src": GLYPH_M3_ASSET.readall(),
    },
    "O35": {
        "description": "combination of bolt and legs",
        "pronunciation": "zb",
        "src": GLYPH_O35_ASSET.readall(),
    },
    "O27": {
        "description": "hall of columns",
        "src": GLYPH_O27_ASSET.readall(),
    },
    "D9": {
        "description": "eye with flowing tears",
        "pronunciation": "rmi",
        "src": GLYPH_D9_ASSET.readall(),
    },
    "T16": {
        "description": "scimitar",
        "src": GLYPH_T16_ASSET.readall(),
    },
    "V20": {
        "description": "cattle hobble",
        "pronunciation": "mD",
        "src": GLYPH_V20_ASSET.readall(),
    },
    "B4": {
        "description": "combination of woman giving birth and three skins tied together",
        "src": GLYPH_B4_ASSET.readall(),
    },
    "Aa40": {
        "src": GLYPH_AA40_ASSET.readall(),
    },
    "P11": {
        "description": "mooringpost",
        "src": GLYPH_P11_ASSET.readall(),
    },
    "M35": {
        "description": "stack(of grain)",
        "src": GLYPH_M35_ASSET.readall(),
    },
    "Aa16": {
        "src": GLYPH_AA16_ASSET.readall(),
    },
    "M9": {
        "description": "lotus flower",
        "pronunciation": "zSn",
        "src": GLYPH_M9_ASSET.readall(),
    },
    "G46": {
        "description": "combination of quail chick and sickle",
        "pronunciation": "mAw",
        "src": GLYPH_G46_ASSET.readall(),
    },
    "F44": {
        "description": "bone with meat",
        "pronunciation": "iwa",
        "src": GLYPH_F44_ASSET.readall(),
    },
    "V31": {
        "description": "basket-with-handle(hieroglyph)",
        "pronunciation": "k",
        "src": GLYPH_V31_ASSET.readall(),
    },
    "T8": {
        "description": "dagger",
        "src": GLYPH_T8_ASSET.readall(),
    },
    "E5": {
        "description": "cow suckling calf",
        "src": GLYPH_E5_ASSET.readall(),
    },
    "C17": {
        "description": "god with falcon head and two plumes",
        "src": GLYPH_C17_ASSET.readall(),
    },
    "M43": {
        "description": "vine on trellis",
        "src": GLYPH_M43_ASSET.readall(),
    },
    "Z91": {
        "src": GLYPH_Z91_ASSET.readall(),
    },
    "V22": {
        "description": "whip",
        "pronunciation": "mH",
        "src": GLYPH_V22_ASSET.readall(),
    },
    "D51": {
        "description": "one finger (horizontal)",
        "src": GLYPH_D51_ASSET.readall(),
    },
    "G19": {
        "description": "combination of owl and forearm with conical loaf",
        "src": GLYPH_G19_ASSET.readall(),
    },
    "T2": {
        "description": "mace with round head",
        "src": GLYPH_T2_ASSET.readall(),
    },
    "W20": {
        "description": "milk jug with cover",
        "src": GLYPH_W20_ASSET.readall(),
    },
    "F27": {
        "description": "skin of cow with bent tail",
        "src": GLYPH_F27_ASSET.readall(),
    },
    "G35": {
        "description": "cormorant",
        "pronunciation": "aq",
        "src": GLYPH_G35_ASSET.readall(),
    },
    "S38": {
        "description": "crook",
        "pronunciation": "HqA",
        "src": GLYPH_S38_ASSET.readall(),
    },
    "O51": {
        "description": "pile of grain",
        "pronunciation": "Snwt",
        "src": GLYPH_O51_ASSET.readall(),
    },
    "D44": {
        "description": "arm with sekhem scepter",
        "src": GLYPH_D44_ASSET.readall(),
    },
    "M11": {
        "description": "flower on long twisted stalk",
        "pronunciation": "wdn",
        "src": GLYPH_M11_ASSET.readall(),
    },
    "F34": {
        "description": "heart",
        "pronunciation": "ib",
        "src": GLYPH_F34_ASSET.readall(),
    },
    "S42": {
        "description": "sekhemscepter",
        "pronunciation": "xrp",
        "src": GLYPH_S42_ASSET.readall(),
    },
    "S3": {
        "description": "red crown",
        "pronunciation": "dSrt",
        "src": GLYPH_S3_ASSET.readall(),
    },
    "T15": {
        "description": "throw stick slanted",
        "src": GLYPH_T15_ASSET.readall(),
    },
    "F24": {
        "description": "f23 reversed",
        "src": GLYPH_F24_ASSET.readall(),
    },
    "Aa27": {
        "pronunciation": "nD",
        "src": GLYPH_AA27_ASSET.readall(),
    },
    "N34": {
        "description": "ingot of metal",
        "src": GLYPH_N34_ASSET.readall(),
    },
    "G27": {
        "description": "flamingo",
        "pronunciation": "dSr",
        "src": GLYPH_G27_ASSET.readall(),
    },
    "A42": {
        "description": "king with uraeus and flagellum",
        "src": GLYPH_A42_ASSET.readall(),
    },
    "N9": {
        "description": "moon with lower half obscured",
        "pronunciation": "pzD",
        "src": GLYPH_N9_ASSET.readall(),
    },
    "M26": {
        "description": "floweringsedge",
        "pronunciation": "Sma",
        "src": GLYPH_M26_ASSET.readall(),
    },
    "F3": {
        "description": "hippopotamus head",
        "src": GLYPH_F3_ASSET.readall(),
    },
    "F8": {
        "description": "forepart of ram",
        "src": GLYPH_F8_ASSET.readall(),
    },
    "Aa12": {
        "src": GLYPH_AA12_ASSET.readall(),
    },
    "O33": {
        "description": "façade of palace",
        "src": GLYPH_O33_ASSET.readall(),
    },
    "O48": {
        "description": "enclosed mound",
        "src": GLYPH_O48_ASSET.readall(),
    },
    "S28": {
        "description": "cloth with fringe on top and folded cloth",
        "src": GLYPH_S28_ASSET.readall(),
    },
    "N8": {
        "description": "sunshine",
        "pronunciation": "Hnmmt",
        "src": GLYPH_N8_ASSET.readall(),
    },
    "F11": {
        "description": "head and neck of animal",
        "src": GLYPH_F11_ASSET.readall(),
    },
    "P5": {
        "description": "sail",
        "pronunciation": "nfw",
        "src": GLYPH_P5_ASSET.readall(),
    },
    "G2": {
        "description": "two egyptian vultures",
        "pronunciation": "AA",
        "src": GLYPH_G2_ASSET.readall(),
    },
    "O44": {
        "description": "emblem of min",
        "src": GLYPH_O44_ASSET.readall(),
    },
    "O2": {
        "description": "combination of house and mace with round head",
        "src": GLYPH_O2_ASSET.readall(),
    },
    "B9": {
        "description": "woman holding sistrum",
        "src": GLYPH_B9_ASSET.readall(),
    },
    "I4": {
        "description": "crocodileon shrine",
        "pronunciation": "sbk",
        "src": GLYPH_I4_ASSET.readall(),
    },
    "S4": {
        "description": "combination of red crown and basket",
        "src": GLYPH_S4_ASSET.readall(),
    },
    "Q6": {
        "description": "sarcophagus",
        "pronunciation": "qrsw",
        "src": GLYPH_Q6_ASSET.readall(),
    },
    "O43": {
        "description": "low fence",
        "src": GLYPH_O43_ASSET.readall(),
    },
    "M34": {
        "description": "ear of emmer",
        "pronunciation": "bdt",
        "src": GLYPH_M34_ASSET.readall(),
    },
    "M24": {
        "description": "combination of sedge and mouth",
        "pronunciation": "rsw",
        "src": GLYPH_M24_ASSET.readall(),
    },
    "O20": {
        "description": "shrine",
        "src": GLYPH_O20_ASSET.readall(),
    },
    "G4": {
        "description": "buzzard",
        "pronunciation": "tyw",
        "src": GLYPH_G4_ASSET.readall(),
    },
    "Aa2": {
        "description": "pustule",
        "src": GLYPH_AA2_ASSET.readall(),
    },
    "U35": {
        "src": GLYPH_U35_ASSET.readall(),
    },
    "N10": {
        "description": "moon with lower section obscured",
        "src": GLYPH_N10_ASSET.readall(),
    },
    "U26": {
        "pronunciation": "wbA",
        "src": GLYPH_U26_ASSET.readall(),
    },
    "F10": {
        "description": "head and neck of animal",
        "src": GLYPH_F10_ASSET.readall(),
    },
    "N24": {
        "description": "irrigation canal system",
        "pronunciation": "spAt",
        "src": GLYPH_N24_ASSET.readall(),
    },
    "N6": {
        "description": "sun with uraeus",
        "src": GLYPH_N6_ASSET.readall(),
    },
    "O25": {
        "description": "obelisk",
        "pronunciation": "txn",
        "src": GLYPH_O25_ASSET.readall(),
    },
    "Aa26": {
        "src": GLYPH_AA26_ASSET.readall(),
    },
    "E17": {
        "description": "jackal",
        "pronunciation": "zAb",
        "src": GLYPH_E17_ASSET.readall(),
    },
    "N35": {
        "description": "ripple of water",
        "pronunciation": "n",
        "src": GLYPH_N35_ASSET.readall(),
    },
    "E24": {
        "description": "panther",
        "pronunciation": "Aby",
        "src": GLYPH_E24_ASSET.readall(),
    },
    "S14": {
        "description": "combination of collar of beads and mace with round head",
        "src": GLYPH_S14_ASSET.readall(),
    },
    "Aa31": {
        "src": GLYPH_AA31_ASSET.readall(),
    },
    "A25": {
        "description": "man striking, with left arm hanging behind back",
        "src": GLYPH_A25_ASSET.readall(),
    },
    "W13": {
        "description": "pot",
        "src": GLYPH_W13_ASSET.readall(),
    },
    "N2": {
        "description": "sky with sceptre",
        "src": GLYPH_N2_ASSET.readall(),
    },
    "A41": {
        "description": "king with uraeus",
        "src": GLYPH_A41_ASSET.readall(),
    },
    "A8": {
        "description": "man performing hnw-rite",
        "src": GLYPH_A8_ASSET.readall(),
    },
    "S29": {
        "description": "folded cloth",
        "pronunciation": "s",
        "src": GLYPH_S29_ASSET.readall(),
    },
    "G54": {
        "description": "plucked bird",
        "pronunciation": "snD",
        "src": GLYPH_G54_ASSET.readall(),
    },
    "X4": {
        "src": GLYPH_X4_ASSET.readall(),
    },
    "N22": {
        "description": "broad tongue of land",
        "src": GLYPH_N22_ASSET.readall(),
    },
    "G37": {
        "description": "sparrow",
        "pronunciation": "nDs",
        "src": GLYPH_G37_ASSET.readall(),
    },
    "D20": {
        "description": "nose, eye and cheek (cursive)",
        "src": GLYPH_D20_ASSET.readall(),
    },
    "Aa6": {
        "src": GLYPH_AA6_ASSET.readall(),
    },
    "H3": {
        "description": "head of spoonbill",
        "pronunciation": "pAq",
        "src": GLYPH_H3_ASSET.readall(),
    },
    "A26": {
        "description": "man with one arm pointing forward",
        "src": GLYPH_A26_ASSET.readall(),
    },
    "P4": {
        "description": "boat with net",
        "pronunciation": "wHa",
        "src": GLYPH_P4_ASSET.readall(),
    },
    "P8": {
        "description": "oar",
        "pronunciation": "xrw",
        "src": GLYPH_P8_ASSET.readall(),
    },
    "T19": {
        "description": "harpoon head",
        "pronunciation": "qs",
        "src": GLYPH_T19_ASSET.readall(),
    },
    "N29": {
        "description": "slope of hill",
        "pronunciation": "q",
        "src": GLYPH_N29_ASSET.readall(),
    },
    "G13": {
        "description": "image of falcon with two plumes",
        "src": GLYPH_G13_ASSET.readall(),
    },
    "Aa24": {
        "src": GLYPH_AA24_ASSET.readall(),
    },
    "M32": {
        "description": "rhizome",
        "src": GLYPH_M32_ASSET.readall(),
    },
    "T14": {
        "description": "throw stick vertically",
        "pronunciation": "qmA",
        "src": GLYPH_T14_ASSET.readall(),
    },
    "F42": {
        "description": "rib",
        "pronunciation": "spr",
        "src": GLYPH_F42_ASSET.readall(),
    },
    "M14": {
        "description": "combination of papyrus and cobra",
        "src": GLYPH_M14_ASSET.readall(),
    },
    "Z10": {
        "description": "crossed diagonal sticks",
        "src": GLYPH_Z10_ASSET.readall(),
    },
    "V1": {
        "pronunciation": "100",
        "src": GLYPH_V1_ASSET.readall(),
    },
    "R24": {
        "description": "two bows tied horizontally",
        "src": GLYPH_R24_ASSET.readall(),
    },
    "D3": {
        "description": "hair",
        "pronunciation": "Sny",
        "src": GLYPH_D3_ASSET.readall(),
    },
    "M38": {
        "description": "wide bundle of flax",
        "src": GLYPH_M38_ASSET.readall(),
    },
    "T6": {
        "description": "combination of mace with round head and two cobras",
        "pronunciation": "HDD",
        "src": GLYPH_T6_ASSET.readall(),
    },
    "E20": {
        "description": "set-animal",
        "src": GLYPH_E20_ASSET.readall(),
    },
    "F9": {
        "description": "leopardhead",
        "src": GLYPH_F9_ASSET.readall(),
    },
    "U37": {
        "src": GLYPH_U37_ASSET.readall(),
    },
    "O45": {
        "description": "domed building",
        "pronunciation": "ipt",
        "src": GLYPH_O45_ASSET.readall(),
    },
    "C8": {
        "description": "ithyphallic god with two plumes, uplifted arm and flagellum",
        "pronunciation": "mnw",
        "src": GLYPH_C8_ASSET.readall(),
    },
    "M20": {
        "description": "field of reeds",
        "pronunciation": "sxt",
        "src": GLYPH_M20_ASSET.readall(),
    },
    "X7": {
        "src": GLYPH_X7_ASSET.readall(),
    },
    "M5": {
        "description": "combination of palm branch and flat loaf",
        "src": GLYPH_M5_ASSET.readall(),
    },
    "G24": {
        "description": "lapwing with twisted wings",
        "src": GLYPH_G24_ASSET.readall(),
    },
    "R22": {
        "description": "two narrow belemnites",
        "pronunciation": "xm",
        "src": GLYPH_R22_ASSET.readall(),
    },
    "S7": {
        "description": "blue crown",
        "pronunciation": "xprS",
        "src": GLYPH_S7_ASSET.readall(),
    },
    "N25": {
        "description": "three hills",
        "pronunciation": "xAst",
        "src": GLYPH_N25_ASSET.readall(),
    },
    "S8": {
        "description": "atefcrown",
        "pronunciation": "Atf",
        "src": GLYPH_S8_ASSET.readall(),
    },
    "G47": {
        "description": "duckling",
        "pronunciation": "TA",
        "src": GLYPH_G47_ASSET.readall(),
    },
    "I1": {
        "description": "gecko",
        "pronunciation": "aSA",
        "src": GLYPH_I1_ASSET.readall(),
    },
    "I12": {
        "description": "erect cobra",
        "src": GLYPH_I12_ASSET.readall(),
    },
    "D24": {
        "description": "upper lip with teeth",
        "pronunciation": "spt",
        "src": GLYPH_D24_ASSET.readall(),
    },
    "G52": {
        "description": "goose picking up grain",
        "src": GLYPH_G52_ASSET.readall(),
    },
    "F1": {
        "description": "ox head",
        "src": GLYPH_F1_ASSET.readall(),
    },
    "N23": {
        "description": "irrigation canal",
        "src": GLYPH_N23_ASSET.readall(),
    },
    "G14": {
        "description": "vulture",
        "pronunciation": "mwt",
        "src": GLYPH_G14_ASSET.readall(),
    },
    "A53": {
        "description": "standing mummy",
        "src": GLYPH_A53_ASSET.readall(),
    },
    "D60": {
        "description": "foot under vase from which water flows",
        "pronunciation": "wab",
        "src": GLYPH_D60_ASSET.readall(),
    },
    "M42": {
        "description": "flower",
        "src": GLYPH_M42_ASSET.readall(),
    },
    "D46": {
        "description": "hand",
        "pronunciation": "d",
        "src": GLYPH_D46_ASSET.readall(),
    },
    "A54": {
        "description": "lying mummy",
        "src": GLYPH_A54_ASSET.readall(),
    },
    "E6": {
        "description": "horse",
        "pronunciation": "zzmt",
        "src": GLYPH_E6_ASSET.readall(),
    },
    "O26": {
        "description": "stela",
        "src": GLYPH_O26_ASSET.readall(),
    },
    "D40": {
        "description": "forearm with stick",
        "src": GLYPH_D40_ASSET.readall(),
    },
    "M36": {
        "description": "bundle of flax",
        "pronunciation": "Dr",
        "src": GLYPH_M36_ASSET.readall(),
    },
    "Y3": {
        "description": "scribe's equipment",
        "pronunciation": "zS",
        "src": GLYPH_Y3_ASSET.readall(),
    },
    "D54": {
        "description": "legs walking",
        "src": GLYPH_D54_ASSET.readall(),
    },
    "N21": {
        "description": "short tongue of land",
        "src": GLYPH_N21_ASSET.readall(),
    },
    "S25": {
        "description": "garment with ties",
        "src": GLYPH_S25_ASSET.readall(),
    },
    "Aa18": {
        "src": GLYPH_AA18_ASSET.readall(),
    },
    "P1": {
        "description": "boat",
        "src": GLYPH_P1_ASSET.readall(),
    },
    "N11": {
        "description": "crescent moon",
        "pronunciation": "iaH",
        "src": GLYPH_N11_ASSET.readall(),
    },
    "H8": {
        "description": "egg",
        "src": GLYPH_H8_ASSET.readall(),
    },
    "Aa17": {
        "pronunciation": "sA",
        "src": GLYPH_AA17_ASSET.readall(),
    },
    "I3": {
        "description": "crocodile",
        "pronunciation": "mzH",
        "src": GLYPH_I3_ASSET.readall(),
    },
    "N15": {
        "description": "star in circle",
        "pronunciation": "dwAt",
        "src": GLYPH_N15_ASSET.readall(),
    },
    "D56": {
        "description": "leg",
        "pronunciation": "sbq",
        "src": GLYPH_D56_ASSET.readall(),
    },
    "A32": {
        "description": "man dancing with arms to the back",
        "src": GLYPH_A32_ASSET.readall(),
    },
    "S2": {
        "description": "combination of white crown and basket",
        "src": GLYPH_S2_ASSET.readall(),
    },
    "X8": {
        "description": "cone-shapedbread",
        "pronunciation": "rdi",
        "src": GLYPH_X8_ASSET.readall(),
    },
    "S32": {
        "description": "cloth with fringe on the side",
        "pronunciation": "siA",
        "src": GLYPH_S32_ASSET.readall(),
    },
    "V26": {
        "pronunciation": "aD",
        "src": GLYPH_V26_ASSET.readall(),
    },
    "G44": {
        "description": "two quail chicks",
        "pronunciation": "ww",
        "src": GLYPH_G44_ASSET.readall(),
    },
    "F48": {
        "description": "intestine",
        "src": GLYPH_F48_ASSET.readall(),
    },
    "S6": {
        "description": "combination of pschent crown and basket",
        "pronunciation": "sxmty",
        "src": GLYPH_S6_ASSET.readall(),
    },
    "O15": {
        "description": "enclosure with cup and flat loaf",
        "pronunciation": "wsxt",
        "src": GLYPH_O15_ASSET.readall(),
    },
    "O34": {
        "description": "door bolt",
        "pronunciation": "z",
        "src": GLYPH_O34_ASSET.readall(),
    },
    "A19": {
        "description": "bent man leaning on staff",
        "src": GLYPH_A19_ASSET.readall(),
    },
    "U4": {
        "src": GLYPH_U4_ASSET.readall(),
    },
    "Z6": {
        "description": "substitute for various human figures",
        "src": GLYPH_Z6_ASSET.readall(),
    },
    "G51": {
        "description": "bird pecking at fish",
        "src": GLYPH_G51_ASSET.readall(),
    },
    "V32": {
        "pronunciation": "msn",
        "src": GLYPH_V32_ASSET.readall(),
    },
    "F31": {
        "description": "three skins tied together",
        "pronunciation": "ms",
        "src": GLYPH_F31_ASSET.readall(),
    },
    "O49": {
        "description": "village",
        "pronunciation": "niwt",
        "src": GLYPH_O49_ASSET.readall(),
    },
    "M7": {
        "description": "combination of palm branch and stool",
        "src": GLYPH_M7_ASSET.readall(),
    },
    "B7": {
        "description": "queen wearing diadem and holding flower",
        "src": GLYPH_B7_ASSET.readall(),
    },
    "N1": {
        "description": "sky",
        "pronunciation": "pt",
        "src": GLYPH_N1_ASSET.readall(),
    },
    "A17": {
        "description": "child sitting with hand to mouth",
        "pronunciation": "Xrd",
        "src": GLYPH_A17_ASSET.readall(),
    },
    "F12": {
        "description": "head and neck of animal",
        "pronunciation": "wsr",
        "src": GLYPH_F12_ASSET.readall(),
    },
    "C7": {
        "description": "god with seth-animal head",
        "pronunciation": "stX",
        "src": GLYPH_C7_ASSET.readall(),
    },
    "V11": {
        "description": "cartouche-(divided)",
        "src": GLYPH_V11_ASSET.readall(),
    },
    "E34": {
        "description": "hare",
        "pronunciation": "wn",
        "src": GLYPH_E34_ASSET.readall(),
    },
    "N13": {
        "description": "combination of crescent moon and star",
        "src": GLYPH_N13_ASSET.readall(),
    },
    "G50": {
        "description": "two plovers",
        "src": GLYPH_G50_ASSET.readall(),
    },
    "F35": {
        "description": "heart andwindpipe",
        "pronunciation": "nfr",
        "src": GLYPH_F35_ASSET.readall(),
    },
    "G28": {
        "description": "glossy ibis",
        "pronunciation": "gm",
        "src": GLYPH_G28_ASSET.readall(),
    },
    "H4": {
        "description": "head of vulture",
        "pronunciation": "nr",
        "src": GLYPH_H4_ASSET.readall(),
    },
    "A44": {
        "description": "king wearing white crown with flagellum",
        "src": GLYPH_A44_ASSET.readall(),
    },
    "F22": {
        "description": "hind-quarters of lion",
        "pronunciation": "pH",
        "src": GLYPH_F22_ASSET.readall(),
    },
    "U29": {
        "src": GLYPH_U29_ASSET.readall(),
    },
    "H2": {
        "description": "head of crested bird",
        "pronunciation": "wSm",
        "src": GLYPH_H2_ASSET.readall(),
    },
    "K1": {
        "description": "tilapia",
        "pronunciation": "in",
        "src": GLYPH_K1_ASSET.readall(),
    },
    "O12": {
        "description": "combination of palace and forearm",
        "src": GLYPH_O12_ASSET.readall(),
    },
    "U14": {
        "src": GLYPH_U14_ASSET.readall(),
    },
    "Aa15": {
        "pronunciation": "M",
        "src": GLYPH_AA15_ASSET.readall(),
    },
    "O9": {
        "description": "combination of enclosure, flat loaf and basket",
        "src": GLYPH_O9_ASSET.readall(),
    },
    "D4": {
        "description": "eye",
        "pronunciation": "ir",
        "src": GLYPH_D4_ASSET.readall(),
    },
    "O17": {
        "description": "open gateway with serpents",
        "src": GLYPH_O17_ASSET.readall(),
    },
    "G3": {
        "description": "combination of egyptian vulture and sickle",
        "src": GLYPH_G3_ASSET.readall(),
    },
    "I15": {
        "description": "snake",
        "src": GLYPH_I15_ASSET.readall(),
    },
    "V28": {
        "description": "a twisted wick",
        "pronunciation": "H",
        "src": GLYPH_V28_ASSET.readall(),
    },
    "A2": {
        "description": "man with hand to mouth",
        "src": GLYPH_A2_ASSET.readall(),
    },
    "U24": {
        "description": "handdrill(hieroglyph)",
        "pronunciation": "Hmt",
        "src": GLYPH_U24_ASSET.readall(),
    },
    "U38": {
        "description": "scale",
        "pronunciation": "mxAt",
        "src": GLYPH_U38_ASSET.readall(),
    },
    "X1": {
        "description": "loaf of bread",
        "pronunciation": "t",
        "src": GLYPH_X1_ASSET.readall(),
    },
    "R23": {
        "description": "two broad belemnites",
        "src": GLYPH_R23_ASSET.readall(),
    },
    "F19": {
        "description": "lower jaw-bone of ox",
        "src": GLYPH_F19_ASSET.readall(),
    },
    "W6": {
        "description": "metal vessel",
        "src": GLYPH_W6_ASSET.readall(),
    },
    "D36": {
        "description": "forearm (palm upwards)",
        "pronunciation": "a",
        "src": GLYPH_D36_ASSET.readall(),
    },
    "Aa29": {
        "src": GLYPH_AA29_ASSET.readall(),
    },
    "U8": {
        "src": GLYPH_U8_ASSET.readall(),
    },
    "T28": {
        "description": "butcher's block",
        "pronunciation": "Xr",
        "src": GLYPH_T28_ASSET.readall(),
    },
    "F49": {
        "description": "intestine",
        "src": GLYPH_F49_ASSET.readall(),
    },
    "U31": {
        "pronunciation": "rtH",
        "src": GLYPH_U31_ASSET.readall(),
    },
    "V33": {
        "pronunciation": "sSr",
        "src": GLYPH_V33_ASSET.readall(),
    },
    "W5": {
        "src": GLYPH_W5_ASSET.readall(),
    },
    "E4": {
        "description": "sacred cow",
        "src": GLYPH_E4_ASSET.readall(),
    },
    "Z5": {
        "description": "diagonal stroke (from hieratic)",
        "src": GLYPH_Z5_ASSET.readall(),
    },
    "Aa13": {
        "pronunciation": "im",
        "src": GLYPH_AA13_ASSET.readall(),
    },
    "O36": {
        "description": "wall",
        "pronunciation": "inb",
        "src": GLYPH_O36_ASSET.readall(),
    },
    "R6": {
        "description": "broad censer",
        "src": GLYPH_R6_ASSET.readall(),
    },
    "E23": {
        "description": "lying lion",
        "pronunciation": "rw",
        "src": GLYPH_E23_ASSET.readall(),
    },
    "E27": {
        "description": "giraffe",
        "src": GLYPH_E27_ASSET.readall(),
    },
    "E19": {
        "description": "wolf on standard with mace",
        "src": GLYPH_E19_ASSET.readall(),
    },
    "G5": {
        "description": "falcon",
        "src": GLYPH_G5_ASSET.readall(),
    },
    "S24": {
        "description": "girdle knot",
        "pronunciation": "Tz",
        "src": GLYPH_S24_ASSET.readall(),
    },
    "W19": {
        "description": "milk jug with handle",
        "pronunciation": "mi",
        "src": GLYPH_W19_ASSET.readall(),
    },
    "T30": {
        "description": "knife",
        "src": GLYPH_T30_ASSET.readall(),
    },
    "W24": {
        "description": "pot",
        "pronunciation": "nw",
        "src": GLYPH_W24_ASSET.readall(),
    },
    "D52": {
        "description": "phallus",
        "pronunciation": "mt",
        "src": GLYPH_D52_ASSET.readall(),
    },
    "O4": {
        "description": "shelter",
        "pronunciation": "h",
        "src": GLYPH_O4_ASSET.readall(),
    },
    "D31": {
        "description": "arms embracing club",
        "src": GLYPH_D31_ASSET.readall(),
    },
    "H5": {
        "description": "wing",
        "src": GLYPH_H5_ASSET.readall(),
    },
    "E28": {
        "description": "oryx",
        "src": GLYPH_E28_ASSET.readall(),
    },
    "S13": {
        "description": "combination of collar of beads and foot",
        "src": GLYPH_S13_ASSET.readall(),
    },
    "A1": {
        "description": "seated man",
        "src": GLYPH_A1_ASSET.readall(),
    },
    "C5": {
        "description": "god with ram head holding ankh",
        "src": GLYPH_C5_ASSET.readall(),
    },
    "D55": {
        "description": "legs walking backwards",
        "src": GLYPH_D55_ASSET.readall(),
    },
    "M23": {
        "description": "sedge",
        "pronunciation": "sw",
        "src": GLYPH_M23_ASSET.readall(),
    },
    "A56": {
        "description": "seated man holding stick",
        "src": GLYPH_A56_ASSET.readall(),
    },
    "R18": {
        "description": "combination of wig on pole and irrigation canal system",
        "src": GLYPH_R18_ASSET.readall(),
    },
    "R1": {
        "description": "high table with offerings",
        "pronunciation": "xAwt",
        "src": GLYPH_R1_ASSET.readall(),
    },
    "C12": {
        "description": "god with two plumes and scepter",
        "src": GLYPH_C12_ASSET.readall(),
    },
    "T35": {
        "description": "butcher's knife",
        "src": GLYPH_T35_ASSET.readall(),
    },
    "S21": {
        "description": "ring",
        "src": GLYPH_S21_ASSET.readall(),
    },
    "E3": {
        "description": "calf",
        "src": GLYPH_E3_ASSET.readall(),
    },
    "R3": {
        "description": "low table with offerings",
        "src": GLYPH_R3_ASSET.readall(),
    },
    "Y4": {
        "description": "scribe's equipment",
        "src": GLYPH_Y4_ASSET.readall(),
    },
    "R5": {
        "description": "narrow censer",
        "pronunciation": "kp",
        "src": GLYPH_R5_ASSET.readall(),
    },
    "M15": {
        "description": "clump of papyrus with buds",
        "src": GLYPH_M15_ASSET.readall(),
    },
    "A15": {
        "description": "man falling",
        "pronunciation": "xr",
        "src": GLYPH_A15_ASSET.readall(),
    },
    "Aa9": {
        "src": GLYPH_AA9_ASSET.readall(),
    },
    "E2": {
        "description": "bull charging",
        "src": GLYPH_E2_ASSET.readall(),
    },
    "U41": {
        "description": "plummet",
        "src": GLYPH_U41_ASSET.readall(),
    },
    "A37": {
        "description": "man in vessel",
        "src": GLYPH_A37_ASSET.readall(),
    },
    "M2": {
        "description": "plant",
        "pronunciation": "Hn",
        "src": GLYPH_M2_ASSET.readall(),
    },
    "D61": {
        "description": "three toes oriented leftward",
        "pronunciation": "sAH",
        "src": GLYPH_D61_ASSET.readall(),
    },
    "G43": {
        "description": "quail chick",
        "pronunciation": "w",
        "src": GLYPH_G43_ASSET.readall(),
    },
    "A39": {
        "description": "man on two giraffes",
        "src": GLYPH_A39_ASSET.readall(),
    },
    "X3": {
        "src": GLYPH_X3_ASSET.readall(),
    },
    "U12": {
        "src": GLYPH_U12_ASSET.readall(),
    },
    "R21": {
        "description": "flower with horns",
        "src": GLYPH_R21_ASSET.readall(),
    },
    "D59": {
        "description": "foot and forearm",
        "pronunciation": "ab",
        "src": GLYPH_D59_ASSET.readall(),
    },
    "V38": {
        "src": GLYPH_V38_ASSET.readall(),
    },
    "N20": {
        "description": "tongue of land",
        "pronunciation": "wDb",
        "src": GLYPH_N20_ASSET.readall(),
    },
    "U36": {
        "description": "fuller's-club",
        "pronunciation": "Hm",
        "src": GLYPH_U36_ASSET.readall(),
    },
    "E32": {
        "description": "baboon",
        "src": GLYPH_E32_ASSET.readall(),
    },
    "G1": {
        "description": "egyptian vulture",
        "pronunciation": "A",
        "src": GLYPH_G1_ASSET.readall(),
    },
    "U3": {
        "src": GLYPH_U3_ASSET.readall(),
    },
    "U33": {
        "description": "'pestle'-(curved top)",
        "pronunciation": "ti",
        "src": GLYPH_U33_ASSET.readall(),
    },
    "V30": {
        "description": "basket(hieroglyph)",
        "pronunciation": "nb",
        "src": GLYPH_V30_ASSET.readall(),
    },
    "F36": {
        "description": "lung and windpipe",
        "pronunciation": "zmA",
        "src": GLYPH_F36_ASSET.readall(),
    },
    "I7": {
        "description": "frog",
        "src": GLYPH_I7_ASSET.readall(),
    },
    "Aa14": {
        "src": GLYPH_AA14_ASSET.readall(),
    },
    "S37": {
        "description": "fan",
        "pronunciation": "xw",
        "src": GLYPH_S37_ASSET.readall(),
    },
    "S26": {
        "description": "apron",
        "pronunciation": "Sndyt",
        "src": GLYPH_S26_ASSET.readall(),
    },
    "S36": {
        "description": "sunshade",
        "src": GLYPH_S36_ASSET.readall(),
    },
    "F13": {
        "description": "horns",
        "pronunciation": "wp",
        "src": GLYPH_F13_ASSET.readall(),
    },
    "O40": {
        "description": "stair single",
        "src": GLYPH_O40_ASSET.readall(),
    },
    "U13": {
        "pronunciation": "hb",
        "src": GLYPH_U13_ASSET.readall(),
    },
    "F5": {
        "description": "hartebeest head",
        "pronunciation": "SsA",
        "src": GLYPH_F5_ASSET.readall(),
    },
    "K2": {
        "description": "barbel",
        "src": GLYPH_K2_ASSET.readall(),
    },
    "B12": {
        "src": GLYPH_B12_ASSET.readall(),
    },
    "F23": {
        "description": "forelegof ox",
        "pronunciation": "xpS",
        "src": GLYPH_F23_ASSET.readall(),
    },
    "Aa20": {
        "pronunciation": "apr",
        "src": GLYPH_AA20_ASSET.readall(),
    },
    "A45": {
        "description": "king wearing red crown",
        "src": GLYPH_A45_ASSET.readall(),
    },
    "F37": {
        "description": "backbone and ribs and spinal cord",
        "src": GLYPH_F37_ASSET.readall(),
    },
    "A13": {
        "description": "man with arms tied behind his back",
        "src": GLYPH_A13_ASSET.readall(),
    },
    "N7": {
        "description": "combination of sun and butcher's block",
        "src": GLYPH_N7_ASSET.readall(),
    },
    "W15": {
        "description": "water jar with rack",
        "src": GLYPH_W15_ASSET.readall(),
    },
    "D18": {
        "description": "ear",
        "src": GLYPH_D18_ASSET.readall(),
    },
    "B10": {
        "src": GLYPH_B10_ASSET.readall(),
    },
    "D26": {
        "description": "liquid issuing from lips",
        "src": GLYPH_D26_ASSET.readall(),
    },
    "V15": {
        "description": "tethering rope w/ walking legs",
        "pronunciation": "iTi",
        "src": GLYPH_V15_ASSET.readall(),
    },
    "C6": {
        "description": "god with jackal head",
        "pronunciation": "inpw",
        "src": GLYPH_C6_ASSET.readall(),
    },
    "D30": {
        "description": "two arms upraised with tail",
        "src": GLYPH_D30_ASSET.readall(),
    },
    "Aa5": {
        "description": "part of steering gear of a ship",
        "pronunciation": "Hp",
        "src": GLYPH_AA5_ASSET.readall(),
    },
    "G41": {
        "description": "pintail alighting",
        "pronunciation": "xn",
        "src": GLYPH_G41_ASSET.readall(),
    },
    "V34": {
        "src": GLYPH_V34_ASSET.readall(),
    },
    "T11": {
        "description": "arrow",
        "pronunciation": "zwn",
        "src": GLYPH_T11_ASSET.readall(),
    },
    "A21": {
        "description": "man holding staff with handkerchief",
        "pronunciation": "sr",
        "src": GLYPH_A21_ASSET.readall(),
    },
    "D22": {
        "description": "mouth with two strokes",
        "src": GLYPH_D22_ASSET.readall(),
    },
    "U6": {
        "pronunciation": "mr",
        "src": GLYPH_U6_ASSET.readall(),
    },
    "P2": {
        "description": "ship under sail",
        "src": GLYPH_P2_ASSET.readall(),
    },
    "L4": {
        "description": "locust",
        "src": GLYPH_L4_ASSET.readall(),
    },
    "D34": {
        "description": "armswith shieldand battle axe",
        "pronunciation": "aHA",
        "src": GLYPH_D34_ASSET.readall(),
    },
    "P7": {
        "description": "combination of mast and forearm",
        "src": GLYPH_P7_ASSET.readall(),
    },
    "G36": {
        "description": "swallow",
        "pronunciation": "wr",
        "src": GLYPH_G36_ASSET.readall(),
    },
    "N16": {
        "description": "land with grains",
        "pronunciation": "tA",
        "src": GLYPH_N16_ASSET.readall(),
    },
    "O21": {
        "description": "façade of shrine",
        "src": GLYPH_O21_ASSET.readall(),
    },
    "Aa10": {
        "src": GLYPH_AA10_ASSET.readall(),
    },
    "M8": {
        "description": "pool with lotus flowers",
        "pronunciation": "SA",
        "src": GLYPH_M8_ASSET.readall(),
    },
    "A46": {
        "description": "king wearing red crown with flagellum",
        "src": GLYPH_A46_ASSET.readall(),
    },
    "C3": {
        "description": "god with ibis head",
        "pronunciation": "DHwty",
        "src": GLYPH_C3_ASSET.readall(),
    },
    "G26": {
        "description": "sacred ibis on standard",
        "src": GLYPH_G26_ASSET.readall(),
    },
    "B1": {
        "description": "seated woman",
        "src": GLYPH_B1_ASSET.readall(),
    },
    "S23": {
        "description": "two whipswith shen ring",
        "pronunciation": "dmD",
        "src": GLYPH_S23_ASSET.readall(),
    },
    "B2": {
        "description": "pregnant woman",
        "src": GLYPH_B2_ASSET.readall(),
    },
    "A12": {
        "description": "soldier with bow and quiver",
        "pronunciation": "mSa",
        "src": GLYPH_A12_ASSET.readall(),
    },
    "G34": {
        "description": "ostrich",
        "src": GLYPH_G34_ASSET.readall(),
    },
    "C2": {
        "description": "god with falcon head and sun-disk holding ankh",
        "src": GLYPH_C2_ASSET.readall(),
    },
    "N14": {
        "description": "star",
        "pronunciation": "sbA",
        "src": GLYPH_N14_ASSET.readall(),
    },
    "F51": {
        "description": "piece of flesh",
        "src": GLYPH_F51_ASSET.readall(),
    },
    "D6": {
        "description": "eye with painted upper lid",
        "src": GLYPH_D6_ASSET.readall(),
    },
    "F14": {
        "description": "horns with palm branch",
        "src": GLYPH_F14_ASSET.readall(),
    },
    "Aa23": {
        "src": GLYPH_AA23_ASSET.readall(),
    },
    "C18": {
        "description": "squatting god",
        "src": GLYPH_C18_ASSET.readall(),
    },
    "V5": {
        "pronunciation": "snT",
        "src": GLYPH_V5_ASSET.readall(),
    },
    "P6": {
        "description": "mast",
        "pronunciation": "aHa",
        "src": GLYPH_P6_ASSET.readall(),
    },
    "G15": {
        "description": "combination of vulture and flagellum",
        "src": GLYPH_G15_ASSET.readall(),
    },
    "A40": {
        "description": "seated god",
        "src": GLYPH_A40_ASSET.readall(),
    },
    "F41": {
        "description": "vertebrae",
        "src": GLYPH_F41_ASSET.readall(),
    },
    "V8": {
        "src": GLYPH_V8_ASSET.readall(),
    },
    "A20": {
        "description": "man leaning on forked staff",
        "src": GLYPH_A20_ASSET.readall(),
    },
    "E16": {
        "description": "lying canine on shrine",
        "src": GLYPH_E16_ASSET.readall(),
    },
    "G16": {
        "description": "vulture and cobra each on a basket",
        "pronunciation": "nbty",
        "src": GLYPH_G16_ASSET.readall(),
    },
    "A24": {
        "description": "man striking with both hands",
        "src": GLYPH_A24_ASSET.readall(),
    },
    "E12": {
        "description": "pig",
        "src": GLYPH_E12_ASSET.readall(),
    },
    "Z93": {
        "src": GLYPH_Z93_ASSET.readall(),
    },
    "T10": {
        "description": "composite bow",
        "pronunciation": "pD",
        "src": GLYPH_T10_ASSET.readall(),
    },
    "D41": {
        "description": "forearm with palm down and bent upper arm",
        "src": GLYPH_D41_ASSET.readall(),
    },
    "V21": {
        "description": "fetter + cobra",
        "src": GLYPH_V21_ASSET.readall(),
    },
    "U23": {
        "description": "chisel",
        "pronunciation": "Ab",
        "src": GLYPH_U23_ASSET.readall(),
    },
    "N42": {
        "description": "well with line of water",
        "src": GLYPH_N42_ASSET.readall(),
    },
    "I8": {
        "description": "tadpole",
        "pronunciation": "Hfn",
        "src": GLYPH_I8_ASSET.readall(),
    },
    "C20": {
        "description": "mummy-shaped god in shrine",
        "src": GLYPH_C20_ASSET.readall(),
    },
    "D8": {
        "description": "eye enclosed in sandy tract",
        "src": GLYPH_D8_ASSET.readall(),
    },
    "A14": {
        "description": "falling man with blood streaming from his head",
        "src": GLYPH_A14_ASSET.readall(),
    },
    "S33": {
        "description": "sandal",
        "pronunciation": "Tb",
        "src": GLYPH_S33_ASSET.readall(),
    },
    "S10": {
        "description": "headband",
        "pronunciation": "mDH",
        "src": GLYPH_S10_ASSET.readall(),
    },
    "M13": {
        "description": "papyrusstem",
        "pronunciation": "wAD",
        "src": GLYPH_M13_ASSET.readall(),
    },
    "A7": {
        "description": "fatigued man",
        "src": GLYPH_A7_ASSET.readall(),
    },
    "W9": {
        "description": "stone jug",
        "pronunciation": "Xnm",
        "src": GLYPH_W9_ASSET.readall(),
    },
    "D39": {
        "description": "forearm with bowl",
        "src": GLYPH_D39_ASSET.readall(),
    },
    "A48": {
        "description": "beardless man seated and holding knife",
        "src": GLYPH_A48_ASSET.readall(),
    },
    "U25": {
        "src": GLYPH_U25_ASSET.readall(),
    },
    "D63": {
        "description": "two toes oriented leftward",
        "src": GLYPH_D63_ASSET.readall(),
    },
    "D5": {
        "description": "eye touched up with paint",
        "src": GLYPH_D5_ASSET.readall(),
    },
    "G38": {
        "description": "white-fronted goose",
        "pronunciation": "gb",
        "src": GLYPH_G38_ASSET.readall(),
    },
    "O10": {
        "description": "combination of enclosure and falcon",
        "src": GLYPH_O10_ASSET.readall(),
    },
    "U5": {
        "src": GLYPH_U5_ASSET.readall(),
    },
    "N38": {
        "description": "deep pool",
        "src": GLYPH_N38_ASSET.readall(),
    },
    "W23": {
        "description": "beer jug",
        "src": GLYPH_W23_ASSET.readall(),
    },
    "U40": {
        "description": "a support-(to lift)",
        "src": GLYPH_U40_ASSET.readall(),
    },
    "C1": {
        "description": "god with sun-disk and uraeus",
        "src": GLYPH_C1_ASSET.readall(),
    },
    "H7": {
        "description": "claw",
        "src": GLYPH_H7_ASSET.readall(),
    },
    "V10": {
        "description": "cartouche",
        "src": GLYPH_V10_ASSET.readall(),
    },
    "V3": {
        "pronunciation": "sTAw",
        "src": GLYPH_V3_ASSET.readall(),
    },
    "F38": {
        "description": "backbone and ribs",
        "src": GLYPH_F38_ASSET.readall(),
    },
    "O30": {
        "description": "support",
        "pronunciation": "zxnt",
        "src": GLYPH_O30_ASSET.readall(),
    },
    "A3": {
        "description": "man sitting on heel",
        "src": GLYPH_A3_ASSET.readall(),
    },
    "S39": {
        "description": "shepherd's crook",
        "pronunciation": "awt",
        "src": GLYPH_S39_ASSET.readall(),
    },
    "F28": {
        "description": "skin of cow with straight tail",
        "src": GLYPH_F28_ASSET.readall(),
    },
    "N18": {
        "description": "sandy tract",
        "pronunciation": "iw",
        "src": GLYPH_N18_ASSET.readall(),
    },
    "S27": {
        "description": "cloth with two strands",
        "pronunciation": "mnxt",
        "src": GLYPH_S27_ASSET.readall(),
    },
    "T9": {
        "description": "bow",
        "pronunciation": "pd",
        "src": GLYPH_T9_ASSET.readall(),
    },
    "R4": {
        "description": "loaf on mat",
        "pronunciation": "Htp",
        "src": GLYPH_R4_ASSET.readall(),
    },
    "W4": {
        "description": "festival chamber, (the tail is also vertical 'great': ꜥꜣ)",
        "src": GLYPH_W4_ASSET.readall(),
    },
    "V37": {
        "pronunciation": "idr",
        "src": GLYPH_V37_ASSET.readall(),
    },
    "U34": {
        "pronunciation": "xsf",
        "src": GLYPH_U34_ASSET.readall(),
    },
    "V36": {
        "description": "doubled container(or-added-glyphs)many spellings",
        "src": GLYPH_V36_ASSET.readall(),
    },
    "O22": {
        "description": "booth with pole",
        "pronunciation": "zH",
        "src": GLYPH_O22_ASSET.readall(),
    },
    "A52": {
        "description": "noble squatting with flagellum",
        "src": GLYPH_A52_ASSET.readall(),
    },
    "T1": {
        "description": "mace with flat head",
        "src": GLYPH_T1_ASSET.readall(),
    },
    "A38": {
        "description": "man holding necks of two emblematic animals with panther heads",
        "pronunciation": "qiz",
        "src": GLYPH_A38_ASSET.readall(),
    },
    "F39": {
        "description": "backbone and spinal cord",
        "pronunciation": "imAx",
        "src": GLYPH_F39_ASSET.readall(),
    },
    "N26": {
        "description": "two hills",
        "pronunciation": "Dw",
        "src": GLYPH_N26_ASSET.readall(),
    },
    "U39": {
        "src": GLYPH_U39_ASSET.readall(),
    },
    "G18": {
        "description": "two owls",
        "pronunciation": "mm",
        "src": GLYPH_G18_ASSET.readall(),
    },
    "G25": {
        "description": "northern bald ibis",
        "pronunciation": "Ax",
        "src": GLYPH_G25_ASSET.readall(),
    },
    "M10": {
        "description": "lotus bud with straight stem",
        "src": GLYPH_M10_ASSET.readall(),
    },
    "O37": {
        "description": "falling wall",
        "src": GLYPH_O37_ASSET.readall(),
    },
    "U17": {
        "description": "pick, opening earth",
        "pronunciation": "grg",
        "src": GLYPH_U17_ASSET.readall(),
    },
    "F4": {
        "description": "forepart of lion",
        "pronunciation": "HAt",
        "src": GLYPH_F4_ASSET.readall(),
    },
    "S40": {
        "description": "wꜣssceptre(uꜣs)",
        "pronunciation": "wAs",
        "src": GLYPH_S40_ASSET.readall(),
    },
    "S22": {
        "description": "shoulder-knot",
        "pronunciation": "sT",
        "src": GLYPH_S22_ASSET.readall(),
    },
    "Aa8": {
        "description": "irrigation tunnels",
        "pronunciation": "qn",
        "src": GLYPH_AA8_ASSET.readall(),
    },
    "E9": {
        "description": "newborn hartebeest",
        "src": GLYPH_E9_ASSET.readall(),
    },
    "T21": {
        "description": "harpoon",
        "pronunciation": "wa",
        "src": GLYPH_T21_ASSET.readall(),
    },
    "Aa19": {
        "src": GLYPH_AA19_ASSET.readall(),
    },
    "A55": {
        "description": "mummy on bed",
        "src": GLYPH_A55_ASSET.readall(),
    },
    "G32": {
        "description": "heron on perch",
        "pronunciation": "baHi",
        "src": GLYPH_G32_ASSET.readall(),
    },
    "Q2": {
        "description": "carryingchair",
        "pronunciation": "wz",
        "src": GLYPH_Q2_ASSET.readall(),
    },
    "I2": {
        "description": "turtle",
        "pronunciation": "Styw",
        "src": GLYPH_I2_ASSET.readall(),
    },
    "Z2": {
        "description": "plural stroke (horizontal)",
        "src": GLYPH_Z2_ASSET.readall(),
    },
    "M1": {
        "description": "tree",
        "pronunciation": "iAm",
        "src": GLYPH_M1_ASSET.readall(),
    },
    "V17": {
        "description": "lifesaver",
        "src": GLYPH_V17_ASSET.readall(),
    },
    "N33": {
        "description": "grain",
        "src": GLYPH_N33_ASSET.readall(),
    },
    "W3": {
        "description": "alabasterbasin",
        "pronunciation": "Hb",
        "src": GLYPH_W3_ASSET.readall(),
    },
    "I10": {
        "description": "cobra",
        "pronunciation": "D",
        "src": GLYPH_I10_ASSET.readall(),
    },
    "I13": {
        "description": "erect cobra on basket",
        "src": GLYPH_I13_ASSET.readall(),
    },
    "D49": {
        "description": "fist",
        "src": GLYPH_D49_ASSET.readall(),
    },
    "O24": {
        "description": "pyramid",
        "src": GLYPH_O24_ASSET.readall(),
    },
    "W7": {
        "description": "granite bowl",
        "src": GLYPH_W7_ASSET.readall(),
    },
    "O3": {
        "description": "combination of house, oar, tall loaf and beer jug",
        "src": GLYPH_O3_ASSET.readall(),
    },
    "D28": {
        "description": "two arms upraised",
        "pronunciation": "kA",
        "src": GLYPH_D28_ASSET.readall(),
    },
    "M27": {
        "description": "combination of flowering sedge and forearm",
        "src": GLYPH_M27_ASSET.readall(),
    },
    "K3": {
        "description": "mullet",
        "pronunciation": "ad",
        "src": GLYPH_K3_ASSET.readall(),
    },
    "R8": {
        "description": "cloth on pole",
        "pronunciation": "nTr",
        "src": GLYPH_R8_ASSET.readall(),
    },
    "V24": {
        "pronunciation": "wD",
        "src": GLYPH_V24_ASSET.readall(),
    },
    "T3": {
        "description": "mace with round head",
        "pronunciation": "HD",
        "src": GLYPH_T3_ASSET.readall(),
    },
    "E31": {
        "description": "goat with collar",
        "src": GLYPH_E31_ASSET.readall(),
    },
    "R25": {
        "description": "two bows tied vertically",
        "src": GLYPH_R25_ASSET.readall(),
    },
    "D33": {
        "description": "arms rowing",
        "src": GLYPH_D33_ASSET.readall(),
    },
    "U19": {
        "src": GLYPH_U19_ASSET.readall(),
    },
    "V4": {
        "description": "lasso",
        "pronunciation": "wA",
        "src": GLYPH_V4_ASSET.readall(),
    },
    "D11": {
        "description": "left part of the eye of horus",
        "src": GLYPH_D11_ASSET.readall(),
    },
    "W12": {
        "description": "jar stand",
        "src": GLYPH_W12_ASSET.readall(),
    },
    "F46": {
        "description": "intestine",
        "pronunciation": "qAb",
        "src": GLYPH_F46_ASSET.readall(),
    },
    "F15": {
        "description": "horns with palm branch and sun",
        "src": GLYPH_F15_ASSET.readall(),
    },
    "A47": {
        "description": "shepherd seated and wrapped in mantle, holding stick",
        "pronunciation": "iry",
        "src": GLYPH_A47_ASSET.readall(),
    },
    "G17": {
        "description": "owl",
        "pronunciation": "m",
        "src": GLYPH_G17_ASSET.readall(),
    },
    "X2": {
        "src": GLYPH_X2_ASSET.readall(),
    },
    "O5": {
        "description": "winding wall from upper-left corner",
        "src": GLYPH_O5_ASSET.readall(),
    },
    "D23": {
        "description": "mouth with three strokes",
        "src": GLYPH_D23_ASSET.readall(),
    },
    "D50": {
        "description": "one finger",
        "pronunciation": "Dba",
        "src": GLYPH_D50_ASSET.readall(),
    },
    "D25": {
        "description": "lips",
        "pronunciation": "spty",
        "src": GLYPH_D25_ASSET.readall(),
    },
    "E29": {
        "description": "gazelle",
        "src": GLYPH_E29_ASSET.readall(),
    },
    "G53": {
        "description": "human-headed bird with bowl with smoke",
        "src": GLYPH_G53_ASSET.readall(),
    },
    "U20": {
        "src": GLYPH_U20_ASSET.readall(),
    },
    "N40": {
        "description": "poolwith legs",
        "pronunciation": "Sm",
        "src": GLYPH_N40_ASSET.readall(),
    },
    "K7": {
        "description": "puffer",
        "src": GLYPH_K7_ASSET.readall(),
    },
    "F43": {
        "description": "ribs",
        "src": GLYPH_F43_ASSET.readall(),
    },
    "N19": {
        "description": "two sandy tracts",
        "src": GLYPH_N19_ASSET.readall(),
    },
    "Z7": {
        "description": "coil(hieratic equivalent)",
        "pronunciation": "W",
        "src": GLYPH_Z7_ASSET.readall(),
    },
    "E8": {
        "description": "kid",
        "src": GLYPH_E8_ASSET.readall(),
    },
    "D37": {
        "description": "forearm with bread cone",
        "src": GLYPH_D37_ASSET.readall(),
    },
    "W21": {
        "description": "wine jars",
        "src": GLYPH_W21_ASSET.readall(),
    },
    "Aa7": {
        "description": "a smiting-blade",
        "src": GLYPH_AA7_ASSET.readall(),
    },
    "P9": {
        "description": "combination of oar and horned viper",
        "src": GLYPH_P9_ASSET.readall(),
    },
    "W25": {
        "description": "pot with legs",
        "pronunciation": "ini",
        "src": GLYPH_W25_ASSET.readall(),
    },
    "C11": {
        "description": "god with arms supporting the sky and palm branch on head",
        "pronunciation": "HH",
        "src": GLYPH_C11_ASSET.readall(),
    },
    "R19": {
        "description": "scepter with feather",
        "src": GLYPH_R19_ASSET.readall(),
    },
    "N5": {
        "description": "sun",
        "pronunciation": "zw",
        "src": GLYPH_N5_ASSET.readall(),
    },
    "O13": {
        "description": "battlemented enclosure",
        "src": GLYPH_O13_ASSET.readall(),
    },
    "W8": {
        "description": "granite bowl",
        "src": GLYPH_W8_ASSET.readall(),
    },
    "M4": {
        "description": "palm branch",
        "pronunciation": "rnp",
        "src": GLYPH_M4_ASSET.readall(),
    },
    "A51": {
        "description": "noble on chair with flagellum",
        "pronunciation": "Spsi",
        "src": GLYPH_A51_ASSET.readall(),
    },
    "Y1": {
        "description": "papyrusroll",
        "pronunciation": "mDAt",
        "src": GLYPH_Y1_ASSET.readall(),
    },
    "M41": {
        "description": "piece of wood",
        "src": GLYPH_M41_ASSET.readall(),
    },
    "O7": {
        "description": "combination of enclosure and flat loaf",
        "src": GLYPH_O7_ASSET.readall(),
    },
    "T25": {
        "description": "float",
        "pronunciation": "DbA",
        "src": GLYPH_T25_ASSET.readall(),
    },
    "Z11": {
        "description": "two planks crossed and joined",
        "pronunciation": "imi",
        "src": GLYPH_Z11_ASSET.readall(),
    },
    "Q5": {
        "description": "chest",
        "src": GLYPH_Q5_ASSET.readall(),
    },
}
