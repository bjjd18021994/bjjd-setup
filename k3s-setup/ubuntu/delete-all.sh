#!/bin/bash
set -e

echo "=============================================================================="
echo "   Kubernetes Application Setup Script (Bash Version)"
echo
echo "   Components to be uninstalled:"
echo "     - Jenkins (Helm)"
echo "     - HashiCorp Vault (Raft)"
echo "     - Postgres"
echo "     - Keycloak (Helm)"
echo "     - platform-ingress"
echo "=============================================================================="
echo

# ------------------------------------------------------------------------------
# 3. Install Jenkins
# ------------------------------------------------------------------------------

echo "===== Uninstalling Jenkins ====="
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

cd ..

# ------------------------------------------------------------------------------
# 4. Install HashiCorp Vault (Raft Mode)
# ------------------------------------------------------------------------------

echo "===== Uninstalling Vault (Raft) ====="
cd hashicorp-vault

# Execute Vault installation script
bash delete-vault-raft.sh

cd ..


# ------------------------------------------------------------------------------
# 5. Install Postgres
# ------------------------------------------------------------------------------

echo "===== Uninstalling Postgres ====="
cd postgres

# Execute Postgres installation script
bash delete-postgres.sh

cd ..


# ------------------------------------------------------------------------------
# 6. Install Keycloak
# ------------------------------------------------------------------------------

echo "===== Uninstalling Keycloak ====="
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

cd ..

# ------------------------------------------------------------------------------
# 7. Install Ingress platform with TLS setup
# ------------------------------------------------------------------------------

echo "===== Uninstalling Ingress ====="

# Execute Ingress uninstallation script
if helm list -n platform | grep -q "platform-ingress"; then
    echo "Found existing platform-ingress release. Uninstalling..."
    helm uninstall platform-ingress -n platform
else
    echo "No platform-ingress release found. Skipping uninstall."
fi

# ------------------------------------------------------------------------------
# Completed
# ------------------------------------------------------------------------------

echo
echo "===== All Components uninstalled Successfully ====="
