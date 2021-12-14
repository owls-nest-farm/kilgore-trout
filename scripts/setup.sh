#!/usr/bin/env bash

set -euo pipefail

trap cleanup EXIT

cleanup() {
    curl -X DELETE \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "$DELETE_URL"

    echo "[INFO] Deleted webhook $DELETE_URL"
}

# By default, the Go server will listen on port 4141, because
# that is the advertised port that `ngrok` uses for its tunnel.
PORT=${1:-4141}

# I believe the left side of the pipe returns exit code 141 because
# it's continuously reading from `/dev/urandom`, but I really don't
# have a good explanation, I'm afraid.
set +o pipefail
SECRET=$(< /dev/urandom tr -cd "[:alnum:]" | head -c 64)
set -o pipefail

echo "[INFO] Creating webhook..."

DELETE_URL=$(
    curl -X POST \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        https://api.github.com/orgs/owls-nest-farm/hooks \
        -d '{ "name": "web", "events": [ "repository" ], "config": { "url": "'"$URL"/events'", "content_type": "json", "secret": "'"$SECRET"'", "insecure_ssl": 0 } }' \
    2> /dev/null \
    | jq --raw-output .url
)

echo "[INFO] Starting Go server..."
./set_branch_protections -port "$PORT"

