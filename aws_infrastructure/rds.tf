resource "aws_security_group" "airbyte_poc_db_sg" {
  name        = "airbyte_db_sg"
  description = "Allow PostgreSQL"
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.airbyte_poc_ec2_sg.id]
  }
}

data "aws_ssm_parameter" "airbyte_poc_postgres_db_user_password" {
  name = "/airbyte/poc/postgres_db_user_password"
}

resource "aws_rds_cluster" "airbyte_postgres_db_rds_cluster" {
  cluster_identifier     = "airbyte-poc-rds-cluster"
  engine                 = "aurora-postgresql"
  engine_version         = "13.12"
  database_name          = "airbyte"
  master_username        = "postgres"
  master_password        = data.aws_ssm_parameter.airbyte_poc_postgres_db_user_password.value
  vpc_security_group_ids = [aws_security_group.airbyte_poc_db_sg.id]
  skip_final_snapshot    = true
  # db_subnet_group_name = "default-vpc-${data.aws_vpc.default.id}"
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_rds_cluster_instance" "airbyte_postgres_db_rds_instance" {
  identifier          = "airbyte-poc-rds-instance"
  cluster_identifier  = aws_rds_cluster.airbyte_postgres_db_rds_cluster.id
  instance_class      = "db.t3.medium"
  engine              = aws_rds_cluster.airbyte_postgres_db_rds_cluster.engine
  engine_version      = aws_rds_cluster.airbyte_postgres_db_rds_cluster.engine_version
  publicly_accessible = false
  # db_subnet_group_name = "default-${data.aws_vpc.default.id}"
  db_subnet_group_name = "default"
}

resource "aws_ssm_parameter" "airbyte_poc_postgres_rds_db_endpoint_url" {
  name  = "/airbyte/poc/airbyte_poc_postgres_rds_db_endpoint_url"
  type  = "String"
  value = aws_rds_cluster.airbyte_postgres_db_rds_cluster.endpoint
}
