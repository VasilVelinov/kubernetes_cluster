# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
    
  config.ssh.insert_key = false

  config.vm.provider "virtualbox" do |v|
    v.memory = 2048
    v.cpus = 2
  end

  config.vm.define "nfs_server" do |nfs_server|
    nfs_server.vm.box = "shekeriev/debian-11"
    nfs_server.vm.hostname = "nfs-server.k8s.lab"
    nfs_server.vm.network "private_network", ip: "192.168.56.100"
    nfs_server.vm.synced_folder "vagrant/", "/vagrant"
    nfs_server.vm.provision "shell", path: "nfs-server.sh"
  end

  config.vm.define "node1" do |node1|
    node1.vm.box = "shekeriev/debian-11"
    node1.vm.hostname = "node1.k8s.lab"
    node1.vm.network "private_network", ip: "192.168.56.101"
    node1.vm.synced_folder "vagrant/", "/vagrant"
    node1.vm.provision "shell", path: "common.sh"
    node1.vm.provision "shell", path: "k8scp.sh"
  end

  config.vm.define "node2" do |node2|
    node2.vm.box = "shekeriev/debian-11"
    node2.vm.hostname = "node2.k8s.lab"
    node2.vm.network "private_network", ip: "192.168.56.102"
    node2.vm.synced_folder "vagrant/", "/vagrant"
    node2.vm.provision "shell", path: "common.sh"
    node2.vm.provision "shell", path: "k8swk.sh"
  end

  config.vm.define "node3" do |node3|
    node3.vm.box = "shekeriev/debian-11"
    node3.vm.hostname = "node3.k8s.lab"
    node3.vm.network "private_network", ip: "192.168.56.103"
    node3.vm.synced_folder "vagrant/", "/vagrant"
    node3.vm.provision "shell", path: "common.sh"
    node3.vm.provision "shell", path: "k8swk.sh"
  end
end
