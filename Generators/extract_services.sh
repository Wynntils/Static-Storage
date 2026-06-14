#!/bin/bash

TARGET_DIR=$(cd $(dirname "$0")/.. >/dev/null 2>&1 && pwd)/Reference

cd $TARGET_DIR

if [ -z "${WYNNCRAFT_API_KEY:-}" ]; then
    echo "Error: WYNNCRAFT_API_KEY is not set"
    exit 1
fi

AUTH_HEADER="Authorization: Bearer ${WYNNCRAFT_API_KEY}"

TARGET="services.json"
TARGET_MAPFEATURES="service_mapfeatures.json"

# Download the json file from Wynncraft API
wget --header="$AUTH_HEADER" -O markers.json.tmp "https://api.wynncraft.com/v3/map/locations/markers"

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
    "Armour Merchant": "Armour Merchant",
    "Dungeon Merchant": "Dungeon Merchant",
    "Dungeon Scroll Merchant": "Dungeon Scroll Merchant",
    "Emerald Merchant": "Emerald Merchant",
    "Mount Merchant": "Mount Merchant",
    "Potion Merchant": "Potion Merchant",
    "Scroll Merchant": "Scroll Merchant",
    "Tool Merchant": "Tool Merchant",
    "Weapon Merchant": "Weapon Merchant",
    "Blacksmith": "Blacksmith",
    "Item Identifier": "Item Identifier",
    "Item Upgrader": "Item Upgrader",
    "Trade Market": "Trade Market",
    "Alchemism Station": "Alchemism Station",
    "Armouring Station": "Armouring Station",
    "Cooking Station": "Cooking Station",
    "Jeweling Station": "Jeweling Station",
    "Scribing Station": "Scribing Station",
    "Tailoring Station": "Tailoring Station",
    "Weaponsmithing Station": "Weaponsmithing Station",
    "Woodworking Station": "Woodworking Station",
    "Fast Travel": "Fast Travel",
    "Housing Air Balloon": "Housing Balloon",
    "Seaskipper Fast Travel": "Seaskipper"
  };

  # Transform the array of items
  map(
    {
      type: mappings[.name],
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