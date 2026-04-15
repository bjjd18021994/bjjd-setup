#!/bin/bash
set -e

echo "=============================================================================="
echo "   Kubernetes Application Setup Script (Bash Version)"
echo
echo "   Components Installed:"
echo "     - Jenkins (Helm)"
echo "     - HashiCorp Vault (Raft)"
echo "     - Postgres"
echo "     - Keycloak (Helm)"
echo "     - platform-ingress"
echo "=============================================================================="
echo


# ------------------------------------------------------------------------------
# 1. Create the folders to store the k8s data
# ------------------------------------------------------------------------------
mkdir -p /home/bjjd/k8s-data/{platform/{vault,keycloak,ingress},data/postgres,bjjd/app,scripts}
chmod -R 777 /home/bjjd/k8s-data
# ------------------------------------------------------------------------------
# 2. Create the namespaces if not exists
# ------------------------------------------------------------------------------
kubectl create namespace platform || true
kubectl create namespace data || true
kubectl create namespace bjjd || true

# ------------------------------------------------------------------------------
# 3. Create the local-path storage class
# ------------------------------------------------------------------------------
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml

# ------------------------------------------------------------------------------
# 4. Install Jenkins
# ------------------------------------------------------------------------------

echo "===== Starting Jenkins Installation ====="
cd jenkins

# Check if Jenkins Helm release exists
if helm list -n platform | grep -q "jenkins"; then
    echo "Found existing Jenkins release. Uninstalling..."
    helm uninstall jenkins -n platform
else
    echo "No Jenkins release found. Skipping uninstall."
fi

# Allow cleanup time
sleep 10

# Install Jenkins
echo "Installing Jenkins chart..."
helm install jenkins ./jenkins-chart/ -n platform

cd ..


# ------------------------------------------------------------------------------
# 4. Install Hashicorp Vault (Raft Mode)
# ------------------------------------------------------------------------------

echo "===== Starting Vault (Raft) Installation ====="
cd hashicorp-vault

# Execute Vault installation script
bash install-vault-raft.sh

cd ..

# ------------------------------------------------------------------------------
# 5. Install Postgres
# ------------------------------------------------------------------------------

echo "===== Starting Postgres Installation ====="
cd postgres

# Execute Postgres installation script
bash install-postgres.sh

cd ..


# ------------------------------------------------------------------------------
# 6. Install Keycloak
# ------------------------------------------------------------------------------

echo "===== Starting Keycloak Installation ====="
cd keycloak

# Check if Keycloak Helm release exists
if helm list -n platform | grep -q "keycloak"; then
    echo "Found existing Keycloak release. Uninstalling..."
    helm uninstall keycloak -n platform
else
    echo "No Keycloak release found. Skipping uninstall."
fi

# Allow cleanup time
sleep 10
kubectl delete pvc keycloak-data-keycloak-0 -n platform --ignore-not-found=true >/dev/null 2>&1
# Install Keycloak
echo "Installing Keycloak chart..."
helm install keycloak ./keycloak-chart/ -n platform

cd ..

# ------------------------------------------------------------------------------
# 7. Install Ingress platform with TLS setup
# ------------------------------------------------------------------------------

echo "===== Starting Postgres Installation ====="
cd platform-ingress

# Execute Postgres installation script
bash install-ingress-platform.sh

cd ..

# ------------------------------------------------------------------------------
# Completed
# ------------------------------------------------------------------------------

echo
echo "===== All Components Installed Successfully ====="
