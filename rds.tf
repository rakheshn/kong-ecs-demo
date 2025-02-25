# RDS
resource "aws_security_group" "rds_sg" {
  name        = "${var.app_name}-RDS-SG"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress = {
    description               = "Postgres access from ECS cluster"
    protocol                  = "tcp"
    from_port                 = "5432"
    to_port                   = "5432"
    security_groups           = ["${aws_security_group.ecs_service_kong.id}"]
   }
  egress = {
    description = "all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = [
    {
      Name    = "${var.app_name}-RDS-SG"
    }
  ]
}

resource "aws_db_parameter_group" "main" {
  name    = "${var.db_engine}"
  family  = "${var.db_engine}${var.db_engine_version}"

  parameter {
    name         = "autovacuum"
    value        = "1"
    apply_method = "pending-reboot"
  }
}

data "aws_vpc" "selected" {
  tags {
    Name = "${var.app_name} VPC"
  }
}

// To retrieve all subnet ids based on filter
data "aws_subnet_ids" "private" {
  vpc_id            = "${module.vpc.vpc_id}"
  tags {
    Name = "*private*"
  }
}

#Subnet group for rds db
resource "aws_db_subnet_group" "kong" {
  name       = "kong"
//  subnet_ids = ["subnet-0b7a4c5c25bbe6941", "subnet-051752641cc3bb42b", "subnet-0e5594ab09de54bae"]
  subnet_ids = ["${data.aws_subnet_ids.private.ids}"]

  tags = {
    Name = "My DB subnet group"
  }
}


#Creation of Postgres DB
module "rds" {
  source                    = "terraform-aws-modules/rds/aws"
  version                   = "~> 1.29.0"
  identifier                = "${lower(var.app_name)}"  # rds identifier must be lowercase
  name                      = "${var.app_name}"

  engine                    = "${var.db_engine}"
  engine_version            = "${var.db_engine_version}"
  port                      = "${var.db_port}"

  instance_class            = "${var.db_instance_class}"
  allocated_storage         = "${var.db_allocated_storage_gb}"
  maintenance_window        = "${var.db_maintenance_window}"
  backup_window             = "${var.db_backup_window}"

  vpc_security_group_ids    = ["${aws_security_group.rds_sg.id}"]
  subnet_ids                = "${module.vpc.private_subnets}"
  multi_az                  = true
  apply_immediately         = true
  skip_final_snapshot       = true

  parameter_group_name      = "${aws_db_parameter_group.main.name}"
  family                    = "${aws_db_parameter_group.main.family}"

  name                      = "${var.db_name}"
  username                  = "${var.db_username}"
  password                  = "${var.db_password}"
  db_subnet_group_name      =  "kong"

}

