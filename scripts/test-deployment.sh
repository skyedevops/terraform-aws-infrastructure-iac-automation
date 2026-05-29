#!/bin/bash
# Script to test the deployed IaC Automation application

set -euo pipefail

echo "=== Testing IaC Automation Deployment ==="

# Check if terraform is available
if ! command -v terraform &> /dev/null; then
    echo "Error: Terraform not found. Please install Terraform first."
    exit 1
fi

# Get the ALB DNS from terraform output
ALB_DNS=$(terraform output -raw alb_dns_name)
echo "Application URL: http://$ALB_DNS"

# Test the application (should return the static HTML page)
echo -n "Testing application response: "
RESPONSE=$(curl -s http://$ALB_DNS || echo "FAILED")
if [[ "$RESPONSE" == *"Hello from Infrastructure as Code Automation Project"* ]]; then
    echo "PASS - Static HTML page served correctly"
else
    echo "FAIL - Got: $RESPONSE"
    exit 1
fi

# Test multiple requests to verify load balancing
echo -n "Testing load balancing (5 requests): "
RESPONSES=()
for i in {1..5}; do
    # Extract a unique part of the response if possible, otherwise just check status
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$ALB_DNS || echo "000")
    RESPONSES+=($STATUS)
done

# Check if all requests returned 200 (indicating load balancer is working)
ALL_200=true
for status in "${RESPONSES[@]}"; do
    if [ "$status" -ne 200 ]; then
        ALL_200=false
        break
    fi
done

if [ "$ALL_200" = true ]; then
    echo "PASS - All 5 requests returned HTTP 200"
else
    echo "FAIL - Some requests did not return 200: ${RESPONSES[*]}"
    exit 1
fi

# Show ASG status
echo -e "\nAuto Scaling Group Status:"
aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names iac-web-asg \
    --query "AutoScalingGroups[0].{Desired:DesiredCapacity, Min:MinSize, Max:MaxSize, Running:Instances[?LifecycleState=='InService'].|length(@)}" \
    --output table

# Show RDS endpoint (just to verify it exists)
echo -e "\nRDS Endpoint (verify exists):"
aws rds describe-db-instances \
    --db-instance-identifier iac-rds \
    --query "DBInstances[0].{Endpoint:Endpoint.Address, Status:DBInstanceStatus}" \
    --output table

echo -e "\n=== Test completed successfully ==="