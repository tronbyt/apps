load("moon_clock_images/moon-01.png", IMAGE_01 = "file")
load("moon_clock_images/moon-02.png", IMAGE_02 = "file")
load("moon_clock_images/moon-03.png", IMAGE_03 = "file")
load("moon_clock_images/moon-04.png", IMAGE_04 = "file")
load("moon_clock_images/moon-05.png", IMAGE_05 = "file")
load("moon_clock_images/moon-06.png", IMAGE_06 = "file")
load("moon_clock_images/moon-07.png", IMAGE_07 = "file")
load("moon_clock_images/moon-08.png", IMAGE_08 = "file")
load("moon_clock_images/moon-09.png", IMAGE_09 = "file")
load("moon_clock_images/moon-10.png", IMAGE_10 = "file")
load("moon_clock_images/moon-11.png", IMAGE_11 = "file")
load("moon_clock_images/moon-12.png", IMAGE_12 = "file")
load("moon_clock_images/moon-13.png", IMAGE_13 = "file")
load("moon_clock_images/moon-14.png", IMAGE_14 = "file")
load("moon_clock_images/moon-15.png", IMAGE_15 = "file")
load("moon_clock_images/moon-16.png", IMAGE_16 = "file")
load("moon_clock_images/moon-17.png", IMAGE_17 = "file")
load("moon_clock_images/moon-18.png", IMAGE_18 = "file")
load("moon_clock_images/moon-19.png", IMAGE_19 = "file")
load("moon_clock_images/moon-20.png", IMAGE_20 = "file")
load("moon_clock_images/moon-21.png", IMAGE_21 = "file")
load("moon_clock_images/moon-22.png", IMAGE_22 = "file")
load("moon_clock_images/moon-23.png", IMAGE_23 = "file")
load("moon_clock_images/moon-24.png", IMAGE_24 = "file")
load("moon_clock_images/moon-25.png", IMAGE_25 = "file")
load("moon_clock_images/moon-26.png", IMAGE_26 = "file")
load("moon_clock_images/moon-27.png", IMAGE_27 = "file")
load("moon_clock_images/moon-28.png", IMAGE_28 = "file")
load("moon_clock_images/moon-29.png", IMAGE_29 = "file")
load("moon_clock_images/moon-30.png", IMAGE_30 = "file")

IMAGES = [
    IMAGE_01,
    IMAGE_02,
    IMAGE_03,
    IMAGE_04,
    IMAGE_05,
    IMAGE_06,
    IMAGE_07,
    IMAGE_08,
    IMAGE_09,
    IMAGE_10,
    IMAGE_11,
    IMAGE_12,
    IMAGE_13,
    IMAGE_14,
    IMAGE_15,
    IMAGE_16,
    IMAGE_17,
    IMAGE_18,
    IMAGE_19,
    IMAGE_20,
    IMAGE_21,
    IMAGE_22,
    IMAGE_23,
    IMAGE_24,
    IMAGE_25,
    IMAGE_26,
    IMAGE_27,
    IMAGE_28,
    IMAGE_29,
    IMAGE_30,
]

def get_moon_image(index):
    return IMAGES[index].readall()
