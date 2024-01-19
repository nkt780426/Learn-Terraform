# AWS Infrastructure as Code Deployment with Terraform
## Overview
This Terraform script automates the deployment of a basic AWS infrastructure, including a Virtual Private Cloud (VPC), Internet Gateway, Custom Route Table, Subnet, Security Group, Network Interface, Elastic IP, and an Ubuntu EC2 instance running an Apache web server.
## Prerequisites
- AWS account with free tier
- Ubuntu server. If you don't have, you can follow 2 solutions
    - Solution 1: Install [Oracle VM VirtualBox](https://www.virtualbox.org/) and download [ubuntu server](https://ubuntu.com/download/server)
    - Solution 2: Install [wsl2](https://learn.microsoft.com/en-us/windows/wsl/install) and install ubuntu in microsoft store 
*Disclaimer, we do not undertake any responsibility for fees incurred when you follow the instructions below*
## Usage
1. Clone the repository:
```bash
    git clone https://github.com/nkt780426/Learn-Terraform.git
    cd Learn-Terraform
```
2. Initialize Terraform:
```bash
    terraform init
```
3. Login your aws account and write your credentials in terraform.tfvals file
- When you login successfully, you can see *your region* in the right of navigate bar
- In the right of navigation bar, click on *Security credentials*, scroll down and create access/secret key of root account. If you don't want to use root account, you can use access/secret key of IAM account instead.
![key](/images/key.png)
- In EC2 dashboard, you can see *your_avaiability_zone*, select 1 of them. Otherside, create a key pair and put it in terraform.tfvals file
![availability_zone and key pair](/images/Screenshot%202024-01-20%20011030.png)
4. Apply Terraform Configuration:
```bash
    terraform apply -auto-approve
```
5. Access the Deployed Resources:
Once the deployment is complete, the public IP of the EC2 instance is provided in the Terraform output. Use this IP to access the web server.
## Description of code
- **VPC**: Creates a Virtual Private Cloud with a specified CIDR block.
- **Internet Gateway**: Creates an Internet Gateway and associates it with the VPC.
- **Route Table**: Creates a custom route table for IPv4 and IPv6 traffic.
- **Subnet**: Creates a subnet within the VPC with a specified CIDR block.
- **Security Group**: Allows inbound traffic on ports 20, 80, 443, and all outbound traffic.
- **Security Group Rules**: Defines ingress and egress rules for the security group.
- **Network Interface**: Creates a network interface within the subnet.
- **Elastic IP**: Associates an Elastic IP with the network interface.
- **EC2 Instance**: Creates an Ubuntu EC2 instance with Apache installed.
## Result
In terminal, you can see 3 output
- server_public_ip: Public IP address of the EC2 instance.
- server_private_ip: Private IP address of the EC2 instance.
- server_ip: ID of the EC2 instance.
Go to browser and access server_public_ip, you will see this
![result](/images/Screenshot%202024-01-20%20011732.png)
## Notes
Don't forget to destroy resources when you are done
```bash
    terraform destroy -auto-approve
```