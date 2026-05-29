variable "vpc_id" {
  description = "The VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS in GB"
  type        = number
  default     = 20
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "iaddb"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Database password"
  type        = string
  # Note: In production, use AWS Secrets Manager or Parameter Store and mark as sensitive
  default     = "password123"
}

variable "web_tier_security_group_id" {
  description = "The security group ID of the web tier (to allow database access)"
  type        = string
}

# RDS Subnet Group
resource "aws_db_subnet_group" "this" {
  name       = "iac-rds-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "iac-rds-subnet-group"
  }
}

# Security group for RDS (allow MySQL from the web tier)
resource "aws_security_group" "rds" {
  name        = "iac-rds-sg"
  description = "Allow MySQL from the web tier"
  vpc_id      = var.vpc_id

  ingress {
    description = "MySQL from web tier"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [var.web_tier_security_group_id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "iac-rds-sg"
  }
}

# RDS Instance (MySQL)
resource "aws_db_instance" "this" {
  identifier            = "iac-rds"
  engine                = "mysql"
  engine_version        = "8.0"
  instance_class        = var.db_instance_class
  allocated_storage     = var.db_allocated_storage
  name                  = var.db_name
  username              = var.db_username
  password              = var.db_password
  db_subnet_group_name  = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible   = false
  skip_final_snapshot   = true # Set to false in production if you want a snapshot on delete
  apply_immediately     = true

  tags = {
    Name = "iac-rds"
  }
}

# Outputs
output "rds_endpoint" {
  description = "The endpoint of the RDS instance"
  value       = aws_db_instance.this.address
}

output "rds_port" {
  description = "The port of the RDS instance"
  value       = aws_db_instance.this.port
}