#!/bin/sh
# This script is used to update the recipe data from the Wynncraft API.

TARGET_DIR=$(cd $(dirname "$0")/.. >/dev/null 2>&1 && pwd)/Reference

cd $TARGET_DIR

if [ -z "${WYNNCRAFT_API_KEY:-}" ]; then
    echo "Error: WYNNCRAFT_API_KEY is not set"
    exit 1
fi

AUTH_HEADER="Authorization: Bearer ${WYNNCRAFT_API_KEY}"

# Download the json file from Wynncraft API
curl -H "$AUTH_HEADER" -o recipes.json.tmp "https://api.wynncraft.com/v3/item/recipe/database?full_result"

if [ ! -s recipes.json.tmp ]; then
    rm recipes.json.tmp
    echo "Error: Wynncraft API is not working, aborting"
    exit
fi

# Check if the file is a JSON object with an API error payload
if jq -e 'type == "object" and ((has("message") and has("request_id")) or has("error"))' recipes.json.tmp > /dev/null; then
    rm recipes.json.tmp
    echo "Error: Wynncraft API returned an error message, aborting"
    exit
fi

# Reformat the API response to use internalName as the key, then sort keys.
jq -S 'if type == "array" then
        (map(
            if .internalName == null
            then error("Missing internalName in recipe payload")
            else { key: .internalName, value: (del(.internalName)) }
            end
        ) | from_entries)
    else .
    end' < recipes.json.tmp > recipes.json.tmp2
# Minimalize the json file
jq -c < recipes.json.tmp2 > recipes.json
rm recipes.json.tmp recipes.json.tmp2

# To be able to review new data, we also need an expanded, human-readable version
jq '.' < recipes.json > recipes_expanded.json

# Calculate md5sum of the new recipe data
MD5=$(md5sum $TARGET_DIR/recipes.json | cut -d' ' -f1)

# Update urls.json with the new md5sum for dataStaticRecipes
jq '. = [.[] | if (.id == "dataStaticRecipes") then (.md5 = "'$MD5'") else . end]' < ../Data-Storage/urls.json > ../Data-Storage/urls.json.tmp
mv ../Data-Storage/urls.json.tmp ../Data-Storage/urls.json
