#!/bin/bash
log_path="/etc/bootLog.txt"
if [ -f "$log_path" ]
then
    echo "Cloud Init script already ran earlier during first time boot.." >> $log_path
    echo "exiting the script.."  >> $log_path
    exit        
else
    touch $log_path
Van1IP="${analytics_mgnt_ip}"
Van2IP="${search_mgnt_ip}"
Address="Match Address $Van1IP,$Van2IP"
SSH_Conf="/etc/ssh/sshd_config"
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
127.0.0.1			localhost
${master_dir_mgmt_ip}			${hostname_dir_1}
${analytics_mgnt_ip}			${analytics_1_hostname}
${search_mgnt_ip}			${search_1_hostname}

# The following lines are desirable for IPv6 capable hosts cloudeinit
::1localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF
echo -e "Modified /etc/hosts file. Refer below new hosts file content:\n`cat /etc/hosts`" >> $log_path

echo "Moditing /etc/hostname file.." >> $log_path
hostname ${hostname_dir_1}
cp /etc/hostname /etc/hostname.bak
cat > /etc/hostname << EOF
${hostname_dir_1}
EOF
if [[ $UBUNTU_RELEASE == "bionic" ]]; then
    sudo hostnamectl set-hostname ${hostname_dir_1}
fi
echo "Hostname modified to : `hostname`" >> $log_path
echo -e "Generating director self signed certififcates. Refer detail below:\n" >> $log_path
sudo rm -rf /var/versa/vnms/data/certs/
sudo -u versa /opt/versa/vnms/scripts/vnms-certgen.sh --cn ${hostname_dir_1} --san ${hostname_dir_2} --storepass versa123 >> $log_path
sudo chown -R versa:versa /var/versa/vnms/data/certs/
echo "Adding north bond and south bond interface in setup.json file.." >> $log_path
cat > /opt/versa/etc/setup.json << EOF
{
    "input":{
        "version": "1.0",
        "south-bound-interface":[
          "eth1"
        ],
        "north-bound-interface":[
          "eth0"
        ],         
        "hostname": "${hostname_dir_1}",
        "disable-reset-password-for-first-time-user-login":"yes"
     }
}
EOF
volume_extend_log_path="/tmp/volume_extend_Log.txt"
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
sed -i.bak "\$a\Match Address ${slave_dir_mgmt_ip}\n  PasswordAuthentication yes\nMatch all" /etc/ssh/sshd_config
sed -i.bak "\$a\Match Address $Van1IP,$Van2IP\n  PasswordAuthentication yes\nMatch all" $SSH_Conf
sudo service ssh restart
echo "Creating HA auto_config script.." >> $log_path
dcuuid=$(uuidgen)
druuid=$(uuidgen)
controller_1_south_bound_network=$(echo ${controller_1_south_bound_subent} | grep -oP '(/).*')
controller_1_internet_network=$(echo ${controller_1_internet_subent} | grep -oP '(/).*')
controller_2_south_bound_network=$(echo ${controller_2_south_bound_subent} | grep -oP '(/).*')
controller_2_internet_network=$(echo ${controller_2_internet_subent} | grep -oP '(/).*')
cat >> /etc/auto_config.sh << EOF
#!/bin/bash
ha_log_path="/etc/auto_config_Log.txt"
ha_default_log_file="/var/log/vnms/ha/postgre-ha.log"
if [ -f "\$ha_log_path" ]
then
    echo "HA configuration already ran earlier.." >> \$ha_log_path
else
    touch \$ha_log_path
echo -e "Auto script started" >> \$ha_log_path
source /etc/profile.d/versa-profile.sh
result=\$(vsh status)
echo "\$result" >> \$ha_log_path
echo "\$result" | egrep -qi 'failed|stopped|not'
until [ "\$?" -ne 0 ]
do
    echo "Versa Director services not running.." >> \$ha_log_path
    sleep 20
    result=\$(vsh status)
    echo "\$result" | egrep -qi 'failed|stopped|not'
done
sleep 20
echo "terraform user addition.." >> \$ha_log_path
curl -k -u Administrator:versa123 --header "Content-Type: application/json" -X POST https://${master_dir_mgmt_ip}:9182/api/config/nms/actions/_operations/create-user -d '{"create-user":{"user":{"name":"terraform","firstname":"terraform","lastname":"autodeployment","password":"Te**@F0^M","email":".","idle-time-out":"15","user-type":"GENERAL","enable-two-factor":false,"primary-role":"ProviderDataCenterSystemAdmin","personalized-landing-page":"/appliances","homedir":".","ssh_keydir":"."}}}' >> /dev/null 2>&1 >> \$ha_log_path
echo "Checking rechability to the slave director.." >> \$ha_log_path
timeout 3 bash -c "</dev/tcp/${slave_dir_mgmt_ip}/22"
until [ "\$?" -eq 0 ]; do  echo "slave director is not rechable" >> \$ha_log_path; sleep 3; timeout 3 bash -c "</dev/tcp/${slave_dir_mgmt_ip}/22"; done
echo "slave director is rechable ..." >> \$ha_log_path
echo "Checking slave director services..." >> \$ha_log_path
sshpass -p 'versa123' ssh -o StrictHostKeyChecking=no -t admin@${slave_dir_mgmt_ip} 'source /etc/profile.d/versa-profile.sh;echo versa123 | sudo -S whoami;vsh status' | egrep -qi 'failed|stopped|not'
until [ "\$?" -ne 0 ]
do
    echo "Slave Director service Not running"
    sleep 3
    sshpass -p 'versa123' ssh -o StrictHostKeyChecking=no -t admin@${slave_dir_mgmt_ip} 'source /etc/profile.d/versa-profile.sh;echo versa123 | sudo -S whoami;vsh status' | egrep -qi 'failed|stopped|not'
done
sleep 20
echo "HA configuration started.." >> \$ha_log_path
echo -e "request vnmsha actions enable-ha mgmt-ip-address ${master_dir_mgmt_ip} peer-mgmt-ip-address ${slave_dir_mgmt_ip} designated-master-mgmt-ip-address ${master_dir_mgmt_ip}" | ncs_cli -N >> \$ha_log_path
echo "HA configuration completed.." >> \$ha_log_path
echo "Wait for VAN cluster completion ..." >> \$ha_log_path
echo "Refere VAN cluster log after 90s in /etc/analytics_log_path.txt ..." >> \$ha_log_path
sleep 3m
analytics_log_path="/etc/analytics_log_path.txt"
analytics_default_log_file="/var/log/vnms/van_cluster_installer.log"
if [ -f "\$analytics_default_log_file" ]
then
    echo "Van_cluster configuration already ran earlier.." >> \$analytics_log_path
else
    touch \$analytics_log_path
    ha_check=\$(echo -e "request vnmsha actions get-vnmsha-postgres-status" | ncs_cli -N)
    echo \$ha_check >> \$analytics_log_path
    \$(echo "\$ha_check" | egrep -qi 'status  HA is not enabled')
    if [[ \$? -eq 0 ]]; then echo "HA is not enabled ..." >> \$analytics_log_path; echo "exiting the script ..." >> \$analytics_log_path; exit; fi
fi
sleep 20
echo -e "configure\nset nms provider analytics-cluster VAN-Cluster connector-config port 8443
set nms provider analytics-cluster VAN-Cluster connector-config web-addresses van-analytics-01 ip-address ${analytics_mgnt_ip}
set nms provider analytics-cluster VAN-Cluster connector-config web-addresses van-search-01 ip-address ${search_mgnt_ip}
set nms provider analytics-cluster VAN-Cluster log-collector-config port 1234 ip-address [ ${analytics_south_bound_ip} ${search_south_bound_ip} ]\ncommit" | ncs_cli -N

echo "Analytics auto script initiated ..." >> \$analytics_log_path
cd /opt/versa/vnms/scripts/van-cluster-config/van_cluster_install/
./van_cluster_installer.py --force >> /dev/null 2>&1 >> \$analytics_log_path
sleep 60
./van_cluster_installer.py --post-setup >> /dev/null 2>&1 >> \$analytics_log_path
echo "Analytics auto script completed ..." >> \$analytics_log_path
echo "Device creation started .. log_file /etc/auto_config_Log.txt/ ..." >> \$analytics_log_path
sleep 20
echo "Service-vnf local resource creation Started ..." >> \$ha_log_path
curl -v -k -u terraform:Te**@F0^M --header "Content-Type: application/json" https://${master_dir_mgmt_ip}:9182/nextgen/localorganization -d '{"localOrg":{"name":"Service-vnf","uuid":"$dcuuid","localOrgNetworks":[{"name":"Master_director","ipAddressAllocationMode":"manual","ipAddressAllocationModev6":"manual"}],"localInstances":[{"name":"Service-vnf","ipAddress":"${service_vnf_eth0_mgnt_ip}"}]}}' >> /dev/null 2>&1 >> \$ha_log_path
echo "Service-vnf local resource creation completed .." >> \$ha_log_path
echo "Org Configuration started .." >> \$ha_log_path
curl -v -k -u terraform:Te**@F0^M --header "Content-Type: application/json" https://${master_dir_mgmt_ip}:9182/nextgen/organization -d '{"id":1,"name":"${parent_org_name}","authType":"psk","dynamicTenantConfig":{"inactivityInterval":48},"subscriptionPlan":"Default-All-Services-Plan","vrfsGroups":[{"name":"${parent_org_name}-LAN-VR","vrfId":"2","enable_vpn":"true"}],"analyticsClusters":["VAN-Cluster"],"sharedControlPlane":false,"cpeDeploymentType":"SDWAN","cmsOrgs":[{"name":"Service-vnf","uuid":"$dcuuid"}]}}' >> /dev/null 2>&1 >> \$ha_log_path
echo "Org Configuration completed .." >> \$ha_log_path
sleep 20
orguuid=\$(curl -k -u terraform:Te**@F0^M https://${master_dir_mgmt_ip}:9182/vnms/organization/orgs --silent | json_pp | grep uuid | awk  '{print \$3}' | tr -d '"' | tr -d ",")
cat >> service_vnf_json << EOT
{"add-devices":{"devices":{"device":{"mgmt-ip":"${service_vnf_eth0_mgnt_ip}","name":"Service-vnf","org":"\$orguuid","cmsorg":"$dcuuid","type":"service-vnf","discover":"true","snglist":{"sng":[{"name":"Default_All_Services","isPartOfVCSN":true}]},"subscription":{"solution-tier":"NGFW","bandwidth":50,"license-period":1,"custom-param":[]}}}}}
EOT
echo "Service-vnf device addition started .." >> \$ha_log_path
curl -v -k -u terraform:Te**@F0^M --header "Content-Type: application/json" https://${master_dir_mgmt_ip}:9182/api/config/nms/actions/_operations/add-devices -d "@service_vnf_json" >> /dev/null 2>&1 >> \$ha_log_path
echo "Service-vnf device addition complted .." >> \$ha_log_path
echo "Adding static routes for overlay subnets ..." >> \$ha_log_path
curl -k -u terraform:Te**@F0^M --header "Content-Type: application/json" -X POST https://${master_dir_mgmt_ip}:9182/api/config/nms/routing-options/static -d '{"route":{"description":"overlay_prifix_dc","destination-prefix":"${overlay_prefixes}","next-hop-address":"${router_south_bound_ip}","outgoing-interface":"eth1"}}' >> /dev/null 2>&1 >> \$ha_log_path
echo "HA , Analytics Deployment and DC-DR-Router addition completed .." >> \$ha_log_path

echo "Controller Deployment started ..." >> \$ha_log_path
echo "Default Overlay Address Prefixes deletion ..." >> \$ha_log_path
curl -k -u terraform:Te**@F0^M --header "Content-Type: application/json" -X DELETE https://${master_dir_mgmt_ip}:9182/vnms/ipam/overlay/prefixes/1
echo "Overlay Address Prefixes creation ..." >> /dev/null 2>&1 >> \$ha_log_path
curl -k -u terraform:Te**@F0^M --header "Content-Type: application/json" https://${master_dir_mgmt_ip}:9182/vnms/ipam/overlay/prefixes -d '{"prefix": "${overlay_prefixes}","status": {"label": "Active"}}' >> /dev/null 2>&1 >> \$ha_log_path
cat >> controller_1_json << EOT
{"versanms.sdwan-controller-workflow": {"controllerName": "${controller_1_hostname}","orgName": "${parent_org_name}","siteId": "1","stagingController": "true","postStagingController": "true","resourceType": "Baremetal","analyticsCluster": "VAN-Cluster","ipv4dhcp": "false","locationInfo": {"country": "${controller_1_country}"},"bgp":{"peerIP":"${controller_1_router_south_bound_ip}","peerIPAs":"64002"},"baremetalController": {"serverIP": "${controller_1_mgnt_ip}","controllerInterface": {"interfaceName": "vni-0/0","unitInfoList": [{"networkName": "To_Director","vlanId": 0,"ipv4address": ["${controller_1_south_bound_ip}$controller_1_south_bound_network"],"ipv6gateway": "","ipv4gateway": "${master_dir_south_bound_ip}"}]},"wanInterfaces": [{"interfaceName": "vni-0/1","unitInfoList": [{"ipv4address": ["${controller_1_internet_private_ip}$controller_1_internet_network"],"vlanId": "0","networkName": "Internet","ipv4dhcp": false,"ipv6dhcp": false,"ipv4gateway": "${controller_1_internet_subnet_gateway}","publicIPAddress": "${controller_1_internet_public_ip}","wanStaging": true,"poolSize": "128","transportDomainList": ["Internet"]}]}]}}} >> /dev/null 2>&1 >> \$ha_log_path
EOT
orguuid=\$(curl -k -u terraform:Te**@F0^M https://${master_dir_mgmt_ip}:9182/vnms/organization/orgs --silent | json_pp | grep uuid | awk  '{print \$3}' | tr -d '"' | tr -d ",")
echo -e "\n creating Wan Networks ..." >> \$ha_log_path
echo \`curl -k -u terraform:Te**@F0^M --header "Content-Type: application/json" -X POST https://${master_dir_mgmt_ip}:9182/nextgen/organization/\$orguuid/wan-networks -d '{"name":"Internet","transport-domains":["Internet"],"description":""}'\` >> /dev/null 2>&1 >> \$ha_log_path
echo "controller_1 save initiated ..." >> \$ha_log_path
curl -k -u terraform:Te**@F0^M --header "Content-Type: application/json" -X POST https://${master_dir_mgmt_ip}:9182/vnms/sdwan/workflow/controllers/controller -d "@controller_1_json" >> /dev/null 2>&1 >> \$ha_log_path
sleep 10
echo "Deploying controller 1 ..." >> \$ha_log_path
curl -k -u terraform:Te**@F0^M --header "Content-Type: application/json" -X POST https://${master_dir_mgmt_ip}:9182/vnms/sdwan/workflow/controllers/controller/deploy/${controller_1_hostname} >> /dev/null 2>&1 >> \$ha_log_path
echo -e "\ncontroller 1 deployment completed ..." >> \$ha_log_path
sleep 10
echo "controller 2 save initiated ..." >> \$ha_log_path
curl -k -u terraform:Te**@F0^M --header "Content-Type: application/json" -X POST https://${master_dir_mgmt_ip}:9182/vnms/sdwan/workflow/controllers/controller -d '{"versanms.sdwan-controller-workflow": {"controllerName": "${controller_2_hostname}","orgName": "${parent_org_name}","siteId": "2","peerControllers":["${controller_1_hostname}"],"stagingController": "true","postStagingController": "true","resourceType": "Baremetal","analyticsCluster": "VAN-Cluster","ipv4dhcp": "false","locationInfo": {"country": "${controller_2_country}"},"bgp":{"peerIP":"${controller_2_router_south_bound_ip}","peerIPAs":"64002"},"baremetalController": {"serverIP": "${controller_2_mgnt_ip}","controllerInterface": {"interfaceName": "vni-0/0","unitInfoList": [{"networkName": "To_Director","vlanId": 0,"ipv4address": ["${controller_2_south_bound_ip}$controller_2_south_bound_network"],"ipv6gateway": "","ipv4gateway": "${slave_dir_south_bound_ip}"}]},"wanInterfaces": [{"interfaceName": "vni-0/1","unitInfoList": [{"ipv4address": ["${controller_2_internet_private_ip}$controller_2_internet_network"],"vlanId": "0","networkName": "Internet","ipv4dhcp": false,"ipv6dhcp": false,"ipv4gateway": "${controller_2_internet_subnet_gateway}","publicIPAddress": "${controller_2_internet_public_ip}","wanStaging": true,"poolSize": "128","transportDomainList": ["Internet"]}]}]}}}' >> /dev/null 2>&1 >> \$ha_log_path
sleep 10
echo "Deploying controller 2 ..." >> \$ha_log_path
curl -k -u terraform:Te**@F0^M --header "Content-Type: application/json" -X POST https://${master_dir_mgmt_ip}:9182/vnms/sdwan/workflow/controllers/controller/deploy/${controller_2_hostname} >> /dev/null 2>&1 >> \$ha_log_path
echo -e "\ncontroller 2 deployment completed ..." >> \$ha_log_path
sleep 20
echo "Terraform user deletion ..." >> \$ha_log_path
echo -e 'configure\ndelete aaa authentication users user terraform\ncommit' | ncs_cli -N >> \$ha_log_path
sshpass -p 'versa123' ssh -o StrictHostKeyChecking=no -t admin@${slave_dir_mgmt_ip} 'echo versa123 | sudo -S whoami;sudo reboot' >> \$ha_log_path
echo -e "\nAuto Deployment completed successfully ..." >> \$ha_log_path
exit
fi
EOF
echo "Modifying /opt/versa/vnms/scripts/van-cluster-config/van_cluster_install/clustersetup.conf file.." >> $log_path
cp /opt/versa/vnms/scripts/van-cluster-config/van_cluster_install/clustersetup.conf /opt/versa/vnms/scripts/van-cluster-config/van_cluster_install/clustersetup.conf_bak
cat > /opt/versa/vnms/scripts/van-cluster-config/van_cluster_install/clustersetup.conf << EOF
[VAN_CLUSTER_SETUP_CONF]
cluster_size:2
cluster_name:VAN-Cluster
forwarder_count: 0
[VERSA_DIRECTOR]
director_count:2
[VERSA-DIR-1]
username: Administrator
password:versa123
rpc_address: ${master_dir_mgmt_ip}
listen_address: ${master_dir_south_bound_ip}
[VERSA-DIR-2]
username: Administrator
password:versa123
rpc_address: ${slave_dir_mgmt_ip}
listen_address: ${slave_dir_south_bound_ip}
[VAN-NODE-1]
username: versa
password:versa123
mode:cluster
hostname:${analytics_1_hostname}
personality:analytics
rpc_address: ${analytics_mgnt_ip}
listen_address: ${analytics_south_bound_ip}
collector_address: ${analytics_south_bound_ip}
collector_port:1234
[VAN-NODE-2]
username: versa
password:versa123
mode:cluster
hostname:${search_1_hostname}
personality:search
rpc_address: ${search_mgnt_ip}
listen_address: ${search_south_bound_ip}
collector_address: ${search_south_bound_ip}
collector_port:1234
EOF
echo "Executing the startup script in non interactive mode.." >> $log_path
sudo -u Administrator /opt/versa/vnms/scripts/vnms-startup.sh --non-interactive  >> /dev/null 2>&1
echo -e "Start_up script started.." >> $log_path
fi
chmod +x /etc/auto_config.sh
crontab -l > auto_config
echo "@reboot sleep 90 && /etc/auto_config.sh" >> auto_config
crontab auto_config
