# -*- mode: ruby -*-
# vi: set ft=ruby :

# To be able to add extra disks. To include: /dev/sdb with name: data
ENV['VAGRANT_EXPERIMENTAL'] = 'disks'

$common = <<EOF
lsblk
dnf update -y
dnf --assumeyes --nogpgcheck install device-mapper-persistent-data iproute-tc lvm2 util-linux e2fsprogs git vim wget curl cloud-utils-growpart gdisk
growpart /dev/sda 2
lsblk
xfs_growfs /
df -hT | grep /dev/sda
echo "root:gprm8350" | sudo chpasswd
echo "options kvm_intel nested=1" >> /etc/modprobe.d/kvm.conf
modprobe -r kvm_intel
modprobe kvm_intel
cat /sys/module/kvm_intel/parameters/nested
modinfo kvm_intel | grep -i nested
EOF

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"
ENV['VAGRANT_NO_PARALLEL'] = 'yes'

Vagrant.configure("2") do |config|

  # Memory & CPU cores for the VMs
  MEMORY = 16384
  CPU = 4

  # Number of nodes to provision
  STORAGE_NODES = 3
  CONTROLLER_NODES = 3
  COMPUTE_NODES = 3
  ADMIN_NODES = 1

  GROUP = "/cluster"

  # Box metadata location and box name
  BOX_URL = "https://oracle.github.io/vagrant-projects/boxes"
  BOX_NAME = "oraclelinux/8"

  config.vm.box = BOX_NAME
  config.vm.box_url = "#{BOX_URL}/#{BOX_NAME}.json"

  config.vm.provider :virtualbox do |vb|
    vb.memory = MEMORY
    vb.cpus = CPU
    vb.gui = false
    vb.customize ["modifyvm", :id, "--chipset", "ich9"]
    vb.customize ["modifyvm", :id, "--nested-hw-virt", "on"]
    vb.customize ["setextradata", :id, "VBoxInternal/CPUM/SSE4.1", "1"]
    vb.customize ["setextradata", :id, "VBoxInternal/CPUM/SSE4.2", "1"]
    vb.customize ["modifyvm", :id, "--groups", GROUP] unless GROUP.nil?
    # it will cause the NAT gateway to accept DNS traffic and the gateway will
    # read the query and use the host's operating system APIs to resolve it
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    # https://docs.oracle.com/en/virtualization/virtualbox/6.0/user/network_performance.html
    vb.customize ["modifyvm", :id, "--nictype1", "virtio", "--cableconnected1", "on"]
    vb.customize ['modifyvm', :id, '--nicpromisc1', 'allow-all']
    vb.customize ["modifyvm", :id, "--nictype2", "virtio", "--cableconnected2", "on"]
    vb.customize ['modifyvm', :id, '--nicpromisc2', 'allow-all']
    # https://bugs.launchpad.net/cloud-images/+bug/1829625/comments/2
    vb.customize ["modifyvm", :id, "--uart1", "0x3F8", "4"]
    vb.customize ['modifyvm', :id, '--uart2', '0x2F8', '3']
    vb.customize ["modifyvm", :id, "--uartmode1", "file", File::NULL]
    vb.customize ["modifyvm", :id, "--uartmode2", "file", File::NULL]
    # Enable nested paging for memory management in hardware
    vb.customize ["modifyvm", :id, "--nestedpaging", "on"]
    # Use large pages to reduce Translation Lookaside Buffers usage
    vb.customize ["modifyvm", :id, "--largepages", "on"]
    # Use virtual processor identifiers  to accelerate context switching
    vb.customize ["modifyvm", :id, "--vtxvpid", "on"]
    vb.customize ['modifyvm', :id, '--vram', '16']
  end

  config.vagrant.plugins = "vagrant-hosts"

  if Vagrant.has_plugin?("vagrant-hosts")
    config.vm.provision :hosts do |provisioner|
      provisioner.add_localhost_hostnames = false
      provisioner.sync_hosts = true
      provisioner.add_host  '192.168.199.100', ['nfs.vagrant.vm', 'nfs']
      provisioner.add_host  '192.168.199.101', ['nfs1.vagrant.vm', 'nfs1']
      provisioner.add_host  '192.168.199.102', ['nfs2.vagrant.vm', 'nfs1']
      provisioner.add_host  '192.168.199.103', ['nfs3.vagrant.vm', 'nfs3']
    end
  end

  nextip = 0
  nextips = 0
  
  (1..CONTROLLER_NODES).each do |i|
    config.vm.define "controller#{i}" do |controller|
      controller.vm.hostname = "controller#{i}.vagrant.vm"
      controller.disksize.size = "120GB"
      ip = 10 + i
      controller.vm.network "private_network", ip: "192.168.99.#{ip}"
      ips = 10 + i
      controller.vm.network "private_network", ip: "192.168.199.#{ips}"
      controller.vm.provision :shell, inline: $common
    end
    nextip = 10 + i
    nextips = 10 + i
  end
  
  (1..COMPUTE_NODES).each do |i|
    config.vm.define "compute#{i}" do |compute|
      compute.vm.hostname = "compute#{i}.vagrant.vm"
      compute.disksize.size = "120GB"
      ip = 20 + i
      compute.vm.network "private_network", ip: "192.168.99.#{ip}"  
      ips = 20 + i
      compute.vm.network "private_network", ip: "192.168.199.#{ips}"
      compute.vm.provision :shell, inline: $common
      compute.vm.disk :disk, size: "200GB", name: "data" 	
    end
    nextip = 20 + i
    nextips = 20 + i
  end  
  
  (1..STORAGE_NODES).each do |i|
    config.vm.define "storage#{i}" do |storage|
      storage.vm.hostname = "storage#{i}.vagrant.vm"
      storage.disksize.size = "120GB"
      ip = 100 + i
      storage.vm.network "private_network", ip: "192.168.99.#{ip}"
      ips = 100 + i
      storage.vm.network "private_network", ip: "192.168.199.#{ips}"
      storage.vm.provision :shell, inline: $common
      storage.vm.disk :disk, size: "200GB", name: "data" 	
    end
    nextip = 100 + i
    nextips = 100 + i
  end

  (1..ADMIN_NODES).each do |i|
    config.vm.define "admin#{i}" do |admin|
      admin.vm.hostname = "admin#{i}.vagrant.vm"
      ip = nextip + 50 + i
      admin.vm.network "private_network", ip: "192.168.99.#{ip}"
      ips = nextips + 50 + i
      admin.vm.network "private_network", ip: "192.168.199.#{ips}"
      admin.vm.provision :shell, inline: $common
    end
  end

  config.vm.post_up_message = "Build complete"
end
