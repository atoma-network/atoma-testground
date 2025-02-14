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
