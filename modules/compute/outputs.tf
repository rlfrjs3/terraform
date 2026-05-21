output "alb_dns_name" { value = aws_lb.web_alb.dns_name }
output "alb_zone_id" { value = aws_lb.web_alb.zone_id }
output "efs_dns_name" { value = aws_efs_file_system.web-efs.dns_name }
output "ec2_private_ip" { value = data.aws_instances.asg_instances.private_ips }
output "bastionhost_public_ip" { value = aws_instance.bastion.public_ip }
