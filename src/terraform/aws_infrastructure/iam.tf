# iam role for ec2 instance
resource "aws_iam_role" "airbyte_poc_ec2_role" {
  name = "airbyte_poc_ec2_role"

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

# ec2 instance needs to read/write from the ssm parameter store when configuring airbyte
resource "aws_iam_policy" "airbyte_poc_ssm_policy" {
  name        = "SSMParameterStoreAirbytePolicy"
  description = "Policy to allow read and write access to SSM Parameter Store secrets with prefix /airbyte/*."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParameterHistory",
          "ssm:GetParametersByPath",
          "ssm:PutParameter",
          "ssm:DeleteParameter",
          "ssm:DeleteParameters",
          "ssm:ListTagsForResource",
        ]
        Resource = "arn:aws:ssm:*:*:parameter/airbyte/*"
      }
    ]
  })
}

# attach the ssm parameter store policy to the ec2 role
resource "aws_iam_role_policy_attachment" "airbyte_poc_ec2_ssm" {
  role       = aws_iam_role.airbyte_poc_ec2_role.name
  policy_arn = aws_iam_policy.airbyte_poc_ssm_policy.arn
}

# ec2 instance needs to read data from the s3 bucket
resource "aws_iam_role_policy_attachment" "airbyte_poc_ec2_s3_read_only" {
  role       = aws_iam_role.airbyte_poc_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# attach the role to the ec2 instance profile
resource "aws_iam_instance_profile" "airbyte_poc_ec2_instance_profile" {
  name = "airbyte_poc_ec2_instance_profile"
  role = aws_iam_role.airbyte_poc_ec2_role.name
  depends_on = [
    aws_iam_role_policy_attachment.airbyte_poc_ec2_ssm,
    aws_iam_role_policy_attachment.airbyte_poc_ec2_s3_read_only,
  ]
}

# role for airbyte server to write into s3 bucket
resource "aws_iam_user" "airbyte_poc_user" {
  name = "airbyte_poc_user"
}

# policy for airbyte user to access airbyte poc s3 bucket
resource "aws_iam_policy" "airbyte_poc_bucket_policy" {
  name        = "airbyte_poc_bucket_policy"
  description = "Policy for Airbyte POC user to access airbyte poc S3 bucket"

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
          "${aws_s3_bucket.airbyte_poc_s3_bucket.arn}",
          "${aws_s3_bucket.airbyte_poc_s3_bucket.arn}/*"
        ]
      }
    ]
  })
}

# attach the s3 destination policy to the airbyte user
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
