# ECS Cluster
resource "aws_security_group" "ecs_sg" {
  name        = "${var.app_name}-ECS-SG"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress = {
    description       = "all from self + alb"
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    security_groups   = ["${aws_security_group.alb_sg.id}"]
    self              = true
  }
  egress = {
    description = "all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags  = [
    {
      Name = "${var.app_name}-ECS-SG"
    }
  ]
}

resource "aws_ecs_cluster" "main" {
  name = "${var.app_name}"
}


data "template_file" "ecs_user_data" {
  template = <<EOF
#!/bin/bash
cat << EOF_CONFIG > /etc/ecs/ecs.config
ECS_CLUSTER=${var.app_name}
ECS_ENABLE_TASK_IAM_ROLE=true
ECS_ENABLE_TASK_ENI=true
ECS_DISABLE_PRIVILEGED=false
ECS_AWSVPC_BLOCK_IMDS=false
EOF_CONFIG
EOF
}


module "asg" {
  source                      = "terraform-aws-modules/autoscaling/aws"
  version                     = "~> 2.10.0"
  name                        = "${var.app_name}-ECS-ASG"
  image_id                    = "${var.ecs_ami}"
//  owner                      = "${var.ami_owner}"
  instance_type               = "${var.ecs_cluster_instance_type}"
  key_name                    = "${var.ssh_key_name}"


  # Launch configuration
  lc_name                     = "${var.app_name}-ECS-LC"
  create_lc                   = true
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.ecs.id}"
  vpc_zone_identifier         = ["${module.vpc.public_subnets}"]
  user_data                   = "${data.template_file.ecs_user_data.rendered}"

  security_groups = [
    "${aws_security_group.ecs_sg.id}"
  ]

  # Auto scaling group
  asg_name                    = "${var.app_name}-ECS-ASG"
  health_check_type           = "EC2"
  min_size                    = 1
  max_size                    = 2
  desired_capacity            = 1
  wait_for_capacity_timeout   = 0
  tags = [
    {
      key                     = "Environment"
      value                   = "demo"
    }
  ]

}