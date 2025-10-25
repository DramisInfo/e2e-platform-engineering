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
echo -e "${BLUE}Validating E2E SDLC Platform Demo${NC}"
echo -e "${BLUE}================================================${NC}\n"

ERRORS=0
WARNINGS=0

# Check if cluster exists
echo -e "${BLUE}Checking cluster...${NC}"
if k3d cluster list | grep -q ${CLUSTER_NAME}; then
    echo -e "${GREEN}✓ Cluster '${CLUSTER_NAME}' exists${NC}"
else
    echo -e "${RED}✗ Cluster '${CLUSTER_NAME}' not found${NC}"
    ((ERRORS++))
    exit 1
fi

# Check if kubectl context is set
CURRENT_CONTEXT=$(kubectl config current-context)
if [[ "$CURRENT_CONTEXT" == "k3d-${CLUSTER_NAME}" ]]; then
    echo -e "${GREEN}✓ kubectl context is set correctly${NC}"
else
    echo -e "${YELLOW}⚠ kubectl context is '${CURRENT_CONTEXT}', expected 'k3d-${CLUSTER_NAME}'${NC}"
    ((WARNINGS++))
fi
echo ""

# Check ArgoCD
echo -e "${BLUE}Checking ArgoCD...${NC}"
if kubectl get namespace argocd >/dev/null 2>&1; then
    echo -e "${GREEN}✓ ArgoCD namespace exists${NC}"
    
    # Check ArgoCD deployments
    ARGOCD_READY=$(kubectl get deployment -n argocd -o json | jq -r '.items[] | select(.status.readyReplicas == .status.replicas) | .metadata.name' | wc -l)
    ARGOCD_TOTAL=$(kubectl get deployment -n argocd --no-headers | wc -l)
    
    if [ "$ARGOCD_READY" -eq "$ARGOCD_TOTAL" ]; then
        echo -e "${GREEN}✓ All ArgoCD deployments are ready (${ARGOCD_READY}/${ARGOCD_TOTAL})${NC}"
    else
        echo -e "${YELLOW}⚠ Some ArgoCD deployments not ready (${ARGOCD_READY}/${ARGOCD_TOTAL})${NC}"
        ((WARNINGS++))
    fi
else
    echo -e "${RED}✗ ArgoCD namespace not found${NC}"
    ((ERRORS++))
fi
echo ""

# Check Argo Rollouts
echo -e "${BLUE}Checking Argo Rollouts...${NC}"
if kubectl get namespace argo-rollouts >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Argo Rollouts namespace exists${NC}"
    
    if kubectl get deployment argo-rollouts -n argo-rollouts >/dev/null 2>&1; then
        ROLLOUTS_READY=$(kubectl get deployment argo-rollouts -n argo-rollouts -o jsonpath='{.status.readyReplicas}')
        if [ "$ROLLOUTS_READY" -ge 1 ]; then
            echo -e "${GREEN}✓ Argo Rollouts controller is ready${NC}"
        else
            echo -e "${YELLOW}⚠ Argo Rollouts controller not ready${NC}"
            ((WARNINGS++))
        fi
    fi
else
    echo -e "${RED}✗ Argo Rollouts namespace not found${NC}"
    ((ERRORS++))
fi
echo ""

# Check Argo Events
echo -e "${BLUE}Checking Argo Events...${NC}"
if kubectl get namespace argo-events >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Argo Events namespace exists${NC}"
    
    EVENTS_READY=$(kubectl get deployment -n argo-events -o json 2>/dev/null | jq -r '.items[] | select(.status.readyReplicas == .status.replicas) | .metadata.name' | wc -l)
    EVENTS_TOTAL=$(kubectl get deployment -n argo-events --no-headers 2>/dev/null | wc -l)
    
    if [ "$EVENTS_READY" -eq "$EVENTS_TOTAL" ] && [ "$EVENTS_TOTAL" -gt 0 ]; then
        echo -e "${GREEN}✓ All Argo Events deployments are ready (${EVENTS_READY}/${EVENTS_TOTAL})${NC}"
    else
        echo -e "${YELLOW}⚠ Some Argo Events deployments not ready (${EVENTS_READY}/${EVENTS_TOTAL})${NC}"
        ((WARNINGS++))
    fi
else
    echo -e "${RED}✗ Argo Events namespace not found${NC}"
    ((ERRORS++))
fi
echo ""

# Check Ingress Controller
echo -e "${BLUE}Checking Ingress Controller...${NC}"
if kubectl get namespace ingress-nginx >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Ingress NGINX namespace exists${NC}"
    
    INGRESS_READY=$(kubectl get deployment ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
    if [ "$INGRESS_READY" -ge 1 ]; then
        echo -e "${GREEN}✓ Ingress controller is ready${NC}"
    else
        echo -e "${YELLOW}⚠ Ingress controller not ready${NC}"
        ((WARNINGS++))
    fi
else
    echo -e "${RED}✗ Ingress NGINX namespace not found${NC}"
    ((ERRORS++))
fi
echo ""

# Check ArgoCD Applications
echo -e "${BLUE}Checking ArgoCD Applications...${NC}"
if kubectl get applications -n argocd >/dev/null 2>&1; then
    APP_COUNT=$(kubectl get applications -n argocd --no-headers 2>/dev/null | wc -l)
    if [ "$APP_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✓ Found ${APP_COUNT} ArgoCD application(s)${NC}"
        kubectl get applications -n argocd -o custom-columns=NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status 2>/dev/null || true
    else
        echo -e "${YELLOW}⚠ No ArgoCD applications found${NC}"
        ((WARNINGS++))
    fi
else
    echo -e "${YELLOW}⚠ Cannot check ArgoCD applications${NC}"
    ((WARNINGS++))
fi
echo ""

# Check staging namespace
echo -e "${BLUE}Checking staging environment...${NC}"
if kubectl get namespace staging >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Staging namespace exists${NC}"
    
    STAGING_PODS=$(kubectl get pods -n staging --no-headers 2>/dev/null | wc -l)
    if [ "$STAGING_PODS" -gt 0 ]; then
        echo -e "${GREEN}✓ Found ${STAGING_PODS} pod(s) in staging${NC}"
    else
        echo -e "${YELLOW}⚠ No pods in staging namespace${NC}"
        ((WARNINGS++))
    fi
else
    echo -e "${YELLOW}⚠ Staging namespace not found (will be created by ArgoCD)${NC}"
    ((WARNINGS++))
fi
echo ""

# Check production namespace
echo -e "${BLUE}Checking production environment...${NC}"
if kubectl get namespace production >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Production namespace exists${NC}"
    
    PROD_PODS=$(kubectl get pods -n production --no-headers 2>/dev/null | wc -l)
    if [ "$PROD_PODS" -gt 0 ]; then
        echo -e "${GREEN}✓ Found ${PROD_PODS} pod(s) in production${NC}"
    else
        echo -e "${YELLOW}⚠ No pods in production namespace${NC}"
        ((WARNINGS++))
    fi
else
    echo -e "${YELLOW}⚠ Production namespace not found (will be created by ArgoCD)${NC}"
    ((WARNINGS++))
fi
echo ""

# Summary
echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}Validation Summary${NC}"
echo -e "${BLUE}================================================${NC}"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo -e "\n${GREEN}Platform is ready to use!${NC}\n"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ ${WARNINGS} warning(s) found${NC}"
    echo -e "\n${YELLOW}Platform is mostly ready, but some components may still be initializing${NC}\n"
    exit 0
else
    echo -e "${RED}✗ ${ERRORS} error(s) found${NC}"
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}⚠ ${WARNINGS} warning(s) found${NC}"
    fi
    echo -e "\n${RED}Platform setup is incomplete${NC}"
    echo -e "Run ${YELLOW}./scripts/setup-cluster.sh${NC} to set up the platform\n"
    exit 1
fi
