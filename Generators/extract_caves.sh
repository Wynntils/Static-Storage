#!/bin/bash

BASE_DIR="$(cd $(dirname "$0")/.. 2>/dev/null && pwd)"

CONTENT_DIR=$BASE_DIR/Data-Storage/raw/content
OUTPUT_DIR=$BASE_DIR/Reference

mkdir -p $OUTPUT_DIR
cat $CONTENT_DIR/content_book_dump.json | jq '.cave' | jq '.[].requirements |= .level' > $OUTPUT_DIR/caves.json

# Calculate md5sum of the new cave data
MD5=$(md5sum $OUTPUT_DIR/caves.json | cut -d' ' -f1)

# Update urls.json with the new md5sum for dataStaticCaveInfo
jq '. = [.[] | if (.id == "dataStaticCaveInfo") then (.md5 = "'$MD5'") else . end]' < $BASE_DIR/Data-Storage/urls.json > $BASE_DIR/Data-Storage/urls.json.tmp

# If the temp file is different from the original, bump the version number
if ! cmp -s ../Data-Storage/urls.json ../Data-Storage/urls.json.tmp; then
    jq 'map(if has("version") then .version += 1 else . end)' < $BASE_DIR/Data-Storage/urls.json.tmp > $BASE_DIR/Data-Storage/urls.json
fi

rm $BASE_DIR/Data-Storage/urls.json.tmp