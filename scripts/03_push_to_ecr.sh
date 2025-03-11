#!/bin/bash
set -e

AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="975050024946"

echo "Logging into AWS ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

echo "Creating ECR repositories..."
aws ecr create-repository --repository-name mern-hello-service || true
aws ecr create-repository --repository-name mern-profile-service || true
aws ecr create-repository --repository-name mern-frontend || true

echo "Tagging and pushing Docker images to ECR..."
docker tag mern-hello-service:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/mern-hello-service:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/mern-hello-service:latest

docker tag mern-profile-service:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/mern-profile-service:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/mern-profile-service:latest

docker tag mern-frontend:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/mern-frontend:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/mern-frontend:latest

echo "Docker images successfully pushed to AWS ECR!"
