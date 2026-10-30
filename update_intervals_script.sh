#!/bin/bash
# This script will insert or update the recommendedInterval line in the manifest.yaml for each app
# according to the update_intervals.txt file
# recommendedInterval will be used as the default update interval when adding app to tronbyt.

while IFS=': ' read -r app interval || [[ -n "$app" ]]; do
  if [[ $app =~ ^#.* ]] || [[ -z "$app" ]] || [[ -z "$interval" ]]; then
    continue
  fi
  
  app_dir="apps/${app}"
  manifest_file="${app_dir}/manifest.yaml"
  
  if [[ -f "$manifest_file" ]]; then
    # Check if recommendedInterval already exists
    if grep -q "recommendedInterval:" "$manifest_file"; then
      # Update existing recommendedInterval
      sed -i.bak "s/recommendedInterval:.*$/recommendedInterval: $interval/" "$manifest_file" && rm -f "${manifest_file}.bak"
    else
      # Add recommendedInterval before the first blank line or at the end of file
      awk -v interval="$interval" \
        ' \
        /^$/ && !added { print "recommendedInterval: " interval; added=1; print ""; next } \
        END { if(!added) { print "recommendedInterval: " interval; } } \
        { print } \
      ' "$manifest_file" > "${manifest_file}.tmp" && mv "${manifest_file}.tmp" "$manifest_file"
    fi
    echo "Updated $manifest_file with interval $interval"
  else
    echo "Warning: Manifest file not found for $app"
  fi
done < update_intervals.txt
