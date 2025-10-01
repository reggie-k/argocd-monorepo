#!/bin/bash
# Regenerate all app-* folders from app-0, deleting all others and recreating them as copies of app-0
set -e

cd "$(dirname "$0")/.."

# Remove all app-* except app-0
echo "Deleting all app-* folders except app-0..."
for d in app-*; do
    if [[ "$d" != "app-0" && -d "$d" ]]; then
        rm -rf "$d"
    fi
done

# Recreate app-1 to app-30 from app-0
echo "Recreating app-1 to app-30 from app-0..."
for i in {1..30}; do
    cp -r app-0 "app-$i"
    # Optionally, update values.yaml or Chart.yaml if you want to customize per app
    # For example, you could set a unique value in values.yaml:
    # yq e ".appIndex = $i" -i "app-$i/values.yaml"
done

echo "All apps regenerated from app-0."
