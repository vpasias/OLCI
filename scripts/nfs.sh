#!/bin/bash
#
# Highly available NFS service with Gluster Storage on Oracle Linux 8
# https://oracle.github.io/linux-labs/HA-NFS/
# https://docs.oracle.com/en/learn/gluster-oracle-linux/index.html#introduction

vagrant ssh storage1 -c "sudo dnf install -y oracle-gluster-release-el8 && sudo dnf config-manager --enable ol8_gluster_appstream ol8_baseos_latest ol8_appstream ol8_addons && sudo dnf install -y glusterfs-server glusterfs-client nfs-ganesha-gluster && sudo dnf install -y corosync pacemaker pcs" && \
vagrant ssh storage2 -c "sudo dnf install -y oracle-gluster-release-el8 && sudo dnf config-manager --enable ol8_gluster_appstream ol8_baseos_latest ol8_appstream ol8_addons && sudo dnf install -y glusterfs-server glusterfs-client nfs-ganesha-gluster && sudo dnf install -y corosync pacemaker pcs" && \
vagrant ssh storage3 -c "sudo dnf install -y oracle-gluster-release-el8 && sudo dnf config-manager --enable ol8_gluster_appstream ol8_baseos_latest ol8_appstream ol8_addons && sudo dnf install -y glusterfs-server glusterfs-client nfs-ganesha-gluster && sudo dnf install -y corosync pacemaker pcs"

#vagrant ssh storage1 -c "sudo firewall-cmd --add-service=glusterfs --permanent && sudo firewall-cmd --reload" && \
#vagrant ssh storage2 -c "sudo firewall-cmd --add-service=glusterfs --permanent && sudo firewall-cmd --reload" && \
#vagrant ssh storage3 -c "sudo firewall-cmd --add-service=glusterfs --permanent && sudo firewall-cmd --reload"

vagrant ssh storage1 -c "sudo systemctl enable --now glusterd.service" && \
vagrant ssh storage2 -c "sudo systemctl enable --now glusterd.service" && \
vagrant ssh storage3 -c "sudo systemctl enable --now glusterd.service"

vagrant ssh storage1 -c "sudo systemctl status glusterd.service" && \
vagrant ssh storage2 -c "sudo systemctl status glusterd.service" && \
vagrant ssh storage3 -c "sudo systemctl status glusterd.service"

vagrant ssh storage1 -c "sudo mkfs.xfs -f -i size=512 -L glusterfs /dev/sdb && sudo mkdir -p /data/glusterfs/myvolume/mybrick && echo 'LABEL=glusterfs /data/glusterfs/myvolume/mybrick xfs defaults 0 0'|sudo tee -a /etc/fstab && sudo mount -a" && \
vagrant ssh storage2 -c "sudo mkfs.xfs -f -i size=512 -L glusterfs /dev/sdb && sudo mkdir -p /data/glusterfs/myvolume/mybrick && echo 'LABEL=glusterfs /data/glusterfs/myvolume/mybrick xfs defaults 0 0'|sudo tee -a /etc/fstab && sudo mount -a" && \
vagrant ssh storage3 -c "sudo mkfs.xfs -f -i size=512 -L glusterfs /dev/sdb && sudo mkdir -p /data/glusterfs/myvolume/mybrick && echo 'LABEL=glusterfs /data/glusterfs/myvolume/mybrick xfs defaults 0 0'|sudo tee -a /etc/fstab && sudo mount -a"

vagrant ssh storage1 -c "sudo gluster peer probe nfs2.vagrant.vm && sudo gluster peer probe nfs3.vagrant.vm" && \
vagrant ssh storage1 -c "sudo gluster peer status && sudo gluster pool list"

vagrant ssh storage1 -c "sudo gluster volume create sharedvol replica 3 nfs{1,2,3}.vagrant.vm:/data/glusterfs/myvolume/mybrick/brick" && \
vagrant ssh storage1 -c "sudo gluster volume start sharedvol && sudo gluster volume info && sudo gluster volume status"

vagrant ssh storage1 -c "sudo mv /etc/ganesha/ganesha.conf /etc/ganesha/old.ganesha.conf && sudo cp /vagrant/scripts/ganesha.conf /etc/ganesha/ganesha.conf" && \
vagrant ssh storage2 -c "sudo mv /etc/ganesha/ganesha.conf /etc/ganesha/old.ganesha.conf && sudo cp /vagrant/scripts/ganesha.conf /etc/ganesha/ganesha.conf" && \
vagrant ssh storage3 -c "sudo mv /etc/ganesha/ganesha.conf /etc/ganesha/old.ganesha.conf && sudo cp /vagrant/scripts/ganesha.conf /etc/ganesha/ganesha.conf"

vagrant ssh storage1 -c 'echo -e "gprm8350\ngprm8350" | sudo passwd hacluster' && \
vagrant ssh storage2 -c 'echo -e "gprm8350\ngprm8350" | sudo passwd hacluster' && \
vagrant ssh storage3 -c 'echo -e "gprm8350\ngprm8350" | sudo passwd hacluster'

#vagrant ssh storage1 -c "sudo firewall-cmd --add-service=high-availability --permanent && sudo firewall-cmd --reload" && \
#vagrant ssh storage2 -c "sudo firewall-cmd --add-service=high-availability --permanent && sudo firewall-cmd --reload" && \
#vagrant ssh storage3 -c "sudo firewall-cmd --add-service=high-availability --permanent && sudo firewall-cmd --reload"

vagrant ssh storage1 -c "sudo systemctl enable corosync && sudo systemctl enable pacemaker && sudo systemctl enable --now pcsd.service" && \
vagrant ssh storage2 -c "sudo systemctl enable corosync && sudo systemctl enable pacemaker && sudo systemctl enable --now pcsd.service" && \
vagrant ssh storage3 -c "sudo systemctl enable corosync && sudo systemctl enable pacemaker && sudo systemctl enable --now pcsd.service"

vagrant ssh storage1 -c "sudo pcs host auth storage1 storage2 storage3 -u hacluster -p gprm8350"
sleep 5
vagrant ssh storage1 -c "sudo pcs cluster setup HA-NFS storage1 storage2 storage3 --force"
sleep 5
vagrant ssh storage1 -c "sudo pcs cluster start --all && sudo pcs cluster enable --all"
sleep 5
vagrant ssh storage1 -c "sudo pcs property set stonith-enabled=false"
sleep 5
vagrant ssh storage1 -c "sudo pcs cluster status"
sleep 5
vagrant ssh storage1 -c "sudo pcs resource create nfs_server systemd:nfs-ganesha op monitor interval=10s"
sleep 5
vagrant ssh storage1 -c "sudo pcs resource create nfs_ip ocf:heartbeat:IPaddr2 ip=192.168.199.100 cidr_netmask=24 op monitor interval=10s"
sleep 5
vagrant ssh storage1 -c "sudo pcs resource group add nfs_group nfs_server nfs_ip"
sleep 5
vagrant ssh storage1 -c "sudo pcs status"

# Testing
# vagrant ssh admin1 -c "sudo dnf install -y nfs-utils"
# vagrant ssh admin1 -c "sudo mkdir /sharedvol && sudo mount -t nfs nfs.vagrant.vm:/sharedvol /sharedvol && df -h /sharedvol/"
# vagrant ssh admin1
# sudo -i
# echo "Hello from OpenWorld" > sudo tee /sharedvol/hello
# exit
# vagrant ssh storage1 -c "sudo pcs status"
# vagrant ssh storage1 -c "sudo pcs node standby storage1"
# vagrant ssh storage1 -c "sudo pcs status"
# vagrant ssh admin1 -c "sudo ls -la /sharedvol/ && sudo cat /sharedvol/hello"
# vagrant ssh storage1 -c "sudo pcs node unstandby storage1"
