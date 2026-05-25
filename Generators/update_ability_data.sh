#!/bin/sh
# This script is used to update the ability tree data from the Wynncraft API.

BASE_DIR=$(cd $(dirname "$0")/.. >/dev/null 2>&1 && pwd)
TARGET_DIR="$BASE_DIR/Reference"
DATA_STORAGE="$BASE_DIR/Data-Storage"
GENERATORS_DIR=$(cd $(dirname "$0") >/dev/null 2>&1 && pwd)

cd "$TARGET_DIR"

if [ -z "${WYNNCRAFT_API_KEY:-}" ]; then
    echo "Error: WYNNCRAFT_API_KEY is not set"
    exit 1
fi

AUTH_HEADER="Authorization: Bearer ${WYNNCRAFT_API_KEY}"
ABILITY_MAP_FILE="ability_map.json"
echo "{}" > "$ABILITY_MAP_FILE"

# Fetch the authoritative class list from the Wynncraft API
curl -H "$AUTH_HEADER" -o classes.json.tmp "https://api.wynncraft.com/v3/classes"

if [ ! -s classes.json.tmp ]; then
    rm -f classes.json.tmp
    echo "Error: Wynncraft API is not working, aborting"
    exit 1
fi

if jq -e 'type == "object" and ((has("message") and has("request_id")) or has("error"))' classes.json.tmp > /dev/null; then
    rm -f classes.json.tmp
    echo "Error: Wynncraft API returned an error message, aborting"
    exit 1
fi

CLASSES=$(jq -r 'keys | join(" ")' classes.json.tmp)
rm -f classes.json.tmp

# Fetch ability tree for each class and save to raw files
for CLASS in $CLASSES; do
    curl -H "$AUTH_HEADER" -o "${CLASS}_abilities.json.tmp" "https://api.wynncraft.com/v3/ability/tree/$CLASS"

    if [ ! -s "${CLASS}_abilities.json.tmp" ]; then
        rm -f "${CLASS}_abilities.json.tmp"
        echo "Error: Wynncraft API is not working for $CLASS ability tree, aborting"
        exit 1
    fi

    if jq -e 'type == "object" and ((has("message") and has("request_id")) or has("error"))' "${CLASS}_abilities.json.tmp" > /dev/null; then
        rm -f "${CLASS}_abilities.json.tmp"
        echo "Error: Wynncraft API returned an error message for $CLASS ability tree, aborting"
        exit 1
    fi

    # Sort keys for stable diffs and save to raw ability_tree directory
    jq -S '.' < "${CLASS}_abilities.json.tmp" > "$DATA_STORAGE/raw/ability_tree/${CLASS}_abilities.json"
    rm -f "${CLASS}_abilities.json.tmp"
done

# Merge raw files into Reference/abilities.json and update its md5
chmod +x "$GENERATORS_DIR/merge_abilities.sh"
"$GENERATORS_DIR/merge_abilities.sh"

# Fetch ability map for each class and accumulate
for CLASS in $CLASSES; do
    curl -H "$AUTH_HEADER" -o "${CLASS}_ability_map.json.tmp" "https://api.wynncraft.com/v3/ability/map/$CLASS"

    if [ ! -s "${CLASS}_ability_map.json.tmp" ]; then
        rm -f "${CLASS}_ability_map.json.tmp"
        echo "Error: Wynncraft API is not working for $CLASS ability map, aborting"
        exit 1
    fi

    if jq -e 'type == "object" and ((has("message") and has("request_id")) or has("error"))' "${CLASS}_ability_map.json.tmp" > /dev/null; then
        rm -f "${CLASS}_ability_map.json.tmp"
        echo "Error: Wynncraft API returned an error message for $CLASS ability map, aborting"
        exit 1
    fi

    jq -c -s '.[0] * { "'"${CLASS}"'": .[1] }' "$ABILITY_MAP_FILE" "${CLASS}_ability_map.json.tmp" > "${ABILITY_MAP_FILE}.tmp"
    mv "${ABILITY_MAP_FILE}.tmp" "$ABILITY_MAP_FILE"
    rm -f "${CLASS}_ability_map.json.tmp"
done

# Sort top-level keys for stable diffs
jq -c 'to_entries | sort_by(.key) | from_entries' "$ABILITY_MAP_FILE" > "${ABILITY_MAP_FILE}.tmp"
mv "${ABILITY_MAP_FILE}.tmp" "$ABILITY_MAP_FILE"

# Write human-readable expanded copy for PR review
jq '.' < "$ABILITY_MAP_FILE" > ability_map_expanded.json

# Calculate md5 and update urls.json
MD5=$(md5sum "$TARGET_DIR/$ABILITY_MAP_FILE" | cut -d' ' -f1)

jq '. = [.[] | if (.id == "dataStaticAbilityMap") then (.md5 = "'$MD5'") else . end]' < "$DATA_STORAGE/urls.json" > "$DATA_STORAGE/urls.json.tmp"
mv "$DATA_STORAGE/urls.json.tmp" "$DATA_STORAGE/urls.json"
