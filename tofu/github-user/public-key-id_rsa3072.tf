# id_rsa3072: regulad's SSH authentication key, tofu/shared's
# regulad_ssh_public_key, which is also his commit-signing key. The title is
# the one GitHub holds, as a new title replaces the key.
resource "github_user_ssh_key" "id_rsa3072" {
  title = "regulad@stalactite"
  key   = module.shared.regulad_ssh_public_key

  lifecycle {
    enabled = local.personal
  }
}
