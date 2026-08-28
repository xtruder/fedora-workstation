# Ignition contributor guidance

- Treat `antares.bu` as the source of truth. Regenerate `antares.ign` with
  `just ignition` from the repository root and
  commit both files together.
- Preserve the two-stage rebase: the first deployment must use the unsigned
  transport because the signing policy is supplied by the workstation image;
  only the following deployment can use the signed transport.
- Keep the Incus 9p agent, SELinux policy, and systemd setup in Ignition so
  `incus exec` remains available across the image rebases.
- Preserve `console=ttyS0,115200n8` and `console=tty0`; the serial console is
  required for `incus console`, while `tty0` keeps VGA boot diagnostics.
- Preserve `nousershstk` while Antares runs with an Incus host-passthrough CPU.
  Some host KVM/QEMU combinations expose CET shadow stacks incorrectly, causing
  PID 1 page faults with error codes `0x44` or `0x46` after GDM starts.
- The disk configuration intentionally assumes FCOS's standard `/dev/sda`
  partition numbers and offsets. Keep `/boot` at 2 GiB: the default 384 MiB
  partition cannot hold both the FCOS and workstation deployments.
- Preserve the XBOOTLDR and x86-64 root GPT type GUIDs when resizing. Without
  them, Silverblue mounts the EFI system partition at `/boot` or cannot locate
  the root partition correctly.
- Keep the explicit `/etc/fstab` entries for ext4 `/boot` and VFAT
  `/boot/efi`. Silverblue's GPT auto-generator otherwise assumes the XBOOTLDR
  filesystem is VFAT and blocks `rpm-ostree`.
- Do not declare `/boot/efi` in `storage.directories`. The directory is
  restored from the FCOS boot filesystem, and Ignition's files stage sees the
  OSTree `/boot` view as read-only.
- Guard each later bootstrap stage by the booted `rpm-ostree` image reference.
  A successful staging command can still fail during shutdown finalization;
  stage markers alone do not prove that the new deployment booted.
- Do not embed this destination Ignition as live ISO Ignition. Its partition
  and kernel-argument operations target an installed disk, and ISO embedding
  does not perform installation.
- Preserve the proven Incus test path in the `antares-vm-*` Just recipes: boot
  an unattended ISO produced by `coreos-installer iso customize` with
  `--dest-device` and `--dest-ignition`. An unmodified FCOS live VM has no
  Incus agent, so do not depend on `incus file push` or `incus exec` before the
  destination system boots.
- Keep `poweroff-after-install` in the customized ISO flow. The install media
  has higher boot priority and Incus has no boot-once ISO option; poweroff lets
  the host detach it before starting the installed disk. Do not replace this
  with an immediate detach after `incus start`, which races live-media reads.
- Use `just antares-vm-test` for end-to-end validation. Transient `incus exec`
  failures are normal only after the installed system starts and reboots
  through the staged rebases.
- Keep RDP optional and out of the automated bootstrap. The passwordless GDM
  autologin session has no persistent unlocked login keyring, so ordinary
  `grdctl rdp set-credentials` stalls. Document `grdctl --headless` for manual
  setup because that mode uses TPM storage or a persistent key-file fallback.
- Keep the preseeded `fs_type` aligned with the installed root filesystem.
  This layout formats root as XFS, so use `xfs`; `btrfs` makes the Incus
  preseed select a Btrfs pool that cannot use the XFS-backed path.
- Declare user-owned parent directories before nested files. In particular,
  `~/.config` and each `~/.config/systemd/user` parent must belong to
  `offlinehq` before enabling the chezmoi user units.
