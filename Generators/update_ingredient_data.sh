#!/bin/sh
# This script is used to update the ingredient data from the Wynncraft API.

TARGET_DIR=$(cd $(dirname "$0")/.. >/dev/null 2>&1 && pwd)/Reference

cd $TARGET_DIR

# Download the json file from Wynncraft API
# FIXME Use prod API
curl -X POST -d '{"type":["ingredients"]}' -H "Content-Type: application/json" -o ingredients.json.tmp "https://api.wynncraft.com/v3/item/search?fullResult=True"

if [ ! -s ingredients.json.tmp ]; then
    rm ingredients.json.tmp
    echo "Error: Wynncraft API is not working, aborting"
    exit
fi

# Sort the items and keys in the json file, since the Wynncraft API is not stable in its order
# This will also get rid of the timestamp, which would mess up the md5sum
jq --sort-keys < ingredients.json.tmp > ingredients.json.tmp2
# Minimalize the json file
jq -c < ingredients.json.tmp2 > advanced_ingredients.json
rm ingredients.json.tmp ingredients.json.tmp2

# To be able to review new data, we also need an expanded, human-readable version
jq '.' < advanced_ingredients.json > advanced_ingredients_expanded.json

# Calculate md5sum of the new ingredient data
MD5=$(md5sum $TARGET_DIR/advanced_ingredients.json | cut -d' ' -f1)

# Update ulrs.json with the new md5sum for dataStaticIngredientsAdvanced
jq '. = [.[] | if (.id == "dataStaticIngredientsAdvanced") then (.md5 = "'$MD5'") else . end]' < ../Data-Storage/urls.json > ../Data-Storage/urls.json.tmp
mv ../Data-Storage/urls.json.tmp ../Data-Storage/urls.json
