#!/usr/bin/env bash
set -euo pipefail

# Get script directory
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DEPLOYMENT_DIR="$SCRIPT_DIR/../deployment"

# Check dependencies
command -v jq >/dev/null 2>&1 || { 
    echo >&2 "ERROR: jq required but not found. Install with: 
    sudo apt install jq || brew install jq";
    exit 1;
}

# Get worker public IPs
WORKER_IPS=$(tofu -chdir="$DEPLOYMENT_DIR" output -json worker_public_ips | jq -r '.[] | @text')

# Convert to array
IPS_ARRAY=($WORKER_IPS)

# Domain to configure
DOMAIN=${1:-"onlineschool.com"}

echo "Configure your DNS provider with the following records for $DOMAIN:"
echo "-----------------------------------------------------------"
echo "Type  | Name                 | Value"
echo "-----------------------------------------------------------"
echo "A     | $DOMAIN              | ${IPS_ARRAY[0]}"
echo "A     | $DOMAIN              | ${IPS_ARRAY[1]}"
echo "A     | $DOMAIN              | ${IPS_ARRAY[2]}"
echo "A     | studio.$DOMAIN       | ${IPS_ARRAY[0]}"
echo "A     | studio.$DOMAIN       | ${IPS_ARRAY[1]}"
echo "A     | studio.$DOMAIN       | ${IPS_ARRAY[2]}"
echo "-----------------------------------------------------------"
echo "This will configure round-robin DNS for load balancing across all worker nodes."
