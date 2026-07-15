###<각 모듈별 변수 참조>



module "network" {
  source               = "./modules/network"
  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "compute" {
  source             = "./modules/compute"
  project_name       = var.project_name
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids
  web_sg_id          = module.network.web_sg_id
  efs_sg_id          = module.network.efs_sg_id
  bastion_sg_id      = module.network.bastion_sg_id
  ami_id             = var.ami_id
  instance_type      = var.instance_type
  key_name           = var.key_name
}

module "s3" {
  source       = "./modules/s3"
  project_name = var.project_name
}

#module "rds" {
#  source             = "./modules/rds"
#  project_name       = var.project_name
#  private_subnet_ids = module.network.private_subnet_ids
#  rds_sg_id          = module.network.rds_sg_id
#}

module "cloudfront" {
  source = "./modules/cloudfront"
  #providers = { aws = aws.us_east_1 }   #cloudfront는 글로벌 리소스이기 때문에 필요없음
  project_name       = var.project_name
  alb_dns_name       = module.compute.alb_dns_name
  ssl_cert_arn       = module.route53.ssl_cert_arn
  domain_name        = var.domain_name
  bucket_domain_name = module.s3.bucket_domain_name
}

module "route53" {
  source                 = "./modules/route53"
  providers              = { aws = aws.us_east_1 } #provider.alias 리전 지정 (Cloudfront에 ACM SSL 인증서를 적용할 때, us-east-1 리전의 인증서만 참조 가능하기 때문에)
  domain_name            = var.domain_name
  cloudfront_domain_name = module.cloudfront.cloudfront_domain_name
}

#module "ssm" {
#  source = "./modules/ssm"
#}







