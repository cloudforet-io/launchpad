data "local_file" "pgp_key" {
  filename = "${path.module}/gpg/public-key-binary.gpg"
}

data "aws_caller_identity" "current" {}

resource "aws_iam_user" "this" {
  name = "spaceone.secret-service"
  path = "/"
}

resource "aws_iam_access_key" "user_access_key" {
  user = aws_iam_user.this.name
  pgp_key = data.local_file.pgp_key.content_base64
}

resource "aws_iam_policy" "this" {
  name        = "spaceone.secret-service"
  description = "A policy for spaceone secret services"
  policy      =  <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Effect": "Allow",
          "Action": [
              "secretsmanager:*"
          ],
          "Resource": [
              "arn:aws:secretsmanager:ap-northeast-2:${data.aws_caller_identity.current.account_id}:secret:*"
          ]
      }
  ]
}
EOF
}

resource "aws_iam_user_policy_attachment" "this" {
  user       = aws_iam_user.this.name
  policy_arn = aws_iam_policy.this.arn
}

resource "local_file" "get_encrypted_secret_key" {
 content  =  aws_iam_access_key.user_access_key.encrypted_secret
 filename = "${path.module}/gpg/secret-key"
}