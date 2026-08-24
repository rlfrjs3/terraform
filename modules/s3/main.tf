###<S3 버킷>
## 버킷의 권한설정은, 버킷정책 / 객체 소유권 / ACL 설정 이렇게 3개가 있음 (객체 소유권은 ACL 활성화/비활성화 여부를 결정하는 것이고, ACL은 세부 설정을 자세하게 할 수 있는 것)
## cloudfront가 S3에 로깅하려면 버킷정책만으로는 안되고, ACL 활성화가 필요(ObjectWriter)
## cloudfront legacy logging 방식을 사용하는데 이 방식 자체가 ACL을 사용하는 방식으로 설계되었기 때문에 무조건 ACL을 활성화 해줘야 함

#버킷 생성
resource "aws_s3_bucket" "tf-bucket" {
  bucket        = "${var.project_name}-rlfrjs3-bucket"
  force_destroy = true # 삭제 시, 버킷 내 객체가 있어도 버킷 삭제 
  tags          = { Name = "${var.project_name}--bucket" }
}

#버킷의 객체 소유권 제어 (ACL 활성화 - cloudfront가 S3에 접근하기 위해서는 ACL 활성화 필요)
resource "aws_s3_bucket_ownership_controls" "tf-bucket-ownership" {
  bucket = aws_s3_bucket.tf-bucket.id
  rule {
    object_ownership = "ObjectWriter" #버킷에 업르드하는 주체가 객체의 소유자가 됨(cloudfront가 S3에 로깅할 때 ACL 문제로 접근 실패하는 것을 방지)
  }
}

#버킷 정책 (cloudfront에서 로깅을 위해 S3에 접근할 수 있도록)
resource "aws_s3_bucket_policy" "tf-bucket-policy" {
  bucket = aws_s3_bucket.tf-bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontLogging"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.tf-bucket.arn}/*"
      }
    ]
  })
}
