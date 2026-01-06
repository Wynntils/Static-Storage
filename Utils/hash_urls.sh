#!/bin/bash

BASE_DIR="$(cd $(dirname "$0")/.. 2>/dev/null && pwd)"
JSON_FILE="$BASE_DIR/Data-Storage/urls.json"
TEMP_JSON_FILE="$BASE_DIR/Data-Storage/urls.json.tmp"

# Function to calculate and update md5 for valid JSON entries
update_md5() {
    local json_file="$1"

    # Create a new temporary JSON file
    jq -c '.[]' "$json_file" | while IFS= read -r obj; do
        if echo "$obj" | jq -e 'has("md5")' > /dev/null; then

            path=$(echo "$obj" | jq -r '.path')

            # Check if path field exists
            if [ "$path" != "null" ]; then
                # Determine the local file path
                local_file="$BASE_DIR/$path"

                # Check if the local file exists
                if [ -f "$local_file" ]; then
                    # Calculate the md5 checksum of the local file
                    new_md5=$(md5sum "$local_file" | awk '{ print $1 }')

                    # Get the current md5 from the object
                    current_md5=$(echo "$obj" | jq -r '.md5')

                    # Check if the md5 checksum has changed
                    if [ "$new_md5" != "$current_md5" ]; then
                        # Update the md5 field in the object
                        obj=$(echo "$obj" | jq --arg new_md5 "$new_md5" '.md5 = $new_md5')
                        echo "Updated md5 for $path" >&2
                    fi
                else
                    echo "Warning: Local file $local_file not found. Skipping." >&2
                fi
            else
                # Path missing
                echo "Warning: Skipping entry without path field" >&2
            fi
        fi

        # Append each (possibly updated) object to the temporary JSON file
        echo "$obj" | jq -c '.' >> "$TEMP_JSON_FILE"
    done

    # Format the output as a valid JSON array
    jq -s '.' "$TEMP_JSON_FILE" > "${TEMP_JSON_FILE}.formatted"
    mv "${TEMP_JSON_FILE}.formatted" "$TEMP_JSON_FILE"
}

# Check if the JSON file exists
if [ ! -f "$JSON_FILE" ]; then
    echo "Error: File $JSON_FILE not found." >&2
    exit 1
fi

# Ensure the temporary file is clean before we start
> "$TEMP_JSON_FILE"

# Update md5 checksums and write to a temporary file
update_md5 "$JSON_FILE"

# Replace the original JSON file with the updated one
mv "$TEMP_JSON_FILE" "$JSON_FILE"
