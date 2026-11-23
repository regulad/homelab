# tflint-ignore-file: terraform_required_version
# OpenTofu's own version constraint. Since 1.12, OpenTofu reads required_version
# in a .tf file as its predecessor's and ignores it; it enforces this block.
language {
  compatible_with {
    opentofu = "~> 1.13.1"
  }
}

terraform {
  required_providers {
    authentik = {
      source = "goauthentik/authentik"
      # The provider's releases follow authentik's, each tested against the
      # authentik release of the same year and month: move it with the server's
      # tag in ansible-generated/files/authentik.regulad.internal/opt/authentik/docker-compose.yml.
      # FIXME(#9): this release's authentik_source_ldap has no peer_certificate or
      # client_certificate, and its update leaves both as they are, so the
      # freeipa source's check of its server against ipa-ca.crt is unmanaged
      # (source-freeipa.tf). Revisit at the next provider release.
      # FIXME(#9): this release's authentik_system_settings has no base_url or
      # impersonation_require_reason, and its update leaves both as they are, so
      # the base URL, https://authentik.regulad.xyz, and the required reason for
      # impersonation are unmanaged (system-settings.tf). Revisit at the next
      # provider release.
      version = "= 2026.8.2"
    }
  }
}
