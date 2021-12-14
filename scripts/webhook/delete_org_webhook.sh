#!/bin/bash

set -eo pipefail

if [ -z "$URL" ]
then
    echo "[ERROR] No URL provided, exiting..."
    exit 1
fi

curl -X DELETE \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "$URL"

echo "[INFO] Deleted webhook $URL"

