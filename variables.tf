# Declarations only. All values live in vars/dev-eu-north-1.tfvars

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
}

variable "name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "vpc_id" {
  description = "ID of the existing VPC for the security group and instance"
  type        = string
}

variable "subnet_id" {
  description = "Subnet for the instance. If null, the first subnet of the VPC is used (it must be public)"
  type        = string
}

variable "key_name" {
  description = "Name of an existing EC2 key pair for SSH"
  type        = string
}

variable "ami_id" {
  description = "AMI ID (Ubuntu Server 26.04 LTS, x86_64)"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "root_volume_size" {
  description = "Root SSD (gp3) size in GiB"
  type        = number
}

variable "jenkins_port" {
  description = "Port Jenkins listens on (must match install_jenkins.sh)"
  type        = number
}

variable "ssh_allowed_cidr_blocks" {
  description = "Source CIDRs allowed to SSH (port 22)"
  type        = list(string)
}

variable "jenkins_allowed_cidr_blocks" {
  description = "Source CIDRs allowed to open Jenkins"
  type        = list(string)
}
