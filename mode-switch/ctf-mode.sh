#!/bin/bash

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then 
    echo "[-] This script requires sudo privileges. Please run with sudo."
    exit 1
fi

echo "[+] Stopping media-server..."
kubectl scale deploy -n media-server --all --replicas=0
kubectl scale sts -n media-server --all --replicas=0

echo "[+] Stopping syncthing..."
kubectl scale deploy -n syncthing --all --replicas=0

# echo "[+] Stopping Longhorn Deployments..."
# kubectl scale deploy -n longhorn-system --all --replicas=0

# echo "[+] Stopping Longhorn DaemonSets..."
# kubectl -n longhorn-system patch daemonset longhorn-manager -p '{"spec": {"template": {"spec": {"nodeSelector": {"non-existing": "true"}}}}}'
# kubectl -n longhorn-system patch daemonset longhorn-csi-plugin -p '{"spec": {"template": {"spec": {"nodeSelector": {"non-existing": "true"}}}}}'
# kubectl -n longhorn-system patch daemonset engine-image-ei-26bab25d -p '{"spec": {"template": {"spec": {"nodeSelector": {"non-existing": "true"}}}}}'

echo "[+] CTF Mode Activated!"