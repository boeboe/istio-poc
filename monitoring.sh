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

# Function to import a Grafana dashboard using the Grafana API
function import_dashboard {
  NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' --context "${KUBECONTEXT}")
  GRAFANA_PORT="${GRAFANA_PORT:-30091}"
  GRAFANA_URL="http://${NODE_IP}:${GRAFANA_PORT}"
  DASHBOARD_ID=6417
  GRAFANA_USER="admin"
  GRAFANA_PASSWORD=$(kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode)
  
  print_info "Importing Grafana dashboard with ID ${DASHBOARD_ID}..."

  # Fetch the Grafana dashboard JSON using the dashboard ID
  DASHBOARD_ID=6417
  curl -s -H "Accept: application/json" "https://grafana.com/api/dashboards/${DASHBOARD_ID}/revisions/latest/download" -o "${BASE_DIR}/output/dashboard.json"

  cat <<EOF > "${BASE_DIR}/output/dashboard_import.json"
{
  “dashboard”: $(cat "${BASE_DIR}/output/dashboard.json"),
  “folderId”: 0,
  “overwrite”: true,
  “inputs”: [
    {
    “name”: “DS_PROMETHEUS”,
    “type”: “datasource”,
    “pluginId”: “prometheus”,
    “value”: “Prometheus”
    }
  ]
}
EOF

  # Import the dashboard to Grafana using the Grafana API
  curl -X POST "${GRAFANA_URL}/api/dashboards/db" \
    -H "Content-Type: application/json" \
    -u "${GRAFANA_USER}:${GRAFANA_PASSWORD}" \
    -d @${BASE_DIR}/output/dashboard_import.json

  print_info "Dashboard import completed."
}

# Install Prometheus, kube-state-metrics, and Grafana
install_prometheus
install_kube_state_metrics
install_grafana
import_dashboard
