# 🚀 BJJD - Kubernetes Platform Setup -- Automated Installation Script

This repository contains an automated setup script that installs the
complete platform stack on a Kubernetes cluster using **Helm** and
standard shell scripting.

The script deploys the following components:

-   **Jenkins** (CI/CD server -- Helm chart)
-   **HashiCorp Vault (Raft mode)** (Secure secrets engine)
-   **Postgres** (Database backend)
-   **Keycloak** (Identity provider -- Helm chart)

It ensures a **clean, repeatable, idempotent deployment** by checking
existing releases and reinstalling components when needed.

| Component             | Install Method        | Description                                                       |
| --------------------- | --------------------- | ----------------------------------------------------------------- |
| **Jenkins**           | Helm Chart            | Deploys Jenkins master with persistent storage                    |
| **Vault (Raft Mode)** | External Shell Script | Deploys HashiCorp Vault backed by integrated Raft storage         |
| **Postgres**          | External Shell Script | Installs PostgreSQL and prepares storage credentials for Keycloak |
| **Keycloak**          | Helm Chart            | Identity & Access Management system connected to Postgres         |



---
## 📌 Prerequisites

### **1️⃣ Create the target folder on Windows (if not already created)**

```sh
mkdir C:\k8s-data\vault
mkdir C:\k8s-data\jenkins
mkdir C:\k8s-data\postgres
```

Or if using vault directory:

```sh
mkdir C:\k8s-data\vault
```

### **2️⃣ Ensure the folder is accessible inside the Kubernetes node**

```sh
wsl -d docker-desktop
ls /mnt/c/k8s-data/vault
ls /mnt/c/k8s-data/jenkins
ls /mnt/c/k8s-data/postgres
```

### **3️⃣ Volume Mount location in pv.yaml file**

HostPath to use in PV:

```
Vault - /run/desktop/mnt/host/c/k8s-data/vault
Jenkins - /run/desktop/mnt/host/c/k8s-data/jenkins
Postgres - /run/desktop/mnt/host/c/k8s-data/postgres

```

Docker Desktop runtime maps it internally to:

```
Vault - /tmp/docker-desktop-root/run/desktop/mnt/host/c/k8s-data/vault
Jenkins - /tmp/docker-desktop-root/run/desktop/mnt/host/c/k8s-data/jenkins
Postgres - /tmp/docker-desktop-root/run/desktop/mnt/host/c/k8s-data/postgres
```
### **3️⃣ Give access to the k8s folder and its subfolder inside docker-desktop otherwise you may get the error of permission denied on vault.db**

HostPath to use in PV:

```
PS C:\Users\Rajiv Kumar Bansal>  wsl -d docker-desktop
cd /tmp/docker-desktop-root/run/desktop/mnt/host/c
chmod -R 777 k8s-data
```
---
## 📁 Directory Structure

    .
    ├── install-all.sh
    ├── jenkins/
    │   ├── jenkins-chart/
    │   └── (Jenkins deployment files)
    ├── hashicorp-vault/
    │   └── install-vault-raft.sh
    ├── postgres/
    │   └── install_postgres.sh
    └── keycloak/
        ├── keycloak-chart/
        └── (Keycloak values/config)
---
## 📜 Script Summary --- `install-all.sh`

- Powershell Script
```bash
cd kubernetes
powershell -ExecutionPolicy Bypass -File install-all.ps1
```
- Shell Script

```bash
cd kubernetes
chmod +x install-all.sh
./install-all.sh
```
The primary script automates deployment of all components in the correct
order:

### **1. Jenkins**

-   Checks if a Helm release named `jenkins` exists.
-   Uninstalls it if found.
-   Installs Jenkins Helm chart from the `jenkins-chart` directory.

### **2. Vault (Raft Mode)**

-   Runs the `install-vault-raft.sh` script located in the
    `hashicorp-vault` folder.
-   Sets up Vault with Raft storage and required Kubernetes resources.

### **3. Postgres**

-   Runs `install_postgres.sh` from the `postgres` folder.
-   Installs PostgreSQL (typically StatefulSet + PVC).

### **4. Keycloak**

-   Checks if a Helm release named `keycloak` exists.
-   Uninstalls it if necessary.
-   Installs Keycloak using the `keycloak-chart` directory.

------------------------------------------------------------------------
# 🔍 Final Necessary Steps

```
kubectl get pods
kubectl logs <pod_name>
```
-   Forward the ports of pods
-   Jenkins - Follow the document and see the steps(after installation) for password retrieval - bjjd-setup/kubernetes/jenkins/README.md 
-   Hashicorp Vault - Follow the document and see the steps(after installation) for password retrieval - bjjd-setup/kubernetes/hashicorp-vault/README.md
-   Keycloak - Follow the document and see the steps(after installation) for credentials refer values.yaml file of keycloak chart - bjjd-setup/kubernetes/keycloak/keycloak-chart
-   Postgres - Follow the document and see the steps(after installation) to connect to the DB - bjjd-setup/kubernetes/postgres/README.md
---