#ECS Task Definition
resource "aws_ecs_task_definition" "kong" {
  family = "${var.app_name}"
  network_mode = "awsvpc"
  execution_role_arn = "${aws_iam_role.kong_ecs_execution_role.arn}"
  cpu = "1024"
  memory = "3072"
  container_definitions = <<DEFINITION
                              [
    {
      "name": "${var.app_name}",
      "image": "${var.app_image}",
      "cpu": 1,
      "memory": 512,
      "portMappings": [
        {
          "containerPort": 8000,
          "hostPort": 8000,
          "protocol": "tcp"
        },
        {
          "containerPort": 8001,
          "hostPort": 8001,
          "protocol": "tcp"
        },
        {
          "containerPort": 8443,
          "hostPort": 8443,
          "protocol": "tcp"
        }
      ],
      "command": [
        "kong",
        "docker-start"
      ],
      "essential": true,
      "environment": [
        {
          "name": "KONG_PG_DATABASE",
          "value": "postgres"
        },
        {
          "name": "KONG_PG_HOST",
          "value": "${replace(module.rds.this_db_instance_endpoint, "/:.*/", "")}"
        },
        {
          "name": "KONG_PG_USER",
          "value": "${var.db_username}"
        },
        {
          "name": "KONG_PG_PASSWORD",
          "value": "${var.db_password}"
        },
        {
          "name": "KONG_PROXY_ACCESS_LOG",
          "value": "/dev/stdout"
        },
        {
          "name": "KONG_ADMIN_ACCESS_LOG",
          "value": "/dev/stdout"
        },
        {
          "name": "KONG_PROXY_ERROR_LOG",
          "value": "/dev/stderr"
        },
        {
          "name": "KONG_ADMIN_ERROR_LOG",
          "value": "/dev/stderr"
        },
        {
          "name": "KONG_ADMIN_LISTEN",
          "value": "0.0.0.0:8001, 0.0.0.0:8444 ssl"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.environment_cloudwatch_group.name}",
          "awslogs-region": "${var.aws_region}",
          "awslogs-stream-prefix": "kong"
        }
      },
      "ulimits": [
        {
          "softLimit": 4096,
          "hardLimit": 4096,
          "name": "nofile"
        }
      ],
      "healthCheck": {
        "command": [ "CMD-SHELL", "curl -f http://localhost:8001/status || exit 1" ],
        "interval": 5,
        "timeout": 5,
        "retries": 3,
        "startPeriod": 0
      }
    }
  ]
  DEFINITION
}

#Create ECS service
resource "aws_ecs_service" "kong" {
  name                = "${var.app_name}"
  launch_type         = "EC2"
  cluster             = "${aws_ecs_cluster.main.id}"
  task_definition     = "${aws_ecs_task_definition.kong.arn}"
  desired_count       = "${var.ecs_service_desired_count}"

//  scheduling_strategy = "DAEMON"

  load_balancer {
    target_group_arn  = "${aws_alb_target_group.main.id}"
    container_name    = "${var.app_name}"
    container_port    = "${var.kong_port_http}"

  }

  network_configuration {
    subnets             = ["${module.vpc.public_subnets}"]
    assign_public_ip    = false
    security_groups     = ["${aws_security_group.ecs_service_kong.id}"]
  }
  depends_on = [
    "aws_alb.main"
  ]
}

#ECS Cloudwatch logs
resource "aws_cloudwatch_log_group" "environment_cloudwatch_group" {
  name = "${terraform.workspace}/kong"
  retention_in_days = "5"
}


resource "aws_security_group" "ecs_service_kong" {
  name        = "${var.app_name}-ECS-SG-kong"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress = {
    description       = "all from self + alb + bastion + kong dash"
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    security_groups   = [
      "${aws_security_group.alb_sg.id}"
    ]
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
      Name = "${var.app_name}-ECS-SG-kong"
    }
  ]
}