#!/usr/bin/env bash

# Variables
export CLUSTER_NAME="istio-cluster"
export KUBECONTEXT="kind-${CLUSTER_NAME}"
export ISTIO_VERSION="1.18.0"

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

if ! command_exists kind; then
    print_error "Error: 'kind' is not installed. Please install kind before proceeding."
    exit 1
fi

if ! command_exists kubectl; then
    print_error "Error: 'kubectl' is not installed. Please install kubectl before proceeding."
    exit 1
fi

if ! command_exists helm; then
    print_error "Error: 'helm' is not installed. Please install helm before proceeding."
    exit 1
fi