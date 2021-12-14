#!/usr/bin/env bash
# shellcheck disable=2016

set -euo pipefail

# This is necessary to access the private repos (see README).
ssh-keyscan -H github.com >> .ssh/known_hosts

{
    echo "export GITHUB_TOKEN=$GITHUB_TOKEN" ;
    echo "export WEBHOOK_URL=$WEBHOOK_URL" ;
    echo "export WEBHOOK_DOMAIN=$WEBHOOK_DOMAIN" ;
    echo "export WEBHOOK_PORT=$WEBHOOK_PORT" ;
    echo "export GOPATH=/home/vagrant/go" ;
    echo "export PATH=/usr/local/go/bin:$PATH" ;
} >> "$HOME/.bashrc"

cp /vagrant/{go.{mod,sum},main.go,webService.go} .
cp /vagrant/scripts/setup.sh .
/usr/local/go/bin/go build -o set_branch_protections

