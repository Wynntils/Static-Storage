#!/bin/bash

BASE_DIR="$(cd "$(dirname "$0")"/.. 2>/dev/null && pwd)"

CONTENT_DIR="$BASE_DIR"/Data-Storage/raw/ability_tree
OUTPUT_DIR="$BASE_DIR"/Reference

mkdir -p "$OUTPUT_DIR"

# Initialize the combined file as an empty JSON object
COMBINED_JSON="$OUTPUT_DIR/abilities.json"
echo "{}" > "$COMBINED_JSON"

for FILE in "$CONTENT_DIR"/*_abilities.json; do
  KEY=$(basename "$FILE" | sed -E 's/(_abilities.json)//') # Extract 'x' from 'x_abilities.json'
  CONTENT=$(jq '.' "$FILE") # Read the entire JSON file
  jq --arg key "$KEY" --argjson content "$CONTENT" '.[$key] = $content' "$COMBINED_JSON" > tmp.json && mv tmp.json "$COMBINED_JSON"
done

# Sort keys
jq 'to_entries | sort_by(.key) | from_entries' "$COMBINED_JSON" > tmp.json && mv tmp.json "$COMBINED_JSON"

# Calculate md5sum of the new combined data
MD5=$(md5sum "$COMBINED_JSON" | cut -d' ' -f1)

# Update urls.json with the new md5sum for dataStaticAbilities
jq --arg md5 "$MD5" '. = [.[] | if (.id == "dataStaticAbilities") then .md5 = $md5 else . end]' < "$BASE_DIR"/Data-Storage/urls.json > "$BASE_DIR"/Data-Storage/urls.json.tmp
mv "$BASE_DIR"/Data-Storage/urls.json.tmp "$BASE_DIR"/Data-Storage/urls.json