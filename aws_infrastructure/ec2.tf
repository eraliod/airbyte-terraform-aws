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
    from_port   = 8006
    to_port     = 8006
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

resource "aws_instance" "ec2_instance" {
  ami           = "ami-019f9b3318b7155c5"
  instance_type = "t2.medium"
  # availability_zone    = "us-east-2b"
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
}

# store the ec2 instance ip in ssm parameter store
resource "aws_ssm_parameter" "airbyte_poc_ec2_instance_ip" {
  name  = "/airbyte/poc/ec2_instance_ip"
  type  = "String"
  value = aws_instance.ec2_instance.public_ip
}