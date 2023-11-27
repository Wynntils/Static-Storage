#!/bin/sh
# This script is used to update the ingredient data from the Wynncraft API.

TARGET_DIR=$(cd $(dirname "$0")/.. >/dev/null 2>&1 && pwd)/Reference

cd $TARGET_DIR

# Download the json file from Wynncraft API
wget -O ingredients.json.tmp "https://api.wynncraft.com/v2/ingredient/search/skills/%5Etailoring,armouring,jeweling,cooking,woodworking,weaponsmithing,alchemism,scribing"

if [ ! -s ingredients.json.tmp ]; then
    rm ingredients.json.tmp
    echo "Error: Wynncraft API is not working, aborting"
    exit
fi

# Sort the items and keys in the json file, since the Wynncraft API is not stable in its order
# This will also get rid of the timestamp, which would mess up the md5sum
jq --sort-keys '{"ingredients":  .data | sort_by(.name)}' < ingredients.json.tmp > ingredients.json.tmp2
# Delete zero and empty values, and then objects that get empty, to keep size down and readability up
jq -c 'del(..|select(. == 0 or . == null)) | del(..|select( . == {}))' < ingredients.json.tmp2 > ingredients.json
rm ingredients.json.tmp ingredients.json.tmp2

# To be able to review new data, we also need an expanded, human-readable version
jq '.' < ingredients.json > ingredients_expanded.json

# Calculate md5sum of the new ingredient data
MD5=$(md5sum $TARGET_DIR/ingredients.json | cut -d' ' -f1)

# Update urls.json with the new md5sum for dataStaticIngredients
jq '. = [.[] | if (.id == "dataStaticIngredients") then (.md5 = "'$MD5'") else . end]' < ../Data-Storage/urls.json > ../Data-Storage/urls.json.tmp
mv ../Data-Storage/urls.json.tmp ../Data-Storage/urls.json
