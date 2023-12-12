#!/bin/bash

# Create VPC
echo "Creating VPC"
vpc_id=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query 'Vpc.VpcId' --output text)
aws ec2 create-tags --resources $vpc_id --tags Key=Name,Value=MyVPC

# Create internet gateway
echo "Creating Internet Gateway..."
igw_id=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 create-tags --resources $igw_id --tags Key=Name,Value=MyInternetGateway

# Attach internet gateway to VPC
aws ec2 attach-internet-gateway --vpc-id $vpc_id --internet-gateway-id $igw_id

# Create a subnet
echo "Creating Subnet..."
subnet_id=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block 10.0.0.0/24 --query 'Subnet.SubnetId' --output text)
aws ec2 create-tags --resources $subnet_id --tags Key=Name,Value=MySubnet

# Create a route table
echo "Creating Route Table..."
rtb_id=$(aws ec2 create-route-table --vpc-id $vpc_id --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-tags --resources $rtb_id --tags Key=Name,Value=MyRouteTable

# Associate the route table with the subnet
aws ec2 associate-route-table --subnet-id $subnet_id --route-table-id $rtb_id

# Create a route to internet gateway
aws ec2 create-route --route-table-id $rtb_id --destination-cidr-block 0.0.0.0/0 --gateway-id $igw_id

# Create a security group
echo "Creating Security Group..."
security_group_id=$(aws ec2 create-security-group --group-name MySecurityGroup --description "My Security Group" --vpc-id $vpc_id --query 'GroupId' --output text)

# Authorize inbound SSH traffic in the security group
aws ec2 authorize-security-group-ingress --group-id $security_group_id --protocol tcp --port 22 --cidr 0.0.0.0/0

# Generate a key pair
echo "Generating Key Pair..."
aws ec2 create-key-pair --key-name ec2Key --query 'KeyMaterial' --output text > ec2Key.pem
chmod 400 ec2Key.pem

# EC2 instance
echo "Launching EC2 instance..."
aws ec2 run-instances \
  --image-id ami-0fc5d935ebf8bc3bc \
  --instance-type t2.micro \
  --key-name ec2Key \
  --subnet-id $subnet_id \
  --security-group-ids $security_group_id \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=MyEC2Instance}]'

echo "Completed!"

