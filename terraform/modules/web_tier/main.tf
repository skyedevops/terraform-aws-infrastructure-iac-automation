variable "vpc_id" {
  description = "The VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "desired_capacity" {
  description = "Desired number of EC2 instances in ASG"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of EC2 instances in ASG"
  type        = number
  default     = 3
}

variable "min_size" {
  description = "Minimum number of EC2 instances in ASG"
  type        = number
  default     = 1
}

variable "key_name" {
  description = "EC2 Key Pair name for SSH access (optional)"
  type        = string
  default     = ""
}

# Security group for the web tier (ALB and EC2)
resource "aws_security_group" "web" {
  name        = "iac-web-sg"
  description = "Allow HTTP inbound from ALB and SSH from anywhere"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from ALB"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    # Note: In a more accurate setup, we would have the ALB in a separate module and reference its SG.
    # But for simplicity in this module, we are creating the ALB here and we want to allow HTTP from the ALB.
    # However, we haven't created the ALB yet in this module? Actually we are about to.
    # Let's change: we will allow HTTP from the internet for now, and then we can tighten it later if needed.
    # But note: we are creating an ALB in this module, and we want to allow traffic from the ALB to the instances.
    # The ALB will have its own security group. We should reference that.
    # Let's restructure: we'll create the ALB security group separately? Or we can note that the ALB we create in this module will have a security group that we can reference.
    # Actually, the ALB we create in this module will be associated with the security group we are defining? No, we are specifying the security group for the ALB as [aws_security_group.web.id] in the aws_lb resource.
    # So the ALB will use this security group. Then for the instances, we want to allow HTTP from the ALB's security group, which is the same as this one.
    # So we can allow from this security group itself.
    security_groups = [aws_security_group.web.id]
  }

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "iac-web-sg"
  }
}

# We are going to create an ALB in this module for simplicity of the web tier.
# However, in a real separation, the ALB might be in a networking module. But for this project, we'll put it here.

# Internet-facing Application Load Balancer
resource "aws_lb" "web" {
  name               = "iac-web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web.id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = {
    Name = "iac-web-alb"
  }
}

# Target Group for the ALB
resource "aws_lb_target_group" "web" {
  name        = "iac-web-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-299"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "iac-web-tg"
  }
}

# Listener for the ALB
resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.id
  }
}

# Launch template for the EC2 instances
# We need to get the latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Ubuntu

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# We'll use a user data script to install a simple app (like the first project) but we can also use a remote file or just a simple HTML.
# For simplicity, we'll install a web server that serves a static page.
data "template_cloudinit_config" "web_config" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content = <<-EOF
      repo_update: true
      repo_upgrade: all
      EOF
  }

  part {
    content_type = "text/x-shell-script"
    content = <<-EOF
      #!/bin/bash
      set -e
      # Install Apache
      apt-get update -y
      apt-get install -y apache2
      # Write a simple HTML page
      echo "<h1>Hello from Infrastructure as Code Automation Project</h1><p>This page is served by an EC2 instance in an Auto Scaling Group behind a Load Balancer.</p>" > /var/www/html/index.html
      # Ensure Apache is running and enabled on boot
      systemctl enable apache2
      systemctl start apache2
    EOF
  }
}

resource "aws_launch_template" "web" {
  name_prefix   = "iac-web-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_name != "" ? var.key_name : null

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.web.id]
  }

  user_data = base64encode(data.template_cloudinit_config.web_config.rendered)

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "iac-web-instance"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "web" {
  name                      = "iac-web-asg"
  max_size                  = var.max_size
  min_size                  = var.min_size
  desired_capacity          = var.desired_capacity
  vpc_zone_identifier       = var.public_subnet_ids # Note: we are putting the ASG in public subnets for simplicity? Actually, we should put in private if we had a separate DB tier, but for this web-only project, public is okay.
  health_check_type         = "EC2"
  health_check_grace_period = 300
  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "iac-web-asg-instance"
    propagate_at_launch = true
  }
}

# Attach the ASG to the ALB target group
resource "aws_autoscaling_attachment" "web_asg_alb" {
  autoscaling_group_name = aws_autoscaling_group.web.name
  lb_target_group_arn    = aws_lb_target_group.web.id
}

# Outputs
output "alb_dns_name" {
  description = "The DNS name of the application load balancer"
  value       = aws_lb.web.dns_name
}

output "web_security_group_id" {
  description = "The ID of the web tier security group"
  value       = aws_security_group.web.id
}