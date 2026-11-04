# home-assistant: the Lambda behind Home Assistant's Alexa Smart Home skill, as
# Home Assistant's Alexa Smart Home instructions set it up. So far only its
# execution role; the function itself is not yet adopted.
resource "aws_iam_role" "home_assistant" {
  name        = "AWSLambdaBasicExecutionRole-SmartHome"
  description = "Allows Lambda functions to call AWS services on your behalf."
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
        Action    = "sts:AssumeRole"
      },
    ]
  })

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "home_assistant" {
  role       = aws_iam_role.home_assistant.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
