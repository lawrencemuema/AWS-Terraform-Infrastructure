provider "aws" {
  region = "us-east-1"
}

#what does this code do in summary

#creates an internet gateway
#creates a vpc
#creates 2 subnets in different availability zones
#creates a launch configuration for the EC2 instances
#creates an autoscaling group to manage the EC2 instances
#creates a security group to control the traffic that is allowed to reach the EC2 instances
#creates an ELB to distribute traffic between the EC2 instances
#creates a target group to manage the EC2 instances
#creates a target group attachment to attach the EC2 instances to the target group
#creates an ELB listener to listen for traffic on a specific port and forward it to the target group


#THE BORING STUFF


# create vpc
resource "aws_vpc" "vpc" {
  cidr_block =  "10.0.0.0/16" 
  #10.0.0.0/16 means we have 65,536 IP addresses available to us in this VPC
  #Ip range is from 10.0.0.0 - 10.0.255.255
    tags = {
        Name = "azubi_vpc"
    }


}
#end of vpc creation

#internet gateway is used to allow traffic to enter and leave the VPC
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

#subnet is used to divide the VPC into smaller networks
resource "aws_subnet" "subnet_az1" {
  cidr_block = "10.0.1.0/24"
  #10.0.1.0/24 has a range from 10.0.1.0 - 10.0.1.255
  availability_zone = "us-east-1a"
  vpc_id = aws_vpc.vpc.id
}

resource "aws_subnet" "subnet_az2" {
  cidr_block = "10.0.2.0/24"
  #10.0.2.0/24 has a range from 10.0.2.0 - 10.0.2.255
  availability_zone = "us-east-1c"
  vpc_id = aws_vpc.vpc.id
}
#end of subnet creation

# Creating a route table
resource "aws_route_table" "custom_route_table" {
  vpc_id = aws_vpc.vpc.id

  # Define your routes here
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "CustomRouteTable"
  }
}

# Associating the route table with subnet_az1
resource "aws_route_table_association" "subnet_az1_assoc" {
  subnet_id      = aws_subnet.subnet_az1.id
  route_table_id = aws_route_table.custom_route_table.id
}

# Associating the route table with subnet_az2
resource "aws_route_table_association" "subnet_az2_assoc" {
  subnet_id      = aws_subnet.subnet_az2.id
  route_table_id = aws_route_table.custom_route_table.id
}

#THE FUN BEGINS



#security group is used to control the traffic that is allowed to reach the EC2 instances
resource "aws_security_group" "sg" {
  name        = "sg"
  description = "Allow inbound HTTP and HTTPS traffic"
  vpc_id      = aws_vpc.vpc.id

    #Ingress is used to allow traffic to reach the EC2 instances
  ingress {
    from_port   = 80 #port 80 is used for HTTP traffic
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443 #port 443 is used for HTTPS traffic
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22 #port 22 is used for SSH traffic
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }




    #Egress is used to allow traffic to leave the EC2 instances
  egress {
    from_port   = 0 #port 0 is used for all traffic
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#ASG launch configuration is used to configure the EC2 instances that will be launched by the ASG
resource "aws_launch_configuration" "launch_config" {
  name = "azubi-launch-config"
  image_id = "ami-0fc5d935ebf8bc3bc" 
    #ami-0fc5d935ebf8bc3bc is the AMI ID for ubuntu 18.04
  instance_type = "t2.micro"
  associate_public_ip_address = true  # Add this line to assign public IPs to instances
  security_groups    = [aws_security_group.sg.id]

   user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install -y apache2

              cat <<HTML > /var/www/html/index.html
              <html>
              <head>
                <title>EC2 Info</title>
                <style>
                  body {
                    font-family: Arial, sans-serif;
                    padding: 20px;
                  }
                  h1 {
                    color: #333;
                  }
                  p {
                    margin-bottom: 10px;
                  }
                  .info {
                    border: 1px solid #ccc;
                    padding: 10px;
                    margin-bottom: 20px;
                    border-radius: 5px;
                    background-color: #f9f9f9;
                  }
                </style>
              </head>
              <body>
                <h1>Welcome to EC2!</h1>

                <div class="info">
                  <h2>Instance Details:</h2>
                  <p><strong>Instance ID:</strong> \\\$(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>
                  <p><strong>Availability Zone:</strong> \\\$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)</p>
                  <p><strong>Public IP:</strong> \\\$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)</p>
                </div>

                <div class="info">
                  <h2>Hello World:</h2>
                </div>

                <p>Designed by Lawrence M</p>
              </body>
              </html>
              HTML

              sudo systemctl start apache2
              sudo systemctl enable apache2
              EOF
}

#ASG is used to manage the EC2 instances - here we are telling it to launch 2 instances
resource "aws_autoscaling_group" "asg" {

  desired_capacity     = 2 #number of instances to launch
  max_size             = 3 #max number of instances to launch
  min_size             = 1
  vpc_zone_identifier = [aws_subnet.subnet_az1.id, aws_subnet.subnet_az2.id]
  launch_configuration = aws_launch_configuration.launch_config.id
  health_check_type          = "EC2"
  health_check_grace_period  = 300
  force_delete                = true

  tag {
    key                 = "Name"
    value               = "web-instance"
    propagate_at_launch = true
  }

  
  # Ensure the ASG instances register with the Target Group
  lifecycle {
    create_before_destroy = true
  }
}

#ELB is used to distribute traffic between the EC2 instances
resource "aws_lb" "lb" {
  name               = "azubi-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg.id]
  enable_deletion_protection = false
  subnets            = [aws_subnet.subnet_az1.id, aws_subnet.subnet_az2.id]

}




#target group is a group of EC2 instances that the ELB will forward traffic to

resource "aws_lb_target_group" "target_group" {
  name        = "azubi-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
  }
}

#ELB listener is used to listen for traffic on a specific port and forward it to the target group
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.target_group.arn
    type             = "forward"

  }
}