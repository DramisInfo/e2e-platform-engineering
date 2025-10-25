#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}E2E SDLC Platform Engineering - Prerequisites Check${NC}"
echo -e "${BLUE}================================================${NC}\n"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check version
check_version() {
    local cmd=$1
    local min_version=$2
    local current_version=$3
    
    echo -e "${YELLOW}Checking $cmd version...${NC}"
    echo -e "  Current: $current_version"
    echo -e "  Required: >= $min_version"
}

ERRORS=0
WARNINGS=0

# Check Docker
echo -e "${BLUE}Checking Docker...${NC}"
if command_exists docker; then
    DOCKER_VERSION=$(docker --version | awk '{print $3}' | sed 's/,//')
    echo -e "${GREEN}✓ Docker found: $DOCKER_VERSION${NC}"
    
    # Check if Docker daemon is running
    if docker info >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Docker daemon is running${NC}"
    else
        echo -e "${RED}✗ Docker daemon is not running${NC}"
        echo -e "  Please start Docker and try again"
        ((ERRORS++))
    fi
else
    echo -e "${RED}✗ Docker not found${NC}"
    echo -e "  Please install Docker: https://docs.docker.com/get-docker/"
    ((ERRORS++))
fi
echo ""

# Check kubectl
echo -e "${BLUE}Checking kubectl...${NC}"
if command_exists kubectl; then
    KUBECTL_VERSION=$(kubectl version --client --short 2>/dev/null | awk '{print $3}' || echo "unknown")
    echo -e "${GREEN}✓ kubectl found: $KUBECTL_VERSION${NC}"
else
    echo -e "${RED}✗ kubectl not found${NC}"
    echo -e "  Please install kubectl: https://kubernetes.io/docs/tasks/tools/"
    ((ERRORS++))
fi
echo ""

# Check k3d
echo -e "${BLUE}Checking k3d...${NC}"
if command_exists k3d; then
    K3D_VERSION=$(k3d version | grep k3d | awk '{print $3}')
    echo -e "${GREEN}✓ k3d found: $K3D_VERSION${NC}"
else
    echo -e "${RED}✗ k3d not found${NC}"
    echo -e "  Please install k3d: https://k3d.io/#installation"
    echo -e "  Quick install: wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash"
    ((ERRORS++))
fi
echo ""

# Check git
echo -e "${BLUE}Checking git...${NC}"
if command_exists git; then
    GIT_VERSION=$(git --version | awk '{print $3}')
    echo -e "${GREEN}✓ git found: $GIT_VERSION${NC}"
else
    echo -e "${RED}✗ git not found${NC}"
    echo -e "  Please install git: https://git-scm.com/downloads"
    ((ERRORS++))
fi
echo ""

# Check jq
echo -e "${BLUE}Checking jq...${NC}"
if command_exists jq; then
    JQ_VERSION=$(jq --version | sed 's/jq-//')
    echo -e "${GREEN}✓ jq found: $JQ_VERSION${NC}"
else
    echo -e "${YELLOW}⚠ jq not found (recommended)${NC}"
    echo -e "  Install jq for better script output: https://stedolan.github.io/jq/download/"
    ((WARNINGS++))
fi
echo ""

# Check available disk space
echo -e "${BLUE}Checking disk space...${NC}"
AVAILABLE_SPACE=$(df -h . | awk 'NR==2 {print $4}')
echo -e "  Available: $AVAILABLE_SPACE"
echo -e "${GREEN}✓ Disk space check complete${NC}"
echo ""

# Check available memory
echo -e "${BLUE}Checking available memory...${NC}"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    AVAILABLE_MEM=$(free -h | awk 'NR==2 {print $7}')
    echo -e "  Available: $AVAILABLE_MEM"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    AVAILABLE_MEM=$(vm_stat | grep "Pages free" | awk '{print $3}' | sed 's/\.//')
    AVAILABLE_MEM_GB=$((AVAILABLE_MEM * 4096 / 1024 / 1024 / 1024))
    echo -e "  Available: ~${AVAILABLE_MEM_GB}GB"
fi
echo -e "${GREEN}✓ Memory check complete${NC}"
echo ""

# Optional tools
echo -e "${BLUE}Checking optional tools...${NC}"

if command_exists helm; then
    HELM_VERSION=$(helm version --short 2>/dev/null | awk '{print $1}' || echo "unknown")
    echo -e "${GREEN}✓ helm found: $HELM_VERSION${NC}"
else
    echo -e "${YELLOW}⚠ helm not found (optional)${NC}"
    ((WARNINGS++))
fi

if command_exists k9s; then
    echo -e "${GREEN}✓ k9s found${NC}"
else
    echo -e "${YELLOW}⚠ k9s not found (optional, but recommended for cluster management)${NC}"
    echo -e "  Install: https://k9scli.io/topics/install/"
    ((WARNINGS++))
fi
echo ""

# Summary
echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}Summary${NC}"
echo -e "${BLUE}================================================${NC}"

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ All required prerequisites are met!${NC}"
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}⚠ $WARNINGS optional tool(s) missing${NC}"
    fi
    echo -e "\n${GREEN}You can proceed with the setup:${NC}"
    echo -e "  ${BLUE}./scripts/setup-cluster.sh${NC}\n"
    exit 0
else
    echo -e "${RED}✗ $ERRORS required prerequisite(s) missing${NC}"
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}⚠ $WARNINGS optional tool(s) missing${NC}"
    fi
    echo -e "\n${RED}Please install missing prerequisites and try again${NC}\n"
    exit 1
fi
