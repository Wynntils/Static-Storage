#!/bin/bash

# Get the base directory
BASE_DIR="$(cd $(dirname "$0")/.. 2>/dev/null && pwd)"

# Set the content and output directories
CONTENT_DIR=$BASE_DIR/Data-Storage
OUTPUT_DIR=$BASE_DIR/Reference

# Create the output directory if it does not exist
mkdir -p $OUTPUT_DIR

# Function to map and transform data
transform_data() {
  jq 'def map_category(type; name):
        if type == "bossAltar" then "boss-altar"
        elif type == "lootrunCamp" then "lootrun-camp"
        elif type == "dungeon" then
          if (name | startswith("Corrupted ")) then "dungeon:corrupted"
          else "dungeon"
          end
        elif type == "raid" then "raid"
        elif type == "cave" then "cave"
        elif type == "Rune Shrines" then "shrine"
        elif type == "Grind Spots" then "grind-spot"
        else type
        end;

      map({
        featureId: (.name | gsub(" "; "-") | gsub("[^a-zA-Z0-9\\-]+"; "") | ascii_downcase),
        categoryId: ("wynntils:content:" + map_category(.type; .name)),
        attributes: (if .requirements.level then {
            label: .name,
            level: .requirements.level
        } else {
            label: .name
        } end),
        location: (.location // .coordinates)
    })'
}

# Read, transform, and write the JSON data from the primary source
primary_data=$(cat $CONTENT_DIR/raw/content/content_book_dump.json | jq '[
.dungeon[], .raid[], .bossAltar[], .lootrunCamp[], .cave[]
]' | transform_data)

# Read, transform, and write the JSON data from the secondary source, filtering for 'Rune Shrines' and 'Grind Spots'
secondary_data=$(cat "$CONTENT_DIR/combat_locations.json" | jq '[
.[] | select(.type == "Rune Shrines" or .type == "Grind Spots") |
{type, locations} | (.locations[] | 
{
    name: .name,
    coordinates: .coordinates,
    type: .type
}) + { type: .type }
]' | transform_data)

# Combine primary and secondary data
combined_data=$(echo "$primary_data" "$secondary_data" | jq -s add)

# Write the combined data to the output file
echo "$combined_data" > $OUTPUT_DIR/combat_mapfeatures.json

# Calculate md5sum of the new cave data
MD5=$(md5sum $OUTPUT_DIR/combat_mapfeatures.json | cut -d' ' -f1)

# Update urls.json with the new md5sum for dataStaticCombatMapFeatures
jq '. = [.[] | if (.id == "dataStaticCombatMapFeatures") then (.md5 = "'$MD5'") else . end]' < $BASE_DIR/Data-Storage/urls.json > $BASE_DIR/Data-Storage/urls.json.tmp

# If the temp file is different from the original, bump the version number
if ! cmp -s ../Data-Storage/urls.json ../Data-Storage/urls.json.tmp; then
    jq 'map(if has("version") then .version += 1 else . end)' < $BASE_DIR/Data-Storage/urls.json.tmp > $BASE_DIR/Data-Storage/urls.json
fi

rm $BASE_DIR/Data-Storage/urls.json.tmp