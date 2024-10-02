#!/usr/bin/env bash
export BASE_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source ${BASE_DIR}/env.sh
# set -e


# Install Prometheus using Helm with NodePort
function install_prometheus {
  print_info "Adding Helm repository for Prometheus..."
  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
  helm repo update

  print_info "Installing Prometheus..."
  helm upgrade --install prometheus prometheus-community/prometheus \
    --kube-context "${KUBECONTEXT}" \
    --namespace monitoring \
    --create-namespace \
    --set server.service.type=NodePort \
    --set "server.service.nodePort=${PROMETHEUS_PORT}" \
    --wait
}

# Install Grafana using Helm with NodePort
function install_grafana {
  print_info "Adding Helm repository for Grafana..."
  helm repo add grafana https://grafana.github.io/helm-charts
  helm repo update

  print_info "Installing Grafana..."
  helm upgrade --install grafana grafana/grafana \
    --kube-context "${KUBECONTEXT}" \
    --namespace monitoring \
    --set service.type=NodePort \
    --set "service.nodePort=${GRAFANA_PORT}" \
    --wait
}

# Install kube-state-metrics using Helm
function install_kube_state_metrics {
  print_info "Installing kube-state-metrics..."
  helm upgrade --install kube-state-metrics prometheus-community/kube-state-metrics \
    --kube-context "${KUBECONTEXT}" \
    --namespace monitoring \
    --wait
}

# Function to download a Grafana dashboard
function download_dashboard {
  DASHBOARD_ID=18283

  print_info "Importing Grafana dashboard with ID ${DASHBOARD_ID}..."

  # Fetch the Grafana dashboard JSON using the dashboard ID
  curl -s -H "Accept: application/json" "https://grafana.com/api/dashboards/${DASHBOARD_ID}/revisions/latest/download" -o "${BASE_DIR}/output/dashboard.json"
  print_info "Dashboard download completed, import manually with ID ${DASHBOARD_ID}."
}

# Install Prometheus, kube-state-metrics, and Grafana
install_prometheus
install_kube_state_metrics
install_grafana
download_dashboard
