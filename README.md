# Inception of Things

---

# Part 1: K3s and Vagrant

## Introduction
This part sets up a **multi-node K3s cluster** using **Vagrant** and **Ansible**. Two virtual machines are created: a **Server** node and a **ServerWorker** (agent) node, both running Ubuntu Jammy. K3s is installed on the server first, and the worker joins automatically using the server's token.

## Concepts & Technologies Explained

### 1. K3s
**K3s** is a lightweight, certified Kubernetes distribution designed for edge, IoT, and resource-constrained environments. It packages the entire Kubernetes control plane into a single binary.

### 2. Vagrant
**Vagrant** automates the creation and configuration of virtual machines. Combined with **Ansible** for provisioning, it provides a reproducible infrastructure-as-code setup.

### 3. Ansible
**Ansible** is used as the provisioner to install common dependencies, set up SSH keys, and install K3s on both nodes. The server token is automatically shared with the worker node to join the cluster.

## Architecture
| Machine | Hostname | IP | Role |
|---------|----------|----|------|
| Server | magrondiS | 192.168.56.110 | K3s Server (control plane) |
| Worker | magrondiSW | 192.168.56.111 | K3s Agent (worker node) |

## How to run the project

### Prerequisites
* VirtualBox
* Vagrant
* Ansible

### Installation
```bash
cd p1/
make up
```

### Verify the cluster
SSH into the server and check the nodes:
```bash
vagrant ssh magrondiS
kubectl get nodes
```
You should see both `magrondiS` (server) and `magrondiSW` (agent) in `Ready` state.

### Makefile Commands
| Command | Description |
|---------|-------------|
| `make up` | Create and provision the VMs |
| `make stop` | Halt the VMs |
| `make reload` | Reload the VMs |
| `make fclean` | Destroy the VMs |
| `make re` | Destroy and recreate the VMs |

---

# Part 2: K3s and Three Simple Applications

## Introduction
This part deploys **three web applications** on a single-node K3s cluster using **Vagrant**. Traffic is routed to the correct application based on the **hostname** using a **Traefik Ingress** controller (bundled with K3s).

## Concepts & Technologies Explained

### 1. Ingress
An **Ingress** resource defines HTTP routing rules. Traefik (K3s's built-in ingress controller) reads these rules and routes traffic to the appropriate backend service based on the `Host` header.

### 2. Replicas
Each app has a configurable number of replicas:
* **app1**: 1 replica
* **app2**: 3 replicas
* **app3**: 1 replica (default/fallback)

## Architecture
| Host | Service | Replicas | Message |
|------|---------|----------|---------|
| app1.com | app1-svc | 1 | Hello from app1 |
| app2.com | app2-svc | 3 | Hello from app 2 |
| *(default)* | app3-svc | 1 | Hello from app3 |

## How to run the project

### Prerequisites
* VirtualBox
* Vagrant

### Installation
```bash
cd p2/
vagrant up
```

### Testing the applications
From the host machine, use `curl` with the `-H` flag to set the `Host` header:
```bash
# App 1
curl -H "Host: app1.com" http://192.168.56.110

# App 2
curl -H "Host: app2.com" http://192.168.56.110

# App 3 (default - any other host or no host)
curl http://192.168.56.110
```

### Verify inside the VM
```bash
vagrant ssh k3s-server
kubectl get pods
kubectl get ingress
```

---

# Part 3: K3d & Argo CD (GitOps)

## Introduction
This part introduces the **GitOps** methodology using **K3d** and **Argo CD**. 
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
   ```
2. Run the installation script:
   ```bash
   ./install.sh
   ```
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

#### 2. The Playground Application
The application is exposed via the K3d loadbalancer on port 8888.
   ```bash
   curl http://localhost:8888
   ```

#### GitOps Testing Procedure

1. Run `curl http://localhost:8888` (Expect v1 response).

2. Go to the public GitHub repository and edit deployment.yaml to change the image tag to `wil42/playground:v2`.

3. Commit the changes.

4. Wait for Argo CD to sync (or click "Refresh" on the UI).

5. Run `curl http://localhost:8888` again (Expect v2 response).

---

# Bonus: K3d, Argo CD & Gitea (Local GitOps)

## Introduction
The bonus part extends Part 3 by replacing the public GitHub repository with a **local Gitea** instance running inside the cluster. This creates a fully self-contained GitOps pipeline: **K3d** cluster + **Gitea** (local Git server) + **Argo CD** (continuous delivery), all automated with **Ansible**.

## Concepts & Technologies Explained

### 1. Gitea
**Gitea** is a lightweight, self-hosted Git service deployed via **Helm** into the cluster. It serves as the local Git repository that Argo CD monitors, removing the dependency on an external GitHub repository.

### 2. Helm
**Helm** is a Kubernetes package manager used here to install Gitea with a single command, handling all the complex Kubernetes resources automatically.

### 3. Fully Automated Pipeline
The Ansible playbook automates the entire setup:
1. Installs Docker, kubectl, K3d, and Helm
2. Creates the K3d cluster with port mappings
3. Deploys Gitea via Helm and creates the `wil-app` repository
4. Installs Argo CD and configures it to watch the Gitea repository
5. Pushes the initial application manifests to Gitea

## Architecture
| Port | Service | Description |
|------|---------|-------------|
| 8080 | Argo CD | Argo CD web dashboard |
| 8081 | Gitea | Gitea web interface |
| 8888 | wil-app | Playground application |

## How to run the project

### Prerequisites
* Ansible installed on the host machine

### Installation
```bash
cd bonus/
make up
```

### Accessing the services
#### 1. Argo CD Dashboard
* URL: http://localhost:8080
* User: `admin`
* Password: `123`

#### 2. Gitea
* URL: http://localhost:8081
* User: `admin`
* Password: `123`

#### 3. The Playground Application
```bash
curl http://localhost:8888
```

#### GitOps Testing Procedure (Local)

1. Run `curl http://localhost:8888` (Expect v1 response).

2. Go to Gitea at http://localhost:8081 and edit `wil-app.yml` in the `admin/wil-app` repository — change the image tag to `wil42/playground:v2`.

3. Commit the changes.

4. Wait for Argo CD to sync (or click "Refresh" on the Argo CD UI at http://localhost:8080).

5. Run `curl http://localhost:8888` again (Expect v2 response).

### Makefile Commands
| Command | Description |
|---------|-------------|
| `make up` | Run the full Ansible playbook |
| `make ansible` | Run the Ansible playbook |
| `make stop` | Halt the VMs |
| `make reload` | Reload the VMs |
| `make fclean` | Destroy the VMs |
| `make re` | Destroy and recreate |

---

# Useful K3d Commands
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
