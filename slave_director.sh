#!/bin/bash
log_path="/etc/bootLog.txt"
if [ -f "$log_path" ]
then
    echo "Cloud Init script already ran earlier during first time boot.." >> $log_path
    echo "exiting the script.."  >> $log_path
    exit        
else
    touch $log_path

SSH_Conf="/etc/ssh/sshd_config"
DirIP_1="${master_dir_mgmt_ip}"
Address="Match Address $DirIP_1"
UBUNTU_RELEASE="$(lsb_release -cs)"
echo "Starting cloud init script...." > $log_path

echo "Modifying /etc/network/interface file.." >> $log_path
cp /etc/network/interfaces /etc/network/interfaces.bak
if [[ $UBUNTU_RELEASE == "trusty" ]]; then
cat > /etc/network/interfaces << EOF
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto eth0
iface eth0 inet dhcp
post-up route add -net 0.0.0.0/0 gw ${mgmt_subnet_gateway} dev eth0
# The secondary network interface
auto eth1
iface eth1 inet dhcp
EOF
else
cat > /etc/network/interfaces << EOF
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

# The loopback network interface
auto lo
iface lo inet loopback
# The primary network interface
auto eth0
iface eth0 inet dhcp
    offload-gro off
post-up route add -net 0.0.0.0/0 gw ${mgmt_subnet_gateway} dev eth0
# The secondary network interface
auto eth1
iface eth1 inet dhcp
    offload-gro off
EOF
fi

echo -e "Modified /etc/network/interface file. Refer below new interface file content:\n`cat /etc/network/interfaces`" >> $log_path

echo "Restart Network services.." >> $log_path
if [[ $UBUNTU_RELEASE == "trusty" ]]; then
    /etc/init.d/networking restart >> /dev/null 2>&1
else
    systemctl restart networking >> /dev/null 2>&1
fi

echo "Modifying /etc/hosts file.." >> $log_path
cp /etc/hosts /etc/hosts.bak
cat > /etc/hosts << EOF
127.0.0.1           localhost
${master_dir_mgmt_ip}         ${hostname_dir_1}
${slave_dir_mgmt_ip}         ${hostname_dir_2}

# The following lines are desirable for IPv6 capable hosts cloudeinit
::1localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF
echo -e "Modified /etc/hosts file. Refer below new hosts file content:\n`cat /etc/hosts`" >> $log_path

echo "Moditing /etc/hostname file.." >> $log_path
hostname ${hostname_dir_2}
cp /etc/hostname /etc/hostname.bak
cat > /etc/hostname << EOF
${hostname_dir_2}
EOF

if [[ $UBUNTU_RELEASE == "bionic" ]]; then
    sudo hostnamectl set-hostname ${hostname_dir_2}
fi

echo "Hostname modified to : `hostname`" >> $log_path

echo "Adding north bond and south bond interface in setup.json file.." >> $log_path
cat > /opt/versa/etc/setup.json << EOF
{
    "input":{
        "version": "1.0",
        "north-bound-interface":[
          "eth0"
        ],      
        "south-bound-interface":[
          "eth1"
        ],
        "hostname": "${hostname_dir_2}",
        "disable-reset-password-for-first-time-user-login":"yes"
     }
}

EOF
# volume_extend_log_path="/tmp/volume_extend_Log.txt"
# if [ -f "\$volume_extend_log_path" ]
# then
#     echo "volume extension ran earlier.." >> $volume_extend_log_path
# else
#     (echo n; echo p; echo 3; echo 314570752; echo 536870910; echo t; echo 3; echo 8e; echo w) | fdisk /dev/nvme0n1 >> $volume_extend_log_path
#     partprobe
#     pvcreate /dev/nvme0n1p3 >> $volume_extend_log_path
#     vgextend system /dev/nvme0n1p3 >> $volume_extend_log_path
#     lvextend -l+100%FREE /dev/system/root >> $volume_extend_log_path
#     resize2fs /dev/mapper/system-root >> $volume_extend_log_path    
# fi
echo -e "Got below data from setup.json file:\n `cat /opt/versa/etc/setup.json`" >> $log_path
echo -e "Enanbling ssh login using password." >> $log_path
if ! grep -Fq "$Address" $SSH_Conf; then
    echo -e "Adding the match address exception for Director Management IP.\n" >> $log_path
    sed -i.bak "\$a\Match Address $DirIP_1\n  PasswordAuthentication yes\nMatch all" $SSH_Conf
    sudo service ssh restart
else
    echo -e "Director Management IP address is alredy present in file $SSH_Conf.\n" >> $log_path
fi
echo "Add DC managment route addition" >> $log_path
echo "Executing the startup script in non interactive mode.." >> $log_path
sleep 1m
sudo -u Administrator /opt/versa/vnms/scripts/vnms-startup.sh --non-interactive
fi