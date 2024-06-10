#!/bin/bash

# Set it to a particular version (for example, 1.27.5) or latest (to install the latest available)
# For example, K8SVER='1.27.5' or K8SVER='latest' (which will translate for example to 1.28.3)
# This is applicable to versions from v1.24.0 onwards

K8SVER='1.27.5'

# DO NOT EDIT BELOW THIS LINE

echo "* Specified version is $K8SVER"

if [ $K8SVER == 'latest' ]; then
	K8SVER=$(curl -sSL https://dl.k8s.io/release/stable.txt | tr -d 'v')
fi

K8SBRANCH=$(echo $K8SVER | cut -d '.' -f1,2)

echo "... working with $K8SVER version from $K8SBRANCH branch."

echo $K8SBRANCH > /tmp/k8s-branch
echo $K8SVER > /tmp/k8s-version

echo '* Load br_netfilter on boot ...'
modprobe br_netfilter
echo br_netfilter >> /etc/modules-load.d/k8s.conf

echo '* Adjust network-related settings and apply them ...'
cat << EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system

echo '* Install iptables and switch it to legacy version ...'
apt-get update && apt-get install -y iptables
update-alternatives --set iptables /usr/sbin/iptables-legacy

echo '* Turn off the swap ...'
swapoff -a
sed -i '/swap/ s/^/#/' /etc/fstab

echo '* Add hosts ...'
echo '192.168.56.101 node1.k8s.lab node1' >> /etc/hosts
echo '192.168.56.102 node2.k8s.lab node2' >> /etc/hosts
echo '192.168.56.103 node3.k8s.lab node3' >> /etc/hosts
echo '192.168.56.100 nfs-server.k8s.lab nfs-server' >> /etc/hosts

echo '* Install other required packages ...'
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

echo '* Download and install the Docker repository key ...'
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo '* Add the Docker repository ...'
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

echo '* Install the required container runtime packages ...'
apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io

echo '* Add vagrant user to docker group ...'
usermod -aG docker vagrant

echo '* Download and install the Kubernetes repository key ...'
curl -fsSL https://pkgs.k8s.io/core:/stable:/v${K8SBRANCH}/deb/Release.key | gpg --dearmor -o /usr/share/keyrings/kubernetes-archive-keyring.gpg

echo '* Add the Kubernetes repository ...'
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${K8SBRANCH}/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list

echo "* Install the selected ($K8SVER) version ..."
apt-get update && apt-get install -y kubelet=${K8SVER}* kubeadm=${K8SVER}* kubectl=${K8SVER}*

echo '* Exclude the Kubernetes packages from being updated ...'
apt-mark hold kubelet kubeadm kubectl

echo '* Adjust containerd configuration ...'
cp /etc/containerd/config.toml /etc/containerd/config.toml.bak
containerd config default | tee /etc/containerd/config.toml > /dev/null
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
sed -i 's/pause:3.6/pause:3.9/g' /etc/containerd/config.toml
systemctl restart containerd

echo '* Install nfs-common'
apt-get update && apt-get install -y nfs-common