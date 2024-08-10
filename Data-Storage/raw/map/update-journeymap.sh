#!/bin/bash
# This script helps the user update the map for Wynntils, using journeymap.
# Please install journeymap 6.0, found in the bin directory.
#
# Made by magicus (https://github.com/magicus)
#

base_dir="$(cd $(dirname "$0")/.. 2>/dev/null && pwd)"
WYNNCRAFT_WORLD_NAME=${WYNNCRAFT_WORLD_NAME:-Wynncraft}
WYNNDATA_DIR=${WYNNDATA_DIR:-$base_dir/map}
COMMAND=$1

if [[ ! -e options.txt ]]; then
    echo "This does not seem to be a Minecraft directory"
    echo "Please cd to your Minecraft directory and try again"
    exit 1
fi
if [[ ! -d journeymap ]]; then
    echo "Cannot find journeymap directory"
    echo "Please verify that you are in the correct directory"
    exit 1
fi

if [[ $COMMAND = "get-from-journeymap" ]]; then
  mkdir -p $WYNNDATA_DIR/journeymap-data/DIM0/day
  echo "Changed files:"
  diff -q journeymap/data/mp/$WYNNCRAFT_WORLD_NAME/DIM0/day $WYNNDATA_DIR/raw_map
  cp -f journeymap/data/mp/$WYNNCRAFT_WORLD_NAME/DIM0/day/* $WYNNDATA_DIR/raw_map
  echo "Please go to $WYNNDATA_DIR and commit and push your changes"
elif [[ $COMMAND == "install-in-journeymap" ]]; then
  mkdir -p journeymap/data/mp/$WYNNCRAFT_WORLD_NAME/DIM0/day
  echo "Changed files:"
  diff -q $WYNNDATA_DIR/raw_map journeymap/data/mp/$WYNNCRAFT_WORLD_NAME/DIM0/day
  cp -f $WYNNDATA_DIR/raw_map/* journeymap/data/mp/$WYNNCRAFT_WORLD_NAME/DIM0/day
  echo "Your journeymap installation now has the latest map data"
elif [[ $COMMAND == "install-wynntils-config" ]]; then
  if [[ ! -d journeymap/config/6.0 ]]; then
      echo "Cannot find journeymap 6.0 config directory"
      echo "Please verify that you are in the correct directory and that you have journeymap 6.0 installed"
      exit 1
  fi
  cp -a journeymap/config/6.0/journeymap.core.config journeymap/config/6.0/journeymap.core.config.orig
  cp -a journeymap/colorpalette.json journeymap/colorpalette.json.orig
  cp $WYNNDATA_DIR/config/journeymap.core.config journeymap/config/6.0/journeymap.core.config
  cp $WYNNDATA_DIR/config/colorpalette.json journeymap/colorpalette.json
  echo "Replaced journeymap.core.config and colorpalette.json (backups saved as .orig)"
elif [[ $COMMAND == "restore-orig-config" ]]; then
  if [[ ! -d journeymap/config/6.0 ]]; then
      echo "Cannot find journeymap 6.0 config directory"
      echo "Please verify that you are in the correct directory and that you have journeymap 6.0 installed"
      exit 1
  fi
  cp -a journeymap/config/6.0/journeymap.core.config.orig journeymap/config/6.0/journeymap.core.config
  cp -a journeymap/colorpalette.json.orig journeymap/colorpalette.json
  echo "Restored journeymap.core.config and colorpalette.json from backups"
else
  echo "Usage: $0 [get-from-journeymap|install-in-journeymap|install-wynntils-config|restore-orig-config]"
fi
