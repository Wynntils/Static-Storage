#!/bin/sh
# This script is used to update the gear data from the Wynncraft API.

TARGET_DIR=$(cd $(dirname "$0")/.. >/dev/null 2>&1 && pwd)/Reference

cd $TARGET_DIR

if [ -z "${WYNNCRAFT_API_KEY:-}" ]; then
    echo "Error: WYNNCRAFT_API_KEY is not set"
    exit 1
fi

AUTH_HEADER="Authorization: Bearer ${WYNNCRAFT_API_KEY}"

# Download the json file from Wynncraft API
curl -X POST -d '{"type":["tome"]}' -H "Content-Type: application/json" -H "$AUTH_HEADER" -o tomes.json.tmp "https://api.wynncraft.com/v3/item/search?fullResult"

if [ ! -s tomes.json.tmp ]; then
    rm tomes.json.tmp
    echo "Error: Wynncraft API is not working, aborting"
    exit
fi

# Check if the file is a JSON object with an API error payload
if jq -e 'type == "object" and ((has("message") and has("request_id")) or has("error"))' tomes.json.tmp > /dev/null; then
    rm tomes.json.tmp
    echo "Error: Wynncraft API returned an error message, aborting"
    exit
fi

# Reformat the API response to keep compatibility with the old key format (displayName as key)
# and then sort keys, since the Wynncraft API is not stable in its order.
jq -S 'if type == "array" then
        (map(
            if (.displayName // .name // .internalName) == null
            then error("Missing displayName/name/internalName in item payload")
            else { key: (.displayName // .name // .internalName), value: (del(.displayName)) }
            end
        ) | from_entries)
    else .
    end' < tomes.json.tmp > tomes.json.tmp2
# Minimalize the json file
jq -c < tomes.json.tmp2 > tomes.json
rm tomes.json.tmp tomes.json.tmp2

# To be able to review new data, we also need an expanded, human-readable version
jq '.' < tomes.json > tomes_expanded.json

# Calculate md5sum of the new gear data
MD5=$(md5sum $TARGET_DIR/tomes.json | cut -d' ' -f1)

# Update urls.json with the new md5sum for dataStaticTomes
jq '. = [.[] | if (.id == "dataStaticTomes") then (.md5 = "'$MD5'") else . end]' < ../Data-Storage/urls.json > ../Data-Storage/urls.json.tmp
mv ../Data-Storage/urls.json.tmp ../Data-Storage/urls.json
