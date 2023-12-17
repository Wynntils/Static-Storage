#!/bin/bash

TARGET_DIR=$(cd $(dirname "$0")/.. >/dev/null 2>&1 && pwd)/Reference

cd $TARGET_DIR

# Download the json file from Wynncraft API
wget -O metadata.json.tmp "https://api.wynncraft.com/v3/item/metadata"

if [ ! -s metadata.json.tmp ]; then
    rm metadata.json.tmp
    echo "Error: Wynncraft API is not working, aborting"
    exit
fi

jq --sort-keys '.identifications | sort | values[]' < metadata.json.tmp > ids.tmp

rm metadata.json.tmp

# Create id_keys.json, if it doesn't exist
if [ ! -f id_keys.json ]; then
    echo "{}" > id_keys.json
fi

# Get the last id in the file
last_id=$(jq '[.| to_entries[] | .value | tonumber] | max' < id_keys.json)
next_id=$((last_id + 1))

# If the file is empty, set the next_id to 0
if [ "$last_id" == "null" ]; then
    next_id=0
fi

# Read the ids.json.tmp file, and put ids that are not present as keys into the file with the next available id
while IFS= read -r id; do
    if jq -e --argjson id "$id" 'has($id)' < id_keys.json >/dev/null 2>&1; then
        continue
    fi

    jq --argjson id "$id" --argjson next_id "$next_id" '. + {($id): $next_id}' < id_keys.json > id_keys.json.tmp
    mv id_keys.json.tmp id_keys.json
    next_id=$((next_id + 1))
done < ids.tmp

# Sort id_keys.json
jq -s 'sort_by(.| to_entries[] | .value) | .[]' < id_keys.json > id_keys.json.tmp
mv id_keys.json.tmp id_keys.json

rm ids.tmp

MD5=$(md5sum $TARGET_DIR/id_keys.json | cut -d' ' -f1)

# Update ulrs.json with the new md5sum for dataStaticIdentificationKeys
jq '. = [.[] | if (.id == "dataStaticIdentificationKeys") then (.md5 = "'$MD5'") else . end]' < ../Data-Storage/urls.json > ../Data-Storage/urls.json.tmp
mv ../Data-Storage/urls.json.tmp ../Data-Storage/urls.json