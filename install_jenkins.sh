#!/bin/bash
# Runs as root via EC2 user_data on Ubuntu 26.04 LTS. Output: /var/log/cloud-init-output.log
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive
cd /tmp

# Install updated packages and base tools
apt-get update
apt-get upgrade -y
#Java 21 (Jenkins requires Java 21 minimum), plus build tools
apt-get install -y fontconfig openjdk-21-jdk git nodejs npm maven unzip jq curl wget gnupg ca-certificates

#Jenkins apt repo (the repo is signed with the 2026 key; the old 2023 key no longer verifies it)
install -d -m 0755 /etc/apt/keyrings
wget -O /etc/apt/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" > /etc/apt/sources.list.d/jenkins.list
apt-get update
apt-get install -y jenkins

#Jenkins port set to 8081 via systemd override (must match jenkins_port in tfvars)
mkdir -p /etc/systemd/system/jenkins.service.d
tee /etc/systemd/system/jenkins.service.d/override.conf <<'EOF'
[Service]
Environment="JENKINS_PORT=8081"
EOF
systemctl daemon-reload

#Docker, and let the jenkins and ubuntu users run it without sudo
apt-get install -y docker.io
systemctl enable --now docker
usermod -aG docker jenkins
usermod -aG docker ubuntu

#Restart Jenkins so it picks up the port override and the docker group
systemctl enable jenkins
systemctl restart jenkins

#AWS CLI v2
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip
unzip -q awscliv2.zip
./aws/install

#ZAP is installed and can be run as zap.sh
wget -q https://github.com/zaproxy/zaproxy/releases/download/v2.17.0/ZAP_2_17_0_unix.sh
chmod +x ZAP_2_17_0_unix.sh
./ZAP_2_17_0_unix.sh -q

#kubectl v1.36 to match the EKS cluster version created in the README
curl -fsSLo kubectl https://dl.k8s.io/release/v1.36.5/bin/linux/amd64/kubectl
install -m 0755 kubectl /usr/local/bin/kubectl

#eksctl (project moved from weaveworks to eksctl-io)
curl -fsSL "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz" | tar xz -C /tmp
install -m 0755 /tmp/eksctl /usr/local/bin/eksctl