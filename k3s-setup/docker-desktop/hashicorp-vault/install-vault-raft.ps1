<#
=========================================================================================
   install-vault-raft.ps1
   Fully Automated Rollback + Fresh Install of HashiCorp Vault (Raft)
   Kubernetes: Docker Desktop (Default Namespace)
=========================================================================================

SUMMARY
-------
This script performs a clean deployment of HashiCorp Vault using the Raft storage backend
on Docker Desktop Kubernetes. It is designed to be safe, repeatable, and fully automated.

WHAT THE SCRIPT DOES:
---------------------
1. **Rollback Phase (Safe Cleanup)**
   ▪ Removes old Helm release (only if it exists)
   ▪ Deletes the StorageClass (hostpath)
   ▪ Deletes PVC (data-vault-0)
   ▪ Deletes PV (hashicorp-vault-raft-pv)
   ▪ All cleanup errors are ignored safely

2. **Fresh Deployment**
   ▪ Applies the StorageClass YAML
   ▪ Applies the PersistentVolume YAML
   ▪ Adds + updates the HashiCorp Helm repo
   ▪ Installs Vault using the Raft-enabled values.yaml

3. **Result**
   ▪ A clean Vault Raft cluster ready to initialize and unseal
   ▪ Everything deployed inside the *default namespace*

USAGE
-----
Run from PowerShell:

   ./install-vault-raft.ps1

REQUIREMENTS
------------
▪ kubectl installed and configured  
▪ helm installed  
▪ Docker Desktop with Kubernetes enabled  
▪ The folder "hashicorp-vault-setup-files" must contain:
       - hostpath-storageclass.yaml
       - hashicorp-vault-raft-pv.yaml
       - hashicorp-vault-raft-values.yaml
=========================================================================================
#>

echo "=== Starting Rollback (Ignore errors) ==="


# -------------------------------
# ROLLBACK PHASE
# -------------------------------

# Remove existing Helm release ONLY if it exists
if (helm list -n default | Select-String -Pattern "vault") {
    Write-Host "Found release 'vault'. Uninstalling..." -ForegroundColor Yellow
    helm uninstall vault --namespace default
} else {
    Write-Host "Release 'vault' does not exist. Skipping." -ForegroundColor DarkYellow
}

# Delete StorageClass (ignore failure)
# kubectl delete sc hostpath 2>$null

# Delete Vault PVC (ignore failure)
kubectl delete pvc data-vault-0 2>$null

# Delete PersistentVolume (ignore failure)
kubectl delete pv hashicorp-vault-raft-pv 2>$null

Start-Sleep -Seconds 3
echo "=== Rollback complete. Starting fresh install ==="


# -------------------------------
# APPLY STORAGECLASS + PV
# -------------------------------

# Check if StorageClass 'hostpath' exists
$scExists = kubectl get storageclass | Select-String "^hostpath\s"

if ($scExists) {
    Write-Host "StorageClass 'hostpath' already exists. Skipping creation."
} else {
    Write-Host "StorageClass 'hostpath' not found. Creating..."
    kubectl apply -f "hashicorp-vault-setup-files/hostpath-storageclass.yaml"
}


echo "Applying PersistentVolume..."
kubectl apply -f "hashicorp-vault-setup-files/hashicorp-vault-raft-pv.yaml"


# -------------------------------
# INSTALL VAULT (HELM)
# -------------------------------

echo "Adding HashiCorp Helm repo..."
helm repo add hashicorp https://helm.releases.hashicorp.com 2>$null

echo "Updating Helm repo..."
helm repo update

echo "Installing Vault with Raft enabled..."
helm install vault hashicorp/vault --values hashicorp-vault-setup-files/hashicorp-vault-raft-values.yaml


# -------------------------------
# FINAL MESSAGE
# -------------------------------
echo "============================="
echo "Vault installation started..."
echo "Pods coming up in default namespace"
echo "Check status using:"
echo "   kubectl get pods"
echo "============================="
