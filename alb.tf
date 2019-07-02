resource "aws_security_group" "alb_sg" {
  name = "${var.app_name}-ALB-SG"
  vpc_id = "${module.vpc.vpc_id}"
  ingress {
    from_port = 8000
    protocol = "tcp"
    to_port = 8000
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 8001
    protocol = "tcp"
    to_port = 8001
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    protocol = "tcp"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_alb" "main" {
  name = "${var.app_name}-ALB"
  subnets = ["${module.vpc.public_subnets}"]
  security_groups = ["${aws_security_group.alb_sg.id}"]
}

resource "aws_lb_listener" "main" {
  "default_action" {
    type = "forward"
    target_group_arn  = "${aws_alb_target_group.main.arn}"
  }
  load_balancer_arn = "${aws_alb.main.arn}"
  port = 80
  protocol = "HTTP"
}

resource "aws_alb_target_group" "main" {
  name              = "${var.app_name}-TG-HTTP"
  port              = 80
  protocol          = "HTTP"
  vpc_id            = "${module.vpc.vpc_id}"
  target_type       = "ip"
  stickiness {
    type            = "lb_cookie"
  }
  health_check {
    path            = "/"
    matcher         = "200"
  }
}

output "alb_dns_name" {
  value = "${aws_alb.main.dns_name}"
}
output "alb_zone_id" {
  value = "${aws_alb.main.zone_id}"
}
