#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CLUSTER_NAME="e2e-sdlc-demo"
ARGOCD_NAMESPACE="argocd"

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}Installing ArgoCD${NC}"
echo -e "${BLUE}================================================${NC}\n"

# Create ArgoCD namespace
echo -e "${YELLOW}Creating ArgoCD namespace...${NC}"
kubectl create namespace ${ARGOCD_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# Install ArgoCD
echo -e "${YELLOW}Installing ArgoCD...${NC}"
kubectl apply -n ${ARGOCD_NAMESPACE} -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
echo -e "${YELLOW}Waiting for ArgoCD to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s \
    deployment/argocd-server \
    deployment/argocd-repo-server \
    deployment/argocd-applicationset-controller \
    -n ${ARGOCD_NAMESPACE}

echo -e "${GREEN}✓ ArgoCD pods are ready${NC}"

# Patch ArgoCD server to use NodePort for easier access
echo -e "${YELLOW}Configuring ArgoCD server service...${NC}"
kubectl patch svc argocd-server -n ${ARGOCD_NAMESPACE} -p '{"spec": {"type": "LoadBalancer"}}'

# Get initial admin password
echo -e "${YELLOW}Retrieving ArgoCD admin password...${NC}"
ARGOCD_PASSWORD=$(kubectl -n ${ARGOCD_NAMESPACE} get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo -e "\n${GREEN}================================================${NC}"
echo -e "${GREEN}ArgoCD Installation Complete!${NC}"
echo -e "${GREEN}================================================${NC}"
echo -e "\n${BLUE}Access Information:${NC}"
echo -e "  Username: ${GREEN}admin${NC}"
echo -e "  Password: ${GREEN}${ARGOCD_PASSWORD}${NC}"
echo -e "\n${BLUE}To access ArgoCD UI:${NC}"
echo -e "  Run: ${YELLOW}kubectl port-forward svc/argocd-server -n argocd 8080:443${NC}"
echo -e "  Then open: ${YELLOW}https://localhost:8080${NC}"
echo -e "  (Accept the self-signed certificate warning)\n"
