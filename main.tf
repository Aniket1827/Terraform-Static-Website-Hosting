#Things to get ready -
    # VPC
    # 2 public subnets
    # Internet gateway
    # Route Table
    # Security Group for web server (port 80) and SSH access from anywhere
    # EC2
    # Load balancer
    # S3

resource "aws_vpc" "aniket_vpc" {
  cidr_block = var.vpc_cidr_block
}

resource "aws_subnet" "subnet_1" {
  vpc_id = aws_vpc.aniket_vpc.id
  cidr_block = var.subnet_1_cidr_block
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "subnet_2" {
  vpc_id = aws_vpc.aniket_vpc.id
  cidr_block = var.subnet_2_cidr_block
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.aniket_vpc.id
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.aniket_vpc.id

  route {
    cidr_block = var.route_table_cidr_block 
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
}

resource "aws_route_table_association" "subnet_association_1" {
  subnet_id = aws_subnet.subnet_1.id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_route_table_association" "subnet_association_2" {
  subnet_id = aws_subnet.subnet_2.id
  route_table_id = aws_route_table.route_table.id
}

# Creating of security group
# 1. Bind it to the create VPC
# 2. Specify the inbound traffic rules
# 3. Specify the outbout traffic rules
resource "aws_security_group" "security_group" {
  name        = "security-group"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.aniket_vpc.id

  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22 
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_s3_bucket" "aniketsproject" {
  bucket = "anikets-project"
}

resource "aws_instance" "instance_1" {
  ami = var.ami_id
  instance_type = var.instance_type
  subnet_id = aws_subnet.subnet_1.id
  security_groups = [ aws_security_group.security_group.id ]
  user_data = base64encode(file("user_data_1.sh"))
}

resource "aws_instance" "instance_2" {
  ami = var.ami_id
  instance_type = var.instance_type
  subnet_id = aws_subnet.subnet_2.id
  security_groups = [ aws_security_group.security_group.id ]
  user_data = base64encode(file("user_data_2.sh"))
}

# Creation of Load Balancer and its association
# 1. Create a Load Balancer
# 2. Crate a target group
# 3. Attach instances to target group
# 4. Configure listener

resource "aws_lb" "myalb" {
  name               = "myalb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.security_group.id]
  subnets         = [aws_subnet.subnet_1.id, aws_subnet.subnet_2.id]

  tags = {
    Name = "web"
  }
}

# Every LB needs a target-group associated with it, to which it will route the traffic
resource "aws_lb_target_group" "tg" {
  name     = "myTG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.aniket_vpc.id

  health_check {
    path = "/"
    port = "traffic-port"
  }
}

# After creating of target-group, attach the instance to the target group
resource "aws_lb_target_group_attachment" "attach1" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.instance_1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "attach2" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.instance_2.id
  port             = 80
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.myalb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.tg.arn
    type             = "forward"
  }
}

output "loadbalancerdns" {
  value = aws_lb.myalb.dns_name
}