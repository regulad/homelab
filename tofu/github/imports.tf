# Adoption of the secrets the repositories already hold; removed after the apply.
# GitHub never returns a value, so each imported secret then takes this
# repository's value in the same apply.

import {
  for_each = toset(keys(local.repository_1362143050_environment_secrets))
  to       = github_actions_environment_secret.repository_1362143050[each.key]
  id       = "${local.repository_1362143050}:nexus-ios:${each.key}"
}

import {
  for_each = toset(keys(local.repository_1366410818_actions_secrets))
  to       = github_actions_secret.repository_1366410818[each.key]
  id       = "${local.repository_1366410818}:${each.key}"
}

import {
  for_each = toset(keys(local.repository_876478767_actions_secrets))
  to       = github_actions_secret.repository_876478767[each.key]
  id       = "${local.repository_876478767}:${each.key}"
}

import {
  for_each = toset(keys(local.repository_823433320_actions_secrets))
  to       = github_actions_secret.repository_823433320[each.key]
  id       = "${local.repository_823433320}:${each.key}"
}

import {
  for_each = toset(keys(local.repository_823433320_dependabot_secrets))
  to       = github_dependabot_secret.repository_823433320[each.key]
  id       = "${local.repository_823433320}:${each.key}"
}

import {
  for_each = toset(keys(local.repository_1386017153_actions_secrets))
  to       = github_actions_secret.repository_1386017153[each.key]
  id       = "${local.repository_1386017153}:${each.key}"
}

import {
  for_each = toset(keys(local.repository_1417443341_actions_secrets))
  to       = github_actions_secret.repository_1417443341[each.key]
  id       = "${local.repository_1417443341}:${each.key}"
}

import {
  for_each = toset(keys(local.repository_364397477_actions_secrets))
  to       = github_actions_secret.repository_364397477[each.key]
  id       = "${local.repository_364397477}:${each.key}"
}

import {
  to = github_dependabot_secret.repository_364397477
  id = "${local.repository_364397477}:DEPENDABOT_MERGE_TOKEN"
}

import {
  for_each = toset(keys(local.repository_832239288_actions_secrets))
  to       = github_actions_secret.repository_832239288[each.key]
  id       = "${local.repository_832239288}:${each.key}"
}

import {
  for_each = toset(keys(local.repository_1449818851_actions_secrets))
  to       = github_actions_secret.repository_1449818851[each.key]
  id       = "${local.repository_1449818851}:${each.key}"
}

import {
  for_each = toset(keys(local.repository_861072224_actions_secrets))
  to       = github_actions_secret.repository_861072224[each.key]
  id       = "${local.repository_861072224}:${each.key}"
}
