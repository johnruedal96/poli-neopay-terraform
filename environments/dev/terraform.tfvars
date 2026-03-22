environment             = "dev"
aws_region              = "us-east-1"
vpc_cidr                = "10.0.0.0/16"
public_subnets          = ["10.0.1.0/24", "10.0.2.0/24"]
private_compute_subnets = ["10.0.10.0/24", "10.0.11.0/24"]
private_data_subnets    = ["10.0.20.0/24", "10.0.21.0/24"]
availability_zones      = ["us-east-1a", "us-east-1b"]
multi_az_db             = false
