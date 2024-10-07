#!/usr/bin/env bash
export BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source ${BASE_DIR}/env.sh
# set -e

if ! command_exists k6; then
    print_error "Error: 'k6' is not installed. Please install k6 before proceeding."
    exit 1
fi

print_info "\nFetching Istio ingress gateway LoadBalancer IP and exposed ports..."
export INGRESS_EXTERNAL_IP=$(kubectl get svc "${ISTIO_INGRESS_SVC}" -n "${ISTIO_INGRESS_NS}" -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
export INGRESS_HTTP_PORT=$(kubectl get svc "${ISTIO_INGRESS_SVC}" -n "${ISTIO_INGRESS_NS}" -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
export INGRESS_HTTPS_PORT=$(kubectl get svc "${ISTIO_INGRESS_SVC}" -n "${ISTIO_INGRESS_NS}" -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
print_info "Istio ingress gateway is available at http://${INGRESS_EXTERNAL_IP}:${INGRESS_HTTP_PORT} and https://${INGRESS_EXTERNAL_IP}:${INGRESS_HTTPS_PORT}"

print_info "\nGoing to login k6 to Grafana Cloud, please specify a valid API token:"
read -p "TOKEN: " GRAFANA_CLOUD_TOKEN
if [[ -z "$GRAFANA_CLOUD_TOKEN" ]]; then
  print_warning "Warning: no Grafa Cloud token provided, results will not be stored in the cloud!"

  print_info "\nStart load testing scenario for http scenario:"
  print_command "TEST_SCENARIO=\"http\" k6 run load.js"
  TEST_SCENARIO="http" k6 run load.js

  print_info "\nStart load testing scenario for https-tls scenario:"
  print_command "TEST_SCENARIO=\"https-mtls\" k6 run --insecure-skip-tls-verify load.js"
  TEST_SCENARIO="https-mtls" k6 run --insecure-skip-tls-verify load.js
else
  k6 cloud login --token "$GRAFANA_CLOUD_TOKEN"

  print_info "\nStart load testing scenario for http scenario:"
  print_command "TEST_SCENARIO=\"http\ k6 cloud run --local-execution load.js"
  TEST_SCENARIO="http" k6 cloud run --local-execution load.js

  print_info "\nStart load testing scenario for https-tls scenario:"
  print_command "TEST_SCENARIO=\"https-mtls\" k6 cloud run --insecure-skip-tls-verify --local-execution load.js"
  TEST_SCENARIO="https-mtls" k6 cloud run --insecure-skip-tls-verify --local-execution load.js
fi


