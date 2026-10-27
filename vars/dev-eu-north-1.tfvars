aws_region = "eu-north-1"
name       = "jenkins"

# Existing network
vpc_id    = "vpc-05453327b5707036d"
subnet_id = "subnet-005fbcc9ac031915e" # null = first subnet of the VPC
key_name  = "keyForPractice"

# Instance
ami_id           = "ami-0aba19e56f3eaec05" # Ubuntu Server 26.04 LTS, x86_64
instance_type    = "m7i-flex.large"
root_volume_size = 20

# Access (public as requested; tighten SSH to your own IP, e.g. ["203.0.113.10/32"])
jenkins_port                = 8081
ssh_allowed_cidr_blocks     = ["0.0.0.0/0"]
jenkins_allowed_cidr_blocks = ["0.0.0.0/0"]

# For the VPC we create later (not used yet, so keep commented out):
# vpc_cidr = "10.20.0.0/16"
