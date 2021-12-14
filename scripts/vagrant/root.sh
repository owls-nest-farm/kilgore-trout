#!/usr/bin/env bash

set -euo pipefail

trap cleanup EXIT

cleanup() {
    rm -f /home/vagrant/*.{zip,deb}
}

if [ -z "$GITHUB_TOKEN" ]
then
    echo "[ERROR] There is no GITHUB_TOKEN, exiting..."
    exit 1
fi

apt-get update
apt-get install -y \
    curl \
    gnupg \
    jq \
    silversearcher-ag \
    software-properties-common \
    tree \
    unzip

# Install Go.
curl -LO https://go.dev/dl/go1.17.5.linux-amd64.tar.gz
tar xf go1.17.5.linux-amd64.tar.gz
mv go /usr/local

# Install ngrok.
curl -O https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip
unzip ngrok-stable-linux-amd64.zip -d /usr/local/bin

# Fixes the "-bash: warning: setlocale: LC_ALL: cannot change locale (en_IN.UTF-8)" warning.
{
    echo LANG=en_US.utf-8 ;
    echo LC_ALL=en_US.utf-8 ;
} >> /etc/environment

su -c "source /vagrant/scripts/vagrant/user.sh" vagrant

