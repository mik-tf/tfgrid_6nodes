#!/bin/bash

set -e

# --- Configuration ---
# Define the path to your Terraform/Tofu configuration directory
TF_CONFIG_DIR_DEPLOYMENT="$(realpath ../deployment)"  # Or wherever your .tf files are
TF_CONFIG_DIR_KUBERNETES="$(realpath ../kubernetes)"  # Or wherever your .tf files are

# --- Cleanup (if needed) ---
cd "$TF_CONFIG_DIR_DEPLOYMENT" || exit 1  # Exit if cd fails
# Example: Destroy the 'clean' resources (adapt to your actual setup)
tofu destroy -auto-approve
bash ../scripts/cleantf.sh

# --- Terraform/Tofu ---
cd "$TF_CONFIG_DIR_DEPLOYMENT" || exit 1  # Ensure we're in the correct directory

tofu init
if ! tofu apply -auto-approve; then
  echo "Tofu apply failed!"
  # Add additional error handling/notification here
  exit 1
fi

# --- WireGuard and Inventory ---
bash ../scripts/wg.sh
bash ../scripts/generate-inventory.sh

# --- Ansible ---
cd "$TF_CONFIG_DIR_KUBERNETES" || exit 1  # Ensure we're in the correct directory

# Robust Ansible Ping with Retry
MAX_RETRIES=5
RETRY_DELAY=5  # seconds

ansible_ping() {
  local retries=0
  while [[ $retries -lt $MAX_RETRIES ]]; do
    ansible all -m ping
    if [[ $? -eq 0 ]]; then
      echo "Ansible ping successful!"
      return 0  # Exit the function successfully
    fi
    retries=$((retries + 1))
    echo "Ansible ping failed (attempt $retries/$MAX_RETRIES). Retrying in $RETRY_DELAY seconds..."
    sleep "$RETRY_DELAY"
  done

  echo "Ansible ping failed after $MAX_RETRIES attempts."
  return 1  # Indicate failure after all retries
}


if ! ansible_ping; then
    echo "Failed to establish Ansible connection after multiple retries."
    exit 1
fi


if ! ansible-playbook k8s-cluster.yml -t common,control,worker; then
  echo "Ansible playbook failed!"
  # Add additional error handling/notification here
  exit 1
fi

echo "Deployment completed successfully!"