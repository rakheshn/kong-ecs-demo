#VPC
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_region" {}

variable "app_name" {
  default = "Kong"
}
variable "aws_vpc_cidr_block" {
  description = "AWS VPC CIDR block."
}

variable "tag" {
  default = "demo"
}

#ECS
variable "ecs_ami" {
  default = "ami-01711df8fe87a6217"
}

variable "ami_owner" {
  default = "591542846629"
}

variable "ecs_cluster_instance_type" {
  #default = "t2.micro"
  default = "m5.xlarge"
}

variable "ssh_key_name" {
  description = "Public key for AWS key pair."
}

variable "app_image" {
  default = "kong:1.0.0rc2"
}
variable "ecs_service_desired_count" {
  default = 1
}
variable "container_memory_reservation" {
  default = 64
}

variable "inbound_cidr_blocks" {
  description = "Trusted networks to be allowed to ingress with ICMP and SSH into the environment."
  type        = "list"
}


# DB
variable "db_name" {}
variable "db_username" {}
variable "db_password" {}

variable "db_engine" {
  default = "postgres"
}

variable "db_engine_version" {
  default = "10"
}

variable "db_instance_class" {
  default = "db.t2.micro"
}

variable "db_port" {
  default = 5432
}
variable "db_maintenance_window" {
  default = "Mon:00:00-Mon:03:00"
}
variable "db_backup_window" {
  default = "03:00-06:00"
}
variable "db_allocated_storage_gb" {
  default = 5
}


# Kong
variable "kong_port_admin" {
  default = "8001"
}
variable "kong_port_http" {
  default = 8000
}
variable "kong_port_https" {
  default = 8443
}


variable "aws_availability_zones" {
  description = "AWS availability zones."
  type        = "list"
}


variable "aws_subnet_cidr_blocks" {
  description = "AWS subnet CIDR blocks. Each availability zone has one subnet."
  type        = "list"
}

variable "aws_ami" {
  description = "AWS AMI for EC2 instances."
}

variable "aws_default_user" {
  description = "AWS default user for EC2 instances."
}

variable "ami_owners" {
  default = "amazon"
}

#autoscale
variable "autoscale_enabled" {
  description = "Setup autoscale."
  default     = "false"
}

variable "autoscale_max_capacity" {
  description = "Max containers count for autoscale."
  default     = "4"
}

variable "service_desired_count" {
  description = "Max containers count for autoscale."
  default     = "1"
}


