# nextcloud

Converges a Nextcloud that runs in a container, the stock image's, through
`occ` in that container (`podman exec --user www-data`), as `maintenance.yml`'s
plays and `nextcloud-cron` run it. The stack itself, its compose file and its
units, are the host's host files.

## What the role does

- **Writes `config.php` whole**, from `files/<host>/<config volume's
  path>/config.php.j2`, into the `nextcloud_config` volume. The template
  keeps the form Nextcloud writes the file in, PHP's `var_export` with its
  trailing spaces, so a file Nextcloud rewrites with the same values stays the
  same and a run changes nothing. `version` and `maintenance` are Nextcloud's
  own, written by its upgrades and maintenance mode, so each run reads them
  from the live configuration. The file holds Nextcloud's secrets, from SOPS,
  so its writes show no diff; the template's history is the record.
- **Keeps the config directory to `config.php`**, Nextcloud's `.htaccess` and
  the image's `config.sample.php` (`nextcloud_config_kept`). Nextcloud merges
  every `*.config.php` there over `config.php`, and saves the merged result
  into `config.php` whenever it writes a setting, so another file would be a
  second owner of the same keys.
- **Enables the apps Nextcloud would enable by itself**, the shipped ones
  its running code's `core/shipped.json` lists as `defaultEnabled` or
  `alwaysEnabled`, with `nextcloud_apps_enabled` added and
  `nextcloud_apps_disabled` taken away, and disables every other enabled app.
  So a host declares only where it differs from Nextcloud's defaults, which
  follow the running release. A declared app Nextcloud lacks is installed from
  the App Store; no app is removed. Versions are not declared: occ installs
  and updates an app only to the App Store's newest release for the running
  major.
- **Sets `nextcloud_app_settings`** that differ, with `occ config:app:set`,
  which keeps a stored key's type, laziness and sensitivity. Only declared keys
  change. A check run lists each change, with old and new values for those
  Nextcloud does not mark sensitive.
- **Converges Mail's provisioning configurations**,
  `nextcloud_mail_provisionings`, through the `mail:provisioning:*` commands of
  Mail 5.13 and later: created, updated where a declared field differs, and
  deleted when their domain is no longer declared, with the accounts they
  provisioned. Mail provisions each matching user's account, and brings it in
  line, whenever the user opens Mail, storing their login password for it, so
  the role runs no `mail:provisioning:apply`.

## Not covered

- **The stack**: its compose file, env files and units are host files, and
  its major release moves only by `maintenance.yml`'s `nextcloud-upgrade`.
- **Nextcloud's state**: users, groups, files, shares, mail accounts added by
  hand, each user's own settings, and the values apps record as they run.
- **A master password** for provisioned accounts: each account uses its user's
  own login password.
- **The official `nextcloud.admin` collection**: its modules run
  `php <path>/occ` on the managed host, which has no PHP here; reaching the
  container through `containers.podman`'s connection would need Podman's API
  socket on the host and root SSH to it from the control node.
