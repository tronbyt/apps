"""
Applet: Cuneiform
Summary: Random cuneiform signs
Description: Shows a cuneiform sign and its Sumerian transliterations.
Author: dinosaursrarr
"""

load("hash.star", "hash")
load("images/sign_a.png", SIGN_A_ASSET = "file")
load("images/sign_a2.png", SIGN_A2_ASSET = "file")
load("images/sign_a3.png", SIGN_A3_ASSET = "file")
load("images/sign_a3_x_a.png", SIGN_A3_X_A_ASSET = "file")
load("images/sign_a3_x_ne.png", SIGN_A3_X_NE_ASSET = "file")
load("images/sign_a3_x_tur.png", SIGN_A3_X_TUR_ASSET = "file")
load("images/sign_a6.png", SIGN_A6_ASSET = "file")
load("images/sign_a_2.png", SIGN_A_2_ASSET = "file")
load("images/sign_a_gab.png", SIGN_A_GAB_ASSET = "file")
load("images/sign_a_x_ha.png", SIGN_A_X_HA_ASSET = "file")
load("images/sign_ab.png", SIGN_AB_ASSET = "file")
load("images/sign_ab2.png", SIGN_AB2_ASSET = "file")
load("images/sign_ab2_x_a3.png", SIGN_AB2_X_A3_ASSET = "file")
load("images/sign_ab2_x_gan2tenu.png", SIGN_AB2_X_GAN2TENU_ASSET = "file")
load("images/sign_ab_x_gal.png", SIGN_AB_X_GAL_ASSET = "file")
load("images/sign_ab_x_ha.png", SIGN_AB_X_HA_ASSET = "file")
load("images/sign_abgunu.png", SIGN_ABGUNU_ASSET = "file")
load("images/sign_ad.png", SIGN_AD_ASSET = "file")
load("images/sign_ak.png", SIGN_AK_ASSET = "file")
load("images/sign_ak_x_erin2.png", SIGN_AK_X_ERIN2_ASSET = "file")
load("images/sign_al.png", SIGN_AL_ASSET = "file")
load("images/sign_alan.png", SIGN_ALAN_ASSET = "file")
load("images/sign_amar.png", SIGN_AMAR_ASSET = "file")
load("images/sign_amar_x_e.png", SIGN_AMAR_X_E_ASSET = "file")
load("images/sign_an.png", SIGN_AN_ASSET = "file")
load("images/sign_an_a_an.png", SIGN_AN_A_AN_ASSET = "file")
load("images/sign_an_an.png", SIGN_AN_AN_ASSET = "file")
load("images/sign_an_e.png", SIGN_AN_E_ASSET = "file")
load("images/sign_an_plus_naga_inverted_an_plus_naga.png", SIGN_AN_PLUS_NAGA_INVERTED_AN_PLUS_NAGA_ASSET = "file")
load("images/sign_apin.png", SIGN_APIN_ASSET = "file")
load("images/sign_arad.png", SIGN_ARAD_ASSET = "file")
load("images/sign_arad_x_kur.png", SIGN_ARAD_X_KUR_ASSET = "file")
load("images/sign_ba.png", SIGN_BA_ASSET = "file")
load("images/sign_bad.png", SIGN_BAD_ASSET = "file")
load("images/sign_bahar2.png", SIGN_BAHAR2_ASSET = "file")
load("images/sign_bal.png", SIGN_BAL_ASSET = "file")
load("images/sign_balag.png", SIGN_BALAG_ASSET = "file")
load("images/sign_bar.png", SIGN_BAR_ASSET = "file")
load("images/sign_bara2.png", SIGN_BARA2_ASSET = "file")
load("images/sign_bi.png", SIGN_BI_ASSET = "file")
load("images/sign_bu.png", SIGN_BU_ASSET = "file")
load("images/sign_bu_bu_ab.png", SIGN_BU_BU_AB_ASSET = "file")
load("images/sign_bulug.png", SIGN_BULUG_ASSET = "file")
load("images/sign_bur.png", SIGN_BUR_ASSET = "file")
load("images/sign_bur2.png", SIGN_BUR2_ASSET = "file")
load("images/sign_da.png", SIGN_DA_ASSET = "file")
load("images/sign_dag.png", SIGN_DAG_ASSET = "file")
load("images/sign_dag_kisim5_x_ga.png", SIGN_DAG_KISIM5_X_GA_ASSET = "file")
load("images/sign_dag_kisim5_x_gir2.png", SIGN_DAG_KISIM5_X_GIR2_ASSET = "file")
load("images/sign_dag_kisim5_x_lu.png", SIGN_DAG_KISIM5_X_LU_ASSET = "file")
load("images/sign_dag_kisim5_x_lu_plus_ma_2.png", SIGN_DAG_KISIM5_X_LU_PLUS_MA_2_ASSET = "file")
load("images/sign_dag_kisim5_x_si.png", SIGN_DAG_KISIM5_X_SI_ASSET = "file")
load("images/sign_dag_kisim5_x_u2_plus_gir2.png", SIGN_DAG_KISIM5_X_U2_PLUS_GIR2_ASSET = "file")
load("images/sign_dam.png", SIGN_DAM_ASSET = "file")
load("images/sign_dar.png", SIGN_DAR_ASSET = "file")
load("images/sign_dara3.png", SIGN_DARA3_ASSET = "file")
load("images/sign_dara4.png", SIGN_DARA4_ASSET = "file")
load("images/sign_di.png", SIGN_DI_ASSET = "file")
load("images/sign_dib.png", SIGN_DIB_ASSET = "file")
load("images/sign_dim.png", SIGN_DIM_ASSET = "file")
load("images/sign_dim2.png", SIGN_DIM2_ASSET = "file")
load("images/sign_dim_x_e.png", SIGN_DIM_X_E_ASSET = "file")
load("images/sign_din.png", SIGN_DIN_ASSET = "file")
load("images/sign_du.png", SIGN_DU_ASSET = "file")
load("images/sign_du_du.png", SIGN_DU_DU_ASSET = "file")
load("images/sign_du_e_ig.png", SIGN_DU_E_IG_ASSET = "file")
load("images/sign_dub.png", SIGN_DUB_ASSET = "file")
load("images/sign_dub2.png", SIGN_DUB2_ASSET = "file")
load("images/sign_dug.png", SIGN_DUG_ASSET = "file")
load("images/sign_dugud.png", SIGN_DUGUD_ASSET = "file")
load("images/sign_dugunu.png", SIGN_DUGUNU_ASSET = "file")
load("images/sign_dun.png", SIGN_DUN_ASSET = "file")
load("images/sign_dun3.png", SIGN_DUN3_ASSET = "file")
load("images/sign_dun3gunu.png", SIGN_DUN3GUNU_ASSET = "file")
load("images/sign_dun3gunugunu.png", SIGN_DUN3GUNUGUNU_ASSET = "file")
load("images/sign_dun3gunugunu_e_ig.png", SIGN_DUN3GUNUGUNU_E_IG_ASSET = "file")
load("images/sign_e.png", SIGN_E_ASSET = "file")
load("images/sign_e2.png", SIGN_E2_ASSET = "file")
load("images/sign_e_2.png", SIGN_E_2_ASSET = "file")
load("images/sign_e_e_tab_tab_gar_gar.png", SIGN_E_E_TAB_TAB_GAR_GAR_ASSET = "file")
load("images/sign_edin.png", SIGN_EDIN_ASSET = "file")
load("images/sign_eg9.png", SIGN_EG9_ASSET = "file")
load("images/sign_egir.png", SIGN_EGIR_ASSET = "file")
load("images/sign_eight_di.png", SIGN_EIGHT_DI_ASSET = "file")
load("images/sign_el.png", SIGN_EL_ASSET = "file")
load("images/sign_en.png", SIGN_EN_ASSET = "file")
load("images/sign_en_x_gan2tenu.png", SIGN_EN_X_GAN2TENU_ASSET = "file")
load("images/sign_eren.png", SIGN_EREN_ASSET = "file")
load("images/sign_erin2.png", SIGN_ERIN2_ASSET = "file")
load("images/sign_ezen.png", SIGN_EZEN_ASSET = "file")
load("images/sign_ezen_x_a.png", SIGN_EZEN_X_A_ASSET = "file")
load("images/sign_ezen_x_bad.png", SIGN_EZEN_X_BAD_ASSET = "file")
load("images/sign_ezen_x_kaskal.png", SIGN_EZEN_X_KASKAL_ASSET = "file")
load("images/sign_ezen_x_ku3.png", SIGN_EZEN_X_KU3_ASSET = "file")
load("images/sign_ezen_x_la.png", SIGN_EZEN_X_LA_ASSET = "file")
load("images/sign_ezen_x_lal_x_lal.png", SIGN_EZEN_X_LAL_X_LAL_ASSET = "file")
load("images/sign_five_di.png", SIGN_FIVE_DI_ASSET = "file")
load("images/sign_five_u.png", SIGN_FIVE_U_ASSET = "file")
load("images/sign_four_di.png", SIGN_FOUR_DI_ASSET = "file")
load("images/sign_four_di_var.png", SIGN_FOUR_DI_VAR_ASSET = "file")
load("images/sign_ga.png", SIGN_GA_ASSET = "file")
load("images/sign_ga2.png", SIGN_GA2_ASSET = "file")
load("images/sign_ga2_x_an.png", SIGN_GA2_X_AN_ASSET = "file")
load("images/sign_ga2_x_e.png", SIGN_GA2_X_E_ASSET = "file")
load("images/sign_ga2_x_gan2tenu.png", SIGN_GA2_X_GAN2TENU_ASSET = "file")
load("images/sign_ga2_x_gar.png", SIGN_GA2_X_GAR_ASSET = "file")
load("images/sign_ga2_x_me_plus_en.png", SIGN_GA2_X_ME_PLUS_EN_ASSET = "file")
load("images/sign_ga2_x_mi.png", SIGN_GA2_X_MI_ASSET = "file")
load("images/sign_ga2_x_nun.png", SIGN_GA2_X_NUN_ASSET = "file")
load("images/sign_ga2_x_nun_nun.png", SIGN_GA2_X_NUN_NUN_ASSET = "file")
load("images/sign_ga2_x_pa.png", SIGN_GA2_X_PA_ASSET = "file")
load("images/sign_ga2_x_sal.png", SIGN_GA2_X_SAL_ASSET = "file")
load("images/sign_ga2_x_tak4.png", SIGN_GA2_X_TAK4_ASSET = "file")
load("images/sign_gaba.png", SIGN_GABA_ASSET = "file")
load("images/sign_gad.png", SIGN_GAD_ASSET = "file")
load("images/sign_gad_gad_gar_gar.png", SIGN_GAD_GAD_GAR_GAR_ASSET = "file")
load("images/sign_gagunu.png", SIGN_GAGUNU_ASSET = "file")
load("images/sign_gal.png", SIGN_GAL_ASSET = "file")
load("images/sign_gal_gad_gad_gar_gar.png", SIGN_GAL_GAD_GAD_GAR_GAR_ASSET = "file")
load("images/sign_galam.png", SIGN_GALAM_ASSET = "file")
load("images/sign_gam.png", SIGN_GAM_ASSET = "file")
load("images/sign_gan.png", SIGN_GAN_ASSET = "file")
load("images/sign_gan2.png", SIGN_GAN2_ASSET = "file")
load("images/sign_gan2_gan2.png", SIGN_GAN2_GAN2_ASSET = "file")
load("images/sign_gan2tenu.png", SIGN_GAN2TENU_ASSET = "file")
load("images/sign_gar.png", SIGN_GAR_ASSET = "file")
load("images/sign_gar3.png", SIGN_GAR3_ASSET = "file")
load("images/sign_ge_tin.png", SIGN_GE_TIN_ASSET = "file")
load("images/sign_gi.png", SIGN_GI_ASSET = "file")
load("images/sign_gi4.png", SIGN_GI4_ASSET = "file")
load("images/sign_gi_gi.png", SIGN_GI_GI_ASSET = "file")
load("images/sign_gidim.png", SIGN_GIDIM_ASSET = "file")
load("images/sign_gig.png", SIGN_GIG_ASSET = "file")
load("images/sign_gir2.png", SIGN_GIR2_ASSET = "file")
load("images/sign_gir2gunu.png", SIGN_GIR2GUNU_ASSET = "file")
load("images/sign_gir3.png", SIGN_GIR3_ASSET = "file")
load("images/sign_gir3_x_a_plus_igi.png", SIGN_GIR3_X_A_PLUS_IGI_ASSET = "file")
load("images/sign_gir3_x_gan2tenu.png", SIGN_GIR3_X_GAN2TENU_ASSET = "file")
load("images/sign_gir3_x_lu_plus_igi.png", SIGN_GIR3_X_LU_PLUS_IGI_ASSET = "file")
load("images/sign_gisal.png", SIGN_GISAL_ASSET = "file")
load("images/sign_gu.png", SIGN_GU_ASSET = "file")
load("images/sign_gu2.png", SIGN_GU2_ASSET = "file")
load("images/sign_gu2_x_kak.png", SIGN_GU2_X_KAK_ASSET = "file")
load("images/sign_gu2_x_nun.png", SIGN_GU2_X_NUN_ASSET = "file")
load("images/sign_gu_gu.png", SIGN_GU_GU_ASSET = "file")
load("images/sign_gud.png", SIGN_GUD_ASSET = "file")
load("images/sign_gud_x_a_plus_kur.png", SIGN_GUD_X_A_PLUS_KUR_ASSET = "file")
load("images/sign_gud_x_kur.png", SIGN_GUD_X_KUR_ASSET = "file")
load("images/sign_gul.png", SIGN_GUL_ASSET = "file")
load("images/sign_gum.png", SIGN_GUM_ASSET = "file")
load("images/sign_gum_x_e.png", SIGN_GUM_X_E_ASSET = "file")
load("images/sign_gur.png", SIGN_GUR_ASSET = "file")
load("images/sign_gur7.png", SIGN_GUR7_ASSET = "file")
load("images/sign_gurun.png", SIGN_GURUN_ASSET = "file")
load("images/sign_ha.png", SIGN_HA_ASSET = "file")
load("images/sign_hagunu.png", SIGN_HAGUNU_ASSET = "file")
load("images/sign_hal.png", SIGN_HAL_ASSET = "file")
load("images/sign_hi.png", SIGN_HI_ASSET = "file")
load("images/sign_hi_x_a.png", SIGN_HI_X_A_ASSET = "file")
load("images/sign_hi_x_a_2.png", SIGN_HI_X_A_2_ASSET = "file")
load("images/sign_hi_x_bad.png", SIGN_HI_X_BAD_ASSET = "file")
load("images/sign_hi_x_e.png", SIGN_HI_X_E_ASSET = "file")
load("images/sign_hi_x_nun.png", SIGN_HI_X_NUN_ASSET = "file")
load("images/sign_hu.png", SIGN_HU_ASSET = "file")
load("images/sign_hub2.png", SIGN_HUB2_ASSET = "file")
load("images/sign_hub2_x_ud.png", SIGN_HUB2_X_UD_ASSET = "file")
load("images/sign_hul2.png", SIGN_HUL2_ASSET = "file")
load("images/sign_i.png", SIGN_I_ASSET = "file")
load("images/sign_i_a.png", SIGN_I_A_ASSET = "file")
load("images/sign_ib.png", SIGN_IB_ASSET = "file")
load("images/sign_id.png", SIGN_ID_ASSET = "file")
load("images/sign_id_x_a.png", SIGN_ID_X_A_ASSET = "file")
load("images/sign_idim.png", SIGN_IDIM_ASSET = "file")
load("images/sign_ig.png", SIGN_IG_ASSET = "file")
load("images/sign_igi.png", SIGN_IGI_ASSET = "file")
load("images/sign_igigunu.png", SIGN_IGIGUNU_ASSET = "file")
load("images/sign_il.png", SIGN_IL_ASSET = "file")
load("images/sign_il2.png", SIGN_IL2_ASSET = "file")
load("images/sign_im.png", SIGN_IM_ASSET = "file")
load("images/sign_im_x_gar.png", SIGN_IM_X_GAR_ASSET = "file")
load("images/sign_im_x_igigunu.png", SIGN_IM_X_IGIGUNU_ASSET = "file")
load("images/sign_im_x_ku_u2.png", SIGN_IM_X_KU_U2_ASSET = "file")
load("images/sign_im_x_tak4.png", SIGN_IM_X_TAK4_ASSET = "file")
load("images/sign_imin.png", SIGN_IMIN_ASSET = "file")
load("images/sign_in.png", SIGN_IN_ASSET = "file")
load("images/sign_inig.png", SIGN_INIG_ASSET = "file")
load("images/sign_ir.png", SIGN_IR_ASSET = "file")
load("images/sign_ita.png", SIGN_ITA_ASSET = "file")
load("images/sign_ka.png", SIGN_KA_ASSET = "file")
load("images/sign_ka2.png", SIGN_KA2_ASSET = "file")
load("images/sign_ka_x_a.png", SIGN_KA_X_A_ASSET = "file")
load("images/sign_ka_x_bad.png", SIGN_KA_X_BAD_ASSET = "file")
load("images/sign_ka_x_balag.png", SIGN_KA_X_BALAG_ASSET = "file")
load("images/sign_ka_x_e.png", SIGN_KA_X_E_ASSET = "file")
load("images/sign_ka_x_e_2.png", SIGN_KA_X_E_2_ASSET = "file")
load("images/sign_ka_x_ga.png", SIGN_KA_X_GA_ASSET = "file")
load("images/sign_ka_x_gan2tenu.png", SIGN_KA_X_GAN2TENU_ASSET = "file")
load("images/sign_ka_x_gar.png", SIGN_KA_X_GAR_ASSET = "file")
load("images/sign_ka_x_id.png", SIGN_KA_X_ID_ASSET = "file")
load("images/sign_ka_x_im.png", SIGN_KA_X_IM_ASSET = "file")
load("images/sign_ka_x_li.png", SIGN_KA_X_LI_ASSET = "file")
load("images/sign_ka_x_me.png", SIGN_KA_X_ME_ASSET = "file")
load("images/sign_ka_x_mi.png", SIGN_KA_X_MI_ASSET = "file")
load("images/sign_ka_x_ne.png", SIGN_KA_X_NE_ASSET = "file")
load("images/sign_ka_x_nun.png", SIGN_KA_X_NUN_ASSET = "file")
load("images/sign_ka_x_sa.png", SIGN_KA_X_SA_ASSET = "file")
load("images/sign_ka_x_sar.png", SIGN_KA_X_SAR_ASSET = "file")
load("images/sign_ka_x_u.png", SIGN_KA_X_U_ASSET = "file")
load("images/sign_ka_x_ud.png", SIGN_KA_X_UD_ASSET = "file")
load("images/sign_kab.png", SIGN_KAB_ASSET = "file")
load("images/sign_kad3.png", SIGN_KAD3_ASSET = "file")
load("images/sign_kad4.png", SIGN_KAD4_ASSET = "file")
load("images/sign_kad5.png", SIGN_KAD5_ASSET = "file")
load("images/sign_kak.png", SIGN_KAK_ASSET = "file")
load("images/sign_kal.png", SIGN_KAL_ASSET = "file")
load("images/sign_kal_x_bad.png", SIGN_KAL_X_BAD_ASSET = "file")
load("images/sign_kaskal.png", SIGN_KASKAL_ASSET = "file")
load("images/sign_kaskal_lagab_x_u_lagab_x_u.png", SIGN_KASKAL_LAGAB_X_U_LAGAB_X_U_ASSET = "file")
load("images/sign_ke_2.png", SIGN_KE_2_ASSET = "file")
load("images/sign_ki.png", SIGN_KI_ASSET = "file")
load("images/sign_ki_x_u.png", SIGN_KI_X_U_ASSET = "file")
load("images/sign_kid.png", SIGN_KID_ASSET = "file")
load("images/sign_kin.png", SIGN_KIN_ASSET = "file")
load("images/sign_kisal.png", SIGN_KISAL_ASSET = "file")
load("images/sign_ku.png", SIGN_KU_ASSET = "file")
load("images/sign_ku3.png", SIGN_KU3_ASSET = "file")
load("images/sign_ku4.png", SIGN_KU4_ASSET = "file")
load("images/sign_ku7.png", SIGN_KU7_ASSET = "file")
load("images/sign_ku_u2.png", SIGN_KU_U2_ASSET = "file")
load("images/sign_kul.png", SIGN_KUL_ASSET = "file")
load("images/sign_kun.png", SIGN_KUN_ASSET = "file")
load("images/sign_kur.png", SIGN_KUR_ASSET = "file")
load("images/sign_la.png", SIGN_LA_ASSET = "file")
load("images/sign_lagab.png", SIGN_LAGAB_ASSET = "file")
load("images/sign_lagab_x_a.png", SIGN_LAGAB_X_A_ASSET = "file")
load("images/sign_lagab_x_bad.png", SIGN_LAGAB_X_BAD_ASSET = "file")
load("images/sign_lagab_x_gar.png", SIGN_LAGAB_X_GAR_ASSET = "file")
load("images/sign_lagab_x_gud.png", SIGN_LAGAB_X_GUD_ASSET = "file")
load("images/sign_lagab_x_gud_plus_gud.png", SIGN_LAGAB_X_GUD_PLUS_GUD_ASSET = "file")
load("images/sign_lagab_x_hal.png", SIGN_LAGAB_X_HAL_ASSET = "file")
load("images/sign_lagab_x_igigunu.png", SIGN_LAGAB_X_IGIGUNU_ASSET = "file")
load("images/sign_lagab_x_kul.png", SIGN_LAGAB_X_KUL_ASSET = "file")
load("images/sign_lagab_x_sum.png", SIGN_LAGAB_X_SUM_ASSET = "file")
load("images/sign_lagab_x_u.png", SIGN_LAGAB_X_U_ASSET = "file")
load("images/sign_lagab_x_u_plus_a.png", SIGN_LAGAB_X_U_PLUS_A_ASSET = "file")
load("images/sign_lagab_x_u_plus_u_plus_u.png", SIGN_LAGAB_X_U_PLUS_U_PLUS_U_ASSET = "file")
load("images/sign_lagar.png", SIGN_LAGAR_ASSET = "file")
load("images/sign_lagar_x_e.png", SIGN_LAGAR_X_E_ASSET = "file")
load("images/sign_lagargunu.png", SIGN_LAGARGUNU_ASSET = "file")
load("images/sign_lagargunu_lagargunu_e.png", SIGN_LAGARGUNU_LAGARGUNU_E_ASSET = "file")
load("images/sign_lal.png", SIGN_LAL_ASSET = "file")
load("images/sign_lal_x_lal.png", SIGN_LAL_X_LAL_ASSET = "file")
load("images/sign_lam.png", SIGN_LAM_ASSET = "file")
load("images/sign_li.png", SIGN_LI_ASSET = "file")
load("images/sign_lil.png", SIGN_LIL_ASSET = "file")
load("images/sign_limmu2.png", SIGN_LIMMU2_ASSET = "file")
load("images/sign_lu.png", SIGN_LU_ASSET = "file")
load("images/sign_lu2.png", SIGN_LU2_ASSET = "file")
load("images/sign_lu2_e_ig.png", SIGN_LU2_E_IG_ASSET = "file")
load("images/sign_lu2_inverted_lu2.png", SIGN_LU2_INVERTED_LU2_ASSET = "file")
load("images/sign_lu2_x_bad.png", SIGN_LU2_X_BAD_ASSET = "file")
load("images/sign_lu2_x_gan2tenu.png", SIGN_LU2_X_GAN2TENU_ASSET = "file")
load("images/sign_lu2_x_ne.png", SIGN_LU2_X_NE_ASSET = "file")
load("images/sign_lu3.png", SIGN_LU3_ASSET = "file")
load("images/sign_lu_x_bad.png", SIGN_LU_X_BAD_ASSET = "file")
load("images/sign_lugal.png", SIGN_LUGAL_ASSET = "file")
load("images/sign_lugal_e_ig.png", SIGN_LUGAL_E_IG_ASSET = "file")
load("images/sign_luh.png", SIGN_LUH_ASSET = "file")
load("images/sign_lul.png", SIGN_LUL_ASSET = "file")
load("images/sign_lum.png", SIGN_LUM_ASSET = "file")
load("images/sign_ma.png", SIGN_MA_ASSET = "file")
load("images/sign_ma2.png", SIGN_MA2_ASSET = "file")
load("images/sign_ma_2.png", SIGN_MA_2_ASSET = "file")
load("images/sign_magunu.png", SIGN_MAGUNU_ASSET = "file")
load("images/sign_mah.png", SIGN_MAH_ASSET = "file")
load("images/sign_mar.png", SIGN_MAR_ASSET = "file")
load("images/sign_me.png", SIGN_ME_ASSET = "file")
load("images/sign_mes.png", SIGN_MES_ASSET = "file")
load("images/sign_mi.png", SIGN_MI_ASSET = "file")
load("images/sign_min.png", SIGN_MIN_ASSET = "file")
load("images/sign_mu.png", SIGN_MU_ASSET = "file")
load("images/sign_mu_3.png", SIGN_MU_3_ASSET = "file")
load("images/sign_mu_3_x_a.png", SIGN_MU_3_X_A_ASSET = "file")
load("images/sign_mu_3_x_a_plus_di.png", SIGN_MU_3_X_A_PLUS_DI_ASSET = "file")
load("images/sign_mu_3gunu.png", SIGN_MU_3GUNU_ASSET = "file")
load("images/sign_mu_mu.png", SIGN_MU_MU_ASSET = "file")
load("images/sign_mu_mu_x_a_plus_na.png", SIGN_MU_MU_X_A_PLUS_NA_ASSET = "file")
load("images/sign_mug.png", SIGN_MUG_ASSET = "file")
load("images/sign_munsub.png", SIGN_MUNSUB_ASSET = "file")
load("images/sign_murgu2.png", SIGN_MURGU2_ASSET = "file")
load("images/sign_na.png", SIGN_NA_ASSET = "file")
load("images/sign_na2.png", SIGN_NA2_ASSET = "file")
load("images/sign_naga.png", SIGN_NAGA_ASSET = "file")
load("images/sign_naga_inverted.png", SIGN_NAGA_INVERTED_ASSET = "file")
load("images/sign_nagar.png", SIGN_NAGAR_ASSET = "file")
load("images/sign_nam.png", SIGN_NAM_ASSET = "file")
load("images/sign_ne.png", SIGN_NE_ASSET = "file")
load("images/sign_ne_e_ig.png", SIGN_NE_E_IG_ASSET = "file")
load("images/sign_ni.png", SIGN_NI_ASSET = "file")
load("images/sign_nim.png", SIGN_NIM_ASSET = "file")
load("images/sign_nim_x_gan2tenu.png", SIGN_NIM_X_GAN2TENU_ASSET = "file")
load("images/sign_ninda2.png", SIGN_NINDA2_ASSET = "file")
load("images/sign_ninda2_x_e.png", SIGN_NINDA2_X_E_ASSET = "file")
load("images/sign_ninda2_x_gud.png", SIGN_NINDA2_X_GUD_ASSET = "file")
load("images/sign_ninda2_x_ne.png", SIGN_NINDA2_X_NE_ASSET = "file")
load("images/sign_nisag.png", SIGN_NISAG_ASSET = "file")
load("images/sign_nu.png", SIGN_NU_ASSET = "file")
load("images/sign_nu11.png", SIGN_NU11_ASSET = "file")
load("images/sign_nun.png", SIGN_NUN_ASSET = "file")
load("images/sign_nun_lagar_x_ma.png", SIGN_NUN_LAGAR_X_MA_ASSET = "file")
load("images/sign_nun_lagar_x_sal.png", SIGN_NUN_LAGAR_X_SAL_ASSET = "file")
load("images/sign_nun_nun.png", SIGN_NUN_NUN_ASSET = "file")
load("images/sign_nuntenu.png", SIGN_NUNTENU_ASSET = "file")
load("images/sign_nunuz.png", SIGN_NUNUZ_ASSET = "file")
load("images/sign_nunuz_ab2_x_a_gab.png", SIGN_NUNUZ_AB2_X_A_GAB_ASSET = "file")
load("images/sign_nunuz_ab2_x_la.png", SIGN_NUNUZ_AB2_X_LA_ASSET = "file")
load("images/sign_one_buru.png", SIGN_ONE_BURU_ASSET = "file")
load("images/sign_one_e_e3.png", SIGN_ONE_E_E3_ASSET = "file")
load("images/sign_pa.png", SIGN_PA_ASSET = "file")
load("images/sign_pad.png", SIGN_PAD_ASSET = "file")
load("images/sign_pan.png", SIGN_PAN_ASSET = "file")
load("images/sign_pap.png", SIGN_PAP_ASSET = "file")
load("images/sign_pe_2.png", SIGN_PE_2_ASSET = "file")
load("images/sign_pi.png", SIGN_PI_ASSET = "file")
load("images/sign_pirig.png", SIGN_PIRIG_ASSET = "file")
load("images/sign_pirig_inverted_pirig.png", SIGN_PIRIG_INVERTED_PIRIG_ASSET = "file")
load("images/sign_pirig_x_ud.png", SIGN_PIRIG_X_UD_ASSET = "file")
load("images/sign_pirig_x_za.png", SIGN_PIRIG_X_ZA_ASSET = "file")
load("images/sign_ra.png", SIGN_RA_ASSET = "file")
load("images/sign_ri.png", SIGN_RI_ASSET = "file")
load("images/sign_ru.png", SIGN_RU_ASSET = "file")
load("images/sign_sa.png", SIGN_SA_ASSET = "file")
load("images/sign_sag.png", SIGN_SAG_ASSET = "file")
load("images/sign_sag_x_id.png", SIGN_SAG_X_ID_ASSET = "file")
load("images/sign_sag_x_u2.png", SIGN_SAG_X_U2_ASSET = "file")
load("images/sign_saggunu.png", SIGN_SAGGUNU_ASSET = "file")
load("images/sign_sal.png", SIGN_SAL_ASSET = "file")
load("images/sign_sar.png", SIGN_SAR_ASSET = "file")
load("images/sign_si.png", SIGN_SI_ASSET = "file")
load("images/sign_sig.png", SIGN_SIG_ASSET = "file")
load("images/sign_sig4.png", SIGN_SIG4_ASSET = "file")
load("images/sign_sigunu.png", SIGN_SIGUNU_ASSET = "file")
load("images/sign_sik2.png", SIGN_SIK2_ASSET = "file")
load("images/sign_sila3.png", SIGN_SILA3_ASSET = "file")
load("images/sign_su.png", SIGN_SU_ASSET = "file")
load("images/sign_sud.png", SIGN_SUD_ASSET = "file")
load("images/sign_sud2.png", SIGN_SUD2_ASSET = "file")
load("images/sign_suhur.png", SIGN_SUHUR_ASSET = "file")
load("images/sign_sum.png", SIGN_SUM_ASSET = "file")
load("images/sign_sur.png", SIGN_SUR_ASSET = "file")
load("images/sign_ta.png", SIGN_TA_ASSET = "file")
load("images/sign_ta_x_hi.png", SIGN_TA_X_HI_ASSET = "file")
load("images/sign_tab.png", SIGN_TAB_ASSET = "file")
load("images/sign_tag.png", SIGN_TAG_ASSET = "file")
load("images/sign_tag_x_tug2.png", SIGN_TAG_X_TUG2_ASSET = "file")
load("images/sign_tag_x_u.png", SIGN_TAG_X_U_ASSET = "file")
load("images/sign_tak4.png", SIGN_TAK4_ASSET = "file")
load("images/sign_tar.png", SIGN_TAR_ASSET = "file")
load("images/sign_te.png", SIGN_TE_ASSET = "file")
load("images/sign_tegunu.png", SIGN_TEGUNU_ASSET = "file")
load("images/sign_three_di.png", SIGN_THREE_DI_ASSET = "file")
load("images/sign_ti.png", SIGN_TI_ASSET = "file")
load("images/sign_til.png", SIGN_TIL_ASSET = "file")
load("images/sign_tir.png", SIGN_TIR_ASSET = "file")
load("images/sign_tu.png", SIGN_TU_ASSET = "file")
load("images/sign_tug2.png", SIGN_TUG2_ASSET = "file")
load("images/sign_tuk.png", SIGN_TUK_ASSET = "file")
load("images/sign_tum.png", SIGN_TUM_ASSET = "file")
load("images/sign_tur.png", SIGN_TUR_ASSET = "file")
load("images/sign_two_a.png", SIGN_TWO_A_ASSET = "file")
load("images/sign_two_e_e3.png", SIGN_TWO_E_E3_ASSET = "file")
load("images/sign_u.png", SIGN_U_ASSET = "file")
load("images/sign_u2.png", SIGN_U2_ASSET = "file")
load("images/sign_u_gud.png", SIGN_U_GUD_ASSET = "file")
load("images/sign_u_u_pa_pa_gar_gar.png", SIGN_U_U_PA_PA_GAR_GAR_ASSET = "file")
load("images/sign_u_u_sur_sur.png", SIGN_U_U_SUR_SUR_ASSET = "file")
load("images/sign_u_u_u.png", SIGN_U_U_U_ASSET = "file")
load("images/sign_u_x_a.png", SIGN_U_X_A_ASSET = "file")
load("images/sign_u_x_tak4.png", SIGN_U_X_TAK4_ASSET = "file")
load("images/sign_ub.png", SIGN_UB_ASSET = "file")
load("images/sign_ubur.png", SIGN_UBUR_ASSET = "file")
load("images/sign_ud.png", SIGN_UD_ASSET = "file")
load("images/sign_ud_ku_u2.png", SIGN_UD_KU_U2_ASSET = "file")
load("images/sign_ud_x_u_plus_u_plus_u.png", SIGN_UD_X_U_PLUS_U_PLUS_U_ASSET = "file")
load("images/sign_ud_x_u_plus_u_plus_ugunu.png", SIGN_UD_X_U_PLUS_U_PLUS_UGUNU_ASSET = "file")
load("images/sign_udug.png", SIGN_UDUG_ASSET = "file")
load("images/sign_um.png", SIGN_UM_ASSET = "file")
load("images/sign_umum.png", SIGN_UMUM_ASSET = "file")
load("images/sign_umum_x_kaskal.png", SIGN_UMUM_X_KASKAL_ASSET = "file")
load("images/sign_un.png", SIGN_UN_ASSET = "file")
load("images/sign_ur.png", SIGN_UR_ASSET = "file")
load("images/sign_ur2.png", SIGN_UR2_ASSET = "file")
load("images/sign_ur2_x_nun.png", SIGN_UR2_X_NUN_ASSET = "file")
load("images/sign_ur2_x_u2.png", SIGN_UR2_X_U2_ASSET = "file")
load("images/sign_ur2_x_u2_plus_a.png", SIGN_UR2_X_U2_PLUS_A_ASSET = "file")
load("images/sign_ur4.png", SIGN_UR4_ASSET = "file")
load("images/sign_ur_e_ig.png", SIGN_UR_E_IG_ASSET = "file")
load("images/sign_uri.png", SIGN_URI_ASSET = "file")
load("images/sign_uri3.png", SIGN_URI3_ASSET = "file")
load("images/sign_uru.png", SIGN_URU_ASSET = "file")
load("images/sign_uru_x_a.png", SIGN_URU_X_A_ASSET = "file")
load("images/sign_uru_x_bar.png", SIGN_URU_X_BAR_ASSET = "file")
load("images/sign_uru_x_ga.png", SIGN_URU_X_GA_ASSET = "file")
load("images/sign_uru_x_gar.png", SIGN_URU_X_GAR_ASSET = "file")
load("images/sign_uru_x_gu.png", SIGN_URU_X_GU_ASSET = "file")
load("images/sign_uru_x_igi.png", SIGN_URU_X_IGI_ASSET = "file")
load("images/sign_uru_x_min.png", SIGN_URU_X_MIN_ASSET = "file")
load("images/sign_uru_x_tu.png", SIGN_URU_X_TU_ASSET = "file")
load("images/sign_uru_x_ud.png", SIGN_URU_X_UD_ASSET = "file")
load("images/sign_uru_x_uruda.png", SIGN_URU_X_URUDA_ASSET = "file")
load("images/sign_uruda.png", SIGN_URUDA_ASSET = "file")
load("images/sign_uz3.png", SIGN_UZ3_ASSET = "file")
load("images/sign_uzu.png", SIGN_UZU_ASSET = "file")
load("images/sign_za.png", SIGN_ZA_ASSET = "file")
load("images/sign_zadim.png", SIGN_ZADIM_ASSET = "file")
load("images/sign_zag.png", SIGN_ZAG_ASSET = "file")
load("images/sign_zatenu.png", SIGN_ZATENU_ASSET = "file")
load("images/sign_ze2.png", SIGN_ZE2_ASSET = "file")
load("images/sign_zi.png", SIGN_ZI_ASSET = "file")
load("images/sign_zi3.png", SIGN_ZI3_ASSET = "file")
load("images/sign_zi_zi.png", SIGN_ZI_ZI_ASSET = "file")
load("images/sign_zig.png", SIGN_ZIG_ASSET = "file")
load("images/sign_zu.png", SIGN_ZU_ASSET = "file")
load("images/sign_zum.png", SIGN_ZUM_ASSET = "file")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")

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

    img = render.Image(sign["src"])
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
        "src": SIGN_A_ASSET.readall(),
    },
    {
        "name": r"A×HA",
        "sumerian_transliterations": [r"saḫ7"],
        "src": SIGN_A_X_HA_ASSET.readall(),
    },
    {
        "name": r"A2",
        "sumerian_transliterations": [r"a2", r"ed", r"et", r"id", r"it", r"iṭ", r"te8"],
        "src": SIGN_A2_ASSET.readall(),
    },
    {
        "name": r"AB",
        "sumerian_transliterations": [r"ab", r"aba", r"ap", r"eš3", r"iri12", r"is3"],
        "src": SIGN_AB_ASSET.readall(),
    },
    {
        "name": r"ABgunu",
        "sumerian_transliterations": [r"ab4", r"aba4", r"gun4", r"iri11", r"unu", r"unug"],
        "src": SIGN_ABGUNU_ASSET.readall(),
    },
    {
        "name": r"AB×GAL",
        "sumerian_transliterations": [r"irigal"],
        "src": SIGN_AB_X_GAL_ASSET.readall(),
    },
    {
        "name": r"AB×HA",
        "sumerian_transliterations": [r"agarinx", r"nanše", r"niĝin6", r"sirara"],
        "src": SIGN_AB_X_HA_ASSET.readall(),
    },
    {
        "name": r"AB2",
        "sumerian_transliterations": [r"ab2"],
        "src": SIGN_AB2_ASSET.readall(),
    },
    {
        "name": r"AB2×GAN2tenu",
        "sumerian_transliterations": [r"šem5"],
        "src": SIGN_AB2_X_GAN2TENU_ASSET.readall(),
    },
    {
        "name": r"AB2×ŠA3",
        "sumerian_transliterations": [r"lipiš", r"ub3", r"šem3"],
        "src": SIGN_AB2_X_A3_ASSET.readall(),
    },
    {
        "name": r"AD",
        "sumerian_transliterations": [r"ad", r"at"],
        "src": SIGN_AD_ASSET.readall(),
    },
    {
        "name": r"AK",
        "sumerian_transliterations": [r"ag", r"ak", r"ša5"],
        "src": SIGN_AK_ASSET.readall(),
    },
    {
        "name": r"AK×ERIN2",
        "sumerian_transliterations": [r"me3"],
        "src": SIGN_AK_X_ERIN2_ASSET.readall(),
    },
    {
        "name": r"AL",
        "sumerian_transliterations": [r"al"],
        "src": SIGN_AL_ASSET.readall(),
    },
    {
        "name": r"ALAN",
        "sumerian_transliterations": [r"alan"],
        "src": SIGN_ALAN_ASSET.readall(),
    },
    {
        "name": r"AMAR",
        "sumerian_transliterations": [r"amar", r"mar2", r"zur"],
        "src": SIGN_AMAR_ASSET.readall(),
    },
    {
        "name": r"AMAR×ŠE",
        "sumerian_transliterations": [r"sizkur"],
        "src": SIGN_AMAR_X_E_ASSET.readall(),
    },
    {
        "name": r"AN",
        "sumerian_transliterations": [r"am6", r"an", r"diĝir", r"il3", r"naggax"],
        "src": SIGN_AN_ASSET.readall(),
    },
    {
        "name": r"AN.AŠ.AN",
        "sumerian_transliterations": [r"tilla2"],
        "src": SIGN_AN_A_AN_ASSET.readall(),
    },
    {
        "name": r"AN/AN",
        "sumerian_transliterations": [r"part of compound"],
        "src": SIGN_AN_AN_ASSET.readall(),
    },
    {
        "name": r"AN+NAGA(inverted)AN+NAGA",
        "sumerian_transliterations": [r"dalḫamun5"],
        "src": SIGN_AN_PLUS_NAGA_INVERTED_AN_PLUS_NAGA_ASSET.readall(),
    },
    {
        "name": r"ANŠE",
        "sumerian_transliterations": [r"anše"],
        "src": SIGN_AN_E_ASSET.readall(),
    },
    {
        "name": r"APIN",
        "sumerian_transliterations": [r"absin3", r"apin", r"engar", r"ur11", r"uš8"],
        "src": SIGN_APIN_ASSET.readall(),
    },
    {
        "name": r"ARAD",
        "sumerian_transliterations": [r"arad", r"er3", r"nitaḫ2"],
        "src": SIGN_ARAD_ASSET.readall(),
    },
    {
        "name": r"ARAD×KUR",
        "sumerian_transliterations": [r"arad2"],
        "src": SIGN_ARAD_X_KUR_ASSET.readall(),
    },
    {
        "name": r"AŠ",
        "sumerian_transliterations": [r"aš", r"dil", r"dili", r"rum", r"til4"],
        "src": SIGN_A_ASSET.readall(),
    },
    {
        "name": r"AŠ2",
        "sumerian_transliterations": [r"aš2", r"ziz2"],
        "src": SIGN_A_2_ASSET.readall(),
    },
    {
        "name": r"AŠGAB",
        "sumerian_transliterations": [r"ašgab"],
        "src": SIGN_A_GAB_ASSET.readall(),
    },
    {
        "name": r"BA",
        "sumerian_transliterations": [r"ba", r"be4"],
        "src": SIGN_BA_ASSET.readall(),
    },
    {
        "name": r"BAD",
        "sumerian_transliterations": [r"ba9", r"bad", r"be"],
        "src": SIGN_BAD_ASSET.readall(),
    },
    {
        "name": r"BAHAR2",
        "sumerian_transliterations": [r"baḫar2"],
        "src": SIGN_BAHAR2_ASSET.readall(),
    },
    {
        "name": r"BAL",
        "sumerian_transliterations": [r"bal"],
        "src": SIGN_BAL_ASSET.readall(),
    },
    {
        "name": r"BALAG",
        "sumerian_transliterations": [r"balaĝ", r"buluĝ5"],
        "src": SIGN_BALAG_ASSET.readall(),
    },
    {
        "name": r"BAR",
        "sumerian_transliterations": [r"bar"],
        "src": SIGN_BAR_ASSET.readall(),
    },
    {
        "name": r"BARA2",
        "sumerian_transliterations": [r"barag", r"šara"],
        "src": SIGN_BARA2_ASSET.readall(),
    },
    {
        "name": r"BI",
        "sumerian_transliterations": [r"be2", r"bi", r"biz", r"kaš", r"pe2", r"pi2"],
        "src": SIGN_BI_ASSET.readall(),
    },
    {
        "name": r"BU",
        "sumerian_transliterations": [r"bu", r"bur12", r"dur7", r"gid2", r"kim3", r"pu", r"sir2", r"su13", r"sud4", r"tur8"],
        "src": SIGN_BU_ASSET.readall(),
    },
    {
        "name": r"BU/BU.AB",
        "sumerian_transliterations": [r"sirsir"],
        "src": SIGN_BU_BU_AB_ASSET.readall(),
    },
    {
        "name": r"BULUG",
        "sumerian_transliterations": [r"bulug"],
        "src": SIGN_BULUG_ASSET.readall(),
    },
    {
        "name": r"BUR",
        "sumerian_transliterations": [r"bur"],
        "src": SIGN_BUR_ASSET.readall(),
    },
    {
        "name": r"BUR2",
        "sumerian_transliterations": [r"bu8", r"bur2", r"du9", r"dun5", r"sun5", r"ušum"],
        "src": SIGN_BUR2_ASSET.readall(),
    },
    {
        "name": r"DA",
        "sumerian_transliterations": [r"da", r"ta2"],
        "src": SIGN_DA_ASSET.readall(),
    },
    {
        "name": r"DAG",
        "sumerian_transliterations": [r"barag2", r"dag", r"par3", r"para3", r"tag2"],
        "src": SIGN_DAG_ASSET.readall(),
    },
    {
        "name": r"DAG.KISIM5×GA",
        "sumerian_transliterations": [r"akan", r"ubur"],
        "src": SIGN_DAG_KISIM5_X_GA_ASSET.readall(),
    },
    {
        "name": r"DAG.KISIM5×GIR2",
        "sumerian_transliterations": [r"kiši8"],
        "src": SIGN_DAG_KISIM5_X_GIR2_ASSET.readall(),
    },
    {
        "name": r"DAG.KISIM5×LU",
        "sumerian_transliterations": [r"ubur2"],
        "src": SIGN_DAG_KISIM5_X_LU_ASSET.readall(),
    },
    {
        "name": r"DAG.KISIM5×LU+MAŠ2",
        "sumerian_transliterations": [r"amaš", r"utua2"],
        "src": SIGN_DAG_KISIM5_X_LU_PLUS_MA_2_ASSET.readall(),
    },
    {
        "name": r"DAG.KISIM5×SI",
        "sumerian_transliterations": [r"kisim2"],
        "src": SIGN_DAG_KISIM5_X_SI_ASSET.readall(),
    },
    {
        "name": r"DAG.KISIM5×U2+GIR2",
        "sumerian_transliterations": [r"kisim", r"ḫarub"],
        "src": SIGN_DAG_KISIM5_X_U2_PLUS_GIR2_ASSET.readall(),
    },
    {
        "name": r"DAM",
        "sumerian_transliterations": [r"dam"],
        "src": SIGN_DAM_ASSET.readall(),
    },
    {
        "name": r"DAR",
        "sumerian_transliterations": [r"dar", r"gun3", r"tar2"],
        "src": SIGN_DAR_ASSET.readall(),
    },
    {
        "name": r"DARA3",
        "sumerian_transliterations": [r"dar3", r"dara3", r"taraḫ"],
        "src": SIGN_DARA3_ASSET.readall(),
    },
    {
        "name": r"DARA4",
        "sumerian_transliterations": [r"dara4"],
        "src": SIGN_DARA4_ASSET.readall(),
    },
    {
        "name": r"DI",
        "sumerian_transliterations": [r"de", r"di", r"sa2", r"silim"],
        "src": SIGN_DI_ASSET.readall(),
    },
    {
        "name": r"DIB",
        "sumerian_transliterations": [r"dab", r"dib"],
        "src": SIGN_DIB_ASSET.readall(),
    },
    {
        "name": r"DIM",
        "sumerian_transliterations": [r"dim"],
        "src": SIGN_DIM_ASSET.readall(),
    },
    {
        "name": r"DIM×ŠE",
        "sumerian_transliterations": [r"mun"],
        "src": SIGN_DIM_X_E_ASSET.readall(),
    },
    {
        "name": r"DIM2",
        "sumerian_transliterations": [r"dim2", r"ge18", r"gen7", r"gim", r"gin7", r"šidim"],
        "src": SIGN_DIM2_ASSET.readall(),
    },
    {
        "name": r"DIN",
        "sumerian_transliterations": [r"din", r"kurun2", r"tin"],
        "src": SIGN_DIN_ASSET.readall(),
    },
    {
        "name": r"DIŠ",
        "sumerian_transliterations": [r"diš", r"eš4"],
        "src": SIGN_DI_ASSET.readall(),
    },
    {
        "name": r"DU",
        "sumerian_transliterations": [r"de6", r"du", r"gub", r"im4", r"kub", r"kurx", r"kux", r"laḫ6", r"ra2", r"re6", r"tu3", r"tum2", r"ĝen", r"ša4"],
        "src": SIGN_DU_ASSET.readall(),
    },
    {
        "name": r"DUgunu",
        "sumerian_transliterations": [r"suḫuš"],
        "src": SIGN_DUGUNU_ASSET.readall(),
    },
    {
        "name": r"DU/DU",
        "sumerian_transliterations": [r"laḫ4", r"re7", r"su8", r"sub2", r"sug2"],
        "src": SIGN_DU_DU_ASSET.readall(),
    },
    {
        "name": r"DUšešig",
        "sumerian_transliterations": [r"gir5", r"im2", r"kaš4", r"rim4"],
        "src": SIGN_DU_E_IG_ASSET.readall(),
    },
    {
        "name": r"DUB",
        "sumerian_transliterations": [r"dab4", r"dub", r"kišib3", r"zamug"],
        "src": SIGN_DUB_ASSET.readall(),
    },
    {
        "name": r"DUB2",
        "sumerian_transliterations": [r"dub2"],
        "src": SIGN_DUB2_ASSET.readall(),
    },
    {
        "name": r"DUG",
        "sumerian_transliterations": [r"dug", r"epir", r"gurun7", r"kurin", r"kurun3"],
        "src": SIGN_DUG_ASSET.readall(),
    },
    {
        "name": r"DUGUD",
        "sumerian_transliterations": [r"dugud", r"ĝi25"],
        "src": SIGN_DUGUD_ASSET.readall(),
    },
    {
        "name": r"DUN",
        "sumerian_transliterations": [r"dun", r"dur9", r"sul", r"zu7", r"šaḫ2", r"šul"],
        "src": SIGN_DUN_ASSET.readall(),
    },
    {
        "name": r"DUN3",
        "sumerian_transliterations": [r"du5", r"tun3"],
        "src": SIGN_DUN3_ASSET.readall(),
    },
    {
        "name": r"DUN3gunu",
        "sumerian_transliterations": [r"aga3", r"giĝ4"],
        "src": SIGN_DUN3GUNU_ASSET.readall(),
    },
    {
        "name": r"DUN3gunugunu",
        "sumerian_transliterations": [r"aga", r"mir", r"niĝir"],
        "src": SIGN_DUN3GUNUGUNU_ASSET.readall(),
    },
    {
        "name": r"DUN3gunugunušešig",
        "sumerian_transliterations": [r"dul4", r"šudul4"],
        "src": SIGN_DUN3GUNUGUNU_E_IG_ASSET.readall(),
    },
    {
        "name": r"E",
        "sumerian_transliterations": [r"e", r"eg2"],
        "src": SIGN_E_ASSET.readall(),
    },
    {
        "name": r"E2",
        "sumerian_transliterations": [r"e2"],
        "src": SIGN_E2_ASSET.readall(),
    },
    {
        "name": r"EDIN",
        "sumerian_transliterations": [r"bir4", r"edimx", r"edin", r"ru6"],
        "src": SIGN_EDIN_ASSET.readall(),
    },
    {
        "name": r"EGIR",
        "sumerian_transliterations": [r"eĝer"],
        "src": SIGN_EGIR_ASSET.readall(),
    },
    {
        "name": r"EL",
        "sumerian_transliterations": [r"el", r"il5", r"sikil"],
        "src": SIGN_EL_ASSET.readall(),
    },
    {
        "name": r"EN",
        "sumerian_transliterations": [r"en", r"in4", r"ru12", r"uru16"],
        "src": SIGN_EN_ASSET.readall(),
    },
    {
        "name": r"EN×GAN2tenu",
        "sumerian_transliterations": [r"buru14", r"enkar", r"ešgiri2"],
        "src": SIGN_EN_X_GAN2TENU_ASSET.readall(),
    },
    {
        "name": r"EREN",
        "sumerian_transliterations": [r"erin", r"še22", r"šeš4"],
        "src": SIGN_EREN_ASSET.readall(),
    },
    {
        "name": r"ERIN2",
        "sumerian_transliterations": [r"erim", r"erin2", r"pir2", r"rin2", r"zalag2"],
        "src": SIGN_ERIN2_ASSET.readall(),
    },
    {
        "name": r"EŠ2",
        "sumerian_transliterations": [r"egir2", r"eš2", r"eše2", r"gir15", r"sumunx", r"ub2", r"še3", r"ḫuĝ"],
        "src": SIGN_E_2_ASSET.readall(),
    },
    {
        "name": r"EZEN",
        "sumerian_transliterations": [r"asilx", r"ezem", r"ezen", r"gublagax", r"šer3", r"šir3"],
        "src": SIGN_EZEN_ASSET.readall(),
    },
    {
        "name": r"EZEN×A",
        "sumerian_transliterations": [r"asil3", r"asila3"],
        "src": SIGN_EZEN_X_A_ASSET.readall(),
    },
    {
        "name": r"EZEN×BAD",
        "sumerian_transliterations": [r"bad3", r"u9", r"ug5", r"un3"],
        "src": SIGN_EZEN_X_BAD_ASSET.readall(),
    },
    {
        "name": r"EZEN×KASKAL",
        "sumerian_transliterations": [r"ubara", r"un4"],
        "src": SIGN_EZEN_X_KASKAL_ASSET.readall(),
    },
    {
        "name": r"EZEN×KU3",
        "sumerian_transliterations": [r"kisiga"],
        "src": SIGN_EZEN_X_KU3_ASSET.readall(),
    },
    {
        "name": r"EZEN×LA",
        "sumerian_transliterations": [r"gublaga"],
        "src": SIGN_EZEN_X_LA_ASSET.readall(),
    },
    {
        "name": r"EZEN×LAL×LAL",
        "sumerian_transliterations": [r"asil", r"asila"],
        "src": SIGN_EZEN_X_LAL_X_LAL_ASSET.readall(),
    },
    {
        "name": r"GA",
        "sumerian_transliterations": [r"ga", r"gur11", r"ka3", r"qa2"],
        "src": SIGN_GA_ASSET.readall(),
    },
    {
        "name": r"GA2",
        "sumerian_transliterations": [r"ba4", r"ma3", r"pisaĝ", r"ĝa2", r"ĝe26"],
        "src": SIGN_GA2_ASSET.readall(),
    },
    {
        "name": r"GA2×AN",
        "sumerian_transliterations": [r"ama", r"daĝal"],
        "src": SIGN_GA2_X_AN_ASSET.readall(),
    },
    {
        "name": r"GA2×GAN2tenu",
        "sumerian_transliterations": [r"dan4"],
        "src": SIGN_GA2_X_GAN2TENU_ASSET.readall(),
    },
    {
        "name": r"GA2×GAR",
        "sumerian_transliterations": [r"ĝalga"],
        "src": SIGN_GA2_X_GAR_ASSET.readall(),
    },
    {
        "name": r"GA2×ME+EN",
        "sumerian_transliterations": [r"dan2", r"men"],
        "src": SIGN_GA2_X_ME_PLUS_EN_ASSET.readall(),
    },
    {
        "name": r"GA2×MI",
        "sumerian_transliterations": [r"itima"],
        "src": SIGN_GA2_X_MI_ASSET.readall(),
    },
    {
        "name": r"GA2×NUN",
        "sumerian_transliterations": [r"ĝanun"],
        "src": SIGN_GA2_X_NUN_ASSET.readall(),
    },
    {
        "name": r"GA2×NUN/NUN",
        "sumerian_transliterations": [r"ur3"],
        "src": SIGN_GA2_X_NUN_NUN_ASSET.readall(),
    },
    {
        "name": r"GA2×PA",
        "sumerian_transliterations": [r"gazi", r"sila4"],
        "src": SIGN_GA2_X_PA_ASSET.readall(),
    },
    {
        "name": r"GA2×SAL",
        "sumerian_transliterations": [r"ama5", r"arḫuš"],
        "src": SIGN_GA2_X_SAL_ASSET.readall(),
    },
    {
        "name": r"GA2×ŠE",
        "sumerian_transliterations": [r"esaĝ2"],
        "src": SIGN_GA2_X_E_ASSET.readall(),
    },
    {
        "name": r"GA2×TAK4",
        "sumerian_transliterations": [r"dan3"],
        "src": SIGN_GA2_X_TAK4_ASSET.readall(),
    },
    {
        "name": r"GABA",
        "sumerian_transliterations": [r"du8", r"duḫ", r"gab", r"gaba"],
        "src": SIGN_GABA_ASSET.readall(),
    },
    {
        "name": r"GAD",
        "sumerian_transliterations": [r"gada"],
        "src": SIGN_GAD_ASSET.readall(),
    },
    {
        "name": r"GAD/GAD.GAR/GAR",
        "sumerian_transliterations": [r"garadinx", r"kinda"],
        "src": SIGN_GAD_GAD_GAR_GAR_ASSET.readall(),
    },
    {
        "name": r"GAL",
        "sumerian_transliterations": [r"gal", r"kal2"],
        "src": SIGN_GAL_ASSET.readall(),
    },
    {
        "name": r"GAL.GAD/GAD.GAR/GAR",
        "sumerian_transliterations": [r"kindagal"],
        "src": SIGN_GAL_GAD_GAD_GAR_GAR_ASSET.readall(),
    },
    {
        "name": r"GALAM",
        "sumerian_transliterations": [r"galam", r"sukud", r"sukux"],
        "src": SIGN_GALAM_ASSET.readall(),
    },
    {
        "name": r"GAM",
        "sumerian_transliterations": [r"gam", r"gur2", r"gurum"],
        "src": SIGN_GAM_ASSET.readall(),
    },
    {
        "name": r"GAN",
        "sumerian_transliterations": [r"gam4", r"gan", r"gana", r"kan", r"ḫe2"],
        "src": SIGN_GAN_ASSET.readall(),
    },
    {
        "name": r"GAN2",
        "sumerian_transliterations": [r"ga3", r"gan2", r"gana2", r"iku", r"kan2"],
        "src": SIGN_GAN2_ASSET.readall(),
    },
    {
        "name": r"GAN2%GAN2",
        "sumerian_transliterations": [r"ulul2"],
        "src": SIGN_GAN2_GAN2_ASSET.readall(),
    },
    {
        "name": r"GAN2tenu",
        "sumerian_transliterations": [r"guru6", r"kar2"],
        "src": SIGN_GAN2TENU_ASSET.readall(),
    },
    {
        "name": r"GAR",
        "sumerian_transliterations": [r"ni3", r"ninda", r"nindan", r"niĝ2", r"ĝar", r"ša2"],
        "src": SIGN_GAR_ASSET.readall(),
    },
    {
        "name": r"GAR3",
        "sumerian_transliterations": [r"gar3", r"gara3", r"qar"],
        "src": SIGN_GAR3_ASSET.readall(),
    },
    {
        "name": r"GAgunu",
        "sumerian_transliterations": [r"gara2"],
        "src": SIGN_GAGUNU_ASSET.readall(),
    },
    {
        "name": r"GEŠTIN",
        "sumerian_transliterations": [r"ĝeštin"],
        "src": SIGN_GE_TIN_ASSET.readall(),
    },
    {
        "name": r"GI",
        "sumerian_transliterations": [r"ge", r"gen6", r"gi", r"ke2", r"ki2", r"sig17"],
        "src": SIGN_GI_ASSET.readall(),
    },
    {
        "name": r"GI4",
        "sumerian_transliterations": [r"ge4", r"gi4", r"qi4"],
        "src": SIGN_GI4_ASSET.readall(),
    },
    {
        "name": r"GIDIM",
        "sumerian_transliterations": [r"gidim"],
        "src": SIGN_GIDIM_ASSET.readall(),
    },
    {
        "name": r"GIG",
        "sumerian_transliterations": [r"gi17", r"gig", r"simx"],
        "src": SIGN_GIG_ASSET.readall(),
    },
    {
        "name": r"GIR2",
        "sumerian_transliterations": [r"ĝir2", r"ĝiri2"],
        "src": SIGN_GIR2_ASSET.readall(),
    },
    {
        "name": r"GIR2gunu",
        "sumerian_transliterations": [r"kiši17", r"tab2", r"ul4"],
        "src": SIGN_GIR2GUNU_ASSET.readall(),
    },
    {
        "name": r"GIR3",
        "sumerian_transliterations": [r"er9", r"gir3", r"ĝir3", r"ĝiri3", r"šakkan2"],
        "src": SIGN_GIR3_ASSET.readall(),
    },
    {
        "name": r"GIR3×A+IGI",
        "sumerian_transliterations": [r"alim"],
        "src": SIGN_GIR3_X_A_PLUS_IGI_ASSET.readall(),
    },
    {
        "name": r"GIR3×GAN2tenu",
        "sumerian_transliterations": [r"gir16", r"giri16", r"girid2"],
        "src": SIGN_GIR3_X_GAN2TENU_ASSET.readall(),
    },
    {
        "name": r"GIR3×LU+IGI",
        "sumerian_transliterations": [r"lulim"],
        "src": SIGN_GIR3_X_LU_PLUS_IGI_ASSET.readall(),
    },
    {
        "name": r"GISAL",
        "sumerian_transliterations": [r"ĝisal"],
        "src": SIGN_GISAL_ASSET.readall(),
    },
    {
        "name": r"GIŠ",
        "sumerian_transliterations": [r"is", r"iz", r"iš6", r"ĝiš"],
        "src": SIGN_GI_ASSET.readall(),
    },
    {
        "name": r"GIŠ%GIŠ",
        "sumerian_transliterations": [r"lirum3", r"ul3", r"šennur", r"ḫul3"],
        "src": SIGN_GI_GI_ASSET.readall(),
    },
    {
        "name": r"GI%GI",
        "sumerian_transliterations": [r"gel", r"gi16", r"gib", r"gil", r"gilim"],
        "src": SIGN_GI_GI_ASSET.readall(),
    },
    {
        "name": r"GU",
        "sumerian_transliterations": [r"gu"],
        "src": SIGN_GU_ASSET.readall(),
    },
    {
        "name": r"GU%GU",
        "sumerian_transliterations": [r"saḫ4", r"suḫ3"],
        "src": SIGN_GU_GU_ASSET.readall(),
    },
    {
        "name": r"GU2",
        "sumerian_transliterations": [r"gu2", r"gun2"],
        "src": SIGN_GU2_ASSET.readall(),
    },
    {
        "name": r"GU2×KAK",
        "sumerian_transliterations": [r"dur", r"usanx"],
        "src": SIGN_GU2_X_KAK_ASSET.readall(),
    },
    {
        "name": r"GU2×NUN",
        "sumerian_transliterations": [r"sub3", r"usan"],
        "src": SIGN_GU2_X_NUN_ASSET.readall(),
    },
    {
        "name": r"GUD",
        "sumerian_transliterations": [r"eštub", r"gu4", r"gud"],
        "src": SIGN_GUD_ASSET.readall(),
    },
    {
        "name": r"GUD×A+KUR",
        "sumerian_transliterations": [r"ildag2"],
        "src": SIGN_GUD_X_A_PLUS_KUR_ASSET.readall(),
    },
    {
        "name": r"GUD×KUR",
        "sumerian_transliterations": [r"am", r"ildag3"],
        "src": SIGN_GUD_X_KUR_ASSET.readall(),
    },
    {
        "name": r"GUL",
        "sumerian_transliterations": [r"gul", r"isimu2", r"kul2", r"si23", r"sumun2"],
        "src": SIGN_GUL_ASSET.readall(),
    },
    {
        "name": r"GUM",
        "sumerian_transliterations": [r"gum", r"kum", r"naĝa4", r"qum"],
        "src": SIGN_GUM_ASSET.readall(),
    },
    {
        "name": r"GUM×ŠE",
        "sumerian_transliterations": [r"gaz", r"naĝa3"],
        "src": SIGN_GUM_X_E_ASSET.readall(),
    },
    {
        "name": r"GUR",
        "sumerian_transliterations": [r"gur"],
        "src": SIGN_GUR_ASSET.readall(),
    },
    {
        "name": r"GUR7",
        "sumerian_transliterations": [r"guru7"],
        "src": SIGN_GUR7_ASSET.readall(),
    },
    {
        "name": r"GURUN",
        "sumerian_transliterations": [r"gamx", r"gurun"],
        "src": SIGN_GURUN_ASSET.readall(),
    },
    {
        "name": r"HA",
        "sumerian_transliterations": [r"ku6", r"peš11", r"ḫa"],
        "src": SIGN_HA_ASSET.readall(),
    },
    {
        "name": r"HAgunu",
        "sumerian_transliterations": [r"biš", r"gir", r"peš"],
        "src": SIGN_HAGUNU_ASSET.readall(),
    },
    {
        "name": r"HAL",
        "sumerian_transliterations": [r"ḫal"],
        "src": SIGN_HAL_ASSET.readall(),
    },
    {
        "name": r"HI",
        "sumerian_transliterations": [r"da10", r"du10", r"dub3", r"dug3", r"šar2", r"ḫe", r"ḫi"],
        "src": SIGN_HI_ASSET.readall(),
    },
    {
        "name": r"HI×AŠ",
        "sumerian_transliterations": [r"sur3"],
        "src": SIGN_HI_X_A_ASSET.readall(),
    },
    {
        "name": r"HI×AŠ2",
        "sumerian_transliterations": [r"ar3", r"kin2", r"kinkin", r"mar6", r"mur", r"ur5", r"ḫar", r"ḫur"],
        "src": SIGN_HI_X_A_2_ASSET.readall(),
    },
    {
        "name": r"HI×BAD",
        "sumerian_transliterations": [r"kam", r"tu7", r"utul2"],
        "src": SIGN_HI_X_BAD_ASSET.readall(),
    },
    {
        "name": r"HI×NUN",
        "sumerian_transliterations": [r"aḫ", r"a’", r"eḫ", r"iḫ", r"umun3", r"uḫ"],
        "src": SIGN_HI_X_NUN_ASSET.readall(),
    },
    {
        "name": r"HI×ŠE",
        "sumerian_transliterations": [r"bir", r"dubur", r"giriš"],
        "src": SIGN_HI_X_E_ASSET.readall(),
    },
    {
        "name": r"HU",
        "sumerian_transliterations": [r"mušen", r"pag", r"u11", r"ḫu"],
        "src": SIGN_HU_ASSET.readall(),
    },
    {
        "name": r"HUB2",
        "sumerian_transliterations": [r"tu11", r"ḫub2"],
        "src": SIGN_HUB2_ASSET.readall(),
    },
    {
        "name": r"HUB2×UD",
        "sumerian_transliterations": [r"tu10"],
        "src": SIGN_HUB2_X_UD_ASSET.readall(),
    },
    {
        "name": r"HUL2",
        "sumerian_transliterations": [r"bibra", r"gukkal", r"kuš8", r"ukuš2", r"ḫul2"],
        "src": SIGN_HUL2_ASSET.readall(),
    },
    {
        "name": r"I",
        "sumerian_transliterations": [r"i"],
        "src": SIGN_I_ASSET.readall(),
    },
    {
        "name": r"I.A",
        "sumerian_transliterations": [r"ia"],
        "src": SIGN_I_A_ASSET.readall(),
    },
    {
        "name": r"IB",
        "sumerian_transliterations": [r"dara2", r"eb", r"ib", r"ip", r"uraš", r"urta"],
        "src": SIGN_IB_ASSET.readall(),
    },
    {
        "name": r"IDIM",
        "sumerian_transliterations": [r"idim"],
        "src": SIGN_IDIM_ASSET.readall(),
    },
    {
        "name": r"IG",
        "sumerian_transliterations": [r"eg", r"ek", r"ig", r"ik", r"iq", r"ĝal2"],
        "src": SIGN_IG_ASSET.readall(),
    },
    {
        "name": r"IGI",
        "sumerian_transliterations": [r"ge8", r"gi8", r"igi", r"lib4", r"lim", r"ši"],
        "src": SIGN_IGI_ASSET.readall(),
    },
    {
        "name": r"IGIgunu",
        "sumerian_transliterations": [r"imma3", r"se12", r"sig7", r"ugur2", r"šex"],
        "src": SIGN_IGIGUNU_ASSET.readall(),
    },
    {
        "name": r"IL",
        "sumerian_transliterations": [r"il"],
        "src": SIGN_IL_ASSET.readall(),
    },
    {
        "name": r"IL2",
        "sumerian_transliterations": [r"dusu", r"ga6", r"gur3", r"guru3", r"il2"],
        "src": SIGN_IL2_ASSET.readall(),
    },
    {
        "name": r"IM",
        "sumerian_transliterations": [r"did", r"em", r"enegir", r"im", r"iškur", r"karkara", r"ni2", r"tum9"],
        "src": SIGN_IM_ASSET.readall(),
    },
    {
        "name": r"IM×TAK4",
        "sumerian_transliterations": [r"kid7"],
        "src": SIGN_IM_X_TAK4_ASSET.readall(),
    },
    {
        "name": r"IMIN",
        "sumerian_transliterations": [r"imin"],
        "src": SIGN_IMIN_ASSET.readall(),
    },
    {
        "name": r"IN",
        "sumerian_transliterations": [r"en6", r"in", r"isin2"],
        "src": SIGN_IN_ASSET.readall(),
    },
    {
        "name": r"IR",
        "sumerian_transliterations": [r"er", r"ir"],
        "src": SIGN_IR_ASSET.readall(),
    },
    {
        "name": r"IŠ",
        "sumerian_transliterations": [r"isiš", r"iš", r"iši", r"kukkuš", r"kuš7", r"saḫar"],
        "src": SIGN_I_ASSET.readall(),
    },
    {
        "name": r"KA",
        "sumerian_transliterations": [r"du11", r"dug4", r"ga14", r"giri17", r"gu3", r"inim", r"ka", r"kir4", r"pi4", r"su11", r"zu2", r"zuḫ", r"šudx"],
        "src": SIGN_KA_ASSET.readall(),
    },
    {
        "name": r"KA×A",
        "sumerian_transliterations": [r"enmen2", r"kab2", r"na8", r"naĝ"],
        "src": SIGN_KA_X_A_ASSET.readall(),
    },
    {
        "name": r"KA×BAD",
        "sumerian_transliterations": [r"uš11"],
        "src": SIGN_KA_X_BAD_ASSET.readall(),
    },
    {
        "name": r"KA×BALAG",
        "sumerian_transliterations": [r"šeg11"],
        "src": SIGN_KA_X_BALAG_ASSET.readall(),
    },
    {
        "name": r"KA×EŠ2",
        "sumerian_transliterations": [r"ma5"],
        "src": SIGN_KA_X_E_2_ASSET.readall(),
    },
    {
        "name": r"KA×GA",
        "sumerian_transliterations": [r"sub"],
        "src": SIGN_KA_X_GA_ASSET.readall(),
    },
    {
        "name": r"KA×GAN2tenu",
        "sumerian_transliterations": [r"bu3", r"kana6", r"puzur5"],
        "src": SIGN_KA_X_GAN2TENU_ASSET.readall(),
    },
    {
        "name": r"KA×GAR",
        "sumerian_transliterations": [r"gu7", r"šaĝar"],
        "src": SIGN_KA_X_GAR_ASSET.readall(),
    },
    {
        "name": r"KA×IM",
        "sumerian_transliterations": [r"bun2"],
        "src": SIGN_KA_X_IM_ASSET.readall(),
    },
    {
        "name": r"KA×LI",
        "sumerian_transliterations": [r"mu7", r"tu6", r"uš7", r"zug4", r"ĝili3", r"šegx"],
        "src": SIGN_KA_X_LI_ASSET.readall(),
    },
    {
        "name": r"KA×ME",
        "sumerian_transliterations": [r"eme"],
        "src": SIGN_KA_X_ME_ASSET.readall(),
    },
    {
        "name": r"KA×MI",
        "sumerian_transliterations": [r"kana5"],
        "src": SIGN_KA_X_MI_ASSET.readall(),
    },
    {
        "name": r"KA×NE",
        "sumerian_transliterations": [r"urgu2"],
        "src": SIGN_KA_X_NE_ASSET.readall(),
    },
    {
        "name": r"KA×NUN",
        "sumerian_transliterations": [r"nundum"],
        "src": SIGN_KA_X_NUN_ASSET.readall(),
    },
    {
        "name": r"KA×SA",
        "sumerian_transliterations": [r"sun4"],
        "src": SIGN_KA_X_SA_ASSET.readall(),
    },
    {
        "name": r"KA×SAR",
        "sumerian_transliterations": [r"ma8"],
        "src": SIGN_KA_X_SAR_ASSET.readall(),
    },
    {
        "name": r"KA×ŠE",
        "sumerian_transliterations": [r"tukur2"],
        "src": SIGN_KA_X_E_ASSET.readall(),
    },
    {
        "name": r"KA×ŠID",
        "sumerian_transliterations": [r"sigx", r"šeg10"],
        "src": SIGN_KA_X_ID_ASSET.readall(),
    },
    {
        "name": r"KA×ŠU",
        "sumerian_transliterations": [r"šudu3"],
        "src": SIGN_KA_X_U_ASSET.readall(),
    },
    {
        "name": r"KA×UD",
        "sumerian_transliterations": [r"enmen", r"si19"],
        "src": SIGN_KA_X_UD_ASSET.readall(),
    },
    {
        "name": r"KA2",
        "sumerian_transliterations": [r"kan4"],
        "src": SIGN_KA2_ASSET.readall(),
    },
    {
        "name": r"KAB",
        "sumerian_transliterations": [r"gab2", r"gabu2", r"kab"],
        "src": SIGN_KAB_ASSET.readall(),
    },
    {
        "name": r"KAD3",
        "sumerian_transliterations": [r"sedx"],
        "src": SIGN_KAD3_ASSET.readall(),
    },
    {
        "name": r"KAD4",
        "sumerian_transliterations": [r"kad4", r"kam3", r"peš5"],
        "src": SIGN_KAD4_ASSET.readall(),
    },
    {
        "name": r"KAD5",
        "sumerian_transliterations": [r"kad5", r"peš6"],
        "src": SIGN_KAD5_ASSET.readall(),
    },
    {
        "name": r"KAK",
        "sumerian_transliterations": [r"da3", r"du3", r"gag", r"ru2", r"ḫenbur"],
        "src": SIGN_KAK_ASSET.readall(),
    },
    {
        "name": r"KAL",
        "sumerian_transliterations": [r"alad2", r"esi", r"kal", r"kalag", r"lamma", r"rib", r"sun7", r"zi8", r"ĝuruš"],
        "src": SIGN_KAL_ASSET.readall(),
    },
    {
        "name": r"KAL×BAD",
        "sumerian_transliterations": [r"alad"],
        "src": SIGN_KAL_X_BAD_ASSET.readall(),
    },
    {
        "name": r"KASKAL",
        "sumerian_transliterations": [r"eš8", r"ir7", r"kaskal", r"raš"],
        "src": SIGN_KASKAL_ASSET.readall(),
    },
    {
        "name": r"KASKAL.LAGAB×U/LAGAB×U",
        "sumerian_transliterations": [r"šubtum6"],
        "src": SIGN_KASKAL_LAGAB_X_U_LAGAB_X_U_ASSET.readall(),
    },
    {
        "name": r"KEŠ2",
        "sumerian_transliterations": [r"gir11", r"keše2", r"kirid", r"ḫir"],
        "src": SIGN_KE_2_ASSET.readall(),
    },
    {
        "name": r"KI",
        "sumerian_transliterations": [r"ge5", r"gi5", r"ke", r"ki", r"qi2"],
        "src": SIGN_KI_ASSET.readall(),
    },
    {
        "name": r"KI×U",
        "sumerian_transliterations": [r"ḫabrud"],
        "src": SIGN_KI_X_U_ASSET.readall(),
    },
    {
        "name": r"KID",
        "sumerian_transliterations": [r"ge2", r"gi2", r"ke4", r"kid", r"lil2"],
        "src": SIGN_KID_ASSET.readall(),
    },
    {
        "name": r"KIN",
        "sumerian_transliterations": [r"gur10", r"kin", r"kiĝ2", r"saga11"],
        "src": SIGN_KIN_ASSET.readall(),
    },
    {
        "name": r"KISAL",
        "sumerian_transliterations": [r"kisal", r"par4"],
        "src": SIGN_KISAL_ASSET.readall(),
    },
    {
        "name": r"KIŠ",
        "sumerian_transliterations": [r"kiš"],
        "src": SIGN_KI_ASSET.readall(),
    },
    {
        "name": r"KU",
        "sumerian_transliterations": [r"bid3", r"bu7", r"dab5", r"dib2", r"dur2", r"duru2", r"durun", r"gu5", r"ku", r"nu10", r"suḫ5", r"tukul", r"tuš", r"ugu4", r"še10"],
        "src": SIGN_KU_ASSET.readall(),
    },
    {
        "name": r"KU3",
        "sumerian_transliterations": [r"ku3", r"kug"],
        "src": SIGN_KU3_ASSET.readall(),
    },
    {
        "name": r"KU4",
        "sumerian_transliterations": [r"ku4", r"kur9"],
        "src": SIGN_KU4_ASSET.readall(),
    },
    {
        "name": r"KU7",
        "sumerian_transliterations": [r"gurušta", r"ku7"],
        "src": SIGN_KU7_ASSET.readall(),
    },
    {
        "name": r"KUL",
        "sumerian_transliterations": [r"kul", r"numun"],
        "src": SIGN_KUL_ASSET.readall(),
    },
    {
        "name": r"KUN",
        "sumerian_transliterations": [r"kun"],
        "src": SIGN_KUN_ASSET.readall(),
    },
    {
        "name": r"KUR",
        "sumerian_transliterations": [r"gin3", r"kur"],
        "src": SIGN_KUR_ASSET.readall(),
    },
    {
        "name": r"KUŠU2",
        "sumerian_transliterations": [r"kušu2", r"uḫ3"],
        "src": SIGN_KU_U2_ASSET.readall(),
    },
    {
        "name": r"LA",
        "sumerian_transliterations": [r"la", r"šika"],
        "src": SIGN_LA_ASSET.readall(),
    },
    {
        "name": r"LAGAB",
        "sumerian_transliterations": [r"ellag", r"girin", r"gur4", r"kilib", r"kir3", r"lagab", r"lugud2", r"ni10", r"niĝin2", r"rin", r"ḫab"],
        "src": SIGN_LAGAB_ASSET.readall(),
    },
    {
        "name": r"LAGAB×A",
        "sumerian_transliterations": [r"ambar", r"as4", r"buniĝ", r"sug"],
        "src": SIGN_LAGAB_X_A_ASSET.readall(),
    },
    {
        "name": r"LAGAB×BAD",
        "sumerian_transliterations": [r"gigir"],
        "src": SIGN_LAGAB_X_BAD_ASSET.readall(),
    },
    {
        "name": r"LAGAB×GAR",
        "sumerian_transliterations": [r"buniĝ2"],
        "src": SIGN_LAGAB_X_GAR_ASSET.readall(),
    },
    {
        "name": r"LAGAB×GUD",
        "sumerian_transliterations": [r"šurum3"],
        "src": SIGN_LAGAB_X_GUD_ASSET.readall(),
    },
    {
        "name": r"LAGAB×GUD+GUD",
        "sumerian_transliterations": [r"ganam4", r"u8", r"šurum"],
        "src": SIGN_LAGAB_X_GUD_PLUS_GUD_ASSET.readall(),
    },
    {
        "name": r"LAGAB×HAL",
        "sumerian_transliterations": [r"engur", r"namma"],
        "src": SIGN_LAGAB_X_HAL_ASSET.readall(),
    },
    {
        "name": r"LAGAB×IGIgunu",
        "sumerian_transliterations": [r"immax", r"šara2"],
        "src": SIGN_LAGAB_X_IGIGUNU_ASSET.readall(),
    },
    {
        "name": r"LAGAB×KUL",
        "sumerian_transliterations": [r"esir2"],
        "src": SIGN_LAGAB_X_KUL_ASSET.readall(),
    },
    {
        "name": r"LAGAB×SUM",
        "sumerian_transliterations": [r"zar"],
        "src": SIGN_LAGAB_X_SUM_ASSET.readall(),
    },
    {
        "name": r"LAGAB×U",
        "sumerian_transliterations": [r"bu4", r"dul2", r"gigir2", r"pu2", r"tul2", r"ub4", r"ḫab2"],
        "src": SIGN_LAGAB_X_U_ASSET.readall(),
    },
    {
        "name": r"LAGAB×U+A",
        "sumerian_transliterations": [r"umaḫ"],
        "src": SIGN_LAGAB_X_U_PLUS_A_ASSET.readall(),
    },
    {
        "name": r"LAGAB×U+U+U",
        "sumerian_transliterations": [r"bul", r"bur10", r"ninna2", r"tuku4"],
        "src": SIGN_LAGAB_X_U_PLUS_U_PLUS_U_ASSET.readall(),
    },
    {
        "name": r"LAGAR",
        "sumerian_transliterations": [r"lagar"],
        "src": SIGN_LAGAR_ASSET.readall(),
    },
    {
        "name": r"LAGARgunu",
        "sumerian_transliterations": [r"du6"],
        "src": SIGN_LAGARGUNU_ASSET.readall(),
    },
    {
        "name": r"LAGARgunu/LAGARgunu.ŠE",
        "sumerian_transliterations": [r"part of compound"],
        "src": SIGN_LAGARGUNU_LAGARGUNU_E_ASSET.readall(),
    },
    {
        "name": r"LAGAR×ŠE",
        "sumerian_transliterations": [r"sur12"],
        "src": SIGN_LAGAR_X_E_ASSET.readall(),
    },
    {
        "name": r"LAL",
        "sumerian_transliterations": [r"la2", r"lal", r"suru5"],
        "src": SIGN_LAL_ASSET.readall(),
    },
    {
        "name": r"LAL×LAL",
        "sumerian_transliterations": [r"part of compound"],
        "src": SIGN_LAL_X_LAL_ASSET.readall(),
    },
    {
        "name": r"LAM",
        "sumerian_transliterations": [r"ešx", r"lam"],
        "src": SIGN_LAM_ASSET.readall(),
    },
    {
        "name": r"LI",
        "sumerian_transliterations": [r"en3", r"gub2", r"le", r"li"],
        "src": SIGN_LI_ASSET.readall(),
    },
    {
        "name": r"LIL",
        "sumerian_transliterations": [r"lil", r"sukux"],
        "src": SIGN_LIL_ASSET.readall(),
    },
    {
        "name": r"LIMMU2",
        "sumerian_transliterations": [r"limmu2"],
        "src": SIGN_LIMMU2_ASSET.readall(),
    },
    {
        "name": r"LIŠ",
        "sumerian_transliterations": [r"dilim2"],
        "src": SIGN_LI_ASSET.readall(),
    },
    {
        "name": r"LU",
        "sumerian_transliterations": [r"lu", r"lug", r"nu12", r"udu"],
        "src": SIGN_LU_ASSET.readall(),
    },
    {
        "name": r"LU×BAD",
        "sumerian_transliterations": [r"ad3"],
        "src": SIGN_LU_X_BAD_ASSET.readall(),
    },
    {
        "name": r"LU2",
        "sumerian_transliterations": [r"lu2"],
        "src": SIGN_LU2_ASSET.readall(),
    },
    {
        "name": r"LU2(inverted)LU2",
        "sumerian_transliterations": [r"inbir"],
        "src": SIGN_LU2_INVERTED_LU2_ASSET.readall(),
    },
    {
        "name": r"LU2šešig",
        "sumerian_transliterations": [r"ri9"],
        "src": SIGN_LU2_E_IG_ASSET.readall(),
    },
    {
        "name": r"LU2×BAD",
        "sumerian_transliterations": [r"ad6"],
        "src": SIGN_LU2_X_BAD_ASSET.readall(),
    },
    {
        "name": r"LU2×GAN2tenu",
        "sumerian_transliterations": [r"šaĝa", r"še29"],
        "src": SIGN_LU2_X_GAN2TENU_ASSET.readall(),
    },
    {
        "name": r"LU2×NE",
        "sumerian_transliterations": [r"du14"],
        "src": SIGN_LU2_X_NE_ASSET.readall(),
    },
    {
        "name": r"LU3",
        "sumerian_transliterations": [r"gar5", r"gug2", r"lu3"],
        "src": SIGN_LU3_ASSET.readall(),
    },
    {
        "name": r"LUGAL",
        "sumerian_transliterations": [r"lillan", r"lugal", r"rab3", r"šarrum"],
        "src": SIGN_LUGAL_ASSET.readall(),
    },
    {
        "name": r"LUGALšešig",
        "sumerian_transliterations": [r"dim3"],
        "src": SIGN_LUGAL_E_IG_ASSET.readall(),
    },
    {
        "name": r"LUH",
        "sumerian_transliterations": [r"luḫ", r"sukkal", r"ḫuluḫ"],
        "src": SIGN_LUH_ASSET.readall(),
    },
    {
        "name": r"LUL",
        "sumerian_transliterations": [r"ka5", r"lib", r"lu5", r"lub", r"lul", r"nar", r"paḫ", r"šatam"],
        "src": SIGN_LUL_ASSET.readall(),
    },
    {
        "name": r"LUM",
        "sumerian_transliterations": [r"gum2", r"gun5", r"guz", r"lum", r"num2", r"ḫum", r"ḫuz"],
        "src": SIGN_LUM_ASSET.readall(),
    },
    {
        "name": r"MA",
        "sumerian_transliterations": [r"ma", r"peš3"],
        "src": SIGN_MA_ASSET.readall(),
    },
    {
        "name": r"MAgunu",
        "sumerian_transliterations": [r"ḫašḫur"],
        "src": SIGN_MAGUNU_ASSET.readall(),
    },
    {
        "name": r"MA2",
        "sumerian_transliterations": [r"ma2"],
        "src": SIGN_MA2_ASSET.readall(),
    },
    {
        "name": r"MAH",
        "sumerian_transliterations": [r"maḫ", r"šutur"],
        "src": SIGN_MAH_ASSET.readall(),
    },
    {
        "name": r"MAR",
        "sumerian_transliterations": [r"mar"],
        "src": SIGN_MAR_ASSET.readall(),
    },
    {
        "name": r"MAŠ",
        "sumerian_transliterations": [r"mas", r"maš", r"sa9"],
        "src": SIGN_MA_ASSET.readall(),
    },
    {
        "name": r"MAŠ2",
        "sumerian_transliterations": [r"maš2"],
        "src": SIGN_MA_2_ASSET.readall(),
    },
    {
        "name": r"ME",
        "sumerian_transliterations": [r"ba13", r"išib", r"me", r"men2"],
        "src": SIGN_ME_ASSET.readall(),
    },
    {
        "name": r"MES",
        "sumerian_transliterations": [r"kišib", r"meš3"],
        "src": SIGN_MES_ASSET.readall(),
    },
    {
        "name": r"MI",
        "sumerian_transliterations": [r"gig2", r"ku10", r"me2", r"mi", r"ĝi6"],
        "src": SIGN_MI_ASSET.readall(),
    },
    {
        "name": r"MIN",
        "sumerian_transliterations": [r"min"],
        "src": SIGN_MIN_ASSET.readall(),
    },
    {
        "name": r"MU",
        "sumerian_transliterations": [r"mu", r"muḫaldim", r"ĝu10"],
        "src": SIGN_MU_ASSET.readall(),
    },
    {
        "name": r"MU/MU",
        "sumerian_transliterations": [r"daḫ", r"taḫ"],
        "src": SIGN_MU_MU_ASSET.readall(),
    },
    {
        "name": r"MUG",
        "sumerian_transliterations": [r"mug"],
        "src": SIGN_MUG_ASSET.readall(),
    },
    {
        "name": r"MUNSUB",
        "sumerian_transliterations": [r"sumur3"],
        "src": SIGN_MUNSUB_ASSET.readall(),
    },
    {
        "name": r"MURGU2",
        "sumerian_transliterations": [r"murgu2"],
        "src": SIGN_MURGU2_ASSET.readall(),
    },
    {
        "name": r"MUŠ",
        "sumerian_transliterations": [r"muš", r"niraḫ", r"suḫx", r"šubax"],
        "src": SIGN_MU_ASSET.readall(),
    },
    {
        "name": r"MUŠ/MUŠ",
        "sumerian_transliterations": [r"ri8"],
        "src": SIGN_MU_MU_ASSET.readall(),
    },
    {
        "name": r"MUŠ/MUŠ×A+NA",
        "sumerian_transliterations": [r"erina8"],
        "src": SIGN_MU_MU_X_A_PLUS_NA_ASSET.readall(),
    },
    {
        "name": r"MUŠ3",
        "sumerian_transliterations": [r"inana", r"muš3", r"sed6", r"suḫ10", r"šuba4"],
        "src": SIGN_MU_3_ASSET.readall(),
    },
    {
        "name": r"MUŠ3gunu",
        "sumerian_transliterations": [r"muš2", r"susbu2", r"suḫ"],
        "src": SIGN_MU_3GUNU_ASSET.readall(),
    },
    {
        "name": r"MUŠ3×A",
        "sumerian_transliterations": [r"part of compound"],
        "src": SIGN_MU_3_X_A_ASSET.readall(),
    },
    {
        "name": r"MUŠ3×A+DI",
        "sumerian_transliterations": [r"sed"],
        "src": SIGN_MU_3_X_A_PLUS_DI_ASSET.readall(),
    },
    {
        "name": r"NA",
        "sumerian_transliterations": [r"na"],
        "src": SIGN_NA_ASSET.readall(),
    },
    {
        "name": r"NA2",
        "sumerian_transliterations": [r"na2", r"nu2"],
        "src": SIGN_NA2_ASSET.readall(),
    },
    {
        "name": r"NAGA",
        "sumerian_transliterations": [r"ereš2", r"naĝa", r"nisaba2"],
        "src": SIGN_NAGA_ASSET.readall(),
    },
    {
        "name": r"NAGA(inverted)",
        "sumerian_transliterations": [r"teme"],
        "src": SIGN_NAGA_INVERTED_ASSET.readall(),
    },
    {
        "name": r"NAGAR",
        "sumerian_transliterations": [r"nagar"],
        "src": SIGN_NAGAR_ASSET.readall(),
    },
    {
        "name": r"NAM",
        "sumerian_transliterations": [r"bir5", r"nam", r"sim", r"sin2"],
        "src": SIGN_NAM_ASSET.readall(),
    },
    {
        "name": r"NE",
        "sumerian_transliterations": [r"bar7", r"be7", r"bi2", r"bil", r"de3", r"du17", r"gibil4", r"izi", r"kum2", r"lam2", r"lem4", r"li9", r"ne", r"ni5", r"pel", r"pil", r"saḫarx", r"šeĝ6"],
        "src": SIGN_NE_ASSET.readall(),
    },
    {
        "name": r"NEšešig",
        "sumerian_transliterations": [r"bil2", r"gibil", r"pel2"],
        "src": SIGN_NE_E_IG_ASSET.readall(),
    },
    {
        "name": r"NI",
        "sumerian_transliterations": [r"be3", r"dig", r"i3", r"ia3", r"le2", r"li2", r"lid2", r"ne2", r"ni", r"suš2", r"zal", r"zar2"],
        "src": SIGN_NI_ASSET.readall(),
    },
    {
        "name": r"NIM",
        "sumerian_transliterations": [r"deḫi3", r"elam", r"nim", r"tum4"],
        "src": SIGN_NIM_ASSET.readall(),
    },
    {
        "name": r"NIM×GAN2tenu",
        "sumerian_transliterations": [r"tum3"],
        "src": SIGN_NIM_X_GAN2TENU_ASSET.readall(),
    },
    {
        "name": r"NINDA2",
        "sumerian_transliterations": [r"inda", r"ninda2"],
        "src": SIGN_NINDA2_ASSET.readall(),
    },
    {
        "name": r"NINDA2×GUD",
        "sumerian_transliterations": [r"indagara"],
        "src": SIGN_NINDA2_X_GUD_ASSET.readall(),
    },
    {
        "name": r"NINDA2×NE",
        "sumerian_transliterations": [r"aĝ2", r"em3", r"eĝ3", r"iĝ3"],
        "src": SIGN_NINDA2_X_NE_ASSET.readall(),
    },
    {
        "name": r"NINDA2×ŠE",
        "sumerian_transliterations": [r"sa10", r"sam2"],
        "src": SIGN_NINDA2_X_E_ASSET.readall(),
    },
    {
        "name": r"NISAG",
        "sumerian_transliterations": [r"nesaĝ"],
        "src": SIGN_NISAG_ASSET.readall(),
    },
    {
        "name": r"NU",
        "sumerian_transliterations": [r"nu", r"sir5"],
        "src": SIGN_NU_ASSET.readall(),
    },
    {
        "name": r"NU11",
        "sumerian_transliterations": [r"nu11"],
        "src": SIGN_NU11_ASSET.readall(),
    },
    {
        "name": r"NUN",
        "sumerian_transliterations": [r"eridug", r"nun", r"sil2", r"zil"],
        "src": SIGN_NUN_ASSET.readall(),
    },
    {
        "name": r"NUNUZ",
        "sumerian_transliterations": [r"nida", r"nunuz", r"nus"],
        "src": SIGN_NUNUZ_ASSET.readall(),
    },
    {
        "name": r"NUNUZ.AB2×AŠGAB",
        "sumerian_transliterations": [r"usan3"],
        "src": SIGN_NUNUZ_AB2_X_A_GAB_ASSET.readall(),
    },
    {
        "name": r"NUNUZ.AB2×LA",
        "sumerian_transliterations": [r"laḫtan"],
        "src": SIGN_NUNUZ_AB2_X_LA_ASSET.readall(),
    },
    {
        "name": r"NUN.LAGAR×MAŠ",
        "sumerian_transliterations": [r"immal"],
        "src": SIGN_NUN_LAGAR_X_MA_ASSET.readall(),
    },
    {
        "name": r"NUN.LAGAR×SAL",
        "sumerian_transliterations": [r"arḫuš2", r"immal2", r"šilam"],
        "src": SIGN_NUN_LAGAR_X_SAL_ASSET.readall(),
    },
    {
        "name": r"NUN/NUN",
        "sumerian_transliterations": [r"nir", r"ri5", r"tirx", r"šer7"],
        "src": SIGN_NUN_NUN_ASSET.readall(),
    },
    {
        "name": r"NUNtenu",
        "sumerian_transliterations": [r"agargara", r"garx"],
        "src": SIGN_NUNTENU_ASSET.readall(),
    },
    {
        "name": r"PA",
        "sumerian_transliterations": [r"kumx", r"kun2", r"mu6", r"mudru", r"pa", r"sag3", r"sig3", r"ugula", r"ux", r"ĝidru", r"ḫendur"],
        "src": SIGN_PA_ASSET.readall(),
    },
    {
        "name": r"PAD",
        "sumerian_transliterations": [r"kurum6", r"pad", r"pax", r"šukur2", r"šutug"],
        "src": SIGN_PAD_ASSET.readall(),
    },
    {
        "name": r"PAN",
        "sumerian_transliterations": [r"pan"],
        "src": SIGN_PAN_ASSET.readall(),
    },
    {
        "name": r"PAP",
        "sumerian_transliterations": [r"kur2", r"pa4", r"pap"],
        "src": SIGN_PAP_ASSET.readall(),
    },
    {
        "name": r"PEŠ2",
        "sumerian_transliterations": [r"kilim", r"peš2"],
        "src": SIGN_PE_2_ASSET.readall(),
    },
    {
        "name": r"PI",
        "sumerian_transliterations": [r"be6", r"bi3", r"me8", r"pa12", r"pe", r"pi", r"tal2", r"wa", r"we", r"wi", r"ĝeštug"],
        "src": SIGN_PI_ASSET.readall(),
    },
    {
        "name": r"PIRIG",
        "sumerian_transliterations": [r"ne3", r"niskum", r"piriĝ"],
        "src": SIGN_PIRIG_ASSET.readall(),
    },
    {
        "name": r"PIRIG(inverted)PIRIG",
        "sumerian_transliterations": [r"tidnim", r"tidnum"],
        "src": SIGN_PIRIG_INVERTED_PIRIG_ASSET.readall(),
    },
    {
        "name": r"PIRIG×UD",
        "sumerian_transliterations": [r"piriĝ3", r"ug", r"uk", r"uq"],
        "src": SIGN_PIRIG_X_UD_ASSET.readall(),
    },
    {
        "name": r"PIRIG×ZA",
        "sumerian_transliterations": [r"az"],
        "src": SIGN_PIRIG_X_ZA_ASSET.readall(),
    },
    {
        "name": r"RA",
        "sumerian_transliterations": [r"ra"],
        "src": SIGN_RA_ASSET.readall(),
    },
    {
        "name": r"RI",
        "sumerian_transliterations": [r"dal", r"de5", r"re", r"ri", r"rig5"],
        "src": SIGN_RI_ASSET.readall(),
    },
    {
        "name": r"RU",
        "sumerian_transliterations": [r"ilar", r"ru", r"šub"],
        "src": SIGN_RU_ASSET.readall(),
    },
    {
        "name": r"SA",
        "sumerian_transliterations": [r"sa"],
        "src": SIGN_SA_ASSET.readall(),
    },
    {
        "name": r"SAG",
        "sumerian_transliterations": [r"dul7", r"sa12", r"saĝ", r"šak"],
        "src": SIGN_SAG_ASSET.readall(),
    },
    {
        "name": r"SAGgunu",
        "sumerian_transliterations": [r"dul3", r"kuš2", r"kušu4", r"sumur", r"sur2"],
        "src": SIGN_SAGGUNU_ASSET.readall(),
    },
    {
        "name": r"SAG×ŠID",
        "sumerian_transliterations": [r"dilib3"],
        "src": SIGN_SAG_X_ID_ASSET.readall(),
    },
    {
        "name": r"SAG×U2",
        "sumerian_transliterations": [r"uzug3"],
        "src": SIGN_SAG_X_U2_ASSET.readall(),
    },
    {
        "name": r"SAL",
        "sumerian_transliterations": [r"gal4", r"mi2", r"munus", r"sal"],
        "src": SIGN_SAL_ASSET.readall(),
    },
    {
        "name": r"SAR",
        "sumerian_transliterations": [r"kiri6", r"mu2", r"nisig", r"sakar", r"sar", r"saḫar2", r"sigx", r"šar"],
        "src": SIGN_SAR_ASSET.readall(),
    },
    {
        "name": r"SI",
        "sumerian_transliterations": [r"si", r"sig9"],
        "src": SIGN_SI_ASSET.readall(),
    },
    {
        "name": r"SIgunu",
        "sumerian_transliterations": [r"sa11", r"su4"],
        "src": SIGN_SIGUNU_ASSET.readall(),
    },
    {
        "name": r"SIG",
        "sumerian_transliterations": [r"si11", r"sig", r"sik", r"šex"],
        "src": SIGN_SIG_ASSET.readall(),
    },
    {
        "name": r"SIG4",
        "sumerian_transliterations": [r"kulla", r"murgu", r"ĝar8", r"šeg12"],
        "src": SIGN_SIG4_ASSET.readall(),
    },
    {
        "name": r"SIK2",
        "sumerian_transliterations": [r"siki"],
        "src": SIGN_SIK2_ASSET.readall(),
    },
    {
        "name": r"SILA3",
        "sumerian_transliterations": [r"qa", r"sal4", r"sila3"],
        "src": SIGN_SILA3_ASSET.readall(),
    },
    {
        "name": r"SU",
        "sumerian_transliterations": [r"kuš", r"su", r"sug6"],
        "src": SIGN_SU_ASSET.readall(),
    },
    {
        "name": r"SUD",
        "sumerian_transliterations": [r"su3", r"sud", r"sug4"],
        "src": SIGN_SUD_ASSET.readall(),
    },
    {
        "name": r"SUD2",
        "sumerian_transliterations": [r"sud2", r"šita3"],
        "src": SIGN_SUD2_ASSET.readall(),
    },
    {
        "name": r"SUHUR",
        "sumerian_transliterations": [r"sumur2", r"suḫur"],
        "src": SIGN_SUHUR_ASSET.readall(),
    },
    {
        "name": r"SUM",
        "sumerian_transliterations": [r"si3", r"sig10", r"sum", r"šum2"],
        "src": SIGN_SUM_ASSET.readall(),
    },
    {
        "name": r"SUR",
        "sumerian_transliterations": [r"sur"],
        "src": SIGN_SUR_ASSET.readall(),
    },
    {
        "name": r"ŠA",
        "sumerian_transliterations": [r"en8", r"ša"],
        "src": SIGN_A_ASSET.readall(),
    },
    {
        "name": r"ŠA3",
        "sumerian_transliterations": [r"pešx", r"ša3", r"šag4"],
        "src": SIGN_A3_ASSET.readall(),
    },
    {
        "name": r"ŠA3×A",
        "sumerian_transliterations": [r"bir7", r"iškila", r"peš4"],
        "src": SIGN_A3_X_A_ASSET.readall(),
    },
    {
        "name": r"ŠA3×NE",
        "sumerian_transliterations": [r"ninim"],
        "src": SIGN_A3_X_NE_ASSET.readall(),
    },
    {
        "name": r"ŠA3×TUR",
        "sumerian_transliterations": [r"peš13"],
        "src": SIGN_A3_X_TUR_ASSET.readall(),
    },
    {
        "name": r"ŠA6",
        "sumerian_transliterations": [r"sa6", r"sag9", r"ĝišnimbar"],
        "src": SIGN_A6_ASSET.readall(),
    },
    {
        "name": r"ŠE",
        "sumerian_transliterations": [r"niga", r"še"],
        "src": SIGN_E_ASSET.readall(),
    },
    {
        "name": r"ŠE/ŠE.TAB/TAB.GAR/GAR",
        "sumerian_transliterations": [r"garadin3"],
        "src": SIGN_E_E_TAB_TAB_GAR_GAR_ASSET.readall(),
    },
    {
        "name": r"ŠEG9",
        "sumerian_transliterations": [r"kiši6", r"šeg9"],
        "src": SIGN_EG9_ASSET.readall(),
    },
    {
        "name": r"ŠEN",
        "sumerian_transliterations": [r"dur10", r"šen"],
        "src": SIGN_EN_ASSET.readall(),
    },
    {
        "name": r"ŠEŠ",
        "sumerian_transliterations": [r"mun4", r"muš5", r"sis", r"šeš"],
        "src": SIGN_E_ASSET.readall(),
    },
    {
        "name": r"ŠEŠ2",
        "sumerian_transliterations": [r"še8", r"šeš2"],
        "src": SIGN_E_2_ASSET.readall(),
    },
    {
        "name": r"ŠID",
        "sumerian_transliterations": [r"kas7", r"kiri8", r"lag", r"nesaĝ2", r"pisaĝ2", r"saĝ5", r"saĝĝa", r"silaĝ", r"šid", r"šub6", r"šudum"],
        "src": SIGN_ID_ASSET.readall(),
    },
    {
        "name": r"ŠID×A",
        "sumerian_transliterations": [r"alal", r"pisaĝ3"],
        "src": SIGN_ID_X_A_ASSET.readall(),
    },
    {
        "name": r"ŠIM",
        "sumerian_transliterations": [r"bappir2", r"lunga", r"mud5", r"šem", r"šembi2", r"šembizid", r"šim"],
        "src": SIGN_IM_ASSET.readall(),
    },
    {
        "name": r"ŠIM×GAR",
        "sumerian_transliterations": [r"bappir", r"lunga3"],
        "src": SIGN_IM_X_GAR_ASSET.readall(),
    },
    {
        "name": r"ŠIM×IGIgunu",
        "sumerian_transliterations": [r"šembi"],
        "src": SIGN_IM_X_IGIGUNU_ASSET.readall(),
    },
    {
        "name": r"ŠIM×KUŠU2",
        "sumerian_transliterations": [r"šembulugx"],
        "src": SIGN_IM_X_KU_U2_ASSET.readall(),
    },
    {
        "name": r"ŠINIG",
        "sumerian_transliterations": [r"šinig"],
        "src": SIGN_INIG_ASSET.readall(),
    },
    {
        "name": r"ŠIR",
        "sumerian_transliterations": [r"aš7", r"šir"],
        "src": SIGN_IR_ASSET.readall(),
    },
    {
        "name": r"ŠITA",
        "sumerian_transliterations": [r"šita"],
        "src": SIGN_ITA_ASSET.readall(),
    },
    {
        "name": r"ŠU",
        "sumerian_transliterations": [r"šu"],
        "src": SIGN_U_ASSET.readall(),
    },
    {
        "name": r"ŠU2",
        "sumerian_transliterations": [r"šu2", r"šuš2"],
        "src": SIGN_U2_ASSET.readall(),
    },
    {
        "name": r"ŠUBUR",
        "sumerian_transliterations": [r"šaḫ", r"šubur"],
        "src": SIGN_UBUR_ASSET.readall(),
    },
    {
        "name": r"TA",
        "sumerian_transliterations": [r"da2", r"ta"],
        "src": SIGN_TA_ASSET.readall(),
    },
    {
        "name": r"TA×HI",
        "sumerian_transliterations": [r"alamuš", r"lal3"],
        "src": SIGN_TA_X_HI_ASSET.readall(),
    },
    {
        "name": r"TAB",
        "sumerian_transliterations": [r"dab2", r"tab", r"tap"],
        "src": SIGN_TAB_ASSET.readall(),
    },
    {
        "name": r"TAG",
        "sumerian_transliterations": [r"sub6", r"tag", r"tibir", r"tuku5", r"zil2", r"šum"],
        "src": SIGN_TAG_ASSET.readall(),
    },
    {
        "name": r"TAG×ŠU",
        "sumerian_transliterations": [r"tibir2"],
        "src": SIGN_TAG_X_U_ASSET.readall(),
    },
    {
        "name": r"TAG×TUG2",
        "sumerian_transliterations": [r"uttu"],
        "src": SIGN_TAG_X_TUG2_ASSET.readall(),
    },
    {
        "name": r"TAK4",
        "sumerian_transliterations": [r"da13", r"kid2", r"tak4", r"taka4"],
        "src": SIGN_TAK4_ASSET.readall(),
    },
    {
        "name": r"TAR",
        "sumerian_transliterations": [r"ku5", r"kud", r"kur5", r"sila", r"tar", r"ḫaš"],
        "src": SIGN_TAR_ASSET.readall(),
    },
    {
        "name": r"TE",
        "sumerian_transliterations": [r"gal5", r"te", r"temen", r"ten", r"teĝ3"],
        "src": SIGN_TE_ASSET.readall(),
    },
    {
        "name": r"TEgunu",
        "sumerian_transliterations": [r"gur8", r"tenx", r"uru5"],
        "src": SIGN_TEGUNU_ASSET.readall(),
    },
    {
        "name": r"TI",
        "sumerian_transliterations": [r"de9", r"di3", r"ti", r"til3", r"tiĝ4"],
        "src": SIGN_TI_ASSET.readall(),
    },
    {
        "name": r"TIL",
        "sumerian_transliterations": [r"sumun", r"til", r"šumun"],
        "src": SIGN_TIL_ASSET.readall(),
    },
    {
        "name": r"TIR",
        "sumerian_transliterations": [r"ezina3", r"ter", r"tir"],
        "src": SIGN_TIR_ASSET.readall(),
    },
    {
        "name": r"TU",
        "sumerian_transliterations": [r"du2", r"tu", r"tud", r"tum12", r"tur5"],
        "src": SIGN_TU_ASSET.readall(),
    },
    {
        "name": r"TUG2",
        "sumerian_transliterations": [r"azlag2", r"dul5", r"mu4", r"mur10", r"nam2", r"taškarin", r"tubax", r"tug2", r"tuku2", r"umuš"],
        "src": SIGN_TUG2_ASSET.readall(),
    },
    {
        "name": r"TUK",
        "sumerian_transliterations": [r"du12", r"tuk", r"tuku"],
        "src": SIGN_TUK_ASSET.readall(),
    },
    {
        "name": r"TUM",
        "sumerian_transliterations": [r"dum", r"eb2", r"ib2", r"tum"],
        "src": SIGN_TUM_ASSET.readall(),
    },
    {
        "name": r"TUR",
        "sumerian_transliterations": [r"ban3", r"banda3", r"di4", r"dumu", r"tur"],
        "src": SIGN_TUR_ASSET.readall(),
    },
    {
        "name": r"U",
        "sumerian_transliterations": [r"bur3", r"buru3", r"u", r"šu4"],
        "src": SIGN_U_ASSET.readall(),
    },
    {
        "name": r"U.GUD",
        "sumerian_transliterations": [r"du7", r"ul"],
        "src": SIGN_U_GUD_ASSET.readall(),
    },
    {
        "name": r"U.U.U",
        "sumerian_transliterations": [r"es2", r"eš"],
        "src": SIGN_U_U_U_ASSET.readall(),
    },
    {
        "name": r"U/U.PA/PA.GAR/GAR",
        "sumerian_transliterations": [r"garadin10"],
        "src": SIGN_U_U_PA_PA_GAR_GAR_ASSET.readall(),
    },
    {
        "name": r"U/U.SUR/SUR",
        "sumerian_transliterations": [r"garadin9"],
        "src": SIGN_U_U_SUR_SUR_ASSET.readall(),
    },
    {
        "name": r"U2",
        "sumerian_transliterations": [r"kuš3", r"u2"],
        "src": SIGN_U2_ASSET.readall(),
    },
    {
        "name": r"UB",
        "sumerian_transliterations": [r"ar2", r"ub", r"up"],
        "src": SIGN_UB_ASSET.readall(),
    },
    {
        "name": r"UD",
        "sumerian_transliterations": [r"a12", r"babbar", r"bir2", r"dag2", r"tam", r"u4", r"ud", r"ut", r"utu", r"zalag", r"šamaš", r"ḫad2"],
        "src": SIGN_UD_ASSET.readall(),
    },
    {
        "name": r"UD.KUŠU2",
        "sumerian_transliterations": [r"akšak", r"aḫ6", r"uḫ2"],
        "src": SIGN_UD_KU_U2_ASSET.readall(),
    },
    {
        "name": r"UD×U+U+U",
        "sumerian_transliterations": [r"itid"],
        "src": SIGN_UD_X_U_PLUS_U_PLUS_U_ASSET.readall(),
    },
    {
        "name": r"UD×U+U+Ugunu",
        "sumerian_transliterations": [r"murub4"],
        "src": SIGN_UD_X_U_PLUS_U_PLUS_UGUNU_ASSET.readall(),
    },
    {
        "name": r"UDUG",
        "sumerian_transliterations": [r"udug"],
        "src": SIGN_UDUG_ASSET.readall(),
    },
    {
        "name": r"UM",
        "sumerian_transliterations": [r"deḫi2", r"um"],
        "src": SIGN_UM_ASSET.readall(),
    },
    {
        "name": r"UMUM",
        "sumerian_transliterations": [r"simug", r"umum", r"umun2"],
        "src": SIGN_UMUM_ASSET.readall(),
    },
    {
        "name": r"UMUM×KASKAL",
        "sumerian_transliterations": [r"abzux", r"de2"],
        "src": SIGN_UMUM_X_KASKAL_ASSET.readall(),
    },
    {
        "name": r"UN",
        "sumerian_transliterations": [r"kalam", r"un", r"uĝ3"],
        "src": SIGN_UN_ASSET.readall(),
    },
    {
        "name": r"UR",
        "sumerian_transliterations": [r"teš2", r"ur"],
        "src": SIGN_UR_ASSET.readall(),
    },
    {
        "name": r"URšešig",
        "sumerian_transliterations": [r"dul9"],
        "src": SIGN_UR_E_IG_ASSET.readall(),
    },
    {
        "name": r"UR2",
        "sumerian_transliterations": [r"ur2"],
        "src": SIGN_UR2_ASSET.readall(),
    },
    {
        "name": r"UR2×NUN",
        "sumerian_transliterations": [r"ušbar"],
        "src": SIGN_UR2_X_NUN_ASSET.readall(),
    },
    {
        "name": r"UR2×U2",
        "sumerian_transliterations": [r"ušbar7"],
        "src": SIGN_UR2_X_U2_ASSET.readall(),
    },
    {
        "name": r"UR2×U2+AŠ",
        "sumerian_transliterations": [r"ušbar3"],
        "src": SIGN_UR2_X_U2_PLUS_A_ASSET.readall(),
    },
    {
        "name": r"UR4",
        "sumerian_transliterations": [r"ur4"],
        "src": SIGN_UR4_ASSET.readall(),
    },
    {
        "name": r"URI",
        "sumerian_transliterations": [r"uri"],
        "src": SIGN_URI_ASSET.readall(),
    },
    {
        "name": r"URI3",
        "sumerian_transliterations": [r"urin", r"uru3"],
        "src": SIGN_URI3_ASSET.readall(),
    },
    {
        "name": r"URU",
        "sumerian_transliterations": [r"eri", r"iri", r"re2", r"ri2", r"u19", r"uru"],
        "src": SIGN_URU_ASSET.readall(),
    },
    {
        "name": r"URU×A",
        "sumerian_transliterations": [r"uru18"],
        "src": SIGN_URU_X_A_ASSET.readall(),
    },
    {
        "name": r"URU×BAR",
        "sumerian_transliterations": [r"unken"],
        "src": SIGN_URU_X_BAR_ASSET.readall(),
    },
    {
        "name": r"URU×GA",
        "sumerian_transliterations": [r"šakir3"],
        "src": SIGN_URU_X_GA_ASSET.readall(),
    },
    {
        "name": r"URU×GAR",
        "sumerian_transliterations": [r"erim3"],
        "src": SIGN_URU_X_GAR_ASSET.readall(),
    },
    {
        "name": r"URU×GU",
        "sumerian_transliterations": [r"gur5", r"guru5", r"guruš3", r"šakir", r"šegx"],
        "src": SIGN_URU_X_GU_ASSET.readall(),
    },
    {
        "name": r"URU×IGI",
        "sumerian_transliterations": [r"asal", r"asar", r"asari", r"silig"],
        "src": SIGN_URU_X_IGI_ASSET.readall(),
    },
    {
        "name": r"URU×MIN",
        "sumerian_transliterations": [r"u18", r"ulu3", r"uru17", r"ĝišgal"],
        "src": SIGN_URU_X_MIN_ASSET.readall(),
    },
    {
        "name": r"URU×TU",
        "sumerian_transliterations": [r"šeg5"],
        "src": SIGN_URU_X_TU_ASSET.readall(),
    },
    {
        "name": r"URU×UD",
        "sumerian_transliterations": [r"erim6", r"uru2"],
        "src": SIGN_URU_X_UD_ASSET.readall(),
    },
    {
        "name": r"URU×URUDA",
        "sumerian_transliterations": [r"banšur", r"silig5", r"urux"],
        "src": SIGN_URU_X_URUDA_ASSET.readall(),
    },
    {
        "name": r"URUDA",
        "sumerian_transliterations": [r"dab6", r"urud"],
        "src": SIGN_URUDA_ASSET.readall(),
    },
    {
        "name": r"UŠ",
        "sumerian_transliterations": [r"nitaḫ", r"us2", r"uš", r"ĝiš3"],
        "src": SIGN_U_ASSET.readall(),
    },
    {
        "name": r"UŠ2",
        "sumerian_transliterations": [r"ug7", r"uš2"],
        "src": SIGN_ONE_E_E3_ASSET.readall(),
    },
    {
        "name": r"UŠ×A",
        "sumerian_transliterations": [r"kaš3"],
        "src": SIGN_U_X_A_ASSET.readall(),
    },
    {
        "name": r"UŠ×TAK4",
        "sumerian_transliterations": [r"dan6"],
        "src": SIGN_U_X_TAK4_ASSET.readall(),
    },
    {
        "name": r"UZ3",
        "sumerian_transliterations": [r"ud5", r"uz3"],
        "src": SIGN_UZ3_ASSET.readall(),
    },
    {
        "name": r"UZU",
        "sumerian_transliterations": [r"uzu"],
        "src": SIGN_UZU_ASSET.readall(),
    },
    {
        "name": r"ZA",
        "sumerian_transliterations": [r"sa3", r"za"],
        "src": SIGN_ZA_ASSET.readall(),
    },
    {
        "name": r"ZAtenu",
        "sumerian_transliterations": [r"ad4"],
        "src": SIGN_ZATENU_ASSET.readall(),
    },
    {
        "name": r"ZADIM",
        "sumerian_transliterations": [r"zadim"],
        "src": SIGN_ZADIM_ASSET.readall(),
    },
    {
        "name": r"ZAG",
        "sumerian_transliterations": [r"za3", r"zag", r"zak"],
        "src": SIGN_ZAG_ASSET.readall(),
    },
    {
        "name": r"ZE2",
        "sumerian_transliterations": [r"ze2", r"zi2"],
        "src": SIGN_ZE2_ASSET.readall(),
    },
    {
        "name": r"ZI",
        "sumerian_transliterations": [r"se2", r"si2", r"ze", r"zi", r"zid", r"zig3", r"ṣi2"],
        "src": SIGN_ZI_ASSET.readall(),
    },
    {
        "name": r"ZI/ZI",
        "sumerian_transliterations": [r"part of compound"],
        "src": SIGN_ZI_ZI_ASSET.readall(),
    },
    {
        "name": r"ZI3",
        "sumerian_transliterations": [r"zid2"],
        "src": SIGN_ZI3_ASSET.readall(),
    },
    {
        "name": r"ZIG",
        "sumerian_transliterations": [r"zib2", r"ḫaš2"],
        "src": SIGN_ZIG_ASSET.readall(),
    },
    {
        "name": r"ZU",
        "sumerian_transliterations": [r"su2", r"zu"],
        "src": SIGN_ZU_ASSET.readall(),
    },
    {
        "name": r"ZUM",
        "sumerian_transliterations": [r"rig2", r"sum2", r"zum", r"ḫaš4"],
        "src": SIGN_ZUM_ASSET.readall(),
    },
    {
        "name": r"TWO.AŠ",
        "sumerian_transliterations": [r"min5"],
        "src": SIGN_TWO_A_ASSET.readall(),
    },
    {
        "name": r"ONE.BURU",
        "sumerian_transliterations": [r"BUR3gunu"],
        "src": SIGN_ONE_BURU_ASSET.readall(),
    },
    {
        "name": r"THREE.DIŠ",
        "sumerian_transliterations": [r"eš5"],
        "src": SIGN_THREE_DI_ASSET.readall(),
    },
    {
        "name": r"FOUR.DIŠ",
        "sumerian_transliterations": [r"limmu5"],
        "src": SIGN_FOUR_DI_ASSET.readall(),
    },
    {
        "name": r"FOUR.DIŠ.VAR",
        "sumerian_transliterations": [r"limmu"],
        "src": SIGN_FOUR_DI_VAR_ASSET.readall(),
    },
    {
        "name": r"FIVE.DIŠ",
        "sumerian_transliterations": [r"ia2"],
        "src": SIGN_FIVE_DI_ASSET.readall(),
    },
    {
        "name": r"EIGHT.DIŠ",
        "sumerian_transliterations": [r"ussu"],
        "src": SIGN_EIGHT_DI_ASSET.readall(),
    },
    {
        "name": r"ONE.EŠE3",
        "sumerian_transliterations": [r"eše3"],
        "src": SIGN_ONE_E_E3_ASSET.readall(),
    },
    {
        "name": r"TWO.EŠE3",
        "sumerian_transliterations": [r"eše3/eše3"],
        "src": SIGN_TWO_E_E3_ASSET.readall(),
    },
    {
        "name": r"FIVE.U",
        "sumerian_transliterations": [r"ninnu"],
        "src": SIGN_FIVE_U_ASSET.readall(),
    },
]
