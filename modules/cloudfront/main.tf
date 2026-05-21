###<CloudFront>
#cloudfront 배포 생성
resource "aws_cloudfront_distribution" "tf-cloudfront" {
  origin {                         #cloudfront의 오리진 설정
    domain_name = var.alb_dns_name #cloudfront 캐시에 없는 요청은 ALB로 전달
    origin_id   = "alb_origin"
    custom_origin_config { #cloudfront 오리진 설정
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only" #cloudfront가 ALB로 트래픽을 전달할 때 HTTP로 강제하도록 설정
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }
  default_cache_behavior {                              #cloudfront 캐싱 설정
    target_origin_id       = "alb_origin"               #cloudfrot 캐시에 없는 요청 시 데이터를 가져올 오리진 ID
    viewer_protocol_policy = "redirect-to-https"        #클라가 HTTP로 요청 시 HTTPS로 리다이렉트(클라와 cloudfront간 SSL 통신)
    allowed_methods        = ["GET", "HEAD", "OPTIONS"] #클라가 사용할 수 있는 메서드
    cached_methods         = ["GET", "HEAD"]            #캐시에 저장할 수 있는 메서드
    default_ttl            = 300
    min_ttl                = 300
    max_ttl                = 3600
    forwarded_values {
      query_string = false #요청 시 쿼리 문자열을 오리진으로 전달하지 않음
      cookies {
        forward = "none" #쿠키 정보를 오리진으로 전달하지 않음
      }
    }
  }
  aliases = [var.domain_name, "www.${var.domain_name}"]
  viewer_certificate {
    acm_certificate_arn      = var.ssl_cert_arn #ACM에서 만든 SSL 인증서 연결
    ssl_support_method       = "sni-only"       #SNI 기반 SSL지원 
    minimum_protocol_version = "TLSv1.2_2019"
  }

  logging_config { #cloudfront 로깅 설정(S3 버킷으로 전달)
    bucket          = var.bucket_domain_name
    prefix          = "cloudfront-log/" #S3 버킷 내 로그가 쌓이는 경로
    include_cookies = false             #쿠키 정보는 로그에 포함되지 않음
  }
  enabled = true #cloudfront 배포 활성화 여부
  restrictions { #지역 제한설정
    geo_restriction {
      restriction_type = "none" #모든 국가에서 접근 허용
    }
  }

  tags = { Name = "${var.project_name}-cloudfront" }
}



