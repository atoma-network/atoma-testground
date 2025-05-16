resource "aws_security_group" "atoma" {
  name        = "atoma-sg"
  description = "Security group for Atoma instances"
  vpc_id      = var.vpc_id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Docker ports
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3001
    to_port     = 3001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 4001
    to_port     = 4001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 4001
    to_port     = 4001
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8083
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8083
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Monitoring ports
  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 30000
    to_port     = 30000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "atoma-sg"
  }
}

resource "tls_private_key" "atoma" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "atoma" {
  key_name   = var.key_name
  public_key = tls_private_key.atoma.public_key_openssh
}

output "private_key" {
  value     = tls_private_key.atoma.private_key_pem
  sensitive = true
}

resource "aws_instance" "atoma_node" {
  count = var.deploy_node ? 1 : 0

  ami           = var.ami_id
  instance_type = var.node_instance_type
  key_name      = aws_key_pair.atoma.key_name
  subnet_id     = var.subnet_id

  vpc_security_group_ids = [aws_security_group.atoma.id]

  root_block_device {
    volume_size = 100
    volume_type = "gp3"
  }

  user_data = templatefile("${path.module}/templates/node_setup.sh", {
    node_branch = var.node_branch
  })

  tags = {
    Name = "atoma-node"
  }
}

resource "aws_instance" "atoma_proxy" {
  count = var.deploy_proxy ? 1 : 0

  ami           = var.ami_id
  instance_type = var.proxy_instance_type
  key_name      = aws_key_pair.atoma.key_name
  subnet_id     = var.subnet_id

  vpc_security_group_ids = [aws_security_group.atoma.id]

  root_block_device {
    volume_size = 100
    volume_type = "gp3"
  }

  user_data = templatefile("${path.module}/templates/proxy_setup.sh", {
    proxy_branch = var.proxy_branch
  })

  tags = {
    Name = "atoma-proxy"
  }
}
