#!/bin/bash
source cfvars
echo $PRIVATESUBNET1 $PRIVATESUBNET2 $PRIVATESUBNET3
aws docdb --region $REGION create-db-subnet-group --db-subnet-group-name $CLUSTERNAME --db-subnet-group-description $CLUSTERNAME --subnet-ids $PRIVATESUBNET1 $PRIVATESUBNET2 $PRIVATESUBNET3
aws docdb --region $REGION create-db-cluster-parameter-group    --db-cluster-parameter-group-name $CLUSTERNAME --db-parameter-group-family docdb3.6 --description $CLUSTERNAME
sleep 300
aws docdb --region $REGION modify-db-cluster-parameter-group --db-cluster-parameter-group-name $CLUSTERNAME --parameters "ParameterName"=tls,"ParameterValue"=disabled,"ApplyMethod"=pending-reboot
aws docdb --region $REGION create-db-cluster --db-cluster-identifier $CLUSTERNAME --db-subnet-group-name $CLUSTERNAME --db-cluster-parameter-group-name $CLUSTERNAME --engine docdb --vpc-security-group-ids $DOCUMENTDBSG --master-username mongoadmin --master-user-password demoadminpass --no-deletion-protection
aws docdb --region $REGION create-db-instance --db-cluster-identifier $CLUSTERNAME --db-instance-class db.r5.large --engine docdb --db-instance-identifier $CLUSTERNAME-1
aws docdb --region $REGION create-db-instance --db-cluster-identifier $CLUSTERNAME --db-instance-class db.r5.large --engine docdb --db-instance-identifier $CLUSTERNAME-2
aws docdb --region $REGION create-db-instance --db-cluster-identifier $CLUSTERNAME --db-instance-class db.r5.large --engine docdb --db-instance-identifier $CLUSTERNAME-3
export DOCDBENDPOINT=$(aws docdb --region $REGION describe-db-clusters --db-cluster-identifier $CLUSTERNAME --query "DBClusters[*].Endpoint" --output text)
echo export DOCDBENDPOINT=$DOCDBENDPOINT >> cfvars
