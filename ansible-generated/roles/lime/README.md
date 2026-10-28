# lime

[lime](https://github.com/regulad/lime) unlocks FileVault-encrypted Macs that
restarted on their own, answering macOS's pre-boot SSH unlock with each Mac's
password. It finds Macs by mDNS through systemd-resolved and identifies each
by its pinned host keys. lime's own README covers how it works and the setup
on each Mac.

## What the role does

- **Builds lime** from its source at `lime_commit`, as lime publishes no
  releases, with Ubuntu's own `cargo` and `rustc`, and `--locked`, so
  `Cargo.lock`'s checksums pin every crate. Each run lets cargo decide
  whether anything changed: a new commit or a new `rustc` from the host's
  updates rebuilds it, and the service restarts only if the binary differs.
- **Installs upstream's unit and README** from the same checkout, and writes
  `/etc/lime/lime.toml` from `lime_interfaces` and `lime_macs`, out of logs
  and diffs, as it names each Mac's unlock account, which hosts keep in SOPS.
- **Seals each Mac's password**, from `lime_passwords` in SOPS, as the
  credential `lime.<name>` in `/etc/credstore.encrypted`, encrypted
  `--with-key=host+tpm2`. A credential that is missing, holds another password
  or no longer decrypts, as after losing the vTPM, is encrypted again from
  SOPS. Credentials of Macs no longer listed are removed.
- **Runs lime** at boot.

## Not covered

- **The host's mDNS:** systemd-resolved must have mDNS on for each interface
  in `lime_interfaces`, which the host's own configuration sets.
- **Each Mac's side:** its hidden unlock account, and the sshd drop-in that
  leaves that account nowhere once the Mac is booted, by lime's README.
