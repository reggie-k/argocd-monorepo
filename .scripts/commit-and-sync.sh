#!/bin/bash# --- Infinite loop for random update and sync ---
set -e

ARGOCD_NAMESPACE="argocd"
ARGOCD_SERVER_URL="http://localhost:8080"
ARGOCD_ADMIN_PASSWORD=$(kubectl -n $ARGOCD_NAMESPACE get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo "Login to ArgoCD"
argocd login localhost:8080 --username admin --password $ARGOCD_ADMIN_PASSWORD --plaintext --grpc-web --insecure

while true; do

    cd "$(dirname "$0")/.."
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
    yq e ".generator.configmaps.data[\"dummy.txt\"] = \"$RANDOM_TEXT\"" -i "$VALUES_FILE"
    git add "$VALUES_FILE"
    git commit -m "Randomize dummy.txt in $SELECTED_APP on $(date)"
    git push
    cd -

    # Sync all ArgoCD apps in parallel, then wait for all to finish
    cd "$(dirname "$0")/.."
    ALL_APPS=(app-*/)
    for APP in "${ALL_APPS[@]%/}"; do
        argocd app sync "$APP" &
    done
    wait
    cd -
done
