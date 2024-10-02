#!/usr/bin/env bash
export BASE_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
source ${BASE_DIR}/env.sh

# Define the manifests directory
MANIFEST_DIR="${BASE_DIR}/stls-https"
CERT_DIR="${BASE_DIR}/output/stls-https"

# Function to generate wildcard certificate and create Kubernetes secret
function create_tls_secret {
  print_info "Generating wildcard certificate and private key..."
  mkdir -p "${CERT_DIR}"

  # Generate a private key
  openssl genrsa -out "${CERT_DIR}/wildcard-key.pem" 2048

  # Create a certificate signing request (CSR)
  openssl req -new -key "${CERT_DIR}/wildcard-key.pem" -out "${CERT_DIR}/wildcard.csr" -subj "/CN=*.example.com/O=My Organization"

  # Self-sign the certificate
  openssl x509 -req -in "${CERT_DIR}/wildcard.csr" -signkey "${CERT_DIR}/wildcard-key.pem" -out "${CERT_DIR}/wildcard-cert.pem" -days 365

  # Create the Kubernetes secret for the certificate and key
  print_info "Creating Kubernetes secret for the wildcard certificate..."
  kubectl create -n istio-system secret tls nginx-gateway-certs \
    --cert="${CERT_DIR}/wildcard-cert.pem" \
    --key="${CERT_DIR}/wildcard-key.pem" --dry-run=client -o yaml | kubectl apply --context "${KUBECONTEXT}" -f -

  print_info "TLS secret has been created."
}

# Function to deploy Nginx with Istio Gateway
function deploy_nginx_with_istio {
  create_tls_secret

  print_info "Creating namespace..."
  kubectl apply -f "${MANIFEST_DIR}/00-namespace.yaml" --context "${KUBECONTEXT}"

  print_info "Deploying Nginx service..."
  kubectl apply -f "${MANIFEST_DIR}/01-deployment.yaml" --context "${KUBECONTEXT}"
  kubectl apply -f "${MANIFEST_DIR}/02-service.yaml" --context "${KUBECONTEXT}"

  print_info "Deploying Istio Gateway..."
  kubectl apply -f "${MANIFEST_DIR}/03-gateway.yaml" --context "${KUBECONTEXT}"

  print_info "Deploying Istio VirtualService..."
  kubectl apply -f "${MANIFEST_DIR}/04-virtualservice.yaml" --context "${KUBECONTEXT}"

  print_info "Deploying Istio PeerAuthentication..."
  kubectl apply -f "${MANIFEST_DIR}/05-peerauthentication.yaml" --context "${KUBECONTEXT}"

  print_info "Deploying Istio DestinationRule..."
  kubectl apply -f "${MANIFEST_DIR}/06-destinationrule.yaml" --context "${KUBECONTEXT}"

  print_info "Nginx has been deployed and exposed through the Istio ingress gateway (Single TLS HTTPS)."
}

# Function to undeploy Nginx with Istio Gateway
function undeploy_nginx_with_istio {
  print_info "Deleting Istio DestinationRule..."
  kubectl delete -f "${MANIFEST_DIR}/06-destinationrule.yaml" --ignore-not-found --context "${KUBECONTEXT}"

  print_info "Deleting Istio PeerAuthentication..."
  kubectl delete -f "${MANIFEST_DIR}/05-peerauthentication.yaml" --ignore-not-found --context "${KUBECONTEXT}"

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
