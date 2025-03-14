#!/bin/bash
set -e

AWS_REGION="us-east-1"
VPC_ID="vpc-03c56cda94b8d7229"
ALB_ARN="arn:aws:elasticloadbalancing:us-east-1:975050024946:loadbalancer/app/mern-alb/6b4c1f6367c9e75a"

echo "Creating Target Groups for ECS Services..."
HELLO_TG_ARN="arn:aws:elasticloadbalancing:us-east-1:975050024946:targetgroup/mern-hello-tg/0efafcd8a63d1931"
PROFILE_TG_ARN="arn:aws:elasticloadbalancing:us-east-1:975050024946:targetgroup/mern-profile-tg/174e16680b583d17"
FRONTEND_TG_ARN="arn:aws:elasticloadbalancing:us-east-1:975050024946:targetgroup/mern-frontend-tg/0f5b383af7dc67b0"

echo "Target Groups created:"
echo "Hello Target Group ARN: $HELLO_TG_ARN"
echo "Profile Target Group ARN: $PROFILE_TG_ARN"
echo "Frontend Target Group ARN: $FRONTEND_TG_ARN"

echo "Registering ECS tasks with Target Groups..."
for SERVICE in "hello-service" "profile-service" "frontend"; do
    TASK_ID=$(aws ecs list-tasks --cluster mern-cluster --query "taskArns[0]" --output text)

    if [[ "$TASK_ID" == "None" ]]; then
        echo "No tasks found for service: $SERVICE. Skipping..."
        continue
    fi

    # Retrieve the private IP of the ECS task
    PRIVATE_IP=$(aws ecs describe-tasks --cluster mern-cluster --tasks $TASK_ID --query "tasks[0].containers[0].networkInterfaces[0].privateIpv4Address" --output text)

    if [[ "$PRIVATE_IP" == "None" || -z "$PRIVATE_IP" ]]; then
        echo "Failed to retrieve private IP for task $TASK_ID. Skipping..."
        continue
    fi

    echo "Private IP for $SERVICE (task $TASK_ID): $PRIVATE_IP"

    # Manually assign the correct Target Group ARN
    case "$SERVICE" in
        "hello-service")
            TG_ARN="$HELLO_TG_ARN"
            ;;
        "profile-service")
            TG_ARN="$PROFILE_TG_ARN"
            ;;
        "frontend")
            TG_ARN="$FRONTEND_TG_ARN"
            ;;
        *)
            echo "Unknown service: $SERVICE. Skipping..."
            continue
            ;;
    esac

    # Register the task using the private IP and manually assigned Target Group ARN
    aws elbv2 register-targets --target-group-arn "$TG_ARN" --targets Id=$PRIVATE_IP
    if [ $? -ne 0 ]; then
        echo "Error registering target for service $SERVICE. Task $TASK_ID with IP $PRIVATE_IP could not be registered."
    else
        echo "Successfully registered ECS task $TASK_ID with IP $PRIVATE_IP for service $SERVICE."
    fi
done

echo "Setting up ALB Listeners and Routing..."
LISTENER_ARN=$(aws elbv2 create-listener --load-balancer-arn $ALB_ARN --protocol HTTP --port 80 --default-actions Type=forward,TargetGroupArn=$FRONTEND_TG_ARN --query 'Listeners[0].ListenerArn' --output text)

echo "Listener ARN: $LISTENER_ARN"

aws elbv2 create-rule --listener-arn $LISTENER_ARN --priority 10 --conditions Field=path-pattern,Values="/hello/*" --actions Type=forward,TargetGroupArn=$HELLO_TG_ARN
aws elbv2 create-rule --listener-arn $LISTENER_ARN --priority 20 --conditions Field=path-pattern,Values="/profile/*" --actions Type=forward,TargetGroupArn=$PROFILE_TG_ARN

echo "ALB routing setup completed."
