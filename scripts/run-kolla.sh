#! /bin/sh

export LC_ALL=C
export LC_CTYPE="UTF-8",
export LANG="en_US.UTF-8"

# ---- PART ONE ------
# Configure SSH connectivity from 'deployment' - admin1 to Target Hosts 

# Comment/remove the following part if ceph-ansible has been installed first.
#############################################################################

echo 'run-kolla.sh: Cleaning directory /home/vagrant/.ssh/'
rm -f /home/vagrant/.ssh/known_hosts
rm -f /home/vagrant/.ssh/id_rsa
rm -f /home/vagrant/.ssh/id_rsa.pub

echo 'run-kolla.sh: Running ssh-keygen -t rsa'
ssh-keygen -q -t rsa -N "" -f /home/vagrant/.ssh/id_rsa

#############################################################################

echo 'run-kolla.sh: Install sshpass'
sudo dnf install sshpass -y

echo 'run-kolla.sh: Running ssh-copy-id vagrant@controller1 - Controller 1'
sshpass -p vagrant ssh-copy-id -o StrictHostKeyChecking=no vagrant@controller1
echo 'run-kolla.sh: Running ssh-copy-id vagrant@controller2 - Controller 2'
sshpass -p vagrant ssh-copy-id -o StrictHostKeyChecking=no vagrant@controller2
echo 'run-kolla.sh: Running ssh-copy-id vagrant@controller3 - Controller 3'
sshpass -p vagrant ssh-copy-id -o StrictHostKeyChecking=no vagrant@controller3

echo 'run-kolla.sh: Running ssh-copy-id vagrant@compute1 - Compute 1'
sshpass -p vagrant ssh-copy-id -o StrictHostKeyChecking=no vagrant@compute1
echo 'run-kolla.sh: Running ssh-copy-id vagrant@compute2 - Compute 2'
sshpass -p vagrant ssh-copy-id -o StrictHostKeyChecking=no vagrant@compute2
echo 'run-kolla.sh: Running ssh-copy-id vagrant@compute3 - Compute 3'
sshpass -p vagrant ssh-copy-id -o StrictHostKeyChecking=no vagrant@compute3

echo 'run-kolla.sh: Running scp controller_setup.sh vagrant@controller1:/home/vagrant/controller_setup.sh'
scp -o StrictHostKeyChecking=no controller_setup.sh vagrant@controller1:/home/vagrant/controller_setup.sh
echo 'run-kolla.sh: Running scp controller_setup.sh vagrant@controller2:/home/vagrant/controller_setup.sh'
scp -o StrictHostKeyChecking=no controller_setup.sh vagrant@controller2:/home/vagrant/controller_setup.sh
echo 'run-kolla.sh: Running scp controller_setup.sh vagrant@controller3:/home/vagrant/controller_setup.sh'
scp -o StrictHostKeyChecking=no controller_setup.sh vagrant@controller3:/home/vagrant/controller_setup.sh

echo 'run-kolla.sh: Running scp compute_setup.sh vagrant@compute1:/home/vagrant/compute_setup.sh'
scp -o StrictHostKeyChecking=no compute_setup.sh vagrant@compute1:/home/vagrant/compute_setup.sh
echo 'run-kolla.sh: Running scp compute_setup.sh vagrant@compute2:/home/vagrant/compute_setup.sh'
scp -o StrictHostKeyChecking=no compute_setup.sh vagrant@compute2:/home/vagrant/compute_setup.sh
echo 'run-kolla.sh: Running scp compute_setup.sh vagrant@compute3:/home/vagrant/compute_setup.sh'
scp -o StrictHostKeyChecking=no compute_setup.sh vagrant@compute3:/home/vagrant/compute_setup.sh

echo 'run-kolla.sh: Running ssh vagrant@controller1 "sudo bash /home/vagrant/controller_setup.sh"'
ssh -o StrictHostKeyChecking=no vagrant@controller1 "sudo bash /home/vagrant/controller_setup.sh"
echo 'run-kolla.sh: Running ssh vagrant@controller2 "sudo bash /home/vagrant/controller_setup.sh"'
ssh -o StrictHostKeyChecking=no vagrant@controller2 "sudo bash /home/vagrant/controller_setup.sh"
echo 'run-kolla.sh: Running ssh vagrant@controller3 "sudo bash /home/vagrant/controller_setup.sh"'
ssh -o StrictHostKeyChecking=no vagrant@controller3 "sudo bash /home/vagrant/controller_setup.sh"

echo 'run-kolla.sh: Running ssh vagrant@compute1 “sudo bash /home/vagrant/compute_setup.sh”'
ssh -o StrictHostKeyChecking=no vagrant@compute1 "sudo bash /home/vagrant/compute_setup.sh"
echo 'run-kolla.sh: Running ssh vagrant@compute2 “sudo bash /home/vagrant/compute_setup.sh”'
ssh -o StrictHostKeyChecking=no vagrant@compute2 "sudo bash /home/vagrant/compute_setup.sh"
echo 'run-kolla.sh: Running ssh vagrant@compute3 “sudo bash /home/vagrant/compute_setup.sh”'
ssh -o StrictHostKeyChecking=no vagrant@compute3 "sudo bash /home/vagrant/compute_setup.sh"

ssh -o StrictHostKeyChecking=no vagrant@compute1 "sudo pvcreate /dev/sda && sudo vgcreate cinder-volumes /dev/sda"
#ssh -o StrictHostKeyChecking=no vagrant@compute1 "sudo pvcreate /dev/sda && sudo pvcreate /dev/sdb && sudo vgcreate cinder-volumes /dev/sda /dev/sdb && lvcreate -L 100G -m1 -n lv_mirror cinder-volumes"
ssh -o StrictHostKeyChecking=no vagrant@compute2 "sudo pvcreate /dev/sda && sudo vgcreate cinder-volumes /dev/sda"
ssh -o StrictHostKeyChecking=no vagrant@compute3 "sudo pvcreate /dev/sda && sudo vgcreate cinder-volumes /dev/sda"

ssh -o StrictHostKeyChecking=no vagrant@compute1 "lsblk && sudo vgs"
ssh -o StrictHostKeyChecking=no vagrant@compute2 "lsblk && sudo vgs"
ssh -o StrictHostKeyChecking=no vagrant@compute3 "lsblk && sudo vgs"

# ---- PART TWO ----
# Install Ansible and Kolla-Ansible

sudo bash controller_setup.sh

sudo dnf update -y && sudo dnf install python3-venv python3-pip python3-devel libffi-devel gcc openssl-devel python3-libselinux python3-jinja2 -y

echo 'run-kolla.sh: Install ansible'
sudo pip3 install -U pip
sudo pip3 install --upgrade pip
sudo pip install -U 'ansible<3.0'

if [ $? -ne 0 ]; then
  echo "Cannot install Ansible"
  exit $?
fi

echo 'run-kolla.sh: Running sudo pip install kolla-ansible'
sudo pip3 install 'kolla-ansible == 12.*'
sudo mkdir -p /etc/kolla && sudo chown $USER:$USER /etc/kolla

if [ $? -ne 0 ]; then
  echo "Cannot install kolla-ansible"
  exit $?
fi

# ---- PART THREE ----
# Prepare Deployment Parameter Files
# See also: https://shreddedbacon.com/post/openstack-kolla/

echo 'run-kolla.sh: Running sudo cp -r /usr/local/share/kolla-ansible/etc_examples/kolla/passwords.yml /etc/kolla'
sudo cp -r /usr/local/share/kolla-ansible/etc_examples/kolla/passwords.yml /etc/kolla
echo 'run-kolla.sh: Running sudo cp globals.yml /etc/kolla'
sudo cp globals.yml /etc/kolla

#sudo mkdir -p /etc/kolla/config
#sudo mkdir -p /etc/kolla/config/cinder
#sudo mkdir -p /etc/kolla/config/cinder/cinder-volume
#sudo mkdir -p /etc/kolla/config/cinder/cinder-backup
#sudo mkdir -p /etc/kolla/config/nova
#sudo mkdir -p /etc/kolla/config/glance

cat << EOF | sudo tee /etc/kolla/config/nfs_shares
nfs.vagrant.vm:/sharedvol
EOF

# ---- PART FOUR ----
# Run Kolla-Ansible Playbooks

export ANSIBLE_HOST_KEY_CHECKING=False
export ANSIBLE_LOG_PATH=ansible.log

echo 'run-kolla.sh: Running sudo kolla-genpwd'
sudo kolla-genpwd

echo 'run-kolla.sh: Running kolla-ansible -i multinode bootstrap-servers'
kolla-ansible -i multinode bootstrap-servers

if [ $? -ne 0 ]; then
  echo "Bootstrap servers failed"
  exit $?
fi

echo 'run-kolla.sh: Running kolla-ansible -i multinode prechecks'
kolla-ansible -i multinode prechecks

if [ $? -ne 0 ]; then
  echo "Prechecks failed"
  exit $?
fi

echo 'run-kolla.sh: Running kolla-ansible -i multinode deploy'
kolla-ansible -i multinode deploy

if [ $? -ne 0 ]; then
  echo "Deploy failed"
  exit $?
fi

echo 'run-kolla.sh: Running sudo kolla-ansible -i multinode post-deploy'
sudo kolla-ansible post-deploy

# ---- PART FIVE ----
# Install OpenStack Client and "populate" OpenStack Deployment with Image, Flavors & Networks

echo 'run-kolla.sh: Running sudo apt install python3-openstackclient'
sudo apt install python3-openstackclient -y

echo 'run-kolla.sh: Running sudo cp init-runonce /usr/local/share/kolla-ansible/init-runonce'
sudo cp init-runonce /usr/local/share/kolla-ansible/init-runonce
#echo 'run-kolla.sh: Running cd /usr/local/share/kolla-ansible'
#cd /usr/local/share/kolla-ansible
#echo 'run-kolla.sh: Running sudo ./init-runonce'
#cat <<-EOF | sudo su
#. /etc/kolla/admin-openrc.sh
#./init-runonce
#EOF
echo "Horizon available at 192.168.99.250, user 'admin', password below:"
grep keystone_admin_password /etc/kolla/passwords.yml
