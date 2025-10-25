#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

CLUSTER_NAME="e2e-sdlc-demo"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${CYAN}"
echo "================================================"
echo "  E2E SDLC Platform Engineering Demo Setup"
echo "================================================"
echo -e "${NC}\n"

# Step 1: Check prerequisites
echo -e "${BLUE}Step 1: Checking prerequisites...${NC}"
bash "${SCRIPT_DIR}/helpers/check-prerequisites.sh"
echo ""

# Step 2: Create k3d cluster
echo -e "${BLUE}Step 2: Creating k3d cluster...${NC}"
if k3d cluster list | grep -q ${CLUSTER_NAME}; then
    echo -e "${YELLOW}Cluster '${CLUSTER_NAME}' already exists${NC}"
    read -p "Do you want to delete and recreate it? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Deleting existing cluster...${NC}"
        k3d cluster delete ${CLUSTER_NAME}
    else
        echo -e "${GREEN}Using existing cluster${NC}"
    fi
fi

if ! k3d cluster list | grep -q ${CLUSTER_NAME}; then
    echo -e "${YELLOW}Creating k3d cluster '${CLUSTER_NAME}'...${NC}"
    k3d cluster create ${CLUSTER_NAME} \
        --agents 2 \
        --port "8080:80@loadbalancer" \
        --port "8443:443@loadbalancer" \
        --wait

    echo -e "${GREEN}✓ Cluster created successfully${NC}"
else
    echo -e "${GREEN}✓ Using existing cluster${NC}"
fi

# Set kubectl context
kubectl config use-context k3d-${CLUSTER_NAME}
echo ""

# Step 3: Install NGINX Ingress Controller
echo -e "${BLUE}Step 3: Installing NGINX Ingress Controller...${NC}"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

echo -e "${YELLOW}Waiting for Ingress Controller to be ready...${NC}"
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s

echo -e "${GREEN}✓ Ingress Controller ready${NC}"
echo ""

# Step 4: Install ArgoCD
echo -e "${BLUE}Step 4: Installing ArgoCD...${NC}"
bash "${SCRIPT_DIR}/install-argocd.sh"
echo ""

# Step 5: Install Argo Rollouts
echo -e "${BLUE}Step 5: Installing Argo Rollouts...${NC}"
bash "${SCRIPT_DIR}/install-argo-rollouts.sh"
echo ""

# Step 6: Install Argo Events
echo -e "${BLUE}Step 6: Installing Argo Events...${NC}"
bash "${SCRIPT_DIR}/install-argo-events.sh"
echo ""

# Step 7: Deploy ArgoCD Applications
echo -e "${BLUE}Step 7: Deploying ArgoCD Applications...${NC}"
echo -e "${YELLOW}Applying ArgoCD Application manifests...${NC}"
kubectl apply -f "${SCRIPT_DIR}/../gitops/argocd/"

echo -e "${GREEN}✓ ArgoCD Applications deployed${NC}"
echo ""

# Step 8: Deploy Argo Events configuration
echo -e "${BLUE}Step 8: Deploying Argo Events configuration...${NC}"
kubectl apply -f "${SCRIPT_DIR}/../gitops/argo-events/"
echo -e "${GREEN}✓ Argo Events configuration deployed${NC}"
echo ""

# Get ArgoCD password
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

# Final summary
echo -e "${CYAN}"
echo "================================================"
echo "  Setup Complete! 🎉"
echo "================================================"
echo -e "${NC}\n"

echo -e "${GREEN}Cluster Information:${NC}"
echo -e "  Cluster Name: ${YELLOW}${CLUSTER_NAME}${NC}"
echo -e "  Context: ${YELLOW}k3d-${CLUSTER_NAME}${NC}"
echo ""

echo -e "${GREEN}ArgoCD Access:${NC}"
echo -e "  Username: ${YELLOW}admin${NC}"
echo -e "  Password: ${YELLOW}${ARGOCD_PASSWORD}${NC}"
echo -e "  UI: ${YELLOW}https://localhost:8080${NC}"
echo -e "  Port-forward: ${YELLOW}kubectl port-forward svc/argocd-server -n argocd 8080:443${NC}"
echo ""

echo -e "${GREEN}Application Access (once deployed):${NC}"
echo -e "  Staging: ${YELLOW}http://staging.local:8080${NC}"
echo -e "  Production: ${YELLOW}http://production.local:8080${NC}"
echo -e "  ${MAGENTA}Note: Add entries to /etc/hosts:${NC}"
echo -e "    ${YELLOW}127.0.0.1 staging.local production.local${NC}"
echo ""

echo -e "${GREEN}Useful Commands:${NC}"
echo -e "  View all resources: ${YELLOW}kubectl get all -A${NC}"
echo -e "  View rollouts: ${YELLOW}kubectl get rollouts -n production${NC}"
echo -e "  View ArgoCD apps: ${YELLOW}kubectl get applications -n argocd${NC}"
echo -e "  Run validation: ${YELLOW}./scripts/validate.sh${NC}"
echo ""

echo -e "${BLUE}Next Steps:${NC}"
echo -e "  1. Port-forward ArgoCD UI: ${YELLOW}kubectl port-forward svc/argocd-server -n argocd 8080:443${NC}"
echo -e "  2. Open ArgoCD UI and login"
echo -e "  3. Watch applications sync"
echo -e "  4. Add hosts file entries for staging.local and production.local"
echo -e "  5. Access the applications!"
echo ""

echo -e "${MAGENTA}To clean up everything:${NC}"
echo -e "  ${YELLOW}./scripts/cleanup.sh${NC}"
echo ""
