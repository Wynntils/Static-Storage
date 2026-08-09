#!/bin/bash

TARGET_DIR=$(cd $(dirname "$0")/.. >/dev/null 2>&1 && pwd)/Reference

# Find the repository root relative to this script.
ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

# Load .local-env if the variable isn't already set.
if [ -z "${WYNNCRAFT_API_KEY:-}" ] && [ -f "$ROOT_DIR/.local-env" ]; then
    . "$ROOT_DIR/.local-env"
fi

if [ -z "${WYNNCRAFT_API_KEY:-}" ]; then
    echo "Error: WYNNCRAFT_API_KEY is not set"
    echo "Either export it or create $ROOT_DIR/.local-env containing the following"
    echo "WYNNCRAFT_API_KEY=\"<api_key_here>\""
    echo "export WYNNCRAFT_API_KEY"
    exit 1
fi

AUTH_HEADER="Authorization: Bearer ${WYNNCRAFT_API_KEY}"

TARGET="gathering_nodes.json"

wget --header="$AUTH_HEADER" -O "$TARGET_DIR/$TARGET.tmp" "https://api.wynncraft.com/v3/map/gathering-nodes"

if [ ! -s "$TARGET_DIR/$TARGET.tmp" ]; then
    rm "$TARGET_DIR/$TARGET.tmp"
    echo "Error: Wynncraft API is not working, aborting"
    exit 1
fi

if jq -e '(length == 2 and has("message") and has("request_id")) or has("error")' "$TARGET_DIR/$TARGET.tmp" > /dev/null; then
    rm "$TARGET_DIR/$TARGET.tmp"
    echo "Error: Wynncraft API returned an error message, aborting"
    exit 1
fi

mv "$TARGET_DIR/$TARGET.tmp" "$TARGET_DIR/$TARGET"

MD5=$(md5sum "$TARGET_DIR/$TARGET" | cut -d' ' -f1)

jq '. = [.[] | if (.id == "dataStaticGatheringNodes") then (.md5 = "'$MD5'") else . end]' < "$TARGET_DIR/../Data-Storage/urls.json" > "$TARGET_DIR/../Data-Storage/urls.json.tmp"
mv "$TARGET_DIR/../Data-Storage/urls.json.tmp" "$TARGET_DIR/../Data-Storage/urls.json"

TARGET_MAPFEATURES="gathering_node_mapfeatures.json"

# The profession a node belongs to is derived from materials.json, so new Wynncraft materials
# are picked up without editing this script. A source material name can belong to several
# professions (Dernic exists for all four, Molten for mining and fishing); the API gives us
# nothing to disambiguate with, so mining wins, which is what Wynntils has always shown.
GATHERING_LOOKUP='
def profession_rank: {"mining": 0, "woodcutting": 1, "farming": 2, "fishing": 3};

# Source materials that materials.json does not describe (Wynntils MiscGatheringType).
def overrides: {
  "LARBONIC_GEODE": {src: "Larbonic Geode", sub: "mining"},
  "RED_ALDER":      {src: "Red Alder",      sub: "woodcutting"},
  "BAMBOO":         {src: "Bamboo",         sub: "woodcutting"},
  "CEMBRA_PINE":    {src: "Cembra Pine",    sub: "woodcutting"},
  "DOUGLAS_FIR":    {src: "Douglas Fir",    sub: "woodcutting"},
  "FLERISI_TREE":   {src: "Flerisi Tree",   sub: "woodcutting"},
  "FLERISI_TRUNK":  {src: "Flerisi Trunk",  sub: "woodcutting"},
  "BLOSSOM":        {src: "Blossom",        sub: "woodcutting"},
  "INDUSTREE":      {src: "Industree",      sub: "woodcutting"},
  "VOIDGLOOM":      {src: "Voidgloom",      sub: "farming"},
  "ABYSSAL_MATTER": {src: "Abyssal Matter",  sub: "fishing"}
};

def lookup:
  ($materials[0] | to_entries
    | map(select(.value.type == "material" and .value.subType != null))
    | map({src: (.key | split(" ")[0]), sub: .value.subType})
    | sort_by(profession_rank[.sub])   # jq sorts are stable, so group_by keeps this order ...
    | group_by(.src)
    | map({key: (.[0].src | ascii_upcase), value: .[0]})   # ... and .[0] is the top priority
    | from_entries)
  + overrides;
'

# Warn about resources we could not place, so the auto-generated PR surfaces them
UNMAPPED=$(jq -n -r --slurpfile materials "$TARGET_DIR/materials.json" --slurpfile nodes "$TARGET_DIR/$TARGET" \
    "$GATHERING_LOOKUP"'lookup as $lookup
     | [$nodes[0][] | select(.type == "NODE") | .resource | select($lookup[.] == null)] | unique | .[]')
if [ -n "$UNMAPPED" ]; then
    echo "Warning: no profession known for these gathering resources, they will use the unknown category:" >&2
    echo "$UNMAPPED" >&2
fi

# Only NODE entries are actual gathering spots. WALL and CORNER are the surrounding blocks of
# an ore vein and would render as duplicate icons a block away from the node itself.
jq -n --slurpfile materials "$TARGET_DIR/materials.json" --slurpfile nodes "$TARGET_DIR/$TARGET" \
  "$GATHERING_LOOKUP"'
def material_suffix: {"mining": "ore", "woodcutting": "log", "farming": "crop", "fishing": "fish"};

lookup as $lookup
| [ $nodes[0][]
    | select(.type == "NODE")
    | . as $node
    | ($lookup[$node.resource] // {src: $node.resource, sub: "unknown"}) as $material
    | { resource: ($material.src | ascii_downcase | gsub(" |_"; "-") | gsub("[^a-z0-9\\-]+"; "")),
        profession: $material.sub,
        location: {x: $node.x, y: $node.y, z: $node.z} } ]
| group_by(.profession + ":" + .resource)
| map(to_entries | map(.value + {index: .key}))
| flatten
| map({
    featureId: (.resource + "-" + (material_suffix[.profession] // "node") + "-" + (.index | tostring)),
    categoryId: ("wynntils:gathering:" + .profession + ":" + .resource),
    location: .location
  })
' > "$TARGET_DIR/$TARGET_MAPFEATURES"

MD5=$(md5sum "$TARGET_DIR/$TARGET_MAPFEATURES" | cut -d' ' -f1)

jq '. = [.[] | if (.id == "dataStaticGatheringNodeMapFeatures") then (.md5 = "'$MD5'") else . end]' < "$TARGET_DIR/../Data-Storage/urls.json" > "$TARGET_DIR/../Data-Storage/urls.json.tmp"
mv "$TARGET_DIR/../Data-Storage/urls.json.tmp" "$TARGET_DIR/../Data-Storage/urls.json"
