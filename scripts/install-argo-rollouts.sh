#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

ROLLOUTS_NAMESPACE="argo-rollouts"

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}Installing Argo Rollouts${NC}"
echo -e "${BLUE}================================================${NC}\n"

# Create namespace
echo -e "${YELLOW}Creating Argo Rollouts namespace...${NC}"
kubectl create namespace ${ROLLOUTS_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# Install Argo Rollouts
echo -e "${YELLOW}Installing Argo Rollouts controller...${NC}"
kubectl apply -n ${ROLLOUTS_NAMESPACE} -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml

# Wait for Argo Rollouts to be ready
echo -e "${YELLOW}Waiting for Argo Rollouts to be ready...${NC}"
kubectl wait --for=condition=available --timeout=180s \
    deployment/argo-rollouts \
    -n ${ROLLOUTS_NAMESPACE}

echo -e "${GREEN}✓ Argo Rollouts is ready${NC}"

echo -e "\n${GREEN}================================================${NC}"
echo -e "${GREEN}Argo Rollouts Installation Complete!${NC}"
echo -e "${GREEN}================================================${NC}"
echo -e "\n${BLUE}Argo Rollouts kubectl plugin (optional):${NC}"
echo -e "  Install: ${YELLOW}curl -LO https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64${NC}"
echo -e "  Make executable: ${YELLOW}chmod +x kubectl-argo-rollouts-linux-amd64${NC}"
echo -e "  Move to PATH: ${YELLOW}sudo mv kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts${NC}"
echo -e "\n${BLUE}View rollouts:${NC}"
echo -e "  ${YELLOW}kubectl argo rollouts list rollouts -n production${NC}"
echo -e "  ${YELLOW}kubectl argo rollouts get rollout <rollout-name> -n production --watch${NC}\n"
