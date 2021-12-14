#!/bin/bash

set -euo pipefail

echo "[$0] [INFO] Tearing down SSH tunnel..."
pkill ssh
echo "[$0] [INFO] Destroying Vagrant..."
vagrant destroy -f

