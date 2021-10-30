#
# Vagrantfile to create Hands on Lab
#
# Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl
#
#
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  # Memory for the VMs (2GB)
  MEMORY = 2048

  # Number of nodes to provision
  MASTER_NODES = 3
  CLIENT_NODES = 1

  GROUP = "/cluster"

  # Box metadata location and box name
  BOX_URL = "https://oracle.github.io/vagrant-projects/boxes"
  BOX_NAME = "oraclelinux/8"

  config.vm.box = BOX_NAME
  config.vm.box_url = "#{BOX_URL}/#{BOX_NAME}.json"

  config.vm.provider :virtualbox do |vb|
    vb.memory = MEMORY
    vb.customize ["modifyvm", :id, "--groups", GROUP] unless GROUP.nil?
  end

  config.vagrant.plugins = "vagrant-hosts"

  if Vagrant.has_plugin?("vagrant-hosts")
    config.vm.provision :hosts do |provisioner|
      provisioner.add_localhost_hostnames = false
      provisioner.sync_hosts = true
      provisioner.autoconfigure = true
      provisioner.add_host  '192.168.99.100', ['nfs.vagrant.vm', 'nfs']
    end
  end

  nextip = 0
  (1..MASTER_NODES).each do |i|
    config.vm.define "master#{i}" do |master|
      master.vm.hostname = "master#{i}.vagrant.vm"
      ip = 100 + i
      master.vm.network "private_network", ip: "192.168.99.#{ip}"
    end
    nextip = 100 + i
  end

  (1..CLIENT_NODES).each do |i|
    config.vm.define "client#{i}" do |client|
      client.vm.hostname = "client#{i}.vagrant.vm"
      ip = nextip + i
      client.vm.network "private_network", ip: "192.168.99.#{ip}"
    end
  end

  config.vm.post_up_message = "Build complete"
end
