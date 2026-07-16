output "alb_dns_name" {
  description = "ALB의 DNS 이름"
  value       = module.compute.alb_dns_name
}

output "bucket_name" {
  description = "S3 버킷 이름"
  value       = module.s3.bucket_name
}

output "db_instance_endpoint" {
  description = "RDS 인스턴스 엔드포인트"
  value       = module.rds.db_instance_endpoint
}

output "efs_dns_name" {
  description = "EFS 파일시스템 DNS 이름"
  value       = module.compute.efs_dns_name
}

output "bastionhost_public_ip" {
  description = "배스천 호스트 공인ip"
  value       = module.compute.bastionhost_public_ip
}

output "ec2_private_ip" {
  description = "생성된 EC2 인스턴스들의 사설ip"
  value       = module.compute.ec2_private_ip
}
