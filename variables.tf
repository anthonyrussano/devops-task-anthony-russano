variable "project_name" {
  description = "Name prefix used for AWS resources."
  type        = string
  default     = "pci-poc"
}

variable "environment" {
  description = "Environment tag value."
  type        = string
  default     = "poc"
}

variable "aws_region" {
  description = "AWS region where the POC is deployed."
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the dedicated POC VPC."
  type        = string
  default     = "10.42.0.0/16"
}

variable "allowed_ingress_cidrs" {
  description = "Finite list of source CIDRs allowed to reach the public ALB."
  type        = list(string)
  default     = ["203.0.113.10/32"]

  validation {
    condition     = length(var.allowed_ingress_cidrs) > 0
    error_message = "At least one allowed source CIDR must be provided."
  }
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN used by the HTTPS listener on the internet-facing ALB."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the POC Linux instances."
  type        = string
  default     = "t3.micro"
}

variable "app_port" {
  description = "HTTP port exposed by the app instance to the ALB."
  type        = number
  default     = 80
}

variable "mysql_port" {
  description = "MySQL port exposed by the database instance to the app."
  type        = number
  default     = 3306
}

variable "egress_proxy_port" {
  description = "Forward proxy port used by app instances for controlled outbound internet access."
  type        = number
  default     = 3128
}

variable "package_repository_domain" {
  description = "Domain required during app instance startup for package installation."
  type        = string
  default     = "example.com"
}

variable "daily_operation_domain" {
  description = "External HTTPS domain required for daily app operation."
  type        = string
  default     = "secureweb.com"
}

variable "ssh_key_name" {
  description = "Optional EC2 key pair name. Prefer SSM Session Manager for auditability."
  type        = string
  default     = null
}

variable "root_volume_size_gb" {
  description = "Encrypted root volume size for each EC2 instance."
  type        = number
  default     = 20
}

