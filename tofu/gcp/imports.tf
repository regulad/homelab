# The Firebase side of home-assistant-311214, adopted: to be removed after the
# adoption apply.
import {
  provider = google-beta.home_assistant
  to       = google_firebase_project.home_assistant
  id       = "projects/home-assistant-311214"
}

import {
  provider = google-beta.home_assistant
  to       = google_firebase_hosting_site.home_assistant
  id       = "projects/home-assistant-311214/sites/home-assistant-311214"
}

import {
  to = google_apikeys_key.home_assistant_firebase_browser
  id = "projects/home-assistant-311214/locations/global/keys/eca7b856-eef1-4f72-b61c-283fb2739550"
}
