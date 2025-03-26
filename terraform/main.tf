# Import modules for different components of the infrastructure

module "networking" {
  source = "./modules/networking"

  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  private_subnets    = var.private_subnets
  public_subnets     = var.public_subnets
}

module "ecs" {
  source = "./modules/ecs"

  environment     = var.environment
  vpc_id          = module.networking.vpc_id
  private_subnets = module.networking.private_subnet_ids
  public_subnets  = module.networking.public_subnet_ids
}

module "monitoring" {
  source = "./modules/monitoring"

  environment     = var.environment
  vpc_id          = module.networking.vpc_id
  private_subnets = module.networking.private_subnet_ids
}

module "storage" {
  source = "./modules/storage"

  environment     = var.environment
  vpc_id          = module.networking.vpc_id
  private_subnets = module.networking.private_subnet_ids
}

# Example simplified Terraform configuration
resource "aws_instance" "atoma_node" {
  ami           = "ami-0c55b159cbfafe1f0" # Ubuntu 20.04 LTS
  instance_type = "c6i.2xlarge"           # 8 vCPUs, 16 GiB memory
  key_name      = aws_key_pair.deployer.key_name

  # More configuration...
}

resource "aws_instance" "atoma_proxy" {
  ami           = "ami-0c55b159cbfafe1f0" # Ubuntu 20.04 LTS
  instance_type = "c5.xlarge"             # 4 vCPUs, 8 GiB memory
  key_name      = aws_key_pair.deployer.key_name

  # More configuration...
}
