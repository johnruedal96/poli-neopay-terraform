variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnets" {
  description = "List of public subnets CIDR"
  type        = list(string)
}

variable "private_compute_subnets" {
  description = "List of private compute subnets CIDR"
  type        = list(string)
}

variable "private_data_subnets" {
  description = "List of private data subnets CIDR"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
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

variable "lambda_producer_arn" {
  description = "ARN of existing producer lambda (empty to skip)"
  type        = string
  default     = ""
}

variable "lambda_consumer_arn" {
  description = "ARN of existing consumer lambda"
  type        = string
  default     = ""
}

variable "alert_email" {
  description = "Email for alerts in production"
  type        = string
  default     = ""
}
