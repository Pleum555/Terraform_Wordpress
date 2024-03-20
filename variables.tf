# variables.tf

variable "region" {
  description = "AWS region"
}
variable "availability_zone" {
  description = "AWS availability zone"
}
variable "ami" {
  description = "AMI ID for the instances"
}
variable "bucket_name" {
  description = "AWS S3 Bucket"
}
variable "database_name" {
  description = "CIDR block for subnet 4 (private subnet for connecting Wordpress to MariaDB)"
}
variable "database_user" {
  description = "CIDR block for subnet 4 (private subnet for connecting Wordpress to MariaDB)"
}
variable "database_pass" {
  description = "CIDR block for subnet 4 (private subnet for connecting Wordpress to MariaDB)"
}
variable "admin_user" {
  description = "Admin's Password"
}
variable "admin_pass" {
  description = "Admin's Password"
}


variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}
variable "public_subnet1_cidr_block" {
  description = "CIDR block for subnet 1 (public subnet for Wordpress)"
  default     = "10.0.1.0/24"
}
variable "public_subnet2_cidr_block" {
  description = "CIDR block for subnet 2 (public subnet for NAT Gateway)"
  default     = "10.0.2.0/24"
}
variable "private_subnet1_cidr_block" {
  description = "CIDR block for subnet 3 (private subnet for MariaDB)"
  default     = "10.0.3.0/24"
}
variable "private_subnet2_cidr_block" {
  description = "CIDR block for subnet 4 (private subnet for connecting Wordpress to MariaDB)"
  default     = "10.0.4.0/24"
}