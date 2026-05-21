###<S3 버킷>
#버킷 생성
resource "aws_s3_bucket" "tf-bucket" {
  bucket        = "${var.project_name}-rlfrjs3-bucket"
  force_destroy = true # 삭제 시, 버킷 내 객체가 있어도 버킷 삭제 
  tags          = { Name = "${var.project_name}--bucket" }
}

#버킷 소유권 제어 (ACL 활성화 - cloudfront가 s3에 접근하기 위해서는 ACL 활성화 필요)
resource "aws_s3_bucket_ownership_controls" "tf-bucket-ownership" {
  bucket = aws_s3_bucket.tf-bucket.id
  rule {
    object_ownership = "ObjectWriter" #버킷에 업르드하는 주체가 객체의 소유자가 됨(cloudfront가 S3에 로깅할 때 ACL 문제로 접근 실패하는 것을 방지)
  }
}

#버킷 정책 (cloudfront에서 로깅을 위해 s3에 접근할 수 있도록)
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
