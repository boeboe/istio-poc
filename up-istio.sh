#!/usr/bin/env bash
export BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source ${BASE_DIR}/env.sh
# set -e

print_info "Adding Istio Helm repository..."
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update

print_info "Installing or upgrading Istio components..."
# Install Istio Base
helm upgrade --install istio-base istio/base \
  --namespace istio-system \
  --create-namespace \
  --kube-context "${KUBECONTEXT}" \
  --version "${ISTIO_VERSION}" \
  --wait

# Install Istiod
helm upgrade --install istiod istio/istiod \
  --namespace istio-system \
  --kube-context "${KUBECONTEXT}" \
  --version "${ISTIO_VERSION}" \
  --wait

# Install Istio Ingress Gateway with NodePort configuration
helm upgrade --install istio-ingressgateway istio/gateway \
  --namespace istio-system \
  --kube-context "${KUBECONTEXT}" \
  --version "${ISTIO_VERSION}" \
  --set service.type=NodePort \
  --set service.ports[0].name=status-port \
  --set "service.ports[0].nodePort=${INGRESS_STATUS_PORT}" \
  --set service.ports[0].port=15021 \
  --set service.ports[0].targetPort=15021 \
  --set service.ports[1].name=http2 \
  --set "service.ports[1].nodePort=${INGRESS_HTTP_PORT}" \
  --set service.ports[1].port=80 \
  --set service.ports[1].targetPort=80 \
  --set service.ports[2].name=https \
  --set "service.ports[2].nodePort=${INGRESS_HTTPS_PORT}" \
  --set service.ports[2].port=443 \
  --set service.ports[2].targetPort=443 \
  --wait

print_info "Waiting for Istio pods to be ready..."
until kubectl get pods -n istio-system --context "${KUBECONTEXT}" >/dev/null 2>&1; do
    print_info "Waiting for Istio resources to be created..."
    sleep 5
done
kubectl wait --for=condition=Ready pods --all -n istio-system --timeout=300s --context "${KUBECONTEXT}"