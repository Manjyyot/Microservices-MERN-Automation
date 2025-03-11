#!/bin/bash
set -e

echo "Creating IAM roles for ECS Task Execution..."

for SERVICE in "hello-service" "profile-service" "frontend"; do
    aws iam create-role --role-name ecsTaskExecutionRole-mern-$SERVICE --assume-role-policy-document file://<(echo '{
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Principal": { "Service": "ecs-tasks.amazonaws.com" },
            "Action": "sts:AssumeRole"
        }]
    }')

    aws iam attach-role-policy --role-name ecsTaskExecutionRole-mern-$SERVICE --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
done

echo "IAM roles created successfully!"
