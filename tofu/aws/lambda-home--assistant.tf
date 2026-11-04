# home-assistant: the Lambda behind Home Assistant's Alexa Smart Home skill, as
# Home Assistant's Alexa Smart Home instructions set it up: it forwards each
# directive from Alexa to Home Assistant, which answers it.
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

resource "aws_cloudwatch_log_group" "home_assistant" {
  name = "/aws/lambda/home-assistant"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# lambda/home-assistant/lambda_function.py is Home Assistant's published Lambda
# (Apache-2.0), byte for byte as deployed on 2026-01-05. It is zipped here; the
# fixed file mode keeps the zip, and so its hash, the same on every machine.
data "archive_file" "home_assistant" {
  type             = "zip"
  source_file      = "${path.module}/lambda/home-assistant/lambda_function.py"
  output_path      = "${path.module}/.terraform/archives/home-assistant.zip"
  output_file_mode = "0644"
}

resource "aws_lambda_function" "home_assistant" {
  function_name    = "home-assistant"
  role             = aws_iam_role.home_assistant.arn
  runtime          = "python3.14"
  architectures    = ["arm64"]
  handler          = "lambda_function.lambda_handler"
  filename         = data.archive_file.home_assistant.output_path
  source_code_hash = data.archive_file.home_assistant.output_base64sha256

  environment {
    variables = {
      BASE_URL = var.home_assistant_base_url
    }
  }

  logging_config {
    log_format = "Text"
    log_group  = aws_cloudwatch_log_group.home_assistant.name
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# Only the skill's own directives may invoke it.
resource "aws_lambda_permission" "home_assistant" {
  statement_id       = "lambda-da65f78a-7759-47f1-9f61-7686f28fef1f"
  function_name      = aws_lambda_function.home_assistant.function_name
  action             = "lambda:InvokeFunction"
  principal          = "alexa-connectedhome.amazon.com"
  event_source_token = "amzn1.ask.skill.9ea3f2e2-8a2a-4d9e-a58a-c9d89c14edae" # The Home Assistant Smart Home skill
}
