# Troubleshooting Guide

This guide helps you resolve common issues when setting up and running the E2E SDLC Platform demonstration.

## Table of Contents

- [Prerequisites Issues](#prerequisites-issues)
- [Cluster Setup Issues](#cluster-setup-issues)
- [ArgoCD Issues](#argocd-issues)
- [Application Deployment Issues](#application-deployment-issues)
- [Network and Access Issues](#network-and-access-issues)
- [CI/CD Pipeline Issues](#cicd-pipeline-issues)
- [Performance Issues](#performance-issues)

---

## Prerequisites Issues

### Docker Daemon Not Running

**Symptom**: Error when running setup script: "Cannot connect to Docker daemon"

**Solution**:
```bash
# Start Docker daemon
# On Linux
sudo systemctl start docker

# On macOS
# Start Docker Desktop application

# Verify
docker ps
```

### kubectl Not Finding Cluster

**Symptom**: `kubectl` commands fail with "connection refused"

**Solution**:
```bash
# Check current context
kubectl config current-context

# Should be: k3d-e2e-sdlc-demo
# If not, set it:
kubectl config use-context k3d-e2e-sdlc-demo

# Verify connection
kubectl get nodes
```

### k3d Installation Issues

**Symptom**: `k3d: command not found`

**Solution**:
```bash
# Install k3d
wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Or with curl
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Verify
k3d version
```

---

## Cluster Setup Issues

### Cluster Creation Fails

**Symptom**: `k3d cluster create` fails

**Common Causes**:
1. Port 8080 or 8443 already in use
2. Insufficient system resources
3. Previous cluster not cleaned up

**Solution**:

```bash
# Check for existing clusters
k3d cluster list

# Delete if exists
k3d cluster delete e2e-sdlc-demo

# Check ports
lsof -i :8080
lsof -i :8443

# Kill processes using these ports if needed
# Then retry cluster creation
./scripts/setup-cluster.sh
```

### Cluster Nodes Not Ready

**Symptom**: Nodes show "NotReady" status

**Diagnosis**:
```bash
kubectl get nodes
kubectl describe node <node-name>
```

**Solution**:
```bash
# Usually resolves itself, wait 1-2 minutes
# If not, recreate cluster
k3d cluster delete e2e-sdlc-demo
./scripts/setup-cluster.sh
```

### Out of Memory/Disk Space

**Symptom**: Pods stuck in "Pending" or "CrashLoopBackOff"

**Diagnosis**:
```bash
# Check node resources
kubectl top nodes
kubectl describe nodes

# Check available disk space
df -h
```

**Solution**:
- Free up disk space
- Increase Docker resource limits
- Reduce replica counts in manifests

---

## ArgoCD Issues

### ArgoCD Pods Not Starting

**Symptom**: ArgoCD pods in CrashLoopBackOff or Pending

**Diagnosis**:
```bash
kubectl get pods -n argocd
kubectl describe pod <pod-name> -n argocd
kubectl logs <pod-name> -n argocd
```

**Solution**:
```bash
# Restart ArgoCD
kubectl rollout restart deployment -n argocd

# If that doesn't work, reinstall
kubectl delete namespace argocd
./scripts/install-argocd.sh
```

### Can't Access ArgoCD UI

**Symptom**: Port-forward works but UI doesn't load

**Diagnosis**:
```bash
# Check if service exists
kubectl get svc -n argocd argocd-server

# Check if pods are ready
kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server
```

**Solution**:
```bash
# Ensure port-forward is running
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Try a different port
kubectl port-forward svc/argocd-server -n argocd 8081:443

# Access https://localhost:8081
```

### ArgoCD Login Fails

**Symptom**: Invalid username or password

**Solution**:
```bash
# Get correct password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
echo

# Username is always: admin
```

### Applications Not Syncing

**Symptom**: ArgoCD applications stuck "OutOfSync"

**Diagnosis**:
```bash
# Check application status
kubectl get applications -n argocd
kubectl describe application staging -n argocd
```

**Solution**:
```bash
# Manual sync
kubectl patch application staging -n argocd \
  --type merge \
  -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}'

# Or use ArgoCD UI: click "Sync" button

# Check for errors in ArgoCD logs
kubectl logs -n argocd deployment/argocd-application-controller
```

---

## Application Deployment Issues

### Images Can't Be Pulled

**Symptom**: Pods show `ImagePullBackOff`

**Diagnosis**:
```bash
kubectl describe pod <pod-name> -n staging
```

**Solution**:

If images don't exist yet (first time setup):
```bash
# Images need to be built by CI first
# Or use placeholder images temporarily:
# Edit gitops/*/deployment.yaml to use:
image: nginx:alpine  # For frontend
image: node:18-alpine  # For backend (won't work properly)
```

For GitHub Packages authentication:
```bash
# Create image pull secret
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=<github-username> \
  --docker-password=<github-token> \
  -n staging

# Add to deployment:
spec:
  imagePullSecrets:
  - name: ghcr-secret
```

### Pods Crashing

**Symptom**: Pods in `CrashLoopBackOff`

**Diagnosis**:
```bash
kubectl get pods -n staging
kubectl logs <pod-name> -n staging
kubectl describe pod <pod-name> -n staging
```

**Common Causes**:
1. Application errors
2. Missing environment variables
3. Port conflicts
4. Resource limits too low

**Solution**:
```bash
# Check logs for errors
kubectl logs <pod-name> -n staging --previous

# Increase resources if needed
kubectl edit deployment backend -n staging
# Update resources section

# Check environment variables
kubectl get deployment backend -n staging -o yaml | grep -A 10 env:
```

### Rollouts Stuck

**Symptom**: Argo Rollout not progressing

**Diagnosis**:
```bash
kubectl argo rollouts get rollout backend -n production
kubectl argo rollouts status backend -n production
```

**Solution**:
```bash
# Check health probes
kubectl describe rollout backend -n production

# Promote manually if needed
kubectl argo rollouts promote backend -n production

# Abort and rollback
kubectl argo rollouts abort backend -n production
kubectl argo rollouts undo backend -n production
```

---

## Network and Access Issues

### Can't Access Applications

**Symptom**: `staging.local` or `production.local` not resolving

**Solution**:

1. **Check /etc/hosts**:
```bash
# Linux/macOS
cat /etc/hosts | grep local

# Should contain:
# 127.0.0.1 staging.local production.local

# Add if missing:
sudo sh -c 'echo "127.0.0.1 staging.local production.local" >> /etc/hosts'
```

2. **Check Ingress**:
```bash
kubectl get ingress -A
kubectl describe ingress staging-ingress -n staging
```

3. **Check Ingress Controller**:
```bash
kubectl get pods -n ingress-nginx
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller
```

### Services Not Accessible

**Symptom**: 503 Service Unavailable

**Diagnosis**:
```bash
# Check if services exist
kubectl get svc -n staging

# Check endpoints
kubectl get endpoints -n staging

# Check pods
kubectl get pods -n staging -o wide
```

**Solution**:
```bash
# Ensure pods are running
kubectl get pods -n staging

# Check service selectors match pod labels
kubectl get svc backend-service -n staging -o yaml
kubectl get pods -n staging --show-labels

# Test service internally
kubectl run -it --rm debug --image=alpine --restart=Never -- sh
# apk add curl
# curl http://backend-service.staging:8080/health
```

---

## CI/CD Pipeline Issues

### GitHub Actions Failing

**Symptom**: CI workflow fails in GitHub Actions

**Common Issues**:

1. **Tests Failing**:
```bash
# Run tests locally first
cd app/backend
npm install
npm test
```

2. **Image Push Failing**:
- Verify GitHub Packages permissions
- Check `GITHUB_TOKEN` has package write access

3. **GitOps Update Failing**:
- Check git configuration in workflow
- Verify write permissions to repository

### Images Not Building

**Symptom**: Docker build fails in CI

**Solution**:
```bash
# Test Docker build locally
cd app/backend
docker build -t test-backend .

# Check Dockerfile syntax
docker build --dry-run -t test-backend .
```

---

## Performance Issues

### Slow Cluster Performance

**Symptoms**: High latency, slow deployments

**Diagnosis**:
```bash
# Check resource usage
kubectl top nodes
kubectl top pods -A

# Check Docker resources
docker stats
```

**Solution**:
```bash
# Increase Docker resources in Docker Desktop
# Settings → Resources → Increase CPU/Memory

# Reduce replica counts
kubectl scale deployment backend --replicas=1 -n staging

# Clean up unused resources
docker system prune -a
```

### Argo Events Not Triggering

**Symptom**: Tests don't run automatically

**Diagnosis**:
```bash
# Check event sources
kubectl get eventsources -n argo-events
kubectl describe eventsource argocd-webhook -n argo-events

# Check sensors
kubectl get sensors -n argo-events
kubectl describe sensor test-trigger -n argo-events

# Check logs
kubectl logs -n argo-events deployment/sensor-controller
```

**Solution**:
```bash
# Restart Argo Events
kubectl rollout restart deployment -n argo-events

# Reapply configurations
kubectl apply -f gitops/argo-events/
```

---

## Debugging Commands

### General Debugging

```bash
# Get all resources
kubectl get all -A

# Check events
kubectl get events -A --sort-by='.lastTimestamp'

# Check logs
kubectl logs -f <pod-name> -n <namespace>

# Describe resources
kubectl describe <resource-type> <resource-name> -n <namespace>

# Execute commands in pod
kubectl exec -it <pod-name> -n <namespace> -- /bin/sh

# Port forward for direct access
kubectl port-forward <pod-name> 8080:8080 -n <namespace>
```

### ArgoCD Debugging

```bash
# Check sync status
argocd app list
argocd app get staging
argocd app history staging

# Force sync
argocd app sync staging --force

# View logs
kubectl logs -n argocd deployment/argocd-application-controller -f
```

### Argo Rollouts Debugging

```bash
# Get rollout status
kubectl argo rollouts get rollout backend -n production

# View history
kubectl argo rollouts history backend -n production

# Set image manually
kubectl argo rollouts set image backend \
  backend=ghcr.io/dramisinfo/e2e-platform-engineering/backend:tag \
  -n production
```

---

## Getting Help

If you can't resolve the issue:

1. **Check logs**: Always check application and controller logs first
2. **Verify setup**: Run `./scripts/validate.sh`
3. **Clean slate**: Try `./scripts/cleanup.sh` then `./scripts/setup-cluster.sh`
4. **Check resources**: Ensure sufficient CPU, memory, and disk
5. **Update tools**: Ensure all tools are latest versions

### Useful Log Locations

```bash
# ArgoCD
kubectl logs -n argocd deployment/argocd-server
kubectl logs -n argocd deployment/argocd-application-controller
kubectl logs -n argocd deployment/argocd-repo-server

# Argo Rollouts
kubectl logs -n argo-rollouts deployment/argo-rollouts

# Argo Events
kubectl logs -n argo-events deployment/eventbus-controller
kubectl logs -n argo-events deployment/eventsource-controller
kubectl logs -n argo-events deployment/sensor-controller

# Ingress
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller

# Applications
kubectl logs -n staging deployment/backend
kubectl logs -n production rollout/backend
```

---

## Reset and Start Fresh

If all else fails:

```bash
# Complete cleanup
./scripts/cleanup.sh

# Remove Docker images
docker system prune -a --volumes

# Start fresh
./scripts/setup-cluster.sh
```
