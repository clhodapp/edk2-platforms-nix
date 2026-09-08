# Product

This repository packages one thing: TianoCore's Ext4Dxe, the read-only
ext4 UEFI filesystem driver in edk2-platforms (`Features/Ext4Pkg`),
built unmodified from a pinned tree for x86-64 and AArch64, and released
as prebuilt binaries whenever upstream's driver source or this
repository's build configuration changes.

The driver is what lets systemd-boot read an ext4 XBOOTLDR partition, so
a machine's `/boot` can be ext4 while its EFI System Partition stays
small. It reads only; the boot loader needs nothing more.

## Why a build, and why a repository of its own

The driver is built from source under a pinned nixpkgs stable channel
and a pinned edk2-platforms commit, so a binary is reproducible from the
commit that released it. Keeping it in a repository of its own gives it
a release cadence tied to its own inputs and a consumer surface of two
kinds: Nix packages and overlay for flakes, release assets for
everything else (a NixOS module that ships a driver by URL and hash, a
hand-managed EFI System Partition).

## Versioning and releases

The version is `<upstream>.<revision>`, from
`pkgs/ext4-dxe/ext4-dxe/version.nix`, and a release is tagged
`v<upstream>.<revision>`.

`upstream` is the committer date of the newest edk2-platforms commit
touching `Features/Ext4Pkg` that the locked `edk2-platforms` input
reaches. Ext4Pkg has no version string of its own and edk2-platforms
has no releases, so the driver's last source change is its version.
The release workflow computes it from the lock on every run and writes
it back; it is not edited by hand.

`revision` is this repository's, starting at 0 for each upstream date.
It is advanced by hand when the build configuration changes under an
unchanged upstream (a nixpkgs bump that moves the edk2 core or the
toolchain; a change to the Nix here) and the released binaries should
be replaced.

The release workflow (`.github/workflows/release.yml`) runs on every
push to main and weekly. It reconciles `upstream` with the lock,
advancing the pin to upstream's newest Ext4Pkg commit on the weekly run,
runs the checks, builds both architectures, and then either creates the
release for the current version, confirms an existing one matches, or
fails because the build differs from what that version released. That
failure is the signal to advance `revision`; a bumped revision on main
releases on the same workflow's next run.

## Deployment

The release assets are named for systemd-boot's drop-in directory
(`EFI/systemd/drivers/<name>x64.efi`, `…aa64.efi`), where systemd-boot
loads them before reading its entries. Under Secure Boot the driver
must be signed with a key the platform trusts; an unsigned driver is
skipped and boot proceeds without ext4 support.
