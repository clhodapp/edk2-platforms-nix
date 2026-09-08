# ext4-dxe

TianoCore's Ext4Dxe, the read-only ext4 UEFI filesystem driver from
edk2-platforms (`Features/Ext4Pkg`), built unmodified from a pinned tree
for x86-64 and AArch64, and released as prebuilt binaries whenever the
driver's upstream source or this build's configuration changes.

## What it is

Ext4Dxe lets UEFI firmware and boot loaders read files from ext4
volumes. Loaded by systemd-boot from its drivers directory, it lets an
XBOOTLDR partition (`/boot`) be ext4, with only the EFI System Partition
left as FAT. The driver reads only. It verifies metadata checksums
(CRC32c, with `metadata_csum_seed`), refuses filesystems carrying
incompatible features it does not know, and handles what current
`mkfs.ext4` defaults produce: 64bit, extents, flex_bg, metadata_csum.

This repository adds no code to the driver. It pins a commit of
edk2-platforms, builds `Ext4Pkg.dsc` against the edk2 core from nixpkgs'
stable channel (`nixos-26.05`), natively for x86-64 and through nixpkgs'
cross toolchain for AArch64, and checks each binary in a VM before it is
released.

## Releases and versioning

Releases carry `ext4_x64.efi`, `ext4_aa64.efi`, and `SHA256SUMS`, named
for systemd-boot's drop-in directory (`EFI/systemd/drivers/`, which
requires the `x64.efi` / `aa64.efi` suffix).

A release is `v<upstream>.<revision>`:

- `upstream` is the committer date of the newest edk2-platforms commit
  touching `Features/Ext4Pkg` that the pinned tree reaches. Ext4Pkg
  carries no version string and edk2-platforms has no releases, so the
  driver's last source change is its version.
- `revision` is this repository's, starting at 0 for each upstream
  date. It advances when the build configuration changes under the same
  upstream (a newer edk2 core or toolchain from nixpkgs) and the
  released binaries should be replaced.

Releases are created by the `release` workflow, not by hand. It runs on
every push to `main` and weekly. The weekly run advances the pin to
upstream's newest Ext4Pkg commit; every run derives `upstream` from the
lock, runs the checks, builds both architectures, and then creates the
release for the current version if none exists, confirms an existing
one is byte-identical, or fails because the build differs from what
that version released. The failure is the signal to advance `revision`
in `pkgs/ext4-dxe/ext4-dxe/version.nix`; a bumped revision pushed to
`main` is released by the same workflow. Each release's notes name the
exact edk2-platforms and nixpkgs commits it was built from.

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

## Verification

`nix flake check` boots each driver in a VM (OVMF on QEMU's q35 for
x86-64; nixpkgs' cross-built ArmVirtQemu on QEMU's `virt` machine for
AArch64), loads it from the UEFI shell, and copies a 1 MiB multi-block
file and a file in a nested directory off a volume made by `mkfs.ext4`
at stock defaults, comparing the copies byte for byte with the
originals. The release workflow runs the same checks before publishing.

## CI

`check.yml` (on `main`) and `check-pr.yml` (on pull requests) run the
flake checks with the repository's Actions cache holding an on-disk Nix
binary cache of what the checks built, less what cache.nixos.org
serves. A pull request that leaves `.github/` alone is built by
`main`'s copy of the pipeline; one that changes it is built by its own
copy under its own cache scope. `main`'s builds are pushed to the
`clhodapp` cachix cache, which `release.yml` substitutes from.

## Binary cache

What `main` builds, both drivers included, is pushed to the `clhodapp`
cachix cache, signed with its key, so `nix build` at the same pins
downloads the driver instead of building the edk2 toolchain. That cache
skips paths its upstreams already hold, so using it means using them
too:

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
