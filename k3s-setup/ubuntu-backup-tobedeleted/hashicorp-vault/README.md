# Vault Single-Node Raft Setup (Docker Desktop Kubernetes)

This guide provides a complete, ready-to-use configuration for running **one Vault server** using **Raft storage** with an explicitly bound PersistentVolume. It is fully compatible with **Docker Desktop Kubernetes**, ensures **persistent data**, and prevents **auto-binding issues**.

You will get:

* ✔ **1 Vault server** (stateful)
* ✔ **1 Raft storage PersistentVolume** (statically provisioned)
* ✔ **Guaranteed persistent data** stored on your host
* ✔ **Stable PV → PVC binding** with no random assignment

---
## 📌 Prerequisites

Before starting, ensure the host directory for Vault data exists and is accessible from Docker Desktop Kubernetes.

### **1️⃣ Create the target folder on Windows (if not already created)**

```sh
mkdir C:\k8s-data\vault
```

Or if using vault directory:

```sh
mkdir C:\k8s-data\vault
```

### **2️⃣ Ensure the folder is accessible inside the Kubernetes node**

```sh
wsl -d docker-desktop
ls /mnt/c/k8s-data/vault
```

### **3️⃣ Volume Mount location in pv.yaml file**

HostPath to use in PV:

```
/run/desktop/mnt/host/c/k8s-data/vault
```

Docker Desktop runtime maps it internally to:

```
/tmp/docker-desktop-root/run/desktop/mnt/host/c/k8s-data/vault
```
### **3️⃣ Give access to the k8s folder and its subfolder inside docker-desktop otherwise you may get the error of permission denied on vault.db**

HostPath to use in PV:

```
PS C:\Users\Rajiv Kumar Bansal>  wsl -d docker-desktop
cd /tmp/docker-desktop-root/run/desktop/mnt/host/c
chmod -R 777 k8s-data
```
---
📂 Repository Structure

Your project folder should look like this:
```
hashicorp-vault
├── install-vault-raft.sh
├── install-vault-raft.ps1
└── hashicorp-vault-setup-files/
    ├── hostpath-storageclass.yaml
    ├── hashicorp-vault-raft-pv.yaml
    ├── hashicorp-vault-raft-values.yaml

```
## ✅ Step 1 — HashiCorp Installation Script
- Powershell Script
```bash
cd hashicorp
powershell -ExecutionPolicy Bypass -File install-vault-raft.ps1
```
- Shell Script

```bash
chmod +x install-vault-raft.sh
./install-vault-raft.sh
```
📌 **Short Summary of the Script**

The script install-vault-raft.sh fully automates:

1. Safe Rollback
- It removes any Vault installation artifacts:
- Deletes existing Vault Helm release
- Deletes StorageClass (hostpath)
- Deletes PVC (data-vault-0)
- Deletes PV (hashicorp-vault-raft-pv)

All deletion errors are ignored safely, so the script never fails during rollback.

2. Fresh Install
The script then:
- Applies the StorageClass YAML
- Applies the PersistentVolume YAML
- Adds & updates the HashiCorp Helm repository
- Installs Vault using a Raft-enabled values file
---

## ✅ Step 2 — Check the PVC (expected to be Pending)

```sh
kubectl get pvc -n vault
```

You should see:

```
data-vault-0   Pending
```

This is **normal** — the PVC will bind once Vault initializes.

---

## ✅ Step 3 — Verify Vault Pod

Check the Vault pod:

```sh
kubectl get pods -n vault
```

View logs if needed:

```sh
kubectl logs vault-0 -n vault
```
## ✅ Step 4 — Ingress implementation

Check the Vault pod:

```sh
kubectl get pods -n vault
```

View logs if needed:

```sh
kubectl logs vault-0 -n vault
```

---

## ✅ Final Result

You now have:

* **One Vault Raft node** running in Docker Desktop Kubernetes
* **Explicit PV ↔ PVC binding** (no random dynamic provisioning)
* **Persistent Raft storage on your host** (`~/vault-data-0`)
* **Resilient to Kubernetes or Docker Desktop resets**

Vault is now fully operational with stable, persistent Raft backend storage.

---

## ✅ Step 4 — Initialize Vault, Unseal, and Join Raft Cluster Nodes

### **Initialize vault-0 with one key share and threshold**

The operator init command generates a root key, breaks it into key shares, and sets the share threshold.

* `-key-shares=1` → produce 1 unseal key
* `-key-threshold=1` → require only 1 key to unseal

Run:

```sh
kubectl exec vault-0 -n vault -- vault operator init -key-shares=1 -key-threshold=1 -format=json > cluster-keys.json
```

Or:

```sh
kubectl exec vault-0 -- vault operator init -key-shares=1 -key-threshold=1 -format=json > cluster-keys.json
```

### **Save the output into cluster-keys.json**

```sh
sudo vi cluster-keys.json
```

### **Capture the Vault unseal key**

```sh
VAULT_UNSEAL_KEY=$(jq -r ".unseal_keys_b64[]" cluster-keys.json)
```

### **Unseal vault-0**

```sh
kubectl exec vault-0 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY
```

### **Verify vault-0 is Ready**

```sh
kubectl get pods -n vault
```

---

### **Join vault-1 and vault-2 to the Raft cluster**

```sh
kubectl exec -ti vault-1 -n vault -- vault operator raft join http://vault-0.vault-internal:8200
kubectl exec -ti vault-2 -n vault -- vault operator raft join http://vault-0.vault-internal:8200
```

### **Unseal vault-1 and vault-2**

Unsealing reconstructs the root key needed to decrypt Vault data.

```sh
kubectl exec -ti vault-1 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY
kubectl exec -ti vault-2 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY
```

After this step, all Vault pods should show **1/1 Ready**.

---

### **Access the Vault UI (port-forward)**

```sh
kubectl port-forward service/vault -n vault 8200:8200
```

### **Open the UI**

Visit:

```
http://localhost:8200/ui/vault/auth?with=token
```

Use the **root token** from *cluster-keys.json*.

---

---

## ✅ Appendix A — Architecture Diagram (ASCII)

```
              +-----------------------+
              |     Vault UI / CLI    |
              |   http://localhost    |
              +-----------+-----------+
                          |
                     Port-Forward
                          |
                  +-------v--------+
                  |   vault-0      |
                  |  Raft Leader   |
                  +-------+--------+
                          |
           +--------------+---------------+
           |                              |
  +--------v--------+            +--------v--------+
  |    vault-1      |            |    vault-2      |
  |  Raft Follower  |            |  Raft Follower  |
  +-----------------+            +-----------------+

     All nodes store data in:
     /vault/data → hostPath PV → local disk
```
---


