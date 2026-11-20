# google (Google Account)

Not an OpenTofu root: only the app passwords of the Google Account that mail relays through live
here, in `secrets.sops.yaml`, as Docker Hub's personal access tokens live in
`tofu/dockerhub/secrets.sops.yaml`. Google Cloud is `tofu/gcp`'s.

Google issues no app password through an API, so each is made by hand in the account's security
settings, under its app name there, `terraform-<name>`, and kept in `google_app_passwords`. Google
shows it once, as four groups of four letters; it is kept without the spaces. An app password has
no scope of its own, so each serves one user, and is revoked when that user no longer needs it.

| App password | Signs in |
|---|---|
| `terraform-dms` | mail's Postfix, to `smtp.gmail.com`, its last fallback relay (`ansible-generated`'s `host_vars/mail/main.yml`, `postfix-sasl-password.cf`) |

To rotate one, make a new app password under the same name, put it in `secrets.sops.yaml`, deliver
it as its user says, and then revoke the old one: for mail, `site.yml --tags host_files --limit mail`
from `ansible-generated/`.
