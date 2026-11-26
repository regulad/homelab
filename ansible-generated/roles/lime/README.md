# lime

[lime](https://github.com/regulad/lime) unlocks FileVault-encrypted Macs that
restarted on their own, answering macOS's pre-boot SSH unlock with each Mac's
password. It finds Macs by mDNS through systemd-resolved and identifies each
by its pinned host keys. lime's own README covers how it works and the setup
on each Mac.

## What the role does

- **Installs lime's release** `lime_version`, from GitHub, as the archive for
  the host's architecture: `linux-amd64-v3` on an x86-64 CPU with
  x86-64-v3, which the role checks, or `linux-arm64`. `get_url` checks it
  against its SHA-256 in `lime_sha256`, copied from the `.sha256` published
  beside it. The archive is kept and unpacked in `lime_cache_dir`, below
  `/var/cache`, which AIDE leaves out; older releases' are removed, as is the
  source checkout and cargo cache that earlier versions of the role built
  from. The service restarts when the binary or the unit changes.
- **The release reports to Sentry,** as lime's PRIVACY.md sets out: a
  session per start and a count of each password sent at the pre-boot
  unlock, nothing about the Macs. Its binary links the host's OpenSSL 3
  (`libssl3`), and needs the glibc of Ubuntu 26.04, which built it, or later.
- **Installs upstream's unit and documentation** from the same archive, and
  writes `/etc/lime/lime.toml` from `lime_interfaces` and `lime_macs`, out of
  logs and diffs, as it names each Mac's unlock account, which hosts keep in
  SOPS.
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
