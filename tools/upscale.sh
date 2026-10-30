#!/bin/bash

# Ensure bc is installed for duration checks (standard on most systems)
if ! command -v bc &> /dev/null; then
    echo "Error: 'bc' is not installed. Please install it (e.g., brew install bc or apt install bc)."
    exit 1
fi

for f in *.{png,webp,gif}; do
    # Skip if no files match or if file is already an @2x version
    [ -e "$f" ] || continue
    if [[ "$f" == *"@2x"* ]]; then continue; fi

    echo "Processing: $f"
    
    # Get frame count and duration for animation detection
    frames=$(ffprobe -v error -select_streams v:0 -show_entries stream=nb_frames -of default=nokey=1:noprint_wrappers=1 "$f")
    duration=$(ffprobe -v error -select_streams v:0 -show_entries stream=duration -of default=nokey=1:noprint_wrappers=1 "$f")
    
    out="${f%.*}@2x.${f##*.}"

    # Determine if it's an animation (Multiple frames OR duration > 0)
    is_animated=false
    if [[ "$frames" != "N/A" && "$frames" -gt 1 ]]; then
        is_animated=true
    elif [[ "$duration" != "N/A" && $(echo "$duration > 0" | bc -l 2>/dev/null) -eq 1 ]]; then
        is_animated=true
    fi

    if [ "$is_animated" = true ]; then
        # ANIMATED: hqx=2 + timing fix + palette optimization
        # -copyts and setpts=PTS prevent the animation from speeding up
        ffmpeg -copyts -i "$f" -filter_complex \
        "[0:v]hqx=2,setpts=PTS,split[a][b];[a]palettegen=reserve_transparent=1[p];[b][p]paletteuse=alpha_threshold=128" \
        "$out" -y -loglevel error
    else
        # STATIC: hqx=2 
        # -update 1 is needed for single-image outputs in FFmpeg
        ffmpeg -i "$f" -vf "hqx=2" -frames:v 1 -update 1 "$out" -y -loglevel error
    fi
done

echo "---------------------------------------"
echo "Done. Upscaled icons are ready in the current folder."
