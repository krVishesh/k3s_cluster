#!/bin/bash

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then 
    echo "[-] This script requires sudo privileges. Please run with sudo."
    exit 1
fi

# echo "[+] Restarting Longhorn DaemonSets..."
# kubectl -n longhorn-system patch daemonset longhorn-manager --type json -p='[{"op": "remove", "path": "/spec/template/spec/nodeSelector/non-existing"}]'
# kubectl -n longhorn-system patch daemonset longhorn-csi-plugin --type json -p='[{"op": "remove", "path": "/spec/template/spec/nodeSelector/non-existing"}]'
# kubectl -n longhorn-system patch daemonset engine-image-ei-26bab25d --type json -p='[{"op": "remove", "path": "/spec/template/spec/nodeSelector/non-existing"}]'

# echo "[+] Restarting Longhorn Deployments..."
# kubectl scale deploy -n longhorn-system --all --replicas=1

echo "[+] Restarting media-server..."
kubectl scale deploy -n media-server --all --replicas=1
kubectl scale sts -n media-server --all --replicas=1

echo "[+] Restarting syncthing..."
kubectl scale deploy -n syncthing --all --replicas=1

echo "[+] Normal Mode Restored!"
