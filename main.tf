# Configure the AWS Provider
terraform {
  required_providers {
    aws = {
      version = "~>3.51.0"
    }
  }
}
provider "aws" {

    region = "${var.region}"
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
}

data "aws_availability_zones" "available" {
  state = "available"
}

#create VPC
resource "aws_vpc" "versa_poc_he_dc_vpc" {
  cidr_block       = var.cidr_block
  instance_tenancy = "default"

  tags = {
    Name = "${var.tag_name}_versa_poc_he_dc_vpc"
  }
}

#create internet gateway

resource "aws_internet_gateway" "versa_poc_he_dc_ig" {
  vpc_id = aws_vpc.versa_poc_he_dc_vpc.id
  tags = {
    Name = "${var.tag_name}_versa_poc_he_dc_ig"
  }
}

#Add default route to the internet gateway

resource "aws_default_route_table" "versa_poc_he_dc_rt" {
  default_route_table_id = aws_vpc.versa_poc_he_dc_vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.versa_poc_he_dc_ig.id
  }
  tags = {
    Name = "${var.tag_name}_versa_poc_he_dc_rt"
  }
}


#create security group for Director and analytics

resource "aws_security_group" "versa_poc_he_dc_sg_dir_ana_mgnt" {
  name        = "${var.tag_name}_versa_poc_he_dc_dir_ana_mgnt"
  description = "Open External Ports"
  vpc_id      = aws_vpc.versa_poc_he_dc_vpc.id 
    
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.tag_name}_versa_poc_he_dc_sg_dir_ana_mgnt"
  }
}

# Add ingress rules to Director and analytics private security group


resource "aws_security_group_rule" "versa_poc_he_dc_sg_internal_rules" {
  type              = "ingress"
  from_port        = 0
  to_port          = 0
  protocol         = "-1"
  cidr_blocks       = [var.cidr_block]
  security_group_id = aws_security_group.versa_poc_he_dc_sg_dir_ana_mgnt.id

}


# Add ingress rules to Director and analytics public security group


resource "aws_security_group_rule" "versa_poc_he_dc_sg_dir_ana_public_mgnt_tcp_rules" {
  count = length(var.dir_ana_public_mgnt_tcp_rules)
  type              = "ingress"
  from_port         = var.dir_ana_public_mgnt_tcp_rules[count.index]
  to_port           = var.dir_ana_public_mgnt_tcp_rules[count.index]
  protocol          = "tcp"
  cidr_blocks       = [var.Public_subnet_resource_access]
  security_group_id = aws_security_group.versa_poc_he_dc_sg_dir_ana_mgnt.id

}

#create security group for sdwan

resource "aws_security_group" "versa_poc_he_dc_sg_sdwan" {
  name        = "${var.tag_name}_versa_poc_he_dc_sg_sdwan"
  description = "Allow SDWAN inbound traffic"
  vpc_id      = aws_vpc.versa_poc_he_dc_vpc.id 
    
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.tag_name}_versa_poc_he_dc_sg_sdwan"
  }
}

# Add ingress rules to the sdwan security group


resource "aws_security_group_rule" "versa_poc_he_dc_sg_sdwan_tcp_rules" {
  count = length(var.sdwan_tcp_port)
  type              = "ingress"
  from_port         = var.sdwan_tcp_port[count.index]
  to_port           = var.sdwan_tcp_port[count.index]
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.versa_poc_he_dc_sg_sdwan.id

}
resource "aws_security_group_rule" "versa_poc_he_dc_sg_sdwan_udp_rules" {
  count = length(var.sdwan_udp_port)
  type              = "ingress"
  from_port         = var.sdwan_udp_port[count.index]
  to_port           = var.sdwan_udp_port[count.index]
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.versa_poc_he_dc_sg_sdwan.id

}

#create security group for south_bound_network

resource "aws_security_group" "versa_poc_he_dc_sg_internal_network" {
  name        = "${var.tag_name}_versa_poc_he_dc_sg_internal_network"
  description = "Allow all traffic"
  vpc_id      = aws_vpc.versa_poc_he_dc_vpc.id 
    
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.tag_name}_versa_poc_he_dc_sg_internal_network"
  }
}


#create subnet for managment

resource "aws_subnet" "versa_poc_he_dc_mgnt" {
  vpc_id     = aws_vpc.versa_poc_he_dc_vpc.id
  cidr_block = var.mgmt_subnet
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
  tags = {
    Name = "${var.tag_name}_versa_poc_he_dc_mgnt"
  }
}

  # create Director and Analytics managment interface
  
resource "aws_network_interface" "versa_poc_he_dc_dir_ana_mgnt_interface" {
  count = length(var.dir_ana_mgnt_interfaces)
  subnet_id = aws_subnet.versa_poc_he_dc_mgnt.id
  private_ips = ["${var.dir_ana_mgnt_interfaces_IP[count.index]}"]
  source_dest_check = false
  security_groups = [aws_security_group.versa_poc_he_dc_sg_dir_ana_mgnt.id]
    tags = {
    Name = "${var.tag_name}_versa_poc_he_dc_${var.dir_ana_mgnt_interfaces[count.index]}"

  }
}

#EIPs associated with director managment network interface
resource "aws_eip" "versa_poc_he_dc_dir_ana_mgnt_interface_public_ip" {
  count = length(var.dir_ana_mgnt_Public_interfaces)  
  vpc                       = true
  network_interface         = aws_network_interface.versa_poc_he_dc_dir_ana_mgnt_interface[count.index].id
    tags = {
    Name = "${var.tag_name}_versa_poc_he_dc_${var.dir_ana_mgnt_Public_interfaces[count.index]}"
  }
}


# create controller and flex managment interface

resource "aws_network_interface" "versa_poc_he_dc_controller_flex_mgnt_interface" {
  count = length(var.controller_flex_mgnt_interfaces)    
  subnet_id = aws_subnet.versa_poc_he_dc_mgnt.id
  private_ips = ["${var.controller_flex_mgnt_interfaces_IP[count.index]}"]  
  source_dest_check = false
  security_groups = [aws_security_group.versa_poc_he_dc_sg_internal_network.id]
    tags = {
    Name = "${var.tag_name}_versa_poc_he_dc_${var.controller_flex_mgnt_interfaces[count.index]}"
  }
}

#create subnet for south_bound_network

resource "aws_subnet" "versa_poc_he_dc_south_bound_network" {
  vpc_id     = aws_vpc.versa_poc_he_dc_vpc.id
  cidr_block = var.south_bound_network_subnet
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
  tags = {
    Name = "${var.tag_name}_versa_poc_he_dc_south_bound_network"
  }
}

  # create south_bound_network interface

resource "aws_network_interface" "versa_poc_he_dc_south_bound_network_interface" {
  count = length(var.south_bound_network_interfaces)    
  subnet_id = aws_subnet.versa_poc_he_dc_south_bound_network.id
  private_ips = ["${var.south_bound_network_interfaces_IP[count.index]}"]    
  source_dest_check = false
  security_groups = [aws_security_group.versa_poc_he_dc_sg_internal_network.id]  
    tags = {
    Name = "${var.tag_name}_versa_poc_he_dc_${var.south_bound_network_interfaces[count.index]}"
  }
}

#create subnet for service_vnf and controller_1

resource "aws_subnet" "versa_poc_he_dc_service_vnf_controller_1" {
  vpc_id     = aws_vpc.versa_poc_he_dc_vpc.id
  cidr_block = var.ctrl_1_network_subnet
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
  tags = {
    Name = "${var.tag_name}_versa_poc_he_dc_service_vnf_controller_1"
  }
}  

resource "aws_network_interface" "versa_poc_he_dc_service_vnf_controller_1_ntw_interface" {
  count = length(var.service_vnf_controller_1_control_network_1_interfaces)   
  subnet_id = aws_subnet.versa_poc_he_dc_service_vnf_controller_1.id
  private_ips = ["${var.service_vnf_controller_1_control_network_1_interfaces_IP[count.index]}"]
  source_dest_check = false
  security_groups = [aws_security_group.versa_poc_he_dc_sg_internal_network.id]
    tags = {
    Name = "${var.tag_name}_versa_poc_he_dc_${var.service_vnf_controller_1_control_network_1_interfaces[count.index]}"
  }
}

#create subnet for service_vnf and controller_2

resource "aws_subnet" "versa_poc_he_dc_service_vnf_controller_2" {
  vpc_id     = aws_vpc.versa_poc_he_dc_vpc.id
  cidr_block = var.ctrl_2_network_subnet
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
  tags = {
    Name = "${var.tag_name}_versa_poc_he_dc_service_vnf_controller_2"
  }
}  

resource "aws_network_interface" "versa_poc_he_dc_service_vnf_controller_2_ntw_interface" {
  count = length(var.service_vnf_controller_2_control_network_2_interfaces)   
  subnet_id = aws_subnet.versa_poc_he_dc_service_vnf_controller_2.id
  private_ips = ["${var.service_vnf_controller_2_control_network_2_interfaces_IP[count.index]}"]
  source_dest_check = false
  security_groups = [aws_security_group.versa_poc_he_dc_sg_internal_network.id]
    tags = {
    Name = "${var.tag_name}_versa_poc_he_dc_${var.service_vnf_controller_2_control_network_2_interfaces[count.index]}"
  }
}
#create subnet for Internet

resource "aws_subnet" "versa_poc_he_dc_internet" {
  vpc_id     = aws_vpc.versa_poc_he_dc_vpc.id
  cidr_block = var.internet_subnet
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
  tags = {
    Name = "${var.tag_name}_versa_poc_he_dc_internet"
  }
}

# create controller internet interface

resource "aws_network_interface" "controller_internet_network_interfaces_IP" {
  count = length(var.controller_internet_network_interfaces)   
  subnet_id = aws_subnet.versa_poc_he_dc_internet.id
  private_ips = ["${var.controller_internet_network_interfaces_IP[count.index]}"]   
  source_dest_check = false
  security_groups = [aws_security_group.versa_poc_he_dc_sg_sdwan.id]
    tags = {
    Name = "${var.tag_name}_versa_poc_he_dc_${var.controller_internet_network_interfaces[count.index]}"
  }
}
#EIPs associated with internet network interface
resource "aws_eip" "controller_internet_network_interfaces_IP_public_ip" {
  count = length(var.controller_internet_network_interfaces)   
  vpc                       = true
  network_interface         = aws_network_interface.controller_internet_network_interfaces_IP[count.index].id
    tags = {
    Name = "${var.tag_name}_versa_poc_he_dc_${var.controller_internet_network_interfaces[count.index]}"
  }
}
#Ec2 instance creation

#create Master Director Ec2 instance 

data "template_file" "user_data_master_director" {
  template = file("./master_director.sh")
  
  vars = {
    parent_org_name = var.parent_org_name
    hostname_dir_1 = var.hostname_dir_1
    hostname_dir_2 = var.hostname_dir_2
    analytics_1_hostname = var.analytics_1_hostname
    search_1_hostname = var.search_1_hostname    
    mgmt_subnet_gateway = var.mgmt_subnet_gateway    

    master_dir_mgmt_ip  = "${aws_network_interface.versa_poc_he_dc_dir_ana_mgnt_interface[0].private_ip}"
    master_dir_south_bound_ip = "${aws_network_interface.versa_poc_he_dc_south_bound_network_interface[0].private_ip}"
    slave_dir_mgmt_ip = "${aws_network_interface.versa_poc_he_dc_dir_ana_mgnt_interface[1].private_ip}"
    slave_dir_south_bound_ip = "${aws_network_interface.versa_poc_he_dc_south_bound_network_interface[1].private_ip}"

    service_vnf_eth0_mgnt_ip = "${aws_network_interface.versa_poc_he_dc_controller_flex_mgnt_interface[0].private_ip}"
    service_vnf_mgnt_ip = "${aws_network_interface.versa_poc_he_dc_controller_flex_mgnt_interface[2].private_ip}"

    analytics_mgnt_ip = "${aws_network_interface.versa_poc_he_dc_dir_ana_mgnt_interface[2].private_ip}"
    search_mgnt_ip = "${aws_network_interface.versa_poc_he_dc_dir_ana_mgnt_interface[3].private_ip}"
    analytics_south_bound_ip = "${aws_network_interface.versa_poc_he_dc_south_bound_network_interface[2].private_ip}"
    search_south_bound_ip = "${aws_network_interface.versa_poc_he_dc_south_bound_network_interface[3].private_ip}"
    router_south_bound_ip = "${aws_network_interface.versa_poc_he_dc_south_bound_network_interface[4].private_ip}"

    overlay_prefixes = var.overlay_prefixes    

    controller_1_hostname = var.controller_1_hostname
    controller_1_country = var.controller_1_country
    controller_1_mgnt_ip =  "${aws_network_interface.versa_poc_he_dc_controller_flex_mgnt_interface[1].private_ip}"
    controller_1_south_bound_ip = "${aws_network_interface.versa_poc_he_dc_service_vnf_controller_1_ntw_interface[1].private_ip}"
    controller_1_internet_private_ip = "${aws_network_interface.controller_internet_network_interfaces_IP[0].private_ip}"
    controller_1_internet_public_ip = "${aws_eip.controller_internet_network_interfaces_IP_public_ip[0].public_ip}"
    controller_1_south_bound_subent = var.ctrl_1_network_subnet
    controller_1_internet_subent = var.internet_subnet
    controller_1_internet_subnet_gateway = var.internet_subnet_gateway
    controller_1_router_south_bound_ip = "${aws_network_interface.versa_poc_he_dc_service_vnf_controller_1_ntw_interface[0].private_ip}"
    
    controller_2_hostname = var.controller_2_hostname
    controller_2_country = var.controller_2_country
    controller_2_mgnt_ip = "${aws_network_interface.versa_poc_he_dc_controller_flex_mgnt_interface[2].private_ip}"
    controller_2_south_bound_ip = "${aws_network_interface.versa_poc_he_dc_service_vnf_controller_2_ntw_interface[1].private_ip}"
    controller_2_internet_private_ip = "${aws_network_interface.controller_internet_network_interfaces_IP[1].private_ip}"
    controller_2_internet_public_ip = "${aws_eip.controller_internet_network_interfaces_IP_public_ip[1].public_ip}"
    controller_2_south_bound_subent = var.ctrl_2_network_subnet
    controller_2_internet_subent = var.internet_subnet
    controller_2_internet_subnet_gateway = var.internet_subnet_gateway
    controller_2_router_south_bound_ip = "${aws_network_interface.versa_poc_he_dc_service_vnf_controller_2_ntw_interface[0].private_ip}"

  }
}

data "template_cloudinit_config" "master_director_config" {
  gzip          = true
  base64_encode = true
  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.user_data_master_director.rendered
  }
}
resource "aws_instance" "versa_poc_he_dc_tf_master_director" {
    # count = var.instance_count    
    ami = var.Director_ami
    instance_type = var.Director_instance_type
    root_block_device {
      delete_on_termination = true
      volume_size = "256"
    }
    availability_zone = "${data.aws_availability_zones.available.names[0]}"
    network_interface {
      network_interface_id = aws_network_interface.versa_poc_he_dc_dir_ana_mgnt_interface[0].id
      device_index         = 0
    }    
    network_interface {
      network_interface_id = aws_network_interface.versa_poc_he_dc_south_bound_network_interface[0].id
      device_index         = 1
    }
    user_data = "${data.template_cloudinit_config.master_director_config.rendered}"
    key_name = "${var.key_pair_name}"
    tags = {
      Name = "${var.tag_name}_versa_poc_he_dc_tf_master_director"
    }
}

#create Master Director Ec2 instance 

data "template_file" "user_data_slave_director" {
  template = file("./slave_director.sh")
  
  vars = {
    hostname_dir_1 = var.hostname_dir_1
    hostname_dir_2 = var.hostname_dir_2
    mgmt_subnet_gateway = var.mgmt_subnet_gateway    
    master_dir_mgmt_ip  = "${aws_network_interface.versa_poc_he_dc_dir_ana_mgnt_interface[0].private_ip}"
    slave_dir_mgmt_ip  = "${aws_network_interface.versa_poc_he_dc_dir_ana_mgnt_interface[1].private_ip}"
  }
}

data "template_cloudinit_config" "slave_director_config" {
  gzip          = true
  base64_encode = true
  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.user_data_slave_director.rendered
  }
}
resource "aws_instance" "versa_poc_he_dc_tf_slave_director" {
    # count = var.instance_count    
    ami = var.Director_ami
    instance_type = var.Director_instance_type
    root_block_device {
      delete_on_termination = true
      # volume_size = "256"
    }
    availability_zone = "${data.aws_availability_zones.available.names[0]}"
    network_interface {
      network_interface_id = aws_network_interface.versa_poc_he_dc_dir_ana_mgnt_interface[1].id
      device_index         = 0
    }    
    network_interface {
      network_interface_id = aws_network_interface.versa_poc_he_dc_south_bound_network_interface[1].id
      device_index         = 1
    }
    user_data = "${data.template_cloudinit_config.slave_director_config.rendered}"
    key_name = "${var.key_pair_name}"
    tags = {
      Name = "${var.tag_name}_versa_poc_he_dc_tf_slave_director"
    }
}

#create analytics Ec2 instance 
variable "instance_count" {
  default = "2"
}
data "template_file" "user_data_analytics" {
  template = file("./analytics.sh")
  
  vars = {
    master_dir_mgmt_ip  = "${aws_network_interface.versa_poc_he_dc_dir_ana_mgnt_interface[0].private_ip}"
    slave_dir_mgmt_ip  = "${aws_network_interface.versa_poc_he_dc_dir_ana_mgnt_interface[1].private_ip}"
    ctrl_1_network_subnet = var.ctrl_1_network_subnet
    ctrl_2_network_subnet = var.ctrl_2_network_subnet    
    service_vnf_south_bound_ip = "${aws_network_interface.versa_poc_he_dc_south_bound_network_interface[4].private_ip}"    
  }
}
data "template_cloudinit_config" "analytics_config" {
  gzip          = false
  base64_encode = false
  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.user_data_analytics.rendered
  }
}
resource "aws_instance" "versa_poc_he_dc_tf_analytics" {
    count = var.instance_count
    ami = var.analytics_ami
    instance_type = var.analytics_instance_type
    root_block_device {
      delete_on_termination = true
      # volume_size = "1024"
    }
    availability_zone = "${data.aws_availability_zones.available.names[0]}"
    network_interface {
      network_interface_id = aws_network_interface.versa_poc_he_dc_dir_ana_mgnt_interface[count.index+2].id
      device_index         = 0
    }    
    network_interface {
      network_interface_id = aws_network_interface.versa_poc_he_dc_south_bound_network_interface[count.index+2].id
      device_index         = 1
    }
    user_data = "${data.template_cloudinit_config.analytics_config.rendered}"
    key_name = "${var.key_pair_name}"
    tags = {
      Name = "${var.tag_name}_versa_poc_he_dc_tf_${var.analytics_tag_name[count.index]}"
    }
}
variable "analytics_tag_name" {
  type = list
  default = ["analytics-1","search-1"]
}
#create service_vnf Ec2 instance 
data "template_file" "user_data_service_vnf_cloud_init" {
  template = file("./dc_dr_network_config_gen.yaml")
  
  vars = {

    parent_org_name = var.parent_org_name    
    South_Bound_Network_ip = "${aws_network_interface.versa_poc_he_dc_south_bound_network_interface[4].private_ip}"
    Controller_1_connect  = "${aws_network_interface.versa_poc_he_dc_service_vnf_controller_1_ntw_interface[0].private_ip}"
    Controller_2_connect  = "${aws_network_interface.versa_poc_he_dc_service_vnf_controller_2_ntw_interface[0].private_ip}"

    master_dir_mgmt_ip  = "${aws_network_interface.versa_poc_he_dc_dir_ana_mgnt_interface[0].private_ip}"
    master_dir_south_bound_ip = "${aws_network_interface.versa_poc_he_dc_south_bound_network_interface[0].private_ip}"
    slave_dir_mgmt_ip  = "${aws_network_interface.versa_poc_he_dc_dir_ana_mgnt_interface[1].private_ip}"
    slave_dir_south_bound_ip = "${aws_network_interface.versa_poc_he_dc_south_bound_network_interface[1].private_ip}"
    
    controller_1_router_ip = "${aws_network_interface.versa_poc_he_dc_service_vnf_controller_1_ntw_interface[1].private_ip}"
    controller_2_router_ip = "${aws_network_interface.versa_poc_he_dc_service_vnf_controller_2_ntw_interface[1].private_ip}"
  }
}
data "template_cloudinit_config" "user_data_service_vnf_config" {
  gzip          = false
  base64_encode = false
  part {
    content_type = "text/cloud-config"
    content      = data.template_file.user_data_service_vnf_cloud_init.rendered
  }
}
resource "aws_instance" "versa_poc_he_dc_tf_service_vnf" { 
    ami = var.controller_ami
    instance_type = var.service_vnf_instance_type
    root_block_device {
      delete_on_termination = true
    }
    availability_zone = "${data.aws_availability_zones.available.names[0]}"
    network_interface {
      network_interface_id = aws_network_interface.versa_poc_he_dc_controller_flex_mgnt_interface[0].id
      device_index         = 0
    }    
    network_interface {
      network_interface_id = aws_network_interface.versa_poc_he_dc_south_bound_network_interface[4].id
      device_index         = 1
    }
    network_interface {
      network_interface_id = aws_network_interface.versa_poc_he_dc_service_vnf_controller_1_ntw_interface[0].id
      device_index         = 2
    }
    network_interface {
      network_interface_id = aws_network_interface.versa_poc_he_dc_service_vnf_controller_2_ntw_interface[0].id
      device_index         = 3
    }
    user_data = "${data.template_cloudinit_config.user_data_service_vnf_config.rendered}"
    key_name = "${var.key_pair_name}"
    tags = {
      Name = "${var.tag_name}_versa_poc_he_dc_tf_service_vnf"
    }
}

#create controller_1 Ec2 instance 

resource "aws_instance" "versa_poc_he_dc_tf_controller_1" { 
    ami = var.controller_ami
    instance_type = var.controller_instance_type
    root_block_device {
      delete_on_termination = true
    }
    availability_zone = "${data.aws_availability_zones.available.names[0]}"
    network_interface {
      network_interface_id = aws_network_interface.versa_poc_he_dc_controller_flex_mgnt_interface[1].id
      device_index         = 0
    }    
    network_interface {
      network_interface_id = aws_network_interface.versa_poc_he_dc_service_vnf_controller_1_ntw_interface[1].id
      device_index         = 1
    }
    network_interface {
      network_interface_id = aws_network_interface.controller_internet_network_interfaces_IP[0].id
      device_index         = 2
    }
    user_data = <<-EOF
    #cloud-config
    cloud_init_modules:
      - write-files
      - set_hostname
      - update_hostname
      - users-groups
      - ssh
    hostname: versa-flexvnf
    write_files:
    - content: |
        #writen by cloud-init write-files module
        auto lo
        auto eth0
        iface lo inet loopback
        iface eth0 inet dhcp
      path: /etc/network/interfaces    
    cloud_final_modules:
    - runcmd
    - scripts-user
    runcmd:
    - sed -i.bak "\$a\Match Address ${aws_network_interface.versa_poc_he_dc_dir_ana_mgnt_interface[0].private_ip}/32\n  PasswordAuthentication yes\nMatch all" /etc/ssh/sshd_config
    - sed -i.bak "\$a\Match Address ${aws_network_interface.versa_poc_he_dc_south_bound_network_interface[0].private_ip}/32\n  PasswordAuthentication yes\nMatch all" /etc/ssh/sshd_config
    - sed -i.bak "\$a\Match Address ${aws_network_interface.versa_poc_he_dc_dir_ana_mgnt_interface[1].private_ip}/32\n  PasswordAuthentication yes\nMatch all" /etc/ssh/sshd_config
    - sed -i.bak "\$a\Match Address ${aws_network_interface.versa_poc_he_dc_south_bound_network_interface[1].private_ip}/32\n  PasswordAuthentication yes\nMatch all" /etc/ssh/sshd_config          
    - sudo service ssh restart
      EOF
    key_name = "${var.key_pair_name}"
    tags = {
      Name = "${var.tag_name}_versa_poc_he_dc_tf_controller_1"
    }
}


#create controller_2 Ec2 instance 

resource "aws_instance" "versa_poc_he_dc_tf_controller_2" { 
    ami = var.controller_ami
    instance_type = var.controller_instance_type
    root_block_device {
      delete_on_termination = true
    }
    availability_zone = "${data.aws_availability_zones.available.names[0]}"
    network_interface {
      network_interface_id = aws_network_interface.versa_poc_he_dc_controller_flex_mgnt_interface[2].id
      device_index         = 0
    }    
    network_interface {
      network_interface_id = aws_network_interface.versa_poc_he_dc_service_vnf_controller_2_ntw_interface[1].id
      device_index         = 1
    }
    network_interface {
      network_interface_id = aws_network_interface.controller_internet_network_interfaces_IP[1].id
      device_index         = 2
    }
    user_data = <<-EOF
    #cloud-config
    cloud_init_modules:
      - write-files
      - set_hostname
      - update_hostname
      - users-groups
      - ssh
    hostname: versa-flexvnf
    write_files:
    - content: |
        #writen by cloud-init write-files module
        auto lo
        auto eth0
        iface lo inet loopback
        iface eth0 inet dhcp
      path: /etc/network/interfaces    
    cloud_final_modules:
    - runcmd
    - scripts-user
    runcmd:
    - sed -i.bak "\$a\Match Address ${aws_network_interface.versa_poc_he_dc_dir_ana_mgnt_interface[0].private_ip}/32\n  PasswordAuthentication yes\nMatch all" /etc/ssh/sshd_config
    - sed -i.bak "\$a\Match Address ${aws_network_interface.versa_poc_he_dc_south_bound_network_interface[0].private_ip}/32\n  PasswordAuthentication yes\nMatch all" /etc/ssh/sshd_config
    - sed -i.bak "\$a\Match Address ${aws_network_interface.versa_poc_he_dc_dir_ana_mgnt_interface[1].private_ip}/32\n  PasswordAuthentication yes\nMatch all" /etc/ssh/sshd_config
    - sed -i.bak "\$a\Match Address ${aws_network_interface.versa_poc_he_dc_south_bound_network_interface[1].private_ip}/32\n  PasswordAuthentication yes\nMatch all" /etc/ssh/sshd_config        
    - sudo service ssh restart
      EOF
    key_name = "${var.key_pair_name}"
    tags = {
      Name = "${var.tag_name}_versa_poc_he_dc_tf_controller_2"
    }
}