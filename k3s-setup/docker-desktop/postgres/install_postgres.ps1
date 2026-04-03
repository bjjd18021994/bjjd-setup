# Requires PowerShell 5+ and kubectl + helm installed

$ErrorActionPreference = "Stop"
if (helm list -n default | Select-String -Pattern "bjjd-postgres") {
    Write-Host "Found release 'bjjd-postgres'. Uninstalling..." -ForegroundColor Yellow
    helm uninstall bjjd-postgres --namespace default
} else {
    Write-Host "Release 'bjjd-postgres' does not exist. Skipping." -ForegroundColor DarkYellow
}

Write-Host "Removing existing  postgres-init-databases job (if present)..." -ForegroundColor Yellow
kubectl delete job postgres-init-databases --ignore-not-found | Out-Null

Write-Host "Deleting PVC 'pg-pvc' if it exists..." -ForegroundColor Yellow
kubectl delete pvc pg-pvc --namespace default --ignore-not-found | Out-Null

Write-Host "Deleting PV 'pg-pv' if it exists..." -ForegroundColor Yellow
kubectl delete pv pg-pv --ignore-not-found | Out-Null

Write-Host "Deleting secret 'postgres-db-secrets' if it exists..." -ForegroundColor Yellow
kubectl delete secret postgres-db-secrets --ignore-not-found | Out-Null

Write-Host "Deleting ConfigMap 'postgres-config' if it exists..." -ForegroundColor Yellow
kubectl delete configmap postgres-config --namespace default --ignore-not-found | Out-Null


Write-Host "Applying PV, PVC,Config and Secrets..." -ForegroundColor Cyan
kubectl apply -f "postgres-setup-files/postgres-pv.yaml"
kubectl apply -f "postgres-setup-files/postgres-pvc.yaml"
kubectl apply -f "postgres-setup-files/postgres-secret.yaml"
kubectl apply -f "postgres-setup-files/postgres-config.yaml"

Write-Host "Adding Bitnami repo (ignore if exists)..." -ForegroundColor Cyan
helm repo add bitnami https://charts.bitnami.com/bitnami 2>$null
helm repo update

Write-Host "Installing / Upgrading Postgres using Helm..." -ForegroundColor Cyan
helm upgrade --install bjjd-postgres bitnami/postgresql --values "postgres-setup-files/values.yaml"
#helm upgrade --install bjjd-postgres bitnami/postgresql --set primary.persistence.existingClaim=pg-pvc --set primary.persistence.enabled=true --set volumePermissions.enabled=true --set auth.postgresPassword=mysecretpassword --set primary.resources.requests.cpu="100m"

Write-Host "Applying DB initialization job..." -ForegroundColor Cyan
kubectl apply -f "postgres-setup-files/db-init-job.yaml"

Write-Host "Postgres setup completed successfully!" -ForegroundColor Green
