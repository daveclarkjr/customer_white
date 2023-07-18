
variable "region" {
  description = "Specifie region for instance creation "
}

variable "access_key" {
    description = "Access key of AWS account to be used to deploy VM on AWS."
}

variable "secret_key" {
    description =  "Secret key of AWS account to be used to deploy VM on AWS."
}

variable "key_pair_name" {
    description = "key pair name for device login"
}

variable "key_pair_file_path" {
  description = "Key file path"
}

variable "tag_name" {
  description = "tag Name"
}
variable "hostname_dir_1" {
  description = "Director host name"
  # default = "versa-director-1"
}
variable "hostname_dir_2" {
  description = "Director host name"
  # default = "versa-director-2"
}
variable "analytics_1_hostname" {
  description = "analytics hostname"
  # default = "van-analytics-01"
}
variable "search_1_hostname" {
  description = "search hostname"
  # default = "van-search-01"
}
variable "controller_1_hostname" {
  description = "controller 1 host name"
  # default = "Controller-1"  
}
variable "controller_1_country" {
  description = "controller 1 country name"
  # default = "Singapore"  
}
variable "controller_2_hostname" {
  description = "controller 2 host name"
  # default = "Controller-2"  
}
variable "controller_2_country" {
  description = "controller 2 country name"
  # default = "california"  
}

variable "cidr_block" {
    description = "IPV4 CIDR for VPC creation"
    # default = "10.153.0.0/16"
}

variable "mgmt_subnet" {
  description = "Management Subnet for VM in AWS"
  # default = "10.153.0.0/24"
}
variable "mgmt_subnet_gateway" {
  description = "Management Ip Gateway for director northbound"
  # default = "10.153.0.1"
}
variable "dir_ana_mgnt_interfaces" {
  type = list(string)
  default = ["master_director_mgnt","slave_director_mgnt","analytics_1_mgnt","search_1_mgnt"]
}  
variable "dir_ana_mgnt_Public_interfaces" {
  type = list(string)
  default = ["master_director_public_mgnt","slave_director_public_mgnt"]
} 
variable "dir_ana_mgnt_interfaces_IP" {
  # default = ["10.153.0.21","10.153.0.22","10.153.0.23","10.153.0.24"]
}
variable "controller_flex_mgnt_interfaces" {
  type = list(string)
  default = ["service_vnf_mgnt","controller_1_mgnt","controller_2_mgnt"]
}
variable "controller_flex_mgnt_interfaces_IP" {
  # default = ["10.153.0.25","10.153.0.26","10.153.0.27"]
}

variable "Public_subnet_resource_access" {
  description = "Define public IP to access the resources"
#   default = "103.77.37.189/32"
}

variable "internet_subnet" {
  description = "Internet Subnet for VM in AWS"
  # default = "10.153.4.0/24"
}
variable "internet_subnet_gateway" {
  description = "Internet Gateway for internet rechability"
  # default = "10.153.4.1"
}
variable "controller_internet_network_interfaces" {
  type = list(string)
  default = ["controller_1_internet_ntw","controller_2_internet_ntw"]
}
variable "controller_internet_network_interfaces_IP" {
  # default = ["10.153.4.26","10.153.4.27"]
}
variable "south_bound_network_subnet" {
  description = "control network subnet for VM in AWS"
  # default = "10.153.1.0/24"
}
variable "south_bound_network_interfaces" {
  type = list(string)
  default = ["master_director_south_bound","slave_director_south_bound","analytics_1_south_bound","search_1_south_bound","service_vnf_south_bound_ntw"]
}
variable "south_bound_network_interfaces_IP" {
  # default = ["10.153.1.21","10.153.1.22","10.153.1.23","10.153.1.24","10.153.1.25"]
}
variable "ctrl_1_network_subnet" {
  description = "Controller_1 to svnf"
  # default = "10.153.2.0/24"
}
variable "ctrl_2_network_subnet" {
  description = "Controller_2 to svnf"
  # default = "10.153.3.0/24"
}
variable "service_vnf_controller_1_control_network_1_interfaces" {
  type = list(string)  
  default = ["service_vnf_control_network_1","controller_1_control_network_1"]
}
variable "service_vnf_controller_1_control_network_1_interfaces_IP" {
description = "control_network_1 Interface Ip for service_vnf"
# default = ["10.153.2.23","10.153.2.24"]
}
variable "service_vnf_controller_2_control_network_2_interfaces" {
  type = list(string)  
  default = ["service_vnf_control_network_2","controller_2_control_network_2"]
}
variable "service_vnf_controller_2_control_network_2_interfaces_IP" {
description = "control_network_2 Interface Ip for service_vnf"
# default = ["10.153.3.23","10.153.3.24"]
}
variable "dir_ana_public_mgnt_tcp_rules" {
    description = "Director and Analytics managment ports"
    default = ["22","443","8080","8443"]
    type = list
}

variable "sdwan_tcp_port" {
    description = "Netconf,REST port,Speed Test"
    default = ["2022", "8443","5201"] 
    type = list
}
variable "sdwan_udp_port" {
    description = "IPsec IKE"
    default = ["500", "4500","4790"] 
    type = list
}

variable "controller_ami" {
    description = "AMI Image to be used to deploy Versa FlexVNF Branch"
}

variable "controller_instance_type" {
    description = "Type of Ec2 instance for controller"
}
variable "service_vnf_instance_type" {
    description = "Type of Ec2 instance for service vnf"
}


variable "Director_ami" {
    description = "AMI Image to be used to deploy versa director"
}

variable "Director_instance_type" {
    description = "Type of Ec2 instance for director"
}

variable "analytics_ami" {
    description = "AMI Image to be used to deploy versa analytics"
}

variable "analytics_instance_type" {
    description = "Type of Ec2 instance for analytics"
}

variable "parent_org_name" {
  description = "Define org to auto_deployment"
#   default = "versa"
}
variable "overlay_prefixes" {
  description = "overlay prefixes"
  # default = "10.0.0.0/8"
}


