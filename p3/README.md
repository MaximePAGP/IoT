# Inception of Things - Part 3: K3d & Argo CD (GitOps)

## Introduction
This part of the project introduces the **GitOps** methodology using **K3d** and **Argo CD**. 
Instead of manually applying Kubernetes configuration files (`kubectl apply`), we use a declarative approach where a Git repository acts as the single source of truth for our infrastructure.

## Concepts & Technologies Explained

### 1. K3d vs K3s
* **K3s** (used in Part 1 & 2) is a lightweight Kubernetes distribution designed for edge computing and IoT. It runs directly on the host or virtual machines.
* **K3d** is a utility designed to easily run **K3s inside Docker containers**. It allows us to spin up highly available, multi-node Kubernetes clusters locally in seconds, without the overhead of heavy virtual machines.

### 2. Argo CD (Continuous Delivery)
Argo CD is a declarative, GitOps continuous delivery tool for Kubernetes.
* It monitors our public GitHub repository.
* When a change is detected (e.g., updating the app tag from `v1` to `v2`), Argo CD automatically pulls the new state and updates the Kubernetes cluster to match the Git repository.

## How to run the project

### Prerequisites
A fresh Debian/Ubuntu Virtual Machine.

### Installation
1. Navigate to the scripts directory:
   ```bash
   cd p3/scripts/
2. Run the installation script:
    ```bash
    ./install.sh
3. Apply Docker group changes:
    ```bash
    newgrp docker
    ```

### Accessing the services
#### 1. Argo CD Dashboard
Since Argo CD enforces HTTPS internally, we use port-forwarding to access the UI safely:

   ```bash
   kubectl port-forward svc/argocd-server -n argocd 8443:443 &
   ```

* Then, open your browser at: https://localhost:8443

* User: admin

* Password: (Printed at the end of the install script)

#### The Playground Application
The application is exposed via the K3d loadbalancer on port 8888.
   ```bash
   curl http://localhost:8888
   ```

#### GitOps Testing Procedure

1. Run curl http://localhost:8888 (Expect v1 response).

2. Go to the public GitHub repository and edit deployment.yaml to change the image tag to wil42/playground:v2.

3. Commit the changes.

4. Wait for Argo CD to sync (or click "Refresh" on the UI).

5. Run curl http://localhost:8888 again (Expect v2 response).


# k3d usefull commands
List clusters:
   ```bash
   k3d cluster list
   ```

Delete iot cluster:
   ```bash
   k3d cluster delete iot-cluster
   ```

Stop clusters:
   ```bash
   k3d cluster stop iot-cluster
   ```

Start clusters who were stopped:
   ```bash
   k3d cluster start iot-cluster
   ```


Check nodes (virtual servers):
   ```bash
   kubectl get nodes
   ```

List namespaces (workspaces):
   ```bash
   kubectl get ns
   ```

Check all in cluster:
   ```bash
   kubectl get pods -A
   ```
