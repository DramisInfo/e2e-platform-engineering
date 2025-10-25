#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

EVENTS_NAMESPACE="argo-events"

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}Installing Argo Events${NC}"
echo -e "${BLUE}================================================${NC}\n"

# Create namespace
echo -e "${YELLOW}Creating Argo Events namespace...${NC}"
kubectl create namespace ${EVENTS_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# Install Argo Events
echo -e "${YELLOW}Installing Argo Events...${NC}"
kubectl apply -n ${EVENTS_NAMESPACE} -f https://raw.githubusercontent.com/argoproj/argo-events/stable/manifests/install.yaml

# Install EventBus
echo -e "${YELLOW}Installing EventBus (NATS)...${NC}"
kubectl apply -n ${EVENTS_NAMESPACE} -f https://raw.githubusercontent.com/argoproj/argo-events/stable/examples/eventbus/native.yaml

# Wait for Argo Events to be ready
echo -e "${YELLOW}Waiting for Argo Events to be ready...${NC}"
kubectl wait --for=condition=available --timeout=180s \
    deployment/eventbus-controller \
    deployment/eventsource-controller \
    deployment/sensor-controller \
    -n ${EVENTS_NAMESPACE}

# Wait for EventBus to be ready
echo -e "${YELLOW}Waiting for EventBus to be ready...${NC}"
sleep 10
kubectl wait --for=condition=ready --timeout=180s \
    pod -l controller=eventbus-controller \
    -n ${EVENTS_NAMESPACE}

echo -e "${GREEN}✓ Argo Events is ready${NC}"

echo -e "\n${GREEN}================================================${NC}"
echo -e "${GREEN}Argo Events Installation Complete!${NC}"
echo -e "${GREEN}================================================${NC}"
echo -e "\n${BLUE}Next steps:${NC}"
echo -e "  - Deploy event sources and sensors from gitops/argo-events/"
echo -e "  ${YELLOW}kubectl apply -f gitops/argo-events/${NC}\n"
