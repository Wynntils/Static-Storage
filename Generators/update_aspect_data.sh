#!/bin/sh
# This script is used to update the aspect data from the Wynncraft API.

TARGET_DIR=$(cd $(dirname "$0")/.. >/dev/null 2>&1 && pwd)/Reference

cd $TARGET_DIR

ASPECTS_FILE="aspects.json"
echo "{}" > $ASPECTS_FILE

# Download the class info from the Wynncraft API
curl -o classes.json.tmp "https://api.wynncraft.com/v3/classes"

if [ ! -s classes.json.tmp ]; then
    rm classes.json.tmp
    echo "Error: Wynncraft API is not working, aborting"
    exit
fi

# Check if the file is a JSON with a single "message" key
if jq -e 'length == 1 and has("message")' classes.json.tmp > /dev/null; then
    rm classes.json.tmp
    echo "Error: Wynncraft API returned an error message, aborting"
    exit
fi

# Parse the available classes from the JSON file
ASPECT_CLASSES=$(jq -r 'keys | join(" ")' classes.json.tmp)
rm classes.json.tmp

for CLASS in $ASPECT_CLASSES; do
    # Download the json file for each class' aspects
    curl -o ${CLASS}_aspects.json.tmp "https://api.wynncraft.com/v3/aspects/$CLASS"

    if [ ! -s ${CLASS}_aspects.json.tmp ]; then
        rm ${CLASS}_aspects.json.tmp
        echo "Error: Wynncraft API is not working for $CLASS, aborting"
        exit
    fi

    # Check if the file is a JSON with a single "message" key
    if jq -e 'length == 1 and has("message")' ${CLASS}_aspects.json.tmp > /dev/null; then
        rm ${CLASS}_aspects.json.tmp
        echo "Error: Wynncraft API returned an error message for $CLASS, aborting"
        exit
    fi

    # Sort the items and keys in the json file, since the Wynncraft API is not stable in its order
    jq --sort-keys < ${CLASS}_aspects.json.tmp > ${CLASS}_aspects.json.tmp2
    # Run the Python script to save the class file with the HTML description parsed to JSON
    python ../Utils/html_parser.py ${CLASS}_aspects.json.tmp2 ${CLASS}_aspects.json false
    rm ${CLASS}_aspects.json.tmp ${CLASS}_aspects.json.tmp2

    # Create/merge the minimized version
    jq -c -s '.[0] * { "'"${CLASS}"'": .[1] }' $ASPECTS_FILE ${CLASS}_aspects.json > ${ASPECTS_FILE}.tmp
    mv ${ASPECTS_FILE}.tmp $ASPECTS_FILE

    rm ${CLASS}_aspects.json
done

# To be able to review new data, we also need an expanded, human-readable version
jq '.' < aspects.json > aspects_expanded.json

# Calculate MD5 checksum for the combined single-line JSON file
MD5=$(md5sum $ASPECTS_FILE | cut -d' ' -f1)

# Update the urls.json file with the new MD5 checksum
jq '. = [.[] | if (.id == "dataStaticAspects") then (.md5 = "'$MD5'") else . end]' < ../Data-Storage/urls.json > ../Data-Storage/urls.json.tmp
mv ../Data-Storage/urls.json.tmp ../Data-Storage/urls.json
