#!/bin/bash

K8SVER=$(cut -d - -f 1 /tmp/k8s-version)

echo "* Initialize Kubernetes cluster ..."
kubeadm init --kubernetes-version=$K8SVER --apiserver-advertise-address=192.168.56.101 --pod-network-cidr 10.244.0.0/16 --token abcdef.0123456789abcdef

echo "* Save the hash to a file ..."
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //' > /vagrant/hash.txt

echo "* Copy configuration for root ..."
mkdir -p /root/.kube
cp -i /etc/kubernetes/admin.conf /root/.kube/config
chown -R root:root /root/.kube

echo "* Copy configuration for vagrant ..."
mkdir -p /home/vagrant/.kube
cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube

# Pod Network plugin - comment/uncomment one of the following blocks
# Currently set to Calico

# echo "* Install Pod Network plugin (Flannel) ..."
# wget -q https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml -O /tmp/kube-flannel.yaml
# sed -i '/--kube-subnet-mgr/ a CHANGEME' /tmp/kube-flannel.yaml
# sed -i "s/CHANGEME/        - --iface=$(ip a | grep 192.168.56.101 | tr -s ' ' | cut -d ' ' -f 8)/" /tmp/kube-flannel.yaml 
# kubectl apply -f /tmp/kube-flannel.yaml

echo "* Install Pod Network plugin (Calico) ..."
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.3/manifests/tigera-operator.yaml
wget -q https://raw.githubusercontent.com/projectcalico/calico/v3.26.3/manifests/custom-resources.yaml -O /tmp/custom-resources.yaml
sed -i 's/192.168.0.0/10.244.0.0/g' /tmp/custom-resources.yaml
kubectl create -f /tmp/custom-resources.yaml