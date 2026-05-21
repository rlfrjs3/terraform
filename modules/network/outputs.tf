output "vpc_id" { value = aws_vpc.tf-vpc.id }
output "public_subnet_ids" { value = aws_subnet.public[*].id }
output "private_subnet_ids" { value = aws_subnet.private[*].id }
output "web_sg_id" { value = aws_security_group.web.id }
output "efs_sg_id" { value = aws_security_group.efs.id }
output "rds_sg_id" { value = aws_security_group.rds.id }
output "bastion_sg_id" { value = aws_security_group.bastion.id }
