#!/bin/bash

#=====================
#| INIT K8s CLUSTER  |
#=====================
# /!\ DONT RUN THIS SCRIPT AS SUDO USER

K8S_RELEASED_VERSION="${1:-1.26.0}"
POD_NET_CIDR="${2:-192.168.0.0/16}"
API_SERVER_ADDR="${3:-$(/bin/hostname -i)}"

sudo kubectl get nodes
# Check if the cluster is already init
if [[ $? != 0 ]]; then
  # Setup the cluster
  sudo kubeadm init \
    --apiserver-advertise-address "$API_SERVER_ADDR" \
    --pod-network-cidr "$POD_NET_CIDR" \
    --kubernetes-version "$K8S_RELEASED_VERSION"
fi

if [[ $? -eq 0 ]]; then
  USER=$(id -u)
  GROUP=$(id -g)
  echo "Start configuring kubectl for user: $(whoami)"
  # Allow current user to execute K8s commands
  USER_K8S_HOME=$HOME/.kube
  K8S_HOME=/etc/kubernetes
  mkdir -p $USER_K8S_HOME
  sudo mkdir -p $K8S_HOME
  sudo cp -i $K8S_HOME/admin.conf $USER_K8S_HOME/config
  sudo chown $USER:$GROUP $USER_K8S_HOME/config
fi

# Installing Networking Plugin Calico
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml

# Print the control node join command
echo "[WORKERS JOIN COMMAND] => copy and paste the command below on your worker nodes"
kubeadm token create --print-join-command
