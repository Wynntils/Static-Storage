#!/bin/bash

BASE_DIR="$(cd $(dirname "$0")/.. 2>/dev/null && pwd)"
ASSETS_DIR="$BASE_DIR/Generators/assets/minecraft/models/item"
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

# Define the lookups
# Format: "key|model_prefix|type"
# key is how the key used for lookup by the mod
# model_prefix is what to look for in the file to count as the current model type, do not include the "item/wynn"
# if looking for multiple model types, separate them with a "," e.g. "weapon/archer,skin/bow"
# type is how the value should be stored. Currently supports: raw, float or range. Not including one will assume float
# raw is kept for compatibility with old clients, don't use for new entries
# Split lookups per item, define the filename when calling process_group
LOOKUPS_POTION=(
  "mythic_box|loot/mythic|raw"
  "beacon_color|gui/beacon/white|raw"
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
  "abilityTree.aspectArcher|gui/ability_tree/aspect/archer"
  "abilityTree.aspectAssassin|gui/ability_tree/aspect/assassin"
  "abilityTree.aspectMage|gui/ability_tree/aspect/mage"
  "abilityTree.aspectShaman|gui/ability_tree/aspect/shaman"
  "abilityTree.aspectWarrior|gui/ability_tree/aspect/warrior"
  "bow.basicWood|weapon/archer/bow_basic_wood"
  "bow.basicGold|weapon/archer/bow_basic_gold"
  "bow.air1|weapon/archer/bow_air_a"
  "bow.air2|weapon/archer/bow_air_b"
  "bow.air3|weapon/archer/bow_air_c"
  "bow.earth1|weapon/archer/bow_earth_a"
  "bow.earth2|weapon/archer/bow_earth_b"
  "bow.earth3|weapon/archer/bow_earth_c"
  "bow.fire1|weapon/archer/bow_fire_a"
  "bow.fire2|weapon/archer/bow_fire_b"
  "bow.fire3|weapon/archer/bow_fire_c"
  "bow.thunder1|weapon/archer/bow_thunder_a"
  "bow.thunder2|weapon/archer/bow_thunder_b"
  "bow.thunder3|weapon/archer/bow_thunder_c"
  "bow.water1|weapon/archer/bow_water_a"
  "bow.water2|weapon/archer/bow_water_b"
  "bow.water3|weapon/archer/bow_water_c"
  "bow.multi1|weapon/archer/bow_multi_a"
  "bow.multi2|weapon/archer/bow_multi_b"
  "bow.multi3|weapon/archer/bow_multi_c"
  "dagger.basicWood|weapon/assassin/dagger_basic_wood"
  "dagger.basicGold|weapon/assassin/dagger_basic_gold"
  "dagger.air1|weapon/assassin/dagger_air_a"
  "dagger.air2|weapon/assassin/dagger_air_b"
  "dagger.air3|weapon/assassin/dagger_air_c"
  "dagger.earth1|weapon/assassin/dagger_earth_a"
  "dagger.earth2|weapon/assassin/dagger_earth_b"
  "dagger.earth3|weapon/assassin/dagger_earth_c"
  "dagger.fire1|weapon/assassin/dagger_fire_a"
  "dagger.fire2|weapon/assassin/dagger_fire_b"
  "dagger.fire3|weapon/assassin/dagger_fire_c"
  "dagger.thunder1|weapon/assassin/dagger_thunder_a"
  "dagger.thunder2|weapon/assassin/dagger_thunder_b"
  "dagger.thunder3|weapon/assassin/dagger_thunder_c"
  "dagger.water1|weapon/assassin/dagger_water_a"
  "dagger.water2|weapon/assassin/dagger_water_b"
  "dagger.water3|weapon/assassin/dagger_water_c"
  "dagger.multi1|weapon/assassin/dagger_multi_a"
  "dagger.multi2|weapon/assassin/dagger_multi_b"
  "dagger.multi3|weapon/assassin/dagger_multi_c"
  "wand.basicWood|weapon/mage/wand_basic_wood"
  "wand.basicGold|weapon/mage/wand_basic_gold"
  "wand.basicDiamond|weapon/mage/wand_basic_diamond"
  "wand.air1|weapon/mage/wand_air_a"
  "wand.air2|weapon/mage/wand_air_b"
  "wand.air3|weapon/mage/wand_air_c"
  "wand.earth1|weapon/mage/wand_earth_a"
  "wand.earth2|weapon/mage/wand_earth_b"
  "wand.earth3|weapon/mage/wand_earth_c"
  "wand.fire1|weapon/mage/wand_fire_a"
  "wand.fire2|weapon/mage/wand_fire_b"
  "wand.fire3|weapon/mage/wand_fire_c"
  "wand.thunder1|weapon/mage/wand_thunder_a"
  "wand.thunder2|weapon/mage/wand_thunder_b"
  "wand.thunder3|weapon/mage/wand_thunder_c"
  "wand.water1|weapon/mage/wand_water_a"
  "wand.water2|weapon/mage/wand_water_b"
  "wand.water3|weapon/mage/wand_water_c"
  "wand.multi1|weapon/mage/wand_multi_a"
  "wand.multi2|weapon/mage/wand_multi_b"
  "wand.multi3|weapon/mage/wand_multi_c"
  "relik.basicWood|weapon/shaman/relik_basic_wooden"
  "relik.basicGold|weapon/shaman/relik_basic_gold"
  "relik.air1|weapon/shaman/relik_air_a"
  "relik.air2|weapon/shaman/relik_air_b"
  "relik.air3|weapon/shaman/relik_air_c"
  "relik.earth1|weapon/shaman/relik_earth_a"
  "relik.earth2|weapon/shaman/relik_earth_b"
  "relik.earth3|weapon/shaman/relik_earth_c"
  "relik.fire1|weapon/shaman/relik_fire_a"
  "relik.fire2|weapon/shaman/relik_fire_b"
  "relik.fire3|weapon/shaman/relik_fire_c"
  "relik.thunder1|weapon/shaman/relik_thunder_a"
  "relik.thunder2|weapon/shaman/relik_thunder_b"
  "relik.thunder3|weapon/shaman/relik_thunder_c"
  "relik.water1|weapon/shaman/relik_water_a"
  "relik.water2|weapon/shaman/relik_water_b"
  "relik.water3|weapon/shaman/relik_water_c"
  "relik.multi1|weapon/shaman/relik_multi_a"
  "relik.multi2|weapon/shaman/relik_multi_b"
  "relik.multi3|weapon/shaman/relik_multi_c"
  "spear.basicWood|weapon/warrior/spear_basic_wood"
  "spear.basicGold|weapon/warrior/spear_basic_gold"
  "spear.air1|weapon/warrior/spear_air_a"
  "spear.air2|weapon/warrior/spear_air_b"
  "spear.air3|weapon/warrior/spear_air_c"
  "spear.earth1|weapon/warrior/spear_earth_a"
  "spear.earth2|weapon/warrior/spear_earth_b"
  "spear.earth3|weapon/warrior/spear_earth_c"
  "spear.fire1|weapon/warrior/spear_fire_a"
  "spear.fire2|weapon/warrior/spear_fire_b"
  "spear.fire3|weapon/warrior/spear_fire_c"
  "spear.thunder1|weapon/warrior/spear_thunder_a"
  "spear.thunder2|weapon/warrior/spear_thunder_b"
  "spear.thunder3|weapon/warrior/spear_thunder_c"
  "spear.water1|weapon/warrior/spear_water_a"
  "spear.water2|weapon/warrior/spear_water_b"
  "spear.water3|weapon/warrior/spear_water_c"
  "spear.multi1|weapon/warrior/spear_multi_a"
  "spear.multi2|weapon/warrior/spear_multi_b"
  "spear.multi3|weapon/warrior/spear_multi_c"
  "ring.basicIron|accessory/ring/ring_base_a"
  "ring.basicGold|accessory/ring/ring_base_b"
  "ring.basicGem|accessory/ring/ring_special_c"
  "ring.basicPearl|accessory/ring/ring_special_b"
  "ring.basicWedding|accessory/ring/ring_special_a"
  "ring.air1|accessory/ring/ring_air_a"
  "ring.air2|accessory/ring/ring_air_b"
  "ring.earth1|accessory/ring/ring_earth_a"
  "ring.earth2|accessory/ring/ring_earth_b"
  "ring.fire1|accessory/ring/ring_fire_a"
  "ring.fire2|accessory/ring/ring_fire_b"
  "ring.thunder1|accessory/ring/ring_thunder_a"
  "ring.thunder2|accessory/ring/ring_thunder_b"
  "ring.water1|accessory/ring/ring_water_a"
  "ring.water2|accessory/ring/ring_water_b"
  "ring.multi1|accessory/ring/ring_multi_a"
  "ring.multi2|accessory/ring/ring_multi_b"
  "bracelet.basicIron|accessory/bracelet/bracelet_base_a"
  "bracelet.basicGold|accessory/bracelet/bracelet_base_b"
  "bracelet.air1|accessory/bracelet/bracelet_air_a"
  "bracelet.air2|accessory/bracelet/bracelet_air_b"
  "bracelet.earth1|accessory/bracelet/bracelet_earth_a"
  "bracelet.earth2|accessory/bracelet/bracelet_earth_b"
  "bracelet.fire1|accessory/bracelet/bracelet_fire_a"
  "bracelet.fire2|accessory/bracelet/bracelet_fire_b"
  "bracelet.thunder1|accessory/bracelet/bracelet_thunder_a"
  "bracelet.thunder2|accessory/bracelet/bracelet_thunder_b"
  "bracelet.water1|accessory/bracelet/bracelet_water_a"
  "bracelet.water2|accessory/bracelet/bracelet_water_b"
  "bracelet.multi1|accessory/bracelet/bracelet_multi_a"
  "bracelet.multi2|accessory/bracelet/bracelet_multi_b"
  "necklace.basicIron|accessory/necklace/necklace_base_a"
  "necklace.basicGold|accessory/necklace/necklace_base_b"
  "necklace.basicCross|accessory/necklace/necklace_special_a"
  "necklace.basicBroach|accessory/necklace/necklace_special_b"
  "necklace.basicPearl|accessory/necklace/necklace_special_c"
  "necklace.air1|accessory/necklace/necklace_air_a"
  "necklace.air2|accessory/necklace/necklace_air_b"
  "necklace.earth1|accessory/necklace/necklace_earth_a"
  "necklace.earth2|accessory/necklace/necklace_earth_b"
  "necklace.fire1|accessory/necklace/necklace_fire_a"
  "necklace.fire2|accessory/necklace/necklace_fire_b"
  "necklace.thunder1|accessory/necklace/necklace_thunder_a"
  "necklace.thunder2|accessory/necklace/necklace_thunder_b"
  "necklace.water1|accessory/necklace/necklace_water_a"
  "necklace.water2|accessory/necklace/necklace_water_b"
  "necklace.multi1|accessory/necklace/necklace_multi_a"
  "necklace.multi2|accessory/necklace/necklace_multi_b"
  "charm.worm|charm/worm"
  "charm.light|charm/light"
  "charm.stone|charm/stone"
  "charm.void|charm/void"
  "tome.armour|mastery_tome/armour"
  "tome.guild|mastery_tome/guild"
  "tome.lootrun|mastery_tome/lootrun"
  "tome.mana|mastery_tome/mana"
  "tome.movement|mastery_tome/movement"
  "tome.utility|mastery_tome/utility"
  "tome.weapon|mastery_tome/weapon"
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
  "boots|armor/boots|range"
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

process_group() {
  local file="$1"
  shift
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
      prefixes+=("$MODEL_BASE/$rp")
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

      raw)
        val="${values[0]}.0"
        echo "Setting raw $key = $val"
        jq --arg k "$key" --argjson v "$val" \
           '.[$k] = $v' \
           "$TEMP_OUTPUT" > "${TEMP_OUTPUT}.new"
        ;;

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
process_group "potion.json" "${LOOKUPS_POTION[@]}"
process_group "leather_helmet.json" "${LOOKUPS_LEATHER_HELMET[@]}"
process_group "leather_chestplate.json" "${LOOKUPS_LEATHER_CHESTPLATE[@]}"
process_group "leather_leggings.json" "${LOOKUPS_LEATHER_LEGGINGS[@]}"
process_group "leather_boots.json" "${LOOKUPS_LEATHER_BOOTS[@]}"

mv "$TEMP_OUTPUT" "$OUTPUT_JSON"
echo "Model Data Updated"
