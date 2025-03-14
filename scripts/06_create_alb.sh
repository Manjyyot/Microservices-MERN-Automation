#!/bin/bash
set -e

echo "Creating Application Load Balancer..."
aws elbv2 create-load-balancer   --name mern-alb   --subnets subnet-0edea208a0374a0bf subnet-02e5fc8279ad35b17   --security-groups sg-07cbebdb239752783   --scheme internet-facing   --type application   --ip-address-type ipv4
echo "ALB created successfully!"
