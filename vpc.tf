provider "aws" {
  region     = "${var.aws_region}"
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  version    = "~> 2.16.0"
}

resource "aws_s3_bucket" "terraform_state_kong4" {
  bucket = "terraform-remote-state-kong4"
  region = "ap-southeast-2"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = false
  }

  tags {
    Name = "terraform-remote-state4"
  }
}

terraform {
  backend "s3" {
    bucket = "terraform-remote-state-kong4"
    key    = "demo/kong_remote_state"
    region = "ap-southeast-2"
  }
}


# VPC

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> 1.66.0"
  name = "${var.app_name} VPC"
  cidr = "{var.vpc"
  map_public_ip_on_launch = false

  azs = "${data.aws_availability_zones.available.names}"
  private_subnets = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24"]
  public_subnets = [
    "10.0.11.0/24",
    "10.0.12.0/24",
    "10.0.13.0/24"]
  enable_nat_gateway = true
  single_nat_gateway = true
  one_nat_gateway_per_az = false
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = "${var.tag}"
}