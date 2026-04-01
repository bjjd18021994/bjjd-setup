# 🚀 K3s Secure Microservices Architecture

![Kubernetes](https://img.shields.io/badge/Kubernetes-K3s-blue?logo=kubernetes)
![Spring
Boot](https://img.shields.io/badge/Spring-Cloud_Gateway-green?logo=spring)
![Keycloak](https://img.shields.io/badge/Auth-Keycloak-orange)
![Vault](https://img.shields.io/badge/Secrets-HashiCorp_Vault-black?logo=vault)
![PostgreSQL](https://img.shields.io/badge/Database-PostgreSQL-blue?logo=postgresql)
![License](https://img.shields.io/badge/License-MIT-lightgrey)

------------------------------------------------------------------------

## 📑 Table of Contents

-   [Architecture Overview](#-architecture-overview)
-   [Architecture Diagram](#-architecture-diagram)
-   [Core Components](#-core-components)
-   [Security Architecture](#-security-architecture)
-   [Request Lifecycle](#-request-lifecycle)
-   [Deployment Layer](#-deployment-layer)
-   [Key Design Benefits](#-key-design-benefits)

------------------------------------------------------------------------

## 📖 Architecture Overview

This repository describes a **secure, production-grade microservices
architecture** deployed on a **K3s Kubernetes cluster**.

The architecture includes:

-   Secure HTTPS ingress
-   Centralized authentication (OAuth2 / OIDC)
-   API Gateway routing
-   15 independent microservices
-   Centralized secrets management (Vault)
-   PostgreSQL persistent storage
-   Optional mTLS for service-to-service communication

------------------------------------------------------------------------

## 🖼 Architecture Diagram

![Architecture Diagram](architecture-diagram.png)

------------------------------------------------------------------------

## 🧩 Core Components

### 🌍 Internet / Clients

-   Browsers
-   API Consumers
-   B2B Clients
-   Communicate via **HTTPS (TLS)**

------------------------------------------------------------------------

### 🚦 Traefik Ingress Controller (K3s Service - ClusterIP)

-   Entry point into the Kubernetes cluster
-   Terminates TLS
-   Domain-based routing:
    -   `jenkins.yourdomain.com`
    -   `api.yourdomain.com`
    -   `keycloak.yourdomain.com`
    -   `vault.yourdomain.com`
-   Routes traffic internally to services

------------------------------------------------------------------------

### 🛠 Jenkins Service

-   Provides Jenkins UI
-   Executes CI/CD pipelines
-   Builds and deploys microservices
-   Accessed securely via ingress

------------------------------------------------------------------------

### 🌐 Spring Cloud Gateway (API Gateway)

-   Central API entry point for microservices
-   Handles OAuth2 authentication via Keycloak
-   Supports optional mTLS
-   Routes external requests to internal services
-   Performs token validation and filtering

------------------------------------------------------------------------

### 🔐 Keycloak Service

-   Identity Provider (IdP)
-   Manages users, roles, and permissions
-   Issues JWT tokens
-   Supports OAuth2 / OpenID Connect

------------------------------------------------------------------------

### 📦 Microservices (15 Applications)

-   Independent deployable services
-   Stateless containers
-   Validate JWT tokens from Keycloak
-   Communicate internally via REST APIs
-   Retrieve secrets from Vault

------------------------------------------------------------------------

### 🔑 HashiCorp Vault

-   Centralized secrets management
-   Stores:
    -   Database credentials
    -   API keys
    -   TLS certificates (for mTLS)
-   Provides secure dynamic secrets

------------------------------------------------------------------------

### 🗄 PostgreSQL Database (StatefulSet)

-   Persistent data storage
-   Stores:
    -   Microservices application data
    -   Keycloak authentication data
-   Deployed as StatefulSet for stable identity and storage

------------------------------------------------------------------------

### 💾 Vault Persistent Storage Backend

-   Stores Vault secrets securely
-   Can use:
    -   File backend
    -   Raft storage
    -   External DB backend
-   Ensures durability and high availability

------------------------------------------------------------------------

## 🔒 Security Architecture

Security is enforced at multiple layers:

-   ✅ HTTPS (TLS) at Ingress
-   ✅ OAuth2 / OIDC authentication via Keycloak
-   ✅ JWT validation at Gateway & Services
-   ✅ Optional mTLS between services
-   ✅ Secrets stored securely in Vault
-   ✅ Database isolation inside cluster

------------------------------------------------------------------------

## 🔄 Request Lifecycle

### 1️⃣ User Authentication Flow

1.  User accesses application via browser.
2.  Request reaches **Traefik Ingress**.
3.  Traffic is routed to **Spring Cloud Gateway**.
4.  Gateway redirects user to **Keycloak** for authentication.
5.  Keycloak validates credentials.
6.  JWT token is issued.
7.  User is redirected back with token.

------------------------------------------------------------------------

### 2️⃣ API Request Flow

1.  Client sends API request with JWT token.
2.  Request reaches Traefik Ingress.
3.  Routed to Spring Cloud Gateway.
4.  Gateway validates JWT token.
5.  Request forwarded to appropriate microservice.
6.  Microservice:
    -   Validates token
    -   Retrieves secrets from Vault if needed
    -   Accesses PostgreSQL database
7.  Response returned via Gateway → Ingress → Client.

------------------------------------------------------------------------

## 🏗 Deployment Layer

All components run inside:

### ☸️ K3s Cluster

-   Lightweight Kubernetes distribution
-   Handles:
    -   Container orchestration
    -   Service discovery
    -   Networking
    -   Load balancing
    -   Stateful & stateless workloads

------------------------------------------------------------------------

## ⭐ Key Design Benefits

-   🔐 Zero-trust security model
-   📦 Fully containerized architecture
-   🔄 Independent service scalability
-   🔑 Centralized identity & secrets management
-   🚀 Production-ready cloud-native design
-   🧩 Clean separation of concerns

------------------------------------------------------------------------

## 📌 Summary

This architecture demonstrates a **secure, scalable, and cloud-native
microservices platform** leveraging:

-   Kubernetes (K3s)
-   Spring Cloud Gateway
-   Keycloak
-   HashiCorp Vault
-   PostgreSQL
-   Jenkins CI/CD

It is suitable for enterprise-grade deployments requiring strong
authentication, secrets management, and modular scalability.

------------------------------------------------------------------------
