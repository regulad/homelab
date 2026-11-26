locals {
  # Every project's OAuth clients, by project ID, then by slug. Each project
  # file declares its own; a project with none is left out.
  oauth_clients = {
    (google_project.doppelganger.project_id) = {
      number  = google_project.doppelganger.number
      clients = local.doppelganger_oauth_clients
    }
    (google_project.regulad_rclone.project_id) = {
      number  = google_project.regulad_rclone.number
      clients = local.regulad_rclone_oauth_clients
    }
  }
}

# The OAuth client IDs of every project, by project ID, then by slug: the one
# source for the roots and hosts that name a client, such as tofu/supabase.
# A client ID is public, as browsers send it at sign-in.
output "oauth_client_ids" {
  value = { for project, p in local.oauth_clients : project => p.clients }

  # A Google client ID begins with its project's number, so a client declared
  # in the wrong project fails here.
  precondition {
    condition = alltrue(flatten([
      for p in values(local.oauth_clients) : [
        for id in values(p.clients) : startswith(id, "${p.number}-")
      ]
    ]))
    error_message = "Every OAuth client ID must begin with its project's number."
  }
}

# tofu-analytics's address and the ID Google gave its uploaded key, which
# tofu/ga4 builds its credentials from, with the private key it holds.
output "tofu_analytics" {
  value = {
    email  = google_service_account.tofu_analytics.email
    key_id = element(split("/", google_service_account_key.tofu_analytics.name), 5)
  }
}

# The Developer Knowledge MCP server's API key, which Parker copies into the
# Bitwarden item dotfiles reads: never printed here.
output "developer_knowledge_api_key" {
  value     = google_apikeys_key.developer_knowledge.key_string
  sensitive = true
}
