# Adoption of the resources created by hand. Removed after the adoption apply.
# IDs that name the account come from data sources, never literals.
data "aws_caller_identity" "current" {}

data "aws_iam_access_keys" "home_assistant" {
  user = "HomeAssistant"
}

data "aws_iam_access_keys" "ask_cli" {
  user = "ASK-CLI"
}

import {
  to = aws_iam_user.home_assistant
  id = "HomeAssistant"
}

import {
  for_each = local.home_assistant_policy_arns

  to = aws_iam_user_policy_attachment.home_assistant[each.key]
  id = "HomeAssistant/${each.value}"
}

import {
  to = aws_iam_access_key.home_assistant
  id = one(data.aws_iam_access_keys.home_assistant.access_keys).access_key_id
}

import {
  to = aws_iam_user.ask_cli
  id = "ASK-CLI"
}

import {
  to = aws_iam_group.ask_cli
  id = "ASK-CLI"
}

import {
  to = aws_iam_user_group_membership.ask_cli
  id = "ASK-CLI/ASK-CLI"
}

import {
  to = aws_iam_policy.ask_cli
  id = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/ASK-CLI"
}

import {
  to = aws_iam_group_policy_attachment.ask_cli
  id = "ASK-CLI/arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/ASK-CLI"
}

import {
  to = aws_iam_access_key.ask_cli
  id = one(data.aws_iam_access_keys.ask_cli.access_keys).access_key_id
}

import {
  to = aws_iam_role.home_assistant
  id = "AWSLambdaBasicExecutionRole-SmartHome"
}

import {
  to = aws_iam_role_policy_attachment.home_assistant
  id = "AWSLambdaBasicExecutionRole-SmartHome/arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

import {
  to = aws_rolesanywhere_trust_anchor.homelab_tofu
  id = "234c136e-ec69-4684-8c27-f4f08c574a99"
}

import {
  to = aws_iam_role.homelab_tofu
  id = "homelab-tofu"
}

import {
  to = aws_iam_role_policy_attachment.homelab_tofu
  id = "homelab-tofu/arn:aws:iam::aws:policy/AdministratorAccess"
}

import {
  to = aws_rolesanywhere_profile.homelab_tofu
  id = "4f7737bc-bbc5-4849-90c0-d866e48a2951"
}
