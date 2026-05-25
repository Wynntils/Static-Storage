#!/bin/bash

TARGET_DIR=$(cd $(dirname "$0")/.. >/dev/null 2>&1 && pwd)/Reference

if [ -z "${WYNNCRAFT_API_KEY:-}" ]; then
    echo "Error: WYNNCRAFT_API_KEY is not set"
    exit 1
fi

AUTH_HEADER="Authorization: Bearer ${WYNNCRAFT_API_KEY}"

TARGET="map_raids.json"

wget --header="$AUTH_HEADER" -O "$TARGET_DIR/$TARGET.tmp" "https://api.wynncraft.com/v3/map/raids"

if [ ! -s "$TARGET_DIR/$TARGET.tmp" ]; then
    rm "$TARGET_DIR/$TARGET.tmp"
    echo "Error: Wynncraft API is not working, aborting"
    exit 1
fi

if jq -e '(length == 2 and has("message") and has("request_id")) or has("error")' "$TARGET_DIR/$TARGET.tmp" > /dev/null; then
    rm "$TARGET_DIR/$TARGET.tmp"
    echo "Error: Wynncraft API returned an error message, aborting"
    exit 1
fi

mv "$TARGET_DIR/$TARGET.tmp" "$TARGET_DIR/$TARGET"

MD5=$(md5sum "$TARGET_DIR/$TARGET" | cut -d' ' -f1)

jq '. = [.[] | if (.id == "dataStaticMapRaids") then (.md5 = "'$MD5'") else . end]' < "$TARGET_DIR/../Data-Storage/urls.json" > "$TARGET_DIR/../Data-Storage/urls.json.tmp"
mv "$TARGET_DIR/../Data-Storage/urls.json.tmp" "$TARGET_DIR/../Data-Storage/urls.json"
