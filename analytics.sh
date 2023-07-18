#!/bin/bash
log_path="/etc/bootLog.txt"
if [ -f "$log_path" ]
then
    echo "Cloud Init script already ran earlier during first time boot.." >> $log_path
else
    touch $log_path
SSH_Conf="/etc/ssh/sshd_config"
DirIP_1="${master_dir_mgmt_ip}"
DirIP_2="${slave_dir_mgmt_ip}"
Address="Match Address $DirIP_1,$DirIP_2"
UBUNTU_RELEASE="$(lsb_release -cs)"
echo "Starting cloud init script..." > $log_path

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
# The secondary network interface
auto eth1
iface eth1 inet dhcp
post-up route add -net ${ctrl_1_network_subnet} gw ${service_vnf_south_bound_ip}
post-up route add -net ${ctrl_2_network_subnet} gw ${service_vnf_south_bound_ip}
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
# The secondary network interface
auto eth1
iface eth1 inet dhcp
    offload-gro off
post-up route add -net ${ctrl_1_network_subnet} gw ${service_vnf_south_bound_ip}
post-up route add -net ${ctrl_2_network_subnet} gw ${service_vnf_south_bound_ip}    
EOF
fi

echo -e "Modified /etc/network/interface file. Refer below new interface file content:\n`cat /etc/network/interfaces`" >> $log_path

echo "Restart Network services.." >> $log_path
if [[ $UBUNTU_RELEASE == "trusty" ]]; then
    /etc/init.d/networking restart >> /dev/null 2>&1
else
    systemctl restart networking >> /dev/null 2>&1
fi
route add -net ${ctrl_1_network_subnet} gw ${service_vnf_south_bound_ip}
route add -net ${ctrl_2_network_subnet} gw ${service_vnf_south_bound_ip}
echo -e "Enanbling ssh login using password." >> $log_path
if ! grep -Fq "$Address" $SSH_Conf; then
    echo -e "Adding the match address exception for Director Management IP.\n" >> $log_path
    sed -i.bak "\$a\Match Address $DirIP_1,$DirIP_2\n  PasswordAuthentication yes\nMatch all" $SSH_Conf
    sudo service ssh restart
else
    echo -e "Director Management IP address is alredy present in file $SSH_Conf.\n" >> $log_path
fi
# volume_extend_log_path="/tmp/volume_extend_Log.txt"
# if [ -f "\$volume_extend_log_path" ]
# then
#     echo "volume extension ran earlier.." >> $volume_extend_log_path
# else
#     (echo n; echo p; echo 3; echo 167770112; echo 2147483646; echo t; echo 3; echo 8e; echo w) | fdisk /dev/nvme0n1 >> $volume_extend_log_path
#     partprobe
#     pvcreate /dev/nvme0n1p3 >> $volume_extend_log_path
#     vgextend system /dev/nvme0n1p3 >> $volume_extend_log_path
#     lvextend -l+100%FREE /dev/system/root >> $volume_extend_log_path
#     resize2fs /dev/mapper/system-root >> $volume_extend_log_path    
# fi
fi
