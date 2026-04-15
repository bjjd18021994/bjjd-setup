#!/bin/bash
# =========================================================================================
#   delete-vault-raft.sh
#   Fully Automated Rollback
#   Kubernetes: Docker Desktop / Linux K8s (Default Namespace)
# =========================================================================================
#
# SUMMARY
# -------
# This script safely removes any existing Vault deployment and then performs a complete
# fresh install using Raft storage. All delete operations ignore errors, ensuring
# the script runs cleanly even if resources do not exist.
#
# chmod +x delete-vault-raft.sh
# ./delete-vault-raft.sh
#
# =========================================================================================

echo "=== Starting Rollback (Ignore errors) ==="

# -------------------------------
# CHECK IF HELM RELEASE EXISTS
# -------------------------------
if helm list -n platform | grep -q "vault"; then
    echo "Found release 'vault'. Uninstalling..."
    helm uninstall vault -n platform
else
    echo "Release 'vault' does not exist. Skipping uninstall."
fi

# -------------------------------
# SAFE CLEANUP (IGNORE ERRORS)
# -------------------------------
echo "Deleting PVC (ignore errors)..."
kubectl delete pvc data-vault-0 -n platform --ignore-not-found=true >/dev/null 2>&1

echo "Deleting PV (ignore errors)..."
kubectl delete pv hashicorp-vault-raft-pv --ignore-not-found=true >/dev/null 2>&1

sleep 3
echo -e "${GREEN}Hashicorp Vault setup has been deleted successfully!${NC}"