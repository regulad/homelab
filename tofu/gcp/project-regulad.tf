# regulad: the home project, which holds homelab-tofu and bills the APIs it calls.
locals {
  regulad_services = toset([
    # Google Analytics' Admin API, which tofu/ga4 calls as tofu-analytics and
    # the Analytics MCP server as analytics-mcp.
    "analyticsadmin.googleapis.com",
    # Google Analytics' Data API, which the Analytics MCP server reports through.
    "analyticsdata.googleapis.com",
    "apikeys.googleapis.com",
    "artifactregistry.googleapis.com",
    "autoscaling.googleapis.com",
    "bigquery.googleapis.com",
    "bigquerystorage.googleapis.com",
    "cloudapis.googleapis.com",
    "cloudasset.googleapis.com",
    "cloudbilling.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudtrace.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "containerregistry.googleapis.com",
    "datastore.googleapis.com",
    "developerknowledge.googleapis.com",
    "dns.googleapis.com",
    "domains.googleapis.com",
    "gkebackup.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "networkconnectivity.googleapis.com",
    "osconfig.googleapis.com",
    "oslogin.googleapis.com",
    "pubsub.googleapis.com",
    "recaptchaenterprise.googleapis.com",
    "run.googleapis.com",
    "servicemanagement.googleapis.com",
    "serviceusage.googleapis.com",
    "sql-component.googleapis.com",
    "storage-api.googleapis.com",
    "storage-component.googleapis.com",
    "storage.googleapis.com",
    "telemetry.googleapis.com",
    "texttospeech.googleapis.com",
  ])
}

resource "google_project" "regulad" {
  name            = "regulad"
  project_id      = "regulad"
  billing_account = "01E486-6286C6-F2B41D"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "google_project_service" "regulad" {
  for_each = local.regulad_services

  project = google_project.regulad.project_id
  service = each.value

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "google_service_account" "google_text_to_speech" {
  project      = google_project.regulad.project_id
  account_id   = "google-text-to-speech"
  display_name = "google-text-to-speech"
  description  = "For testing of google text-to-speech"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# tofu-analytics: the account tofu/ga4 works as, an Editor of the Google
# Analytics account, which only Parker can grant in Analytics' own console
# (tofu/ga4's README). It holds no Google Cloud role.
resource "google_service_account" "tofu_analytics" {
  project      = google_project.regulad.project_id
  account_id   = "tofu-analytics"
  display_name = "OpenTofu: Google Analytics (regulad/homelab)"
}

# Its key, whose private half Google never had, as homelab-tofu's: the
# certificate of the private key in tofu/ga4/provider.sops.yaml, uploaded.
resource "google_service_account_key" "tofu_analytics" {
  service_account_id = google_service_account.tofu_analytics.name
  public_key_data    = filebase64("${path.module}/service-account-tofu-analytics.crt")
}

# analytics-mcp: the account Google Analytics' MCP server works as on Parker's
# machines, set up by regulad/dotfiles. It holds no Google Cloud role; its
# access to Analytics is granted in Analytics' own console.
resource "google_service_account" "analytics_mcp" {
  project      = google_project.regulad.project_id
  account_id   = "analytics-mcp"
  display_name = "Google Analytics MCP server (regulad/dotfiles)"
}

# Its key, whose private half Google never had: the certificate of a key made
# for it, uploaded. The certificate is valid for one year, so the key expires
# with it. The key file, with the private key, is dotfiles', age-encrypted
# there; nothing here holds it.
resource "google_service_account_key" "analytics_mcp" {
  service_account_id = google_service_account.analytics_mcp.name
  public_key_data    = filebase64("${path.module}/service-account-analytics-mcp.crt")
}

resource "google_recaptcha_enterprise_key" "pterodactyl" {
  project      = google_project.regulad.project_id
  display_name = "pterodactyl.regulad.xyz"

  web_settings {
    integration_type  = "SCORE"
    allow_all_domains = false
    allowed_domains   = ["pterodactyl.regulad.xyz"]
    allow_amp_traffic = false
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# The API key of Google's Developer Knowledge MCP server, which Parker's coding
# agents send as X-Goog-Api-Key from several machines, so it has no application
# restriction: it reaches the Developer Knowledge API and nothing else. Its value
# is the developer_knowledge_api_key output, which Parker keeps in Bitwarden for
# dotfiles.
resource "google_apikeys_key" "developer_knowledge" {
  name         = "developer-knowledge-mcp"
  display_name = "Developer Knowledge MCP"
  project      = google_project.regulad.project_id

  restrictions {
    api_targets {
      service = "developerknowledge.googleapis.com"
    }
  }

  depends_on = [
    google_project_service.regulad["apikeys.googleapis.com"],
    google_project_service.regulad["developerknowledge.googleapis.com"],
  ]
}
