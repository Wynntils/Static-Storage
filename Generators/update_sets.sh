#!/bin/sh
# This script is used to update the set bonus data from the Wynncraft API.

TARGET_DIR=$(cd $(dirname "$0")/.. >/dev/null 2>&1 && pwd)/Reference

cd $TARGET_DIR

if [ -z "${WYNNCRAFT_API_KEY:-}" ]; then
    echo "Error: WYNNCRAFT_API_KEY is not set"
    exit 1
fi

AUTH_HEADER="Authorization: Bearer ${WYNNCRAFT_API_KEY}"

# Download the json file from Wynncraft API
curl -H "$AUTH_HEADER" -o sets.json.tmp "https://api.wynncraft.com/v3/item/sets"

if [ ! -s sets.json.tmp ]; then
    rm sets.json.tmp
    echo "Error: Wynncraft API is not working, aborting"
    exit
fi

# Check if the file is a JSON with a "message" and "request_id" key or the "error" key is present
if jq -e '(length == 2 and has("message") and has("request_id")) or has("error")' sets.json.tmp > /dev/null; then
    rm sets.json.tmp
    echo "Error: Wynncraft API returned an error message, aborting"
    exit
fi

# Sort the items and keys in the json file, since the Wynncraft API is not stable in its order
jq --sort-keys -r '.' < sets.json.tmp > sets.json.tmp2
# Minimalize the json file
jq -c < sets.json.tmp2 > sets.json
rm sets.json.tmp sets.json.tmp2

# To be able to review new data, we also need an expanded, human-readable version
jq '.' < sets.json > sets_expanded.json

# Calculate md5sum of the new gear data
MD5=$(md5sum $TARGET_DIR/sets.json | cut -d' ' -f1)

# Update urls.json with the new md5sum for dataStaticSets
jq '. = [.[] | if (.id == "dataStaticSets") then (.md5 = "'$MD5'") else . end]' < ../Data-Storage/urls.json > ../Data-Storage/urls.json.tmp
mv ../Data-Storage/urls.json.tmp ../Data-Storage/urls.json
