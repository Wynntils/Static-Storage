#!/bin/bash

BASE_DIR="$(cd $(dirname "$0")/.. 2>/dev/null && pwd)"
ASSETS_DIR="$BASE_DIR/Generators/assets/minecraft/items"
OUTPUT_JSON="$BASE_DIR/Data-Storage/model_data.json"
TEMP_OUTPUT="$OUTPUT_JSON.tmp"

# All items come under item/wynn
MODEL_BASE="item/wynn"

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

# Define the looks
# 2 Formats
# 1. "key|model_suffix"
# 2. "key|model_suffix|type"
# key is how the mod will lookup the model data
# model_suffix is what comes after the "item/wynn/" for the model. Can be defined in the lookup or ignored and it will
# need to be defined in the process_group call.
# If looking for multiple model types, separate them with a "," e.g. "weapon/archer,skin/bow"
# type is how the value should be stored. Currently supports: float or range. Not including one will assume float
# Split lookups per item, define the filename when calling process_group
LOOKUPS_BOWS=(
  "bow.basicWood|bow_basic_wood"
  "bow.basicGold|bow_basic_gold"
  "bow.air1|bow_air_a"
  "bow.air2|bow_air_b"
  "bow.air3|bow_air_c"
  "bow.earth1|bow_earth_a"
  "bow.earth2|bow_earth_b"
  "bow.earth3|bow_earth_c"
  "bow.fire1|bow_fire_a"
  "bow.fire2|bow_fire_b"
  "bow.fire3|bow_fire_c"
  "bow.thunder1|bow_thunder_a"
  "bow.thunder2|bow_thunder_b"
  "bow.thunder3|bow_thunder_c"
  "bow.water1|bow_water_a"
  "bow.water2|bow_water_b"
  "bow.water3|bow_water_c"
  "bow.multi1|bow_multi_a"
  "bow.multi2|bow_multi_b"
  "bow.multi3|bow_multi_c"
)
  
LOOKUPS_DAGGERS=(
  "dagger.basicWood|dagger_basic_wood"
  "dagger.basicGold|dagger_basic_gold"
  "dagger.air1|dagger_air_a"
  "dagger.air2|dagger_air_b"
  "dagger.air3|dagger_air_c"
  "dagger.earth1|dagger_earth_a"
  "dagger.earth2|dagger_earth_b"
  "dagger.earth3|dagger_earth_c"
  "dagger.fire1|dagger_fire_a"
  "dagger.fire2|dagger_fire_b"
  "dagger.fire3|dagger_fire_c"
  "dagger.thunder1|dagger_thunder_a"
  "dagger.thunder2|dagger_thunder_b"
  "dagger.thunder3|dagger_thunder_c"
  "dagger.water1|dagger_water_a"
  "dagger.water2|dagger_water_b"
  "dagger.water3|dagger_water_c"
  "dagger.multi1|dagger_multi_a"
  "dagger.multi2|dagger_multi_b"
  "dagger.multi3|dagger_multi_c"
)
  
LOOKUPS_WANDS=(
  "wand.basicWood|wand_basic_wood"
  "wand.basicGold|wand_basic_gold"
  "wand.basicDiamond|wand_basic_diamond"
  "wand.air1|wand_air_a"
  "wand.air2|wand_air_b"
  "wand.air3|wand_air_c"
  "wand.earth1|wand_earth_a"
  "wand.earth2|wand_earth_b"
  "wand.earth3|wand_earth_c"
  "wand.fire1|wand_fire_a"
  "wand.fire2|wand_fire_b"
  "wand.fire3|wand_fire_c"
  "wand.thunder1|wand_thunder_a"
  "wand.thunder2|wand_thunder_b"
  "wand.thunder3|wand_thunder_c"
  "wand.water1|wand_water_a"
  "wand.water2|wand_water_b"
  "wand.water3|wand_water_c"
  "wand.multi1|wand_multi_a"
  "wand.multi2|wand_multi_b"
  "wand.multi3|wand_multi_c"
)
  
LOOKUPS_RELIKS=(
  "relik.basicWood|relik_basic_wooden"
  "relik.basicGold|relik_basic_gold"
  "relik.air1|relik_air_a"
  "relik.air2|relik_air_b"
  "relik.air3|relik_air_c"
  "relik.earth1|relik_earth_a"
  "relik.earth2|relik_earth_b"
  "relik.earth3|relik_earth_c"
  "relik.fire1|relik_fire_a"
  "relik.fire2|relik_fire_b"
  "relik.fire3|relik_fire_c"
  "relik.thunder1|relik_thunder_a"
  "relik.thunder2|relik_thunder_b"
  "relik.thunder3|relik_thunder_c"
  "relik.water1|relik_water_a"
  "relik.water2|relik_water_b"
  "relik.water3|relik_water_c"
  "relik.multi1|relik_multi_a"
  "relik.multi2|relik_multi_b"
  "relik.multi3|relik_multi_c"
)
  
LOOKUPS_SPEARS=(
  "spear.basicWood|spear_basic_wood"
  "spear.basicGold|spear_basic_gold"
  "spear.air1|spear_air_a"
  "spear.air2|spear_air_b"
  "spear.air3|spear_air_c"
  "spear.earth1|spear_earth_a"
  "spear.earth2|spear_earth_b"
  "spear.earth3|spear_earth_c"
  "spear.fire1|spear_fire_a"
  "spear.fire2|spear_fire_b"
  "spear.fire3|spear_fire_c"
  "spear.thunder1|spear_thunder_a"
  "spear.thunder2|spear_thunder_b"
  "spear.thunder3|spear_thunder_c"
  "spear.water1|spear_water_a"
  "spear.water2|spear_water_b"
  "spear.water3|spear_water_c"
  "spear.multi1|spear_multi_a"
  "spear.multi2|spear_multi_b"
  "spear.multi3|spear_multi_c"
)
  
LOOKUPS_RINGS=(
  "ring.basicIron|ring_base_a"
  "ring.basicGold|ring_base_b"
  "ring.basicGem|ring_special_c"
  "ring.basicPearl|ring_special_b"
  "ring.basicWedding|ring_special_a"
  "ring.air1|ring_air_a"
  "ring.air2|ring_air_b"
  "ring.earth1|ring_earth_a"
  "ring.earth2|ring_earth_b"
  "ring.fire1|ring_fire_a"
  "ring.fire2|ring_fire_b"
  "ring.thunder1|ring_thunder_a"
  "ring.thunder2|ring_thunder_b"
  "ring.water1|ring_water_a"
  "ring.water2|ring_water_b"
  "ring.multi1|ring_multi_a"
  "ring.multi2|ring_multi_b"
)
  
LOOKUPS_BRACELETS=(
  "bracelet.basicIron|bracelet_base_a"
  "bracelet.basicGold|bracelet_base_b"
  "bracelet.air1|bracelet_air_a"
  "bracelet.air2|bracelet_air_b"
  "bracelet.earth1|bracelet_earth_a"
  "bracelet.earth2|bracelet_earth_b"
  "bracelet.fire1|bracelet_fire_a"
  "bracelet.fire2|bracelet_fire_b"
  "bracelet.thunder1|bracelet_thunder_a"
  "bracelet.thunder2|bracelet_thunder_b"
  "bracelet.water1|bracelet_water_a"
  "bracelet.water2|bracelet_water_b"
  "bracelet.multi1|bracelet_multi_a"
  "bracelet.multi2|bracelet_multi_b"
)
  
LOOKUPS_NECKLACES=(
  "necklace.basicIron|necklace_base_a"
  "necklace.basicGold|necklace_base_b"
  "necklace.basicCross|necklace_special_a"
  "necklace.basicBroach|necklace_special_b"
  "necklace.basicPearl|necklace_special_c"
  "necklace.air1|necklace_air_a"
  "necklace.air2|necklace_air_b"
  "necklace.earth1|necklace_earth_a"
  "necklace.earth2|necklace_earth_b"
  "necklace.fire1|necklace_fire_a"
  "necklace.fire2|necklace_fire_b"
  "necklace.thunder1|necklace_thunder_a"
  "necklace.thunder2|necklace_thunder_b"
  "necklace.water1|necklace_water_a"
  "necklace.water2|necklace_water_b"
  "necklace.multi1|necklace_multi_a"
  "necklace.multi2|necklace_multi_b"
)

LOOKUPS_CHARMS=(
  "charm.worm|worm"
  "charm.light|light"
  "charm.stone|stone"
  "charm.void|void"
)

LOOKUPS_TOMES=(
  "tome.armour|armour"
  "tome.guild|guild"
  "tome.lootrun|lootrun"
  "tome.mana|mana"
  "tome.movement|movement"
  "tome.utility|utility"
  "tome.weapon|weapon"
)

LOOKUPS_MISC=(
  "mythic_box|loot/mythic"
  "beacon_color|gui/beacon/white"
  "corkian_amplifier|augment/corkian_amplifier"
  "corkian_insulator|augment/corkian_insulator"
  "corkian_simulator|augment/corkian_simulator"
  "dungeon_key|dungeon/key"
  "dungeon_key_broken|dungeon/key_broken"
  "rune_az|rune/az"
  "rune_nii|rune/nii"
  "rune_uth|rune/uth"
  "rune_tol|rune/tol"
  "rune_ek|rune/ek"
  "abilityTree.aspectArcher|gui/ability_tree/aspect/archer"
  "abilityTree.aspectAssassin|gui/ability_tree/aspect/assassin"
  "abilityTree.aspectMage|gui/ability_tree/aspect/mage"
  "abilityTree.aspectShaman|gui/ability_tree/aspect/shaman"
  "abilityTree.aspectWarrior|gui/ability_tree/aspect/warrior"
  "tome|mastery_tome|range"
  "charm|charm|range"
  "ring|accessory/ring|range"
  "bracelet|accessory/bracelet|range"
  "necklace|accessory/necklace|range"
  "bow|weapon/archer,skin/bow|range"
  "dagger|weapon/assassin,skin/dagger|range"
  "wand|weapon/mage,skin/wand|range"
  "relik|weapon/shaman,skin/relik|range"
  "spear|weapon/warrior,skin/spear|range"
  "helmet_skin|skin/hat|range"
)

LOOKUPS_LEATHER_HELMET=(
  "helmet.pale_leather|armor/helmet/pale_leather_helmet"
  "helmet.chainmail|armor/helmet/chainmail_helmet"
  "helmet.pale_chainmail|armor/helmet/pale_chainmail_helmet"
  "helmet.iron|armor/helmet/iron_helmet"
  "helmet.pale_iron|armor/helmet/pale_iron_helmet"
  "helmet.gold|armor/helmet/gold_helmet"
  "helmet.pale_gold|armor/helmet/pale_gold_helmet"
  "helmet.diamond|armor/helmet/diamond_helmet"
  "helmet.pale_diamond|armor/helmet/pale_diamond_helmet"
  "helmet.titanium|armor/helmet/titanium_helmet"
  "helmet.pale_titanium|armor/helmet/pale_titanium_helmet"
  "helmet|armor/helmet|range"
)

LOOKUPS_LEATHER_CHESTPLATE=(
  "chestplate.pale_leather|armor/chestplate/pale_leather_chestplate"
  "chestplate.chainmail|armor/chestplate/chainmail_chestplate"
  "chestplate.pale_chainmail|armor/chestplate/pale_chainmail_chestplate"
  "chestplate.iron|armor/chestplate/iron_chestplate"
  "chestplate.pale_iron|armor/chestplate/pale_iron_chestplate"
  "chestplate.gold|armor/chestplate/gold_chestplate"
  "chestplate.pale_gold|armor/chestplate/pale_gold_chestplate"
  "chestplate.diamond|armor/chestplate/diamond_chestplate"
  "chestplate.pale_diamond|armor/chestplate/pale_diamond_chestplate"
  "chestplate.titanium|armor/chestplate/titanium_chestplate"
  "chestplate.pale_titanium|armor/chestplate/pale_titanium_chestplate"
  "chestplate|armor/chestplate|range"
)

LOOKUPS_LEATHER_LEGGINGS=(
  "leggings.pale_leather|armor/leggings/pale_leather_leggings"
  "leggings.chainmail|armor/leggings/chainmail_leggings"
  "leggings.pale_chainmail|armor/leggings/pale_chainmail_leggings"
  "leggings.iron|armor/leggings/iron_leggings"
  "leggings.pale_iron|armor/leggings/pale_iron_leggings"
  "leggings.gold|armor/leggings/gold_leggings"
  "leggings.pale_gold|armor/leggings/pale_gold_leggings"
  "leggings.diamond|armor/leggings/diamond_leggings"
  "leggings.pale_diamond|armor/leggings/pale_diamond_leggings"
  "leggings.titanium|armor/leggings/titanium_leggings"
  "leggings.pale_titanium|armor/leggings/pale_titanium_leggings"
  "leggings|armor/leggings|range"
)

LOOKUPS_LEATHER_BOOTS=(
  "boots.pale_leather|armor/boots/pale_leather_boots"
  "boots.chainmail|armor/boots/chainmail_boots"
  "boots.pale_chainmail|armor/boots/pale_chainmail_boots"
  "boots.iron|armor/boots/iron_boots"
  "boots.pale_iron|armor/boots/pale_iron_boots"
  "boots.gold|armor/boots/gold_boots"
  "boots.pale_gold|armor/boots/pale_gold_boots"
  "boots.diamond|armor/boots/diamond_boots"
  "boots.pale_diamond|armor/boots/pale_diamond_boots"
  "boots.titanium|armor/boots/titanium_boots"
  "boots.pale_titanium|armor/boots/pale_titanium_boots"
  "boots|armor/boots|range"
)

extract_values() {
  local file="$1"
  local prefix="$2"

  jq -r --arg p "$prefix" '
    [
      (
        .overrides[]?
        | select(.model? | type == "string")
        | select(.model | startswith($p))
        | .predicate.custom_model_data?
      ),
      (
        .. | objects
        | select(has("threshold"))
        | select(.model.model? | type == "string")
        | select(.model.model | startswith($p))
        | .threshold
      )
    ]
    | flatten[]
    | select(. != null)
    | tonumber
  ' "$file"
}

process_group() {
  local file="$1"
  local group_base="$2"
  shift 2
  local entries=("$@")

  local full_path="$ASSETS_DIR/$file"

  if [ ! -f "$full_path" ]; then
    echo "Missing file: $full_path"
    return
  fi

  for entry in "${entries[@]}"; do
    IFS="|" read -r key prefix type <<< "$entry"
    # Assume float if no type provided
    type="${type:-float}"

    IFS=',' read -r -a raw_prefixes <<< "$prefix"

    prefixes=()
    for rp in "${raw_prefixes[@]}"; do
      if [ -n "$group_base" ]; then
        prefixes+=("$MODEL_BASE/$group_base/$rp")
      else
        prefixes+=("$MODEL_BASE/$rp")
      fi
    done

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

      float)
        val="${values[0]}.0"
        echo "Setting float $key = $val"
        jq --arg k "$key" --argjson v "$val" \
           '.floats[$k] = $v' \
           "$TEMP_OUTPUT" > "${TEMP_OUTPUT}.new"
        ;;

      range)
        sorted=($(printf '%s\n' "${values[@]}" | sort -n))
        min="${sorted[0]}.0"
        max="${sorted[-1]}.0"
        echo "Setting range $key = [$min, $max]"
        jq --arg k "$key" --arg lo "$min" --arg hi "$max" \
           '.ranges[$k] = [($lo|tonumber), ($hi|tonumber)]' \
           "$TEMP_OUTPUT" > "${TEMP_OUTPUT}.new"
        ;;

    esac

    mv "${TEMP_OUTPUT}.new" "$TEMP_OUTPUT"
  done
}

cp "$OUTPUT_JSON" "$TEMP_OUTPUT"

# Define the item file to look in for each lookup group
# First argument is the item file to look in
# Second argument is what to append after "item/wynn", used for groups with many entries
# Third argument is the lookup group to use
process_group "potion.json" "" "${LOOKUPS_MISC[@]}"
process_group "potion.json" "weapon/archer" "${LOOKUPS_BOWS[@]}"
process_group "potion.json" "weapon/assassin" "${LOOKUPS_DAGGERS[@]}"
process_group "potion.json" "weapon/mage" "${LOOKUPS_WANDS[@]}"
process_group "potion.json" "weapon/shaman" "${LOOKUPS_RELIKS[@]}"
process_group "potion.json" "weapon/warrior" "${LOOKUPS_SPEARS[@]}"
process_group "potion.json" "accessory/ring" "${LOOKUPS_RINGS[@]}"
process_group "potion.json" "accessory/bracelet" "${LOOKUPS_BRACELETS[@]}"
process_group "potion.json" "accessory/necklace" "${LOOKUPS_NECKLACES[@]}"
process_group "potion.json" "charm" "${LOOKUPS_CHARMS[@]}"
process_group "potion.json" "mastery_tome" "${LOOKUPS_TOMES[@]}"
process_group "leather_helmet.json" "" "${LOOKUPS_LEATHER_HELMET[@]}"
process_group "leather_chestplate.json" "" "${LOOKUPS_LEATHER_CHESTPLATE[@]}"
process_group "leather_leggings.json" "" "${LOOKUPS_LEATHER_LEGGINGS[@]}"
process_group "leather_boots.json" "" "${LOOKUPS_LEATHER_BOOTS[@]}"

mv "$TEMP_OUTPUT" "$OUTPUT_JSON"
echo "Model Data Updated"
