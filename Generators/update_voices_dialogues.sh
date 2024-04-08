#!/bin/bash
# This script will retrieve the latest version of shared/Sounds.java from
# the Voices of Wynn project repository, and parse it into a json file.
#
# Made by magicus (https://github.com/magicus)
#

base_dir="$(cd $(dirname "$0")/.. 2>/dev/null && pwd)"

TMPDIR=$(mktemp -dt wynntils-map.XXXXX)
if [[ ! -e $TMPDIR ]]; then
  echo "Failed to create temporary directory"
  exit 1
fi

# Download the json file from Wynncraft API
wget -O "$TMPDIR/Sounds.java" "https://raw.githubusercontent.com/Team-VoW/WynncraftVoiceProject/main/shared/Sounds.java"

# First use awk to convert the java source code to a simpler format looking like this:
# quest: "Kings Recruit"
# line: "[1/2] Caravan Driver: Agh!", "kingsrecruit-caravandriver-1", false, 45
awk -f "$base_dir/Generators/update_voices_dialogues_helper.awk" "$TMPDIR/Sounds.java" > "$TMPDIR/partial.txt"

# Then use perl to create a json file out of the partial results
perl "$base_dir/Generators/update_voices_dialogues_helper.pl" "$TMPDIR/partial.txt" > "$TMPDIR/output.json"

# Finally use jq to format the json file properly
TARGET_DIR="$base_dir/Reference"

jq -c . "$TMPDIR/output.json" > "$TARGET_DIR/dialogues.json"
jq . "$TMPDIR/output.json" > "$TARGET_DIR/dialogues_expanded.json"

rm -rf "$TMPDIR"
