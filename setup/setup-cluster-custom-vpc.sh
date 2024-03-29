
echo "Please name your cluster"
read -e CLUSTERNAME
echo "Which AWS Region do you wish to use?"
read -e REGION

echo #Setting up vars file"
> cfvars

aws cloudformation --region $REGION create-stack --stack-name $CLUSTERNAME --template-body file://corevpc.yaml
sleep 5
aws cloudformation --region $REGION wait stack-create-complete --stack-name $CLUSTERNAME

export PRIVATESUBNET1=$(aws --region $REGION cloudformation describe-stacks --stack-name $CLUSTERNAME --query "Stacks[0].Outputs[?OutputKey=='PrivateSubnet1'].OutputValue" --output text)
export PRIVATESUBNET2=$(aws --region $REGION cloudformation describe-stacks --stack-name $CLUSTERNAME --query "Stacks[0].Outputs[?OutputKey=='PrivateSubnet2'].OutputValue" --output text)
export PRIVATESUBNET3=$(aws --region $REGION cloudformation describe-stacks --stack-name $CLUSTERNAME --query "Stacks[0].Outputs[?OutputKey=='PrivateSubnet3'].OutputValue" --output text)
export PUBLICSUBNET1=$(aws --region $REGION cloudformation describe-stacks --stack-name $CLUSTERNAME --query "Stacks[0].Outputs[?OutputKey=='PublicSubnet1'].OutputValue" --output text)
export PUBLICSUBNET2=$(aws --region $REGION cloudformation describe-stacks --stack-name $CLUSTERNAME --query "Stacks[0].Outputs[?OutputKey=='PublicSubnet2'].OutputValue" --output text)
export PUBLICSUBNET3=$(aws --region $REGION cloudformation describe-stacks --stack-name $CLUSTERNAME --query "Stacks[0].Outputs[?OutputKey=='PublicSubnet3'].OutputValue" --output text)
export VPC=$(aws --region $REGION cloudformation describe-stacks --stack-name $CLUSTERNAME --query "Stacks[0].Outputs[?OutputKey=='VPC'].OutputValue" --output text)
export DOCUMENTDBSG=$(aws --region $REGION cloudformation describe-stacks --stack-name $CLUSTERNAME --query "Stacks[0].Outputs[?OutputKey=='DocumentDBSG'].OutputValue" --output text)
export DOCDBENDPOINT=$(aws --region $REGION cloudformation describe-stacks --stack-name $CLUSTERNAME --query "Stacks[0].Outputs[?OutputKey=='DocumentDBEndpoint'].OutputValue" --output text)
export DBSVCSG=$(aws --region $REGION cloudformation describe-stacks --stack-name $CLUSTERNAME --query "Stacks[0].Outputs[?OutputKey=='DBSVCSG'].OutputValue" --output text)
export NAMESPACE=$(aws --region $REGION cloudformation describe-stacks --stack-name $CLUSTERNAME --query "Stacks[0].Outputs[?OutputKey=='CloudMapNamespace'].OutputValue" --output text)
export ACCOUNTNUMBER=$(aws --region $REGION sts get-caller-identity --query "Account" --output text )
export REGION=$REGION
export CLUSTER_NAME=$CLUSTERNAME
export AWS_REGION=$REGION

echo export PRIVATESUBNET1=$PRIVATESUBNET1 >> cfvars 
echo export PRIVATESUBNET2=$PRIVATESUBNET2 >> cfvars
echo export PRIVATESUBNET3=$PRIVATESUBNET3 >> cfvars
echo export PUBLICSUBNET1=$PUBLICSUBNET1 >> cfvars
echo export PUBLICSUBNET2=$PUBLICSUBNET1 >> cfvars
echo export PUBLICSUBNET3=$PUBLICSUBNET1 >> cfvars
echo export VPC=$VPC >> cfvars
echo export CLUSTERNAME=$CLUSTERNAME >> cfvars
echo export REGION=$REGION >> cfvars
echo export DOCUMENTDBSG=$DOCUMENTDBSG >> cfvars
echo export ACCOUNTNUMBER=$ACCOUNTNUMBER >> cfvars
echo export DOCDBENDPOINT=$DOCDBENDPOINT >> cfvars
echo export CLUSTER_NAME=$CLUSTERNAME >> cfvars
echo export AWS_REGION=$REGION >> cfvars
echo export DBSVCSG=$DBSVCSG >> cfvars
echo export NAMESPACE=$NAMESPACE >> cfvars

# Rewrite cluster name from template file

sed "s/<<name>>/$CLUSTERNAME/" cluster.template > $CLUSTERNAME.yaml

# Rewrite regions in cluster file

sed -i.bak "s/<<region>>/$REGION/" $CLUSTERNAME.yaml

# Rewrite the VPC ID

sed -i.bak "s/<<vpc>>/$VPC/" $CLUSTERNAME.yaml

# Rewrite the security group holder with the new ID

sed -i.bak "s/<<securitygroup>>/$DBSVCSG/" $CLUSTERNAME.yaml

# Rewrite private subnets in cluster file

sed -i.bak "s/<<privatesubnet1>>/$PRIVATESUBNET1/" $CLUSTERNAME.yaml
sed -i.bak "s/<<privatesubnet2>>/$PRIVATESUBNET2/" $CLUSTERNAME.yaml
sed -i.bak "s/<<privatesubnet3>>/$PRIVATESUBNET3/" $CLUSTERNAME.yaml


# Rewrite public subnets in cluster file

sed -i.bak "s/<<publicsubnet1>>/$PUBLICSUBNET1/" $CLUSTERNAME.yaml
sed -i.bak "s/<<publicsubnet2>>/$PUBLICSUBNET2/" $CLUSTERNAME.yaml
sed -i.bak "s/<<publicsubnet3>>/$PUBLICSUBNET3/" $CLUSTERNAME.yaml


rm -rf *.bak

eksctl create cluster -f $CLUSTERNAME.yaml

    
echo "Configuring appmesh via Helm"

helm repo add eks https://aws.github.io/eks-charts
kubectl apply -k "https://github.com/aws/eks-charts/stable/appmesh-controller/crds?ref=master"

helm upgrade -i appmesh-controller eks/appmesh-controller \
    --namespace appmesh-system \
    --set region=$AWS_REGION \
    --set serviceAccount.create=false \
    --set serviceAccount.name=appmesh-controller \
    --set tracing.enabled=true \
    --set tracing.provider=x-ray   

echo "Installing Cloudwatch Agent"
curl https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/master/k8s-yaml-templates/quickstart/cwagent-fluentd-quickstart.yaml | sed "s/{{cluster_name}}/${CLUSTERNAME}/;s/{{region_name}}/${REGION}/" | kubectl apply -f -
    

sleep 10

kubectl apply -f mesh_ns.yaml


cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: tracker
---
apiVersion: batch/v1
kind: Job
metadata:
  # Unique key of the Job instance
  name: launched
  namespace: tracker
spec:
  template:
    metadata:
      name: tracker
    spec:
      containers:
      - name: tracker
        image: numanoids/eksappmesh
      # Do not restart containers after they exit
      restartPolicy: Never
EOF

kubectl delete ns tracker

echo "All Done"
