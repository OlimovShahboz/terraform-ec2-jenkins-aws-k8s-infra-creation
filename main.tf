terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  # Applied to every resource, so we don't repeat tags everywhere
  default_tags {
    tags = {
      Project   = var.name
      ManagedBy = "terraform"
    }
  }
}

# ---------------------------------------------------------------
# Data sources (read-only lookups)
# ---------------------------------------------------------------

# Subnets of the existing VPC; the instance is placed in one of them
data "aws_subnets" "selected" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

# The exact AMI we want (Ubuntu 26.04 LTS). Fails at plan time if the ID
# doesn't exist in this region, and lets us check its CPU architecture.
data "aws_ami" "selected" {
  owners = ["099720109477"] # Canonical

  filter {
    name   = "image-id"
    values = [var.ami_id]
  }
}

# ---------------------------------------------------------------
# Security group
# ---------------------------------------------------------------
resource "aws_security_group" "jenkins" {
  name        = "${var.name}-sg"
  description = "Allow SSH and Jenkins, all outbound"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name}-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  for_each = toset(var.ssh_allowed_cidr_blocks)

  security_group_id = aws_security_group.jenkins.id
  description       = "SSH"
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "jenkins" {
  for_each = toset(var.jenkins_allowed_cidr_blocks)

  security_group_id = aws_security_group.jenkins.id
  description       = "Jenkins UI"
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = var.jenkins_port
  to_port           = var.jenkins_port
}

resource "aws_vpc_security_group_egress_rule" "all_out" {
  security_group_id = aws_security_group.jenkins.id
  description       = "All outbound"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# ---------------------------------------------------------------
# IAM: instance role that can access EKS (instead of Action "*")
# ---------------------------------------------------------------
resource "aws_iam_role" "jenkins" {
  name = "${var.name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "eks_access" {
  name = "${var.name}-eks-access"
  role = aws_iam_role.jenkins.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "eks:DescribeCluster",
        "eks:ListClusters",
        "eks:AccessKubernetesApi",
        "eks:DescribeNodegroup",
        "eks:ListNodegroups",
        "eks:DescribeAddon",
        "eks:ListAddons",
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_instance_profile" "jenkins" {
  name = "${var.name}-ec2-profile"
  role = aws_iam_role.jenkins.name
}

# ---------------------------------------------------------------
# EC2 instance
# ---------------------------------------------------------------
resource "aws_instance" "jenkins" {
  ami                         = data.aws_ami.selected.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = coalesce(var.subnet_id, sort(data.aws_subnets.selected.ids)[0])
  vpc_security_group_ids      = [aws_security_group.jenkins.id]
  iam_instance_profile        = aws_iam_instance_profile.jenkins.name
  associate_public_ip_address = true
  user_data                   = file("${path.module}/install_jenkins.sh")

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  # IMDSv2 only; hop limit 2 so containers on the host (docker builds) can still reach the role
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  lifecycle {
    precondition {
      condition     = data.aws_ami.selected.architecture == "x86_64"
      error_message = "The AMI must be x86_64 for ${var.instance_type}."
    }
  }

  tags = {
    Name = var.name
  }
}
