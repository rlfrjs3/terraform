terraform { #CloudFront에 SSL 인증서를 연결하기 위해 인증서를 us-east-1 리전에서 생성
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

