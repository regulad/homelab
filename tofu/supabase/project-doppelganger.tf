# doppelganger: the project behind Doppelganger, and its settings.
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
    # Sign-in with Google, through tofu/gcp's "Doppelganger Production" client;
    # its client secret is the API's to keep, as the provider never reads it back.
    external_google_enabled   = true
    external_google_client_id = data.terraform_remote_state.gcp.outputs.oauth_client_ids["pure-toolbox-429813-a4"]["doppelganger-production"]
  })

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
