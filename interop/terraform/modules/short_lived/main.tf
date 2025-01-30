terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_key_pair" "atoma" {
  key_name_prefix = "atoma-"
  public_key      = file("${path.module}/files/atoma.pub")
}

resource "aws_instance" "atoma" {
  tags = {
    Name = "atoma-node"
  }

  launch_template {
    name = "atoma-node"
  }

  key_name = aws_key_pair.atoma.key_name
}

output "public_ip" {
  value = aws_instance.atoma.public_ip
}
