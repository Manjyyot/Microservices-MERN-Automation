#!/bin/bash
set -e

AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="975050024946"

echo "Creating ECS Cluster..."
aws ecs create-cluster --cluster-name mern-cluster || true

echo "Registering ECS Task Definitions..."
for SERVICE in "hello-service" "profile-service" "frontend"; do
  aws ecs register-task-definition --family mern-$SERVICE --network-mode awsvpc --requires-compatibilities FARGATE --cpu "256" --memory "512" --execution-role-arn arn:aws:iam::$AWS_ACCOUNT_ID:role/ecsTaskExecutionRole-mern-$SERVICE --container-definitions "[{
    \"name\": \"mern-$SERVICE\",
    \"image\": \"$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/mern-$SERVICE:latest\",
    \"portMappings\": [{ \"containerPort\": 5001, \"hostPort\": 5001 }],
    \"essential\": true
  }]"
done

echo "Deploying ECS Services..."
for SERVICE in "hello-service" "profile-service" "frontend"; do
  aws ecs create-service --cluster mern-cluster --service-name mern-$SERVICE --task-definition mern-$SERVICE --desired-count 1 --launch-type FARGATE --network-configuration "awsvpcConfiguration={subnets=[subnet-xxxxx],securityGroups=[sg-xxxxx],assignPublicIp=ENABLED}"
done

echo "ECS services deployed successfully!"
