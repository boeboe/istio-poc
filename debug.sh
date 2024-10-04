#!/usr/bin/env bash
export BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source ${BASE_DIR}/env.sh
# set -e

if ! command_exists istioctl; then
    print_error "Error: 'istioctl' is not installed. Please install istioctl before proceeding."
    exit 1
fi

# Enable debug mode on Istio ingress gateway
print_info "Enabling debug mode on Istio ingress gateway..."
ISTIO_INGRESS_POD=$(kubectl get pods -n "${ISTIO_INGRESS_NS}" -l "istio=${ISTIO_INGRESS_SVC}" -o jsonpath='{.items[0].metadata.name}')
print_command "istioctl -i \"${ISTIO_NS}\" proxy-config log ${ISTIO_INGRESS_POD}.${ISTIO_INGRESS_NS} --level \"debug\""
istioctl -i "${ISTIO_NS}" proxy-config log ${ISTIO_INGRESS_POD}.${ISTIO_INGRESS_NS} --level "debug"

# Enable debug mode on a specific pod with an Istio sidecar
print_info "Enabling debug mode on target pod with an Istio sidecar..."
TARGET_POD_NAME=$(kubectl get pods -n perf-https-mtls -l "app=nginx" -o jsonpath='{.items[0].metadata.name}')
print_command "istioctl -i \"${ISTIO_NS}\" proxy-config log ${TARGET_POD_NAME}.perf-https-mtls --level \"debug\""
istioctl -i "${ISTIO_NS}" proxy-config log ${TARGET_POD_NAME}.perf-https-mtls --level "debug"

print_info "Debug mode has been enabled for both the Istio ingress gateway and the target pod."
