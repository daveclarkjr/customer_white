
#provider INFO
region = "us-east-1"
access_key = "AKIA5MZGWGX2DKLCJ24C"
secret_key = "UkWs9Pi683QDqm8DzKY5luZGebu5diQ75Eo3SITw"
tag_name = "GDIT-POC"

#file path example /Users/dinz/Downloads
key_pair_file_path = "/Users/daclark/tf_projects/gdit/"
key_pair_name = "gdit_poc"

#Host Name for Director
hostname_dir_1 = "cloud-director-1"
hostname_dir_2 = "cloud-director-2"
analytics_1_hostname = "van-analytics-01"
search_1_hostname = "van-search-01"
controller_1_hostname = "Controller-1"
controller_1_country = "US"
controller_2_hostname = "Controller-2"
controller_2_country = "US"

#DC and DR INSTANCE TYPE
## LAB ###
Director_instance_type = "c5.xlarge"
analytics_instance_type = "c5.xlarge"
controller_instance_type = "c5.xlarge"
service_vnf_instance_type = "c5.xlarge"

# ## PRODUCTION ###
# Director_instance_type = "c5.2xlarge"
# analytics_instance_type = "c5.4xlarge"
# controller_instance_type = "c5.2xlarge"
# service_vnf_instance_type = "c5.xlarge"

# # DC 22.1.1 Bionic us-east-1

Director_ami = "ami-0aed4af63b4b40a7a"
analytics_ami = "ami-0dd597856e0c254ce"
controller_ami = "ami-08bfa0efb79cfc4f9"

# # DC 21.3.1 Bionic ap-southeast-1

# Director_ami = "ami-080415a85ce53e39c"
# analytics_ami = "ami-0a859404e0ca8a420"
# controller_ami = "ami-07d23048a79e8ec7c"

#DC-DR CIDR Subnet INFO

cidr_block = "10.153.0.0/16"

#### MGNT Subnet INFO ####
mgmt_subnet = "10.153.0.0/24"
mgmt_subnet_gateway = "10.153.0.1"
#["Master_Director","Slave_Director","Analytics","Search"]
dir_ana_mgnt_interfaces_IP = ["10.153.0.21","10.153.0.22","10.153.0.23","10.153.0.24"]
#[service_vnf,Controller1,Controller2]
controller_flex_mgnt_interfaces_IP = ["10.153.0.25","10.153.0.26","10.153.0.27"]
#### SOUTH_BOUND Subnet INFO ####
south_bound_network_subnet = "10.153.1.0/24"
#["Master_Director","Slave_Director","Analytics","Search",service_vnf]
south_bound_network_interfaces_IP = ["10.153.1.21","10.153.1.22","10.153.1.23","10.153.1.24","10.153.1.25"]
#### ctrl_1 Subnet INFO ####
ctrl_1_network_subnet = "10.153.2.0/24"
#[service_vnf,Controller1]
service_vnf_controller_1_control_network_1_interfaces_IP = ["10.153.2.25","10.153.2.26"]
#### ctrl_2 Subnet INFO ####
ctrl_2_network_subnet = "10.153.3.0/24"
#[service_vnf,Controller2]
service_vnf_controller_2_control_network_2_interfaces_IP = ["10.153.3.25","10.153.3.27"]
internet_subnet = "10.153.4.0/24"
internet_subnet_gateway = "10.153.4.1"
#[Controller1,Controller2]
controller_internet_network_interfaces_IP = ["10.153.4.26","10.153.4.27"]

#Accessable subnet
Public_subnet_resource_access ="0.0.0.0/0"

#ORG NAME
parent_org_name = "versa"

overlay_prefixes = "10.0.0.0/8"
