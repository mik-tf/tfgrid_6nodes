#!/usr/bin/env bash
set -euo pipefail

# Get script directory
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DEPLOYMENT_DIR="$SCRIPT_DIR/../deployment"
OUTPUT_FILE="$SCRIPT_DIR/../kubernetes/inventory.ini"

# Check dependencies
command -v jq >/dev/null 2>&1 || { 
    echo >&2 "ERROR: jq required but not found. Install with: 
    sudo apt install jq || brew install jq";
    exit 1;
}

# Clear existing file and generate new inventory
echo "Generating inventory from Terraform outputs..."
echo "# Kubernetes Control Plane Nodes" > "$OUTPUT_FILE"
echo "[kube_control]" >> "$OUTPUT_FILE"

# Generate control plane nodes (node1, node2, node3)
tofu -chdir="$DEPLOYMENT_DIR" show -json | jq -r '
  .values.outputs.wireguard_ips.value | 
  to_entries | map(select(.key | test("node_[0-2]"))) | 
  .[] | "node\((.key | split("_")[1] | tonumber + 1)) ansible_host=\(.value) ansible_user=root"
' >> "$OUTPUT_FILE"

# Add worker nodes section
echo -e "\n# Kubernetes Worker Nodes" >> "$OUTPUT_FILE"
echo "[kube_node]" >> "$OUTPUT_FILE"

# Generate worker nodes (node4, node5, node6)
tofu -chdir="$DEPLOYMENT_DIR" show -json | jq -r '
  .values.outputs.wireguard_ips.value | 
  to_entries | map(select(.key | test("node_[3-5]"))) | 
  .[] | "node\((.key | split("_")[1] | tonumber + 1)) ansible_host=\(.value) ansible_user=root"
' >> "$OUTPUT_FILE"

# Add global variables
echo -e "\n# Global Variables" >> "$OUTPUT_FILE"
echo "[all:vars]" >> "$OUTPUT_FILE"
echo "ansible_python_interpreter=/usr/bin/python3.12" >> "$OUTPUT_FILE"

echo "Inventory generated: $OUTPUT_FILE"