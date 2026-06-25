# 🏗️ High-Availability Three-Tier Infrastructure: Architectural Blueprint

## 📌 Executive Summary
This project implements a production-ready, resilient three-tier web architecture on AWS. The design focuses on **Zero Single Points of Failure (SPOF)** and **Strict Isolation**, ensuring that the application can withstand the failure of an entire Availability Zone (AZ) without service interruption.

## 🛠️ Technical Stack
- **Provisioning:** Terraform (Modular HCL)
- **Cloud Provider:** Amazon Web Services (AWS)
- **Compute:** EC2 Auto Scaling Groups (ASG)
- **Traffic Management:** Application Load Balancer (ALB)
- **Data Layer:** Amazon RDS (MySQL)
- **Network:** Custom VPC with Tiered Subnetting

## 📐 Design Philosophy & Implementation

### 1. Resilience & Fault Tolerance (The "Reliability" Layer)
- **Multi-AZ Distribution:** All compute and data resources are distributed across two Availability Zones. This ensures that if one AWS data center fails, traffic is automatically routed to the surviving zone.
- **Self-Healing Infrastructure:** By utilizing **Auto Scaling Groups**, the infrastructure automatically detects unhealthy instances and replaces them in real-time, maintaining the desired capacity without manual intervention.

### 2. Zero-Trust Network Topology
- **Strict Tier Isolation:**
    - **Web Tier:** Public-facing ALB only.
    - **App Tier:** Private subnets, accessible only via the ALB.
    - **Data Tier:** Deeply isolated private subnets, accessible only from the App Tier.
- **Least-Privilege Security Groups:** Implemented a chain of security groups where each tier only opens the specific ports required for the next tier to communicate, preventing lateral movement in the event of a breach.

### 3. Modular IaC for Scale
- **Separation of Concerns:** The infrastructure is split into three distinct modules (`Networking`, `Web`, `Data`). This allows for independent scaling, testing, and updates of each layer without risking the entire environment.
- **Environment Agnosticism:** Through the use of Terraform variables, this entire stack can be replicated across `dev`, `staging`, and `prod` environments with zero code changes.

### 4. Production-Ready State Management
- **Remote State Implementation:** The architecture is designed for S3 remote backends with DynamoDB state locking to prevent state corruption during concurrent team deployments.

## 📈 Reliability Verdict
This architecture is designed for **High Availability (HA)**. By combining multi-AZ redundancy, tiered network isolation, and a modular IaC approach, it transforms a simple web app into a resilient platform capable of supporting production workloads.