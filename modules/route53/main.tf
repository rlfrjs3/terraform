#apply 전, 다음의 수동작업 필요#  -> 초기 1번 진행하고 나서 destroy하고 다시 apply할 때에는 안해줘도 됨(호스팅영역은 삭제되지 않기 때문에 그대로 있음)
#근데 호스팅영역을 콘솔에서 따로 삭제한다면, apply 하기 전에 아래 2개 선행 작업 필요함
#1.route53에서 개인도메인 호스팅역 생성
#2.생성 후 할당된 AWS 네임서버로 변경





###<ACM에서 SSL인증서 발급>
resource "aws_acm_certificate" "ssl_cert" {
  domain_name               = var.domain_name            #SSL 인증서의 도메인 이름
  subject_alternative_names = ["www.${var.domain_name}"] #추가적인 대체 도메인 이름
  validation_method         = "DNS"
  lifecycle { create_before_destroy = true } #인증서 갱신 시 먼저 새 인증서를 생성한 후, 기존 인증서를 제거
}




###<SSL 인증서 DNS인증 자동화>
#검증을 위한 DNS레코드 받아오기
resource "aws_route53_record" "ssl_cert_record" {
  for_each = {
    for dvo in aws_acm_certificate.ssl_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name #검증을 위한 레코드 이름
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }
  #위에서 받아온 레코드 내 도메인에 적용해서 인증하기
  zone_id = data.aws_route53_zone.hosting_zone.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 300
}

#실제 SSL인증서 검증 프로세스
resource "aws_acm_certificate_validation" "ssl_cert_validation" {
  certificate_arn         = aws_acm_certificate.ssl_cert.arn                                 #위 ACM에서 생성한 SSL인증서 
  validation_record_fqdns = [for record in aws_route53_record.ssl_cert_record : record.fqdn] #위 검증을 위해 생성한 DNS레코드 
}









###<Route53에서 수동으로 만든 개인도메인 호스팅영역 불러오기>
data "aws_route53_zone" "hosting_zone" {
  name = var.domain_name
}


###<DNS 레코드에 cloudfront 배포 레코드 설정하기>
resource "aws_route53_record" "root_domain" { #대포도메인 레코드 설정
  zone_id = data.aws_route53_zone.hosting_zone.zone_id
  name    = var.domain_name
  type    = "A"
  alias {
    name                   = var.cloudfront_domain_name
    zone_id                = "Z2FDTNDATAQYW2" #cloudfront의 zone ID는 항상 다음의 고정값을 가지므로 하드코딩(글로벌 서비스이기 때문에 고정된 ID를 사용함)
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_domain" { #www 서브도메인 레코드 설정
  zone_id = data.aws_route53_zone.hosting_zone.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"
  alias {
    name                   = var.cloudfront_domain_name
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}





