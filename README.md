# E2E SDLC Platform Engineering Demonstration

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform: Kubernetes](https://img.shields.io/badge/Platform-Kubernetes-blue.svg)](https://kubernetes.io/)
[![GitOps: ArgoCD](https://img.shields.io/badge/GitOps-ArgoCD-orange.svg)](https://argoproj.github.io/cd/)

A comprehensive end-to-end Software Development Lifecycle (SDLC) demonstration showcasing modern platform engineering practices using GitOps, progressive delivery, and automated testing.

## 🎯 Overview

This project demonstrates a complete, production-ready CI/CD pipeline with:

- **GitOps**: Declarative deployment with ArgoCD
- **Progressive Delivery**: Canary deployments with Argo Rollouts
- **Event-Driven Automation**: Automated testing with Argo Events
- **Modern Stack**: Kubernetes, Docker, GitHub Actions
- **Local Development**: Fully functional on k3d (no cloud costs!)

## 🏗️ Architecture

```
┌─────────────┐     ┌──────────────┐     ┌─────────────────┐
│   GitHub    │────▶│ GitHub       │────▶│  Kubernetes     │
│ Repository  │     │ Actions CI   │     │  (k3d cluster)  │
└─────────────┘     └──────────────┘     └─────────────────┘
                            │                      │
                            ▼                      ▼
                    ┌──────────────┐      ┌─────────────────┐
                    │   GitHub     │      │    ArgoCD       │
                    │  Packages    │◀─────│  (GitOps CD)    │
                    └──────────────┘      └─────────────────┘
                                                   │
                    ┌──────────────────────────────┴────────┐
                    │                                       │
                    ▼                                       ▼
            ┌──────────────┐                      ┌──────────────┐
            │   Staging    │                      │  Production  │
            │ Environment  │                      │ Environment  │
            └──────────────┘                      └──────────────┘
                    │                                       │
                    ▼                                       ▼
            ┌──────────────┐                      ┌──────────────┐
            │ Argo Events  │                      │Argo Rollouts │
            │(Auto Tests)  │                      │  (Canary)    │
            └──────────────┘                      └──────────────┘
```

For detailed architecture diagrams, see [docs/architecture.md](docs/architecture.md).

## ✨ Features

### CI/CD Pipeline
- ✅ Automated builds on every PR
- ✅ Unit and integration testing
- ✅ Container image building and publishing
- ✅ Automatic GitOps manifest updates
- ✅ Staging deployment on merge

### GitOps Deployment
- ✅ ArgoCD for declarative deployments
- ✅ Automatic synchronization
- ✅ Health monitoring
- ✅ Easy rollback capabilities

### Progressive Delivery
- ✅ Canary deployment strategy (20% → 50% → 100%)
- ✅ Automatic health checks
- ✅ Automatic rollback on failure
- ✅ Zero-downtime deployments

### Automated Testing
- ✅ REST API integration tests
- ✅ Playwright E2E tests
- ✅ Event-driven test execution
- ✅ Automated promotion to production

## 🚀 Quick Start

### Prerequisites

Required tools:
- [Docker](https://docs.docker.com/get-docker/) (v20.10+)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) (v1.24+)
- [k3d](https://k3d.io/#installation) (v5.0+)
- [Git](https://git-scm.com/downloads)

Optional but recommended:
- [k9s](https://k9scli.io/) - Terminal UI for Kubernetes
- [jq](https://stedolan.github.io/jq/) - JSON processor

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/DramisInfo/e2e-platform-engineering.git
   cd e2e-platform-engineering
   ```

2. **Check prerequisites**
   ```bash
   ./scripts/helpers/check-prerequisites.sh
   ```

3. **Set up the cluster** (one command!)
   ```bash
   ./scripts/setup-cluster.sh
   ```

   This script will:
   - Create a k3d Kubernetes cluster
   - Install NGINX Ingress Controller
   - Install ArgoCD
   - Install Argo Rollouts
   - Install Argo Events
   - Deploy the applications
   - Configure automated testing

   Setup time: ~10-15 minutes

4. **Validate the setup**
   ```bash
   ./scripts/validate.sh
   ```

### Accessing the Platform

#### ArgoCD UI
```bash
# Port-forward ArgoCD server
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Open in browser
open https://localhost:8080
```

#### Applications

Add to `/etc/hosts`:
```
127.0.0.1 staging.local production.local
```

Then access:
- **Staging**: http://staging.local:8080
- **Production**: http://production.local:8080

## 📖 Documentation

- **[Architecture Guide](docs/architecture.md)** - Detailed system architecture with diagrams
- **[Setup Guide](docs/setup-guide.md)** - Step-by-step installation and configuration
- **[Walkthrough](docs/walkthrough.md)** - Complete demo workflow
- **[Troubleshooting](docs/troubleshooting.md)** - Common issues and solutions
- **[PRD](prd-files/e2e-sdlc-platform-demo.md)** - Product Requirements Document

## 🔄 Workflow

### Developer Workflow

1. **Create a feature branch**
   ```bash
   git checkout -b feature/my-feature
   ```

2. **Make changes** to `app/backend` or `app/frontend`

3. **Create Pull Request**
   - GitHub Actions runs tests and builds
   - PR checks must pass before merge

4. **Merge to main**
   - Images built and pushed to GitHub Packages
   - GitOps manifests automatically updated
   - ArgoCD deploys to staging

5. **Automated testing**
   - Argo Events detects staging deployment
   - Integration tests run automatically
   - E2E tests execute

6. **Production deployment**
   - Tests pass → Production manifests updated
   - Argo Rollouts performs canary deployment
   - 20% → 50% → 100% traffic shift
   - Automatic rollback if unhealthy

## 🛠️ Project Structure

```
e2e-platform-engineering/
├── app/
│   ├── backend/          # Node.js REST API
│   │   ├── src/
│   │   ├── __tests__/
│   │   ├── Dockerfile
│   │   └── package.json
│   └── frontend/         # Web interface
│       ├── src/
│       ├── public/
│       ├── Dockerfile
│       └── package.json
├── gitops/
│   ├── argocd/          # ArgoCD Application definitions
│   ├── staging/         # Staging environment manifests
│   ├── production/      # Production environment manifests (with Rollouts)
│   └── argo-events/     # Event automation configuration
├── tests/
│   ├── integration/     # REST API integration tests
│   └── e2e/            # Playwright E2E tests
├── scripts/
│   ├── setup-cluster.sh        # Main setup script
│   ├── cleanup.sh              # Cluster teardown
│   ├── validate.sh             # Validation script
│   ├── install-argocd.sh       # ArgoCD installation
│   ├── install-argo-rollouts.sh
│   ├── install-argo-events.sh
│   └── helpers/
│       └── check-prerequisites.sh
├── docs/
│   ├── architecture.md
│   ├── setup-guide.md
│   ├── walkthrough.md
│   └── troubleshooting.md
└── .github/
    └── workflows/       # CI/CD pipelines
        ├── ci-backend.yaml
        └── ci-frontend.yaml
```

## 🧪 Testing

### Run Backend Tests Locally
```bash
cd app/backend
npm install
npm test
```

### Run Integration Tests
```bash
cd tests/integration
npm install
API_URL=http://localhost:8080 npm run test:integration
```

### Run E2E Tests
```bash
cd tests/e2e
npm install
BASE_URL=http://localhost npm test
```

## 📊 Monitoring

### View ArgoCD Applications
```bash
kubectl get applications -n argocd
```

### Watch Rollouts
```bash
kubectl get rollouts -n production --watch
```

### View Logs
```bash
# Staging
kubectl logs -n staging -l app=backend -f

# Production
kubectl logs -n production -l app=backend -f
```

### Check Argo Events
```bash
kubectl get sensors -n argo-events
kubectl get eventsources -n argo-events
```

## 🔧 Common Operations

### Trigger a Deployment
```bash
# Update image tag in staging
kubectl set image deployment/backend backend=ghcr.io/dramisinfo/e2e-platform-engineering/backend:new-tag -n staging
```

### Manual Rollback
```bash
# Rollback a rollout
kubectl argo rollouts undo backend -n production
```

### Restart a Deployment
```bash
kubectl rollout restart deployment/backend -n staging
```

### View ArgoCD Sync Status
```bash
argocd app list
argocd app get staging
```

## 🧹 Cleanup

To remove everything:
```bash
./scripts/cleanup.sh
```

This will delete the k3d cluster and all resources.

## 🤝 Contributing

This is a demonstration project, but contributions are welcome!

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

Built with these amazing open-source tools:
- [Kubernetes](https://kubernetes.io/)
- [k3d](https://k3d.io/)
- [ArgoCD](https://argoproj.github.io/cd/)
- [Argo Rollouts](https://argoproj.github.io/rollouts/)
- [Argo Events](https://argoproj.github.io/events/)
- [GitHub Actions](https://github.com/features/actions)
- [Node.js](https://nodejs.org/)
- [Playwright](https://playwright.dev/)

## 📚 Learn More

- [GitOps Principles](https://opengitops.dev/)
- [Canary Deployments](https://martinfowler.com/bliki/CanaryRelease.html)
- [Platform Engineering](https://platformengineering.org/)

---

**Made with ❤️ by the Platform Engineering Team**
