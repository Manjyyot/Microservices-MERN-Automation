#!/bin/bash
set -e

echo "Creating Application Load Balancer..."

aws elbv2 create-load-balancer --name mern-alb --subnets subnet-xxxxx subnet-yyyyy --security-groups sg-xxxxx --scheme internet-facing --type application --ip-address-type ipv4

echo "ALB created successfully!"
