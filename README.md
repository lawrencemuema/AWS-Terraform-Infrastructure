# AWS-Terraform-Infrastructure

## Overview
This repository contains Terraform scripts to provision and manage infrastructure on AWS.

## Description
The scripts in this repository automate the deployment of a scalable and highly available web application architecture on Amazon Web Services (AWS). The infrastructure includes:

- **Network Setup:** Creates a Virtual Private Cloud (VPC), subnets in different availability zones, and associates them with a custom route table and an internet gateway for internet access.

- **Security Configuration:** Establishes security groups controlling inbound and outbound traffic to EC2 instances.

- **Instance Configuration:** Sets up launch configurations for EC2 instances running an Apache web server and generates an HTML page displaying instance metadata.

- **Auto Scaling and Load Balancing:** Implements an Auto Scaling Group (ASG) and an Application Load Balancer (ALB) for distributing traffic among instances.

## Prerequisites
- Install Terraform on your local machine. ([Terraform Installation Guide](https://learn.hashicorp.com/tutorials/terraform/install-cli))
- Configure AWS credentials with appropriate permissions. ([AWS Configuration Guide](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html))

## Usage
1. Clone this repository:
    ```bash
    git clone https://github.com/lawrencemuema/AWS-Terraform-Infrastructure.git
    cd AWS-Terraform-Infrastructure/
    ```

2. Update the Terraform variables in the `.tf` files as needed.

3. Initialize Terraform and apply the configuration:
    ```bash
    terraform init
    terraform apply
    ```

## Cleanup
To avoid incurring charges, ensure to destroy the resources after use:
```bash
terraform destroy
