# Product

This repository is a Nix build of TianoCore's edk2-platforms tree
against edk2 stable tags, with nixpkgs' toolchain. It has two outputs
with different obligations.

The drop-in drivers (Ext4Dxe, the FTDI serial driver, the ASIX USB
Ethernet drivers, the DisplayLink display driver, ChaosKey) are built
unmodified for x86-64 and AArch64, checked in a VM, and released as
prebuilt binaries whenever what goes into them changes. A release is
the deliverable: a user without Nix copies a file onto an EFI System
Partition. The ext4 driver is what lets systemd-boot read an ext4
XBOOTLDR partition, which is the use the fleet has for it.

The extras (the Intel advanced-feature packages, and whatever else in
the tree builds standalone but is not a drop-in) are carried as pinned
Nix expressions: a build attribute that is known to compile at these
pins, for someone integrating a feature into their own firmware image.
They are built best-effort, never released, and never allowed to hold
anything else.

## Why a repository of its own

The drivers are built from source: the edk2 core at a stable tag and
edk2-platforms at a pinned commit, with the toolchain from a pinned
nixpkgs stable channel, so a binary is reproducible from the commit
that released it. Keeping the build in a repository of its own gives it
a release cadence tied to its own inputs and a consumer surface of two
kinds: Nix packages and an overlay for flakes, release assets for
everything else (a NixOS module that ships a driver by URL and hash, a
hand-managed EFI System Partition).

## Versioning and releases

The version is `<edk2>.<revision>`, from
`pkgs/edk2-platforms-nix/version.nix`, and a release is tagged
`v<edk2>.<revision>` and carries every drop-in for both architectures.

`edk2` is the edk2 stable tag the batch is built against
(`edk2-stable<edk2>`), the tag the `edk2-src` input in `flake.nix`
names. The release workflow keeps the field equal to the lock and is
the only thing that edits it.

`revision` counts rebuilds against the same tag, starting at 0 for
each. Three things move the version:

- edk2 tags a new stable release. The weekly run moves `edk2-src` to
  it, re-locks, sets `edk2`, and resets `revision` to 0. A release
  follows.
- A pin moves and any driver changes: edk2-platforms (the drivers'
  source), nixpkgs (the toolchain), or anything else in `flake.lock`,
  whether advanced by the weekly run or by the workspace's convergence.
  The run finds the fresh build differs from the release under the
  current version and, because nothing but `flake.lock` changed since
  that release, bumps `revision` itself. A release follows.
- A file this repository authors changes and a driver changes. The run
  fails: the binaries under a version must not change, and the change
  is not a pin move. Bumping `revision` by hand and pushing is what
  releases it.

A pin move that leaves every driver byte-identical changes nothing: the
run confirms the existing release matches and stops.

The release workflow (`.github/workflows/release.yml`) runs on every
push to main and weekly. It advances the pins on the weekly run,
reconciles `edk2` with the lock, builds the stable variants' checks by
name, builds every driver the release manifest lists, and applies the
rules above. The manifest (`packages.release-manifest`) is generated
from each driver package's `passthru.release`, so adding a drop-in is
one package file and one line in the package index.

## The unstable variants

Every drop-in also exists as `<name>-unstable` and
`<name>-unstable-aarch64`, built against edk2 master as of the last
weekly advance (`edk2-unstable-src`), versioned `0-unstable-<date>`.
They exist to see the next edk2 coming: main's check run puts them
through the same VM checks, and a failure there is an early sign of
what the next stable tag will need. They are never released, and their
checks do not gate a release.

## The extras

`extras.<system>.<name>` holds the Intel feature packages' validation
builds (`configs/flake-parts/default/extras.nix`). They live outside
`packages` and `checks` because the fleet's check pipeline builds every
attribute of both and fails on any, and a feature package that stops
building at a new edk2 tag must not turn every pull request red or
hold a release. `extras.yml` builds each in its own job, records the
outcome of every attribute in `extras/STATUS.md` on main, keeps what it
built in the repository's Actions cache only, and pushes nothing to
cachix.

## Deployment

The release assets are named for systemd-boot's drop-in directory
(`EFI/systemd/drivers/<name>x64.efi`, `…aa64.efi`), where systemd-boot
loads them before reading its entries. Under Secure Boot a driver must
be signed with a key the platform trusts; an unsigned driver is skipped
and boot proceeds without it.
