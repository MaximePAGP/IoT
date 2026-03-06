#!/bin/bash
set -euo pipefail

K3S_CONFIG="/etc/rancher/k3s/k3s.yaml"
VAGRANT_KUBE_DIR="/home/vagrant/.kube"
SHARED_KUBECONFIG="/vagrant/k3s.yaml"

# Install curl only when missing.
ensure_curl() {
  if command -v curl >/dev/null 2>&1; then
    echo "[INFO] curl is already installed."
    return
  fi

  echo "[INFO] Installing curl..."
  apt-get update
  apt-get install -y curl
}

# Install K3s server if it is not already present.
install_k3s_if_missing() {
  if [ -f "$K3S_CONFIG" ]; then
    echo "[INFO] K3s is already installed."
    return
  fi
  echo "[INFO] Installing K3s server..."
  curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --write-kubeconfig-mode 644" sh -
}

# Ensure kubectl is available after installation.
ensure_kubectl() {
  if command -v kubectl >/dev/null 2>&1; then
    return
  fi

  echo "[ERROR] kubectl was not installed." >&2
  exit 1
}

# Give the vagrant user access to kubeconfig inside the VM.
configure_vagrant_kubeconfig() {
  echo "[INFO] Configuring kubeconfig for user 'vagrant'..."
  mkdir -p "$VAGRANT_KUBE_DIR"
  cp "$K3S_CONFIG" "$VAGRANT_KUBE_DIR/config"
  chown -R vagrant:vagrant "$VAGRANT_KUBE_DIR"
}

# Wait until the API server responds to kubectl.
wait_for_cluster() {
  local max_attempts=30
  local sleep_seconds=2
  local attempt=1

  echo "[INFO] Waiting for Kubernetes API..."
  while (( attempt <= max_attempts )); do
    if kubectl get nodes >/dev/null 2>&1; then
      echo "[INFO] Cluster is ready."
      return
    fi

    echo "  Attempt ${attempt}/${max_attempts}: not ready yet."
    sleep "$sleep_seconds"
    ((attempt++))
  done

  echo "[ERROR] Cluster did not become ready in time." >&2
  exit 1
}

# Apply all application manifests.
deploy_manifests() {
  echo "[INFO] Deploying Kubernetes manifests..."
  kubectl apply -f /vagrant/confs/app1.yaml
  kubectl apply -f /vagrant/confs/app2.yaml
  kubectl apply -f /vagrant/confs/app3.yaml
  kubectl apply -f /vagrant/confs/ingress.yaml
}

# Export kubeconfig to the shared Vagrant folder for host usage.
export_shared_kubeconfig() {
  echo "[INFO] Exporting kubeconfig to shared folder..."
  cp "$K3S_CONFIG" "$SHARED_KUBECONFIG"
  chmod 0644 "$SHARED_KUBECONFIG"
  chown vagrant:vagrant "$SHARED_KUBECONFIG" || true
}

main() {
  echo "[INFO] Starting server provisioning..."
  ensure_curl
  install_k3s_if_missing
  ensure_kubectl

  export KUBECONFIG="$K3S_CONFIG"

  configure_vagrant_kubeconfig
  wait_for_cluster
  deploy_manifests
  export_shared_kubeconfig

  echo "[INFO] Provisioning completed."
}

main "$@"
