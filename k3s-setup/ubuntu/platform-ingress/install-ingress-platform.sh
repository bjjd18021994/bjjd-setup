#!/bin/bash

set -e

echo "Installing cert-manager..."

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml

echo "Waiting for cert-manager to be ready..."

sleep 39

kubectl wait --for=condition=Available deployment cert-manager -n cert-manager --timeout=180s
kubectl wait --for=condition=Available deployment cert-manager-webhook -n cert-manager --timeout=180s
kubectl wait --for=condition=Available deployment cert-manager-cainjector -n cert-manager --timeout=180s

echo "Deploying platform ingress Helm chart..."

helm upgrade --install platform-ingress ./platform-ingress-chart -n platform

echo "Deployment completed successfully!"