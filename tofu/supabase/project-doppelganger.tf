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
    # Sign-in with Google. Doppelganger signs in with Google's ID tokens, which
    # Supabase accepts for each client ID in this comma-separated list: the
    # doppelganger client, first, as Supabase's own redirect sign-in uses the
    # first with the secret, then doppelganger-test, for local development,
    # which signs in to this project too. The API folds
    # external_google_additional_client_ids into this list, so it is not used.
    external_google_enabled = true
    external_google_client_id = join(",", [
      local.doppelganger_google_client_ids["doppelganger"],
      local.doppelganger_google_client_ids["doppelganger-test"],
    ])
    external_google_secret = local.doppelganger_google_client_secrets["doppelganger"]
    # Auth's mail, from noreply@doppelgangerhq.com, through mail's submission
    # over implicit TLS, signed in as svc-doppelganger-supabase, whose FreeIPA
    # account wako's host_vars declare with this password.
    smtp_admin_email = "noreply@doppelgangerhq.com"
    smtp_sender_name = "Doppelganger"
    smtp_host        = "mail.regulad.xyz"
    smtp_port        = "465" # submission over implicit TLS
    smtp_user        = "svc-doppelganger-supabase@regulad.xyz"
    smtp_pass        = var.smtp_password
  })

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# The project's API keys, which the provider reads from Supabase's API.
data "supabase_apikeys" "doppelganger" {
  project_ref = supabase_project.doppelganger.id
}

# What doppelgangerhq.com's web.env takes from the project: its URL, the anon
# key, which ships to the browser, and the service role key. The provider does
# not expose the JWT secret, which stays in doppelgangerhq.com's SOPS file.
output "doppelganger" {
  value = {
    url              = "https://${supabase_project.doppelganger.id}.supabase.co"
    anon_key         = data.supabase_apikeys.doppelganger.anon_key
    service_role_key = data.supabase_apikeys.doppelganger.service_role_key
  }
  sensitive = true
}
