locals {
  # Keyed by each name's trailing AD number: ad_1, ad_2, ad_3. The names carry
  # the tenancy-specific prefix, so plans keep them redacted.
  availability_domains = sensitive({
    for ad in data.oci_identity_availability_domains.tenancy.availability_domains :
    "ad_${regex("-AD-(\\d+)$", ad.name)[0]}" => ad.name
  })
}

# Availability-domain names carry a tenancy-specific prefix, so they are looked up.
data "oci_identity_availability_domains" "tenancy" {
  compartment_id = var.tenancy_ocid
}

module "shared" {
  source = "../shared"
}
