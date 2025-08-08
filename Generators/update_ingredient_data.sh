#!/bin/sh
# This script is used to update the ingredient data from the Wynncraft API.

TARGET_DIR=$(cd $(dirname "$0")/.. >/dev/null 2>&1 && pwd)/Reference

cd $TARGET_DIR

# Download the json file from Wynncraft API
curl -X POST -d '{"type":["ingredient"]}' -H "Content-Type: application/json" -o ingredients.json.tmp "https://api.wynncraft.com/v3/item/search?fullResult"

if [ ! -s ingredients.json.tmp ]; then
    rm ingredients.json.tmp
    echo "Error: Wynncraft API is not working, aborting"
    exit
fi

# Check if the file is a JSON with a "message" and "request_id" key or the "error" key is present
if jq -e '(length == 2 and has("message") and has("request_id")) or has("error")' ingredients.json.tmp > /dev/null; then
    rm ingredients.json.tmp
    echo "Error: Wynncraft API returned an error message, aborting"
    exit
fi

# Sort the items and keys in the json file, since the Wynncraft API is not stable in its order
jq --sort-keys < ingredients.json.tmp > ingredients.json.tmp2
# Minimalize the json file
jq -c < ingredients.json.tmp2 > ingredients.json
rm ingredients.json.tmp ingredients.json.tmp2

# To be able to review new data, we also need an expanded, human-readable version
jq '.' < ingredients.json > ingredients_expanded.json

# Calculate md5sum of the new ingredient data
MD5=$(md5sum $TARGET_DIR/ingredients.json | cut -d' ' -f1)

# Update ulrs.json with the new md5sum for dataStaticIngredients
jq '. = [.[] | if (.id == "dataStaticIngredients") then (.md5 = "'$MD5'") else . end]' < ../Data-Storage/urls.json > ../Data-Storage/urls.json.tmp
mv ../Data-Storage/urls.json.tmp ../Data-Storage/urls.json
