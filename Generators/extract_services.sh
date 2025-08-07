#!/bin/bash

TARGET_DIR=$(cd $(dirname "$0")/.. >/dev/null 2>&1 && pwd)/Reference

cd $TARGET_DIR

TARGET="services.json"
TARGET_MAPFEATURES="service_mapfeatures.json"

# Download the json file from Wynncraft API
wget -O markers.json.tmp "https://api.wynncraft.com/v3/map/locations/markers"

if [ ! -s markers.json.tmp ]; then
    rm markers.json.tmp
    echo "Error: Wynncraft API is not working, aborting"
    exit
fi

# Check if the file is a JSON with a "message" and "request_id" key or the "error" key is present
if jq -e '(length == 2 and has("message") and has("request_id")) or has("error")' markers.json.tmp > /dev/null; then
    rm markers.json.tmp
    echo "Error: Wynncraft API returned an error message, aborting"
    exit
fi

# Input JSON file name
inputFile="markers.json.tmp"

missingFile="../Data-Storage/services_missing.json"

# Transform the input using jq directly
jq '
  # Define the mappings as a key-value object
  def mappings: {
    "Merchant_Armour.png": "Armour Merchant",
    "Merchant_Dungeon.png": "Dungeon Scroll Merchant",
    "Merchant_Emerald.png": "Emerald Merchant",
    "Merchant_Liquid.png": "Liquid Merchant",
    "Merchant_Potion.png": "Potion Merchant",
    "Merchant_Scroll.png": "Scroll Merchant",
    "Merchant_Tool.png": "Tool Merchant",
    "Merchant_Weapon.png": "Weapon Merchant",
    "NPC_Blacksmith.png": "Blacksmith",
    "NPC_ItemIdentifier.png": "Item Identifier",
    "NPC_PowderMaster.png": "Powder Master",
    "NPC_TradeMarket.png": "Trade Market",
    "Profession_Alchemism.png": "Alchemism Station",
    "Profession_Armouring.png": "Armouring Station",
    "Profession_Cooking.png": "Cooking Station",
    "Profession_Jeweling.png": "Jeweling Station",
    "Profession_Scribing.png": "Scribing Station",
    "Profession_Tailoring.png": "Tailoring Station",
    "Profession_Weaponsmithing.png": "Weaponsmithing Station",
    "Profession_Woodworking.png": "Woodworking Station",
    "Special_FastTravel.png": "Fast Travel",
    "Special_HousingAirBalloon.png": "Housing Balloon",
    "Special_SeaskipperFastTravel.png": "Seaskipper"
  };

  # Transform the array of items
  map(
    {
      type: mappings[.icon],
      locations: [{ x: (.x | tonumber), y: (.y | tonumber), z: (.z | tonumber) }]
    }
  )
  # Filter out any items that could not be mapped
  | map(select(.type != null))
  # Group by type and merge locations
  | group_by(.type)
  | map({
      type: .[0].type,
      locations: map(.locations[]) | unique_by({x, y, z})
    })
' "$inputFile" > services.json.tmp

# Combine the files and handle processing
jq -s '
  # Combine arrays from both files
  add |
  # Group by type to merge types present in both files
  group_by(.type) |
  # Map each group to a single object consolidating the locations
  map({
    type: .[0].type,
    locations: (map(.locations[]) | unique_by({x, y, z}))
  })
' $TARGET.tmp $missingFile > $TARGET

# Clean up the temporary files
rm $TARGET.tmp
rm $inputFile

# Calculate md5sum of the new gear data
MD5=$(md5sum $TARGET_DIR/$TARGET | cut -d' ' -f1)

# Update urls.json with the new md5sum for dataStaticServices
jq '. = [.[] | if (.id == "dataStaticServices") then (.md5 = "'$MD5'") else . end]' < ../Data-Storage/urls.json > ../Data-Storage/urls.json.tmp
mv ../Data-Storage/urls.json.tmp ../Data-Storage/urls.json

jq '
def to_feature_id(type; index):
  (type | ascii_downcase | gsub(" "; "-") | gsub("[^a-zA-Z0-9\\-]+"; "")) + "-" + (index|tostring);

def map_type(type):
  {
    "Alchemism Station": "profession:alchemism",
    "Armour Merchant": "merchant:armor",
    "Armouring Station": "profession:armoring",
    "Blacksmith": "blacksmith",
    "Booth Shop": "booth-shop",
    "Cooking Station": "profession:cooking",
    "Dungeon Scroll Merchant": "merchant:dungeon-scroll",
    "Emerald Merchant": "merchant:emerald",
    "Fast Travel": "fast-travel",
    "Housing Balloon": "housing-balloon",
    "Item Identifier": "identifier",
    "Jeweling Station": "profession:jeweling",
    "Liquid Merchant": "merchant:liquid-emerald",
    "Party Finder": "party-finder",
    "Potion Merchant": "merchant:potion",
    "Powder Master": "powder-master",
    "Scribing Station": "profession:scribing",
    "Scroll Merchant": "merchant:scroll",
    "Seaskipper": "seaskipper",
    "Tailoring Station": "profession:tailoring",
    "Tool Merchant": "merchant:tool",
    "Trade Market": "trade-market",
    "Weapon Merchant": "merchant:weapon",
    "Weaponsmithing Station": "profession:weaponsmithing",
    "Woodworking Station": "profession:woodworking"
  }[type];

[.[] | .type as $type | .locations | to_entries | .[] |
  {
    featureId: to_feature_id($type; .key),
    categoryId: ("wynntils:service:" + map_type($type)),
    location: .value
  }
]
' < $TARGET > $TARGET_MAPFEATURES

# Calculate md5sum of the new gear data
MD5=$(md5sum $TARGET_DIR/$TARGET_MAPFEATURES | cut -d' ' -f1)

# Update urls.json with the new md5sum for dataStaticServicesMapFeatures
jq '. = [.[] | if (.id == "dataStaticServicesMapFeatures") then (.md5 = "'$MD5'") else . end]' < ../Data-Storage/urls.json > ../Data-Storage/urls.json.tmp
mv ../Data-Storage/urls.json.tmp ../Data-Storage/urls.json