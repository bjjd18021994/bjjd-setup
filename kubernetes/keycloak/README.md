# 🚀 Keycloak Helm Chart (StatefulSet + External PostgreSQL)

This Helm chart deploys **Keycloak** as a **StatefulSet** using an **external PostgreSQL database**.
It includes persistence, secrets, service, and optional ingress support.

This chart does **not deploy PostgreSQL** — it connects to an already running Postgres instance.

---

## 📁 Directory Structure

```
keycloak/
  Chart.yaml
  values.yaml
  templates/
    statefulset.yaml
    service.yaml
    secrets.yaml
    ingress.yaml
```

---

# 📦 Features

- Deploys **Keycloak 25+** using Kubernetes StatefulSet
- Uses **external PostgreSQL** (Bitnami or standalone)
- Automatic admin + DB credential management via Secrets
- Persistent storage using PVC
- Optional Ingress
- Customizable CPU/MEM resources
- Helm-managed upgrades

---

# ⚙️ Configuration (values.yaml)

Key fields inside `values.yaml`:

* **image:** Keycloak image source (quay.io recommended)
* **service.port:** Port exposed by Keycloak (default 8080)
* **postgres:** External database connection details
* **admin:** Keycloak admin username/password
* **persistence:** PVC settings (`storageClass`, size, mode)
* **resources:** CPU & memory requests/limits

---

# 🔐 Secrets

The chart automatically creates two secrets:

### 1️⃣ `keycloak-db-secret`

Contains:

* PostgreSQL username
* PostgreSQL password

### 2️⃣ `keycloak-admin-secret`

Contains:

* Keycloak admin username
* Keycloak admin password

Both secrets are generated from values provided in `values.yaml`.

---

# 🏗️ Deployment Components

### 🧱 StatefulSet

Located at:
`templates/statefulset.yaml`

Includes:

* Keycloak container
* JDBC connection settings
* Admin setup
* Readiness/liveness probes
* PersistentVolumeClaim template

### 🌐 Service

Located at:
`templates/service.yaml`

Creates:

```
ClusterIP service
Port: 8080
```

### 🔑 Secrets

Located at:
`templates/secrets.yaml`

Encodes DB + admin credentials.

### 🌍 Ingress (optional)

Located at:
`templates/ingress.yaml`

Disabled by default.

---

# 🗄️ Persistence

The chart creates a PVC automatically:

```
- Name: keycloak-data
- StorageClass: hostpath (customizable)
- Size: 5Gi (customizable)
```

Used to persist:

* Keycloak data
* Realm exports (if enabled)
* Themes (if used)

---

# 📥 Prerequisites

Before installation:

### ✔ Kubernetes Cluster

Docker Desktop, Minikube, K3s, AKS, EKS, GKE — all supported.

### ✔ External PostgreSQL Already Running

The chart expects an existing Postgres service, e.g.:

```
bjjd-postgres-postgresql.default.svc.cluster.local
```

### ✔ Database + User Created

You must create:

* A database (e.g., `keycloak`)
* A user (e.g., `kcuser`)
* With full privileges on that database

If you want, I can provide an init Job for this as well.

---

# 🚀 Install Keycloak

Run:

```sh
helm install keycloak ./keycloak
```

or upgrade:

```sh
helm upgrade --install keycloak ./keycloak
```

---

# 🔍 Check Deployment

```
kubectl get pods
kubectl logs keycloak-0
kubectl get svc keycloak
```

---

# 🧪 Test Keycloak

If using port-forward:

```sh
kubectl port-forward svc/keycloak 8080:8080
```

Access:

```
http://localhost:8080
```

Login using the admin credentials from your values file.

---

# 🛠 Customization Options

We can easily extend this chart to include:

- TLS + cert-manager
- Custom themes via ConfigMap or PV
- ExternalSecret integration
- Ingress annotations (NGINX, HAProxy)
- Autoscaling (HPA)
- Monitoring & metrics dashboards
- Realm import on startup

---

# 📌 Notes

* Use `replicaCount: 1` unless running Keycloak in HA mode with a shared database and sticky sessions.
* You **must** ensure PostgreSQL has:

    * Correct DB name
    * Correct username/password
    * Full permissions
* For production:

    * Enable Ingress + TLS
    * Use secure passwords
    * Use a storage class with reliable disk

---

# ✅ Summary

This Helm chart gives you:

- A complete StatefulSet-based Keycloak setup
- External PostgreSQL support
- Persistent & secure deployment
- Clean separation of configs and templates
- Easy upgrades & maintenance

---
