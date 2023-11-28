#!/bin/bash

BASE_DIR="$(cd $(dirname "$0")/.. 2>/dev/null && pwd)"

jq 'sort_by(if has("id") then .id else "" end)' < ./Data-Storage/urls.json > ./Data-Storage/urls.json.tmp

mv ./Data-Storage/urls.json.tmp ./Data-Storage/urls.json
