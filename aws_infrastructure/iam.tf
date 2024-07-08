# IAM role for EC2 instance to read from SSM Parameter Store
resource "aws_iam_role" "airbyte_poc_ec2_ssm_role" {
  name = "airbyte_poc_ec2_ssm_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "airbyte_poc_ec2_ssm_read_only" {
  role       = aws_iam_role.airbyte_poc_ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "airbyte_poc_ec2_s3_read_only" {
  role       = aws_iam_role.airbyte_poc_ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_instance_profile" "airbyte_poc_ec2_instance_profile" {
  name = "airbyte_poc_ec2_instance_profile"
  role = aws_iam_role.airbyte_poc_ec2_ssm_role.name
  depends_on = [
    aws_iam_role_policy_attachment.airbyte_poc_ec2_ssm_read_only,
    aws_iam_role_policy_attachment.airbyte_poc_ec2_s3_read_only,
    ]
}


# role for airbyte server to use when connecting to aws account and read/write to s3 as a destination
resource "aws_iam_user" "airbyte_poc_user" {
  name = "airbyte_poc_user"
}

resource "aws_iam_policy" "airbyte_poc_bucket_policy" {
  name        = "airbyte_poc_bucket_policy"
  description = "Policy for Airbyte POC user to access airbyte-poc S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:PutObjectAcl",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation"
        ],
        Effect = "Allow",
        Resource = [
          "${aws_s3_bucket.airbyte_poc.arn}",
          "${aws_s3_bucket.airbyte_poc.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "airbyte_poc_user_policy_attachment" {
  user       = aws_iam_user.airbyte_poc_user.name
  policy_arn = aws_iam_policy.airbyte_poc_bucket_policy.arn
}

# create access key for airbyte user and save it in SSM Parameter Store
resource "aws_iam_access_key" "airbyte_poc_user_key" {
  user = aws_iam_user.airbyte_poc_user.name
}

resource "aws_ssm_parameter" "airbyte_poc_user_access_key_id" {
  name  = "/airbyte/poc/user_access_key_id"
  type  = "String"
  value = aws_iam_access_key.airbyte_poc_user_key.id
}

resource "aws_ssm_parameter" "airbyte_poc_user_secret_access_key" {
  name  = "/airbyte/poc/user_secret_access_key"
  type  = "SecureString"
  value = aws_iam_access_key.airbyte_poc_user_key.secret
}
