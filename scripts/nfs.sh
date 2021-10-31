#!/bin/bash
#
# Highly available NFS service with Gluster Storage on Oracle Linux 8
# https://oracle.github.io/linux-labs/HA-NFS/
# https://docs.oracle.com/en/learn/gluster-oracle-linux/index.html#introduction

vagrant ssh storage1 -c "sudo dnf install -y oracle-gluster-release-el8 && sudo dnf config-manager --enable ol8_gluster_appstream ol8_baseos_latest ol8_appstream && sudo dnf install -y glusterfs-server glusterfs-client corosync nfs-ganesha-gluster pacemaker pcs git vim wget curl" && \
vagrant ssh storage2 -c "sudo dnf install -y oracle-gluster-release-el8 && sudo dnf config-manager --enable ol8_gluster_appstream ol8_baseos_latest ol8_appstream && sudo dnf install -y glusterfs-server glusterfs-client corosync nfs-ganesha-gluster pacemaker pcs git vim wget curl" && \
vagrant ssh storage3 -c "sudo dnf install -y oracle-gluster-release-el8 && sudo dnf config-manager --enable ol8_gluster_appstream ol8_baseos_latest ol8_appstream && sudo dnf install -y glusterfs-server glusterfs-client corosync nfs-ganesha-gluster pacemaker pcs git vim wget curl"

vagrant ssh storage1 -c "sudo firewall-cmd --add-service=glusterfs --permanent && sudo firewall-cmd --reload" && \
vagrant ssh storage2 -c "sudo firewall-cmd --add-service=glusterfs --permanent && sudo firewall-cmd --reload" && \
vagrant ssh storage3 -c "sudo firewall-cmd --add-service=glusterfs --permanent && sudo firewall-cmd --reload"

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

vagrant ssh storage1 -c "sudo gluster volume create sharedvol replica 3 nfs{1,2,3}:/data/glusterfs/sharedvol/mybrick/brick" && \
vagrant ssh storage1 -c "sudo gluster volume start sharedvol && sudo gluster volume info && gluster volume status"

vagrant ssh storage1 -c "sudo mv /etc/ganesha/ganesha.conf /etc/ganesha/old.ganesha.conf && sudo cp /vagrant/scripts/ganesha.conf /etc/ganesha/ganesha.conf" && \
vagrant ssh storage2 -c "sudo mv /etc/ganesha/ganesha.conf /etc/ganesha/old.ganesha.conf && sudo cp /vagrant/scripts/ganesha.conf /etc/ganesha/ganesha.conf" && \
vagrant ssh storage3 -c "sudo mv /etc/ganesha/ganesha.conf /etc/ganesha/old.ganesha.conf && sudo cp /vagrant/scripts/ganesha.conf /etc/ganesha/ganesha.conf"

