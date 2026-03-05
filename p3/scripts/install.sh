#!/bin/bash

# ==============================================================================
# Script to install Docker, K3d, Kubectl and setup the cluster
# ==============================================================================

echo "Updating system and installing prerequisites..."
sudo apt-get update -y
sudo apt-get install -y curl git docker.io

echo "Configuring Docker..."
sudo systemctl enable --now docker
sudo usermod -aG docker $USER  # according rights to user => sudi is not longer required

echo "Installing K3d..."
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

echo "Installing Kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# Give Docker a moment to start properly
sleep 3

echo "Creating K3d cluster (iot-cluster)..."
# Port 8888 for the app, Port 8080 for Argo CD UI
sudo k3d cluster create iot-cluster --port "8888:8888@loadbalancer" --port "8080:80@loadbalancer" --wait

# Copy the kubeconfig so the standard user can use kubectl without sudo
mkdir -p ~/.kube
sudo k3d kubeconfig get iot-cluster > ~/.kube/config  # generate config file (API server address, certificates, and tokens needed to authenticate)
sudo chown $USER:$USER ~/.kube/config

echo "Creating namespaces (argocd and dev)..."
kubectl create namespace argocd
kubectl create namespace dev

echo "Installing Argo CD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "======================================================================="
echo "Installation complete!"
echo "IMPORTANT: Please log out and log back in (or type 'newgrp docker') "
echo "to apply Docker group permissions without needing sudo."
echo "======================================================================="
