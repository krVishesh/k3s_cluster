# k3s Scripts

A collection of Kubernetes manifests for deploying self-hosted services on k3s. This repository contains configurations for various applications including media servers, cloud storage, and file synchronization tools.

## 📦 Included Services

- **Nextcloud** - Self-hosted cloud storage and collaboration platform
- **Jellyfin** - Media server for streaming movies, TV shows, and music
- **MariaDB** - Database server (used by Nextcloud)
- **qBittorrent** - BitTorrent client
- **Syncthing** - Decentralized file synchronization
- **Cloudflared** - Cloudflare tunnel for secure remote access
- **Longhorn** - Distributed block storage for Kubernetes
- **Prometheus Stack** - Cluster monitoring with Prometheus, Alertmanager, and Grafana

## 📁 Project Structure

```
k3s_scripts/
├── apps/              # Application deployments
├── helm/              # Helm chart values
├── ingress/           # Ingress configurations (Traefik)
├── namespace/         # Kubernetes namespaces
├── pvc/               # Persistent Volume Claims
├── secrets/           # Secrets (gitignored - create your own)
├── service/           # Service definitions
└── storage/           # Persistent Volume definitions
```

## 🚀 Prerequisites

- k3s cluster installed and running
- `kubectl` configured to access your cluster
- Longhorn installed (for persistent storage)
- Helm installed (for `prometheus-community/kube-prometheus-stack`)
- Traefik ingress controller (comes with k3s by default)
- Node labels configured:
  - `load=heavy` - For resource-intensive workloads
  - `persistence=true` - For nodes with persistent storage

## 📋 Setup Instructions

### 1. Create Namespaces

```bash
kubectl apply -f namespace/namespace.yaml
```

### 2. Install Longhorn (if not already installed)

```bash
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.10.0/deploy/longhorn.yaml
```

### 3. Create Secrets

**Important:** The `secrets/` folder is gitignored. You need to create your own secret files based on the examples in the `secrets/` directory.

Required secrets:
- `mariadb-secret.yaml` - Database credentials
- `nextcloud-creds.yaml` - Nextcloud admin credentials
- `cloudflared-creds.yaml` - Cloudflare tunnel credentials
- `longhorn-secret.yaml` - Longhorn configuration (if needed)
- `monitoring-secrets.yaml` - Grafana admin username and password for the monitoring stack

Example secret structure:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mariadb-secret
  namespace: media-server
type: Opaque
stringData:
  MYSQL_ROOT_PASSWORD: your-root-password
  MYSQL_DATABASE: nextcloud
  MYSQL_USER: nextcloud
  MYSQL_PASSWORD: your-db-password
```

Grafana credentials are read from the `monitoring-secrets` Secret in the `monitoring` namespace:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: monitoring-secrets
  namespace: monitoring
type: Opaque
stringData:
  grafana-admin-user: your-admin-user
  grafana-admin-password: your-strong-password
```

### 4. Deploy Storage

```bash
kubectl apply -f storage/
kubectl apply -f pvc/
```

### 5. Deploy Secrets

```bash
kubectl apply -f secrets/
```

### 6. Deploy Applications

```bash
kubectl apply -f apps/
```

### 7. Deploy Monitoring Stack

Add the Prometheus Community Helm repository if needed, then deploy the stack with the values from `helm/prometheus-stack.yaml`:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install prometheus-stack prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f helm/prometheus-stack.yaml
```

This installs Prometheus, Alertmanager, and Grafana. Grafana uses the admin credentials stored in `secrets/monitoring-secrets.yaml`.

### 8. Deploy Services

```bash
kubectl apply -f service/
```

### 9. Deploy Ingress

```bash
kubectl apply -f ingress/
```

## 🔧 Configuration

### Node Labels

Ensure your nodes have the following labels for proper scheduling:

```bash
kubectl label nodes <node-name> load=heavy
kubectl label nodes <node-name> persistence=true
```

### Ingress Configuration

The ingress configurations use Traefik. Update the `host` fields in the ingress files to match your domain:

- `nextcloud.local` → Your Nextcloud domain
- `jellyfin.local` → Your Jellyfin domain
- `qbittorrent.local` → Your qBittorrent domain
- `syncthing.local` → Your Syncthing domain
- `grafana.local` → Your Grafana domain

### Timezone

Default timezone is set to `Asia/Kolkata`. Update the `TZ` environment variable in deployment files if needed.

## 📝 Notes

- All persistent volumes use Longhorn storage class
- Services are deployed in the `media-server` and `syncthing` namespaces
- Monitoring components are deployed in the `monitoring` namespace via Helm
- Nextcloud is configured to use MariaDB as the database backend
- Volume mounts are configured for data persistence across pod restarts
- Grafana admin credentials are sourced from the `monitoring-secrets` Kubernetes Secret

## 🔒 Security

- **Never commit secrets to git** - The `secrets/` folder is gitignored
- Use strong passwords for all services
- Configure proper firewall rules
- Use HTTPS/TLS for production deployments
- Regularly update container images

## 🛠️ Maintenance

### Update Applications

To update application images, edit the deployment files in `apps/` and apply:

```bash
kubectl apply -f apps/<app-name>.yaml
```

### Backup

Regularly backup your persistent volumes, especially:
- Nextcloud data and config
- MariaDB data
- Jellyfin media library metadata

### Monitoring

Check pod status:
```bash
kubectl get pods -n media-server
kubectl get pods -n syncthing
kubectl get pods -n monitoring
```

View logs:
```bash
kubectl logs -n media-server <pod-name>
```

## 📄 License

This project is provided as-is for personal use.

## 🤝 Contributing

Feel free to submit issues or pull requests for improvements.
