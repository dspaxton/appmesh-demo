#!/bin/bash

source cfvars
echo "Cleaning up resources"

echo "Tearing down the ECS resources"
aws --region $REGION appmesh delete-route --route-name user-agent --mesh-name my-mesh --virtual-router-name frontend-virtual-router_my-apps
aws --region $REGION cloudformation delete-stack --stack-name $CLUSTERNAME-ecs-fargate
aws --region $REGION cloudformation wait stack-delete-complete --stack-name $CLUSTERNAME-ecs-fargate

echo "Tearing down application and nodes prior to deleting fargate profile"
kubectl delete -f ../deploy/fullappv2-appmesh.yaml 
