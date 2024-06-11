provider "aws" {
  region = "$AWS_REGION"
}

terraform {
  backend "s3" {
    bucket         = "$BUCKET_NAME"
    key            = "terraform/state"
    region         = "$AWS_REGION"
    dynamodb_table = "terraform-lock"
  }
}

variable "environment" {
  type = string
  default = "dev"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone = element(["us-east-1a", "us-east-1b"], count.index)
}

resource "aws_security_group" "sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web" {
  count         = 1  # Adjust the count to stay within Free Tier limits
  ami           = "ami-0c55b159cbfafe1f0"  # Amazon Linux 2 AMI (Free Tier eligible)
  instance_type = "t2.micro"
  subnet_id     = element(aws_subnet.subnet.*.id, count.index)
  security_groups = [aws_security_group.sg.name]

  tags = {
    Name = "web-${count.index}-${var.environment}"
  }
}
