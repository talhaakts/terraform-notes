provider "aws" {
  region     = "us-east-1"
  access_key = ""
  secret_key = ""
}

locals {
  talha_user_data = <<EOF
#!/bin/bash
sudo apt update -y
sudo apt install docker.io -y
sudo service docker start
sudo wget https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo chmod +x minikube-linux-amd64
sudo mv minikube-linux-amd64 /usr/local/bin/minikube
sudo curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
sudo minikube start --force
EOF
}
resource "aws_key_pair" "talha-key" {
  key_name   = "talha-key"
  public_key = "${file("talha-key.pub")}"
}

resource "aws_instance" "talha-instance" {
  ami           = "ami-0557a15b87f6559cf"
  instance_type = "t2.medium"
  vpc_security_group_ids = ["${aws_security_group.talha-security.id}"]
  key_name               = "${aws_key_pair.talha-key.key_name}"
  tags = {
    Name = "talha-ec2"
  }
  user_data = "${local.talha_user_data}"
}


data "aws_vpc" "selected" {}

resource "aws_security_group" "talha-security" {
  description = "talha-security"
  vpc_id      = "${data.aws_vpc.selected.id}"
  name        = "talha-security"

  tags = {
    Name = "talha-security"
  }
}

resource "aws_security_group_rule" "all-inbound" {
  type              = "ingress"
  security_group_id = "${aws_security_group.talha-security.id}"
  from_port         = -1
  to_port           = 0
  protocol          = "-1"

  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "all-outbound" {
  type              = "egress"
  security_group_id = "${aws_security_group.talha-security.id}"
  from_port         = -1
  to_port           = 0
  protocol          = "-1"

  cidr_blocks = ["0.0.0.0/0"]
}
