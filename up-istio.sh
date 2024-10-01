#!/usr/bin/env bash
export BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source ${BASE_DIR}/env.sh
# set -e

print_info "Adding Istio Helm repository..."
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update

print_info "Installing or upgrading Istio components..."
helm upgrade --install istio-base istio/base --namespace istio-system --create-namespace --version "${ISTIO_VERSION}" --wait
helm upgrade --install istiod istio/istiod --namespace istio-system --version "${ISTIO_VERSION}" --wait
helm upgrade --install istio-ingressgateway istio/gateway --namespace istio-system --version "${ISTIO_VERSION}" --set service.type=NodePort --wait

print_info "Waiting for Istio pods to be ready..."
until kubectl get pods -n istio-system >/dev/null 2>&1; do
    print_info "Waiting for Istio resources to be created..."
    sleep 5
done
kubectl wait --for=condition=Ready pods --all -n istio-system --timeout=300s