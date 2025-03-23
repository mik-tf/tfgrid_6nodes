#!/usr/bin/env bash
set -euo pipefail

# Check dependencies
command -v jq >/dev/null 2>&1 || { 
    echo >&2 "ERROR: jq required but not found. Install with: 
    sudo apt install jq || brew install jq";
    exit 1;
}

command -v tofu >/dev/null 2>&1 || {
    echo >&2 "ERROR: tofu (OpenTofu) required but not found.";
    exit 1;
}

# Get script directory
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DEPLOYMENT_DIR="$SCRIPT_DIR/../deployment"

# Declare associative arrays for IP addresses
declare -A mycelium_ips=()
declare -A wireguard_ips=()
declare -A public_ips=()

# Fetch IP addresses from Terraform outputs
echo "Fetching IP addresses from Terraform..."
terraform_output=$(tofu -chdir="$DEPLOYMENT_DIR" show -json)

# Parse Mycelium IPs (IPv6)
while IFS="=" read -r key value; do
    mycelium_ips["$key"]="$value"
done < <(jq -r '.values.outputs.mycelium_ips.value // empty | to_entries[] | "\(.key)=\(.value)"' <<< "$terraform_output")

# Parse WireGuard IPs (IPv4)
while IFS="=" read -r key value; do
    wireguard_ips["$key"]="$value"
done < <(jq -r '.values.outputs.wireguard_ips.value // empty | to_entries[] | "\(.key)=\(.value)"' <<< "$terraform_output")

# Parse Public IPs (IPv4 - may not exist for all nodes)
while IFS="=" read -r key value; do
    public_ips["$key"]="$value"
done < <(jq -r '.values.outputs.public_ips.value // empty | to_entries[] | "\(.key)=\(.value)"' <<< "$terraform_output")

# Perform ping tests
for node in "${!mycelium_ips[@]}"; do
    # Mycelium (IPv6) check
    echo "=== Pinging Mycelium (${node}) ${mycelium_ips[$node]} ==="
    ping6 -c 5 "${mycelium_ips[$node]}" || true
    
    # WireGuard (IPv4) check
    echo -e "\n=== Pinging WireGuard (${node}) ${wireguard_ips[$node]} ==="
    ping -c 5 "${wireguard_ips[$node]}" || true
    
    # Public IP check (if exists)
    if [ "${public_ips[$node]+exists}" ]; then
        echo -e "\n=== Pinging Public (${node}) ${public_ips[$node]} ==="
        ping -c 5 "${public_ips[$node]}" || true
    fi
    
    echo -e "\n"
done

echo "All ping tests completed!"