#!/bin/bash

source ./cfvars
echo "Creating repositories and building the service docker images"

for dir in $(ls ../services)
do
echo "Creating repository for service $dir"
aws ecr --region $REGION create-repository --repository-name $dir  --image-scanning-configuration scanOnPush=true
done

CURWD=$PWD
echo "Logging into ECR"
$(aws --region $REGION ecr get-login --no-include-email)
if [[ $? -ne 0 ]];then
	aws ecr get-login-password | docker login --username AWS --password-stdin https://$ACCOUNTNUMBER.dkr.ecr.eu-west-1.amazonaws.com
fi

for dir in $(ls ../services)
do
echo "Building and pushing image for $dir"
cd ../services/$dir
./build.sh
cd $CURWD
done

echo "Setting up deployment files with new image details"
sed "s/ACCOUNTNUMBER/$ACCOUNTNUMBER/" ../deploy/fullappv1-appmesh.template > ../deploy/fullappv1-appmesh.yaml
sed -i.bak "s/REGION/$REGION/" ../deploy/fullappv1-appmesh.yaml
sed "s/ACCOUNTNUMBER/$ACCOUNTNUMBER/" ../deploy/fullappv2-appmesh.template > ../deploy/fullappv2-appmesh.yaml
sed -i.bak "s/REGION/$REGION/" ../deploy/fullappv2-appmesh.yaml


