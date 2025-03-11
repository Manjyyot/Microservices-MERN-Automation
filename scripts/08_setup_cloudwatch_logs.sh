#!/bin/bash
set -e  # Exit if any command fails

AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="975050024946"
SERVICES=("hello-service" "profile-service" "frontend")

echo "Starting CloudWatch logging setup for ECS services..."

# Step 1: Create CloudWatch Log Groups
echo "Creating CloudWatch log groups..."
for SERVICE in "${SERVICES[@]}"; do
    LOG_GROUP="/ecs/mern-$SERVICE"
    if aws logs describe-log-groups --log-group-name-prefix "$LOG_GROUP" | grep -q "$LOG_GROUP"; then
        echo "CloudWatch log group already exists for $SERVICE."
    else
        echo "Creating log group for $SERVICE..."
        aws logs create-log-group --log-group-name "$LOG_GROUP"
    fi
done

# Step 2: Attach CloudWatch Logging Permissions to ECS Task IAM Roles
echo "Attaching CloudWatch logging permissions to ECS task roles..."
for SERVICE in "${SERVICES[@]}"; do
    IAM_ROLE="ecsTaskExecutionRole-mern-$SERVICE"
    if aws iam list-attached-role-policies --role-name "$IAM_ROLE" | grep -q "CloudWatchLogsFullAccess"; then
        echo "CloudWatch logging policy already attached to $IAM_ROLE."
    else
        echo "Attaching CloudWatchLogsFullAccess policy to $IAM_ROLE..."
        aws iam attach-role-policy --role-name "$IAM_ROLE" --policy-arn arn:aws:iam::aws:policy/CloudWatchLogsFullAccess
    fi
done

# Step 3: Update ECS Task Definitions with CloudWatch Logging
echo "Updating ECS task definitions to enable CloudWatch logs..."
for SERVICE in "${SERVICES[@]}"; do
    echo "Updating task definition for $SERVICE..."

    aws ecs register-task-definition --family mern-$SERVICE \
      --network-mode awsvpc \
      --requires-compatibilities FARGATE \
      --cpu "256" --memory "512" \
      --execution-role-arn arn:aws:iam::$AWS_ACCOUNT_ID:role/ecsTaskExecutionRole-mern-$SERVICE \
      --container-definitions "[{
        \"name\": \"mern-$SERVICE\",
        \"image\": \"$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/mern-$SERVICE:latest\",
        \"portMappings\": [{ \"containerPort\": 5001, \"hostPort\": 5001 }],
        \"essential\": true,
        \"logConfiguration\": {
          \"logDriver\": \"awslogs\",
          \"options\": {
            \"awslogs-group\": \"/ecs/mern-$SERVICE\",
            \"awslogs-region\": \"$AWS_REGION\",
            \"awslogs-stream-prefix\": \"ecs\"
          }
        }
      }]"

    echo "Task definition for $SERVICE updated."
done

# Step 4: Restart ECS Services to Apply CloudWatch Logging
echo "Restarting ECS services to apply changes..."
for SERVICE in "${SERVICES[@]}"; do
    echo "Updating ECS service: $SERVICE..."
    # Ensure that you are passing the correct ECS service name
    SERVICE_NAME="mern-$SERVICE"
    aws ecs update-service --cluster mern-cluster --service $SERVICE_NAME --task-definition mern-$SERVICE
done

# Step 5: Verify CloudWatch Log Groups and Fetch Logs
echo "Verifying CloudWatch log groups..."
aws logs describe-log-groups --log-group-name-prefix "/ecs/"

echo "Checking recent logs from CloudWatch..."
for SERVICE in "${SERVICES[@]}"; do
    LOG_GROUP="/ecs/mern-$SERVICE"
    echo "Fetching logs for $SERVICE..."
    aws logs filter-log-events --log-group-name "$LOG_GROUP" --limit 10 || echo "No logs found yet for $SERVICE."
done

echo "CloudWatch setup completed successfully."
