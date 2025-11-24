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
mkdir C:\k8s-data\jenkins
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

---


## ✅ Step 1 — Create the StorageClass

Create the file: **hostpath-storageclass.yaml**

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: hostpath
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
```

Apply it:

```sh
kubectl apply -f hostpath-storageclass.yaml
```

---

## ✅ Step 2 — Create the PersistentVolume (Static HostPath Storage)

Create the file: **vault-raft-pv.yaml**

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: vault-raft-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  storageClassName: hostpath
  hostPath:
    path: /run/desktop/mnt/host/c/k8s-data/vault
  persistentVolumeReclaimPolicy: Retain
```

➡ **Adjust the path** if needed for your OS.
This directory permanently stores all Vault Raft data.

Apply the PV:

```sh
kubectl apply -f vault-raft-pv.yaml
```

---

## ✅ Step 3 — Vault Helm Values (Enable Raft)

Create the file: **helm-vault-raft-values.yml**

```yaml
server:
  resources:
    requests:
      memory: 4Gi
      cpu: 1000m
    limits:
      memory: 8Gi
      cpu: 1000m
  affinity: ""
  readinessProbe:
    enabled: true
    path: "/v1/sys/health?standbyok=true&sealedcode=204&uninitcode=204"
  dataStorage:
    enabled: true
    size: 10Gi
    storageClass: "hostpath"
  ha:
    enabled: true
    replicas: 3
    raft:
      enabled: true
      setNodeId: true
      config: |
        ui = true

        listener "tcp" {
          tls_disable = true
          address = "[::]:8200"
          cluster_address = "[::]:8201"
        }

        storage "raft" {
          path = "/vault/data"
        }
```

---

## ✅ Step 4 — Add Helm Repo & Install Vault

Add the HashiCorp Helm repository:

```sh
helm repo add hashicorp https://helm.releases.hashicorp.com
```

Update all repositories:

```sh
helm repo update
```

Verify Vault chart is available:

```sh
helm search repo hashicorp/vault
```

Edit or confirm your values file:

```sh
sudo vi helm-vault-raft-values.yml
```

Minimal Raft-enabled Helm values example:

```yaml
server:
  affinity: ""
  ha:
    enabled: true
    raft:
      enabled: true
```

Install Vault:

```sh
helm install vault hashicorp/vault --values helm-vault-raft-values.yml -n vault
```

---

## 🧪 Step 5 — Check the PVC (expected to be Pending)

```sh
kubectl get pvc -n vault
```

You should see:

```
data-vault-0   Pending
```

This is **normal** — the PVC will bind once Vault initializes.

---

## 🧪 Step 6 — Verify Vault Pod

Check the Vault pod:

```sh
kubectl get pods -n vault
```

View logs if needed:

```sh
kubectl logs vault-0 -n vault
```

---

# ⭐ Final Result

You now have:

* **One Vault Raft node** running in Docker Desktop Kubernetes
* **Explicit PV ↔ PVC binding** (no random dynamic provisioning)
* **Persistent Raft storage on your host** (`~/vault-data-0`)
* **Resilient to Kubernetes or Docker Desktop resets**

Vault is now fully operational with stable, persistent Raft backend storage.

---

## 🧩 Step 7 — Initialize, Unseal, and Join Raft Cluster Nodes

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
kubectl exec vault-0 -n vault -- vault operator init -key-shares=1 -key-threshold=1 -format=json
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

# 🖼️ Appendix A — Architecture Diagram (ASCII)

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

# ⚙️ Appendix B — Automated Setup Script (Optional)

Create a script named **deploy-vault-raft.sh**:

```bash
#!/bin/bash
set -e

NAMESPACE="vault"

# Step 1: StorageClass
kubectl apply -f hostpath-storageclass.yaml

# Step 2: PV
kubectl apply -f vault-raft-pv.yaml

# Step 3: Helm values already provided

# Step 4: Repo + Install
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
helm install vault hashicorp/vault -n $NAMESPACE --create-namespace \
  --values helm-vault-raft-values.yml

# Wait for pod
kubectl wait --for=condition=Ready pod/vault-0 -n $NAMESPACE --timeout=120s

echo "Vault deployed. You may now initialize and unseal."
```

Make executable:

```sh
chmod +x deploy-vault-raft.sh
```

Run it:

```sh
./deploy-vault-raft.sh
```

---

# 🧹 Appendix C — Cleanup / Teardown

If you want to completely remove the deployment and data:

### **Delete Helm release:**

```sh
helm uninstall vault -n vault
```

### **Delete namespace:**

```sh
kubectl delete namespace vault
```

### **Delete PersistentVolume:**

```sh
kubectl delete pv vault-raft-pv
```

### **Delete data directory (irreversible!)**

Make sure Vault is deleted before removing data.

```sh
sudo rm -rf /run/desktop/mnt/host/c/k8s-data/vault
```

### **Delete the StorageClass:**

```sh
kubectl delete -f hostpath-storageclass.yaml
```

---


