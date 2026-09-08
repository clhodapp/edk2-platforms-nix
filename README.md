# ext4-dxe

TianoCore's Ext4Dxe, the read-only ext4 UEFI filesystem driver from
edk2-platforms (`Features/Ext4Pkg`), built unmodified against edk2
stable tags for x86-64 and AArch64, and released as prebuilt binaries
whenever what goes into them changes.

## What it is

Ext4Dxe lets UEFI firmware and boot loaders read files from ext4
volumes. Loaded by systemd-boot from its drivers directory, it lets an
XBOOTLDR partition (`/boot`) be ext4, with only the EFI System Partition
left as FAT. The driver reads only. It verifies metadata checksums
(CRC32c, with `metadata_csum_seed`), refuses filesystems carrying
incompatible features it does not know, and handles what current
`mkfs.ext4` defaults produce: 64bit, extents, flex_bg, metadata_csum.

This repository adds no code to the driver. It pins the edk2 core at a
stable tag and edk2-platforms at a commit, builds `Ext4Pkg.dsc` with
the toolchain from nixpkgs' stable channel (`nixos-26.05`), natively
for x86-64 and through nixpkgs' cross toolchain for AArch64, and checks
each binary in a VM before it is released.

## Releases and versioning

Releases carry `ext4_x64.efi`, `ext4_aa64.efi`, and `SHA256SUMS`, named
for systemd-boot's drop-in directory (`EFI/systemd/drivers/`, which
requires the `x64.efi` / `aa64.efi` suffix).

A release is `v<edk2>.<revision>`:

- `edk2` is the edk2 stable tag the driver is built against
  (`edk2-stable<edk2>`). Each new tag starts a new series at revision 0.
- `revision` counts rebuilds against that tag.

Releases are created by the `release` workflow, not by hand. It runs on
every push to `main` and weekly, and three things move the version:

- edk2 tags a new stable release. The weekly run moves the pin to it
  and releases `v<newtag>.0`.
- A pin moves and the driver changes: edk2-platforms (the driver's own
  source) or nixpkgs (the toolchain), whether advanced by the weekly run
  or by the workspace's convergence. The run sees the build differ from
  the release under the current version and, since only `flake.lock`
  changed, bumps `revision` itself and releases.
- A file in this repository changes and the driver changes. The run
  fails rather than publish different bytes under an existing version;
  bumping `revision` in `pkgs/ext4-dxe/ext4-dxe/version.nix` by hand
  and pushing releases it.

A pin move that leaves the driver byte-identical releases nothing. Each
release's notes name the exact edk2, edk2-platforms, and nixpkgs
commits it was built from.

## Using it

Without Nix: download the artifact for your architecture from a
release, check it against `SHA256SUMS`, and copy it to
`EFI/systemd/drivers/` on the EFI System Partition (or rEFInd's
`drivers_x64` / `drivers_aa64`, or `load` it from a UEFI shell). Under
Secure Boot it must be signed by a key the platform trusts, for example
`sbsign --key db.key --cert db.crt --output ext4_x64.efi ext4_x64.efi`;
an unsigned driver is skipped.

With Nix: `packages.x86_64-linux.ext4-dxe` and
`packages.x86_64-linux.ext4-dxe-aarch64` each place `Ext4Dxe.efi` at
the output's root, and `overlays.packages` is a plain nixpkgs overlay
adding them as `pkgs.ext4-dxe.ext4-dxe` and
`pkgs.ext4-dxe.ext4-dxe-aarch64`. Both variants live under
`x86_64-linux` because the AArch64 one is cross-built from there.

```bash
nix build github:clhodapp/ext4-dxe#ext4-dxe
nix build github:clhodapp/ext4-dxe#ext4-dxe-aarch64
```

`ext4-dxe-unstable` and `ext4-dxe-unstable-aarch64` are the same driver
built against edk2 master as of the last weekly advance. They are
checked on every push to `main` and never released; a failure there is
an early look at what the next stable tag will need.

## Verification

`nix flake check` boots each driver in a VM (OVMF on QEMU's q35 for
x86-64; nixpkgs' cross-built ArmVirtQemu on QEMU's `virt` machine for
AArch64), loads it from the UEFI shell, and copies a 1 MiB multi-block
file and a file in a nested directory off a volume made by `mkfs.ext4`
at stock defaults, comparing the copies byte for byte with the
originals. The release workflow runs the stable checks before
publishing.

## CI

`check.yml` (on `main`) and `check-pr.yml` (on pull requests) run the
flake checks with the repository's Actions cache holding an on-disk Nix
binary cache of what the checks built, less what cache.nixos.org
serves. A pull request that leaves `.github/` alone is built by
`main`'s copy of the pipeline; one that changes it is built by its own
copy under its own cache scope. `main`'s builds are pushed to the
`clhodapp` cachix cache, which `release.yml` substitutes from.

## Binary cache

What `main` builds, all four drivers included, is pushed to the
`clhodapp` cachix cache, signed with its key, so `nix build` at the same
pins downloads the driver instead of building edk2's BaseTools. That
cache skips paths its upstreams already hold, so using it means using
them too:

| Substituter | Public key |
|---|---|
| `https://clhodapp.cachix.org` | `clhodapp.cachix.org-1:EW/0conxH0OQyo0o4ub/grdkFspholmQMSnQyj0vrZI=` |
| `https://nix-community.cachix.org` | `nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=` |
| `https://numtide.cachix.org` | `numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE=` |

The flake's `nixConfig` declares all three, so a direct `nix build` or
`nix flake check` here uses them once accepted: answer Nix's prompt, or
pass `--accept-flake-config`. A flake that consumes this one as an
input must add them to its own `extra-substituters` and
`extra-trusted-public-keys`; Nix does not carry an input's settings
into the consumer.

## Licensing

The Nix build scaffolding, the tests, and the workflows in this
repository are MIT (see `LICENSE`). The driver itself is TianoCore's,
under BSD-2-Clause-Patent; its source is not vendored here but fetched
from edk2-platforms at the pinned commit, and the built `Ext4Dxe.efi`
carries upstream's license.
