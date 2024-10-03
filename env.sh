#!/usr/bin/env bash

# Setup Environment Variables
export ENVIRONMENT="plfstg"
# export ENVIRONMENT="plftst"
# export ENVIRONMENT="plfdev"
export ISTIO_NS="aks-istio-system"
export ISTIO_INGRESS_NS="aks-istio-ingress"
export ISTIO_EGRESS_NS="aks-istio-egress"
# export ISTIO_INGRESS_MODE="external"
export ISTIO_INGRESS_MODE="internal"
export ISTIO_INGRESS_SVC="aks-istio-ingressgateway-${ISTIO_INGRESS_MODE}"

# Colors
end="\033[0m"
black="\033[0;30m"
blackb="\033[1;30m"
white="\033[0;37m"
whiteb="\033[1;37m"
red="\033[0;31m"
redb="\033[1;31m"
green="\033[0;32m"
greenb="\033[1;32m"
yellow="\033[0;33m"
yellowb="\033[1;33m"
blue="\033[0;34m"
blueb="\033[1;34m"
purple="\033[0;35m"
purpleb="\033[1;35m"
lightblue="\033[0;36m"
lightblueb="\033[1;36m"

# Print info messages
function print_info {
  echo -e "${greenb}${1}${end}"
}

# Print warning messages
function print_warning {
  echo -e "${yellowb}${1}${end}"
}

# Print error messages
function print_error {
  echo -e "${redb}${1}${end}"
}

# Print command messages
function print_command {
  echo -e "${lightblueb}${1}${end}"
}

export -f print_info print_warning print_error print_command

function command_exists() {
    command -v "$1" >/dev/null 2>&1
}

if ! command_exists kubectl; then
    print_error "Error: 'kubectl' is not installed. Please install kubectl before proceeding."
    exit 1
fi

if ! command_exists helm; then
    print_error "Error: 'helm' is not installed. Please install helm before proceeding."
    exit 1
fi

case "${ENVIRONMENT}" in
  plfstg)
    print_info "Setting env variables for 'plfstg'"
    export AZ_SUBSCRIPTION="d6ba0fbd-9ea3-4148-ac73-c9af12cb342a"
    export AZ_RESOURCEGROUP="rg-apps-plfstg"
    export AZ_AKS_NAME="aks-apps-plfstg"
    export KUBECONTEXT="aks-apps-plfstg"
    export DNS_SUFFIX="staging.platform.liantis.net"
    ;;

  plftst)
    print_info "Setting env variables for 'plftst'"
    export AZ_SUBSCRIPTION="a63f2e43-de09-4537-88d0-8e0f439bbbb4"
    export AZ_RESOURCEGROUP="rg-apps-plftst"
    export AZ_AKS_NAME="aks-apps-plftst"
    export KUBECONTEXT="aks-apps-plftst"
    export DNS_SUFFIX="test.platform.liantis.net"
    ;;

  plfdev)
    print_info "Setting env variables for 'plfdev'"
    export AZ_SUBSCRIPTION="30f926fb-0740-480c-aa79-5c635d83683d"
    export AZ_RESOURCEGROUP="rg-apps-plfdev"
    export AZ_AKS_NAME="aks-apps-plfdev"
    export KUBECONTEXT="aks-apps-plfdev"
    export DNS_SUFFIX="dev.platform.liantis.net"
    ;;

  *)
    print_error "ENVIRONMENT must be one of 'plfstg', 'plftst' or 'plfdev'"
    exit 1
    ;;
esac

# Check if the context exists
if ! kubectl config get-contexts "${KUBECONTEXT}" &>/dev/null; then
  print_error "Error: Kubernetes context '${KUBECONTEXT}' does not exist."
  exit 1
fi

# Get the current context
CURRENT_CONTEXT=$(kubectl config current-context)

# If the current context is not the target context, switch to it
if [ "${CURRENT_CONTEXT}" != "${KUBECONTEXT}" ]; then
  print_info "Switching to Kubernetes context '${KUBECONTEXT}'..."
  kubectl config use-context "${KUBECONTEXT}"
else
  print_info "Already using Kubernetes context '${KUBECONTEXT}'."
fi 
