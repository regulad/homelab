# regulad: the Google Analytics account that holds every property. Analytics
# creates accounts only in its console, so the provider adopts this one.
resource "ga4_account" "regulad" {
  display_name = "regulad"
  region_code  = "US"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
