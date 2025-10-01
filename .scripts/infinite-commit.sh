#!/bin/bash
# Infinite commit script: randomly updates dummy.txt in a random app-*/values.yaml and commits/pushes
set -e

cd "$(dirname "$0")/.."

while true; do
    APPS=(app-*/)
    NUM_APPS=${#APPS[@]}
    if [ "$NUM_APPS" -eq 0 ]; then
        echo "No app-* folders found!"
        exit 1
    fi
    RANDOM_IDX=$((RANDOM % NUM_APPS))
    SELECTED_APP=${APPS[$RANDOM_IDX]%/}
    VALUES_FILE="$SELECTED_APP/values.yaml"
    if [ ! -f "$VALUES_FILE" ]; then
        echo "$VALUES_FILE not found!"
        exit 1
    fi
        RANDOM_TEXT=$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 13)
        echo $RANDOM_TEXT
        echo "Updating $VALUES_FILE: configmaps.data[\"dummy.txt\"] = $RANDOM_TEXT"
        yq e ".configmaps.data[\"dummy.txt\"] = \"$RANDOM_TEXT\"" -i "$VALUES_FILE"
        git add "$VALUES_FILE"
        git commit -m "Randomize dummy.txt in $SELECTED_APP on $(date)"
        git push
        sleep 1s
done
