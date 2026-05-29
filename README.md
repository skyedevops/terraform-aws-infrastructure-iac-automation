

## Project Overview
Creates a three-tier web application on AWS using Terraform modules:
- **Networking Module**: VPC with public/private subnets, Internet Gateway, NAT Gateways
- **Web Tier Module**: Application Load Balancer, Auto Scaling Group, EC2 instances (static HTML server)
- **Data Tier Module**: Amazon RDS MySQL instance
- **Key Features**: Modular, reusable code with least-privilege inter-module communication

## Key Features
- Modular Terraform code promoting reusability and maintainability
- Resources spread across two Availability Zones for high availability
- Least-privilege security groups at each tier
- Clean separation of concerns: networking, compute, data layers
- Environment-agnostic design using variables
- Remote state management ready (S3 + DynamoDB for production)

## Documentation
- [`BUILD_PROCESS.md`](BUILD_PROCESS.md) - Complete build, verify, and teardown process
- [`docs/MODULES_OVERVIEW.md`](docs/MODULES_OVERVIEW.md) - Detailed modules explanation
- [`scripts/test-deployment.sh`](scripts/test-deployment.sh) - Verification script

## Quick Start
```bash
# 1. Initialize
cd terraform
terraform init

# 2. Preview changes
terraform plan

# 3. Apply infrastructure
terraform apply

# 4. Test deployment
../scripts/test-deployment.sh

# 5. Clean up
terraform destroy
```

## Technologies Used
- **Terraform**: Infrastructure as Code (with modules)
- **AWS**: VPC, EC2, ALB, ASG, RDS, IAM, Security Groups
- **Application**: Simple HTML web server

---
