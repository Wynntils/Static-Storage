#!/bin/sh
# This script will retrieve the labels.js file from map.wynncraft.com, parse
# the locations and coordinates that are present in it, and convert it to a
# json file.
#
# Made by magicus (https://github.com/magicus)
#
MYDIR=$(cd $(dirname "$0") >/dev/null 2>&1 && pwd)
TARGET="$MYDIR/../Reference/places.json"
TARGET_MAPFEATURES="$MYDIR/../Reference/place_mapfeatures.json"

# This file contain additional labels that are not provided by upstread.
MISSING="$MYDIR/../Data-Storage/map-labels-missing.json"

command -v curl > /dev/null 2>&1
if test $? -ne 0; then
  echo curl is required
  exit 1
fi

command -v gawk > /dev/null 2>&1
if test $? -ne 0; then
  echo gawk is required
  exit 1
fi

command -v jq > /dev/null 2>&1
if test $? -ne 0; then
  echo jq is required
  exit 1
fi

curl -s https://map.wynncraft.com/js/labels.js | gawk '
# Capture coordinates
match($0, /fromWorldToLatLng\(\s*([-0-9]+),\s*[-0-9]+,\s*([-0-9]+),/, a) {
  x = a[1]
  z = a[2]
}

# With level
match($0, /html:\s*e\(\x27([^<]+)<div class="level">\[Lv\. ([^]]+)\]<\/div>\x27,\s*"([0-9]+)"/, b) {
  if (x == "" || z == "") next

  name = b[1]
  gsub(/[ \t]+$/, "", name)
  gsub(/\\\x27/, sprintf("%c", 39), name)
  level = b[2]
  gsub(/[ \t]+/, "", level)
  size = b[3]

  if (size == 25) layer = 1
  else if (size == 16) layer = 2
  else if (size == 14) layer = 3
  else next

  print x "\t" z "\t" name "\t" layer "\t" level
}

# Without level
match($0, /html:\s*e\(\x27([^<]+)\x27,\s*"([0-9]+)"/, c) ||
match($0, /html:\s*e\("([^"]+)",\s*"([0-9]+)"/, c) {
  if (x == "" || z == "") next

  name = c[1]
  gsub(/[ \t]+$/, "", name)
  gsub(/\\\x27/, sprintf("%c", 39), name)

  size = c[2]

  if (size == 25) layer = 1
  else if (size == 16) layer = 2
  else if (size == 14) layer = 3
  else next

  print x "\t" z "\t" name "\t" layer
}
' > "$TARGET.tmp"

jq -R -s '
  split("\n")
  | map(select(length > 0))
  | map(split("\t"))
  | map(
      if length == 5 then
        { layer: (.[3]|tonumber),
          level: .[4],
          name: .[2],
          x: (.[0]|tonumber),
          z: (.[1]|tonumber) }
      else
        { layer: (.[3]|tonumber),
          name: .[2],
          x: (.[0]|tonumber),
          z: (.[1]|tonumber) }
      end
    )
  | { labels: . }
' "$TARGET.tmp" \
| jq -s '
    (.[0].labels + (.[1].labels // []))
    | sort_by(.name)
    | { labels: . }
  ' - "$MISSING" \
> "$TARGET"
rm "$TARGET.tmp"

# Calculate md5sum of the new places.json
MD5=$(md5sum $TARGET | cut -d' ' -f1)

# Update urls.json with the new md5sum for dataStaticPlaces
jq '. = [.[] | if (.id == "dataStaticPlaces") then (.md5 = "'$MD5'") else . end]' < $MYDIR/../Data-Storage/urls.json > $MYDIR/../Data-Storage/urls.json.tmp
mv $MYDIR/../Data-Storage/urls.json.tmp $MYDIR/../Data-Storage/urls.json

echo Finished updating "$TARGET"

jq '[
.labels[] | {
    featureId: (.name | gsub(" "; "-") | gsub("[^a-zA-Z0-9\\-]+"; "") | ascii_downcase),
    categoryId: ("wynntils:place:" + (if .layer == 1 then "province"
                                      elif .layer == 2 then "city"
                                      else "town-or-place" end)),
    attributes: {
      label: .name
    },
    location: {
      x: .x,
      y: 0,
      z: .z
    }
} + (if .level != null then {level: (
        if .level | test("^\\d+$") then
          (.level | tonumber)
        elif .level | test("^\\d+-\\d+$") then
          (.level | split("-")[0] | tonumber)
        elif .level | test("^\\d+\\+$") then
          (.level | gsub("\\+"; "") | tonumber)
        else
          null  # Default value in case of unexpected format
        end
      )} else {} end)
]
' < "$TARGET" > "$TARGET_MAPFEATURES"

# Calculate md5sum of the new place_mapfeatures.json
MD5=$(md5sum $TARGET_MAPFEATURES | cut -d' ' -f1)

# Update urls.json with the new md5sum for dataStaticPlaceMapFeatures
jq '. = [.[] | if (.id == "dataStaticPlaceMapFeatures") then (.md5 = "'$MD5'") else . end]' < $MYDIR/../Data-Storage/urls.json > $MYDIR/../Data-Storage/urls.json.tmp
mv $MYDIR/../Data-Storage/urls.json.tmp $MYDIR/../Data-Storage/urls.json

echo Finished updating "$TARGET_MAPFEATURES"