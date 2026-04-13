# Platform Ingress Helm Chart

This Helm chart deploys a **production-ready Kubernetes Ingress setup** using **Traefik** and **cert-manager** for securely exposing:

* Vault
* Jenkins
* Keycloak

It includes:

* TLS via cert-manager (Let's Encrypt)
* Traefik middlewares (auth, security headers, rate limiting, HTTPS redirect)
* Host-based routing using subdomains

---

## 📦 Chart Structure

```
platform-ingress/
│── Chart.yaml
│── values.yaml
│── templates/
│   ├── ingress.yaml
│   ├── clusterissuer.yaml
│   ├── middleware-auth.yaml
│   ├── middleware-security.yaml
│   ├── middleware-ratelimit.yaml
│   ├── middleware-redirect.yaml
```

---

## ⚙️ Prerequisites

Ensure the following are installed in your cluster:

* Kubernetes (v1.19+)
* Helm (v3+)
* Traefik Ingress Controller
* cert-manager

---
## 🚀 Installation (Recommended Approach)

### ✅ Step 1: Bootstrap Script (cert-manager + Helm)

Create a file `install-ingress-platform.sh`:

```bash id="bootstrap-script"
#!/bin/bash

set -e

echo "Installing cert-manager..."

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml

echo "Waiting for cert-manager to be ready..."

kubectl wait --for=condition=Available deployment cert-manager -n cert-manager --timeout=180s
kubectl wait --for=condition=Available deployment cert-manager-webhook -n cert-manager --timeout=180s
kubectl wait --for=condition=Available deployment cert-manager-cainjector -n cert-manager --timeout=180s

echo "Deploying platform ingress Helm chart..."

helm upgrade --install platform-ingress ./platform-ingress-chart -n platform

echo "Deployment completed successfully!"
```

---

### ▶️ Run Script

```bash id="run-script"
chmod +x install-ingress-platform.sh
./setup.sh
```

---

## 🌐 Configuration

Update `values.yaml` as per your environment:

```yaml
domain: bhavyajagjananidarbar.org

tls:
  enabled: true
  secretName: bjjd-tls
  clusterIssuer: letsencrypt-prod
  
certManager:
  enabled: true
  email: your-email@example.com
  clusterIssuer: letsencrypt-prod

services:
  vault:
    name: vault
    host: vault
    port: 8200

  jenkins:
    name: jenkins
    host: jenkins
    port: 9090

  keycloak:
    name: keycloak
    host: keycloak
    port: 8080

middlewares:
  auth:
    enabled: true
    secretName: basic-auth-secret

  rateLimit:
    average: 100
    burst: 50
```

---

## 🔐 TLS Configuration

This chart uses **cert-manager** for TLS certificates.

Make sure a ClusterIssuer exists:

```bash
kubectl get clusterissuer
```

Expected:

```
letsencrypt-prod
```

---

## 🔑 Basic Authentication Setup

Create a basic auth secret:

```bash
htpasswd -nb admin admin@379 | base64
```

Apply secret:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: basic-auth-secret
  namespace: default
type: Opaque
data:
  users: <BASE64_OUTPUT>
```

---

---

## 🌍 Access URLs

After deployment, services will be available at:

* https://vault.<your-domain>
* https://jenkins.<your-domain>
* https://keycloak.<your-domain>

Example:

* https://vault.bhavyajagjananidarbar.org
* https://jenkins.bhavyajagjananidarbar.org
* https://keycloak.bhavyajagjananidarbar.org

---

## 🛡️ Security Features

### 1. HTTPS Enforcement

* Automatically redirects HTTP → HTTPS

### 2. Security Headers

* HSTS
* X-Frame-Options
* X-Content-Type-Options
* XSS Protection

### 3. Rate Limiting

* Configurable request limits to prevent abuse

### 4. Authentication (Optional)

* Basic Auth enabled via middleware

---

## 🧠 Best Practices

### 🔐 Protect Sensitive Services

Recommended:

| Service  | Auth Required |
| -------- | ------------- |
| Vault    | Yes           |
| Jenkins  | Yes           |
| Keycloak | No            |

---

### 🔄 Replace Basic Auth (Recommended)

For production, replace Basic Auth with:

* Keycloak SSO
* OAuth2 Proxy
* Traefik ForwardAuth

---

### 🌍 DNS Configuration

Ensure DNS is configured:

```
*.bhavyajagjananidarbar.org → Ingress LoadBalancer IP
```

---

### 🔒 Wildcard Certificates

For best results:

* Use DNS challenge in cert-manager
* Supports `*.domain.com`

---

## ⚠️ Notes

* Do NOT use both Traefik certresolver and cert-manager together
* This chart is configured to use **cert-manager only**
* Ensure ports match your actual service configurations

---

## 🚀 Future Enhancements

You can extend this setup with:

* Keycloak SSO integration
* Internal/private ingress for Vault
* Per-service middleware customization
* Multi-environment Helm values (dev/staging/prod)

---

## 🤝 Contributing

Feel free to enhance:

* Middleware configurations
* Security policies
* Helm templating flexibility

---

## 📄 License

This project is for internal/platform use. Customize as needed.

---
