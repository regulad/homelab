# rolesanywhere: how OpenTofu signs in, through IAM Roles Anywhere as the role
# homelab-tofu (see README.md). Created by hand to bootstrap this root.
resource "aws_rolesanywhere_trust_anchor" "homelab_tofu" {
  name    = "homelab-tofu"
  enabled = true

  source {
    source_type = "CERTIFICATE_BUNDLE"

    source_data {
      x509_certificate_data = file("${path.module}/rolesanywhere-ca.crt")
    }
  }

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_role" "homelab_tofu" {
  name = "homelab-tofu"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "rolesanywhere.amazonaws.com" }
        Action    = ["sts:AssumeRole", "sts:TagSession", "sts:SetSourceIdentity"]
        Condition = {
          ArnEquals = { "aws:SourceArn" = aws_rolesanywhere_trust_anchor.homelab_tofu.arn }
        }
      },
    ]
  })

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}

# This root manages IAM itself, so a narrower grant would contain nothing.
resource "aws_iam_role_policy_attachment" "homelab_tofu" {
  role       = aws_iam_role.homelab_tofu.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_rolesanywhere_profile" "homelab_tofu" {
  name      = "homelab-tofu"
  enabled   = true
  role_arns = [aws_iam_role.homelab_tofu.arn]

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
