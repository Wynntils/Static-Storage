#!/bin/bash

BASE_DIR="$(cd $(dirname "$0")/.. 2>/dev/null && pwd)"
ASSETS_DIR="$BASE_DIR/Generators/assets/minecraft/models/item"
OUTPUT_JSON="$BASE_DIR/Data-Storage/model_data.json"
TEMP_OUTPUT="$OUTPUT_JSON.tmp"

# Ensure resource pack exists
if [ ! -d "$BASE_DIR/Generators/assets" ]; then
  echo "Resource pack not found, place \"assets\" directory inside \"Generators\" directory"
  exit 1
fi

# Check the model_data file exists, otherwise create it
if [ ! -f "$OUTPUT_JSON" ]; then
  echo "model_data.json not found — creating a new one"
  echo "{}" > "$OUTPUT_JSON"
fi

# Ensure floats/ranges objects exist
jq '
  if .floats == null then .floats = {} else . end |
  if .ranges == null then .ranges = {} else . end
' "$OUTPUT_JSON" > "$TEMP_OUTPUT"
mv "$TEMP_OUTPUT" "$OUTPUT_JSON"

# Define the lookups
# Format: "key|filename|model_prefix|type"
# key is how the key used for lookup by the mod
# filename is what item file to search in, most will be potion.json
# model_prefix is what to look for in the file to count as the current model type
# type is how the value should be stored. Currently supports: raw, float or range
# raw is kept for compatibility with old clients, don't use for new entries
LOOKUPS=(
    "mythic_box|potion.json|item/wynn/loot/mythic|raw"
    "beacon_color|potion.json|item/wynn/gui/beacon/white|raw"
    "mythic_box|potion.json|item/wynn/loot/mythic|float"
    "beacon_color|potion.json|item/wynn/gui/beacon/white|float"
    "helmet|leather_helmet.json|item/wynn/armor/helmet|range"
    "chestplate|leather_chestplate.json|item/wynn/armor/chestplate|range"
    "leggings|leather_leggings.json|item/wynn/armor/leggings|range"
    "boots|leather_boots.json|item/wynn/armor/boots|range"
    "tome|potion.json|item/wynn/mastery_tome|range"
    "charm|potion.json|item/wynn/charm|range"
    "ring|potion.json|item/wynn/accessory/ring|range"
    "bracelet|potion.json|item/wynn/accessory/bracelet|range"
    "necklace|potion.json|item/wynn/accessory/necklace|range"
    "bow|potion.json|item/wynn/weapon/archer,item/wynn/skin/bow|range"
    "dagger|potion.json|item/wynn/weapon/assassin,item/wynn/skin/dagger|range"
    "wand|potion.json|item/wynn/weapon/mage,item/wynn/skin/wand|range"
    "relik|potion.json|item/wynn/weapon/shaman,item/wynn/skin/relik|range"
    "spear|potion.json|item/wynn/weapon/warrior,item/wynn/skin/spear|range"
    "helmet_skin|potion.json|item/wynn/skin/hat|range"
)

extract_values() {
  local file="$1"
  local prefix="$2"

  jq -r --arg p "$prefix" '
    .overrides[]
    | select(.model | startswith($p))
    | .predicate.custom_model_data
  ' "$file"
}

echo "Extracting model data..."
cp "$OUTPUT_JSON" "$TEMP_OUTPUT"

for entry in "${LOOKUPS[@]}"; do
  IFS="|" read -r key file prefix type <<< "$entry"
  full_path="$ASSETS_DIR/$file"

  if [ ! -f "$full_path" ]; then
    echo "Missing file: $full_path"
    continue
  fi

  IFS=',' read -r -a prefixes <<< "$prefix"

  values=()

  for p in "${prefixes[@]}"; do
    matches=($(extract_values "$full_path" "$p" | tr -d '\r'))
    values+=("${matches[@]}")
  done

  if [ ${#values[@]} -eq 0 ]; then
    echo "No values found for $key"
    continue
  fi

  case "$type" in

    "raw")
      raw="${values[0]}"
      val="${raw}.0"
      echo "Setting raw $key = $val"
      jq --arg k "$key" --argjson v "$val" \
         '.[$k] = $v' \
         "$TEMP_OUTPUT" > "${TEMP_OUTPUT}.new"
      mv "${TEMP_OUTPUT}.new" "$TEMP_OUTPUT"
      ;;

    "float")
      raw="${values[0]}"
      val="${raw}.0"
      echo "Setting float $key = $val"
      jq --arg k "$key" --argjson v "$val" \
         '.floats[$k] = $v' \
         "$TEMP_OUTPUT" > "${TEMP_OUTPUT}.new"
      mv "${TEMP_OUTPUT}.new" "$TEMP_OUTPUT"
      ;;

    "range")
      sorted=($(printf '%s\n' "${values[@]}" | tr -d '\r' | sort -n))
      min="${sorted[0]}.0"
      max="${sorted[-1]}.0"
      echo "Setting range $key = [$min, $max]"
      jq --arg k "$key" --arg lo "$min" --arg hi "$max" \
         '.ranges[$k] = [($lo | tonumber), ($hi | tonumber)]' \
         "$TEMP_OUTPUT" > "${TEMP_OUTPUT}.new"
      mv "${TEMP_OUTPUT}.new" "$TEMP_OUTPUT"
      ;;

  esac
done

mv "$TEMP_OUTPUT" "$OUTPUT_JSON"
echo "Model Data Updated"
