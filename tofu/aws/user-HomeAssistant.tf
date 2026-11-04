# HomeAssistant: the IAM user Home Assistant's AWS integrations sign in as.
locals {
  home_assistant_policy_arns = {
    IAMReadOnlyAccess    = "arn:aws:iam::aws:policy/IAMReadOnlyAccess"
    AmazonSNSFullAccess  = "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
    AmazonSQSFullAccess  = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
    AWSLambda_FullAccess = "arn:aws:iam::aws:policy/AWSLambda_FullAccess"
  }
}

resource "aws_iam_user" "home_assistant" {
  name = "HomeAssistant"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_user_policy_attachment" "home_assistant" {
  for_each = local.home_assistant_policy_arns

  user       = aws_iam_user.home_assistant.name
  policy_arn = each.value
}

# Its secret lives only in Home Assistant; state holds the key's ID and status.
resource "aws_iam_access_key" "home_assistant" {
  user = aws_iam_user.home_assistant.name

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
