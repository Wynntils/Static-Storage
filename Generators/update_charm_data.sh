#!/bin/sh
# This script is used to update the gear data from the Wynncraft API.

TARGET_DIR=$(cd $(dirname "$0")/.. >/dev/null 2>&1 && pwd)/Reference

cd $TARGET_DIR

# Download the json file from Wynncraft API
curl -X POST -d '{"type":["charm"]}' -H "Content-Type: application/json" -o charms.json.tmp "https://api.wynncraft.com/v3/item/search?fullResult=True"

if [ ! -s charms.json.tmp ]; then
    rm charms.json.tmp
    echo "Error: Wynncraft API is not working, aborting"
    exit
fi

# Check if the file is a JSON with a single "message" key
if jq -e 'length == 1 and has("message")' charms.json.tmp > /dev/null; then
    rm charms.json.tmp
    echo "Error: Wynncraft API returned an error message, aborting"
    exit
fi

# Sort the items and keys in the json file, since the Wynncraft API is not stable in its order
jq --sort-keys -r '.' < charms.json.tmp > charms.json.tmp2
# Minimalize the json file
jq -c < charms.json.tmp2 > charms.json
rm charms.json.tmp charms.json.tmp2

# To be able to review new data, we also need an expanded, human-readable version
jq '.' < charms.json > charms_expanded.json

# Calculate md5sum of the new gear data
MD5=$(md5sum $TARGET_DIR/charms.json | cut -d' ' -f1)

# Update urls.json with the new md5sum for dataStaticCharms
jq '. = [.[] | if (.id == "dataStaticCharms") then (.md5 = "'$MD5'") else . end]' < ../Data-Storage/urls.json > ../Data-Storage/urls.json.tmp
mv ../Data-Storage/urls.json.tmp ../Data-Storage/urls.json
