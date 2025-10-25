# Setup Guide

This guide provides step-by-step instructions for setting up the E2E SDLC Platform Engineering demonstration.

## Prerequisites

### Required Tools

1. **Docker** (v20.10+)
   - Install: https://docs.docker.com/get-docker/
   - Verify: `docker --version`

2. **kubectl** (v1.24+)
   - Install: https://kubernetes.io/docs/tasks/tools/
   - Verify: `kubectl version --client`

3. **k3d** (v5.0+)
   - Install: `wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash`
   - Verify: `k3d version`

4. **Git**
   - Install: https://git-scm.com/downloads
   - Verify: `git --version`

### Optional Tools

- **k9s**: Terminal-based Kubernetes dashboard
  - Install: https://k9scli.io/topics/install/
  
- **jq**: JSON processor for better script output
  - Install: `sudo apt-get install jq` (Linux) or `brew install jq` (macOS)

### System Requirements

- **CPU**: 4+ cores recommended
- **RAM**: 8GB minimum, 16GB recommended
- **Disk**: 20GB free space
- **OS**: Linux or macOS (Windows with WSL2)

## Installation Steps

### Step 1: Check Prerequisites

Run the prerequisites checker:

```bash
./scripts/helpers/check-prerequisites.sh
```

This will verify all required tools are installed and display version information.

### Step 2: Clone Repository

```bash
git clone https://github.com/DramisInfo/e2e-platform-engineering.git
cd e2e-platform-engineering
```

### Step 3: Run Setup Script

Execute the main setup script:

```bash
./scripts/setup-cluster.sh
```

**What this script does:**

1. Creates a k3d cluster named `e2e-sdlc-demo`
2. Configures cluster with 2 agent nodes
3. Sets up port forwarding (8080:80, 8443:443)
4. Installs NGINX Ingress Controller
5. Installs ArgoCD
6. Installs Argo Rollouts
7. Installs Argo Events
8. Deploys ArgoCD Applications
9. Configures event automation

**Expected time:** 10-15 minutes

### Step 4: Verify Installation

Run the validation script:

```bash
./scripts/validate.sh
```

This checks:
- Cluster existence and health
- ArgoCD installation and readiness
- Argo Rollouts installation
- Argo Events installation
- Ingress controller status
- Application deployments

### Step 5: Access ArgoCD

1. **Port-forward ArgoCD UI:**
   ```bash
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   ```

2. **Get admin password:**
   ```bash
   kubectl -n argocd get secret argocd-initial-admin-secret \
     -o jsonpath="{.data.password}" | base64 -d
   echo
   ```

3. **Open ArgoCD UI:**
   - URL: https://localhost:8080
   - Username: `admin`
   - Password: (from step 2)
   - Accept the self-signed certificate warning

### Step 6: Configure Local DNS

Add entries to `/etc/hosts`:

```bash
# On Linux/macOS
sudo sh -c 'echo "127.0.0.1 staging.local production.local" >> /etc/hosts'

# On Windows (edit C:\Windows\System32\drivers\etc\hosts)
127.0.0.1 staging.local production.local
```

### Step 7: Access Applications

Wait for ArgoCD to sync applications (usually 1-3 minutes), then access:

- **Staging**: http://staging.local:8080
- **Production**: http://production.local:8080

## Manual Installation (Advanced)

If you prefer to install components manually:

### 1. Create k3d Cluster

```bash
k3d cluster create e2e-sdlc-demo \
  --agents 2 \
  --port "8080:80@loadbalancer" \
  --port "8443:443@loadbalancer" \
  --wait
```

### 2. Install Ingress Controller

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s
```

### 3. Install ArgoCD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl wait --for=condition=available --timeout=300s \
  deployment/argocd-server -n argocd
```

### 4. Install Argo Rollouts

```bash
kubectl create namespace argo-rollouts
kubectl apply -n argo-rollouts \
  -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
```

### 5. Install Argo Events

```bash
kubectl create namespace argo-events
kubectl apply -n argo-events \
  -f https://raw.githubusercontent.com/argoproj/argo-events/stable/manifests/install.yaml
kubectl apply -n argo-events \
  -f https://raw.githubusercontent.com/argoproj/argo-events/stable/examples/eventbus/native.yaml
```

### 6. Deploy Applications

```bash
kubectl apply -f gitops/argocd/
kubectl apply -f gitops/argo-events/
```

## Post-Installation Configuration

### ArgoCD CLI (Optional)

Install ArgoCD CLI for command-line management:

```bash
# Linux
curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x argocd
sudo mv argocd /usr/local/bin/

# macOS
brew install argocd

# Login
argocd login localhost:8080
```

### Argo Rollouts Plugin (Optional)

Install kubectl plugin for managing rollouts:

```bash
curl -LO https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64
chmod +x kubectl-argo-rollouts-linux-amd64
sudo mv kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts

# View rollouts
kubectl argo rollouts list rollouts -n production
```

## Verification Checklist

- [ ] k3d cluster is running
- [ ] kubectl can connect to cluster
- [ ] ArgoCD UI is accessible
- [ ] Ingress controller is ready
- [ ] ArgoCD applications are synced
- [ ] Staging namespace has pods
- [ ] Production namespace has pods
- [ ] Applications are accessible via browser

## Next Steps

- Read the [Walkthrough Guide](walkthrough.md) for a complete demo
- Explore the [Architecture Documentation](architecture.md)
- Review [Troubleshooting Guide](troubleshooting.md) if you encounter issues

## Cleanup

To remove everything:

```bash
./scripts/cleanup.sh
```

This will delete the k3d cluster and all associated resources.
