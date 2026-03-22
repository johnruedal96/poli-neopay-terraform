variable "environment" {
  description = "Environment name"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs"
  type        = list(string)
}

variable "private_compute_subnet_ids" {
  description = "Private compute subnet IDs"
  type        = list(string)
}

variable "private_data_subnet_ids" {
  description = "Private data subnet IDs"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "alb_sg_id" {
  description = "ALB Security Group ID"
  type        = string
}

variable "app_sg_id" {
  description = "App Security Group ID"
  type        = string
}

variable "db_sg_id" {
  description = "DB Security Group ID"
  type        = string
}

variable "ec2_instance_profile_name" {
  description = "EC2 Instance Profile Name"
  type        = string
}

variable "multi_az_db" {
  description = "Enable Multi-AZ for RDS"
  type        = bool
  default     = false
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

# ALB
resource "aws_lb" "main" {
  name               = "neopay-alb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids

  tags = {
    Name        = "neopay-alb-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "app" {
  name     = "neopay-tg-${var.environment}"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 10
    interval            = 30
    timeout             = 5
    matcher             = "200"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# Auto Scaling Group
resource "aws_launch_template" "app" {
  name_prefix   = "neopay-launch-template-${var.environment}"
  image_id      = "ami-0c421724a94bba6d6"
  instance_type = "t3.micro"

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.app_sg_id]
  }

  iam_instance_profile {
    name = var.ec2_instance_profile_name
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y nginx
              echo "<html><body>OK</body></html>" > /usr/share/nginx/html/health
              sed -i 's/listen       80;/listen       8080;/' /etc/nginx/nginx.conf
              systemctl enable nginx
              systemctl start nginx
              EOF
  )

  tags = {
    Name        = "neopay-lt-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_autoscaling_group" "app" {
  name                = "neopay-asg-${var.environment}"
  vpc_zone_identifier = var.private_compute_subnet_ids
  target_group_arns   = [aws_lb_target_group.app.arn]
  max_size            = 3
  min_size            = 1
  desired_capacity    = 1

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "neopay-app-instance-${var.environment}"
    propagate_at_launch = true
  }
}

# RDS Subnet Group
resource "aws_db_subnet_group" "data" {
  name       = "neopay-db-subnet-group-${var.environment}"
  subnet_ids = var.private_data_subnet_ids

  tags = {
    Name        = "neopay-db-subnet-group-${var.environment}"
    Environment = var.environment
  }
}

# RDS Instance
resource "aws_db_instance" "main" {
  allocated_storage      = 20
  db_name                = "neopay"
  engine                 = "postgres"
  engine_version         = "15.10"
  instance_class         = "db.t3.micro"
  username               = "neopay_admin"
  password               = var.db_password
  parameter_group_name   = "default.postgres15"
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.data.name
  vpc_security_group_ids = [var.db_sg_id]
  multi_az               = var.multi_az_db

  tags = {
    Name        = "neopay-db-${var.environment}"
    Environment = var.environment
  }
}

output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "db_endpoint" {
  value = aws_db_instance.main.endpoint
}

output "db_name" {
  value = aws_db_instance.main.db_name
}

output "db_username" {
  value = aws_db_instance.main.username
}
