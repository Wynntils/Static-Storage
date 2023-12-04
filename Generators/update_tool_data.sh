#!/bin/sh
# This script is used to update the gear data from the Wynncraft API.

TARGET_DIR=$(cd $(dirname "$0")/.. >/dev/null 2>&1 && pwd)/Reference

cd $TARGET_DIR

# Download the json file from Wynncraft API
# FIXME: Use release v3 API
curl -X POST -d '{"type":["tools"]}' -H "Content-Type: application/json" -o tools.json.tmp "https://api.wynncraft.com/v3-dev/item/search?fullResult=True"

if [ ! -s tools.json.tmp ]; then
    rm tools.json.tmp
    echo "Error: Wynncraft API is not working, aborting"
    exit
fi

# Sort the items and keys in the json file, since the Wynncraft API is not stable in its order
# This will also get rid of the timestamp, which would mess up the md5sum
jq --sort-keys -r '.' < tools.json.tmp > tools.json.tmp2
# Minimalize the json file
jq -c < tools.json.tmp2 > tools.json
rm tools.json.tmp tools.json.tmp2

# To be able to review new data, we also need an expanded, human-readable version
jq '.' < tools.json > tools_expanded.json

# Calculate md5sum of the new gear data
MD5=$(md5sum $TARGET_DIR/tools.json | cut -d' ' -f1)

# Update urls.json with the new md5sum for dataStaticTools
jq '. = [.[] | if (.id == "dataStaticTools") then (.md5 = "'$MD5'") else . end]' < ../Data-Storage/urls.json > ../Data-Storage/urls.json.tmp
mv ../Data-Storage/urls.json.tmp ../Data-Storage/urls.json
