#!/usr/bin/env bash
export BASE_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
source ${BASE_DIR}/env.sh

# Define the manifests directory
MANIFEST_DIR="${BASE_DIR}/plain-http"

# Function to deploy Nginx with Istio Gateway
function deploy_nginx_with_istio {
  print_info "Creating namespace..."
  kubectl apply -f "${MANIFEST_DIR}/00-namespace.yaml" --context "${KUBECONTEXT}"

  print_info "Deploying Nginx service..."
  kubectl apply -f "${MANIFEST_DIR}/01-deployment.yaml" --context "${KUBECONTEXT}"
  kubectl apply -f "${MANIFEST_DIR}/02-service.yaml" --context "${KUBECONTEXT}"

  print_info "Deploying Istio Gateway..."
  kubectl apply -f "${MANIFEST_DIR}/03-gateway.yaml" --context "${KUBECONTEXT}"

  print_info "Deploying Istio VirtualService..."
  kubectl apply -f "${MANIFEST_DIR}/04-virtualservice.yaml" --context "${KUBECONTEXT}"

  print_info "Nginx has been deployed and exposed through the Istio ingress gateway (HTTP only)."
}

# Function to undeploy Nginx with Istio Gateway
function undeploy_nginx_with_istio {
  print_info "Deleting Istio VirtualService..."
  kubectl delete -f "${MANIFEST_DIR}/04-virtualservice.yaml" --ignore-not-found --context "${KUBECONTEXT}"

  print_info "Deleting Istio Gateway..."
  kubectl delete -f "${MANIFEST_DIR}/03-gateway.yaml" --ignore-not-found --context "${KUBECONTEXT}"

  print_info "Deleting Nginx service..."
  kubectl delete -f "${MANIFEST_DIR}/02-service.yaml" --ignore-not-found --context "${KUBECONTEXT}"

  print_info "Deleting Nginx deployment..."
  kubectl delete -f "${MANIFEST_DIR}/01-deployment.yaml" --ignore-not-found --context "${KUBECONTEXT}"

  print_info "Deleting namespace..."
  kubectl delete -f "${MANIFEST_DIR}/00-namespace.yaml" --ignore-not-found --context "${KUBECONTEXT}"

  print_info "Nginx and Istio resources have been undeployed."
}

# Check input parameter to determine deploy or undeploy
if [[ "$1" == "deploy" ]]; then
  deploy_nginx_with_istio
elif [[ "$1" == "undeploy" ]]; then
  undeploy_nginx_with_istio
else
  print_error "Invalid argument. Use 'deploy' or 'undeploy'."
  exit 1
fi