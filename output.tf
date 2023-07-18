
# VPC id
output "vpc_id" {
  value = "${aws_vpc.versa_poc_he_dc_vpc.id}"
}
# Instance ID
output "master_director_instance_id" {
  value = "${aws_instance.versa_poc_he_dc_tf_master_director.id}"
}
output "slave_director_instance_id" {
  value = "${aws_instance.versa_poc_he_dc_tf_slave_director.id}"
}
output "analytics_1_instance_id" {
  value = "${aws_instance.versa_poc_he_dc_tf_analytics[0].id}"
}
output "search_1_instance_id" {
  value = "${aws_instance.versa_poc_he_dc_tf_analytics[1].id}"
}
output "controller_1_instance_id" {
  value = "${aws_instance.versa_poc_he_dc_tf_controller_1.id}"
}
output "controller_2_instance_id" {
  value = "${aws_instance.versa_poc_he_dc_tf_controller_2.id}"
}
output "service_vnf_instance_id" {
  value = "${aws_instance.versa_poc_he_dc_tf_service_vnf.id}"
}


# Main route table id

output "main_route_table_id" {
    value = "${aws_vpc.versa_poc_he_dc_vpc.main_route_table_id}"
}
output "internet_gateway" {
    value = "${aws_internet_gateway.versa_poc_he_dc_ig.id}"
}

#security Group's
# output "security_group_sdwan" {
#   value = "${aws_security_group.versa_poc_he_dc_sg_sdwan.id}"
# }
# output "security_group_Director_Analytics_mgnt" {
#   value = "${aws_security_group.versa_poc_he_dc_sg_dir_ana_mgnt.id}"
# }
# output "security_group_controller_mgnt" {
#   value = "${aws_security_group.versa_poc_he_dc_sg_controller_mgnt.id}"
# }

# output"security_group_south_bound_network" {
#   value = "${aws_security_group.versa_poc_he_dc_sg_internal_network.id}"
# }

#Public IP for managment

output "master_director_mgnt_interface_public_ip" {
  value = "${aws_eip.versa_poc_he_dc_dir_ana_mgnt_interface_public_ip[0].public_ip}"
}
output "slave_director_mgnt_interface_public_ip" {
  value = "${aws_eip.versa_poc_he_dc_dir_ana_mgnt_interface_public_ip[1].public_ip}"
}
# output "analytics_1_mgnt_interface_public_ip" {
#   value = "${aws_eip.versa_poc_he_dc_dir_ana_mgnt_interface_public_ip[1].public_ip}"
# }
# output "search_1_mgnt_interface_public_ip" {
#   value = "${aws_eip.versa_poc_he_dc_dir_ana_mgnt_interface_public_ip[2].public_ip}"
# }
output "controller_1_internet_interface_public_ip" {
  value = "${aws_eip.controller_internet_network_interfaces_IP_public_ip[0].public_ip}"
}
output "controller_2_internet_interface_public_ip" {
  value = "${aws_eip.controller_internet_network_interfaces_IP_public_ip[1].public_ip}"
}

#Private IP
output "service_vnf_mgnt_interface_private_ip" {
  value = "${aws_network_interface.versa_poc_he_dc_controller_flex_mgnt_interface[0].private_ip}"
}
output "service_vnf_south_bound_network_interface_private_ip" {
  value = "${aws_network_interface.versa_poc_he_dc_south_bound_network_interface[4].private_ip}"
}
output "service_vnf_control_network_1_interface_private_ip" {
  value = "${aws_network_interface.versa_poc_he_dc_service_vnf_controller_1_ntw_interface[0].private_ip}"
}
output "service_vnf_control_network_2_interface_private_ip" {
  value = "${aws_network_interface.versa_poc_he_dc_service_vnf_controller_2_ntw_interface[0].private_ip}"
}

output "controller_1_mgnt_interface_private_ip" {
  value = "${aws_network_interface.versa_poc_he_dc_controller_flex_mgnt_interface[1].private_ip}"
}
output "controller_1_control_network_1_interface_private_ip" {
  value = "${aws_network_interface.versa_poc_he_dc_service_vnf_controller_1_ntw_interface[1].private_ip}"
}
output "controller_1_internet_interface_private_ip" {
  value = "${aws_eip.controller_internet_network_interfaces_IP_public_ip[0].private_ip}"
}
output "controller_2_mgnt_interface_private_ip" {
  value = "${aws_network_interface.versa_poc_he_dc_controller_flex_mgnt_interface[2].private_ip}"
}
output "controller_2_control_network_2_interface_private_ip" {
  value = "${aws_network_interface.versa_poc_he_dc_service_vnf_controller_2_ntw_interface[1].private_ip}"
}
output "controller_2_internet_interface_private_ip" {
  value = "${aws_eip.controller_internet_network_interfaces_IP_public_ip[1].private_ip}"
}

output "master_director_mgnt_interface_private_ip" {
  value = "${aws_network_interface.versa_poc_he_dc_dir_ana_mgnt_interface[0].private_ip}"
}
output "master_director_south_bound_network_interface_private_ip" {
  value = "${aws_network_interface.versa_poc_he_dc_south_bound_network_interface[0].private_ip}"
}
output "slave_director_mgnt_interface_private_ip" {
  value = "${aws_network_interface.versa_poc_he_dc_dir_ana_mgnt_interface[1].private_ip}"
}
output "slave_director_south_bound_network_interface_private_ip" {
  value = "${aws_network_interface.versa_poc_he_dc_south_bound_network_interface[1].private_ip}"
}

output "analytics_1_mgnt_interface_private_ip" {
  value = "${aws_network_interface.versa_poc_he_dc_dir_ana_mgnt_interface[2].private_ip}"
}
output "analytics_1_south_bound_network_interface_private_ip" {
  value = "${aws_network_interface.versa_poc_he_dc_south_bound_network_interface[1].private_ip}"
}

output "search_1_mgnt_interface_private_ip" {
  value = "${aws_network_interface.versa_poc_he_dc_dir_ana_mgnt_interface[3].private_ip}"
}
output "search_1_south_bound_network_interface_private_ip" {
  value = "${aws_network_interface.versa_poc_he_dc_south_bound_network_interface[2].private_ip}"
}

#Connect to instance

output "master_director_Connect_to_instance" {
  value = "ssh -i ${var.key_pair_name}.pem Administrator@${aws_eip.versa_poc_he_dc_dir_ana_mgnt_interface_public_ip[0].public_ip}"
} 
output "slave_director_Connect_to_instance" {
  value = "ssh -i ${var.key_pair_name}.pem Administrator@${aws_eip.versa_poc_he_dc_dir_ana_mgnt_interface_public_ip[1].public_ip}"
} 
# output "analytics_1_Connect_to_instance" {
#   value = "ssh -i ${var.key_pair_name}.pem versa@${aws_eip.versa_poc_he_dc_dir_ana_mgnt_interface_public_ip[1].public_ip}"
# } 
# output "search_1_Connect_to_instance" {
#   value = "ssh -i ${var.key_pair_name}.pem versa@${aws_eip.versa_poc_he_dc_dir_ana_mgnt_interface_public_ip[2].public_ip}"
# } 
# output "controller_1_Connect_to_instance" {
#   value = "ssh -i ${var.key_pair_name}.pem admin@${aws_eip.versa_poc_he_dc_controller_flex_mgnt_interface_public_ip[1].public_ip}"
# } 
# output "service_vnf_Connect_to_instance" {
#   value = "ssh -i ${var.key_pair_name}.pem admin@${aws_eip.versa_poc_he_dc_controller_flex_mgnt_interface_public_ip[1].public_ip}"
# } 