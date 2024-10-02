#!/usr/bin/env bash
export BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source ${BASE_DIR}/env.sh
# set -e

echo "Checking that the kubeconfig context is set to ${KUBECONTEXT}..."
CURRENT_CONTEXT=$(kubectl config current-context)
if [ "$CURRENT_CONTEXT" != "${KUBECONTEXT}" ]; then
    print_info "Current kubeconfig context (${CURRENT_CONTEXT}) does not match the expected context (${KUBECONTEXT}). Please switch to the correct context."
    exit 1
fi

print_info "Kind cluster information:"
kind get clusters

print_info "Kubectl context information:"
kubectl cluster-info --context "${KUBECONTEXT}"

print_info "Kubernetes pods and services:"
kubectl get po,svc --all-namespaces -o wide --context "${KUBECONTEXT}"

print_info "\nFetching Istio ingress gateway NodePort information..."
INGRESS_PORT=$(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}' --context "${KUBECONTEXT}")
INGRESS_HTTPS_PORT=$(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}' --context "${KUBECONTEXT}")
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' --context "${KUBECONTEXT}")
print_info "Istio ingress gateway is available at http://${NODE_IP}:${INGRESS_PORT} and https://${NODE_IP}:${INGRESS_HTTPS_PORT}"

# Fetch Prometheus NodePort and Node IP
print_info "\nFetching Prometheus NodePort information..."
PROMETHEUS_PORT=$(kubectl get svc prometheus-server -n monitoring -o jsonpath='{.spec.ports[?(@.targetPort==9090)].nodePort}' --context "${KUBECONTEXT}")
PROMETHEUS_URL="http://${NODE_IP}:${PROMETHEUS_PORT}"
print_info "Prometheus is available at ${PROMETHEUS_URL}"

print_info "\nFetching Grafana NodePort information..."
GRAFANA_PORT=$(kubectl get svc grafana -n monitoring -o jsonpath='{.spec.ports[?(@.targetPort==3000)].nodePort}' --context "${KUBECONTEXT}")
GRAFANA_URL="http://${NODE_IP}:${GRAFANA_PORT}"
print_info "Grafana is available at ${GRAFANA_URL}"
print_info "\nFetching Grafana admin password..."
GRAFANA_ADMIN_PASSWORD=$(kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" --context "${KUBECONTEXT}" | base64 --decode)
print_info "Grafana admin password: ${GRAFANA_ADMIN_PASSWORD}"

print_info "\nTest traffic commands:"
print_command "curl http://test.example.com:30443 --resolve test.example.com:${INGRESS_HTTP_PORT}:${NODE_IP} -H 'Test: HALLOOOOOO'"
print_command "curl https://test.example.com:30443 --cacert output/stls-https/wildcard-cert.pem  --resolve test.example.com:${INGRESS_HTTPS_PORT}:${NODE_IP} -H 'Test: HALLOOOOOO'"
print_command "curl https://test.example.com:30443 --cacert output/mtls-https/wildcard-cert.pem  --resolve test.example.com:${INGRESS_HTTPS_PORT}:${NODE_IP} -H 'Test: HALLOOOOOO'"
