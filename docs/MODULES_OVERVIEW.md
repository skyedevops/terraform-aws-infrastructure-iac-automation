# IaC Automation Project - Modules Overview

This document explains the IaC automation project that demonstrates the ability to automate infrastructure using industry-standard infrastructure code tool (Terraform) with a modular approach.

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

## Module Structure

```
terraform/
├── main.tf              # Root configuration calling modules
├── variables.tf         # Input variables
├── outputs.tf           # Output values
├── modules/
│   ├── vpc/             # Networking module
│   │   ├── main.tf
│   │   └── variables.tf
│   ├── web_tier/        # Web tier module (ALB, ASG, EC2)
│   │   ├── main.tf
│   │   └── variables.tf
│   └── data_tier/       # Data tier module (RDS)
│       ├── main.tf
│       └── variables.tf
└── ...
```

## Module Details

### 1. Networking Module (`modules/vpc/`)

**Purpose**: Creates the foundational network infrastructure for the application.

**Resources Created**:
- VPC with specified CIDR block
- Internet Gateway for public internet access
- Public Subnets (2) in different Availability Zones
- Private Subnets (2) in different Availability Zones
- NAT Gateways (2) for private subnet outbound internet access
- Route Tables and Associations for proper traffic routing

**Key Features**:
- Resources spread across two Availability Zones for high availability
- Proper segmentation: public subnets for internet-facing components, private subnets for internal components
- NAT Gateways allow private instances to initiate outbound connections (for updates, etc.) while preventing inbound internet access
- Outputs: VPC ID, public subnet IDs, private subnet IDs

### 2. Web Tier Module (`modules/web_tier/`)

**Purpose**: Creates the compute and load balancing layers for serving web traffic.

**Resources Created**:
- Security Group for web tier (allows HTTP from ALB and SSH from anywhere)
- Application Load Balancer (internet-facing)
- Target Group for the ALB
- Listener for the ALB (HTTP 80 to target group)
- Launch Template for EC2 instances
- Auto Scaling Group
- Autoscaling attachment (ASG to target group)

**Key Features**:
- Uses latest Ubuntu AMI via data source
- User data script installs Apache and serves a static HTML page
- ASG configured with desired/min/max capacity (2/1/3)
- ASG spans public subnets (for simplicity in this demo - in production with a separate data tier, ASG would typically be in private subnets)
- Least-privilege security: ALB SG allows HTTP from internet, EC2 SG allows HTTP only from ALB SG
- Outputs: ALB DNS name, web tier security group ID

### 3. Data Tier Module (`modules/data_tier/`)

**Purpose**: Creates the data storage layer for the application.

**Resources Created**:
- DB Subnet Group using private subnets
- Security Group for RDS (allows MySQL from web tier)
- RDS MySQL Instance

**Key Features**:
- RDS instance placed in private subnets (isolated from direct internet access)
- Security group only allows MySQL access from the web tier security group
- RDS instance configured with specified storage and instance class
- Not publicly accessible
- Outputs: RDS endpoint, RDS port

## Inter-Module Communication

The modules communicate through Terraform outputs and inputs:

1. **VPC → Web Tier**: 
   - VPC module outputs `vpc_id`, `public_subnet_ids`, `private_subnet_ids`
   - Web tier module inputs `vpc_id` and `public_subnet_ids`

2. **Web Tier → Data Tier**:
   - Web tier module outputs `web_security_group_id`
   - Data tier module inputs `web_tier_security_group_id` to configure RDS security group

This demonstrates secure, least-privilege communication between layers:
- Web tier can only be reached via ALB (internet) or SSH (debugging)
- Data tier can only be reached from web tier (MySQL port)
- No direct internet access to data tier
- No direct internet access to web tier instances (only via ALB)

## Benefits of Modular Approach

### Reusability
- Each module can be reused in other projects with different variables
- VPC module could be used for multiple environments (dev/test/prod)
- Web tier module could be adapted for different application types
- Data tier module could be reused for different database needs

### Maintainability
- Changes to networking don't require touching web tier or data tier code
- Clear separation of concerns makes code easier to understand and modify
- Teams can work on different modules independently
- Easier to test modules in isolation

### Consistency
- Standardized patterns for common infrastructure components
- Reduced risk of configuration drift between environments
- Easier to enforce organizational standards and best practices

### Version Control
- Modules can be versioned independently
- Different environments can use different versions of the same module
- Easier to roll back changes to a specific module without affecting others

## How to Use This Project

See `BUILD_PROCESS.md` for the complete step-by-step build, verify, and teardown process.

## Files to Reference
- `terraform/main.tf` - Root configuration calling modules
- `terraform/variables.tf` - Input parameters
- `terraform/outputs.tf` - Output values
- `terraform/modules/vpc/main.tf` - VPC module
- `terraform/modules/web_tier/main.tf` - Web tier module (ALB, ASG, EC2)
- `terraform/modules/data_tier/main.tf` - Data tier module (RDS)
- `BUILD_PROCESS.md` - Build process documentation
- `docs/MODULES_OVERVIEW.md` - This document

## Next Steps for Enhancement
To further demonstrate expertise, consider adding:
- Separate networking module for ALB (more realistic separation)
- Additional modules for monitoring (CloudWatch alarms, SNS topics)
- Module for IAM roles and policies
- Module for backup and disaster recovery (RDS snapshots, etc.)
- Module for autoscaling policies based on CloudWatch metrics
- Workspaces or Terraform Cloud for enterprise-scale module management
- Module templates in a separate repository for cross-project reuse