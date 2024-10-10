# query the ec2 instance to ensure airbyte server api is reachable (no authentication so we can see the command stdout)
resource "null_resource" "wait_for_instance" {
  provisioner "local-exec" {
    command = <<EOT
    echo "Waiting for Airbyte api to start. Timeout set for 5 minutes..."
    for i in $(seq 1 30); do
      response=$(curl -s -w "\n%%{http_code}" http://${aws_instance.ec2_instance.public_ip}:8001/api/public/v1/workspaces)
      http_code=$(echo "$response" | tail -c 4)
      if [ "$http_code" == "401" ]; then
        echo "Instance is running!"
        break
      else
        echo "Waiting for Airbyte api to start..."
        sleep 10
      fi
    done
    "Instance did not start in time. Exiting..."
    exit 1
    EOT
  }
  depends_on = [aws_instance.ec2_instance]
  triggers = {
    instance_public_ip = aws_instance.ec2_instance.public_ip
  }
}

# retrieve the airbyte server password from ssm parameter store
data "aws_ssm_parameter" "airbyte_server_admin_password" {
  name = "/airbyte/poc/server_admin_password"
}

# query the airbyte server for the default workspace id
data "http" "airbyte_api_workspace" {
  url = "http://${aws_instance.ec2_instance.public_ip}:8001/api/public/v1/workspaces"
  request_headers = {
    Authorization = "Basic ${base64encode("admin:${data.aws_ssm_parameter.airbyte_server_admin_password.value}")}"
  }
  depends_on = [ null_resource.wait_for_instance ]
}

# generate ouputs
output "airbyte_poc_workspace_id" {
  value = jsondecode(data.http.airbyte_api_workspace.response_body).data[0].workspaceId
}

output "airbyte_poc_ec2_instance_ip" {
  value = aws_instance.ec2_instance.public_ip
}

output "airbyte_poc_s3_bucket" {
  value = aws_s3_bucket.airbyte_poc_s3_bucket.arn
}