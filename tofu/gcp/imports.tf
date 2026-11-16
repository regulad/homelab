# Adoption only: these blocks bring the restored project doppelganger into
# state, and are removed after the adoption apply.

import {
  to = google_project.doppelganger
  id = "pure-toolbox-429813-a4"
}

import {
  for_each = local.doppelganger_services

  to = google_project_service.doppelganger[each.value]
  id = "pure-toolbox-429813-a4/${each.value}"
}

# Owner for homelab-tofu, granted by hand to bootstrap the adoption.
import {
  to = google_project_iam_member.homelab_tofu["pure-toolbox-429813-a4"]
  id = "pure-toolbox-429813-a4 roles/owner serviceAccount:homelab-tofu@regulad.iam.gserviceaccount.com"
}
