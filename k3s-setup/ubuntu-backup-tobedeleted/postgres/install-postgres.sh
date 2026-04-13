#!/usr/bin/env bash
set -euo pipefail

# Colors
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
GREEN="\033[1;32m"
NC="\033[0m"

echo -e "${YELLOW}Checking for existing Helm release 'bjjd-postgres'...${NC}"

# If helm release exists, uninstall it
if helm list -n default | grep -q "bjjd-postgres"; then
    echo -e "${YELLOW}Found release 'bjjd-postgres'. Uninstalling...${NC}"
    helm uninstall bjjd-postgres --namespace default || true
else
    echo -e "${YELLOW}Release 'bjjd-postgres' does not exist. Skipping.${NC}"
fi

echo -e "${YELLOW}Removing existing postgres-init-databases job (if present)...${NC}"
kubectl delete job postgres-init-databases --ignore-not-found >/dev/null 2>&1 || true

echo -e "${YELLOW}Deleting PVC 'pg-pvc' if it exists...${NC}"
kubectl delete pvc pg-pvc --namespace default --ignore-not-found >/dev/null 2>&1 || true

echo -e "${YELLOW}Deleting PV 'pg-pv' if it exists...${NC}"
kubectl delete pv pg-pv --ignore-not-found >/dev/null 2>&1 || true

echo -e "${YELLOW}Deleting secret 'postgres-db-secrets' if it exists...${NC}"
kubectl delete secret postgres-db-secrets --ignore-not-found >/dev/null 2>&1 || true

echo -e "${YELLOW}Deleting ConfigMap 'postgres-config' if it exists...${NC}"
kubectl delete configmap postgres-config --namespace default --ignore-not-found >/dev/null 2>&1 || true

echo -e "${CYAN}Applying PV, PVC, ConfigMap, and Secrets...${NC}"
kubectl apply -f "postgres-setup-files/postgres-pv.yaml"
kubectl apply -f "postgres-setup-files/postgres-pvc.yaml"
kubectl apply -f "postgres-setup-files/postgres-secret.yaml"
kubectl apply -f "postgres-setup-files/postgres-config.yaml"

echo -e "${CYAN}Adding Bitnami repo (ignore if exists)...${NC}"
helm repo add bitnami https://charts.bitnami.com/bitnami >/dev/null 2>&1 || true
helm repo update

echo -e "${CYAN}Installing / Upgrading Postgres using Helm...${NC}"
helm upgrade --install bjjd-postgres bitnami/postgresql \
  --namespace default \
  --values "postgres-setup-files/values.yaml"

# Alternative (manual PVC binding)
# helm upgrade --install bjjd-postgres bitnami/postgresql \
#   --set primary.persistence.existingClaim=pg-pvc \
#   --set primary.persistence.enabled=true \
#   --set volumePermissions.enabled=true \
#   --set auth.postgresPassword=mysecretpassword \
#   --set primary.resources.requests.cpu="100m"

echo -e "${CYAN}Applying DB initialization job...${NC}"
kubectl apply -f "postgres-setup-files/db-init-job.yaml"

echo -e "${GREEN}Postgres setup completed successfully!${NC}"
