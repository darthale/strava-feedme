variable bucket_name {}
variable appname {}

variable "state_bucket" {}
variable "state_file" {}

variable "image_name" {}
variable "image_tag" {}


variable "vpc_cidr" {
  description = "The CIDR block of the vpc"
}

variable "public_subnets_cidr" {
  type        = "list"
  description = "The CIDR block for the public subnet"
}

variable "private_subnets_cidr" {
  type        = "list"
  description = "The CIDR block for the private subnet"
}

variable "environment" {
  description = "The environment"
}

variable "region" {
  description = "The region to launch the bastion host"
}

variable "availability_zones" {
  type        = "list"
  description = "The az that the resources will be launched"
}

/*variable "key_name" {
  description = "The public key for the bastion host"
}*/

variable "allocated_storage" {
  default     = "20"
  description = "The storage size in GB"
}

variable "instance_class" {
  description = "The instance type"
}

variable "multi_az" {
  default     = false
  description = "Muti-az allowed?"
}

variable "database_name" {
  description = "The database name"
}

variable "database_username" {
  description = "The username of the database"
}

variable "database_password" {
  description = "The password of the database"
}

variable "http_inbound_eni_ip" {
  description = "Inbound http connections from eni"
}

variable "home_ip_address" {
  description = "home ip address"
}