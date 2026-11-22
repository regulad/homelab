# System settings: authentik's defaults, which the provider's defaults match,
# except for the flags. Its update leaves the settings the provider cannot
# express, base_url and impersonation_require_reason, as they are
# (versions.tf), and so does authentik with its system flags, such as setup,
# which its API neither returns nor lets a client change.
resource "authentik_system_settings" "settings" {
  # authentik's own defaults, which the tenant stores none of. The provider's
  # default turns core_default_app_access off.
  flags = jsonencode({
    # An application with no policy bound can be accessed by every user.
    core_default_app_access                = true
    enterprise_audit_include_expanded_diff = false
    flows_continuous_login                 = false
    flows_refresh_others                   = false
  })

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
