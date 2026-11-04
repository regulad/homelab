# ASK-CLI: the IAM user, group and policy the Alexa Skills Kit CLI deploys
# skills as, named as Amazon's ASK CLI setup instructions name them.
resource "aws_iam_user" "ask_cli" {
  name = "ASK-CLI"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_group" "ask_cli" {
  name = "ASK-CLI"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_user_group_membership" "ask_cli" {
  user   = aws_iam_user.ask_cli.name
  groups = [aws_iam_group.ask_cli.name]
}

resource "aws_iam_policy" "ask_cli" {
  name        = "ASK-CLI"
  description = "Allows the permissions that ASK CLI needs."
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudformation:CreateStack",
          "cloudformation:UpdateStack",
          "cloudformation:DescribeStacks",
          "cloudformation:DescribeStackResource",
          "cloudformation:DescribeStackResources",
          "cloudformation:DeleteStack",
          "iam:CreateRole",
          "iam:GetRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PassRole",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:DeleteRole",
          "lambda:AddPermission",
          "lambda:CreateFunction",
          "lambda:GetFunction",
          "lambda:UpdateFunctionCode",
          "lambda:UpdateFunctionConfiguration",
          "lambda:ListFunctions",
          "lambda:DeleteFunction",
          "lambda:RemovePermission",
          "logs:FilterLogEvents",
          "logs:getLogEvents",
          "logs:describeLogStreams",
          "logs:CreateLogGroup",
          "logs:PutRetentionPolicy",
          "s3:CreateBucket",
          "s3:ListBucket",
          "s3:GetBucketVersioning",
          "s3:PutBucketVersioning",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["iam:PassRole"]
        Resource = "*"
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "lambda.amazonaws.com"
          }
        }
      },
    ]
  })

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_group_policy_attachment" "ask_cli" {
  group      = aws_iam_group.ask_cli.name
  policy_arn = aws_iam_policy.ask_cli.arn
}

# Its secret lives only in the ASK CLI's credentials; state holds the key's ID
# and status.
resource "aws_iam_access_key" "ask_cli" {
  user = aws_iam_user.ask_cli.name

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
