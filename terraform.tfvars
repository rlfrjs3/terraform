###value 설정파일 - 해당 파일의 값들만 수정하면 코드 재사용이 가능하도록

#tag값
project_name = "tf-project-1"

#VPC
region               = "ap-northeast-2"
vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["ap-northeast-2a", "ap-northeast-2b"]
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.101.0/24", "10.0.102.0/24"]

#EC2
ami_id        = "ami-0ae2c887094315bed" #Amazon linux 2023 ami
instance_type = "t3.micro"
key_name      = "iac_keypair"

#route53
domain_name = "kkangsoju.co.kr"


