environment             = "prod"
aws_region              = "us-east-1"
vpc_cidr                = "10.1.0.0/16"
public_subnets          = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
private_compute_subnets = ["10.1.10.0/24", "10.1.11.0/24", "10.1.12.0/24"]
private_data_subnets    = ["10.1.20.0/24", "10.1.21.0/24", "10.1.22.0/24"]
availability_zones      = ["us-east-1a", "us-east-1b", "us-east-1c"]
multi_az_db             = true
