output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.jenkins.id
}

output "public_ip" {
  description = "Public IP of the Jenkins server"
  value       = aws_instance.jenkins.public_ip
}

output "jenkins_url" {
  description = "Jenkins URL"
  value       = "http://${aws_instance.jenkins.public_ip}:${var.jenkins_port}"
}

output "ssh_command" {
  description = "SSH command (Ubuntu AMI uses the ubuntu user)"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${aws_instance.jenkins.public_ip}"
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.jenkins.id
}

output "iam_role_arn" {
  description = "Instance role ARN: add it as an EKS access entry once the cluster exists"
  value       = aws_iam_role.jenkins.arn
}
