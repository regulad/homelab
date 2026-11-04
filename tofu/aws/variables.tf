# Temporary credentials from IAM Roles Anywhere, which sourcing prepare.sh
# obtains with the role's certificate and exports as TF_VAR_aws_*. Ephemeral,
# so neither state nor saved plans keep them; an apply reads them again.
variable "aws_access_key_id" {
  type      = string
  sensitive = true
  ephemeral = true
  nullable  = false
}

variable "aws_secret_access_key" {
  type      = string
  sensitive = true
  ephemeral = true
  nullable  = false
}

variable "aws_session_token" {
  type      = string
  sensitive = true
  ephemeral = true
  nullable  = false
}
