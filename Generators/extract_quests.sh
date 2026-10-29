#!/bin/bash

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"

DATA_STORAGE="$BASE_DIR/Data-Storage"
CONTENT_FILE="$DATA_STORAGE/raw/content/content_book_dump.json"
INTERNAL_NAMES_FILE="$DATA_STORAGE/quest_internal_names.json"
MISSING_QUESTS_FILE="$DATA_STORAGE/missing_quests.json"
OUTPUT_FILE="$BASE_DIR/Reference/quests.json"

mkdir -p "$(dirname "$OUTPUT_FILE")"

jq \
  --slurpfile internalNames "$INTERNAL_NAMES_FILE" \
  --slurpfile missingQuests "$MISSING_QUESTS_FILE" '
  (
    .quest
    | map(. as $quest | {
        key: ($internalNames[0][$quest.name] // $quest.name),
        value: {
          displayName: $quest.name,
          level: $quest.requirements.level,
          removed: false
        }
      })
    | from_entries
  ) as $dumpQuests
  |
  (
    $missingQuests[0] + $dumpQuests
    | to_entries
    | sort_by(.key)
    | from_entries
  )
' "$CONTENT_FILE" > "$OUTPUT_FILE"

# Calculate md5sum of the new quest data
MD5=$(md5sum "$OUTPUT_FILE" | cut -d' ' -f1)

# Update urls.json with the new md5sum for dataStaticQuests
jq '. = [.[] | if (.id == "dataStaticQuests") then (.md5 = "'$MD5'") else . end]' "$DATA_STORAGE/urls.json" > "$DATA_STORAGE/urls.json.tmp"
mv "$DATA_STORAGE/urls.json.tmp" "$DATA_STORAGE/urls.json"
