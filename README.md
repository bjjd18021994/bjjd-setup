# BJJD Setup (Docker Desktop Kubernetes)
- Hashicorp Vault (Single-Node Raft Setup)
- Jenkins
- Postgres
- keycloak

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
### **3️⃣ Installation Script

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
---