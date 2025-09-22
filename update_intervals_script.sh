#!/bin/bash
# This script will insert or update the recommeneded_interval line in the manifest.yaml for each app
# according to the update_intervals.txt file
# recommended interval will be used as the default update interval when adding app to tronbyt.

while IFS=': ' read -r app interval || [[ -n "$app" ]]; do
  if [[ $app =~ ^#.* ]] || [[ -z "$app" ]] || [[ -z "$interval" ]]; then
    continue
  fi
  
  app_dir="apps/${app}"
  manifest_file="${app_dir}/manifest.yaml"
  
  if [[ -f "$manifest_file" ]]; then
    # Check if recommended_interval already exists
    if grep -q "recommended_interval:" "$manifest_file"; then
      # Replace existing recommended_interval line - compatible with both GNU and BSD sed
      sed -i.bak "s/recommended_interval:.*$/recommended_interval: $interval/" "$manifest_file" && rm -f "${manifest_file}.bak"
    else
      # Add recommended_interval before the first blank line or at the end of file
      awk -v interval="$interval" '
        /^$/ && !added { print "recommended_interval: " interval; added=1; print ""; next }
        END { if(!added) print "recommended_interval: " interval }
        { print }
      ' "$manifest_file" > "${manifest_file}.tmp" && mv "${manifest_file}.tmp" "$manifest_file"
    fi
    echo "Updated $manifest_file with interval $interval"
  else
    echo "Warning: Manifest file not found for $app"
  fi
done < update_intervals.txt
