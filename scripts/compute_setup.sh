#! /bin/sh

dnf update -y
dnf install -y python3 python3-simplejson mdadm
dnf install -y qemu-kvm

echo "configfs" >> /etc/modules
update-initramfs -u
systemctl daemon-reload

systemctl stop open-iscsi
systemctl disable open-iscsi
systemctl stop iscsid
systemctl disable iscsid

dnf update -y

reboot
