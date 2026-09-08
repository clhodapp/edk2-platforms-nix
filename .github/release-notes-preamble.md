Prebuilt UEFI drivers, for use without Nix.

| Artifact | For |
|---|---|
| `ext4_x64.efi` | x86-64 UEFI |
| `ext4_aa64.efi` | AArch64 UEFI |

Verify a download against `SHA256SUMS` before installing it.

## What it is

TianoCore's Ext4Dxe (edk2-platforms, `Features/Ext4Pkg`), built unmodified: a read-only ext4 filesystem driver that lets UEFI firmware and boot loaders read files from ext4 volumes. It verifies metadata checksums (CRC32c, with `metadata_csum_seed`), refuses filesystems carrying incompatible features it does not know, and handles what current `mkfs.ext4` defaults produce (64bit, extents, flex_bg, metadata_csum).

## Versioning

A release is `v<upstream>.<revision>`. `upstream` is the date of the newest edk2-platforms commit that touches `Features/Ext4Pkg` in the tree the driver was built from, since Ext4Pkg carries no version and edk2-platforms has no releases. `revision` counts rebuilds of the same upstream source with a changed build configuration (a newer edk2 core or toolchain from nixpkgs). Both architectures are built together from one commit, so a release always carries both.

## Supported platforms

x86-64 and AArch64 UEFI. Each release is verified before it is published by loading the driver from a UEFI shell and reading a stock-`mkfs.ext4` volume back byte for byte: on x86-64 under TianoCore OVMF in QEMU, on AArch64 under edk2's ArmVirtQemu on an emulated machine. The x86-64 driver is in use under systemd-boot on real hardware; the AArch64 one has not been run on real hardware.

## Provenance

The artifacts are the store paths the repository's CI built and pushed to its binary cache for the tagged commit, copied out and renamed; they are byte-identical to what `nix build .#ext4-dxe` (or `.#ext4-dxe-aarch64`) produces at that commit, which is one way to check a download beyond `SHA256SUMS`. The "This release" table below names the exact upstream and nixpkgs commits.

## Installing

For systemd-boot, copy the artifact for your architecture to `EFI/systemd/drivers/` on the EFI System Partition, keeping the `x64.efi` (or `aa64.efi`) filename suffix, which systemd-boot requires. systemd-boot then reads ext4 volumes, which lets an XBOOTLDR partition (`/boot`) be ext4. rEFInd loads it from its `drivers_x64` (or `drivers_aa64`) directory, and a UEFI shell on `load`.

## Secure Boot

If Secure Boot is enabled, the driver must be signed by a key your platform's signature database trusts, or the firmware will skip it. Signing with your own db key:

```
sbsign --key db.key --cert db.crt \
  --output ext4_x64.efi ext4_x64.efi
```
