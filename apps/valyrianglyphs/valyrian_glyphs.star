"""
Applet: Valyrian Glyphs
Summary: Random High Valyrian glyphs
Description: Display a random glyph and translations from the High Valyrian language, as featured in HBO's Game of Thrones and House of the Dragon.
Author: frame-shift and David J. Peterson
"""

load("animation.star", "animation")
load("images/glyph_a.png", GLYPH_A_ASSET = "file")
load("images/glyph_air.png", GLYPH_AIR_ASSET = "file")
load("images/glyph_amaranth.png", GLYPH_AMARANTH_ASSET = "file")
load("images/glyph_and.png", GLYPH_AND_ASSET = "file")
load("images/glyph_apple.png", GLYPH_APPLE_ASSET = "file")
load("images/glyph_arakh.png", GLYPH_ARAKH_ASSET = "file")
load("images/glyph_area.png", GLYPH_AREA_ASSET = "file")
load("images/glyph_arm.png", GLYPH_ARM_ASSET = "file")
load("images/glyph_arrange.png", GLYPH_ARRANGE_ASSET = "file")
load("images/glyph_arrow.png", GLYPH_ARROW_ASSET = "file")
load("images/glyph_art.png", GLYPH_ART_ASSET = "file")
load("images/glyph_ash.png", GLYPH_ASH_ASSET = "file")
load("images/glyph_ask.png", GLYPH_ASK_ASSET = "file")
load("images/glyph_avoid.png", GLYPH_AVOID_ASSET = "file")
load("images/glyph_awake.png", GLYPH_AWAKE_ASSET = "file")
load("images/glyph_b.png", GLYPH_B_ASSET = "file")
load("images/glyph_back.png", GLYPH_BACK_ASSET = "file")
load("images/glyph_barley.png", GLYPH_BARLEY_ASSET = "file")
load("images/glyph_basket.png", GLYPH_BASKET_ASSET = "file")
load("images/glyph_bat.png", GLYPH_BAT_ASSET = "file")
load("images/glyph_bean.png", GLYPH_BEAN_ASSET = "file")
load("images/glyph_beans.png", GLYPH_BEANS_ASSET = "file")
load("images/glyph_bear.png", GLYPH_BEAR_ASSET = "file")
load("images/glyph_beard.png", GLYPH_BEARD_ASSET = "file")
load("images/glyph_beautiful.png", GLYPH_BEAUTIFUL_ASSET = "file")
load("images/glyph_bed.png", GLYPH_BED_ASSET = "file")
load("images/glyph_bee.png", GLYPH_BEE_ASSET = "file")
load("images/glyph_beet.png", GLYPH_BEET_ASSET = "file")
load("images/glyph_beetle.png", GLYPH_BEETLE_ASSET = "file")
load("images/glyph_big.png", GLYPH_BIG_ASSET = "file")
load("images/glyph_bigbrother.png", GLYPH_BIGBROTHER_ASSET = "file")
load("images/glyph_bigsister.png", GLYPH_BIGSISTER_ASSET = "file")
load("images/glyph_bird.png", GLYPH_BIRD_ASSET = "file")
load("images/glyph_bite.png", GLYPH_BITE_ASSET = "file")
load("images/glyph_bitter.png", GLYPH_BITTER_ASSET = "file")
load("images/glyph_blackberry.png", GLYPH_BLACKBERRY_ASSET = "file")
load("images/glyph_blood.png", GLYPH_BLOOD_ASSET = "file")
load("images/glyph_boar.png", GLYPH_BOAR_ASSET = "file")
load("images/glyph_boat.png", GLYPH_BOAT_ASSET = "file")
load("images/glyph_body.png", GLYPH_BODY_ASSET = "file")
load("images/glyph_bone.png", GLYPH_BONE_ASSET = "file")
load("images/glyph_boot.png", GLYPH_BOOT_ASSET = "file")
load("images/glyph_bound.png", GLYPH_BOUND_ASSET = "file")
load("images/glyph_boy.png", GLYPH_BOY_ASSET = "file")
load("images/glyph_brace.png", GLYPH_BRACE_ASSET = "file")
load("images/glyph_brain.png", GLYPH_BRAIN_ASSET = "file")
load("images/glyph_bread.png", GLYPH_BREAD_ASSET = "file")
load("images/glyph_break.png", GLYPH_BREAK_ASSET = "file")
load("images/glyph_breeze.png", GLYPH_BREEZE_ASSET = "file")
load("images/glyph_bring.png", GLYPH_BRING_ASSET = "file")
load("images/glyph_bull.png", GLYPH_BULL_ASSET = "file")
load("images/glyph_burn.png", GLYPH_BURN_ASSET = "file")
load("images/glyph_burst.png", GLYPH_BURST_ASSET = "file")
load("images/glyph_bury.png", GLYPH_BURY_ASSET = "file")
load("images/glyph_butcher.png", GLYPH_BUTCHER_ASSET = "file")
load("images/glyph_buy.png", GLYPH_BUY_ASSET = "file")
load("images/glyph_canyon.png", GLYPH_CANYON_ASSET = "file")
load("images/glyph_carrot.png", GLYPH_CARROT_ASSET = "file")
load("images/glyph_case.png", GLYPH_CASE_ASSET = "file")
load("images/glyph_cat.png", GLYPH_CAT_ASSET = "file")
load("images/glyph_cedar.png", GLYPH_CEDAR_ASSET = "file")
load("images/glyph_celery.png", GLYPH_CELERY_ASSET = "file")
load("images/glyph_certain.png", GLYPH_CERTAIN_ASSET = "file")
load("images/glyph_chain.png", GLYPH_CHAIN_ASSET = "file")
load("images/glyph_charge.png", GLYPH_CHARGE_ASSET = "file")
load("images/glyph_chase.png", GLYPH_CHASE_ASSET = "file")
load("images/glyph_cherry.png", GLYPH_CHERRY_ASSET = "file")
load("images/glyph_chest.png", GLYPH_CHEST_ASSET = "file")
load("images/glyph_chop.png", GLYPH_CHOP_ASSET = "file")
load("images/glyph_city.png", GLYPH_CITY_ASSET = "file")
load("images/glyph_clay.png", GLYPH_CLAY_ASSET = "file")
load("images/glyph_climb.png", GLYPH_CLIMB_ASSET = "file")
load("images/glyph_closingstrike.png", GLYPH_CLOSINGSTRIKE_ASSET = "file")
load("images/glyph_cloud.png", GLYPH_CLOUD_ASSET = "file")
load("images/glyph_cold.png", GLYPH_COLD_ASSET = "file")
load("images/glyph_come.png", GLYPH_COME_ASSET = "file")
load("images/glyph_control.png", GLYPH_CONTROL_ASSET = "file")
load("images/glyph_cool.png", GLYPH_COOL_ASSET = "file")
load("images/glyph_copper.png", GLYPH_COPPER_ASSET = "file")
load("images/glyph_core.png", GLYPH_CORE_ASSET = "file")
load("images/glyph_crawl.png", GLYPH_CRAWL_ASSET = "file")
load("images/glyph_crooked.png", GLYPH_CROOKED_ASSET = "file")
load("images/glyph_cross.png", GLYPH_CROSS_ASSET = "file")
load("images/glyph_crystal.png", GLYPH_CRYSTAL_ASSET = "file")
load("images/glyph_curve.png", GLYPH_CURVE_ASSET = "file")
load("images/glyph_cyclic.png", GLYPH_CYCLIC_ASSET = "file")
load("images/glyph_d.png", GLYPH_D_ASSET = "file")
load("images/glyph_dadsbigsister.png", GLYPH_DADSBIGSISTER_ASSET = "file")
load("images/glyph_dadslittlesister.png", GLYPH_DADSLITTLESISTER_ASSET = "file")
load("images/glyph_dance.png", GLYPH_DANCE_ASSET = "file")
load("images/glyph_dark.png", GLYPH_DARK_ASSET = "file")
load("images/glyph_dawn.png", GLYPH_DAWN_ASSET = "file")
load("images/glyph_day.png", GLYPH_DAY_ASSET = "file")
load("images/glyph_death.png", GLYPH_DEATH_ASSET = "file")
load("images/glyph_deer.png", GLYPH_DEER_ASSET = "file")
load("images/glyph_defeat.png", GLYPH_DEFEAT_ASSET = "file")
load("images/glyph_dig.png", GLYPH_DIG_ASSET = "file")
load("images/glyph_digit.png", GLYPH_DIGIT_ASSET = "file")
load("images/glyph_dip.png", GLYPH_DIP_ASSET = "file")
load("images/glyph_do.png", GLYPH_DO_ASSET = "file")
load("images/glyph_dog.png", GLYPH_DOG_ASSET = "file")
load("images/glyph_dole.png", GLYPH_DOLE_ASSET = "file")
load("images/glyph_doom.png", GLYPH_DOOM_ASSET = "file")
load("images/glyph_door.png", GLYPH_DOOR_ASSET = "file")
load("images/glyph_doubledot.png", GLYPH_DOUBLEDOT_ASSET = "file")
load("images/glyph_drag.png", GLYPH_DRAG_ASSET = "file")
load("images/glyph_dragon.png", GLYPH_DRAGON_ASSET = "file")
load("images/glyph_dragonfly.png", GLYPH_DRAGONFLY_ASSET = "file")
load("images/glyph_drain.png", GLYPH_DRAIN_ASSET = "file")
load("images/glyph_drakarys.png", GLYPH_DRAKARYS_ASSET = "file")
load("images/glyph_drill.png", GLYPH_DRILL_ASSET = "file")
load("images/glyph_drink.png", GLYPH_DRINK_ASSET = "file")
load("images/glyph_drop.png", GLYPH_DROP_ASSET = "file")
load("images/glyph_drum.png", GLYPH_DRUM_ASSET = "file")
load("images/glyph_dry.png", GLYPH_DRY_ASSET = "file")
load("images/glyph_duck.png", GLYPH_DUCK_ASSET = "file")
load("images/glyph_dull.png", GLYPH_DULL_ASSET = "file")
load("images/glyph_dust.png", GLYPH_DUST_ASSET = "file")
load("images/glyph_e.png", GLYPH_E_ASSET = "file")
load("images/glyph_eagle.png", GLYPH_EAGLE_ASSET = "file")
load("images/glyph_ear.png", GLYPH_EAR_ASSET = "file")
load("images/glyph_earth.png", GLYPH_EARTH_ASSET = "file")
load("images/glyph_eat.png", GLYPH_EAT_ASSET = "file")
load("images/glyph_eel.png", GLYPH_EEL_ASSET = "file")
load("images/glyph_egg.png", GLYPH_EGG_ASSET = "file")
load("images/glyph_eight.png", GLYPH_EIGHT_ASSET = "file")
load("images/glyph_ember.png", GLYPH_EMBER_ASSET = "file")
load("images/glyph_enye.png", GLYPH_ENYE_ASSET = "file")
load("images/glyph_equal.png", GLYPH_EQUAL_ASSET = "file")
load("images/glyph_evil.png", GLYPH_EVIL_ASSET = "file")
load("images/glyph_eye.png", GLYPH_EYE_ASSET = "file")
load("images/glyph_fall.png", GLYPH_FALL_ASSET = "file")
load("images/glyph_father.png", GLYPH_FATHER_ASSET = "file")
load("images/glyph_fear.png", GLYPH_FEAR_ASSET = "file")
load("images/glyph_feather.png", GLYPH_FEATHER_ASSET = "file")
load("images/glyph_fig.png", GLYPH_FIG_ASSET = "file")
load("images/glyph_fight.png", GLYPH_FIGHT_ASSET = "file")
load("images/glyph_fill.png", GLYPH_FILL_ASSET = "file")
load("images/glyph_finish.png", GLYPH_FINISH_ASSET = "file")
load("images/glyph_fire.png", GLYPH_FIRE_ASSET = "file")
load("images/glyph_firstperson.png", GLYPH_FIRSTPERSON_ASSET = "file")
load("images/glyph_fish.png", GLYPH_FISH_ASSET = "file")
load("images/glyph_five.png", GLYPH_FIVE_ASSET = "file")
load("images/glyph_flap.png", GLYPH_FLAP_ASSET = "file")
load("images/glyph_flesh.png", GLYPH_FLESH_ASSET = "file")
load("images/glyph_flow.png", GLYPH_FLOW_ASSET = "file")
load("images/glyph_flower.png", GLYPH_FLOWER_ASSET = "file")
load("images/glyph_fly.png", GLYPH_FLY_ASSET = "file")
load("images/glyph_fold.png", GLYPH_FOLD_ASSET = "file")
load("images/glyph_follow.png", GLYPH_FOLLOW_ASSET = "file")
load("images/glyph_food.png", GLYPH_FOOD_ASSET = "file")
load("images/glyph_foot.png", GLYPH_FOOT_ASSET = "file")
load("images/glyph_forest.png", GLYPH_FOREST_ASSET = "file")
load("images/glyph_four.png", GLYPH_FOUR_ASSET = "file")
load("images/glyph_fox.png", GLYPH_FOX_ASSET = "file")
load("images/glyph_free.png", GLYPH_FREE_ASSET = "file")
load("images/glyph_frog.png", GLYPH_FROG_ASSET = "file")
load("images/glyph_fruit.png", GLYPH_FRUIT_ASSET = "file")
load("images/glyph_furrow.png", GLYPH_FURROW_ASSET = "file")
load("images/glyph_g.png", GLYPH_G_ASSET = "file")
load("images/glyph_garlic.png", GLYPH_GARLIC_ASSET = "file")
load("images/glyph_gate.png", GLYPH_GATE_ASSET = "file")
load("images/glyph_giant.png", GLYPH_GIANT_ASSET = "file")
load("images/glyph_girl.png", GLYPH_GIRL_ASSET = "file")
load("images/glyph_give.png", GLYPH_GIVE_ASSET = "file")
load("images/glyph_glass.png", GLYPH_GLASS_ASSET = "file")
load("images/glyph_go.png", GLYPH_GO_ASSET = "file")
load("images/glyph_goat.png", GLYPH_GOAT_ASSET = "file")
load("images/glyph_god.png", GLYPH_GOD_ASSET = "file")
load("images/glyph_gold.png", GLYPH_GOLD_ASSET = "file")
load("images/glyph_good.png", GLYPH_GOOD_ASSET = "file")
load("images/glyph_grape.png", GLYPH_GRAPE_ASSET = "file")
load("images/glyph_grapes.png", GLYPH_GRAPES_ASSET = "file")
load("images/glyph_grass.png", GLYPH_GRASS_ASSET = "file")
load("images/glyph_great.png", GLYPH_GREAT_ASSET = "file")
load("images/glyph_grind.png", GLYPH_GRIND_ASSET = "file")
load("images/glyph_guard.png", GLYPH_GUARD_ASSET = "file")
load("images/glyph_guess.png", GLYPH_GUESS_ASSET = "file")
load("images/glyph_guest.png", GLYPH_GUEST_ASSET = "file")
load("images/glyph_gull.png", GLYPH_GULL_ASSET = "file")
load("images/glyph_h.png", GLYPH_H_ASSET = "file")
load("images/glyph_hack.png", GLYPH_HACK_ASSET = "file")
load("images/glyph_half.png", GLYPH_HALF_ASSET = "file")
load("images/glyph_hammer.png", GLYPH_HAMMER_ASSET = "file")
load("images/glyph_hand.png", GLYPH_HAND_ASSET = "file")
load("images/glyph_hang.png", GLYPH_HANG_ASSET = "file")
load("images/glyph_have.png", GLYPH_HAVE_ASSET = "file")
load("images/glyph_hazel.png", GLYPH_HAZEL_ASSET = "file")
load("images/glyph_head.png", GLYPH_HEAD_ASSET = "file")
load("images/glyph_healthy.png", GLYPH_HEALTHY_ASSET = "file")
load("images/glyph_heart.png", GLYPH_HEART_ASSET = "file")
load("images/glyph_heavy.png", GLYPH_HEAVY_ASSET = "file")
load("images/glyph_heft.png", GLYPH_HEFT_ASSET = "file")
load("images/glyph_helm.png", GLYPH_HELM_ASSET = "file")
load("images/glyph_help.png", GLYPH_HELP_ASSET = "file")
load("images/glyph_hide.png", GLYPH_HIDE_ASSET = "file")
load("images/glyph_high.png", GLYPH_HIGH_ASSET = "file")
load("images/glyph_hit.png", GLYPH_HIT_ASSET = "file")
load("images/glyph_hold.png", GLYPH_HOLD_ASSET = "file")
load("images/glyph_hole.png", GLYPH_HOLE_ASSET = "file")
load("images/glyph_honey.png", GLYPH_HONEY_ASSET = "file")
load("images/glyph_hook.png", GLYPH_HOOK_ASSET = "file")
load("images/glyph_horse.png", GLYPH_HORSE_ASSET = "file")
load("images/glyph_hot.png", GLYPH_HOT_ASSET = "file")
load("images/glyph_house.png", GLYPH_HOUSE_ASSET = "file")
load("images/glyph_hunger.png", GLYPH_HUNGER_ASSET = "file")
load("images/glyph_hunt.png", GLYPH_HUNT_ASSET = "file")
load("images/glyph_i.png", GLYPH_I_ASSET = "file")
load("images/glyph_ice.png", GLYPH_ICE_ASSET = "file")
load("images/glyph_ignite.png", GLYPH_IGNITE_ASSET = "file")
load("images/glyph_imprint.png", GLYPH_IMPRINT_ASSET = "file")
load("images/glyph_infant.png", GLYPH_INFANT_ASSET = "file")
load("images/glyph_iron.png", GLYPH_IRON_ASSET = "file")
load("images/glyph_island.png", GLYPH_ISLAND_ASSET = "file")
load("images/glyph_it.png", GLYPH_IT_ASSET = "file")
load("images/glyph_ivy.png", GLYPH_IVY_ASSET = "file")
load("images/glyph_j.png", GLYPH_J_ASSET = "file")
load("images/glyph_jasmine.png", GLYPH_JASMINE_ASSET = "file")
load("images/glyph_joyful.png", GLYPH_JOYFUL_ASSET = "file")
load("images/glyph_k.png", GLYPH_K_ASSET = "file")
load("images/glyph_kae.png", GLYPH_KAE_ASSET = "file")
load("images/glyph_keep.png", GLYPH_KEEP_ASSET = "file")
load("images/glyph_kidney.png", GLYPH_KIDNEY_ASSET = "file")
load("images/glyph_kill.png", GLYPH_KILL_ASSET = "file")
load("images/glyph_kiln.png", GLYPH_KILN_ASSET = "file")
load("images/glyph_king.png", GLYPH_KING_ASSET = "file")
load("images/glyph_l.png", GLYPH_L_ASSET = "file")
load("images/glyph_lake.png", GLYPH_LAKE_ASSET = "file")
load("images/glyph_laugh.png", GLYPH_LAUGH_ASSET = "file")
load("images/glyph_lava.png", GLYPH_LAVA_ASSET = "file")
load("images/glyph_lead.png", GLYPH_LEAD_ASSET = "file")
load("images/glyph_leaf.png", GLYPH_LEAF_ASSET = "file")
load("images/glyph_leak.png", GLYPH_LEAK_ASSET = "file")
load("images/glyph_lean.png", GLYPH_LEAN_ASSET = "file")
load("images/glyph_leather.png", GLYPH_LEATHER_ASSET = "file")
load("images/glyph_left.png", GLYPH_LEFT_ASSET = "file")
load("images/glyph_leg.png", GLYPH_LEG_ASSET = "file")
load("images/glyph_lie.png", GLYPH_LIE_ASSET = "file")
load("images/glyph_like.png", GLYPH_LIKE_ASSET = "file")
load("images/glyph_lilac.png", GLYPH_LILAC_ASSET = "file")
load("images/glyph_lime.png", GLYPH_LIME_ASSET = "file")
load("images/glyph_line.png", GLYPH_LINE_ASSET = "file")
load("images/glyph_little.png", GLYPH_LITTLE_ASSET = "file")
load("images/glyph_littlebrother.png", GLYPH_LITTLEBROTHER_ASSET = "file")
load("images/glyph_littlesister.png", GLYPH_LITTLESISTER_ASSET = "file")
load("images/glyph_lizard.png", GLYPH_LIZARD_ASSET = "file")
load("images/glyph_ll.png", GLYPH_LL_ASSET = "file")
load("images/glyph_long.png", GLYPH_LONG_ASSET = "file")
load("images/glyph_low.png", GLYPH_LOW_ASSET = "file")
load("images/glyph_luck.png", GLYPH_LUCK_ASSET = "file")
load("images/glyph_lung.png", GLYPH_LUNG_ASSET = "file")
load("images/glyph_lungwort.png", GLYPH_LUNGWORT_ASSET = "file")
load("images/glyph_m.png", GLYPH_M_ASSET = "file")
load("images/glyph_maegi.png", GLYPH_MAEGI_ASSET = "file")
load("images/glyph_man.png", GLYPH_MAN_ASSET = "file")
load("images/glyph_manage.png", GLYPH_MANAGE_ASSET = "file")
load("images/glyph_many.png", GLYPH_MANY_ASSET = "file")
load("images/glyph_marry.png", GLYPH_MARRY_ASSET = "file")
load("images/glyph_match.png", GLYPH_MATCH_ASSET = "file")
load("images/glyph_meat.png", GLYPH_MEAT_ASSET = "file")
load("images/glyph_meet.png", GLYPH_MEET_ASSET = "file")
load("images/glyph_melt.png", GLYPH_MELT_ASSET = "file")
load("images/glyph_memory.png", GLYPH_MEMORY_ASSET = "file")
load("images/glyph_middot.png", GLYPH_MIDDOT_ASSET = "file")
load("images/glyph_midnight.png", GLYPH_MIDNIGHT_ASSET = "file")
load("images/glyph_milk.png", GLYPH_MILK_ASSET = "file")
load("images/glyph_mint.png", GLYPH_MINT_ASSET = "file")
load("images/glyph_momsbigbrother.png", GLYPH_MOMSBIGBROTHER_ASSET = "file")
load("images/glyph_momslittlebrother.png", GLYPH_MOMSLITTLEBROTHER_ASSET = "file")
load("images/glyph_monkey.png", GLYPH_MONKEY_ASSET = "file")
load("images/glyph_moon.png", GLYPH_MOON_ASSET = "file")
load("images/glyph_mother.png", GLYPH_MOTHER_ASSET = "file")
load("images/glyph_mountain.png", GLYPH_MOUNTAIN_ASSET = "file")
load("images/glyph_mountainrange.png", GLYPH_MOUNTAINRANGE_ASSET = "file")
load("images/glyph_mouth.png", GLYPH_MOUTH_ASSET = "file")
load("images/glyph_move.png", GLYPH_MOVE_ASSET = "file")
load("images/glyph_much.png", GLYPH_MUCH_ASSET = "file")
load("images/glyph_mud.png", GLYPH_MUD_ASSET = "file")
load("images/glyph_mushroom.png", GLYPH_MUSHROOM_ASSET = "file")
load("images/glyph_n.png", GLYPH_N_ASSET = "file")
load("images/glyph_nadir.png", GLYPH_NADIR_ASSET = "file")
load("images/glyph_name.png", GLYPH_NAME_ASSET = "file")
load("images/glyph_narrow.png", GLYPH_NARROW_ASSET = "file")
load("images/glyph_neck.png", GLYPH_NECK_ASSET = "file")
load("images/glyph_night.png", GLYPH_NIGHT_ASSET = "file")
load("images/glyph_nightsky.png", GLYPH_NIGHTSKY_ASSET = "file")
load("images/glyph_nine.png", GLYPH_NINE_ASSET = "file")
load("images/glyph_nn.png", GLYPH_NN_ASSET = "file")
load("images/glyph_nose.png", GLYPH_NOSE_ASSET = "file")
load("images/glyph_not.png", GLYPH_NOT_ASSET = "file")
load("images/glyph_o.png", GLYPH_O_ASSET = "file")
load("images/glyph_obsolete.png", GLYPH_OBSOLETE_ASSET = "file")
load("images/glyph_ocean.png", GLYPH_OCEAN_ASSET = "file")
load("images/glyph_old.png", GLYPH_OLD_ASSET = "file")
load("images/glyph_oldeat.png", GLYPH_OLDEAT_ASSET = "file")
load("images/glyph_oleander.png", GLYPH_OLEANDER_ASSET = "file")
load("images/glyph_olive.png", GLYPH_OLIVE_ASSET = "file")
load("images/glyph_one.png", GLYPH_ONE_ASSET = "file")
load("images/glyph_openingstrike.png", GLYPH_OPENINGSTRIKE_ASSET = "file")
load("images/glyph_orchid.png", GLYPH_ORCHID_ASSET = "file")
load("images/glyph_other.png", GLYPH_OTHER_ASSET = "file")
load("images/glyph_owl.png", GLYPH_OWL_ASSET = "file")
load("images/glyph_p.png", GLYPH_P_ASSET = "file")
load("images/glyph_palm.png", GLYPH_PALM_ASSET = "file")
load("images/glyph_path.png", GLYPH_PATH_ASSET = "file")
load("images/glyph_peel.png", GLYPH_PEEL_ASSET = "file")
load("images/glyph_pelican.png", GLYPH_PELICAN_ASSET = "file")
load("images/glyph_pile.png", GLYPH_PILE_ASSET = "file")
load("images/glyph_pillar.png", GLYPH_PILLAR_ASSET = "file")
load("images/glyph_plan.png", GLYPH_PLAN_ASSET = "file")
load("images/glyph_planet.png", GLYPH_PLANET_ASSET = "file")
load("images/glyph_play.png", GLYPH_PLAY_ASSET = "file")
load("images/glyph_pluck.png", GLYPH_PLUCK_ASSET = "file")
load("images/glyph_poke.png", GLYPH_POKE_ASSET = "file")
load("images/glyph_pomegranate.png", GLYPH_POMEGRANATE_ASSET = "file")
load("images/glyph_poppy.png", GLYPH_POPPY_ASSET = "file")
load("images/glyph_pot.png", GLYPH_POT_ASSET = "file")
load("images/glyph_pound.png", GLYPH_POUND_ASSET = "file")
load("images/glyph_pour.png", GLYPH_POUR_ASSET = "file")
load("images/glyph_power.png", GLYPH_POWER_ASSET = "file")
load("images/glyph_praise.png", GLYPH_PRAISE_ASSET = "file")
load("images/glyph_press.png", GLYPH_PRESS_ASSET = "file")
load("images/glyph_pretty.png", GLYPH_PRETTY_ASSET = "file")
load("images/glyph_priest.png", GLYPH_PRIEST_ASSET = "file")
load("images/glyph_prop.png", GLYPH_PROP_ASSET = "file")
load("images/glyph_protrude.png", GLYPH_PROTRUDE_ASSET = "file")
load("images/glyph_pull.png", GLYPH_PULL_ASSET = "file")
load("images/glyph_pure.png", GLYPH_PURE_ASSET = "file")
load("images/glyph_push.png", GLYPH_PUSH_ASSET = "file")
load("images/glyph_put.png", GLYPH_PUT_ASSET = "file")
load("images/glyph_q.png", GLYPH_Q_ASSET = "file")
load("images/glyph_r.png", GLYPH_R_ASSET = "file")
load("images/glyph_rabbit.png", GLYPH_RABBIT_ASSET = "file")
load("images/glyph_rain.png", GLYPH_RAIN_ASSET = "file")
load("images/glyph_ram.png", GLYPH_RAM_ASSET = "file")
load("images/glyph_raven.png", GLYPH_RAVEN_ASSET = "file")
load("images/glyph_rh.png", GLYPH_RH_ASSET = "file")
load("images/glyph_rice.png", GLYPH_RICE_ASSET = "file")
load("images/glyph_ride.png", GLYPH_RIDE_ASSET = "file")
load("images/glyph_rip.png", GLYPH_RIP_ASSET = "file")
load("images/glyph_rise.png", GLYPH_RISE_ASSET = "file")
load("images/glyph_river.png", GLYPH_RIVER_ASSET = "file")
load("images/glyph_roll.png", GLYPH_ROLL_ASSET = "file")
load("images/glyph_rooster.png", GLYPH_ROOSTER_ASSET = "file")
load("images/glyph_rope.png", GLYPH_ROPE_ASSET = "file")
load("images/glyph_rose.png", GLYPH_ROSE_ASSET = "file")
load("images/glyph_rot.png", GLYPH_ROT_ASSET = "file")
load("images/glyph_rough.png", GLYPH_ROUGH_ASSET = "file")
load("images/glyph_rr.png", GLYPH_RR_ASSET = "file")
load("images/glyph_rub.png", GLYPH_RUB_ASSET = "file")
load("images/glyph_run.png", GLYPH_RUN_ASSET = "file")
load("images/glyph_s.png", GLYPH_S_ASSET = "file")
load("images/glyph_safe.png", GLYPH_SAFE_ASSET = "file")
load("images/glyph_salt.png", GLYPH_SALT_ASSET = "file")
load("images/glyph_sambucus.png", GLYPH_SAMBUCUS_ASSET = "file")
load("images/glyph_same.png", GLYPH_SAME_ASSET = "file")
load("images/glyph_sand.png", GLYPH_SAND_ASSET = "file")
load("images/glyph_scalp.png", GLYPH_SCALP_ASSET = "file")
load("images/glyph_scorpion.png", GLYPH_SCORPION_ASSET = "file")
load("images/glyph_scrape.png", GLYPH_SCRAPE_ASSET = "file")
load("images/glyph_scratch.png", GLYPH_SCRATCH_ASSET = "file")
load("images/glyph_scream.png", GLYPH_SCREAM_ASSET = "file")
load("images/glyph_screech.png", GLYPH_SCREECH_ASSET = "file")
load("images/glyph_seed.png", GLYPH_SEED_ASSET = "file")
load("images/glyph_sell.png", GLYPH_SELL_ASSET = "file")
load("images/glyph_sense.png", GLYPH_SENSE_ASSET = "file")
load("images/glyph_separate.png", GLYPH_SEPARATE_ASSET = "file")
load("images/glyph_serve.png", GLYPH_SERVE_ASSET = "file")
load("images/glyph_seven.png", GLYPH_SEVEN_ASSET = "file")
load("images/glyph_sew.png", GLYPH_SEW_ASSET = "file")
load("images/glyph_sharp.png", GLYPH_SHARP_ASSET = "file")
load("images/glyph_she.png", GLYPH_SHE_ASSET = "file")
load("images/glyph_sheep.png", GLYPH_SHEEP_ASSET = "file")
load("images/glyph_shield.png", GLYPH_SHIELD_ASSET = "file")
load("images/glyph_short.png", GLYPH_SHORT_ASSET = "file")
load("images/glyph_shoulder.png", GLYPH_SHOULDER_ASSET = "file")
load("images/glyph_shove.png", GLYPH_SHOVE_ASSET = "file")
load("images/glyph_show.png", GLYPH_SHOW_ASSET = "file")
load("images/glyph_sibling.png", GLYPH_SIBLING_ASSET = "file")
load("images/glyph_silk.png", GLYPH_SILK_ASSET = "file")
load("images/glyph_silver.png", GLYPH_SILVER_ASSET = "file")
load("images/glyph_sing.png", GLYPH_SING_ASSET = "file")
load("images/glyph_sit.png", GLYPH_SIT_ASSET = "file")
load("images/glyph_six.png", GLYPH_SIX_ASSET = "file")
load("images/glyph_sleep.png", GLYPH_SLEEP_ASSET = "file")
load("images/glyph_slow.png", GLYPH_SLOW_ASSET = "file")
load("images/glyph_smile.png", GLYPH_SMILE_ASSET = "file")
load("images/glyph_smoke.png", GLYPH_SMOKE_ASSET = "file")
load("images/glyph_snout.png", GLYPH_SNOUT_ASSET = "file")
load("images/glyph_snow.png", GLYPH_SNOW_ASSET = "file")
load("images/glyph_soil.png", GLYPH_SOIL_ASSET = "file")
load("images/glyph_solid.png", GLYPH_SOLID_ASSET = "file")
load("images/glyph_sour.png", GLYPH_SOUR_ASSET = "file")
load("images/glyph_sparrow.png", GLYPH_SPARROW_ASSET = "file")
load("images/glyph_speak.png", GLYPH_SPEAK_ASSET = "file")
load("images/glyph_spider.png", GLYPH_SPIDER_ASSET = "file")
load("images/glyph_spring.png", GLYPH_SPRING_ASSET = "file")
load("images/glyph_squid.png", GLYPH_SQUID_ASSET = "file")
load("images/glyph_squirrel.png", GLYPH_SQUIRREL_ASSET = "file")
load("images/glyph_ss.png", GLYPH_SS_ASSET = "file")
load("images/glyph_stand.png", GLYPH_STAND_ASSET = "file")
load("images/glyph_star.png", GLYPH_STAR_ASSET = "file")
load("images/glyph_steer.png", GLYPH_STEER_ASSET = "file")
load("images/glyph_stomach.png", GLYPH_STOMACH_ASSET = "file")
load("images/glyph_stone.png", GLYPH_STONE_ASSET = "file")
load("images/glyph_storm.png", GLYPH_STORM_ASSET = "file")
load("images/glyph_strawberry.png", GLYPH_STRAWBERRY_ASSET = "file")
load("images/glyph_stretch.png", GLYPH_STRETCH_ASSET = "file")
load("images/glyph_struggle.png", GLYPH_STRUGGLE_ASSET = "file")
load("images/glyph_stuck.png", GLYPH_STUCK_ASSET = "file")
load("images/glyph_suckle.png", GLYPH_SUCKLE_ASSET = "file")
load("images/glyph_summer.png", GLYPH_SUMMER_ASSET = "file")
load("images/glyph_sun.png", GLYPH_SUN_ASSET = "file")
load("images/glyph_sunrise.png", GLYPH_SUNRISE_ASSET = "file")
load("images/glyph_sunset.png", GLYPH_SUNSET_ASSET = "file")
load("images/glyph_swap.png", GLYPH_SWAP_ASSET = "file")
load("images/glyph_sweet.png", GLYPH_SWEET_ASSET = "file")
load("images/glyph_swell.png", GLYPH_SWELL_ASSET = "file")
load("images/glyph_swim.png", GLYPH_SWIM_ASSET = "file")
load("images/glyph_t.png", GLYPH_T_ASSET = "file")
load("images/glyph_table.png", GLYPH_TABLE_ASSET = "file")
load("images/glyph_tail.png", GLYPH_TAIL_ASSET = "file")
load("images/glyph_targaryen.png", GLYPH_TARGARYEN_ASSET = "file")
load("images/glyph_tea.png", GLYPH_TEA_ASSET = "file")
load("images/glyph_tear.png", GLYPH_TEAR_ASSET = "file")
load("images/glyph_they.png", GLYPH_THEY_ASSET = "file")
load("images/glyph_thick.png", GLYPH_THICK_ASSET = "file")
load("images/glyph_thigh.png", GLYPH_THIGH_ASSET = "file")
load("images/glyph_thin.png", GLYPH_THIN_ASSET = "file")
load("images/glyph_thing.png", GLYPH_THING_ASSET = "file")
load("images/glyph_three.png", GLYPH_THREE_ASSET = "file")
load("images/glyph_through.png", GLYPH_THROUGH_ASSET = "file")
load("images/glyph_throw.png", GLYPH_THROW_ASSET = "file")
load("images/glyph_toil.png", GLYPH_TOIL_ASSET = "file")
load("images/glyph_tongue.png", GLYPH_TONGUE_ASSET = "file")
load("images/glyph_tooth.png", GLYPH_TOOTH_ASSET = "file")
load("images/glyph_top.png", GLYPH_TOP_ASSET = "file")
load("images/glyph_touch.png", GLYPH_TOUCH_ASSET = "file")
load("images/glyph_tree.png", GLYPH_TREE_ASSET = "file")
load("images/glyph_trout.png", GLYPH_TROUT_ASSET = "file")
load("images/glyph_true.png", GLYPH_TRUE_ASSET = "file")
load("images/glyph_ts.png", GLYPH_TS_ASSET = "file")
load("images/glyph_tt.png", GLYPH_TT_ASSET = "file")
load("images/glyph_turn.png", GLYPH_TURN_ASSET = "file")
load("images/glyph_turtle.png", GLYPH_TURTLE_ASSET = "file")
load("images/glyph_two.png", GLYPH_TWO_ASSET = "file")
load("images/glyph_type.png", GLYPH_TYPE_ASSET = "file")
load("images/glyph_tyrant.png", GLYPH_TYRANT_ASSET = "file")
load("images/glyph_tys.png", GLYPH_TYS_ASSET = "file")
load("images/glyph_u.png", GLYPH_U_ASSET = "file")
load("images/glyph_uproot.png", GLYPH_UPROOT_ASSET = "file")
load("images/glyph_v.png", GLYPH_V_ASSET = "file")
load("images/glyph_valyria.png", GLYPH_VALYRIA_ASSET = "file")
load("images/glyph_vapor.png", GLYPH_VAPOR_ASSET = "file")
load("images/glyph_veil.png", GLYPH_VEIL_ASSET = "file")
load("images/glyph_velaryon.png", GLYPH_VELARYON_ASSET = "file")
load("images/glyph_violet.png", GLYPH_VIOLET_ASSET = "file")
load("images/glyph_warm.png", GLYPH_WARM_ASSET = "file")
load("images/glyph_warn.png", GLYPH_WARN_ASSET = "file")
load("images/glyph_water.png", GLYPH_WATER_ASSET = "file")
load("images/glyph_waterowl.png", GLYPH_WATEROWL_ASSET = "file")
load("images/glyph_wave.png", GLYPH_WAVE_ASSET = "file")
load("images/glyph_we.png", GLYPH_WE_ASSET = "file")
load("images/glyph_wet.png", GLYPH_WET_ASSET = "file")
load("images/glyph_whale.png", GLYPH_WHALE_ASSET = "file")
load("images/glyph_what.png", GLYPH_WHAT_ASSET = "file")
load("images/glyph_wheel.png", GLYPH_WHEEL_ASSET = "file")
load("images/glyph_whip.png", GLYPH_WHIP_ASSET = "file")
load("images/glyph_whirl.png", GLYPH_WHIRL_ASSET = "file")
load("images/glyph_whole.png", GLYPH_WHOLE_ASSET = "file")
load("images/glyph_wide.png", GLYPH_WIDE_ASSET = "file")
load("images/glyph_wilt.png", GLYPH_WILT_ASSET = "file")
load("images/glyph_wind.png", GLYPH_WIND_ASSET = "file")
load("images/glyph_wipe.png", GLYPH_WIPE_ASSET = "file")
load("images/glyph_wolf.png", GLYPH_WOLF_ASSET = "file")
load("images/glyph_woman.png", GLYPH_WOMAN_ASSET = "file")
load("images/glyph_wood.png", GLYPH_WOOD_ASSET = "file")
load("images/glyph_word.png", GLYPH_WORD_ASSET = "file")
load("images/glyph_worm.png", GLYPH_WORM_ASSET = "file")
load("images/glyph_write.png", GLYPH_WRITE_ASSET = "file")
load("images/glyph_x.png", GLYPH_X_ASSET = "file")
load("images/glyph_y.png", GLYPH_Y_ASSET = "file")
load("images/glyph_young.png", GLYPH_YOUNG_ASSET = "file")
load("images/glyph_z.png", GLYPH_Z_ASSET = "file")
load("images/glyph_zero.png", GLYPH_ZERO_ASSET = "file")
load("images/glyph_zr.png", GLYPH_ZR_ASSET = "file")
load("random.star", "random")
load("render.star", "render")

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
    ["a", "\u0101", "glyph for long a", "", "", GLYPH_A_ASSET.readall()],
    ["air", "paghar", "air", "breath", "", GLYPH_AIR_ASSET.readall()],
    ["air2", "paghagon", "to breathe", "to inhale", "", GLYPH_AIR_ASSET.readall()],
    ["amaranth", "olzon", "amaranth", "", "", GLYPH_AMARANTH_ASSET.readall()],
    ["and", "selagon", "to agree", "to head for", "to make for", GLYPH_AND_ASSET.readall()],
    ["and2", "se", "and", "", "", GLYPH_AND_ASSET.readall()],
    ["apple", "pr\u016Bbres", "apple", "", "", GLYPH_APPLE_ASSET.readall()],
    ["arakh", "arakhi", "arakh", "(Dothraki", "borrowing)", GLYPH_ARAKH_ASSET.readall()],
    ["area", "\u0101lion", "area", "place", "location", GLYPH_AREA_ASSET.readall()],
    ["arm", "\u00F1\u014Dghe", "arm", "", "", GLYPH_ARM_ASSET.readall()],
    ["arrange", "verdagon", "to arrange", "to order", "to deal in", GLYPH_ARRANGE_ASSET.readall()],
    ["arrow", "p\u0113je", "arrow", "", "", GLYPH_ARROW_ASSET.readall()],
    ["art", "\u0177s", "art", "", "", GLYPH_ART_ASSET.readall()],
    ["ash", "\u00F1uqir", "ash", "ashes", "", GLYPH_ASH_ASSET.readall()],
    ["ask", "epagon", "to ask", "to inquire", "to query", GLYPH_ASK_ASSET.readall()],
    ["avoid", "kulogon", "to avoid", "to dodge", "to go around", GLYPH_AVOID_ASSET.readall()],
    ["awake", "kiragon", "to be awake", "to be up", "", GLYPH_AWAKE_ASSET.readall()],
    ["b", "b", "glyph for b", "", "", GLYPH_B_ASSET.readall()],
    ["back", "inkon", "back", "back side", "", GLYPH_BACK_ASSET.readall()],
    ["back2", "ampa", "ten (10)", "", "", GLYPH_BACK_ASSET.readall()],
    ["barley", "\u0101ro", "barley", "", "", GLYPH_BARLEY_ASSET.readall()],
    ["basket", "g\u016Bron", "basket", "", "", GLYPH_BASKET_ASSET.readall()],
    ["bat", "massa", "bat", "", "", GLYPH_BAT_ASSET.readall()],
    ["bean", "l\u0101gho", "bean", "", "", GLYPH_BEAN_ASSET.readall()],
    ["beans", "l\u0101ghor", "beans", "", "", GLYPH_BEANS_ASSET.readall()],
    ["bear", "gryves", "bear", "", "", GLYPH_BEAR_ASSET.readall()],
    ["beard", "rhotton", "beard", "", "", GLYPH_BEARD_ASSET.readall()],
    ["beautiful", "gevie", "beautiful", "", "", GLYPH_BEAUTIFUL_ASSET.readall()],
    ["bed", "ilvos", "bed", "", "", GLYPH_BED_ASSET.readall()],
    ["bee", "\u0113s", "bee", "", "", GLYPH_BEE_ASSET.readall()],
    ["beet", "kr\u0113go", "beet", "", "", GLYPH_BEET_ASSET.readall()],
    ["beetle", "heltar", "beetle", "", "", GLYPH_BEETLE_ASSET.readall()],
    ["big", "r\u014Dva", "big", "large", "", GLYPH_BIG_ASSET.readall()],
    ["bigbrother", "l\u0113kia", "older", "brother", "", GLYPH_BIGBROTHER_ASSET.readall()],
    ["bigsister", "mandia", "older", "sister", "", GLYPH_BIGSISTER_ASSET.readall()],
    ["bird", "ao", "you (singular)", "", "", GLYPH_BIRD_ASSET.readall()],
    ["bird2", "hontes", "bird", "", "", GLYPH_BIRD_ASSET.readall()],
    ["bite", "angogon", "to bite", "", "", GLYPH_BITE_ASSET.readall()],
    ["bitter", "geba", "bitter", "acrid", "", GLYPH_BITTER_ASSET.readall()],
    ["blackberry", "vusko", "blackberry", "", "", GLYPH_BLACKBERRY_ASSET.readall()],
    ["blood", "\u0101nogar", "blood", "", "", GLYPH_BLOOD_ASSET.readall()],
    ["boar", "qryldes", "boar", "pig (m)", "", GLYPH_BOAR_ASSET.readall()],
    ["boar2", "beqes", "pig (f)", "", "", GLYPH_BOAR_ASSET.readall()],
    ["boat", "l\u014Dgor", "boat", "ship", "", GLYPH_BOAT_ASSET.readall()],
    ["body", "m\u0113ny", "body", "", "", GLYPH_BODY_ASSET.readall()],
    ["bone", "\u012Bby", "bone", "", "", GLYPH_BONE_ASSET.readall()],
    ["boot", "landis", "shoe", "boot", "", GLYPH_BOOT_ASSET.readall()],
    ["bound", "pyghagon", "to jump", "to leap", "to bounce", GLYPH_BOUND_ASSET.readall()],
    ["boy", "taoba", "boy", "", "", GLYPH_BOY_ASSET.readall()],
    ["boy2", "tr\u0113sy", "son", "parallel nephew", "", GLYPH_BOY_ASSET.readall()],
    ["brace", "aena", "supportive", "reliable", "", GLYPH_BRACE_ASSET.readall()],
    ["brain", "\u00F1aka", "brain", "", "", GLYPH_BRAIN_ASSET.readall()],
    ["bread", "havon", "bread", "", "", GLYPH_BREAD_ASSET.readall()],
    ["break", "pryjagon", "to destroy", "to ruin", "to break", GLYPH_BREAK_ASSET.readall()],
    ["breeze", "pisti", "breeze", "", "", GLYPH_BREEZE_ASSET.readall()],
    ["bring", "maghagon", "to bring", "to carry", "", GLYPH_BRING_ASSET.readall()],
    ["bull", "vandis", "bull", "cow (m)", "", GLYPH_BULL_ASSET.readall()],
    ["bull2", "nuspes", "cow (f)", "", "", GLYPH_BULL_ASSET.readall()],
    ["burn", "z\u0101lagon", "to burn", "", "", GLYPH_BURN_ASSET.readall()],
    ["burst", "biragon", "to burst", "to explode", "to break", GLYPH_BURST_ASSET.readall()],
    ["bury", "tojagon", "to bury", "", "", GLYPH_BURY_ASSET.readall()],
    ["butcher", "heghagon", "to slaughter", "", "", GLYPH_BUTCHER_ASSET.readall()],
    ["buy", "sindigon", "to buy", "to purchase", "", GLYPH_BUY_ASSET.readall()],
    ["canyon", "rios", "valley", "canyon", "", GLYPH_CANYON_ASSET.readall()],
    ["carrot", "onjapos", "carrot", "", "", GLYPH_CARROT_ASSET.readall()],
    ["case", "pragron", "case", "shell", "husk", GLYPH_CASE_ASSET.readall()],
    ["cat", "k\u0113li", "cat", "kitty", "", GLYPH_CAT_ASSET.readall()],
    ["cedar", "uela", "cedar", "", "", GLYPH_CEDAR_ASSET.readall()],
    ["celery", "n\u014Dro", "celery", "celery stalk", "", GLYPH_CELERY_ASSET.readall()],
    ["certain", "s\u012Blie", "certain", "absolute", "definite", GLYPH_CERTAIN_ASSET.readall()],
    ["chain", "belmon", "chain", "", "", GLYPH_CHAIN_ASSET.readall()],
    ["charge", "gaemagon", "to charge", "to rush", "", GLYPH_CHARGE_ASSET.readall()],
    ["chase", "daenagon", "to pursue", "to chase", "", GLYPH_CHASE_ASSET.readall()],
    ["cherry", "jerde", "cherry", "", "", GLYPH_CHERRY_ASSET.readall()],
    ["chest", "naejos", "chest", "pectorals", "breast", GLYPH_CHEST_ASSET.readall()],
    ["chop", "jukagon", "to cleave", "to chop", "", GLYPH_CHOP_ASSET.readall()],
    ["city", "oktion", "city", "", "", GLYPH_CITY_ASSET.readall()],
    ["clay", "indor", "clay", "", "", GLYPH_CLAY_ASSET.readall()],
    ["climb", "hepagon", "to climb", "to ascend", "", GLYPH_CLIMB_ASSET.readall()],
    ["closingstrike", ")", "equivalent", "to a closed", "parenthesis", GLYPH_CLOSINGSTRIKE_ASSET.readall()],
    ["cloud", "sambar", "cloud", "", "", GLYPH_CLOUD_ASSET.readall()],
    ["cold", "iosre", "cold", "(to the touch)", "", GLYPH_COLD_ASSET.readall()],
    ["come", "m\u0101zigon", "to come", "to arrive", "", GLYPH_COME_ASSET.readall()],
    ["control", "visagon", "to control", "to manage", "to handle", GLYPH_CONTROL_ASSET.readall()],
    ["cool", "qapa", "cold", "(internally)", "", GLYPH_COOL_ASSET.readall()],
    ["copper", "br\u0101edy", "bell", "", "", GLYPH_COPPER_ASSET.readall()],
    ["core", "ripo", "core", "pit", "", GLYPH_CORE_ASSET.readall()],
    ["crawl", "tyvagon", "to crawl", "to creep", "", GLYPH_CRAWL_ASSET.readall()],
    ["crooked", "onga", "crooked", "gnarled", "wrinkled", GLYPH_CROOKED_ASSET.readall()],
    ["cross", "\u012Bligon", "to cross", "to retread", "", GLYPH_CROSS_ASSET.readall()],
    ["crystal", "z\u0101eres", "crystal", "gem", "", GLYPH_CRYSTAL_ASSET.readall()],
    ["curve", "oba", "curved", "arched", "convex", GLYPH_CURVE_ASSET.readall()],
    ["curve2", "obagon", "to curve", "to bow", "to bend", GLYPH_CURVE_ASSET.readall()],
    ["cyclic", "are", "cyclic", "rhythmic", "repetitive", GLYPH_CYCLIC_ASSET.readall()],
    ["d", "d", "glyph for d", "", "", GLYPH_D_ASSET.readall()],
    ["dadsbigsister", "velma", "father's", "older", "sister", GLYPH_DADSBIGSISTER_ASSET.readall()],
    ["dadslittlesister", "\u00F1\u0101mar", "father's", "younger", "sister", GLYPH_DADSLITTLESISTER_ASSET.readall()],
    ["dance", "lilagon", "to dance", "", "", GLYPH_DANCE_ASSET.readall()],
    ["dark", "zomir", "darkness", "", "", GLYPH_DARK_ASSET.readall()],
    ["dawn", "\u014Dz", "dawn", "", "", GLYPH_DAWN_ASSET.readall()],
    ["day", "tubis", "day", "", "", GLYPH_DAY_ASSET.readall()],
    ["death", "morghon", "death", "", "", GLYPH_DEATH_ASSET.readall()],
    ["deer", "myrdys", "doe", "deer (f)", "", GLYPH_DEER_ASSET.readall()],
    ["deer2", "velkrys", "stag", "deer (m)", "", GLYPH_DEER_ASSET.readall()],
    ["defeat", "\u0113rinagon", "to defeat", "to conquer", "to vanquish", GLYPH_DEFEAT_ASSET.readall()],
    ["dig", "rudigon", "to dig", "", "", GLYPH_DIG_ASSET.readall()],
    ["digit", "t\u0101emis", "digit", "finger", "toe", GLYPH_DIGIT_ASSET.readall()],
    ["dip", "iovagon", "to dip", "to dunk", "to submerge", GLYPH_DIP_ASSET.readall()],
    ["do", "gaomagon", "to do", "to act", "to perform", GLYPH_DO_ASSET.readall()],
    ["dog", "jaos", "dog", "", "", GLYPH_DOG_ASSET.readall()],
    ["dole", "tyragon", "to distribute", "to share", "to dole out", GLYPH_DOLE_ASSET.readall()],
    ["doom", "v\u0113jes", "doom", "fate", "", GLYPH_DOOM_ASSET.readall()],
    ["door", "nerny", "door", "mouth of a cave", "", GLYPH_DOOR_ASSET.readall()],
    ["doubledot", ":", "punctuation", "used to separate", "clauses", GLYPH_DOUBLEDOT_ASSET.readall()],
    ["drag", "ql\u0101dugon", "to drag", "", "", GLYPH_DRAG_ASSET.readall()],
    ["dragon", "zaldr\u012Bzes", "dragon", "", "", GLYPH_DRAGON_ASSET.readall()],
    ["dragonfly", "r\u0177z", "dragonfly", "", "", GLYPH_DRAGONFLY_ASSET.readall()],
    ["drain", "qeragon", "to drain", "to empty", "to dissolve", GLYPH_DRAIN_ASSET.readall()],
    ["drakarys", "drakarys", "dragonfire", "", "", GLYPH_DRAKARYS_ASSET.readall()],
    ["drill", "l\u014Dry", "drill", "hand drill", "", GLYPH_DRILL_ASSET.readall()],
    ["drill2", "l\u014Dragon", "to drill", "to bore", "", GLYPH_DRILL_ASSET.readall()],
    ["drink", "m\u014Dzugon", "to drink", "", "", GLYPH_DRINK_ASSET.readall()],
    ["drop", "rughagon", "to drop", "", "", GLYPH_DROP_ASSET.readall()],
    ["drum", "meme", "drum", "", "", GLYPH_DRUM_ASSET.readall()],
    ["dry", "tista", "dry", "", "", GLYPH_DRY_ASSET.readall()],
    ["duck", "ezar", "duck", "", "", GLYPH_DUCK_ASSET.readall()],
    ["dull", "ruaka", "dull", "ineffective", "", GLYPH_DULL_ASSET.readall()],
    ["dust", "jeson", "dust", "powder", "", GLYPH_DUST_ASSET.readall()],
    ["e", "\u0113", "glyph for long e", "", "", GLYPH_E_ASSET.readall()],
    ["eagle", "z\u0113res", "eagle", "", "", GLYPH_EAGLE_ASSET.readall()],
    ["ear", "eleks", "ear", "", "", GLYPH_EAR_ASSET.readall()],
    ["earth", "tegon", "ground", "earth", "soil", GLYPH_EARTH_ASSET.readall()],
    ["eat", "kis-", "used with", "words for", "eating", GLYPH_EAT_ASSET.readall()],
    ["eel", "ubles", "eel", "", "", GLYPH_EEL_ASSET.readall()],
    ["egg", "dr\u014Dmon", "egg", "", "", GLYPH_EGG_ASSET.readall()],
    ["eight", "j\u0113nqa", "eight (8)", "", "", GLYPH_EIGHT_ASSET.readall()],
    ["ember", "jehys", "ember", "glowing coal", "", GLYPH_EMBER_ASSET.readall()],
    ["enye", "\u00F1", "glyph for \u00F1", "", "", GLYPH_ENYE_ASSET.readall()],
    ["equal", "g\u012Bda", "equal", "steady", "stable", GLYPH_EQUAL_ASSET.readall()],
    ["evil", "k\u014Dz", "bad", "evil", "wicked", GLYPH_EVIL_ASSET.readall()],
    ["eye", "laes", "eye", "", "", GLYPH_EYE_ASSET.readall()],
    ["fall", "ropagon", "to fall", "", "", GLYPH_FALL_ASSET.readall()],
    ["father", "kepa", "father", "dad", "paternal uncle", GLYPH_FATHER_ASSET.readall()],
    ["fear", "z\u016Bgagon", "to fear", "to be afraid", "", GLYPH_FEAR_ASSET.readall()],
    ["feather", "t\u012Bkos", "feather", "", "", GLYPH_FEATHER_ASSET.readall()],
    ["fig", "r\u014Dbir", "fig", "", "", GLYPH_FIG_ASSET.readall()],
    ["fight", "azandy", "short sword", "", "", GLYPH_FIGHT_ASSET.readall()],
    ["fill", "leghagon", "to fill", "", "", GLYPH_FILL_ASSET.readall()],
    ["finish", "tatagon", "to finish", "", "", GLYPH_FINISH_ASSET.readall()],
    ["fire", "perzys", "fire", "", "", GLYPH_FIRE_ASSET.readall()],
    ["firstperson", "nyke", "I (pronoun)", "", "", GLYPH_FIRSTPERSON_ASSET.readall()],
    ["fish", "klios", "fish", "", "", GLYPH_FISH_ASSET.readall()],
    ["fish2", "adere", "quick", "smooth", "slippery", GLYPH_FISH_ASSET.readall()],
    ["five", "t\u014Dma", "five (5)", "", "", GLYPH_FIVE_ASSET.readall()],
    ["flap", "lytagon", "to flap", "", "", GLYPH_FLAP_ASSET.readall()],
    ["flesh", "\u00F1elly", "skin", "flesh", "", GLYPH_FLESH_ASSET.readall()],
    ["flow", "i\u0101ragon", "to flow", "to run", "to go", GLYPH_FLOW_ASSET.readall()],
    ["flower", "r\u016Bklon", "flower", "", "", GLYPH_FLOWER_ASSET.readall()],
    ["fly", "s\u014Dvion", "butterfly", "", "", GLYPH_FLY_ASSET.readall()],
    ["fold", "lurugon", "to fold", "", "", GLYPH_FOLD_ASSET.readall()],
    ["follow", "pikagon", "to follow", "", "", GLYPH_FOLLOW_ASSET.readall()],
    ["food", "havor", "food", "sustenance", "", GLYPH_FOOD_ASSET.readall()],
    ["foot", "deks", "foot", "step", "", GLYPH_FOOT_ASSET.readall()],
    ["forest", "gu\u0113sin", "forest", "woods", "", GLYPH_FOREST_ASSET.readall()],
    ["four", "arlie", "new", "", "", GLYPH_FOUR_ASSET.readall()],
    ["four2", "izula", "four (4)", "", "", GLYPH_FOUR_ASSET.readall()],
    ["fox", "lanty", "fox", "", "", GLYPH_FOX_ASSET.readall()],
    ["free", "d\u0101ez", "free", "", "", GLYPH_FREE_ASSET.readall()],
    ["frog", "reks", "frog", "", "", GLYPH_FROG_ASSET.readall()],
    ["fruit", "gerpa", "fruit", "", "", GLYPH_FRUIT_ASSET.readall()],
    ["furrow", "grozagon", "to plow", "", "", GLYPH_FURROW_ASSET.readall()],
    ["g", "g", "glyph for g", "", "", GLYPH_G_ASSET.readall()],
    ["garlic", "zubon", "garlic", "", "", GLYPH_GARLIC_ASSET.readall()],
    ["gate", "remio", "gate", "city gate", "", GLYPH_GATE_ASSET.readall()],
    ["giant", "labar", "giant", "", "", GLYPH_GIANT_ASSET.readall()],
    ["girl", "ri\u00F1a", "girl", "child", "", GLYPH_GIRL_ASSET.readall()],
    ["girl2", "tala", "daughter", "parallel niece", "", GLYPH_GIRL_ASSET.readall()],
    ["give", "tepagon", "to give", "", "", GLYPH_GIVE_ASSET.readall()],
    ["glass", "jenys", "glass", "", "", GLYPH_GLASS_ASSET.readall()],
    ["go", "jagon", "to go", "", "", GLYPH_GO_ASSET.readall()],
    ["goat", "hobres", "goat (m)", "jerk", "", GLYPH_GOAT_ASSET.readall()],
    ["goat2", "epses", "goat (f)", "", "", GLYPH_GOAT_ASSET.readall()],
    ["god", "jaes", "god", "deity", "", GLYPH_GOD_ASSET.readall()],
    ["gold", "\u0101eksion", "gold", "", "", GLYPH_GOLD_ASSET.readall()],
    ["good", "s\u0177z", "good", "", "", GLYPH_GOOD_ASSET.readall()],
    ["grape", "avero", "grape", "", "", GLYPH_GRAPE_ASSET.readall()],
    ["grapes", "averun", "bunch", "of", "grapes", GLYPH_GRAPES_ASSET.readall()],
    ["grass", "parmon", "grass", "", "", GLYPH_GRASS_ASSET.readall()],
    ["great", "kara", "great", "magnificent", "excellent", GLYPH_GREAT_ASSET.readall()],
    ["grind", "\u00F1uragon", "to grind", "to mash", "", GLYPH_GRIND_ASSET.readall()],
    ["guard", "m\u012Bsagon", "to guard", "to defend", "to clothe", GLYPH_GUARD_ASSET.readall()],
    ["guess", "ot\u0101pagon", "to guess", "to opine", "to think", GLYPH_GUESS_ASSET.readall()],
    ["guest", "zentys", "guest", "", "", GLYPH_GUEST_ASSET.readall()],
    ["gull", "bratsi", "gull", "seagull", "", GLYPH_GULL_ASSET.readall()],
    ["h", "h", "glyph for h", "", "", GLYPH_H_ASSET.readall()],
    ["hack", "rhupagon", "to hack", "to chip", "to split", GLYPH_HACK_ASSET.readall()],
    ["half", "ez\u012Bmi", "half", "", "", GLYPH_HALF_ASSET.readall()],
    ["hammer", "galry", "hammer", "mallet", "", GLYPH_HAMMER_ASSET.readall()],
    ["hand", "ondos", "hand", "agency", "", GLYPH_HAND_ASSET.readall()],
    ["hand2", "pakton", "right", "right side", "right hand", GLYPH_HAND_ASSET.readall()],
    ["hang", "b\u0113rigon", "to hang", "", "", GLYPH_HANG_ASSET.readall()],
    ["have", "emagon", "to have", "", "", GLYPH_HAVE_ASSET.readall()],
    ["hazel", "rhaegor", "hazel tree", "", "", GLYPH_HAZEL_ASSET.readall()],
    ["head", "bartos", "head", "", "", GLYPH_HEAD_ASSET.readall()],
    ["healthy", "rytsa", "healthy", "well", "hale", GLYPH_HEALTHY_ASSET.readall()],
    ["heart", "pr\u016Bmia", "heart", "", "", GLYPH_HEART_ASSET.readall()],
    ["heavy", "kempa", "heavy", "weighty", "impressive", GLYPH_HEAVY_ASSET.readall()],
    ["heft", "osragon", "to pick up", "to lift", "to heft", GLYPH_HEFT_ASSET.readall()],
    ["helm", "gelte", "helmet", "helm", "", GLYPH_HELM_ASSET.readall()],
    ["help", "baelagon", "to help", "to assist", "to aid", GLYPH_HELP_ASSET.readall()],
    ["hide", "ruaragon", "to hide", "to conceal", "", GLYPH_HIDE_ASSET.readall()],
    ["high", "eglie", "high", "superior", "late", GLYPH_HIGH_ASSET.readall()],
    ["hit", "h\u012Blagon", "to punch", "to hit", "to strike", GLYPH_HIT_ASSET.readall()],
    ["hold", "pilogon", "to hold", "onto", "", GLYPH_HOLD_ASSET.readall()],
    ["hole", "nopon", "hole", "pit", "", GLYPH_HOLE_ASSET.readall()],
    ["honey", "elilla", "honey", "", "", GLYPH_HONEY_ASSET.readall()],
    ["hook", "\u016Bly", "hook", "", "", GLYPH_HOOK_ASSET.readall()],
    ["horse", "anne", "horse", "", "", GLYPH_HORSE_ASSET.readall()],
    ["hot", "b\u0101ne", "hot", "(to the touch)", "", GLYPH_HOT_ASSET.readall()],
    ["house", "lenton", "house", "home", "", GLYPH_HOUSE_ASSET.readall()],
    ["hunger", "merbugon", "to be hungry", "to hunger", "", GLYPH_HUNGER_ASSET.readall()],
    ["hunt", "arghugon", "to hunt", "", "", GLYPH_HUNT_ASSET.readall()],
    ["i", "\u012B", "glyph for long i", "", "", GLYPH_I_ASSET.readall()],
    ["ignite", "pradagon", "to activate", "to start", "to ignite", GLYPH_IGNITE_ASSET.readall()],
    ["ice", "suvion", "ice", "", "", GLYPH_ICE_ASSET.readall()],
    ["imprint", "k\u012Bvo", "imprint", "footprint", "stamp", GLYPH_IMPRINT_ASSET.readall()],
    ["infant", "r\u016Bs", "infant", "baby", "child", GLYPH_INFANT_ASSET.readall()],
    ["iron", "\u0101egion", "iron", "", "", GLYPH_IRON_ASSET.readall()],
    ["island", "\u0101jon", "island", "", "", GLYPH_ISLAND_ASSET.readall()],
    ["it", "\u016Bja", "she, he, it", "(terrestrial and", "aquatic nouns)", GLYPH_IT_ASSET.readall()],
    ["ivy", "joro", "ivy", "", "", GLYPH_IVY_ASSET.readall()],
    ["j", "j", "glyph for j", "", "", GLYPH_J_ASSET.readall()],
    ["jasmine", "ovo\u00F1o", "jasmine", "", "", GLYPH_JASMINE_ASSET.readall()],
    ["joyful", "jessie", "joyful", "exultant", "", GLYPH_JOYFUL_ASSET.readall()],
    ["k", "k", "glyph for k", "", "", GLYPH_K_ASSET.readall()],
    ["kae", "kae-", "used with", "words for", "salvation", GLYPH_KAE_ASSET.readall()],
    ["keep", "r\u0101elagon", "to keep", "to maintain", "to retain", GLYPH_KEEP_ASSET.readall()],
    ["kidney", "rhemo", "kidney", "", "", GLYPH_KIDNEY_ASSET.readall()],
    ["kill", "s\u0113nagon", "to kill", "", "", GLYPH_KILL_ASSET.readall()],
    ["kiln", "peri", "kiln", "", "", GLYPH_KILN_ASSET.readall()],
    ["king", "d\u0101rys", "king", "monarch", "", GLYPH_KING_ASSET.readall()],
    ["king2", "d\u0101ria", "queen", "", "", GLYPH_KING_ASSET.readall()],
    ["l", "l", "glyph for l", "", "", GLYPH_L_ASSET.readall()],
    ["lake", "n\u0101var", "lake", "", "", GLYPH_LAKE_ASSET.readall()],
    ["laugh", "s\u014Dpagon", "to laugh", "", "", GLYPH_LAUGH_ASSET.readall()],
    ["lava", "runar", "lava", "", "", GLYPH_LAVA_ASSET.readall()],
    ["lead", "jemagon", "to lead", "to guide", "", GLYPH_LEAD_ASSET.readall()],
    ["leaf", "temby", "leaf", "palm frond", "page", GLYPH_LEAF_ASSET.readall()],
    ["leak", "nehugon", "to leak", "to seep", "to ooze", GLYPH_LEAK_ASSET.readall()],
    ["lean", "resagon", "to lean", "to list", "", GLYPH_LEAN_ASSET.readall()],
    ["leather", "rongon", "leather", "hide", "animal skin", GLYPH_LEATHER_ASSET.readall()],
    ["left", "gepton", "left", "left side", "left hand", GLYPH_LEFT_ASSET.readall()],
    ["leg", "kris", "leg", "", "", GLYPH_LEG_ASSET.readall()],
    ["lie", "ilagon", "to lie", "to be straight", "to be at", GLYPH_LIE_ASSET.readall()],
    ["lilac", "saere", "lilac", "", "", GLYPH_LILAC_ASSET.readall()],
    ["lime", "g\u0177s", "lime", "", "", GLYPH_LIME_ASSET.readall()],
    ["line", "qogron", "row", "line", "rank", GLYPH_LINE_ASSET.readall()],
    ["little", "byka", "small", "little", "", GLYPH_LITTLE_ASSET.readall()],
    ["littlebrother", "valonqar", "younger", "brother", "", GLYPH_LITTLEBROTHER_ASSET.readall()],
    ["littlesister", "h\u0101edar", "younger", "sister", "", GLYPH_LITTLESISTER_ASSET.readall()],
    ["lizard", "r\u012Bza", "lizard", "reptile", "", GLYPH_LIZARD_ASSET.readall()],
    ["ll", "ll", "ligature for", "double l", "", GLYPH_LL_ASSET.readall()],
    ["like", "raqagon", "to like", "to love", "to appreciate", GLYPH_LIKE_ASSET.readall()],
    ["long", "b\u014Dsa", "long", "tall", "", GLYPH_LONG_ASSET.readall()],
    ["low", "quba", "low", "inferior", "previous", GLYPH_LOW_ASSET.readall()],
    ["luck", "biare", "fortunate", "lucky", "happy", GLYPH_LUCK_ASSET.readall()],
    ["lung", "m\u014Ds", "lung", "", "", GLYPH_LUNG_ASSET.readall()],
    ["lungwort", "odinge", "lungwort", "", "", GLYPH_LUNGWORT_ASSET.readall()],
    ["m", "m", "glyph for m", "", "", GLYPH_M_ASSET.readall()],
    ["maegi", "maegi", "soothsayer", "fortune teller", "", GLYPH_MAEGI_ASSET.readall()],
    ["man", "vala", "man", "", "", GLYPH_MAN_ASSET.readall()],
    ["manage", "r\u012Bnagon", "to manage", "to handle", "to oversee", GLYPH_MANAGE_ASSET.readall()],
    ["many", "naena", "many", "multitude", "horde", GLYPH_MANY_ASSET.readall()],
    ["marry", "d\u012Bnagon", "to put", "to place", "to marry", GLYPH_MARRY_ASSET.readall()],
    ["match", "z\u0177ragon", "to match", "to fit", "to go with", GLYPH_MATCH_ASSET.readall()],
    ["meat", "parklon", "meat", "", "", GLYPH_MEAT_ASSET.readall()],
    ["meet", "rhaenagon", "to meet", "to discover", "to begin", GLYPH_MEET_ASSET.readall()],
    ["melt", "hivagon", "to melt", "", "", GLYPH_MELT_ASSET.readall()],
    ["memory", "r\u016Bnagon", "to remember", "to recall", "", GLYPH_MEMORY_ASSET.readall()],
    ["middot", "\u00B7", "punctuation", "used to separate", "words", GLYPH_MIDDOT_ASSET.readall()],
    ["midnight", "bant\u0101zma", "midnight", "", "", GLYPH_MIDNIGHT_ASSET.readall()],
    ["milk", "j\u016Blor", "milk", "", "", GLYPH_MILK_ASSET.readall()],
    ["mint", "z\u0101kon", "mint", "", "", GLYPH_MINT_ASSET.readall()],
    ["momsbigbrother", "i\u0101pa", "mother's", "older", "brother", GLYPH_MOMSBIGBROTHER_ASSET.readall()],
    ["momslittlebrother", "q\u0177bor", "mother's", "younger", "brother", GLYPH_MOMSLITTLEBROTHER_ASSET.readall()],
    ["monkey", "gaba", "monkey", "", "", GLYPH_MONKEY_ASSET.readall()],
    ["moon", "h\u016Bra", "moon", "", "", GLYPH_MOON_ASSET.readall()],
    ["mother", "mu\u00F1a", "mother", "mom", "maternal aunt", GLYPH_MOTHER_ASSET.readall()],
    ["mountain", "bl\u0113non", "mountain", "", "", GLYPH_MOUNTAIN_ASSET.readall()],
    ["mountainrange", "bl\u0113nun", "mountain", "range", "", GLYPH_MOUNTAINRANGE_ASSET.readall()],
    ["mouth", "relgos", "mouth (human)", "", "", GLYPH_MOUTH_ASSET.readall()],
    ["move", "aeragon", "to move", "to go", "", GLYPH_MOVE_ASSET.readall()],
    ["much", "olvie", "much", "a lot", "many", GLYPH_MUCH_ASSET.readall()],
    ["mud", "vaogar", "mud", "filth", "", GLYPH_MUD_ASSET.readall()],
    ["mushroom", "nollon", "mushroom", "", "", GLYPH_MUSHROOM_ASSET.readall()],
    ["n", "n", "glyph for n", "", "", GLYPH_N_ASSET.readall()],
    ["nadir", "gaos", "belly (animal)", "nadir", "underside", GLYPH_NADIR_ASSET.readall()],
    ["name", "br\u014Dzagon", "to name", "", "", GLYPH_NAME_ASSET.readall()],
    ["narrow", "\u0177rda", "narrow", "", "", GLYPH_NARROW_ASSET.readall()],
    ["neck", "yrgos", "neck", "throat", "", GLYPH_NECK_ASSET.readall()],
    ["night", "bantis", "night", "", "", GLYPH_NIGHT_ASSET.readall()],
    ["nightsky", "\u0113brion", "night sky", "", "", GLYPH_NIGHTSKY_ASSET.readall()],
    ["nine", "v\u014Dre", "nine (9)", "", "", GLYPH_NINE_ASSET.readall()],
    ["nn", "nn", "ligature for", "double n", "", GLYPH_NN_ASSET.readall()],
    ["nose", "pungos", "nose", "", "", GLYPH_NOSE_ASSET.readall()],
    ["not", "daor", "no", "not", "", GLYPH_NOT_ASSET.readall()],
    ["o", "\u014D", "glyph for long o", "", "", GLYPH_O_ASSET.readall()],
    ["obsolete", "n\u016Bda", "gray", "antiquated", "obsolete", GLYPH_OBSOLETE_ASSET.readall()],
    ["ocean", "embar", "sea", "ocean", "", GLYPH_OCEAN_ASSET.readall()],
    ["old", "u\u0113pa", "old", "elderly", "", GLYPH_OLD_ASSET.readall()],
    ["oldeat", "kis-", "older version", "of the kis-", "glyph", GLYPH_OLDEAT_ASSET.readall()],
    ["oleander", "helaenor", "oleander", "oleander bush", "", GLYPH_OLEANDER_ASSET.readall()],
    ["olive", "p\u0113ko", "olive", "", "", GLYPH_OLIVE_ASSET.readall()],
    ["one", "m\u0113re", "one (1)", "only", "sole", GLYPH_ONE_ASSET.readall()],
    ["openingstrike", "(", "equivalent", "to an opening", "parenthesis", GLYPH_OPENINGSTRIKE_ASSET.readall()],
    ["orchid", "votre", "orchid", "", "", GLYPH_ORCHID_ASSET.readall()],
    ["other", "tolie", "other", "higher", "next", GLYPH_OTHER_ASSET.readall()],
    ["owl", "atroksia", "owl", "", "", GLYPH_OWL_ASSET.readall()],
    ["p", "p", "glyph for p", "", "", GLYPH_P_ASSET.readall()],
    ["palm", "nine", "palm of the hand", "", "", GLYPH_PALM_ASSET.readall()],
    ["path", "geron", "path", "walkway", "", GLYPH_PATH_ASSET.readall()],
    ["peel", "dyragon", "to peel", "", "", GLYPH_PEEL_ASSET.readall()],
    ["pelican", "manengi", "pelican", "", "", GLYPH_PELICAN_ASSET.readall()],
    ["pelican2", "manengagon", "to scoop", "to ladle", "", GLYPH_PELICAN_ASSET.readall()],
    ["pile", "k\u0101ro", "heap", "pile", "", GLYPH_PILE_ASSET.readall()],
    ["pillar", "q\u012Bzy", "pillar", "support", "post", GLYPH_PILLAR_ASSET.readall()],
    ["plan", "k\u0177vagon", "to plan", "to strategize", "to conceive", GLYPH_PLAN_ASSET.readall()],
    ["planet", "v\u0177s", "planet", "world", "", GLYPH_PLANET_ASSET.readall()],
    ["play", "tymagon", "to play", "to frolic", "to gambol", GLYPH_PLAY_ASSET.readall()],
    ["pluck", "deragon", "to pluck", "to pick", "", GLYPH_PLUCK_ASSET.readall()],
    ["poke", "t\u0113magon", "to poke", "to prod", "to prick", GLYPH_POKE_ASSET.readall()],
    ["pomegranate", "n\u0113\u00F1o", "pomegranate", "", "", GLYPH_POMEGRANATE_ASSET.readall()],
    ["poppy", "j\u014Dz", "poppy", "", "", GLYPH_POPPY_ASSET.readall()],
    ["pot", "\u00F1uton", "pot", "cooking pot", "", GLYPH_POT_ASSET.readall()],
    ["pot2", "keragon", "to cook", "", "", GLYPH_POT_ASSET.readall()],
    ["pound", "qepagon", "to pound", "to flatten", "to tamp", GLYPH_POUND_ASSET.readall()],
    ["pour", "hulagon", "to pour", "", "", GLYPH_POUR_ASSET.readall()],
    ["power", "kostagon", "to be able", "can (aux)", "", GLYPH_POWER_ASSET.readall()],
    ["praise", "rijagon", "to praise", "to laud", "", GLYPH_PRAISE_ASSET.readall()],
    ["press", "p\u0177nagon", "to press", "to squeeze", "to compress", GLYPH_PRESS_ASSET.readall()],
    ["pretty", "litse", "pretty", "cute", "fair", GLYPH_PRETTY_ASSET.readall()],
    ["priest", "voktys", "priest", "priestess", "", GLYPH_PRIEST_ASSET.readall()],
    ["prop", "t\u0101ragon", "to pitch", "to prop up", "", GLYPH_PROP_ASSET.readall()],
    ["protrude", "hyngagon", "to protrude", "to stick out", "to extend", GLYPH_PROTRUDE_ASSET.readall()],
    ["pull", "hakogon", "to pull", "to bother", "to annoy", GLYPH_PULL_ASSET.readall()],
    ["pure", "v\u014Dka", "pure", "", "", GLYPH_PURE_ASSET.readall()],
    ["push", "indigon", "to push", "to intend", "to mean to do", GLYPH_PUSH_ASSET.readall()],
    ["put", "hannagon", "to put in place", "", "", GLYPH_PUT_ASSET.readall()],
    ["q", "q", "glyph for q", "", "", GLYPH_Q_ASSET.readall()],
    ["r", "r", "glyph for r", "", "", GLYPH_R_ASSET.readall()],
    ["rabbit", "hunes", "rabbit", "bunny", "hare", GLYPH_RABBIT_ASSET.readall()],
    ["rain", "daomio", "rain", "", "", GLYPH_RAIN_ASSET.readall()],
    ["ram", "\u014Dtor", "ram", "sheep (m)", "", GLYPH_RAM_ASSET.readall()],
    ["raven", "v\u014Dljes", "raven", "", "", GLYPH_RAVEN_ASSET.readall()],
    ["rh", "rh", "glyph for rh", "", "", GLYPH_RH_ASSET.readall()],
    ["rice", "m\u0101lor", "rice", "", "", GLYPH_RICE_ASSET.readall()],
    ["ride", "kipagon", "to ride", "", "", GLYPH_RIDE_ASSET.readall()],
    ["rip", "tessagon", "to rip", "to tear", "", GLYPH_RIP_ASSET.readall()],
    ["rise", "s\u012Bmagon", "to rise", "to float up", "", GLYPH_RISE_ASSET.readall()],
    ["river", "qelbar", "river", "", "", GLYPH_RIVER_ASSET.readall()],
    ["roll", "s\u014Dlugon", "to roll", "to tumble", "", GLYPH_ROLL_ASSET.readall()],
    ["rooster", "\u00F1oves", "rooster", "chicken (m)", "", GLYPH_ROOSTER_ASSET.readall()],
    ["rooster2", "qulbes", "hen", "chicken (f)", "", GLYPH_ROOSTER_ASSET.readall()],
    ["rope", "hubon", "rope", "cord", "", GLYPH_ROPE_ASSET.readall()],
    ["rose", "r\u0113ko", "rose", "", "", GLYPH_ROSE_ASSET.readall()],
    ["rot", "puatagon", "to rot", "to shrivel", "to go bad", GLYPH_ROT_ASSET.readall()],
    ["rough", "rhinka", "rough", "coarse", "unpleasant", GLYPH_ROUGH_ASSET.readall()],
    ["rr", "rr", "ligature", "for", "double r", GLYPH_RR_ASSET.readall()],
    ["rub", "pamagon", "to rub", "to pet", "", GLYPH_RUB_ASSET.readall()],
    ["run", "dakogon", "to run", "", "", GLYPH_RUN_ASSET.readall()],
    ["s", "s", "glyph for s", "", "", GLYPH_S_ASSET.readall()],
    ["safe", "\u0177gha", "safe", "secure", "", GLYPH_SAFE_ASSET.readall()],
    ["salt", "lopon", "salt", "", "", GLYPH_SALT_ASSET.readall()],
    ["sambucus", "t\u014Dmo", "elderflower", "sambucus", "", GLYPH_SAMBUCUS_ASSET.readall()],
    ["same", "h\u0113nka", "same", "similar", "", GLYPH_SAME_ASSET.readall()],
    ["sand", "rizmon", "sand", "", "", GLYPH_SAND_ASSET.readall()],
    ["scalp", "ziksos", "neck", "scalp", "", GLYPH_SCALP_ASSET.readall()],
    ["scorpion", "raedes", "scorpion", "", "", GLYPH_SCORPION_ASSET.readall()],
    ["scrape", "gisagon", "to scrape", "", "", GLYPH_SCRAPE_ASSET.readall()],
    ["scratch", "purtagon", "to scratch", "to scour", "to score", GLYPH_SCRATCH_ASSET.readall()],
    ["scream", "h\u012Bghagon", "to scream", "to wail", "to cry out", GLYPH_SCREAM_ASSET.readall()],
    ["screech", "jitsagon", "to screech", "to yelp", "to yowl", GLYPH_SCREECH_ASSET.readall()],
    ["seed", "n\u016Bmo", "pod", "seed", "nut", GLYPH_SEED_ASSET.readall()],
    ["sell", "lioragon", "to sell", "", "", GLYPH_SELL_ASSET.readall()],
    ["sense", "hylagon", "to feel", "to sense", "", GLYPH_SENSE_ASSET.readall()],
    ["separate", "viragon", "to separate", "to thresh out", "to pull apart", GLYPH_SEPARATE_ASSET.readall()],
    ["serve", "dohaeragon", "to serve", "", "", GLYPH_SERVE_ASSET.readall()],
    ["seven", "s\u012Bkuda", "seven (7)", "", "", GLYPH_SEVEN_ASSET.readall()],
    ["seven2", "sagon", "to be (copula)", "", "", GLYPH_SEVEN_ASSET.readall()],
    ["sew", "\u00F1epegon", "to sew", "", "", GLYPH_SEW_ASSET.readall()],
    ["sharp", "qana", "sharp", "effective", "", GLYPH_SHARP_ASSET.readall()],
    ["she", "ziry", "she, he, it", "(lunar and", "solar nouns)", GLYPH_SHE_ASSET.readall()],
    ["sheep", "bianor", "sheep (f)", "", "", GLYPH_SHEEP_ASSET.readall()],
    ["shield", "somby", "shield", "", "", GLYPH_SHIELD_ASSET.readall()],
    ["short", "m\u012Bba", "short", "", "", GLYPH_SHORT_ASSET.readall()],
    ["shoulder", "q\u012Bbi", "shoulder", "back of the neck", "shoulder area", GLYPH_SHOULDER_ASSET.readall()],
    ["shove", "v\u0101degon", "to position", "to put in place", "", GLYPH_SHOVE_ASSET.readall()],
    ["show", "arrigon", "to show", "to display", "", GLYPH_SHOW_ASSET.readall()],
    ["sibling", "dubys", "sibling", "parallel cousin", "", GLYPH_SIBLING_ASSET.readall()],
    ["silk", "kyno", "silkworm", "", "", GLYPH_SILK_ASSET.readall()],
    ["silver", "g\u0113lion", "silver", "", "", GLYPH_SILVER_ASSET.readall()],
    ["sing", "v\u0101edagon", "to sing", "", "", GLYPH_SING_ASSET.readall()],
    ["sit", "d\u0113magon", "to sit", "to sit down", "", GLYPH_SIT_ASSET.readall()],
    ["six", "b\u0177re", "six (6)", "", "", GLYPH_SIX_ASSET.readall()],
    ["sleep", "\u0113drugon", "to sleep", "", "", GLYPH_SLEEP_ASSET.readall()],
    ["slow", "paez", "slow", "sluggish", "", GLYPH_SLOW_ASSET.readall()],
    ["smile", "l\u012Brigon", "to smile", "", "", GLYPH_SMILE_ASSET.readall()],
    ["smoke", "\u014Drbar", "smoke", "", "", GLYPH_SMOKE_ASSET.readall()],
    ["snout", "\u0101psos", "snout", "muzzle", "mouth", GLYPH_SNOUT_ASSET.readall()],
    ["snow", "s\u014Dna", "snow", "", "", GLYPH_SNOW_ASSET.readall()],
    ["soil", "balon", "soil", "", "", GLYPH_SOIL_ASSET.readall()],
    ["solid", "l\u014Dta", "solid", "hard", "durable", GLYPH_SOLID_ASSET.readall()],
    ["sour", "v\u012Bga", "sour", "", "", GLYPH_SOUR_ASSET.readall()],
    ["sparrow", "urghes", "sparrow", "", "", GLYPH_SPARROW_ASSET.readall()],
    ["speak", "\u0177dragon", "to speak", "to talk", "", GLYPH_SPEAK_ASSET.readall()],
    ["spider", "vaokses", "spider", "", "", GLYPH_SPIDER_ASSET.readall()],
    ["spring", "ki\u014Ds", "spring (season)", "", "", GLYPH_SPRING_ASSET.readall()],
    ["squid", "u\u0113s", "squid", "", "", GLYPH_SQUID_ASSET.readall()],
    ["squirrel", "rola", "squirrel", "", "", GLYPH_SQUIRREL_ASSET.readall()],
    ["ss", "ss", "ligature for", "double s", "", GLYPH_SS_ASSET.readall()],
    ["stand", "i\u014Dragon", "to stand", "to be in a state", "", GLYPH_STAND_ASSET.readall()],
    ["star", "q\u0113los", "star", "", "", GLYPH_STAR_ASSET.readall()],
    ["steer", "soljagon", "to guide", "to steer", "to pilot", GLYPH_STEER_ASSET.readall()],
    ["stomach", "iemny", "stomach", "belly (human)", "", GLYPH_STOMACH_ASSET.readall()],
    ["stone", "d\u014Dron", "stone", "rock", "", GLYPH_STONE_ASSET.readall()],
    ["stone2", "qighagon", "to pile", "to stack", "", GLYPH_STONE_ASSET.readall()],
    ["storm", "jelm\u0101zma", "storm", "violent winds", "", GLYPH_STORM_ASSET.readall()],
    ["strawberry", "z\u014Dro", "strawberry", "", "", GLYPH_STRAWBERRY_ASSET.readall()],
    ["stretch", "korzigon", "to stretch", "to extend", "to last", GLYPH_STRETCH_ASSET.readall()],
    ["struggle", "ambigon", "to struggle", "", "", GLYPH_STRUGGLE_ASSET.readall()],
    ["stuck", "suez", "stuck", "jammed", "wedged", GLYPH_STUCK_ASSET.readall()],
    ["suckle", "b\u012Bbagon", "to suckle", "", "", GLYPH_SUCKLE_ASSET.readall()],
    ["summer", "jaedos", "summer", "", "", GLYPH_SUMMER_ASSET.readall()],
    ["sun", "v\u0113zos", "sun", "", "", GLYPH_SUN_ASSET.readall()],
    ["sunrise", "\u00F1\u0101qien", "sunrise", "", "", GLYPH_SUNRISE_ASSET.readall()],
    ["sunrise2", "dr\u016Br", "tomorrow", "", "", GLYPH_SUNRISE_ASSET.readall()],
    ["sunset", "endien", "sunset", "", "", GLYPH_SUNSET_ASSET.readall()],
    ["sunset2", "z\u0101n", "yesterday", "", "", GLYPH_SUNSET_ASSET.readall()],
    ["swap", "milagon", "to swap", "to switch", "", GLYPH_SWAP_ASSET.readall()],
    ["sweet", "d\u014Dna", "sweet", "pleasant", "", GLYPH_SWEET_ASSET.readall()],
    ["swell", "h\u014Dzigon", "to swell", "", "", GLYPH_SWELL_ASSET.readall()],
    ["swim", "bughegon", "to swim", "", "", GLYPH_SWIM_ASSET.readall()],
    ["t", "t", "glyph for t", "", "", GLYPH_T_ASSET.readall()],
    ["table", "qurdon", "table", "", "", GLYPH_TABLE_ASSET.readall()],
    ["tail", "bode", "tail", "", "", GLYPH_TAIL_ASSET.readall()],
    ["targaryen", "Targ\u0101rien", "Targaryen", "", "", GLYPH_TARGARYEN_ASSET.readall()],
    ["tea", "s\u016Bmo", "tea leaf", "", "", GLYPH_TEA_ASSET.readall()],
    ["tear", "q\u016Bvy", "tear", "teardrop", "", GLYPH_TEAR_ASSET.readall()],
    ["tear2", "limagon", "to cry", "to weep", "", GLYPH_TEAR_ASSET.readall()],
    ["they", "p\u014Dnta", "they", "", "", GLYPH_THEY_ASSET.readall()],
    ["thick", "qumblie", "thick", "", "", GLYPH_THICK_ASSET.readall()],
    ["thigh", "pore", "thigh", "", "", GLYPH_THIGH_ASSET.readall()],
    ["thin", "vasrie", "thin", "", "", GLYPH_THIN_ASSET.readall()],
    ["thing", "non", "thing", "", "", GLYPH_THING_ASSET.readall()],
    ["three", "h\u0101re", "three (3)", "", "", GLYPH_THREE_ASSET.readall()],
    ["through", "r\u0113bagon", "to pass through", "to go through", "to undergo", GLYPH_THROUGH_ASSET.readall()],
    ["throw", "ilzigon", "to throw", "to sow", "to bore", GLYPH_THROW_ASSET.readall()],
    ["toil", "botagon", "to work", "to endure", "to suffer", GLYPH_TOIL_ASSET.readall()],
    ["tongue", "\u0113ngos", "tongue", "language", "dialect", GLYPH_TONGUE_ASSET.readall()],
    ["tooth", "\u0101tsio", "tooth", "", "", GLYPH_TOOTH_ASSET.readall()],
    ["top", "baes", "top", "summit", "tip", GLYPH_TOP_ASSET.readall()],
    ["touch", "renigon", "to touch", "", "", GLYPH_TOUCH_ASSET.readall()],
    ["tree", "gu\u0113se", "tree", "", "", GLYPH_TREE_ASSET.readall()],
    ["trout", "b\u0113gor", "trout", "", "", GLYPH_TROUT_ASSET.readall()],
    ["true", "dr\u0113je", "true", "right", "correct", GLYPH_TRUE_ASSET.readall()],
    ["ts", "ts", "ligature", "for", "ts", GLYPH_TS_ASSET.readall()],
    ["tt", "tt", "ligature", "for", "double t", GLYPH_TT_ASSET.readall()],
    ["turn", "p\u0101legon", "to twist", "to turn", "to rotate", GLYPH_TURN_ASSET.readall()],
    ["turtle", "qintir", "turtle", "", "", GLYPH_TURTLE_ASSET.readall()],
    ["two", "lanta", "two (2)", "", "", GLYPH_TWO_ASSET.readall()],
    ["type", "l\u016Bs", "type", "kind", "", GLYPH_TYPE_ASSET.readall()],
    ["tyrant", "qr\u012Bnio", "tyrant", "dictator", "", GLYPH_TYRANT_ASSET.readall()],
    ["tys", "tys", "ligature for tys", "", "", GLYPH_TYS_ASSET.readall()],
    ["u", "\u016B", "glyph for long u", "", "", GLYPH_U_ASSET.readall()],
    ["uproot", "terragon", "to uproot", "to unearth", "to dig up", GLYPH_UPROOT_ASSET.readall()],
    ["v", "v", "glyph for v", "", "", GLYPH_V_ASSET.readall()],
    ["valyria", "Valyria", "Valyria", "", "", GLYPH_VALYRIA_ASSET.readall()],
    ["vapor", "konor", "vapor", "steam", "", GLYPH_VAPOR_ASSET.readall()],
    ["veil", "laodi", "veil", "", "", GLYPH_VEIL_ASSET.readall()],
    ["veil2", "laodigon", "to abduct", "to steal", "to cover", GLYPH_VEIL_ASSET.readall()],
    ["velaryon", "velagon", "to oscillate", "to bob", "", GLYPH_VELARYON_ASSET.readall()],
    ["violet", "daema", "violet (flower)", "", "", GLYPH_VIOLET_ASSET.readall()],
    ["warm", "dija", "hot", "(internally)", "", GLYPH_WARM_ASSET.readall()],
    ["warn", "vermagon", "to warn", "to alert", "", GLYPH_WARN_ASSET.readall()],
    ["water", "i\u0113dar", "water", "", "", GLYPH_WATER_ASSET.readall()],
    ["waterowl", "-ria", "glyph used as a", "determinative", "for some nouns", GLYPH_WATEROWL_ASSET.readall()],
    ["wave", "pelar", "wave", "", "", GLYPH_WAVE_ASSET.readall()],
    ["we", "\u012Blon", "we", "", "", GLYPH_WE_ASSET.readall()],
    ["wet", "l\u014Dz", "wet", "damp", "moist", GLYPH_WET_ASSET.readall()],
    ["whale", "qaedar", "whale", "", "", GLYPH_WHALE_ASSET.readall()],
    ["what", "skoros", "what", "", "", GLYPH_WHAT_ASSET.readall()],
    ["wheel", "grevy", "wheel", "", "", GLYPH_WHEEL_ASSET.readall()],
    ["whip", "qil\u014Dny", "whip", "", "", GLYPH_WHIP_ASSET.readall()],
    ["whip2", "qil\u014Dnagon", "to whip", "to chastise", "to punish", GLYPH_WHIP_ASSET.readall()],
    ["whirl", "s\u016Bsagon", "to whirl", "to twirl", "to spin", GLYPH_WHIRL_ASSET.readall()],
    ["whole", "giez", "whole", "complete", "together", GLYPH_WHOLE_ASSET.readall()],
    ["wide", "dr\u0101\u00F1e", "wide", "", "", GLYPH_WIDE_ASSET.readall()],
    ["wilt", "gosagon", "to wilt", "to wither", "", GLYPH_WILT_ASSET.readall()],
    ["wind", "jelmio", "wind", "", "", GLYPH_WIND_ASSET.readall()],
    ["wipe", "r\u0101enagon", "to wipe", "to brush", "", GLYPH_WIPE_ASSET.readall()],
    ["wolf", "zokla", "wolf", "", "", GLYPH_WOLF_ASSET.readall()],
    ["woman", "\u0101bra", "woman", "", "", GLYPH_WOMAN_ASSET.readall()],
    ["wood", "tijon", "wood", "", "", GLYPH_WOOD_ASSET.readall()],
    ["word", "udir", "word", "", "", GLYPH_WORD_ASSET.readall()],
    ["worm", "turgon", "worm", "", "", GLYPH_WORM_ASSET.readall()],
    ["write", "bardugon", "to write", "", "", GLYPH_WRITE_ASSET.readall()],
    ["x", "ks", "ligature for ks", "", "", GLYPH_X_ASSET.readall()],
    ["y", "\u0177", "glyph for long y", "", "", GLYPH_Y_ASSET.readall()],
    ["y2", "g\u0101r", "hundred (100)", "", "", GLYPH_Y_ASSET.readall()],
    ["young", "suene", "young", "youthful", "", GLYPH_YOUNG_ASSET.readall()],
    ["z", "z", "glyph for z", "", "", GLYPH_Z_ASSET.readall()],
    ["zero", "daorun", "zero (0)", "nothing", "null", GLYPH_ZERO_ASSET.readall()],
    ["zr", "zr", "ligature for", "zr or sr", "", GLYPH_ZR_ASSET.readall()],
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
