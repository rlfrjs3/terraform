###<CloudFront>
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


#기본 Behavior - 정적 파일 패턴에 해당하지 않는 캐싱하지 않음
  default_cache_behavior {                              
    target_origin_id       = "alb_origin"               #cloudfrot 캐시에 없는 요청 시 데이터를 가져올 오리진 ID
    viewer_protocol_policy = "redirect-to-https"        #클라가 HTTP로 요청 시 HTTPS로 리다이렉트(클라와 cloudfront간 SSL 통신)
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]     #애플리케이션에서 사용할 수 있는 메소드
    cached_methods         = ["GET", "HEAD"]
    default_ttl            = 0
    min_ttl                = 0
    max_ttl                = 0
    forwarded_values {       #동적 요청은 Query String 전달
      query_string = true
      cookies {
        forward = "all"      #로그인/세션 등 동적 요청을 위해 쿠키 전달
      }
    }
  }

#정적 콘텐츠 Behavior - 아래 확장자 해당하는 요청만 캐싱 
  dynamic "ordered_cache_behavior" {

    for_each = toset([
      "*.css",
      "*.js",
      "*.jpg",
      "*.jpeg",
      "*.png",
      "*.gif",
      "*.ico",
      "*.webp",
      "*.svg",
      "*.woff",
      "*.woff2",
      "*.ttf",
      "*.eot"
    ])
   
    content {
      path_pattern           = ordered_cache_behavior.value
      target_origin_id       = "alb_origin"
      viewer_protocol_policy = "redirect-to-https"
      allowed_methods 	     = ["GET", "HEAD", "OPTIONS"]
      cached_methods         = ["GET", "HEAD"]
      default_ttl            = 3600
      min_ttl                = 300
      max_ttl                = 86400
      compress 		     = true    # css와 js 등의 압축 활성화
      forwarded_values {
        query_string = false
        cookies {
          forward = "none"     #정적 컨텐츠는 쿠키를 오리진으로 전달하지 않음      
        }
      }
    }
  }

# CloudFront와 개인도메인 연결
  aliases = [var.domain_name, "www.${var.domain_name}"]

# ACM SSL 연결
  viewer_certificate {
    acm_certificate_arn      = var.ssl_cert_arn #ACM에서 만든 SSL 인증서 연결
    ssl_support_method       = "sni-only"       #SNI 기반 SSL지원 
    minimum_protocol_version = "TLSv1.2_2019"
  }

# CloudFront 액세스 로그 S3에 저장
  logging_config { #cloudfront legacy  로깅 설정(S3 버킷으로 전달) -> S3 버킷의 ACL이 반드시 활성화 되어있어야 함
    bucket          = var.bucket_domain_name
    prefix          = "cloudfront-log/" #S3 버킷 내 로그가 쌓이는 경로
    include_cookies = false             #쿠키 정보는 로그에 포함되지 않음
  }

# CloudFront 배포 활성화
  enabled = true 

# 배포 지역 제한
  restrictions { 
    geo_restriction {
      restriction_type = "none" #모든 국가에서 접근 허용
    }
  }

  tags = { Name = "${var.project_name}-cloudfront" }
}



