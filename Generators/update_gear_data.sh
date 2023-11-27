#!/bin/sh
# This script is used to update the gear data from the Wynncraft API.

TARGET_DIR=$(cd $(dirname "$0")/.. >/dev/null 2>&1 && pwd)/Reference

cd $TARGET_DIR

# Download the json file from Wynncraft API
wget -O gear.json.tmp "https://api.wynncraft.com/public_api.php?action=itemDB&category=all"

if [ ! -s gear.json.tmp ]; then
    rm gear.json.tmp
    echo "Error: Wynncraft API is not working, aborting"
    exit
fi

# Sort the items and keys in the json file, since the Wynncraft API is not stable in its order
# This will also get rid of the timestamp, which would mess up the md5sum
jq --sort-keys '{"items":  .items | sort_by(.name)}' < gear.json.tmp > gear.json.tmp2
# Delete zero and empty values to keep size down and readability up
jq -c 'del(..|select(. == 0 or . == null or . == "0-0"))' < gear.json.tmp2 > gear.json
rm gear.json.tmp gear.json.tmp2

# To be able to review new data, we also need an expanded, human-readable version
jq '.' < gear.json > gear_expanded.json

# Calculate md5sum of the new gear data
MD5=$(md5sum $TARGET_DIR/gear.json | cut -d' ' -f1)

# Update urls.json with the new md5sum for dataStaticGear
jq '. = [.[] | if (.id == "dataStaticGear") then (.md5 = "'$MD5'") else . end]' < ../Data-Storage/urls.json > ../Data-Storage/urls.json.tmp
mv ../Data-Storage/urls.json.tmp ../Data-Storage/urls.json
