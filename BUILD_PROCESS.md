# IaC Automation Project - Build Process

This document outlines the steps to build, verify, and teardown the IaC automation project that demonstrates the ability to automate infrastructure using industry-standard infrastructure code tool (Terraform) with a modular approach.

## Project Overview
This project creates a three-tier web application on AWS using Terraform modules:
- **Networking Module**: VPC with public and private subnets, Internet Gateway, NAT Gateways
- **Web Tier Module**: Application Load Balancer, Auto Scaling Group, EC2 instances (running a static HTML web server)
- **Data Tier Module**: Amazon RDS MySQL instance
- **Key Features**: 
  - Modular, reusable Terraform code
  - Resources spread across two Availability Zones for high availability
  - Least-privilege security groups
  - The web tier instances are in public subnets (for simplicity in this demonstration) and the data tier is in private subnets

## Prerequisites
- AWS Account with permissions to create: VPC, EC2, ELB, ASG, RDS, IAM, Security Groups
- AWS CLI configured (`aws configure`)
- Terraform v1.0+ installed
- Key pair (optional, for SSH access to instances)

## Build Process

### Phase 1: Initialize
```bash
cd /home/skyetech/engineer-projects/02-iac-automation/terraform
terraform init
```
*What this does:* Downloads the AWS provider plugin and prepares the working directory.

### Phase 2: Plan (Critical Step)
```bash
terraform plan -out=tfplan
```
*What this does:* Shows exactly what Terraform will create, change, or destroy. **Always review this before applying.**
*What to look for:* 
- Creation of VPC, subnets, IGW, NAT gateways from the VPC module
- Creation of security groups, launch template, ASG, ALB, target group, listener from the web tier module
- Creation of RDS subnet group, security group, and RDS instance from the data tier module
- Zero resources to be destroyed or changed (on first run)

### Phase 3: Apply
```bash
terraform apply tfplan
# or: terraform apply (then type "yes" when prompted)
```
*What this does:* Creates all the defined infrastructure in the correct order.
*Expected output:* 
```
Apply complete! Resources: 20 added, 0 changed, 0 destroyed.

Outputs:
alb_dns_name = "iac-web-alb-1234567890.us-east-1.elb.amazonaws.com"
rds_endpoint = "iac-rds.abcdefg12345.us-east-1.rds.amazonaws.com"
rds_port = 3306
vpc_id = "vpc-0a1b2c3d4e5f6g7h8"
public_subnet_ids = [
  "subnet-0a1b2c3d4e5f6g7h8",
  "subnet-0i9j8k7l6m5n4o3p2"
]
private_subnet_ids = [
  "subnet-0q1r2s3t4u5v6w7x8",
  "subnet-0y9z8x7w6v5u4t3s2"
]
```

### Phase 4: Verify
```bash
# Get the application URL
ALB_DNS=$(terraform output -raw alb_dns_name)
echo "Application URL: http://$ALB_DNS"

# Test the application (should show the static HTML page)
curl -s http://$ALB_DNS
# Expected: "<h1>Hello from Infrastructure as Code Automation Project</h1><p>This page is served by an EC2 instance in an Auto Scaling Group behind a Load Balancer.</p>"

# Verify load balancing (hit multiple times)
for i in {1..5}; do curl -s http://$ALB_DNS; done
# Should return the same static HTML page each time (proof requests are being served by the ASG behind the ALB)

# Check ASG status
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names iac-web-asg \
  --query "AutoScalingGroups[0].{Desired:DesiredCapacity, Min:MinSize, Max:MaxSize, Instances:length(Instances)}"

# Check RDS endpoint (should match output)
aws rds describe-db-instances \
  --db-instance-identifier iac-rds \
  --query "DBInstances[0].Endpoint.Address"
```
*What this does:* Verifies that the application is working (serving the static HTML page), that the load balancer is distributing traffic to the ASG, and that the RDS instance is created and accessible (though not directly from the internet due to security groups).

### Phase 5: Teardown (MANDATORY to avoid charges)
```bash
terraform destroy -auto-approve
# or: terraform destroy (then type "yes" when prompted)
```
*What this does:* Destroys all resources in the correct reverse order of creation.
*Expected output:*
```
Destroy complete! Resources: 20 destroyed.
```

## What This Demonstrates in an Interview
When explaining this project, focus on:

### 1. **Modular Infrastructure as Code**
> "This project shows I can break down infrastructure into reusable, maintainable modules (VPC, web tier, data tier) using Terraform, the industry-standard IaC tool. Each module encapsulates a specific concern and can be versioned and reused independently."

### 2. **Resource Interconnection**
> "I demonstrate how to connect modules securely: the web tier module outputs its security group ID, which is passed to the data tier module to allow database access only from the web tier. This shows understanding of least-privilege networking and module communication."

### 3. **Automation and Reproducibility**
> "The entire infrastructure is defined in code. I can show the exact impact of changes with `terraform plan`, version control the infrastructure in Git, and reproduce identical environments in different stages (dev/test/prod) by changing variables."

### 4. **Production-Minded Design**
> "Even in a demonstration, I've included production essentials: resources spread across multiple AZs for high availability, least-privilege security groups, and separation of concerns (networking, compute, data layers)."

## Files to Reference
- `terraform/main.tf` - The root configuration that calls the modules and defines variables and outputs
- `terraform/modules/vpc/main.tf` - VPC module (public/private subnets, IGW, NAT, route tables)
- `terraform/modules/web_tier/main.tf` - Web tier module (security group, ALB, ASG, launch template with user data for Apache/static HTML)
- `terraform/modules/data_tier/main.tf` - Data tier module (RDS subnet group, security group, RDS instance)
- `BUILD_PROCESS.md` - This document

## Common Pitfalls & How We Avoided Them
| Pitfall | Solution |
|---------|----------|
| Hardcoded credentials | Used variables (in production would use AWS Secrets Manager) |
| Publicly accessible databases | RDS in private subnets with `publicly_accessible = false` |
| Overly permissive security groups | Least-privilege rules: ALB→internet (via its SG), EC2←ALB SG, RDS←web tier SG |
| Not verifying before apply | Mandatory `terraform plan` step |
| Leaving resources running | Explicit destroy process with verification |

## Final Note
This project proves I can automate infrastructure using industry-standard IaC tools with a modular, maintainable approach - exactly what employers look for in DevOps and cloud engineering roles.