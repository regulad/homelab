# OpenTofu authenticates with a Vercel access token for the regulad team, from
# provider.sops.env (VERCEL_API_TOKEN), which sourcing prepare.sh exports.
provider "vercel" {
  # regulad (slug regulad0), the account's one team, which every resource here
  # belongs to.
  team = "team_JrB4YMLbrdINYpJ5RdhGyK3d"
}
