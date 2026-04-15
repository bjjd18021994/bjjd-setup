#!/bin/bash
# =========================================================================================
#   install-vault-raft.sh
#   Fully Automated Rollback + Fresh Install of HashiCorp Vault (Raft)
#   Kubernetes: Docker Desktop / Linux K8s (Default Namespace)
# =========================================================================================
#
# SUMMARY
# -------
# This script safely removes any existing Vault deployment and then performs a complete
# fresh install using Raft storage. All delete operations ignore errors, ensuring
# the script runs cleanly even if resources do not exist.
#
# REQUIREMENTS
# ------------
# - kubectl installed and configured
# - helm installed
# - Docker Desktop Kubernetes or any local K8s cluster
# - Directory "hashicorp-vault-setup-files" must contain:
#       hostpath-storageclass.yaml
#       hashicorp-vault-raft-pv.yaml
#       hashicorp-vault-raft-values.yaml
#
# USAGE
# -----
# chmod +x install-vault-raft.sh
# ./install-vault-raft.sh
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
echo "=== Rollback complete. Starting fresh install ==="


# -------------------------------
# APPLY PV
# -------------------------------
echo "Applying PersistentVolume..."
kubectl apply -f hashicorp-vault-setup-files/hashicorp-vault-raft-pv.yaml


# -------------------------------
# INSTALL VAULT USING HELM
# -------------------------------
echo "Adding HashiCorp Helm repo..."
helm repo add hashicorp https://helm.releases.hashicorp.com >/dev/null 2>&1

echo "Updating Helm repo..."
helm repo update

echo "Installing Vault with Raft enabled..."
helm install vault hashicorp/vault -n platform \
  --values hashicorp-vault-setup-files/hashicorp-vault-raft-values.yaml


# -------------------------------
# FINAL MESSAGE
# -------------------------------
echo "============================="
echo "Vault installation triggered..."
echo "Pods will start in the platform namespace."
echo ""
echo "Check pod status:"
echo "   kubectl get pods"
echo ""
echo "Once vault-0 is running, initialize it:"
echo "   kubectl exec vault-0 -- vault operator init"
echo "============================="
