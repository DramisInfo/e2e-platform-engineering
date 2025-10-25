# Architecture Documentation

## E2E SDLC Platform Engineering Demonstration

This document provides detailed architectural diagrams and explanations for the end-to-end SDLC demonstration platform.

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Component Architecture](#component-architecture)
3. [Workflow Diagrams](#workflow-diagrams)
4. [Deployment Strategy](#deployment-strategy)
5. [Network Architecture](#network-architecture)
6. [Component Interactions](#component-interactions)

---

## System Overview

### High-Level Architecture

```mermaid
C4Context
    title System Context Diagram - E2E SDLC Platform

    Person(dev, "Developer", "Software developer creating features")
    Person(platform, "Platform Engineer", "Manages infrastructure and tooling")
    
    System_Boundary(demo, "E2E SDLC Demo Platform") {
        System(github, "GitHub Platform", "Version control, CI, and artifact registry")
        System(k8s, "Kubernetes Cluster", "Application runtime environment")
        System(gitops, "GitOps Tools", "ArgoCD, Argo Events, Argo Rollouts")
    }
    
    Rel(dev, github, "Pushes code, creates PRs")
    Rel(platform, k8s, "Manages cluster, monitors deployments")
    Rel(github, k8s, "Provides images and manifests")
    Rel(gitops, k8s, "Deploys and manages applications")
    
    UpdateLayoutConfig($c4ShapeInRow="3", $c4BoundaryInRow="1")
```

### End-to-End Data Flow

```mermaid
flowchart TD
    Start([Developer Commits Code]) --> PR[Create Pull Request]
    PR --> CIBuild[GitHub Actions: Build & Test]
    CIBuild --> |Success| Merge[Merge to Main]
    CIBuild --> |Failure| Fix[Fix Issues]
    Fix --> PR
    
    Merge --> CIProd[GitHub Actions: Build Production Images]
    CIProd --> Registry[Push to GitHub Packages]
    CIProd --> UpdateManifest[Update GitOps Manifests]
    
    UpdateManifest --> ArgoDetect[ArgoCD Detects Changes]
    ArgoDetect --> DeployStaging[Deploy to Staging]
    
    DeployStaging --> EventTrigger[Argo Events: Detect Deployment]
    EventTrigger --> RunTests[Execute Integration Tests]
    
    RunTests --> |Pass| PromoteProd[Update Production Manifests]
    RunTests --> |Fail| Alert[Alert Team]
    Alert --> Fix
    
    PromoteProd --> ArgoSync[ArgoCD Syncs Production]
    ArgoSync --> CanaryStart[Argo Rollouts: Start Canary]
    
    CanaryStart --> C20[20% Traffic to New Version]
    C20 --> |Healthy| C50[50% Traffic to New Version]
    C50 --> |Healthy| C100[100% Traffic to New Version]
    
    C20 --> |Unhealthy| Rollback[Automatic Rollback]
    C50 --> |Unhealthy| Rollback
    
    C100 --> Success([Deployment Complete])
    Rollback --> Alert
    
    style Start fill:#4caf50,color:#fff
    style Success fill:#4caf50,color:#fff
    style Alert fill:#f44336,color:#fff
    style Rollback fill:#ff9800,color:#fff
```

---

## Component Architecture

### Kubernetes Cluster Components

```mermaid
graph TB
    subgraph K3d["k3d Cluster (Local Docker)"]
        subgraph ControlPlane["Control Plane"]
            API[Kube API Server]
            Scheduler[Scheduler]
            Controller[Controller Manager]
            ETCD[etcd]
        end
        
        subgraph ArgoStack["Argo Stack"]
            ArgoCD[ArgoCD Server<br/>+ Repo Server<br/>+ Application Controller]
            ArgoRollouts[Rollouts Controller]
            ArgoEvents[Events Controller<br/>+ Event Sources<br/>+ Sensors]
        end
        
        subgraph Ingress["Ingress Layer"]
            IngressController[Traefik/NGINX]
            IngressRules[Ingress Rules]
        end
        
        subgraph StagingNS["Staging Namespace"]
            SFE[Frontend Deployment<br/>nginx/static]
            SBE[Backend Deployment<br/>REST API]
            SFESvc[Frontend Service]
            SBESvc[Backend Service]
        end
        
        subgraph ProductionNS["Production Namespace"]
            PFE[Frontend Rollout<br/>Canary Strategy]
            PBE[Backend Rollout<br/>Canary Strategy]
            PFESvc[Frontend Service]
            PBESvc[Backend Service]
        end
        
        subgraph TestNS["Test Namespace"]
            IntegrationJob[Integration Test Jobs]
            E2EJob[E2E Test Jobs]
        end
    end
    
    API --> Scheduler
    API --> Controller
    API --> ETCD
    
    ArgoCD --> API
    ArgoRollouts --> API
    ArgoEvents --> API
    
    IngressController --> IngressRules
    IngressRules --> SFESvc
    IngressRules --> SBESvc
    IngressRules --> PFESvc
    IngressRules --> PBESvc
    
    SFESvc --> SFE
    SBESvc --> SBE
    PFESvc --> PFE
    PBESvc --> PBE
    
    ArgoCD --> StagingNS
    ArgoCD --> ProductionNS
    ArgoEvents --> TestNS
    ArgoRollouts --> ProductionNS
    
    style ControlPlane fill:#e3f2fd,stroke:#1565c0
    style ArgoStack fill:#f3e5f5,stroke:#6a1b9a
    style Ingress fill:#e8f5e9,stroke:#2e7d32
    style StagingNS fill:#fff9c4,stroke:#f57f17
    style ProductionNS fill:#ffebee,stroke:#c62828
    style TestNS fill:#e0f2f1,stroke:#00695c
```

### Application Architecture

```mermaid
graph LR
    subgraph Browser["User Browser"]
        UI[Web Interface]
    end
    
    subgraph Frontend["Frontend Container"]
        React[React/Vue App]
        StaticFiles[Static Assets]
        NginxServer[Nginx Server]
    end
    
    subgraph Backend["Backend Container"]
        API[REST API Server]
        Routes[API Routes]
        Logic[Business Logic]
        Health[Health Endpoints]
    end
    
    UI --> NginxServer
    NginxServer --> React
    NginxServer --> StaticFiles
    React --> API
    API --> Routes
    Routes --> Logic
    Routes --> Health
    
    style Browser fill:#e3f2fd,stroke:#1565c0
    style Frontend fill:#fff3e0,stroke:#e65100
    style Backend fill:#e8f5e9,stroke:#2e7d32
```

---

## Workflow Diagrams

### Complete CI/CD Pipeline

```mermaid
sequenceDiagram
    autonumber
    actor Developer
    participant GitHub
    participant CI as GitHub Actions
    participant Registry as GitHub Packages
    participant ArgoCD
    participant Staging as Staging Env
    participant Events as Argo Events
    participant Tests
    participant Rollouts as Argo Rollouts
    participant Production as Production Env
    
    Developer->>GitHub: Push code to feature branch
    Developer->>GitHub: Create Pull Request
    GitHub->>CI: Trigger PR workflow
    
    activate CI
    CI->>CI: Lint code
    CI->>CI: Run unit tests
    CI->>CI: Build Docker images
    CI-->>GitHub: Update PR status
    deactivate CI
    
    Developer->>GitHub: Merge PR to main
    GitHub->>CI: Trigger main branch workflow
    
    activate CI
    CI->>CI: Build production images
    CI->>CI: Tag with commit SHA + version
    CI->>Registry: Push images
    CI->>GitHub: Update gitops/staging manifests
    deactivate CI
    
    GitHub-->>ArgoCD: Manifest change detected
    
    activate ArgoCD
    ArgoCD->>Registry: Pull new images
    ArgoCD->>Staging: Deploy updated application
    Staging-->>ArgoCD: Sync successful
    deactivate ArgoCD
    
    Staging->>Events: Deployment complete webhook
    
    activate Events
    Events->>Tests: Trigger test jobs
    deactivate Events
    
    activate Tests
    Tests->>Staging: Run API integration tests
    Tests->>Staging: Run Playwright E2E tests
    Tests->>Tests: Validate results
    Tests->>GitHub: Update gitops/production manifests
    deactivate Tests
    
    GitHub-->>ArgoCD: Production manifest change
    
    activate ArgoCD
    ArgoCD->>Rollouts: Initiate rollout
    deactivate ArgoCD
    
    activate Rollouts
    Rollouts->>Production: Deploy canary (20%)
    Rollouts->>Rollouts: Wait & health check
    Rollouts->>Production: Scale canary (50%)
    Rollouts->>Rollouts: Wait & health check
    Rollouts->>Production: Scale canary (100%)
    Rollouts->>Production: Terminate old version
    deactivate Rollouts
    
    Production-->>Developer: Deployment complete notification
```

### GitOps Sync Process

```mermaid
stateDiagram-v2
    [*] --> Idle: ArgoCD Running
    
    Idle --> Detecting: Poll Git Repository (3min interval)
    Detecting --> OutOfSync: Manifest Changes Detected
    Detecting --> Idle: No Changes
    
    OutOfSync --> Syncing: Auto-Sync Enabled
    OutOfSync --> ManualReview: Auto-Sync Disabled
    ManualReview --> Syncing: Manual Sync Triggered
    
    Syncing --> Applying: Generate Kubernetes Resources
    Applying --> Validating: Apply to Cluster
    
    Validating --> Healthy: All Resources Healthy
    Validating --> Degraded: Some Resources Unhealthy
    Validating --> Failed: Sync Failed
    
    Healthy --> Idle: Sync Complete
    Degraded --> Retry: Auto-Retry
    Failed --> Retry: Auto-Retry
    Retry --> Syncing: Retry Attempt
    Retry --> Error: Max Retries Exceeded
    
    Error --> [*]: Alert Team
    
    note right of OutOfSync
        Changes can include:
        - Image tags
        - Resource specs
        - ConfigMaps
        - Secrets
    end note
    
    note right of Healthy
        Health checks:
        - Pod status
        - Readiness probes
        - Liveness probes
    end note
```

### Argo Events Trigger Flow

```mermaid
flowchart TB
    subgraph EventSource["Event Source"]
        Webhook[ArgoCD Webhook]
        Resource[Resource Watcher]
    end
    
    subgraph EventBus["Event Bus"]
        NATS[NATS Streaming]
    end
    
    subgraph Sensor["Sensor"]
        Dependencies[Event Dependencies]
        Filters[Event Filters]
        Triggers[Trigger Templates]
    end
    
    subgraph Actions["Triggered Actions"]
        CreateJob[Create Test Job]
        UpdateManifest[Update Git Manifest]
        Notification[Send Notification]
    end
    
    Webhook --> NATS
    Resource --> NATS
    
    NATS --> Dependencies
    Dependencies --> Filters
    Filters --> |Match| Triggers
    Filters --> |No Match| Discard[Discard Event]
    
    Triggers --> CreateJob
    Triggers --> UpdateManifest
    Triggers --> Notification
    
    CreateJob --> K8sJob[Kubernetes Job]
    UpdateManifest --> GitCommit[Git Commit]
    Notification --> Slack[Slack/Email]
    
    style EventSource fill:#e1f5fe,stroke:#01579b
    style EventBus fill:#f3e5f5,stroke:#4a148c
    style Sensor fill:#e8f5e9,stroke:#1b5e20
    style Actions fill:#fff3e0,stroke:#e65100
```

---

## Deployment Strategy

### Canary Deployment Progression

```mermaid
gantt
    title Canary Deployment Timeline
    dateFormat mm:ss
    axisFormat %M:%S
    
    section Version 1.0
    100% Traffic (5 pods)    :v1_100, 00:00, 01:00
    80% Traffic (4 pods)     :v1_80, 01:00, 01:30
    50% Traffic (3 pods)     :v1_50, 01:30, 02:00
    0% Traffic (terminated)  :v1_0, 02:00, 03:00
    
    section Version 2.0
    0% Traffic              :v2_0, 00:00, 01:00
    20% Traffic (1 pod)     :v2_20, 01:00, 01:30
    50% Traffic (2 pods)    :v2_50, 01:30, 02:00
    100% Traffic (5 pods)   :v2_100, 02:00, 03:00
    
    section Health Checks
    Initial deployment      :crit, check1, 01:00, 00:05
    Pause 30s               :pause1, 01:05, 00:25
    Health check (20%)      :crit, check2, 01:30, 00:05
    Pause 30s               :pause2, 01:35, 00:25
    Health check (50%)      :crit, check3, 02:00, 00:05
    Final promotion         :check4, 02:05, 00:55
```

### Progressive Traffic Shift

```mermaid
graph TD
    Start[Start Canary Deployment] --> Deploy20[Deploy 20% Canary]
    
    Deploy20 --> Check20{Health Check}
    Check20 -->|Healthy| Wait20[Wait 30s]
    Check20 -->|Unhealthy| Rollback[Rollback to Stable]
    
    Wait20 --> Deploy50[Deploy 50% Canary]
    Deploy50 --> Check50{Health Check}
    Check50 -->|Healthy| Wait50[Wait 30s]
    Check50 -->|Unhealthy| Rollback
    
    Wait50 --> Deploy100[Deploy 100% Canary]
    Deploy100 --> Check100{Health Check}
    Check100 -->|Healthy| Cleanup[Terminate Old Version]
    Check100 -->|Unhealthy| Rollback
    
    Cleanup --> Success[Deployment Complete]
    Rollback --> Alert[Alert Team]
    
    style Start fill:#4caf50,color:#fff
    style Success fill:#4caf50,color:#fff
    style Rollback fill:#f44336,color:#fff
    style Alert fill:#ff9800,color:#fff
    style Check20 fill:#2196f3,color:#fff
    style Check50 fill:#2196f3,color:#fff
    style Check100 fill:#2196f3,color:#fff
```

### Rollback Strategy

```mermaid
stateDiagram-v2
    [*] --> Stable: v1.0 Running
    
    Stable --> Canary20: Deploy v2.0 (20%)
    Canary20 --> Canary50: Health OK
    Canary50 --> Canary100: Health OK
    Canary100 --> NewStable: Health OK
    
    Canary20 --> RollingBack: Health Failed
    Canary50 --> RollingBack: Health Failed
    Canary100 --> RollingBack: Health Failed
    
    RollingBack --> Stable: Revert to v1.0
    NewStable --> [*]: v2.0 Stable
    
    note right of RollingBack
        Rollback Actions:
        - Scale canary to 0
        - Route 100% to stable
        - Create incident
        - Notify team
    end note
    
    note right of NewStable
        v2.0 becomes new stable
        v1.0 ReplicaSets preserved
        for quick rollback if needed
    end note
```

---

## Network Architecture

### Ingress and Service Mesh

```mermaid
graph TB
    subgraph External["External Access"]
        Browser[Web Browser]
        API_Client[API Client]
    end
    
    subgraph IngressLayer["Ingress Layer (Traefik)"]
        Ingress[Ingress Controller]
        StagingRule[staging.local<br/>→ Staging Services]
        ProdRule[production.local<br/>→ Production Services]
    end
    
    subgraph StagingServices["Staging Namespace"]
        SFESvc[Frontend Service<br/>ClusterIP]
        SBESvc[Backend Service<br/>ClusterIP]
        SFE1[Frontend Pod 1]
        SFE2[Frontend Pod 2]
        SBE1[Backend Pod 1]
        SBE2[Backend Pod 2]
    end
    
    subgraph ProductionServices["Production Namespace"]
        PFESvc[Frontend Service<br/>ClusterIP]
        PBESvc[Backend Service<br/>ClusterIP]
        PFE_Stable[Frontend Stable]
        PFE_Canary[Frontend Canary]
        PBE_Stable[Backend Stable]
        PBE_Canary[Backend Canary]
    end
    
    Browser --> Ingress
    API_Client --> Ingress
    
    Ingress --> StagingRule
    Ingress --> ProdRule
    
    StagingRule --> SFESvc
    StagingRule --> SBESvc
    ProdRule --> PFESvc
    ProdRule --> PBESvc
    
    SFESvc --> SFE1
    SFESvc --> SFE2
    SBESvc --> SBE1
    SBESvc --> SBE2
    
    PFESvc -.->|80%| PFE_Stable
    PFESvc -.->|20%| PFE_Canary
    PBESvc -.->|80%| PBE_Stable
    PBESvc -.->|20%| PBE_Canary
    
    SFE1 --> SBESvc
    SFE2 --> SBESvc
    
    style External fill:#e3f2fd,stroke:#1565c0
    style IngressLayer fill:#e8f5e9,stroke:#2e7d32
    style StagingServices fill:#fff9c4,stroke:#f57f17
    style ProductionServices fill:#ffebee,stroke:#c62828
```

### Service Communication

```mermaid
sequenceDiagram
    participant User
    participant Ingress
    participant FrontendSvc
    participant Frontend
    participant BackendSvc
    participant Backend
    
    User->>Ingress: HTTPS Request<br/>production.local
    Ingress->>FrontendSvc: Route to Frontend Service
    FrontendSvc->>Frontend: Load balance to Pod
    
    activate Frontend
    Frontend->>Frontend: Serve static HTML/JS
    Frontend-->>User: Return web page
    deactivate Frontend
    
    User->>Frontend: API Request (AJAX)
    Frontend->>BackendSvc: HTTP Request<br/>backend-service:8080
    BackendSvc->>Backend: Load balance to Pod
    
    activate Backend
    Backend->>Backend: Process business logic
    Backend-->>Frontend: JSON Response
    deactivate Backend
    
    Frontend-->>User: Update UI
    
    Note over Frontend,Backend: Services use DNS:<br/>backend-service.production.svc.cluster.local
```

---

## Component Interactions

### ArgoCD Application Sync

```mermaid
flowchart LR
    subgraph Git["Git Repository"]
        Manifests[Kubernetes Manifests]
    end
    
    subgraph ArgoCD["ArgoCD Components"]
        RepoServer[Repo Server]
        AppController[Application Controller]
        APIServer[API Server]
    end
    
    subgraph K8s["Kubernetes Cluster"]
        Resources[Kubernetes Resources]
    end
    
    subgraph User["User Interface"]
        CLI[argocd CLI]
        UI[Web UI]
    end
    
    Manifests -->|1. Poll/Webhook| RepoServer
    RepoServer -->|2. Generate manifests| AppController
    AppController -->|3. Compare desired vs actual| Resources
    AppController -->|4. Apply changes| Resources
    AppController -->|5. Report status| APIServer
    
    CLI --> APIServer
    UI --> APIServer
    APIServer --> AppController
    
    style Git fill:#24292e,stroke:#58a6ff,color:#fff
    style ArgoCD fill:#f3e5f5,stroke:#6a1b9a
    style K8s fill:#e3f2fd,stroke:#1565c0
    style User fill:#e8f5e9,stroke:#2e7d32
```

### Argo Rollouts Analysis Loop

```mermaid
flowchart TD
    Start[New Rollout Detected] --> CreateRS[Create Canary ReplicaSet]
    CreateRS --> SetWeight[Set Traffic Weight: 20%]
    
    SetWeight --> AnalysisRun[Start Analysis Run]
    AnalysisRun --> CollectMetrics[Collect Metrics]
    
    CollectMetrics --> EvaluateMetrics{Metrics Healthy?}
    EvaluateMetrics -->|Yes| WaitPause[Wait Pause Duration]
    EvaluateMetrics -->|No| FailAnalysis[Analysis Failed]
    
    WaitPause --> NextStep{More Steps?}
    NextStep -->|Yes| IncreaseWeight[Increase Weight]
    NextStep -->|No| FullPromotion[Promote to 100%]
    
    IncreaseWeight --> AnalysisRun
    
    FailAnalysis --> AbortRollout[Abort Rollout]
    AbortRollout --> ScaleDownCanary[Scale Down Canary]
    ScaleDownCanary --> NotifyFailure[Notify Failure]
    
    FullPromotion --> ScaleDownStable[Scale Down Old Version]
    ScaleDownStable --> UpdateStatus[Update Rollout Status]
    UpdateStatus --> Success[Rollout Complete]
    
    style Start fill:#4caf50,color:#fff
    style Success fill:#4caf50,color:#fff
    style FailAnalysis fill:#f44336,color:#fff
    style AbortRollout fill:#f44336,color:#fff
    style EvaluateMetrics fill:#2196f3,color:#fff
```

---

## Repository Structure Visualization

```mermaid
graph TD
    Root[e2e-platform-engineering/]
    
    Root --> Docs[docs/]
    Root --> Scripts[scripts/]
    Root --> App[app/]
    Root --> GitOps[gitops/]
    Root --> Tests[tests/]
    Root --> GHA[.github/]
    
    Docs --> DocArch[architecture.md]
    Docs --> DocSetup[setup-guide.md]
    Docs --> DocWalk[walkthrough.md]
    
    Scripts --> Setup[setup-cluster.sh]
    Scripts --> InstallArgoCD[install-argocd.sh]
    Scripts --> InstallRollouts[install-argo-rollouts.sh]
    Scripts --> Cleanup[cleanup.sh]
    
    App --> Frontend[frontend/]
    App --> Backend[backend/]
    
    Frontend --> FESrc[src/]
    Frontend --> FEDocker[Dockerfile]
    Backend --> BESrc[src/]
    Backend --> BEDocker[Dockerfile]
    
    GitOps --> ArgoApps[argocd/]
    GitOps --> Staging[staging/]
    GitOps --> Production[production/]
    GitOps --> Events[argo-events/]
    
    Staging --> SKust[kustomization.yaml]
    Staging --> SFE[frontend-deployment.yaml]
    Staging --> SBE[backend-deployment.yaml]
    
    Production --> PKust[kustomization.yaml]
    Production --> PFE[frontend-rollout.yaml]
    Production --> PBE[backend-rollout.yaml]
    
    Tests --> Integration[integration/]
    Tests --> E2E[e2e/]
    
    GHA --> Workflows[workflows/]
    Workflows --> CIFE[ci-frontend.yaml]
    Workflows --> CIBE[ci-backend.yaml]
    
    style Root fill:#24292e,stroke:#58a6ff,color:#fff
    style App fill:#0969da,stroke:#54aeff,color:#fff
    style GitOps fill:#8250df,stroke:#a371f7,color:#fff
    style Tests fill:#bf3989,stroke:#d2a8ff,color:#fff
    style Scripts fill:#1f6feb,stroke:#58a6ff,color:#fff
```

---

## Technology Integration Map

```mermaid
mindmap
    root((E2E SDLC<br/>Platform))
        Version Control
            GitHub
                Repository
                Pull Requests
                Branch Protection
        CI Pipeline
            GitHub Actions
                Build Workflows
                Test Workflows
                Image Publishing
                Manifest Updates
        Artifact Storage
            GitHub Packages
                Container Registry
                Image Versioning
                Access Control
        Infrastructure
            k3d
                Lightweight K8s
                Docker-based
                Local Development
            Kubernetes
                Pods
                Services
                Ingress
                Namespaces
        GitOps
            ArgoCD
                Git Sync
                Auto Deployment
                Health Monitoring
                UI Dashboard
        Progressive Delivery
            Argo Rollouts
                Canary Strategy
                Traffic Management
                Auto Rollback
                Analysis
        Event Automation
            Argo Events
                Event Sources
                Sensors
                Triggers
                Webhooks
        Testing
            Integration Tests
                REST API Tests
                Smoke Tests
            E2E Tests
                Playwright
                Browser Automation
                User Flows
        Configuration
            Kustomize
                Overlays
                Patches
                Environment Config
```

---

## Summary

This architecture demonstrates a modern, cloud-native approach to software delivery with:

- **Full Automation**: From commit to production deployment
- **GitOps Principles**: Git as single source of truth
- **Progressive Delivery**: Risk-mitigated releases via canary deployments
- **Event-Driven Testing**: Automated quality gates
- **Local Development**: No cloud costs, fast iteration
- **Production Practices**: Real-world patterns and tools

The architecture is designed to be:
- **Educational**: Clear separation of concerns
- **Extensible**: Easy to add monitoring, security scanning, etc.
- **Reproducible**: Fully scripted setup
- **Representative**: Uses industry-standard tools and patterns
