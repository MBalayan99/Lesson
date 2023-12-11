#!/bin/bash
  echo "Cleaning up resources..."

  # Terminate EC2 instances
  aws ec2 terminate-instances --instance-ids $(aws ec2 describe-instances --filters "Name=tag:Name,Values=MyEC2Instance" --query 'Reservations[].Instances[].InstanceId' --output text)

  # Wait for instances to terminate
  aws ec2 wait instance-terminated --instance-ids $(aws ec2 describe-instances --filters "Name=tag:Name,Values=MyEC2Instance" --query 'Reservations[].Instances[].InstanceId' --output text)

  # Disassociate and delete route table
  aws ec2 disassociate-route-table --association-id $(aws ec2 describe-route-tables --filters "Name=tag:Name,Values=MyRouteTable" --query 'RouteTables[].Associations[].RouteTableAssociationId' --output text)
  aws ec2 delete-route-table --route-table-id $(aws ec2 describe-route-tables --filters "Name=tag:Name,Values=MyRouteTable" --query 'RouteTables[].RouteTableId' --output text)

  # Detach and delete internet gateway (if exists)
  igw_id=$(aws ec2 describe-internet-gateways --filters "Name=tag:Name,Values=MyInternetGateway" --query 'InternetGateways[].InternetGatewayId' --output text)
  if [ -n "$igw_id" ]; then
    aws ec2 detach-internet-gateway --internet-gateway-id $igw_id --vpc-id $vpc_id
    aws ec2 delete-internet-gateway --internet-gateway-id $igw_id
  fi

  # delete  security group ingress rules and delete security group (if exists)
  security_group_id=$(aws ec2 describe-security-groups --filters "Name=tag:Name,Values=MySecurityGroup" --query 'SecurityGroups[].GroupId' --output text)
  if [ -n "$security_group_id" ]; then
    aws ec2 revoke-security-group-ingress --group-id $security_group_id --protocol tcp --port 22 --cidr 0.0.0.0/0
    aws ec2 delete-security-group --group-id $security_group_id
  fi

  # Delete subnet
  aws ec2 delete-subnet --subnet-id $(aws ec2 describe-subnets --filters "Name=tag:Name,Values=MySubnet" --query 'Subnets[].SubnetId' --output text)

  # Delete VPC
  aws ec2 delete-vpc --vpc-id $vpc_id

  echo "Clean-up completed!"

