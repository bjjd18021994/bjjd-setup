#!/usr/bin/env bash
set -euo pipefail

# Colors
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
GREEN="\033[1;32m"
NC="\033[0m"

echo -e "${YELLOW}Checking for existing Helm release 'bjjd-postgres'...${NC}"

# If helm release exists, uninstall it
if helm list -n platform | grep -q "bjjd-postgres"; then
    echo -e "${YELLOW}Found release 'bjjd-postgres'. Uninstalling...${NC}"
    helm uninstall bjjd-postgres --namespace platform || true
else
    echo -e "${YELLOW}Release 'bjjd-postgres' does not exist. Skipping.${NC}"
fi

echo -e "${YELLOW}Removing existing postgres-init-databases job (if present)...${NC}"
kubectl delete job postgres-init-databases --ignore-not-found >/dev/null 2>&1 || true

echo -e "${YELLOW}Deleting PVC 'pg-pvc' if it exists...${NC}"
kubectl delete pvc pg-pvc --namespace platform --ignore-not-found >/dev/null 2>&1 || true

echo -e "${YELLOW}Deleting PV 'pg-pv' if it exists...${NC}"
kubectl delete pv pg-pv --ignore-not-found >/dev/null 2>&1 || true

echo -e "${YELLOW}Deleting secret 'postgres-db-secrets' if it exists...${NC}"
kubectl delete secret postgres-db-secrets --ignore-not-found >/dev/null 2>&1 || true

echo -e "${YELLOW}Deleting ConfigMap 'postgres-config' if it exists...${NC}"
kubectl delete configmap postgres-config --namespace platform --ignore-not-found >/dev/null 2>&1 || true

echo -e "${GREEN}Postgres setup has been deleted successfully!${NC}"
