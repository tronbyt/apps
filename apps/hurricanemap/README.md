# Hurricane Map for Tronbyt
Displays current global tropical depressions, storms, hurricanes, cyclones, and typhoons.

Users can customize their preferred basin (see below), colors, and symbols. They can also hide the app if no storms are present in the selected basin.

![Hurricane Map for Tronbyt](hurricane_map.webp)

This app supports 2x display:<br>
![Hurricane Map at 2x for Tronbyt](hurricane_map@2x.webp)

## Basins
In addition to global maps, users can choose specific basins to display.

Selection of the bounds for the basins was adapted from [Bloemendaal et al., 2020](https://doi.org/10.1038/s41597-020-0381-2) (Figure 1). The lateral bounds of the boxes were expanded to fit a 2:1 aspect ratio.

<img src="images/map_basins.svg" alt="Map of basins" width="85%">

## Symbols
For this app, the [Saffir-Simpson scale](https://en.wikipedia.org/wiki/Saffir%E2%80%93Simpson_scale) is used to classify storm intensity.

A storm's intensity dictates which shapes and colors to use, depending on the selected symbol size. Below is a table of how the symbols will appear using their default colors. The center of a storm is always anchored to the center of its symbol.

|                     | Large | Medium | Small |
|---------------------|-------|--------|-------|
| Tropical Depression | ![Tropical Depression - Large](images/icon_large_td.png) | ![Tropical Depression - Medium](images/icon_s_m_td.png) | ![Tropical Depression - Small](images/icon_s_m_td.png) |
| Tropical Storm      | ![Tropical Storm - Large](images/icon_large_ts.png) | ![Tropical Storm - Medium](images/icon_medium_ts.png) | ![Tropical Storm - Small](images/icon_small_ts.png) |
| Category 1          | ![Category 1 - Large](images/icon_large_cat1.png) | ![Category 1 - Medium](images/icon_medium_cat1.png) | ![Category 1 - Small](images/icon_small_cat1.png) |
| Category 2          | ![Category 2 - Large](images/icon_large_cat2.png) | ![Category 2 - Medium](images/icon_medium_cat2.png) | ![Category 2 - Small](images/icon_small_cat2.png) |
| Category 3          | ![Category 3 - Large](images/icon_large_cat3.png) | ![Category 3 - Medium](images/icon_medium_cat3.png) | ![Category 3 - Small](images/icon_small_cat3.png) |
| Category 4          | ![Category 4 - Large](images/icon_large_cat4.png) | ![Category 4 - Medium](images/icon_medium_cat4.png) | ![Category 4 - Small](images/icon_small_cat4.png) |
| Category 5          | ![Category 5 - Large](images/icon_large_cat5.png) | ![Category 5 - Medium](images/icon_medium_cat5.png) | ![Category 5 - Small](images/icon_small_cat5.png) |

## Data sources
Storm data is combined from two sources:
- The [National Hurricane Center](http://www.nhc.noaa.gov/), which covers the Northern Atlantic and Eastern Pacific basins.
- The [Joint Typhoon Warning Center](https://www.metoc.navy.mil/jtwc/jtwc.html), which covers all other basins.

## Attributions
Basin map adapted from "[Tissot indicatrix world map Mercator proj.svg](https://commons.wikimedia.org/wiki/File:Tissot_indicatrix_world_map_Mercator_proj.svg)" by [Eric Gaba](https://commons.wikimedia.org/wiki/User:Sting), licensed under [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/). Changes: Tissot indicatrix circles removed, cropped to 80°N - 80°S, degree labels and ocean basin boxes added. This adapted map is licensed under [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/).

Coastline data © [OpenStreetMap contributors](https://www.openstreetmap.org/copyright), available under the [Open Database License (ODbL) 1.0](https://opendatacommons.org/licenses/odbl/1.0/).

The data was obtained via the `earth-coastlines` map (10 km resolution) from [geo-maps](https://github.com/simonepri/geo-maps) by Simone Primarosa (code licensed under the MIT License).

The map pattern arrays in `helper.star` is a derived rasterization of this data (128x64) and is made available under ODbL 1.0. The dynamically generated SVGs are Produced Works based on OpenStreetMap data.