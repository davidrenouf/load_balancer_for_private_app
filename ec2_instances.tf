data "aws_ami" "ubuntu" {
    most_recent = true

    filter {
      name   = "name"
      values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-*"]
    }

    filter {
      name   = "architecture"
      values = ["x86_64"]
    }

    filter {
      name   = "virtualization-type"
      values = ["hvm"]
    }

    owners = ["099720109477"] # Canonical
}

resource "aws_instance" "private_a" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id = aws_subnet.private_subnet_a.id
  vpc_security_group_ids = [aws_security_group.instance_security_group.id]

  key_name = "lb-internal"

  user_data = <<EOF
#!/bin/bash

sudo apt update
sudo apt install -y nginx
EOF

  tags = {
    Name = "private-instance-a"
  }
}

resource "aws_instance" "private_b" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id = aws_subnet.private_subnet_b.id
  vpc_security_group_ids = [aws_security_group.instance_security_group.id]

  key_name = "lb-internal"

  user_data = <<EOF
#!/bin/bash

sudo apt update
sudo apt install -y nginx
EOF

  tags = {
    Name = "private-instance-b"
  }
}

resource "aws_security_group" "instance_security_group" {
  name        = "${var.env}-instance-security-group"
  description = "Allow HTTP(S) access for instances from VPC"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.vpc.cidr_block]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.vpc.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env}-instance-security-group"
  }
}
