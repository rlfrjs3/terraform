###<버전 및 프로바이더 설정>
terraform {
  required_version = ">= 1.5.0" #테라폼 CLI 최소버전 요구 명시 (내 코드가 동작할 수 있는 CLI 버전)
  required_providers {          #테라폼 프로바이더 종류와 버전 명시 (명시한 프로바이더 버전을 hashicorp 레지스트리에서 다운)     
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }

  backend "local" {
    path    = "./terraform.state"
  }

#  backend "s3" {
#    bucket  = "tf-project-backend"
#    key     = "terraform-project/stephane/terraform.tfstate"
#    region  = "ap-northeast-2"
#    encrypt = true
#    #dynamodb_table = "" 
#  }
}


#참고 : 매일 클라우드 서비스들이 업데이트되기 때문에 그에 맞게 hashicorp에서도 프로바이더 버전을 업그레이드 하는 것 





###< 리전>

#공통 리전
provider "aws" {
  region = var.region
  #  profile = "stephane"
}

#cloudfront에 ACM SSL 인증서 연결을 위해서는 us-east-1 리전에서 인증서를 발급해야 함(인증서를 해당 리전에서 중앙 관리하기 때문에)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
  #  profile = "stephane"
}





