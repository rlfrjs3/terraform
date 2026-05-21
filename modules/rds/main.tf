###<SSM 파라미터스토어에서 불러오기>   -> 이미 존재하는 파라미터를 불러오는 로직임(고로 만들어져 있어야 함)
data "aws_ssm_parameter" "db_password" {
  name            = "password"
  with_decryption = true
}




###<RDS>###
#RDS 서브넷 그룹(network 모듈에서 프라이빗 서브넷 참조)
resource "aws_db_subnet_group" "tf-db-subnetgroup" {
  name       = "${var.project_name}-db-subnetgroup"
  subnet_ids = var.private_subnet_ids

  tags = { Name = "${var.project_name}-db-subnetgroup" }
}

#RDS에 연결해서 사용할 파라미터 그룹(mysql8 기준)
resource "aws_db_parameter_group" "mysql8_pg" {
  name   = "mysql8-parameter-group"
  family = "mysql8.0"

  parameter {
    name         = "character_set_server"
    value        = "utf8mb4"
    apply_method = "immediate"
  }

  parameter {
    name         = "collation_server"
    value        = "utf8mb4_general_ci"
    apply_method = "immediate"
  }

  parameter {
    name         = "max_connections"
    value        = "200"
    apply_method = "immediate"
  }


  parameter {
    name         = "innodb_buffer_pool_size"
    value        = "134217728" # 128MB, 서버 메모리를 기준으로 적절히 결정
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "innodb_flush_log_at_trx_commit"
    value        = "1"
    apply_method = "immediate"
  }

  parameter {
    name         = "sync_binlog"
    value        = "1"
    apply_method = "immediate"
  }

  tags = { Name = "mysql8-custom-parameter-group" }
}

#RDS 인스턴스(앞서 만든 서브넷그룹, 파라미터그룹, RDS보안그룹을 참조하여 생성)
resource "aws_db_instance" "tf-db" {
  engine            = "mysql"
  engine_version    = "8.0"
  identifier        = "${var.project_name}-rds"
  db_name           = "terraform"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  username          = "terraform"
  password          = data.aws_ssm_parameter.db_password.value #SSM에서 가져옴

  db_subnet_group_name   = aws_db_subnet_group.tf-db-subnetgroup.id #DB 서브넷그룹 연결
  vpc_security_group_ids = [var.rds_sg_id]                          #rds 보안그룹 연결
  parameter_group_name   = aws_db_parameter_group.mysql8_pg.id      #DB 파라미터그룹 연결

  backup_retention_period = 0    #백업없이 설정
  skip_final_snapshot     = true #삭제 시 최종 스냅샷 생성을 건너뜀

  tags = { Name = "${var.project_name}-rds" }
}
