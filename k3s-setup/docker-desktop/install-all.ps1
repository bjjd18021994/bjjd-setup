<#
================================================================================
   Kubernetes Application Setup Script
   Components Installed:
     - Jenkins          (Helm chart)
     - HashiCorp Vault (Raft mode, via external script)
     - Postgres         (via external script)
     - Keycloak         (Helm chart)

   This script ensures each component is installed cleanly by:
     ✔ Checking if a Helm release already exists
     ✔ Uninstalling old releases (idempotent installation)
     ✔ Executing component-specific install scripts
     ✔ Adding wait times to allow cleanup and provisioning

   Author: <Your Name>
   Purpose: Automated, repeatable setup of the platform stack
================================================================================
#>

# -------------------------------------------------------------------------------
# 1. Install Jenkins
# -------------------------------------------------------------------------------

Write-Host "===== Starting Jenkins Installation =====" -ForegroundColor Cyan
cd jenkins

# Check if Jenkins Helm release already exists
$jenkinsExists = helm list -n default | Select-String "jenkins"

if ($jenkinsExists) {
    Write-Host "Found existing Jenkins release. Uninstalling..." -ForegroundColor Yellow
    helm uninstall jenkins -n default
} else {
    Write-Host "No existing Jenkins release found. Skipping uninstall." -ForegroundColor Green
}

# Allow time for resources to clean up
Start-Sleep -Seconds 10

# Install Jenkins Helm chart
Write-Host "Installing Jenkins chart..." -ForegroundColor Cyan
helm install jenkins .\jenkins-chart\


# -------------------------------------------------------------------------------
# 2. Install HashiCorp Vault (Raft mode)
# -------------------------------------------------------------------------------

Write-Host "`n===== Starting Vault (Raft) Installation =====" -ForegroundColor Cyan
cd ../hashicorp-vault

# Run Vault installation script
& ".\install-vault-raft.ps1"


# -------------------------------------------------------------------------------
# 3. Install Postgres
# -------------------------------------------------------------------------------

Write-Host "`n===== Starting Postgres Installation =====" -ForegroundColor Cyan
cd ../postgres

# Run Postgres installation script
& ".\install_postgres.ps1"


# -------------------------------------------------------------------------------
# 4. Install Keycloak
# -------------------------------------------------------------------------------

Write-Host "`n===== Starting Keycloak Installation =====" -ForegroundColor Cyan
cd ../keycloak

# Check if Keycloak Helm release exists
$keycloakExists = helm list -n default | Select-String "keycloak"

if ($keycloakExists) {
    Write-Host "Found existing Keycloak release. Uninstalling..." -ForegroundColor Yellow
    helm uninstall keycloak -n default
} else {
    Write-Host "No existing Keycloak release found. Skipping uninstall." -ForegroundColor Green
}

# Allow cleanup time
Start-Sleep -Seconds 10

# Install Keycloak Helm chart
Write-Host "Installing Keycloak chart..." -ForegroundColor Cyan
helm install keycloak .\keycloak-chart\


# -------------------------------------------------------------------------------
# Script Completed
# -------------------------------------------------------------------------------

Write-Host "`n===== All Components Installed Successfully =====" -ForegroundColor Green
