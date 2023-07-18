This Terraform Template is intended to Automate and bringing up Versa Head End setup on AWS in one touch mode.
It will bring up 2 instances of Versa Director, 2 analytics node, service VNF & Versa Controller's in single regions.

# Pre-requisites for using this template:

- **Terraform Install:** To Download & Install Terraform, refer Link "www.terraform.io/downloads.html"
- **Versa Head End Images:** Image available and added in AWS in .ami format for:
  - Versa Director
  - Versa Controller/service VNF
  - Versa Analytics


# Usage:

- Download all the files in PC where Terraform is installed. It is recommended that place all the files in folder as terraform will store the state file for this environment once it is applied.
- Go to the folder "versa_poc_he_auto_config_v1" where all the required files are placed.

- Use command `terraform init` to initialize. it will download necessary terraform plugins required to run this template.
- Then use command `terraform plan` to plan the deployment. It will show the plan regarding all the resources being provisioned as part of this template.
- At last use command `terraform apply` to apply this plan in action for deployment. It will start deploying all the resource on Azure.

The following figure illustrates the redundant (high availability) headend topology created by the Terraform template(s).

It will require below files to run it.


|____README.md
|____main.tf
|____output.tf
|____variable.tf
|____terraform.tfvars
|____analytics.sh
|____slave_director.sh
|____master_director.sh
|____dr_network_config_gen.yaml


**main.tf file:**

main.tf template file will perform below actions/activities when executed:

- It will deploy (Master_Director,slave_director,Analytics,Search,service VNF, controller-1 and controller-2) in region.
- once instances deployed, Master_Director and Slave_Director will initialize the vnms-startup script in non-interactive mode
-service VNF will initialize the cloud-init script along with BGP configuration,
- Master_Director and Slave_Director will form the HA,
- once HA is ready, then van_cluster_installer.py will start to integrate the analytics.
- Post van_cluster_installer.py service VNF, controller-1 and Controller-2 will added to the Director.


**var.tf file:**

var.tf file will have definition for all the variables defined/used as part of this template. User does not need to update anything in this file.

**terraform.tfvars file:**

terraform.tfvars file is being used to get the variables values from user. User need to update the required fields according to their environment. This file will have below information:

###### provider INFO ######
region : Provide the  region deatils to deploy  components. Eg "ap-southeast-1".
access_key : Provide the access key information here. This information will be obtained as part of terraform login.
secret_key : Provide the Secret key information here. This information will be obtained as part of terraform login.
tag_name : Provide the tag info , it will add the tag in every resource Eg: "customer-1"

###### file path example /Users/dinz/Downloads ######
key_pair_file_path : Provide the file path for the key pair Eg: "/Users/dinz/Downloads"
key_pair_name : Provide the key pair name

###### Host Name ######

hostname_dir_1 : Provide the hostname for master Director instances
hostname_dir_2 : Provide the hostname for slave Director instances
analytics_1_hostname : Provide the hostname for Analytics instances
search_1_hostname : Provide the hostname for search instances
controller_1_hostname : Provide the hostname for controller-1 instances
controller_1_country : Provide the country info for controller-1 instances
controller_2_hostname : Provide the hostname for controller-2 instances
controller_2_country : Provide the country info for controller-2 instances

###### INSTANCE TYPE ######

Director_instance_type : Provide the instance type which will be used to provision the Versa Director Instance. By default, c5.2xlarge will be used.
analytics_instance_type : Provide the instance type which will be used to provision the Versa Analytics Instance. By default, c5.4xlarge will be used.
controller_instance_type : Provide the instance type which will be used to provision the Versa Controller Instance. By default, c5.2xlarge will be used.
router_instance_type : Provide the instance type which will be used to provision the Versa service VNF Instance. By default, c5.xlarge will be used.

###### AMI ######
Director_ami : Provide the Versa Director ami for  region
analytics_ami : Provide the Versa Analytics ami for  region
controller_ami : Provide the Versa VOS ami for  region

###### CIDR Subnet INFO ######

cidr_block : Provide the  VPC subnet info. By default "10.153.0.0/16" will be created in .

###### MGNT Subnet INFO ######

mgmt_subnet : Provide the  management/North_bound subnet info. By default "10.153.0.0/24" will be created as management/North_bound subnet in .
mgmt_subnet_gateway : Provide the  management/North_bound gateway IP info. By default "10.153.0.1" will be created as management/North_bound gateway in .
dir_ana_mgnt_interfaces_IP : Provide the management IP details for ["Master_Director",""Slave_Director"","Analytics","Search"]. By default "10.153.0.21","10.153.0.22","10.153.0.23","10.153.0.24" will be created respectively.
controller_flex_mgnt_interfaces_IP : Provide the management IP details for [service_vnf,Controller1,Controller2]. By default "10.153.0.25","10.153.0.26","10.153.0.27" will be created respectively.

#### SOUTH_BOUND Subnet INFO ####

south_bound_network_subnet : Provide the  south bound subnet info. By default "10.153.1.0/24" will be created as south bound subnet in .
south_bound_network_interfaces_IP : Provide the south bound IP details for ["Master_Director","Slave_Director","Analytics","Search",service_vnf]. By default ["10.153.1.21","10.153.1.22","10.153.1.23","10.153.1.24","10.153.1.25"] will be created respectively.

#### Control_1 Network Subnet INFO ####

ctrl_1_network_subnet : Provide the  Control_1 Network subnet info. By default "10.153.2.0/24" will be created.
service_vnf_controller_1_control_network_1_interfaces_IP : Provide the south bound IP details for [service_vnf,Controller1]. By default ["10.153.2.25","10.153.2.26"] will be created respectively.

#### Control_2 Network Subnet INFO ####

ctrl_2_network_subnet : Provide the  Control_1 Network subnet info. By default "10.153.3.0/24" will be created.
service_vnf_controller_1_control_network_1_interfaces_IP : Provide the south bound IP details for [service_vnf,Controller2]. By default ["10.153.3.25","10.153.2.27"] will be created respectively.


#### INTERNET Subnet INFO ####

internet_subnet : Provide the  internet subnet info. By default "10.153.4.0/24" will be created as internet subnet in .
internet_subnet_gateway : Provide the  internet gateway IP info. By default "10.153.4.1" will be created as internet gateway in .
controller_internet_network_interfaces_IP : Provide the  internet IP details for [Controller1,Controller2]. By default ["10.153.4.26","10.153.4.27"] will be created respectively.

#### Accessable subnet ####
If you want you can restrict the subnets
Public_subnet_resource_access ="0.0.0.0/0"

#### ORG NAME ####
parent_org_name = Provide the parent ORG name. By default "versa" will be used as parent ORG
overlay_prefixes = Provide the overlay prefixes . By default "10.0.0.0/8" will be used as overlay prefixes


**output.tf file:**

output.tf file will have information to provide the output
