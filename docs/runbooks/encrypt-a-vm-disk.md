# Encrypt a VM's passed-through disk

How a Proxmox VM whose disk is a whole physical drive, passed through as
`virtio0`, comes to boot from LUKS2 on that drive, unlocked from its vTPM. This
applies to aboriginal (VM 100) and dodo (VM 101), whose SATA SSDs are passed
through. It follows the goal **Encrypted at rest** in [`AGENTS.md`](../../AGENTS.md).

The VM moves, while running, onto an interim `rbd` disk laid out as the drive
will be: an EFI system partition, an ext4 `/boot`, and LUKS2 over the rest.
Later, with the VM off, that disk is copied onto the drive, and the VM boots
from the drive again. Every step that changes a host or OpenTofu state needs
Parker's approval for that step (`AGENTS.md`, rule 1).

## What the drive ends up holding

| Partition | Size | Holds |
|---|---|---|
| 1 | 1 GiB | EFI system partition (vfat), at `/boot/efi` |
| 2 | 1 GiB | `/boot` (ext4), outside LUKS, as GRUB cannot open LUKS from the TPM |
| 3 | the rest | LUKS2, opened as `root`, holding the btrfs root with its subvolumes and swapfile |

The LUKS volume's UUID is the one `luks_volumes` gives in the host's
`host_vars`, and its recovery passphrase is `luks_recovery_passphrase` in the
host's `secrets.sops.yml`. The `luks` role writes `/etc/crypttab` with
`discard`, so TRIM passes from btrfs (`discard=async`) through dm-crypt to the
disk below. The `luks-bind` maintenance play seals the volume's key to the
vTPM at PCR 7 with clevis, whose initramfs-tools hook unlocks it at boot, in
the crash kernel's initramfs too.

## Before starting

- The host has `luks_volumes` and `luks_recovery_passphrase`, and its guest file
  in `tofu/gonkputer` has the interim `virtio1` disk on `rbd`, 238 GiB, smaller
  than the drive's 250059096 KiB, and `luks` among its Ansible groups.
- **aboriginal only:** its `boot_order` names only `virtio0`, which would boot
  the old `/boot` on the drive if the VM restarted after the move. Its guest
  file sets `boot_order = ["virtio1", "virtio0"]` for the interim, in the same
  change: the firmware tries the interim disk first, and falls back to the
  drive while the interim disk's EFI system partition is still empty.
- No other agent is applying to the host (`AGENTS.md`, Parallel agents).

## 1. Add the interim disk

From `tofu/gonkputer`, plan and apply the change. The disk is hot-plugged; the
VM keeps running. Then, in the guest, find it by its size, 255550554112 bytes
against the drive's 256060514304:

```sh
lsblk -b -d -o NAME,SIZE /dev/vd?
```

Below, `NEW` is the interim disk (`/dev/vdb`), and `OLD_ROOT` the drive's btrfs
partition: `/dev/vda2` on dodo, `/dev/vda3` on aboriginal.

## 2. Partition and format it

In the guest, as root:

```sh
sfdisk "$NEW" <<'EOF'
label: gpt
size=1GiB, type=uefi, name=EFI
size=1GiB, type=linux, name=boot
type=CA7D7CCB-63ED-4C53-861C-1742536059CC, name=root
EOF
mkfs.vfat -F 32 -n EFI "${NEW}1"
mkfs.ext4 -L boot "${NEW}2"
```

From the repository root on the operator's machine, format the LUKS volume with
the recovery passphrase and open it. The passphrase goes through a pipe, never
onto a disk. `--sector-size 4096` matches btrfs's 4 KiB sectors, so dm-crypt
encrypts each block in one operation rather than eight 512-byte ones.

```sh
host=dodo  # or aboriginal
vars=ansible-generated/inventory/host_vars/$host.regulad.internal
uuid=$(yq '.luks_volumes[0].uuid' "$vars/main.yml")
sops -d --extract '["luks_recovery_passphrase"]' "$vars/secrets.sops.yml" | tr -d '\n' |
  ssh "$host" "sudo cryptsetup luksFormat --batch-mode --type luks2 --uuid $uuid --sector-size 4096 --key-file=- ${NEW}3"
sops -d --extract '["luks_recovery_passphrase"]' "$vars/secrets.sops.yml" | tr -d '\n' |
  ssh "$host" "sudo cryptsetup open --allow-discards --key-file=- ${NEW}3 root"
```

Check that discards reach the mapping: `lsblk -D /dev/mapper/root` shows a
non-zero `DISC-GRAN`.

## 3. Install clevis, crypttab, and the TPM binding

From `ansible-generated/`, with `--flush-cache` since step 1 changed
OpenTofu's state:

```sh
ansible-playbook playbooks/site.yml --flush-cache --tags luks --limit $host.regulad.internal
ansible-playbook playbooks/maintenance.yml --tags luks-bind --limit $host.regulad.internal
```

The first writes `/etc/crypttab` and rebuilds the initramfs and the crash
kernel's, each now able to unlock `root`; the `initramfs` option includes it
before the root moves onto it, so a reboot at any point from here comes up:
until step 5, the initramfs opens the still-empty volume and mounts the root
from the drive.
The second seals the key to the vTPM, and marks its keyslot `prefer`: an
unlock tries keyslots in order, and the recovery passphrase's, argon2id at
1 GiB, needs more memory than the crash kernel has; clevis's is PBKDF2.
Check, in the guest:

```sh
clevis luks list -d "${NEW}3"                                # a tpm2 binding, pcr_ids 7; nothing before the bind
clevis luks pass -d "${NEW}3" -s 1 >/dev/null && echo unseals # its slot from the list
cryptsetup luksDump "${NEW}3" | grep -A1 '^  1: '             # Priority: preferred
lsinitramfs /boot/initrd.img-"$(uname -r)" | grep -c clevis
lsinitramfs /var/lib/kdump/initrd.img-"$(uname -r)" | grep -c clevis
```

## 4. Move `/boot` and the EFI system partition

In the guest, as root:

```sh
mkdir -p /mnt/newboot /mnt/newefi
mount "${NEW}2" /mnt/newboot
mount "${NEW}1" /mnt/newefi
rsync -aHAXx /boot/ /mnt/newboot/   # -x: stays off /boot/efi
mkdir -p /mnt/newboot/efi
rsync -rt /boot/efi/ /mnt/newefi/
umount /mnt/newefi /mnt/newboot
umount /boot/efi
umount /boot 2>/dev/null || true    # aboriginal's own /boot; dodo's is a directory
mount "${NEW}2" /boot
mount "${NEW}1" /boot/efi
```

In `/etc/fstab`, point `/boot/efi`, and aboriginal's `/boot`, at the new
partitions' UUIDs (`blkid -s UUID -o value "${NEW}1"`, `"${NEW}2"`), and give
dodo a `/boot` line in the installer's form, as aboriginal's is:

```
/dev/disk/by-uuid/<UUID of ${NEW}2> /boot ext4 defaults 0 1
```

Then make GRUB boot from the new partitions, and record the new EFI system
partition as the one package updates install GRUB to:

```sh
systemctl daemon-reload
echo "grub-efi-amd64 grub-efi/install_devices multiselect ${NEW}1" | debconf-set-selections
echo "grub-efi-amd64-signed grub-efi/install_devices multiselect ${NEW}1" | debconf-set-selections
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ubuntu --uefi-secure-boot
update-grub
update-initramfs -u -k all
efibootmgr   # the "ubuntu" entry, first in BootOrder, names ${NEW}1's PARTUUID
```

dodo's old kernels stay in the btrfs, hidden under the new `/boot`; remove them
once the VM has booted from the new disk (step 6), through a bind mount of `/`.

## 5. Move the root onto LUKS

btrfs moves a mounted filesystem between devices. A swapfile pins its extents
and needs a single-device filesystem, so swap to it stops for the move; zram
keeps swapping.

```sh
swapoff /swap/swapfile
btrfs device add /dev/mapper/root /   # trims the whole volume first
systemd-run --unit=btrfs-move btrfs device remove "$OLD_ROOT" /
journalctl -fu btrfs-move    # until it exits; `btrfs device usage /` shows progress
swapon --all                 # fstab's options; a bare `swapon <file>` drops pri and discard
update-grub
```

The filesystem keeps its UUID, so the kernel command line and fstab's root
lines stay as they are. `update-grub` takes GRUB's font from `/boot` once the
root is on LUKS, which GRUB cannot read: `grep search /boot/grub/grub.cfg`
then names only `/boot`'s UUID. If `swapon` fails, `site.yml --tags swap`
makes the swapfile again. On dodo, about 66 GiB moved onto `rbd` in ten
minutes.

## 6. Prove the boot (dodo)

dodo can reboot on its own; aboriginal cannot, so its first encrypted boot
waits for the copy in step 8, at a host reboot. Reboot dodo, then check that it
unlocked without a prompt and is running from the interim disk:

```sh
findmnt -no SOURCE --target /               # /dev/mapper/root
findmnt -no SOURCE --target /boot           # ${NEW}2
findmnt -no SOURCE --target /boot/efi       # ${NEW}1
dmsetup table root | grep -c allow_discards
```

The initramfs's clevis unlock logs only to the console, not the journal. A
root on `/dev/mapper/root` shows it ran, as only the initramfs opens the volume
before the root is mounted; the VM answering SSH within a minute, and no
passphrase prompt at the console, show the TPM unsealed the key. systemd-cryptsetup logs that it
ignores the crypttab option `initramfs`, which is initramfs-tools' alone.

Then:
- dodo's restic job backs up mount points: add `/boot` to its
  `restic_jobs.snapshot.paths` and apply `site.yml --tags restic`.
- AIDE mails this procedure's writes once, as a one-off operation (`AIDE.md`,
  rule 8), or accept them with `maintenance.yml --tags aide-accept`.

## 7. Prove the crash kernel (optional)

With approval, crash the guest on purpose and check that the crash kernel
unlocked the root and saved a dump:

```sh
echo c > /proc/sysrq-trigger
# after the reboot:
ls /var/crash
```

## 8. Copy onto the drive, with the VM off

For aboriginal, inside a host reboot, as VM 100 is never restarted on its own.
The apply below locks every host `tofu/gonkputer` lists, so an apply another
agent makes to any of them while the VM is off holds the VM off until this
branch contains that commit: tell the other agents before the shutdown.

On prodingus, with the VM shut down (`qm shutdown <vmid>`), copy the interim
disk's image onto the drive in full, in a unit of its own so that it doesn't
depend on the SSH session. Then discard what the drive holds past the image,
which the old layout left there, and move the GPT's backup header to the
drive's end:

```sh
image=$(qm config <vmid> | sed -n 's/^virtio1: rbd:\([^,]*\),.*/\1/p')
drive=/dev/disk/by-id/ata-SK_hynix_SC311_SATA_256GB_<serial>
systemd-run --unit=copy-<vmid> --wait -p Type=exec /bin/bash -c \
  "set -o pipefail; rbd export --no-progress --pool rbd_ssd $image - | dd of=$drive bs=4M iflag=fullblock oflag=direct conv=fsync"
journalctl -u copy-<vmid> -o cat | tail -4   # dd's byte count: the image's size
blkdiscard --offset "$(rbd info --pool rbd_ssd "$image" --format json | jq .size)" "$drive"
sfdisk --relocate gpt-bak-std "$drive"
sfdisk --verify "$drive"
```

Both disks now carry the same UUIDs, so the VM must never start with both
attached: not from the web interface, and not at a host boot, as `onboot` is
set. Remove the `virtio1` disk from the guest file (and, on aboriginal, return
`boot_order` to `["virtio0"]`), commit, plan and apply. With the VM off, the
plan also shows `started` going from false to true: the provider sends Proxmox
a delete for `virtio1`, which keeps the image as `unused0`, and then starts the
VM. The firmware's boot entry names the EFI system partition's PARTUUID, which
the copy kept.

In the guest:

```sh
echo "grub-efi-amd64 grub-efi/install_devices multiselect /dev/vda1" | debconf-set-selections
echo "grub-efi-amd64-signed grub-efi/install_devices multiselect /dev/vda1" | debconf-set-selections
fstrim -av   # the copy wrote every block; this trims the free ones again
```

Last, once the VM runs from the drive, delete the interim image, which
OpenTofu no longer tracks: `qm set <vmid> --delete unused0` on prodingus.

## Recovery

If the vTPM does not unseal the key, as after a change to Secure Boot's
databases or shim's revocation level, which PCR 7 measures, the initramfs asks
for the passphrase at the Proxmox console. Type `luks_recovery_passphrase`;
once booted, `maintenance.yml --tags luks-bind` seals the key to the TPM again.
