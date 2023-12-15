#!/bin/bash

echo "Cleaning up resources in us-west-1 region..."

# Terminate EC2 instances
aws ec2 terminate-instances --region us-west-1 --instance-ids $(aws ec2 describe-instances --region us-west-1 --filters "Name=tag:Name,Values=MyEC2Instance" --query 'Reservations[].Instances[].InstanceId' --output text)

# Wait for instances to terminate
aws ec2 wait instance-terminated --region us-west-1 --instance-ids $(aws ec2 describe-instances --region us-west-1 --filters "Name=tag:Name,Values=MyEC2Instance" --query 'Reservations[].Instances[].InstanceId' --output text)

# Disassociate and delete route table
aws ec2 disassociate-route-table --region us-west-1 --association-id $(aws ec2 describe-route-tables --region us-west-1 --filters "Name=tag:Name,Values=MyRouteTable" --query 'RouteTables[].Associations[].RouteTableAssociationId' --output text)
aws ec2 delete-route-table --region us-west-1 --route-table-id $(aws ec2 describe-route-tables --region us-west-1 --filters "Name=tag:Name,Values=MyRouteTable" --query 'RouteTables[].RouteTableId' --output text)

# Detach and delete internet gateway (if exists)
igw_id=$(aws ec2 describe-internet-gateways --region us-west-1 --filters "Name=tag:Name,Values=MyInternetGateway" --query 'InternetGateways[].InternetGatewayId' --output text)
if [ -n "$igw_id" ]; then
  aws ec2 detach-internet-gateway --region us-west-1 --internet-gateway-id $igw_id --vpc-id $vpc_id
  aws ec2 delete-internet-gateway --region us-west-1 --internet-gateway-id $igw_id
fi

# delete security group ingress rules and delete security group (if exists)
security_group_id=$(aws ec2 describe-security-groups --region us-west-1 --filters "Name=tag:Name,Values=MySecurityGroup" --query 'SecurityGroups[].GroupId' --output text)
if [ -n "$security_group_id" ]; then
  aws ec2 revoke-security-group-ingress --region us-west-1 --group-id $security_group_id --protocol tcp --port 22 --cidr 0.0.0.0/0
  aws ec2 delete-security-group --region us-west-1 --group-id $security_group_id
fi

# Delete subnet
aws ec2 delete-subnet --region us-west-1 --subnet-id $(aws ec2 describe-subnets --region us-west-1 --filters "Name=tag:Name,Values=MySubnet" --query 'Subnets[].SubnetId' --output text)

# Delete VPC
aws ec2 delete-vpc --region us-west-1 --vpc-id $vpc_id

echo "Clean-up completed!"
