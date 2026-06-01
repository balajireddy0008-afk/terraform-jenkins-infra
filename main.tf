
## Latest Amazon Linux 2023 AMI ##

data "aws_ami" "amazon_linux" {

  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*"]
  }
}

## VPC ##

resource "aws_vpc" "jenkins_vpc" {

  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "jenkins-vpc"
  }
}


## Public Subnet ##

resource "aws_subnet" "public_subnet" {

  vpc_id = aws_vpc.jenkins_vpc.id

  cidr_block = "10.0.1.0/24"

  map_public_ip_on_launch = true

  availability_zone = "ap-south-1a"

  tags = {
    Name = "public-subnet"
  }
}


## Internet Gateway ##
resource "aws_internet_gateway" "igw" {

  vpc_id = aws_vpc.jenkins_vpc.id

  tags = {
    Name = "jenkins-igw"
  }
}

## Route Table ##

resource "aws_route_table" "public_rt" {

  vpc_id = aws_vpc.jenkins_vpc.id

  route {
    cidr_block = "0.0.0.0/0"

    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_assoc" {

  subnet_id      = aws_subnet.public_subnet.id

  route_table_id = aws_route_table.public_rt.id
}


## Security Group ##

resource "aws_security_group" "jenkins_sg" {

  name   = "jenkins-sg"

  vpc_id = aws_vpc.jenkins_vpc.id

  ingress {

    from_port = 22
    to_port   = 22

    protocol = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {

    from_port = 8080
    to_port   = 8080

    protocol = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {

    from_port = 0
    to_port   = 0

    protocol = "-1"

    cidr_blocks = ["0.0.0.0/0"]
  }
}

## Key Pair ##

resource "aws_key_pair" "jenkins_key" {

  key_name = "jenkins-key"

  public_key = file("C:/Users/User/.ssh/id_rsa.pub")
}

# EC2
#
resource "aws_instance" "jenkins_server" {

  ami = data.aws_ami.amazon_linux.id

  instance_type = var.instance_type

  subnet_id = aws_subnet.public_subnet.id

  vpc_security_group_ids = [
    aws_security_group.jenkins_sg.id
  ]

  key_name = aws_key_pair.jenkins_key.key_name

  user_data = file("userdata.sh")

  tags = {
    Name = "Jenkins-Server"
  }
}