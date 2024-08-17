#!/bin/sh
# This script is used to update the gear data from the Wynncraft API.

TARGET_DIR=$(cd $(dirname "$0")/.. >/dev/null 2>&1 && pwd)/Reference

cd $TARGET_DIR

# Download the json file from Wynncraft API
curl -X POST -d '{"type":["tomes"]}' -H "Content-Type: application/json" -o tomes.json.tmp "https://api.wynncraft.com/v3/item/search?fullResult=True"

if [ ! -s tomes.json.tmp ]; then
    rm tomes.json.tmp
    echo "Error: Wynncraft API is not working, aborting"
    exit
fi

# Check if the file is a JSON with a single "message" key
if jq -e 'length == 1 and has("message")' tomes.json.tmp > /dev/null; then
    rm tomes.json.tmp
    echo "Error: Wynncraft API returned an error message, aborting"
    exit
fi

# Sort the items and keys in the json file, since the Wynncraft API is not stable in its order
jq --sort-keys -r '.' < tomes.json.tmp > tomes.json.tmp2
# Minimalize the json file
jq -c < tomes.json.tmp2 > tomes.json
rm tomes.json.tmp tomes.json.tmp2

# To be able to review new data, we also need an expanded, human-readable version
jq '.' < tomes.json > tomes_expanded.json

# Calculate md5sum of the new gear data
MD5=$(md5sum $TARGET_DIR/tomes.json | cut -d' ' -f1)

# Update urls.json with the new md5sum for dataStaticTomes
jq '. = [.[] | if (.id == "dataStaticTomes") then (.md5 = "'$MD5'") else . end]' < ../Data-Storage/urls.json > ../Data-Storage/urls.json.tmp

# If the temp file is different from the original, bump the version number
if ! cmp -s ../Data-Storage/urls.json ../Data-Storage/urls.json.tmp; then
    jq 'map(if has("version") then .version += 1 else . end)' < ../Data-Storage/urls.json.tmp > ../Data-Storage/urls.json
fi

rm ../Data-Storage/urls.json.tmp