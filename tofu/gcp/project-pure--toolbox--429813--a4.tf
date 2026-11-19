# pure-toolbox-429813-a4: doppelganger, home of the OAuth clients behind the
# Supabase project doppelganger's sign-in with Google, which no resource
# manages (README.md). It has no billing account.
locals {
  doppelganger_services = toset([
    "telemetry.googleapis.com",
  ])

  # The project's OAuth clients, made in the console (README.md), by slug:
  # each client's ID, from the file Google gave for it in
  # oauth-clients.sops.json, where SOPS encrypts only the secret.
  # doppelganger: doppelgangerhq.com; doppelganger-test: local development,
  # on localhost.
  doppelganger_oauth_clients = {
    for slug, client in jsondecode(file("${path.module}/oauth-clients.sops.json"))[google_project.doppelganger.project_id] :
    slug => client.web.client_id
  }
}

resource "google_project" "doppelganger" {
  name       = "doppelganger"
  project_id = "pure-toolbox-429813-a4"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "google_project_service" "doppelganger" {
  for_each = local.doppelganger_services

  project = google_project.doppelganger.project_id
  service = each.value

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
