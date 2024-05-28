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

  user_data = <<-EOF
#!/bin/bash
echo 'Starting user data script'
mkdir -p /var/log/init-scripts
chmod 755 /var/log/init-scripts
chown root:root /var/log/init-scripts

# Set permissions to allow other users to read the log file
LOGFILE="/var/log/init-scripts/airbyte-init.log"
touch "$LOGFILE"
chmod 644 "$LOGFILE"

# Format: yyyy-mm-dd hh:mm:ss
timestamp() {
  date +"%Y-%m-%d %H:%M:%S"
}

# Log a message with the current timestamp
log_message() {
  local message="$1"
  echo "$(timestamp) : $message" >> "$LOGFILE"
}

echo 'starting airbyte installation setup script'
log_message "starting airbyte installation setup script"

log_message "running yum update"
yum update -y >> "$LOGFILE" 2>&1
log_message "yum update complete"

log_message "installing docker"
yum install -y docker >> "$LOGFILE" 2>&1
log_message "docker installation complete"
log_message "testing docker - docker version: $(docker --version)"
log_message "starting docker service"
systemctl start docker >> "$LOGFILE" 2>&1
log_message "docker service started"
log_message "enabling docker service for future reboots"
systemctl enable docker >> "$LOGFILE" 2>&1
log_message "docker service enabled"
log_message "adding root and ec2-user to docker group"
usermod -a -G docker ec2-user >> "$LOGFILE" 2>&1
log_message "user added to docker group"

log_message "installing docker compose plugin (V2)"
mkdir -p /usr/local/lib/docker/cli-plugins
curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/lib/docker/cli-plugins/docker-compose >> "$LOGFILE" 2>&1
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose >> "$LOGFILE" 2>&1
# ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose >> "$LOGFILE" 2>&1
log_message "testing docker compose - docker compose version: $(docker compose version)"
log_message "docker compose installation complete"

# Create /etc/profile.d/airbyte_variables.sh to dynamically pull values from AWS SSM Parameter Store
log_message "creating /etc/profile.d/airbyte_variables.sh"
echo '#!/bin/bash' | tee /etc/profile.d/airbyte_variables.sh
echo 'export BASIC_AUTH_USERNAME=data-dolphin-admin' | tee -a /etc/profile.d/airbyte_variables.sh
echo 'export BASIC_AUTH_PASSWORD=$(aws ssm get-parameter --name /airbyte/poc/server_admin_password --with-decryption --query Parameter.Value --output text)' | tee -a /etc/profile.d/airbyte_variables.sh
echo 'export DATABASE_USER=postgres' | tee -a /etc/profile.d/airbyte_variables.sh
echo 'export DATABASE_PASSWORD=$(aws ssm get-parameter --name /airbyte/poc/postgres_db_user_password --with-decryption --query Parameter.Value --output text)' | tee -a /etc/profile.d/airbyte_variables.sh
echo 'export DATABASE_HOST=$(aws ssm get-parameter --name /airbyte/poc/airbyte_poc_postgres_rds_db_endpoint_url --with-decryption --query Parameter.Value --output text)' | tee -a /etc/profile.d/airbyte_variables.sh
echo 'export DATABASE_PORT=5432' | tee -a /etc/profile.d/airbyte_variables.sh
echo 'export DATABASE_DB=airbyte' | tee -a /etc/profile.d/airbyte_variables.sh
echo 'export DATABASE_URL=jdbc:postgresql://$${DATABASE_HOST}:5432/$${DATABASE_DB}' | tee -a /etc/profile.d/airbyte_variables.sh
log_message "airbyte_variables.sh created"

log_message "sourcing airbyte_variables.sh"
source /etc/profile.d/airbyte_variables.sh
# give enough time to source the variables (found it is needed)
sleep 10
log_message "testing sourcing airbyte_variables.sh - DATABASE_URL: $DATABASE_URL, BASIC_AUTH_USERNAME: $BASIC_AUTH_USERNAME"

# Establish a location for the Airbyte files
AIRBYTE_DIR="/opt/airbyte"
mkdir -p "$AIRBYTE_DIR" >> "$LOGFILE" 2>&1
# Ensure the directory has the appropriate permissions
chmod -R 775 "$AIRBYTE_DIR" >> "$LOGFILE" 2>&1

# Pull Airbyte and run the docker images
log_message "pulling airbyte docker image"
cd "$AIRBYTE_DIR"
wget https://raw.githubusercontent.com/airbytehq/airbyte/master/run-ab-platform.sh >> "$LOGFILE" 2>&1
log_message "airbyte docker image pulled"
log_message "making run-ab-platform.sh executable"
chmod +x run-ab-platform.sh
log_message "downloading docker compose airbyte resources"
./run-ab-platform.sh -d >> "$LOGFILE" 2>&1 
# touch /var/log/init-scripts/run-ab.log
docker compose up -d
EOF
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