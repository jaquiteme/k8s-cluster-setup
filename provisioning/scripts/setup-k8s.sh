#!/bin/bash
#======================================
#| K8S SETUP FOR DEBIAN BASED DISTRIB |
#======================================
# /!\ THIS SCRIPT MUST BE RUN AS SUDO USER

K8S_VERSION="${1:-1.28.0}"

echo "Setting up containerd required modules..."
cat <<EOF | tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

modprobe overlay && modprobe br_netfilter

echo "Setting up systcl conf..."
cat <<EOF | tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

update_sysctl=$(sysctl --system)
if [[ $? -eq 0 ]]; then
    echo "Sysctl successfully reloaded"
fi

# Install containerd.io following docker installation
# https://forum.linuxfoundation.org/discussion/862825/kubeadm-init-error-cri-v1-runtime-api-is-not-implemented
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update && apt-get install -y containerd.io
# Removing default containerd config if exists
if [[ -f "/etc/containerd/config.toml" ]]; then
    rm /etc/containerd/config.toml
fi
# Starting containerd service
systemctl start containerd

# K8S need swap to be disabled
swapoff -a

# Miscellaneous packages required by K8S
apt-get update && apt-get install -y ca-certificates apt-transport-https curl gpg

# Download Google cloud public signing key
mkdir -p /etc/apt/keyrings
curl -fsSL "https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/Release.key" | \
    gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg


# Add K8S apt
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/ /" | \
    tee /etc/apt/sources.list.d/kubernetes.list

# Install K8S packages
apt-get update && apt-get install -y \
kubelet="$K8S_VERSION" \
kubeadm="$K8S_VERSION" \
kubectl="$K8S_VERSION" \
--allow-change-held-packages

# Freeze K8s package versions
if [[ $? -eq 0 ]]; then
    apt-mark hold kubelet kubeadm kubectl
fi
