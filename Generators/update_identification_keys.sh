#!/bin/bash

TARGET_DIR=$(cd $(dirname "$0")/.. >/dev/null 2>&1 && pwd)/Reference

cd $TARGET_DIR

# Download the json file from Wynncraft API
wget -O gear.json.tmp "https://api.wynncraft.com/v3/item/database?fullResult=True"

if [ ! -s gear.json.tmp ]; then
    rm gear.json.tmp
    echo "Error: Wynncraft API is not working, aborting"
    exit
fi

jq --sort-keys '[to_entries[] | .value | (.identifications | to_entries[] | .key)?] | unique' < gear.json.tmp > gear_ids.json.tmp

rm gear.json.tmp

