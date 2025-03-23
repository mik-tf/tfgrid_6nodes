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

# Generate base inventory
echo "Generating inventory from Terraform outputs..."
tofu -chdir="$DEPLOYMENT_DIR" show -json | jq -r '
  .values.outputs.wireguard_ips.value | 
  to_entries | map(
    "\(.key) ansible_host=\(.value) ansible_user=root"
  ) | .[]
' > "$OUTPUT_FILE"

# Append control nodes
echo -e "\n[control]" >> "$OUTPUT_FILE"
tofu -chdir="$DEPLOYMENT_DIR" show -json | jq -r '
  .values.outputs.wireguard_ips.value |
  keys | map(select(. | test("node_[0-2]"))) | .[]
' >> "$OUTPUT_FILE"


# Append worker nodes
echo -e "\n[worker]" >> "$OUTPUT_FILE"
tofu -chdir="$DEPLOYMENT_DIR" show -json | jq -r '
  .values.outputs.wireguard_ips.value |
  keys | map(select(. | test("node_[3-5]"))) | .[]
' >> "$OUTPUT_FILE"

# Add children groups
echo -e "\n[kube_control:children]\ncontrol" >> "$OUTPUT_FILE"
echo -e "\n[kube_node:children]\nworker" >> "$OUTPUT_FILE"

# Rename nodes from node_0 to node1, node_1 to node2, etc.
echo "Renaming nodes in inventory..."
for i in {0..5}; do
    new_num=$((i + 1))
    sed -i "s/node_${i}/node${new_num}/g" "$OUTPUT_FILE"
done

echo "Inventory generated: $OUTPUT_FILE"
