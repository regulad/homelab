# The adoption's import blocks, removed after the adoption apply: release's
# deployment policies, made by hand.

import {
  to = github_repository_environment_deployment_policy.repository_1463115679["release/branch/master"]
  id = "Warlock:release:67307515"
}

import {
  to = github_repository_environment_deployment_policy.repository_1463115679["release/tag/v*"]
  id = "Warlock:release:67307516"
}
