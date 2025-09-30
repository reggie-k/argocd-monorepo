#!/bin/bash# --- Infinite loop for random update and sync ---
set -e

ARGOCD_NAMESPACE="argocd"
ARGOCD_SERVER_URL="http://localhost:8888"
ARGOCD_ADMIN_PASSWORD=$(kubectl -n $ARGOCD_NAMESPACE get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo "Login to ArgoCD"
argocd login localhost:8888 --username admin --password $ARGOCD_ADMIN_PASSWORD --insecure --plaintext

while true; do
    cd "$(dirname "$0")/.."
    APPS=(app-*/)
    NUM_APPS=${#APPS[@]}

    if [ "$NUM_APPS" -eq 0 ]; then
        echo "No app-* folders found!"
        exit 1
    fi

    # Shuffle and pick 5 unique apps for this batch
    BATCH_APPS=($(printf "%s\n" "${APPS[@]%/}" | shuf | head -n 5))

    # Update, commit, and push each app in parallel
    for APP in "${BATCH_APPS[@]}"; do
        (
            VALUES_FILE="$APP/values.yaml"
            if [ ! -f "$VALUES_FILE" ]; then
                echo "$VALUES_FILE not found!"
                exit 1
            fi
            RANDOM_TEXT=$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 13)
            echo $RANDOM_TEXT
            echo "Updating $VALUES_FILE: configmaps.data[\"dummy.txt\"] = $RANDOM_TEXT"
            yq e ".generator.configmaps.data[\"dummy.txt\"] = \"$RANDOM_TEXT\"" -i "$VALUES_FILE"
            git add "$VALUES_FILE"
            git commit -m "Randomize dummy.txt in $APP on $(date)"
            git push
        ) &
    done

    wait
    # Sync all apps in the background, don't wait for finish
    ALL_APPS=(app-*/)
    ALL_APPS_TO_SYNC="${ALL_APPS[@]%/}"
    argocd app sync $ALL_APPS_TO_SYNC &
    cd -
done
