#!/usr/bin/env bash
set -euo pipefail
AIR_GAPPED="$1"
RUNTIME="$2"
IMAGES_DIR="$3"

echo "当前环境运行时: ${RUNTIME}"
if [ ${AIR_GAPPED} = "true" ]; then
    echo "当前环境：离线环境"
else
    echo "当前环境：在线环境"
fi

if [ ${RUNTIME} = "docker" ] && [ ${AIR_GAPPED} = "true" ]; then
    sudo docker load -i ${IMAGES_DIR}
fi

if [ ${RUNTIME} = "containerd" ] && [ ${AIR_GAPPED} = "true" ]; then
    sudo ctr -n k8s.io images import ${IMAGES_DIR}
fi

if [ ${RUNTIME} = "k3s" ] && [ ${AIR_GAPPED} = "true" ]; then
    sudo k3s ctr -n k8s.io images import ${IMAGES_DIR}
fi