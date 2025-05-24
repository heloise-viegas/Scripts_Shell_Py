#!/bin/bash
#Author: Heloise Viegas
#date: 2023-10-04
#version: 1.0
# This script installs the required packages for the project.

# Take EC2 details from the user
echo "Please enter the EC2 instance ID:"
read ec2id
echo "Please enter the region:"
read region
echo "Please enter the full path to your .pem file:"
read keyname
echo "Please enter EC2 username:"
read ec2user
echo "Please enter EC2 public DNS:"
read ec2dns
profile="devops_user"

# Check if EC2 is running; if not, start it
ec2status=$(aws ec2 describe-instance-status --instance-ids $ec2id --output text --region $region --profile $profile | grep INSTANCESTATE | awk '{print $3}')
echo "EC2 status: $ec2status"
if [[ "$ec2status" == "running" ]]
then
  echo "EC2 is running"
else
  echo "EC2 is not running"
  aws ec2 start-instances --instance-ids $ec2id --region $region --profile $profile
  echo "EC2 is starting"
fi

# Connect to the EC2 instance and install packages
ssh -t -i $keyname $ec2user@$ec2dns << EOF
sudo apt update -y
sudo apt upgrade -y

# Install Docker
sudo apt-get install ca-certificates curl -y
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  \$(. /etc/os-release && echo "\${UBUNTU_CODENAME:-\$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
docker --version

# Install kubectl
curl -LO "https://dl.k8s.io/release/\$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/release/\$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "\$(cat kubectl.sha256)  kubectl" | sha256sum --check
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client --output=yaml

# Install AWS CLI
sudo apt-get install unzip -y
sudo apt-get remove awscli -y
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version
EOF

echo "Packages installed successfully on EC2 instance $ec2id in region $region."