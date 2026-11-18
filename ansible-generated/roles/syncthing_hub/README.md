# syncthing_hub

The hub of regulad's Syncthing mesh: aboriginal, always on, holding a copy of
every shared folder. Every other node, configured by
[`regulad/dotfiles`](https://github.com/regulad/dotfiles), marks the hub as its
introducer, so a device the hub accepts reaches the rest of the mesh without
pairing by hand.

## What it does

- **Syncthing** is the `syncthing` package's own user unit, run by
  `syncthing_hub_user` from boot through lingering.
- **Identity:** `cert.pem` and `key.pem`, from the host's `secrets.sops.yml`,
  go into the user's Syncthing state directory. The device ID is the
  certificate's SHA-256, so a rebuilt hub keeps it.
- **API key:** `/etc/syncthing-hub/api-key.env` sets `STGUIAPIKEY`, which
  overrides `config.xml`'s key. A drop-in gives it to Syncthing, and the
  joining service reads it too. Each run also sets the key in `config.xml`
  to it, through the REST API, so a tool reading `config.xml`, such as
  dotfiles' `syncthing cli`, authenticates with the same key.
- **Joining service:** `syncthing-join`, a user unit beside Syncthing, enabled
  globally and limited to the user by `ConditionUser=`. It accepts a pending
  device whose address is on the tailnet when `tailscale whois` reports its
  node either as untagged and owned by `syncthing_hub_owner` (the owner rule)
  or as carrying `syncthing_hub_tag`, whoever owns it (the tag rule). It shares
  each folder in `syncthing_hub_folders` that a configured device offers.
  Everything else stays pending. It logs each decision, with the rule that
  admitted a device, to the user's journal: `journalctl --user -u
  syncthing-join` as the user.

## What it leaves alone

Everything else in the user's home belongs to dotfiles, on the hub as on every
node: the folders and their paths, `~/.claude/.stignore`, the folders'
permissions, and usage and crash reporting. The role writes no folder and no
other setting in `config.xml`. Discovery and relays stay at Syncthing's
defaults.

The tailnet's policy lets the owner's devices and `tag:server` hosts reach
every port, Syncthing's 22000 among them. A node in the mesh by the tag rule
reaches the hub on 22000 through `tag:syncthing`'s own grants, in
`tofu/tailscale`'s policy; each host's `tailscale_tags` gives it the tag.

## Tests

`tests/test_syncthing_join.py`, under Python 3.9 with the repository's other
tests, checks which devices the service accepts and which folders it shares,
against a stand-in for Syncthing's REST API and for `tailscale whois`.
