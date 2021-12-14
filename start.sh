#!/bin/bash

set -eo pipefail

if [ -z "$GITHUB_TOKEN" ]
then
    echo "[$0] [INFO] \`GITHUB_TOKEN\` is not set, exiting..."
    exit 1
fi

if [ -n "$WEBHOOK_URL" ]
then
    # Remove the scheme before sending to `read`.
    IFS=: read -r WEBHOOK_DOMAIN WEBHOOK_PORT <<< "${WEBHOOK_URL#*//}"

    if [ -z "$WEBHOOK_PORT" ]
    then
        WEBHOOK_PORT=80
    fi

    echo "[$0] [INFO] Forwarding port $WEBHOOK_PORT to $WEBHOOK_URL..."
    ssh -fCNR "$WEBHOOK_PORT:127.0.0.1:4141" "$WEBHOOK_DOMAIN"

    echo "[$0] [INFO] Starting Vagrant..."
    GITHUB_TOKEN="$GITHUB_TOKEN" \
    WEBHOOK_URL="$WEBHOOK_URL" \
    WEBHOOK_DOMAIN="$WEBHOOK_DOMAIN" \
    WEBHOOK_PORT="$WEBHOOK_PORT" \
        vagrant up
else
    GITHUB_TOKEN="$GITHUB_TOKEN" \
        vagrant up
fi

echo "[$0] [INFO] Logging into Vagrant..."
vagrant ssh

