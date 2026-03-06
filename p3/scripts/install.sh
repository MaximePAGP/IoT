#!/bin/bash
# ==============================================================================
# Inception of Things - Part 3: K3d and Argo CD Setup
# ==============================================================================

echo "Updating system and installing prerequisites..."
sudo apt-get update -y
sudo apt-get install -y curl git docker.io

echo "Configuring Docker..."
sudo systemctl enable --now docker
sudo usermod -aG docker $USER

echo "Installing K3d..."
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

echo "Installing Kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

sleep 3

echo "Creating K3d cluster (iot-cluster)..."
sudo k3d cluster create iot-cluster --port "8888:8888@loadbalancer" --port "8080:80@loadbalancer" --wait

mkdir -p ~/.kube
sudo k3d kubeconfig get iot-cluster > ~/.kube/config
sudo chown $USER:$USER ~/.kube/config

echo "Creating namespaces..."
kubectl create namespace argocd
kubectl create namespace dev

echo "Installing Argo CD..."
kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Waiting for Argo CD CRDs to initialize (15s)..."
sleep 15

echo "Linking Argo CD to GitHub repository..."
kubectl apply -f ../confs/application.yaml

echo "Waiting for Argo CD Secret to be generated (10s)..."
sleep 10

while ! kubectl -n argocd get secret argocd-initial-admin-secret &>/dev/null; do
    sleep 5
done
ARGOPWD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo "======================================================================="
echo "Installation complete!"
echo "ArgoCD User : admin"
echo "ArgoCD Password : $ARGOPWD"
echo ""
echo "Access :"
echo "   Go to : https://localhost:8443"
echo "======================================================================="

 kubectl port-forward svc/argocd-server -n argocd 8443:443 &>/dev/null