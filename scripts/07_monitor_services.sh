#!/bin/bash
set -e

echo "Fetching ECS Services..."
aws ecs list-services --cluster mern-cluster

echo "Fetching ECS Tasks..."
aws ecs list-tasks --cluster mern-cluster

echo "Fetching logs..."
aws logs filter-log-events --log-group-name "/ecs/mern-hello-service" --limit 10
aws logs filter-log-events --log-group-name "/ecs/mern-profile-service" --limit 10
aws logs filter-log-events --log-group-name "/ecs/mern-frontend" --limit 10
