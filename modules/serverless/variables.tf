variable "environment" {
  description = "Nombre del entorno (dev, prod, ...)"
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC"
  type        = string
}

variable "private_compute_subnet_ids" {
  description = "Subredes privadas con ruta al NAT (Lambda consumidora + SQS API)"
  type        = list(string)
}

variable "lambda_security_group_id" {
  description = "Security group para Lambdas que acceden a RDS"
  type        = string
}

variable "db_host" {
  description = "Hostname RDS (sin puerto)"
  type        = string
}

variable "db_port" {
  description = "Puerto PostgreSQL"
  type        = string
}

variable "db_name" {
  description = "Nombre de la base de datos"
  type        = string
}

variable "db_username" {
  description = "Usuario de la base de datos"
  type        = string
}

variable "db_password" {
  description = "Contraseña de la base de datos"
  type        = string
  sensitive   = true
}

variable "lambda_producer_arn" {
  description = "ARN de la lambda producer existente"
  type        = string
  default     = ""
}

variable "lambda_consumer_arn" {
  description = "ARN de la lambda consumer existente"
  type        = string
  default     = ""
}

variable "lambda_producer_name" {
  description = "Nombre de la lambda producer"
  type        = string
  default     = "neopay-pagos-producer-dev"
}

variable "lambda_consumer_name" {
  description = "Nombre de la lambda consumer"
  type        = string
  default     = "neopay-pagos-consumer-dev"
}

variable "lambda_runtime" {
  description = "Runtime de las lambdas"
  type        = string
  default     = "python3.12"
}

variable "lambda_memory" {
  description = "Memoria en MB para las lambdas"
  type        = number
  default     = 256
}

variable "lambda_timeout" {
  description = "Timeout en segundos para las lambdas"
  type        = number
  default     = 30
}