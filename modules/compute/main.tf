###<EFS>
#EFS 파일시스템 생성 (프라이빗 서브넷 배치)
resource "aws_efs_file_system" "web-efs" {
  creation_token = "${var.project_name}-efs" #중복생성 방지용 토큰
  encrypted      = true                      #저장되는 데이터는 AWS KMS를 이용해 암호화
  tags           = { Name = "${var.project_name}-efs" }
}

#EFS 마운트타겟 생성 - 각 프라이빗 서브넷마다
resource "aws_efs_mount_target" "web-efs-mt" {
  count           = length(var.private_subnet_ids) #프라이빗 서브넷마다 생성
  file_system_id  = aws_efs_file_system.web-efs.id
  subnet_id       = element(var.private_subnet_ids, count.index)
  security_groups = [var.efs_sg_id]
}



###<Auto Scaling Group>
#시작 템플릿
resource "aws_launch_template" "web" {
  name                   = "${var.project_name}-launch-template"
  image_id               = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [var.web_sg_id]
  #  iam_instance_profile { name = var.instance_profile }
  depends_on = [aws_efs_mount_target.web-efs-mt]

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size           = 50
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    }
  }
  user_data = base64encode(<<EOT
#!/bin/bash
dnf -y update && dnf -y install httpd
dnf -y install nfs-utils
systemctl enable --now httpd
echo "<h1>Welcome to My Web Server</h1>" > /var/www/html/index.html

mkdir -p /data/efs
EFS_DNS="${aws_efs_file_system.web-efs.dns_name}"

if ! grep -q "/data/efs" /etc/fstab; then
  echo "$EFS_DNS:/ /data/efs nfs4 defaults,_netdev,nofail 0 0" >> /etc/fstab
fi

for i in {1..12}; do
    mount -a
    if mountpoint -q /data/efs; then
        echo "[$(date)] EFS mount Successful" >> /var/log/efs-mount.log
        break
    fi
    echo "[$(date)] Retry $i: EFS not ready yet" >> /var/log/efs-mount.log
    sleep 10
done

if ! mountpoint -q /data/efs; then
    echo "[$(date)] EFS mount fail" >> /var/log/efs-mount.log
fi

EOT
  )

  tags = { Name = "${var.project_name}-web-server" }
}

#시작 템플릿을 사용하여 ASG를 생성 (프라이빗 서브넷 배치)
resource "aws_autoscaling_group" "web_asg" {

  target_group_arns         = [aws_lb_target_group.web_tg.arn] #ALB 타겟그룹과 연결
  desired_capacity          = 3                                #평상시 갯수
  max_size                  = 3                                #최대 갯수
  min_size                  = 3                                #최소 갯수
  vpc_zone_identifier       = var.private_subnet_ids           #프라이빗 서브넷에만 생성
  health_check_type         = "ELB"                            #웹서버 80포트 응답 없으면 삭제하고 재생성
  health_check_grace_period = 300
  #  instance_refresh { strategy = "Rolling" }              #시작템플릿 설정이 바뀐다면 기존 인스턴스 종료하고 다시 생성
  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "${var.project_name}-web-server"
    propagate_at_launch = true
  }
}

#ASG로 생성된 인스턴스들의 정보를 가져옴 -> apply 하고 인스턴스ID 들을 output으로 출력하기 위해
data "aws_instances" "asg_instances" {
  filter {
    name   = "tag:aws:autoscaling:groupName"
    values = [aws_autoscaling_group.web_asg.name]
  }

  instance_state_names = ["running"]

  depends_on = [aws_autoscaling_group.web_asg]
}









###<Application Load Balancer>  (퍼블릭 서브넷 배치)

#ALB 
resource "aws_lb" "web_alb" {
  name               = "${var.project_name}-alb"
  load_balancer_type = "application"
  security_groups    = [var.web_sg_id]
  subnets            = var.public_subnet_ids

  tags = { Name = "${var.project_name}-alb" }
}

#ALB 타겟그룹
resource "aws_lb_target_group" "web_tg" {
  name     = "${var.project_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/" #루트 경로로 HTTP 체크
    interval            = 60  #60초마다 체크
    timeout             = 10  #응답대기 5초
    healthy_threshold   = 3   #2번 연속 성공해야 정상으로 판단
    unhealthy_threshold = 3   #2번 연속 실패하면 비정상으로 판단
  }

  tags = { Name = "${var.project_name}-tg" }
}

#ALB 리스너(리스너를 통해 요청을 타겟그룹으로 전달)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward" #요청을 아래에서 지정한 타겟그룹으로 전달
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}






###<Bastion Host>
resource "aws_instance" "bastion" {
  ami             = var.ami_id
  instance_type   = var.instance_type
  subnet_id       = var.public_subnet_ids[0]
  key_name        = var.key_name
  security_groups = [var.bastion_sg_id]

  associate_public_ip_address = true

  tags = { Name = "${var.project_name}-bastionhost" }
}









# 트래픽-> ALB -> 리스너-> ALB 타겟그룹=ASG 타겟그룹  즉, ALB의 타겟그룹과 ASG의 타겟그룹이 동일
# ALB 리스너는 http 80 트래픽 통신만 받아서 처리 (https 443 통신은 클라와 cloudfront 간의 통신만)

