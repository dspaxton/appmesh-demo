#!/bin/bash

source cfvars
echo "Cleaning up resources"

echo "Tearing down the ECS resources"
aws --region $REGION appmesh delete-route --route-name user-agent --mesh-name my-mesh --virtual-router-name frontend-virtual-router_my-apps
aws --region $REGION cloudformation delete-stack --stack-name $CLUSTERNAME-ecs-fargate
aws --region $REGION cloudformation wait stack-delete-complete --stack-name $CLUSTERNAME-ecs-fargate

echo "Tearing down application and nodes prior to deleting fargate profile"
kubectl delete -f ../deploy/fullappv2-appmesh.yaml 
kubectl delete -f mesh_ns.yaml

eksctl delete cluster -r $REGION --name $CLUSTERNAME
sleep 60
aws --region $REGION eks wait cluster-deleted --name $CLUSTERNAME
aws --region $REGION cloudformation delete-stack --stack-name $CLUSTERNAME
aws --region $REGION cloudformation wait stack-delete-complete --stack-name $CLUSTERNAME

# Cleaning up ECR Resources 
#for repository in $(aws --region $REGION  ecr describe-repositories --query "repositories[*].repositoryName" --output text ); 
# Cleaning up ECR Resources 
#for repository in $(aws --region $REGION  ecr describe-repositories --query "repositories[*].repositoryName" --output text ); 
for repository in $(ls ../services); 
do 
echo "Cleaning up repository ${repository}"
    for image in $(aws --region $REGION ecr list-images --repository-name $repository --query "imageIds[*].imageDigest" --output text ); do 
        echo "Attempting to delete image $image"
        aws --region $REGION ecr batch-delete-image --repository-name $repository --image-ids imageDigest=$image; 
    done
done

# for repository in $(aws --region $REGION  ecr describe-repositories --query "repositories[*].repositoryName" --output text ); 
for repository in $(ls ../services); 
do aws --region $REGION ecr delete-repository --repository-name $repository; done


rm -rf cfvars
