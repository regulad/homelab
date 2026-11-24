# x081BE541EA23ACF3: regulad's GPG key, by its key ID, which signs patches, and
# commits under a git too old for SSH signing. files/gpg-key-x081BE541EA23ACF3.asc
# holds its armored public key as GitHub holds it; the key is compared ignoring
# line endings, which GitHub keeps as uploaded.
resource "github_user_gpg_key" "x081BE541EA23ACF3" {
  armored_public_key = file("${path.module}/files/gpg-key-x081BE541EA23ACF3.asc")

  lifecycle {
    enabled = local.personal
  }
}
