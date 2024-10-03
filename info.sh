#!/usr/bin/env bash
export BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source ${BASE_DIR}/env.sh
# set -e

print_info "Kubectl context information:"
kubectl cluster-info

print_info "Kubernetes pods and services:"
kubectl get po,svc --all-namespaces -o wide

print_info "\nFetching Istio ingress gateway LoadBalancer IP and exposed ports..."
INGRESS_EXTERNAL_IP=$(kubectl get svc "${ISTIO_INGRESS_SVC}" -n "${ISTIO_INGRESS_NS}" -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
INGRESS_HTTP_PORT=$(kubectl get svc "${ISTIO_INGRESS_SVC}" -n "${ISTIO_INGRESS_NS}" -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
INGRESS_HTTPS_PORT=$(kubectl get svc "${ISTIO_INGRESS_SVC}" -n "${ISTIO_INGRESS_NS}" -o jsonpath='{.spec.ports[?(@.name=="https")].port}')
print_info "Istio ingress gateway is available at http://${INGRESS_EXTERNAL_IP}:${INGRESS_HTTP_PORT} and https://${INGRESS_EXTERNAL_IP}:${INGRESS_HTTPS_PORT}"

print_info "\nTest traffic commands:"
print_command "curl http://perf-http.${DNS_SUFFIX} --resolve perf-http.${DNS_SUFFIX}:${INGRESS_HTTP_PORT}:${INGRESS_EXTERNAL_IP} -H 'Test: HALLOOOOOO'"
print_command "curl https://perf-https-mtls.${DNS_SUFFIX} --cacert output/mtls-https/wildcard-cert.pem  --resolve perf-https-mtls.${DNS_SUFFIX}:${INGRESS_HTTPS_PORT}:${INGRESS_EXTERNAL_IP} -H 'Test: HALLOOOOOO'"
