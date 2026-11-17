# homelab-provider-test: the app terraform-provider-onesignal's live tests run
# in (`make testlive`). They create API keys and templates in it and destroy
# them again, so it holds nothing of its own; its web push origin is a
# placeholder. OneSignal cannot delete apps through its API, so the tests never
# create one, and need this one to exist.
resource "onesignal_app" "homelab_provider_test" {
  name              = "homelab-provider-test"
  organization_id   = local.organization_id
  chrome_web_origin = "https://example.com"

  # The following exists as an artifact of import from the imperative setup.
  lifecycle {
    prevent_destroy = true
  }
}
