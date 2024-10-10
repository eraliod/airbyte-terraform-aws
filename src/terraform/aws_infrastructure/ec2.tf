# security group allowing ec2 instance to connect to the rds instance, ingress to the airbyte ui and api
# this security group is far too permissive for anything more than a poc
resource "aws_security_group" "airbyte_poc_ec2_sg" {
  name        = "airbyte_ec2_sg"
  description = "Allow SSH and Airbyte"
  # ssh
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Airbyte user interface 
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Airbyte api server
  ingress {
    from_port   = 8001
    to_port     = 8001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # need this egress rule to fetch data from s3 and github (Airbyte docker image and connectors)
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # need this egress rule to grab the uid from ulid.abapp.cloud. Part of the run-ab-platform.sh script
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # need to connect to the postgres database
  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # ping out to check for internet connectivity
  egress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# find the latest ami for ec2 amazon-linux instances
data "aws_ami" "latest" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  owners = ["137112412989"] # Amazon Linux 2
}

resource "aws_instance" "ec2_instance" {
  ami                  = data.aws_ami.latest.id
  instance_type        = "t2.medium"
  security_groups      = [aws_security_group.airbyte_poc_ec2_sg.name]
  iam_instance_profile = aws_iam_instance_profile.airbyte_poc_ec2_instance_profile.name
  user_data            = file("${path.module}/init.sh")
  tags = {
    Name = "airbyte-poc-ec2"
  }
  root_block_device {
    volume_size = 100
    volume_type = "gp3"
  }
  depends_on = [
    aws_ssm_parameter.airbyte_poc_postgres_rds_db_endpoint_url,
  ]
  provisioner "local-exec" {
    command = "aws ec2 wait instance-running --instance-ids ${self.id}"
  }
}
