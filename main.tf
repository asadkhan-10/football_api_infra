
resource "aws_security_group" "web_sg" {
  description = "launch-wizard-1 created 2026-04-28T05:02:18.944Z"
  egress = [{
    cidr_blocks      = ["0.0.0.0/0"]
    description      = ""
    from_port        = 0
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "-1"
    security_groups  = []
    self             = false
    to_port          = 0
  }]
  ingress = [{
    cidr_blocks      = ["0.0.0.0/0"]
    description      = ""
    from_port        = 22
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "tcp"
    security_groups  = []
    self             = false
    to_port          = 22
    }, {
    cidr_blocks      = ["0.0.0.0/0"]
    description      = ""
    from_port        = 443
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "tcp"
    security_groups  = []
    self             = false
    to_port          = 443
    }, {
    cidr_blocks      = ["0.0.0.0/0"]
    description      = ""
    from_port        = 80
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "tcp"
    security_groups  = []
    self             = false
    to_port          = 80
  }]
  name                   = "launch-wizard-1"
  revoke_rules_on_delete = null
  tags                   = {}
  tags_all               = {}
  vpc_id                 = "vpc-0336a98e647d4eb04"
}

# __generated__ by Terraform
resource "aws_instance" "web" {
  ami                                  = "ami-05d62b9bc5a6ca605"
  associate_public_ip_address          = true
  availability_zone                    = "eu-north-1b"
  disable_api_stop                     = false
  disable_api_termination              = false
  ebs_optimized                        = true
  get_password_data                    = false
  hibernation                          = false
  instance_initiated_shutdown_behavior = "stop"
  instance_type                        = "t3.micro"
  key_name                             = "football-api"
  monitoring                           = false
  placement_partition_number           = 0
  private_ip                           = "172.31.34.241"
  secondary_private_ips                = []
  source_dest_check                    = true
  subnet_id                            = "subnet-081c8c448febe3bc9"
  tags = {
    Name = "football-api"
  }
  tags_all = {
    Name = "football-api"
  }
  tenancy                     = "default"
  user_data_replace_on_change = null
  volume_tags                 = null
  vpc_security_group_ids      = ["sg-0455e46e05624821d"]
  capacity_reservation_specification {
    capacity_reservation_preference = "open"
  }
  cpu_options {
    core_count       = 1
    threads_per_core = 2
  }
  credit_specification {
    cpu_credits = "unlimited"
  }
  enclave_options {
    enabled = false
  }
  maintenance_options {
    auto_recovery = "default"
  }
  metadata_options {
    http_endpoint               = "enabled"
    http_protocol_ipv6          = "disabled"
    http_put_response_hop_limit = 2
    http_tokens                 = "required"
    instance_metadata_tags      = "disabled"
  }
  private_dns_name_options {
    enable_resource_name_dns_a_record    = true
    enable_resource_name_dns_aaaa_record = false
    hostname_type                        = "ip-name"
  }
  root_block_device {
    delete_on_termination = true
    encrypted             = false
    iops                  = 3000
    tags                  = {}
    tags_all              = {}
    throughput            = 125
    volume_size           = 8
    volume_type           = "gp3"
  }
}
