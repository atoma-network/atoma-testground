# Import modules for different components of the infrastructure

module "networking" {
  source = "./modules/networking"

  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  private_subnets    = var.private_subnets
  public_subnets     = var.public_subnets
}

module "atoma" {
  source = "./modules/atoma"

  vpc_id              = module.networking.vpc_id
  subnet_id           = module.networking.public_subnet_ids[0]
  key_name            = var.key_name
  ami_id              = var.ami_id
  node_instance_type  = var.node_instance_type
  proxy_instance_type = var.proxy_instance_type
  deploy_node         = var.deploy_node
  deploy_proxy        = var.deploy_proxy
  node_branch         = var.node_branch
  proxy_branch        = var.proxy_branch
}
