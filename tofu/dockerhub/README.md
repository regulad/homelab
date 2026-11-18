# dockerhub (Docker Hub)

Not yet an OpenTofu root: only the personal access tokens of the Docker Hub account `regulad`
live here, in `secrets.sops.yaml`, as GitHub's live in `tofu/github/secrets.sops.yaml`.

Docker Hub issues no personal access token through its API to an account with two-factor
authentication: a token can manage repositories but not other tokens, and the provider's
password sign-in cannot answer a second factor. So each token is issued by hand in Docker Hub's
settings, under its name there, `terraform-<word>--<word>`, with the narrowest access permissions
that serve it, and kept in `dockerhub_pats`.

| Token | Access | Used by |
|---|---|---|
| `terraform-nexus--dockerhub` | Public Repo Read-only | The upstream login of Nexus's `docker-io` proxy (`ansible-generated`'s `group_vars/nexus_servers.yml`, `nexus_repositories` role) |

To rotate one, issue a new token under the same name, put it in `secrets.sops.yaml`, and deliver
it as its user says: for Nexus, `maintenance.yml --tags nexus-proxy-logins` from
`ansible-generated/`, since Nexus never returns a stored password.
