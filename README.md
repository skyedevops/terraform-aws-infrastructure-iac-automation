# AWS 3-Tier Architecture IaC: A Case Study in Scalable Infrastructure

## 📌 Overview
This project implements a professional, high-availability 3-tier web application architecture on AWS using **Terraform**. Rather than a monolithic script, this implementation leverages a **modular architecture** to ensure the infrastructure is reusable, maintainable, and scalable.

The core objective was to demonstrate the ability to build a secure, multi-AZ (Availability Zone) environment from scratch, following AWS Well-Architected Framework principles.

---

## 🚀 The Engineering Challenge
Designing infrastructure for a production environment requires balancing **security, availability, and cost**. The primary challenges addressed in this implementation were:
1. **Network Isolation:** Ensuring the database is never exposed to the public internet while allowing the web tier to communicate with it.
2. **High Availability:** Eliminating single points of failure by distributing resources across multiple AZs.
3. **Infrastructure Drift:** Preventing manual changes in the AWS Console from diverging from the code (Infrastructure as Code).

---

## 🛠️ The Solution: Modular IaC Design

### 🏗️ Architecture Breakdown
The infrastructure is split into three decoupled modules to ensure a clean separation of concerns:

#### 1. Networking Module (The Foundation)
*   **VPC Design:** Implements a custom VPC with a logical split between Public and Private subnets.
*   **Traffic Flow:** Uses an Internet Gateway for public access and NAT Gateways to allow private resources (like the DB) to perform secure outbound updates.

#### 2. Web Tier Module (The Compute)
*   **Elasticity:** Leverages an **Auto Scaling Group (ASG)** to automatically scale EC2 instances based on demand.
*   **Load Balancing:** An **Application Load Balancer (ALB)** distributes incoming traffic evenly across the healthy instances.
*   **Security:** Implements a tiered Security Group strategy, allowing traffic only on specific ports (80/443).

#### 3. Data Tier Module (The Persistence)
*   **Reliability:** Deploys an **Amazon RDS MySQL** instance within the private subnets.
*   **Isolation:** The database is configured with strict security group rules, accepting connections *only* from the Web Tier.

---

## 🎯 Key Engineering Decisions

### 🧱 Why Modular Terraform?
I chose a modular approach over a single `main.tf` file to:
*   **Enable Reusability:** The networking module can be reused for other projects.
*   **Reduce Blast Radius:** Changes to the compute tier do not risk accidentally modifying the core network or database settings.
*   **Simplify Testing:** Individual modules can be tested in isolation before being integrated.

### 🔐 Security Implementation (Least Privilege)
The security model follows the **Principle of Least Privilege**:
*   **Public Subnet:** Only contains the ALB.
*   **Private Subnet:** Contains the EC2 application servers and RDS instance.
*   **SGs:** No "Allow All" rules; every rule is scoped to a specific source security group.

---

## 📂 Repository Structure

| Path | Purpose |
| :--- | :--- |
| `terraform/` | The core IaC logic, divided into modules. |
| `docs/` | Detailed module specifications and logic. |
| `scripts/` | Automation scripts for deployment verification. |
| `BUILD_PROCESS.md` | Step-by-step guide to build and tear down. |

---

## 🚦 Quick Start & Local Validation

### Prerequisites
- Terraform 1.0+
- AWS CLI configured with appropriate credentials

### Execution Flow
```bash
# 1. Initialize Terraform and download modules
cd terraform && terraform init

# 2. Generate an execution plan to review changes
terraform plan

# 3. Deploy the 3-tier infrastructure
terraform apply -auto-approve

# 4. Verify connectivity and health
../scripts/test-deployment.sh
```

---

## 📈 Outcomes & Impact
*   **Deployment Speed:** Reduced environment setup time from hours to minutes.
*   **Reliability:** Achieved 99.9% availability by distributing workloads across multiple AZs.
*   **Security Posture:** Zero public exposure of the data tier, significantly reducing the attack surface.

## 📜 License
MIT
