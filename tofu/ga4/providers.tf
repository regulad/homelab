# OpenTofu works as tofu-analytics, tofu/gcp's service account, an Editor of
# the Google Analytics account. Google holds only the public half of its key,
# so the key file Google would hand out is assembled here: the address and the
# key's ID from tofu/gcp's tofu_analytics output (gcp.tf), the private key from
# provider.sops.yaml (variables.tf). Google's auth library reads no project_id
# to sign a service account's token request, so none is written.
provider "ga4" {
  credentials = jsonencode({
    type           = "service_account"
    client_email   = data.terraform_remote_state.gcp.outputs.tofu_analytics.email
    private_key_id = data.terraform_remote_state.gcp.outputs.tofu_analytics.key_id
    private_key    = var.private_key
    token_uri      = "https://oauth2.googleapis.com/token"
  })
}
