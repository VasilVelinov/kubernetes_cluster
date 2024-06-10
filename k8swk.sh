#!/bin/bash

echo "* Join the worker node ..."
kubeadm join 192.168.56.101:6443 --token abcdef.0123456789abcdef --discovery-token-ca-cert-hash sha256:`cat /vagrant/hash.txt`
