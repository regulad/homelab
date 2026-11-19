# doppelganger: the project behind Doppelganger, and its settings.
locals {
  # Its sign-in with Google's clients, in tofu/gcp's project
  # pure-toolbox-429813-a4, by slug: their IDs from tofu/gcp's outputs, and
  # their secrets from its oauth-clients.sops.json, through prepare.sh.
  doppelganger_google_client_ids     = data.terraform_remote_state.gcp.outputs.oauth_client_ids["pure-toolbox-429813-a4"]
  doppelganger_google_client_secrets = var.google_oauth_client_secrets["pure-toolbox-429813-a4"]
}

resource "supabase_project" "doppelganger" {
  name              = "doppelganger"
  organization_id   = "vjpmxgwlilbffofvqunj" # regulad
  region            = "us-east-1"
  database_password = var.database_password

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# Each setting group declares only the keys that differ from a new project's
# defaults; the provider reads back only the declared keys.
resource "supabase_settings" "doppelganger" {
  project_ref = supabase_project.doppelganger.id

  auth = jsonencode({
    site_url       = "https://doppelgangerhq.com"
    uri_allow_list = "https://doppelgangerhq.com"
    # Sign-in with Google, through the doppelganger client. Doppelganger signs
    # in with Google's ID tokens, which Supabase accepts for each client ID
    # here; the secret serves only Supabase's own redirect sign-in. Local
    # development signs in to this project too, through doppelganger-test.
    external_google_enabled               = true
    external_google_client_id             = local.doppelganger_google_client_ids["doppelganger"]
    external_google_secret                = local.doppelganger_google_client_secrets["doppelganger"]
    external_google_additional_client_ids = local.doppelganger_google_client_ids["doppelganger-test"]
  })

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
