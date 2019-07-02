# IAM roles for ECS
resource "aws_iam_role" "ecs_container_instance" {
  name               = "ecs-container-instance-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}
resource "aws_iam_role_policy" "ecs_instance_role_policy" {
  name     = "ecs_instance_role_policy"
  policy   = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:CreateCluster",
        "ecs:DeregisterContainerInstance",
        "ecs:DiscoverPollEndpoint",
        "ecs:Poll",
        "ecs:RegisterContainerInstance",
        "ecs:StartTelemetrySession",
        "ecs:Submit*",
        "ecs:StartTask"
      ],
      "Resource": "*"
    },
		{
			"Effect": "Allow",
			"Action": [
				"ec2:CreateNetworkInterface",
				"ec2:DescribeNetworkInterfaces",
				"ec2:DetachNetworkInterface",
				"ec2:DeleteNetworkInterface",
				"ec2:AttachNetworkInterface",
				"ec2:DescribeInstances",
				"autoscaling:CompleteLifecycleAction"
			],
			"Resource": "*"
    },
        {
            "Effect": "Allow",
            "Action": [
                  "ec2:AuthorizeSecurityGroupIngress",
                  "ec2:Describe*",
                  "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
                  "elasticloadbalancing:DeregisterTargets",
                  "elasticloadbalancing:Describe*",
                  "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
                  "elasticloadbalancing:RegisterTargets"
            ],
      "Resource": "*"
    }
  ]
}
EOF
  role     = "${aws_iam_role.ecs_container_instance.id}"
}

# Instance profile for this role - to be attached to ECS instances
resource "aws_iam_instance_profile" "ecs" {
  name = "ecs-container-instance-profile"
  path = "/"
  role = "${aws_iam_role.ecs_container_instance.name}"
}


resource "aws_iam_role" "kong_ecs_execution_role" {
  name = "${terraform.workspace}-kong-service-execution-role"
  path = "/"
  description = "Used to allow Kong ECS Service to access AWS Resournces"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "kong_ecs_iam_policy" {
  name = "KongECSServiceExecutionRole"
  role = "${aws_iam_role.kong_ecs_execution_role.name}"
  policy = "${data.aws_iam_policy_document.kong_ecs_execution_policy_document.json}"
}

data "aws_iam_policy_document" "kong_ecs_execution_policy_document" {
  statement {
    effect = "Allow"

    actions = [
      "ecr:*",
      "logs:*"
    ]

    resources = [
      "*",
    ]
  }
}

output "ecs_instance_profile_id" {
  value = "${aws_iam_instance_profile.ecs.id}"
}