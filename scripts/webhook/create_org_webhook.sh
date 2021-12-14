#!/bin/bash

set -euo pipefail

# This writes everything except the DELETE url to `stderr`.
# This allows tools to just capture the url from `stdout` and
# not have to parse all the output.
#
# For example, to just capture the url (i.e., the `stdout`),
# do this:
#
#       ./create_org_webhook.sh 2> /dev/null
#

trap cleanup EXIT

cleanup() {
    rm -f curl.out
}

set +e
SECRET=$(< /dev/urandom tr -cd "[:alnum:]" | head -c 64)
set -e

curl -X POST \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    https://api.github.com/orgs/owls-nest-farm/hooks \
    -d '{ "name": "web", "events": [ "repository" ], "config": { "url": "http://149.56.47.216:8888/events", "content_type": "json", "secret": "'"$SECRET"'", "insecure_ssl": 0 } }' \
    2> /dev/null \
    | >&2 tee curl.out

>&2 echo "[SUCCESS] Created webhook."
DELETE_URL=$(jq --raw-output .url curl.out)
>&2 echo "[INFO] Delete url is $DELETE_URL"
echo "$DELETE_URL"

