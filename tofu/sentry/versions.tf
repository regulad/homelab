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
    sentry = {
      source = "jianyuan/sentry"
      # FIXME: 0.16.0 cannot manage data scrubbing, so the organization's and the
      # projects' scrubbing settings, the IP-address scrubbing among them, are
      # unmanaged. Upstream merged support for them after this release, in
      # https://github.com/jianyuan/terraform-provider-sentry/commit/6dc306102cbed10a5534238fc0a56c835f1fea34
      # (#995). Revisit at the first release that contains it.
      # FIXME: the provider has no resource for custom integrations, so the
      # organization's internal integrations other than homelab-tofu, such as
      # Vercel's, are unmanaged. The request for one,
      # https://github.com/jianyuan/terraform-provider-sentry/issues/164, was
      # closed as not planned in a backlog cleanup on 2026-09-01. Revisit if it is
      # reopened or a release adds such a resource.
      version = "= 0.16.0"
    }
  }
}
