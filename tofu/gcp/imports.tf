# Adoption of the resources created by hand. Removed after the adoption apply.
import {
  to = google_project.regulad
  id = "regulad"
}

import {
  to = google_project.home_assistant
  id = "home-assistant-311214"
}

import {
  to = google_project.regulad_rclone
  id = "regulad-rclone"
}

import {
  to = google_project.matrix_synapse
  id = "matrix-synapse-1733678924090"
}

import {
  for_each = local.regulad_services

  to = google_project_service.regulad[each.value]
  id = "regulad/${each.value}"
}

import {
  for_each = local.home_assistant_services

  to = google_project_service.home_assistant[each.value]
  id = "home-assistant-311214/${each.value}"
}

import {
  for_each = local.regulad_rclone_services

  to = google_project_service.regulad_rclone[each.value]
  id = "regulad-rclone/${each.value}"
}

import {
  for_each = local.matrix_synapse_services

  to = google_project_service.matrix_synapse[each.value]
  id = "matrix-synapse-1733678924090/${each.value}"
}

import {
  to = google_service_account.homelab_tofu
  id = "projects/regulad/serviceAccounts/homelab-tofu@regulad.iam.gserviceaccount.com"
}

import {
  to = google_service_account.google_text_to_speech
  id = "projects/regulad/serviceAccounts/google-text-to-speech@regulad.iam.gserviceaccount.com"
}

import {
  to = google_service_account.home_assistant
  id = "projects/home-assistant-311214/serviceAccounts/home-assistant@home-assistant-311214.iam.gserviceaccount.com"
}

import {
  to = google_service_account.rclone
  id = "projects/regulad-rclone/serviceAccounts/rclone@regulad-rclone.iam.gserviceaccount.com"
}

import {
  to = google_recaptcha_enterprise_key.pterodactyl
  id = "projects/regulad/keys/6LeCxXQtAAAAAH_RDp0rZQ7a0rI9ETLF-jiK3RyI"
}

import {
  to = google_recaptcha_enterprise_key.matrix
  id = "projects/matrix-synapse-1733678924090/keys/6LehOsAqAAAAADzG1dvWHy_0EpnjeBHmO0bISzTG"
}

import {
  for_each = toset(["regulad", "home-assistant-311214", "regulad-rclone", "matrix-synapse-1733678924090"])

  to = google_project_iam_member.homelab_tofu[each.value]
  id = "${each.value} roles/owner serviceAccount:homelab-tofu@regulad.iam.gserviceaccount.com"
}
