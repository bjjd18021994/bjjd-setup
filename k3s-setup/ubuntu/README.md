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

## 🏗️ Namespace Structure

```
platform/
  ├── keycloak
  ├── vault
  ├── ingress
  ├── cert-manager

data/
  ├── postgres

bjjd/
  ├── app services
  ├── deployments
  ├── configmaps
```

### 📁 Kubernetes Storage Path Structure
### **1️⃣️Create the folder as per the below diagram

```bash
/home/bjjd/k8s-data/
  ├── platform/
  │     ├── vault/
  │     ├── keycloak/
  │     ├── ingress/
  │
  ├── data/
  │     ├── postgres/
  │
  ├── bjjd/
        ├── app/
```
- Script to create the folders
```bash
mkdir -p /home/bjjd/k8s-data/{platform/{vault,keycloak,ingress},data/postgres}
```

### **2️⃣ Ensure the folder is accessible inside the Kubernetes node**

```sh
sudo chmod -R 777 /home/bjjd/k8s-data
```

### **3️⃣ Volume Mount location in pv.yaml file**

HostPath to use in PV:

```
Vault - /home/bjjd/k8s-data/platform/vault
Jenkins - /home/bjjd/k8s-data/platform/jenkins
Postgres - /home/bjjd/k8s-data/data/postgres

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
    └── platform-ingress/
        ├── platform-ingress-chart/
        └── install-ingress-platform.sh 
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

### **1. Create the folders to store k8s data**
```bash
/home/bjjd/k8s-data/
  ├── platform/
  │     ├── vault/
  │     ├── keycloak/
  │     ├── ingress/
  │
  ├── data/
  │     ├── postgres/
  │
  ├── bjjd/
        ├── app/
```

### **2. Create the namespaces**
  -   platform - vault, jenkins, vault and cert-manager
  -   data - postgres
  -   bjjd - microservices
### **3. Jenkins**
-   Checks if a Helm release named `jenkins` exists.
-   Uninstalls it if found.
-   Installs Jenkins Helm chart from the `jenkins-chart` directory.

### **4. Vault (Raft Mode)**

-   Runs the `install-vault-raft.sh` script located in the
    `hashicorp-vault` folder.
-   Sets up Vault with Raft storage and required Kubernetes resources.

### **5. Postgres**

-   Runs `install_postgres.sh` from the `postgres` folder.
-   Installs PostgreSQL (typically StatefulSet + PVC).

### **6. Keycloak**

-   Checks if a Helm release named `keycloak` exists.
-   Uninstalls it if necessary.
-   Installs Keycloak using the `keycloak-chart` directory.

### **7. Ingress Platform Setup with TLS**
-   Runs the `install-ingress-platform.sh` script located in the
    `platform-ingress` folder.


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
-   Ingress Platform - - Follow the document and see the steps(after installation) to access the urls of jenkins, vault and keycloak via ingress - bjjd-setup/k3s-setup/ubuntu/platform-ingress/README.md
---

## 🌍 Access URLs
After deployment, services will be available at:

Example:

* https://vault.bhavyajagjananidarbar.org
* https://jenkins.bhavyajagjananidarbar.org
* https://keycloak.bhavyajagjananidarbar.org
