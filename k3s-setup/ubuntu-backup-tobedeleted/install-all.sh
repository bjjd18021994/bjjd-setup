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
# 1. Install Jenkins
# ------------------------------------------------------------------------------

echo "===== Starting Jenkins Installation ====="
cd jenkins

# Check if Jenkins Helm release exists
if helm list -n default | grep -q "jenkins"; then
    echo "Found existing Jenkins release. Uninstalling..."
    helm uninstall jenkins -n default
else
    echo "No Jenkins release found. Skipping uninstall."
fi

# Allow cleanup time
sleep 10

# Install Jenkins
echo "Installing Jenkins chart..."
helm install jenkins ./jenkins-chart/

cd ..


# ------------------------------------------------------------------------------
# 2. Install HashiCorp Vault (Raft Mode)
# ------------------------------------------------------------------------------

echo "===== Starting Vault (Raft) Installation ====="
cd hashicorp-vault

# Execute Vault installation script
bash install-vault-raft.sh

cd ..


# ------------------------------------------------------------------------------
# 3. Install Postgres
# ------------------------------------------------------------------------------

echo "===== Starting Postgres Installation ====="
cd postgres

# Execute Postgres installation script
bash install_postgres.sh

cd ..


# ------------------------------------------------------------------------------
# 4. Install Keycloak
# ------------------------------------------------------------------------------

echo "===== Starting Keycloak Installation ====="
cd keycloak

# Check if Keycloak Helm release exists
if helm list -n default | grep -q "keycloak"; then
    echo "Found existing Keycloak release. Uninstalling..."
    helm uninstall keycloak -n default
else
    echo "No Keycloak release found. Skipping uninstall."
fi

# Allow cleanup time
sleep 10

# Install Keycloak
echo "Installing Keycloak chart..."
helm install keycloak ./keycloak-chart/

cd ..


# ------------------------------------------------------------------------------
# Completed
# ------------------------------------------------------------------------------

echo
echo "===== All Components Installed Successfully ====="
