variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "subnets" {
  description = "Subnet configuration"
  type = map(object({
    cidr = string
    zone = string
  }))
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
