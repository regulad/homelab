# discord (Discord applications)

Not an OpenTofu root. Discord's public API cannot manage an application's lifecycle or its
credentials, so the Discord applications the homelab's services use are made and kept by hand in
the [Developer Portal](https://discord.com/developers/applications), as Google's app passwords are
(`tofu/google`) and Docker Hub's tokens (`tofu/dockerhub`).

## What the API cannot do

Discord documents no endpoint, checked against its developer docs on 2026-11-26, to:

- create or delete an application;
- reset a bot token, or read or reset an application's OAuth2 client secret;
- add or remove OAuth2 redirect URIs;
- turn the privileged gateway intents (presence, server members, message content) on or off;
- move an application to a team, or manage a team's members.

The Portal does all of these through Discord's internal API, signed in as a user. Calling that API
with a user account's token is automating a user account, which Discord's terms forbid, so no
script or provider here does it.

## What it can do

The application API ([Application](https://docs.discord.com/developers/resources/application))
authenticates as the application's own bot, with its bot token:

- `GET /applications/@me` reads the application.
- `PATCH /applications/@me` edits its description, icon, cover image, tags, install settings
  (`custom_install_url`, `install_params`, `integration_types_config`), interactions endpoint URL,
  role-connections verification URL, event webhooks, and only the limited intent `flags`.
- Application commands, role-connection metadata, application emojis, and reading SKUs and
  entitlements are under `/applications/{application.id}/`.

So a credential is always issued in the Portal first. The community OpenTofu providers for Discord
(kirchdev/discord, shadow-templars/discord, alpaca744/discord and others) all start from a bot token
and manage what that bot can reach, such as guilds, channels and application commands. None of
them creates an application or issues its credentials.

## Credentials

Each bot token or client secret is copied from the Portal into the SOPS file of the host or root
that uses it. To rotate one, reset it in the Portal, put the new value in that SOPS file, and
deliver it to its service.

## PepperCord's applications

PepperCord (`839264035756310589`) and its mirror CordPepperer (`890394048228122715`) both run
regulad/PepperCord (`ansible-generated/inventory/group_vars/peppercord.yml`), each with its bot
token in its host's `secrets.sops.yml` (`peppercord_token`). Both are public, and both set their
Terms of Service and Privacy Policy URLs, in the Portal, to the repository's own files:

- `https://github.com/regulad/PepperCord/blob/main/TOS.md`
- `https://github.com/regulad/PepperCord/blob/main/PRIVACY.md`

The Portal accepts a policy URL only while its page loads: a page that doesn't exist yet is
refused with "The Terms of Service URL provided is not allowed", whatever its domain. Publish a
policy before setting its URL.
