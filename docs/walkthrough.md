# Demo Walkthrough

This guide walks you through the complete E2E SDLC demonstration, from code change to production deployment.

## Overview

You'll learn how to:
1. Make code changes to the application
2. See CI/CD pipeline in action
3. Watch GitOps deployment to staging
4. See automated testing execute
5. Observe canary deployment to production

**Time required:** ~30 minutes

## Prerequisites

- Completed setup from [Setup Guide](setup-guide.md)
- Cluster is running and validated
- ArgoCD UI is accessible

## Part 1: Understanding the Current State

### 1.1 View ArgoCD Applications

Open ArgoCD UI at https://localhost:8080

You should see two applications:
- **staging**: Synced to gitops/staging
- **production**: Synced to gitops/production

### 1.2 Check Current Application Version

Access the applications:
- Staging: http://staging.local:8080
- Production: http://production.local:8080

Note the version badge at the top (e.g., "v1.0.0" and commit SHA).

### 1.3 Explore Kubernetes Resources

```bash
# View staging resources
kubectl get all -n staging

# View production rollouts
kubectl get rollouts -n production
kubectl argo rollouts get rollout backend -n production
```

## Part 2: Make a Code Change

### 2.1 Create a Feature Branch

```bash
git checkout -b feature/update-version
```

### 2.2 Modify the Backend

Edit `app/backend/package.json` and update the version:

```json
{
  "name": "e2e-backend",
  "version": "2.0.0",  // Changed from 1.0.0
  ...
}
```

### 2.3 Add a New API Endpoint (Optional)

Edit `app/backend/src/index.js` and add:

```javascript
// Add after existing endpoints
app.get('/api/status', (req, res) => {
  res.json({
    status: 'operational',
    version: VERSION,
    message: 'System is running smoothly!'
  });
});
```

### 2.4 Update Tests

Edit `app/backend/__tests__/api.test.js` and add:

```javascript
it('should return status information', async () => {
  const response = await request(app).get('/api/status');
  expect(response.status).toBe(200);
  expect(response.body.status).toBe('operational');
  expect(response.body).toHaveProperty('version');
});
```

### 2.5 Test Locally

```bash
cd app/backend
npm install
npm test
npm start  # Test manually at http://localhost:8080
```

## Part 3: Create Pull Request

### 3.1 Commit Changes

```bash
git add .
git commit -m "Update backend version to 2.0.0 and add status endpoint"
```

### 3.2 Push to GitHub

```bash
git push origin feature/update-version
```

### 3.3 Create Pull Request

1. Go to GitHub repository
2. Click "New Pull Request"
3. Select `feature/update-version` → `main`
4. Create the PR

### 3.4 Watch CI Pipeline

The CI pipeline will:
- Install dependencies
- Run linter
- Run unit tests
- Build Docker image (on PR)

Check the "Actions" tab to see progress.

## Part 4: Merge and Deploy to Staging

### 4.1 Merge Pull Request

Once CI passes:
1. Approve the PR (if required)
2. Click "Merge pull request"
3. Confirm the merge

### 4.2 Watch Main Branch CI

The main branch workflow will:
- Build production Docker images
- Tag with commit SHA
- Push to GitHub Packages
- Update staging GitOps manifests
- Commit changes back to repo

### 4.3 Observe ArgoCD Sync

```bash
# Watch ArgoCD sync status
watch kubectl get applications -n argocd

# Or in ArgoCD UI, watch the "staging" application
```

ArgoCD detects the manifest changes and syncs automatically:
1. Pulls new container images
2. Updates deployments
3. Monitors health status

### 4.4 Verify Staging Deployment

```bash
# Check pods are updated
kubectl get pods -n staging

# Check version
curl http://staging.local:8080/version

# Test new endpoint
curl http://staging.local:8080/api/status
```

Visit http://staging.local:8080 and verify the version badge shows the new version.

## Part 5: Automated Testing

### 5.1 Watch Argo Events Trigger

Argo Events detects the staging deployment and triggers tests:

```bash
# Watch for test jobs
kubectl get jobs -n staging --watch

# View sensor status
kubectl get sensors -n argo-events
```

### 5.2 Check Test Execution

```bash
# Find the test job
TEST_JOB=$(kubectl get jobs -n staging -l app=integration-tests --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1].metadata.name}')

# View test logs
kubectl logs job/$TEST_JOB -n staging
```

You should see:
- ✓ Health checks passing
- ✓ API endpoint tests passing
- ✓ New status endpoint test passing

### 5.3 E2E Tests (If Configured)

E2E tests run in a separate job:

```bash
# Find E2E test job
E2E_JOB=$(kubectl get jobs -n staging -l app=e2e-tests --sort-by=.metadata.creationTimestamp -o jsonpath='{.items[-1].metadata.name}')

# View E2E test logs
kubectl logs job/$E2E_JOB -n staging
```

## Part 6: Production Canary Deployment

### 6.1 Trigger Production Update

When tests pass, the test job (or automation) updates production manifests:

```bash
# Manually update production (simulating automation)
sed -i "s|image: ghcr.io/dramisinfo/e2e-platform-engineering/backend:.*|image: ghcr.io/dramisinfo/e2e-platform-engineering/backend:main-$(git rev-parse HEAD)|g" gitops/production/backend-rollout.yaml

git add gitops/production/backend-rollout.yaml
git commit -m "Promote backend to production"
git push
```

### 6.2 Watch Canary Rollout

```bash
# Watch rollout progress
kubectl argo rollouts get rollout backend -n production --watch

# Or use kubectl
kubectl get rollouts -n production --watch
```

You'll see the canary deployment progress:
1. **Step 1**: 20% traffic to new version (pause 30s)
2. **Step 2**: 50% traffic to new version (pause 30s)
3. **Step 3**: 100% traffic to new version
4. **Cleanup**: Old version terminated

### 6.3 Monitor in Real-Time

Open multiple terminals:

**Terminal 1**: Watch rollout
```bash
kubectl argo rollouts get rollout backend -n production --watch
```

**Terminal 2**: Watch pods
```bash
kubectl get pods -n production --watch
```

**Terminal 3**: Test application
```bash
while true; do
  curl -s http://production.local:8080/version | jq '.version'
  sleep 2
done
```

### 6.4 Observe Traffic Shifting

During the canary deployment:
- Requests are gradually shifted to the new version
- Both versions run simultaneously
- Health checks occur at each step
- Automatic rollback if health checks fail

## Part 7: Verification

### 7.1 Check Final State

```bash
# Verify all pods are running new version
kubectl get pods -n production -o custom-columns=NAME:.metadata.name,IMAGE:.spec.containers[0].image

# Check rollout status
kubectl argo rollouts status backend -n production
```

### 7.2 Test Production

Visit http://production.local:8080

- Verify version badge shows v2.0.0
- Test the new `/api/status` endpoint
- Verify all functionality works

### 7.3 Review ArgoCD

In ArgoCD UI:
- Both applications should show "Synced" and "Healthy"
- Review sync history
- Check resource tree

## Part 8: Rollback Demonstration (Optional)

### 8.1 Introduce a Breaking Change

Make a change that will fail health checks:

Edit `app/backend/src/index.js`:
```javascript
// Comment out health endpoint to simulate failure
// app.get('/health', (req, res) => { ... });
```

### 8.2 Push and Deploy

Follow the same process as before.

### 8.3 Watch Automatic Rollback

The canary deployment will:
1. Deploy 20% canary
2. Detect health check failures
3. Automatically rollback to stable version
4. Alert in ArgoCD

```bash
kubectl argo rollouts get rollout backend -n production --watch
```

You'll see the rollout abort and revert.

### 8.4 Cleanup

Revert the breaking change and redeploy.

## Key Takeaways

✅ **GitOps**: All changes tracked in Git, declarative state

✅ **Automation**: No manual intervention needed

✅ **Safety**: Automated tests and canary deployments reduce risk

✅ **Visibility**: ArgoCD provides clear deployment status

✅ **Rollback**: Automatic failure detection and rollback

✅ **Speed**: From code commit to production in minutes

## Advanced Scenarios

### Manual Approval Gates

Add manual approval before production:

```yaml
# In rollout spec
strategy:
  canary:
    steps:
    - setWeight: 20
    - pause: {}  # Manual approval required
```

### Blue-Green Deployment

Switch to blue-green strategy:

```yaml
strategy:
  blueGreen:
    activeService: backend-service
    previewService: backend-preview-service
```

### Analysis and Metrics

Add Prometheus metrics analysis:

```yaml
strategy:
  canary:
    analysis:
      templates:
      - templateName: success-rate
```

## Next Steps

- Explore [Troubleshooting Guide](troubleshooting.md)
- Review [Architecture Documentation](architecture.md)
- Customize the pipeline for your needs
- Add more complex scenarios

## Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Argo Rollouts Concepts](https://argoproj.github.io/argo-rollouts/concepts/)
- [GitOps Principles](https://opengitops.dev/)
