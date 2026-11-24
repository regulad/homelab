# github-personal (GitHub, regulad's account)

Not yet an OpenTofu root: only the personal access tokens of the GitHub account `regulad`
live here, in `secrets.sops.yaml`, as Docker Hub's live in
`tofu/dockerhub/secrets.sops.yaml`. It is to declare the account's own settings, such as
its SSH and signing keys, with a token of its own.

GitHub has no API that issues a personal access token, and no App-issued token can fill a
repository's secret, as those last an hour. So each token is issued by hand in regulad's
settings, under its name there, `terraform-<word>--<word>`, with the narrowest access that
serves it, and kept in `github_pats`; the comment above each gives its type, its
repository access and its permissions.

Their users read them from here, their only copy:

- `tofu/github`, for repositories' Actions and Dependabot secrets, through its
  `prepare.sh`;
- `tofu/vercel`, for projects' environment variables, through its `prepare.sh`;
- `ansible-generated`, for ghcr.io logins: Nexus's `ghcr-io` proxy
  (`group_vars/nexus_servers.yml`), and the `registry_auth` logins of mail, pihole2 and
  doppelgangerhq.com (their `host_vars`).

To rotate one, issue a new token under the same name, put it in `secrets.sops.yaml` with
`sops edit`, and deliver it as its users say: an apply of `tofu/github` or `tofu/vercel`;
for Nexus, `maintenance.yml --tags nexus-proxy-logins` from `ansible-generated/`, since
Nexus never returns a stored password; for a host,
`site.yml --tags registry_auth --limit <host>`. Then delete the old token in GitHub.
