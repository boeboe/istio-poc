#!/usr/bin/env bash
export BASE_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
source ${BASE_DIR}/env.sh

# Define the manifests directory
MANIFEST_DIR="${BASE_DIR}/https-mtls"
CERT_DIR="${BASE_DIR}/output/https-mtls"

# Function to generate wildcard certificate and create Kubernetes secret
function create_tls_secret {
  # Check if the certificate files already exist
  if [[ -f "${CERT_DIR}/wildcard-key.pem" && -f "${CERT_DIR}/wildcard-cert.pem" && -f "${CERT_DIR}/wildcard.csr" ]]; then
    print_info "Certificate and key already exist, skipping generation."
  else
    print_info "Generating wildcard certificate and private key..."

    # Generate a private key
    openssl genrsa -out "${CERT_DIR}/wildcard-key.pem" 2048

    # Create a certificate signing request (CSR)
    openssl req -new -key "${CERT_DIR}/wildcard-key.pem" -out "${CERT_DIR}/wildcard.csr" -subj "/CN=*.${DNS_SUFFIX}/O=Liantis"

    # Self-sign the certificate
    openssl x509 -req -in "${CERT_DIR}/wildcard.csr" -signkey "${CERT_DIR}/wildcard-key.pem" -out "${CERT_DIR}/wildcard-cert.pem" -days 365
  fi

  # Create the Kubernetes secret for the certificate and key if it doesn't already exist
  print_info "Checking if Kubernetes secret for the wildcard certificate already exists..."

  if ! kubectl get secret perf-https-mtls-certs -n "${ISTIO_INGRESS_NS}" &>/dev/null; then
    print_info "Creating Kubernetes secret for the wildcard certificate..."
    kubectl create -n "${ISTIO_INGRESS_NS}" secret tls perf-https-mtls-certs \
      --cert="${CERT_DIR}/wildcard-cert.pem" \
      --key="${CERT_DIR}/wildcard-key.pem" --dry-run=client -o yaml | kubectl apply -f -
    print_info "TLS secret has been created."
  else
    print_info "Kubernetes secret 'perf-https-mtls-certs' already exists. Skipping creation."
  fi
}


# Function to remove the Kubernetes secret for the wildcard certificate
function remove_tls_secret {
  print_info "Deleting Kubernetes secret for the wildcard certificate..."
  kubectl delete secret perf-https-mtls-certs -n "${ISTIO_INGRESS_NS}" --ignore-not-found
  print_info "TLS secret has been deleted."
}


# Function to deploy Nginx with Istio Gateway
function deploy_nginx_with_istio {
  create_tls_secret

  print_info "Creating namespace..."
  kubectl apply -f "${MANIFEST_DIR}/00-namespace.yaml"

  print_info "Deploying Nginx service..."
  kubectl apply -f "${MANIFEST_DIR}/01-deployment.yaml"
  kubectl apply -f "${MANIFEST_DIR}/02-service.yaml"

  print_info "Deploying Istio gateway, virtualservice and peerauthentication..."
  envsubst < ${MANIFEST_DIR}/03-gateway.yaml | kubectl apply -f -
  envsubst < ${MANIFEST_DIR}/04-virtualservice.yaml | kubectl apply -f -
  kubectl apply -f "${MANIFEST_DIR}/05-peerauthentication.yaml"

  print_info "Nginx has been deployed and exposed through the Istio ingress gateway (Mutual TLS HTTPS)."
}

# Function to undeploy Nginx with Istio Gateway
function undeploy_nginx_with_istio {
  print_info "Deleting Istio peerauthentication..."
  kubectl delete -f "${MANIFEST_DIR}/05-peerauthentication.yaml" --ignore-not-found

  print_info "Deleting Istio virtualservice..."
  kubectl delete -f "${MANIFEST_DIR}/04-virtualservice.yaml" --ignore-not-found

  print_info "Deleting Istio gateway..."
  kubectl delete -f "${MANIFEST_DIR}/03-gateway.yaml" --ignore-not-found

  print_info "Deleting Nginx service..."
  kubectl delete -f "${MANIFEST_DIR}/02-service.yaml" --ignore-not-found

  print_info "Deleting Nginx deployment..."
  kubectl delete -f "${MANIFEST_DIR}/01-deployment.yaml" --ignore-not-found

  print_info "Deleting namespace..."
  kubectl delete -f "${MANIFEST_DIR}/00-namespace.yaml" --ignore-not-found

  # Remove the TLS secret
  remove_tls_secret

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
