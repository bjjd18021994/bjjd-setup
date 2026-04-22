# README — PostgreSQL on Kubernetes (Windows host path persistence)

This README explains how to install PostgreSQL on a Kubernetes cluster running on **Docker Desktop** or **WSL2**, persist data on a Windows host folder, and provision databases for a microservices architecture.

> **Important:** Kubernetes cannot mount Windows paths directly. This guide relies on Docker Desktop / WSL2 mounting so that a Windows path like `C:\k8s-data\postgres` appears inside the Kubernetes node as `/run/desktop/mnt/host/c/k8s-data/postgres` (or `/mnt/c/k8s-data/postgres` inside WSL). Follow the HostPath mapping steps closely.

---

## Table of contents

1. Prerequisites
2. Host folder setup (Windows + WSL2/Docker Desktop)
3. Postgres Installation and DB Init Script
4. Create microservice databases (two approaches)
   - Option 1: Manual (exec + psql)
   - Option 2 (Recommended): Kubernetes Job that reads secrets
5. Validation
6. Example microservice Helm/env usage
7. Troubleshooting & tips

---

## 1) Prerequisites

- Docker Desktop with Kubernetes enabled **or** a Kubernetes cluster running inside WSL2.
- `kubectl` configured to talk to the cluster.
- `helm` installed.
- A Windows folder for PostgreSQL data, e.g., `C:\k8s-data\postgres`.
- Ability to run `wsl -d docker-desktop` commands (Docker Desktop WSL integration).

---

## 2) Host folder setup (Windows + WSL2/Docker Desktop)

### **1️⃣ Create the target folder in Ubuntu (if not already created)**

```sh
mkdir -p /home/bjjd/k8s-data/data/postgres
```

### **2️⃣ Volume Mount location in pv.yaml file**

HostPath to use in PV:

```
/home/bjjd/k8s-data/data/postgres
```

### **3️⃣ Give access to the k8s folder and its subfolder

HostPath to use in PV:

```
chmod -R 777 /home/bjjd/k8s-data/data/postgres
```

(Adjust permissions to your security requirements — `777` is permissive but effective for local development.)

---

## 3) Postgres Installation and DB Init Script
- Shell Script

```bash
chmod +x install_postgres.sh
./install_postgres.sh
```
📌 **Short Summary of the Script**
- The script completely resets and reinstall PostgreSQL on Kubernetes. 
- It Uninstalls any existing Helm release (bjjd-postgres)
- Deletes old Job, PV, PVC, Secret, and ConfigMap
- Re-applies fresh PV, PVC, Secret, and ConfigMap
- Adds/updates the Bitnami Helm repo
- Installs/Upgrades PostgreSQL using your values.yaml
- Runs the DB initialization job to create databases and users

> **Important:** The shell or powershell script performs the following function: - 
> - helm uninstall bjjd-postgres --namespace default
> - kubectl delete job postgres-init-databases --ignore-not-found 
> - kubectl delete pvc pg-pvc --namespace default --ignore-not-found 
> - kubectl delete pv pg-pv --ignore-not-found 
> - kubectl delete secret postgres-db-secrets --ignore-not-found 
> - kubectl delete configmap postgres-config --namespace default --ignore-not-found 
> - kubectl apply -f postgres-setup-files/postgres-pv.yaml 
> - kubectl apply -f postgres-setup-files/postgres-pvc.yaml 
> - kubectl apply -f postgres-setup-files/postgres-secret.yaml 
> - kubectl apply -f postgres-setup-files/postgres-config.yaml 
> - helm repo add bitnami https://charts.bitnami.com/bitnami
> - helm repo update 
> - helm upgrade --install bjjd-postgres bitnami/postgresql --namespace default --values postgres-setup-files/values.yaml 
> - kubectl apply -f postgres-setup-files/db-init-job.yaml

---
## 4) Create the databases for the microservices

### 🧩 Recommended Standard Microservice DB Pattern (Best Practice)

| Microservice | Database     | User       | Password      |
|--------------|--------------|------------|---------------|
| keycloak     | keycloak_db  | keycloak   | keycloak@9999 |
| Users        | users_db     | users      | users@9999    |
| accounts     | accounts_db  | accounts   | accounts@9999 |
| darshan      | darshan_db   | darshan    | darshan@9999  |
| persons      | persons_db   | persons    | persons@9999  |
| projects     | projects_db  | projects   | projects@9999 |

This mapping ensures **clear separation**, **security**, and consistent **microservice‑owned database patterns**.


Two approaches are provided: manual (exec) and automated (Job + Secrets).

### Option 1 — Manual (Not recommended for repeatable deployments)

1. Exec into the postgres pod:

```bash
kubectl exec -it my-postgres-postgresql-0 -- bash
psql -U postgres
```

2. SQL commands (example):

```sql
CREATE DATABASE accounts_db;
CREATE USER accounts WITH PASSWORD 'accounts@9999';
GRANT ALL PRIVILEGES ON DATABASE accounts_db TO accounts;

CREATE DATABASE keycloak_db;
CREATE USER keycloak WITH PASSWORD 'keycloak@9999';
GRANT ALL PRIVILEGES ON DATABASE keycloak_db TO keycloak;
```

### Option 2 — Recommended: Kubernetes Secret + DB initialization Job

- Followed this approach in our case
---

## 5) Validation

After the Job completes, verify databases and users from the Postgres pod:

```bash
kubectl exec -it my-postgres-postgresql-0 -- psql -U postgres -c "\l"
```

Expected databases:
- keycloak_db
- accounts_db
- darshan_db
- persons_db
- projects_db
- users_db

Expected roles/users:
- accounts
- users
- darshan
- persons
- projects
- keycloak

---

## 6) Microservice Helm Charts - Integration examples

Each microservice should read connection strings and credentials from environment variables or secrets.

### Example 1: Darshan service
```yaml
env:
  - name: SPRING_DATASOURCE_URL
    value: jdbc:postgresql://bjjd-postgres-postgresql.data.svc.cluster.local:5432/darshan_db
  - name: SPRING_DATASOURCE_USERNAME
    value: orders
  - name: SPRING_DATASOURCE_PASSWORD
    valueFrom:
      secretKeyRef:
        name: postgres-db-secrets
        key: DARSHAN_DB_PASSWORD
```

### Example 2: Keycloak
```yaml
extraEnv:
  - name: KC_DB
    value: postgres
  - name: KC_DB_URL
    value: jdbc:postgresql://bjjd-postgres-postgresql.data.svc.cluster.local:5432/keycloak_db
  - name: KC_DB_USERNAME
    value: keycloak
  - name: KC_DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: postgres-db-secrets
        key: KEYCLOAK_DB_PASSWORD
```

### Example 3: Each microservice now connects like this:

**accounts_db**
```
jdbc:postgresql://bjjd-postgres-postgresql.data.svc.cluster.local:5432/accounts_db
username: accounts
password: accounts@9999
```

**persons_db**
```
jdbc:postgresql://bjjd-postgres-postgresql.data.svc.cluster.local:5432/persons_db
username: persons
password: persons@9999
```

**projects_db**
```
jdbc:postgresql://bjjd-postgres-postgresql.data.svc.cluster.local:5432/projects_db
username: projects
password: projects@9999
```

**users_db**
```
jdbc:postgresql://bjjd-postgres-postgresql.data.svc.cluster.local:5432/users_db
username: users
password: users@9999
```

---

## 7) Troubleshooting & tips

- **Permission denied when PostgreSQL writes to host path:** Make sure the Windows folder is accessible inside the `docker-desktop` WSL distro and has appropriate permissions. Use `chmod -R` inside `docker-desktop` as shown earlier.
- **HostPath mismatch:** Confirm the exact hostPath on your environment by inspecting `/tmp/docker-desktop-root/run/desktop/mnt/host/c` inside the `docker-desktop` WSL distribution.
- **Kubernetes cannot mount Windows paths directly:** Always use the internal mapped path (example: `/run/desktop/mnt/host/c/...`).
- **Use Secrets, not plaintext in values files:** For production or shared environments, store passwords in Kubernetes `Secret`s and reference them rather than embedding passwords in `values.yaml`.
- **Use `volumePermissions` with Bitnami charts:** The `volumePermissions` helper container ensures the mounted path has correct UID/GID required by the Postgres container.
- **Local dev vs production:** HostPath PV is suitable for local development on Docker Desktop / WSL2. For production use a networked/provisioned storage (CSI, cloud volumes, etc.) instead.

---

### 🔧 Common Issues & Solutions

#### 1. **Permission denied when PostgreSQL writes to host path**
This occurs when Docker Desktop’s WSL backend does not have permission to write to the Windows folder being used as PersistentVolume.

**Fix:**
Inside the `docker-desktop` WSL distro, run:
```bash
wsl -d docker-desktop
cd /tmp/docker-desktop-root/run/desktop/mnt/host/c/k8s-data
chmod -R 777 postgres
```
Adjust permissions according to your security needs.

---

#### 2. **Kubernetes cannot mount Windows paths directly**
Kubernetes **does not support mounting Windows paths like `C:older`**.
You must use the mapped internal Linux path created by Docker Desktop:
```
/run/desktop/mnt/host/c/k8s-data/postgres
```
If the chart fails to mount PV, verify the exact internal mapping:
```bash
wsl -d docker-desktop
ls /run/desktop/mnt/host/c/k8s-data/postgres
```

---

#### 3. **pod stuck in Init:0/1 due to volume permissions**
This happens when the Postgres container cannot write to mounted volume.

**Fix:** Enable Bitnami permission helper:
```yaml
volumePermissions:
  enabled: true
```

---

#### 4. **HostPath mismatch across systems**
On some machines the internal Docker Desktop mapping may be located at:
```
/tmp/docker-desktop-root/run/desktop/mnt/host/c/k8s-data/postgres
```
Check and adjust PV accordingly.

---

#### 5. **Databases not created when Job runs too early**
Kubernetes Job may start before PostgreSQL is ready.

**Fix:** Use `pg_isready` loop (already included in Job):
```bash
until pg_isready -h $HOST -U postgres; do sleep 2; done
```

---

#### 6. **Wrong passwords in microservices**
If a microservice fails to connect, verify:
- DB username matches the DB user created by Job
- Password matches Kubernetes Secret
- Service URL matches actual cluster DNS:
```
bjjd-postgres-postgresql.data.svc.cluster.local:5432
```

---

#### 7. **PV does not bind to PVC**
Check:
```bash
kubectl get pv
kubectl get pvc
```
Ensure:
- same `storageClassName`
- PVC has `volumeName: pg-pv`
---

*End of README*

