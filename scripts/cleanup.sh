#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CLUSTER_NAME="e2e-sdlc-demo"

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}Cleaning up E2E SDLC Platform Demo${NC}"
echo -e "${BLUE}================================================${NC}\n"

# Confirm deletion
read -p "Are you sure you want to delete the cluster '${CLUSTER_NAME}'? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Cleanup cancelled${NC}"
    exit 0
fi

# Delete k3d cluster
if k3d cluster list | grep -q ${CLUSTER_NAME}; then
    echo -e "${YELLOW}Deleting k3d cluster '${CLUSTER_NAME}'...${NC}"
    k3d cluster delete ${CLUSTER_NAME}
    echo -e "${GREEN}✓ Cluster deleted${NC}"
else
    echo -e "${YELLOW}Cluster '${CLUSTER_NAME}' not found${NC}"
fi

echo -e "\n${GREEN}================================================${NC}"
echo -e "${GREEN}Cleanup Complete!${NC}"
echo -e "${GREEN}================================================${NC}"
echo -e "\n${BLUE}To set up the cluster again, run:${NC}"
echo -e "  ${YELLOW}./scripts/setup-cluster.sh${NC}\n"
