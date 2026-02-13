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
    "corkian_amplifier|potion.json|item/wynn/augment/corkian_amplifier|float"
    "corkian_insulator|potion.json|item/wynn/augment/corkian_insulator|float"
    "corkian_simulator|potion.json|item/wynn/augment/corkian_simulator|float"
    "dungeon_key|potion.json|item/wynn/dungeon/key|float"
    "dungeon_key_broken|potion.json|item/wynn/dungeon/key_broken|float"
    "rune_az|potion.json|item/wynn/rune/az|float"
    "rune_nii|potion.json|item/wynn/rune/nii|float"
    "rune_uth|potion.json|item/wynn/rune/uth|float"
    "rune_tol|potion.json|item/wynn/rune/tol|float"
    "abilityTree.aspectArcher|potion.json|item/wynn/gui/ability_tree/aspect/archer|float"
    "abilityTree.aspectAssassin|potion.json|item/wynn/gui/ability_tree/aspect/assassin|float"
    "abilityTree.aspectMage|potion.json|item/wynn/gui/ability_tree/aspect/mage|float"
    "abilityTree.aspectShaman|potion.json|item/wynn/gui/ability_tree/aspect/shaman|float"
    "abilityTree.aspectWarrior|potion.json|item/wynn/gui/ability_tree/aspect/warrior|float"
    "bow.basicWood|potion.json|item/wynn/weapon/archer/bow_basic_wood|float"
    "bow.basicGold|potion.json|item/wynn/weapon/archer/bow_basic_gold|float"
    "bow.air1|potion.json|item/wynn/weapon/archer/bow_air_a|float"
    "bow.air2|potion.json|item/wynn/weapon/archer/bow_air_b|float"
    "bow.air3|potion.json|item/wynn/weapon/archer/bow_air_c|float"
    "bow.earth1|potion.json|item/wynn/weapon/archer/bow_earth_a|float"
    "bow.earth2|potion.json|item/wynn/weapon/archer/bow_earth_b|float"
    "bow.earth3|potion.json|item/wynn/weapon/archer/bow_earth_c|float"
    "bow.fire1|potion.json|item/wynn/weapon/archer/bow_fire_a|float"
    "bow.fire2|potion.json|item/wynn/weapon/archer/bow_fire_b|float"
    "bow.fire3|potion.json|item/wynn/weapon/archer/bow_fire_c|float"
    "bow.thunder1|potion.json|item/wynn/weapon/archer/bow_thunder_a|float"
    "bow.thunder2|potion.json|item/wynn/weapon/archer/bow_thunder_b|float"
    "bow.thunder3|potion.json|item/wynn/weapon/archer/bow_thunder_c|float"
    "bow.water1|potion.json|item/wynn/weapon/archer/bow_water_a|float"
    "bow.water2|potion.json|item/wynn/weapon/archer/bow_water_b|float"
    "bow.water3|potion.json|item/wynn/weapon/archer/bow_water_c|float"
    "bow.multi1|potion.json|item/wynn/weapon/archer/bow_multi_a|float"
    "bow.multi2|potion.json|item/wynn/weapon/archer/bow_multi_b|float"
    "bow.multi3|potion.json|item/wynn/weapon/archer/bow_multi_c|float"
    "dagger.basicWood|potion.json|item/wynn/weapon/assassin/dagger_basic_wood|float"
    "dagger.basicGold|potion.json|item/wynn/weapon/assassin/dagger_basic_gold|float"
    "dagger.air1|potion.json|item/wynn/weapon/assassin/dagger_air_a|float"
    "dagger.air2|potion.json|item/wynn/weapon/assassin/dagger_air_b|float"
    "dagger.air3|potion.json|item/wynn/weapon/assassin/dagger_air_c|float"
    "dagger.earth1|potion.json|item/wynn/weapon/assassin/dagger_earth_a|float"
    "dagger.earth2|potion.json|item/wynn/weapon/assassin/dagger_earth_b|float"
    "dagger.earth3|potion.json|item/wynn/weapon/assassin/dagger_earth_c|float"
    "dagger.fire1|potion.json|item/wynn/weapon/assassin/dagger_fire_a|float"
    "dagger.fire2|potion.json|item/wynn/weapon/assassin/dagger_fire_b|float"
    "dagger.fire3|potion.json|item/wynn/weapon/assassin/dagger_fire_c|float"
    "dagger.thunder1|potion.json|item/wynn/weapon/assassin/dagger_thunder_a|float"
    "dagger.thunder2|potion.json|item/wynn/weapon/assassin/dagger_thunder_b|float"
    "dagger.thunder3|potion.json|item/wynn/weapon/assassin/dagger_thunder_c|float"
    "dagger.water1|potion.json|item/wynn/weapon/assassin/dagger_water_a|float"
    "dagger.water2|potion.json|item/wynn/weapon/assassin/dagger_water_b|float"
    "dagger.water3|potion.json|item/wynn/weapon/assassin/dagger_water_c|float"
    "dagger.multi1|potion.json|item/wynn/weapon/assassin/dagger_multi_a|float"
    "dagger.multi2|potion.json|item/wynn/weapon/assassin/dagger_multi_b|float"
    "dagger.multi3|potion.json|item/wynn/weapon/assassin/dagger_multi_c|float"
    "wand.basicWood|potion.json|item/wynn/weapon/mage/wand_basic_wood|float"
    "wand.basicGold|potion.json|item/wynn/weapon/mage/wand_basic_gold|float"
    "wand.basicDiamond|potion.json|item/wynn/weapon/mage/wand_basic_diamond|float"
    "wand.air1|potion.json|item/wynn/weapon/mage/wand_air_a|float"
    "wand.air2|potion.json|item/wynn/weapon/mage/wand_air_b|float"
    "wand.air3|potion.json|item/wynn/weapon/mage/wand_air_c|float"
    "wand.earth1|potion.json|item/wynn/weapon/mage/wand_earth_a|float"
    "wand.earth2|potion.json|item/wynn/weapon/mage/wand_earth_b|float"
    "wand.earth3|potion.json|item/wynn/weapon/mage/wand_earth_c|float"
    "wand.fire1|potion.json|item/wynn/weapon/mage/wand_fire_a|float"
    "wand.fire2|potion.json|item/wynn/weapon/mage/wand_fire_b|float"
    "wand.fire3|potion.json|item/wynn/weapon/mage/wand_fire_c|float"
    "wand.thunder1|potion.json|item/wynn/weapon/mage/wand_thunder_a|float"
    "wand.thunder2|potion.json|item/wynn/weapon/mage/wand_thunder_b|float"
    "wand.thunder3|potion.json|item/wynn/weapon/mage/wand_thunder_c|float"
    "wand.water1|potion.json|item/wynn/weapon/mage/wand_water_a|float"
    "wand.water2|potion.json|item/wynn/weapon/mage/wand_water_b|float"
    "wand.water3|potion.json|item/wynn/weapon/mage/wand_water_c|float"
    "wand.multi1|potion.json|item/wynn/weapon/mage/wand_multi_a|float"
    "wand.multi2|potion.json|item/wynn/weapon/mage/wand_multi_b|float"
    "wand.multi3|potion.json|item/wynn/weapon/mage/wand_multi_c|float"
    "relik.basicWood|potion.json|item/wynn/weapon/shaman/relik_basic_wooden|float"
    "relik.basicGold|potion.json|item/wynn/weapon/shaman/relik_basic_gold|float"
    "relik.air1|potion.json|item/wynn/weapon/shaman/relik_air_a|float"
    "relik.air2|potion.json|item/wynn/weapon/shaman/relik_air_b|float"
    "relik.air3|potion.json|item/wynn/weapon/shaman/relik_air_c|float"
    "relik.earth1|potion.json|item/wynn/weapon/shaman/relik_earth_a|float"
    "relik.earth2|potion.json|item/wynn/weapon/shaman/relik_earth_b|float"
    "relik.earth3|potion.json|item/wynn/weapon/shaman/relik_earth_c|float"
    "relik.fire1|potion.json|item/wynn/weapon/shaman/relik_fire_a|float"
    "relik.fire2|potion.json|item/wynn/weapon/shaman/relik_fire_b|float"
    "relik.fire3|potion.json|item/wynn/weapon/shaman/relik_fire_c|float"
    "relik.thunder1|potion.json|item/wynn/weapon/shaman/relik_thunder_a|float"
    "relik.thunder2|potion.json|item/wynn/weapon/shaman/relik_thunder_b|float"
    "relik.thunder3|potion.json|item/wynn/weapon/shaman/relik_thunder_c|float"
    "relik.water1|potion.json|item/wynn/weapon/shaman/relik_water_a|float"
    "relik.water2|potion.json|item/wynn/weapon/shaman/relik_water_b|float"
    "relik.water3|potion.json|item/wynn/weapon/shaman/relik_water_c|float"
    "relik.multi1|potion.json|item/wynn/weapon/shaman/relik_multi_a|float"
    "relik.multi2|potion.json|item/wynn/weapon/shaman/relik_multi_b|float"
    "relik.multi3|potion.json|item/wynn/weapon/shaman/relik_multi_c|float"
    "spear.basicWood|potion.json|item/wynn/weapon/warrior/spear_basic_wood|float"
    "spear.basicGold|potion.json|item/wynn/weapon/warrior/spear_basic_gold|float"
    "spear.air1|potion.json|item/wynn/weapon/warrior/spear_air_a|float"
    "spear.air2|potion.json|item/wynn/weapon/warrior/spear_air_b|float"
    "spear.air3|potion.json|item/wynn/weapon/warrior/spear_air_c|float"
    "spear.earth1|potion.json|item/wynn/weapon/warrior/spear_earth_a|float"
    "spear.earth2|potion.json|item/wynn/weapon/warrior/spear_earth_b|float"
    "spear.earth3|potion.json|item/wynn/weapon/warrior/spear_earth_c|float"
    "spear.fire1|potion.json|item/wynn/weapon/warrior/spear_fire_a|float"
    "spear.fire2|potion.json|item/wynn/weapon/warrior/spear_fire_b|float"
    "spear.fire3|potion.json|item/wynn/weapon/warrior/spear_fire_c|float"
    "spear.thunder1|potion.json|item/wynn/weapon/warrior/spear_thunder_a|float"
    "spear.thunder2|potion.json|item/wynn/weapon/warrior/spear_thunder_b|float"
    "spear.thunder3|potion.json|item/wynn/weapon/warrior/spear_thunder_c|float"
    "spear.water1|potion.json|item/wynn/weapon/warrior/spear_water_a|float"
    "spear.water2|potion.json|item/wynn/weapon/warrior/spear_water_b|float"
    "spear.water3|potion.json|item/wynn/weapon/warrior/spear_water_c|float"
    "spear.multi1|potion.json|item/wynn/weapon/warrior/spear_multi_a|float"
    "spear.multi2|potion.json|item/wynn/weapon/warrior/spear_multi_b|float"
    "spear.multi3|potion.json|item/wynn/weapon/warrior/spear_multi_c|float"
    "ring.basicIron|potion.json|item/wynn/accessory/ring/ring_base_a|float"
    "ring.basicGold|potion.json|item/wynn/accessory/ring/ring_base_b|float"
    "ring.basicGem|potion.json|item/wynn/accessory/ring/ring_special_c|float"
    "ring.basicPearl|potion.json|item/wynn/accessory/ring/ring_special_b|float"
    "ring.basicWedding|potion.json|item/wynn/accessory/ring/ring_special_a|float"
    "ring.air1|potion.json|item/wynn/accessory/ring/ring_air_a|float"
    "ring.air2|potion.json|item/wynn/accessory/ring/ring_air_b|float"
    "ring.earth1|potion.json|item/wynn/accessory/ring/ring_earth_a|float"
    "ring.earth2|potion.json|item/wynn/accessory/ring/ring_earth_b|float"
    "ring.fire1|potion.json|item/wynn/accessory/ring/ring_fire_a|float"
    "ring.fire2|potion.json|item/wynn/accessory/ring/ring_fire_b|float"
    "ring.thunder1|potion.json|item/wynn/accessory/ring/ring_thunder_a|float"
    "ring.thunder2|potion.json|item/wynn/accessory/ring/ring_thunder_b|float"
    "ring.water1|potion.json|item/wynn/accessory/ring/ring_water_a|float"
    "ring.water2|potion.json|item/wynn/accessory/ring/ring_water_b|float"
    "ring.multi1|potion.json|item/wynn/accessory/ring/ring_multi_a|float"
    "ring.multi2|potion.json|item/wynn/accessory/ring/ring_multi_b|float"
    "bracelet.basicIron|potion.json|item/wynn/accessory/bracelet/bracelet_base_a|float"
    "bracelet.basicGold|potion.json|item/wynn/accessory/bracelet/bracelet_base_b|float"
    "bracelet.air1|potion.json|item/wynn/accessory/bracelet/bracelet_air_a|float"
    "bracelet.air2|potion.json|item/wynn/accessory/bracelet/bracelet_air_b|float"
    "bracelet.earth1|potion.json|item/wynn/accessory/bracelet/bracelet_earth_a|float"
    "bracelet.earth2|potion.json|item/wynn/accessory/bracelet/bracelet_earth_b|float"
    "bracelet.fire1|potion.json|item/wynn/accessory/bracelet/bracelet_fire_a|float"
    "bracelet.fire2|potion.json|item/wynn/accessory/bracelet/bracelet_fire_b|float"
    "bracelet.thunder1|potion.json|item/wynn/accessory/bracelet/bracelet_thunder_a|float"
    "bracelet.thunder2|potion.json|item/wynn/accessory/bracelet/bracelet_thunder_b|float"
    "bracelet.water1|potion.json|item/wynn/accessory/bracelet/bracelet_water_a|float"
    "bracelet.water2|potion.json|item/wynn/accessory/bracelet/bracelet_water_b|float"
    "bracelet.multi1|potion.json|item/wynn/accessory/bracelet/bracelet_multi_a|float"
    "bracelet.multi2|potion.json|item/wynn/accessory/bracelet/bracelet_multi_b|float"
    "necklace.basicIron|potion.json|item/wynn/accessory/necklace/necklace_base_a|float"
    "necklace.basicGold|potion.json|item/wynn/accessory/necklace/necklace_base_b|float"
    "necklace.basicCross|potion.json|item/wynn/accessory/necklace/necklace_special_a|float"
    "necklace.basicBroach|potion.json|item/wynn/accessory/necklace/necklace_special_b|float"
    "necklace.basicPearl|potion.json|item/wynn/accessory/necklace/necklace_special_c|float"
    "necklace.air1|potion.json|item/wynn/accessory/necklace/necklace_air_a|float"
    "necklace.air2|potion.json|item/wynn/accessory/necklace/necklace_air_b|float"
    "necklace.earth1|potion.json|item/wynn/accessory/necklace/necklace_earth_a|float"
    "necklace.earth2|potion.json|item/wynn/accessory/necklace/necklace_earth_b|float"
    "necklace.fire1|potion.json|item/wynn/accessory/necklace/necklace_fire_a|float"
    "necklace.fire2|potion.json|item/wynn/accessory/necklace/necklace_fire_b|float"
    "necklace.thunder1|potion.json|item/wynn/accessory/necklace/necklace_thunder_a|float"
    "necklace.thunder2|potion.json|item/wynn/accessory/necklace/necklace_thunder_b|float"
    "necklace.water1|potion.json|item/wynn/accessory/necklace/necklace_water_a|float"
    "necklace.water2|potion.json|item/wynn/accessory/necklace/necklace_water_b|float"
    "necklace.multi1|potion.json|item/wynn/accessory/necklace/necklace_multi_a|float"
    "necklace.multi2|potion.json|item/wynn/accessory/necklace/necklace_multi_b|float"
    "charm.worm|potion.json|item/wynn/charm/worm|float"
    "charm.light|potion.json|item/wynn/charm/light|float"
    "charm.stone|potion.json|item/wynn/charm/stone|float"
    "charm.void|potion.json|item/wynn/charm/void|float"
    "tome.armour|potion.json|item/wynn/mastery_tome/armour|float"
    "tome.guild|potion.json|item/wynn/mastery_tome/guild|float"
    "tome.lootrun|potion.json|item/wynn/mastery_tome/lootrun|float"
    "tome.mana|potion.json|item/wynn/mastery_tome/mana|float"
    "tome.movement|potion.json|item/wynn/mastery_tome/movement|float"
    "tome.utility|potion.json|item/wynn/mastery_tome/utility|float"
    "tome.weapon|potion.json|item/wynn/mastery_tome/weapon|float"
    "helmet.pale_leather|leather_helmet.json|item/wynn/armor/helmet/pale_leather_helmet|float"
    "helmet.chainmail|leather_helmet.json|item/wynn/armor/helmet/chainmail_helmet|float"
    "helmet.pale_chainmail|leather_helmet.json|item/wynn/armor/helmet/pale_chainmail_helmet|float"
    "helmet.iron|leather_helmet.json|item/wynn/armor/helmet/iron_helmet|float"
    "helmet.pale_iron|leather_helmet.json|item/wynn/armor/helmet/pale_iron_helmet|float"
    "helmet.gold|leather_helmet.json|item/wynn/armor/helmet/gold_helmet|float"
    "helmet.pale_gold|leather_helmet.json|item/wynn/armor/helmet/pale_gold_helmet|float"
    "helmet.diamond|leather_helmet.json|item/wynn/armor/helmet/diamond_helmet|float"
    "helmet.pale_diamond|leather_helmet.json|item/wynn/armor/helmet/pale_diamond_helmet|float"
    "chestplate.pale_leather|leather_chestplate.json|item/wynn/armor/chestplate/pale_leather_chestplate|float"
    "chestplate.chainmail|leather_chestplate.json|item/wynn/armor/chestplate/chainmail_chestplate|float"
    "chestplate.pale_chainmail|leather_chestplate.json|item/wynn/armor/chestplate/pale_chainmail_chestplate|float"
    "chestplate.iron|leather_chestplate.json|item/wynn/armor/chestplate/iron_chestplate|float"
    "chestplate.pale_iron|leather_chestplate.json|item/wynn/armor/chestplate/pale_iron_chestplate|float"
    "chestplate.gold|leather_chestplate.json|item/wynn/armor/chestplate/gold_chestplate|float"
    "chestplate.pale_gold|leather_chestplate.json|item/wynn/armor/chestplate/pale_gold_chestplate|float"
    "chestplate.diamond|leather_chestplate.json|item/wynn/armor/chestplate/diamond_chestplate|float"
    "chestplate.pale_diamond|leather_chestplate.json|item/wynn/armor/chestplate/pale_diamond_chestplate|float"
    "leggings.pale_leather|leather_leggings.json|item/wynn/armor/leggings/pale_leather_leggings|float"
    "leggings.chainmail|leather_leggings.json|item/wynn/armor/leggings/chainmail_leggings|float"
    "leggings.pale_chainmail|leather_leggings.json|item/wynn/armor/leggings/pale_chainmail_leggings|float"
    "leggings.iron|leather_leggings.json|item/wynn/armor/leggings/iron_leggings|float"
    "leggings.pale_iron|leather_leggings.json|item/wynn/armor/leggings/pale_iron_leggings|float"
    "leggings.gold|leather_leggings.json|item/wynn/armor/leggings/gold_leggings|float"
    "leggings.pale_gold|leather_leggings.json|item/wynn/armor/leggings/pale_gold_leggings|float"
    "leggings.diamond|leather_leggings.json|item/wynn/armor/leggings/diamond_leggings|float"
    "leggings.pale_diamond|leather_leggings.json|item/wynn/armor/leggings/pale_diamond_leggings|float"
    "boots.pale_leather|leather_boots.json|item/wynn/armor/boots/pale_leather_boots|float"
    "boots.chainmail|leather_boots.json|item/wynn/armor/boots/chainmail_boots|float"
    "boots.pale_chainmail|leather_boots.json|item/wynn/armor/boots/pale_chainmail_boots|float"
    "boots.iron|leather_boots.json|item/wynn/armor/boots/iron_boots|float"
    "boots.pale_iron|leather_boots.json|item/wynn/armor/boots/pale_iron_boots|float"
    "boots.gold|leather_boots.json|item/wynn/armor/boots/gold_boots|float"
    "boots.pale_gold|leather_boots.json|item/wynn/armor/boots/pale_gold_boots|float"
    "boots.diamond|leather_boots.json|item/wynn/armor/boots/diamond_boots|float"
    "boots.pale_diamond|leather_boots.json|item/wynn/armor/boots/pale_diamond_boots|float"
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
