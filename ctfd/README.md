# CTFd Kubernetes Deployment

Kubernetes manifests for deploying CTFd (Capture The Flag framework) on K3s.

## Overview

Deployment includes:
- **CTFd Application**: Web application (port 8000)
- **MariaDB**: Database (1 replica, 5Gi storage)
- **Redis**: HA cluster with 3 replicas + Sentinel
- **Storage**: Longhorn-based PVCs for logs, uploads, and database

## Architecture

`Ingress → CTFd → MariaDB | Redis (3x) + Sentinel (3x)`

## Prerequisites

- K3s cluster with Traefik ingress
- Longhorn storage class
- DNS for `ctfd.local` (or update ingress)

## Installation

```bash
# 1. Create namespace
kubectl apply -f namespace.yaml

# 2. Configure secrets (see below) then apply
kubectl apply -f secrets.yaml

# 3. Create config map
kubectl apply -f config-map.yaml

# 4. Create storage
kubectl apply -f storage.yaml

# 5. Deploy database and wait
kubectl apply -f deployment/db.yaml
kubectl wait --for=condition=ready pod -l app=ctfd-db -n ctfd --timeout=300s

# 6. Deploy Redis
kubectl apply -f deployment/redis.yaml
kubectl apply -f deployment/redis-sentinel.yaml
kubectl wait --for=condition=ready pod -l app=ctfd-redis -n ctfd --timeout=300s

# 7. Deploy CTFd and services
kubectl apply -f deployment/ctfd.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml
```

## Configuration

### Secrets

⚠️ **IMPORTANT**: Configure `secrets.yaml` with secure passwords before deploying:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: ctfd-secret
  namespace: ctfd
type: Opaque
stringData:
  MYSQL_ROOT_PASSWORD: <your-root-password>
  MYSQL_DATABASE: ctfd
  MYSQL_PASSWORD: <your-db-password>
  MYSQL_USER: <your-db-user>
  DATABASE_URL: "mysql+pymysql://<user>:<password>@ctfd-db/ctfd"
  REDIS_URL: "redis://:<redis-password>@ctfd-redis:6379"
```

**Note**: Redis password must match in both `config-map.yaml` and `secrets.yaml`.

## Access

- **Web**: `http://ctfd.local` (via ingress)
- **Port Forward**: `kubectl port-forward -n ctfd svc/ctfd-main 8000:8000`

## Troubleshooting

```bash
# Check pod status
kubectl get pods -n ctfd

# View logs
kubectl logs -n ctfd -l app=ctfd-main
kubectl logs -n ctfd -l app=ctfd-db
kubectl logs -n ctfd -l app=ctfd-redis

# Check PVCs
kubectl get pvc -n ctfd

# Describe pod for events
kubectl describe pod <pod-name> -n ctfd
```

**Common Issues**: CrashLoopBackOff (check logs/secrets/PVCs), DB connection (verify pod/DATABASE_URL), Redis (verify pods/password match), Storage (check Longhorn/PVCs)

## Maintenance

```bash
# Backup database
DB_POD=$(kubectl get pod -n ctfd -l app=ctfd-db -o jsonpath='{.items[0].metadata.name}')
ROOT_PASSWORD=$(kubectl get secret ctfd-secret -n ctfd -o jsonpath='{.data.MYSQL_ROOT_PASSWORD}' | base64 -d)
kubectl exec -n ctfd $DB_POD -- mysqldump -u root -p"$ROOT_PASSWORD" ctfd > ctfd-backup-$(date +%Y%m%d).sql

# Update CTFd
kubectl set image deployment/ctfd-main ctfd-main=ctfd/ctfd:latest -n ctfd

# Restart components
kubectl rollout restart deployment ctfd-main -n ctfd
```

## File Structure

```
ctfd/
├── README.md
├── namespace.yaml
├── secrets.yaml          # Configure passwords here
├── config-map.yaml       # Redis configuration
├── storage.yaml          # PVCs
├── service.yaml
├── ingress.yaml
└── deployment/
    ├── ctfd.yaml
    ├── db.yaml
    ├── redis.yaml
    └── redis-sentinel.yaml
```

## Security Notes

⚠️ Before production:
1. Set strong passwords in `secrets.yaml`
2. Match Redis password in `config-map.yaml` and `secrets.yaml`
3. Enable TLS/HTTPS in ingress
4. Use external secret management
5. Never commit passwords to version control

## References

- [CTFd Docs](https://docs.ctfd.io/) | [GitHub](https://github.com/CTFd/CTFd)
