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
    # Sign-in with Google; its client secret is the API's to keep, as the
    # provider never reads it back.
    external_google_enabled   = true
    external_google_client_id = "6822405828-jcheqartcigc09111gq22tb6oqnvsrpa.apps.googleusercontent.com"
  })

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
