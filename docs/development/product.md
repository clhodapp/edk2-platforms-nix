# Product

This repository packages one thing: TianoCore's Ext4Dxe, the read-only
ext4 UEFI filesystem driver in edk2-platforms (`Features/Ext4Pkg`),
built unmodified against edk2 stable tags for x86-64 and AArch64, and
released as prebuilt binaries whenever what goes into them changes.

The driver is what lets systemd-boot read an ext4 XBOOTLDR partition, so
a machine's `/boot` can be ext4 while its EFI System Partition stays
small. It reads only; the boot loader needs nothing more.

## Why a build, and why a repository of its own

The driver is built from source: the edk2 core at a stable tag and the
edk2-platforms tree at a pinned commit, with the toolchain from a pinned
nixpkgs stable channel, so a binary is reproducible from the commit
that released it. Keeping it in a repository of its own gives it a
release cadence tied to its own inputs and a consumer surface of two
kinds: Nix packages and overlay for flakes, release assets for
everything else (a NixOS module that ships a driver by URL and hash, a
hand-managed EFI System Partition).

## Versioning and releases

The version is `<edk2>.<revision>`, from
`pkgs/ext4-dxe/ext4-dxe/version.nix`, and a release is tagged
`v<edk2>.<revision>`.

`edk2` is the edk2 stable tag the driver is built against
(`edk2-stable<edk2>`), the tag the `edk2-src` input in `flake.nix`
names. The release workflow keeps the field equal to the lock and is
the only thing that edits it.

`revision` counts rebuilds against the same tag, starting at 0 for
each. Three things move the version:

- edk2 tags a new stable release. The weekly run moves `edk2-src` to
  it, re-locks, sets `edk2`, and resets `revision` to 0. A release
  follows.
- A pin moves and the driver changes: edk2-platforms (the driver's own
  source), nixpkgs (the toolchain), or anything else in `flake.lock`,
  whether advanced by the weekly run or by the workspace's convergence.
  The run finds the fresh build differs from the release under the
  current version and, because nothing but `flake.lock` changed since
  that release, bumps `revision` itself. A release follows.
- A file this repository authors changes and the driver changes. The
  run fails: the binaries under a version must not change, and the
  change is not a pin move. Bumping `revision` by hand and pushing is
  what releases it.

A pin move that leaves the driver byte-identical changes nothing: the
run confirms the existing release matches and stops.

The release workflow (`.github/workflows/release.yml`) runs on every
push to main and weekly. It advances the pins on the weekly run,
reconciles `edk2` with the lock, builds the stable checks, builds both
architectures, and applies the rules above.

## The unstable packages

`ext4-dxe-unstable` and `ext4-dxe-unstable-aarch64` are the same
driver built against edk2 master as of the last weekly advance
(`edk2-unstable-src`), versioned `0-unstable-<date>`. They exist to
see the next edk2 coming: main's check run boots them in the same VM
checks, and a failure there is an early sign of what the next stable
tag will need. They are never released, and their checks do not gate
a release.

## Deployment

The release assets are named for systemd-boot's drop-in directory
(`EFI/systemd/drivers/<name>x64.efi`, `…aa64.efi`), where systemd-boot
loads them before reading its entries. Under Secure Boot the driver
must be signed with a key the platform trusts; an unsigned driver is
skipped and boot proceeds without ext4 support.
