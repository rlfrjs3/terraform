output "bucket_name" { value = aws_s3_bucket.tf-bucket.bucket } #단순 버킷이름   my-bucket
output "bucket_domain_name" { value = aws_s3_bucket.tf-bucket.bucket_domain_name }
